--[[
    MIDI Drum Sequencer - command_history.lua
    
    Implements undo/redo functionality using the Command pattern.
    Manages a history stack of user actions for professional workflow.
    
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

local commandHistory = {
    -- Command history stacks
    undoStack = {},         -- Commands that can be undone
    redoStack = {},         -- Commands that can be redone
    
    -- Configuration
    maxHistorySize = 50,    -- Maximum number of commands to remember
    
    -- References to application modules (set during initialization)
    sequencer = nil,
    audio = nil,
    ui = nil
}

-- Initialize the command history system
-- @param sequencer: Reference to sequencer module
-- @param audio: Reference to audio module  
-- @param ui: Reference to UI module
function commandHistory:init(sequencer, audio, ui)
    self.sequencer = sequencer
    self.audio = audio
    self.ui = ui
    
    -- Clear any existing history
    self.undoStack = {}
    self.redoStack = {}
    
    print("Command history system initialized")
end

-- Execute a command and add it to the undo stack
-- @param command: Command object with execute() and undo() methods
function commandHistory:executeCommand(command)
    -- Execute the command
    command:execute()
    
    -- Add to undo stack
    table.insert(self.undoStack, command)
    
    -- Clear redo stack (new action invalidates redo history)
    self.redoStack = {}
    
    -- Enforce maximum history size
    if #self.undoStack > self.maxHistorySize then
        table.remove(self.undoStack, 1)  -- Remove oldest command
    end
end

-- Undo the last command
-- @return: true if undo was performed, false if no commands to undo
function commandHistory:undo()
    if #self.undoStack == 0 then
        return false  -- Nothing to undo
    end
    
    -- Get the last command
    local command = table.remove(self.undoStack)
    
    -- Undo the command
    command:undo()
    
    -- Move to redo stack
    table.insert(self.redoStack, command)
    
    -- Enforce maximum redo size
    if #self.redoStack > self.maxHistorySize then
        table.remove(self.redoStack, 1)
    end
    
    return true
end

-- Redo the last undone command
-- @return: true if redo was performed, false if no commands to redo
function commandHistory:redo()
    if #self.redoStack == 0 then
        return false  -- Nothing to redo
    end
    
    -- Get the last undone command
    local command = table.remove(self.redoStack)
    
    -- Re-execute the command
    command:execute()
    
    -- Move back to undo stack
    table.insert(self.undoStack, command)
    
    return true
end

-- Check if undo is available
-- @return: true if there are commands that can be undone
function commandHistory:canUndo()
    return #self.undoStack > 0
end

-- Check if redo is available
-- @return: true if there are commands that can be redone
function commandHistory:canRedo()
    return #self.redoStack > 0
end

-- Clear all command history
-- Useful when loading a new pattern or resetting the application
function commandHistory:clear()
    self.undoStack = {}
    self.redoStack = {}
end

-- Get command history statistics for debugging
-- @return: Table with undo/redo counts and stack information
function commandHistory:getStats()
    return {
        undoCount = #self.undoStack,
        redoCount = #self.redoStack,
        maxSize = self.maxHistorySize,
        canUndo = self:canUndo(),
        canRedo = self:canRedo()
    }
end

--[[
    Command Base Class
    
    All undoable commands should implement this interface
--]]
local Command = {}
Command.__index = Command

-- Create a new command instance
-- @param executeFunc: Function to execute the command
-- @param undoFunc: Function to undo the command
-- @param description: Optional description for debugging
function Command:new(executeFunc, undoFunc, description)
    local cmd = {
        executeFunc = executeFunc,
        undoFunc = undoFunc,
        description = description or "Unknown Command"
    }
    setmetatable(cmd, self)
    return cmd
end

-- Execute the command
function Command:execute()
    if self.executeFunc then
        self.executeFunc()
    end
end

-- Undo the command
function Command:undo()
    if self.undoFunc then
        self.undoFunc()
    end
end

--[[
    Specific Command Implementations
--]]

-- Toggle Step Command
-- Handles toggling individual pattern steps on/off
local ToggleStepCommand = {}
ToggleStepCommand.__index = ToggleStepCommand
setmetatable(ToggleStepCommand, Command)

function ToggleStepCommand:new(sequencer, track, step)
    local cmd = {
        sequencer = sequencer,
        track = track,
        step = step,
        description = string.format("Toggle step %d on track %d", step, track)
    }
    setmetatable(cmd, self)
    return cmd
end

function ToggleStepCommand:execute()
    self.sequencer:toggleStep(self.track, self.step)
end

function ToggleStepCommand:undo()
    -- Toggle again to revert
    self.sequencer:toggleStep(self.track, self.step)
end

-- Clear Pattern Command  
-- Handles clearing the entire pattern grid
local ClearPatternCommand = {}
ClearPatternCommand.__index = ClearPatternCommand
setmetatable(ClearPatternCommand, Command)

function ClearPatternCommand:new(sequencer)
    local cmd = {
        sequencer = sequencer,
        previousPattern = {},
        description = "Clear pattern"
    }
    
    -- Save current pattern state
    for track = 1, 8 do
        cmd.previousPattern[track] = {}
        for step = 1, 16 do
            cmd.previousPattern[track][step] = sequencer.pattern[track][step]
        end
    end
    
    setmetatable(cmd, self)
    return cmd
end

function ClearPatternCommand:execute()
    self.sequencer:clearPattern()
end

function ClearPatternCommand:undo()
    -- Restore previous pattern
    for track = 1, 8 do
        for step = 1, 16 do
            self.sequencer.pattern[track][step] = self.previousPattern[track][step]
        end
    end
end

-- BPM Change Command
-- Handles BPM tempo changes
local BPMChangeCommand = {}
BPMChangeCommand.__index = BPMChangeCommand
setmetatable(BPMChangeCommand, Command)

function BPMChangeCommand:new(sequencer, newBPM)
    local cmd = {
        sequencer = sequencer,
        newBPM = newBPM,
        previousBPM = sequencer.bpm,
        description = string.format("Change BPM from %d to %d", sequencer.bpm, newBPM)
    }
    setmetatable(cmd, self)
    return cmd
end

function BPMChangeCommand:execute()
    self.sequencer:setBPM(self.newBPM)
end

function BPMChangeCommand:undo()
    self.sequencer:setBPM(self.previousBPM)
end

-- Volume Change Command
-- Handles track volume adjustments
local VolumeChangeCommand = {}
VolumeChangeCommand.__index = VolumeChangeCommand
setmetatable(VolumeChangeCommand, Command)

function VolumeChangeCommand:new(audio, track, newVolume)
    local cmd = {
        audio = audio,
        track = track,
        newVolume = newVolume,
        previousVolume = audio:getVolume(track),
        description = string.format("Change track %d volume from %.2f to %.2f", track, audio:getVolume(track), newVolume)
    }
    setmetatable(cmd, self)
    return cmd
end

function VolumeChangeCommand:execute()
    self.audio:setVolume(self.track, self.newVolume)
end

function VolumeChangeCommand:undo()
    self.audio:setVolume(self.track, self.previousVolume)
end

-- Export command classes for use by other modules
commandHistory.Command = Command
commandHistory.ToggleStepCommand = ToggleStepCommand
commandHistory.ClearPatternCommand = ClearPatternCommand
commandHistory.BPMChangeCommand = BPMChangeCommand
commandHistory.VolumeChangeCommand = VolumeChangeCommand

return commandHistory