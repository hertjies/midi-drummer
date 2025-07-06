--[[
    MIDI Drum Sequencer - sequencer.lua
    
    Core logic for the drum pattern sequencer.
    Handles timing, pattern storage, and playback control.
    
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

local sequencer = {
    pattern = {},        -- 8x16 matrix storing the drum pattern
    currentStep = 1,     -- Current position in the sequence (1-16)
    isPlaying = false,   -- Playback state
    bpm = 120,          -- Beats per minute
    stepDuration = 0,   -- Time duration of each step in seconds
    
    -- Clock-based timing system for frame-rate independent accuracy
    startTime = 0,      -- Absolute time when playback started (CPU clock)
    lastStepTime = 0,   -- Time when current step was triggered
    totalSteps = 0,     -- Total number of steps processed since start
    timingMode = "clock" -- "clock" for CPU timing, "frame" for legacy frame-based
}

-- Initialize the sequencer
-- Creates an empty 8x16 pattern matrix and resets timing state
function sequencer:init()
    -- Create 8 tracks (drums)
    for track = 1, 8 do
        self.pattern[track] = {}
        -- Create 16 steps per track
        for step = 1, 16 do
            self.pattern[track][step] = false  -- All steps start inactive
        end
    end
    
    -- Initialize timing state for clock-based system
    self.currentStep = 1
    self.isPlaying = false
    self.startTime = 0
    self.lastStepTime = 0
    self.totalSteps = 0
    
    -- Calculate step duration based on initial BPM
    self:updateStepDuration()
end

-- Calculate step duration based on current BPM
-- Formula: 60 seconds / BPM / 4 (16th notes)
function sequencer:updateStepDuration()
    self.stepDuration = 60 / self.bpm / 4
end

-- Update sequencer state using clock-based timing
-- Called every frame but timing is independent of frame rate
-- @param dt: Delta time since last frame (used for fallback mode only)
function sequencer:update(dt)
    if not self.isPlaying then
        return
    end
    
    if self.timingMode == "clock" then
        self:updateClockBased()
    else
        -- Legacy frame-based timing (kept for compatibility)
        self:updateFrameBased(dt)
    end
end

-- Clock-based timing update (frame-rate independent)
-- Uses CPU time for precise musical timing
function sequencer:updateClockBased()
    local currentTime = love.timer.getTime()  -- High-precision CPU time
    local elapsedTime = currentTime - self.startTime
    
    -- Calculate which step we should be on based on elapsed time
    local targetStepIndex = math.floor(elapsedTime / self.stepDuration)
    local targetStep = (targetStepIndex % 16) + 1  -- Wrap around 1-16
    
    -- Process any steps we've missed (handles frame drops gracefully)
    while self.totalSteps <= targetStepIndex do
        -- Calculate the actual step number (1-16)
        local stepToTrigger = (self.totalSteps % 16) + 1
        
        -- If this is a new step, advance and trigger
        if stepToTrigger ~= self.currentStep or self.totalSteps == 0 then
            self.currentStep = stepToTrigger
            self.lastStepTime = self.startTime + (self.totalSteps * self.stepDuration)
            self:triggerCurrentStep()
        end
        
        self.totalSteps = self.totalSteps + 1
        
        -- Safety check to prevent infinite loops with very large time gaps
        if self.totalSteps > targetStepIndex + 32 then
            self.totalSteps = targetStepIndex
            break
        end
    end
    
    -- Update current step to match the target
    self.currentStep = targetStep
end

-- Legacy frame-based timing update (for compatibility/testing)
-- @param dt: Delta time since last frame in seconds
function sequencer:updateFrameBased(dt)
    local stepTime = self.stepTime or 0
    stepTime = stepTime + dt
    
    -- Process multiple steps if needed (handles large dt values)
    local stepCounter = 0
    while stepTime >= self.stepDuration do
        stepTime = stepTime - self.stepDuration
        self:advanceStep()
        stepCounter = stepCounter + 1
        
        -- Safety check to prevent infinite loops
        if stepCounter > 32 then
            stepTime = stepTime % self.stepDuration
            break
        end
    end
    
    self.stepTime = stepTime
end

-- Advance to the next step in the sequence
-- Wraps around to step 1 after step 16
function sequencer:advanceStep()
    self.currentStep = self.currentStep + 1
    if self.currentStep > 16 then
        self.currentStep = 1  -- Loop back to beginning
    end
    
    -- Trigger sounds for active steps (audio module will handle in Phase 3)
    self:triggerCurrentStep()
end

-- Trigger sounds for all active tracks at the current step
-- This will be connected to the audio module in Phase 3
function sequencer:triggerCurrentStep()
    -- Play metronome click for current step (if enabled)
    if self.audio and self.audio.playMetronome then
        self.audio:playMetronome(self.currentStep)
    end
    
    -- Check each track to see if current step is active
    for track = 1, 8 do
        if self.pattern[track][self.currentStep] then
            -- Audio playback will be implemented in Phase 3
            -- For now, this serves as the integration point
            if self.audio then
                self.audio:playSample(track)
            end
        end
    end
end

-- Start playback with clock-based timing and audio system verification
-- Records start time and triggers first step immediately, but only if audio system is ready
function sequencer:play()
    -- Check if audio system is ready before starting playback
    if self.audio and not self.audio:isSystemReady() then
        print("Warning: Audio system not ready for playback. Initializing...")
        -- Try to reinitialize audio system
        if self.audio.init then
            self.audio:init()
        end
        -- If still not ready, continue but warn user
        if not self.audio:isSystemReady() then
            print("Warning: Audio system initialization incomplete. Playback may have timing issues.")
        end
    end
    
    self.isPlaying = true
    
    if self.timingMode == "clock" then
        -- Clock-based timing: record absolute start time
        self.startTime = love.timer.getTime()
        self.lastStepTime = self.startTime
        self.totalSteps = 0
        -- Current step stays where it was (allows resume from any position)
    else
        -- Legacy frame-based timing
        self.stepTime = 0
    end
    
    -- Trigger the current step immediately when starting playback
    -- This ensures the first step's sounds are played without delay
    self:triggerCurrentStep()
end

-- Stop playback and reset timing state
-- Returns to the beginning of the pattern
function sequencer:stop()
    self.isPlaying = false
    self.currentStep = 1
    
    if self.timingMode == "clock" then
        -- Reset clock-based timing state
        self.startTime = 0
        self.lastStepTime = 0
        self.totalSteps = 0
    else
        -- Reset frame-based timing state
        self.stepTime = 0
    end
end

-- Toggle a step on/off in the pattern
-- @param track: Track number (1-8)
-- @param step: Step number (1-16)
function sequencer:toggleStep(track, step)
    -- Validate input bounds
    if track >= 1 and track <= 8 and step >= 1 and step <= 16 then
        self.pattern[track][step] = not self.pattern[track][step]
    end
end

-- Set the BPM (beats per minute)
-- Clamps value between 60 and 300
-- Adjusts timing state to prevent rhythm disruption during playback
-- @param bpm: New BPM value
function sequencer:setBPM(bpm)
    local oldBPM = self.bpm
    self.bpm = math.max(60, math.min(300, bpm))
    
    -- If BPM changed and we're playing, adjust timing state
    if self.isPlaying and oldBPM ~= self.bpm then
        if self.timingMode == "clock" then
            -- Clock-based: adjust start time to maintain current rhythm position
            local currentTime = love.timer.getTime()
            local elapsedTime = currentTime - self.startTime
            local oldDuration = 60 / oldBPM / 4
            local newDuration = 60 / self.bpm / 4
            
            -- Calculate how far through the current step we are
            local stepProgress = (elapsedTime % oldDuration) / oldDuration
            
            -- Adjust start time so the new timing aligns with current position
            local newElapsedSteps = self.totalSteps + stepProgress
            self.startTime = currentTime - (newElapsedSteps * newDuration)
        else
            -- Frame-based: scale accumulated time proportionally
            local oldDuration = 60 / oldBPM / 4
            local newDuration = 60 / self.bpm / 4
            
            if oldDuration > 0 and self.stepTime then
                self.stepTime = self.stepTime * (newDuration / oldDuration)
            end
        end
    end
    
    self:updateStepDuration()
end

-- Set timing mode for the sequencer
-- @param mode: "clock" for CPU clock-based timing, "frame" for frame-based timing
function sequencer:setTimingMode(mode)
    if mode == "clock" or mode == "frame" then
        local wasPlaying = self.isPlaying
        
        -- Stop if playing to avoid timing conflicts during transition
        if wasPlaying then
            self:stop()
        end
        
        self.timingMode = mode
        
        -- Restart if we were playing
        if wasPlaying then
            self:play()
        end
    end
end

-- Get current timing information for debugging/display
-- @return: Table with timing details
function sequencer:getTimingInfo()
    local info = {
        mode = self.timingMode,
        bpm = self.bpm,
        stepDuration = self.stepDuration,
        currentStep = self.currentStep,
        isPlaying = self.isPlaying
    }
    
    if self.timingMode == "clock" then
        info.startTime = self.startTime
        info.totalSteps = self.totalSteps
        info.lastStepTime = self.lastStepTime
        if self.isPlaying then
            info.currentTime = love.timer.getTime()
            info.elapsedTime = info.currentTime - self.startTime
        end
    else
        info.stepTime = self.stepTime or 0
    end
    
    return info
end

-- Get audio system readiness and status information
-- @return: Table with audio system status or nil if no audio system
function sequencer:getAudioStatus()
    if not self.audio then
        return nil
    end
    
    local status = {
        hasAudioSystem = true,
        isAudioReady = (self.audio.isSystemReady and self.audio:isSystemReady()) or false
    }
    
    -- Get detailed status if available
    if self.audio.getSystemStatus then
        local detailedStatus = self.audio:getSystemStatus()
        for key, value in pairs(detailedStatus) do
            status[key] = value
        end
    end
    
    return status
end

-- Clear all steps in the pattern
-- Resets the entire pattern to empty
-- Clear all pattern steps
-- Sets all steps in the 8x16 pattern grid to inactive (false)
-- This provides a quick way to start with a blank pattern
-- @note Does not affect playback state or BPM settings
function sequencer:clearPattern()
    -- Iterate through all 8 tracks
    for track = 1, 8 do
        -- Iterate through all 16 steps in each track
        for step = 1, 16 do
            self.pattern[track][step] = false  -- Set step to inactive
        end
    end
end

-- Get active tracks for a specific step
-- @param step: Step number (1-16)
-- @return: Table of active track numbers
function sequencer:getActiveTracksAtStep(step)
    local activeTracks = {}
    if step >= 1 and step <= 16 then
        for track = 1, 8 do
            if self.pattern[track][step] then
                table.insert(activeTracks, track)
            end
        end
    end
    return activeTracks
end

-- Toggle metronome on/off
-- @param enabled: true to enable, false to disable, nil to toggle
-- @return: New metronome state (true/false)
function sequencer:setMetronomeEnabled(enabled)
    if self.audio and self.audio.setMetronomeEnabled then
        return self.audio:setMetronomeEnabled(enabled)
    end
    return false
end

-- Get current metronome state
-- @return: true if metronome is enabled, false otherwise
function sequencer:isMetronomeEnabled()
    if self.audio and self.audio.isMetronomeEnabled then
        return self.audio:isMetronomeEnabled()
    end
    return false
end

-- Set metronome volume for specific click type
-- @param clickType: "normal" or "accent"
-- @param volume: Volume level (0.0 to 1.0)
function sequencer:setMetronomeVolume(clickType, volume)
    if self.audio and self.audio.setMetronomeVolume then
        self.audio:setMetronomeVolume(clickType, volume)
    end
end

-- Get current metronome volume for specific click type
-- @param clickType: "normal" or "accent"
-- @return: Current metronome volume (0.0 to 1.0)
function sequencer:getMetronomeVolume(clickType)
    if self.audio and self.audio.getMetronomeVolume then
        return self.audio:getMetronomeVolume(clickType)
    end
    return 0.6  -- Default fallback
end

return sequencer