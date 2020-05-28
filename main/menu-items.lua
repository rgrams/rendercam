
-- Specifications for the buttons in the menu hierarchy.

-- { buttonName, callbackName, { arg1, arg2 } },

local M = {
	{ "Unit Tests", "openChildren", {
	} },
	{ "Performance Tests", "openChildren", {
	} },
	{ "Visual Tests", "openChildren", {
		{ "animate aspect ratio", "loadScene", {"animate aspect ratio"} },
	} },
	{ "Examples", "openChildren", {
	} },
}

return M
