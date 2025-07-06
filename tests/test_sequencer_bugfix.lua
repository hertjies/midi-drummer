--[[
    MIDI Drum Sequencer - test_sequencer_bugfix.lua
    
    Unit tests for sequencer bug fixes.
    Tests that sounds trigger immediately on play start.
    
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

-- Mock audio module to track trigger calls
local mockAudio = {
    triggerLog = {},
    
    playSample = function(self, track)
        table.insert(self.triggerLog, {
            track = track,
            time = os.clock()  -- Record when the sample was triggered
        })
    end,
    
    isSystemReady = function(self)
        return true
    end,
    
    reset = function(self)
        self.triggerLog = {}
    end
}

local sequencer = require("sequencer")

local TestSequencerBugfix = {}

function TestSequencerBugfix:setUp()
    -- Initialize sequencer with fresh pattern
    sequencer:init()
    
    -- Set to frame-based timing for these tests
    sequencer:setTimingMode("frame")
    
    -- Connect mock audio
    sequencer.audio = mockAudio
    mockAudio:reset()
    
    -- Set up a test pattern with notes on step 1
    sequencer.pattern[1][1] = true  -- Kick on step 1
    sequencer.pattern[2][1] = true  -- Snare on step 1
    sequencer.pattern[3][1] = true  -- Hi-hat on step 1
end

function TestSequencerBugfix:tearDown()
    -- Ensure playback is stopped
    sequencer:stop()
    sequencer.audio = nil
end

function TestSequencerBugfix:testFirstStepTriggersImmediately()
    -- Test that sounds on step 1 are triggered immediately when play is pressed
    local startTime = os.clock()
    
    -- Start playback
    sequencer:play()
    
    -- Check that sounds were triggered immediately
    luaunit.assertEquals(#mockAudio.triggerLog, 3, "Expected 3 sounds to trigger")
    
    -- Verify the correct tracks were triggered
    local triggeredTracks = {}
    for _, trigger in ipairs(mockAudio.triggerLog) do
        triggeredTracks[trigger.track] = true
    end
    
    luaunit.assertTrue(triggeredTracks[1], "Track 1 (kick) should have triggered")
    luaunit.assertTrue(triggeredTracks[2], "Track 2 (snare) should have triggered")
    luaunit.assertTrue(triggeredTracks[3], "Track 3 (hi-hat) should have triggered")
    
    -- Verify triggers happened immediately (within a small time window)
    for _, trigger in ipairs(mockAudio.triggerLog) do
        local timeDiff = trigger.time - startTime
        luaunit.assertTrue(timeDiff < 0.001, "Trigger should happen immediately, not after delay")
    end
end

function TestSequencerBugfix:testNoDoubleTriggerOnFirstStep()
    -- Test that the first step doesn't trigger twice when advancing
    sequencer:play()
    
    -- Clear the initial trigger log
    mockAudio:reset()
    
    -- Simulate time passing to trigger next step
    sequencer:update(sequencer.stepDuration + 0.001)
    
    -- Should have advanced to step 2, not retriggered step 1
    luaunit.assertEquals(sequencer.currentStep, 2, "Should be on step 2")
    
    -- No sounds should trigger (step 2 is empty in our test pattern)
    luaunit.assertEquals(#mockAudio.triggerLog, 0, "No sounds should trigger on empty step 2")
end

function TestSequencerBugfix:testPlayFromMiddlePattern()
    -- Test that play triggers current step even when not starting from step 1
    sequencer.currentStep = 5
    sequencer.pattern[1][5] = true  -- Add a kick on step 5
    
    sequencer:play()
    
    -- Should trigger step 5 immediately
    luaunit.assertEquals(#mockAudio.triggerLog, 1, "Expected 1 sound to trigger")
    luaunit.assertEquals(mockAudio.triggerLog[1].track, 1, "Track 1 should trigger")
end

function TestSequencerBugfix:testStopDoesNotTrigger()
    -- Test that stopping doesn't trigger any sounds
    sequencer:play()
    mockAudio:reset()
    
    sequencer:stop()
    
    -- No additional sounds should trigger on stop
    luaunit.assertEquals(#mockAudio.triggerLog, 0, "No sounds should trigger on stop")
    luaunit.assertEquals(sequencer.currentStep, 1, "Should reset to step 1")
end

function TestSequencerBugfix:testEmptyPatternNoTrigger()
    -- Test that empty pattern doesn't cause errors
    -- Clear the pattern
    for track = 1, 8 do
        for step = 1, 16 do
            sequencer.pattern[track][step] = false
        end
    end
    
    sequencer:play()
    
    -- No sounds should trigger
    luaunit.assertEquals(#mockAudio.triggerLog, 0, "No sounds should trigger on empty pattern")
end

function TestSequencerBugfix:testRestartWhilePlaying()
    -- Test that pressing play while already playing triggers current step
    sequencer:play()
    
    -- Advance to step 3
    sequencer:update(sequencer.stepDuration)  -- To step 2
    sequencer:update(sequencer.stepDuration)  -- To step 3
    luaunit.assertEquals(sequencer.currentStep, 3, "Should be on step 3")
    
    -- Add a note on step 3
    sequencer.pattern[4][3] = true  -- Add crash on step 3
    
    -- Clear log and press play again
    mockAudio:reset()
    sequencer:play()
    
    -- Should trigger step 3 immediately
    luaunit.assertEquals(#mockAudio.triggerLog, 1, "Expected 1 sound to trigger")
    luaunit.assertEquals(mockAudio.triggerLog[1].track, 4, "Track 4 (crash) should trigger")
    luaunit.assertEquals(sequencer.currentStep, 3, "Should still be on step 3")
end

return TestSequencerBugfix