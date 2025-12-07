local opt = vim.opt

-- hide mode since statusline shows it
opt.showmode = false
-- faster CursorHold updates
opt.updatetime = 500
-- enable mapped sequence timeout
opt.timeout = true
-- timeout length for mappings (ms)
opt.timeoutlen = 300

-- maintain indent on new lines
opt.autoindent = true
-- smarter autoindent for code
opt.smartindent = true

-- vertical splits open to the right
opt.splitright = true
-- horizontal splits open below
opt.splitbelow = true

-- displayed width of a tab
opt.tabstop = 2
-- editing operations use 2 spaces
opt.softtabstop = 2
-- indentation uses 2 spaces
opt.shiftwidth = 2
-- convert tabs to spaces
opt.expandtab = true

-- use system clipboard
opt.clipboard = "unnamedplus"
-- completion behavior
opt.completeopt = { "menuone", "noselect", "preview" }

-- enable mouse support
opt.mouse = "a"

-- show invisible chars
opt.list = true
-- characters shown for invisibles
opt.listchars = {
  tab = "» ",
  trail = "•",
  nbsp = "␣",
}

-- don't jump to matching bracket
opt.showmatch = false
-- enable spell-checking
opt.spell = true
-- hide obsolete ruler
opt.ruler = false

-- show line numbers
opt.number = true
-- relative numbers for movement
opt.relativenumber = true
-- width of line number column
opt.numberwidth = 3

-- soft wrap long lines
opt.wrap = true
-- wrap near right edge
opt.wrapmargin = 8

-- highlight current line
opt.cursorline = true

-- ignore case when searching…
opt.ignorecase = true
-- …unless search contains uppercase
opt.smartcase = true

-- persistent undo history
opt.undofile = true

-- always show tabline
opt.showtabline = 2
-- minimal command area height
opt.cmdheight = 1

-- minimal lines above/below cursor
opt.scroll = 1

-- disable hard-wrapping; keep only soft visual wrapping
-- never auto-insert newlines
opt.textwidth = 0
-- prevent hard wrap while typing
opt.formatoptions:remove ("t")
