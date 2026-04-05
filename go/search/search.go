package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	docExtRe = `\.(pdf|txt|md|markdown|doc|docx|odt|rtf|ppt|pptx|odp|xls|xlsx|ods|csv|epub)$`
	imgExtRe = `\.(svg|png|jpg|jpeg|gif|bmp|webp|tif|tiff|ico|avif|heic)$`
)

var docExts = []string{
	"pdf", "txt", "md", "markdown", "doc", "docx", "odt", "rtf", "ppt", "pptx", "odp", "xls", "xlsx", "ods", "csv", "epub",
}

var imgExts = []string{
	"svg", "png", "jpg", "jpeg", "gif", "bmp", "webp", "tif", "tiff", "ico", "avif", "heic",
}

var excludedDirs = []string{
	".git",
	"node_modules",
	"vendor",
	".cache",
	".cargo",
	"target",
	".venv",
}

type app struct {
	home      string
	stateDir  string
	history   string
	exe       string
	hasFD     bool
	initialQ  string
	effective string

	searchDir          string
	startupPrefixQuery string
}

type indexPaths struct {
	All string
	Doc string
	Img string
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) > 0 && strings.HasPrefix(args[0], "__") {
		return runInternal(args[0], args[1:])
	}

	a, err := newApp(args)
	if err != nil {
		return err
	}
	return a.runInteractive()
}

func runInternal(action string, args []string) error {
	query := strings.Join(args, " ")

	switch action {
	case "__dir_reload":
		return internalDirReload(query)
	case "__main_reload":
		return internalMainReload(query)
	case "__rebuild":
		return internalRebuild()
	default:
		return fmt.Errorf("unknown internal action: %s", action)
	}
}

func newApp(args []string) (*app, error) {
	if err := requireCmd("fzf"); err != nil {
		return nil, err
	}
	if err := requireCmd("rg"); err != nil {
		return nil, err
	}
	if err := requireCmd("xdg-open"); err != nil {
		return nil, err
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("resolve home dir: %w", err)
	}

	stateHome := os.Getenv("XDG_STATE_HOME")
	if stateHome == "" {
		stateHome = filepath.Join(home, ".local", "state")
	}
	stateDir := filepath.Join(stateHome, "file_search")
	if err := os.MkdirAll(stateDir, 0o755); err != nil {
		return nil, fmt.Errorf("create state dir %s: %w", stateDir, err)
	}

	history := filepath.Join(stateDir, "history")
	f, err := os.OpenFile(history, os.O_CREATE, 0o644)
	if err != nil {
		return nil, fmt.Errorf("touch history %s: %w", history, err)
	}
	_ = f.Close()

	exe, err := os.Executable()
	if err != nil {
		exe = os.Args[0]
	}

	initial := ""
	if len(args) > 0 {
		initial = args[0]
	}

	return &app{
		home:     home,
		stateDir: stateDir,
		history:  history,
		exe:      exe,
		hasFD:    commandExists("fd"),
		initialQ: initial,
	}, nil
}

func (a *app) runInteractive() error {
	a.effective = trimLeadingSpace(a.initialQ)
	defaultDir := preferredStartDir(a.history, a.home)

	if isKnownModeQuery(a.effective) {
		a.startupPrefixQuery = a.effective
		a.searchDir = defaultDir
	} else {
		dir, prefix, ok, err := a.chooseSearchDir()
		if err != nil {
			return err
		}
		if !ok {
			return nil
		}

		a.searchDir = dir
		a.startupPrefixQuery = prefix
	}

	if a.startupPrefixQuery != "" {
		a.effective = a.startupPrefixQuery
	}

	if err := saveDir(a.searchDir, a.home, a.history, a.stateDir); err != nil {
		return err
	}
	if err := os.Chdir(a.searchDir); err != nil {
		return fmt.Errorf("cd %s: %w", a.searchDir, err)
	}
	clearTTY()

	indexes, cleanup, err := createIndexes(a.stateDir)
	if err != nil {
		return err
	}
	defer cleanup()

	if err := buildIndexes(a.searchDir, indexes, a.hasFD); err != nil {
		return err
	}

	query, selected, ok, err := a.runMainFZF(indexes)
	if err != nil {
		return err
	}
	if !ok || selected == "" {
		return nil
	}

	mode, term := parseMode(query)
	switch mode {
	case "w":
		if term == "" {
			return nil
		}
		return openWebPopup(googleURL(term))
	case "c":
		if term == "" {
			return nil
		}
		return openURLDefault(chatGPTURL(term))
	case "i":
		return openImagePreview(selected)
	default:
		return openWithXDG(selected)
	}
}

