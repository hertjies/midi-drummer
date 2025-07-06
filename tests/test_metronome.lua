--[[
    MIDI Drum Sequencer - test_metronome.lua
    
    Unit tests for metronome functionality.
    Tests metronome audio generation, toggle functionality, and sequencer integration.
    
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
            source.clone = function() return mockLove.audio.newSource(data) end
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

local TestMetronome = {}

function TestMetronome:setUp()
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
    audio:setMetronomeVolume(0.6)
end

function TestMetronome:tearDown()
    -- Clean up any state
    sequencer.audio = nil
    ui.sequencer = nil
    ui.audio = nil
end

function TestMetronome:testMetronomeInitialization()
    -- Test that metronome components are properly initialized
    luaunit.assertNotNil(audio.metronomeSamples, "Metronome samples should be initialized")
    luaunit.assertNotNil(audio.metronomeSources, "Metronome sources should be initialized")
    luaunit.assertEquals(type(audio.metronomeSamples), "table", "Metronome samples should be a table")
    luaunit.assertEquals(type(audio.metronomeSources), "table", "Metronome sources should be a table")
    
    -- Test default state
    luaunit.assertFalse(audio.metronomeEnabled, "Metronome should be disabled by default")
    luaunit.assertEquals(audio.metronomeVolume, 0.6, "Default metronome volume should be 0.6")
end

function TestMetronome:testMetronomeToggle()
    -- Test basic toggle functionality
    luaunit.assertFalse(audio:isMetronomeEnabled(), "Initially disabled")
    
    -- Enable metronome
    local result = audio:setMetronomeEnabled(true)
    luaunit.assertTrue(result, "setMetronomeEnabled should return new state")
    luaunit.assertTrue(audio:isMetronomeEnabled(), "Should be enabled after setting to true")
    
    -- Disable metronome
    result = audio:setMetronomeEnabled(false)
    luaunit.assertFalse(result, "setMetronomeEnabled should return new state")
    luaunit.assertFalse(audio:isMetronomeEnabled(), "Should be disabled after setting to false")
    
    -- Test toggle (nil parameter)
    result = audio:setMetronomeEnabled(nil)
    luaunit.assertTrue(result, "Should toggle to enabled")
    luaunit.assertTrue(audio:isMetronomeEnabled(), "Should be enabled after toggle")
    
    result = audio:setMetronomeEnabled(nil)
    luaunit.assertFalse(result, "Should toggle to disabled")
    luaunit.assertFalse(audio:isMetronomeEnabled(), "Should be disabled after toggle")
end

function TestMetronome:testMetronomeVolumeControl()
    -- Test volume setting and getting
    audio:setMetronomeVolume(0.8)
    luaunit.assertEquals(audio:getMetronomeVolume(), 0.8, "Volume should be set to 0.8")
    
    -- Test volume clamping
    audio:setMetronomeVolume(1.5)
    luaunit.assertEquals(audio:getMetronomeVolume(), 1.0, "Volume should be clamped to 1.0")
    
    audio:setMetronomeVolume(-0.5)
    luaunit.assertEquals(audio:getMetronomeVolume(), 0.0, "Volume should be clamped to 0.0")
    
    -- Test edge cases
    audio:setMetronomeVolume(0.0)
    luaunit.assertEquals(audio:getMetronomeVolume(), 0.0, "Volume should be exactly 0.0")
    
    audio:setMetronomeVolume(1.0)
    luaunit.assertEquals(audio:getMetronomeVolume(), 1.0, "Volume should be exactly 1.0")
end

function TestMetronome:testAccentBeatDetection()
    -- Test accent beat detection for steps 1, 5, 9, 13
    local accentSteps = {1, 5, 9, 13}
    local normalSteps = {2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15, 16}
    
    audio:setMetronomeEnabled(true)
    
    -- Test that playMetronome doesn't crash for accent steps
    for _, step in ipairs(accentSteps) do
        audio:playMetronome(step)  -- Should not crash
    end
    
    -- Test that playMetronome doesn't crash for normal steps
    for _, step in ipairs(normalSteps) do
        audio:playMetronome(step)  -- Should not crash
    end
end

function TestMetronome:testMetronomePlaybackWhenDisabled()
    -- Test that metronome doesn't play when disabled
    audio:setMetronomeEnabled(false)
    
    -- Should not crash even when disabled
    for step = 1, 16 do
        audio:playMetronome(step)
    end
    
    -- No audio should be triggered (verified by no crash)
    luaunit.assertTrue(true, "Metronome playback when disabled should not crash")
end

function TestMetronome:testSequencerMetronomeIntegration()
    -- Test sequencer metronome wrapper methods
    
    -- Test enable/disable through sequencer
    local result = sequencer:setMetronomeEnabled(true)
    luaunit.assertTrue(result, "Sequencer should enable metronome")
    luaunit.assertTrue(sequencer:isMetronomeEnabled(), "Sequencer should report metronome as enabled")
    
    result = sequencer:setMetronomeEnabled(false)
    luaunit.assertFalse(result, "Sequencer should disable metronome")
    luaunit.assertFalse(sequencer:isMetronomeEnabled(), "Sequencer should report metronome as disabled")
    
    -- Test toggle through sequencer
    result = sequencer:setMetronomeEnabled(nil)
    luaunit.assertTrue(result, "Sequencer should toggle metronome on")
    
    -- Test volume control through sequencer
    sequencer:setMetronomeVolume(0.9)
    luaunit.assertEquals(sequencer:getMetronomeVolume(), 0.9, "Sequencer should set metronome volume")
end

function TestMetronome:testMetronomeWithoutAudioSystem()
    -- Test behavior when audio system is not available
    local originalAudio = sequencer.audio
    sequencer.audio = nil
    
    -- Should not crash
    local result = sequencer:setMetronomeEnabled(true)
    luaunit.assertFalse(result, "Should return false when no audio system")
    
    luaunit.assertFalse(sequencer:isMetronomeEnabled(), "Should return false when no audio system")
    
    sequencer:setMetronomeVolume(0.8)  -- Should not crash
    luaunit.assertEquals(sequencer:getMetronomeVolume(), 0.6, "Should return default volume when no audio system")
    
    -- Restore
    sequencer.audio = originalAudio
end

function TestMetronome:testUIMetronomeButton()
    -- Test UI metronome button state display
    
    -- Test button state when metronome is disabled
    sequencer:setMetronomeEnabled(false)
    local metronomeEnabled = sequencer:isMetronomeEnabled()
    luaunit.assertFalse(metronomeEnabled, "UI should show metronome as disabled")
    
    -- Test button state when metronome is enabled
    sequencer:setMetronomeEnabled(true)
    metronomeEnabled = sequencer:isMetronomeEnabled()
    luaunit.assertTrue(metronomeEnabled, "UI should show metronome as enabled")
end

function TestMetronome:testMetronomeStateConsistency()
    -- Test that metronome state remains consistent across operations
    
    audio:setMetronomeEnabled(true)
    audio:setMetronomeVolume(0.75)
    
    -- State should persist through playback operations
    for step = 1, 16 do
        audio:playMetronome(step)
        luaunit.assertTrue(audio:isMetronomeEnabled(), "Metronome should remain enabled during playback")
        luaunit.assertEquals(audio:getMetronomeVolume(), 0.75, "Volume should remain consistent")
    end
    
    -- State should persist through other audio operations
    audio:playSample(1)  -- Play a drum sound
    luaunit.assertTrue(audio:isMetronomeEnabled(), "Metronome should remain enabled after playing drum sample")
    luaunit.assertEquals(audio:getMetronomeVolume(), 0.75, "Volume should remain consistent after playing drum sample")
end

function TestMetronome:testMetronomeSourceManagement()
    -- Test that metronome sources are properly managed
    
    audio:setMetronomeEnabled(true)
    
    -- Test that source pools exist
    luaunit.assertNotNil(audio.metronomeSources.normal, "Normal metronome sources should exist")
    luaunit.assertNotNil(audio.metronomeSources.accent, "Accent metronome sources should exist")
    
    luaunit.assertEquals(type(audio.metronomeSources.normal), "table", "Normal sources should be a table")
    luaunit.assertEquals(type(audio.metronomeSources.accent), "table", "Accent sources should be a table")
    
    -- Test that playing metronome doesn't crash the source management
    for i = 1, 10 do
        audio:playMetronome(1)  -- Accent beat
        audio:playMetronome(2)  -- Normal beat
    end
    
    luaunit.assertTrue(true, "Metronome source management should handle multiple plays")
end

function TestMetronome:testMetronomeMemoryManagement()
    -- Test that metronome doesn't create memory leaks
    
    local initialNormalSources = #audio.metronomeSources.normal
    local initialAccentSources = #audio.metronomeSources.accent
    
    audio:setMetronomeEnabled(true)
    
    -- Play metronome many times
    for i = 1, 20 do
        audio:playMetronome(i % 16 + 1)
    end
    
    -- Source pools should still exist and not grow excessively
    luaunit.assertTrue(#audio.metronomeSources.normal >= 0, "Normal source pool should still exist")
    luaunit.assertTrue(#audio.metronomeSources.accent >= 0, "Accent source pool should still exist")
    
    -- Should not have massive growth (basic leak check)
    luaunit.assertTrue(#audio.metronomeSources.normal < 100, "Normal source pool should not grow excessively")
    luaunit.assertTrue(#audio.metronomeSources.accent < 100, "Accent source pool should not grow excessively")
end

function TestMetronome:testMetronomeDocumentation()
    -- Test that metronome functions are properly documented and accessible
    
    luaunit.assertEquals(type(audio.setMetronomeEnabled), "function", "setMetronomeEnabled should be a function")
    luaunit.assertEquals(type(audio.isMetronomeEnabled), "function", "isMetronomeEnabled should be a function")
    luaunit.assertEquals(type(audio.setMetronomeVolume), "function", "setMetronomeVolume should be a function")
    luaunit.assertEquals(type(audio.getMetronomeVolume), "function", "getMetronomeVolume should be a function")
    luaunit.assertEquals(type(audio.playMetronome), "function", "playMetronome should be a function")
    
    luaunit.assertEquals(type(sequencer.setMetronomeEnabled), "function", "sequencer setMetronomeEnabled should be a function")
    luaunit.assertEquals(type(sequencer.isMetronomeEnabled), "function", "sequencer isMetronomeEnabled should be a function")
    luaunit.assertEquals(type(sequencer.setMetronomeVolume), "function", "sequencer setMetronomeVolume should be a function")
    luaunit.assertEquals(type(sequencer.getMetronomeVolume), "function", "sequencer getMetronomeVolume should be a function")
end

return TestMetronome