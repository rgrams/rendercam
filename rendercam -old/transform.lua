
local M = {}

-- If you're doing more than 5 transforms with the same object then it
-- makes sense to get the matrix and multiply yourself, otherwise it's
-- faster to use the transform functions.

-- NOTE: All of these functions modify the input vector, so if you want to
--       keep the original vector, input a copy of it to the transform function.

function M.v3_by_matrix(v3, m)
	local v4 = m * vmath.vector4(v3.x, v3.y, v3.z, 1)
	v3.x, v3.y, v3.z = v4.x, v4.y, v4.z
	return v3
end

function M.get_to_world_matrix_2(url)
	local m = go.get_world_transform(url)
	return m
end

-- If you want the world-to-local matrix, just invert the result with vmath.inv().
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

function M.local_to_world(v3, wp, wr, ws)
	-- Scale.
	v3.x = v3.x * ws.x;  v3.y = v3.y * ws.y;  v3.z = v3.z * ws.z
	-- Rotation.
	v3 = vmath.rotate(wr, v3)
	-- Translation.
	v3.x = v3.x + wp.x;  v3.y = v3.y + wp.y;  v3.z = v3.z + wp.z
	return v3
end

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

return M