func (a *app) chooseSearchDir() (dir string, prefix string, ok bool, err error) {
	defaultDir := preferredStartDir(a.history, a.home)
	dirReload := fmt.Sprintf("%s __dir_reload {q}", shellQuote(a.exe))
	prefixIndexes, cleanupIndexes, err := createIndexes(a.stateDir)
	if err != nil {
		return "", "", false, err
	}
	defer cleanupIndexes()

	docReadyMarker, err := os.CreateTemp(a.stateDir, "dirprefix.doc.ready.*")
	if err != nil {
		return "", "", false, fmt.Errorf("create dir-prefix doc marker: %w", err)
	}
	docReadyPath := docReadyMarker.Name()
	_ = docReadyMarker.Close()
	_ = os.Remove(docReadyPath)
	defer os.Remove(docReadyPath)

	imgReadyMarker, err := os.CreateTemp(a.stateDir, "dirprefix.img.ready.*")
	if err != nil {
		return "", "", false, fmt.Errorf("create dir-prefix img marker: %w", err)
	}
	imgReadyPath := imgReadyMarker.Name()
	_ = imgReadyMarker.Close()
	_ = os.Remove(imgReadyPath)
	defer os.Remove(imgReadyPath)

	out, ok, err := runFZF(
		[]string{
			"--height=50%",
			"--layout=reverse",
			"--cycle",
			"--phony",
			"--disabled",
			"--exit-0",
			"--prompt=Directory > ",
			"--header=Enter: choose dir | Type d:/i:/w:/c:<query> to switch mode, then Enter to continue",
			"--print-query",
			"--border",
			"--bind", "start:reload:" + dirReload,
			"--bind", "change:reload:" + dirReload,
		},
		nil,
		[]string{
			"HISTORY_FILE=" + a.history,
			"DIR_PREFIX_SEARCH_DIR=" + defaultDir,
			"DIR_PREFIX_INDEX_DOC=" + prefixIndexes.Doc,
			"DIR_PREFIX_INDEX_IMG=" + prefixIndexes.Img,
			"DIR_PREFIX_DOC_READY=" + docReadyPath,
			"DIR_PREFIX_IMG_READY=" + imgReadyPath,
			"DIR_PREFIX_HAS_FD=" + boolString(a.hasFD),
		},
	)
	if err != nil {
		return "", "", false, err
	}
	if !ok {
		return "", "", false, nil
	}

	query, choice := parseFZFQueryAndSelection(out)
	query = trimLeadingSpace(query)

	if isKnownModeQuery(query) {
		handled, err := handlePrefixSelection(query, choice)
		if err != nil {
			return "", "", false, err
		}
		if handled {
			return "", "", false, nil
		}
		return defaultDir, query, true, nil
	}

	// Defensive fallback: sometimes query can be empty while the selected
	// dynamic row already indicates prefix mode.
	switch {
	case strings.HasPrefix(choice, "Web search: "):
		term := strings.TrimSpace(strings.TrimPrefix(choice, "Web search: "))
		return defaultDir, "w:" + term, true, nil
	case choice == "Type query after w: to search the web":
		return defaultDir, "w:", true, nil
	case strings.HasPrefix(choice, "ChatGPT: "):
		term := strings.TrimSpace(strings.TrimPrefix(choice, "ChatGPT: "))
		return defaultDir, "c:" + term, true, nil
	case choice == "Type query after c: to open ChatGPT":
		return defaultDir, "c:", true, nil
	}

	if choice == "" {
		// No explicit directory chosen: behave as if recent dir was chosen
		// (HOME fallback). Preserve any typed query so main search starts immediately.
		return defaultDir, query, true, nil
	}

	switch {
	case strings.HasPrefix(choice, "Recent: "):
		return strings.TrimPrefix(choice, "Recent: "), "", true, nil
	case strings.HasPrefix(choice, "Home: "):
		return strings.TrimPrefix(choice, "Home: "), "", true, nil
	case choice == "Choose other directory":
		picked, ok, err := a.chooseOtherDirectory()
		if err != nil {
			return "", "", false, err
		}
		if !ok {
			return "", "", false, nil
		}
		return picked, "", true, nil
	default:
		return "", "", false, nil
	}
}

