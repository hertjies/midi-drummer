--[[
    MIDI Drum Sequencer - test_pattern_dialog_z_order.lua
    
    Unit tests for pattern dialog Z-order (rendering on top of grid).
    Tests that the pattern save/load dialog appears in front of all other UI elements.
    
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
        getTime = function() return os.clock() end,
        getDelta = function() return 0.016 end  -- 60 FPS
    },
    audio = {
        newSource = function(data) 
            local source = {
                setVolume = function() end,
                isPlaying = function() return false end,
                play = function() end,
                stop = function() end
            }
            source.clone = function() 
                return {
                    setVolume = function() end,
                    isPlaying = function() return false end,
                    play = function() end,
                    stop = function() end,
                    clone = function() return source.clone() end
                }
            end
            return source
        end,
        play = function(source) end
    },
    sound = {
        newSoundData = function(samples, sampleRate, bitDepth, channels)
            return {
                setSample = function() end
            }
        end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local ui = require("src.ui")
local sequencer = require("src.sequencer")
local audio = require("src.audio")
local utils = require("src.utils")

local TestPatternDialogZOrder = {}

function TestPatternDialogZOrder:setUp()
    -- Initialize modules
    audio:init()
    sequencer:init()
    
    -- Connect modules
    sequencer.audio = audio
    ui.sequencer = sequencer
    ui.audio = audio
    ui.utils = utils
    
    -- Reset UI state
    ui.patternListVisible = false
    ui.patternDialogMode = "none"
    ui.patternList = {}
end

function TestPatternDialogZOrder:tearDown()
    -- Clean up modules
    sequencer.audio = nil
    ui.sequencer = nil
    ui.audio = nil
    ui.utils = nil
end

function TestPatternDialogZOrder:testDialogNotVisibleByDefault()
    -- Test that dialog is not visible by default
    luaunit.assertFalse(ui.patternListVisible, "Dialog should not be visible by default")
    luaunit.assertEquals(ui.patternDialogMode, "none", "Dialog mode should be none by default")
end

function TestPatternDialogZOrder:testDialogVisibilityControl()
    -- Test dialog visibility control
    ui.patternListVisible = false
    
    -- The draw function should not crash when dialog is not visible
    ui:draw()
    luaunit.assertTrue(true, "Drawing UI without dialog should not crash")
    
    -- Show dialog
    ui.patternListVisible = true
    ui.patternDialogMode = "save"
    
    -- The draw function should not crash when dialog is visible
    ui:draw()
    luaunit.assertTrue(true, "Drawing UI with dialog should not crash")
end

function TestPatternDialogZOrder:testDialogDrawnLastInMainDraw()
    -- Test that pattern dialog is drawn after grid in main draw function
    -- We'll verify this by checking that the main draw function calls the dialog
    -- at the end, ensuring it appears on top of other elements
    
    ui.patternListVisible = true
    ui.patternDialogMode = "save"
    ui.patternList = {"test_pattern"}
    
    -- Mock the individual draw functions to track call order
    local drawOrder = {}
    
    local originalDrawGrid = ui.drawGrid
    local originalDrawPatternSelectionDialog = ui.drawPatternSelectionDialog
    
    ui.drawGrid = function(self)
        table.insert(drawOrder, "drawGrid")
        originalDrawGrid(self)
    end
    
    ui.drawPatternSelectionDialog = function(self)
        table.insert(drawOrder, "drawPatternSelectionDialog")
        originalDrawPatternSelectionDialog(self)
    end
    
    -- Call main draw function
    ui:draw()
    
    -- Restore original functions
    ui.drawGrid = originalDrawGrid
    ui.drawPatternSelectionDialog = originalDrawPatternSelectionDialog
    
    -- Verify that dialog is drawn after grid
    local gridIndex = nil
    local dialogIndex = nil
    
    for i, funcName in ipairs(drawOrder) do
        if funcName == "drawGrid" then
            gridIndex = i
        elseif funcName == "drawPatternSelectionDialog" then
            dialogIndex = i
        end
    end
    
    luaunit.assertNotNil(gridIndex, "Grid should be drawn")
    luaunit.assertNotNil(dialogIndex, "Dialog should be drawn")
    luaunit.assertTrue(dialogIndex > gridIndex, "Dialog should be drawn after grid to appear on top")
end

function TestPatternDialogZOrder:testDialogNotDrawnWhenNotVisible()
    -- Test that dialog is not drawn when not visible
    ui.patternListVisible = false
    ui.patternDialogMode = "save"
    
    local dialogDrawn = false
    local originalDrawPatternSelectionDialog = ui.drawPatternSelectionDialog
    
    ui.drawPatternSelectionDialog = function(self)
        dialogDrawn = true
        originalDrawPatternSelectionDialog(self)
    end
    
    -- Call main draw function
    ui:draw()
    
    -- Restore original function
    ui.drawPatternSelectionDialog = originalDrawPatternSelectionDialog
    
    luaunit.assertFalse(dialogDrawn, "Dialog should not be drawn when not visible")
end

function TestPatternDialogZOrder:testDialogDrawnWhenVisible()
    -- Test that dialog is drawn when visible
    ui.patternListVisible = true
    ui.patternDialogMode = "save"
    
    local dialogDrawn = false
    local originalDrawPatternSelectionDialog = ui.drawPatternSelectionDialog
    
    ui.drawPatternSelectionDialog = function(self)
        dialogDrawn = true
        originalDrawPatternSelectionDialog(self)
    end
    
    -- Call main draw function
    ui:draw()
    
    -- Restore original function
    ui.drawPatternSelectionDialog = originalDrawPatternSelectionDialog
    
    luaunit.assertTrue(dialogDrawn, "Dialog should be drawn when visible")
end

function TestPatternDialogZOrder:testDialogPositioning()
    -- Test that dialog is positioned in center of screen
    ui.patternListVisible = true
    ui.patternDialogMode = "save"
    ui.patternList = {"pattern1", "pattern2"}
    
    -- The drawPatternSelectionDialog function should position dialog in center
    -- This test verifies the function can be called without errors
    ui:drawPatternSelectionDialog()
    luaunit.assertTrue(true, "Drawing pattern selection dialog should not crash")
end

function TestPatternDialogZOrder:testDialogModeHandling()
    -- Test different dialog modes
    local modes = {"save", "load", "none"}
    
    for _, mode in ipairs(modes) do
        ui.patternDialogMode = mode
        ui.patternListVisible = (mode ~= "none")
        
        -- Should be able to draw without errors regardless of mode
        ui:draw()
        luaunit.assertTrue(true, "Drawing UI in " .. mode .. " mode should not crash")
    end
end

return TestPatternDialogZOrder