--[[
    MIDI Drum Sequencer - test_subtle_ui_colors.lua
    
    Unit tests for subtle UI color system.
    Tests color palette definition, helper functions, and UI integration.
    
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
        getFont = function() return {getWidth = function() return 50 end, getHeight = function() return 12 end} end,
        getWidth = function() return 900 end,
        getHeight = function() return 650 end
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

local TestSubtleUIColors = {}

function TestSubtleUIColors:setUp()
    -- Set up UI dependencies
    ui.utils = utils
    
    -- Reset UI state
    ui.hoveredCell = nil
end

function TestSubtleUIColors:tearDown()
    ui.utils = nil
end

function TestSubtleUIColors:testUIColorPaletteDefinition()
    -- Test that UI color palette is properly defined
    luaunit.assertNotNil(ui.uiColors, "UI colors palette should be defined")
    luaunit.assertEquals(type(ui.uiColors), "table", "UI colors should be a table")
    
    -- Test required color categories exist
    local requiredCategories = {
        "background", "panelBackground", "border",
        "textPrimary", "textSecondary", "textAccent",
        "buttonNormal", "buttonHover", "buttonPressed", "buttonActive",
        "sliderTrack", "sliderHandle", "sliderHandleActive",
        "accentBlue", "accentPurple", "accentTeal"
    }
    
    for _, category in ipairs(requiredCategories) do
        luaunit.assertNotNil(ui.uiColors[category], 
                           string.format("UI color category '%s' should be defined", category))
        luaunit.assertEquals(type(ui.uiColors[category]), "table",
                           string.format("UI color '%s' should be a table", category))
        luaunit.assertEquals(#ui.uiColors[category], 3,
                           string.format("UI color '%s' should have 3 RGB components", category))
    end
end

function TestSubtleUIColors:testUIColorValues()
    -- Test that color values are in valid RGB range (0-1)
    for colorName, color in pairs(ui.uiColors) do
        for i, component in ipairs(color) do
            luaunit.assertTrue(component >= 0 and component <= 1,
                             string.format("Color %s component %d should be 0-1 range", colorName, i))
            luaunit.assertEquals(type(component), "number",
                               string.format("Color %s component %d should be a number", colorName, i))
        end
    end
end

function TestSubtleUIColors:testSetUIColorFunction()
    -- Test the setUIColor helper function
    luaunit.assertEquals(type(ui.setUIColor), "function", "setUIColor should be a function")
    
    -- Test valid color setting (we can't easily test love.graphics.setColor calls in unit tests)
    -- Just ensure function doesn't crash
    ui:setUIColor("textPrimary")
    ui:setUIColor("buttonNormal")
    ui:setUIColor("background")
end

function TestSubtleUIColors:testColorSubtlety()
    -- Test that UI colors are appropriately subtle (not too bright)
    -- Background colors should be quite dark
    local bg = ui.uiColors.background
    local maxBgComponent = math.max(bg[1], bg[2], bg[3])
    luaunit.assertTrue(maxBgComponent < 0.2, "Background should be quite dark for subtlety")
    
    -- Panel backgrounds should be slightly lighter than main background
    local panel = ui.uiColors.panelBackground
    local maxPanelComponent = math.max(panel[1], panel[2], panel[3])
    luaunit.assertTrue(maxPanelComponent > maxBgComponent, "Panel should be lighter than background")
    luaunit.assertTrue(maxPanelComponent < 0.3, "Panel background should still be subtle")
end

function TestSubtleUIColors:testButtonColorProgression()
    -- Test that button colors follow logical progression
    local normal = ui.uiColors.buttonNormal
    local hover = ui.uiColors.buttonHover
    local pressed = ui.uiColors.buttonPressed
    
    -- Calculate brightness (simple average)
    local function brightness(color)
        return (color[1] + color[2] + color[3]) / 3
    end
    
    local normalBrightness = brightness(normal)
    local hoverBrightness = brightness(hover)
    local pressedBrightness = brightness(pressed)
    
    luaunit.assertTrue(hoverBrightness > normalBrightness, "Hover should be brighter than normal")
    luaunit.assertTrue(pressedBrightness < normalBrightness, "Pressed should be darker than normal")
end

function TestSubtleUIColors:testSliderColorProgression()
    -- Test that slider colors follow logical progression
    local track = ui.uiColors.sliderTrack
    local handle = ui.uiColors.sliderHandle
    local active = ui.uiColors.sliderHandleActive
    
    -- Calculate brightness
    local function brightness(color)
        return (color[1] + color[2] + color[3]) / 3
    end
    
    local trackBrightness = brightness(track)
    local handleBrightness = brightness(handle)
    local activeBrightness = brightness(active)
    
    luaunit.assertTrue(handleBrightness > trackBrightness, "Handle should be brighter than track")
    luaunit.assertTrue(activeBrightness > handleBrightness, "Active handle should be brightest")
end

function TestSubtleUIColors:testTextColorHierarchy()
    -- Test that text colors have appropriate hierarchy
    local primary = ui.uiColors.textPrimary
    local secondary = ui.uiColors.textSecondary
    local accent = ui.uiColors.textAccent
    
    -- Calculate brightness
    local function brightness(color)
        return (color[1] + color[2] + color[3]) / 3
    end
    
    local primaryBrightness = brightness(primary)
    local secondaryBrightness = brightness(secondary)
    local accentBrightness = brightness(accent)
    
    luaunit.assertTrue(primaryBrightness > secondaryBrightness, 
                     "Primary text should be brighter than secondary")
    luaunit.assertTrue(primaryBrightness > 0.8, "Primary text should be quite bright for readability")
    luaunit.assertTrue(secondaryBrightness > 0.5, "Secondary text should still be readable")
end

function TestSubtleUIColors:testAccentColorDistinctiveness()
    -- Test that accent colors are distinct from each other
    local blue = ui.uiColors.accentBlue
    local purple = ui.uiColors.accentPurple
    local teal = ui.uiColors.accentTeal
    
    -- Calculate color distance (simple Euclidean distance in RGB space)
    local function colorDistance(color1, color2)
        return math.sqrt(
            (color1[1] - color2[1])^2 + 
            (color1[2] - color2[2])^2 + 
            (color1[3] - color2[3])^2
        )
    end
    
    luaunit.assertTrue(colorDistance(blue, purple) > 0.2, "Blue and purple should be distinct")
    luaunit.assertTrue(colorDistance(blue, teal) > 0.2, "Blue and teal should be distinct")
    luaunit.assertTrue(colorDistance(purple, teal) > 0.2, "Purple and teal should be distinct")
end

function TestSubtleUIColors:testColorConsistency()
    -- Test that colors within families are consistent
    -- Button colors should maintain similar hue relationships
    local buttonNormal = ui.uiColors.buttonNormal
    local buttonHover = ui.uiColors.buttonHover
    local buttonPressed = ui.uiColors.buttonPressed
    
    -- Test that color relationships are maintained (same hue family)
    -- For subtle colors, we mainly check that they don't have wildly different hue shifts
    for i = 1, 3 do
        local normalComponent = buttonNormal[i]
        local hoverComponent = buttonHover[i]
        local pressedComponent = buttonPressed[i]
        
        -- Hover should be consistently brighter across all channels
        luaunit.assertTrue(hoverComponent >= normalComponent,
                         string.format("Hover component %d should be >= normal", i))
        
        -- Pressed should be consistently darker across all channels
        luaunit.assertTrue(pressedComponent <= normalComponent,
                         string.format("Pressed component %d should be <= normal", i))
    end
end

function TestSubtleUIColors:testColorMemoryUsage()
    -- Test that color system is memory efficient
    luaunit.assertEquals(type(ui.uiColors), "table", "UI colors should be stored in a table")
    
    -- Count total color definitions
    local colorCount = 0
    for _, _ in pairs(ui.uiColors) do
        colorCount = colorCount + 1
    end
    
    luaunit.assertTrue(colorCount >= 15, "Should have at least 15 color definitions")
    luaunit.assertTrue(colorCount <= 25, "Should not have excessive color definitions")
    
    -- Each color should have exactly 3 components
    for colorName, color in pairs(ui.uiColors) do
        luaunit.assertEquals(#color, 3, 
                           string.format("Color %s should have exactly 3 RGB components", colorName))
    end
end

function TestSubtleUIColors:testUIDrawingFunctionExists()
    -- Test that UI drawing functions exist and are callable
    luaunit.assertEquals(type(ui.draw), "function", "UI draw function should exist")
    luaunit.assertEquals(type(ui.drawUIPanels), "function", "drawUIPanels function should exist")
    luaunit.assertEquals(type(ui.drawButton), "function", "drawButton function should exist")
    luaunit.assertEquals(type(ui.drawBPMControl), "function", "drawBPMControl function should exist")
    luaunit.assertEquals(type(ui.drawVolumeControls), "function", "drawVolumeControls function should exist")
end

function TestSubtleUIColors:testColorSystemDocumentation()
    -- Test that the color system is well-documented
    luaunit.assertNotNil(ui.uiColors, "UI colors should be defined")
    luaunit.assertEquals(type(ui.uiColors), "table", "UI colors should be a table")
    
    -- setUIColor function should exist
    luaunit.assertEquals(type(ui.setUIColor), "function", "setUIColor should be a function")
    
    -- Color system should be self-contained (no external dependencies beyond RGB values)
    for colorName, color in pairs(ui.uiColors) do
        luaunit.assertEquals(type(color), "table", 
                           string.format("Color %s should be a table", colorName))
        luaunit.assertEquals(#color, 3, 
                           string.format("Color %s should have 3 components", colorName))
        
        for i, component in ipairs(color) do
            luaunit.assertEquals(type(component), "number", 
                               string.format("Color %s component %d should be a number", colorName, i))
        end
    end
end

return TestSubtleUIColors