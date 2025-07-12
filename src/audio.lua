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
    audioLatency = 0.005,   -- Estimated audio system latency in seconds
    
    -- Metronome system
    metronomeEnabled = false,     -- Whether metronome is currently enabled
    metronomeSamples = {},        -- Metronome sound samples (normal and accent)
    metronomeSources = {},        -- Prebuffered metronome sources
    metronomeVolumes = {          -- Separate volumes for normal and accent clicks
        normal = 0.6,             -- Default normal click volume (0.0 to 1.0)
        accent = 0.8              -- Default accent click volume (0.0 to 1.0)
    }
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
    
    -- Initialize metronome sounds
    self:initializeMetronome()
    
    -- Mark system as ready after initialization
    self.isReady = true
    
    print("Audio system initialized with prebuffering")
end

-- Load default drum samples from assets directory
-- Falls back to generating basic waveforms if files don't exist
function audio:loadDefaultSamples()
    local loadedCount = 0
    local generatedCount = 0
    
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
            loadedCount = loadedCount + 1
        else
            -- Generate a basic waveform as fallback
            self:generateFallbackSample(track)
            print("Generated fallback sample for track " .. track .. " (" .. self.trackNames[track] .. ")")
            generatedCount = generatedCount + 1
        end
    end
    
    -- Print summary
    if loadedCount > 0 and generatedCount > 0 then
        print("Audio: Loaded " .. loadedCount .. " WAV samples, generated " .. generatedCount .. " procedural samples")
    elseif loadedCount == 8 then
        print("Audio: All samples loaded from WAV files - high quality audio enabled")
    elseif generatedCount == 8 then
        print("Audio: Using procedural generation - place WAV files in assets/samples/ for better quality")
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
    
    -- Generate realistic drum sounds using advanced synthesis
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local sample = 0
        
        if track == 1 then
            -- Kick: Punchy kick with click and sub-bass
            local click_env = math.exp(-t * 50)  -- Sharp attack envelope
            local sub_env = math.exp(-t * 3)     -- Longer sustain envelope
            local click = math.sin(2 * math.pi * 80 * t) * click_env * 0.3
            local sub = math.sin(2 * math.pi * 45 * t) * sub_env * 0.7
            sample = click + sub
            
        elseif track == 2 then
            -- Snare: Realistic snare with body and snares
            local body_env = math.exp(-t * 8)
            local snare_env = math.exp(-t * 15)
            local body = math.sin(2 * math.pi * 200 * t) * body_env * 0.4
            local snares = (math.random() - 0.5) * 2 * snare_env * 0.6
            -- Add some harmonic content
            local harmonic = math.sin(2 * math.pi * 400 * t) * body_env * 0.2
            sample = body + snares + harmonic
            
        elseif track == 3 then
            -- Closed Hi-hat: Crisp, short metallic sound
            local env = math.exp(-t * 25)
            local noise = (math.random() - 0.5) * 2 * env
            -- Add metallic shimmer
            local metallic = (math.sin(2 * math.pi * 8000 * t) + math.sin(2 * math.pi * 12000 * t)) * env * 0.3
            sample = noise * 0.7 + metallic
            
        elseif track == 4 then
            -- Open Hi-hat: Longer, more sizzling
            local env = math.exp(-t * 4)  -- Longer decay
            local noise = (math.random() - 0.5) * 2 * env
            -- More complex metallic content
            local sizzle = (math.sin(2 * math.pi * 10000 * t) + math.sin(2 * math.pi * 15000 * t) + math.sin(2 * math.pi * 6000 * t)) * env * 0.4
            sample = noise * 0.6 + sizzle
            
        elseif track == 5 then
            -- Crash: Complex, long-sustaining cymbal
            local env = math.exp(-t * 1.5)  -- Very long decay
            local noise = (math.random() - 0.5) * 2 * env
            -- Complex harmonic series for realistic cymbal sound
            local harmonics = (
                math.sin(2 * math.pi * 3000 * t) + 
                math.sin(2 * math.pi * 5000 * t) + 
                math.sin(2 * math.pi * 8000 * t) + 
                math.sin(2 * math.pi * 12000 * t)
            ) * env * 0.3
            sample = noise * 0.7 + harmonics
            
        elseif track == 6 then
            -- Ride: Defined ping with sustain
            local ping_env = math.exp(-t * 20)
            local sustain_env = math.exp(-t * 2)
            local ping = math.sin(2 * math.pi * 2500 * t) * ping_env * 0.5
            local sustain = (math.sin(2 * math.pi * 4000 * t) + math.sin(2 * math.pi * 6000 * t)) * sustain_env * 0.3
            local noise = (math.random() - 0.5) * 2 * sustain_env * 0.2
            sample = ping + sustain + noise
            
        elseif track == 7 then
            -- Low tom: Deep, resonant tom
            local env = math.exp(-t * 6)
            local fundamental = math.sin(2 * math.pi * 80 * t) * env * 0.8
            local harmonic = math.sin(2 * math.pi * 160 * t) * env * 0.3
            -- Add some attack punch
            local attack = math.sin(2 * math.pi * 200 * t) * math.exp(-t * 30) * 0.2
            sample = fundamental + harmonic + attack
            
        elseif track == 8 then
            -- High tom: Bright, punchy tom
            local env = math.exp(-t * 8)
            local fundamental = math.sin(2 * math.pi * 120 * t) * env * 0.8
            local harmonic = math.sin(2 * math.pi * 240 * t) * env * 0.4
            -- Add attack definition
            local attack = math.sin(2 * math.pi * 300 * t) * math.exp(-t * 35) * 0.3
            sample = fundamental + harmonic + attack
        end
        
        -- Apply compression-like limiting and clamp
        sample = sample * 0.8  -- Reduce overall level to prevent clipping
        sample = math.max(-1, math.min(1, sample))
        soundData:setSample(i, sample)
    end
    
    -- Create source from generated data
    if love and love.audio and love.audio.newSource then
        self.samples[track] = love.audio.newSource(soundData)
    end
