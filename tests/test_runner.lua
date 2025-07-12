--[[
    MIDI Drum Sequencer - test_runner.lua
    
    Test runner for the MIDI Drum Sequencer project.
    Runs all test suites and reports results.
    
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

-- Add project paths to Lua's module search path
package.path = package.path .. ";./?.lua;./lib/?.lua;./src/?.lua;./tests/?.lua"

local luaunit = require("luaunit")

-- Import test modules
local test_sequencer = require("test_sequencer")
local test_utils = require("test_utils")
local test_sequencer_phase2 = require("test_sequencer_phase2")
local test_ui_phase2 = require("test_ui_phase2")
local test_audio_phase3 = require("test_audio_phase3")
local test_ui_phase3 = require("test_ui_phase3")
local test_midi_phase4 = require("test_midi_phase4")
local test_ui_phase4 = require("test_ui_phase4")
local test_sequencer_bugfix = require("test_sequencer_bugfix")
local test_timing_fixes = require("test_timing_fixes")
local test_clock_timing = require("test_clock_timing")
local test_audio_timing_fixes = require("test_audio_timing_fixes")
local test_sequencer_audio_readiness = require("test_sequencer_audio_readiness")
local test_bpm_text_input = require("test_bpm_text_input")
local test_bpm_slider_sync = require("test_bpm_slider_sync")
local test_real_application_flow = require("test_real_application_flow")
local test_clear_pattern = require("test_clear_pattern")
local test_reset_volumes = require("test_reset_volumes")
local test_ui_reorganization = require("test_ui_reorganization")
local test_track_colors = require("test_track_colors")
local test_subtle_ui_colors = require("test_subtle_ui_colors")
local test_metronome = require("test_metronome")
local test_improved_metronome = require("test_improved_metronome")
local test_sequence_grouping = require("test_sequence_grouping")
local test_ui_border_enhancements = require("test_ui_border_enhancements")
local test_pattern_save_load = require("test_pattern_save_load")
local test_pattern_manager_bugfix = require("test_pattern_manager_bugfix")
local test_pattern_ui_bugfixes = require("test_pattern_ui_bugfixes")
local test_pattern_dialog_z_order = require("test_pattern_dialog_z_order")

-- Run all tests
print("=== MIDI Drum Sequencer Test Suite ===")
print("")

local allPassed = true

print("Running Sequencer Tests...")
allPassed = luaunit.run(test_sequencer) and allPassed

print("\nRunning Utils Tests...")
allPassed = luaunit.run(test_utils) and allPassed

print("\nRunning Phase 2 Sequencer Tests...")
allPassed = luaunit.run(test_sequencer_phase2) and allPassed

print("\nRunning Phase 2 UI Tests...")
allPassed = luaunit.run(test_ui_phase2) and allPassed

print("\nRunning Phase 3 Audio Tests...")
allPassed = luaunit.run(test_audio_phase3) and allPassed

print("\nRunning Phase 3 UI Tests...")
allPassed = luaunit.run(test_ui_phase3) and allPassed

print("\nRunning Phase 4 MIDI Tests...")
allPassed = luaunit.run(test_midi_phase4) and allPassed

print("\nRunning Phase 4 UI Tests...")
allPassed = luaunit.run(test_ui_phase4) and allPassed

print("\nRunning Bug Fix Tests...")
allPassed = luaunit.run(test_sequencer_bugfix) and allPassed

print("\nRunning Timing Fix Tests...")
allPassed = luaunit.run(test_timing_fixes) and allPassed

print("\nRunning Clock-Based Timing Tests...")
allPassed = luaunit.run(test_clock_timing) and allPassed

print("\nRunning Audio Timing Fix Tests...")
allPassed = luaunit.run(test_audio_timing_fixes) and allPassed

print("\nRunning Sequencer Audio Readiness Tests...")
allPassed = luaunit.run(test_sequencer_audio_readiness) and allPassed

print("\nRunning BPM Text Input Tests...")
allPassed = luaunit.run(test_bpm_text_input) and allPassed

print("\nRunning BPM Slider Sync Tests...")
allPassed = luaunit.run(test_bpm_slider_sync) and allPassed

print("\nRunning Real Application Flow Tests...")
allPassed = luaunit.run(test_real_application_flow) and allPassed

print("\nRunning Clear Pattern Tests...")
allPassed = luaunit.run(test_clear_pattern) and allPassed

print("\nRunning Reset Volumes Tests...")
allPassed = luaunit.run(test_reset_volumes) and allPassed

print("\nRunning UI Reorganization Tests...")
allPassed = luaunit.run(test_ui_reorganization) and allPassed

print("\nRunning Track Colors Tests...")
allPassed = luaunit.run(test_track_colors) and allPassed

print("\nRunning Subtle UI Colors Tests...")
allPassed = luaunit.run(test_subtle_ui_colors) and allPassed

print("\nRunning Metronome Tests...")
allPassed = luaunit.run(test_metronome) and allPassed

print("\nRunning Improved Metronome Tests...")
allPassed = luaunit.run(test_improved_metronome) and allPassed

print("\nRunning Sequence Grouping Tests...")
allPassed = luaunit.run(test_sequence_grouping) and allPassed

print("\nRunning UI Border Enhancement Tests...")
allPassed = luaunit.run(test_ui_border_enhancements) and allPassed

print("\nRunning Pattern Save/Load Tests...")
allPassed = luaunit.run(test_pattern_save_load) and allPassed

print("\nRunning Pattern Manager Bugfix Tests...")
allPassed = luaunit.run(test_pattern_manager_bugfix) and allPassed

print("\nRunning Pattern UI Bugfix Tests...")
allPassed = luaunit.run(test_pattern_ui_bugfixes) and allPassed

print("\nRunning Pattern Dialog Z-Order Tests...")
allPassed = luaunit.run(test_pattern_dialog_z_order) and allPassed

print("\n=== Test Summary ===")
if allPassed then
    print("All tests passed!")
    os.exit(0)
else
    print("Some tests failed!")
    os.exit(1)
end