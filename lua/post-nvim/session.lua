local config = require("post-nvim.config")

local M = {}

function M.session_path(name)
  return config.get().session_dir .. "/" .. name:gsub("[^%w_%-]", "_") .. ".json"
end

function M.save(name, data)
  local dir = config.get().session_dir
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  local path = M.session_path(name)
  data._saved_at = os.time()
  data._ttl_days = config.get().session_ttl_days
  vim.fn.writefile({ vim.fn.json_encode(data) }, path)
end

function M.load(name)
  local path = M.session_path(name)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(path))
  if not ok then
    return nil
  end

  if data._ttl_days then
    local age_seconds = os.time() - (data._saved_at or 0)
    local age_days = age_seconds / 86400
    if age_days > data._ttl_days then
      M.delete(name)
      return nil
    end
  end

  return data
end

function M.delete(name)
  local path = M.session_path(name)
  if vim.fn.delete(path) ~= 0 then
    vim.notify("post.nvim: Failed to delete session: " .. name, vim.log.levels.WARN)
  end
end

function M.list()
  local dir = config.get().session_dir
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end

  local files = vim.fn.glob(dir .. "/*.json", false, true)
  local sessions = {}
  for _, filepath in ipairs(files) do
    local name = filepath:match("/([^/]+)%.json$")
    if name then
      table.insert(sessions, name)
    end
  end
  table.sort(sessions)
  return sessions
end

function M.gc()
  local dir = config.get().session_dir
  if vim.fn.isdirectory(dir) == 0 then
    return
  end

  local files = vim.fn.glob(dir .. "/*.json", false, true)
  for _, filepath in ipairs(files) do
    local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(filepath))
    if ok and data._ttl_days then
      local age_seconds = os.time() - (data._saved_at or 0)
      local age_days = age_seconds / 86400
      if age_days > data._ttl_days then
        vim.fn.delete(filepath)
      end
    end
  end
end

return M
