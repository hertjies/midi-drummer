--[[
    MIDI Drum Sequencer - test_utils.lua
    
    Unit tests for the utilities module.
    Tests common utility functions like clamp and pointInRect.
    
    Copyright (C) 2024 MIDI Drum Sequencer Contributors
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")
local utils = require("utils")

local TestUtils = {}

function TestUtils:testClamp()
    -- Test normal clamping
    luaunit.assertEquals(utils.clamp(5, 0, 10), 5)
    luaunit.assertEquals(utils.clamp(15, 0, 10), 10)
    luaunit.assertEquals(utils.clamp(-5, 0, 10), 0)
    
    -- Test edge cases
    luaunit.assertEquals(utils.clamp(0, 0, 10), 0)
    luaunit.assertEquals(utils.clamp(10, 0, 10), 10)
    
    -- Test with negative ranges
    luaunit.assertEquals(utils.clamp(-15, -20, -10), -15)
    luaunit.assertEquals(utils.clamp(-5, -20, -10), -10)
    luaunit.assertEquals(utils.clamp(-25, -20, -10), -20)
    
    -- Test with decimal values
    luaunit.assertAlmostEquals(utils.clamp(5.5, 0.0, 10.0), 5.5, 0.001)
    luaunit.assertAlmostEquals(utils.clamp(15.7, 0.0, 10.0), 10.0, 0.001)
end

function TestUtils:testPointInRect()
    -- Test point inside rectangle
    luaunit.assertTrue(utils.pointInRect(5, 5, 0, 0, 10, 10))
    luaunit.assertTrue(utils.pointInRect(50, 50, 40, 40, 20, 20))
    
    -- Test point outside rectangle
    luaunit.assertFalse(utils.pointInRect(15, 5, 0, 0, 10, 10))
    luaunit.assertFalse(utils.pointInRect(5, 15, 0, 0, 10, 10))
    luaunit.assertFalse(utils.pointInRect(-5, 5, 0, 0, 10, 10))
    luaunit.assertFalse(utils.pointInRect(5, -5, 0, 0, 10, 10))
    
    -- Test points on edges (should be inside)
    luaunit.assertTrue(utils.pointInRect(0, 0, 0, 0, 10, 10))   -- Top-left corner
    luaunit.assertTrue(utils.pointInRect(10, 10, 0, 0, 10, 10)) -- Bottom-right corner
    luaunit.assertTrue(utils.pointInRect(0, 5, 0, 0, 10, 10))   -- Left edge
    luaunit.assertTrue(utils.pointInRect(10, 5, 0, 0, 10, 10))  -- Right edge
    luaunit.assertTrue(utils.pointInRect(5, 0, 0, 0, 10, 10))   -- Top edge
    luaunit.assertTrue(utils.pointInRect(5, 10, 0, 0, 10, 10))  -- Bottom edge
    
    -- Test with offset rectangles
    luaunit.assertTrue(utils.pointInRect(105, 105, 100, 100, 50, 50))
    luaunit.assertFalse(utils.pointInRect(95, 105, 100, 100, 50, 50))
    
    -- Test with zero-size rectangle
    -- A point at the exact position of a zero-size rectangle is considered inside
    luaunit.assertTrue(utils.pointInRect(5, 5, 5, 5, 0, 0))
    -- But a point elsewhere is not
    luaunit.assertFalse(utils.pointInRect(6, 5, 5, 5, 0, 0))
    luaunit.assertFalse(utils.pointInRect(5, 6, 5, 5, 0, 0))
end

return TestUtils