func (a *app) chooseOtherDirectory() (string, bool, error) {
	input, err := listDirsOutput(a.home, a.hasFD)
	if err != nil {
		return "", false, err
	}

	out, ok, err := runFZF(
		[]string{
			"--height=80%",
			"--layout=reverse",
			"--cycle",
			"--prompt=Find dir > ",
			"--header=Type to filter, arrows to move, TAB to copy selection to query, Enter to choose",
			"--border",
			"--scheme=path",
			"--bind=tab:replace-query",
			"--exit-0",
		},
		bytes.NewReader(input),
		nil,
	)
	if err != nil {
		return "", false, err
	}
	if !ok {
		return "", false, nil
	}

	picked := strings.TrimSpace(out)
	if picked == "" {
		return "", false, nil
	}
	return picked, true, nil
}

func (a *app) runMainFZF(indexes indexPaths) (query string, selection string, ok bool, err error) {
	mainReload := fmt.Sprintf("%s __main_reload {q}", shellQuote(a.exe))
	rebuild := fmt.Sprintf("%s __rebuild", shellQuote(a.exe))
	copyCmd := detectCopySelectionCmd()

	out, ok, err := runFZF(
		[]string{
			"--phony",
			"--disabled",
			"--query=" + a.effective,
			"--print-query",
			"--height=100%",
			"--layout=reverse",
			"--cycle",
			"--prompt=File > ",
			"--header=Dir: " + a.searchDir + " | Prefix: d: docs, i: images, w: web, c: chatgpt | Ctrl+R: rescan | Ctrl+Y: copy selection",
			"--bind", "start:reload:" + mainReload,
			"--bind", "change:reload:" + mainReload,
			"--bind", "ctrl-r:execute-silent(" + rebuild + ")+reload:" + mainReload,
			"--bind", "ctrl-y:execute-silent(printf '%q\\n' {} | " + copyCmd + ")+abort",
			"--exit-0",
		},
		nil,
		[]string{
			"SEARCH_DIR=" + a.searchDir,
			"FILE_INDEX_ALL=" + indexes.All,
			"FILE_INDEX_DOC=" + indexes.Doc,
			"FILE_INDEX_IMG=" + indexes.Img,
		},
	)
	if err != nil {
		return "", "", false, err
	}
	if !ok {
		return "", "", false, nil
	}

	q, sel := parseFZFQueryAndSelection(out)
	if sel == "" {
		return "", "", false, nil
	}
	return q, sel, true, nil
}

func runFZF(args []string, stdin io.Reader, env []string) (string, bool, error) {
	cmd := exec.Command("fzf", args...)
	if stdin != nil {
		cmd.Stdin = stdin
	} else {
		cmd.Stdin = os.Stdin
	}
	cmd.Stderr = os.Stderr
	cmd.Env = append(os.Environ(), env...)

	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			switch exitErr.ExitCode() {
			case 1, 130:
				return "", false, nil
			}
		}
		return "", false, fmt.Errorf("fzf failed: %w", err)
	}

	return out.String(), true, nil
}

func parseFZFQueryAndSelection(raw string) (string, string) {
	raw = strings.TrimRight(raw, "\n")
	if raw == "" {
		return "", ""
	}

	parts := strings.SplitN(raw, "\n", 2)
	query := parts[0]
	selection := ""
	if len(parts) == 2 {
		selection = strings.TrimSpace(parts[1])
	}
	return query, selection
}

