-- The colourscheme these dotfiles carry, written by scripts/theme.sh.
--
-- Native, in the sense that nothing installs it: ~/.config/nvim is on the
-- runtimepath and a file under colors/ is exactly what `:colorscheme` looks for,
-- so this works in a neovim with no plugin manager at all.
--
-- Only the palette between the markers is generated. What each colour is *for*
-- is written once, below, and holds for every theme in themes/ - so adding a
-- theme is a palette, not a colourscheme of its own.
--
-- The roles follow the base16 convention, which is the reason one mapping can
-- look right across palettes as unalike as Solarized and Dracula:
--
--   red     variables, tags, deletions      green    strings, additions
--   orange  numbers, booleans, constants    cyan     escapes, regex, support
--   yellow  types and classes               blue     functions and methods
--   magenta keywords and storage            dim      comments

-- theme:begin nvim
local c = {
  scheme = "dark",
  bg = "#282828",
  bg_alt = "#3c3836",
  bg_raised = "#504945",
  fg = "#ebdbb2",
  fg_alt = "#d5c4a1",
  subtle = "#a89984",
  dim = "#928374",
  border = "#d79921",
  accent = "#fabd2f",
  red = "#fb4934",
  green = "#b8bb26",
  yellow = "#fabd2f",
  blue = "#83a598",
  magenta = "#d3869b",
  cyan = "#8ec07c",
  orange = "#fe8019",
  ansi = {
    "#282828", "#cc241d", "#98971a", "#d79921",
    "#458588", "#b16286", "#689d6a", "#a89984",
    "#928374", "#fb4934", "#b8bb26", "#fabd2f",
    "#83a598", "#d3869b", "#8ec07c", "#ebdbb2",
  },
}
-- theme:end

-- Set before anything else: changing it re-sources whatever colourscheme is
-- loaded, and doing that while this one is half-applied would leave the two
-- interleaved.
vim.o.background = c.scheme

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "dotfiles"

-- `:terminal` gets the sixteen colours the terminal emulator itself was given,
-- so a shell inside neovim looks like a shell outside it.
for i, colour in ipairs(c.ansi) do
  vim.g["terminal_color_" .. (i - 1)] = colour
end

-- Text laid over one of the accent colours - a search match, a selected menu row
-- - is either the background or the foreground, whichever can actually be read
-- against it. Which one that is differs by theme: Dracula's accents are bright
-- and want the dark, Solarized Dark's are muted and want the light. Asking the
-- colour rather than the theme means a palette added later is right for free.
local function luminance(hex)
  local function channel(byte)
    local v = tonumber(hex:sub(byte, byte + 1), 16) / 255
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * channel(2) + 0.7152 * channel(4) + 0.0722 * channel(6)
end

local function contrast(a, b)
  local high, low = luminance(a), luminance(b)
  if high < low then
    high, low = low, high
  end
  return (high + 0.05) / (low + 0.05)
end

local function on(colour)
  return contrast(colour, c.bg) >= contrast(colour, c.fg) and c.bg or c.fg
end

