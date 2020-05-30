
-- Specifications for the buttons in the menu hierarchy.

-- { buttonName, callbackName, { arg1, arg2 } },

local M = {
	{ "Visual Tests", "openChildren", {
		{ "starting transform", "loadScene", {"starting transform"} },
		{ "animate aspect ratio", "loadScene", {"animate aspect ratio"} },
		{ "get camera by url", "loadScene", {"get camera by url"} },
		{ "initial zoom", "loadScene", {"initial zoom"} },
		{ "animate zoom", "loadScene", {"animate zoom"} },
		{ "dolly zoom", "loadScene", {"dolly zoom"} },
		{ "world to screen", "loadScene", {"world to screen"} },
		{ "world to screen animated", "loadScene", {"world to screen animated"} },
		{ "world to screen delta", "loadScene", {"world to screen delta"} },
	} },
	{ "Examples", "openChildren", {
	} },
	{ "Unit Tests", "openChildren", {
	} },
	{ "Performance Tests", "openChildren", {
	} },
}

return M
