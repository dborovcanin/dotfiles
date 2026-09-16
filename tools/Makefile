# Go tools in tools/<name>/ build into bin/<name> at the repo root, where the
# sway and niri configs run them from, and install into $(PREFIX) so they are
# on PATH too. Run from tools/, or from anywhere with make -C tools.
#
#   make                 build every tool
#   make install         build, then install into ~/.local/bin
#   make uninstall       remove what install put there
#   make clean           remove bin/
#   make search          build one tool
#
# PREFIX=/usr/local/bin make install installs somewhere else.

PREFIX ?= $(HOME)/.local/bin
BIN    := ../bin
TOOLS  := $(patsubst %/,%,$(wildcard */))

.PHONY: all build install uninstall clean $(TOOLS)

all: build

build: $(TOOLS)

# Always handed to go build, which knows better than make what is out of date.
$(TOOLS):
	go build -trimpath -ldflags="-s -w" -o $(BIN)/$@ ./$@

# rm first: an old symlink back into bin/ would make install copy a file onto itself.
install: build
	mkdir -p $(PREFIX)
	for tool in $(TOOLS); do \
		rm -f $(PREFIX)/$$tool && install -m 755 $(BIN)/$$tool $(PREFIX)/$$tool && echo "installed $(PREFIX)/$$tool"; \
	done

uninstall:
	for tool in $(TOOLS); do rm -f $(PREFIX)/$$tool; done

clean:
	rm -rf $(BIN)
