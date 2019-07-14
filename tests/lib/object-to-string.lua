
-- By Josh Grams

local objectToString

local function worksAsIdentifier(k)
	if type(k) == 'number' then return true
	elseif type(k) == 'string' then
		if string.match(k, "[%a_][%w_]*") then
			return true
		end
	end
	return false
end

local function tableToString(t, indent)
	indent = indent or ''
	local indent2 = indent .. '\t'
	local items = {}
	local len, oneline = 0, true
	-- Add named key/value pairs.
	for k,v in pairs(t) do
		if type(k) ~= 'number' or k > #t then
			if #items > 0 then len = len + string.len(', ') end
			local s
			if worksAsIdentifier(k) then s = k else
				s = '[' .. objectToString(k, indent2) .. ']'
			end
			s = s .. ' = ' .. objectToString(v, indent2)
			len = len + string.len(s)
			table.insert(items, s)
		end
	end
	-- Add numbered values.
	for _,v in ipairs(t) do
		local s = objectToString(v, indent2)
		if len > 0 then len = len + string.len(', ') end
		len = len + string.len(s)
		table.insert(items, s)
	end
	-- Print all.
	local multi = (len > 70)
	local sep = multi and '\n' .. indent .. '\t' or ' '
	local s = '{' .. sep
	for i,item in ipairs(items) do
		if i > 1 then s = s .. ',' .. sep end
		s = s .. item
	end
	if multi then s = s .. '\n' .. indent .. '}'
	else s = s .. sep .. '}' end
	return s
end

local escapeSpecial = {
	['"'] = '\\"',
	['\n'] = '\\n'
}

objectToString = function(obj, indent)
	local t = type(obj)
	if t == 'string' then
		obj = string.gsub(obj, "[\"\n]", escapeSpecial)
		return '"' .. obj .. '"'
	elseif t == 'table' then
		return tableToString(obj, indent)
	else
		return tostring(obj)
	end
end

return objectToString