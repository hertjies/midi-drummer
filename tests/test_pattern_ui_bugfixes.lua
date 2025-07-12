--[[
    MIDI Drum Sequencer - test_pattern_ui_bugfixes.lua
    
    Unit tests for pattern manager UI bug fixes including:
    - Pattern save validation and error handling
    - Pattern load validation and error handling  
    - Pattern name input cursor flashing fix
    - Dialog display logic for empty pattern lists
    
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

-- Mock Love2D modules for testing
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
        getTime = function() return os.clock() end,
        getDelta = function() return 0.016 end  -- 60 FPS
    },
    audio = {
        newSource = function(data) 
            local source = {
                setVolume = function() end,
                isPlaying = function() return false end,
                play = function() end,
                stop = function() end
            }
            source.clone = function() 
                return {
                    setVolume = function() end,
                    isPlaying = function() return false end,
                    play = function() end,
                    stop = function() end,
                    clone = function() return source.clone() end
                }
            end
            return source
        end,
        play = function(source) end
    },
    sound = {
        newSoundData = function(samples, sampleRate, bitDepth, channels)
            return {
                setSample = function() end
            }
        end
    },
    filesystem = {
        getInfo = function(path) return nil end,
        createDirectory = function(path) return true end,
        write = function(filename, data) 
            _G.mockFileSystem = _G.mockFileSystem or {}
            _G.mockFileSystem[filename] = data
            return true 
        end,
        read = function(filename)
            _G.mockFileSystem = _G.mockFileSystem or {}
            return _G.mockFileSystem[filename]
        end,
        getDirectoryItems = function(dir)
            _G.mockFileSystem = _G.mockFileSystem or {}
            local files = {}
            for filename, _ in pairs(_G.mockFileSystem) do
                if filename:match("^" .. dir .. "/.*%.json$") then
                    local basename = filename:gsub("^" .. dir .. "/", "")
                    table.insert(files, basename)
                end
            end
            return files
        end,
        remove = function(filename)
            _G.mockFileSystem = _G.mockFileSystem or {}
            if _G.mockFileSystem[filename] then
                _G.mockFileSystem[filename] = nil
                return true
            end
            return false
        end
    }
}

-- Replace love global with our mock
_G.love = mockLove

-- Capture print outputs for testing
local printOutput = {}
local originalPrint = print
local function mockPrint(...)
    local args = {...}
    local str = ""
    for i, arg in ipairs(args) do
        if i > 1 then str = str .. "\t" end
        str = str .. tostring(arg)
    end
    table.insert(printOutput, str)
    -- Also call original print for debugging
    originalPrint(...)
end

-- Load required modules
local ui = require("src.ui")
local sequencer = require("src.sequencer")
local audio = require("src.audio")
local utils = require("src.utils")
local pattern_manager = require("src.pattern_manager")

local TestPatternUIBugfixes = {}

function TestPatternUIBugfixes:setUp()
    -- Clear mock file system and print output
    _G.mockFileSystem = {}
    printOutput = {}
    
    -- Override print function to capture output
    _G.print = mockPrint
    
    -- Initialize modules
    audio:init()
    sequencer:init()
    
    -- Connect modules
    sequencer.audio = audio
    ui.sequencer = sequencer
    ui.audio = audio
    ui.utils = utils
    
    -- Reset UI state
    ui.patternNameInput = ""
    ui.patternNameInputActive = false
    ui.patternNameInputCursorTimer = 0
    ui.patternList = {}
    ui.patternListVisible = false
    ui.selectedPatternIndex = 1
    ui.patternDialogMode = "none"
end

function TestPatternUIBugfixes:tearDown()
    -- Restore original print function
    _G.print = originalPrint
    
    -- Clean up modules
    sequencer.audio = nil
    ui.sequencer = nil
    ui.audio = nil
    ui.utils = nil
    
    -- Clear mock file system
    _G.mockFileSystem = {}
    printOutput = {}
end

