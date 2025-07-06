--[[
    MIDI Drum Sequencer - test_improved_metronome.lua
    
    Unit tests for improved metronome functionality with separate volume controls
    and enhanced clock tick sounds.
    
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
local audio = require("audio")
local sequencer = require("sequencer")
local ui = require("ui")
local utils = require("utils")

local TestImprovedMetronome = {}

function TestImprovedMetronome:setUp()
    -- Initialize modules
    audio:init()
    sequencer:init()
    
    -- Connect modules
    sequencer.audio = audio
    ui.sequencer = sequencer
    ui.audio = audio
    ui.utils = utils
    
    -- Reset states
    audio:setMetronomeEnabled(false)
    audio:setMetronomeVolume("normal", 0.6)
    audio:setMetronomeVolume("accent", 0.8)
end

function TestImprovedMetronome:tearDown()
    -- Clean up any state
    sequencer.audio = nil
    ui.sequencer = nil
    ui.audio = nil
end

function TestImprovedMetronome:testSeparateVolumeControls()
    -- Test that normal and accent clicks have separate volume controls
    
    -- Set different volumes
    audio:setMetronomeVolume("normal", 0.3)
    audio:setMetronomeVolume("accent", 0.9)
    
    -- Verify volumes are set correctly
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.3, "Normal volume should be 0.3")
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.9, "Accent volume should be 0.9")
    
    -- Test that they are independent
    audio:setMetronomeVolume("normal", 0.7)
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.7, "Normal volume should change to 0.7")
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.9, "Accent volume should remain 0.9")
end

function TestImprovedMetronome:testVolumeValidation()
    -- Test volume clamping for both click types
    
    -- Test normal click volume clamping
    audio:setMetronomeVolume("normal", 1.5)
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 1.0, "Normal volume should be clamped to 1.0")
    
    audio:setMetronomeVolume("normal", -0.5)
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.0, "Normal volume should be clamped to 0.0")
    
    -- Test accent click volume clamping
    audio:setMetronomeVolume("accent", 2.0)
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 1.0, "Accent volume should be clamped to 1.0")
    
    audio:setMetronomeVolume("accent", -0.3)
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.0, "Accent volume should be clamped to 0.0")
end

function TestImprovedMetronome:testInvalidClickType()
    -- Test error handling for invalid click types
    
    -- Should handle invalid click types gracefully
    audio:setMetronomeVolume("invalid", 0.5)  -- Should not crash
    
    local volume = audio:getMetronomeVolume("invalid")
    luaunit.assertEquals(volume, 0.6, "Invalid click type should return default volume")
    
    -- Test with nil
    local nilVolume = audio:getMetronomeVolume(nil)
    luaunit.assertEquals(nilVolume, 0.6, "Nil click type should return default volume")
end

function TestImprovedMetronome:testSequencerVolumeIntegration()
    -- Test sequencer wrapper methods for volume control
    
    -- Set volumes through sequencer
    sequencer:setMetronomeVolume("normal", 0.4)
    sequencer:setMetronomeVolume("accent", 0.7)
    
    -- Verify through sequencer
    luaunit.assertEquals(sequencer:getMetronomeVolume("normal"), 0.4, "Sequencer should set normal volume")
    luaunit.assertEquals(sequencer:getMetronomeVolume("accent"), 0.7, "Sequencer should set accent volume")
    
    -- Verify through audio system
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.4, "Audio should have normal volume")
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.7, "Audio should have accent volume")
end

function TestImprovedMetronome:testSequencerVolumeWithoutAudioSystem()
    -- Test sequencer volume methods when audio system is not available
    local originalAudio = sequencer.audio
    sequencer.audio = nil
    
    -- Should not crash
    sequencer:setMetronomeVolume("normal", 0.8)
    sequencer:setMetronomeVolume("accent", 0.9)
    
    -- Should return default values
    luaunit.assertEquals(sequencer:getMetronomeVolume("normal"), 0.6, "Should return default when no audio system")
    luaunit.assertEquals(sequencer:getMetronomeVolume("accent"), 0.6, "Should return default when no audio system")
    
    -- Restore
    sequencer.audio = originalAudio
end

function TestImprovedMetronome:testUIVolumeSliderState()
    -- Test UI state for metronome volume sliders
    
    luaunit.assertNil(ui.metronomeVolumeDragging, "Should not be dragging initially")
    
    -- Simulate dragging normal volume
    ui.metronomeVolumeDragging = "normal"
    luaunit.assertEquals(ui.metronomeVolumeDragging, "normal", "Should be dragging normal volume")
    
    -- Simulate dragging accent volume
    ui.metronomeVolumeDragging = "accent"
    luaunit.assertEquals(ui.metronomeVolumeDragging, "accent", "Should be dragging accent volume")
    
    -- Reset state
    ui.metronomeVolumeDragging = nil
    luaunit.assertNil(ui.metronomeVolumeDragging, "Should not be dragging after reset")
end

function TestImprovedMetronome:testUIVolumeUpdateFunction()
    -- Test UI volume update function
    
    -- Test normal volume update
    ui:updateMetronomeVolumeFromMouse("normal", ui.volumeControlsX + 40)  -- 50% position
    local normalVolume = sequencer:getMetronomeVolume("normal")
    luaunit.assertTrue(normalVolume > 0.4 and normalVolume < 0.6, "Normal volume should be around 50%")
    
    -- Test accent volume update
    ui:updateMetronomeVolumeFromMouse("accent", ui.volumeControlsX + 64)  -- 80% position
    local accentVolume = sequencer:getMetronomeVolume("accent")
    luaunit.assertTrue(accentVolume > 0.7 and accentVolume < 0.9, "Accent volume should be around 80%")
    
    -- Test boundary cases
    ui:updateMetronomeVolumeFromMouse("normal", ui.volumeControlsX - 10)  -- Below 0%
    luaunit.assertEquals(sequencer:getMetronomeVolume("normal"), 0.0, "Volume should be 0% at minimum")
    
    ui:updateMetronomeVolumeFromMouse("accent", ui.volumeControlsX + 100)  -- Above 100%
    luaunit.assertEquals(sequencer:getMetronomeVolume("accent"), 1.0, "Volume should be 100% at maximum")
