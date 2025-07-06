--[[
    MIDI Drum Sequencer - test_clear_pattern.lua
    
    Unit tests for clear pattern functionality.
    Tests the clear grid pattern button and sequencer clearPattern function.
    
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

-- Mock Love2D modules
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
        getFont = function() return {getWidth = function() return 50 end, getHeight = function() return 12 end} end
    },
    timer = {
        getTime = function() return os.clock() end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local sequencer = require("sequencer")
local ui = require("ui")
local utils = require("utils")

local TestClearPattern = {}

function TestClearPattern:setUp()
    -- Initialize sequencer
    sequencer:init()
    
    -- Set up UI dependencies
    ui.sequencer = sequencer
    ui.utils = utils
    
    -- Reset UI state
    ui.clickedButton = nil
    
    -- Create a test pattern with some active steps
    sequencer.pattern[1][1] = true   -- Kick on step 1
    sequencer.pattern[1][5] = true   -- Kick on step 5  
    sequencer.pattern[2][3] = true   -- Snare on step 3
    sequencer.pattern[2][7] = true   -- Snare on step 7
    sequencer.pattern[3][2] = true   -- Hi-hat on step 2
    sequencer.pattern[3][4] = true   -- Hi-hat on step 4
    sequencer.pattern[3][6] = true   -- Hi-hat on step 6
    sequencer.pattern[3][8] = true   -- Hi-hat on step 8
end

function TestClearPattern:tearDown()
    ui.sequencer = nil
    ui.utils = nil
end

function TestClearPattern:testClearPatternEmptiesAllSteps()
    -- Verify we have some active steps before clearing
    local activeStepsCount = 0
    for track = 1, 8 do
        for step = 1, 16 do
            if sequencer.pattern[track][step] then
                activeStepsCount = activeStepsCount + 1
            end
        end
    end
    
    luaunit.assertTrue(activeStepsCount > 0, "Should have some active steps before clearing")
    
    -- Call clearPattern
    sequencer:clearPattern()
    
    -- Verify all steps are now inactive
    for track = 1, 8 do
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step], 
                               string.format("Track %d step %d should be inactive after clear", track, step))
        end
    end
end

function TestClearPattern:testClearPatternDoesNotAffectPlaybackState()
    -- Start playback
    sequencer:play()
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should be playing")
    
    local initialBPM = sequencer.bpm
    local initialStep = sequencer.currentStep
    
    -- Clear pattern
    sequencer:clearPattern()
    
    -- Verify playback state is unchanged
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should still be playing after clear")
    luaunit.assertEquals(sequencer.bpm, initialBPM, "BPM should be unchanged after clear")
    luaunit.assertEquals(sequencer.currentStep, initialStep, "Current step should be unchanged after clear")
end

function TestClearPattern:testClearPatternDoesNotAffectBPMSettings()
    -- Set a specific BPM
    local testBPM = 140
    sequencer:setBPM(testBPM)
    luaunit.assertEquals(sequencer.bpm, testBPM, "BPM should be set to test value")
    
    -- Clear pattern
    sequencer:clearPattern()
    
    -- Verify BPM is unchanged
    luaunit.assertEquals(sequencer.bpm, testBPM, "BPM should be unchanged after clear")
end

function TestClearPattern:testClearButtonUIPosition()
    -- Test that clear button is positioned correctly between RESET and EXPORT
    local playX = 200
    local stopX = playX + ui.buttonWidth + 10
    local resetX = stopX + ui.buttonWidth + 10
    local clearX = resetX + ui.buttonWidth + 10
    local exportX = clearX + ui.buttonWidth + 10
    
    -- Verify button positions make sense
    luaunit.assertTrue(clearX > resetX, "Clear button should be to the right of reset button")
    luaunit.assertTrue(exportX > clearX, "Export button should be to the right of clear button")
    luaunit.assertEquals(clearX - resetX, ui.buttonWidth + 10, "Clear button should have proper spacing from reset")
    luaunit.assertEquals(exportX - clearX, ui.buttonWidth + 10, "Export button should have proper spacing from clear")
end

