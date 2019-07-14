
local M = {}

-- If you're doing more than 5 transforms with the same object then it
-- makes sense to get the matrix and multiply yourself, otherwise it's
-- faster to use the transform functions.

-- v3-to-v4 and v4-to-v3  -- 25 ms for 100,000 iterations.
-- vmath.inv  -- 21 ms for 100,000 iterations.
-- vmath.ortho_inv  -- 20 ms for 100,000 iterations.
-- Empty function with return value  -- 1 ms for 100,000 iterations.

-- 81 ms for 100,000 iterations.
function M.v3_by_matrix(v3, m)
	local v4 = m * vmath.vector4(v3.x, v3.y, v3.z, 1)
	v3.x, v3.y, v3.z = v4.x, v4.y, v4.z -- Does NOT create a new vector. Modifies the original one.
	return v3
end

-- 30 ms for 100,000 iterations
function M.v4_by_matrix(v4, m)
	return m * v4
end

-- 185 ms for 100,000 iterations.
function M.get_to_world_matrix(wp, wr, ws)
	-- Make matrix4 from rotation quaternion.
	local m = vmath.matrix4_from_quat(wr)

	-- Multiply axes by world scale.
	m.m00, m.m01, m.m02 = m.m00 * ws.x, m.m01 * ws.y, m.m02 * ws.z
	m.m10, m.m11, m.m12 = m.m10 * ws.x, m.m11 * ws.y, m.m12 * ws.z
	m.m20, m.m21, m.m22 = m.m20 * ws.x, m.m21 * ws.y, m.m22 * ws.z

	-- Plug in world position.
	m.m03, m.m13, m.m23 = wp.x, wp.y, wp.z

	return m
end

-- 98 ms for 100,000 iterations.
function M.local_to_world(v3, wp, wr, ws)
	-- Scale.
	v3.x = v3.x * ws.x;  v3.y = v3.y * ws.y;  v3.z = v3.z * ws.z
	-- Rotation.
	v3 = vmath.rotate(wr, v3)
	-- Translation.
	v3.x = v3.x + wp.x;  v3.y = v3.y + wp.y;  v3.z = v3.z + wp.z
	return v3
end

-- 116 ms for 100,000 iterations.
function M.world_to_local(v3, wp, wr, ws)
	-- Translation inverse.
	v3.x = v3.x - wp.x;  v3.y = v3.y - wp.y;  v3.z = v3.z - wp.z
	-- Rotation inverse.
	local r = vmath.conj(wr)
	v3 = vmath.rotate(r, v3)
	-- Scale inverse.
	v3.x = v3.x / ws.x;  v3.y = v3.y / ws.y;  v3.z = v3.z / ws.z
	return v3
end

--[[  With vector4.
function M.world_to_local(v4, wp, wr, ws)
	-- 213 ms for 100,000 iterations.
	-- [[ Fastest method, but doesn't produce a matrix.
	-- Translation inverse.
	v4.x = v4.x - wp.x;  v4.y = v4.y - wp.y;  v4.z = v4.z - wp.z
	-- Rotation inverse.
	local m = vmath.matrix4_from_quat(wr)
	local rInv = vmath.inv(m)
	v4 = rInv * v4
	-- Scale inverse.
	v4.x = v4.x / ws.x;  v4.y = v4.y / ws.y;  v4.z = v4.z / ws.z
	return v4
	--]]


	-- 270 ms for 100,000 iterations.
	--[[ Second-fastest method by a little bit, but makes two extra matrices.
	local r = vmath.matrix4_from_quat(wr)
	local s = vmath.matrix4()
	s.m00, s.m11, s.m22 = ws.x, ws.y, ws.z
	local t = vmath.matrix4()
	t.m03, t.m13, t.m23 = wp.x, wp.y, wp.z

	local m = t * r * s
	local invm = vmath.inv(m)
	return invm * v4, invm, m
	--]]


	-- 306 ms for 100,000 iterations.
	--[[
	-- 1. Make matrix4 from rotation quaternion.
	local m = vmath.matrix4_from_quat(wr)

	-- 2. Multiply axes by world scale.
	m.m00, m.m01, m.m02 = m.m00 * ws.x, m.m01 * ws.y, m.m02 * ws.z
	m.m10, m.m11, m.m12 = m.m10 * ws.x, m.m11 * ws.y, m.m12 * ws.z
	m.m20, m.m21, m.m22 = m.m20 * ws.x, m.m21 * ws.y, m.m22 * ws.z

	-- 3. Plug in world position.
	m.m03, m.m13, m.m23 = wp.x, wp.y, wp.z
	local invm = vmath.inv(m)
	return invm * v4, invm, m
end
	--]]
--]]

return M
