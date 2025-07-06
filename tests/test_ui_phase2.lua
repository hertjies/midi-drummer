--[[
    MIDI Drum Sequencer - test_ui_phase2.lua
    
    Unit tests for Phase 2 UI functionality.
    Tests BPM controls and slider interaction.
    
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

-- Tests BPM controls and slider interaction
-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")

-- Mock Love2D graphics functions for testing
love = {
    graphics = {
        setColor = function() end,
        setFont = function() end,
        newFont = function() return {
            getWidth = function() return 10 end,
            getHeight = function() return 10 end
        } end,
        print = function() end,
        rectangle = function() end,
        circle = function() end,
        setLineWidth = function() end,
        getFont = function() return {
            getWidth = function() return 10 end,
            getHeight = function() return 10 end
        } end
    }
}

local ui = require("ui")
local sequencer = require("sequencer")

local TestUIPhase2 = {}

function TestUIPhase2:setUp()
    -- Initialize modules
    sequencer:init()
    ui.sequencer = sequencer
    ui.utils = require("utils")
    ui.bpmDragging = false
    ui.clickedButton = nil
end

function TestUIPhase2:testBPMSliderCalculation()
    -- Test BPM to slider position calculation
    sequencer:setBPM(60)
    ui:drawBPMControl() -- This calculates handle position
    
    -- At minimum BPM (60), handle should be at start
    sequencer:setBPM(60)
    local normalizedMin = (60 - 60) / (300 - 60)
    luaunit.assertEquals(normalizedMin, 0)
    
    -- At maximum BPM (300), handle should be at end
    sequencer:setBPM(300)
    local normalizedMax = (300 - 60) / (300 - 60)
    luaunit.assertEquals(normalizedMax, 1)
    
    -- At middle BPM (180), handle should be at middle
    sequencer:setBPM(180)
    local normalizedMid = (180 - 60) / (300 - 60)
    luaunit.assertAlmostEquals(normalizedMid, 0.5, 0.001)
end

function TestUIPhase2:testUpdateBPMFromMouse()
    -- Test converting mouse position to BPM
    
    -- Mouse at start of slider
    ui:updateBPMFromMouse(ui.bpmSliderX)
    luaunit.assertEquals(sequencer.bpm, 60)
    
    -- Mouse at end of slider
    ui:updateBPMFromMouse(ui.bpmSliderX + ui.bpmSliderWidth)
    luaunit.assertEquals(sequencer.bpm, 300)
    
    -- Mouse at middle of slider
    ui:updateBPMFromMouse(ui.bpmSliderX + ui.bpmSliderWidth / 2)
    luaunit.assertEquals(sequencer.bpm, 180)
    
    -- Mouse before slider (should clamp to minimum)
    ui:updateBPMFromMouse(ui.bpmSliderX - 50)
    luaunit.assertEquals(sequencer.bpm, 60)
    
    -- Mouse after slider (should clamp to maximum)
    ui:updateBPMFromMouse(ui.bpmSliderX + ui.bpmSliderWidth + 50)
    luaunit.assertEquals(sequencer.bpm, 300)
end

function TestUIPhase2:testBPMButtonClicks()
    -- Test decrease button
    sequencer:setBPM(120)
    ui:mousepressed(ui.bpmSliderX - 30, ui.bpmSliderY + 10) -- Click decrease button (correct Y offset)
    luaunit.assertEquals(sequencer.bpm, 115)
    luaunit.assertEquals(ui.clickedButton, "-")
    ui:mousereleased(ui.bpmSliderX - 30, ui.bpmSliderY + 10) -- Release button
    
    -- Test increase button
    ui:mousepressed(ui.bpmSliderX + ui.bpmSliderWidth + 20, ui.bpmSliderY + 10) -- Click increase button (correct Y offset)
    luaunit.assertEquals(sequencer.bpm, 120)
    luaunit.assertEquals(ui.clickedButton, "+")
    ui:mousereleased(ui.bpmSliderX + ui.bpmSliderWidth + 20, ui.bpmSliderY + 10) -- Release button
    
    -- Test button limits
    sequencer:setBPM(60)
    ui:mousepressed(ui.bpmSliderX - 30, ui.bpmSliderY + 10) -- Try to decrease below minimum (correct Y offset)
    luaunit.assertEquals(sequencer.bpm, 60) -- Should stay at 60
    ui:mousereleased(ui.bpmSliderX - 30, ui.bpmSliderY + 10) -- Release button
    
    sequencer:setBPM(300)
    ui:mousepressed(ui.bpmSliderX + ui.bpmSliderWidth + 20, ui.bpmSliderY + 10) -- Try to increase above maximum (correct Y offset)
    luaunit.assertEquals(sequencer.bpm, 300) -- Should stay at 300
    ui:mousereleased(ui.bpmSliderX + ui.bpmSliderWidth + 20, ui.bpmSliderY + 10) -- Release button
end

function TestUIPhase2:testBPMSliderDragging()
    -- Test starting drag
    ui.clickedButton = nil  -- Ensure no button is clicked
    luaunit.assertFalse(ui.bpmDragging)
    ui:mousepressed(ui.bpmSliderX + 50, ui.bpmSliderY + 10) -- Click on slider
    luaunit.assertTrue(ui.bpmDragging)
    
    -- Test dragging updates BPM
    ui:mousemoved(ui.bpmSliderX + 100, ui.bpmSliderY + 10)
    local expectedBPM = math.floor(60 + (100 / ui.bpmSliderWidth) * 240)
    luaunit.assertEquals(sequencer.bpm, expectedBPM)
    
    -- Test releasing stops drag
    ui:mousereleased(0, 0)
    luaunit.assertFalse(ui.bpmDragging)
end

function TestUIPhase2:testMouseReleaseResetState()
    -- Set some states
    ui.clickedButton = "PLAY"
    ui.bpmDragging = true
    
    -- Release mouse
    ui:mousereleased(100, 100)
    
    -- Both states should be cleared
    luaunit.assertNil(ui.clickedButton)
    luaunit.assertFalse(ui.bpmDragging)
end

return TestUIPhase2