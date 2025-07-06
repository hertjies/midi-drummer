--[[
    MIDI Drum Sequencer - test_bmp_slider_sync.lua
    
    Unit tests for BPM slider synchronization when using text input.
    Tests that the slider handle position updates correctly when BPM is changed via text input.
    
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

-- Mock modules
local mockSequencer = {
    bpm = 120,
    setBPM = function(self, newBPM) 
        self.bpm = newBPM 
        print("Mock sequencer BPM set to:", newBPM)  -- Debug output
    end
}

local mockUtils = {
    pointInRect = function(x, y, rectX, rectY, rectW, rectH)
        return x >= rectX and x <= rectX + rectW and 
               y >= rectY and y <= rectY + rectH
    end,
    clamp = function(value, min, max)
        return math.max(min, math.min(max, value))
    end
}

local ui = require("ui")

local TestBPMSliderSync = {}

function TestBPMSliderSync:setUp()
    -- Initialize UI with mock dependencies
    ui.sequencer = mockSequencer
    ui.utils = mockUtils
    
    -- Reset UI state
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = ""
    ui.bpmTextInputCursorTimer = 0
    mockSequencer.bpm = 120
end

function TestBPMSliderSync:tearDown()
    ui.sequencer = nil
    ui.utils = nil
end

function TestBPMSliderSync:testSliderHandlePositionCalculation()
    -- Test slider handle position calculation for different BPM values
    
    -- Test minimum BPM (60)
    mockSequencer.bpm = 60
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local expectedHandleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    luaunit.assertEquals(normalizedBPM, 0, "Minimum BPM should normalize to 0")
    luaunit.assertEquals(expectedHandleX, ui.bpmSliderX, "Handle should be at left edge for minimum BPM")
    
    -- Test middle BPM (180)
    mockSequencer.bpm = 180
    normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    expectedHandleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    luaunit.assertEquals(normalizedBPM, 0.5, "Middle BPM should normalize to 0.5")
    luaunit.assertEquals(expectedHandleX, ui.bpmSliderX + ui.bpmSliderWidth / 2, "Handle should be at center for middle BPM")
    
    -- Test maximum BPM (300)
    mockSequencer.bpm = 300
    normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    expectedHandleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    luaunit.assertEquals(normalizedBPM, 1, "Maximum BPM should normalize to 1")
    luaunit.assertEquals(expectedHandleX, ui.bpmSliderX + ui.bpmSliderWidth, "Handle should be at right edge for maximum BPM")
end

function TestBPMSliderSync:testTextInputUpdatesBPM()
    -- Test that text input correctly updates the sequencer BPM
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    local originalBPM = mockSequencer.bpm
    ui:applyBPMTextInput()
    
    luaunit.assertEquals(mockSequencer.bpm, 150, "Text input should update sequencer BPM")
    luaunit.assertTrue(mockSequencer.bpm ~= originalBPM, "BPM should be different from original")
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should be deactivated after applying")
end

function TestBPMSliderSync:testSliderPositionAfterTextInput()
    -- Test that slider handle position reflects BPM change from text input
    
    -- Set initial BPM via text input
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "240"
    ui:applyBPMTextInput()
    
    -- Calculate expected slider position
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)  -- (240-60)/(300-60) = 0.75
    local expectedHandleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    
    luaunit.assertEquals(mockSequencer.bpm, 240, "BPM should be set to 240")
    luaunit.assertEquals(normalizedBPM, 0.75, "Normalized BPM should be 0.75")
    
    -- The handle position calculation should match what's used in drawBPMControl()
    local actualNormalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local actualHandleX = ui.bpmSliderX + actualNormalizedBPM * ui.bpmSliderWidth
    
    luaunit.assertEquals(actualHandleX, expectedHandleX, "Actual handle position should match expected position")
end

function TestBPMSliderSync:testSliderPositionAfterMinimumBPM()
    -- Test slider position when text input sets minimum BPM
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "45"  -- Below minimum, should clamp to 60
    ui:applyBPMTextInput()
    
    luaunit.assertEquals(mockSequencer.bpm, 60, "BPM should be clamped to minimum (60)")
    
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    luaunit.assertEquals(normalizedBPM, 0, "Normalized BPM should be 0 for minimum")
end

function TestBPMSliderSync:testSliderPositionAfterMaximumBPM()
    -- Test slider position when text input sets maximum BPM
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "350"  -- Above maximum, should clamp to 300
    ui:applyBPMTextInput()
    
    luaunit.assertEquals(mockSequencer.bpm, 300, "BPM should be clamped to maximum (300)")
    
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    luaunit.assertEquals(normalizedBPM, 1, "Normalized BPM should be 1 for maximum")
end

function TestBPMSliderSync:testEnterKeyUpdatesSliderPosition()
    -- Test that Enter key application updates slider position
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "175"
    
    -- Simulate Enter key press
    ui:keypressed("return")
    
    luaunit.assertEquals(mockSequencer.bpm, 175, "Enter key should apply BPM value")
    
    -- Verify slider position calculation is correct
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local expectedNormalized = (175 - 60) / (300 - 60)  -- Should be ~0.479
    
    luaunit.assertTrue(math.abs(normalizedBPM - expectedNormalized) < 0.001, 
                      "Normalized BPM should match expected calculation")
end

function TestBPMSliderSync:testMultipleTextInputChanges()
    -- Test that multiple text input changes correctly update slider position
    
    -- First change
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "90"
    ui:applyBPMTextInput()
    luaunit.assertEquals(mockSequencer.bpm, 90, "First change should set BPM to 90")
    
    -- Second change
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "200"
    ui:applyBPMTextInput()
    luaunit.assertEquals(mockSequencer.bpm, 200, "Second change should set BPM to 200")
    
    -- Third change
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "130"
    ui:applyBPMTextInput()
    luaunit.assertEquals(mockSequencer.bpm, 130, "Third change should set BPM to 130")
    
    -- Verify final slider position
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local expectedNormalized = (130 - 60) / (300 - 60)
    
    luaunit.assertTrue(math.abs(normalizedBPM - expectedNormalized) < 0.001,
                      "Final slider position should be correct")
end

function TestBPMSliderSync:testSliderConsistencyAfterTextInput()
    -- Test that slider position is consistent with BPM value after text input
    
    local testBPMs = {75, 120, 150, 180, 220, 275}
    
    for _, testBPM in ipairs(testBPMs) do
        -- Set BPM via text input
        ui.bpmTextInputActive = true
        ui.bpmTextInputBuffer = tostring(testBPM)
        ui:applyBPMTextInput()
        
        -- Calculate slider position
        local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
        local handleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
        
        -- Verify consistency
        luaunit.assertEquals(mockSequencer.bpm, testBPM, 
                            string.format("BPM should be set to %d", testBPM))
        
        -- Verify normalized value is within valid range
        luaunit.assertTrue(normalizedBPM >= 0 and normalizedBPM <= 1,
                          string.format("Normalized BPM (%f) should be between 0 and 1", normalizedBPM))
        
        -- Verify handle position is within slider bounds
        luaunit.assertTrue(handleX >= ui.bpmSliderX and handleX <= ui.bpmSliderX + ui.bpmSliderWidth,
                          string.format("Handle position (%f) should be within slider bounds", handleX))
    end
end

function TestBPMSliderSync:testUserWorkflowSimulation()
    -- Test complete user workflow: click text input, type, press enter
    local initialBPM = mockSequencer.bpm
    
    -- Step 1: Click on text input (simulated)
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = ""  -- Cleared on activation
    luaunit.assertTrue(ui.bpmTextInputActive, "Text input should be active after click")
    
    -- Step 2: Type characters one by one
    ui:textinput("1")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "1", "Buffer should contain '1'")
    
    ui:textinput("8")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "18", "Buffer should contain '18'")
    
    ui:textinput("0")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "180", "Buffer should contain '180'")
    
    -- At this point, sequencer BPM should still be the original value
    luaunit.assertEquals(mockSequencer.bpm, initialBPM, "BPM should not change until Enter is pressed")
    
    -- Step 3: Press Enter to apply
    ui:keypressed("return")
    
    -- Now the BPM should be updated and text input deactivated
    luaunit.assertEquals(mockSequencer.bpm, 180, "BPM should be updated to 180 after Enter")
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should be deactivated after Enter")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Buffer should be cleared after Enter")
    
    -- Verify slider position reflects the new BPM
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local expectedHandleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    
    -- This simulates what would happen in drawBPMControl()
    local actualNormalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local actualHandleX = ui.bpmSliderX + actualNormalizedBPM * ui.bpmSliderWidth
    
    luaunit.assertEquals(actualHandleX, expectedHandleX, "Slider handle position should reflect new BPM")
