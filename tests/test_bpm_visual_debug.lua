--[[
    MIDI Drum Sequencer - test_bpm_visual_debug.lua
    
    Debug tests to diagnose BPM slider visual update issues.
    
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
        print(string.format("DEBUG: Setting BPM from %d to %d", self.bpm, newBPM))
        self.bpm = newBPM 
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

local TestBPMVisualDebug = {}

function TestBPMVisualDebug:setUp()
    -- Initialize UI with mock dependencies
    ui.sequencer = mockSequencer
    ui.utils = mockUtils
    
    -- Reset UI state
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = ""
    ui.bpmTextInputCursorTimer = 0
    mockSequencer.bpm = 120
    
    print("DEBUG: Test setup complete - BPM:", mockSequencer.bpm)
end

function TestBPMVisualDebug:tearDown()
    ui.sequencer = nil
    ui.utils = nil
end

function TestBPMVisualDebug:testDetailedSliderPositionChange()
    -- Test with detailed output to understand slider behavior
    print("\n=== DETAILED SLIDER POSITION TEST ===")
    
    -- Initial state
    local initialBPM = mockSequencer.bpm
    local initialNormalized = (initialBPM - 60) / (300 - 60)
    local initialHandleX = ui.bpmSliderX + initialNormalized * ui.bpmSliderWidth
    
    print(string.format("Initial state:"))
    print(string.format("  BPM: %d", initialBPM))
    print(string.format("  Normalized: %.3f", initialNormalized))
    print(string.format("  Handle X: %.2f (slider starts at %.2f, width %.2f)", 
                       initialHandleX, ui.bpmSliderX, ui.bpmSliderWidth))
    
    -- Simulate text input change
    print("\nSimulating text input change to 200...")
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "200"
    
    print(string.format("Before applying text input:"))
    print(string.format("  Text input active: %s", tostring(ui.bpmTextInputActive)))
    print(string.format("  Text input buffer: '%s'", ui.bpmTextInputBuffer))
    print(string.format("  Sequencer BPM: %d", mockSequencer.bpm))
    
    -- Apply the change
    ui:applyBPMTextInput()
    
    -- Check new state
    local newBPM = mockSequencer.bpm
    local newNormalized = (newBPM - 60) / (300 - 60)
    local newHandleX = ui.bpmSliderX + newNormalized * ui.bpmSliderWidth
    
    print(string.format("\nAfter applying text input:"))
    print(string.format("  BPM: %d", newBPM))
    print(string.format("  Normalized: %.3f", newNormalized))
    print(string.format("  Handle X: %.2f", newHandleX))
    print(string.format("  Text input active: %s", tostring(ui.bpmTextInputActive)))
    print(string.format("  Text input buffer: '%s'", ui.bpmTextInputBuffer))
    
    -- Calculate change
    local bpmChange = newBPM - initialBPM
    local handleXChange = newHandleX - initialHandleX
    
    print(string.format("\nChanges:"))
    print(string.format("  BPM change: %+d", bpmChange))
    print(string.format("  Handle X change: %+.2f pixels", handleXChange))
    
    -- Verify the change is significant enough to be visible
    luaunit.assertTrue(math.abs(bpmChange) > 0, "BPM should have changed")
    luaunit.assertTrue(math.abs(handleXChange) > 1, "Handle position should change by at least 1 pixel")
    
    print("=== TEST COMPLETE ===\n")
end

function TestBPMVisualDebug:testTextDisplayBehavior()
    -- Test the text display behavior in detail
    print("\n=== TEXT DISPLAY BEHAVIOR TEST ===")
    
    -- Initial state - text input inactive
    print("Phase 1: Text input inactive")
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = ""
    mockSequencer.bpm = 120
    
    -- Simulate what would be displayed in the text input field
    local displayText = ui.bpmTextInputBuffer
    if displayText == "" then
        displayText = tostring(mockSequencer.bpm)
    end
    print(string.format("  Text input shows: '%s'", displayText))
    
    -- Activate text input
    print("\nPhase 2: Text input activated (simulating click)")
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = ""  -- Cleared on activation
    
    displayText = ui.bpmTextInputBuffer
    if displayText == "" then
        displayText = tostring(mockSequencer.bpm)
    end
    print(string.format("  Text input shows: '%s' (placeholder)", displayText))
    
    -- User types
    print("\nPhase 3: User types '180'")
    ui.bpmTextInputBuffer = "180"  -- Simulate typing
    
    displayText = ui.bpmTextInputBuffer
    if displayText == "" then
        displayText = tostring(mockSequencer.bpm)
    end
    print(string.format("  Text input shows: '%s'", displayText))
    print(string.format("  Sequencer BPM: %d (unchanged until Enter)", mockSequencer.bpm))
    
    -- User presses Enter
    print("\nPhase 4: User presses Enter")
    ui:keypressed("return")
    
    displayText = ui.bpmTextInputBuffer
    if displayText == "" then
        displayText = tostring(mockSequencer.bpm)
    end
    print(string.format("  Text input shows: '%s' (placeholder after clearing)", displayText))
    print(string.format("  Sequencer BPM: %d (updated)", mockSequencer.bpm))
    print(string.format("  Text input active: %s", tostring(ui.bpmTextInputActive)))
    
    luaunit.assertEquals(mockSequencer.bpm, 180, "BPM should be updated")
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should be deactivated")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Buffer should be cleared")
    
    print("=== TEST COMPLETE ===\n")
end

function TestBPMVisualDebug:testSliderRangeVisualization()
    -- Test slider positions across the full range
    print("\n=== SLIDER RANGE VISUALIZATION ===")
    
    local testValues = {60, 120, 180, 240, 300}
    
    for _, bpm in ipairs(testValues) do
        mockSequencer.bpm = bpm
        local normalized = (bpm - 60) / (300 - 60)
        local handleX = ui.bpmSliderX + normalized * ui.bpmSliderWidth
        local percentageAcrossSlider = (handleX - ui.bpmSliderX) / ui.bpmSliderWidth * 100
        
        print(string.format("BPM %3d: normalized=%.3f, handleX=%6.2f, %5.1f%% across slider", 
                           bpm, normalized, handleX, percentageAcrossSlider))
    end
    
    print("=== TEST COMPLETE ===\n")
end

return TestBPMVisualDebug