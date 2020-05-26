
local iter = 100000

local function run_test(func, name, ...)
	assert(func, "perf-test: No function to test for name, '"..name.."'.")
	local t = socket.gettime()
	for i=1, iter do
		func(...)
	end
	print(string.format("Function '%s' took %.5f ms", name, (socket.gettime() - t)*1000))
end

return run_test
