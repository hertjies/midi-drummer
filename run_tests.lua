-- Standalone test runner that can be executed with regular Lua
-- Set up the Lua module search path for all project directories
package.path = "./src/?.lua;./lib/?.lua;./tests/?.lua;" .. package.path

-- Run tests
dofile("tests/test_runner.lua")