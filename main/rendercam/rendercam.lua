
local M = {}


local SCALEMODE_EXPANDVIEW = hash("expandView")
local SCALEMODE_FIXEDAREA = hash("fixedArea")
local SCALEMODE_FIXEDWIDTH = hash("fixedWidth")
local SCALEMODE_FIXEDHEIGHT = hash("fixedHeight")

M.ortho_zoom_mult = 0.01

M.view = vmath.matrix4()
M.proj = vmath.matrix4()

M.window = vmath.vector3()
M.viewport = { x = 0, y = 0, width = M.window.x, height = M.window.y, scale = { x = 1, y = 1 } }

M.configWin = vmath.vector3(M.window)
M.configAspect = M.configWin.x / M.configWin.y
--				Fit		(scale)		(offset)	Zoom						Stretch
M.guiAdjust = { [0] = {sx=1, sy=1, ox=0, oy=0}, [1] = {sx=1, sy=1, ox=0, oy=0}, [2] = {sx=1, sy=1, ox=0, oy=0} }
M.guiOffset = vmath.vector3()
M.GUI_ADJUST_FIT = 0
M.GUI_ADJUST_ZOOM = 1
M.GUI_ADJUST_STRETCH = 2

local cameras = {}
local curCam = nil


-- ---------------------------------------------------------------------------------
--| 							PRIVATE FUNCTIONS									|
-- ---------------------------------------------------------------------------------

local function get_target_worldViewSize(cam, lastX, lastY, lastWinX, lastWinY, winX, winY)
	local x, y

	if cam.fixedAspectRatio then
		if cam.scaleMode == SCALEMODE_EXPANDVIEW then
			local z = math.max(lastX / lastWinX, lastY / lastWinY)
			x, y = winX * z, winY * z
		else -- Fixed Area, Fixed Width, and Fixed Height all work the same with a fixed aspect ratio
			--		The proportion and world view area remain the same.
			x, y = lastX, lastY
		end
		-- Enforce aspect ratio
		local scale = math.min(x / cam.aspectRatio, y / 1)
		x, y = scale * cam.aspectRatio, scale

	else -- Non-fixed aspect ratio
		if cam.scaleMode == SCALEMODE_EXPANDVIEW then
			local z = math.max(lastX / lastWinX, lastY / lastWinY)
			x, y = winX * z, winY * z
		elseif cam.scaleMode == SCALEMODE_FIXEDAREA then
			if not cam.fixedAspectRatio then -- x, y stay at lastX, lastY with fixed aspect ratio
				local lastArea = lastX * lastY
				local windowArea = winX * winY
				local axisScale = math.sqrt(lastArea / windowArea)
				x, y = winX * axisScale, winY * axisScale
			end
		elseif cam.scaleMode == SCALEMODE_FIXEDWIDTH then
			local ratio = winX / winY
			x, y = lastX, lastX / ratio
		elseif cam.scaleMode == SCALEMODE_FIXEDHEIGHT then
			local ratio = winX / winY
			x, y = lastY * ratio, lastY
		else
			error("rendercam - get_target_worldViewSize() - camera: " .. cam.id .. ", scale mode not found.")
		end
	end

	return x, y
end

local function get_fov(distance, y) -- must use Y, not X
	return math.atan(y / distance) * 2
end

local function calculate_gui_adjust_scales()
	local sx, sy = M.window.x / M.configWin.x, M.window.y / M.configWin.y

	-- Fit
	local adj = M.guiAdjust[M.GUI_ADJUST_FIT]
	local scale = math.min(sx, sy)
	adj.sx = scale;  adj.sy = scale
	adj.ox = (M.window.x - M.configWin.x * adj.sx) * 0.5 / adj.sx
	adj.oy = (M.window.y - M.configWin.y * adj.sy) * 0.5 / adj.sy

	-- Zoom
	adj = M.guiAdjust[M.GUI_ADJUST_ZOOM]
	scale = math.max(sx, sy)
	adj.sx = scale;  adj.sy = scale
	adj.ox = (M.window.x - M.configWin.x * adj.sx) * 0.5 / adj.sx
	adj.oy = (M.window.y - M.configWin.y * adj.sy) * 0.5 / adj.sy

	-- Stretch
	adj = M.guiAdjust[M.GUI_ADJUST_STRETCH]
	adj.sx = sx;  adj.sy = sy
	-- distorts to fit window, offsets always zero