end

-- Initialize metronome sounds and prebuffered sources
-- Creates two metronome sounds: normal click and accented click
function audio:initializeMetronome()
    -- Initialize metronome sources containers
    self.metronomeSources = {
        normal = {},  -- Sources for normal clicks
        accent = {}   -- Sources for accented clicks
    }
    
    -- Generate metronome sounds if Love2D audio is available
    if not (love and love.audio and love.sound) then
        print("Metronome: Audio system not available, using silent metronome")
        return
    end
    
    -- Generate normal metronome click (clock tick sound)
    self:generateClockTick("normal", 1000, 0.04)  -- 1000Hz, 40ms duration
    
    -- Generate accented metronome click (accented clock tick sound) 
    self:generateClockTick("accent", 1400, 0.06)  -- 1400Hz, 60ms duration
    
    -- Create prebuffered sources for both types with separate volumes
    for clickType, _ in pairs(self.metronomeSamples) do
        for i = 1, 4 do  -- 4 prebuffered sources each
            if self.metronomeSamples[clickType] then
                local source = self.metronomeSamples[clickType]:clone()
                source:setVolume(self.metronomeVolumes[clickType])
                table.insert(self.metronomeSources[clickType], source)
            end
        end
    end
    
    print("Metronome initialized with normal and accent clicks")
end

