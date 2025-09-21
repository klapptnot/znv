-- Name:         kalika
-- Description:  A vibrant yet soft colorscheme for peaceful coding vibes
-- Author:       Klapptnot 💜
-- Maintainer:   Klapptnot <https://github.com/klapptnot>
-- Website:      https://github.com/klapptnot/znvim
-- License:      MIT
-- Last Updated: 2025 Sep 21

-- This is the Kalika color scheme. It defines peaceful, vibrant colors to
-- bring you balance and clarity while coding.

local defaults = {
  transparent = false,
}

local M = {
  opts = vim.deepcopy (defaults),
}

-- Build palette depending on opts
function M.get_palette (opts)
  local bg, vbg = nil, nil
  if not opts.transparent then
    bg = "#0e0a16"
    vbg = "#1a1424"
  end

  return {
    -- Backgrounds
    background = bg,
    variant_bg = vbg, -- floating, menus, etc.

    -- Text colors
    foreground = "#e6d7ff",
    darkent_fg = "#0e0a16",
    variant_fd = "#edd7ff",
    subtext1 = "#bbaacc",
    subtext0 = "#9399b3",

    -- Accents
    accent0 = "#c299ff", -- Main accent (titles, selection)
    accent1 = "#d5baff", -- Lighter accent (FloatTitle)
    accent2 = "#a0d2ff", -- Secondary (StatusLineNC, types)
    accent3 = "#afb9f8", -- Tertiary (identifiers)
    accent5 = "#8d7d94",

    -- Syntax-specific
    string = "#baffc9",
    character = "#ffe2fe",
    number = "#ff8fab",
    float = "#ff8fab",
    boolean = "#fff0cf",
    class = "#feeeee",
    function_name = "#c299ff",
    keyword = "#faacf4",
    operator = "#dea584",
    conditional = "#c299ff",
    looping = "#ff8fab",
    type = "#ffa29e",
    special = "#fac1a6",
    marked = "#94e2d5",
    preproc = "#fc7ccf",
    define = "#c299ff",
    macro = "#ff8fab",
    constant = "#ff8fab",
    comment = "#9399b3",

    -- LSP
    ["@parameter"] = "#f0d2f7",

    -- UI Components
    border = "#fe8ffa", -- VertSplit
    selection = "#c299ff", -- PmenuSel bg
    visual_bg = "#36274c",
    search = "#ffdfab",
    cursearch = "#ffaaaa",

    -- Diagnostics
    error = "#fa5b6b",
    warning = "#ffc8c0",
    info = "#a0d4f7",
    hint = "#9d79d6",
    ok = "#90ee90",
  }
end

