--[[
    MIDI Drum Sequencer - utils.lua
    
    Common utility functions used across the application.
    
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

local utils = {}

-- Clamp a value between minimum and maximum bounds
-- @param value: The value to clamp
-- @param min: Minimum allowed value
-- @param max: Maximum allowed value
-- @return: Clamped value
function utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Check if a point is inside a rectangle
-- @param px, py: Point coordinates
-- @param x, y: Rectangle top-left corner
-- @param w, h: Rectangle width and height
-- @return: true if point is inside rectangle, false otherwise
function utils.pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

return utils