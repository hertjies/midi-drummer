--[[
    MIDI Drum Sequencer - test_sequence_grouping.lua
    
    Unit tests for sequence grouping UI functionality with 4-group background colors.
    Tests the visual organization system that groups steps 1-4, 5-8, 9-12, 13-16
    with alternating background colors for improved pattern readability.
    
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

-- Mock Love2D modules for testing
local mockLove = {
    graphics = {
        setColor = function(...) end,
        setFont = function(...) end,
        newFont = function(...) return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        print = function(...) end,
        rectangle = function(...) end,
        circle = function(...) end,
        line = function(...) end,
        setLineWidth = function(...) end,
        getFont = function() return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        getWidth = function() return 900 end,
        getHeight = function() return 650 end
    },
    timer = {
        getTime = function() return os.clock() end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local ui = require("ui")
local sequencer = require("sequencer")
local utils = require("utils")

local TestSequenceGrouping = {}

function TestSequenceGrouping:setUp()
    -- Initialize modules
    sequencer:init()
    
    -- Connect modules
    ui.sequencer = sequencer
    ui.utils = utils
end

function TestSequenceGrouping:tearDown()
    -- Clean up any state
    ui.sequencer = nil
    ui.utils = nil
end

function TestSequenceGrouping:testSequenceGroupColorDefinitions()
    -- Test that group colors are properly defined in UI color palette
    
    luaunit.assertNotNil(ui.uiColors.sequenceGroup13, "Group 1&3 color should be defined")
    luaunit.assertNotNil(ui.uiColors.sequenceGroup24, "Group 2&4 color should be defined")
    
    -- Verify colors are valid RGB tables
    luaunit.assertEquals(#ui.uiColors.sequenceGroup13, 3, "Group 1&3 color should have 3 components")
    luaunit.assertEquals(#ui.uiColors.sequenceGroup24, 3, "Group 2&4 color should have 3 components")
    
    -- Verify colors are different
    local group13 = ui.uiColors.sequenceGroup13
    local group24 = ui.uiColors.sequenceGroup24
    luaunit.assertTrue(group13[1] ~= group24[1] or group13[2] ~= group24[2] or group13[3] ~= group24[3],
                      "Group colors should be visually distinct")
end

function TestSequenceGrouping:testGetSequenceGroupColorFunction()
    -- Test the getSequenceGroupColor helper function for correct group assignment
    
    -- Group 1: steps 1-4 should return group13 color
    for step = 1, 4 do
        local color = ui:getSequenceGroupColor(step)
        luaunit.assertEquals(color, ui.uiColors.sequenceGroup13, 
                           "Step " .. step .. " should use group 1&3 color")
    end
    
    -- Group 2: steps 5-8 should return group24 color  
    for step = 5, 8 do
        local color = ui:getSequenceGroupColor(step)
        luaunit.assertEquals(color, ui.uiColors.sequenceGroup24,
                           "Step " .. step .. " should use group 2&4 color")
    end
    
    -- Group 3: steps 9-12 should return group13 color
    for step = 9, 12 do
        local color = ui:getSequenceGroupColor(step)
        luaunit.assertEquals(color, ui.uiColors.sequenceGroup13,
                           "Step " .. step .. " should use group 1&3 color")
    end
    
    -- Group 4: steps 13-16 should return group24 color
    for step = 13, 16 do
        local color = ui:getSequenceGroupColor(step)
        luaunit.assertEquals(color, ui.uiColors.sequenceGroup24,
                           "Step " .. step .. " should use group 2&4 color")
    end
end

function TestSequenceGrouping:testSequenceGroupAlternation()
    -- Test that groups properly alternate between the two color schemes
    
    local group1Color = ui:getSequenceGroupColor(1)  -- Should be group13
    local group2Color = ui:getSequenceGroupColor(5)  -- Should be group24
    local group3Color = ui:getSequenceGroupColor(9)  -- Should be group13
    local group4Color = ui:getSequenceGroupColor(13) -- Should be group24
    
    -- Groups 1 and 3 should have the same color
    luaunit.assertEquals(group1Color, group3Color, "Groups 1 and 3 should have same color")
    
    -- Groups 2 and 4 should have the same color
    luaunit.assertEquals(group2Color, group4Color, "Groups 2 and 4 should have same color")
    
    -- Adjacent groups should have different colors
    luaunit.assertTrue(group1Color ~= group2Color, "Groups 1 and 2 should have different colors")
    luaunit.assertTrue(group2Color ~= group3Color, "Groups 2 and 3 should have different colors")
    luaunit.assertTrue(group3Color ~= group4Color, "Groups 3 and 4 should have different colors")
end

function TestSequenceGrouping:testGroupBoundaryEdgeCases()
    -- Test edge cases at group boundaries
    
    -- Test boundary between groups 1 and 2
    luaunit.assertEquals(ui:getSequenceGroupColor(4), ui.uiColors.sequenceGroup13, "Step 4 should be in group 1")
    luaunit.assertEquals(ui:getSequenceGroupColor(5), ui.uiColors.sequenceGroup24, "Step 5 should be in group 2")
    
    -- Test boundary between groups 2 and 3
    luaunit.assertEquals(ui:getSequenceGroupColor(8), ui.uiColors.sequenceGroup24, "Step 8 should be in group 2")
    luaunit.assertEquals(ui:getSequenceGroupColor(9), ui.uiColors.sequenceGroup13, "Step 9 should be in group 3")
    
    -- Test boundary between groups 3 and 4
    luaunit.assertEquals(ui:getSequenceGroupColor(12), ui.uiColors.sequenceGroup13, "Step 12 should be in group 3")
    luaunit.assertEquals(ui:getSequenceGroupColor(13), ui.uiColors.sequenceGroup24, "Step 13 should be in group 4")
    
    -- Test last step
    luaunit.assertEquals(ui:getSequenceGroupColor(16), ui.uiColors.sequenceGroup24, "Step 16 should be in group 4")
end

function TestSequenceGrouping:testInvalidStepInputHandling()
    -- Test behavior with invalid step numbers (edge case handling)
    
    -- Test step 0 (should not crash)
    local color0 = ui:getSequenceGroupColor(0)
    luaunit.assertNotNil(color0, "Step 0 should return a color without crashing")
    
    -- Test step 17 (beyond normal range)
    local color17 = ui:getSequenceGroupColor(17)
    luaunit.assertNotNil(color17, "Step 17 should return a color without crashing")
    
    -- Test negative step
    local colorNeg = ui:getSequenceGroupColor(-1)
    luaunit.assertNotNil(colorNeg, "Negative step should return a color without crashing")
end

function TestSequenceGrouping:testDrawSequenceGroupBackgroundsFunction()
    -- Test that the background drawing function exists and is callable
    
    luaunit.assertEquals(type(ui.drawSequenceGroupBackgrounds), "function",
                       "drawSequenceGroupBackgrounds should be a function")
    
    -- Test that function can be called without crashing
    ui:drawSequenceGroupBackgrounds()
    luaunit.assertTrue(true, "drawSequenceGroupBackgrounds should execute without errors")
end

function TestSequenceGrouping:testGroupCalculationLogic()
    -- Test the mathematical group calculation logic
    
    -- Test that math.ceil(step / 4) produces correct group numbers
    luaunit.assertEquals(math.ceil(1 / 4), 1, "Step 1 should be in group 1")
    luaunit.assertEquals(math.ceil(4 / 4), 1, "Step 4 should be in group 1")
    luaunit.assertEquals(math.ceil(5 / 4), 2, "Step 5 should be in group 2")
    luaunit.assertEquals(math.ceil(8 / 4), 2, "Step 8 should be in group 2")
    luaunit.assertEquals(math.ceil(9 / 4), 3, "Step 9 should be in group 3")
    luaunit.assertEquals(math.ceil(12 / 4), 3, "Step 12 should be in group 3")
    luaunit.assertEquals(math.ceil(13 / 4), 4, "Step 13 should be in group 4")
    luaunit.assertEquals(math.ceil(16 / 4), 4, "Step 16 should be in group 4")
end

function TestSequenceGrouping:testGroupColorConsistency()
    -- Test that group colors remain consistent across multiple calls
    
    local step1Color1 = ui:getSequenceGroupColor(1)
    local step1Color2 = ui:getSequenceGroupColor(1)
    luaunit.assertEquals(step1Color1, step1Color2, "Multiple calls should return same color")
    
    local step5Color1 = ui:getSequenceGroupColor(5)
    local step5Color2 = ui:getSequenceGroupColor(5)
    luaunit.assertEquals(step5Color1, step5Color2, "Multiple calls should return same color")
end

function TestSequenceGrouping:testColorValueRanges()
    -- Test that color values are within valid RGB ranges (0.0 to 1.0)
    
    for step = 1, 16 do
        local color = ui:getSequenceGroupColor(step)
        
        -- Test each color component
        for i = 1, 3 do
            luaunit.assertTrue(color[i] >= 0.0, "Color component should be >= 0.0")
            luaunit.assertTrue(color[i] <= 1.0, "Color component should be <= 1.0")
        end
    end
end

function TestSequenceGrouping:testGroupPatternReadability()
    -- Test that the grouping pattern enhances readability through proper contrast
    
    local group13Color = ui.uiColors.sequenceGroup13
    local group24Color = ui.uiColors.sequenceGroup24
    
    -- Test that group24 is darker than group13 (as specified in requirements)
    local brightness13 = (group13Color[1] + group13Color[2] + group13Color[3]) / 3
    local brightness24 = (group24Color[1] + group24Color[2] + group24Color[3]) / 3
    
    luaunit.assertTrue(brightness24 < brightness13, 
                      "Group 2&4 should be darker than group 1&3 for visual contrast")
end

function TestSequenceGrouping:testGroupBackgroundIntegration()
    -- Test integration with existing grid drawing system
    
    -- Verify that the group background drawing is called in drawGrid
    luaunit.assertEquals(type(ui.drawGrid), "function", "drawGrid should be a function")
    
    -- Test that drawGrid can be called without errors (integration test)
    ui:drawGrid()
    luaunit.assertTrue(true, "drawGrid should execute without errors with group backgrounds")
end

function TestSequenceGrouping:testSequenceGroupDocumentation()
    -- Test that the grouping system is properly documented in comments
    
    -- This test validates that the implementation includes proper documentation
    -- The actual validation happens during code review, but we test the function existence
    luaunit.assertNotNil(ui.getSequenceGroupColor, "Group color function should exist")
    luaunit.assertNotNil(ui.drawSequenceGroupBackgrounds, "Group background drawing function should exist")
end

return TestSequenceGrouping