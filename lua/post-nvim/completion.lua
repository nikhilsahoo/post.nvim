local M = {}

local keyword_patterns = {
  method_keywords = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" },
  auth_types = { "none", "basic", "bearer", "api-key", "oauth2" },
  test_types = { "status", "header", "jsonpath", "body" },
  operators = { "eq", "neq", "contains", "matches" },
  top_level_keys = { "method", "url", "headers", "body", "auth", "tests" },
  auth_keys = { "type", "username", "password", "token", "key", "header", "access_token" },
  test_keys = { "type", "key", "value", "operator" },
  common_headers = {
    "Authorization", "Content-Type", "Accept", "Cache-Control",
    "User-Agent", "X-API-Key", "Cookie", "Origin", "Referer",
  },
}

local function get_line_text()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or ""
  local col = cursor[2]
  return line, col, line:sub(1, col)
end

local function get_cursor_context()
  local line, col, before = get_line_text()
  local trimmed = line:match("^%s*(.-)%s*$")

  return {
    line = line,
    col = col,
    before_cursor = before,
    trimmed = trimmed,
  }
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

function M.get_completions()
  local ctx = get_cursor_context()
  local items = {}
  local line = ctx.line
  local before = ctx.before_cursor
  local trimmed = ctx.trimmed

  -- Text format: HTTP method at line start
  if not trimmed:match("^%s*[%{%}\"]") and not trimmed:match(":") and trimmed ~= "" then
    local method_prefix = trimmed:upper()
    for _, method in ipairs(keyword_patterns.method_keywords) do
      if method:sub(1, #method_prefix) == method_prefix then
        table.insert(items, {
          label = method,
          insertText = method .. " ",
        })
      end
    end
    if #items > 0 then
      return items
    end
  end

  -- Text format: header name after method
  if trimmed:match(":") and not trimmed:match("^%s*[%{%}\"]") then
    local header_prefix = trimmed:match("^([%w%-]+)%s*:") or trimmed:gsub(":.*", "")
    for _, h in ipairs(keyword_patterns.common_headers) do
      if h:sub(1, #header_prefix):lower() == header_prefix:lower() then
        table.insert(items, {
          label = h,
          insertText = h .. ": ",
        })
      end
    end
    if #items > 0 then
      return items
    end
  end

  -- JSON format
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  -- Check if we look like we're in JSON context
  local file_content = table.concat(lines, "\n")
  if not file_content:match("^%s*{") then
    return items
  end

  local context = get_json_context(lines, row, col)

  -- JSON key context: after { or ,
  if context.expect_value then
    -- Suggest values for known enums
    if context.last_key and context.last_key:match('"') then
      local clean_key = context.last_key:gsub('"', "")
      local value_map = {
        method = keyword_patterns.method_keywords,
        type = keyword_patterns.auth_types,
      }
      local type_values = {}
      for _, v in ipairs(keyword_patterns.auth_types) do
        table.insert(type_values, v)
      end
      for _, v in ipairs(keyword_patterns.test_types) do
        table.insert(type_values, v)
      end
      value_map.type = type_values
      value_map.operator = keyword_patterns.operators

      local candidates = value_map[clean_key] or {}
      for _, val in ipairs(candidates) do
        table.insert(items, {
          label = val,
          insertText = '"' .. val .. '"',
        })
      end
    end
    return items
  end

  -- JSON key context
  local current_parent = context.parent_keys[#context.parent_keys]
  local candidates
  if current_parent == "auth" then
    candidates = keyword_patterns.auth_keys
  elseif current_parent == "tests" then
    candidates = keyword_patterns.test_keys
  elseif not current_parent then
    candidates = keyword_patterns.top_level_keys
  end

  if candidates then
    for _, key in ipairs(candidates) do
      -- Figure out what's already typed after the last quote
      local typed = ""
      local after_last_brace = before:reverse():match("[%{%}]"):reverse()
      if after_last_brace then
        typed = after_last_brace
      end
      if key:sub(1, #typed):lower() == typed:lower() or typed == "" then
        table.insert(items, {
          label = key,
          insertText = '"' .. key .. '"',
        })
      end
    end
  end

  return items
end

function M.omnifunc(findstart, base)
  if findstart == 1 then
    local line, col = vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[2]
    return col
  end

  local items = M.get_completions()
  local results = {}
  for _, item in ipairs(items) do
    local word = item.insertText or item.label
    if word:sub(1, #base):lower() == base:lower() then
      table.insert(results, word)
    end
  end
  return results
end

function M.complete(_, params, callback)
  local items = M.get_completions()
  local ctx_items = {}
  for _, item in ipairs(items) do
    table.insert(ctx_items, {
      label = item.label,
      insertText = item.insertText or item.label,
      kind = 14,
    })
  end

  callback({
    items = ctx_items,
    isIncomplete = false,
  })
end

function M.register()
  -- Register as nvim-cmp source (handles lazy cmp loading)
  local function do_register()
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.register_source("post-nvim", {
        complete = M.complete,
      })
    end
  end

  -- If cmp is already loaded, register now
  do_register()

  -- Also listen for cmp being loaded later (lazy loading)
  vim.api.nvim_create_autocmd("User", {
    pattern = "CmpLoaded",
    callback = do_register,
  })

  -- Set omnifunc for .http files so <C-x><C-o> works out of the box
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "http",
    callback = function()
      vim.bo.omnifunc = "v:lua.require('post-nvim.completion').omnifunc"
      vim.bo.commentstring = "# %s"
    end,
  })
end

return M
