--[[
    MIDI Drum Sequencer - test_sequencer_phase2.lua
    
    Unit tests for Phase 2 sequencer functionality.
    Tests timing system, playback controls, and BPM management.
    
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

-- Tests timing, playback, and new methods
-- Path is already set by test_runner.lua when running the full suite
-- For standalone execution, add paths:
if not package.path:match("./src/%?%.lua") then
    package.path = package.path .. ";./src/?.lua;./lib/?.lua"
end

local luaunit = require("luaunit")
local sequencer = require("sequencer")

local TestSequencerPhase2 = {}

function TestSequencerPhase2:setUp()
    -- Reset sequencer to initial state before each test
    sequencer.pattern = {}
    sequencer.currentStep = 1
    sequencer.isPlaying = false
    sequencer.bpm = 120
    sequencer.stepTime = 0
    sequencer:init()
    -- Set to frame-based timing for legacy tests
    sequencer:setTimingMode("frame")
end

function TestSequencerPhase2:testTimingAccuracy()
    -- Test that timing calculations are accurate
    sequencer:play()
    luaunit.assertTrue(sequencer.isPlaying)
    
    -- Simulate time passing (almost one step)
    local almostOneStep = sequencer.stepDuration - 0.001
    sequencer:update(almostOneStep)
    luaunit.assertEquals(sequencer.currentStep, 1) -- Should not advance yet
    
    -- Complete the step
    sequencer:update(0.002)
    luaunit.assertEquals(sequencer.currentStep, 2) -- Should advance now
    
    -- Test timing accumulation
    local oldStepTime = sequencer.stepTime
    sequencer:update(0.05)
    luaunit.assertAlmostEquals(sequencer.stepTime, oldStepTime + 0.05, 0.0001)
end

function TestSequencerPhase2:testPlaybackLoop()
    -- Test that pattern loops correctly
    sequencer:play()
    sequencer.currentStep = 15
    
    -- Advance two steps
    sequencer:advanceStep()
    luaunit.assertEquals(sequencer.currentStep, 16)
    
    sequencer:advanceStep()
    luaunit.assertEquals(sequencer.currentStep, 1) -- Should loop back
end

function TestSequencerPhase2:testClearPattern()
    -- Set some steps
    sequencer:toggleStep(1, 1)
    sequencer:toggleStep(3, 5)
    sequencer:toggleStep(8, 16)
    
    -- Verify they're set
    luaunit.assertTrue(sequencer.pattern[1][1])
    luaunit.assertTrue(sequencer.pattern[3][5])
    luaunit.assertTrue(sequencer.pattern[8][16])
    
    -- Clear pattern
    sequencer:clearPattern()
    
    -- Verify all steps are cleared
    for track = 1, 8 do
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step])
        end
    end
end

function TestSequencerPhase2:testGetActiveTracksAtStep()
    -- Set up a pattern
    sequencer:toggleStep(1, 5)  -- Kick on step 5
    sequencer:toggleStep(2, 5)  -- Snare on step 5
    sequencer:toggleStep(3, 5)  -- Hi-hat on step 5
    sequencer:toggleStep(1, 6)  -- Kick on step 6
    
    -- Test step 5
    local activeTracks = sequencer:getActiveTracksAtStep(5)
    luaunit.assertEquals(#activeTracks, 3)
    luaunit.assertEquals(activeTracks[1], 1)
    luaunit.assertEquals(activeTracks[2], 2)
    luaunit.assertEquals(activeTracks[3], 3)
    
    -- Test step 6
    activeTracks = sequencer:getActiveTracksAtStep(6)
    luaunit.assertEquals(#activeTracks, 1)
    luaunit.assertEquals(activeTracks[1], 1)
    
    -- Test empty step
    activeTracks = sequencer:getActiveTracksAtStep(7)
    luaunit.assertEquals(#activeTracks, 0)
    
    -- Test invalid step
    activeTracks = sequencer:getActiveTracksAtStep(17)
    luaunit.assertEquals(#activeTracks, 0)
end

function TestSequencerPhase2:testBPMChangeDuringPlayback()
    -- Start playback
    sequencer:play()
    sequencer:setBPM(120)
    local oldDuration = sequencer.stepDuration
    
    -- Change BPM
    sequencer:setBPM(240)
    
    -- Verify step duration changed
    luaunit.assertAlmostEquals(sequencer.stepDuration, oldDuration / 2, 0.0001)
    
    -- Verify playback continues
    luaunit.assertTrue(sequencer.isPlaying)
end

function TestSequencerPhase2:testStepTimeReset()
    -- Test that step time resets properly
    sequencer:play()
    sequencer:update(0.05)
    luaunit.assertTrue(sequencer.stepTime > 0)
    
    -- Stop should reset step time
    sequencer:stop()
    luaunit.assertEquals(sequencer.stepTime, 0)
    
    -- Play should also reset step time
    sequencer:update(0.05)
    sequencer:play()
    luaunit.assertEquals(sequencer.stepTime, 0)
end

function TestSequencerPhase2:testTriggerCurrentStep()
    -- This tests the trigger mechanism (audio will be added in Phase 3)
    -- Set up a pattern
    sequencer:toggleStep(1, 1)
    sequencer:toggleStep(2, 1) 
    sequencer:toggleStep(3, 2)
    
    -- Test that triggerCurrentStep doesn't crash without audio module
    sequencer.currentStep = 1
    local success = pcall(function() sequencer:triggerCurrentStep() end)
    luaunit.assertTrue(success)
    
    -- Move to step 2 and test again
    sequencer.currentStep = 2
    success = pcall(function() sequencer:triggerCurrentStep() end)
    luaunit.assertTrue(success)
end

return TestSequencerPhase2