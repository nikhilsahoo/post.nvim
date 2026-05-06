local M = {}

local auth_headers = {}

function M.register(name, fn)
  auth_headers[name] = fn
end

function M.apply(auth_config)
  if not auth_config or not auth_config.type then
    return {}
  end

  local fn = auth_headers[auth_config.type]
  if fn then
    return fn(auth_config)
  end

  vim.notify("post.nvim: Unknown auth type '" .. auth_config.type .. "'", vim.log.levels.WARN)
  return {}
end

M.register("none", function()
  return {}
end)

M.register("basic", function(config)
  local encoded = vim.fn.systemlist("printf '%s:%s' " .. vim.fn.shellescape(config.username) .. " " .. vim.fn.shellescape(config.password) .. " | base64 -w 0")[1] or ""
  return { ["Authorization"] = "Basic " .. encoded }
end)

M.register("bearer", function(config)
  return { ["Authorization"] = "Bearer " .. (config.token or "") }
end)

M.register("api-key", function(config)
  local header = config.header or "X-API-Key"
  return { [header] = config.key or "" }
end)

M.register("oauth2", function(config)
  return { ["Authorization"] = "Bearer " .. (config.access_token or "") }
end)

return M
