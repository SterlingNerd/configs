--[[
Mermaid sanitizer for render-markdown-mermaid.nvim

Strips problematic mermaid syntax that causes rendering failures:
- `%%{init ...}%%` directives
- `style` / `classDef` definitions
- `:::class` class assignments
- Collapses excessive blank lines
]]--

local M = {}

--- Sanitize mermaid diagram source by stripping unsupported syntax
---@param src string Raw mermaid diagram source
---@return string Sanitized mermaid diagram source
function M.sanitize(src)
  if not src or src == "" then
    return src
  end

  local lines = vim.split(src, "\n", { plain = true })
  local out = {}
  local blank_count = 0

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$") or ""

    -- Skip %%{init ...}%% directives
    if trimmed:match("^%%%{.*init.*}%%$") then
      goto continue
    end

    -- Skip style definitions: style nodeName fill:#color,stroke:#color,...
    if trimmed:match("^style%s+%w+") then
      goto continue
    end

    -- Skip classDef definitions: classDef className fill:#color,stroke:#color,...
    if trimmed:match("^classDef%s+%w+") then
      goto continue
    end

    -- Skip pure class assignment lines: nodeName:::className (no arrow syntax)
    -- Arrow syntax contains - or > (e.g., -->, ->, -.->)
    if trimmed:match("^%w+%s*:::%w+") and not trimmed:match("[%-.>]") then
      goto continue
    end

    -- Collapse multiple consecutive blank lines into a single blank line
    if trimmed == "" then
      blank_count = blank_count + 1
      if blank_count <= 1 then
        table.insert(out, "")
      end
    else
      table.insert(out, line)
      blank_count = 0
    end

    ::continue::
  end

  -- Trim leading/trailing blank lines
  while #out > 0 and out[1] == "" do
    table.remove(out, 1)
  end
  while #out > 0 and out[#out] == "" do
    table.remove(out)
  end

  return table.concat(out, "\n")
end

--- Sanitize with error handling - returns original on failure
---@param src string
---@return string
function M.safe_sanitize(src)
  local ok, result = pcall(M.sanitize, src)
  if ok then
    return result
  else
    vim.notify("mermaid_sanitize failed: " .. tostring(result), vim.log.levels.WARN)
    return src
  end
end

return M