func internalDirReload(query string) error {
	query = trimLeadingSpace(query)
	mode, term := parseMode(query)

	if mode != "" {
		switch mode {
		case "w":
			if term != "" {
				fmt.Printf("Web search: %s\n", term)
			} else {
				fmt.Println("Type query after w: to search the web")
			}
		case "c":
			if term != "" {
				fmt.Printf("ChatGPT: %s\n", term)
			} else {
				fmt.Println("Type query after c: to open ChatGPT")
			}
		case "d":
			return reloadDirPrefixFiles("d", term)
		case "i":
			return reloadDirPrefixFiles("i", term)
		}
		return nil
	}

	home, _ := os.UserHomeDir()
	history := os.Getenv("HISTORY_FILE")
	recents := readRecent(history, home, 5)
	for _, dir := range recents {
		fmt.Printf("Recent: %s\n", dir)
	}
	fmt.Printf("Home: %s\n", home)
	fmt.Println("Choose other directory")
	return nil
}

func reloadDirPrefixFiles(mode, term string) error {
	searchDir := os.Getenv("DIR_PREFIX_SEARCH_DIR")
	doc := os.Getenv("DIR_PREFIX_INDEX_DOC")
	img := os.Getenv("DIR_PREFIX_INDEX_IMG")
	docReady := os.Getenv("DIR_PREFIX_DOC_READY")
	imgReady := os.Getenv("DIR_PREFIX_IMG_READY")
	hasFD := os.Getenv("DIR_PREFIX_HAS_FD") == "1"

	if searchDir == "" || doc == "" || img == "" {
		return nil
	}

	source := doc
	if mode == "d" {
		if err := ensureDirPrefixIndex(searchDir, doc, "d", docReady, hasFD); err != nil {
			return nil
		}
	} else if mode == "i" {
		if err := ensureDirPrefixIndex(searchDir, img, "i", imgReady, hasFD); err != nil {
			return nil
		}
		source = img
	} else {
		return nil
	}

	if term == "" {
		return copyFileToStdout(source)
	}
	return rgFilterToStdout(term, source)
}

func ensureDirPrefixIndex(searchDir, outPath, mode, readyMarker string, hasFD bool) error {
	if readyMarker != "" {
		if _, err := os.Stat(readyMarker); err == nil {
			return nil
		}
	}

	if err := writeModeIndex(searchDir, outPath, mode, hasFD); err != nil {
		return err
	}

	if readyMarker != "" {
		if err := os.WriteFile(readyMarker, []byte("ok\n"), 0o644); err != nil {
			return err
		}
	}
	return nil
}

func internalMainReload(query string) error {
	mode, term := parseMode(query)
	all := os.Getenv("FILE_INDEX_ALL")
	doc := os.Getenv("FILE_INDEX_DOC")
	img := os.Getenv("FILE_INDEX_IMG")

	source := all
	switch mode {
	case "d":
		source = doc
	case "i":
		source = img
	case "w":
		if term != "" {
			fmt.Printf("Web search: %s\n", term)
		} else {
			fmt.Println("Type query after w: to search the web")
		}
		return nil
	case "c":
		if term != "" {
			fmt.Printf("ChatGPT: %s\n", term)
		} else {
			fmt.Println("Type query after c: to open ChatGPT")
		}
		return nil
	}

	if source == "" {
		return nil
	}

	if term == "" {
		return copyFileToStdout(source)
	}
	return rgFilterToStdout(term, source)
}

func internalRebuild() error {
	searchDir := os.Getenv("SEARCH_DIR")
	all := os.Getenv("FILE_INDEX_ALL")
	doc := os.Getenv("FILE_INDEX_DOC")
	img := os.Getenv("FILE_INDEX_IMG")

	if searchDir == "" || all == "" || doc == "" || img == "" {
		return nil
	}

	indexes := indexPaths{All: all, Doc: doc, Img: img}
	return buildIndexes(searchDir, indexes, commandExists("fd"))
}

func createIndexes(stateDir string) (indexPaths, func(), error) {
	all, err := os.CreateTemp(stateDir, "files.all.*")
	if err != nil {
		return indexPaths{}, nil, fmt.Errorf("create all index: %w", err)
	}
	doc, err := os.CreateTemp(stateDir, "files.doc.*")
	if err != nil {
		_ = os.Remove(all.Name())
		return indexPaths{}, nil, fmt.Errorf("create doc index: %w", err)
	}
	img, err := os.CreateTemp(stateDir, "files.img.*")
	if err != nil {
		_ = os.Remove(all.Name())
		_ = os.Remove(doc.Name())
		return indexPaths{}, nil, fmt.Errorf("create img index: %w", err)
	}

	_ = all.Close()
	_ = doc.Close()
	_ = img.Close()

	paths := indexPaths{All: all.Name(), Doc: doc.Name(), Img: img.Name()}
	cleanup := func() {
		_ = os.Remove(paths.All)
		_ = os.Remove(paths.Doc)
		_ = os.Remove(paths.Img)
	}

	return paths, cleanup, nil
}

