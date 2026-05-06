local M = {}

local function jsonpath_get(obj, path)
  if not obj or not path then
    return nil
  end

  local parts = {}
  for part in path:gmatch("[^.]+") do
    table.insert(parts, part)
  end

  local current = obj
  for _, part in ipairs(parts) do
    if part:match("%[(%d+)%]") then
      local idx = tonumber(part:match("%[(%d+)%]"))
      local key = part:match("^(.*)%[")
      if key and key ~= "" then
        current = current[key]
      end
      if type(current) == "table" and idx then
        current = current[idx]
      end
    elseif type(current) == "table" then
      current = current[part]
    else
      return nil
    end
    if current == nil then
      return nil
    end
  end

  if type(current) == "table" then
    return vim.fn.json_encode(current)
  end
  return tostring(current)
end

function M.extract(response_body, path)
  local ok, obj = pcall(vim.fn.json_decode, response_body)
  if not ok then
    return nil
  end
  return jsonpath_get(obj, path)
end

function M.inject(template, variables)
  if not template then
    return template
  end

  local result = template:gsub("{{(%w[%w_]*)}}", function(name)
    return variables[name] or "{{" .. name .. "}}"
  end)

  return result
end

function M.collect_templates(str)
  local templates = {}
  for name in str:gmatch("{{(%w[%w_]*)}}") do
    templates[name] = true
  end
  local keys = {}
  for k in pairs(templates) do
    table.insert(keys, k)
  end
  return keys
end

return M