end


-- ---------------------------------------------------------------------------------
--| 					PUBLIC FUNCTIONS I: CAMERA STUFF							|
-- ---------------------------------------------------------------------------------

function M.activate_camera(id)
	if cameras[id] then
		if cameras[id] ~= curCam then
			if curCam then curCam.active = false end
			curCam = cameras[id]
			if curCam.useViewArea then
				M.update_window_size(curCam.viewArea.x, curCam.viewArea.y) -- set window to viewArea so that'll be used as the old window
				msg.post("@render:", "update window")
			else
				msg.post("@render:", "update window")
			end
		end
	else
		print("WARNING: rendercam.activate_camera() - camera ".. id .. " not found. ")
	end
end

function M.camera_init(id, data)
	cameras[id] = data
	if data.active then
		M.activate_camera(id)
	end
end

function M.camera_final(id)
	cameras[id] = nil
end

function M.get_ortho_scale(cam_id)
	local cam = cameras[cam_id]
	if cam.orthographic then
		return cam.orthoScale
	else
		print("ERROR: rendercam.get_ortho_scale() - this camera is not orthographic")
	end
end

function M.set_ortho_scale(s, cam_id)
	local cam = cameras[cam_id]
	if cam.orthographic then
		cam.orthoScale = s
	else
		print("ERROR: rendercam.set_ortho_scale() - this camera is not orthographic")
	end
end

