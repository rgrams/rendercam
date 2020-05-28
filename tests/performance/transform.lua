
local transform = require "rendercam -old.transform"

local perf_test = require "tests.lib.perf-test"

local function v4_to_v3(v4)
	return vmath.vector3(v4.x, v4.y, v4.z)
end

local function v3_to_v4(v3)
	return vmath.vector4(v3.x, v3.y, v3.z, 1)
end

local _v4 = vmath.vector4(1)
local function v3_to_local_v4(v3)
	_v4.x, _v4.y, _v4.z = v3.x, v3.y, v3.z
	return _v4
end

local function emptyFunc()
	return 1
end

local v3 = vmath.vector3()
local wp = go.get_world_position()
local wr = go.get_world_rotation()
local ws = go.get_world_scale()

local m = transform.get_to_world_matrix(wp, wr, ws)
local v3_2 = vmath.vector3(v3)
local v4_2 = vmath.vector4(1)

local v3 = vmath.vector3(1)
local localPos = transform.world_to_local(v3, wp, wr, ws)

perf_test(emptyFunc, "empty function")

perf_test(transform.get_to_world_matrix, "get to-world matrix", wp, wr, ws)
perf_test(transform.get_to_world_matrix_2, "go.get_world_matrix (str url)", ".")
perf_test(transform.get_to_world_matrix_2, "go.get_world_matrix (no url)")
perf_test(transform.get_to_world_matrix_2, "go.get_world_matrix (url obj)", msg.url())
perf_test(transform.v3_by_matrix, "multiply v3 by matrix", v3_2, m)
perf_test(function(m) return vmath.inv(m) end, "invert matrix", m)
perf_test(function(m) return vmath.ortho_inv(m) end, "ortho invert matrix", m)
perf_test(transform.world_to_local, "world to local", v3, wp, wr, ws)
perf_test(transform.local_to_world, "local to world", go.get_position(), wp, wr, ws)
perf_test(v3_to_v4, "v3 to v4", vmath.vector3())
perf_test(v3_to_local_v4, "v3 to local v4", vmath.vector3())
perf_test(v4_to_v3, "v4 to v3", vmath.vector4())
perf_test(function() return vmath.ortho_inv(go.get_world_transform()) end, "get view matrix")

perf_test(emptyFunc, "empty function")
