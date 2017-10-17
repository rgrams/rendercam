
local M = {}


local PERSPECTIVE = hash("perspective")
local ORTHOGRAPHIC = hash("orthographic")

local SCALEMODE_EXPANDVIEW = hash("expandView")
local SCALEMODE_FIXEDAREA = hash("fixedArea")
local SCALEMODE_FIXEDWIDTH = hash("fixedWidth")
local SCALEMODE_FIXEDHEIGHT = hash("fixedHeight")

local DEFAULT_VIEWDIST = 500 -- arbitrary distance in front of camera used to calculate world view size on window changes

M.view = vmath.matrix4()
M.proj = vmath.matrix4()

M.winSize = vmath.vector3()
M.winHalfSize = vmath.vector3()
M.viewportOffset = vmath.vector3()
M.viewportScale = vmath.vector3(1)

local nearz = 100
local farz = 1000
local abs_nearZ = nearz -- absolute nearz and farz
local abs_farZ = farz -- regular nearz and farz are relative to camera z
local world_plane_z = 0
local campos = vmath.vector3(0, 0, 1000)

local cameras = {}
local curCam = nil


function M.activate_camera(id)
	print("rendercam.activate_camera")
	if cameras[id] then
		if curCam then curCam.active = false end
		curCam = cameras[id]
		if curCam.useViewArea then
			local winSize = vmath.vector3(M.winSize) -- save copy of winSize
			M.update_winSize(curCam.viewArea.x, curCam.viewArea.y) -- set winSize to viewArea so that'll be used as the old winSize
			M.update_window(winSize.x, winSize.y) -- update window with real winSize as the new size
		else
			M.update_window()
		end
	end
end

function M.camera_init(id, data)
	print("rendercam.camera_init")
	cameras[id] = data
	if not data.useViewArea then data.viewArea.z = DEFAULT_VIEWDIST end
	print("viewArea = ", data.viewArea)
	if data.active then
		M.activate_camera(id)
	end
end

function M.camera_final(id)
	cameras[id] = nil
end

function M.calculate_view()
	-- The view matrix is just the camera object transform. (translation & rotation, scale is ignored)
	--		It changes as the camera is translated and rotated, but has nothing to do with aspect ratio or anything else.
	M.view = vmath.matrix4_look_at(curCam.pos, curCam.pos + curCam.forwardVec, curCam.upVec)
	return M.view
end

function M.calculate_proj() -- calculate projection matrix
	if not curCam.orthographic then
		M.proj = vmath.matrix4_perspective(curCam.fov, curCam.aspectRatio, curCam.nearZ, curCam.farZ)
	else -- ORTHOGRAPHIC
		local x = curCam.halfViewArea.x * curCam.orthoScale
		local y = curCam.halfViewArea.y * curCam.orthoScale
		M.proj = vmath.matrix4_orthographic(-x, x, -y, y, curCam.nearZ, curCam.farZ)
	end

	return M.proj
end

function M.get_target_worldViewSize(cam, lastX, lastY, lastWinX, lastWinY, winX, winY)
	print("get_target_worldViewSize ", cam.scaleMode, lastX, lastY, lastWinX, lastWinY, winX, winY)

	local x, y

	if cam.fixedAspectRatio then
		if cam.scaleMode == SCALEMODE_EXPANDVIEW then
			local z = math.max(lastX / lastWinX, lastY / lastWinY)
			x, y = winX * z, winY * z
		else -- Fixed Area, Fixed Width, and Fixed Height all work the same with a fixed aspect ratio
			--		The proportion and world view area remain the same.
			x, y = lastX, lastY
		end
		print("pre-aspect mod: x, y = ", x, y)

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
	newX = newX or M.winSize.x
	newY = newY or M.winSize.y
	print("rendercam.update_window - new window size = ", newX, newY)

	local x, y = M.get_target_worldViewSize(curCam, curCam.viewArea.x, curCam.viewArea.y, M.winSize.x, M.winSize.y, newX, newY)
	print("     calculated viewArea = ", x .. ", " .. y)
	curCam.viewArea.x = x;  curCam.viewArea.y = y
	curCam.aspectRatio = x / y

	M.update_winSize(newX, newY)

	if curCam.fixedAspectRatio then -- if fixed aspect ratio, calculate viewport cropping offset
		local scale = math.min(M.winSize.x / curCam.aspectRatio, M.winSize.y / 1)
		M.viewportOffset.x = (M.winSize.x - curCam.aspectRatio * scale)*0.5
		M.viewportOffset.y = (M.winSize.y - 1 * scale)*0.5

		local finalViewport = M.winSize - M.viewportOffset * 2
		M.viewportScale.x = finalViewport.x / M.winSize.x
		M.viewportScale.y = finalViewport.y / M.winSize.y
		print("     Fixed Aspect Ratio - viewportOffset = ", M.viewportOffset, M.viewportScale)
	end

	if curCam.orthographic then
		curCam.halfViewArea.x = x/2;  curCam.halfViewArea.y = y/2
	else
		curCam.fov = get_fov(curCam.viewArea.z, curCam.viewArea.y * 0.5)
		print("     calculated aspect, FOV = ", curCam.aspectRatio, curCam.fov)
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

--########################################  Screen to World  ########################################
function M.screen_to_world(x, y, worldz)
	-- convert screen coordinates to viewport coordinates (if fixed aspect ratio)
	x = (x - M.viewportOffset.x) / M.viewportScale.x
	y = (y - M.viewportOffset.y) / M.viewportScale.y

	worldz = worldz or 0

	local m = vmath.inv(M.proj * M.view)

	-- Remap coordinates to range -1 to 1
	local x1 = (x - M.winSize.x * 0.5) / M.winSize.x * 2
	local y1 = (y - M.winSize.y * 0.5) / M.winSize.y * 2

	local np = m * vmath.vector4(x1, y1, -1, 1)
	local fp = m * vmath.vector4(x1, y1, 1, 1)
	np = np * (1/np.w)
	fp = fp * (1/fp.w)

	local t = ( worldz - curCam.abs_nearZ) / (curCam.abs_farZ - curCam.abs_nearZ) -- normalize desired Z to 0-1 from nearz to farz
	local worldpos = vmath.lerp(t, np, fp) -- vector4
	--print(worldpos)
	return vmath.vector3(worldpos.x, worldpos.y, worldpos.z)
end

--########################################  World to Screen  ########################################
function M.world_to_screen(pos)
	local m = M.proj * M.view
	pos = vmath.vector4(pos.x, pos.y, pos.z, 1)

	pos = m * pos
	pos = pos * (1/pos.w)
	pos.x = (pos.x / 2 + 0.5) * M.winSize.x
	pos.y = (pos.y / 2 + 0.5) * M.winSize.y

	return vmath.vector3(pos.x, pos.y, 0)
end

--########################################  Set Window Resolution  ########################################
function M.update_winSize(x, y)
	M.winSize.x = x;  M.winSize.y = y
	M.winHalfSize.x = x * 0.5;  M.winHalfSize.y = y * 0.5
end

--########################################  Set Camera  ########################################
function M.update_camera_pos(pos, near, far) -- near & far args are optional
	print("rendercam - update_camera_pos")
	nearz = near or nearz
	farz = far or farz

	campos = pos
	abs_nearz = campos.z - nearz
	abs_farz = campos.z - farz
end

return M
