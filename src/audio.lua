--[[
    MIDI Drum Sequencer - audio.lua
    
    Handles audio sample loading and real-time playback.
    Manages drum samples and provides volume control per track.
    
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

local audio = {
    -- Audio sample storage
    samples = {},           -- Original sound data for each track
    sources = {},          -- Playable source instances for polyphony
    prebufferedSources = {}, -- Pre-created sources for immediate playback
    
    -- Track configuration
    trackNames = {
        "kick",             -- Track 1: Kick drum
        "snare",            -- Track 2: Snare drum
        "hihat_closed",     -- Track 3: Closed hi-hat
        "hihat_open",       -- Track 4: Open hi-hat
        "crash",            -- Track 5: Crash cymbal
        "ride",             -- Track 6: Ride cymbal
        "tom_low",          -- Track 7: Low tom
        "tom_high"          -- Track 8: High tom
    },
    
    -- Volume settings (0.0 to 1.0)
    volumes = {},
    
    -- Audio settings
    maxSources = 32,        -- Maximum simultaneous sounds
    prebufferCount = 4,     -- Number of pre-created sources per track
    sampleRate = 44100,     -- Expected sample rate
    bitDepth = 16,          -- Expected bit depth
    
    -- Audio timing and feedback
    triggerFeedback = {},   -- Visual feedback for audio triggers
    feedbackDuration = 0.1, -- How long trigger feedback lasts
    isReady = false,        -- Whether audio system is fully initialized and ready
    initializationStartTime = 0, -- Time when initialization started
    audioLatency = 0.005    -- Estimated audio system latency in seconds
}

-- Initialize the audio system with prebuffering for optimal timing
-- Sets up default volumes, loads samples, and creates prebuffered sources
function audio:init()
    self.initializationStartTime = love.timer and love.timer.getTime() or 0
    self.isReady = false
    
    -- Initialize volumes to default (0.7 = 70%)
    for track = 1, 8 do
        self.volumes[track] = 0.7
        self.triggerFeedback[track] = 0
    end
    
    -- Initialize source pools for polyphony
    for track = 1, 8 do
        self.sources[track] = {}
        self.prebufferedSources[track] = {}
    end
    
    -- Attempt to load default samples
    self:loadDefaultSamples()
    
    -- Create prebuffered sources for immediate playback
    self:createPrebufferedSources()
    
    -- Mark system as ready after initialization
    self.isReady = true
    
    print("Audio system initialized with prebuffering")
end

-- Load default drum samples from assets directory
-- Falls back to generating basic waveforms if files don't exist
function audio:loadDefaultSamples()
    for track = 1, 8 do
        local filename = "assets/samples/" .. self.trackNames[track] .. ".wav"
        
        -- Try to load the sample file (if love.audio is available)
        local success, sample = false, nil
        if love and love.audio and love.audio.newSource then
            success, sample = pcall(love.audio.newSource, filename, "static")
        end
        
        if success and sample then
            self.samples[track] = sample
            print("Loaded sample: " .. filename)
        else
            -- Generate a basic waveform as fallback
            self:generateFallbackSample(track)
            print("Generated fallback sample for track " .. track .. " (" .. self.trackNames[track] .. ")")
        end
    end
end

-- Create prebuffered audio sources for immediate playback
-- Pre-creates sources to eliminate initialization delay during playback
function audio:createPrebufferedSources()
    for track = 1, 8 do
        if self.samples[track] then
            -- Create multiple prebuffered sources for polyphony
            for i = 1, self.prebufferCount do
                local source = self.samples[track]:clone()
                source:setVolume(self.volumes[track])
                table.insert(self.prebufferedSources[track], source)
            end
        end
    end
end

-- Generate a basic waveform sample as fallback
-- Creates simple synthetic sounds when audio files are not available
-- @param track: Track number (1-8)
function audio:generateFallbackSample(track)
    local sampleRate = 44100
    local duration = 0.2  -- 200ms samples
    local samples = math.floor(sampleRate * duration)
    
    -- Create sound data (if love.sound is available)
    if not (love and love.sound and love.sound.newSoundData) then
        -- Create a minimal dummy sample if Love2D sound is not available
        self.samples[track] = {
            clone = function() 
                return {
                    clone = function() return self.samples[track] end,
                    setVolume = function() end,
                    isPlaying = function() return false end
                }
            end,
            setVolume = function() end,
            isPlaying = function() return false end
        }
        return
    end
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Generate different waveforms based on track type
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local amplitude = math.exp(-t * 5) -- Exponential decay
        local sample = 0
        
        if track == 1 then
            -- Kick: Low frequency sine wave
            sample = amplitude * math.sin(2 * math.pi * 60 * t)
        elseif track == 2 then
            -- Snare: Noise burst with tone
            local noise = (math.random() - 0.5) * 2
            local tone = math.sin(2 * math.pi * 200 * t)
            sample = amplitude * (noise * 0.7 + tone * 0.3)
        elseif track == 3 or track == 4 then
            -- Hi-hats: High frequency noise
            sample = amplitude * (math.random() - 0.5) * 2
            amplitude = amplitude * math.exp(-t * 20) -- Faster decay for hi-hats
        elseif track == 5 then
            -- Crash: Bright noise with long decay
            sample = amplitude * (math.random() - 0.5) * 2 * math.exp(-t * 2)
        elseif track == 6 then
            -- Ride: Metallic tone
            sample = amplitude * (math.sin(2 * math.pi * 300 * t) + math.sin(2 * math.pi * 900 * t)) * 0.5
        elseif track == 7 then
            -- Low tom: Mid-low frequency
            sample = amplitude * math.sin(2 * math.pi * 100 * t)
        elseif track == 8 then
            -- High tom: Mid-high frequency
            sample = amplitude * math.sin(2 * math.pi * 150 * t)
        end
        
        -- Apply final amplitude and clamp
        sample = math.max(-1, math.min(1, sample * amplitude))
        soundData:setSample(i, sample)
    end
    
    -- Create source from generated data
    if love and love.audio and love.audio.newSource then
        self.samples[track] = love.audio.newSource(soundData)
    end
end

-- Load a custom sample for a specific track
-- @param track: Track number (1-8)
-- @param filepath: Path to the audio file
-- @return: true if successful, false otherwise
function audio:loadSample(track, filepath)
    if track < 1 or track > 8 then
        print("Error: Invalid track number " .. track)
        return false
    end
    
    local success, sample = pcall(love.audio.newSource, filepath, "static")
    
    if success and sample then
        self.samples[track] = sample
        -- Clear existing source pool for this track
        self.sources[track] = {}
        print("Loaded custom sample for track " .. track .. ": " .. filepath)
        return true
    else
        print("Error loading sample: " .. filepath)
        return false
    end
end

-- Play a sample for a specific track
-- Play audio sample with optimal timing and coordination
-- Uses prebuffered sources for minimal latency and coordinates visual feedback
-- @param track: Track number (1-8)
-- @param delayVisualFeedback: Optional delay for visual feedback (for timing coordination)
function audio:playSample(track, delayVisualFeedback)
    if track < 1 or track > 8 or not self.samples[track] or not self.isReady then
        return false
    end
    
    local source = nil
    
    -- Try to use a prebuffered source first for minimal latency
    if #self.prebufferedSources[track] > 0 then
        source = table.remove(self.prebufferedSources[track], 1)
        -- Update volume in case it changed
        source:setVolume(self.volumes[track])
    else
        -- Fall back to creating a new source if prebuffer is empty
        source = self.samples[track]:clone()
        source:setVolume(self.volumes[track])
    end
    
    -- Play the sound immediately (if love.audio is available)
    if love and love.audio and love.audio.play then
        love.audio.play(source)
    end
    
    -- Add to source pool for tracking
    table.insert(self.sources[track], source)
    
    -- Handle visual feedback timing coordination
    if delayVisualFeedback and delayVisualFeedback > 0 then
        -- Schedule visual feedback to align with audio
        self:scheduleVisualFeedback(track, delayVisualFeedback)
    else
        -- Immediate visual feedback (default behavior)
        self.triggerFeedback[track] = self.feedbackDuration
    end
    
    -- Replenish prebuffered sources
    self:replenishPrebufferedSource(track)
    
    -- Clean up finished sources to prevent memory leaks
    self:cleanupSources(track)
    
    return true
end

-- Clean up finished audio sources to prevent memory leaks
-- @param track: Track number (1-8), or nil for all tracks
function audio:cleanupSources(track)
    if track then
        -- Clean specific track
        local activeSources = {}
        for _, source in ipairs(self.sources[track]) do
            if source:isPlaying() then
                table.insert(activeSources, source)
            end
        end
        self.sources[track] = activeSources
    else
        -- Clean all tracks
        for t = 1, 8 do
            self:cleanupSources(t)
        end
    end
end

-- Replenish a prebuffered source for a track to maintain buffer
-- Ensures we always have sources ready for immediate playback
-- @param track: Track number (1-8)
function audio:replenishPrebufferedSource(track)
    if track >= 1 and track <= 8 and self.samples[track] then
        if #self.prebufferedSources[track] < self.prebufferCount then
            local source = self.samples[track]:clone()
            source:setVolume(self.volumes[track])
            table.insert(self.prebufferedSources[track], source)
        end
    end
end

-- Schedule visual feedback to align with audio timing
-- Coordinates visual feedback to match when audio actually plays
-- @param track: Track number (1-8)
-- @param delay: Delay in seconds before triggering visual feedback
function audio:scheduleVisualFeedback(track, delay)
    -- For now, we'll implement immediate feedback but store the delay
    -- This could be enhanced with a timer system for precise coordination
    self.triggerFeedback[track] = self.feedbackDuration
    -- TODO: Implement actual delayed feedback scheduling in future iteration
end

-- Check if the audio system is ready for playback
-- Returns true if all samples are loaded and prebuffer is ready
-- @return: Boolean indicating readiness
function audio:isSystemReady()
    if not self.isReady then
        return false
    end
    
    -- Check that all tracks have samples and prebuffered sources
    for track = 1, 8 do
        if not self.samples[track] or #self.prebufferedSources[track] == 0 then
            return false
        end
    end
    
    return true
end

-- Get audio system status information for debugging
-- @return: Table with detailed audio system status
function audio:getSystemStatus()
    local status = {
        isReady = self.isReady,
        isSystemReady = self:isSystemReady(),
        estimatedLatency = self.audioLatency,
        prebufferStatus = {}
    }
    
    for track = 1, 8 do
        status.prebufferStatus[track] = {
            hasSample = self.samples[track] ~= nil,
            prebufferedCount = #self.prebufferedSources[track],
            activeSourceCount = #self.sources[track],
            volume = self.volumes[track]
        }
    end
    
    return status
end

-- Set volume for a specific track and update all associated sources
-- @param track: Track number (1-8)
-- @param volume: Volume level (0.0 to 1.0)
function audio:setVolume(track, volume)
    if track >= 1 and track <= 8 then
        self.volumes[track] = math.max(0, math.min(1, volume))
        
        -- Update volume for all prebuffered sources
        for _, source in ipairs(self.prebufferedSources[track]) do
            source:setVolume(self.volumes[track])
        end
        
        -- Update volume for all active sources
        for _, source in ipairs(self.sources[track]) do
            source:setVolume(self.volumes[track])
        end
    end
end

-- Get volume for a specific track
-- @param track: Track number (1-8)
-- @return: Volume level (0.0 to 1.0)
function audio:getVolume(track)
    if track >= 1 and track <= 8 then
        return self.volumes[track]
    end
    return 0
end

-- Update audio system
-- Called every frame to update trigger feedback and cleanup
-- @param dt: Delta time since last frame
function audio:update(dt)
    -- Update trigger feedback timers
    for track = 1, 8 do
        if self.triggerFeedback[track] > 0 then
            self.triggerFeedback[track] = self.triggerFeedback[track] - dt
            if self.triggerFeedback[track] < 0 then
                self.triggerFeedback[track] = 0
            end
        end
    end
    
    -- Periodic cleanup (every 60 frames at 60fps = 1 second)
    if love.timer.getTime() % 1 < dt then
        self:cleanupSources()
    end
end

-- Check if a track has trigger feedback active
-- Used for visual feedback in UI
-- @param track: Track number (1-8)
-- @return: true if feedback is active
function audio:hasTriggerFeedback(track)
    if track >= 1 and track <= 8 then
        return self.triggerFeedback[track] > 0
    end
    return false
end

-- Stop all playing sounds
-- Useful for stopping playback immediately
function audio:stopAll()
    for track = 1, 8 do
        for _, source in ipairs(self.sources[track]) do
            if source:isPlaying() then
                source:stop()
            end
        end
        self.sources[track] = {}
    end
end

-- Get audio system statistics
-- @return: Table with audio statistics
function audio:getStats()
    local stats = {
        totalSources = 0,
        samplesLoaded = 0
    }
    
    for track = 1, 8 do
        if self.samples[track] then
            stats.samplesLoaded = stats.samplesLoaded + 1
        end
        stats.totalSources = stats.totalSources + #self.sources[track]
    end
    
    return stats
end

return audio