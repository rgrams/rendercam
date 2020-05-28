
local M = {}

if sys.get_config("script.shared_state") ~= "1" then
	error("rendercam - 'shared_state' setting in game.project (under 'Script') must be enabled for rendercam to work.", 0)
end

-- Localized stuff: (for a small speed boost)
local sqrt = math.sqrt
local min = math.min
local atan = math.atan
local floor = math.floor
local deg, rad = math.deg, math.rad
local matrix4_orthographic = vmath.matrix4_orthographic
local matrix4_perspective = vmath.matrix4_perspective
local ortho_inv = vmath.ortho_inv
local get_world_transform = go.get_world_transform

local function round(x)
	return floor(x + 0.5)
end

-- Constants:
local EXPAND_VIEW = hash("expandView")
local FIXED_AREA = hash("fixedArea")
local FIXED_WIDTH = hash("fixedWidth")
local FIXED_HEIGHT = hash("fixedHeight")
local CONTEXT_KEY = 3700146495

-- Public Variables:
M.configW = sys.get_config("display.width", 960) -- Original window width/height from game.project.
M.configH = sys.get_config("display.height", 480)
M.winW, M.winH = M.configW, M.configH
M.current = nil -- The current camera.
M.debug = {
	name = sys.get_config("rendercam.debug_camera_name", "0"),
	stats = sys.get_config("rendercam.debug_camera_stats", "0"),
}
for k,v in pairs(M.debug) do
	M.debug[k] = v == "1" and true or false -- Convert to boolean.
end

local cameras = {}

function M.get_zoom_for_resize(scaleMode, newW, newH, oldW, oldH)
	if scaleMode == EXPAND_VIEW then
		return 1
	elseif scaleMode == FIXED_AREA then
		local newArea = newW * newH
		local oldArea = oldW * oldH
		return sqrt(newArea / oldArea) -- Zoom is the scale on both axes, hence the square root.
	elseif scaleMode == FIXED_WIDTH then
		return newW / oldW
	elseif scaleMode == FIXED_HEIGHT then
		return newH / oldH
	end
end

-- Update the camera's viewport to fit within the specified rect.
function M.update_cam_viewport(self, x, y, w, h)
	local vp = self.viewport
	if self.fixedAspectRatio then
		local vpw = min(w, h * self.aspectRatio)
		local vph = vpw / self.aspectRatio
		local extraX, extraY = w - vpw, h - vph
		-- Keep everything as integers to prevent subpixel jitter when animating aspect ratio.
		local ox = round(extraX * self.viewportAlign.x) -- Letterbox offset within rect.
		local oy = round(extraY * self.viewportAlign.y)
		local _ox = round(extraX * (1 - self.viewportAlign.x)) -- Letterbox offset on the opposite corner.
		local _oy = round(extraY * (1 - self.viewportAlign.y))
		vp.x, vp.y = x + ox, y + oy
		vp.w, vp.h = w - ox - _ox, h - oy - _oy -- Width/height is the remaining space.
	else
		vp.x, vp.y, vp.w, vp.h = x, y, w, h
	end
end

-- a = Y for vertical FOV, X for horizontal FOV.
function M.get_fov(viewDist, a)
	return deg(atan(a / viewDist) * 2) -- opp / adj
end

function M.get_view(self)
	return ortho_inv(get_world_transform(self.offsetURL))
end

function M.get_projection(self)
	if self.orthographic then
		local hw, hh = self.viewArea.x/2, self.viewArea.y/2
		return matrix4_orthographic(-hw, hw, -hh, hh, self.nearZ, self.farZ)
	else
		local aspectRatio = self.viewArea.x / self.viewArea.y
		return matrix4_perspective(rad(self.fov), aspectRatio, self.nearZ, self.farZ)
	end
end

function M.update_cam_window(self, x, y, newW, newH, oldW, oldH)
	local vp = self.viewport
	local oldVpW, oldVpH = vp.w, vp.h
	M.update_cam_viewport(self, x, y, newW, newH)
	local z = M.get_zoom_for_resize(self.scaleMode, vp.w, vp.h, oldVpW, oldVpH) -- Zoom based on viewport size change.
	self.zoom = self.zoom * z -- It's relative zoom.
	self.viewArea.x = self.viewport.w / self.zoom -- New viewArea == zoomed viewport area.
	self.viewArea.y = self.viewport.h / self.zoom
	if not self.orthographic then
		self.fov = M.get_fov(self.viewDistance, self.viewArea.y)
	end
	self.projection = M.get_projection(self) -- Window resize happens after update, so this is necessary.
end

function M.window_resized(newW, newH, oldW, oldH) -- From render script. NOT called on engine start.
	for i,cam in ipairs(cameras) do
		cam:update_window(0, 0, newW, newH, oldW, oldH)
	end
	M.winW, M.winH = newW, newH
end

 -- Update the view matrices of all cameras. Should call in render script update.
function M.update_camera_transforms()
	local oldContext = _G[CONTEXT_KEY] -- Questionable practice? Yes. Solves all problems easily? Yes.
	for i,cam in ipairs(cameras) do
		if cam.enabled or cam.updateWhenDisabled then
			_G[CONTEXT_KEY] = cam
			cam.view = M.get_view(cam)
		end
	end
	_G[CONTEXT_KEY] = oldContext
end

function M.camera_apply(self) -- Can only be called from the render script.
	local vp = self.viewport
	render.set_viewport(vp.x, vp.y, vp.w, vp.h)
	render.set_view(self.view)
	render.set_projection(self.projection)
end

function M.camera_enable(self)
	if M.current then  M.camera_disable(M.current)  end
	self.enabled = true
	M.current = self
end

function M.get_camera(url)
	for i,cam in ipairs(cameras) do
		if cam.url == url then
			return cam
		end
	end
end

local function register_camera(self)
	table.insert(cameras, self)
end

local function unregister_camera(self)
	for i,cam in ipairs(cameras) do
		if cam == self then
			table.remove(cameras, i)
			break
		end
	end
end

function M.camera_disable(self)
	self.enabled = false
	M.current = nil
end

function M.camera_init(self)
	register_camera(self)
	if not self.useViewArea then
		self.viewArea.x, self.viewArea.y = M.configW, M.configH
	end
	M.update_cam_viewport(self, 0, 0, self.viewArea.x, self.viewArea.y)
	self:update_window(0, 0, M.configW, M.configH, self.viewArea.x, self.viewArea.y)
	self:update_window(0, 0, M.winW, M.winH, self.viewArea.x, self.viewArea.y)
	if self.enabled then  M.camera_enable(self)  end
end

function M.camera_final(self)
	unregister_camera(self)
	if self.enabled then  M.camera_disable(self)  end
end

return M
