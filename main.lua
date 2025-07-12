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
    state = "main",          -- Current application state (only "main" for now)
    sequencer = nil,         -- Sequencer module reference
    ui = nil,                -- UI module reference
    audio = nil,             -- Audio module reference
    midi = nil,              -- MIDI module reference
    utils = nil,             -- Utilities module reference
    commandHistory = nil     -- Command history for undo/redo functionality
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
    app.commandHistory = require("src.command_history")
    
    -- Initialize modules
    app.sequencer:init()
    app.audio:init()
    app.ui:init()
    app.commandHistory:init(app.sequencer, app.audio, app.ui)
    
    -- Connect modules
    app.sequencer.audio = app.audio
    app.ui.commandHistory = app.commandHistory
    
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
    if app.state == "main" then
        if button == 1 then
            -- Left click: normal UI interaction
            app.ui:mousepressed(x, y)
        elseif button == 2 then
            -- Right click: velocity editing
            app.ui:rightMousePressed(x, y)
        end
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

-- Love2D mouse wheel callback
-- @param x, y: Mouse wheel movement
function love.wheelmoved(x, y)
    if app.state == "main" then
        app.ui:wheelmoved(x, y)
    end
end

-- Love2D key press callback
-- @param key: Key that was pressed
function love.keypressed(key)
    if app.state == "main" then
        -- Handle undo/redo shortcuts first (Ctrl+Z/Ctrl+Y)
        local ctrlPressed = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
        
        if ctrlPressed and key == "z" then
            -- Undo (Ctrl+Z)
            if app.commandHistory:undo() then
                print("Undo performed")
            else
                print("Nothing to undo")
            end
        elseif ctrlPressed and key == "y" then
            -- Redo (Ctrl+Y)
            if app.commandHistory:redo() then
                print("Redo performed")
            else
                print("Nothing to redo")
            end
        elseif not app.ui.bpmTextInputActive and not app.ui.patternNameInputActive then
            -- Handle shortcuts only when text input is not active
            if key == "space" then
                -- Spacebar: Play/Stop toggle
                if app.sequencer.isPlaying then
                    app.sequencer:stop()
                    print("Stopped")
                else
                    app.sequencer:play()
                    print("Playing")
                end
            elseif key >= "1" and key <= "8" then
                -- Number keys 1-8: Track preview
                local trackNum = tonumber(key)
                if app.audio then
                    app.audio:playSample(trackNum)
                    print("Preview track " .. trackNum .. ": " .. app.ui.trackLabels[trackNum])
                end
            elseif key == "up" or key == "down" or key == "left" or key == "right" then
                -- Arrow keys: Grid navigation
                app.ui:handleArrowKeyNavigation(key)
            elseif key == "return" or key == "kpenter" then
                -- Enter: Toggle current step
                app.ui:toggleCurrentStep()
            else
                -- Let UI handle other key input (for text input)
                app.ui:keypressed(key)
            end
        else
            -- Text input is active, let UI handle all keys
            app.ui:keypressed(key)
        end
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