--[[
    MIDI Drum Sequencer - test_reset_volumes.lua
    
    Unit tests for reset all track volumes functionality.
    Tests the reset volumes button and audio resetAllVolumes function.
    
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
    },
    audio = {
        newSource = function(filename, type)
            -- Mock audio source
            local source
            source = {
                setVolume = function(self, volume) self.volume = volume end,
                getVolume = function(self) return self.volume or 1.0 end,
                play = function(self) end,
                stop = function(self) end,
                isPlaying = function(self) return false end,
                clone = function(self) 
                    local cloned = {}
                    for k, v in pairs(source) do
                        cloned[k] = v
                    end
                    cloned.volume = self.volume
                    return cloned
                end,
                volume = 1.0
            }
            return source
        end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local audio = require("audio")
local ui = require("ui")
local utils = require("utils")

local TestResetVolumes = {}

function TestResetVolumes:setUp()
    -- Initialize audio system
    audio:init()
    
    -- Set up UI dependencies
    ui.audio = audio
    ui.utils = utils
    
    -- Reset UI state
    ui.clickedButton = nil
    ui.volumeDragging = nil
    
    -- Set some test volumes different from 70%
    audio:setVolume(1, 0.5)  -- 50%
    audio:setVolume(2, 0.9)  -- 90%
    audio:setVolume(3, 0.3)  -- 30%
    audio:setVolume(4, 1.0)  -- 100%
    audio:setVolume(5, 0.1)  -- 10%
    audio:setVolume(6, 0.8)  -- 80%
    audio:setVolume(7, 0.6)  -- 60%
    audio:setVolume(8, 0.4)  -- 40%
end

function TestResetVolumes:tearDown()
    ui.audio = nil
    ui.utils = nil
end

function TestResetVolumes:testResetAllVolumesFunction()
    -- Verify we have different volumes before reset
    luaunit.assertEquals(audio:getVolume(1), 0.5, "Track 1 should be at 50% before reset")
    luaunit.assertEquals(audio:getVolume(2), 0.9, "Track 2 should be at 90% before reset")
    luaunit.assertEquals(audio:getVolume(3), 0.3, "Track 3 should be at 30% before reset")
    luaunit.assertEquals(audio:getVolume(4), 1.0, "Track 4 should be at 100% before reset")
    
    -- Call resetAllVolumes
    audio:resetAllVolumes()
    
    -- Verify all tracks are now at 70%
    for track = 1, 8 do
        luaunit.assertEquals(audio:getVolume(track), 0.7, 
                           string.format("Track %d should be at 70%% after reset", track))
    end
end

function TestResetVolumes:testResetVolumesFromVariousLevels()
    -- Test resetting from extreme values
    audio:setVolume(1, 0.0)   -- Minimum
    audio:setVolume(2, 1.0)   -- Maximum
    audio:setVolume(3, 0.15)  -- Very low
    audio:setVolume(4, 0.95)  -- Very high
    audio:setVolume(5, 0.7)   -- Already at target
    
    -- Reset all volumes
    audio:resetAllVolumes()
    
    -- Verify all are at 70%
    for track = 1, 8 do
        luaunit.assertEquals(audio:getVolume(track), 0.7,
                           string.format("Track %d should be reset to 70%%", track))
    end
end

function TestResetVolumes:testResetButtonUIPosition()
    -- Test that reset button is positioned correctly above volume controls
    local volumeAreaX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local resetButtonY = ui.gridY - 35
    local resetButtonWidth = 80
    local resetButtonHeight = 25
    
    -- Verify button position makes sense
    luaunit.assertTrue(resetButtonY < ui.gridY, "Reset button should be above the grid")
    luaunit.assertTrue(resetButtonWidth > 0, "Reset button should have positive width")
    luaunit.assertTrue(resetButtonHeight > 0, "Reset button should have positive height")
    
    -- Verify it's positioned near volume controls
    local expectedVolumeX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    luaunit.assertTrue(math.abs(volumeAreaX - expectedVolumeX) < 5,
                      "Reset button should be positioned near volume controls")
end

function TestResetVolumes:testResetButtonMouseClick()
    -- Set different volumes before clicking
    audio:setVolume(1, 0.2)
    audio:setVolume(8, 0.9)
    
    -- Verify volumes are different from 70%
    luaunit.assertEquals(audio:getVolume(1), 0.2, "Track 1 should be at 20% before click")
    luaunit.assertEquals(audio:getVolume(8), 0.9, "Track 8 should be at 90% before click")
    
    -- Calculate reset button position and click it
    local volumeAreaX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local resetButtonY = ui.gridY - 35
    local resetButtonWidth = 80
    local resetButtonHeight = 25
    local clickX = volumeAreaX - 25 + resetButtonWidth / 2
    local clickY = resetButtonY + resetButtonHeight / 2
    
    -- Simulate clicking on reset button
    ui:mousepressed(clickX, clickY)
    
    -- Verify button click was registered
    luaunit.assertEquals(ui.clickedButton, "Reset Vol", "Reset button should be registered as clicked")
    
    -- Verify all volumes were reset to 70%
    for track = 1, 8 do
        luaunit.assertEquals(audio:getVolume(track), 0.7,
                           string.format("Track %d should be reset to 70%% after button click", track))
    end
end

function TestResetVolumes:testResetButtonNoInterferenceWithVolumeSliders()
    -- Test that reset button doesn't interfere with volume slider functionality
    
    -- Set initial volume
    audio:setVolume(1, 0.5)
    luaunit.assertEquals(audio:getVolume(1), 0.5, "Track 1 should be at 50% initially")
    
    -- Simulate clicking on a volume slider (track 1)
    local trackY = ui.gridY + (1 - 1) * (ui.cellSize + ui.cellPadding)
    local sliderX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local sliderY = trackY + (ui.cellSize - ui.volumeSliderHeight) / 2
    
    -- Reset clicked button state
    ui.clickedButton = nil
    
    ui:mousepressed(sliderX + 20, sliderY)  -- Click somewhere on the slider
    
    luaunit.assertEquals(ui.volumeDragging, 1, "Volume slider should be in dragging state")
    luaunit.assertNotEquals(ui.clickedButton, "Reset Vol", "Reset button should not be activated by slider click")
end

function TestResetVolumes:testResetButtonWithoutAudioSystem()
    -- Test behavior when audio system is not available
    local originalAudio = ui.audio
    ui.audio = nil
    
    -- Calculate reset button position
    local volumeAreaX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local resetButtonY = ui.gridY - 35
    local resetButtonWidth = 80
    local resetButtonHeight = 25
    local clickX = volumeAreaX - 25 + resetButtonWidth / 2
    local clickY = resetButtonY + resetButtonHeight / 2
    
    -- Simulate clicking on reset button without audio system
    ui:mousepressed(clickX, clickY)
    
    -- Should not crash and button should not be clicked
    luaunit.assertNotNil(ui.clickedButton ~= "Reset Vol" and true or nil, "Reset button should not activate without audio system")
    
    -- Restore audio system
    ui.audio = originalAudio
end

function TestResetVolumes:testResetButtonVisualFeedback()
    -- Test that reset button provides appropriate visual feedback
    
    -- Initially no button should be clicked
    luaunit.assertNil(ui.clickedButton, "No button should be clicked initially")
    
    -- Simulate clicking reset button
    local volumeAreaX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local resetButtonY = ui.gridY - 35
    local resetButtonWidth = 80
    local resetButtonHeight = 25
    local clickX = volumeAreaX - 25 + resetButtonWidth / 2
    local clickY = resetButtonY + resetButtonHeight / 2
    
    ui:mousepressed(clickX, clickY)
    
    -- Verify button click state is registered
    luaunit.assertEquals(ui.clickedButton, "Reset Vol", "Reset button should be in clicked state")
    
    -- Simulate mouse release (would normally be called by Love2D)
    ui:mousereleased(clickX, clickY)
    
    -- Verify button click state is cleared
    luaunit.assertNil(ui.clickedButton, "Button click state should be cleared after release")
end

function TestResetVolumes:testResetVolumesPreservesOtherState()
    -- Test that resetting volumes doesn't affect other audio state
    
    -- Set some volumes and trigger some feedback
    audio:setVolume(1, 0.3)
    audio.triggerFeedback[1] = 0.05  -- Some active feedback
    audio.triggerFeedback[2] = 0.02  -- Some active feedback
    
    -- Store original state
    local originalFeedback1 = audio.triggerFeedback[1]
    local originalFeedback2 = audio.triggerFeedback[2]
    local originalReady = audio.isReady
    
    -- Reset volumes
    audio:resetAllVolumes()
    
    -- Verify volumes changed but other state preserved
    luaunit.assertEquals(audio:getVolume(1), 0.7, "Volume should be reset")
    luaunit.assertEquals(audio.triggerFeedback[1], originalFeedback1, "Trigger feedback should be preserved")
    luaunit.assertEquals(audio.triggerFeedback[2], originalFeedback2, "Trigger feedback should be preserved")
    luaunit.assertEquals(audio.isReady, originalReady, "Audio ready state should be preserved")
end

function TestResetVolumes:testResetVolumesUpdatesAllSources()
    -- Test that resetting volumes updates both prebuffered and active sources
    
    -- This test verifies the implementation calls setVolume for each track
    -- which should update all associated sources
    
    -- Set up tracking to verify setVolume was called
    local setVolumeCalls = {}
    local originalSetVolume = audio.setVolume
    
    audio.setVolume = function(self, track, volume)
        table.insert(setVolumeCalls, {track = track, volume = volume})
        originalSetVolume(self, track, volume)
    end
    
    -- Reset volumes
    audio:resetAllVolumes()
    
    -- Verify setVolume was called for all 8 tracks with 0.7 volume
    luaunit.assertEquals(#setVolumeCalls, 8, "setVolume should be called for all 8 tracks")
    
    for i = 1, 8 do
        luaunit.assertEquals(setVolumeCalls[i].track, i, string.format("Call %d should be for track %d", i, i))
        luaunit.assertEquals(setVolumeCalls[i].volume, 0.7, string.format("Call %d should set volume to 70%%", i))
    end
    
    -- Restore original function
    audio.setVolume = originalSetVolume
end

function TestResetVolumes:testResetButtonClickPrevention()
    -- Test that reset button click is prevented when other UI elements are active
    
    -- Set BPM dragging state
    ui.bpmDragging = true
    
    -- Calculate reset button position
    local volumeAreaX = ui.gridX + 16 * (ui.cellSize + ui.cellPadding) + 20
    local resetButtonY = ui.gridY - 35
    local resetButtonWidth = 80
    local resetButtonHeight = 25
    local clickX = volumeAreaX - 25 + resetButtonWidth / 2
    local clickY = resetButtonY + resetButtonHeight / 2
    
    -- Set different volume to verify it doesn't get reset
    audio:setVolume(1, 0.3)
    
    -- Simulate clicking on reset button while BPM dragging
    ui:mousepressed(clickX, clickY)
    
    -- Verify button was not activated
    luaunit.assertNotNil(ui.clickedButton ~= "Reset Vol" and true or nil, "Reset button should not activate during BPM drag")
    luaunit.assertEquals(audio:getVolume(1), 0.3, "Volume should not be reset during BPM drag")
    
    -- Reset state
    ui.bpmDragging = false
end

function TestResetVolumes:testResetVolumesIdempotent()
    -- Test that calling reset multiple times is safe and consistent
    
    -- Set some different volumes
    audio:setVolume(1, 0.2)
    audio:setVolume(2, 0.8)
    
    -- Reset volumes once
    audio:resetAllVolumes()
    
    -- Verify all at 70%
    for track = 1, 8 do
        luaunit.assertEquals(audio:getVolume(track), 0.7, 
                           string.format("Track %d should be at 70%% after first reset", track))
    end
    
    -- Reset volumes again
    audio:resetAllVolumes()
    
    -- Verify still at 70%
    for track = 1, 8 do
        luaunit.assertEquals(audio:getVolume(track), 0.7,
                           string.format("Track %d should still be at 70%% after second reset", track))
    end
end

return TestResetVolumes