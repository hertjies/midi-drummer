--[[
    MIDI Drum Sequencer - test_sequencer_audio_readiness.lua
    
    Unit tests for sequencer audio readiness integration.
    Tests sequencer behavior when audio system is/isn't ready.
    
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

-- Mock audio system for testing
local mockAudio = {
    isReady = true,
    systemReady = true,
    initCallCount = 0,
    playCallLog = {},
    
    isSystemReady = function(self)
        return self.systemReady
    end,
    
    getSystemStatus = function(self)
        return {
            isReady = self.isReady,
            isSystemReady = self.systemReady,
            estimatedLatency = 0.005
        }
    end,
    
    init = function(self)
        self.initCallCount = self.initCallCount + 1
        self.isReady = true
        self.systemReady = true
    end,
    
    playSample = function(self, track)
        table.insert(self.playCallLog, {
            track = track,
            time = love.timer and love.timer.getTime() or 0
        })
        return true
    end,
    
    reset = function(self)
        self.isReady = true
        self.systemReady = true
        self.initCallCount = 0
        self.playCallLog = {}
    end
}

-- Mock Love2D timer
love = love or {}
love.timer = love.timer or {
    currentTime = 0,
    getTime = function() return love.timer.currentTime end
}

local sequencer = require("sequencer")

local TestSequencerAudioReadiness = {}

function TestSequencerAudioReadiness:setUp()
    -- Reset mock audio
    mockAudio:reset()
    
    -- Initialize sequencer
    sequencer:init()
    sequencer.audio = mockAudio
    
    -- Set up test pattern
    sequencer.pattern[1][1] = true  -- Kick on step 1
    sequencer.pattern[2][5] = true  -- Snare on step 5
end

function TestSequencerAudioReadiness:tearDown()
    sequencer:stop()
    sequencer.audio = nil
    mockAudio:reset()
end

function TestSequencerAudioReadiness:testPlayWithReadyAudioSystem()
    -- Test normal playback when audio system is ready
    mockAudio.systemReady = true
    
    sequencer:play()
    
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should be playing")
    luaunit.assertEquals(mockAudio.initCallCount, 0, "Should not reinitialize audio when ready")
    luaunit.assertEquals(#mockAudio.playCallLog, 1, "Should trigger audio for step 1")
    luaunit.assertEquals(mockAudio.playCallLog[1].track, 1, "Should play kick on step 1")
end

function TestSequencerAudioReadiness:testPlayWithUnreadyAudioSystem()
    -- Test playback when audio system is not ready
    mockAudio.systemReady = false
    
    sequencer:play()
    
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should still start playing")
    luaunit.assertEquals(mockAudio.initCallCount, 1, "Should attempt to reinitialize audio")
    
    -- After reinitialization, audio should be ready and trigger
    luaunit.assertEquals(#mockAudio.playCallLog, 1, "Should trigger audio after reinitialization")
end

function TestSequencerAudioReadiness:testPlayWithNoAudioSystem()
    -- Test playback when no audio system is connected
    sequencer.audio = nil
    
    sequencer:play()
    
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should still start playing without audio")
    -- No audio calls should be made since there's no audio system
end

function TestSequencerAudioReadiness:testGetAudioStatus()
    -- Test audio status reporting
    local status = sequencer:getAudioStatus()
    
    luaunit.assertNotNil(status, "Should return audio status")
    luaunit.assertTrue(status.hasAudioSystem, "Should indicate audio system is present")
    luaunit.assertTrue(status.isAudioReady, "Should indicate audio is ready")
    luaunit.assertTrue(status.isReady, "Should include detailed status")
    luaunit.assertTrue(status.isSystemReady, "Should include system ready status")
end

function TestSequencerAudioReadiness:testGetAudioStatusWithoutAudio()
    -- Test audio status when no audio system
    sequencer.audio = nil
    
    local status = sequencer:getAudioStatus()
    luaunit.assertNil(status, "Should return nil when no audio system")
end

function TestSequencerAudioReadiness:testAudioReadinessAffectsPlayback()
    -- Test that audio readiness is checked before each play
    mockAudio.systemReady = false
    
    -- First play attempt
    sequencer:play()
    sequencer:stop()
    
    -- Audio system becomes ready
    mockAudio.systemReady = true
    
    -- Second play attempt
    mockAudio.initCallCount = 0  -- Reset counter
    sequencer:play()
    
    luaunit.assertEquals(mockAudio.initCallCount, 0, 
                        "Should not reinitialize when audio is ready")
end

function TestSequencerAudioReadiness:testPlaybackContinuesIfReinitializationFails()
    -- Test that playback continues even if audio reinitialization fails
    mockAudio.systemReady = false
    
    -- Mock reinitialization that doesn't fix the problem
    local originalInit = mockAudio.init
    mockAudio.init = function(self)
        self.initCallCount = self.initCallCount + 1
        -- Don't set systemReady to true (reinitialization fails)
    end
    
    sequencer:play()
    
    luaunit.assertTrue(sequencer.isPlaying, "Sequencer should still play despite audio issues")
    luaunit.assertEquals(mockAudio.initCallCount, 1, "Should attempt reinitialization")
    
    -- Restore original init
    mockAudio.init = originalInit
end

function TestSequencerAudioReadiness:testTimingModePreservedDuringAudioCheck()
    -- Test that timing mode is preserved when checking audio readiness
    sequencer:setTimingMode("frame")
    mockAudio.systemReady = false
    
    sequencer:play()
    
    luaunit.assertEquals(sequencer.timingMode, "frame", 
                        "Timing mode should be preserved during audio check")
end

function TestSequencerAudioReadiness:testClockTimingStartTimeRecorded()
    -- Test that clock timing properly records start time even with audio checks
    sequencer:setTimingMode("clock")
    love.timer.currentTime = 123.456
    
    sequencer:play()
    
    luaunit.assertEquals(sequencer.startTime, 123.456, 
                        "Should record correct start time")
    luaunit.assertEquals(sequencer.timingMode, "clock", 
                        "Should maintain clock timing mode")
end

function TestSequencerAudioReadiness:testFrameTimingResetStepTime()
    -- Test that frame timing properly resets step time
    sequencer:setTimingMode("frame")
    sequencer.stepTime = 0.5  -- Set some accumulated time
    
    sequencer:play()
    
    luaunit.assertEquals(sequencer.stepTime, 0, "Should reset step time for frame mode")
end

return TestSequencerAudioReadiness