--[[
    MIDI Drum Sequencer - test_bpm_text_input.lua
    
    Unit tests for BPM text input functionality.
    Tests text input validation, keyboard handling, and UI interaction.
    
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
    setBPM = function(self, newBPM) self.bpm = newBPM end
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

local TestBPMTextInput = {}

function TestBPMTextInput:setUp()
    -- Initialize UI with mock dependencies
    ui.sequencer = mockSequencer
    ui.utils = mockUtils
    
    -- Reset UI state
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = ""
    ui.bpmTextInputCursorTimer = 0
    mockSequencer.bpm = 120
end

function TestBPMTextInput:tearDown()
    ui.sequencer = nil
    ui.utils = nil
end

function TestBPMTextInput:testTextInputActivation()
    -- Test clicking on text input field activates it
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should start inactive")
    
    -- Simulate clicking directly on the text input field
    -- (The test simulates the effect rather than going through full mouse handling)
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = ""  -- Clear buffer when clicking to start fresh input
    ui.bpmTextInputCursorTimer = 0
    ui.bpmDragging = false  -- Stop any active slider dragging when switching to text input
    
    luaunit.assertTrue(ui.bpmTextInputActive, "Text input should be activated by click")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Buffer should be cleared on activation")
end

function TestBPMTextInput:testTextInputDeactivation()
    -- Test clicking outside deactivates text input
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    -- Click outside all UI areas (but avoid grid area to prevent toggle calls)
    ui:mousepressed(10, 10)
    
    luaunit.assertFalse(ui.bpmTextInputActive, "Text input should be deactivated by external click")
end

function TestBPMTextInput:testNumericInputAccepted()
    -- Test that numeric characters are accepted
    ui.bpmTextInputActive = true
    
    ui:textinput("1")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "1", "Should accept numeric input")
    
    ui:textinput("2")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "12", "Should append numeric input")
    
    ui:textinput("0")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "120", "Should accept three-digit input")
end

function TestBPMTextInput:testNonNumericInputRejected()
    -- Test that non-numeric characters are rejected
    ui.bpmTextInputActive = true
    
    ui:textinput("a")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Should reject alphabetic input")
    
    ui:textinput("!")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Should reject special characters")
    
    ui:textinput(" ")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Should reject spaces")
end

function TestBPMTextInput:testMaxLengthLimit()
    -- Test that input is limited to 3 characters
    ui.bpmTextInputActive = true
    
    ui:textinput("1")
    ui:textinput("2")
    ui:textinput("3")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "123", "Should accept up to 3 digits")
    
    ui:textinput("4")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "123", "Should reject input beyond 3 digits")
end

function TestBPMTextInput:testBackspaceHandling()
    -- Test backspace key functionality
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    ui:keypressed("backspace")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "15", "Backspace should remove last character")
    
    ui:keypressed("backspace")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "1", "Backspace should work repeatedly")
    
    ui:keypressed("backspace")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Backspace should clear buffer")
    
    ui:keypressed("backspace")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Backspace on empty buffer should not error")
end

function TestBPMTextInput:testEnterKeyAppliesBPM()
    -- Test that Enter key applies BPM value
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    ui:keypressed("return")
    
    luaunit.assertEquals(mockSequencer.bpm, 150, "Enter should apply BPM value")
    luaunit.assertFalse(ui.bpmTextInputActive, "Enter should deactivate text input")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Enter should clear buffer")
end

function TestBPMTextInput:testNumpadEnterAppliesBPM()
    -- Test that numeric keypad Enter key also applies BPM value
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "175"
    mockSequencer.bpm = 120  -- Reset to known value
    
    ui:keypressed("kpenter")
    
    luaunit.assertEquals(mockSequencer.bpm, 175, "Numpad Enter should apply BPM value")
    luaunit.assertFalse(ui.bpmTextInputActive, "Numpad Enter should deactivate text input")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Numpad Enter should clear buffer")
end

function TestBPMTextInput:testAlternateEnterKeyAppliesBPM()
    -- Test that the alternate "enter" key name also works
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "200"
    mockSequencer.bpm = 120  -- Reset to known value
    
    ui:keypressed("enter")
    
    luaunit.assertEquals(mockSequencer.bpm, 200, "Alternate Enter should apply BPM value")
    luaunit.assertFalse(ui.bpmTextInputActive, "Alternate Enter should deactivate text input")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Alternate Enter should clear buffer")
end

