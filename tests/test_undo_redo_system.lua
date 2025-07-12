--[[
    MIDI Drum Sequencer - test_undo_redo_system.lua
    
    Comprehensive tests for the undo/redo functionality.
    Tests command pattern implementation and history management.
    
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

local luaunit = require('lib.luaunit')

-- Test class for undo/redo system
TestUndoRedoSystem = {}

function TestUndoRedoSystem:setUp()
    -- Initialize all required modules
    self.sequencer = require("src.sequencer")
    self.audio = require("src.audio")
    self.ui = require("src.ui")
    self.utils = require("src.utils")
    self.commandHistory = require("src.command_history")
    
    -- Initialize modules
    self.sequencer:init()
    self.audio:init()
    self.ui:init()
    self.ui.utils = self.utils  -- Connect utils to UI
    self.commandHistory:init(self.sequencer, self.audio, self.ui)
    
    -- Connect command history to UI
    self.ui.commandHistory = self.commandHistory
    
    -- Set initial BPM
    self.sequencer:setBPM(120)
    
    -- Clear pattern to start with clean state
    self.sequencer:clearPattern()
end

function TestUndoRedoSystem:tearDown()
    -- Clean up
    if self.commandHistory then
        self.commandHistory:clear()
    end
end

-- Test basic command history initialization
function TestUndoRedoSystem:testCommandHistoryInit()
    luaunit.assertNotNil(self.commandHistory)
    luaunit.assertFalse(self.commandHistory:canUndo())
    luaunit.assertFalse(self.commandHistory:canRedo())
    
    local stats = self.commandHistory:getStats()
    luaunit.assertEquals(stats.undoCount, 0)
    luaunit.assertEquals(stats.redoCount, 0)
    luaunit.assertEquals(stats.maxSize, 50)
end

-- Test step toggle command
function TestUndoRedoSystem:testToggleStepCommand()
    local track = 2
    local step = 5
    
    -- Initially step should be off
    luaunit.assertFalse(self.sequencer.pattern[track][step])
    
    -- Create and execute toggle command
    local command = self.commandHistory.ToggleStepCommand:new(self.sequencer, track, step)
    self.commandHistory:executeCommand(command)
    
    -- Step should now be on
    luaunit.assertTrue(self.sequencer.pattern[track][step])
    luaunit.assertTrue(self.commandHistory:canUndo())
    luaunit.assertFalse(self.commandHistory:canRedo())
    
    -- Undo the command
    luaunit.assertTrue(self.commandHistory:undo())
    
    -- Step should be off again
    luaunit.assertFalse(self.sequencer.pattern[track][step])
    luaunit.assertFalse(self.commandHistory:canUndo())
    luaunit.assertTrue(self.commandHistory:canRedo())
    
    -- Redo the command
    luaunit.assertTrue(self.commandHistory:redo())
    
    -- Step should be on again
    luaunit.assertTrue(self.sequencer.pattern[track][step])
    luaunit.assertTrue(self.commandHistory:canUndo())
    luaunit.assertFalse(self.commandHistory:canRedo())
end

-- Test clear pattern command
function TestUndoRedoSystem:testClearPatternCommand()
    -- Set up some pattern data
    self.sequencer.pattern[1][1] = true
    self.sequencer.pattern[2][3] = true
    self.sequencer.pattern[4][8] = true
    self.sequencer.pattern[7][12] = true
    
    -- Verify pattern has data
    luaunit.assertTrue(self.sequencer.pattern[1][1])
    luaunit.assertTrue(self.sequencer.pattern[2][3])
    luaunit.assertTrue(self.sequencer.pattern[4][8])
    luaunit.assertTrue(self.sequencer.pattern[7][12])
    
    -- Create and execute clear command
    local command = self.commandHistory.ClearPatternCommand:new(self.sequencer)
    self.commandHistory:executeCommand(command)
    
    -- Pattern should be cleared
    luaunit.assertFalse(self.sequencer.pattern[1][1])
    luaunit.assertFalse(self.sequencer.pattern[2][3])
    luaunit.assertFalse(self.sequencer.pattern[4][8])
    luaunit.assertFalse(self.sequencer.pattern[7][12])
    
    -- Undo should restore pattern
    luaunit.assertTrue(self.commandHistory:undo())
    luaunit.assertTrue(self.sequencer.pattern[1][1])
    luaunit.assertTrue(self.sequencer.pattern[2][3])
    luaunit.assertTrue(self.sequencer.pattern[4][8])
    luaunit.assertTrue(self.sequencer.pattern[7][12])
    
    -- Redo should clear again
    luaunit.assertTrue(self.commandHistory:redo())
    luaunit.assertFalse(self.sequencer.pattern[1][1])
    luaunit.assertFalse(self.sequencer.pattern[2][3])
    luaunit.assertFalse(self.sequencer.pattern[4][8])
    luaunit.assertFalse(self.sequencer.pattern[7][12])
end

-- Test BPM change command
function TestUndoRedoSystem:testBPMChangeCommand()
    local initialBPM = 120
    local newBPM = 140
    
    -- Set initial BPM
    self.sequencer:setBPM(initialBPM)
    luaunit.assertEquals(self.sequencer.bpm, initialBPM)
    
    -- Create and execute BPM change command
    local command = self.commandHistory.BPMChangeCommand:new(self.sequencer, newBPM)
    self.commandHistory:executeCommand(command)
    
    -- BPM should be changed
    luaunit.assertEquals(self.sequencer.bpm, newBPM)
    
    -- Undo should restore original BPM
    luaunit.assertTrue(self.commandHistory:undo())
    luaunit.assertEquals(self.sequencer.bpm, initialBPM)
    
    -- Redo should change BPM again
    luaunit.assertTrue(self.commandHistory:redo())
    luaunit.assertEquals(self.sequencer.bpm, newBPM)
end

-- Test volume change command
function TestUndoRedoSystem:testVolumeChangeCommand()
    local track = 3
    local initialVolume = 0.7
    local newVolume = 0.5
    
    -- Set initial volume
    self.audio:setVolume(track, initialVolume)
    luaunit.assertAlmostEquals(self.audio:getVolume(track), initialVolume, 0.01)
    
    -- Create and execute volume change command
    local command = self.commandHistory.VolumeChangeCommand:new(self.audio, track, newVolume)
    self.commandHistory:executeCommand(command)
    
    -- Volume should be changed
    luaunit.assertAlmostEquals(self.audio:getVolume(track), newVolume, 0.01)
    
    -- Undo should restore original volume
    luaunit.assertTrue(self.commandHistory:undo())
    luaunit.assertAlmostEquals(self.audio:getVolume(track), initialVolume, 0.01)
    
    -- Redo should change volume again
    luaunit.assertTrue(self.commandHistory:redo())
    luaunit.assertAlmostEquals(self.audio:getVolume(track), newVolume, 0.01)
end

-- Test multiple commands and complex undo/redo
function TestUndoRedoSystem:testMultipleCommands()
    -- Execute multiple different commands
    local cmd1 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 1, 1)
    local cmd2 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 2, 5)
    local cmd3 = self.commandHistory.BPMChangeCommand:new(self.sequencer, 140)
    local cmd4 = self.commandHistory.VolumeChangeCommand:new(self.audio, 1, 0.8)
    
    self.commandHistory:executeCommand(cmd1)
    self.commandHistory:executeCommand(cmd2)
    self.commandHistory:executeCommand(cmd3)
    self.commandHistory:executeCommand(cmd4)
    
    -- Verify final state
    luaunit.assertTrue(self.sequencer.pattern[1][1])
    luaunit.assertTrue(self.sequencer.pattern[2][5])
    luaunit.assertEquals(self.sequencer.bpm, 140)
    luaunit.assertAlmostEquals(self.audio:getVolume(1), 0.8, 0.01)
    
    local stats = self.commandHistory:getStats()
    luaunit.assertEquals(stats.undoCount, 4)
    luaunit.assertEquals(stats.redoCount, 0)
    
    -- Undo commands one by one
    luaunit.assertTrue(self.commandHistory:undo())  -- Undo volume change
    luaunit.assertAlmostEquals(self.audio:getVolume(1), 0.7, 0.01)
    
    luaunit.assertTrue(self.commandHistory:undo())  -- Undo BPM change
    luaunit.assertEquals(self.sequencer.bpm, 120)
    
    luaunit.assertTrue(self.commandHistory:undo())  -- Undo step 2,5
    luaunit.assertFalse(self.sequencer.pattern[2][5])
    
    luaunit.assertTrue(self.commandHistory:undo())  -- Undo step 1,1
    luaunit.assertFalse(self.sequencer.pattern[1][1])
    
    -- Should not be able to undo anymore
    luaunit.assertFalse(self.commandHistory:undo())
    
    -- Check stats
    stats = self.commandHistory:getStats()
    luaunit.assertEquals(stats.undoCount, 0)
    luaunit.assertEquals(stats.redoCount, 4)
    
    -- Redo all commands
    luaunit.assertTrue(self.commandHistory:redo())  -- Redo step 1,1
    luaunit.assertTrue(self.sequencer.pattern[1][1])
    
    luaunit.assertTrue(self.commandHistory:redo())  -- Redo step 2,5
    luaunit.assertTrue(self.sequencer.pattern[2][5])
    
    luaunit.assertTrue(self.commandHistory:redo())  -- Redo BPM change
    luaunit.assertEquals(self.sequencer.bpm, 140)
    
    luaunit.assertTrue(self.commandHistory:redo())  -- Redo volume change
    luaunit.assertAlmostEquals(self.audio:getVolume(1), 0.8, 0.01)
    
    -- Should not be able to redo anymore
    luaunit.assertFalse(self.commandHistory:redo())
