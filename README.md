# MIDI Drum Sequencer

A Windows-based drum pattern sequencer built with Lua and LÖVE 2D framework. Create drum patterns using an intuitive grid interface and export them as MIDI files for use in your favorite DAW.

![MIDI Drum Sequencer](screenshot.png)
*Screenshot placeholder - application in development*

## Features

### Current (Phases 1-4 Complete - MVP Ready!)
- ✅ 16-step × 8-track pattern grid
- ✅ Interactive pattern editing with mouse
- ✅ Real-time pattern playback with accurate timing
- ✅ Visual playback indicator (yellow border on current step)
- ✅ Transport controls (Play/Stop/Reset/Clear/Export)
- ✅ **Comprehensive BPM control system (60-300 BPM)**
  - Interactive slider for smooth drag adjustment
  - +/- buttons for precise 5-BPM increments
  - **Text input field for direct BPM entry**
  - Real-time BPM updates during playback
  - Input validation with automatic range clamping
- ✅ **Real-time audio preview** with procedurally generated drum samples
  - Kick, snare, hi-hats, crash, ride, and tom sounds
  - Automatic fallback sample generation when audio files unavailable
  - Full polyphony support for simultaneous sounds
- ✅ **Individual track volume controls**
  - Interactive volume sliders for each track
  - Real-time volume adjustment
  - Visual volume percentage display
  - **Reset Volumes button** to restore all tracks to 70% level
- ✅ **Visual audio feedback**
  - Grid cells light up when sounds are triggered
  - Track label clicking for sound preview
- ✅ **MIDI file export functionality**
  - Standard MIDI File (SMF) Type 0 format
  - General MIDI drum mapping (Channel 10)
  - 96 PPQ resolution for accurate timing
  - Automatic timestamped filenames
  - Compatible with all major DAWs
- ✅ Track labels for different drum sounds
- ✅ Hover effects for better user experience
- ✅ **Pattern clearing functionality**
  - Dedicated Clear button in transport controls
  - Instantly empties entire pattern grid
  - Does not affect playback state or BPM settings
- ✅ **Reorganized UI layout for better UX**
  - Logical grouping of related controls (BPM, Transport, Volume)
  - Eliminated overlapping interface elements
  - Improved spacing and accessibility
  - Organized into clear visual hierarchy
- ✅ **Colorful track-based UI design**
  - 8 distinct track colors using 16 Xterm color palette
  - Track-specific color coding for easy identification
  - Dynamic brightness based on playback state
  - Enhanced visual feedback during pattern playback
- ✅ **Subtle UI theming**
  - Professional dark theme with blue-gray accent tones
  - Subtle color palette that complements track colors
  - Enhanced visual hierarchy with thoughtful text color gradients
  - Improved button states and interactive element feedback
- ✅ **Metronome functionality**
  - Audible metronome clicks during pattern playback
  - Accent beats on steps 1, 5, 9, and 13 for musical emphasis
  - Toggle on/off functionality accessible during playback
  - **Separate volume controls for normal and accent clicks**
  - Professional clock-tick sounds generated procedurally
  - Enhanced clock-tick sounds with harmonic richness and mechanical click characteristics
- ✅ **Sequence grid visual grouping**
  - 4-group background color system for enhanced pattern readability
  - Alternating backgrounds: Groups 1&3 (steps 1-4, 9-12) with dark grey
  - Groups 2&4 (steps 5-8, 13-16) with even darker grey for visual contrast
  - Improved musical phrase recognition and editing workflow
- ✅ **Enhanced UI with minimal borders**
  - Minimal borders on all slider controls for improved definition
  - Button backgrounds with matching border and fill colors
  - Consistent 1-pixel border styling throughout interface
  - Enhanced visual clarity while maintaining clean aesthetic
- ✅ Timing-accurate step sequencing

