
local M = {}

M.COLORS = {
	white = vmath.vector4(1),
	black = vmath.vector4(0, 0, 0, 1),
	red = vmath.vector4(1, 0, 0, 1),
	cyan = vmath.vector4(0, 1, 1, 1),
	yellow = vmath.vector4(1, 1, 0, 1),
	green = vmath.vector4(0, 1, 0, 1),
	blue = vmath.vector4(0, 0.5, 1, 1),
	pink = vmath.vector4(1, 0.5, 1, 1),
	magenta = vmath.vector4(1, 0, 1, 1),
}
local DEFAULT_COLOR = M.COLORS.yellow
local DEFAULT_CIRCLE_SEGMENTS = 16
local TWO_PI = math.pi * 2
local V1, V2 = vmath.vector3(), vmath.vector3()
local MSGDATA = {}
local cos, sin = math.cos, math.sin

local function rotate_xy(x, y, a)
	local c = cos(a);  local s = sin(a)
	return c * x - s * y, s * x + c * y
end

function M.line(x1, y1, x2, y2, c)
	c = c or DEFAULT_COLOR
	if M.COLORS[c] then  c = M.COLORS[c]  end
	V1.x = x1;  V1.y = y1
	V2.x = x2;  V2.y = y2
	MSGDATA.start_point, MSGDATA.end_point, MSGDATA.color = V1, V2, c
	msg.post("@render:", "draw_line", MSGDATA)
end

function M.rect(lt, rt, top, bot, c)
	M.line(lt, top, rt, top, c)
	M.line(rt, top, rt, bot, c)
	M.line(rt, bot, lt, bot, c)
	M.line(lt, bot, lt, top, c)
end

function M.box(x, y, w, h, c, rot)
	h = h or w
	local w2, h2 = w/2, h/2
	local tlx, tly, trx, try, brx, bry, blx, bly
	if rot and rot ~= 0 then -- Rotate corner offsets then add center pos.
		tlx, tly = rotate_xy(-w2, h2, rot)
		trx, try = rotate_xy(w2, h2, rot)
		brx, bry = rotate_xy(w2, -h2, rot)
		blx, bly = rotate_xy(-w2, -h2, rot)
		tlx, tly, trx, try = tlx + x, tly + y, trx + x, try + y
		brx, bry, blx, bly = brx + x, bry + y, blx + x, bly + y
	else
		tlx, tly = x - w2, y + h2
		trx, try = x + w2, y + h2
		brx, bry = x + w2, y - h2
		blx, bly = x - w2, y - h2
	end
	M.line(tlx, tly, trx, try, c)
	M.line(trx, try, brx, bry, c)
	M.line(brx, bry, blx, bly, c)
	M.line(blx, bly, tlx, tly, c)
end

function M.circle(cx, cy, r, c, segments)
	segments = segments or DEFAULT_CIRCLE_SEGMENTS
	local a = TWO_PI / segments
	local x1, y1 = cx + r, cy
	for i=1,segments do
		local a2 = i * a
		local x2, y2 = cx + cos(a2) * r, cy + sin(a2) * r
		M.line(x1, y1, x2, y2, c)
		x1, y1 = x2, y2
	end
end

return M
