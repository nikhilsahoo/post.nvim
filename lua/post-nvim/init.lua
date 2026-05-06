local config = require("post-nvim.config")
local environment = require("post-nvim.environment")
local session = require("post-nvim.session")
local request = require("post-nvim.request")
local http = require("post-nvim.http")
local response = require("post-nvim.response")
local suite = require("post-nvim.suite")
local ui = require("post-nvim.ui")

local M = {}

local augroup = vim.api.nvim_create_augroup("PostNvim", { clear = true })

function M.run_request(req_data)
  local resolved = request.resolve(req_data)
  local status_buf = ui.create_scratch_buf("post-nvim://status")
  ui.set_lines(status_buf, { "Sending " .. resolved.method .. " " .. resolved.url .. " ..." })
  ui.open_in_split(status_buf, "horizontal", 5)

  local job_id = http.send(resolved, function(resp)
    ui.set_lines(status_buf, {
      "Status: " .. (resp.status or "?") .. " " .. (resp.reason or ""),
      "Time: " .. os.date("%H:%M:%S"),
    })

    response.open_response(resp)

    if req_data.tests and #req_data.tests > 0 then
      vim.schedule(function()
        local test_result = suite.run_tests(req_data.tests, resp)
        local test_buf = ui.create_scratch_buf("post-nvim://tests")
        ui.set_lines(test_buf, suite.format_results(test_result))
        ui.set_filetype(test_buf, "json")
        ui.open_in_split(test_buf)
      end)
    end

    -- Save to session history
    local session_name = req_data.method:lower() .. "_" .. req_data.url:gsub("[^%w]", "_"):sub(1, 50)
    session.save(session_name, {
      request = req_data,
      response = {
        status = resp.status,
        headers = resp.headers,
        body_length = #(resp.body or ""),
      },
      timestamp = os.time(),
    })
  end)
end

function M.run_visual_selection()
  local req, err = request.parse_visual_selection()
  if not req then
    vim.notify("post.nvim: " .. (err or "Failed to parse request"), vim.log.levels.ERROR)
    return
  end
  M.run_request(req)
end

function M.run_buffer()
  local req, err = request.parse_current_buffer()
  if not req then
    vim.notify("post.nvim: " .. (err or "Failed to parse request"), vim.log.levels.ERROR)
    return
  end
  M.run_request(req)
end

function M.run_suite(suite_data)
  local results = {}
  local all_passed = true

  for i, req_data in ipairs(suite_data.requests or {}) do
    local resolved = request.resolve(req_data)
    local status_buf = ui.create_scratch_buf("post-nvim://suite-status")
    ui.set_lines(status_buf, { "Running request " .. i .. ": " .. resolved.method .. " " .. resolved.url })

    http.send(resolved, function(resp)
      local test_result = { passed = true, results = {} }
      if req_data.tests and #req_data.tests > 0 then
        test_result = suite.run_tests(req_data.tests, resp)
      end

      table.insert(results, {
        index = i,
        request = req_data,
        response = resp,
        tests = test_result,
      })

      if not test_result.passed then
        all_passed = false
      end

      if #results == #suite_data.requests then
        vim.schedule(function()
          M.show_suite_results(suite_data, results, all_passed)
        end)
      end
    end)
  end
end

function M.show_suite_results(suite_data, results, all_passed)
  local buf = ui.create_scratch_buf("post-nvim://suite-results")
  local lines = {}
  table.insert(lines, "=== Suite: " .. (suite_data.name or "Unnamed") .. " ===")
  table.insert(lines, "Overall: " .. (all_passed and "PASSED" or "FAILED"))
  table.insert(lines, "Requests: " .. #results)
  table.insert(lines, "")

  for _, r in ipairs(results) do
    local status_str = r.tests.passed and "PASS" or "FAIL"
    table.insert(lines, "[" .. status_str .. "] " .. r.index .. ". " .. (r.request.method or "GET") .. " " .. (r.request.url or ""))
    table.insert(lines, "    Status: " .. (r.response.status or "?") .. " " .. (r.response.reason or ""))
    for _, tr in ipairs(r.tests.results) do
      table.insert(lines, "    " .. tr.message)
    end
    table.insert(lines, "")
  end

  ui.set_lines(buf, lines)
  ui.open_in_split(buf)
end

function M.set_env(name)
  if environment.set_active(name) then
    vim.notify("post.nvim: Switched to environment '" .. name .. "'")
  end
end

function M.list_envs()
  local names = environment.list()
  if #names == 0 then
    vim.notify("post.nvim: No environments loaded")
    return
  end
  local current = environment.get_active()
  local lines = { "=== Environments ===" }
  for _, name in ipairs(names) do
    local marker = (name == current) and " *" or "  "
    table.insert(lines, marker .. name)
  end
  local buf = ui.create_scratch_buf("post-nvim://environments")
  ui.set_lines(buf, lines)
  ui.open_in_split(buf, "horizontal", 10)
end

function M.list_sessions()
  local sessions = session.list()
  if #sessions == 0 then
    vim.notify("post.nvim: No sessions found")
    return
  end
  local lines = { "=== Sessions ===" }
  for _, name in ipairs(sessions) do
    table.insert(lines, "  " .. name)
  end
  local buf = ui.create_scratch_buf("post-nvim://sessions")
  ui.set_lines(buf, lines)
  ui.open_in_split(buf, "horizontal", 10)
end

function M.delete_session(name)
  session.delete(name)
  vim.notify("post.nvim: Deleted session '" .. name .. "'")
end

function M.session_gc()
  session.gc()
  vim.notify("post.nvim: Session garbage collection complete")
end

function M.cancel()
  http.cancel_all()
  vim.notify("post.nvim: Cancelled all active requests")
end

function M.setup(opts)
  config.setup(opts)

  environment.init()

  session.gc()

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = config.get().http_filetype,
    desc = "Post.nvim http filetype settings",
    callback = function()
      vim.bo.commentstring = "# %s"
    end,
  })
end

return M