local groups = {
  -- The editor itself
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.bg_alt },
  FloatBorder = { fg = c.bg_raised, bg = c.bg_alt },
  FloatTitle = { fg = c.border, bg = c.bg_alt, bold = true },
  Cursor = { fg = c.bg, bg = c.fg },
  CursorLine = { bg = c.bg_alt },
  CursorColumn = { bg = c.bg_alt },
  ColorColumn = { bg = c.bg_alt },
  LineNr = { fg = c.dim },
  CursorLineNr = { fg = c.border, bold = true },
  SignColumn = { bg = c.bg },
  FoldColumn = { fg = c.dim, bg = c.bg },
  Folded = { fg = c.dim, bg = c.bg_alt },
  VertSplit = { fg = c.bg_raised },
  WinSeparator = { fg = c.bg_raised },
  EndOfBuffer = { fg = c.bg },
  Visual = { bg = c.bg_raised },
  VisualNOS = { bg = c.bg_raised },
  Search = { fg = on(c.yellow), bg = c.yellow },
  IncSearch = { fg = on(c.orange), bg = c.orange },
  CurSearch = { fg = on(c.orange), bg = c.orange },
  MatchParen = { fg = c.accent, bold = true },
  NonText = { fg = c.bg_raised },
  Whitespace = { fg = c.bg_raised },
  SpecialKey = { fg = c.bg_raised },
  Directory = { fg = c.blue },
  Title = { fg = c.border, bold = true },
  Question = { fg = c.green },
  MoreMsg = { fg = c.green },
  ModeMsg = { fg = c.fg, bold = true },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.yellow },
  Conceal = { fg = c.dim },
  QuickFixLine = { bg = c.bg_raised },
  WildMenu = { fg = on(c.border), bg = c.border },

  -- Status, tabs and menus
  StatusLine = { fg = c.fg_alt, bg = c.bg_alt },
  StatusLineNC = { fg = c.dim, bg = c.bg_alt },
  TabLine = { fg = c.dim, bg = c.bg_alt },
  TabLineSel = { fg = on(c.border), bg = c.border },
  TabLineFill = { bg = c.bg_alt },
  Pmenu = { fg = c.fg, bg = c.bg_alt },
  PmenuSel = { fg = on(c.border), bg = c.border },
  PmenuSbar = { bg = c.bg_alt },
  PmenuThumb = { bg = c.bg_raised },
  PmenuMatch = { fg = c.blue, bg = c.bg_alt, bold = true },
  PmenuMatchSel = { fg = on(c.border), bg = c.border, bold = true },

  -- Syntax, by the roles at the top of this file
  Comment = { fg = c.dim, italic = true },
  Constant = { fg = c.orange },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.orange },
  Boolean = { fg = c.orange },
  Float = { fg = c.orange },
  Identifier = { fg = c.red },
  Function = { fg = c.blue },
  Statement = { fg = c.magenta },
  Conditional = { fg = c.magenta },
  Repeat = { fg = c.magenta },
  Label = { fg = c.magenta },
  Operator = { fg = c.fg },
  Keyword = { fg = c.magenta },
  Exception = { fg = c.magenta },
  PreProc = { fg = c.magenta },
  Include = { fg = c.magenta },
  Define = { fg = c.magenta },
  Macro = { fg = c.cyan },
  PreCondit = { fg = c.magenta },
  Type = { fg = c.yellow },
  StorageClass = { fg = c.yellow },
  Structure = { fg = c.yellow },
  Typedef = { fg = c.yellow },
  Special = { fg = c.cyan },
  SpecialChar = { fg = c.cyan },
  Tag = { fg = c.red },
  Delimiter = { fg = c.subtle },
  SpecialComment = { fg = c.subtle, italic = true },
  Debug = { fg = c.orange },
  Underlined = { underline = true },
  Ignore = { fg = c.dim },
  Error = { fg = c.red },
  Todo = { fg = on(c.yellow), bg = c.yellow, bold = true },

  -- The treesitter captures neovim leaves unlinked. Everything else reaches the
  -- groups above by neovim's own defaults, so only the gaps are named here.
  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.red },
  ["@variable.parameter"] = { fg = c.fg_alt },
  ["@variable.member"] = { fg = c.subtle },
  ["@field"] = { fg = c.subtle },
  ["@property"] = { fg = c.subtle },
  ["@punctuation.bracket"] = { fg = c.subtle },
  ["@punctuation.delimiter"] = { fg = c.subtle },
  ["@punctuation.special"] = { fg = c.cyan },
  ["@constructor"] = { fg = c.yellow },
  ["@tag.attribute"] = { fg = c.yellow },
  ["@markup.heading"] = { fg = c.border, bold = true },
  ["@markup.raw"] = { fg = c.green },
  ["@markup.link"] = { fg = c.blue, underline = true },
  ["@markup.list"] = { fg = c.red },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@diff.plus"] = { fg = c.green },
  ["@diff.minus"] = { fg = c.red },

  -- Diagnostics and LSP
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.cyan },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { sp = c.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = c.yellow, undercurl = true },
  DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true },
  DiagnosticUnderlineHint = { sp = c.cyan, undercurl = true },
  DiagnosticUnnecessary = { fg = c.dim },
  LspReferenceText = { bg = c.bg_raised },
  LspReferenceRead = { bg = c.bg_raised },
  LspReferenceWrite = { bg = c.bg_raised, underline = true },
  LspInlayHint = { fg = c.dim, bg = c.bg_alt },
  LspSignatureActiveParameter = { fg = c.border, bold = true },

  -- Diffs, which gitsigns and the diff view both reach
  DiffAdd = { fg = c.green, bg = c.bg_alt },
  DiffChange = { fg = c.yellow, bg = c.bg_alt },
  DiffDelete = { fg = c.red, bg = c.bg_alt },
  DiffText = { fg = on(c.yellow), bg = c.yellow },
  Added = { fg = c.green },
  Changed = { fg = c.yellow },
  Removed = { fg = c.red },

  -- Spelling
  SpellBad = { sp = c.red, undercurl = true },
  SpellCap = { sp = c.yellow, undercurl = true },
  SpellLocal = { sp = c.cyan, undercurl = true },
  SpellRare = { sp = c.magenta, undercurl = true },
}

for group, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, group, spec)
end
