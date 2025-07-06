--[[
    MIDI Drum Sequencer - test_audio_phase3.lua
    
    Unit tests for Phase 3 audio functionality.
    Tests audio sample loading, playback, and volume control.
    
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

-- Tests audio loading, playback, and volume control
-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")

-- Mock Love2D audio functions for testing
love = love or {}
love.audio = love.audio or {}
love.sound = love.sound or {}
love.timer = love.timer or {}

-- Mock functions
love.audio.newSource = function(data, type)
    return {
        clone = function() return {
            setVolume = function() end,
            isPlaying = function() return false end,
            stop = function() end
        } end,
        setVolume = function() end,
        isPlaying = function() return false end,
        stop = function() end
    }
end

love.audio.play = function() end

love.sound.newSoundData = function(samples, rate, bits, channels)
    return {
        setSample = function() end
    }
end

love.timer.getTime = function() return 0 end

local audio = require("audio")

local TestAudioPhase3 = {}

function TestAudioPhase3:setUp()
    -- Reset audio state
    audio.samples = {}
    audio.sources = {}
    audio.volumes = {}
    audio.triggerFeedback = {}
    audio:init()
end

function TestAudioPhase3:testInit()
    -- Test that init sets up proper defaults
    luaunit.assertEquals(#audio.volumes, 8)
    luaunit.assertEquals(#audio.triggerFeedback, 8)
    luaunit.assertEquals(#audio.sources, 8)
    
    -- Check default volumes
    for track = 1, 8 do
        luaunit.assertEquals(audio.volumes[track], 0.7)
        luaunit.assertEquals(audio.triggerFeedback[track], 0)
        luaunit.assertNotNil(audio.sources[track])
    end
end

function TestAudioPhase3:testVolumeControl()
    -- Test setting volume
    audio:setVolume(1, 0.5)
    luaunit.assertEquals(audio:getVolume(1), 0.5)
    
    -- Test volume clamping
    audio:setVolume(2, 1.5)  -- Above maximum
    luaunit.assertEquals(audio:getVolume(2), 1.0)
    
    audio:setVolume(3, -0.5)  -- Below minimum
    luaunit.assertEquals(audio:getVolume(3), 0.0)
    
    -- Test invalid track numbers
    audio:setVolume(0, 0.5)   -- Invalid
    audio:setVolume(9, 0.5)   -- Invalid
    luaunit.assertEquals(audio:getVolume(0), 0)
    luaunit.assertEquals(audio:getVolume(9), 0)
end

function TestAudioPhase3:testTrackNames()
    -- Test that all track names are defined
    luaunit.assertEquals(#audio.trackNames, 8)
    
    -- Test specific track names
    luaunit.assertEquals(audio.trackNames[1], "kick")
    luaunit.assertEquals(audio.trackNames[2], "snare")
    luaunit.assertEquals(audio.trackNames[3], "hihat_closed")
    luaunit.assertEquals(audio.trackNames[4], "hihat_open")
    luaunit.assertEquals(audio.trackNames[8], "tom_high")
end

function TestAudioPhase3:testPlaySample()
    -- This should not crash even without real audio files
    local success = pcall(function() 
        audio:playSample(1) 
    end)
    luaunit.assertTrue(success)
    
    -- Test with invalid track numbers
    success = pcall(function() 
        audio:playSample(0)
        audio:playSample(9)
    end)
    luaunit.assertTrue(success)
end

function TestAudioPhase3:testTriggerFeedback()
    -- Initially no feedback
    luaunit.assertFalse(audio:hasTriggerFeedback(1))
    
    -- Play sample should trigger feedback
    audio:playSample(1)
    luaunit.assertTrue(audio:hasTriggerFeedback(1))
    
    -- Update should decrease feedback
    local initialFeedback = audio.triggerFeedback[1]
    audio:update(0.05)
    luaunit.assertTrue(audio.triggerFeedback[1] < initialFeedback)
    
    -- After feedback duration, should be false
    audio.triggerFeedback[1] = 0
    luaunit.assertFalse(audio:hasTriggerFeedback(1))
end

function TestAudioPhase3:testUpdate()
    -- Set some trigger feedback
    audio.triggerFeedback[1] = 0.1
    audio.triggerFeedback[2] = 0.05
    
    -- Update should decrease feedback
    audio:update(0.03)
    luaunit.assertAlmostEquals(audio.triggerFeedback[1], 0.07, 0.001)
    luaunit.assertAlmostEquals(audio.triggerFeedback[2], 0.02, 0.001)
    
    -- Update that exceeds feedback should clamp to 0
    audio:update(0.1)
    luaunit.assertEquals(audio.triggerFeedback[1], 0)
    luaunit.assertEquals(audio.triggerFeedback[2], 0)
end

function TestAudioPhase3:testStopAll()
    -- Should not crash
    local success = pcall(function() 
        audio:stopAll() 
    end)
    luaunit.assertTrue(success)
    
    -- Should clear all source pools
    for track = 1, 8 do
        luaunit.assertEquals(#audio.sources[track], 0)
    end
end

function TestAudioPhase3:testGetStats()
    local stats = audio:getStats()
    
    -- Should return proper structure
    luaunit.assertNotNil(stats.totalSources)
    luaunit.assertNotNil(stats.samplesLoaded)
    
    -- With mocked samples, should have 8 loaded
    luaunit.assertEquals(stats.samplesLoaded, 8)
    luaunit.assertEquals(stats.totalSources, 0)
end

function TestAudioPhase3:testGenerateFallbackSample()
    -- Should not crash when generating samples
    local success = pcall(function()
        for track = 1, 8 do
            audio:generateFallbackSample(track)
        end
    end)
    luaunit.assertTrue(success)
end

function TestAudioPhase3:testLoadSample()
    -- Note: With mocked Love2D, pcall always succeeds, so we test the error handling
    
    -- Test with invalid track number
    local result = audio:loadSample(0, "test.wav")
    luaunit.assertFalse(result)
    
    result = audio:loadSample(9, "test.wav")
    luaunit.assertFalse(result)
    
    -- Test with valid track number (should succeed with mock)
    result = audio:loadSample(1, "test.wav")
    luaunit.assertTrue(result)
end

return TestAudioPhase3