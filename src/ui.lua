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
    -- Layout organization - reorganized for better UX and no overlaps
    -- ROW 1: BPM Controls (Y=20)
    -- ROW 2: Transport Controls (Y=60) 
    -- ROW 3: Grid Headers (Y=105)
    -- ROW 4: Main Grid + Volume Controls (Y=120+)
    
    -- Grid positioning and sizing
    gridX = 50,         -- Grid left position
    gridY = 120,        -- Grid top position (moved down to avoid overlaps)
    cellSize = 32,      -- Size of each grid cell in pixels
    cellPadding = 2,    -- Space between cells
    
    -- Transport control positioning (ROW 2)
    transportY = 60,    -- Y position for transport buttons (moved down)
    buttonWidth = 80,   -- Width of transport buttons
    buttonHeight = 30,  -- Height of transport buttons
    
    -- BPM control positioning (ROW 1 - dedicated space)
    bpmControlsY = 20,      -- Y position for BPM controls group
    bpmSliderX = 150,       -- BPM slider X position (left side, no conflicts)
    bpmSliderY = 20,        -- BPM slider Y position (top row)
    bpmSliderWidth = 180,   -- BPM slider width (slightly smaller)
    bpmSliderHeight = 20,   -- BPM slider height
    bpmDragging = false,    -- Whether user is dragging BPM slider
    
    -- BPM text input positioning (grouped with BPM controls)
    bpmTextInputX = 350,    -- BPM text input X position (right of slider)
    bpmTextInputY = 18,     -- BPM text input Y position (aligned with slider)
    bpmTextInputWidth = 60, -- BPM text input width
    bpmTextInputHeight = 24, -- BPM text input height
    bpmTextInputActive = false, -- Whether text input is focused/active
    bpmTextInputBuffer = "", -- Current text being typed in the input
    bpmTextInputCursorTimer = 0, -- Timer for blinking cursor animation
    
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
    
    -- Volume control positioning (right side of grid)
    volumeSliderWidth = 80, -- Width of volume sliders
    volumeSliderHeight = 10,-- Height of volume sliders
    volumeDragging = nil,   -- Track number being dragged, or nil
    volumeControlsX = 650,  -- X position for volume controls (fixed position)
    
    -- Metronome volume control state
    metronomeVolumeDragging = nil,  -- "normal" or "accent" if dragging metronome volume
    
    -- Layout spacing constants for consistency
    elementSpacing = 10,    -- Standard spacing between UI elements
    groupSpacing = 20,      -- Spacing between UI groups
    marginLeft = 20,        -- Left margin for all controls
    marginTop = 10,         -- Top margin for all controls
    
    -- Subtle UI color palette for non-grid elements
    -- Designed to complement track colors without competing for attention
    uiColors = {
        -- Background and neutral tones
        background = {0.05, 0.05, 0.05},        -- Very dark background
        panelBackground = {0.12, 0.12, 0.15},   -- Slightly blue-tinted dark panels
        border = {0.25, 0.25, 0.28},            -- Subtle gray-blue borders
        
        -- Text colors
        textPrimary = {0.95, 0.95, 0.95},       -- Near-white primary text
        textSecondary = {0.7, 0.7, 0.7},        -- Dimmed secondary text
        textAccent = {0.8, 0.85, 0.9},          -- Slightly blue-tinted accent text
        
        -- Button colors
        buttonNormal = {0.2, 0.22, 0.25},       -- Dark blue-gray buttons
        buttonHover = {0.25, 0.28, 0.32},       -- Lighter on hover
        buttonPressed = {0.15, 0.17, 0.2},      -- Darker when pressed
        buttonActive = {0.2, 0.5, 0.3},         -- Subtle green for active states
        
        -- Control colors
        sliderTrack = {0.15, 0.15, 0.18},       -- Dark slider tracks
        sliderHandle = {0.4, 0.45, 0.5},        -- Blue-gray slider handles
        sliderHandleActive = {0.6, 0.7, 0.8},   -- Lighter blue when active
        
        -- Accent colors (very subtle)
        accentBlue = {0.2, 0.3, 0.6},           -- Subtle blue accent
        accentPurple = {0.5, 0.2, 0.5},         -- Subtle purple accent
        accentTeal = {0.1, 0.4, 0.4},           -- Subtle teal accent
        
        -- Sequence grouping background colors
        -- 4-group system: groups 1&3 (steps 1-4, 9-12) and groups 2&4 (steps 5-8, 13-16)
        sequenceGroup13 = {0.10, 0.10, 0.10},   -- Dark grey for groups 1 & 3
        sequenceGroup24 = {0.06, 0.06, 0.06}    -- Even darker grey for groups 2 & 4
    },
    
    -- Track color system using 16 Xterm colors palette
    -- Each track has three brightness levels: dim (40%), normal (70%), bright (100%)
    trackColors = {
        -- Track 1: Kick (Bright Red family)
        {
            dim = {0.4, 0.0, 0.0},      -- Dimmed red for inactive state
            normal = {0.7, 0.0, 0.0},   -- Normal red for active steps
            bright = {1.0, 0.0, 0.0}    -- Bright red for playing steps
        },
        -- Track 2: Snare (Bright Yellow family)  
        {
            dim = {0.4, 0.4, 0.0},      -- Dimmed yellow
            normal = {0.7, 0.7, 0.0},   -- Normal yellow
            bright = {1.0, 1.0, 0.0}    -- Bright yellow
        },
        -- Track 3: Hi-Hat Closed (Bright Cyan family)
        {
            dim = {0.0, 0.4, 0.4},      -- Dimmed cyan
            normal = {0.0, 0.7, 0.7},   -- Normal cyan
            bright = {0.0, 1.0, 1.0}    -- Bright cyan
        },
        -- Track 4: Hi-Hat Open (Bright Green family)
        {
            dim = {0.0, 0.4, 0.0},      -- Dimmed green
            normal = {0.0, 0.7, 0.0},   -- Normal green
            bright = {0.0, 1.0, 0.0}    -- Bright green
        },
        -- Track 5: Crash (Bright Magenta family)
        {
            dim = {0.4, 0.0, 0.4},      -- Dimmed magenta
            normal = {0.7, 0.0, 0.7},   -- Normal magenta
            bright = {1.0, 0.0, 1.0}    -- Bright magenta
        },
        -- Track 6: Ride (Bright Blue family)
        {
            dim = {0.0, 0.0, 0.4},      -- Dimmed blue
            normal = {0.0, 0.0, 0.7},   -- Normal blue
            bright = {0.0, 0.0, 1.0}    -- Bright blue
        },
        -- Track 7: Tom Low (Normal White family)
        {
            dim = {0.3, 0.3, 0.3},      -- Dim white/gray
            normal = {0.6, 0.6, 0.6},   -- Normal white/gray (Xterm bright black)
            bright = {1.0, 1.0, 1.0}    -- Bright white
        },
        -- Track 8: Tom High (Orange family)
        {
            dim = {0.4, 0.2, 0.0},      -- Dim orange
            normal = {0.8, 0.4, 0.0},   -- Normal orange
            bright = {1.0, 0.6, 0.0}    -- Bright orange
        }
    }
}