function TestPatternUIBugfixes:testSavePatternWithEmptyName()
    -- Test saving with empty pattern name and no existing patterns
    ui.patternNameInput = ""
    ui.patternList = {}
    ui.selectedPatternIndex = 1
    
    ui:executeSavePattern()
    
    -- Should get error message about empty pattern name
    luaunit.assertTrue(#printOutput > 0, "Should have error message")
    luaunit.assertTrue(printOutput[1]:find("Please enter a pattern name") ~= nil, "Should ask for pattern name")
end

function TestPatternUIBugfixes:testSavePatternWithInvalidName()
    -- Test saving with invalid pattern name
    ui.patternNameInput = "invalid pattern name"  -- Contains spaces
    
    ui:executeSavePattern()
    
    -- Should get validation error
    luaunit.assertTrue(#printOutput > 0, "Should have error message")
    luaunit.assertTrue(printOutput[1]:find("Invalid pattern name") ~= nil, "Should show validation error")
end

function TestPatternUIBugfixes:testSavePatternWithValidName()
    -- Test saving with valid pattern name
    ui.patternNameInput = "test_pattern"
    
    ui:executeSavePattern()
    
    -- Should succeed
    luaunit.assertTrue(#printOutput > 0, "Should have success message")
    luaunit.assertTrue(printOutput[1]:find("Pattern saved") ~= nil, "Should show success message")
    luaunit.assertEquals(ui.patternNameInput, "", "Should clear pattern name input")
    luaunit.assertFalse(ui.patternNameInputActive, "Should deactivate input")
end

function TestPatternUIBugfixes:testSavePatternUsingSelectedPattern()
    -- Test saving by selecting existing pattern (overwrite)
    ui.patternNameInput = ""
    ui.patternList = {"existing_pattern"}
    ui.selectedPatternIndex = 1
    
    ui:executeSavePattern()
    
    -- Should succeed using selected pattern name
    luaunit.assertTrue(#printOutput > 0, "Should have message")
    luaunit.assertTrue(printOutput[1]:find("Pattern saved") ~= nil, "Should save using selected name")
end

function TestPatternUIBugfixes:testLoadPatternWithNoPatterns()
    -- Test loading when no patterns exist
    ui.patternList = {}
    
    ui:executeLoadPattern()
    
    -- Should get error about no patterns
    luaunit.assertTrue(#printOutput > 0, "Should have error message")
    luaunit.assertTrue(printOutput[1]:find("No saved patterns found") ~= nil, "Should show no patterns error")
end

function TestPatternUIBugfixes:testLoadPatternWithInvalidSelection()
    -- Test loading with invalid selection index
    ui.patternList = {"test_pattern"}
    ui.selectedPatternIndex = 5  -- Invalid index
    
    ui:executeLoadPattern()
    
    -- Should get error about invalid selection
    luaunit.assertTrue(#printOutput > 0, "Should have error message")
    luaunit.assertTrue(printOutput[1]:find("Invalid pattern selection") ~= nil, "Should show invalid selection error")
end

function TestPatternUIBugfixes:testLoadPatternWithValidSelection()
    -- First save a pattern to load
    ui.patternNameInput = "test_load"
    ui:executeSavePattern()
    printOutput = {}  -- Clear previous output
    
    -- Set up for loading
    ui.patternList = sequencer:getPatternList()
    ui.selectedPatternIndex = 1
    
    ui:executeLoadPattern()
    
    -- Should succeed
    luaunit.assertTrue(#printOutput > 0, "Should have success message")
    luaunit.assertTrue(printOutput[1]:find("Pattern loaded") ~= nil, "Should show success message")
end

function TestPatternUIBugfixes:testOpenLoadDialogWithNoPatterns()
    -- Test opening load dialog when no patterns exist
    ui:openLoadPatternDialog()
    
    -- Should not show dialog and print error
    luaunit.assertFalse(ui.patternListVisible, "Dialog should not be visible")
    luaunit.assertTrue(#printOutput > 0, "Should have error message")
    luaunit.assertTrue(printOutput[1]:find("No saved patterns found") ~= nil, "Should show no patterns message")
end

function TestPatternUIBugfixes:testOpenLoadDialogWithPatterns()
    -- First save a pattern
    ui.patternNameInput = "test_pattern"
    ui:executeSavePattern()
    
    -- Open load dialog
    ui:openLoadPatternDialog()
    
    -- Should show dialog
    luaunit.assertTrue(ui.patternListVisible, "Dialog should be visible")
    luaunit.assertEquals(ui.patternDialogMode, "load", "Should be in load mode")
    luaunit.assertEquals(ui.selectedPatternIndex, 1, "Should select first pattern")
end

function TestPatternUIBugfixes:testOpenSaveDialogAlwaysWorks()
    -- Test opening save dialog when no patterns exist
    ui:openSavePatternDialog()
    
    -- Should always show dialog for save mode
    luaunit.assertTrue(ui.patternListVisible, "Dialog should be visible for save")
    luaunit.assertEquals(ui.patternDialogMode, "save", "Should be in save mode")
end

function TestPatternUIBugfixes:testPatternNameInputCursorFlashing()
    -- Test cursor flashing behavior
    
    -- When input is not active, cursor timer should be reset
    ui.patternNameInputActive = false
    ui.patternNameInputCursorTimer = 5.0  -- Set to some value
    
    ui:drawPatternNameInput(100, 100, 150, 25)
    
    -- Cursor timer should be reset when not active
    luaunit.assertEquals(ui.patternNameInputCursorTimer, 0, "Cursor timer should be reset when not active")
end

function TestPatternUIBugfixes:testPatternNameInputActiveCursor()
    -- Test cursor when input is active
    ui.patternNameInputActive = true
    ui.patternNameInput = "test"
    ui.patternNameInputCursorTimer = 0
    
    -- Mock timer delta
    local originalGetDelta = love.timer.getDelta
    love.timer.getDelta = function() return 0.5 end  -- Half second
    
    ui:drawPatternNameInput(100, 100, 150, 25)
    
    -- Cursor timer should have been updated
    luaunit.assertTrue(ui.patternNameInputCursorTimer > 0, "Cursor timer should be updated when active")
    
    -- Restore original function
    love.timer.getDelta = originalGetDelta
end

function TestPatternUIBugfixes:testPatternNameInputPlaceholderText()
    -- Test placeholder text display
    ui.patternNameInput = ""
    ui.patternNameInputActive = false
    
    -- This should not crash and should display placeholder
    ui:drawPatternNameInput(100, 100, 150, 25)
    
    luaunit.assertTrue(true, "Drawing placeholder text should not crash")
end

function TestPatternUIBugfixes:testPatternDialogDisplayLogic()
    -- Test dialog display logic for different scenarios
    
    -- Test save mode with no patterns
    ui.patternDialogMode = "save"
    ui.patternList = {}
    ui.patternListVisible = true
    
    -- Should draw dialog for save mode even with empty list
    ui:drawPatternSelectionDialog()
    luaunit.assertTrue(true, "Save dialog should draw with empty pattern list")
    
    -- Test load mode with no patterns
    ui.patternDialogMode = "load"
    ui.patternList = {}
    
    -- Should not draw dialog for load mode with empty list
    ui:drawPatternSelectionDialog()
    luaunit.assertTrue(true, "Load dialog should handle empty pattern list gracefully")
end

function TestPatternUIBugfixes:testPatternValidationErrorMessages()
    -- Test various validation scenarios
    
    -- Empty filename
    ui.patternNameInput = ""
    ui.patternList = {}
    ui:executeSavePattern()
    luaunit.assertTrue(printOutput[#printOutput]:find("enter a pattern name") ~= nil, "Should show empty name error")
    
    -- Reset output
    printOutput = {}
    
    -- Invalid characters
    ui.patternNameInput = "test/pattern"
    ui:executeSavePattern()
    luaunit.assertTrue(printOutput[#printOutput]:find("Invalid pattern name") ~= nil, "Should show invalid characters error")
    
    -- Reset output
    printOutput = {}
    
    -- Valid name should work
    ui.patternNameInput = "valid_pattern"
    ui:executeSavePattern()
    luaunit.assertTrue(printOutput[#printOutput]:find("Pattern saved") ~= nil, "Valid name should save successfully")
end

function TestPatternUIBugfixes:testDialogStateManagement()
    -- Test that dialog state is properly managed
    
    -- Open save dialog
    ui:openSavePatternDialog()
    luaunit.assertTrue(ui.patternListVisible, "Dialog should be visible")
    luaunit.assertEquals(ui.patternDialogMode, "save", "Should be in save mode")
    
    -- Close dialog
    ui:closePatternDialog()
    luaunit.assertFalse(ui.patternListVisible, "Dialog should be hidden")
    luaunit.assertEquals(ui.patternDialogMode, "none", "Should reset mode")
    luaunit.assertEquals(ui.selectedPatternIndex, 1, "Should reset selection")
end

function TestPatternUIBugfixes:testPatternNameInputStateManagement()
    -- Test pattern name input state management
    
    -- Activate input
    ui.patternNameInput = ""
    ui.patternNameInputActive = true
    ui.patternNameInputCursorTimer = 0
    
    -- Successful save should clear input state
    ui.patternNameInput = "test_pattern"
    ui:executeSavePattern()
    
    luaunit.assertEquals(ui.patternNameInput, "", "Should clear pattern name input")
    luaunit.assertFalse(ui.patternNameInputActive, "Should deactivate input")
end

return TestPatternUIBugfixes