
local M = {
	{ "Unit Tests", "openChildren", {
		{ "1", "loadScene", {"alpha"} },
		{ "2", "loadScene", {"beta"} },
		{ "3", "loadScene", {"delta"} },
	} },
	{ "Performance Tests", "openChildren", {
		{ "1", "loadScene1", {"alpha"} },
		{ "2", "loadScene2", {"beta"} },
		{ "3", "loadScene3", {"delta"} },
		{ "4", "loadScene4", {"delta"} },
		{ "5", "loadScene5", {"delta"} },
		{ "6", "loadScene6", {"delta"} },
		{ "7", "loadScene7", {"delta"} },
		{ "8", "loadScene8", {"delta"} },
		{ "9", "loadScene9", {"delta"} },
		{ "10", "loadScene10", {"delta"} },
	} },
	{ "Visual Tests", "openChildren", {
		{ "1", "loadScene", {"alpha"} },
		{ "2", "loadScene", {"beta"} },
		{ "3", "loadScene", {"delta"} },
	} },
	{ "Examples", "openChildren", {
		{ "1", "loadScene", {"alpha"} },
		{ "2", "loadScene", {"beta"} },
		{ "3", "loadScene", {"delta"} },
	} },
}
-- "Back to Main", "Prev", ...[7 buttons]..., "Next"

return M
