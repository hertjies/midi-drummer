--[[
    MIDI Drum Sequencer - test_pattern_manager_bugfix.lua
    
    Unit tests to verify that the pattern_manager module loading bug is fixed.
    Tests that the module can be properly loaded with the correct path.
    
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
        write = function(filename, data) return true end,
        read = function(filename) return nil end,
        getDirectoryItems = function(dir) return {} end,
        remove = function(filename) return false end
    }
}

-- Replace love global with our mock
_G.love = mockLove

local TestPatternManagerBugfix = {}

function TestPatternManagerBugfix:setUp()
    -- Clear any cached modules
    package.loaded["src.pattern_manager"] = nil
    package.loaded["pattern_manager"] = nil
    package.loaded["src.sequencer"] = nil
    package.loaded["src.audio"] = nil
end

function TestPatternManagerBugfix:tearDown()
    -- Clean up
    package.loaded["src.pattern_manager"] = nil
    package.loaded["pattern_manager"] = nil
    package.loaded["src.sequencer"] = nil
    package.loaded["src.audio"] = nil
end

function TestPatternManagerBugfix:testPatternManagerModuleLoading()
    -- Test that pattern_manager can be loaded with the correct path
    local success, pattern_manager = pcall(require, "src.pattern_manager")
    
    luaunit.assertTrue(success, "Pattern manager module should load successfully with 'src.pattern_manager' path")
    luaunit.assertNotNil(pattern_manager, "Pattern manager module should not be nil")
    luaunit.assertEquals(type(pattern_manager), "table", "Pattern manager should be a table")
    
    -- Verify key functions exist
    luaunit.assertEquals(type(pattern_manager.init), "function", "Pattern manager should have init function")
    luaunit.assertEquals(type(pattern_manager.savePattern), "function", "Pattern manager should have savePattern function")
    luaunit.assertEquals(type(pattern_manager.loadPattern), "function", "Pattern manager should have loadPattern function")
end

function TestPatternManagerBugfix:testSequencerInitializesPatternManager()
    -- Test that sequencer properly initializes pattern manager with correct path
    local audio = require("src.audio")
    audio:init()
    
    local sequencer = require("src.sequencer")
    
    -- Initialize should not throw an error
    local success, error_msg = pcall(function() sequencer:init() end)
    
    luaunit.assertTrue(success, "Sequencer initialization should succeed without module not found error")
    luaunit.assertNil(error_msg, "No error should occur during sequencer initialization")
    
    -- Verify pattern manager was properly initialized
    luaunit.assertNotNil(sequencer.patternManager, "Pattern manager should be initialized in sequencer")
    luaunit.assertEquals(type(sequencer.patternManager), "table", "Pattern manager should be a table")
end

function TestPatternManagerBugfix:testPatternManagerFunctionsAccessible()
    -- Test that pattern manager functions are accessible through sequencer
    local audio = require("src.audio")
    audio:init()
    
    local sequencer = require("src.sequencer")
    sequencer:init()
    sequencer.audio = audio
    
    -- Test that pattern functions are callable
    luaunit.assertEquals(type(sequencer.savePattern), "function", "savePattern should be accessible")
    luaunit.assertEquals(type(sequencer.loadPattern), "function", "loadPattern should be accessible")
    luaunit.assertEquals(type(sequencer.getPatternList), "function", "getPatternList should be accessible")
    luaunit.assertEquals(type(sequencer.deletePattern), "function", "deletePattern should be accessible")
    luaunit.assertEquals(type(sequencer.validatePatternFilename), "function", "validatePatternFilename should be accessible")
end

function TestPatternManagerBugfix:testIncorrectPathFails()
    -- Test that the old incorrect path would fail (documenting the bug)
    -- Temporarily remove src path to test the scenario
    local original_path = package.path
    package.path = package.path:gsub(";%./src/%?%.lua", "")
    
    local success, error_msg = pcall(require, "pattern_manager")
    
    -- Restore original path
    package.path = original_path
    
    luaunit.assertFalse(success, "Loading pattern_manager without src prefix should fail")
    luaunit.assertNotNil(error_msg, "Error message should be provided for incorrect path")
    luaunit.assertTrue(error_msg:find("not found") ~= nil, "Error should indicate module not found")
end

function TestPatternManagerBugfix:testPatternManagerAPIIntegrity()
    -- Test that all expected pattern manager functions exist after loading
    local pattern_manager = require("src.pattern_manager")
    
    local expectedFunctions = {
        "init",
        "encodeJSON",
        "decodeJSON",
        "createPatternData",
        "applyPatternData",
        "savePattern",
        "loadPattern",
        "getPatternList",
        "deletePattern",
        "validateFilename"
    }
    
    for _, funcName in ipairs(expectedFunctions) do
        luaunit.assertEquals(type(pattern_manager[funcName]), "function", 
            string.format("Pattern manager should have %s function", funcName))
    end
end

function TestPatternManagerBugfix:testSequencerPatternOperations()
    -- Test that pattern operations work correctly after the fix
    local audio = require("src.audio")
    audio:init()
    
    local sequencer = require("src.sequencer")
    sequencer:init()
    sequencer.audio = audio
    
    -- Test pattern validation
    local isValid = sequencer:validatePatternFilename("test_pattern")
    luaunit.assertTrue(isValid, "Valid pattern filename should be accepted")
    
    -- Test invalid pattern name
    isValid = sequencer:validatePatternFilename("test pattern")
    luaunit.assertFalse(isValid, "Invalid pattern filename with space should be rejected")
    
    -- Test pattern list (should be empty initially)
    local patternList = sequencer:getPatternList()
    luaunit.assertEquals(type(patternList), "table", "Pattern list should be a table")
    luaunit.assertEquals(#patternList, 0, "Pattern list should initially be empty")
end

function TestPatternManagerBugfix:testModulePathConsistency()
    -- Test that all modules use consistent path structure
    local modules = {
        "src.sequencer",
        "src.audio", 
        "src.ui",
        "src.midi",
        "src.utils",
        "src.pattern_manager"
    }
    
    for _, moduleName in ipairs(modules) do
        local success, module = pcall(require, moduleName)
        luaunit.assertTrue(success, string.format("Module %s should load successfully", moduleName))
        luaunit.assertNotNil(module, string.format("Module %s should not be nil", moduleName))
    end
end

return TestPatternManagerBugfix