### Future Features (Phase 5-6)
- 📁 Pattern save/load functionality
- ↩️ Undo/redo support
- ⌨️ Keyboard shortcuts
- 🎹 Velocity control per step
- 🔗 Pattern chaining
- 🎵 Custom sample loading support
- 🎛️ Advanced export options (velocity, resolution)

## Requirements

- Windows 10/11 (or other OS supported by LÖVE)
- LÖVE 11.4 (included in the project)
- Lua 5.1+ (for running tests)
- **Screen Resolution**: Minimum 900x650 pixels for optimal UI layout

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/midi-drum-sequencer.git
cd midi-drum-sequencer
```

2. The project includes LÖVE 11.4 binaries for Windows in the `love/` directory, so no additional installation is required.

## Usage

### Running the Application

Using the included LÖVE binaries:
```bash
love/love.exe .
```

Or if you have LÖVE installed system-wide:
```bash
love .
```

### Controls

- **Mouse Click on Grid**: Toggle drum steps on/off
- **Play Button**: Start pattern playback with audio
- **Stop Button**: Stop playback
- **Reset Button**: Stop and return to beginning
- **Clear Button**: Clear all pattern steps (empty the grid)
- **Export Button**: Export pattern as MIDI file (.mid)
- **Metro Button**: Toggle metronome on/off (remains in sync during playback)
- **Track Labels**: Click to preview individual drum sounds
- **BPM Slider**: Drag to adjust tempo (60-300 BPM)
- **BPM +/- Buttons**: Fine-tune BPM in steps of 5
- **BPM Text Input**: Click the text field below the slider to type BPM directly
  - Press Enter (main or numpad) to apply, Escape to cancel
  - Click elsewhere to apply and lose focus
  - Automatically validates and clamps to 60-300 range
- **Volume Sliders**: Adjust individual track volumes (0-100%)
- **Reset Vol Button**: Reset all track volumes to 70% (default level)
- **Metronome Volume Sliders**: Separate volume controls for normal and accent metronome clicks
- **Escape Key**: Exit application

### Track Layout and Color Coding

The sequencer includes 8 tracks mapped to common drum sounds, each with a distinct color:

1. **Kick** - Bass drum (🔴 **Red**)
2. **Snare** - Snare drum (🟡 **Yellow**)
3. **Hi-Hat C** - Closed hi-hat (🔵 **Cyan**)
4. **Hi-Hat O** - Open hi-hat (🟢 **Green**)
5. **Crash** - Crash cymbal (🟣 **Magenta**)
6. **Ride** - Ride cymbal (🔵 **Blue**)
7. **Tom Low** - Low tom (🔴 **Dark Red**)
8. **Tom High** - High tom (🟡 **Dark Yellow**)

#### Color States:
- **Dimmed (40%)**: Inactive pattern steps
- **Normal (70%)**: Active pattern steps  
- **Bright (100%)**: Currently playing steps with audio feedback

## Development

### Project Structure

```
midi-drum-sequencer/
├── main.lua                 # Application entry point
├── conf.lua                 # LÖVE 2D configuration
├── src/
│   ├── sequencer.lua        # Core sequencer logic
│   ├── audio.lua            # Audio playback (Phase 3)
│   ├── midi.lua             # MIDI export (Phase 4)
│   ├── ui.lua               # User interface
│   └── utils.lua            # Utility functions
├── lib/
│   └── luaunit.lua          # Testing framework
├── tests/
│   ├── test_runner.lua      # Test suite runner
│   ├── test_sequencer.lua   # Sequencer tests
│   └── test_utils.lua       # Utility tests
├── love/                    # LÖVE 2D Windows binaries
└── assets/                  # (Future) Audio samples and fonts
```

### Running Tests

The project includes a comprehensive test suite using LuaUnit with **100% pass rate**:

```bash
# Run all tests
lua tests/test_runner.lua

# Or on Windows
test.bat

