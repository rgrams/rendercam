
local BUTTON_NODE_KEY = hash("button")
local BUTTON_TEXT_NODE_KEY = hash("text")
local BUTTON_SHORTCUT_NODE_KEY = hash("shortcut")

local BODY_COLOR_NORMAL = vmath.vector4(0.4, 0.4, 0.4, 1)
local BODY_COLOR_HOVERED = vmath.vector4(0.5, 0.5, 0.5, 1)
local BODY_COLOR_PRESSED = vmath.vector4(0.2, 0.2, 0.2, 1)

local Button = {}

function Button.hover(self)
	if not self.isHovered then
		self.isHovered = true
		if not self.isKeyboardPressed then
			gui.set_color(self.bodyNode, BODY_COLOR_HOVERED)
		end
	end
end

function Button.unhover(self)
	if self.isHovered then
		self.isHovered = false
		if not self.isKeyboardPressed then
			gui.set_color(self.bodyNode, BODY_COLOR_NORMAL)
		end
	end
end

function Button.press(self, isKeyboard)
	self.isPressed = true
	if isKeyboard then  self.isKeyboardPressed = true  end
	gui.set_color(self.bodyNode, BODY_COLOR_PRESSED)
end

function Button.release(self, dontFire, isKeyboard)
	if self.callback and not dontFire then
		self:callback()
	end
	if isKeyboard then  self.isKeyboardPressed = false  end
	-- Stay pressed if keyboard press is held.
	if not self.isKeyboardPressed then
		self.isPressed = false
		local color = self.isHovered and BODY_COLOR_HOVERED or BODY_COLOR_NORMAL
		gui.set_color(self.bodyNode, color)
	end
end

function Button.overlaps(self, x, y)
	return gui.pick_node(self.bodyNode, x, y)
end

local ButtonGroup = {}

function ButtonGroup.newButton(self, text, pos, shortcut, callback)
	shortcut = tostring(shortcut)
	local nodes = gui.clone_tree(self.protoBtn)
	local bodyNode = nodes[BUTTON_NODE_KEY]
	local textNode = nodes[BUTTON_TEXT_NODE_KEY]
	local shortcutNode = nodes[BUTTON_SHORTCUT_NODE_KEY]

	gui.set_text(textNode, text)
	gui.set_position(bodyNode, pos)
	gui.set_color(bodyNode, BODY_COLOR_NORMAL)
	gui.set_text(shortcutNode, shortcut)

	local btn = {
		text = text,
		callback = callback,
		bodyNode = bodyNode,
		textNode = textNode,
		shortcutAction = hash(shortcut),
		isHovered = false,
		isPressed = false,
		isKeyboardPressed = false
	}
	for k,v in pairs(Button) do  btn[k] = v  end
	table.insert(self.buttons, btn)
	self.buttonForShortcut[btn.shortcutAction] = btn
end

function ButtonGroup.input(self, action_id, action)
	if not action_id then
		self.hoveredBtn = nil
		for i,button in ipairs(self.buttons) do
			if button:overlaps(action.x, action.y) then
				self.hoveredBtn = button
			elseif button.isHovered then
				button:unhover()
				if button.isPressed then
					self.pressedBtn = nil
					button:release(true)
				end
			end
		end
		if self.hoveredBtn then  self.hoveredBtn:hover()  end -- Only hover one button.
	elseif action_id == hash("left click") then
		if action.pressed then
			if self.hoveredBtn then
				self.pressedBtn = self.hoveredBtn
				self.pressedBtn:press()
			end
		elseif action.released then
			if self.pressedBtn then
				self.pressedBtn:release()
				self.pressedBtn = nil
			end
		end
	elseif self.buttonForShortcut[action_id] then
		local button = self.buttonForShortcut[action_id]
		if action.pressed then
			button:press(true)
		elseif action.released then
			button:release(false, true)
		end
	end
end

function newButtonGroup(protoBtn)
	local self = {}
	self.protoBtn = protoBtn
	self.buttons = {}
	self.buttonForShortcut = {}
	self.hoveredBtn = nil
	self.pressedBtn = nil
	for k,v in pairs(ButtonGroup) do  self[k] = v  end
	return self
end

return newButtonGroup