-- Build highlight groups given a palette
function M.get_highlights (palette)
  return {
    -- Base
    Normal = { fg = palette.foreground, bg = palette.background },
    NormalNC = { fg = palette.foreground, bg = palette.background },
    CursorLine = { bg = palette.variant_bg },
    CursorLineNr = { fg = palette.accent0, bold = true },
    LineNr = { fg = palette.subtext0 },
    Visual = { bg = palette.visual_bg },
    Comment = { fg = palette.comment, italic = true },
    Title = { fg = palette.accent1, bg = palette.variant_bg, bold = true },
    Underlined = { underline = true },

    -- Constants & Values
    Constant = { fg = palette.constant },
    String = { fg = palette.string },
    Character = { fg = palette.character },
    Number = { fg = palette.number },
    Boolean = { fg = palette.boolean },
    Float = { fg = palette.float },

    -- Identifiers & Functions
    Identifier = { fg = palette.accent3 },
    Function = { fg = palette.function_name, italic = true },

    -- Language Elements
    Statement = { fg = palette.keyword, bold = true },
    Keyword = { fg = palette.keyword, italic = true },
    Conditional = { fg = palette.conditional },
    Repeat = { fg = palette.looping },
    Operator = { fg = palette.operator },
    Structure = { fg = palette.class },
    Label = { fg = palette.special, italic = true },
    Exception = { link = "Keyword" },
    TypeDef = { link = "Type" },

    -- Types & Special
    Type = { fg = palette.type, italic = true },
    Special = { fg = palette.special },
    SpecialChar = { fg = palette.marked, bold = true },

    -- Preprocessor
    PreProc = { fg = palette.preproc },
    Include = { link = "PreProc" },
    Define = { link = "PreProc" },
    Macro = { fg = palette.macro },

    -- UI Components
    ModeMsg = { fg = palette.accent2, bold = true },
    NonText = { fg = palette.accent5, italic = true },
    WinBar = { bold = true },
    Error = { fg = palette.error, bold = true },
    Todo = { fg = palette.accent1, bold = true },
    TabLine = { fg = palette.foreground, bg = palette.variant_bg },
    TabLineSel = { fg = palette.background, bg = palette.accent },
    TabLineFill = { bg = palette.variant_bg },
    StatusLine = { fg = palette.foreground, bg = palette.variant_bg },
    StatusLineNC = { fg = palette.accent2, bg = palette.variant_bg },
    Pmenu = { fg = palette.foreground, bg = palette.variant_bg },
    PmenuSel = { fg = palette.darkent_fg, bg = palette.selection },
    VertSplit = { fg = palette.border },
    Search = { fg = palette.darkent_fg, bg = palette.search },
    CurSearch = { fg = palette.darkent_fg, bg = palette.cursearch },

    -- Floating Windows
    NormalFloat = { fg = palette.foreground, bg = palette.variant_bg },
    FloatBorder = { fg = palette.border, bg = palette.variant_bg },
    FloatTitle = { link = "Title" },

    -- Messages / Logs
    MsgArea = { fg = palette.foreground, bg = palette.variant_bg },
    ErrorMsg = { fg = palette.error, bold = true },
    WarningMsg = { fg = palette.warning, bold = true },
    InfoMsg = { fg = palette.info, bold = true },
    HintMsg = { fg = palette.hint, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = palette.error },
    DiagnosticWarn = { fg = palette.warning },
    DiagnosticInfo = { fg = palette.info },
    DiagnosticHint = { fg = palette.hint },
    DiagnosticOk = { fg = palette.ok },

    DiagnosticUnderlineError = { sp = palette.error, underline = true },
    DiagnosticUnderlineWarn = { sp = palette.warning, underline = true },
    DiagnosticUnderlineInfo = { sp = palette.info, underline = true },
    DiagnosticUnderlineHint = { sp = palette.hint, underline = true },
    DiagnosticUnderlineOk = { sp = palette.ok, underline = true },

    DiagnosticVirtualTextError = { link = "DiagnosticError" },
    DiagnosticVirtualTextWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualTextInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualTextHint = { link = "DiagnosticHint" },
    DiagnosticVirtualTextOk = { link = "DiagnosticOk" },

    DiagnosticFloatingError = { link = "DiagnosticError" },
    DiagnosticFloatingWarn = { link = "DiagnosticWarn" },
    DiagnosticFloatingInfo = { link = "DiagnosticInfo" },
    DiagnosticFloatingHint = { link = "DiagnosticHint" },
    DiagnosticFloatingOk = { link = "DiagnosticOk" },

    DiagnosticSignError = { link = "DiagnosticError" },
    DiagnosticSignWarn = { link = "DiagnosticWarn" },
    DiagnosticSignInfo = { link = "DiagnosticInfo" },
    DiagnosticSignHint = { link = "DiagnosticHint" },
    DiagnosticSignOk = { link = "DiagnosticOk" },
    DiagnosticDeprecated = { sp = palette.error, strikethrough = true },
    DiagnosticUnnecessary = { link = "Comment" },

    LspInlayHint = { link = "NonText" },
    SnippetTabstop = { link = "Visual" },

    Tag = { link = "Special" },
    Delimiter = { link = "Special" },
    Debug = { fg = palette.warning, italic = true },
    SignColumn = { fg = palette.accent0 },
    FoldColumn = { fg = palette.accent1 },

    -- Text
    ["@markup.raw"] = { link = "Comment" },
    ["@markup.link"] = { link = "Identifier" },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.link.url"] = { link = "Underlined" },
    ["@markup.underline"] = { link = "Underlined" },
    ["@comment.todo"] = { link = "Todo" },

    -- Miscs
    ["@comment"] = { link = "Comment" },
    ["@punctuation"] = { link = "Delimiter" },

    -- Constants
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Special" },
    ["@constant.macro"] = { link = "Define" },
    ["@string"] = { link = "String" },
    ["@string.escape"] = { link = "SpecialChar" },
    ["@string.special"] = { link = "SpecialChar" },
    ["@character"] = { link = "Character" },
    ["@character.special"] = { link = "SpecialChar" },
    ["@number"] = { link = "Number" },
    ["@number.float"] = { link = "Float" },
    ["@boolean"] = { link = "Boolean" },

    -- Functions
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { link = "Special" },
    ["@function.macro"] = { link = "Macro" },
    ["@function.method"] = { link = "Function" },
    ["@type.builtin"] = { link = "Type" },
    ["@variable.parameter.builtin"] = { link = "Special" },
    ["@variable.member"] = { link = "Identifier" },
    ["@property"] = { link = "Identifier" },
    ["@attribute"] = { link = "Macro" },
    ["@attribute.builtin"] = { link = "Special" },
    ["@constructor"] = { link = "Special" },

    -- Keywords
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.conditional"] = { link = "Conditional" },
    ["@keyword.exception"] = { link = "Exception" },
    ["@keyword.repeat"] = { link = "Repeat" },
    ["@keyword.type"] = { link = "Structure" },
    ["@label"] = { link = "Label" },
    ["@operator"] = { link = "Operator" },

    ["@variable"] = { link = "Identifier" },
    ["@variable.parameter"] = { fg = palette["@parameter"], italic = true },
    ["@type"] = { link = "Type" },
    ["@type.definition"] = { link = "Typedef" },
    ["@keyword.import"] = { link = "Include" },
    ["@keyword.directive"] = { link = "PreProc" },
    ["@keyword.debug"] = { link = "Debug" },
    ["@module"] = { link = "Identifier" },
    ["@tag"] = { link = "Tag" },
    ["@tag.builtin"] = { link = "Special" },

    -- LSP semantic tokens
    ["@lsp.type.class"] = { link = "Structure" },
    ["@lsp.type.comment"] = { link = "Comment" },
    ["@lsp.type.decorator"] = { link = "Function" },
    ["@lsp.type.enum"] = { link = "Structure" },
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.function"] = { link = "Function" },
    ["@lsp.type.interface"] = { link = "Structure" },
    ["@lsp.type.macro"] = { link = "Macro" },
    ["@lsp.type.method"] = { link = "Function" },
    ["@lsp.type.namespace"] = { link = "Structure" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "Identifier" },
    ["@lsp.type.struct"] = { link = "Structure" },
    ["@lsp.type.type"] = { link = "Type" },
    ["@lsp.type.typeParameter"] = { link = "TypeDef" },
    ["@lsp.type.variable"] = { link = "Identifier" },

    WinSeparator = { link = "VertSplit" },
    WinBarNC = { link = "WinBar" },
    EndOfBuffer = { link = "NonText" },
    LineNrAbove = { link = "LineNr" },
    LineNrBelow = { link = "LineNr" },
    QuickFixLine = { link = "Search" },
    CursorLineSign = { link = "SignColumn" },
    CursorLineFold = { link = "FoldColumn" },
    PmenuKind = { link = "Pmenu" },
    PmenuKindSel = { link = "PmenuSel" },
    PmenuMatch = { link = "Pmenu" },
    PmenuMatchSel = { link = "PmenuSel" },
    PmenuExtra = { link = "Pmenu" },
    PmenuExtraSel = { link = "PmenuSel" },
    ComplMatchIns = {},
    Substitute = { link = "Search" },
    Whitespace = { link = "NonText" },
    MsgSeparator = { link = "StatusLine" },
    FloatFooter = { link = "Title" },
  }
end

function M.setup (opts)
  M.opts = vim.tbl_deep_extend ("force", defaults, opts or {})
  if vim.g.colors_name == "kalika" then M.load () end
end

-- Apply highlights and set colorscheme name
function M.load (opts)
  opts                = vim.tbl_extend ("force", M.opts, opts or {})

  local palette       = M.get_palette (opts)
  local highlights    = M.get_highlights (palette)

  -- guard: require termguicolors
  local current_theme = vim.g.colors_name or "default"
  vim.defer_fn (function ()
    if not vim.opt.termguicolors:get () then
      vim.cmd.colorscheme (current_theme)
      vim.cmd.redraw ()
      vim.notify (
        "Kalika theme requires `termguicolors=true`. Falling back.",
        vim.log.levels.ERROR,
        { title = "Kalika Theme" }
      )
    end
  end, 0)

  vim.cmd.highlight ("clear")

  for group, gopts in pairs (highlights) do
    gopts.force = true
    gopts.cterm = gopts.cterm or {}
    vim.api.nvim_set_hl (0, group, gopts)
  end

  vim.g.colors_name = "kalika"
end

return M
