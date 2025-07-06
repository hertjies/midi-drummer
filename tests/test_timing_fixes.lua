--[[
    MIDI Drum Sequencer - test_timing_fixes.lua
    
    Unit tests for timing accuracy improvements.
    Tests BPM changes during playback and large delta time handling.
    
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

-- Mock audio module to track step triggers
local mockAudio = {
    triggerLog = {},
    
    playSample = function(self, track)
        table.insert(self.triggerLog, {
            track = track,
            step = nil,  -- Will be set by caller
            time = os.clock()
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

local TestTimingFixes = {}

function TestTimingFixes:setUp()
    -- Initialize sequencer with fresh state
    sequencer:init()
    
    -- Set to frame-based timing for these legacy tests
    sequencer:setTimingMode("frame")
    
    sequencer.audio = mockAudio
    mockAudio:reset()
    
    -- Set up a test pattern with notes on multiple steps
    sequencer.pattern[1][1] = true   -- Kick on step 1
    sequencer.pattern[2][5] = true   -- Snare on step 5
    sequencer.pattern[3][9] = true   -- Hi-hat on step 9
    sequencer.pattern[4][13] = true  -- Crash on step 13
end

function TestTimingFixes:tearDown()
    sequencer:stop()
    sequencer.audio = nil
end

function TestTimingFixes:testLargeDeltaTimeHandling()
    -- Test that large delta times (frame drops) are handled correctly
    sequencer:play()
    mockAudio:reset()
    
    -- Simulate a large frame drop that should advance multiple steps
    local largeStepDuration = sequencer.stepDuration * 3.5  -- 3.5 steps worth of time
    sequencer:update(largeStepDuration)
    
    -- Should have advanced to step 4 (1 + 3 steps = 4)
    luaunit.assertEquals(sequencer.currentStep, 4, "Should advance multiple steps")
    
    -- Step 4 is empty in our test pattern, so no sounds should trigger
    luaunit.assertEquals(#mockAudio.triggerLog, 0, "Step 4 is empty in our test pattern")
    
    -- The remaining fractional time should be preserved (0.5 steps worth)
    local expectedRemainingTime = largeStepDuration - (sequencer.stepDuration * 3)
    luaunit.assertTrue(math.abs(sequencer.stepTime - expectedRemainingTime) < 0.001, 
                      "Should preserve fractional timing")
end

function TestTimingFixes:testExtremelyLargeDeltaTime()
    -- Test safety mechanism for extremely large delta times
    sequencer:play()
    mockAudio:reset()
    
    -- Simulate an extremely large frame drop (more than full pattern)
    local extremelyLargeDelta = sequencer.stepDuration * 20  -- 20 steps worth
    sequencer:update(extremelyLargeDelta)
    
    -- Should have triggered steps in the pattern (steps 1, 5, 9, 13 each at least once)
    -- With 20 steps, we go around the pattern at least once
    luaunit.assertTrue(#mockAudio.triggerLog >= 1, "Should trigger at least some steps")
    
    -- Should not be stuck in infinite loop - stepTime should be reasonable
    luaunit.assertTrue(sequencer.stepTime < sequencer.stepDuration, 
                      "Should break out of potential infinite loop")
end

function TestTimingFixes:testBPMChangeWhilePlaying()
    -- Test that BPM changes during playback maintain timing continuity
    sequencer:setBPM(120)
    sequencer:play()
    
    -- Advance partway through a step
    local halfStepTime = sequencer.stepDuration * 0.5
    sequencer:update(halfStepTime)
    
    -- Change BPM to double speed
    sequencer:setBPM(240)
    
    -- The accumulated time should be scaled proportionally
    -- At 240 BPM, step duration is half of 120 BPM
    -- So the accumulated time should be scaled to match
    local expectedScaledTime = halfStepTime * 0.5  -- Scaled down for faster BPM
    luaunit.assertTrue(math.abs(sequencer.stepTime - expectedScaledTime) < 0.001,
                      "Step time should be scaled for BPM change")
end

function TestTimingFixes:testBPMSlowdownWhilePlaying()
    -- Test BPM slowing down during playback
    sequencer:setBPM(240)  -- Start fast
    sequencer:play()
    
    -- Advance partway through a step
    local quarterStepTime = sequencer.stepDuration * 0.25
    sequencer:update(quarterStepTime)
    
    -- Slow down to half speed
    sequencer:setBPM(120)
    
    -- The accumulated time should be scaled proportionally
    local expectedScaledTime = quarterStepTime * 2.0  -- Scaled up for slower BPM
    luaunit.assertTrue(math.abs(sequencer.stepTime - expectedScaledTime) < 0.001,
                      "Step time should be scaled for BPM slowdown")
end

function TestTimingFixes:testBPMChangeWhenNotPlaying()
    -- Test that BPM changes when not playing don't affect stepTime
    sequencer:setBPM(120)
    sequencer.stepTime = 0.1  -- Set some accumulated time
    
    -- Change BPM while not playing
    sequencer:setBPM(240)
    
    -- stepTime should remain unchanged
    luaunit.assertEquals(sequencer.stepTime, 0.1, "stepTime unchanged when not playing")
end

function TestTimingFixes:testTimingContinuityAfterBPMChange()
    -- Test that rhythm continues smoothly after BPM change
    sequencer:setBPM(120)
    sequencer:play()
    mockAudio:reset()
    
    -- Let it run for a bit to establish rhythm
    for i = 1, 3 do
        sequencer:update(sequencer.stepDuration)
    end
    luaunit.assertEquals(sequencer.currentStep, 4, "Should be on step 4")
    
    -- Change BPM mid-playback
    sequencer:setBPM(180)  -- 1.5x faster
    
    -- Continue playback - should maintain smooth timing
    local oldStepCount = #mockAudio.triggerLog
    sequencer:update(sequencer.stepDuration)  -- Use new step duration
    
    luaunit.assertEquals(sequencer.currentStep, 5, "Should advance to step 5")
    luaunit.assertEquals(#mockAudio.triggerLog, oldStepCount + 1, "Should trigger step 5")
end

function TestTimingFixes:testNoBPMChangeWithSameValue()
    -- Test that setting the same BPM doesn't trigger timing adjustments
    sequencer:setBPM(120)
    sequencer:play()
    
    local halfStepTime = sequencer.stepDuration * 0.5
    sequencer:update(halfStepTime)
    
    local originalStepTime = sequencer.stepTime
    
    -- Set the same BPM
    sequencer:setBPM(120)
    
    -- stepTime should remain unchanged
    luaunit.assertEquals(sequencer.stepTime, originalStepTime, 
                        "stepTime unchanged when BPM doesn't change")
end

function TestTimingFixes:testPrecisionWithSmallDeltas()
    -- Test timing precision with very small delta times
    sequencer:setBPM(120)
    sequencer:play()
    mockAudio:reset()
    
    -- Simulate many small updates (high frame rate)
    local totalTime = 0
    local smallDelta = 0.001  -- 1ms updates (1000 FPS)
    
    -- Accumulate until we should trigger the next step
    while totalTime < sequencer.stepDuration * 1.1 do
        sequencer:update(smallDelta)
        totalTime = totalTime + smallDelta
    end
    
    -- Should have triggered exactly once at the right time
    luaunit.assertEquals(sequencer.currentStep, 2, "Should advance to step 2")
    luaunit.assertEquals(#mockAudio.triggerLog, 0, "Step 2 is empty in our test pattern")
end

function TestTimingFixes:testTimingDriftPrevention()
    -- Test that timing drift is prevented over long sequences
    sequencer:setBPM(120)
    sequencer:play()
    
    local stepCount = 0
    local totalTime = 0
    
    -- Run for many steps with slightly irregular timing
    for i = 1, 100 do
        local irregularDelta = sequencer.stepDuration + (math.random() - 0.5) * 0.001
        sequencer:update(irregularDelta)
        totalTime = totalTime + irregularDelta
        
        if sequencer.currentStep ~= stepCount % 16 + 1 then
            stepCount = stepCount + 1
        end
    end
    
    -- Total time should roughly match expected time for number of steps
    local expectedTime = stepCount * sequencer.stepDuration
    local timeDrift = math.abs(totalTime - expectedTime)
    
    -- Drift should be reasonable (less than 2 step durations for 100 irregular updates)
    -- Note: Some drift is expected with deliberately irregular timing
    luaunit.assertTrue(timeDrift < sequencer.stepDuration * 2, 
                      "Timing drift should be reasonable over long sequences")
end

return TestTimingFixes