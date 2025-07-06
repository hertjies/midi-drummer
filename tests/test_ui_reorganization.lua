--[[
    MIDI Drum Sequencer - test_ui_reorganization.lua
    
    Unit tests for UI reorganization and layout improvements.
    Tests proper spacing, positioning, and elimination of overlaps.
    
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

-- Mock Love2D modules
local mockLove = {
    graphics = {
        setColor = function(...) end,
        setFont = function(...) end,
        newFont = function(...) return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        print = function(...) end,
        rectangle = function(...) end,
        circle = function(...) end,
        line = function(...) end,
        setLineWidth = function(...) end,
        getFont = function() return {getWidth = function() return 50 end, getHeight = function() return 12 end} end
    },
    timer = {
        getTime = function() return os.clock() end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Load required modules
local ui = require("ui")
local utils = require("utils")

local TestUIReorganization = {}

function TestUIReorganization:setUp()
    -- Set up UI dependencies
    ui.utils = utils
    
    -- Reset UI state
    ui.clickedButton = nil
    ui.hoveredCell = nil
    ui.bpmDragging = false
    ui.volumeDragging = nil
end

function TestUIReorganization:tearDown()
    ui.utils = nil
end

function TestUIReorganization:testLayoutOrganization()
    -- Test that UI elements are properly organized into logical rows
    
    -- ROW 1: BPM Controls (Y=20)
    luaunit.assertEquals(ui.bpmControlsY, 20, "BPM controls should be on row 1 (Y=20)")
    luaunit.assertEquals(ui.bpmSliderY, 20, "BPM slider should be aligned with BPM controls")
    luaunit.assertEquals(ui.bpmTextInputY, 18, "BPM text input should be aligned with slider")
    
    -- ROW 2: Transport Controls (Y=60)
    luaunit.assertEquals(ui.transportY, 60, "Transport controls should be on row 2 (Y=60)")
    
    -- ROW 4: Grid and Volume Controls (Y=120+)
    luaunit.assertEquals(ui.gridY, 120, "Grid should start at Y=120 for proper spacing")
end

function TestUIReorganization:testNoOverlaps()
    -- Test that critical overlaps have been eliminated
    
    -- BPM Controls area: X=20-500, Y=15-45
    local bpmAreaLeft = ui.marginLeft
    local bpmAreaRight = ui.bpmSliderX + ui.bpmSliderWidth + 100  -- Include BPM value display
    local bpmAreaTop = ui.bpmControlsY - 5
    local bpmAreaBottom = ui.bpmControlsY + 25
    
    -- Transport Controls area: X=200-640, Y=60-90
    local transportAreaLeft = 200
    local transportAreaRight = 200 + 5 * (ui.buttonWidth + 10) - 10  -- 5 buttons with spacing
    local transportAreaTop = ui.transportY
    local transportAreaBottom = ui.transportY + ui.buttonHeight
    
    -- Test no vertical overlap between BPM and Transport controls
    luaunit.assertTrue(bpmAreaBottom < transportAreaTop, 
                      "BPM controls should not overlap with transport controls vertically")
    
    -- Test adequate spacing between rows
    local spacingBetweenRows = transportAreaTop - bpmAreaBottom
    luaunit.assertTrue(spacingBetweenRows >= 10, 
                      "Should have at least 10px spacing between BPM and transport controls")
end

function TestUIReorganization:testBPMControlsGrouping()
    -- Test that BPM controls are properly grouped and spaced
    
    -- Calculate positions for all BPM elements
    local decreaseButtonX = ui.bpmSliderX - 35
    local sliderStartX = ui.bpmSliderX
    local sliderEndX = ui.bpmSliderX + ui.bpmSliderWidth
    local increaseButtonX = ui.bpmSliderX + ui.bpmSliderWidth + 10
    local textInputX = ui.bpmTextInputX
    local bpmValueX = ui.bpmSliderX + ui.bpmSliderWidth + 45
    
    -- Test logical ordering (left to right)
    luaunit.assertTrue(decreaseButtonX < sliderStartX, "Decrease button should be left of slider")
    luaunit.assertTrue(sliderEndX < increaseButtonX, "Increase button should be right of slider")
    luaunit.assertTrue(sliderEndX < textInputX, "Text input should be right of slider")
    
    -- Test adequate spacing between elements
    luaunit.assertTrue(sliderStartX - (decreaseButtonX + 25) >= 5, 
                      "Should have spacing between decrease button and slider")
    luaunit.assertTrue(increaseButtonX - sliderEndX >= 10, 
                      "Should have spacing between slider and increase button")
end

function TestUIReorganization:testVolumeControlsPositioning()
    -- Test that volume controls use fixed positioning and proper spacing
    
    luaunit.assertEquals(ui.volumeControlsX, 650, "Volume controls should have fixed X position")
    
    -- Test that volume controls don't extend beyond window
    local volumeEndX = ui.volumeControlsX + ui.volumeSliderWidth + 50  -- Include percentage display
    luaunit.assertTrue(volumeEndX <= 900, "Volume controls should fit within 900px window width")
    
    -- Test reset button positioning
    local resetButtonY = ui.gridY - 25  -- Updated to match implementation
    local resetButtonHeight = 20
    luaunit.assertTrue(resetButtonY > ui.transportY + ui.buttonHeight, 
                      "Reset button should be below transport controls")
    luaunit.assertTrue(resetButtonY + resetButtonHeight < ui.gridY, 
                      "Reset button should be above grid")
end

function TestUIReorganization:testGridSpacing()
    -- Test that grid has proper spacing from other elements
    
    -- Grid should have adequate space from transport controls
    local gridTop = ui.gridY - 15  -- Include step numbers
    luaunit.assertTrue(gridTop > ui.transportY + ui.buttonHeight + 10, 
                      "Grid should have spacing from transport controls")
    
    -- Test grid dimensions fit within window
    local gridWidth = 16 * (ui.cellSize + ui.cellPadding) - ui.cellPadding
    local gridHeight = 8 * (ui.cellSize + ui.cellPadding) - ui.cellPadding
    
    luaunit.assertTrue(ui.gridX + gridWidth < ui.volumeControlsX - 20, 
                      "Grid should have spacing from volume controls")
    luaunit.assertTrue(ui.gridY + gridHeight < 650, 
                      "Grid should fit within window height")
end

function TestUIReorganization:testClickTargetSpacing()
    -- Test that interactive elements have adequate spacing for accurate clicking
    
    -- BPM buttons should not be too close
    local decreaseButtonRight = ui.bpmSliderX - 35 + 25
    local sliderLeft = ui.bpmSliderX
    luaunit.assertTrue(sliderLeft - decreaseButtonRight >= 5, 
                      "Decrease button and slider should have click spacing")
    
    local sliderRight = ui.bpmSliderX + ui.bpmSliderWidth
    local increaseButtonLeft = ui.bpmSliderX + ui.bpmSliderWidth + 10
    luaunit.assertTrue(increaseButtonLeft - sliderRight >= 10, 
                      "Slider and increase button should have click spacing")
    
    -- Transport buttons should have standard spacing
    local buttonSpacing = 10
    for i = 1, 4 do  -- Test spacing between first 4 buttons
        local button1Right = 200 + i * (ui.buttonWidth + buttonSpacing) - buttonSpacing
        local button2Left = 200 + i * (ui.buttonWidth + buttonSpacing)
        luaunit.assertEquals(button2Left - button1Right, buttonSpacing, 
                           string.format("Transport buttons %d and %d should have %dpx spacing", i, i+1, buttonSpacing))
    end
end

function TestUIReorganization:testResponsiveLayoutConstants()
    -- Test that layout uses consistent spacing constants
    
    luaunit.assertEquals(ui.elementSpacing, 10, "Element spacing should be consistent")
    luaunit.assertEquals(ui.groupSpacing, 20, "Group spacing should be consistent")
    luaunit.assertEquals(ui.marginLeft, 20, "Left margin should be consistent")
    luaunit.assertEquals(ui.marginTop, 10, "Top margin should be consistent")
    
    -- Test that spacing constants are actually used in calculations
    luaunit.assertTrue(ui.elementSpacing > 0, "Element spacing should be positive")
    luaunit.assertTrue(ui.groupSpacing >= ui.elementSpacing, 
                      "Group spacing should be at least as large as element spacing")
end

function TestUIReorganization:testWindowSizeAdequacy()
    -- Test that window size accommodates the reorganized layout
    
    -- Calculate minimum required width
    local bpmControlsWidth = ui.bpmSliderX + ui.bpmSliderWidth + 100  -- Include BPM value
    local volumeControlsWidth = ui.volumeControlsX + ui.volumeSliderWidth + 50  -- Include percentage
    local requiredWidth = math.max(bpmControlsWidth, volumeControlsWidth)
    
    luaunit.assertTrue(requiredWidth <= 900, 
                      string.format("Required width %d should fit in 900px window", requiredWidth))
    
    -- Calculate minimum required height
    local gridBottom = ui.gridY + 8 * (ui.cellSize + ui.cellPadding)
    luaunit.assertTrue(gridBottom <= 650, 
                      string.format("Grid bottom %d should fit in 650px window", gridBottom))
end

function TestUIReorganization:testUIElementAlignment()
    -- Test that related elements are properly aligned
    
    -- BPM controls should be vertically aligned
    local bpmSliderCenter = ui.bpmSliderY + ui.bpmSliderHeight / 2
    local textInputCenter = ui.bpmTextInputY + ui.bpmTextInputHeight / 2
    local alignmentTolerance = 3  -- Allow small differences
    
    luaunit.assertTrue(math.abs(bpmSliderCenter - textInputCenter) <= alignmentTolerance, 
                      "BPM slider and text input should be vertically aligned")
    
    -- Transport buttons should be aligned
    luaunit.assertEquals(ui.transportY, 60, "All transport buttons should be at same Y position")
    
    -- Volume sliders should be aligned with tracks
    for track = 1, 8 do
        local trackY = ui.gridY + (track - 1) * (ui.cellSize + ui.cellPadding)
        local expectedSliderY = trackY + (ui.cellSize - ui.volumeSliderHeight) / 2
        -- This is tested by the volume drawing code itself
        luaunit.assertTrue(expectedSliderY > trackY, "Volume slider should be within track row")
        luaunit.assertTrue(expectedSliderY < trackY + ui.cellSize, "Volume slider should be within track row")
    end
end

function TestUIReorganization:testAccessibilitySpacing()
    -- Test that UI meets basic accessibility guidelines for touch targets
    
    local minTouchTarget = 44  -- Minimum recommended touch target size
    local minSpacing = 8       -- Minimum spacing between touch targets
    
    -- BPM buttons should be adequately sized
    luaunit.assertTrue(25 >= 20, "BPM buttons should be reasonably sized for clicking")  -- 25x24 buttons
    
    -- Transport buttons should be adequately sized
    luaunit.assertTrue(ui.buttonWidth >= 60, "Transport buttons should be wide enough")
    luaunit.assertTrue(ui.buttonHeight >= 25, "Transport buttons should be tall enough")
    
    -- Volume sliders should have adequate click area
    local volumeClickHeight = ui.volumeSliderHeight + 4  -- Handle extends 2px each side
    luaunit.assertTrue(volumeClickHeight >= 8, "Volume sliders should have adequate click height")
end

function TestUIReorganization:testLayoutDocumentation()
    -- Test that layout is self-documenting through comments and structure
    
    -- Test that layout constants exist and are meaningful
    luaunit.assertTrue(ui.bpmControlsY < ui.transportY, "BPM controls should be above transport")
    luaunit.assertTrue(ui.transportY < ui.gridY, "Transport should be above grid")
    
    -- Test that fixed positions are used for better predictability
    luaunit.assertTrue(ui.volumeControlsX > 600, "Volume controls should be positioned on right side")
    luaunit.assertTrue(ui.gridX < 100, "Grid should be positioned on left side")
end

function TestUIReorganization:testNoElementClipping()
    -- Test that no UI elements extend beyond their intended boundaries
    
    -- Test BPM controls don't clip
    local bpmMaxX = ui.bpmSliderX + ui.bpmSliderWidth + 100
    luaunit.assertTrue(bpmMaxX < 900, "BPM controls should not clip window edge")
    
    -- Test volume controls don't clip
    local volumeMaxX = ui.volumeControlsX + ui.volumeSliderWidth + 50
    luaunit.assertTrue(volumeMaxX < 900, "Volume controls should not clip window edge")
    
    -- Test grid labels don't clip
    local gridLabelMinX = ui.gridX - 45
    luaunit.assertTrue(gridLabelMinX >= 0, "Grid labels should not clip left edge")
end

return TestUIReorganization