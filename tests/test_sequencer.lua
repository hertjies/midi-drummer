--[[
    MIDI Drum Sequencer - test_sequencer.lua
    
    Unit tests for the sequencer module.
    Tests core sequencer functionality, pattern management, and timing.
    
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
local sequencer = require("sequencer")

local TestSequencer = {}

function TestSequencer:setUp()
    -- Reset sequencer to initial state before each test
    sequencer.pattern = {}
    sequencer.currentStep = 1
    sequencer.isPlaying = false
    sequencer.bpm = 120
    sequencer.stepTime = 0
    sequencer:init()
end

function TestSequencer:testInit()
    -- Test that init creates 8x16 pattern matrix
    luaunit.assertNotNil(sequencer.pattern)
    luaunit.assertEquals(#sequencer.pattern, 8)
    
    for track = 1, 8 do
        luaunit.assertNotNil(sequencer.pattern[track])
        luaunit.assertEquals(#sequencer.pattern[track], 16)
        
        -- All steps should be false initially
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step])
        end
    end
    
    -- Check initial values
    luaunit.assertEquals(sequencer.currentStep, 1)
    luaunit.assertFalse(sequencer.isPlaying)
    luaunit.assertEquals(sequencer.bpm, 120)
end

function TestSequencer:testToggleStep()
    -- Test toggling steps on and off
    luaunit.assertFalse(sequencer.pattern[1][1])
    
    sequencer:toggleStep(1, 1)
    luaunit.assertTrue(sequencer.pattern[1][1])
    
    sequencer:toggleStep(1, 1)
    luaunit.assertFalse(sequencer.pattern[1][1])
    
    -- Test multiple steps
    sequencer:toggleStep(3, 5)
    sequencer:toggleStep(8, 16)
    luaunit.assertTrue(sequencer.pattern[3][5])
    luaunit.assertTrue(sequencer.pattern[8][16])
end

function TestSequencer:testToggleStepBounds()
    -- Test boundary conditions
    sequencer:toggleStep(0, 1)  -- Invalid track
    sequencer:toggleStep(9, 1)  -- Invalid track
    sequencer:toggleStep(1, 0)  -- Invalid step
    sequencer:toggleStep(1, 17) -- Invalid step
    
    -- Pattern should remain unchanged
    for track = 1, 8 do
        for step = 1, 16 do
            luaunit.assertFalse(sequencer.pattern[track][step])
        end
    end
end

function TestSequencer:testPlayStop()
    -- Test play functionality
    luaunit.assertFalse(sequencer.isPlaying)
    luaunit.assertEquals(sequencer.currentStep, 1)
    
    sequencer:play()
    luaunit.assertTrue(sequencer.isPlaying)
    luaunit.assertEquals(sequencer.stepTime, 0)
    
    -- Test stop functionality
    sequencer.currentStep = 5  -- Simulate progression
    sequencer:stop()
    luaunit.assertFalse(sequencer.isPlaying)
    luaunit.assertEquals(sequencer.currentStep, 1)  -- Reset to start
    luaunit.assertEquals(sequencer.stepTime, 0)
end

function TestSequencer:testSetBPM()
    -- Test normal BPM setting
    sequencer:setBPM(140)
    luaunit.assertEquals(sequencer.bpm, 140)
    
    -- Test BPM clamping
    sequencer:setBPM(50)   -- Below minimum
    luaunit.assertEquals(sequencer.bpm, 60)
    
    sequencer:setBPM(350)  -- Above maximum
    luaunit.assertEquals(sequencer.bpm, 300)
    
    -- Test step duration calculation
    sequencer:setBPM(120)
    luaunit.assertAlmostEquals(sequencer.stepDuration, 0.125, 0.001)  -- 60/120/4
    
    sequencer:setBPM(240)
    luaunit.assertAlmostEquals(sequencer.stepDuration, 0.0625, 0.001) -- 60/240/4
end

function TestSequencer:testAdvanceStep()
    -- Test step advancement
    luaunit.assertEquals(sequencer.currentStep, 1)
    
    sequencer:advanceStep()
    luaunit.assertEquals(sequencer.currentStep, 2)
    
    -- Test wrap around
    sequencer.currentStep = 16
    sequencer:advanceStep()
    luaunit.assertEquals(sequencer.currentStep, 1)
end

function TestSequencer:testUpdateStepDuration()
    sequencer.bpm = 120
    sequencer:updateStepDuration()
    luaunit.assertAlmostEquals(sequencer.stepDuration, 0.125, 0.001)
    
    sequencer.bpm = 60
    sequencer:updateStepDuration()
    luaunit.assertAlmostEquals(sequencer.stepDuration, 0.25, 0.001)
end

return TestSequencer