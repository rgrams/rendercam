
-- ************************************************************************************************
-- Copyright 2019 Ross Grams
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software
-- and associated documentation files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
-- BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ************************************************************************************************

-- Debug-Draw - For Defold.
-- A set of convenience functions to draw lines, shapes, and text with the
-- "draw_line" and "draw_text" render messages.

local M = {}

M.COLORS = {
	white = vmath.vector4(1),
	black = vmath.vector4(0, 0, 0, 1),
	red = vmath.vector4(1, 0, 0, 1),
	cyan = vmath.vector4(0, 1, 1, 1),
	yellow = vmath.vector4(1, 1, 0, 1),
	orange = vmath.vector4(1, 0.5, 0, 1),
	green = vmath.vector4(0, 1, 0, 1),
	blue = vmath.vector4(0, 0.5, 1, 1),
	pink = vmath.vector4(1, 0.5, 1, 1),
	magenta = vmath.vector4(1, 0, 1, 1),
}
M.default_color = M.COLORS.yellow -- Can be a vector4 or a name.
M.default_circle_segments = 16

local TWO_PI = math.pi * 2
local V1, V2 = vmath.vector3(), vmath.vector3()
local MSGDATA = { start_point = V1, end_point = V2 }
local TEXTMSGDATA = {}
local cos, sin = math.cos, math.sin

local function rotate_xy(x, y, a)
	local c = cos(a);  local s = sin(a)
	return c * x - s * y, s * x + c * y
end

function M.ray(v1, v2, color)
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	V1.x = v1.x;  V1.y = v1.y;  V1.z = v1.z
	V2.x = v2.x;  V2.y = v2.y;  V2.z = v2.z
	MSGDATA.color = color
	msg.post("@render:", "draw_line", MSGDATA)
end

function M.line(x1, y1, x2, y2, color)
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	V1.x = x1;  V1.y = y1;  V1.z = 0
	V2.x = x2;  V2.y = y2;  V2.z = 0
	MSGDATA.color = color
	msg.post("@render:", "draw_line", MSGDATA)
end

function M.rect(lt, rt, top, bot, color)
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	M.line(lt, top, rt, top, color)
	M.line(rt, top, rt, bot, color)
	M.line(rt, bot, lt, bot, color)
	M.line(lt, bot, lt, top, color)
end

function M.box(cx, cy, w, h, color, rot)
	h = h or w
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	local w2, h2 = w/2, h/2
	local tlx, tly, trx, try, brx, bry, blx, bly
	if rot and rot ~= 0 then -- Rotate corner offsets then add center pos.
		tlx, tly = rotate_xy(-w2, h2, rot)
		trx, try = rotate_xy(w2, h2, rot)
		brx, bry = rotate_xy(w2, -h2, rot)
		blx, bly = rotate_xy(-w2, -h2, rot)
		tlx, tly, trx, try = tlx + cx, tly + cy, trx + cx, try + cy
		brx, bry, blx, bly = brx + cx, bry + cy, blx + cx, bly + cy
	else
		tlx, tly = cx - w2, cy + h2
		trx, try = cx + w2, cy + h2
		brx, bry = cx + w2, cy - h2
		blx, bly = cx - w2, cy - h2
	end
	M.line(tlx, tly, trx, try, color)
	M.line(trx, try, brx, bry, color)
	M.line(brx, bry, blx, bly, color)
	M.line(blx, bly, tlx, tly, color)
end

function M.cross(cx, cy, radiusX, radiusY, color, rot)
	radiusY = radiusY or radiusX
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end

	local x1x, x1y, x2x, x2y = -radiusX, 0, radiusX, 0 -- X line (horizontal), points 1 and 2.
	local y1x, y1y, y2x, y2y = 0, -radiusY, 0, radiusY -- Y line (vertical), points 1 and 2
	if rot and rot ~= 0 then -- Rotate point offsets if needed.
		x1x, x1y = rotate_xy(x1x, x1y, rot)
		x2x, x2y = rotate_xy(x2x, x2y, rot)
		y1x, y1y = rotate_xy(y1x, y1y, rot)
		y2x, y2y = rotate_xy(y2x, y2y, rot)
	end
	-- Add center pos to point positions.
	x1x, x1y, x2x, x2y = x1x + cx, x1y + cy, x2x + cx, x2y + cy
	y1x, y1y, y2x, y2y = y1x + cx, y1y + cy, y2x + cx, y2y + cy

	M.line(x1x, x1y, x2x, x2y, color)
	M.line(y1x, y1y, y2x, y2y, color)
end

function M.circle(cx, cy, radius, color, segments, baseAngle)
	segments = segments or M.default_circle_segments
	if segments <= 1 then  return  end
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	baseAngle = baseAngle or 0
	local a = TWO_PI / segments
	local x1, y1 = cx + cos(baseAngle) * radius, cy + sin(baseAngle) * radius
	for i=1,segments do
		local a2 = baseAngle + i * a
		local x2, y2 = cx + cos(a2) * radius, cy + sin(a2) * radius
		M.line(x1, y1, x2, y2, color)
		x1, y1 = x2, y2
		if segments <= 2 then  break  end -- Don't bother drawing both if it's only 2 with no gap.
	end
end

function M.text(text, x, y, color)
	color = color or M.default_color
	if M.COLORS[color] then  color = M.COLORS[color]  end
	V1.x, V1.y = x, y
	TEXTMSGDATA.text, TEXTMSGDATA.position, TEXTMSGDATA.color = text, V1, color
	msg.post("@render:", "draw_debug_text", TEXTMSGDATA)
end

return M