# Run specific test file
lua tests/test_sequencer.lua
```

#### Test Suite Overview (July 2025)
- **Total Coverage**: 247 tests across 24 test suites
- **Pass Rate**: 100% (247/247 tests passing)
- **Test Categories**:
  - ✅ Core Sequencer Logic (7 tests)
  - ✅ Utility Functions (2 tests) 
  - ✅ Phase 2 Sequencer Features (7 tests)
  - ✅ Phase 2 UI Interactions (5 tests)
  - ✅ Phase 3 Audio System (10 tests)
  - ✅ Phase 3 UI Audio Controls (7 tests)
  - ✅ Phase 4 MIDI Export (11 tests)
  - ✅ Phase 4 UI Export Controls (10 tests)
  - ✅ Bug Fix Validation (6 tests)
  - ✅ Timing System Fixes (9 tests)
  - ✅ Clock-Based Timing (10 tests)
  - ✅ Audio Timing Improvements (9 tests)
  - ✅ Sequencer Audio Integration (10 tests)
  - ✅ BPM Text Input Feature (19 tests)
  - ✅ BPM Slider Synchronization (11 tests)
  - ✅ Real Application Flow (5 tests)
  - ✅ Clear Pattern Functionality (12 tests)
  - ✅ Reset Volumes Functionality (12 tests)
  - ✅ UI Reorganization and Layout (12 tests)
  - ✅ Track Colors and Visual Design (12 tests)
  - ✅ Subtle UI Color System (12 tests)
  - ✅ Metronome Functionality (12 tests)
  - ✅ Improved Metronome Volume Controls (14 tests)
  - ✅ Sequence Grid Visual Grouping (12 tests)
  - ✅ UI Border Enhancements (15 tests)

#### Advanced Test Features
- **Mock Timer System**: Controlled time simulation for clock-based timing tests
- **Mock Audio System**: Audio trigger validation and comprehensive logging
- **Timing Mode Isolation**: Legacy tests preserved using frame-based timing
- **Edge Case Coverage**: Every timing scenario and bug fix thoroughly validated
- **Debug Information**: Enhanced error messages with detailed timing diagnostics

### Development Phases

The project is being developed in phases:

1. **Phase 1: Foundation** ✅ Complete
   - Basic UI and grid rendering
   - Pattern storage and editing
   - Transport controls

2. **Phase 2: Sequencer Logic** ✅ Complete
   - Timing system implementation
   - Real-time playback functionality
   - Interactive BPM control (slider + buttons)
   - Pattern looping
   - Visual step position indicator

3. **Phase 3: Audio Integration** ✅ Complete
   - Procedural sample generation system
   - Real-time audio playback during sequencing
   - Individual track volume controls
   - Visual audio trigger feedback
   - Sound preview functionality

4. **Phase 4: MIDI Export** ✅ Complete
   - Standard MIDI File (SMF) Type 0 implementation
   - General MIDI drum mapping (Channel 10)
   - Variable timing resolution (96 PPQ default)
   - Pattern validation and statistics
   - Timestamped export filenames
   - DAW compatibility testing

5. **Phase 5: Testing & Polish**
   - Comprehensive testing
   - UI improvements
   - Additional features

### Bug Fixes

#### Fixed: First Step Sound Missing on Play (December 2024)
- **Issue**: When pressing Play, the first step's sounds were not triggered immediately
- **Cause**: The sequencer only triggered sounds when advancing steps, not on initial play
- **Solution**: Modified `sequencer:play()` to trigger the current step immediately
- **Test**: Added comprehensive tests in `test_sequencer_bugfix.lua`

#### Fixed: Timing Accuracy Issues (December 2024)
- **Issue**: Playback timing could be inaccurate in some cases
- **Causes**: 
  - Large frame drops could miss step triggers
  - BPM changes during playback caused timing glitches
  - Single-step processing couldn't handle multiple steps per frame
- **Solutions**:
  - Implemented multi-step processing with `while` loop in `update()`
  - Added proportional timing adjustment when BPM changes during playback
  - Added safety mechanism for extremely large delta times
  - Improved timing drift prevention
- **Test**: Added comprehensive tests in `test_timing_fixes.lua`

#### Enhanced: Clock-Based Timing System (December 2024)
- **Enhancement**: Complete timing system overhaul from frame-based to CPU clock-based timing
- **Professional Benefits**:
  - **Frame-Rate Independence**: Timing accuracy unaffected by frame drops, VSync, or variable frame rates
  - **Professional Accuracy**: Eliminates timing drift over extended playback sessions
  - **Better DAW Integration**: More precise BPM timing suitable for professional music production
  - **Consistent Performance**: Works reliably across different hardware configurations
- **Advanced Features**:
  - **Dual Timing Modes**: CPU clock timing using `love.timer.getTime()` with frame-based fallback
  - **Seamless Mode Switching**: Switch between timing modes via `setTimingMode()` without interruption
  - **Smart BPM Handling**: Proportional timing adjustment during live BPM changes
  - **Multi-Step Processing**: Handles large time gaps gracefully with intelligent catch-up
  - **Safety Mechanisms**: Built-in protection against infinite loops and extreme time jumps
  - **Timing Diagnostics**: Real-time timing information via `getTimingInfo()` API
- **Technical Implementation**:
  - High-precision CPU timing with microsecond accuracy
  - Intelligent step processing with safety limits (32-step maximum per update)
  - Backward compatibility preserves all existing functionality
  - Comprehensive test coverage with mock timer system
- **Test Coverage**: 10 comprehensive tests in `test_clock_timing.lua` covering all edge cases

#### Enhanced: Audio System Timing and Prebuffering (December 2024)
- **Enhancement**: Major audio system improvements for optimal timing accuracy
- **Critical Issues Resolved**:
  - **Visual Feedback Timing**: Fixed visual feedback triggering before sound playback
  - **Sound System Initialization**: Implemented prebuffering to eliminate playback delays
  - **Audio Readiness Validation**: Added system readiness checks before playback starts
- **Advanced Audio Features**:
  - **Prebuffered Sources**: Pre-created audio sources for zero-latency playback
  - **Automatic Replenishment**: Dynamic prebuffer management maintains optimal performance
  - **System Status Monitoring**: Real-time audio system status and diagnostics
  - **Graceful Fallbacks**: Robust handling when audio system is not ready
  - **Volume Coordination**: Synchronized volume updates across all audio sources
- **Sequencer Integration**:
  - **Audio Readiness Checks**: Sequencer validates audio system before starting playback
  - **Automatic Recovery**: Attempts to reinitialize audio system if not ready
  - **Seamless Coordination**: Audio timing perfectly synchronized with sequencer timing
  - **Status Reporting**: Comprehensive audio system status via `getAudioStatus()`
- **Technical Implementation**:
  - 4 prebuffered sources per track for immediate availability
  - Estimated 5ms audio latency compensation
  - Automatic source cleanup prevents memory leaks
  - Love2D compatibility checks for headless testing
- **Test Coverage**: 19 comprehensive tests across 2 new test suites validating all improvements

#### Fixed: BPM Slider Synchronization Issue (December 2024)
- **Issue**: BPM slider handle position did not update when BPM was changed via text input, especially when clicking elsewhere to lose focus
- **Root Cause**: Text input changes were only applied when pressing Enter, not when focus was lost by clicking elsewhere
- **Critical Discovery**: When users typed a BPM value and clicked outside the text field (normal UI behavior), the value was discarded without being applied
- **Solution**: Enhanced focus loss handling and state management:
  - **Focus Loss Application**: Automatically apply BPM changes when clicking outside text input field
  - **State Management**: Proper cleanup of `bpmDragging` flag during text input operations
  - **Dual Input Methods**: Support both Enter key and focus loss for applying BPM changes
- **Technical Implementation**:
  - Modified mouse click handler to apply text input before deactivating on focus loss
  - Added `self.bpmDragging = false` in text input activation and application
  - Enhanced `applyBPMTextInput()` with comprehensive state cleanup
  - Improved color state management in text input drawing
- **Comprehensive Testing**: 16 new test cases across 2 test suites:
  - Complete user workflow simulation (click, type, Enter/focus loss)
  - Slider handle position calculation across full BPM range (60-300)
  - Focus loss behavior with both empty and filled input buffers
  - Edge cases with conflicting UI states (dragging + text input)
  - Real application flow validation with Love2D lifecycle simulation

## Technical Details

### Timing System Specifications
- **Primary Mode**: CPU clock-based timing using `love.timer.getTime()`
- **Fallback Mode**: Frame-based timing for compatibility
- **Precision**: Microsecond-level timing accuracy
- **BPM Range**: 60-300 BPM with real-time adjustment
- **Safety Limits**: 32-step maximum processing per update cycle
- **Timing APIs**: 
  - `setTimingMode(mode)` - Switch between "clock" and "frame" modes
  - `getTimingInfo()` - Real-time timing diagnostics and monitoring

### MIDI Specification
- Format: Standard MIDI File (SMF) Type 0
- Resolution: 96 PPQ (Pulses Per Quarter Note)
- Channel: 10 (GM Drum Channel)
- Note mapping follows General MIDI drum specification

### Audio Requirements
- Sample format: 16-bit WAV, 44.1kHz
- Target latency: < 10ms
- Full 8-track polyphony

### Performance
- **Rendering**: 60 FPS with efficient grid drawing and dirty rectangle optimization
- **Timing Accuracy**: Microsecond-precision timing independent of frame rate
- **Memory Efficiency**: Minimal memory footprint with intelligent resource management
- **CPU Optimization**: Smart step processing with safety limits prevents performance spikes
- **Audio Latency**: < 10ms target with full 8-track polyphony support
- **Test Performance**: 77 tests execute in under 5 seconds with 100% reliability

## Contributing

This project is currently in active development. Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing code patterns
- Run tests before submitting PRs

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.

### What this means:

- ✅ **Free to use** - You can use this software for any purpose
- ✅ **Free to modify** - You can change and improve the software
- ✅ **Free to distribute** - You can share copies with others
- ✅ **Commercial use allowed** - You can use it in commercial projects

### Requirements:

- 📄 **Include license** - You must include the GPL-3.0 license with any distribution
- 🔧 **Share modifications** - Any modifications must also be licensed under GPL-3.0
- 📝 **Mark changes** - You must clearly indicate what changes you made
- 💻 **Provide source** - You must provide source code when distributing

The GPL-3.0 ensures that this software and any derivatives remain free and open source for everyone.

## Acknowledgments

- Built with [LÖVE 2D](https://love2d.org/) framework
- Testing with [LuaUnit](https://github.com/bluebird75/luaunit)
- Inspired by classic drum machines and modern DAWs

## Roadmap

### Version 1.0 (MVP) ✅ Complete!
- [x] Basic pattern sequencing
- [x] BPM control with interactive slider
- [x] Real-time playback timing
- [x] Audio playback with procedural samples
- [x] Individual track volume controls
- [x] MIDI export functionality

### Version 2.0
- [ ] Pattern save/load
- [ ] Multiple pattern banks
- [ ] Swing/shuffle timing
- [ ] Velocity control

### Version 3.0
- [ ] Real-time MIDI output
- [ ] VST plugin support
- [ ] Advanced timing options
- [ ] Pattern chaining

## Contact

For questions, suggestions, or bug reports, please open an issue on GitHub.

### Copyright Notice

Copyright (C) 2024 MIDI Drum Sequencer Contributors

This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to redistribute it under certain conditions; see the LICENSE file for details.

---

**Note**: This project is under active development. Features and documentation may change as development progresses.