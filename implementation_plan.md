# MIDI Drum Sequencer - Implementation Plan

## Project Overview

A Windows-based MIDI drum sequencer built with Lua LÖVE (Love2D) featuring a 16-step pattern sequencer with 8 drum tracks, configurable BPM, and MIDI export functionality.

## Technical Architecture

### Core Components

1. **Main Application (`main.lua`)**
   - Love2D lifecycle management
   - State management and scene routing
   - Global configuration and settings

2. **Sequencer Engine (`sequencer.lua`)**
   - 16x8 pattern matrix management
   - Timing and playback logic
   - BPM control and step advancement
   - Pattern looping

3. **Audio System (`audio.lua`)**
   - Sample loading and playback
   - Real-time audio preview
   - Volume and pan controls

4. **MIDI System (`midi.lua`)**
   - MIDI file generation and export
   - MIDI note mapping for drum sounds
   - Timing conversion (steps to MIDI ticks)

5. **UI System (`ui.lua`)**
   - Grid-based step sequencer interface
   - Transport controls (play/stop/reset)
   - BPM slider and display
   - Export button

6. **Utilities (`utils.lua`)**
   - Helper functions
   - File I/O operations
   - Mathematical utilities

## Development Environment Setup

### Prerequisites
- **LÖVE 11.4** (latest stable version)
- **Windows 10/11**
- **Text Editor**: VS Code with Lua extension
- **Git** for version control

### Project Structure
```
midi-drum-sequencer/
├── main.lua                 # Entry point
├── conf.lua                 # Love2D configuration
├── src/
│   ├── sequencer.lua        # Core sequencer logic
│   ├── audio.lua            # Audio management
│   ├── midi.lua             # MIDI file handling
│   ├── ui.lua               # User interface
│   └── utils.lua            # Utility functions
├── assets/
│   ├── samples/             # Drum samples (.wav)
│   └── fonts/               # UI fonts
├── tests/
│   ├── test_sequencer.lua   # Sequencer unit tests
│   ├── test_midi.lua        # MIDI export tests
│   └── test_runner.lua      # Test framework
├── lib/                     # External dependencies
│   └── luaunit.lua          # Testing framework
└── README.md
```

## Implementation Phases

### Phase 1: Foundation & Setup (Days 1-2)

**Objectives:**
- Set up development environment
- Create basic Love2D application structure
- Implement basic UI framework

**Tasks:**
1. Initialize Love2D project with `conf.lua`
2. Create main application loop with basic state management
3. Set up modular architecture with require statements
4. Implement basic grid rendering for 16x8 matrix
5. Add mouse input handling for grid interaction
6. Create basic transport controls (play/stop buttons)

**Deliverables:**
- Working Love2D application window
- Clickable 16x8 grid interface
- Basic transport controls (non-functional)

### Phase 2: Sequencer Logic (Days 3-4)

**Objectives:**
- Implement core sequencer timing and logic
- Add pattern storage and manipulation

**Tasks:**
1. Create pattern data structure (16x8 boolean matrix)
2. Implement BPM-based timing system using Love2D timers
3. Add step advancement and looping logic
4. Implement pattern editing (toggle steps on/off)
5. Add visual feedback for current step position
6. Create BPM adjustment controls

**Deliverables:**
- Functional step sequencer with timing
- Pattern editing capability
- Visual step position indicator
- BPM control

### Phase 3: Audio Integration (Days 5-6)

**Objectives:**
- Add audio preview functionality
- Load and manage drum samples

**Tasks:**
1. Create audio system for loading .wav samples
2. Map 8 drum tracks to different samples (kick, snare, hi-hat, etc.)
3. Implement real-time audio playback during sequencer operation
4. Add volume controls for individual tracks
5. Optimize audio performance for real-time playback
6. Add visual feedback for audio triggers

**Deliverables:**
- Audio playback during sequence playback
- 8 distinct drum sounds
- Volume controls
- Audio-visual synchronization

### Phase 4: MIDI Export (Days 7-8)

**Objectives:**
- Implement MIDI file generation
- Create export functionality

**Tasks:**
1. Research and implement MIDI file format (SMF)
2. Create MIDI note mapping for drum sounds (General MIDI Drum Map)
3. Convert sequencer timing to MIDI timing (PPQ - Pulses Per Quarter)
4. Implement MIDI file writing functionality
5. Add export dialog and file saving
6. Test MIDI file compatibility with DAWs

**Deliverables:**
- MIDI file export functionality
- Compatible .mid files
- Export user interface

