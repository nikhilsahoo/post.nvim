local config = require("post-nvim.config")

local M = {}

M.current_env = nil
M.envs = {}

function M.set_active(name)
  if M.envs[name] then
    M.current_env = name
    return true
  end
  vim.notify("post.nvim: Environment '" .. name .. "' not found", vim.log.levels.WARN)
  return false
end

function M.get_active()
  return M.current_env
end

function M.get_variables()
  if M.current_env and M.envs[M.current_env] then
    return M.envs[M.current_env].variables or {}
  end
  return {}
end

function M.get(name)
  return M.envs[name]
end

function M.list()
  local names = {}
  for name in pairs(M.envs) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.load(env_name, env_data)
  M.envs[env_name] = vim.tbl_deep_extend("keep", env_data, {
    variables = {},
  })
end

function M.remove(name)
  M.envs[name] = nil
  if M.current_env == name then
    M.current_env = nil
  end
end

function M.load_from_file(filepath)
  local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(filepath))
  if not ok then
    vim.notify("post.nvim: Failed to parse environment file: " .. filepath, vim.log.levels.ERROR)
    return false
  end
  for name, env_data in pairs(data) do
    M.load(name, env_data)
  end
  return true
end

function M.load_all_from_dir(dir)
  local files = vim.fn.glob(dir .. "/*.json", false, true)
  for _, filepath in ipairs(files) do
    M.load_from_file(filepath)
  end
end

function M.init()
  local env_dir = config.get().environments_dir
  if vim.fn.isdirectory(env_dir) == 1 then
    M.load_all_from_dir(env_dir)
  end
end

return M