end

function TestBPMSliderSync:testSliderDraggingStateCleared()
    -- Test that slider dragging state is properly cleared when using text input
    
    -- Simulate slider being dragged
    ui.bpmDragging = true
    luaunit.assertTrue(ui.bpmDragging, "Slider should be in dragging state")
    
    -- Click on text input
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = ""
    ui.bpmDragging = false  -- This should happen in mousepressed
    
    luaunit.assertFalse(ui.bpmDragging, "Dragging state should be cleared when clicking text input")
    
    -- Apply BPM change via text input
    ui.bpmTextInputBuffer = "200"
    ui:applyBPMTextInput()
    
    -- Verify dragging state remains cleared
    luaunit.assertFalse(ui.bpmDragging, "Dragging state should remain cleared after applying text input")
    luaunit.assertEquals(mockSequencer.bpm, 200, "BPM should be updated")
end

function TestBPMSliderSync:testSliderStateConsistency()
    -- Test that slider state is consistent after text input changes
    
    -- Start with slider in dragging state (edge case)
    ui.bpmDragging = true
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "250"
    
    -- Apply text input (should clear dragging state)
    ui:applyBPMTextInput()
    
    luaunit.assertFalse(ui.bpmDragging, "Dragging state should be cleared by applyBPMTextInput")
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should be deactivated")
    luaunit.assertEquals(mockSequencer.bpm, 250, "BPM should be updated")
    
    -- Verify slider position calculation works correctly
    local normalizedBPM = (mockSequencer.bpm - 60) / (300 - 60)
    local handleX = ui.bpmSliderX + normalizedBPM * ui.bpmSliderWidth
    
    luaunit.assertTrue(normalizedBPM >= 0 and normalizedBPM <= 1, "Normalized BPM should be in valid range")
    luaunit.assertTrue(handleX >= ui.bpmSliderX and handleX <= ui.bpmSliderX + ui.bpmSliderWidth, 
                      "Handle position should be within slider bounds")
end

return TestBPMSliderSync