### Phase 5: Testing Framework (Days 9-10)

**Objectives:**
- Implement comprehensive testing
- Ensure code quality and reliability

**Tasks:**
1. Set up LuaUnit testing framework
2. Write unit tests for sequencer logic
3. Create tests for MIDI export functionality
4. Implement integration tests for audio system
5. Add UI interaction tests
6. Create automated test runner

**Deliverables:**
- Comprehensive test suite
- Automated testing capability
- Code coverage validation

### Phase 6: Polish & Features (Days 11-12)

**Objectives:**
- Enhance user experience
- Add final features and optimizations

**Tasks:**
1. Improve UI design and visual feedback
2. Add pattern save/load functionality
3. Implement undo/redo functionality
4. Add keyboard shortcuts
5. Optimize performance
6. Create user documentation

**Deliverables:**
- Polished user interface
- Save/load patterns
- Performance optimizations
- User documentation

## Technical Specifications

### MIDI Implementation
- **Format**: Standard MIDI File (SMF) Type 0
- **Drum Mapping**: General MIDI Drum Map (Channel 10)
- **Resolution**: 96 PPQ (Pulses Per Quarter Note)
- **Note Assignments**:
  - Track 1: Kick (C1 - MIDI 36)
  - Track 2: Snare (D1 - MIDI 38)
  - Track 3: Closed Hi-Hat (F#1 - MIDI 42)
  - Track 4: Open Hi-Hat (A#1 - MIDI 46)
  - Track 5: Crash (C#2 - MIDI 49)
  - Track 6: Ride (D#2 - MIDI 51)
  - Track 7: Low Tom (A0 - MIDI 45)
  - Track 8: High Tom (D2 - MIDI 50)

### Timing System Enhancement (December 2024)
- **Clock-Based Timing**: CPU clock timing using `love.timer.getTime()` for professional accuracy
- **Frame-Rate Independence**: Timing accuracy unaffected by frame drops, VSync, or variable frame rates
- **Backward Compatibility**: Supports both "clock" and "frame" timing modes via `setTimingMode()`
- **BPM Change Handling**: Smooth timing adjustments during playback with proportional time scaling
- **Multi-Step Processing**: Handles large time gaps gracefully with `while` loop processing
- **Safety Mechanisms**: Prevents infinite loops with extreme time jumps (32-step safety limit)
- **Timing Information API**: `getTimingInfo()` provides real-time timing diagnostics
- **Professional Accuracy**: Eliminates timing drift over long playback sessions
- **Seamless Mode Switching**: Can switch between timing modes without disrupting playback

### Audio Requirements
- **Sample Format**: 16-bit WAV files, 44.1kHz
- **Latency**: < 10ms for responsive feedback
- **Polyphony**: Support simultaneous playback of all 8 tracks

### UI Specifications
- **Grid Size**: 16 columns (steps) × 8 rows (tracks)
- **Step Size**: 32×32 pixels per cell
- **Colors**: 
  - Active step: Bright color
  - Inactive step: Dim color
  - Current position: Highlighted border
- **Controls**: Play, Stop, Reset, Export, BPM slider

## Testing Strategy

### Unit Tests
- Sequencer timing accuracy
- Pattern data manipulation
- MIDI file generation
- Audio sample loading

### Integration Tests
- Audio-visual synchronization
- MIDI export validation
- File I/O operations
- UI interaction workflows

### Performance Tests
- Audio latency measurements
- Memory usage optimization
- CPU performance under load

### Test Suite Status (July 2025)
- **Total Test Coverage**: 247 tests across 24 test suites
- **Pass Rate**: 100% (247/247 tests passing)
- **Test Categories**:
  - Core Sequencer Tests (7 tests)
  - Utility Function Tests (2 tests)
  - Phase 2 Sequencer Logic Tests (7 tests)
  - Phase 2 UI Interaction Tests (5 tests)
  - Phase 3 Audio System Tests (10 tests)
  - Phase 3 UI Audio Tests (7 tests)
  - Phase 4 MIDI Export Tests (11 tests)
  - Phase 4 UI Export Tests (10 tests)
  - Bug Fix Validation Tests (6 tests)
  - Timing System Fix Tests (9 tests)
  - Clock-Based Timing Tests (10 tests)
  - Audio Timing Fix Tests (9 tests)
  - Sequencer Audio Readiness Tests (10 tests)
  - BPM Text Input Feature Tests (19 tests)
  - BPM Slider Sync Tests (11 tests)
  - Real Application Flow Tests (5 tests)
  - Clear Pattern Functionality Tests (12 tests)
  - Reset Volumes Functionality Tests (12 tests)
  - UI Reorganization Tests (12 tests)
  - Track Colors Tests (12 tests)
  - Subtle UI Colors Tests (12 tests)
  - Metronome Functionality Tests (12 tests)
  - Improved Metronome Tests (14 tests)
  - Sequence Grid Visual Grouping Tests (12 tests)
  - UI Border Enhancement Tests (15 tests)

### Clock-Based Timing Test Coverage
- **Frame-Rate Independence**: Validates timing accuracy under variable frame rates
- **Precise Step Timing**: Tests exact step boundary triggering
- **Long Playback Accuracy**: Verifies timing over extended playback sessions
- **BPM Change Handling**: Tests smooth BPM transitions during playback
- **Safety Mechanisms**: Validates protection against extreme time gaps
- **Mode Switching**: Tests seamless transitions between timing modes
- **Backward Compatibility**: Ensures frame-based timing still works correctly

### Test Infrastructure Improvements
- **Mock Timer System**: Controlled time simulation for clock-based tests
- **Mock Audio System**: Audio trigger validation and logging
- **Timing Mode Isolation**: Legacy tests use frame-based mode for compatibility
- **Debug Information**: Enhanced error messages with timing diagnostics
- **Comprehensive Coverage**: Every timing edge case and bug fix validated

## Dependencies

### Required Libraries
- **LÖVE 11.4**: Main framework
- **LuaUnit**: Testing framework
- **Custom MIDI library**: For MIDI file generation (to be implemented)

### External Tools
- **MIDI validator**: For testing exported files
- **Audio editor**: For preparing sample files
- **DAW software**: For MIDI compatibility testing

## Risk Assessment & Mitigation

### Technical Risks
1. **MIDI Complexity**: MIDI file format implementation
   - *Mitigation*: Start with simple MIDI library, expand gradually
2. **Audio Latency**: Real-time audio performance
   - *Mitigation*: Use Love2D's efficient audio system, optimize buffer sizes
3. **Cross-platform Compatibility**: Windows-specific requirements
   - *Mitigation*: Focus on Love2D's cross-platform capabilities

### Development Risks
1. **Timeline Constraints**: Complex feature set
   - *Mitigation*: Prioritize core features, make advanced features optional
2. **Testing Coverage**: Ensuring reliability
   - *Mitigation*: Implement tests from early phases

## Success Criteria

### Minimum Viable Product (MVP)
- [x] 16-step × 8-track pattern programming
- [x] Basic audio playback
- [x] BPM control
- [x] MIDI file export
- [x] Mouse-based interaction

### Enhanced Features
- [ ] Pattern save/load
- [ ] Undo/redo functionality
- [ ] Advanced timing options (swing, shuffle)
- [ ] Real-time MIDI output
- [x] **BPM text input functionality** - Direct BPM entry via text field
- [x] **Clear grid pattern** - Dedicated Clear button to empty entire pattern grid
- [x] **Reset all track levels to 70% button** - Dedicated Reset Vol button to restore default volumes
- [x] **UI reorganization for better UX** - Eliminated overlapping elements and improved layout
- [x] **Colorful track-based UI design** - Implemented 16 Xterm color palette with dynamic brightness
- [ ] Sample Loader per track
- [ ] Export location select
- [ ] Import file with location select
- [ ] Velocity of hits
- [ ] Track entry skip on loop, ie every second repeat, every 4th repeat
- [x] **Add metronome** - Implemented audible metronome with accent beats and toggle functionality
- [ ] Add precount
- [x] **Overlapping labels** - Fixed through comprehensive UI reorganization
- [x] **Colour each track select** - Implemented comprehensive track color system with Xterm palette
- [x] **Subtle UI theming** - Added professional dark theme with subtle color accents

### Latest Features ✅ July 2025
- [x] **BPM Text Input** - Direct BPM entry via dedicated text field with validation
- [x] **Input Validation** - Automatic range clamping (60-300) and numeric-only input
- [x] **Keyboard Navigation** - Enter/Escape/Backspace support for text input
- [x] **Visual Polish** - Cursor animation and active/inactive state feedback
- [x] **Smart Integration** - Seamless interaction with existing BPM controls
- [x] **Comprehensive Testing** - 19 test cases covering all input scenarios
- [x] **Clear Grid Pattern** - Dedicated Clear button in transport controls
- [x] **Pattern Management** - Instantly clear entire pattern grid without affecting playback
- [x] **UI Integration** - Clear button positioned between Reset and Export buttons
- [x] **State Preservation** - Clear function preserves BPM and playback state
- [x] **Test Coverage** - 12 comprehensive test cases for clear pattern functionality
- [x] **Reset All Volumes** - Dedicated Reset Vol button above volume controls
- [x] **Volume Management** - Instantly reset all track volumes to 70% (default level)
- [x] **Audio Integration** - Updates all prebuffered and active audio sources immediately
- [x] **UI Positioning** - Reset Vol button positioned above volume slider area
- [x] **Comprehensive Testing** - 12 test cases covering all reset volume scenarios
- [x] **UI Layout Reorganization** - Complete redesign for better UX and functionality
- [x] **Overlap Elimination** - Fixed critical overlap between transport and BPM controls
- [x] **Logical Grouping** - Organized UI into clear rows (BPM, Transport, Grid+Volume)
- [x] **Improved Spacing** - Consistent spacing standards and accessibility guidelines
- [x] **Window Optimization** - Increased window size to 900x650 for better fit
- [x] **Layout Testing** - 12 comprehensive tests for positioning and spacing validation
- [x] **Track Color System** - 8 distinct colors based on 16 Xterm color palette
- [x] **Dynamic Color Brightness** - Three brightness levels (dim/normal/bright) based on state
- [x] **Visual State Feedback** - Colors change dynamically during playback and interaction
- [x] **Color-coded Track Labels** - Enhanced visual identification of tracks
- [x] **Accessibility Compliant** - Color contrast and distinctiveness testing
- [x] **Comprehensive Color Testing** - 12 tests covering all color functionality
- [x] **Subtle UI Color System** - Professional dark theme with complementary color palette
- [x] **Enhanced Visual Hierarchy** - Improved text colors, button states, and UI element contrast
- [x] **Panel Backgrounds** - Subtle visual grouping with minimal distraction from main grid
- [x] **Comprehensive UI Color Testing** - 12 tests covering all subtle UI color functionality
- [x] **Metronome Feature** - Audible metronome with accent beats on steps 1, 5, 9, 13
- [x] **Metronome Toggle Control** - UI button and API for enabling/disabling metronome during playback
- [x] **Professional Metronome Sounds** - Procedurally generated high-quality click sounds with different accent tones
- [x] **Metronome Volume Control** - Independent volume adjustment separate from track volumes
- [x] **Comprehensive Metronome Testing** - 12 tests covering all metronome functionality
- [x] **Improved Metronome Volume Controls** - Separate volume sliders for normal and accent clicks
- [x] **Enhanced Clock-Tick Sounds** - Realistic mechanical clock tick sounds with harmonics and noise
- [x] **Metronome UI Integration** - Volume sliders positioned with other audio controls
- [x] **Comprehensive Improved Metronome Testing** - 14 tests covering enhanced metronome functionality
- [x] **Sequence Grid Visual Grouping** - 4-group background color system for enhanced pattern readability
- [x] **Alternating Group Backgrounds** - Groups 1&3 (steps 1-4, 9-12) with dark grey, groups 2&4 (steps 5-8, 13-16) with darker grey
- [x] **Enhanced Musical Workflow** - Improved visual organization aids in pattern creation and editing
- [x] **Comprehensive Grouping Testing** - 12 tests covering all sequence grouping functionality
- [x] **UI Border Enhancements** - Minimal borders on all slider controls for improved visual definition
- [x] **Button Background and Borders** - Matching border and fill colors for consistent button styling
- [x] **Enhanced Visual Clarity** - 1-pixel minimal borders throughout interface for clean aesthetic
- [x] **Comprehensive Border Testing** - 15 tests covering all UI border enhancement functionality

### Bugs ✅ All Completed
- [x] Play start doesnt generate sound for first step in sequence
- [x] Prioritise playback sound
- [x] CPU clock-based timing system
- [x] Frame-based timing accuracy issues
- [x] BPM change timing glitches during playback
- [x] Large frame drop handling
- [x] Timing drift over long playback sessions
- [x] Visual feedback triggers before sound
- [x] Sound system and sounds loading should be initialised before playback starts

## Licence
Project is covered by the latest GPL

## Conclusion

This implementation plan provides a structured approach to building a professional-quality MIDI drum sequencer. The phased development ensures steady progress while maintaining code quality through comprehensive testing. The modular architecture allows for future enhancements and maintains clean separation of concerns.