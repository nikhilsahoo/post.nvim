local config = require("post-nvim.config")

local M = {}

local active_jobs = {}

local function build_curl_args(request)
  local args = { "curl", "-s", "-S", "-i", "-w", "\n%{http_code}\n%{content_type}" }

  local c = config.get().curl

  if c.proxy then
    table.insert(args, "--proxy")
    table.insert(args, c.proxy)
  end

  if c.insecure then
    table.insert(args, "--insecure")
  end

  table.insert(args, "--connect-timeout")
  table.insert(args, tostring(c.connect_timeout))

  table.insert(args, "--max-time")
  table.insert(args, tostring(c.max_time))

  if request.method and request.method ~= "GET" then
    table.insert(args, "-X")
    table.insert(args, request.method)
  end

  if request.headers then
    for k, v in pairs(request.headers) do
      table.insert(args, "-H")
      table.insert(args, k .. ": " .. v)
    end
  end

  if request.body then
    table.insert(args, "--data-raw")
    table.insert(args, request.body)
  end

  table.insert(args, request.url)

  return args
end

local function parse_curl_output(output)
  local response = {
    status = 0,
    reason = "Unknown",
    headers = {},
    body = "",
    raw = output,
  }

  if not output or output == "" then
    response.status = 0
    response.reason = "Empty response"
    return response
  end

  local http_code = 0
  local content_type = ""

  local lines = vim.split(output, "\n")
  local status_line_found = false
  local in_headers = true
  local body_lines = {}

  -- curl -i outputs headers first, then body. The -w format adds two extra lines at the end.
  for i, line in ipairs(lines) do
    -- Skip the trailing metadata lines from -w format
    if line:match("^%d+$") then
      http_code = tonumber(line)
      in_headers = false
    elseif line:match("^[a-z]+/[a-z0-9.+-]+") and i == #lines then
      content_type = line
    elseif in_headers then
      if line:match("^HTTP/%d%.%d") then
        status_line_found = true
        local _, _, code, reason = line:find("^HTTP/%d%.%d (%d+) (.+)$")
        if code then
          response.status = tonumber(code)
        end
        if reason then
          response.reason = reason
        end
      elseif line == "" then
        in_headers = false
      elseif status_line_found then
        local key, value = line:match("^([%w%-]+)%s*:%s*(.+)$")
        if key and value then
          response.headers[key] = value
          response.headers[key:lower()] = value
        end
      end
    else
      table.insert(body_lines, line)
    end
  end

  response.body = table.concat(body_lines, "\n")

  if http_code > 0 and response.status == 0 then
    response.status = http_code
  end

  return response
end

function M.send(request, callback)
  local args = build_curl_args(request)
  local stdout_data = {}
  local stderr_data = {}

  local job_id = vim.fn.jobstart(args, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_data, line)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stderr_data, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      local output = table.concat(stdout_data, "\n")

      local response
      if exit_code ~= 0 then
        local err = table.concat(stderr_data, "\n")
        if err == "" then
          err = "curl exited with code " .. exit_code
        end
        response = {
          status = 0,
          reason = "CurlError",
          headers = {},
          body = "",
          error = err,
          raw = output,
        }
      else
        response = parse_curl_output(output)
      end

      active_jobs[job_id] = nil

      if callback then
        callback(response)
      end
    end,
  })

  if job_id <= 0 then
    local err_msg = "Failed to start curl process"
    if callback then
      callback({
        status = 0,
        reason = "JobError",
        headers = {},
        body = "",
        error = err_msg,
      })
    end
    return nil
  end

  active_jobs[job_id] = true
  return job_id
end

function M.cancel(job_id)
  if job_id and active_jobs[job_id] then
    vim.fn.jobstop(job_id)
    active_jobs[job_id] = nil
  end
end

function M.cancel_all()
  for job_id in pairs(active_jobs) do
    vim.fn.jobstop(job_id)
  end
  active_jobs = {}
end

return M