-- Initialize the UI module
-- Loads required modules for interaction
function ui:init()
    self.sequencer = require("src.sequencer")
    self.audio = require("src.audio")
    self.midi = require("src.midi")
    self.utils = require("src.utils")
end

-- Helper function to set UI colors from the palette
-- @param colorName: Name of color from uiColors palette
function ui:setUIColor(colorName)
    local color = self.uiColors[colorName]
    if color then
        love.graphics.setColor(color[1], color[2], color[3])
    else
        -- Fallback to white if color not found
        love.graphics.setColor(1, 1, 1)
    end
end

-- Get the appropriate color for a track based on its state
-- @param track: Track number (1-8)
-- @param isActive: Whether the step is active (true/false)
-- @param isPlaying: Whether this step is currently playing (true/false)
-- @param hasTriggerFeedback: Whether audio feedback is active (true/false)
-- @return: RGB color table {r, g, b} for Love2D setColor function
function ui:getTrackColor(track, isActive, isPlaying, hasTriggerFeedback)
    if track < 1 or track > 8 then
        -- Default to gray for invalid tracks
        return {0.3, 0.3, 0.3}
    end
    
    local trackColorSet = self.trackColors[track]
    
    if not isActive then
        -- Inactive steps use dark gray
        return {0.2, 0.2, 0.2}
    end
    
    if isPlaying and hasTriggerFeedback then
        -- Currently playing with audio feedback - use brightest color
        return trackColorSet.bright
    elseif hasTriggerFeedback then
        -- Audio feedback active but not current step - use normal brightness
        return trackColorSet.normal
    else
        -- Active step without feedback - use dimmed color
        return trackColorSet.dim
    end
end

