
local transform = require 'rendercam -old.transform'
local T = require 'tests.lib.simple-test'
local eq = require 'tests.lib.roughly-equal'

return {
	"Transform",
	function()

		-- Check that matrix4 orientation is what we expect.
		do
			local m = vmath.matrix4()
			m.m00, m.m01, m.m02, m.m03 = 1, 2, 3, 4
			m.m10, m.m11, m.m12, m.m13 = 5, 6, 7, 8
			m.m20, m.m21, m.m22, m.m23 = 9, 10, 11, 12
			m.m30, m.m31, m.m32, m.m33 = 13, 14, 15, 16
			local v = vmath.vector4(1, 0, 0, 0)
			v = m * v
			T.has(v, {x=1,y=5,z=9,w=13}, 'Matrix4 X-vector is "vertical".')
		end

		-- Test world_to_local with only a position difference.
		do
			local v = vmath.vector3(0, 0, 0)
			local wp = vmath.vector3(100, 50, 1)
			local wr = vmath.quat()
			local ws = vmath.vector3(1, 1, 1)
			local lv = transform.world_to_local(v, wp, wr, ws)
			T.ok(
				type(lv) == 'userdata' and lv.x and lv.y and lv.z,
				'transform.world_to_local - Translation only: Result is a vector.'
			)
			T.ok(
				eq(lv.x, -wp.x) and eq(lv.y, -wp.y) and eq(lv.y, -wp.y),
				'transform.world_to_local - Translation only: Result is correct.'
			)
		end

		-- Test world_to_local with only a rotation difference.
		do
			local v = vmath.vector3(1, 0, 0)
			local wp = vmath.vector3(0, 0, 0)
			local wr = vmath.quat_rotation_z(math.pi/2)
			local ws = vmath.vector3(1, 1, 1)
			local lv = transform.world_to_local(v, wp, wr, ws)
			T.ok(
				eq(lv.x, 0) and eq(lv.y, -1) and eq(lv.z, 0),
				'transform.world_to_local - Rotation only: Result is correct.'
			)
		end

		-- Test world_to_local with only a scale difference.
		do
			local v = vmath.vector3(1, 2, 4)
			local wp = vmath.vector3(0, 0, 0)
			local wr = vmath.quat()
			local ws = vmath.vector3(4, 3, 2)
			local lv = transform.world_to_local(v, wp, wr, ws)
			T.ok(
				eq(lv.x, 1/4) and eq(lv.y, 2/3) and eq(lv.z, 4/2),
				'transform.world_to_local - Scale only: Result is correct.'
			)
		end

		-- Test world_to_local with rotation and scale difference.
		do
			local v = vmath.vector3(-150, 400, 20)
			local wp = vmath.vector3(0, 0, 0)
			local wr = vmath.quat_rotation_z(math.pi/2) * vmath.quat_rotation_y(math.pi/2)
			local ws = vmath.vector3(4, 3, 2)
			local lv = transform.world_to_local(v, wp, wr, ws)
			-- rotate -90 on z:	 (y, -x, z)			==> (400, 150, 20)
			-- rotate -90 on y:	 (-z, y, x)			==> (-20, 150, 400)
			-- scale:				 (1/4, 1/3, 1/2)	==> (-5, 50, 200)
			T.ok(
				eq(lv.x, -5) and eq(lv.y, 50) and eq(lv.z, 200),
				'transform.world_to_local - Rotation and Scale: Result is correct.'
			)
		end

		-- Test world_to_local with translation, rotation, and scale difference.
		do
			local v = vmath.vector3(-150, 400, 20)
			local wp = vmath.vector3(-135, -30, 260)
			local wr = vmath.quat_rotation_z(math.pi/2) * vmath.quat_rotation_y(math.pi/2)
			local ws = vmath.vector3(4, 3, 2)
			local lv = transform.world_to_local(v, wp, wr, ws)
			-- translate 									==> (-15, 430, -240)
			-- rotate -90 on z:	 (y, -x, z)			==> (430, 15, -240)
			-- rotate -90 on y:	 (-z, y, x)			==> (240, 15, 430)
			-- scale:				 (1/4, 1/3, 1/2)	==> (60, 5, 215)
			T.ok(
				eq(lv.x, 60) and eq(lv.y, 5) and eq(lv.z, 215),
				'transform.world_to_local - Translation, Rotation, & Scale: Result is correct.'
			)

			-- Make sure that getting the matrix and multiplying gives the same result.
			local m = transform.get_to_world_matrix(wp, wr, ws)
			local invm = vmath.inv(m)
			local v = vmath.vector3(-150, 400, 20)
			local lv = transform.v3_by_matrix(v, invm)
			T.ok(
				eq(lv.x, 60) and eq(lv.y, 5) and eq(lv.z, 215),
				'transform.get_to_world_matrix, invert, and multiply. - Translation, Rotation, & Scale: Result is correct.'
			)

			lv = transform.v3_by_matrix(lv, m)
			T.ok(
				eq(lv.x, -150) and eq(lv.y, 400) and eq(lv.z, 20),
				'...multiplying last result by to-world matrix gives us the original vector.'
			)
		end
	end
}