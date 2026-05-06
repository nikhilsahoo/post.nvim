local M = {}

function M.run_tests(tests, response)
  if not tests or #tests == 0 then
    return { passed = true, results = {} }
  end

  local results = {}
  local all_passed = true

  for _, test in ipairs(tests) do
    local result = M.run_test(test, response)
    table.insert(results, result)
    if not result.passed then
      all_passed = false
    end
  end

  return { passed = all_passed, results = results }
end

function M.run_test(test, response)
  if test.type == "status" then
    return M.assert_status(response, test)
  elseif test.type == "header" then
    return M.assert_header(response, test)
  elseif test.type == "jsonpath" then
    return M.assert_jsonpath(response, test)
  elseif test.type == "body" then
    return M.assert_body(response, test)
  end

  return { passed = false, message = "Unknown test type: " .. (test.type or "nil") }
end

function M.assert_status(response, test)
  local expected = tonumber(test.value)
  local actual = tonumber(response.status)
  local op = test.operator or "eq"
  local passed = M.compare(actual, op, expected)
  return {
    passed = passed,
    type = "status",
    expected = expected,
    actual = actual,
    message = (passed and "PASS" or "FAIL") .. ": status " .. (op == "eq" and "==" or op) .. " " .. tostring(expected) .. " (got " .. tostring(actual) .. ")",
  }
end

function M.assert_header(response, test)
  local headers = response.headers or {}
  local actual = headers[test.key] or headers[test.key:lower()]
  local op = test.operator or "eq"
  local passed = M.compare(actual, op, test.value)
  return {
    passed = passed,
    type = "header",
    key = test.key,
    expected = test.value,
    actual = actual,
    message = (passed and "PASS" or "FAIL") .. ": header '" .. test.key .. "' " .. (op == "eq" and "==" or op) .. " '" .. tostring(test.value) .. "'" .. (actual and " (got '" .. tostring(actual) .. "')" or " (missing)"),
  }
end

function M.assert_jsonpath(response, test)
  local variables = require("post-nvim.variables")
  local actual = variables.extract(response.body, test.key)
  local op = test.operator or "eq"
  local passed = false
  if actual ~= nil then
    passed = M.compare(actual, op, test.value)
  end
  return {
    passed = passed,
    type = "jsonpath",
    key = test.key,
    expected = test.value,
    actual = actual,
    message = (passed and "PASS" or "FAIL") .. ": jsonpath '" .. test.key .. "' " .. (op == "eq" and "==" or op) .. " '" .. tostring(test.value) .. "'" .. (actual and " (got '" .. tostring(actual) .. "')" or " (not found)"),
  }
end

function M.assert_body(response, test)
  local body = response.body or ""
  local op = test.operator or "contains"
  local passed = M.compare(body, op, test.value)
  return {
    passed = passed,
    type = "body",
    expected = test.value,
    actual = body,
    message = (passed and "PASS" or "FAIL") .. ": body " .. op .. " '" .. tostring(test.value) .. "'",
  }
end

function M.compare(actual, operator, expected)
  if operator == "eq" then
    return tostring(actual) == tostring(expected)
  elseif operator == "neq" then
    return tostring(actual) ~= tostring(expected)
  elseif operator == "contains" then
    return (tostring(actual or ""):find(tostring(expected), 1, true) ~= nil)
  elseif operator == "matches" then
    return (tostring(actual or ""):match(expected) ~= nil)
  end
  return false
end

function M.format_results(test_result)
  local lines = {}
  table.insert(lines, "=== Test Results ===")
  table.insert(lines, "Overall: " .. (test_result.passed and "PASSED" or "FAILED"))
  table.insert(lines, "")
  for _, result in ipairs(test_result.results) do
    table.insert(lines, result.message)
  end
  return lines
end

return M