-- Update UI state
-- Handles text input cursor blinking animation
-- @param dt: Delta time since last frame
function ui:update(dt)
    -- Update text input cursor blinking animation
    if self.bpmTextInputActive then
        self.bpmTextInputCursorTimer = self.bpmTextInputCursorTimer + dt
        if self.bpmTextInputCursorTimer > 1.0 then  -- Blink every second
            self.bpmTextInputCursorTimer = 0
        end
    end
end

-- Main draw function
-- Renders all UI elements
function ui:draw()
    -- Draw subtle background
    self:setUIColor("background")
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw UI panels with subtle backgrounds
    self:drawUIPanels()
    
    self:drawTransportControls()  -- Play/Stop/Reset buttons
    self:drawGrid()              -- Pattern grid
    self:drawBPMControl()        -- BPM display and slider
    self:drawBPMTextInput()      -- BPM text input field
    self:drawVolumeControls()    -- Volume sliders
end

-- Draw UI panels (backgrounds and borders removed for cleaner UI)
function ui:drawUIPanels()
    -- All panel backgrounds removed for minimal design
end

-- Draw the pattern grid
-- Renders the 16x8 grid with track labels and step numbers
-- Get sequence group background color for step grouping visualization
-- Implements 4-group system: groups 1&3 (steps 1-4, 9-12) and groups 2&4 (steps 5-8, 13-16)
-- @param step: Step number (1-16)
-- @return: Color table {r, g, b} for the group background
function ui:getSequenceGroupColor(step)
    -- Group 1: steps 1-4, Group 2: steps 5-8, Group 3: steps 9-12, Group 4: steps 13-16
    local group = math.ceil(step / 4)
    
    -- Groups 1 & 3 use dark grey, Groups 2 & 4 use even darker grey
    if group == 1 or group == 3 then
        return self.uiColors.sequenceGroup13  -- Dark grey
    else
        return self.uiColors.sequenceGroup24  -- Even darker grey
    end
end

-- Draw sequence group backgrounds for enhanced visual organization
-- Creates alternating background colors for 4-step groups to improve pattern readability
function ui:drawSequenceGroupBackgrounds()
    -- Draw background rectangles for each 4-step group
    for group = 1, 4 do
        -- Calculate group boundaries
        local startStep = (group - 1) * 4 + 1
        local endStep = group * 4
        
        -- Calculate group rectangle dimensions
        local groupX = self.gridX + (startStep - 1) * (self.cellSize + self.cellPadding)
        local groupY = self.gridY
        local groupWidth = 4 * (self.cellSize + self.cellPadding) - self.cellPadding
        local groupHeight = 8 * (self.cellSize + self.cellPadding) - self.cellPadding
        
        -- Get appropriate background color for this group
        local groupColor = self:getSequenceGroupColor(startStep)
        love.graphics.setColor(groupColor[1], groupColor[2], groupColor[3])
        
        -- Draw the group background rectangle
        love.graphics.rectangle("fill", groupX, groupY, groupWidth, groupHeight)
    end
end

function ui:drawGrid()
    -- Draw sequence group backgrounds first (behind all other elements)
    self:drawSequenceGroupBackgrounds()
    
    -- Set subtle text color for labels
    self:setUIColor("textAccent")
    love.graphics.setFont(love.graphics.newFont(12))
    
    -- Draw track labels on the left with color coding
    for track = 1, 8 do
        -- Use the track's normal color for the label
        local labelColor = self.trackColors[track].normal
        love.graphics.setColor(labelColor[1], labelColor[2], labelColor[3])
        
        love.graphics.print(
            self.trackLabels[track], 
            self.gridX - 45, 
            self.gridY + (track - 1) * (self.cellSize + self.cellPadding) + 8
        )
    end
    
    -- Draw step numbers header with proper spacing
    self:setUIColor("textSecondary")  -- Use subtle secondary text color
    love.graphics.setFont(love.graphics.newFont(10))
    for step = 1, 16 do
        love.graphics.print(
            step, 
            self.gridX + (step - 1) * (self.cellSize + self.cellPadding) + 10, 
            self.gridY - 15  -- Adjusted for new layout
        )
    end
    
    -- Draw grid cells with colorful track-specific design
    for track = 1, 8 do
        for step = 1, 16 do
            local x = self.gridX + (step - 1) * (self.cellSize + self.cellPadding)
            local y = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
            
            -- Determine cell state for color selection
            local isActive = self.sequencer.pattern[track][step]
            local hasTriggerFeedback = self.audio and self.audio:hasTriggerFeedback(track)
            local isCurrentStep = (self.sequencer.currentStep == step and self.sequencer.isPlaying)
            
            -- Get appropriate color based on track and state
            local cellColor = self:getTrackColor(track, isActive, isCurrentStep, hasTriggerFeedback)
            love.graphics.setColor(cellColor[1], cellColor[2], cellColor[3])
            
            -- Draw the main cell
            love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
            
            -- Draw current step indicator during playback with enhanced highlight
            if isCurrentStep then
                -- Use bright white border for current step
                love.graphics.setColor(1, 1, 1)  -- White border
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", x - 1, y - 1, self.cellSize + 2, self.cellSize + 2)
            end
            
            -- Draw hover effect with subtle white overlay
            if self.hoveredCell and self.hoveredCell.track == track and self.hoveredCell.step == step then
                love.graphics.setColor(1, 1, 1, 0.2)  -- Semi-transparent white overlay
                love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
            end
        end
    end