func buildIndexes(searchDir string, indexes indexPaths, hasFD bool) error {
	if err := writeAllFilesIndex(searchDir, indexes.All, hasFD); err != nil {
		return err
	}
	if err := writeFilteredIndex(indexes.All, indexes.Doc, docExtRe); err != nil {
		return err
	}
	if err := writeFilteredIndex(indexes.All, indexes.Img, imgExtRe); err != nil {
		return err
	}
	return nil
}

func writeModeIndex(root, outPath, mode string, hasFD bool) error {
	pattern := docExtRe
	exts := docExts
	if mode == "i" {
		pattern = imgExtRe
		exts = imgExts
	}

	if hasFD {
		out, err := os.Create(outPath)
		if err != nil {
			return fmt.Errorf("open %s: %w", outPath, err)
		}
		defer out.Close()

		cmd := listFilesByExtCmd(root, exts)
		cmd.Stdout = out
		cmd.Stderr = io.Discard
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("build %s index: %w", mode, err)
		}
		return nil
	}

	tmpAll, err := os.CreateTemp(filepath.Dir(outPath), "files.mode.all.*")
	if err != nil {
		return fmt.Errorf("create temp all index: %w", err)
	}
	tmpAllPath := tmpAll.Name()
	_ = tmpAll.Close()
	defer os.Remove(tmpAllPath)

	if err := writeAllFilesIndex(root, tmpAllPath, false); err != nil {
		return err
	}
	return writeFilteredIndex(tmpAllPath, outPath, pattern)
}

func writeAllFilesIndex(root, outPath string, hasFD bool) error {
	out, err := os.Create(outPath)
	if err != nil {
		return fmt.Errorf("open %s: %w", outPath, err)
	}
	defer out.Close()

	cmd := listFilesCmd(root, hasFD)
	cmd.Stdout = out
	cmd.Stderr = io.Discard
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("build all index: %w", err)
	}
	return nil
}

func writeFilteredIndex(allPath, outPath, pattern string) error {
	out, err := os.Create(outPath)
	if err != nil {
		return fmt.Errorf("open %s: %w", outPath, err)
	}
	defer out.Close()

	cmd := exec.Command("rg", "--ignore-case", pattern, allPath)
	cmd.Stdout = out
	cmd.Stderr = io.Discard
	if err := cmd.Run(); err != nil {
		if isExitCode(err, 1) {
			return nil
		}
		return fmt.Errorf("build filtered index: %w", err)
	}
	return nil
}

func listDirsOutput(root string, hasFD bool) ([]byte, error) {
	cmd := listDirsCmd(root, hasFD)
	cmd.Stderr = io.Discard
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("list dirs: %w", err)
	}
	return out, nil
}

func listDirsCmd(root string, hasFD bool) *exec.Cmd {
	if hasFD {
		args := []string{
			"--hidden",
			"--type", "d",
			"--absolute-path",
		}
		for _, ex := range excludedDirs {
			args = append(args, "--exclude", ex)
		}
		args = append(args, ".", root)
		return exec.Command("fd", args...)
	}

	args := []string{root, "("}
	for i, ex := range excludedDirs {
		if i > 0 {
			args = append(args, "-o")
		}
		args = append(args, "-name", ex)
	}
	args = append(args, ")", "-prune", "-o", "-type", "d", "-print")
	return exec.Command("find", args...)
}

func listFilesCmd(root string, hasFD bool) *exec.Cmd {
	if hasFD {
		args := []string{
			"--hidden",
			"--type", "f",
			"--absolute-path",
		}
		for _, ex := range excludedDirs {
			args = append(args, "--exclude", ex)
		}
		args = append(args, ".", root)
		return exec.Command("fd", args...)
	}

	args := []string{root, "("}
	for i, ex := range excludedDirs {
		if i > 0 {
			args = append(args, "-o")
		}
		args = append(args, "-name", ex)
	}
	args = append(args, ")", "-prune", "-o", "-type", "f", "-print")
	return exec.Command("find", args...)
}