end

-- Test new action clears redo stack
function TestUndoRedoSystem:testNewActionClearsRedo()
    -- Execute two commands
    local cmd1 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 1, 1)
    local cmd2 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 2, 2)
    
    self.commandHistory:executeCommand(cmd1)
    self.commandHistory:executeCommand(cmd2)
    
    -- Undo one command
    luaunit.assertTrue(self.commandHistory:undo())
    luaunit.assertTrue(self.commandHistory:canRedo())
    
    -- Execute new command - should clear redo stack
    local cmd3 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 3, 3)
    self.commandHistory:executeCommand(cmd3)
    
    -- Redo should not be available
    luaunit.assertFalse(self.commandHistory:canRedo())
    luaunit.assertFalse(self.commandHistory:redo())
end

-- Test command history size limit
function TestUndoRedoSystem:testHistorySizeLimit()
    -- Set a smaller limit for testing
    self.commandHistory.maxHistorySize = 3
    
    -- Execute more commands than the limit
    for i = 1, 5 do
        local cmd = self.commandHistory.ToggleStepCommand:new(self.sequencer, 1, i)
        self.commandHistory:executeCommand(cmd)
    end
    
    -- Should only keep the last 3 commands
    local stats = self.commandHistory:getStats()
    luaunit.assertEquals(stats.undoCount, 3)
    
    -- Verify which commands are preserved (should be commands 3, 4, 5)
    luaunit.assertTrue(self.sequencer.pattern[1][3])
    luaunit.assertTrue(self.sequencer.pattern[1][4])
    luaunit.assertTrue(self.sequencer.pattern[1][5])
    
    -- Undo all available
    self.commandHistory:undo()  -- Undo step 5
    self.commandHistory:undo()  -- Undo step 4
    self.commandHistory:undo()  -- Undo step 3
    
    -- Steps 1 and 2 should still be on (they were not undone)
    luaunit.assertTrue(self.sequencer.pattern[1][1])
    luaunit.assertTrue(self.sequencer.pattern[1][2])
    luaunit.assertFalse(self.sequencer.pattern[1][3])
    luaunit.assertFalse(self.sequencer.pattern[1][4])
    luaunit.assertFalse(self.sequencer.pattern[1][5])
