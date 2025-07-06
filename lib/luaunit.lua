-- Minimal LuaUnit implementation for testing
local M = {}

M.tests = {}
M.results = {
    passed = 0,
    failed = 0,
    errors = {}
}

function M.assertEquals(actual, expected, message)
    if actual ~= expected then
        local msg = message or ""
        error(string.format("assertEquals failed: expected '%s', got '%s'. %s", tostring(expected), tostring(actual), msg), 2)
    end
end

function M.assertTrue(value, message)
    if not value then
        local msg = message or ""
        error(string.format("assertTrue failed. %s", msg), 2)
    end
end

function M.assertFalse(value, message)
    if value then
        local msg = message or ""
        error(string.format("assertFalse failed. %s", msg), 2)
    end
end

function M.assertNotNil(value, message)
    if value == nil then
        local msg = message or ""
        error(string.format("assertNotNil failed. %s", msg), 2)
    end
end

function M.assertNil(value, message)
    if value ~= nil then
        local msg = message or ""
        error(string.format("assertNil failed: got '%s'. %s", tostring(value), msg), 2)
    end
end

function M.assertAlmostEquals(actual, expected, tolerance, message)
    tolerance = tolerance or 0.00001
    if math.abs(actual - expected) > tolerance then
        local msg = message or ""
        error(string.format("assertAlmostEquals failed: expected '%s', got '%s' (tolerance: %s). %s", 
            tostring(expected), tostring(actual), tostring(tolerance), msg), 2)
    end
end

function M.run(testClass)
    M.results = {passed = 0, failed = 0, errors = {}}
    
    print("\nRunning tests...\n")
    
    -- Run setUp before each test if it exists
    local setUp = testClass.setUp
    local tearDown = testClass.tearDown
    
    for name, func in pairs(testClass) do
        if type(func) == "function" and name:match("^test") then
            if setUp then setUp() end
            
            local success, err = pcall(func)
            
            if success then
                M.results.passed = M.results.passed + 1
                print(string.format("[PASS] %s", name))
            else
                M.results.failed = M.results.failed + 1
                table.insert(M.results.errors, {test = name, error = err})
                print(string.format("[FAIL] %s: %s", name, err))
            end
            
            if tearDown then tearDown() end
        end
    end
    
    print(string.format("\nTests run: %d, Passed: %d, Failed: %d", 
        M.results.passed + M.results.failed, M.results.passed, M.results.failed))
    
    if #M.results.errors > 0 then
        print("\nFailures:")
        for _, err in ipairs(M.results.errors) do
            print(string.format("  %s: %s", err.test, err.error))
        end
    end
    
    return M.results.failed == 0
end

return M