func listFilesByExtCmd(root string, exts []string) *exec.Cmd {
	args := []string{
		"--hidden",
		"--type", "f",
		"--absolute-path",
	}
	for _, ex := range excludedDirs {
		args = append(args, "--exclude", ex)
	}
	for _, ext := range exts {
		args = append(args, "-e", ext)
	}
	args = append(args, ".", root)
	return exec.Command("fd", args...)
}

func readRecent(historyFile, home string, limit int) []string {
	lines, err := readLines(historyFile)
	if err != nil {
		return nil
	}

	seen := make(map[string]bool)
	recent := make([]string, 0, limit)

	for i := len(lines) - 1; i >= 0; i-- {
		v := strings.TrimSpace(lines[i])
		if v == "" || v == home {
			continue
		}
		if seen[v] {
			continue
		}
		seen[v] = true
		recent = append(recent, v)
		if len(recent) >= limit {
			break
		}
	}
	return recent
}

func preferredStartDir(historyFile, home string) string {
	recent := readRecent(historyFile, home, 10)
	for _, dir := range recent {
		info, err := os.Stat(dir)
		if err != nil || !info.IsDir() {
			continue
		}
		return dir
	}
	return home
}

func saveDir(dir, home, historyFile, stateDir string) error {
	if dir == "" || dir == home {
		return nil
	}

	lines, _ := readLines(historyFile)
	filtered := make([]string, 0, len(lines)+1)
	for _, v := range lines {
		v = strings.TrimSpace(v)
		if v == "" || v == dir {
			continue
		}
		filtered = append(filtered, v)
	}
	filtered = append(filtered, dir)
	if len(filtered) > 50 {
		filtered = filtered[len(filtered)-50:]
	}

	tmp, err := os.CreateTemp(stateDir, "history.*")
	if err != nil {
		return fmt.Errorf("create history temp: %w", err)
	}
	for _, v := range filtered {
		if _, err := fmt.Fprintln(tmp, v); err != nil {
			_ = tmp.Close()
			_ = os.Remove(tmp.Name())
			return fmt.Errorf("write history temp: %w", err)
		}
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmp.Name())
		return fmt.Errorf("close history temp: %w", err)
	}
	if err := os.Rename(tmp.Name(), historyFile); err != nil {
		_ = os.Remove(tmp.Name())
		return fmt.Errorf("replace history: %w", err)
	}
	return nil
}

func parseMode(query string) (mode, term string) {
	query = trimLeadingSpace(query)
	mode = ""
	term = query

	idx := strings.Index(query, ":")
	if idx < 0 {
		return mode, term
	}

	maybeMode := query[:idx]
	maybeTerm := trimLeadingSpace(query[idx+1:])
	switch maybeMode {
	case "d", "i", "w", "c":
		mode = maybeMode
		term = maybeTerm
	default:
		mode = ""
		term = maybeTerm
	}
	return mode, term
}

func isKnownModeQuery(query string) bool {
	query = trimLeadingSpace(query)
	return strings.HasPrefix(query, "d:") ||
		strings.HasPrefix(query, "i:") ||
		strings.HasPrefix(query, "w:") ||
		strings.HasPrefix(query, "c:")
}

func trimLeadingSpace(v string) string {
	return strings.TrimLeft(v, " \t\r\n")
}

func googleURL(query string) string {
	return "https://www.google.com/search?q=" + url.QueryEscape(query)
}

func chatGPTURL(query string) string {
	return "https://chatgpt.com/?q=" + url.QueryEscape(query)
}

func openImagePreview(file string) error {
	if commandExists("feh") {
		return launchDetached("feh --auto-zoom --scale-down " + shellQuote(file))
	}
	return openWithXDG(file)
}

func openWithXDG(target string) error {
	return launchDetached("xdg-open " + shellQuote(target))
}

