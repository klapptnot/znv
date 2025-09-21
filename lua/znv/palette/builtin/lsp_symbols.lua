local str = require ("warm.str")

--- @param opts? {buf:integer?}
local function get_document_symbols (opts)
  opts = opts or {}
  --- @diagnostic disable-next-line: unused-local
  local function handle_request_answer (results, context, config)
    if not results then return {} end
    local lines = {}
    local pos = {}

    -- Recursive function to extract symbols from the response
    local function extract_symbols (items)
      for _, item in ipairs (items) do
        -- Check if it's DocumentSymbol or SymbolInformation
        if item.kind == 12 or item.kind == 6 or item.kind == 8 then -- function / method / field
          if item.range then
            local range = item.range
            local line = range.start.line
            local col = range.start.character

            lines[#lines+1] = str.format (
              "{: =<60} ➜ {}",
              tostring (line) .. ":" .. tostring (col),
              item.name
            )
            table.insert (pos, {
              line + 1,
              col,
            })

            -- Process children if any
            if item.children then extract_symbols (item.children) end
          elseif item.location then -- SymbolInformation
            local location = item.location
            local line = location.range.start.line
            local col = location.range.start.character

            lines[#lines+1] = str.format (
              "{: =<60} ➜ {}",
              tostring (line) .. ":" .. tostring (col),
              item.name
            )
            table.insert (pos, {
              line + 1,
              col,
            })
          end
        end
      end
    end

    -- Process results from all clients
    for _, result in pairs (results) do
      if result.result then extract_symbols (result.result) end
    end

    vim.ui.select (lines, {
      prompt = "Jump to",
      format = function (s) return s end,
    }, function (_, idx)
      if idx == nil then return end
      vim.api.nvim_win_set_cursor (vim.api.nvim_get_current_win (), {
        pos[idx][1],
        pos[idx][2],
      })
    end)
  end

  local buf = opts.buf or vim.api.nvim_get_current_buf ()

  -- Check if LSP is attached to the buffer
  local clients = vim.lsp.get_clients ({ bufnr = buf })
  if #clients == 0 then return end

  -- Request document symbols synchronously
  local _ = vim.lsp.buf_request_all (
    buf,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params (buf) },
    handle_request_answer
  )
end

return get_document_symbols
