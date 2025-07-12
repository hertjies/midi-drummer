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
    -- ROW 2.5: Pattern Controls (Y=95)
    -- ROW 3: Grid Headers (Y=130)
    -- ROW 4: Main Grid + Volume Controls (Y=145+)
    
    -- Grid positioning and sizing
    gridX = 50,         -- Grid left position
    gridY = 145,        -- Grid top position (moved down for pattern controls)
    cellSize = 32,      -- Size of each grid cell in pixels
    cellPadding = 2,    -- Space between cells
    
    -- Transport control positioning (ROW 2)
    transportY = 60,    -- Y position for transport buttons (moved down)
    buttonWidth = 80,   -- Width of transport buttons
    buttonHeight = 30,  -- Height of transport buttons
    
    -- Pattern control positioning (ROW 2.5)
    patternControlsY = 95,      -- Y position for pattern save/load controls
    patternButtonWidth = 60,    -- Width of pattern control buttons (smaller)
    patternButtonHeight = 25,   -- Height of pattern control buttons (smaller)
    
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
    
    -- Pattern management UI state
    patternNameInput = "",           -- Current pattern name being typed
    patternNameInputActive = false,  -- Whether pattern name input is focused
    patternNameInputCursorTimer = 0, -- Timer for blinking cursor in pattern name input
    patternList = {},               -- List of available patterns
    patternListVisible = false,     -- Whether pattern selection list is visible
    selectedPatternIndex = 1,       -- Currently selected pattern in the list
    patternDialogMode = "none",     -- "save", "load", or "none"
    
    -- Help dialog UI state
    helpVisible = false,            -- Whether help dialog is visible
    helpScrollY = 0,                -- Vertical scroll position in help dialog
    helpScrollDragging = false,     -- Whether user is dragging the scroll bar
    helpScrollDragOffset = 0,       -- Offset from mouse to scroll thumb top when dragging
    
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
    self:drawPatternControls()   -- Pattern save/load controls (without dialog)
    self:drawGrid()              -- Pattern grid
    self:drawBPMControl()        -- BPM display and slider
    self:drawBPMTextInput()      -- BPM text input field
    self:drawVolumeControls()    -- Volume sliders
    
    -- Draw pattern selection dialog last so it appears on top of everything else
    -- This ensures the dialog is not hidden behind the grid or other UI elements
    if self.patternListVisible then
        self:drawPatternSelectionDialog()
    end
    
    -- Draw help dialog last to ensure it's on top
    if self.helpVisible then
        self:drawHelpDialog()
    end
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
    local helpX = metronomeX + self.buttonWidth + 10
    
    -- Get metronome state for button display
    local metronomeEnabled = self.sequencer and self.sequencer:isMetronomeEnabled() or false
    
    -- Draw buttons with appropriate states
    self:drawButton("PLAY", playX, self.transportY, self.buttonWidth, self.buttonHeight, self.sequencer.isPlaying)
    self:drawButton("STOP", stopX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("RESET", resetX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("CLEAR", clearX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("EXPORT", exportX, self.transportY, self.buttonWidth, self.buttonHeight, false)
    self:drawButton("METRO", metronomeX, self.transportY, self.buttonWidth, self.buttonHeight, metronomeEnabled)
    self:drawButton("HELP", helpX, self.transportY, self.buttonWidth, self.buttonHeight, self.helpVisible)
end

-- Draw pattern save/load controls
-- Renders pattern management interface with save/load buttons and pattern name input
function ui:drawPatternControls()
    if not self.sequencer then return end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    -- Calculate button positions (smaller buttons for pattern controls)
    local saveX = 200
    local loadX = saveX + self.patternButtonWidth + 10
    local newX = loadX + self.patternButtonWidth + 10
    local nameInputX = newX + self.patternButtonWidth + 20
    local nameInputWidth = 150
    local nameInputHeight = self.patternButtonHeight
    
    -- Draw section label
    self:setUIColor("textAccent")
    love.graphics.print("Patterns:", 200 - 60, self.patternControlsY + 3)
    
    -- Draw pattern control buttons
    self:drawButton("SAVE", saveX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight, false)
    self:drawButton("LOAD", loadX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight, false)
    self:drawButton("NEW", newX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight, false)
    
    -- Draw pattern name input field
    self:drawPatternNameInput(nameInputX, self.patternControlsY, nameInputWidth, nameInputHeight)
end

-- Draw pattern name input field
-- @param x, y: Input field position
-- @param width, height: Input field dimensions
function ui:drawPatternNameInput(x, y, width, height)
    -- Draw input field border (minimal styling)
    self:setUIColor("border")
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Determine display text and cursor state
    local displayText = self.patternNameInput
    local showCursor = false
    
    if self.patternNameInputActive then
        -- Add blinking cursor when active - fixed cursor flashing logic
        self.patternNameInputCursorTimer = self.patternNameInputCursorTimer + (love.timer and love.timer.getDelta() or 0.016)
        showCursor = math.floor(self.patternNameInputCursorTimer * 2) % 2 == 0
        if showCursor then
            displayText = displayText .. "|"
        end
    else
        -- Reset cursor timer when not active to prevent residual flashing
        self.patternNameInputCursorTimer = 0
    end
    
    -- Display placeholder text if input is empty (fixed logic to prevent cursor artifacts)
    if self.patternNameInput == "" then
        self:setUIColor("textSecondary")
        displayText = "pattern name"
    else
        self:setUIColor("textPrimary")
    end
    
    -- Draw text content with padding
    love.graphics.setFont(love.graphics.newFont(10))
    local textY = y + (height - love.graphics.getFont():getHeight()) / 2
    love.graphics.print(displayText, x + 5, textY)
end

-- Draw pattern selection dialog
-- Shows list of available patterns for loading or saving
function ui:drawPatternSelectionDialog()
    if not self.sequencer then return end
    
    -- For save mode, always show dialog even if no patterns exist
    -- For load mode, only show if patterns exist
    if self.patternDialogMode == "load" and #self.patternList == 0 then
        return
    end
    
    -- Dialog dimensions and position
    local dialogWidth = 300
    local dialogHeight = math.min(200, #self.patternList * 25 + 60)
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    
    -- Draw dialog background
    self:setUIColor("panelBackground")
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight)
    
    -- Draw dialog border
    self:setUIColor("border")
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight)
    
    -- Draw dialog title
    self:setUIColor("textPrimary")
    love.graphics.setFont(love.graphics.newFont(14))
    local titleText = self.patternDialogMode == "save" and "Save Pattern" or "Load Pattern"
    love.graphics.print(titleText, dialogX + 10, dialogY + 10)
    
    -- Draw pattern list or empty message
    love.graphics.setFont(love.graphics.newFont(12))
    local listY = dialogY + 35
    
    if #self.patternList == 0 then
        -- Show message when no patterns exist
        self:setUIColor("textSecondary")
        local emptyMsg = self.patternDialogMode == "save" and 
            "No saved patterns. Enter a name above." or 
            "No saved patterns found."
        love.graphics.print(emptyMsg, dialogX + 10, listY)
    else
        -- Draw pattern list
        for i, patternName in ipairs(self.patternList) do
            local itemY = listY + (i - 1) * 25
            
            -- Highlight selected item
            if i == self.selectedPatternIndex then
                self:setUIColor("buttonActive")
                love.graphics.rectangle("fill", dialogX + 5, itemY - 2, dialogWidth - 10, 20)
            end
            
            -- Draw pattern name
            self:setUIColor("textPrimary")
            love.graphics.print(patternName, dialogX + 10, itemY)
        end
    end
    
    -- Draw dialog buttons
    local buttonY = dialogY + dialogHeight - 35
    local cancelX = dialogX + 10
    local confirmX = dialogX + dialogWidth - 70
    
    self:drawButton("Cancel", cancelX, buttonY, 50, 25, false)
    local confirmText = self.patternDialogMode == "save" and "Save" or "Load"
    self:drawButton(confirmText, confirmX, buttonY, 50, 25, false)
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
    
    -- Check help dialog first (it's on top)
    if self.helpVisible then
        local dialogWidth = 700
        local dialogHeight = 500
        local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
        local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
        
        -- Check close button (X)
        local closeX = dialogX + dialogWidth - 35
        local closeY = dialogY + 5
        if self.utils.pointInRect(x, y, closeX, closeY, 30, 30) then
            self.helpVisible = false
            return  -- Consume the click
        end
        
        -- Check scroll bar clicks
        local contentX = dialogX + 20
        local contentY = dialogY + 40
        local contentWidth = dialogWidth - 60
        local contentHeight = dialogHeight - 60
        
        -- Calculate if scroll bar should be visible
        local helpSections = self:getHelpContent()
        local totalContentHeight = 0
        for _, section in ipairs(helpSections) do
            if section.title then
                totalContentHeight = totalContentHeight + 20  -- Title height
            end
            if section.content then
                totalContentHeight = totalContentHeight + (#section.content * 16) + 8  -- Content lines + spacing
            end
        end
        
        if totalContentHeight > contentHeight then
            local scrollBarX = dialogX + dialogWidth - 20
            local scrollBarY = contentY
            local scrollBarHeight = contentHeight
            local scrollThumbHeight = math.max(20, scrollBarHeight * (contentHeight / totalContentHeight))
            local maxScroll = totalContentHeight - contentHeight
            local scrollThumbY = scrollBarY + ((self.helpScrollY or 0) / maxScroll) * (scrollBarHeight - scrollThumbHeight)
            
            -- Check if clicking on scroll bar
            if self.utils.pointInRect(x, y, scrollBarX, scrollBarY, 15, scrollBarHeight) then
                -- Check if clicking on thumb specifically
                if self.utils.pointInRect(x, y, scrollBarX + 2, scrollThumbY, 11, scrollThumbHeight) then
                    -- Start dragging the scroll thumb
                    self.helpScrollDragging = true
                    self.helpScrollDragOffset = y - scrollThumbY
                    return  -- Consume the click
                else
                    -- Click on scroll bar track - jump scroll position
                    local clickRatio = (y - scrollBarY) / scrollBarHeight
                    self.helpScrollY = self.utils.clamp(clickRatio * maxScroll, 0, maxScroll)
                    return  -- Consume the click
                end
            end
        end
        
        -- Check if click is within dialog bounds (consume click to prevent interaction with elements behind)
        if self.utils.pointInRect(x, y, dialogX, dialogY, dialogWidth, dialogHeight) then
            return  -- Consume the click but don't close dialog
        else
            -- Click outside dialog - close it
            self.helpVisible = false
            return
        end
    end
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
    local helpX = metronomeX + self.buttonWidth + 10
    
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
    elseif self.utils.pointInRect(x, y, helpX, self.transportY, self.buttonWidth, self.buttonHeight) then
        self.clickedButton = "HELP"
        -- Toggle help dialog visibility
        self.helpVisible = not self.helpVisible
        self.helpScrollY = 0  -- Reset scroll position when opening
        uiElementClicked = true
    end
    
    -- Check pattern control buttons
    if not uiElementClicked then
        uiElementClicked = self:handlePatternControlClicks(x, y) or uiElementClicked
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
    self.helpScrollDragging = false
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
    
    -- Handle help dialog scroll bar dragging
    if self.helpScrollDragging then
        self:updateHelpScrollFromMouse(y)
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

-- Handle mouse wheel scrolling
-- @param x, y: Mouse wheel movement (y is typically used for vertical scrolling)
function ui:wheelmoved(x, y)
    -- Only handle scrolling when help dialog is visible
    if self.helpVisible then
        local scrollAmount = y * 30  -- 30 pixels per wheel step
        
        -- Calculate content dimensions for scroll bounds
        local dialogHeight = 500
        local contentHeight = dialogHeight - 60  -- Account for title bar
        local helpSections = self:getHelpContent()
        
        -- Estimate total content height
        local totalContentHeight = 0
        for _, section in ipairs(helpSections) do
            if section.title then
                totalContentHeight = totalContentHeight + 20  -- Title height
            end
            if section.content then
                totalContentHeight = totalContentHeight + (#section.content * 16) + 8  -- Content lines + spacing
            end
        end
        
        -- Calculate scroll bounds
        local maxScroll = math.max(0, totalContentHeight - contentHeight)
        
        -- Update scroll position with bounds checking
        self.helpScrollY = self.helpScrollY or 0
        self.helpScrollY = self.utils.clamp(self.helpScrollY - scrollAmount, 0, maxScroll)
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

-- Update help dialog scroll position based on mouse dragging
-- @param mouseY: Current mouse Y coordinate
function ui:updateHelpScrollFromMouse(mouseY)
    if not self.helpVisible or not self.helpScrollDragging then
        return
    end
    
    -- Calculate dialog dimensions (same as in drawHelpDialog)
    local dialogWidth = 700
    local dialogHeight = 500
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    local contentY = dialogY + 40
    local contentHeight = dialogHeight - 60
    
    -- Calculate total content height
    local helpSections = self:getHelpContent()
    local totalContentHeight = 0
    for _, section in ipairs(helpSections) do
        if section.title then
            totalContentHeight = totalContentHeight + 20  -- Title height
        end
        if section.content then
            totalContentHeight = totalContentHeight + (#section.content * 16) + 8  -- Content lines + spacing
        end
    end
    
    -- Only scroll if content is larger than container
    if totalContentHeight > contentHeight then
        local scrollBarY = contentY
        local scrollBarHeight = contentHeight
        local scrollThumbHeight = math.max(20, scrollBarHeight * (contentHeight / totalContentHeight))
        local maxScroll = totalContentHeight - contentHeight
        
        -- Calculate new thumb position based on mouse Y minus drag offset
        local newThumbY = mouseY - self.helpScrollDragOffset
        
        -- Convert thumb position to scroll ratio
        local thumbRange = scrollBarHeight - scrollThumbHeight
        local thumbRatio = self.utils.clamp((newThumbY - scrollBarY) / thumbRange, 0, 1)
        
        -- Update scroll position
        self.helpScrollY = thumbRatio * maxScroll
    end
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

-- Handle keyboard text input for BPM text field and pattern name input
-- @param text: Text character that was typed
function ui:textinput(text)
    if self.bpmTextInputActive then
        -- Only allow numeric input (0-9) for BPM
        if text:match("[0-9]") and string.len(self.bpmTextInputBuffer) < 3 then
            self.bpmTextInputBuffer = self.bpmTextInputBuffer .. text
            self.bpmTextInputCursorTimer = 0  -- Reset cursor blink
        end
    elseif self.patternNameInputActive then
        -- Allow alphanumeric, hyphens, and underscores for pattern names
        if text:match("[%w%-_]") and string.len(self.patternNameInput) < 50 then
            self.patternNameInput = self.patternNameInput .. text
            self.patternNameInputCursorTimer = 0  -- Reset cursor blink
        end
    end
end

-- Handle keyboard key press events for BPM text field and pattern name input
-- @param key: Key that was pressed
function ui:keypressed(key)
    if self.bpmTextInputActive then
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
    elseif self.patternNameInputActive then
        if key == "backspace" then
            -- Remove last character from pattern name
            if string.len(self.patternNameInput) > 0 then
                self.patternNameInput = string.sub(self.patternNameInput, 1, -2)
                self.patternNameInputCursorTimer = 0  -- Reset cursor blink
            end
        elseif key == "return" or key == "enter" or key == "kpenter" then
            -- Deactivate pattern name input
            self.patternNameInputActive = false
        elseif key == "escape" then
            -- Cancel pattern name input
            self.patternNameInputActive = false
            self.patternNameInput = ""
        end
    elseif self.patternListVisible then
        -- Handle keyboard navigation in pattern selection dialog
        if key == "up" then
            self.selectedPatternIndex = math.max(1, self.selectedPatternIndex - 1)
        elseif key == "down" then
            self.selectedPatternIndex = math.min(#self.patternList, self.selectedPatternIndex + 1)
        elseif key == "return" or key == "enter" or key == "kpenter" then
            -- Execute save or load action
            if self.patternDialogMode == "save" then
                self:executeSavePattern()
            elseif self.patternDialogMode == "load" then
                self:executeLoadPattern()
            end
        elseif key == "escape" then
            -- Close dialog
            self:closePatternDialog()
        end
    elseif self.helpVisible then
        -- Handle keyboard input for help dialog
        if key == "escape" then
            -- Close help dialog
            self.helpVisible = false
        end
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

-- Handle pattern control button clicks
-- @param x, y: Mouse coordinates
-- @return: true if a UI element was clicked, false otherwise
function ui:handlePatternControlClicks(x, y)
    -- Calculate pattern button positions (matching drawPatternControls)
    local saveX = 200
    local loadX = saveX + self.patternButtonWidth + 10
    local newX = loadX + self.patternButtonWidth + 10
    local nameInputX = newX + self.patternButtonWidth + 20
    local nameInputWidth = 150
    local nameInputHeight = self.patternButtonHeight
    
    -- Check Save button
    if self.utils.pointInRect(x, y, saveX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight) then
        self.clickedButton = "SAVE"
        self:openSavePatternDialog()
        return true
    -- Check Load button
    elseif self.utils.pointInRect(x, y, loadX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight) then
        self.clickedButton = "LOAD"
        self:openLoadPatternDialog()
        return true
    -- Check New button (creates new empty pattern)
    elseif self.utils.pointInRect(x, y, newX, self.patternControlsY, self.patternButtonWidth, self.patternButtonHeight) then
        self.clickedButton = "NEW"
        self:createNewPattern()
        return true
    -- Check pattern name input field
    elseif self.utils.pointInRect(x, y, nameInputX, self.patternControlsY, nameInputWidth, nameInputHeight) then
        self.patternNameInputActive = true
        self.patternNameInput = ""  -- Clear input when clicking
        self.patternNameInputCursorTimer = 0
        return true
    end
    
    -- Check pattern selection dialog clicks if visible
    if self.patternListVisible then
        return self:handlePatternDialogClicks(x, y)
    end
    
    return false
end

-- Open save pattern dialog
-- Shows pattern selection interface for saving current pattern
function ui:openSavePatternDialog()
    self.patternDialogMode = "save"
    self.patternList = self.sequencer:getPatternList()
    self.patternListVisible = true
    self.selectedPatternIndex = 1
end

-- Open load pattern dialog
-- Shows pattern selection interface for loading existing pattern
function ui:openLoadPatternDialog()
    self.patternDialogMode = "load"
    self.patternList = self.sequencer:getPatternList()
    
    -- Check if any patterns exist before showing dialog
    if #self.patternList == 0 then
        print("No saved patterns found. Create some patterns first.")
        return
    end
    
    self.patternListVisible = true
    self.selectedPatternIndex = 1
end

-- Create new empty pattern
-- Clears current pattern and resets settings to defaults
function ui:createNewPattern()
    if self.sequencer then
        -- Clear current pattern
        self.sequencer:clearPattern()
        
        -- Reset BPM to default
        self.sequencer:setBPM(120)
        
        -- Reset all track volumes to default
        if self.audio then
            self.audio:resetAllVolumes()
        end
        
        -- Reset pattern name input
        self.patternNameInput = ""
        self.patternNameInputActive = false
    end
end

-- Handle clicks within pattern selection dialog
-- @param x, y: Mouse coordinates
-- @return: true if a UI element was clicked, false otherwise
function ui:handlePatternDialogClicks(x, y)
    if not self.patternListVisible or #self.patternList == 0 then return false end
    
    -- Dialog dimensions and position (matching drawPatternSelectionDialog)
    local dialogWidth = 300
    local dialogHeight = math.min(200, #self.patternList * 25 + 60)
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    
    -- Check pattern list item clicks
    local listY = dialogY + 35
    for i, patternName in ipairs(self.patternList) do
        local itemY = listY + (i - 1) * 25
        if self.utils.pointInRect(x, y, dialogX + 5, itemY - 2, dialogWidth - 10, 20) then
            self.selectedPatternIndex = i
            return true
        end
    end
    
    -- Check dialog buttons
    local buttonY = dialogY + dialogHeight - 35
    local cancelX = dialogX + 10
    local confirmX = dialogX + dialogWidth - 70
    
    if self.utils.pointInRect(x, y, cancelX, buttonY, 50, 25) then
        -- Cancel button - close dialog
        self:closePatternDialog()
        return true
    elseif self.utils.pointInRect(x, y, confirmX, buttonY, 50, 25) then
        -- Confirm button - execute save or load
        if self.patternDialogMode == "save" then
            self:executeSavePattern()
        elseif self.patternDialogMode == "load" then
            self:executeLoadPattern()
        end
        return true
    end
    
    return false
end

-- Close pattern selection dialog
-- Hides the dialog and resets dialog state
function ui:closePatternDialog()
    self.patternListVisible = false
    self.patternDialogMode = "none"
    self.selectedPatternIndex = 1
end

-- Execute pattern save operation
-- Saves current pattern with specified name
function ui:executeSavePattern()
    local patternName = self.patternNameInput
    
    -- Use selected pattern name if input is empty and patterns exist
    if patternName == "" and self.selectedPatternIndex <= #self.patternList then
        patternName = self.patternList[self.selectedPatternIndex]
    end
    
    -- Check if pattern name is still empty (no input and no selection)
    if patternName == "" then
        print("Error: Please enter a pattern name or select an existing pattern.")
        return
    end
    
    -- Validate filename
    if not self.sequencer:validatePatternFilename(patternName) then
        print("Invalid pattern name. Use only letters, numbers, hyphens, and underscores.")
        return
    end
    
    -- Save pattern
    local success, error_msg = self.sequencer:savePattern(patternName)
    if success then
        print("Pattern saved: " .. patternName)
        self:closePatternDialog()
        self.patternNameInput = ""
        self.patternNameInputActive = false
    else
        print("Error saving pattern: " .. (error_msg or "Unknown error"))
    end
end

-- Execute pattern load operation
-- Loads selected pattern from file
function ui:executeLoadPattern()
    -- Check if there are any patterns to load
    if #self.patternList == 0 then
        print("Error: No saved patterns found.")
        return
    end
    
    -- Check if selection is valid
    if self.selectedPatternIndex < 1 or self.selectedPatternIndex > #self.patternList then
        print("Error: Invalid pattern selection.")
        return
    end
    
    local patternName = self.patternList[self.selectedPatternIndex]
    
    -- Load pattern
    local success, error_msg = self.sequencer:loadPattern(patternName)
    if success then
        print("Pattern loaded: " .. patternName)
        self:closePatternDialog()
        self.patternNameInput = patternName
        self.patternNameInputActive = false
    else
        print("Error loading pattern: " .. (error_msg or "Unknown error"))
    end
end

-- Draw help dialog with comprehensive user manual
-- Displays a scrollable help window with complete instructions for using the drum sequencer
function ui:drawHelpDialog()
    if not love or not love.graphics then return end
    
    -- Dialog dimensions and positioning
    local dialogWidth = 700
    local dialogHeight = 500
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    
    -- Semi-transparent background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Dialog background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight)
    
    -- Dialog border
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX, dialogY, dialogWidth, dialogHeight)
    
    -- Title bar
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, 40)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("MIDI Drum Sequencer - Help & User Manual", dialogX + 10, dialogY + 12)
    
    -- Close button (X in top right)
    local closeX = dialogX + dialogWidth - 35
    local closeY = dialogY + 5
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", closeX, closeY, 30, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("X", closeX + 11, closeY + 8)
    
    -- Content area setup
    local contentX = dialogX + 15
    local contentY = dialogY + 50
    local contentWidth = dialogWidth - 30
    local contentHeight = dialogHeight - 60
    local lineHeight = 16
    local sectionSpacing = 8
    
    -- Scissor test to clip content to dialog area
    love.graphics.setScissor(contentX, contentY, contentWidth, contentHeight)
    
    -- Calculate scroll offset
    local scrollOffset = self.helpScrollY or 0
    local currentY = contentY - scrollOffset
    
    -- Help content
    local helpSections = self:getHelpContent()
    
    for _, section in ipairs(helpSections) do
        -- Section title
        if section.title then
            love.graphics.setColor(0.9, 0.9, 0.4, 1)  -- Yellow for titles
            love.graphics.print(section.title, contentX, currentY)
            currentY = currentY + lineHeight + 4
        end
        
        -- Section content
        if section.content then
            love.graphics.setColor(0.9, 0.9, 0.9, 1)  -- Light gray for content
            for _, line in ipairs(section.content) do
                if line == "" then
                    currentY = currentY + lineHeight / 2  -- Half line for empty lines
                else
                    love.graphics.print(line, contentX + 10, currentY)
                    currentY = currentY + lineHeight
                end
            end
        end
        
        currentY = currentY + sectionSpacing
    end
    
    -- Clear scissor test
    love.graphics.setScissor()
    
    -- Scroll indicator if needed
    local totalContentHeight = currentY - (contentY - scrollOffset)
    if totalContentHeight > contentHeight then
        local scrollBarX = dialogX + dialogWidth - 20
        local scrollBarY = contentY
        local scrollBarHeight = contentHeight
        local scrollThumbHeight = math.max(20, scrollBarHeight * (contentHeight / totalContentHeight))
        local scrollThumbY = scrollBarY + (scrollOffset / (totalContentHeight - contentHeight)) * (scrollBarHeight - scrollThumbHeight)
        
        -- Scroll bar background
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", scrollBarX, scrollBarY, 15, scrollBarHeight)
        
        -- Scroll thumb
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.rectangle("fill", scrollBarX + 2, scrollThumbY, 11, scrollThumbHeight)
    end
end

-- Get comprehensive help content for the drum sequencer
-- Returns structured help data with titles and content sections
function ui:getHelpContent()
    return {
        {
            title = "🥁 WELCOME TO MIDI DRUM SEQUENCER",
            content = {
                "A professional 16-step drum pattern sequencer with 8 tracks, real-time audio,",
                "and MIDI export capabilities. Create drum beats, adjust volumes, and export to MIDI.",
                ""
            }
        },
        {
            title = "🎵 GETTING STARTED",
            content = {
                "• Click grid cells to toggle drum hits on/off",
                "• Press PLAY to start playback, STOP to stop",
                "• Adjust BPM with slider or text input (60-300 BPM)",
                "• Use volume sliders on the right to control track levels",
                ""
            }
        },
        {
            title = "🎛️ TRANSPORT CONTROLS",
            content = {
                "PLAY    - Start/continue playback",
                "STOP    - Stop playback",
                "RESET   - Stop and return to step 1",
                "CLEAR   - Clear entire pattern grid",
                "EXPORT  - Export pattern as MIDI file",
                "METRO   - Toggle metronome on/off",
                "HELP    - Show this help dialog",
                ""
            }
        },
        {
            title = "🥁 DRUM TRACKS (Top to Bottom)",
            content = {
                "Track 1: Kick Drum        - Deep bass drum",
                "Track 2: Snare Drum       - Sharp snare hit",
                "Track 3: Closed Hi-Hat    - Crisp hi-hat",
                "Track 4: Open Hi-Hat      - Sizzling hi-hat",
                "Track 5: Crash Cymbal     - Bright crash",
                "Track 6: Ride Cymbal      - Metallic ride",
                "Track 7: Low Tom          - Deep tom",
                "Track 8: High Tom         - Bright tom",
                ""
            }
        },
        {
            title = "⚡ QUICK TIPS",
            content = {
                "• Click track labels to preview sounds",
                "• Pattern loops automatically when playing",
                "• Current step is highlighted during playback",
                "• Grid cells light up when sounds are triggered",
                "• Metronome has accent beats on steps 1, 5, 9, 13",
                ""
            }
        },
        {
            title = "💾 PATTERN MANAGEMENT",
            content = {
                "SAVE    - Save current pattern with custom name",
                "LOAD    - Load previously saved pattern",
                "DELETE  - Remove selected pattern from list",
                "",
                "Patterns preserve: drum hits, BPM, volumes, metronome settings",
                ""
            }
        },
        {
            title = "🎚️ VOLUME CONTROLS",
            content = {
                "• Individual sliders for each drum track (0-100%)",
                "• Reset Vol button restores all tracks to 70%",
                "• Separate metronome volume controls",
                "• Volumes are saved with patterns",
                ""
            }
        },
        {
            title = "🎼 MIDI EXPORT",
            content = {
                "• Exports Standard MIDI File (SMF) format",
                "• Uses General MIDI Drum Map (Channel 10)",
                "• Compatible with all DAWs and MIDI software",
                "• Preserves timing and pattern structure",
                "• Files saved as: drum_pattern_YYYYMMDD_HHMMSS.mid",
                ""
            }
        },
        {
            title = "🔊 AUDIO SYSTEM",
            content = {
                "• High-quality procedural drum synthesis",
                "• Real-time audio with low latency",
                "• Support for WAV sample loading",
                "• Place WAV files in assets/samples/ for custom sounds",
                ""
            }
        },
        {
            title = "⌨️ KEYBOARD SHORTCUTS",
            content = {
                "• Click and drag to interact with UI elements",
                "• All controls are mouse-based for simplicity",
                "• Pattern name input supports standard text editing",
                ""
            }
        },
        {
            title = "🔧 TROUBLESHOOTING",
            content = {
                "No Sound:",
                "  • Check system volume and audio output",
                "  • Ensure track volumes are not at 0%",
                "",
                "MIDI Export Issues:",
                "  • Check file permissions in save directory",
                "  • Ensure pattern has some drum hits",
                "",
                "Performance Issues:",
                "  • Close other audio applications",
                "  • Reduce metronome volume if causing distortion",
                ""
            }
        },
        {
            title = "📄 LICENSE & CREDITS",
            content = {
                "GNU General Public License v3.0 (GPL-3.0)",
                "Free and open source software",
                "",
                "Built with LÖVE 2D framework",
                "Professional drum sequencer for music production",
                "",
                "Press ESC or click X to close this help dialog"
            }
        }
    }
end

return ui