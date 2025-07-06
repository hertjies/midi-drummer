# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MIDI drum sequencer built with Lua and LÖVE 2D (Love2D) framework. The project features a 16-step pattern sequencer with 8 drum tracks, configurable BPM, and MIDI export functionality for Windows.

**License**: GNU General Public License v3.0 (GPL-3.0) - This is free and open source software that ensures users' freedom to use, modify, and distribute the software while keeping it open source.

## Development Commands

### Running the Application
```bash
# Run using the included LÖVE binaries (Windows)
love/love.exe .

# Alternative: If LÖVE is installed system-wide
love .
```

### Testing
```bash
# Run all tests with standalone Lua
lua run_tests.lua

# Run tests on Windows
test.bat

# Run specific test file
lua tests/test_sequencer.lua
```

## Architecture Overview

The application follows a modular architecture with these core components:

- **main.lua**: Entry point and Love2D lifecycle management
- **src/sequencer.lua**: Core sequencer logic (16x8 pattern matrix, timing, BPM control)
- **src/audio.lua**: Audio sample loading and real-time playback
- **src/midi.lua**: MIDI file generation and export (SMF Type 0 format)
- **src/ui.lua**: Grid-based interface and transport controls
- **src/utils.lua**: Helper functions and utilities

## Key Technical Details

### MIDI Implementation
- Standard MIDI File (SMF) Type 0 format
- 96 PPQ (Pulses Per Quarter Note) resolution
- Drum sounds mapped to General MIDI Drum Map (Channel 10):
  - Track 1: Kick (C1 - MIDI 36)
  - Track 2: Snare (D1 - MIDI 38)
  - Track 3: Closed Hi-Hat (F#1 - MIDI 42)
  - Track 4: Open Hi-Hat (A#1 - MIDI 46)
  - Track 5: Crash (C#2 - MIDI 49)
  - Track 6: Ride (D#2 - MIDI 51)
  - Track 7: Low Tom (A0 - MIDI 45)
  - Track 8: High Tom (D2 - MIDI 50)

### Audio System
- Uses Love2D's audio system for real-time playback
- Expects 16-bit WAV files at 44.1kHz
- Target latency: < 10ms

### UI Specifications
- Grid: 16 columns (steps) × 8 rows (tracks)
- Step size: 32×32 pixels per cell
- Mouse-based interaction for pattern editing

## Known Issues and Fixes

### Fixed Issues
1. **First Step Sound Missing on Play** (Fixed December 2024)
   - **Problem**: When pressing Play, the first step's sounds were not triggered
   - **Cause**: Sequencer only triggered sounds when advancing steps
   - **Solution**: Modified `sequencer:play()` to call `triggerCurrentStep()` immediately
   - **Test**: See `test_sequencer_bugfix.lua`

2. **Timing Accuracy Issues** (Fixed December 2024)
   - **Problem**: Playback timing was inaccurate with frame drops and BPM changes
   - **Causes**: Large delta times, BPM changes during playback, single-step processing
   - **Solutions**: Multi-step processing, proportional timing adjustment, safety mechanisms
   - **Test**: See `test_timing_fixes.lua`

## Development Environment

- **Framework**: LÖVE 11.4 (included in love/ directory)
- **Language**: Lua
- **Platform**: Windows (primary), with cross-platform potential
- **Testing**: LuaUnit framework (to be added in lib/luaunit.lua)

## Project Status

**Phases 1, 2 & 3 Complete** - The project now has a fully functional drum pattern sequencer with audio:
- Real-time pattern playback with accurate timing
- Interactive BPM control (60-300 BPM) with slider and buttons
- **Real-time audio playback** with procedurally generated drum samples
- **Individual track volume controls** with interactive sliders
- **Visual audio trigger feedback** - grid cells light up when sounds play
- Visual step position indicator during playback
- Pattern editing and clearing functionality
- Sound preview by clicking track labels
- Comprehensive test suite with 37 passing tests

**Next Phase**: MIDI file export functionality

## Important Files

- **implementation_plan.md**: Comprehensive 12-day development plan with technical specifications
- **conf.lua**: LÖVE configuration file (to be created)
- **.claude/settings.local.json**: Contains permissions for bash commands (find, ls)