func openURLDefault(target string) error {
	switch {
	case commandExists("brave-browser"):
		return launchDetached("brave-browser " + shellQuote(target))
	case commandExists("brave"):
		return launchDetached("brave " + shellQuote(target))
	default:
		return openWithXDG(target)
	}
}

func openWebPopup(target string) error {
	switch {
	case commandExists("brave-browser"):
		return launchDetached("brave-browser --new-window --app=" + shellQuote(target))
	case commandExists("brave"):
		return launchDetached("brave --new-window --app=" + shellQuote(target))
	case commandExists("google-chrome-stable"):
		return launchDetached("google-chrome-stable --new-window --app=" + shellQuote(target))
	case commandExists("google-chrome"):
		return launchDetached("google-chrome --new-window --app=" + shellQuote(target))
	case commandExists("chromium"):
		return launchDetached("chromium --new-window --app=" + shellQuote(target))
	case commandExists("chromium-browser"):
		return launchDetached("chromium-browser --new-window --app=" + shellQuote(target))
	case commandExists("vivaldi"):
		return launchDetached("vivaldi --new-window --app=" + shellQuote(target))
	case commandExists("firefox"):
		return launchDetached("firefox --new-window " + shellQuote(target))
	default:
		return openURLDefault(target)
	}
}

func launchDetached(cmd string) error {
	if commandExists("swaymsg") {
		c := exec.Command("swaymsg", "exec", cmd)
		c.Stdout = io.Discard
		c.Stderr = io.Discard
		if err := c.Run(); err == nil {
			return nil
		}
	}

	if commandExists("setsid") {
		c := exec.Command("setsid", "sh", "-c", cmd)
		c.Stdout = io.Discard
		c.Stderr = io.Discard
		c.Stdin = nil
		return c.Start()
	}

	c := exec.Command("sh", "-c", cmd)
	c.Stdout = io.Discard
	c.Stderr = io.Discard
	c.Stdin = nil
	return c.Start()
}

func detectCopySelectionCmd() string {
	switch {
	case commandExists("wl-copy"):
		return "wl-copy"
	case commandExists("xclip"):
		return "xclip -selection clipboard"
	case commandExists("xsel"):
		return "xsel --clipboard --input"
	default:
		return "cat >/dev/null"
	}
}

func copyFileToStdout(path string) error {
	f, err := os.Open(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		return err
	}
	defer f.Close()
	_, err = io.Copy(os.Stdout, f)
	return err
}

func rgFilterToStdout(term, source string) error {
	cmd := exec.Command("rg", "--ignore-case", "--fixed-strings", "--", term, source)
	cmd.Stdout = os.Stdout
	cmd.Stderr = io.Discard
	if err := cmd.Run(); err != nil {
		if isExitCode(err, 1) {
			return nil
		}
		return err
	}
	return nil
}

func readLines(path string) ([]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var lines []string
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		lines = append(lines, sc.Text())
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	return lines, nil
}

func requireCmd(name string) error {
	if !commandExists(name) {
		return fmt.Errorf("missing required command: %s", name)
	}
	return nil
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func isExitCode(err error, code int) bool {
	var exitErr *exec.ExitError
	return errors.As(err, &exitErr) && exitErr.ExitCode() == code
}

func clearTTY() {
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return
	}
	defer tty.Close()
	_, _ = tty.WriteString("\033c")
}

func shellQuote(v string) string {
	if v == "" {
		return "''"
	}
	return "'" + strings.ReplaceAll(v, "'", `'\''`) + "'"
}

func boolString(v bool) string {
	if v {
		return "1"
	}
	return "0"
}

func handlePrefixSelection(query, choice string) (bool, error) {
	query = trimLeadingSpace(query)
	mode, term := parseMode(query)
	choice = strings.TrimSpace(choice)

	if mode == "" {
		return false, nil
	}

	switch mode {
	case "w":
		if term == "" {
			return true, nil
		}
		return true, openWebPopup(googleURL(term))
	case "c":
		if term == "" {
			return true, nil
		}
		return true, openURLDefault(chatGPTURL(term))
	case "d":
		if choice == "" {
			return false, nil
		}
		return true, openWithXDG(choice)
	case "i":
		if choice == "" {
			return false, nil
		}
		return true, openImagePreview(choice)
	default:
		return false, nil
	}
}
