
-- Specifications for the buttons in the menu hierarchy.

-- { buttonName, callbackName, { arg1, arg2 } },

local M = {
	{ "Visual Tests", "openChildren", {
		{ "starting transform", "loadScene", {"starting transform"} },
		{ "animate aspect ratio", "loadScene", {"animate aspect ratio"} },
		{ "get camera by url", "loadScene", {"get camera by url"} },
		{ "initial zoom", "loadScene", {"initial zoom"} },
		{ "animate zoom", "loadScene", {"animate zoom"} },
	} },
	{ "Examples", "openChildren", {
	} },
	{ "Unit Tests", "openChildren", {
	} },
	{ "Performance Tests", "openChildren", {
	} },
}

return M
