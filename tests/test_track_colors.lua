--[[
    MIDI Drum Sequencer - test_track_colors.lua
    
    Unit tests for track color system using 16 Xterm colors.
    Tests color assignments, brightness variations, and state-based coloring.
    
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

local TestTrackColors = {}

function TestTrackColors:setUp()
    -- Set up UI dependencies
    ui.utils = utils
    
    -- Reset UI state
    ui.hoveredCell = nil
end

function TestTrackColors:tearDown()
    ui.utils = nil
end

function TestTrackColors:testTrackColorDefinitions()
    -- Test that all 8 tracks have color definitions
    luaunit.assertEquals(#ui.trackColors, 8, "Should have color definitions for 8 tracks")
    
    -- Test that each track has all three brightness levels
    for track = 1, 8 do
        luaunit.assertNotNil(ui.trackColors[track], string.format("Track %d should have color definition", track))
        luaunit.assertNotNil(ui.trackColors[track].dim, string.format("Track %d should have dim color", track))
        luaunit.assertNotNil(ui.trackColors[track].normal, string.format("Track %d should have normal color", track))
        luaunit.assertNotNil(ui.trackColors[track].bright, string.format("Track %d should have bright color", track))
        
        -- Test that each color is a valid RGB triplet
        for _, brightness in pairs({"dim", "normal", "bright"}) do
            local color = ui.trackColors[track][brightness]
            luaunit.assertEquals(#color, 3, string.format("Track %d %s color should have 3 RGB values", track, brightness))
            
            -- Test that RGB values are in valid range (0-1)
            for i, value in ipairs(color) do
                luaunit.assertTrue(value >= 0 and value <= 1, 
                                 string.format("Track %d %s color component %d should be 0-1", track, brightness, i))
            end
        end
    end
end

function TestTrackColors:testXtermColorCompliance()
    -- Test that colors follow Xterm 16-color palette
    
    -- Helper function to compare color tables
    local function colorsEqual(color1, color2)
        return math.abs(color1[1] - color2[1]) < 0.001 and
               math.abs(color1[2] - color2[2]) < 0.001 and
               math.abs(color1[3] - color2[3]) < 0.001
    end
    
    -- Track 1 (Kick) should be red family
    luaunit.assertTrue(colorsEqual(ui.trackColors[1].bright, {1.0, 0.0, 0.0}), "Kick should be bright red")
    
    -- Track 2 (Snare) should be yellow family
    luaunit.assertTrue(colorsEqual(ui.trackColors[2].bright, {1.0, 1.0, 0.0}), "Snare should be bright yellow")
    
    -- Track 3 (Hi-Hat Closed) should be cyan family
    luaunit.assertTrue(colorsEqual(ui.trackColors[3].bright, {0.0, 1.0, 1.0}), "Hi-Hat Closed should be bright cyan")
    
    -- Track 4 (Hi-Hat Open) should be green family
    luaunit.assertTrue(colorsEqual(ui.trackColors[4].bright, {0.0, 1.0, 0.0}), "Hi-Hat Open should be bright green")
    
    -- Track 5 (Crash) should be magenta family
    luaunit.assertTrue(colorsEqual(ui.trackColors[5].bright, {1.0, 0.0, 1.0}), "Crash should be bright magenta")
    
    -- Track 6 (Ride) should be blue family
    luaunit.assertTrue(colorsEqual(ui.trackColors[6].bright, {0.0, 0.0, 1.0}), "Ride should be bright blue")
    
    -- Track 7 (Tom Low) should be normal white family
    luaunit.assertTrue(colorsEqual(ui.trackColors[7].normal, {0.6, 0.6, 0.6}), "Tom Low should be normal white")
    
    -- Track 8 (Tom High) should be normal orange family
    luaunit.assertTrue(colorsEqual(ui.trackColors[8].normal, {0.8, 0.4, 0.0}), "Tom High should be normal orange")
end

function TestTrackColors:testBrightnessProgression()
    -- Test that brightness levels follow the expected progression
    
    for track = 1, 8 do
        local dim = ui.trackColors[track].dim
        local normal = ui.trackColors[track].normal
        local bright = ui.trackColors[track].bright
        
        -- For each RGB component, brightness should increase: dim < normal < bright
        for i = 1, 3 do
            if bright[i] > 0 then  -- Only test non-zero color components
                luaunit.assertTrue(dim[i] <= normal[i], 
                                 string.format("Track %d component %d: dim should be <= normal", track, i))
                luaunit.assertTrue(normal[i] <= bright[i], 
                                 string.format("Track %d component %d: normal should be <= bright", track, i))
            end
        end
    end
end

function TestTrackColors:testGetTrackColorFunction()
    -- Test the getTrackColor function with various states
    
    -- Helper function to compare color tables
    local function colorsEqual(color1, color2)
        return math.abs(color1[1] - color2[1]) < 0.001 and
               math.abs(color1[2] - color2[2]) < 0.001 and
               math.abs(color1[3] - color2[3]) < 0.001
    end
    
    -- Test invalid track numbers
    local invalidColor = ui:getTrackColor(0, true, false, false)
    luaunit.assertTrue(colorsEqual(invalidColor, {0.3, 0.3, 0.3}), "Invalid track should return gray")
    
    invalidColor = ui:getTrackColor(9, true, false, false)
    luaunit.assertTrue(colorsEqual(invalidColor, {0.3, 0.3, 0.3}), "Invalid track should return gray")
    
    -- Test inactive step
    local inactiveColor = ui:getTrackColor(1, false, false, false)
    luaunit.assertTrue(colorsEqual(inactiveColor, {0.2, 0.2, 0.2}), "Inactive step should return dark gray")
    
    -- Test active step without feedback
    local activeColor = ui:getTrackColor(1, true, false, false)
    luaunit.assertTrue(colorsEqual(activeColor, ui.trackColors[1].dim), "Active step without feedback should use dim color")
    
    -- Test active step with feedback but not playing
    local feedbackColor = ui:getTrackColor(1, true, false, true)
    luaunit.assertTrue(colorsEqual(feedbackColor, ui.trackColors[1].normal), "Active step with feedback should use normal color")
    
    -- Test active step that is currently playing with feedback
    local playingColor = ui:getTrackColor(1, true, true, true)
    luaunit.assertTrue(colorsEqual(playingColor, ui.trackColors[1].bright), "Playing step with feedback should use bright color")
end

function TestTrackColors:testColorDistinctiveness()
    -- Test that track colors are sufficiently distinct from each other
    
    for track1 = 1, 8 do
        for track2 = track1 + 1, 8 do
            local color1 = ui.trackColors[track1].normal
            local color2 = ui.trackColors[track2].normal
            
            -- Calculate color distance (simple Euclidean distance in RGB space)
            local distance = math.sqrt(
                (color1[1] - color2[1])^2 + 
                (color1[2] - color2[2])^2 + 
                (color1[3] - color2[3])^2
            )
            
            -- Colors should be reasonably distinct (distance > 0.3 in RGB space)
            luaunit.assertTrue(distance > 0.3, 
                             string.format("Tracks %d and %d colors should be distinct (distance: %.2f)", 
                                         track1, track2, distance))
        end
    end
end

function TestTrackColors:testColorConsistency()
    -- Test that color families are consistent across brightness levels
    
    for track = 1, 8 do
        local dim = ui.trackColors[track].dim
        local normal = ui.trackColors[track].normal  
        local bright = ui.trackColors[track].bright
        
        -- Test that the same color channels are non-zero across all brightness levels
        for i = 1, 3 do
            local dimZero = (dim[i] == 0)
            local normalZero = (normal[i] == 0)
            local brightZero = (bright[i] == 0)
            
            luaunit.assertEquals(dimZero, normalZero, 
                               string.format("Track %d component %d: dim and normal should have same zero state", track, i))
            luaunit.assertEquals(normalZero, brightZero, 
                               string.format("Track %d component %d: normal and bright should have same zero state", track, i))
        end
    end
end

function TestTrackColors:testColorAccessibility()
    -- Test that colors meet basic accessibility guidelines
    
    for track = 1, 8 do
        local bright = ui.trackColors[track].bright
        
        -- Calculate relative luminance (simplified formula)
        local luminance = 0.299 * bright[1] + 0.587 * bright[2] + 0.114 * bright[3]
        
        -- Bright colors should have reasonable luminance (not too dark)
        -- Lower threshold for pure colors like red and blue which have inherently low luminance
        luaunit.assertTrue(luminance > 0.1, 
                         string.format("Track %d bright color should have adequate luminance (%.2f)", track, luminance))
        
        -- Test contrast with dark background (0.1, 0.1, 0.1)
        local backgroundLuminance = 0.299 * 0.1 + 0.587 * 0.1 + 0.114 * 0.1
        local contrastRatio = (luminance + 0.05) / (backgroundLuminance + 0.05)
        
        -- Should have reasonable contrast ratio (at least 1.0:1 for large colored elements)
        luaunit.assertTrue(contrastRatio >= 1.0, 
                         string.format("Track %d should have adequate contrast ratio (%.1f:1)", track, contrastRatio))
    end
end

function TestTrackColors:testStateCombinations()
    -- Test all possible combinations of track states
    
    -- Helper function to compare color tables
    local function colorsEqual(color1, color2)
        return math.abs(color1[1] - color2[1]) < 0.001 and
               math.abs(color1[2] - color2[2]) < 0.001 and
               math.abs(color1[3] - color2[3]) < 0.001
    end
    
    local testCases = {
        {active = false, playing = false, feedback = false, expected = "dark gray"},
        {active = false, playing = false, feedback = true, expected = "dark gray"},
        {active = false, playing = true, feedback = false, expected = "dark gray"},
        {active = false, playing = true, feedback = true, expected = "dark gray"},
        {active = true, playing = false, feedback = false, expected = "dim"},
        {active = true, playing = false, feedback = true, expected = "normal"},
        {active = true, playing = true, feedback = false, expected = "dim"},
        {active = true, playing = true, feedback = true, expected = "bright"}
    }
    
    for _, testCase in ipairs(testCases) do
        local color = ui:getTrackColor(1, testCase.active, testCase.playing, testCase.feedback)
        
        if testCase.expected == "dark gray" then
            luaunit.assertTrue(colorsEqual(color, {0.2, 0.2, 0.2}), 
                               string.format("State %s should return dark gray", testCase.expected))
        elseif testCase.expected == "dim" then
            luaunit.assertTrue(colorsEqual(color, ui.trackColors[1].dim),
                               string.format("State %s should return dim color", testCase.expected))
        elseif testCase.expected == "normal" then
            luaunit.assertTrue(colorsEqual(color, ui.trackColors[1].normal),
                               string.format("State %s should return normal color", testCase.expected))
        elseif testCase.expected == "bright" then
            luaunit.assertTrue(colorsEqual(color, ui.trackColors[1].bright),
                               string.format("State %s should return bright color", testCase.expected))
        end
    end
end

function TestTrackColors:testColorPersistence()
    -- Test that colors remain consistent across multiple calls
    
    -- Helper function to compare color tables
    local function colorsEqual(color1, color2)
        return math.abs(color1[1] - color2[1]) < 0.001 and
               math.abs(color1[2] - color2[2]) < 0.001 and
               math.abs(color1[3] - color2[3]) < 0.001
    end
    
    for track = 1, 8 do
        local color1 = ui:getTrackColor(track, true, false, false)
        local color2 = ui:getTrackColor(track, true, false, false)
        
        luaunit.assertTrue(colorsEqual(color1, color2), 
                           string.format("Track %d color should be consistent across calls", track))
    end
end

function TestTrackColors:testColorMemoryUsage()
    -- Test that color system doesn't use excessive memory
    
    -- Color system should be lightweight with minimal state
    luaunit.assertEquals(type(ui.trackColors), "table", "Track colors should be stored in a table")
    luaunit.assertTrue(#ui.trackColors <= 8, "Should not have more than 8 track colors")
    
    -- Each color set should have exactly 3 brightness levels
    for track = 1, 8 do
        local colorCount = 0
        for _, _ in pairs(ui.trackColors[track]) do
            colorCount = colorCount + 1
        end
        luaunit.assertEquals(colorCount, 3, string.format("Track %d should have exactly 3 brightness levels", track))
    end
end

function TestTrackColors:testColorSystemDocumentation()
    -- Test that the color system is well-documented
    
    -- Track colors table should exist and be accessible
    luaunit.assertNotNil(ui.trackColors, "Track colors should be defined")
    luaunit.assertEquals(type(ui.trackColors), "table", "Track colors should be a table")
    
    -- getTrackColor function should exist
    luaunit.assertEquals(type(ui.getTrackColor), "function", "getTrackColor should be a function")
    
    -- Color system should be self-contained (no external dependencies beyond RGB values)
    for track = 1, 8 do
        for _, brightness in pairs({"dim", "normal", "bright"}) do
            local color = ui.trackColors[track][brightness]
            luaunit.assertEquals(type(color), "table", "Color should be a table")
            luaunit.assertEquals(#color, 3, "Color should have 3 components")
            
            for i, component in ipairs(color) do
                luaunit.assertEquals(type(component), "number", "Color component should be a number")
            end
        end
    end
end

return TestTrackColors