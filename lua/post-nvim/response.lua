local config = require("post-nvim.config")
local ui = require("post-nvim.ui")

local M = {}

function M.display_response(buf, response)
  local status_line = "Status: " .. (response.status or "?") .. " (" .. (response.reason or "Unknown") .. ")"
  ui.set_lines(buf, { status_line, "" })

  if response.headers then
    ui.append_line(buf, "-- Headers --")
    for k, v in pairs(response.headers) do
      ui.append_line(buf, k .. ": " .. v)
    end
    ui.append_line(buf, "")
  end

  if response.body then
    ui.append_line(buf, "-- Body --")
    local body_lines = vim.split(response.body, "\n")
    for _, line in ipairs(body_lines) do
      ui.append_line(buf, line)
    end
  end
end

function M.display_error(buf, err_msg)
  ui.set_lines(buf, { "Error: " .. err_msg })
end

local function try_format_json(str)
  local ok, decoded = pcall(vim.fn.json_decode, str)
  if ok then
    return vim.fn.json_encode(decoded)
  end
  return str
end

local function try_format_xml(str)
  return str
end

function M.format_body(body, content_type)
  if not body then
    return ""
  end

  local ct = (content_type or ""):lower()
  if ct:find("json") or ct:find("application/.*json") then
    return try_format_json(body)
  elseif ct:find("xml") or ct:find("application/.*xml") then
    return try_format_xml(body)
  end
  return body
end

function M.open_response(response)
  local buf = ui.create_scratch_buf("post-nvim://response")
  local ct = ""
  if response.headers then
    ct = response.headers["Content-Type"] or response.headers["content-type"] or ""
  end
  response.body = M.format_body(response.body, ct)
  M.display_response(buf, response)
  ui.set_filetype(buf, "json")
  ui.open_in_split(buf)
end

return M
