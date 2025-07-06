--[[
    MIDI Drum Sequencer - ui.lua
    
    Handles all user interface rendering and interaction.
    Includes grid display, transport controls, and mouse handling.
    
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

local ui = {
    -- Grid positioning and sizing
    gridX = 50,         -- Grid left position
    gridY = 100,        -- Grid top position
    cellSize = 32,      -- Size of each grid cell in pixels
    cellPadding = 2,    -- Space between cells
    
    -- Transport control positioning
    transportY = 50,    -- Y position for transport buttons
    buttonWidth = 80,   -- Width of transport buttons
    buttonHeight = 30,  -- Height of transport buttons
    
    -- Track labels for the drum sounds
    trackLabels = {
        "Kick",         -- Track 1
        "Snare",        -- Track 2
        "Hi-Hat C",     -- Track 3 (Closed Hi-Hat)
        "Hi-Hat O",     -- Track 4 (Open Hi-Hat)
        "Crash",        -- Track 5
        "Ride",         -- Track 6
        "Tom Low",      -- Track 7
        "Tom High"      -- Track 8
    },
    
    -- UI state
    hoveredCell = nil,      -- Currently hovered grid cell {track, step}
    clickedButton = nil,    -- Currently pressed button name
    
    -- BPM control state
    bpmSliderX = 520,       -- BPM slider X position (moved to avoid export button conflict)
    bpmSliderY = 50,        -- BPM slider Y position
    bpmSliderWidth = 200,   -- BPM slider width
    bpmSliderHeight = 20,   -- BPM slider height
    bpmDragging = false,    -- Whether user is dragging BPM slider
    
    -- Volume control state
    volumeSliderWidth = 80, -- Width of volume sliders
    volumeSliderHeight = 10,-- Height of volume sliders
    volumeDragging = nil    -- Track number being dragged, or nil
}

-- Initialize the UI module
-- Loads required modules for interaction
function ui:init()
    self.sequencer = require("src.sequencer")
    self.audio = require("src.audio")
    self.midi = require("src.midi")
    self.utils = require("src.utils")
end

-- Update UI state
-- Currently unused but reserved for future UI animations
-- @param dt: Delta time since last frame
function ui:update(dt)
    -- Reserved for future UI updates (animations, transitions, etc.)
end

-- Main draw function
-- Renders all UI elements
function ui:draw()
    self:drawTransportControls()  -- Play/Stop/Reset buttons
    self:drawGrid()              -- Pattern grid
    self:drawBPMControl()        -- BPM display
    self:drawVolumeControls()    -- Volume sliders
end

-- Draw the pattern grid
-- Renders the 16x8 grid with track labels and step numbers
function ui:drawGrid()
    -- Set white color for labels
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    -- Draw track labels on the left
    for track = 1, 8 do
        love.graphics.print(
            self.trackLabels[track], 
            self.gridX - 45, 
            self.gridY + (track - 1) * (self.cellSize + self.cellPadding) + 8
        )
    end
    
    -- Draw step numbers on top
    for step = 1, 16 do
        love.graphics.print(
            step, 
            self.gridX + (step - 1) * (self.cellSize + self.cellPadding) + 10, 
            self.gridY - 20
        )
    end
    
    -- Draw grid cells
    for track = 1, 8 do
        for step = 1, 16 do
            local x = self.gridX + (step - 1) * (self.cellSize + self.cellPadding)
            local y = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
            
            -- Set cell color based on state
            local isActive = self.sequencer.pattern[track][step]
            local hasTriggerFeedback = self.audio and self.audio:hasTriggerFeedback(track)
            
            if isActive then
                if hasTriggerFeedback then
                    love.graphics.setColor(1, 0.5, 0.5)  -- Bright red for triggered active steps
                else
                    love.graphics.setColor(0.8, 0.3, 0.3)  -- Red for active steps
                end
            else
                if hasTriggerFeedback then
                    love.graphics.setColor(0.5, 0.5, 0.5)  -- Light gray for triggered inactive steps
                else
                    love.graphics.setColor(0.3, 0.3, 0.3)  -- Dark gray for inactive
                end
            end
            
            -- Draw cell
            love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
            
            -- Draw current step indicator during playback
            if self.sequencer.currentStep == step and self.sequencer.isPlaying then
                love.graphics.setColor(1, 1, 0)  -- Yellow
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", x - 1, y - 1, self.cellSize + 2, self.cellSize + 2)
            end
            
            -- Draw hover effect
            if self.hoveredCell and self.hoveredCell.track == track and self.hoveredCell.step == step then
                love.graphics.setColor(1, 1, 1, 0.3)  -- Semi-transparent white
                love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
            end
        end
    end
end

-- Draw transport control buttons
-- Renders Play, Stop, Reset, and Export buttons
function ui:drawTransportControls()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- Calculate button positions
    local playX = 200
    local stopX = playX + self.buttonWidth + 10
    local resetX = stopX + self.buttonWidth + 10
    local exportX = resetX + self.buttonWidth + 10
    
    -- Draw buttons with appropriate states
    self:drawButton("PLAY", playX, self.transportY, self.buttonWidth, self.buttonHeight, self.sequencer.isPlaying)
    self:drawButton("STOP", stopX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("RESET", resetX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("EXPORT", exportX, self.transportY, self.buttonWidth, self.buttonHeight, false)
end

-- Draw a single button
-- @param text: Button label
-- @param x, y: Button position
-- @param w, h: Button dimensions
-- @param active: Whether button is in active state
function ui:drawButton(text, x, y, w, h, active)
    -- Set button color based on state
    if active then
        love.graphics.setColor(0.3, 0.8, 0.3)      -- Green for active
    elseif self.clickedButton == text then
        love.graphics.setColor(0.5, 0.5, 0.5)      -- Gray for pressed
    else
        love.graphics.setColor(0.4, 0.4, 0.4)      -- Dark gray for normal
    end
    
    -- Draw button background
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Draw button border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- Draw centered text
    local font = love.graphics.getFont()
    local textW = font:getWidth(text)
    local textH = font:getHeight()
    love.graphics.print(text, x + (w - textW) / 2, y + (h - textH) / 2)
end

-- Draw BPM display and controls
-- Shows current BPM with slider and adjustment buttons
function ui:drawBPMControl()
    -- Draw BPM label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("BPM:", self.bpmSliderX - 50, self.bpmSliderY)
    
    -- Draw current BPM value
    love.graphics.print(tostring(self.sequencer.bpm), self.bpmSliderX + self.bpmSliderWidth + 10, self.bpmSliderY)
    
    -- Draw decrease button
    self:drawButton("-", self.bpmSliderX - 30, self.bpmSliderY - 5, 25, 25, false)
    
    -- Draw increase button  
    self:drawButton("+", self.bpmSliderX + self.bpmSliderWidth + 40, self.bpmSliderY - 5, 25, 25, false)
    
    -- Draw slider track
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.bpmSliderX, self.bpmSliderY + 5, self.bpmSliderWidth, 10)
    
    -- Draw slider border
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", self.bpmSliderX, self.bpmSliderY + 5, self.bpmSliderWidth, 10)
    
    -- Calculate slider handle position
    local normalizedBPM = (self.sequencer.bpm - 60) / (300 - 60)  -- Normalize to 0-1
    local handleX = self.bpmSliderX + normalizedBPM * self.bpmSliderWidth
    
    -- Draw slider handle
    if self.bpmDragging then
        love.graphics.setColor(0.9, 0.9, 0.9)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    love.graphics.circle("fill", handleX, self.bpmSliderY + 10, 8)
    
    -- Draw handle border
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", handleX, self.bpmSliderY + 10, 8)
end

-- Draw volume controls for each track
-- Shows volume sliders next to track labels
function ui:drawVolumeControls()
    if not self.audio then return end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    
    for track = 1, 8 do
        local trackY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
        local sliderX = self.gridX + 16 * (self.cellSize + self.cellPadding) + 20
        local sliderY = trackY + (self.cellSize - self.volumeSliderHeight) / 2
        
        -- Draw volume label
        love.graphics.print("Vol", sliderX - 25, sliderY - 2)
        
        -- Draw slider track
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
        
        -- Draw slider border
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
        
        -- Calculate handle position
        local volume = self.audio:getVolume(track)
        local handleX = sliderX + volume * self.volumeSliderWidth
        
        -- Draw slider handle
        if self.volumeDragging == track then
            love.graphics.setColor(0.9, 0.9, 0.9)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle("fill", handleX - 2, sliderY - 2, 4, self.volumeSliderHeight + 4)
        
        -- Draw volume percentage
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%d%%", math.floor(volume * 100)), sliderX + self.volumeSliderWidth + 5, sliderY - 2)
    end
end

-- Handle mouse press events
-- @param x, y: Mouse coordinates
function ui:mousepressed(x, y)
    -- Check grid clicks
    local cellX = math.floor((x - self.gridX) / (self.cellSize + self.cellPadding)) + 1
    local cellY = math.floor((y - self.gridY) / (self.cellSize + self.cellPadding)) + 1
    
    -- Toggle grid cell if within bounds
    if cellX >= 1 and cellX <= 16 and cellY >= 1 and cellY <= 8 then
        local pixelX = self.gridX + (cellX - 1) * (self.cellSize + self.cellPadding)
        local pixelY = self.gridY + (cellY - 1) * (self.cellSize + self.cellPadding)
        
        -- Check if click is within cell (not in padding)
        if self.utils.pointInRect(x, y, pixelX, pixelY, self.cellSize, self.cellSize) then
            self.sequencer:toggleStep(cellY, cellX)  -- Note: track = cellY, step = cellX
        end
    end
    
    -- Check transport button clicks
    local playX = 200
    local stopX = playX + self.buttonWidth + 10
    local resetX = stopX + self.buttonWidth + 10
    local exportX = resetX + self.buttonWidth + 10
    
    if self.utils.pointInRect(x, y, playX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "PLAY"
        self.sequencer:play()
    elseif self.utils.pointInRect(x, y, stopX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "STOP"
        self.sequencer:stop()
    elseif self.utils.pointInRect(x, y, resetX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "RESET"
        self.sequencer:stop()  -- Reset also stops playback
    elseif self.utils.pointInRect(x, y, exportX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "EXPORT"
        self:exportMIDI()
    end
    
    -- Check BPM controls (only if not already handled by transport buttons)
    if not self.clickedButton then
        -- Decrease BPM button
        if self.utils.pointInRect(x, y, self.bpmSliderX - 30, self.bpmSliderY - 5, 25, 25) then
            self.clickedButton = "-"
            self.sequencer:setBPM(self.sequencer.bpm - 5)
        -- Increase BPM button
        elseif self.utils.pointInRect(x, y, self.bpmSliderX + self.bpmSliderWidth + 40, self.bpmSliderY - 5, 25, 25) then
            self.clickedButton = "+"
            self.sequencer:setBPM(self.sequencer.bpm + 5)
        -- Check if clicking on slider handle or track
        elseif self.utils.pointInRect(x, y, self.bpmSliderX - 10, self.bpmSliderY, self.bpmSliderWidth + 20, 20) then
            self.bpmDragging = true
            self:updateBPMFromMouse(x)
        end
    end
    
    -- Check track label clicks (for audio testing) - only if not already handled
    if self.audio and not self.clickedButton and not self.bpmDragging then
        for track = 1, 8 do
            local labelY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding) + 8
            if self.utils.pointInRect(x, y, self.gridX - 45, labelY, 40, 16) then
                self.audio:playSample(track)
                break
            end
        end
    end
    
    -- Check volume slider clicks - only if not already handled
    if self.audio and not self.clickedButton and not self.bpmDragging then
        for track = 1, 8 do
            local trackY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
            local sliderX = self.gridX + 16 * (self.cellSize + self.cellPadding) + 20
            local sliderY = trackY + (self.cellSize - self.volumeSliderHeight) / 2
            
            if self.utils.pointInRect(x, y, sliderX - 5, sliderY - 5, self.volumeSliderWidth + 10, self.volumeSliderHeight + 10) then
                self.volumeDragging = track
                self:updateVolumeFromMouse(track, x)
                break
            end
        end
    end
end

-- Handle mouse release events
-- Clears clicked button state and stops BPM dragging
-- @param x, y: Mouse coordinates
function ui:mousereleased(x, y)
    self.clickedButton = nil
    self.bpmDragging = false
    self.volumeDragging = nil
end

-- Handle mouse movement
-- Updates hover state for grid cells and handles BPM slider dragging
-- @param x, y: Current mouse coordinates
function ui:mousemoved(x, y)
    -- Handle BPM slider dragging
    if self.bpmDragging then
        self:updateBPMFromMouse(x)
    end
    
    -- Handle volume slider dragging
    if self.volumeDragging then
        self:updateVolumeFromMouse(self.volumeDragging, x)
    end
    
    -- Calculate grid cell under mouse
    local cellX = math.floor((x - self.gridX) / (self.cellSize + self.cellPadding)) + 1
    local cellY = math.floor((y - self.gridY) / (self.cellSize + self.cellPadding)) + 1
    
    -- Update hover state if within grid bounds
    if cellX >= 1 and cellX <= 16 and cellY >= 1 and cellY <= 8 then
        local pixelX = self.gridX + (cellX - 1) * (self.cellSize + self.cellPadding)
        local pixelY = self.gridY + (cellY - 1) * (self.cellSize + self.cellPadding)
        
        -- Only hover if mouse is within cell (not in padding)
        if self.utils.pointInRect(x, y, pixelX, pixelY, self.cellSize, self.cellSize) then
            self.hoveredCell = {track = cellY, step = cellX}
        else
            self.hoveredCell = nil
        end
    else
        self.hoveredCell = nil
    end
end

-- Update BPM based on mouse position
-- @param mouseX: Current mouse X coordinate
function ui:updateBPMFromMouse(mouseX)
    -- Calculate normalized position (0-1) along slider
    local relativeX = mouseX - self.bpmSliderX
    local normalized = self.utils.clamp(relativeX / self.bpmSliderWidth, 0, 1)
    
    -- Convert to BPM range (60-300)
    local newBPM = math.floor(60 + normalized * (300 - 60))
    self.sequencer:setBPM(newBPM)
end

-- Update volume based on mouse position
-- @param track: Track number (1-8)
-- @param mouseX: Current mouse X coordinate
function ui:updateVolumeFromMouse(track, mouseX)
    if not self.audio then return end
    
    -- Calculate slider position
    local trackY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
    local sliderX = self.gridX + 16 * (self.cellSize + self.cellPadding) + 20
    
    -- Calculate normalized position (0-1) along slider
    local relativeX = mouseX - sliderX
    local normalized = self.utils.clamp(relativeX / self.volumeSliderWidth, 0, 1)
    
    -- Set volume
    self.audio:setVolume(track, normalized)
end

-- Export current pattern as MIDI file
-- Creates a timestamped filename and exports the pattern
function ui:exportMIDI()
    if not self.midi or not self.sequencer then
        print("Error: MIDI or sequencer module not available")
        return
    end
    
    -- Generate filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "drum_pattern_" .. timestamp .. ".mid"
    
    -- Get pattern statistics for user feedback
    local stats = self.midi:getPatternStats(self.sequencer.pattern)
    if stats then
        print(string.format("Exporting pattern: %d notes across %d tracks", stats.totalNotes, 8))
    end
    
    -- Export pattern with current BPM
    local success = self.midi:exportPattern(self.sequencer.pattern, self.sequencer.bpm, filename)
    
    if success then
        print("MIDI export successful!")
        -- Could show a visual confirmation here in the future
    else
        print("MIDI export failed!")
        -- Could show an error message here in the future
    end
end

return ui