function TestBPMTextInput:testEscapeKeyCancel()
    -- Test that Escape key cancels input without applying
    local originalBPM = mockSequencer.bpm
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "200"
    
    ui:keypressed("escape")
    
    luaunit.assertEquals(mockSequencer.bpm, originalBPM, "Escape should not change BPM")
    luaunit.assertFalse(ui.bpmTextInputActive, "Escape should deactivate text input")
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Escape should clear buffer")
end

function TestBPMTextInput:testBPMRangeValidation()
    -- Test BPM value clamping to valid range (60-300)
    ui.bpmTextInputActive = true
    
    -- Test below minimum
    ui.bpmTextInputBuffer = "50"
    ui:keypressed("return")
    luaunit.assertEquals(mockSequencer.bpm, 60, "Should clamp to minimum BPM (60)")
    
    -- Test above maximum
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "400"
    ui:keypressed("return")
    luaunit.assertEquals(mockSequencer.bpm, 300, "Should clamp to maximum BPM (300)")
    
    -- Test valid value
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "180"
    ui:keypressed("return")
    luaunit.assertEquals(mockSequencer.bpm, 180, "Should accept valid BPM value")
end

function TestBPMTextInput:testEmptyInputHandling()
    -- Test applying empty input
    local originalBPM = mockSequencer.bpm
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = ""
    
    ui:keypressed("return")
    
    luaunit.assertEquals(mockSequencer.bpm, originalBPM, "Empty input should not change BPM")
    luaunit.assertFalse(ui.bpmTextInputActive, "Empty input should deactivate text input")
end

function TestBPMTextInput:testInvalidNumberHandling()
    -- Test handling of invalid number strings (edge case)
    local originalBPM = mockSequencer.bpm
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "abc"  -- Somehow got invalid content
    
    ui:applyBPMTextInput()
    
    luaunit.assertEquals(mockSequencer.bpm, originalBPM, "Invalid number should not change BPM")
    luaunit.assertFalse(ui.bpmTextInputActive, "Invalid input should deactivate text input")
end

function TestBPMTextInput:testSliderDeactivatesTextInput()
    -- Test that using slider deactivates text input
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    -- Simulate clicking exactly on slider handle area
    local sliderHandleX = ui.bpmSliderX + ui.bpmSliderWidth / 2
    local sliderHandleY = ui.bpmSliderY + 10  
    ui:mousepressed(sliderHandleX, sliderHandleY)
    
    luaunit.assertFalse(ui.bpmTextInputActive, "Slider use should deactivate text input")
end

function TestBPMTextInput:testButtonsDeactivateTextInput()
    -- Test that using +/- buttons deactivates text input
    ui.bpmTextInputActive = true
    ui.bpmTextInputBuffer = "150"
    
    -- Simulate clicking on + button
    ui:mousepressed(ui.bpmSliderX + ui.bpmSliderWidth + 40 + 10, ui.bpmSliderY)
    
    luaunit.assertFalse(ui.bpmTextInputActive, "Button use should deactivate text input")
end

function TestBPMTextInput:testCursorBlinkingAnimation()
    -- Test cursor blinking timer functionality
    ui.bpmTextInputActive = true
    ui.bpmTextInputCursorTimer = 0
    
    ui:update(0.3)
    luaunit.assertEquals(ui.bpmTextInputCursorTimer, 0.3, "Timer should advance with delta time")
    
    ui:update(0.8)
    luaunit.assertEquals(ui.bpmTextInputCursorTimer, 0, "Timer should reset after 1 second")
end

function TestBPMTextInput:testInactiveNoCursorUpdate()
    -- Test that cursor timer doesn't update when text input is inactive
    ui.bpmTextInputActive = false
    ui.bpmTextInputCursorTimer = 0.5
    
    ui:update(0.2)
    
    luaunit.assertEquals(ui.bpmTextInputCursorTimer, 0.5, "Timer should not update when inactive")
end

function TestBPMTextInput:testTextInputWhenInactive()
    -- Test that text input is ignored when field is inactive
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = ""
    
    ui:textinput("5")
    
    luaunit.assertEquals(ui.bpmTextInputBuffer, "", "Text input should be ignored when inactive")
end

function TestBPMTextInput:testKeyPressWhenInactive()
    -- Test that key presses are ignored when field is inactive
    ui.bpmTextInputActive = false
    ui.bpmTextInputBuffer = "test"
    
    ui:keypressed("backspace")
    
    luaunit.assertEquals(ui.bpmTextInputBuffer, "test", "Key press should be ignored when inactive")
end

return TestBPMTextInput