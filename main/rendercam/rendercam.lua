
local M = {}


local PERSPECTIVE = hash("perspective")
local ORTHOGRAPHIC = hash("orthographic")

local SCALEMODE_EXPANDVIEW = hash("expandView")
local SCALEMODE_FIXEDAREA = hash("fixedArea")
local SCALEMODE_FIXEDWIDTH = hash("fixedWidth")
local SCALEMODE_FIXEDHEIGHT = hash("fixedHeight")

M.view = vmath.matrix4()
M.proj = vmath.matrix4()

M.window = vmath.vector3()
M.viewport = { x = 0, y = 0, width = M.window.x, height = M.window.y, scale = { x = 1, y = 1 } }

local cameras = {}
local curCam = nil


function M.activate_camera(id)
	if cameras[id] then
		if curCam then curCam.active = false end
		curCam = cameras[id]
		if curCam.useViewArea then
			M.update_window_size(curCam.viewArea.x, curCam.viewArea.y) -- set window to viewArea so that'll be used as the old window
			msg.post("@render:", "update window")
		else
			msg.post("@render:", "update window")
		end
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

function M.calculate_view() -- called from render script on update
	-- The view matrix is just the camera object transform. (Translation & rotation. Scale is ignored)
	--		It changes as the camera is translated and rotated, but has nothing to do with aspect ratio or anything else.
	M.view = vmath.matrix4_look_at(curCam.pos, curCam.pos + curCam.forwardVec, curCam.upVec)
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

function M.get_target_worldViewSize(cam, lastX, lastY, lastWinX, lastWinY, winX, winY)
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
			error("rendercam.get_target_worldViewSize() - camera: " .. cam.id .. ", scale mode not found.")
		end
	end

	return x, y
end

local function get_fov(distance, y) -- must use Y, not X
	return math.atan(y / distance) * 2
end

function M.update_window(newX, newY)
	newX = newX or M.window.x
	newY = newY or M.window.y

	local x, y = M.get_target_worldViewSize(curCam, curCam.viewArea.x, curCam.viewArea.y, M.window.x, M.window.y, newX, newY)
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
	end

	if curCam.orthographic then
		curCam.halfViewArea.x = x/2;  curCam.halfViewArea.y = y/2
	else
		curCam.fov = get_fov(curCam.viewArea.z, curCam.viewArea.y * 0.5)
	end
end

function M.zoom(z, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	if cam.orthographic then
		cam.orthoScale = cam.orthoScale + z * 0.01
	else
		cam.pos = cam.pos - cam.forwardVec * z
	end
end

function M.pan(dx, dy, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	cam.pos = cam.pos + cam.rightVec * dx + cam.upVec * dy
end

function M.screen_to_world(x, y, worldz, cam_id)
	local cam = cam_id and cameras[cam_id] or curCam
	worldz = worldz or 0

	if cam.fixedAspectRatio then -- convert screen coordinates to viewport coordinates
		x = (x - M.viewport.x) / M.viewport.scale.x
		y = (y - M.viewport.y) / M.viewport.scale.y
	end

	local m = vmath.inv(M.proj * M.view)

	-- Remap coordinates to range -1 to 1
	local x1 = (x - M.window.x * 0.5) / M.window.x * 2
	local y1 = (y - M.window.y * 0.5) / M.window.y * 2

	local np = m * vmath.vector4(x1, y1, -1, 1)
	local fp = m * vmath.vector4(x1, y1, 1, 1)
	np = np * (1/np.w)
	fp = fp * (1/fp.w)

	local t = ( worldz - cam.abs_nearZ) / (cam.abs_farZ - cam.abs_nearZ) -- normalize desired Z to 0-1 from nearz to farz
	local worldpos = vmath.lerp(t, np, fp)
	return vmath.vector3(worldpos.x, worldpos.y, worldpos.z) -- convert vector4 to vector3
end

function M.world_to_screen(pos)
	local m = M.proj * M.view
	pos = vmath.vector4(pos.x, pos.y, pos.z, 1)

	pos = m * pos
	pos = pos * (1/pos.w)
	pos.x = (pos.x / 2 + 0.5) * M.viewport.width + M.viewport.x
	pos.y = (pos.y / 2 + 0.5) * M.viewport.height + M.viewport.y

	return vmath.vector3(pos.x, pos.y, 0)
end

function M.update_window_size(x, y)
	M.window.x = x;  M.window.y = y
	M.viewport.width = x;  M.viewport.height = y
end


return M