function M.zoom(z, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	if cam.orthographic then
		cam.orthoScale = cam.orthoScale + z * M.ortho_zoom_mult
	else
		cam.lpos = cam.lpos - cam.lforwardVec * z
		go.set_position(cam.lpos, cam.id)
	end
end

function M.pan(dx, dy, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	cam.lpos = cam.lpos + cam.lrightVec * dx + cam.lupVec * dy
	go.set_position(cam.lpos, cam.id)
end

function M.shake(dist, dur, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	table.insert(cam.shakes, { dist = dist, dur = dur, t = dur })
end

function M.recoil(vec, dur, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	table.insert(cam.recoils, { vec = vec, dur = dur, t = dur })
end

function M.stop_shaking(cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	cam.shakes = {}
	cam.recoils = {}
end

function M.follow(target_id, allowMultiFollow, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	if allowMultiFollow then
		table.insert(cam.follows, target_id)
	else
		cam.follows = { target_id }
	end
	cam.following = true
end

function M.unfollow(target_id, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	for i, v in ipairs(cam.follows) do
		if v == target_id then
			table.remove(cam.follows, i)
			if #cam.follows == 0 then cam.following = false end
		end
	end
end

-- ---------------------------------------------------------------------------------
--| 					PUBLIC FUNCTIONS II: RENDER SCRIPT							|
-- ---------------------------------------------------------------------------------

function M.calculate_view() -- called from render script on update
	-- The view matrix is just the camera object transform. (Translation & rotation. Scale is ignored)
	--		It changes as the camera is translated and rotated, but has nothing to do with aspect ratio or anything else.
	M.view = vmath.matrix4_look_at(curCam.wpos, curCam.wpos + curCam.wforwardVec, curCam.wupVec)
	return M.view
end

function M.calculate_proj() -- called from render script on update
	if curCam.orthographic then
		local x = curCam.halfViewArea.x * curCam.orthoScale
		local y = curCam.halfViewArea.y * curCam.orthoScale
		M.proj = vmath.matrix4_orthographic(-x, x, -y, y, curCam.nearZ, curCam.farZ)
	else -- perspective
		M.proj = vmath.matrix4_perspective(curCam.fov, curCam.aspectRatio, curCam.nearZ, curCam.farZ)
	end
	return M.proj
end

function M.update_window_size(x, y)
	M.window.x = x;  M.window.y = y
	M.viewport.width = x;  M.viewport.height = y
end

function M.update_window(newX, newY)
	newX = newX or M.window.x
	newY = newY or M.window.y

	local x, y = get_target_worldViewSize(curCam, curCam.viewArea.x, curCam.viewArea.y, M.window.x, M.window.y, newX, newY)
	curCam.viewArea.x = x;  curCam.viewArea.y = y
	curCam.aspectRatio = x / y
	M.update_window_size(newX, newY)

	if curCam.fixedAspectRatio then -- if fixed aspect ratio, calculate viewport cropping
		local scale = math.min(M.window.x / curCam.aspectRatio, M.window.y / 1)
		M.viewport.width = curCam.aspectRatio * scale
		M.viewport.height = scale

		-- Viewport offset: bar on edge of screen from fixed aspect ratio
		M.viewport.x = (M.window.x - M.viewport.width) * 0.5
		M.viewport.y = (M.window.y - M.viewport.height) * 0.5

		-- For screen-to-viewport coordinate conversion
		M.viewport.scale.x = M.viewport.width / newX
		M.viewport.scale.y = M.viewport.height / newY
	else
		M.viewport.x = 0;  M.viewport.y = 0
		M.viewport.width = newX;  M.viewport.height = newY
	end

	if curCam.orthographic then
		curCam.halfViewArea.x = x/2;  curCam.halfViewArea.y = y/2
	else
		curCam.fov = get_fov(curCam.viewArea.z, curCam.viewArea.y * 0.5)
	end

	calculate_gui_adjust_scales()
end

-- ---------------------------------------------------------------------------------
--| 					PUBLIC FUNCTIONS III: TRANSFORMS							|
-- ---------------------------------------------------------------------------------

function M.screen_to_viewport(x, y, delta)
	if delta then
		x = x / M.viewport.scale.x
		y = y / M.viewport.scale.y
	else
		x = (x - M.viewport.x) / M.viewport.scale.x
		y = (y - M.viewport.y) / M.viewport.scale.y
	end
	return x, y
end

-- Returns start and end points for a ray from the camera through the supplied screen coordinates
-- Start point is on the camera near plane, end point is on the far plane.
function M.screen_to_world_ray(x, y)
	if curCam.fixedAspectRatio then -- convert screen coordinates to viewport coordinates
		x, y = M.screen_to_viewport(x, y)
	end

	local m = vmath.inv(M.proj * M.view)

	-- Remap coordinates to range -1 to 1
	local x1 = (x - M.window.x * 0.5) / M.window.x * 2
	local y1 = (y - M.window.y * 0.5) / M.window.y * 2

	local np = m * vmath.vector4(x1, y1, -1, 1)
	local fp = m * vmath.vector4(x1, y1, 1, 1)
	np = np * (1/np.w)
	fp = fp * (1/fp.w)

	return np, fp
end

function M.screen_to_world_2d(x, y, delta, worldz)
	worldz = worldz or curCam["2dWorldZ"]

	if curCam.fixedAspectRatio then
		x, y = M.screen_to_viewport(x, y, delta)
	end

	local m = not delta and vmath.inv(M.proj * M.view) or vmath.inv(M.proj)

	-- Remap coordinates to range -1 to 1
	x1 = (x - M.window.x * 0.5) / M.window.x * 2
	y1 = (y - M.window.y * 0.5) / M.window.y * 2

	if delta then x1 = x1 + 1;  y1 = y1 + 1 end

	local np = m * vmath.vector4(x1, y1, -1, 1)
	local fp = m * vmath.vector4(x1, y1, 1, 1)
	np = np * (1/np.w)
	fp = fp * (1/fp.w)

	local t = ( worldz - curCam.abs_nearZ) / (curCam.abs_farZ - curCam.abs_nearZ) -- normalize desired Z to 0-1 from abs_nearZ to abs_farZ
	local worldpos = vmath.lerp(t, np, fp)
	return vmath.vector3(worldpos.x, worldpos.y, worldpos.z) -- convert vector4 to vector3
end

function M.world_to_screen(pos, adjust)
	local m = M.proj * M.view
	pos = vmath.vector4(pos.x, pos.y, pos.z, 1)

	pos = m * pos
	pos = pos * (1/pos.w)
	pos.x = (pos.x / 2 + 0.5) * M.viewport.width + M.viewport.x
	pos.y = (pos.y / 2 + 0.5) * M.viewport.height + M.viewport.y

	if adjust then
		pos.x = pos.x / M.guiAdjust[adjust].sx - M.guiAdjust[adjust].ox
		pos.y = pos.y / M.guiAdjust[adjust].sy - M.guiAdjust[adjust].oy
	end

	return vmath.vector3(pos.x, pos.y, 0)
end


return M
