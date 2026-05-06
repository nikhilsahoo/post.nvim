local variables = require("post-nvim.variables")
local environment = require("post-nvim.environment")

local M = {}

M.schema = {
  type = "object",
  properties = {
    method = { type = "string", enum = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" } },
    url = { type = "string" },
    headers = { type = "object", additionalProperties = { type = "string" } },
    body = { type = "string" },
    auth = {
      type = "object",
      properties = {
        type = { type = "string", enum = { "none", "basic", "bearer", "api-key", "oauth2" } },
      },
    },
    tests = {
      type = "array",
      items = {
        type = "object",
        properties = {
          type = { type = "string", enum = { "status", "header", "jsonpath", "body" } },
          key = { type = "string" },
          value = {},
          operator = { type = "string", enum = { "eq", "neq", "contains", "matches" } },
        },
      },
    },
  },
  required = { "method", "url" },
}

local function default_for_method(method)
  local m = method:upper()
  if m == "GET" or m == "HEAD" or m == "OPTIONS" or m == "DELETE" then
    return true
  end
  return false
end

function M.parse_http_block(lines)
  if not lines or #lines == 0 then
    return nil, "No lines to parse"
  end

  local text = table.concat(lines, "\n")
  local ok, data = pcall(vim.fn.json_decode, text)
  if ok and type(data) == "table" then
    return M.validate(data)
  end

  return M.parse_text(lines)
end

function M.parse_text(lines)
  local request = {
    method = "GET",
    url = "",
    headers = {},
    body = nil,
  }

  local parsing_headers = false
  local parsing_body = false
  local body_lines = {}

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed == "" then
      if parsing_headers then
        parsing_headers = false
        parsing_body = true
      end
    elseif not parsing_headers and not parsing_body then
      local method, url = trimmed:match("^(%u+)%s+(.+)$")
      if method and url then
        request.method = method
        request.url = url
        parsing_headers = true
      end
    elseif parsing_headers then
      local key, value = trimmed:match("^([%w%-]+)%s*:%s*(.+)$")
      if key and value then
        request.headers[key] = value
      end
    elseif parsing_body then
      table.insert(body_lines, line)
    end
  end

  if #body_lines > 0 then
    request.body = table.concat(body_lines, "\n")
  end

  return M.validate(request)
end

function M.validate(request)
  if not request.method then
    return nil, "Request must have a method"
  end
  if not request.url then
    return nil, "Request must have a url"
  end

  request.method = request.method:upper()
  request.headers = request.headers or {}
  request.tests = request.tests or {}

  return request, nil
end

function M.resolve(request)
  local env_vars = environment.get_variables()
  local resolved = vim.tbl_deep_extend("keep", {}, request)

  resolved.url = variables.inject(resolved.url, env_vars)

  local resolved_headers = {}
  for k, v in pairs(resolved.headers or {}) do
    resolved_headers[variables.inject(k, env_vars)] = variables.inject(v, env_vars)
  end
  resolved.headers = resolved_headers

  if resolved.body then
    resolved.body = variables.inject(resolved.body, env_vars)
  end

  if resolved.auth then
    local auth = require("post-nvim.auth")
    local auth_headers = auth.apply(resolved.auth)
    for k, v in pairs(auth_headers) do
      resolved.headers[k] = v
    end
  end

  return resolved
end

function M.parse_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return M.parse_http_block(lines)
end

function M.parse_current_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return M.parse_http_block(lines)
end

return M