end

-- Draw transport control buttons
-- Renders Play, Stop, Reset, Clear, Export, and Metronome buttons
function ui:drawTransportControls()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- Calculate button positions
    local playX = 200
    local stopX = playX + self.buttonWidth + 10
    local resetX = stopX + self.buttonWidth + 10
    local clearX = resetX + self.buttonWidth + 10
    local exportX = clearX + self.buttonWidth + 10
    local metronomeX = exportX + self.buttonWidth + 10
    
    -- Get metronome state for button display
    local metronomeEnabled = self.sequencer and self.sequencer:isMetronomeEnabled() or false
    
    -- Draw buttons with appropriate states
    self:drawButton("PLAY", playX, self.transportY, self.buttonWidth, self.buttonHeight, self.sequencer.isPlaying)
    self:drawButton("STOP", stopX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("RESET", resetX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("CLEAR", clearX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("EXPORT", exportX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("METRO", metronomeX, self.transportY, self.buttonWidth, self.buttonHeight, metronomeEnabled)
end

-- Draw a single button
-- @param text: Button label
-- @param x, y: Button position
-- @param w, h: Button dimensions
-- @param active: Whether button is in active state
function ui:drawButton(text, x, y, w, h, active)
    -- Define button color based on state for enhanced UI with matching border and fill
    local buttonColor
    if active then
        buttonColor = "buttonActive"     -- Subtle green for active
    elseif self.clickedButton == text then
        buttonColor = "buttonPressed"    -- Darker for pressed
    else
        buttonColor = "buttonNormal"     -- Normal button color
    end
    
    -- Draw button background with matching border and fill
    self:setUIColor(buttonColor)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Draw minimal border around button (same color as fill for consistency)
    self:setUIColor(buttonColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- Draw centered text with primary color for contrast
    self:setUIColor("textPrimary")
    local font = love.graphics.getFont()
    local textW = font:getWidth(text)
    local textH = font:getHeight()
    love.graphics.print(text, x + (w - textW) / 2, y + (h - textH) / 2)
end

-- Draw BPM display and controls in organized layout
-- Shows current BPM with grouped controls and proper spacing
function ui:drawBPMControl()
    -- Use subtle accent color for headers
    self:setUIColor("textAccent")
    love.graphics.setFont(love.graphics.newFont(14))
    
    -- Draw BPM controls group header
    love.graphics.print("BPM Controls", self.marginLeft, self.bpmControlsY - 5)
    
    -- Draw BPM label next to slider
    self:setUIColor("textPrimary")
    love.graphics.print("BPM:", self.bpmSliderX - 40, self.bpmSliderY)
    
    -- Draw decrease button (left of slider)
    self:drawButton("-", self.bpmSliderX - 35, self.bpmSliderY - 2, 25, 24, false)
    
    -- Draw slider track with minimal border for enhanced UI
    local trackY = self.bpmSliderY + 5
    local trackHeight = 10
    
    -- Draw track background with subtle fill
    self:setUIColor("sliderTrack")
    love.graphics.rectangle("fill", self.bpmSliderX, trackY, self.bpmSliderWidth, trackHeight)
    
    -- Draw minimal border around track
    self:setUIColor("border")
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.bpmSliderX, trackY, self.bpmSliderWidth, trackHeight)
    
    -- Calculate slider handle position
    local normalizedBPM = (self.sequencer.bpm - 60) / (300 - 60)  -- Normalize to 0-1
    local handleX = self.bpmSliderX + normalizedBPM * self.bpmSliderWidth
    
    -- Draw slider handle with enhanced styling
    if self.bpmDragging then
        self:setUIColor("sliderHandleActive")
    else
        self:setUIColor("sliderHandle")
    end
    love.graphics.circle("fill", handleX, self.bpmSliderY + 10, 8)
    
    -- Draw minimal border around handle
    self:setUIColor("border")
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", handleX, self.bpmSliderY + 10, 8)
    
    -- Draw increase button (right of slider with spacing)
    self:drawButton("+", self.bpmSliderX + self.bpmSliderWidth + 10, self.bpmSliderY - 2, 25, 24, false)
    
    -- Draw current BPM value (right of increase button)
    self:setUIColor("textPrimary")
    love.graphics.print(tostring(self.sequencer.bpm), self.bpmSliderX + self.bpmSliderWidth + 45, self.bpmSliderY)
end

-- Draw BPM text input field
-- Shows text input for direct BPM entry
function ui:drawBPMTextInput()
    -- Input field background removed for minimal design
    
    -- Draw text content with subtle colors
    love.graphics.setFont(love.graphics.newFont(12))
    
    local displayText = self.bpmTextInputBuffer
    if displayText == "" then
        -- Show current BPM as placeholder when buffer is empty
        displayText = tostring(self.sequencer.bpm)
        self:setUIColor("textSecondary")  -- Dimmed placeholder text
    else
        -- Show typed text in primary color
        self:setUIColor("textPrimary")  -- Primary text for active input
    end
    
    -- Center text vertically in the input field
    local font = love.graphics.getFont()
    local textHeight = font:getHeight()
    local textY = self.bpmTextInputY + (self.bpmTextInputHeight - textHeight) / 2
    
    love.graphics.print(displayText, self.bpmTextInputX + 5, textY)
    
    -- Draw blinking cursor when active
    if self.bpmTextInputActive and self.bpmTextInputCursorTimer < 0.5 then
        local textWidth = font:getWidth(self.bpmTextInputBuffer)
        local cursorX = self.bpmTextInputX + 5 + textWidth
        self:setUIColor("textPrimary")
        love.graphics.line(cursorX, textY, cursorX, textY + textHeight)
    end
end

-- Draw volume controls for each track with organized layout
-- Shows volume sliders with proper spacing and reset volumes button
function ui:drawVolumeControls()
    if not self.audio then return end
    
    -- Use subtle color scheme for volume controls
    self:setUIColor("textAccent")
    love.graphics.setFont(love.graphics.newFont(10))
    
    -- Draw volume controls group header
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Volume Controls", self.volumeControlsX - 25, self.gridY - 35)
    
    -- Draw reset volumes button with proper positioning
    local resetButtonY = self.gridY - 25  -- Position with adequate spacing above grid
    local resetButtonWidth = 80
    local resetButtonHeight = 20
    
    self:drawButton("Reset Vol", self.volumeControlsX - 10, resetButtonY, resetButtonWidth, resetButtonHeight, false)
    
    love.graphics.setFont(love.graphics.newFont(10))
    
    -- Draw volume sliders for each track with consistent positioning
    for track = 1, 8 do
        local trackY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
        local sliderX = self.volumeControlsX
        local sliderY = trackY + (self.cellSize - self.volumeSliderHeight) / 2
        
        -- Draw volume label with subtle color
        self:setUIColor("textSecondary")
        love.graphics.print("Vol", sliderX - 25, sliderY - 2)
        
        -- Draw slider track with minimal border for enhanced UI
        self:setUIColor("sliderTrack")
        love.graphics.rectangle("fill", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
        
        -- Draw minimal border around track
        self:setUIColor("border")
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
        
        -- Calculate handle position
        local volume = self.audio:getVolume(track)
        local handleX = sliderX + volume * self.volumeSliderWidth
        
        -- Draw slider handle with enhanced styling
        if self.volumeDragging == track then
            self:setUIColor("sliderHandleActive")
        else
            self:setUIColor("sliderHandle")
        end
        love.graphics.rectangle("fill", handleX - 2, sliderY - 2, 4, self.volumeSliderHeight + 4)
        
        -- Draw minimal border around handle
        self:setUIColor("border")
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", handleX - 2, sliderY - 2, 4, self.volumeSliderHeight + 4)
        
        -- Draw volume percentage with primary text color
        self:setUIColor("textPrimary")
        love.graphics.print(string.format("%d%%", math.floor(volume * 100)), 
                           sliderX + self.volumeSliderWidth + 8, sliderY - 2)
    end
    
    -- Draw metronome volume controls below the track volumes
    self:drawMetronomeVolumeControls()
end

-- Draw metronome volume controls (normal and accent click volumes)
-- Shows volume sliders for normal and accent metronome clicks with labels
function ui:drawMetronomeVolumeControls()
    if not self.sequencer then return end
    
    local metronomeSectionY = self.gridY + 8 * (self.cellSize + self.cellPadding) + 20
    
    -- Draw metronome volume section header
    self:setUIColor("textAccent")
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Metronome", self.volumeControlsX - 25, metronomeSectionY)
    
    love.graphics.setFont(love.graphics.newFont(10))
    
    -- Draw normal click volume slider
    local normalSliderY = metronomeSectionY + 20
    self:drawMetronomeVolumeSlider("normal", "Normal", normalSliderY)
    
    -- Draw accent click volume slider  
    local accentSliderY = normalSliderY + 25
    self:drawMetronomeVolumeSlider("accent", "Accent", accentSliderY)
end

-- Draw a single metronome volume slider
-- @param clickType: "normal" or "accent"
-- @param label: Display label for the slider
-- @param sliderY: Y position for the slider
function ui:drawMetronomeVolumeSlider(clickType, label, sliderY)
    local sliderX = self.volumeControlsX
    
    -- Draw volume label with metronome-specific colors
    if clickType == "accent" then
        self:setUIColor("accentPurple")  -- Subtle purple for accent
    else
        self:setUIColor("textSecondary")  -- Standard secondary for normal
    end
    love.graphics.print(label, sliderX - 25, sliderY - 2)
    
    -- Draw slider track with minimal border for enhanced UI
    self:setUIColor("sliderTrack")
    love.graphics.rectangle("fill", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
    
    -- Draw minimal border around track
    self:setUIColor("border")
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", sliderX, sliderY, self.volumeSliderWidth, self.volumeSliderHeight)
    
    -- Calculate handle position
    local volume = self.sequencer:getMetronomeVolume(clickType)
    local handleX = sliderX + volume * self.volumeSliderWidth
    
    -- Draw slider handle with enhanced styling
    if self.metronomeVolumeDragging == clickType then
        self:setUIColor("sliderHandleActive")
    else
        if clickType == "accent" then
            self:setUIColor("accentPurple")  -- Purple tint for accent handle
        else
            self:setUIColor("sliderHandle")   -- Standard handle color
        end
    end
    love.graphics.rectangle("fill", handleX - 2, sliderY - 2, 4, self.volumeSliderHeight + 4)
    
    -- Draw minimal border around handle
    self:setUIColor("border")
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", handleX - 2, sliderY - 2, 4, self.volumeSliderHeight + 4)
    
    -- Draw volume percentage with appropriate color
    if clickType == "accent" then
        self:setUIColor("accentPurple")
    else
        self:setUIColor("textPrimary")
    end
    love.graphics.print(string.format("%d%%", math.floor(volume * 100)), 
                       sliderX + self.volumeSliderWidth + 8, sliderY - 2)
end

-- Handle mouse press events
-- @param x, y: Mouse coordinates
function ui:mousepressed(x, y)
    -- Track if any UI element was clicked
    local uiElementClicked = false
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
            uiElementClicked = true
        end
    end
    
    -- Check transport button clicks
    local playX = 200
    local stopX = playX + self.buttonWidth + 10
    local resetX = stopX + self.buttonWidth + 10
    local clearX = resetX + self.buttonWidth + 10
    local exportX = clearX + self.buttonWidth + 10
    local metronomeX = exportX + self.buttonWidth + 10
    
    if self.utils.pointInRect(x, y, playX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "PLAY"
        self.sequencer:play()
        uiElementClicked = true
    elseif self.utils.pointInRect(x, y, stopX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "STOP"
        self.sequencer:stop()
        uiElementClicked = true
    elseif self.utils.pointInRect(x, y, resetX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "RESET"
        self.sequencer:stop()  -- Reset also stops playback
        uiElementClicked = true
    elseif self.utils.pointInRect(x, y, clearX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "CLEAR"
        self.sequencer:clearPattern()  -- Clear all pattern steps
        uiElementClicked = true
    elseif self.utils.pointInRect(x, y, exportX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "EXPORT"
        self:exportMIDI()
        uiElementClicked = true
    elseif self.utils.pointInRect(x, y, metronomeX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "METRO"
        -- Toggle metronome state (can be toggled during playback)
        self.sequencer:setMetronomeEnabled(nil)  -- nil means toggle
        uiElementClicked = true
    end
    
    -- Check BPM controls (only if not already handled by transport buttons)
    if not self.clickedButton then
        -- Check BPM text input click
        if self.utils.pointInRect(x, y, self.bpmTextInputX, self.bpmTextInputY, 
                                 self.bpmTextInputWidth, self.bpmTextInputHeight) then
            self.bpmTextInputActive = true
            self.bpmTextInputBuffer = ""  -- Clear buffer when clicking to start fresh input
            self.bpmTextInputCursorTimer = 0
            self.bpmDragging = false  -- Stop any active slider dragging when switching to text input
            uiElementClicked = true
        -- Decrease BPM button (updated position)
        elseif self.utils.pointInRect(x, y, self.bpmSliderX - 35, self.bpmSliderY - 2, 25, 24) then
            self.clickedButton = "-"
            self.sequencer:setBPM(self.sequencer.bpm - 5)
            self.bpmTextInputActive = false  -- Deactivate text input when using buttons
            uiElementClicked = true
        -- Increase BPM button (updated position)
        elseif self.utils.pointInRect(x, y, self.bpmSliderX + self.bpmSliderWidth + 10, self.bpmSliderY - 2, 25, 24) then
            self.clickedButton = "+"
            self.sequencer:setBPM(self.sequencer.bpm + 5)
            self.bpmTextInputActive = false  -- Deactivate text input when using buttons
            uiElementClicked = true
        -- Check if clicking on slider handle or track (updated position)
        elseif self.utils.pointInRect(x, y, self.bpmSliderX - 10, self.bpmSliderY, self.bpmSliderWidth + 20, 20) then
            self.bpmDragging = true
            self:updateBPMFromMouse(x)
            self.bpmTextInputActive = false  -- Deactivate text input when using slider
            uiElementClicked = true
        end
    end
    
    -- Check track label clicks (for audio testing) - only if not already handled
    if self.audio and not self.clickedButton and not self.bpmDragging then
        for track = 1, 8 do
            local labelY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding) + 8
            if self.utils.pointInRect(x, y, self.gridX - 45, labelY, 40, 16) then
                self.audio:playSample(track)
                uiElementClicked = true
                break
            end
        end
    end
    
    -- Check reset volumes button click (updated position) - only if not already handled
    if self.audio and not self.clickedButton and not self.bpmDragging then
        local resetButtonY = self.gridY - 25  -- Updated position with proper spacing
        local resetButtonWidth = 80
        local resetButtonHeight = 20  -- Updated height
        
        if self.utils.pointInRect(x, y, self.volumeControlsX - 10, resetButtonY, resetButtonWidth, resetButtonHeight) then
            self.clickedButton = "Reset Vol"
            self.audio:resetAllVolumes()  -- Reset all track volumes to 70%
            uiElementClicked = true
        end
    end
    
    -- Check volume slider clicks (updated position) - only if not already handled
    if self.audio and not self.clickedButton and not self.bpmDragging then
        for track = 1, 8 do
            local trackY = self.gridY + (track - 1) * (self.cellSize + self.cellPadding)
            local sliderX = self.volumeControlsX  -- Updated to use fixed position
            local sliderY = trackY + (self.cellSize - self.volumeSliderHeight) / 2
            
            if self.utils.pointInRect(x, y, sliderX - 5, sliderY - 5, self.volumeSliderWidth + 10, self.volumeSliderHeight + 10) then
                self.volumeDragging = track
                self:updateVolumeFromMouse(track, x)
                uiElementClicked = true
                break
            end
        end
    end
    
    -- Check metronome volume slider clicks - only if not already handled
    if self.sequencer and not self.clickedButton and not self.bpmDragging and not self.volumeDragging then
        local metronomeSectionY = self.gridY + 8 * (self.cellSize + self.cellPadding) + 20
        local sliderX = self.volumeControlsX
        
        -- Check normal metronome volume slider
        local normalSliderY = metronomeSectionY + 20
        if self.utils.pointInRect(x, y, sliderX - 5, normalSliderY - 5, self.volumeSliderWidth + 10, self.volumeSliderHeight + 10) then
            self.metronomeVolumeDragging = "normal"
            self:updateMetronomeVolumeFromMouse("normal", x)
            uiElementClicked = true
        end
        
        -- Check accent metronome volume slider
        local accentSliderY = normalSliderY + 25
        if self.utils.pointInRect(x, y, sliderX - 5, accentSliderY - 5, self.volumeSliderWidth + 10, self.volumeSliderHeight + 10) then
            self.metronomeVolumeDragging = "accent"
            self:updateMetronomeVolumeFromMouse("accent", x)
            uiElementClicked = true
        end
    end
    
    -- If no UI element was clicked, apply and deactivate text input
    if not uiElementClicked then
        -- If text input was active with content, apply the BPM change before deactivating
        if self.bpmTextInputActive and self.bpmTextInputBuffer ~= "" then
            self:applyBPMTextInput()
        else
            -- Just deactivate if no content
            self.bpmTextInputActive = false
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
    self.metronomeVolumeDragging = nil
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
    
    -- Handle metronome volume slider dragging
    if self.metronomeVolumeDragging then
        self:updateMetronomeVolumeFromMouse(self.metronomeVolumeDragging, x)
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

-- Update volume based on mouse position with reorganized layout
-- @param track: Track number (1-8)
-- @param mouseX: Current mouse X coordinate
function ui:updateVolumeFromMouse(track, mouseX)
    if not self.audio then return end
    
    -- Use fixed volume controls position
    local sliderX = self.volumeControlsX
    
    -- Calculate normalized position (0-1) along slider
    local relativeX = mouseX - sliderX
    local normalized = self.utils.clamp(relativeX / self.volumeSliderWidth, 0, 1)
    
    -- Set volume
    self.audio:setVolume(track, normalized)
end

-- Update metronome volume from mouse position
-- @param clickType: "normal" or "accent"
-- @param mouseX: Mouse X coordinate
function ui:updateMetronomeVolumeFromMouse(clickType, mouseX)
    if not self.sequencer then return end
    
    -- Use fixed volume controls position
    local sliderX = self.volumeControlsX
    
    -- Calculate normalized position (0-1) along slider
    local relativeX = mouseX - sliderX
    local normalized = self.utils.clamp(relativeX / self.volumeSliderWidth, 0, 1)
    
    -- Set metronome volume for specific click type
    self.sequencer:setMetronomeVolume(clickType, normalized)
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

-- Handle keyboard text input for BPM text field
-- @param text: Text character that was typed
function ui:textinput(text)
    if not self.bpmTextInputActive then return end
    
    -- Only allow numeric input (0-9)
    if text:match("[0-9]") and string.len(self.bpmTextInputBuffer) < 3 then
        self.bpmTextInputBuffer = self.bpmTextInputBuffer .. text
        self.bpmTextInputCursorTimer = 0  -- Reset cursor blink
    end
end

-- Handle keyboard key press events for BPM text field
-- @param key: Key that was pressed
function ui:keypressed(key)
    if not self.bpmTextInputActive then return end
    
    if key == "backspace" then
        -- Remove last character from buffer
        if string.len(self.bpmTextInputBuffer) > 0 then
            self.bpmTextInputBuffer = string.sub(self.bpmTextInputBuffer, 1, -2)
            self.bpmTextInputCursorTimer = 0  -- Reset cursor blink
        end
    elseif key == "return" or key == "enter" or key == "kpenter" then
        -- Apply the BPM value and deactivate text input
        -- Supports both main Enter key and numeric keypad Enter key
        self:applyBPMTextInput()
    elseif key == "escape" then
        -- Cancel text input without applying
        self.bpmTextInputActive = false
        self.bpmTextInputBuffer = ""
    end
end

-- Apply BPM value from text input with validation
-- Validates the input and updates the sequencer BPM
-- Also ensures slider visual state is properly updated
function ui:applyBPMTextInput()
    if self.bpmTextInputBuffer == "" then
        -- Empty input - just deactivate without changing BPM
        self.bpmTextInputActive = false
        return
    end
    
    -- Convert text to number and validate
    local newBPM = tonumber(self.bpmTextInputBuffer)
    
    if newBPM then
        -- Clamp to valid BPM range (60-300)
        newBPM = math.max(60, math.min(300, math.floor(newBPM)))
        
        self.sequencer:setBPM(newBPM)
        
        -- Ensure slider state is clean for proper visual update
        -- This guarantees the slider handle reflects the new BPM value
        self.bpmDragging = false
    end
    
    -- Deactivate text input and clear buffer
    self.bpmTextInputActive = false
    self.bpmTextInputBuffer = ""
end

return ui