--[[
    MIDI Drum Sequencer - conf.lua
    
    Love2D configuration file.
    Sets up application window and module settings.
    
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

function love.conf(t)
    -- Application identity for save data
    t.identity = "midi-drum-sequencer"
    
    -- Love2D version this was designed for
    t.version = "11.4"
    
    -- Enable console output on Windows
    t.console = true

    -- Window settings - updated for reorganized UI layout
    t.window.title = "MIDI Drum Sequencer"  -- Window title
    t.window.width = 900                     -- Window width in pixels (increased for better layout)
    t.window.height = 650                    -- Window height in pixels (increased for better spacing)
    t.window.resizable = false               -- Fixed window size
    t.window.vsync = 1                       -- Enable vertical sync

    -- Enable/disable Love2D modules
    -- Only enable what we need for better performance
    t.modules.audio = true       -- Audio playback
    t.modules.data = true        -- Data encoding functions
    t.modules.event = true       -- Event handling
    t.modules.font = true        -- Font rendering
    t.modules.graphics = true    -- Graphics rendering
    t.modules.image = true       -- Image loading
    t.modules.joystick = false   -- Not needed
    t.modules.keyboard = true    -- Keyboard input
    t.modules.math = true        -- Math functions
    t.modules.mouse = true       -- Mouse input
    t.modules.physics = false    -- Not needed
    t.modules.sound = true       -- Sound decoding
    t.modules.system = true      -- System info
    t.modules.thread = false     -- Not needed
    t.modules.timer = true       -- Timing functions
    t.modules.touch = false      -- Not needed
    t.modules.video = false      -- Not needed
    t.modules.window = true      -- Window management
end