-- Generate a clock tick sound that mimics a real mechanical clock
-- @param clickType: "normal" or "accent"
-- @param frequency: Primary tick frequency in Hz
-- @param duration: Click duration in seconds
function audio:generateClockTick(clickType, frequency, duration)
    local samples = math.floor(duration * self.sampleRate)
    local soundData = love.sound.newSoundData(samples, self.sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / self.sampleRate
        
        -- Create a clock-like tick with multiple frequency components
        local amplitude = 0.4  -- Base amplitude
        
        -- Primary frequency component (main tick)
        local primary = math.sin(2 * math.pi * frequency * t)
        
        -- Higher harmonic for metallic click character
        local harmonic = math.sin(2 * math.pi * frequency * 2.3 * t) * 0.3
        
        -- Brief noise burst for mechanical click character (first 5ms)
        local noise = 0
        if t < 0.005 then
            noise = (math.random() - 0.5) * 0.4 * (1 - t / 0.005)
        end
        
        -- Combine components
        local wave = primary + harmonic + noise
        
        -- Create sharp attack and quick decay envelope for crisp tick
        local envelope = 1.0
        if t < 0.002 then
            -- Very sharp attack (2ms)
            envelope = t / 0.002
        else
            -- Exponential decay after attack
            envelope = math.exp(-(t - 0.002) * 25)
        end
        
        -- Apply accent emphasis for accent clicks
        if clickType == "accent" then
            amplitude = amplitude * 1.3  -- 30% louder
            -- Add lower frequency component for fuller sound
            local lowComponent = math.sin(2 * math.pi * frequency * 0.5 * t) * 0.2
            wave = wave + lowComponent
        end
        
        local sample = wave * envelope * amplitude
        
        -- Clamp to valid range
        sample = math.max(-1, math.min(1, sample))
        soundData:setSample(i, sample)
    end
    
    -- Create audio source from generated data
    self.metronomeSamples[clickType] = love.audio.newSource(soundData)
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
-- @param velocity: Optional velocity (0.0-1.0, defaults to 1.0 for backward compatibility)
function audio:playSample(track, delayVisualFeedback, velocity)
    if track < 1 or track > 8 or not self.samples[track] or not self.isReady then
        return false
    end
    
    local source = nil
    
    -- Calculate final volume (track volume * velocity)
    local normalizedVelocity = velocity or 1.0  -- Default to full velocity
    local finalVolume = self.volumes[track] * normalizedVelocity
    
    -- Try to use a prebuffered source first for minimal latency
    if #self.prebufferedSources[track] > 0 then
        source = table.remove(self.prebufferedSources[track], 1)
        -- Set volume with velocity applied
        source:setVolume(finalVolume)
    else
        -- Fall back to creating a new source if prebuffer is empty
        source = self.samples[track]:clone()
        source:setVolume(finalVolume)
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

-- Reset all track volumes to 70% (default level)
-- Sets all 8 tracks to the standard 0.7 volume level
-- Updates all prebuffered and active sources immediately
function audio:resetAllVolumes()
    for track = 1, 8 do
        self:setVolume(track, 0.7)  -- Reset to 70% volume
    end
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

-- Toggle metronome on/off
-- @param enabled: true to enable, false to disable, nil to toggle current state
-- @return: New metronome state (true/false)
function audio:setMetronomeEnabled(enabled)
    if enabled == nil then
        -- Toggle current state
        self.metronomeEnabled = not self.metronomeEnabled
    else
        self.metronomeEnabled = enabled
    end
    
    print("Metronome " .. (self.metronomeEnabled and "enabled" or "disabled"))
    return self.metronomeEnabled
end

-- Get current metronome state
-- @return: true if metronome is enabled, false otherwise
function audio:isMetronomeEnabled()
    return self.metronomeEnabled
end

-- Set metronome volume for specific click type
-- @param clickType: "normal" or "accent"
-- @param volume: Volume level (0.0 to 1.0)
function audio:setMetronomeVolume(clickType, volume)
    if not self.metronomeVolumes[clickType] then
        print("Error: Invalid metronome click type: " .. tostring(clickType))
        return
    end
    
    self.metronomeVolumes[clickType] = math.max(0, math.min(1, volume))
    
    -- Update volume on all prebuffered metronome sources of this type
    if self.metronomeSources[clickType] then
        for _, source in ipairs(self.metronomeSources[clickType]) do
            source:setVolume(self.metronomeVolumes[clickType])
        end
    end
end

-- Get current metronome volume for specific click type
-- @param clickType: "normal" or "accent"
-- @return: Current metronome volume (0.0 to 1.0)
function audio:getMetronomeVolume(clickType)
    if not self.metronomeVolumes[clickType] then
        return 0.6  -- Default fallback
    end
    return self.metronomeVolumes[clickType]
end

-- Play a metronome click for the specified step
-- @param step: Current step number (1-16)
-- @param delayVisualFeedback: Optional delay for visual feedback alignment
function audio:playMetronome(step, delayVisualFeedback)
    -- Only play if metronome is enabled
    if not self.metronomeEnabled then
        return
    end
    
    -- Check if audio system is available
    if not (love and love.audio and love.audio.play) then
        return
    end
    
    -- Determine if this is an accented beat (steps 1, 5, 9, 13)
    local isAccent = (step == 1 or step == 5 or step == 9 or step == 13)
    local clickType = isAccent and "accent" or "normal"
    
    -- Get an available prebuffered source
    local source = nil
    if #self.metronomeSources[clickType] > 0 then
        source = table.remove(self.metronomeSources[clickType], 1)
        -- Update volume in case it changed
        source:setVolume(self.metronomeVolumes[clickType])
    elseif self.metronomeSamples[clickType] then
        -- Fall back to creating a new source
        source = self.metronomeSamples[clickType]:clone()
        source:setVolume(self.metronomeVolumes[clickType])
    end
    
    if source then
        -- Play the metronome click
        love.audio.play(source)
        
        -- Return source to pool after a short delay (longer than click duration)
        -- This is a simple approach - in a production system you might want
        -- more sophisticated source management
        self:scheduleMetronomeSourceReturn(source, clickType, 0.15)
    end
end

-- Schedule return of metronome source to the prebuffered pool
-- @param source: Audio source to return
-- @param clickType: "normal" or "accent" 
-- @param delay: Delay before returning (in seconds)
function audio:scheduleMetronomeSourceReturn(source, clickType, delay)
    -- Simple implementation: add back to pool immediately
    -- In a more complex system, you might use a timer
    table.insert(self.metronomeSources[clickType], source)
end

return audio