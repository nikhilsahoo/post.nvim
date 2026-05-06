local M = {}

local keyword_patterns = {
  method_keywords = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" },
  auth_types = { "none", "basic", "bearer", "api-key", "oauth2" },
  test_types = { "status", "header", "jsonpath", "body" },
  operators = { "eq", "neq", "contains", "matches" },
  top_level_keys = { "method", "url", "headers", "body", "auth", "tests" },
  auth_keys = { "type", "username", "password", "token", "key", "header", "access_token" },
  test_keys = { "type", "key", "value", "operator" },
}

local function context_to_prefix()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or ""
  local col = cursor[2]
  local before_cursor = line:sub(1, col)

  if before_cursor:match("%{") and not before_cursor:match("%}") then
    return "json-key"
  end
  if before_cursor:match('"') and not before_cursor:match('"', 2) then
    return "json-value"
  end

  -- Check if we're after a line starting with an HTTP method
  -- or at the start of a line (text format)
  local trimmed = line:match("^%s*(.-)%s*$")
  if trimmed ~= "" and not trimmed:match("^%s*[%{%}\"]") and not trimmed:match(":") then
    return "text-method"
  end
  if trimmed:match(":") and not trimmed:match("^%s*[%{%}\"]") and not trimmed:match("//") then
    return "text-header"
  end

  return nil
end

local function get_json_context(lines, row, col)
  local text_before = {}
  for i = 0, row - 1 do
    table.insert(text_before, lines[i + 1])
  end
  local current_line_prefix = lines[row + 1]:sub(1, col)
  table.insert(text_before, current_line_prefix)
  local before = table.concat(text_before, "\n")

  local depth = 0
  local in_string = false
  local last_key = nil
  local last_colon_key = nil
  local parent_keys = {}
  local expect_value = false

  for i = 1, #before do
    local c = before:sub(i, i)
    if c == '"' and (i == 1 or before:sub(i - 1, i - 1) ~= "\\") then
      in_string = not in_string
    elseif not in_string then
      if c == "{" then
        depth = depth + 1
        table.insert(parent_keys, last_key)
        last_key = nil
        expect_value = false
      elseif c == "}" then
        depth = math.max(depth - 1, 0)
        table.remove(parent_keys)
        last_key = nil
      elseif c == ":" then
        expect_value = true
      elseif c == "," then
        expect_value = false
      end
    end
  end

  -- Try to find what key name is being typed after a quote
  if not in_string then
    local quote_open = before:match('"([^"]*)$')
    if quote_open then
      local key_candidate = quote_open
      if #before >= 3 then
        local before_quote = before:sub(1, #before - #quote_open - 1)
        if before_quote:match("%{$") or before_quote:match(",$") or before_quote:match("%{%s*$") then
          last_key = key_candidate
        end
      end
    end
  end

  return {
    depth = depth,
    last_key = last_key,
    parent_keys = parent_keys,
    expect_value = expect_value,
  }
end

function M.complete(_, request, callback)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local context = get_json_context(lines, row, col)
  local prefix = context_to_prefix()
  local items = {}

  if prefix == "json-key" then
    local current_parent = context.parent_keys[#context.parent_keys]
    local keys_under = {
      method = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" },
      auth = { "type", "username", "password", "token", "key", "header", "access_token" },
      tests = { "type", "key", "value", "operator" },
    }

    local candidates
    if current_parent == "auth" then
      candidates = keyword_patterns.auth_keys
    elseif current_parent == "tests" then
      candidates = keyword_patterns.test_keys
    elseif current_parent then
      candidates = (keys_under[current_parent] or { current_parent })
    else
      candidates = keyword_patterns.top_level_keys
    end

    for _, key in ipairs(candidates) do
      table.insert(items, {
        label = key,
        kind = 14,
        insertText = key,
      })
    end
  elseif prefix == "json-value" then
    if context.last_key and context.last_key:match('"') then
      local clean_key = context.last_key:gsub('"', "")
      local values = {
        method = keyword_patterns.method_keywords,
        type = vim.list_extend({}, keyword_patterns.auth_types, keyword_patterns.test_types),
        operator = keyword_patterns.operators,
      }
      local candidates = values[clean_key] or {}
      for _, val in ipairs(candidates) do
        table.insert(items, {
          label = val,
          kind = 14,
          insertText = '"' .. val .. '"',
        })
      end
    end
  elseif prefix == "text-method" then
    for _, method in ipairs(keyword_patterns.method_keywords) do
      table.insert(items, {
        label = method,
        insertText = method .. " ",
        kind = 14,
      })
    end
  elseif prefix == "text-header" then
    local common_headers = {
      "Authorization", "Content-Type", "Accept", "Cache-Control",
      "User-Agent", "X-API-Key", "Cookie", "Origin", "Referer",
    }
    for _, h in ipairs(common_headers) do
      table.insert(items, {
        label = h,
        insertText = h .. ": ",
        kind = 14,
      })
    end
  end

  callback({
    items = items,
    isIncomplete = false,
  })
end

function M.is_available()
  local ok = pcall(require, "cmp")
  return ok
end

function M.register()
  if not M.is_available() then
    return
  end
  local cmp = require("cmp")
  cmp.register_source("post-nvim", {
    complete = M.complete,
  })
end

return M