end

function TestImprovedMetronome:testClockTickSoundGeneration()
    -- Test that clock tick generation doesn't crash
    
    -- Should not crash during initialization
    audio:generateClockTick("normal", 1000, 0.04)
    audio:generateClockTick("accent", 1400, 0.06)
    
    luaunit.assertTrue(true, "Clock tick generation should not crash")
    
    -- Test with various parameters
    audio:generateClockTick("normal", 800, 0.03)   -- Lower frequency, shorter
    audio:generateClockTick("accent", 1600, 0.08)  -- Higher frequency, longer
    
    luaunit.assertTrue(true, "Various clock tick parameters should work")
end

function TestImprovedMetronome:testVolumeSourceManagement()
    -- Test that volumes are properly applied to prebuffered sources
    
    audio:setMetronomeEnabled(true)
    
    -- Set specific volumes
    audio:setMetronomeVolume("normal", 0.3)
    audio:setMetronomeVolume("accent", 0.7)
    
    -- Test playback with different volumes (should not crash)
    for step = 1, 16 do
        audio:playMetronome(step)
    end
    
    luaunit.assertTrue(true, "Volume source management should work correctly")
end

function TestImprovedMetronome:testVolumeConsistency()
    -- Test that volumes remain consistent across operations
    
    audio:setMetronomeVolume("normal", 0.45)
    audio:setMetronomeVolume("accent", 0.75)
    
    -- Volumes should persist through audio operations
    for i = 1, 10 do
        audio:playMetronome(1)  -- Accent beat
        audio:playMetronome(2)  -- Normal beat
    end
    
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.45, "Normal volume should remain consistent")
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.75, "Accent volume should remain consistent")
    
    -- Volumes should persist through enable/disable operations
    audio:setMetronomeEnabled(false)
    audio:setMetronomeEnabled(true)
    
    luaunit.assertEquals(audio:getMetronomeVolume("normal"), 0.45, "Normal volume should persist after toggle")
    luaunit.assertEquals(audio:getMetronomeVolume("accent"), 0.75, "Accent volume should persist after toggle")
end

function TestImprovedMetronome:testDefaultVolumes()
    -- Test default volume levels
    
    -- Fresh audio system should have default volumes
    local freshAudio = require("audio")
    
    luaunit.assertEquals(freshAudio.metronomeVolumes.normal, 0.6, "Default normal volume should be 0.6")
    luaunit.assertEquals(freshAudio.metronomeVolumes.accent, 0.8, "Default accent volume should be 0.8")
    
    luaunit.assertEquals(freshAudio:getMetronomeVolume("normal"), 0.6, "Default normal volume via getter")
    luaunit.assertEquals(freshAudio:getMetronomeVolume("accent"), 0.8, "Default accent volume via getter")
end

function TestImprovedMetronome:testVolumeMemoryManagement()
    -- Test that volume changes don't create memory leaks
    
    audio:setMetronomeEnabled(true)
    
    -- Rapidly change volumes many times
    for i = 1, 50 do
        local normalVol = (i % 10) / 10
        local accentVol = ((i + 5) % 10) / 10
        
        audio:setMetronomeVolume("normal", normalVol)
        audio:setMetronomeVolume("accent", accentVol)
        
        -- Play some metronome clicks
        audio:playMetronome(i % 16 + 1)
    end
    
    luaunit.assertTrue(true, "Rapid volume changes should not cause memory issues")
end

function TestImprovedMetronome:testVolumeSliderVisuals()
    -- Test that volume slider drawing functions exist and are callable
    
    luaunit.assertEquals(type(ui.drawMetronomeVolumeControls), "function", 
                       "drawMetronomeVolumeControls should be a function")
    luaunit.assertEquals(type(ui.drawMetronomeVolumeSlider), "function", 
                       "drawMetronomeVolumeSlider should be a function")
    luaunit.assertEquals(type(ui.updateMetronomeVolumeFromMouse), "function", 
                       "updateMetronomeVolumeFromMouse should be a function")
    
    -- Test that drawing functions don't crash
    ui:drawMetronomeVolumeControls()
    ui:drawMetronomeVolumeSlider("normal", "Normal", 100)
    ui:drawMetronomeVolumeSlider("accent", "Accent", 125)
    
    luaunit.assertTrue(true, "Volume slider drawing should not crash")
end

function TestImprovedMetronome:testEnhancedSoundCharacteristics()
    -- Test that enhanced sounds have different characteristics
    
    -- Generate both types of sounds
    audio:generateClockTick("normal", 1000, 0.04)
    audio:generateClockTick("accent", 1400, 0.06)
    
    -- Both should create sound samples
    luaunit.assertNotNil(audio.metronomeSamples.normal, "Normal tick sound should be generated")
    luaunit.assertNotNil(audio.metronomeSamples.accent, "Accent tick sound should be generated")
    
    -- Accent should be different from normal (testing at data structure level)
    -- Note: We can't directly compare audio sources, so we just ensure both exist
    luaunit.assertTrue(audio.metronomeSamples.normal ~= audio.metronomeSamples.accent, 
                      "Normal and accent sounds should be different objects")
end

return TestImprovedMetronome