end

-- Test command history clear
function TestUndoRedoSystem:testHistoryClear()
    -- Execute some commands
    local cmd1 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 1, 1)
    local cmd2 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 2, 2)
    
    self.commandHistory:executeCommand(cmd1)
    self.commandHistory:executeCommand(cmd2)
    
    -- Verify we have history
    luaunit.assertTrue(self.commandHistory:canUndo())
    
    -- Clear history
    self.commandHistory:clear()
    
    -- History should be empty
    luaunit.assertFalse(self.commandHistory:canUndo())
    luaunit.assertFalse(self.commandHistory:canRedo())
    
    local stats = self.commandHistory:getStats()
    luaunit.assertEquals(stats.undoCount, 0)
    luaunit.assertEquals(stats.redoCount, 0)
end

-- Test empty undo/redo operations
function TestUndoRedoSystem:testEmptyOperations()
    -- Should not be able to undo/redo when history is empty
    luaunit.assertFalse(self.commandHistory:undo())
    luaunit.assertFalse(self.commandHistory:redo())
    luaunit.assertFalse(self.commandHistory:canUndo())
    luaunit.assertFalse(self.commandHistory:canRedo())
end

-- Test command descriptions
function TestUndoRedoSystem:testCommandDescriptions()
    local cmd1 = self.commandHistory.ToggleStepCommand:new(self.sequencer, 2, 5)
    local cmd2 = self.commandHistory.ClearPatternCommand:new(self.sequencer)
    local cmd3 = self.commandHistory.BPMChangeCommand:new(self.sequencer, 140)
    local cmd4 = self.commandHistory.VolumeChangeCommand:new(self.audio, 3, 0.5)
    
    -- Test command descriptions contain useful information
    luaunit.assertStrContains(cmd1.description, "Toggle step 5 on track 2")
    luaunit.assertStrContains(cmd2.description, "Clear pattern")
    luaunit.assertStrContains(cmd3.description, "Change BPM")
    luaunit.assertStrContains(cmd4.description, "Change track 3 volume")
end

return TestUndoRedoSystem