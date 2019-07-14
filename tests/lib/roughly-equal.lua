
-- By Josh Grams

local default_epsilon = 0.0001
local abs = math.abs

local function roughly_equal(a, b, epsilon)
	epsilon = epsilon or default_epsilon
	return abs(a - b) < epsilon
end

return roughly_equal