function TestClearPattern:testClearButtonMouseClick()
    -- Calculate clear button position (same as in UI code)
    local playX = 200
    local stopX = playX + ui.buttonWidth + 10
    local resetX = stopX + ui.buttonWidth + 10
    local clearX = resetX + ui.buttonWidth + 10
    
    -- Create test pattern
    sequencer.pattern[1][1] = true
    sequencer.pattern[2][2] = true
    
    -- Verify pattern has active steps
    luaunit.assertTrue(sequencer.pattern[1][1], "Should have active step before clear")
    luaunit.assertTrue(sequencer.pattern[2][2], "Should have active step before clear")
    
    -- Simulate clicking on clear button
    ui:mousepressed(clearX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    
    -- Verify button click was registered
    luaunit.assertEquals(ui.clickedButton, "CLEAR", "Clear button should be registered as clicked")
    
    -- Verify pattern was cleared
    luaunit.assertFalse(sequencer.pattern[1][1], "Step should be cleared after button click")
    luaunit.assertFalse(sequencer.pattern[2][2], "Step should be cleared after button click")
end

function TestClearPattern:testClearButtonNoInterferenceWithOtherButtons()
    -- Test that clear button doesn't interfere with other transport buttons
    
    -- Test play button still works
    local playX = 200
    ui:mousepressed(playX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    luaunit.assertEquals(ui.clickedButton, "PLAY", "Play button should work independently")
    luaunit.assertTrue(sequencer.isPlaying, "Play should start playback")
    
    -- Reset clicked button state
    ui.clickedButton = nil
    sequencer:stop()
    
    -- Test stop button still works
    sequencer:play()  -- Start again
    local stopX = playX + ui.buttonWidth + 10
    ui:mousepressed(stopX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    luaunit.assertEquals(ui.clickedButton, "STOP", "Stop button should work independently")
    luaunit.assertFalse(sequencer.isPlaying, "Stop should halt playback")
    
    -- Reset clicked button state
    ui.clickedButton = nil
    
    -- Test reset button still works
    sequencer.currentStep = 8  -- Set to middle of pattern
    local resetX = stopX + ui.buttonWidth + 10
    ui:mousepressed(resetX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    luaunit.assertEquals(ui.clickedButton, "RESET", "Reset button should work independently")
    luaunit.assertEquals(sequencer.currentStep, 1, "Reset should return to step 1")
end

function TestClearPattern:testClearButtonWithActivePlayback()
    -- Test clearing pattern while sequencer is playing
    sequencer:play()
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should be playing")
    
    -- Set current step to somewhere in the middle
    sequencer.currentStep = 5
    
    -- Create test pattern
    sequencer.pattern[1][5] = true  -- Active step at current position
    sequencer.pattern[2][10] = true  -- Active step at future position
    
    -- Clear pattern via button click
    local clearX = 200 + 3 * (ui.buttonWidth + 10)  -- Position calculation
    ui:mousepressed(clearX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    
    -- Verify playback continues but pattern is cleared
    luaunit.assertTrue(sequencer.isPlaying, "Playback should continue after clear")
    luaunit.assertEquals(sequencer.currentStep, 5, "Current step should be unchanged")
    luaunit.assertFalse(sequencer.pattern[1][5], "Pattern should be cleared")
    luaunit.assertFalse(sequencer.pattern[2][10], "Pattern should be cleared")
end

function TestClearPattern:testClearPatternPreservesEmptyPattern()
    -- Test clearing an already empty pattern (should not cause errors)
    
    -- First, clear the pattern to ensure it's empty
    sequencer:clearPattern()
    
    -- Verify it's empty
    for track = 1, 8 do
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step], 
                               string.format("Track %d step %d should be inactive", track, step))
        end
    end
    
    -- Clear again (should not cause any issues)
    sequencer:clearPattern()
    
    -- Verify it's still empty
    for track = 1, 8 do
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step], 
                               string.format("Track %d step %d should still be inactive", track, step))
        end
    end
end

function TestClearPattern:testClearPatternBoundaryConditions()
    -- Test that clear pattern works correctly with edge cases
    
    -- Fill entire pattern (all tracks, all steps)
    for track = 1, 8 do
        for step = 1, 16 do
            sequencer.pattern[track][step] = true
        end
    end
    
    -- Verify pattern is completely full
    local activeCount = 0
    for track = 1, 8 do
        for step = 1, 16 do
            if sequencer.pattern[track][step] then
                activeCount = activeCount + 1
            end
        end
    end
    luaunit.assertEquals(activeCount, 8 * 16, "Pattern should be completely full")
    
    -- Clear the full pattern
    sequencer:clearPattern()
    
    -- Verify pattern is completely empty
    activeCount = 0
    for track = 1, 8 do
        for step = 1, 16 do
            if sequencer.pattern[track][step] then
                activeCount = activeCount + 1
            end
        end
    end
    luaunit.assertEquals(activeCount, 0, "Pattern should be completely empty after clear")
end

function TestClearPattern:testClearButtonVisualFeedback()
    -- Test that clear button provides appropriate visual feedback
    
    -- Initially no button should be clicked
    luaunit.assertNil(ui.clickedButton, "No button should be clicked initially")
    
    -- Simulate clicking clear button
    local clearX = 200 + 3 * (ui.buttonWidth + 10)  -- Position calculation
    ui:mousepressed(clearX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    
    -- Verify button click state is registered
    luaunit.assertEquals(ui.clickedButton, "CLEAR", "Clear button should be in clicked state")
    
    -- Simulate mouse release (would normally be called by Love2D)
    ui:mousereleased(clearX + ui.buttonWidth/2, ui.transportY + ui.buttonHeight/2)
    
    -- Verify button click state is cleared
    luaunit.assertNil(ui.clickedButton, "Button click state should be cleared after release")
end

return TestClearPattern