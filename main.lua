--[[
    MIDI Drum Sequencer - main.lua
    
    Main entry point for the Love2D application.
    Manages application state and routes events to appropriate modules.
    
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

-- Application state table
local app = {
    state = "main",     -- Current application state (only "main" for now)
    sequencer = nil,    -- Sequencer module reference
    ui = nil,           -- UI module reference
    audio = nil,        -- Audio module reference
    midi = nil,         -- MIDI module reference
    utils = nil         -- Utilities module reference
}

-- Love2D initialization callback
-- Called once when the application starts
function love.load()
    -- Load all modules
    app.sequencer = require("src.sequencer")
    app.audio = require("src.audio")
    app.midi = require("src.midi")
    app.ui = require("src.ui")
    app.utils = require("src.utils")
    
    -- Initialize modules
    app.sequencer:init()
    app.audio:init()
    app.ui:init()
    
    -- Connect audio to sequencer
    app.sequencer.audio = app.audio
    
    -- Set dark background color
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

-- Love2D update callback
-- Called every frame with delta time
-- @param dt: Time elapsed since last frame in seconds
function love.update(dt)
    if app.state == "main" then
        app.sequencer:update(dt)
        app.audio:update(dt)
        app.ui:update(dt)
    end
end

-- Love2D draw callback
-- Called every frame to render graphics
function love.draw()
    if app.state == "main" then
        app.ui:draw()
    end
end

-- Love2D mouse press callback
-- @param x, y: Mouse coordinates
-- @param button: Mouse button number (1 = left, 2 = right, 3 = middle)
function love.mousepressed(x, y, button)
    if app.state == "main" and button == 1 then
        app.ui:mousepressed(x, y)
    end
end

-- Love2D mouse release callback
-- @param x, y: Mouse coordinates
-- @param button: Mouse button number
function love.mousereleased(x, y, button)
    if app.state == "main" and button == 1 then
        app.ui:mousereleased(x, y)
    end
end

-- Love2D mouse moved callback
-- @param x, y: Current mouse coordinates
function love.mousemoved(x, y)
    if app.state == "main" then
        app.ui:mousemoved(x, y)
    end
end

-- Love2D key press callback
-- @param key: Key that was pressed
function love.keypressed(key)
    if app.state == "main" then
        -- Let UI handle key input first (for text input)
        app.ui:keypressed(key)
    end
    
    -- Global key handling
    if key == "escape" then
        -- If text input is active, let UI handle escape first
        if not app.ui.bpmTextInputActive then
            love.event.quit()
        end
    end
end

-- Love2D text input callback
-- @param text: Text character that was typed
function love.textinput(text)
    if app.state == "main" then
        app.ui:textinput(text)
    end
end