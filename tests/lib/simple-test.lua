-- Simple TAP-compatible testing.
-- By Josh Grams

local objectToString = require 'tests.lib.object-to-string'


local coverage = false
local tested, failed = 0, 0

if testCoverage then
	coverage = require(testCoverage.module)
	coverage.init(testCoverage.config)
end

local function note(msg)
	local space = msg and not string.match(msg, '^\t') or false
	print((space and "# " or '#') .. (msg or ''))
end

local function check(test, context)
	if type(test) == 'function' then
		test(context)
	elseif type(test) == 'string' then
		note(test)
	elseif type(test) == 'table' then
		for i,t in ipairs(test) do
			local context
			if test.setup then context = test.setup() end
			check(t, context)
			if test.teardown then test.teardown(context) end
		end
	end
end

-- Must be called exactly once, either at the beginning
-- or at the end.
local function plan(n)
	if n then
		print("1.." .. n)
	else
		print("1.." .. tested)
		if failed > 0 then
			local msg = tostring(failed) .. " of "
			msg = msg .. tostring(tested) .. " tests failed!"
			note(msg)
		end
	end
end

local function ok(ok, msg, level)
	tested = tested + 1
	if not ok then failed = failed + 1 end
	local status = (ok and 'ok ' or 'not ok ') .. tested
	local space = msg and not string.match(msg, '^\t') or false
	print(status .. (space and ' ' or '') .. (msg or ''))
	if not ok then
		local l = 1 + (level or 1)
		local t = '# ' .. debug.traceback('Test failed:', l)
		print(string.gsub(t, '\n', '\n# '))
	end
	return ok
end

local function areOK(yes, a, b, msg, level)
	ok(yes, msg, 1 + (level or 1))
	if not yes then
		note("Expected " .. objectToString(b, '#'))
		note(" but got " .. objectToString(a, '#'))
	end
	return yes
end

local function is(a, b, msg, level)
	return areOK(a == b, a, b, msg, level)
end

local function nearlyEqual(a, b, tol)
	tol = tol or 1.19209290e-07
	local diff = math.abs(a - b)
	if diff <= tol then return true end
	local largest = math.max(math.abs(a), math.abs(b))
	return diff <= largest * tol
end

local function isNearly(a, b, msg, level)
	return areOK(nearlyEqual(a, b), a, b, msg, level)
end

local function has(actual, expected, msg, path, l)
	l = l or 2
	path = path or 'obj'
	local yes = true
	for k,v in pairs(expected) do
		local path = path .. '.' .. k
		if type(v) == 'table' and type(actual[k]) == 'table' then
			yes = has(actual[k], v, msg, path, l + 1) and yes
		else
			local msg = path .. ': ' .. msg
			yes = is(actual[k], v, msg, l) and yes
		end
	end
	return yes
end

local function bail(msg)
	print("Bail out!")
	error(msg)
end

return {
	check = check, plan = plan,
	ok = ok, is = is, has = has,
	isNearly = isNearly,
	note = note, bail = bail
}
