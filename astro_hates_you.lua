-- astro hates you  |  SINGLE BUILD (PC + Mobile switchable in Settings)
-- separate always-on launcher button (tap to hide/show the window)
-- Device setting: PC = fixed 600x400 layout, Mobile = auto-fits the viewport
-- Gui Width + Gui Height are separate lists so you can make any shape
-- buttons fire on release so swiping the list doesnt toggle everything
-- took rayfield out and wrote my own ui, it loads faster and stops breaking

local Looey = {}
Looey.__index = Looey

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer

local white = Color3.fromRGB(255,255,255)

-- blue theme (key names kept so the rest of the script still works)
local c = {
	bg = Color3.fromRGB(10,22,55),
	panel = Color3.fromRGB(18,40,95),
	panel2 = Color3.fromRGB(28,62,135),
	track = Color3.fromRGB(40,80,160),
	gold = Color3.fromRGB(130,200,255),
	rose = Color3.fromRGB(70,130,230),
	cyan = Color3.fromRGB(190,230,255),
	text = Color3.fromRGB(240,248,255),
	dim = Color3.fromRGB(150,190,235),
	green = Color3.fromRGB(132,238,178),
	dark = Color3.fromRGB(6,12,32),
}

local font = Enum.Font.Gotham
local fontMed = Enum.Font.GothamMedium
local fontBold = Enum.Font.GothamBold
local fontBlack = Enum.Font.GothamBlack

local function new(class, props)
	local o = Instance.new(class)
	if props then
		for k,v in pairs(props) do o[k] = v end
	end
	return o
end

local function round(o, r)
	return new("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = o})
end

local function outline(o, col, th, tr)
	return new("UIStroke", {
		Color = col or c.gold, Thickness = th or 1,
		Transparency = tr or 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o,
	})
end

-- gradient multiplies with background so base has to be white
local function gradient(o, a, b, rot)
	o.BackgroundColor3 = white
	return new("UIGradient", {Color = ColorSequence.new(a, b), Rotation = rot or 0, Parent = o})
end

local function tw(o, t, props, style, dir)
	local x = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	x:Play()
	return x
end

-- keeps a floating window fully on screen (offsets are relative to a 0.5,0.5 anchor)
local function clampToScreen(pos, w, h)
	local cam = workspace.CurrentCamera
	if not cam then return pos end
	local vp = cam.ViewportSize
	local halfX = math.max((vp.X - w) / 2, 0)
	local halfY = math.max((vp.Y - h) / 2, 0)
	return UDim2.new(pos.X.Scale, math.clamp(pos.X.Offset, -halfX, halfX), pos.Y.Scale, math.clamp(pos.Y.Offset, -halfY, halfY))
end

-- where the launcher button parks for each side
local function sideToPos(side)
	side = string.lower(tostring(side or "top"))
	if side == "right" then
		return UDim2.new(1, -50, 0.5, 0)
	elseif side == "top" then
		return UDim2.new(0.5, 0, 0, 62)
	else
		return UDim2.new(0, 50, 0.5, 0)
	end
end

-- fires only if the finger/mouse barely moved, so scrolling never triggers stuff
local function onTap(obj, callback, threshold)
	threshold = threshold or 10
	local startPos, moved, tracking = nil, false, false
	obj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startPos = input.Position
			moved = false
			tracking = true
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if tracking and startPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startPos
			if math.abs(d.X) > threshold or math.abs(d.Y) > threshold then moved = true end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if tracking and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			tracking = false
			if not moved then task.spawn(callback) end
		end
	end)
end

local function drag(frame, handle, onMove, threshold, onEnd)
	handle = handle or frame
	threshold = threshold or 3
	local down, start, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			down = true
			start = input.Position
			startPos = frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if down and start and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - start
			if math.abs(d.X) > threshold or math.abs(d.Y) > threshold then
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				if onMove then onMove() end
			end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if down and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			down = false
			start = nil
			if onEnd then onEnd() end
		end
	end)
end

-- elements
local Tab = {}
Tab.__index = Tab

function Tab:_n()
	self.n = self.n + 1
	return self.n
end

function Tab:CreateSection(name, keepCase)
	local f = new("Frame", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, LayoutOrder = self:_n(), Parent = self.page})
	new("TextLabel", {
		Text = keepCase and (name or "section") or string.upper(name or "section"), Font = fontBold, TextSize = 11, TextColor3 = c.gold,
		BackgroundTransparency = 1, Size = UDim2.new(1,0,0,16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
	})
	local line = new("Frame", {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-6), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = f})
	gradient(line, c.gold, c.rose, 90)
	return f
end

function Tab:CreateButton(cfg)
	cfg = cfg or {}
	local hasToggle = cfg.Toggle and true or false

	local holder = new("Frame", {
		Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
		LayoutOrder = self:_n(), Parent = self.page,
	})

	local b = new("TextButton", {
		Text = "", AutoButtonColor = false,
		Size = hasToggle and UDim2.new(1,-52,1,0) or UDim2.new(1,0,1,0),
		BackgroundColor3 = c.panel, BorderSizePixel = 0, Parent = holder,
	})
	round(b, 8)
	local s = outline(b, c.gold, 1, 0.7)
	gradient(b, c.panel, c.bg, 90)
	local glow = new("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = c.gold, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = b})
	round(glow, 8)
	new("TextLabel", {
		Text = cfg.Name or "button", Font = fontBold, TextSize = 12, TextColor3 = c.text,
		BackgroundTransparency = 1, Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0), ZIndex = 2, Parent = b,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center,
	})
	b.MouseEnter:Connect(function()
		tw(glow, 0.15, {BackgroundTransparency = 0.88})
		tw(s, 0.15, {Transparency = 0})
	end)
	b.MouseLeave:Connect(function()
		tw(glow, 0.15, {BackgroundTransparency = 1})
		tw(s, 0.15, {Transparency = 0.7})
	end)
	b.MouseButton1Down:Connect(function() tw(glow, 0.1, {BackgroundTransparency = 0.72}) end)
	b.MouseButton1Up:Connect(function() tw(glow, 0.15, {BackgroundTransparency = 0.88}) end)
	onTap(b, function()
		if cfg.Callback then cfg.Callback() end
	end)

	local on = cfg.CurrentValue and true or false
	local switch, knob

	if hasToggle then
		switch = new("Frame", {
			Size = UDim2.new(0,40,0,20), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-6,0.5,0),
			BackgroundColor3 = c.track, BorderSizePixel = 0, Active = true, Parent = holder,
		})
		round(switch, 10)
		knob = new("Frame", {
			Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,3,0.5,0),
			BackgroundColor3 = c.dim, BorderSizePixel = 0, Parent = switch,
		})
		round(knob, 7)

		local function draw(anim)
			local col = on and c.green or c.track
			local kp = on and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
			local kc = on and white or c.dim
			if anim then
				tw(switch, 0.18, {BackgroundColor3 = col})
				tw(knob, 0.18, {Position = kp, BackgroundColor3 = kc})
			else
				switch.BackgroundColor3 = col
				knob.Position = kp
				knob.BackgroundColor3 = kc
			end
		end
		draw(false)

		local function set(v, fire)
			on = v and true or false
			draw(true)
			if fire then
				if on then
					if cfg.OnCallback then task.spawn(cfg.OnCallback) elseif cfg.Callback then task.spawn(cfg.Callback) end
				else
					if cfg.OffCallback then task.spawn(cfg.OffCallback) end
				end
				if cfg.ToggleCallback then task.spawn(cfg.ToggleCallback, on) end
			end
		end

		onTap(switch, function() set(not on, true) end)

		if cfg.Flag then
			self.win.flags[cfg.Flag] = {Set = set, Get = function() return on end}
		end
		return {Set = set, Get = function() return on end, Button = b}
	end

	return {Button = b}
end

function Tab:CreateToggle(cfg)
	cfg = cfg or {}
	local row = new("Frame", {
		Size = UDim2.new(1,0,0,38), BackgroundColor3 = c.panel, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, Active = true, LayoutOrder = self:_n(), Parent = self.page,
	})
	round(row, 8)
	outline(row, c.gold, 1, 0.78)
	new("TextLabel", {
		Text = cfg.Name or "toggle", Font = fontMed, TextSize = 12, TextColor3 = c.text,
		BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0), Size = UDim2.new(1,-64,1,0),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, Parent = row,
	})
	local switch = new("Frame", {
		Size = UDim2.new(0,40,0,20), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-10,0.5,0),
		BackgroundColor3 = c.track, BorderSizePixel = 0, Parent = row,
	})
	round(switch, 10)
	local knob = new("Frame", {
		Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,3,0.5,0),
		BackgroundColor3 = c.dim, BorderSizePixel = 0, Parent = switch,
	})
	round(knob, 7)

	local on = cfg.CurrentValue and true or false

	local function draw(anim)
		local col = on and c.green or c.track
		local kp = on and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
		local kc = on and white or c.dim
		if anim then
			tw(switch, 0.18, {BackgroundColor3 = col})
			tw(knob, 0.18, {Position = kp, BackgroundColor3 = kc})
		else
			switch.BackgroundColor3 = col
			knob.Position = kp
			knob.BackgroundColor3 = kc
		end
	end
	draw(false)

	local function set(v, fire)
		on = v and true or false
		draw(true)
		if fire and cfg.Callback then task.spawn(cfg.Callback, on) end
	end

	onTap(row, function() set(not on, true) end)

	if cfg.Flag then
		self.win.flags[cfg.Flag] = {Set = set, Get = function() return on end}
	end
	return {Set = set, Get = function() return on end}
end

function Tab:CreateSlider(cfg)
	cfg = cfg or {}
	local min = (cfg.Range and cfg.Range[1]) or 0
	local max = (cfg.Range and cfg.Range[2]) or 100
	local step = cfg.Increment or 1
	local val = cfg.CurrentValue or min
	local hasToggle = cfg.Toggle and true or false
	local enabled = hasToggle and (cfg.ToggleDefault == true) or false

	local holder = new("Frame", {
		Size = UDim2.new(1,0,0, hasToggle and 52 or 50), BackgroundColor3 = c.panel, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, LayoutOrder = self:_n(), Parent = self.page,
	})
	round(holder, 8)
	outline(holder, c.gold, 1, 0.78)
	new("TextLabel", {
		Text = cfg.Name or "slider", Font = fontMed, TextSize = 12, TextColor3 = c.text,
		BackgroundTransparency = 1, Position = UDim2.new(0,10,0,6),
		Size = UDim2.new(1, hasToggle and -118 or -72, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = holder,
	})
	local valLbl = new("TextLabel", {
		Text = tostring(val), Font = fontBold, TextSize = 12, TextColor3 = c.gold,
		BackgroundTransparency = 1, Position = UDim2.new(1, hasToggle and -100 or -64, 0, 6),
		Size = UDim2.new(0, hasToggle and 42 or 54, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Right, Parent = holder,
	})
	local track = new("Frame", {
		Size = UDim2.new(1,-20,0,6), Position = UDim2.new(0,10,0,34),
		BackgroundColor3 = c.track, BorderSizePixel = 0, Active = true, Parent = holder,
	})
	round(track, 3)
	local fill = new("Frame", {Size = UDim2.new(0,0,1,0), BorderSizePixel = 0, Parent = track})
	round(fill, 3)
	gradient(fill, c.cyan, c.rose, 90)
	local knob = new("Frame", {
		Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,0,0.5,0),
		BackgroundColor3 = white, BorderSizePixel = 0, Parent = track,
	})
	round(knob, 7)
	outline(knob, c.cyan, 1.5, 0)

	local switch, switchKnob
	if hasToggle then
		switch = new("Frame", {
			Size = UDim2.new(0,40,0,20), AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-10,0,16),
			BackgroundColor3 = c.track, BorderSizePixel = 0, Active = true, Parent = holder,
		})
		round(switch, 10)
		switchKnob = new("Frame", {
			Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,3,0.5,0),
			BackgroundColor3 = c.dim, BorderSizePixel = 0, Parent = switch,
		})
		round(switchKnob, 7)
	end

	local function refresh()
		if not hasToggle then return end
		switch.BackgroundColor3 = enabled and c.green or c.track
		switchKnob.Position = enabled and UDim2.new(0,23,0.5,0) or UDim2.new(0,3,0.5,0)
		switchKnob.BackgroundColor3 = enabled and white or c.dim
		track.BackgroundTransparency = enabled and 0 or 0.5
		fill.BackgroundTransparency = enabled and 0 or 0.55
		knob.BackgroundTransparency = enabled and 0 or 0.35
		valLbl.TextColor3 = enabled and c.gold or c.dim
	end

	local function set(v, fire)
		v = math.clamp(v, min, max)
		if step > 0 then v = min + math.floor((v - min) / step + 0.5) * step end
		v = math.clamp(v, min, max)
		val = math.floor(v * 1000 + 0.5) / 1000
		local a = (max - min > 0) and (val - min) / (max - min) or 0
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valLbl.Text = tostring(val)
		if fire and cfg.Callback then task.spawn(cfg.Callback, val, enabled) end
	end

	local function setEnabled(v, fire)
		if not hasToggle then return end
		enabled = v and true or false
		refresh()
		if fire and cfg.Callback then task.spawn(cfg.Callback, val, enabled) end
	end

	-- CORREÇÃO DA FUNCIONALIDADE DE ARRASTAR DOS SLIDERS
	local dragging = false
	local function updateSlider(input)
		local pos = track.AbsolutePosition.X
		local size = track.AbsoluteSize.X
		if size > 0 then
			local relX = math.clamp(input.Position.X - pos, 0, size)
			local pct = relX / size
			local newVal = min + (max - min) * pct
			set(newVal, true)
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider(input)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	set(val, false)
	refresh()

	if hasToggle then
		onTap(switch, function() setEnabled(not enabled, true) end)
	end

	if cfg.Flag then
		self.win.flags[cfg.Flag] = {
			Set = function(v, fire) set(v, fire) end,
			Get = function() return val end,
			SetEnabled = function(v, fire) setEnabled(v, fire) end,
			GetEnabled = function() return enabled end,
		}
	end
	return {
		Set = function(v) set(v, false) end,
		Get = function() return val end,
		SetEnabled = function(v) setEnabled(v, false) end,
		GetEnabled = function() return enabled end,
	}
end

function Tab:CreateDropdown(cfg)
	cfg = cfg or {}
	local opts = cfg.Options or {}
	local isMulti = cfg.MultiSelect and true or false
	local picked = {}

	if isMulti then
		if type(cfg.CurrentOption) == "table" then
			for _, v in ipairs(cfg.CurrentOption) do picked[v] = true end
		elseif cfg.CurrentOption then
			picked[cfg.CurrentOption] = true
		end
	else
		local single = cfg.CurrentOption
		if type(single) == "table" then single = single[1] end
		picked = single or opts[1]
	end

	local holder = new("Frame", {
		Size = UDim2.new(1,0,0,36), BackgroundColor3 = c.panel, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = self:_n(), Parent = self.page,
	})
	round(holder, 8)
	outline(holder, c.gold, 1, 0.78)

	local head = new("TextButton", {Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = holder})
	new("TextLabel", {
		Text = cfg.Name or "select", Font = fontMed, TextSize = 12, TextColor3 = c.text,
		BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0), Size = UDim2.new(0.52,-10,1,0),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, Parent = head,
	})

	local function getDisplayText()
		if isMulti then
			local t = {}
			for k, v in pairs(picked) do if v then table.insert(t, tostring(k)) end end
			if #t == 0 then return "None" end
			return table.concat(t, ", ")
		else
			return tostring(picked)
		end
	end

	local valLbl = new("TextLabel", {
		Text = getDisplayText(), Font = fontBold, TextSize = 12, TextColor3 = c.cyan,
		BackgroundTransparency = 1, Position = UDim2.new(0.52,0,0,0), Size = UDim2.new(0.48,-26,1,0),
		TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, Parent = head,
	})
	local arrow = new("TextLabel", {
		Text = "v", Font = fontBold, TextSize = 13, TextColor3 = c.gold,
		BackgroundTransparency = 1, Position = UDim2.new(1,-20,0,0), Size = UDim2.new(0,16,1,0),
		TextXAlignment = Enum.TextXAlignment.Center, Parent = head,
	})

	local listH = math.min(#opts * 21 + 8, 140)
	local list = new("ScrollingFrame", {
		Size = UDim2.new(1,-16,0,listH), Position = UDim2.new(0,8,0,38),
		BackgroundColor3 = c.dark, BackgroundTransparency = 0.35, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = c.gold,
		CanvasSize = UDim2.new(0,0,0,0), Visible = false, Parent = holder,
	})
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	round(list, 6)
	new("UIListLayout", {Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
	new("UIPadding", {PaddingTop = UDim.new(0,4), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,4), PaddingBottom = UDim.new(0,4), Parent = list})

	local open = false
	local function toggle(force)
		if force ~= nil then open = force else open = not open end
		list.Visible = open
		tw(holder, 0.18, {Size = UDim2.new(1,0,0, open and (36 + listH) or 36)})
		tw(arrow, 0.18, {Rotation = open and 180 or 0})
	end

	local optionButtons = {}

	local function refreshButtons()
		for opt, ob in pairs(optionButtons) do
			local isSelected = isMulti and picked[opt] or (picked == opt)
			ob.TextColor3 = isSelected and c.green or c.dim
		end
	end

	local function setupOptions(newOpts)
		opts = newOpts or opts
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		optionButtons = {}
		listH = math.min(#opts * 21 + 8, 140)
		if open then
			holder.Size = UDim2.new(1,0,0, 36 + listH)
		end
		list.Size = UDim2.new(1,-16,0,listH)

		for i, opt in ipairs(opts) do
			local ob = new("TextButton", {
				Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, Text = tostring(opt),
				Font = font, TextSize = 12, TextColor3 = c.dim,
				TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
				LayoutOrder = i, Parent = list,
			})
			optionButtons[opt] = ob

			ob.MouseEnter:Connect(function()
				local isSel = isMulti and picked[opt] or (picked == opt)
				if not isSel then ob.TextColor3 = c.cyan end
			end)
			ob.MouseLeave:Connect(function()
				local isSel = isMulti and picked[opt] or (picked == opt)
				ob.TextColor3 = isSel and c.green or c.dim
			end)

			onTap(ob, function()
				if isMulti then
					picked[opt] = not picked[opt]
					valLbl.Text = getDisplayText()
					refreshButtons()
					if cfg.Callback then cfg.Callback(picked) end
				else
					picked = opt
					valLbl.Text = tostring(opt)
					refreshButtons()
					if cfg.Callback then cfg.Callback(opt) end
					toggle(false)
				end
			end)
		end
		refreshButtons()
	end

	setupOptions(opts)

	onTap(head, function() toggle() end)

	local resObj = {
		Set = function(v, fire)
			if isMulti then
				picked = {}
				if type(v) == "table" then for _, x in ipairs(v) do picked[x] = true end end
			else
				picked = v
			end
			valLbl.Text = getDisplayText()
			refreshButtons()
			if fire and cfg.Callback then
				local arg = picked
				if not isMulti and type(arg) == "string" then arg = arg end
				task.spawn(cfg.Callback, arg)
			end
		end,
		Get = function() return picked end,
		Refresh = function(newOpts)
			setupOptions(newOpts)
		end
	}

	if cfg.Flag then
		self.win.flags[cfg.Flag] = resObj
	end
	return resObj
end

function Tab:CreateInput(cfg)
	cfg = cfg or {}
	local row = new("Frame", {
		Size = UDim2.new(1,0,0,38), BackgroundColor3 = c.panel, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, LayoutOrder = self:_n(), Parent = self.page,
	})
	round(row, 8)
	outline(row, c.gold, 1, 0.78)
	new("TextLabel", {
		Text = cfg.Name or "input", Font = fontMed, TextSize = 12, TextColor3 = c.text,
		BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0), Size = UDim2.new(0.4,-10,1,0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
	})
	local box = new("TextBox", {
		Text = cfg.CurrentValue or "", PlaceholderText = cfg.Placeholder or "type here...",
		Font = font, TextSize = 12, TextColor3 = c.text, PlaceholderColor3 = c.dim,
		ClearTextOnFocus = false, BackgroundColor3 = c.track, BackgroundTransparency = 0.3, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-8,0.5,0), Size = UDim2.new(0.6,-8,0,24),
		TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, Parent = row,
	})
	round(box, 6)
	new("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = box})
	box.FocusLost:Connect(function()
		if cfg.Callback then task.spawn(cfg.Callback, box.Text) end
	end)
	local obj = {
		Set = function(v) box.Text = tostring(v or "") end,
		Get = function() return box.Text end,
	}
	if cfg.Flag then self.win.flags[cfg.Flag] = obj end
	return obj
end

function Looey:CreateWindow(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Looey)
	self.flags = {}
	self.tabs = {}
	self.hidden = true
	self.sideW = 104

	local parent = plr:WaitForChild("PlayerGui")
	local ok, hui = pcall(function() return gethui() end)
	if ok and hui then
		parent = hui
	else
		local ok2, core = pcall(function() return game:GetService("CoreGui") end)
		if ok2 and core then parent = core end
	end

	local gui = new("ScreenGui", {
		Name = "LooeyGui", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = parent,
	})
	self.gui = gui
	Looey.gui = gui
	Looey.flags = self.flags

	local autoDev = (UIS.TouchEnabled and not UIS.KeyboardEnabled) and "Mobile" or "PC"
	self.device = (getgenv and getgenv().LooeyDevice) or autoDev

	if getgenv and getgenv().LooeyGuiSize then
		self.customW = getgenv().LooeyGuiSize[1]
		self.customH = getgenv().LooeyGuiSize[2]
	end

	local function computeLayout()
		local vp = workspace.CurrentCamera.ViewportSize
		local W, H
		if self.device == "PC" then
			local s = math.min(1, (vp.X - 30) / 600, (vp.Y - 30) / 400)
			W, H = math.floor(600 * s), math.floor(400 * s)
		else
			W = math.clamp(vp.X - 16, 290, 460)
			H = math.clamp(vp.Y - 16, 340, 680)
		end
		if self.customW then W = self.customW end
		if self.customH then H = self.customH end
		return W, H
	end
	self.computeLayout = computeLayout

	local btnSide = (getgenv and getgenv().LooeyBtnSide) or "top"
	self.btnSide = btnSide
	self.btnPos = (getgenv and getgenv().LooeyBtnPos) or sideToPos(btnSide)
	self.btnSize = (getgenv and getgenv().LooeyBtnSize) or 40

	local W, H = computeLayout()
	self.W, self.H = W, H
	local center = UDim2.new(0.5, 0, 0.5, 0)
	self.winPos = (getgenv and getgenv().LooeyWinPos) or center

	local shadow = new("Frame", {
		Name = "Shadow", AnchorPoint = Vector2.new(0.5,0.5), Position = self.winPos,
		Size = UDim2.fromOffset(W + 16, H + 20), BackgroundColor3 = Color3.fromRGB(0,0,0),
		BackgroundTransparency = 0.55, BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = gui,
	})
	round(shadow, 18)
	self.shadow = shadow

	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5,0.5), Position = self.winPos,
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = c.bg, BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false, ZIndex = 2, Parent = gui,
	})
	round(main, 14)
	outline(main, c.gold, 1.5, 0.35)
	-- solid dark blue background
	main.BackgroundColor3 = Color3.fromRGB(10,25,75)
	self.main = main

	local bar = new("Frame", {
		Name = "TopBar", Size = UDim2.new(1,0,0,40), BackgroundColor3 = c.panel2,
		BorderSizePixel = 0, ZIndex = 3, Parent = main,
	})
	round(bar, 14)
	new("Frame", {Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,1,-16), BackgroundColor3 = c.panel2, BorderSizePixel = 0, ZIndex = 3, Parent = bar})
	local hair = new("Frame", {Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2), BorderSizePixel = 0, ZIndex = 4, Parent = bar})
	gradient(hair, c.gold, c.rose, 90)

	new("TextLabel", {
		Text = "astro hates you", Font = fontBlack, TextSize = 14,
		TextColor3 = c.gold, BackgroundTransparency = 1, Position = UDim2.new(0,14,0,0),
		Size = UDim2.new(1,-108,1,0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = bar,
	})

	local function topBtn(txt, x, col)
		local b = new("TextButton", {
			Text = txt, Font = fontBold, TextSize = 16, TextColor3 = col,
			BackgroundColor3 = c.bg, BackgroundTransparency = 0.4, AutoButtonColor = false,
			Size = UDim2.new(0,26,0,26), AnchorPoint = Vector2.new(1,0.5),
			Position = UDim2.new(1,x,0.5,0), BorderSizePixel = 0, ZIndex = 6, Parent = bar,
		})
		round(b, 8)
		outline(b, col, 1, 0.6)
		b.MouseEnter:Connect(function()
			tw(b, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = col})
			tw(b, 0.15, {TextColor3 = c.bg})
		end)
		b.MouseLeave:Connect(function()
			tw(b, 0.15, {BackgroundTransparency = 0.4, BackgroundColor3 = c.bg})
			tw(b, 0.15, {TextColor3 = col})
		end)
		return b
	end

	local minBtn = topBtn("-", -42, c.cyan)
	local closeBtn = topBtn("X", -12, c.rose)

	local side = new("ScrollingFrame", {
		Name = "Sidebar", Position = UDim2.new(0,0,0,40), Size = UDim2.new(0,self.sideW,1,-40),
		BackgroundColor3 = c.bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Parent = main,
		ScrollBarThickness = 3, ScrollBarImageColor3 = c.gold, CanvasSize = UDim2.new(0,0,0,0),
	})
	side.AutomaticCanvasSize = Enum.AutomaticSize.Y
	new("UIListLayout", {Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side})
	new("UIPadding", {PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8), Parent = side})
	self.side = side
	
	local content = new("ScrollingFrame", {
		Name = "Content", Position = UDim2.new(0,self.sideW + 8,0,48), Size = UDim2.new(1,-(self.sideW + 20),1,-60),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,0),
		ScrollBarThickness = 4, ScrollBarImageColor3 = c.gold, ZIndex = 3, Parent = main,
	})
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.content = content

	-- the pulse behind the launcher button: a darker blue star
	-- drawn from 5 bars (a pentagram) so its exact center sits on the center of the launcher
	local glow = new("Frame", {
		AnchorPoint = Vector2.new(0.5,0.5), Position = self.btnPos,
		Size = UDim2.fromOffset(100, 100), BackgroundTransparency = 1, BorderSizePixel = 0,
		Visible = true, ZIndex = 19, Parent = gui,
	})
	local glowScale = new("UIScale", {Name = "StarScale", Scale = 1.5, Parent = glow})
	local glowBars = {}
	do
		local R, thick = 50, 9
		local pts = {}
		for k = 0, 4 do
			local ang = math.rad(-90 + k * 72)
			pts[k] = Vector2.new(math.cos(ang) * R, math.sin(ang) * R)
		end
		for k = 0, 4 do
			local a, b = pts[k], pts[(k + 2) % 5]
			local mid, d = (a + b) / 2, b - a
			table.insert(glowBars, new("Frame", {
				AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5, mid.X, 0.5, mid.Y),
				Size = UDim2.fromOffset(d.Magnitude + thick * 0.6, thick), Rotation = math.deg(math.atan2(d.Y, d.X)),
				BackgroundColor3 = Color3.fromRGB(20,50,160), BackgroundTransparency = 0.5,
				BorderSizePixel = 0, ZIndex = 19, Parent = glow,
			}))
		end
	end
	self.glow = glow

	local star = new("ImageButton", {
		Name = "Launcher", AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5,0.5), Position = self.btnPos,
		Size = UDim2.fromOffset(self.btnSize, self.btnSize), BackgroundColor3 = c.bg,
		BorderSizePixel = 0, Visible = true, ZIndex = 20, Parent = gui,
		Image = "rbxassetid://121374428235477",
	})
	local starCorner = round(star, 12)
	self.starCorner = starCorner
	outline(star, c.gold, 1.5, 0.05)
	self.star = star

	drag(star, star, function()
		glow.Position = star.Position
		self.btnPos = star.Position
		if getgenv then getgenv().LooeyBtnPos = star.Position end
	end, 6, function()
		local p = clampToScreen(star.Position, self.btnSize, self.btnSize)
		star.Position = p
		glow.Position = p
		self.btnPos = p
		if getgenv then getgenv().LooeyBtnPos = p end
	end)
	onTap(star, function() self:Toggle() end, 6)

	RunService.RenderStepped:Connect(function(dt)
		if star.Parent then
			glow.Position = star.Position
			local pulse = math.sin(tick() * 2.2)
			-- the tips always reach about 14px past the edge of the button, whatever size the button is
			local tipRadius = (self.btnSize or 58) / 2 + 14 + pulse * 4
			glow.Size = UDim2.fromOffset(100, 100)
			glowScale.Scale = tipRadius / 50
			local turn = (tick() * 50) % 360
			glow.Rotation = turn

			-- fades out as it finishes a full spin, then fades back in as the next spin starts
			local phase = turn / 360
			local gone = 0
			if phase > 0.8 then gone = (phase - 0.8) / 0.2
			elseif phase < 0.1 then gone = (0.1 - phase) / 0.1 end
			gone = (1 - math.cos(gone * math.pi)) / 2

			local base = 0.5 - pulse * 0.12
			local transparency = 1 - (1 - base) * (1 - gone)
			for _, bar in ipairs(glowBars) do
				bar.BackgroundTransparency = transparency
			end
		end
	end)

	local notifHolder = new("Frame", {
		Name = "Notifs", AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-12,0,12),
		Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ZIndex = 90, Parent = gui,
	})
	self.notifHolder = notifHolder
	Looey.notifHolder = notifHolder

	local function keepOnScreen()
		local p = clampToScreen(main.Position, self.W, self.H)
		main.Position = p
		shadow.Position = p
		self.winPos = p
		if getgenv then getgenv().LooeyWinPos = p end
	end
	drag(main, bar, keepOnScreen, 3, keepOnScreen)
	
	onTap(minBtn, function() self:SetVisible(false) end)
	onTap(closeBtn, function() self:Close() end)

	local function applyLayout(w, h)
		local sw = math.clamp(math.floor(w * 0.25), 88, 160)
		self.sideW = sw
		self.W, self.H = w, h
		main.Size = UDim2.fromOffset(w, h)
		shadow.Size = UDim2.fromOffset(w + 16, h + 20)
		side.Size = UDim2.new(0, sw, 1, -40)
		content.Position = UDim2.new(0, sw + 8, 0, 48)
		content.Size = UDim2.new(1, -(sw + 20), 1, -60)
		main.Position = self.winPos
		shadow.Position = self.winPos
	end
	self.applyLayout = applyLayout

	local function relayout()
		if not gui.Parent then return end
		applyLayout(computeLayout())
	end
	self.relayout = relayout

	pcall(function()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
	end)

	self:intro(function()
		self.hidden = false
		main.Visible = true
		shadow.Visible = true
		main.Size = UDim2.fromOffset(W - 70, H - 50)
		shadow.Size = UDim2.fromOffset(W - 54, H - 30)
		tw(main, 0.35, {Size = UDim2.fromOffset(W, H)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tw(shadow, 0.35, {Size = UDim2.fromOffset(W + 16, H + 20)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	return self
end

function Looey:intro(done)
	local cover = new("Frame", {
		Name = "Intro", Size = UDim2.new(1,0,1,0), BackgroundColor3 = c.bg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 100, Parent = self.gui,
	})
	
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(1,0,0,220), BackgroundTransparency = 1, ZIndex = 101, Parent = cover,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,6),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder,
	})

	local lines = {"mm astro", "astro hates you", "astro"}

	task.spawn(function()
		for i, text in ipairs(lines) do
			local size = (i == 1) and 22 or (i == 2 and 36 or 16)
			local textFont = (i == 1) and fontBold or (i == 2 and fontBlack or fontMed)
			local textColor = (i == 3) and c.rose or c.gold

			local lbl = new("TextLabel", {
				Text = "", Font = textFont, TextSize = size,
				TextColor3 = textColor, BackgroundTransparency = 1,
				Size = UDim2.new(0.9,0,0,size + 12), TextTransparency = 1,
				TextStrokeTransparency = 1, TextStrokeColor3 = Color3.fromRGB(0,0,0),
				LayoutOrder = i, Parent = holder,
			})
			tw(lbl, 0.15, {TextTransparency = 0, TextStrokeTransparency = 0.6})
			for ch = 1, #text do
				lbl.Text = text:sub(1, ch)
				task.wait(0.03)
			end
			task.wait(0.5)
		end

		task.wait(0.6)
		tw(cover, 0.45, {BackgroundTransparency = 1})
		for _, kid in ipairs(holder:GetChildren()) do
			if kid:IsA("TextLabel") then tw(kid, 0.4, {TextTransparency = 1, TextStrokeTransparency = 1}) end
		end
		task.wait(0.5)
		cover:Destroy()
		done()
	end)
end

-- saved settings: kept in getgenv() (survives closing and re-running the script) and in a file
-- when the executor supports writefile/readfile (survives restarting the game or executor)
local AstroCfg = {file = "astro_hates_you_settings.json"}
do
	local HttpService = game:GetService("HttpService")
	local data
	pcall(function() if getgenv then data = getgenv().AstroSettings end end)
	if type(data) ~= "table" then
		data = {}
		pcall(function()
			if isfile and readfile and isfile(AstroCfg.file) then
				local decoded = HttpService:JSONDecode(readfile(AstroCfg.file))
				if type(decoded) == "table" then data = decoded end
			end
		end)
	end
	AstroCfg.data = data
	function AstroCfg.save()
		pcall(function() if getgenv then getgenv().AstroSettings = AstroCfg.data end end)
		pcall(function()
			if writefile then writefile(AstroCfg.file, HttpService:JSONEncode(AstroCfg.data)) end
		end)
	end
end

-- astro pops up at the bottom of the window and says which tab you opened
function Looey:ShowTabBanner(name)
	if AstroCfg.data.tabBanner == false then return end
	local main = self.main
	if not main or not main.Parent then return end

	local holder = self.tabBanner
	if not holder or not holder.Parent then
		holder = new("Frame", {
			Name = "TabBanner", AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,1,-12),
			Size = UDim2.fromOffset(0,40), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 60, Parent = main,
		})
		new("UIScale", {Name = "PopScale", Scale = 0.4, Parent = holder})

		-- crescent moon, tilted, sits behind the text box and peeks out of its top right corner
		new("TextLabel", {
			Name = "Moon", Text = "\u{263E}", Font = fontBold, TextSize = 44,
			TextColor3 = Color3.fromRGB(70,150,255), TextTransparency = 1, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(1,-14,0,0),
			Size = UDim2.fromOffset(44,44), Rotation = 20, ZIndex = 60, Parent = holder,
		})

		local pill = new("Frame", {
			Name = "Pill", Size = UDim2.fromOffset(0,40), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.fromRGB(215,232,255), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 61, Parent = holder,
		})
		round(pill, 12)
		new("UIPadding", {PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,14), Parent = pill})
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8), Parent = pill,
		})
		new("ImageLabel", {
			Name = "Astro", Size = UDim2.fromOffset(32,32), BackgroundTransparency = 1,
			Image = "rbxassetid://121374428235477", ScaleType = Enum.ScaleType.Fit,
			ImageTransparency = 1, ZIndex = 62, LayoutOrder = 1, Parent = pill,
		})
		new("TextLabel", {
			Name = "Message", Size = UDim2.fromOffset(0,32), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1, Font = fontBold, TextSize = 14, TextTransparency = 1,
			TextColor3 = Color3.fromRGB(45,120,235), ZIndex = 62, LayoutOrder = 2, Parent = pill,
		})
		self.tabBanner = holder
	end

	local pill, moon, pop = holder.Pill, holder.Moon, holder.PopScale
	local img, label = pill.Astro, pill.Message

	self.bannerToken = (self.bannerToken or 0) + 1
	local token = self.bannerToken

	-- one full pop in -> hold (colors fade back and forth) -> fade out cycle
	-- returns false if a newer banner took over while this one was playing
	local function runPhase(text, image, c1, c2)
		if self.bannerToken ~= token then return false end
		label.Text = text
		img.Image = image

		pop.Scale = 0.4
		holder.Visible = true
		tw(pop, 0.4, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tw(pill, 0.15, {BackgroundTransparency = 0.08})
		tw(img, 0.15, {ImageTransparency = 0})
		tw(label, 0.15, {TextTransparency = 0})
		tw(moon, 0.15, {TextTransparency = 0})

		local moonBlue, moonWhite = Color3.fromRGB(70,150,255), Color3.fromRGB(255,255,255)
		local t0 = tick()
		while self.bannerToken == token and tick() - t0 < 2.6 do
			local a = (1 - math.cos((tick() - t0) * 3.5)) / 2
			label.TextColor3 = c1:Lerp(c2, a)
			moon.TextColor3 = moonBlue:Lerp(moonWhite, a)
			task.wait()
		end
		if self.bannerToken ~= token then return false end

		tw(pop, 0.25, {Scale = 0.6}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tw(pill, 0.25, {BackgroundTransparency = 1})
		tw(img, 0.25, {ImageTransparency = 1})
		tw(label, 0.25, {TextTransparency = 1})
		tw(moon, 0.25, {TextTransparency = 1})
		task.wait(0.35)
		if self.bannerToken ~= token then return false end
		holder.Visible = false
		return true
	end

	local descriptions = {
		Automation = "auto pickups, auto items, and auto escapes",
		Esp = "see twisteds, players, items, and machines",
		Teleport = "teleport to machines, elevators, and items",
		Player = "stamina, ability range, speed, and noclip",
		Machine = "skillchecks and gigi machine tools",
		Map = "fullbright and lighting options",
		Fun = "spin, jump power, and fov changer",
		Settings = "move and resize the gui and its button",
	}
	local description = descriptions[name] or ("everything for " .. tostring(name) .. " is in here")

	task.spawn(function()
		-- 1) astro says which tab you opened (blue -> dark blue)
		local ok = runPhase("this is the " .. tostring(name) .. " tab", "rbxassetid://121374428235477",
			Color3.fromRGB(45,120,235), Color3.fromRGB(10,30,110))
		if not ok then return end
		task.wait(0.15)
		-- 2) then the second image describes the tab (purple -> dark purple)
		runPhase(description, "rbxassetid://18358868097",
			Color3.fromRGB(170,90,235), Color3.fromRGB(60,15,110))
	end)
end

function Looey:CreateTab(name, icon)
	local win = self
	local tab = setmetatable({}, Tab)
	tab.win = win
	tab.n = 0
	tab.name = name

	local page = new("Frame", {
		Name = name .. "Page", Size = UDim2.new(1,-10,0,0), BackgroundTransparency = 1,
		Visible = false, LayoutOrder = #win.tabs, Parent = win.content,
	})
	page.AutomaticSize = Enum.AutomaticSize.Y
	new("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
	tab.page = page

	local btn = new("TextButton", {
		Name = name .. "Tab", Size = UDim2.new(1,0,0,30), BackgroundColor3 = c.panel,
		BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
		LayoutOrder = #win.tabs, Parent = win.side,
	})
	round(btn, 8)
	local btnStroke = outline(btn, c.gold, 1, 1)
	local mark = new("Frame", {
		Size = UDim2.new(0,3,0,0), Position = UDim2.new(0,0,0.5,0), AnchorPoint = Vector2.new(0,0.5),
		BackgroundColor3 = c.gold, BorderSizePixel = 0, Parent = btn,
	})
	round(mark, 2)

	local iconImg
	if icon then
		iconImg = new("ImageLabel", {
			Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,8,0.5,-8),
			BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(icon),
			ImageColor3 = c.dim, Parent = btn,
		})
	end
	local lbl = new("TextLabel", {
		Text = name, Font = fontBold, TextSize = 12, TextColor3 = c.dim, BackgroundTransparency = 1,
		Position = UDim2.new(0, icon and 30 or 10, 0, 0), Size = UDim2.new(1, icon and -34 or -14, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = btn,
	})

	tab.btn = btn
	tab.lbl = lbl
	tab.mark = mark
	tab.stroke = btnStroke
	tab.icon = iconImg

	btn.MouseEnter:Connect(function()
		if win.active ~= tab then
			tw(btn, 0.15, {BackgroundTransparency = 0.55})
			if iconImg then iconImg.ImageColor3 = c.gold end
		end
	end)
	btn.MouseLeave:Connect(function()
		if win.active ~= tab then
			tw(btn, 0.15, {BackgroundTransparency = 1})
			if iconImg then iconImg.ImageColor3 = c.dim end
		end
	end)
	onTap(btn, function()
		win:SelectTab(tab)
		win:ShowTabBanner(name)
	end)

	table.insert(win.tabs, tab)
	if not win.active then win:SelectTab(tab) end
	return tab
end

function Looey:SelectTab(tab)
	self.active = tab
	for _, t in ipairs(self.tabs) do
		local on = (t == tab)
		t.page.Visible = on
		tw(t.btn, 0.15, {BackgroundTransparency = on and 0.2 or 1, BackgroundColor3 = on and c.panel2 or c.panel})
		tw(t.lbl, 0.15, {TextColor3 = on and c.text or c.dim})
		tw(t.mark, 0.15, {Size = on and UDim2.new(0,3,0,18) or UDim2.new(0,3,0,0)})
		tw(t.stroke, 0.15, {Transparency = on and 0.35 or 1})
		if t.icon then tw(t.icon, 0.15, {ImageColor3 = on and c.gold or c.dim}) end
	end
end

function Looey:Notify(cfg)
	cfg = cfg or {}
	local holder = self.notifHolder
	if not holder or not holder.Parent then return end

	local vpX = workspace.CurrentCamera.ViewportSize.X
	local wdt = math.min(268, vpX - 28)

	local y = #holder:GetChildren() * 62
	local toast = new("Frame", {
		Size = UDim2.new(0,wdt,0,52), AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(0,wdt + 52,0,y), BackgroundColor3 = c.bg,
		BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 90, Parent = holder,
	})
	round(toast, 10)
	outline(toast, c.gold, 1, 0.35)
	local stripe = new("Frame", {Size = UDim2.new(0,3,1,-12), Position = UDim2.new(0,8,0,6), BorderSizePixel = 0, Parent = toast})
	round(stripe, 2)
	gradient(stripe, c.cyan, c.rose, 0)
	new("TextLabel", {
		Text = cfg.Title or "notice", Font = fontBold, TextSize = 13, TextColor3 = c.gold,
		BackgroundTransparency = 1, Position = UDim2.new(0,18,0,8), Size = UDim2.new(1,-26,0,16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = toast,
	})
	new("TextLabel", {
		Text = cfg.Content or "", Font = font, TextSize = 12, TextColor3 = c.dim,
		BackgroundTransparency = 1, Position = UDim2.new(0,18,0,26), Size = UDim2.new(1,-26,0,18),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = toast,
	})

	tw(toast, 0.35, {Position = UDim2.new(0,0,0,y)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(cfg.Duration or 3, function()
		if toast and toast.Parent then
			tw(toast, 0.3, {BackgroundTransparency = 1, Position = UDim2.new(0,40,0,y)})
			for _, kid in ipairs(toast:GetDescendants()) do
				if kid:IsA("TextLabel") then tw(kid, 0.25, {TextTransparency = 1}) end
			end
			task.wait(0.35)
			toast:Destroy()
		end
	end)
end

function Looey:SetDevice(dev)
	dev = (string.lower(tostring(dev)) == "pc") and "PC" or "Mobile"
	self.device = dev
	if getgenv then getgenv().LooeyDevice = dev end

	local target = (dev == "PC") and 13 or 12
	if self.gui then
		for _, d in ipairs(self.gui:GetDescendants()) do
			if d:IsA("TextLabel") and (d.TextSize == 12 or d.TextSize == 13) then
				d.TextSize = target
			end
		end
	end

	if self.relayout then self.relayout() end
end

function Looey:SetButtonSide(side)
	side = string.lower(tostring(side or "top"))
	self.btnSide = side
	local p = sideToPos(side)
	self.btnPos = p
	if getgenv then
		getgenv().LooeyBtnSide = side
		getgenv().LooeyBtnPos = p
	end
	if self.star then
		self.star.Position = p
		self.glow.Position = p
	end
end

function Looey:SetButtonSize(px)
	px = math.clamp(tonumber(px) or 58, 24, 200)
	self.btnSize = px
	if getgenv then getgenv().LooeyBtnSize = px end
	if self.star then
		self.star.Size = UDim2.fromOffset(px, px)
		if self.starCorner then self.starCorner.CornerRadius = UDim.new(0, px / 2) end
	end
	if self.glow then
		self.glow.Size = UDim2.fromOffset(px + 16, px + 16)
	end
end

function Looey:SetWidth(w)
	self.customW = tonumber(w) or nil
	if getgenv then getgenv().LooeyGuiSize = {self.customW, self.customH} end
	if self.relayout then self.relayout() end
end

function Looey:SetHeight(h)
	self.customH = tonumber(h) or nil
	if getgenv then getgenv().LooeyGuiSize = {self.customW, self.customH} end
	if self.relayout then self.relayout() end
end

function Looey:SetSize(w, h)
	self:SetWidth(w)
	self:SetHeight(h)
end

function Looey:Center()
	if not self.main then return end
	local cpos = UDim2.new(0.5, 0, 0.5, 0)
	self.winPos = cpos
	if getgenv then getgenv().LooeyWinPos = cpos end
	self.main.Position = cpos
	self.shadow.Position = cpos
end

-- cancels any tab banner that is playing; with animate it leaves a copy behind that fades out fast
function Looey:HideTabBanner(animate)
	self.bannerToken = (self.bannerToken or 0) + 1
	local holder = self.tabBanner
	if not holder or not holder.Parent or not holder.Visible then return end

	if animate and self.gui and self.gui.Parent then
		pcall(function()
			local ghost = holder:Clone()
			ghost.AnchorPoint = Vector2.new(0,0)
			ghost.Position = UDim2.fromOffset(
				holder.AbsolutePosition.X - self.gui.AbsolutePosition.X,
				holder.AbsolutePosition.Y - self.gui.AbsolutePosition.Y
			)
			ghost.ZIndex = 200
			ghost.Parent = self.gui
			for _, d in ipairs(ghost:GetDescendants()) do
				if d:IsA("GuiObject") then d.ZIndex = 200 + d.ZIndex end
				if d:IsA("TextLabel") then
					tw(d, 0.2, {TextTransparency = 1})
				elseif d:IsA("ImageLabel") then
					tw(d, 0.2, {ImageTransparency = 1})
				elseif d:IsA("Frame") then
					tw(d, 0.2, {BackgroundTransparency = 1})
				end
			end
			task.delay(0.25, function() ghost:Destroy() end)
		end)
	end

	holder.Visible = false
end

function Looey:SetVisible(v)
	if not self.gui or not self.gui.Parent then return end
	if v then
		self.hidden = false
		local p = clampToScreen(self.winPos or UDim2.new(0.5,0,0.5,0), self.W, self.H)
		self.winPos = p
		if getgenv then getgenv().LooeyWinPos = p end
		self.main.Position = p
		self.shadow.Position = p
		self.main.Size = UDim2.fromOffset(self.W - 70, self.H - 50)
		self.shadow.Size = UDim2.fromOffset(self.W + 16, self.H + 20)
		self.main.Visible = true
		self.shadow.Visible = true
		tw(self.main, 0.3, {Size = UDim2.fromOffset(self.W, self.H)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	else
		self.hidden = true
		self:HideTabBanner(true)
		self.main.Visible = false
		self.shadow.Visible = false
	end
end

function Looey:Toggle()
	if self.hidden then
		self:SetVisible(true)
	else
		self:SetVisible(false)
	end
end

function Looey:Minimize()
	self:SetVisible(false)
end

function Looey:Restore()
	self:SetVisible(true)
end

function Looey:Close()
	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
end

local Rayfield = Looey

local Window = Rayfield:CreateWindow({
	Name = "astro hates you",
	LoadingTitle = "Loading That FUCKASS Gui...",
	LoadingSubtitle = "BOIIIIIIIIIIIIIIIIIIIIIIIIIIIII",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character, HumanoidRootPart, Humanoid

local function updateCharVars(char)
    Character = char
    if char then
        HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
        Humanoid = char:WaitForChild("Humanoid", 5)
    end
end

LocalPlayer.CharacterAdded:Connect(updateCharVars)
if LocalPlayer.Character then
    updateCharVars(LocalPlayer.Character)
end

-- Blacklist Tables
local itemBlacklist = {}
local playerBlacklist = {}

local TwistedMonsterNames = {
    ["CosmoMonster"] = true, ["BoxtenMonster"] = true, ["YattaMonster"] = true, ["ShrimpoMonster"] = true,
    ["RudieMonster"] = true, ["RibeccaMonster"] = true, ["EggsonMonster"] = true, ["LooeyMonster"] = true,
    ["PoppyMonster"] = true, ["BrushaMonster"] = true, ["TishaMonster"] = true, ["FinnMonster"] = true,
    ["BrightneyMonster"] = true, ["FlyteMonster"] = true, ["GingerMonster"] = true, ["SoulvesterMonster"] = true,
    ["ToodlesMonster"] = true, ["GlistenMonster"] = true, ["GigiMonster"] = true, ["GoobMonster"] = true,
    ["ScrapsMonster"] = true, ["CoalMonster"] = true, ["EclipseMonster"] = true, ["CocoaMonster"] = true,
    ["FlutterMonster"] = true, ["ShellyMonster"] = true, ["PebbleMonster"] = true, ["VeeMonster"] = true,
    ["AstroMonster"] = true, ["SproutMonster"] = true, ["BobetteMonster"] = true, ["BassieMonster"] = true,
    ["DyleMonster"] = true, ["DandyMonster"] = true, ["GourdyMonster"] = true, ["TeaganMonster"] = true,
    ["RodgerMonster"] = true, ["RazzleDazzleMonster"] = true, ["ConnieMonster"] = true, ["WaxwellMonster"] = true,
    ["DiodaMonster"] = true, ["DessaMonster"] = true, ["Dioda"] = true, ["Dessa"] = true
}

local function isTwistedNearby(targetPos, maxDist)
    maxDist = maxDist or 30
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and TwistedMonsterNames[obj.Name] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if part and (part.Position - targetPos).Magnitude <= maxDist then
                return true
            end
        end
    end
    return false
end

local function isElevatorNearby(targetPos, maxDist)
    maxDist = maxDist or 30
    local elevatorsFolder = Workspace:FindFirstChild("Elevators")
    if elevatorsFolder then
        for _, obj in ipairs(elevatorsFolder:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or obj
                if part and (part.Position - targetPos).Magnitude <= maxDist then
                    return true
                end
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Elevator" or obj.Name == "ElevatorDoor" then
            local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or (obj:IsA("BasePart") and obj)
            if part and (part.Position - targetPos).Magnitude <= maxDist then
                return true
            end
        end
    end
    return false
end

local function canInteractWithPosition(pos)
    if isElevatorNearby(pos, 30) then return false end
    if isTwistedNearby(pos, 30) then return false end
    return true
end

-- "Valve" is also the name of parts on the machines, so only count one as the item when it has a
-- pickup prompt (its text says pick up, grab, take or collect, like the other items)
local function isRealValveItem(obj)
    if obj.Name ~= "Valve" then return true end
    local prompts = {}
    if obj:IsA("ProximityPrompt") then table.insert(prompts, obj) end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
    end
    for _, prompt in ipairs(prompts) do
        local text = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
        if text:find("pick") or text:find("grab") or text:find("take") or text:find("collect") then
            return true
        end
    end
    return false
end

local function teleportTo(name, isExact)
    if not Character or not HumanoidRootPart then return false end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local match = isExact and (obj.Name == name) or obj.Name:lower():find(name:lower())
        if match and obj.Name == "Valve" and not isRealValveItem(obj) then match = false end
        if match then
            local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or (obj:IsA("BasePart") and obj)
            if part then
                local targetPos = part:IsA("Model") and part:GetPivot().Position or part.Position
                if isElevatorNearby(targetPos, 30) then continue end
                if isTwistedNearby(targetPos, 30) then
                    Rayfield:Notify({ Title = "Teleport", Content = "Twisted Nearby.", Duration = 2 })
                    return false
                end
                HumanoidRootPart.CFrame = (part:IsA("Model") and part:GetPivot() or part.CFrame) + Vector3.new(0, 3, 0)
                return true
            end
        end
    end
    return false
end

local function performTeleportToMachine()
    if not Character or not HumanoidRootPart then return end
    local ignoredNames = {
        ["VendingMachine"] = true, ["Cooking_ExpressoMachine"] = true,
        ["DanceMachine"] = true, ["Gachapon_Arcade_01"] = true,
        ["Gachapon_Arcade_02"] = true, ["Gachapon_Arcade_03"] = true
    }
    local generators = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not ignoredNames[obj.Name] and obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower == "generator" or nameLower == "generators" or nameLower:find("generator") or nameLower:find("dual_generator") or nameLower:find("dualgen") or nameLower:find("trickortreatgen") then
                local stats = obj:FindFirstChild("Stats") or (obj.Parent and obj.Parent:FindFirstChild("Stats"))
                local isCompleted = false
                if stats then
                    local completed = stats:FindFirstChild("Completed")
                    if completed and completed.Value == true then isCompleted = true end
                end

                if not isCompleted then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part and not isTwistedNearby(part.Position, 30) and not isElevatorNearby(part.Position, 30) then
                        table.insert(generators, part)
                    end
                end
            end
        end
    end
    if #generators > 0 then
        local randomGen = generators[math.random(1, #generators)]
        HumanoidRootPart.CFrame = randomGen.CFrame + Vector3.new(0, 3, 0)
    else
        Rayfield:Notify({ Title = "Teleport", Content = "Twisted Nearby or inside Elevator.", Duration = 2 })
    end
end

local NoclipConnection = nil

local function applyNoclip()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if getconnections then
                pcall(function()
                    for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanQuery"))) do conn:Disconnect() end
                    for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanCollide"))) do conn:Disconnect() end
                    for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanTouch"))) do conn:Disconnect() end
                    for _, conn in ipairs(getconnections(part.Changed)) do conn:Disconnect() end
                end)
            end
            part.CanCollide = false
        end
    end
end

local function toggleNoclip(state)
    if state then
        applyNoclip()
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local AutomationTab = Window:CreateTab("Automation", 71680025256265)

-- sound button: picks one of these at random each click (add or remove IDs as you like)
local SOUND_IDS = {
    "rbxassetid://87343402066963",
    "rbxassetid://119660706522561",
    "rbxassetid://95788498610061",
    "rbxassetid://120119228376767",
}
local lastSoundIndex = nil
local clickSound = Instance.new("Sound")
clickSound.Name = "AstroClickSound"
clickSound.Volume = 1
clickSound.Parent = game:GetService("SoundService")

AutomationTab:CreateButton({
    Name = "listen to him",
    Callback = function()
        pcall(function()
            local idx = math.random(#SOUND_IDS)
            if #SOUND_IDS > 1 then
                while idx == lastSoundIndex do idx = math.random(#SOUND_IDS) end
            end
            lastSoundIndex = idx
            clickSound:Stop()
            clickSound.SoundId = SOUND_IDS[idx]
            clickSound.TimePosition = 0
            clickSound:Play()
        end)
    end
})

local autoGetToElevatorEnabled = false
AutomationTab:CreateToggle({
    Name = "Auto Get To Elevator",
    CurrentValue = false,
    Flag = "AutoGetToElevatorToggle",
    Callback = function(v)
        autoGetToElevatorEnabled = v
    end
})

task.spawn(function()
    while true do
        task.wait(0.5)
        if autoGetToElevatorEnabled then
            pcall(function()
                local infoFolder = Workspace:FindFirstChild("Info")
                local panicValue = infoFolder and infoFolder:FindFirstChild("Panic")
                local elevatorsFolder = Workspace:FindFirstChild("Elevators")

                if panicValue and panicValue.Value == true and elevatorsFolder and HumanoidRootPart then
                    local elevator = elevatorsFolder:FindFirstChild("Elevator") or elevatorsFolder:FindFirstChildOfClass("Model")
                    if elevator then
                        local targetPart = elevator.PrimaryPart or elevator:FindFirstChild("Hitbox") or elevator:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        end
                    end
                end
            end)
        end
    end
end)

local function smartCollectItem(itemObj)
    if not Character or not HumanoidRootPart then return false end
    local targetPart = itemObj:IsA("BasePart") and itemObj or itemObj:FindFirstChildWhichIsA("BasePart", true)
    local prompt = itemObj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not targetPart or not prompt then return false end

    local originalPosition = HumanoidRootPart.CFrame
    local startTime = tick()
    local collected = false

    while tick() - startTime < 5 do
        if not Character or not HumanoidRootPart then break end
        HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, -3, 0)
        pcall(function() fireproximityprompt(prompt) end)

        if not itemObj.Parent then
            collected = true
            break
        end
        task.wait(0.1)
    end

    if HumanoidRootPart then
        HumanoidRootPart.CFrame = originalPosition
    end
    return collected
end

local autoExtractActive = false
local autoHealsActive = false
local autoCollectActive = false
local autoCollectEventActive = false
local autoPickUpTapesActive = false

AutomationTab:CreateToggle({
    Name = "Auto Pick Up Extraction Items",
    CurrentValue = false,
    Flag = "AutoPickUpExtractionItemsToggle",
    Callback = function(v) autoExtractActive = v end
})

AutomationTab:CreateToggle({
    Name = "Auto Pick Up Heals",
    CurrentValue = false,
    Flag = "AutoPickUpHealsToggle",
    Callback = function(v) autoHealsActive = v end
})

AutomationTab:CreateToggle({
    Name = "Auto Collect Research Capsules",
    CurrentValue = false,
    Flag = "AutoCollectResearchCapsulesToggle",
    Callback = function(v) autoCollectActive = v end
})

AutomationTab:CreateToggle({
    Name = "Auto Collect Event Currency",
    CurrentValue = false,
    Flag = "AutoCollectEventCurrencyToggle",
    Callback = function(v) autoCollectEventActive = v end
})

AutomationTab:CreateToggle({
    Name = "Auto Pick Up Tapes",
    CurrentValue = false,
    Flag = "AutoPickUpTapesToggle",
    Callback = function(v) autoPickUpTapesActive = v end
})

task.spawn(function()
    local extractionNames = {["ExtractionSpeedCandy"]=true, ["Instructions"]=true, ["BonBon"]=true, ["Jawbreaker"]=true, ["JumperCable"]=true, ["Valve"]=true}
    local healNames = {["Bandage"]=true, ["HealthKit"]=true}
    local eventCurrencyNames = {["Pumpkin"]=true, ["Basket"]=true, ["Ornament"]=true, ["Hm"]=true}

    local function isInventoryFull()
        local char = LocalPlayer.Character
        if not char then return false end
        local inv = char:FindFirstChild("Inventory")
        if not inv then return false end

        for i = 1, 3 do
            local slot = inv:FindFirstChild("Slot" .. tostring(i))
            if not slot or slot.Value == nil or slot.Value == "" or slot.Value == "None" then
                return false
            end
        end
        return true
    end

    while true do
        task.wait(1)
        if Character and HumanoidRootPart then
            if not isInventoryFull() then
                if autoExtractActive then
                    pcall(function()
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if not autoExtractActive or isInventoryFull() then break end
                            if extractionNames[obj.Name] and isRealValveItem(obj) then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                                if part and not isElevatorNearby(part.Position, 15) then
                                    smartCollectItem(obj)
                                end
                            end
                        end
                    end)
                end

                if autoHealsActive then
                    pcall(function()
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if not autoHealsActive or isInventoryFull() then break end
                            if healNames[obj.Name] then
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                                if part and not isElevatorNearby(part.Position, 15) then
                                    smartCollectItem(obj)
                                end
                            end
                        end
                    end)
                end

                if autoPickUpTapesActive then
                    pcall(function()
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if not autoPickUpTapesActive or isInventoryFull() then break end
                            if obj.Name == "Tape" then
                                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                                    if part and not isElevatorNearby(part.Position, 15) then
                                        smartCollectItem(obj)
                                    end
                                end
                            end
                        end
                    end)
                end
            end

            if autoCollectActive then
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if not autoCollectActive then break end
                        if obj.Name == "ResearchCapsule" then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part and not isElevatorNearby(part.Position, 15) then
                                smartCollectItem(obj)
                            end
                        end
                    end
                end)
            end

            if autoCollectEventActive then
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if not autoCollectEventActive then break end
                        if eventCurrencyNames[obj.Name] then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part and not isElevatorNearby(part.Position, 15) then
                                smartCollectItem(obj)
                            end
                        end
                    end
                end)
            end
        end
    end
end)

local autoUseItemsEnabled = false
AutomationTab:CreateToggle({
    Name = "Auto Use Itens",
    CurrentValue = false,
    Flag = "AutoUseItemsToggle",
    Callback = function(v)
        autoUseItemsEnabled = v
    end
})

task.spawn(function()
    while true do
        if autoUseItemsEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Inventory") then
                    local inv = char.Inventory
                    for i = 1, 3 do
                        local slot = inv:FindFirstChild("Slot" .. tostring(i))
                        if slot and ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ItemEvent") then
                            ReplicatedStorage.Events.ItemEvent:InvokeServer(char, slot)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

local autoAbilityEnabled = false
AutomationTab:CreateToggle({
    Name = "Auto Use Ability",
    CurrentValue = false,
    Flag = "AutoAbilityToggle",
    Callback = function(v)
        autoAbilityEnabled = v
    end
})

task.spawn(function()
    while true do
        if autoAbilityEnabled then
            pcall(function()
                if Character and HumanoidRootPart and ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("AbilityEvent") then
                    ReplicatedStorage.Events.AbilityEvent:InvokeServer(Character, HumanoidRootPart.CFrame, false)
                end
            end)
        end
        task.wait(1.5)
    end
end)

AutomationTab:CreateButton({
    Name = "Auto Escape Squirm",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/refs/heads/main/auto%20struggle.lua"))()
        end)
    end
})

local EspTab = Window:CreateTab("Esp", 130098091866021)

EspTab:CreateSection("Twisteds ESP")

local twistedEspEnabled = false
local twistedDisableNametags = false
local activeTwistedMonsters = {}
local twistedConnection = nil

EspTab:CreateToggle({
    Name = "Twisted Esp",
    CurrentValue = false,
    Flag = "TwistedEspToggle",
    Callback = function(v)
        twistedEspEnabled = v

        local ColorChangingList = { ["GourdyMonster"] = true, ["BassieMonster"] = true, ["BobetteMonster"] = true, ["VeeMonster"] = true, ["DyleMonster"] = true, ["DandyMonster"] = true, ["AstroMonster"] = true, ["PebbleMonster"] = true, ["ShellyMonster"] = true, ["SproutMonster"] = true }
        local Colors = {
            Color3.fromRGB(30, 144, 255), Color3.fromRGB(65, 105, 225), Color3.fromRGB(135, 206, 250),
            Color3.fromRGB(148, 0, 211), Color3.fromRGB(138, 43, 226), Color3.fromRGB(186, 85, 211),
            Color3.fromRGB(255, 105, 180), Color3.fromRGB(255, 20, 147), Color3.fromRGB(255, 182, 193),
        }
        local CommonList = { ["BoxtenMonster"] = true, ["PoppyMonster"] = true, ["BrushaMonster"] = true, ["ShrimpoMonster"] = true, ["RudieMonster"] = true, ["EggsonMonster"] = true, ["RibeccaMonster"] = true, ["YattaMonster"] = true, ["TishaMonster"] = true, ["LooeyMonster"] = true, ["CosmoMonster"] = true }
        local UncommonList = { ["FinnMonster"] = true, ["TeaganMonster"] = true, ["RodgerMonster"] = true, ["RazzleDazzleMonster"] = true, ["SoulvesterMonster"] = true, ["GingerMonster"] = true, ["FlyteMonster"] = true, ["ConnieMonster"] = true, ["BrightneyMonster"] = true, ["ToodlesMonster"] = true }
        local RareList = { ["GigiMonster"] = true, ["ScrapsMonster"] = true, ["GoobMonster"] = true, ["WaxwellMonster"] = true, ["GlistenMonster"] = true, ["FlutterMonster"] = true, ["EclipseMonster"] = true, ["CocoaMonster"] = true, ["CoalMonster"] = true, ["SquirmMonster"] = true, ["BlottMonster"] = true }
        local BlotHandsList = { ["BlotHand"] = true, ["BlotHand_L"] = true, ["BlotHand_R"] = true }
        local MainList = { ["ShellyMonster"] = true, ["AstroMonster"] = true, ["PebbleMonster"] = true, ["VeeMonster"] = true, ["SproutMonster"] = true, ["BassieMonster"] = true, ["BobetteMonster"] = true, ["GourdyMonster"] = true }
        local LethalList = { ["DandyMonster"] = true, ["DyleMonster"] = true, ["DiodaMonster"] = true, ["DessaMonster"] = true, ["Dioda"] = true, ["Dessa"] = true }

        local EasterEventList = { ["CocoaMonster"] = true, ["BassieMonster"] = true, ["FlyteMonster"] = true, ["EggsonMonster"] = true }
        local EasterColors = {Color3.fromRGB(255, 255, 153), Color3.fromRGB(255, 153, 204)}
        local HalloweenEventList = { ["GourdyMonster"] = true, ["EclipseMonster"] = true, ["SoulvesterMonster"] = true, ["RibeccaMonster"] = true }
        local HalloweenColors = {Color3.fromRGB(148, 0, 211), Color3.fromRGB(255, 128, 0)}
        local XmasEventList = { ["BobetteMonster"] = true, ["CoalMonster"] = true, ["GingerMonster"] = true, ["RudieMonster"] = true }
        local XmasColors = {Color3.fromRGB(0, 204, 153), Color3.fromRGB(255, 51, 51)}
        local LethalColors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 0)}

        local AllMonsters = {}
        for k in pairs(CommonList) do AllMonsters[k] = true end
        for k in pairs(UncommonList) do AllMonsters[k] = true end
        for k in pairs(RareList) do AllMonsters[k] = true end
        for k in pairs(BlotHandsList) do AllMonsters[k] = true end
        for k in pairs(ColorChangingList) do AllMonsters[k] = true end
        for k in pairs(LethalList) do AllMonsters[k] = true end

        local function setupMonster(model)
            if not model or not model:IsA("Model") or model:FindFirstChild("ESP_Container") then return end

            local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
            if not head then return end

            local container = Instance.new("Folder")
            container.Name = "ESP_Container"
            container.Parent = model

            local highlight = Instance.new("Highlight")
            highlight.Adornee = model
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = container

            local billboard = Instance.new("BillboardGui", head)
            billboard.Name = "Nametag"
            billboard.Size = UDim2.new(0, 180, 0, 35)
            billboard.StudsOffset = Vector3.new(0, 4.2, 0)
            billboard.AlwaysOnTop = true
            billboard.Enabled = not twistedDisableNametags

            local textLabel = Instance.new("TextLabel", billboard)
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Enum.Font.FredokaOne
            textLabel.TextSize = 9
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

            local rarityText = ""
            local baseTextColor = Color3.fromRGB(255, 0, 0)

            if CommonList[model.Name] then rarityText = " | Common"; baseTextColor = Color3.fromRGB(180, 180, 180)
            elseif UncommonList[model.Name] then rarityText = " | Uncommon"; baseTextColor = Color3.fromRGB(50, 255, 50)
            elseif RareList[model.Name] then rarityText = " | Rare"; baseTextColor = Color3.fromRGB(100, 200, 255)
            elseif BlotHandsList[model.Name] then rarityText = ""; baseTextColor = Color3.fromRGB(100, 200, 255)
            elseif MainList[model.Name] then rarityText = " | Main" end

            if LethalList[model.Name] then rarityText = " | Lethal" end

            local rawName = BlotHandsList[model.Name] and "BlotHand" or model.Name:gsub("Monster", "")
            textLabel.Text = "Twisted " .. rawName .. rarityText

            table.insert(activeTwistedMonsters, billboard)

            task.spawn(function()
                local alpha = 0
                local colorIndex = math.random(#Colors)
                local nextIndex = math.random(#Colors)

                while twistedEspEnabled and model and model.Parent and highlight and highlight.Parent do
                    local dt = task.wait(0.05)
                    alpha = alpha + (dt / 1.0)
                    if alpha >= 1 then
                        alpha = 0
                        colorIndex = nextIndex
                        repeat nextIndex = math.random(#Colors) until nextIndex ~= colorIndex
                    end

                    local targetColor = baseTextColor
                    local pingPongAlpha = math.abs((tick() % 2) - 1)

                    if LethalList[model.Name] then
                        -- lethal: smooth rainbow
                        targetColor = Color3.fromHSV((tick() * 0.4) % 1, 1, 1)
                    elseif EasterEventList[model.Name] then
                        targetColor = EasterColors[1]:Lerp(EasterColors[2], pingPongAlpha)
                    elseif HalloweenEventList[model.Name] then
                        targetColor = HalloweenColors[1]:Lerp(HalloweenColors[2], pingPongAlpha)
                    elseif XmasEventList[model.Name] then
                        targetColor = XmasColors[1]:Lerp(XmasColors[2], pingPongAlpha)
                    elseif ColorChangingList[model.Name] then
                        local c1 = Colors[colorIndex]
                        local c2 = Colors[nextIndex]
                        targetColor = c1:Lerp(c2, alpha)
                    end

                    -- highlight fades slight purple -> dark blue -> back to purple
                    local fade = (math.sin(tick() * 2) + 1) / 2
                    local fadeColor = Color3.fromRGB(170, 120, 230):Lerp(Color3.fromRGB(10, 25, 110), fade)
                    highlight.FillColor = fadeColor
                    -- dioda and dessa also get a rainbow outline (same color as their nametag)
                    if model.Name == "DiodaMonster" or model.Name == "DessaMonster" or model.Name == "Dioda" or model.Name == "Dessa" then
                        highlight.OutlineColor = targetColor
                    end
                    textLabel.TextColor3 = targetColor
                end
            end)
        end

        if twistedEspEnabled then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and AllMonsters[obj.Name] then
                    setupMonster(obj)
                end
            end

            if twistedConnection then twistedConnection:Disconnect() end
            twistedConnection = Workspace.DescendantAdded:Connect(function(obj)
                if twistedEspEnabled and obj:IsA("Model") and AllMonsters[obj.Name] then
                    task.wait(0.1)
                    setupMonster(obj)
                end
            end)
        else
            if twistedConnection then
                twistedConnection:Disconnect()
                twistedConnection = nil
            end
            activeTwistedMonsters = {}
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "ESP_Container" or (obj.Name == "Nametag" and obj.Parent and obj.Parent:IsA("BasePart")) then
                    obj:Destroy()
                end
            end
        end
    end
})

EspTab:CreateToggle({
    Name = "Disable Twisted Esp Nametags",
    CurrentValue = false,
    Flag = "TwistedDisableNametagsToggle",
    Callback = function(v)
        twistedDisableNametags = v
        for _, tag in ipairs(activeTwistedMonsters) do
            if tag and tag.Parent then tag.Enabled = not twistedDisableNametags end
        end
    end
})

-- Sprout Tendril Esp
local sproutTendrilEspEnabled = false
local sproutTendrilDisableNametags = false -- ADICIONADO PARA CONTROLE
local activeSproutTendrilNametags = {}
local sproutTendrilConnection = nil

EspTab:CreateToggle({
    Name = "Sprout Tendril Esp",
    CurrentValue = false,
    Flag = "SproutTendrilEspToggle",
    Callback = function(v)
        sproutTendrilEspEnabled = v

        local function setupSproutTendril(obj)
            if not obj or obj.Name ~= "SproutTendril" or obj:FindFirstChild("SproutTendrilESP") then return end

            local folder = Instance.new("Folder")
            folder.Name = "SproutTendrilESP"
            folder.Parent = obj

            local highlight = Instance.new("Highlight")
            highlight.Name = "Chams"
            highlight.Adornee = obj
            highlight.FillColor = Color3.fromRGB(0, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = folder

            local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or (obj:IsA("BasePart") and obj)
            if part then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "Nametag"
                billboard.Adornee = part
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Enabled = not sproutTendrilDisableNametags -- APLICADO O TOGGLE DE DISABLE NAMETAGS

                table.insert(activeSproutTendrilNametags, billboard)
                billboard.Parent = folder

                local textLabel = Instance.new("TextLabel", billboard)
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = "Twisted Sprout Tendril"
                textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                textLabel.TextSize = 9
                textLabel.Font = Enum.Font.FredokaOne
                textLabel.TextStrokeTransparency = 0
                textLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            end
        end

        if sproutTendrilEspEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                setupSproutTendril(obj)
            end
            if sproutTendrilConnection then sproutTendrilConnection:Disconnect() end
            sproutTendrilConnection = workspace.DescendantAdded:Connect(function(obj)
                if sproutTendrilEspEnabled then
                    task.wait(0.1)
                    setupSproutTendril(obj)
                end
            end)
        else
            if sproutTendrilConnection then
                sproutTendrilConnection:Disconnect()
                sproutTendrilConnection = nil
            end
            activeSproutTendrilNametags = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                local espFolder = obj:FindFirstChild("SproutTendrilESP")
                if espFolder then espFolder:Destroy() end
            end
        end
    end
})

-- ADICIONADO O TOGGLE PARA DESATIVAR NAMETAGS DO SPROUT TENDRIL
EspTab:CreateToggle({
    Name = "Disable Sprout Tendril Nametags",
    CurrentValue = false,
    Flag = "SproutTendrilDisableNametagsToggle",
    Callback = function(v)
        sproutTendrilDisableNametags = v
        for _, tag in ipairs(activeSproutTendrilNametags) do
            if tag and tag.Parent then tag.Enabled = not sproutTendrilDisableNametags end
        end
    end
})

EspTab:CreateSection("Player ESP")

local playerEspEnabled = false
local playerDisableNametags = false
local activePlayerNametags = {}

local playerEspConn = nil

local function isTwistedModel(m)
    return TwistedMonsterNames[m.Name] == true or m.Name:match("Monster$") ~= nil
end

local function clearPlayerEsp()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "CustomChams" and obj:IsA("Highlight")) or (obj.Name == "CustomNametag" and obj:IsA("BillboardGui")) then
            obj:Destroy()
        end
    end
end

EspTab:CreateToggle({
    Name = "Player Esp",
    CurrentValue = false,
    Flag = "PlayerEspToggle",
    Callback = function(v)
        playerEspEnabled = v

        local COLOR_NORMAL_BLUE = Color3.fromRGB(0, 50, 150)
        local COLOR_LOW_BLUE = Color3.fromRGB(0, 30, 100)
        local COLOR_CRIT_BLUE = Color3.fromRGB(0, 15, 60)

        local COLOR_NORMAL_GREEN = Color3.fromRGB(0, 255, 0)
        local COLOR_LOW_GREEN = Color3.fromRGB(0, 180, 0)
        local COLOR_CRIT_GREEN = Color3.fromRGB(0, 100, 0)

        -- highlights every model that has a Humanoid (all players), skipping you and the Twisteds
        local function setupHumanoidModel(char)
            if not playerEspEnabled then return end
            if not char or not char:IsA("Model") then return end
            if char == LocalPlayer.Character then return end
            if isTwistedModel(char) then return end
            if char:FindFirstChild("CustomChams") then return end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            local owner = Players:GetPlayerFromCharacter(char)
            if not owner then
                local lowerName = char.Name:lower()
                if lowerName:find("dandy") or lowerName:find("dioda") or lowerName:find("dessa") or lowerName:find("ichorling") then return end
            end
            local displayName = owner and owner.Name or char.Name
            if playerBlacklist[displayName] then return end

            local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 2) or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart", true)
            if not head then return end

            if not playerEspEnabled or char:FindFirstChild("CustomChams") then return end

            local highlight = Instance.new("Highlight")
            highlight.Name = "CustomChams"
            highlight.Adornee = char
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = char

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "CustomNametag"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Enabled = not playerDisableNametags
            billboard.Parent = char

            table.insert(activePlayerNametags, billboard)

            local layout = Instance.new("UIListLayout", billboard)
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Center

            local nameLabel = Instance.new("TextLabel", billboard)
            nameLabel.Name = "NickLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 25)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = displayName
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 9
            nameLabel.Font = Enum.Font.FredokaOne
            nameLabel.TextStrokeTransparency = 0.5

            local healthLabel = Instance.new("TextLabel", billboard)
            healthLabel.Name = "HealthLabel"
            healthLabel.Size = UDim2.new(1, 0, 0, 25)
            healthLabel.BackgroundTransparency = 1
            healthLabel.TextSize = 9
            healthLabel.Font = Enum.Font.FredokaOne
            healthLabel.TextStrokeTransparency = 0.5

            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not playerEspEnabled or not char or not char.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 or playerBlacklist[displayName] then
                    if highlight then highlight:Destroy() end
                    if billboard then billboard:Destroy() end
                    if connection then connection:Disconnect() end
                    return
                end

                local currentHp = math.floor(humanoid.Health)
                healthLabel.Text = "Health: " .. currentHp

                if currentHp == 1 then
                    highlight.FillColor = COLOR_CRIT_BLUE; highlight.OutlineColor = COLOR_CRIT_BLUE; healthLabel.TextColor3 = COLOR_CRIT_GREEN
                elseif currentHp <= 2 then
                    highlight.FillColor = COLOR_LOW_BLUE; highlight.OutlineColor = COLOR_LOW_BLUE; healthLabel.TextColor3 = COLOR_LOW_GREEN
                else
                    highlight.FillColor = COLOR_NORMAL_BLUE; highlight.OutlineColor = COLOR_NORMAL_BLUE; healthLabel.TextColor3 = COLOR_NORMAL_GREEN
                end
            end)
        end

        if playerEspEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Humanoid") then
                    task.spawn(setupHumanoidModel, obj.Parent)
                end
            end

            if playerEspConn then playerEspConn:Disconnect() end
            playerEspConn = Workspace.DescendantAdded:Connect(function(obj)
                if playerEspEnabled and obj:IsA("Humanoid") then
                    task.wait(0.1)
                    setupHumanoidModel(obj.Parent)
                end
            end)
        else
            if playerEspConn then
                playerEspConn:Disconnect()
                playerEspConn = nil
            end
            activePlayerNametags = {}
            clearPlayerEsp()
        end
    end
})

EspTab:CreateToggle({
    Name = "Disable Player Esp Nametags",
    CurrentValue = false,
    Flag = "PlayerDisableNametagsToggle",
    Callback = function(v)
        playerDisableNametags = v
        for _, tag in ipairs(activePlayerNametags) do
            if tag and tag.Parent then tag.Enabled = not playerDisableNametags end
        end
    end
})

EspTab:CreateSection("Item ESP")

local itemEspEnabled = false
local itemDisableNametags = false
local activeItemNametags = {}
local itemConnection = nil

local itemMap = {
    AirHorn = "Air Horn", SmokeBomb = "Smoke Bomb", ResearchCapsule = "Research Capsule",
    ProteinBar = "Protein Bar", Jawbreaker = "Jawbreaker", EjectButton = "Eject Button",
    HealthKit = "MedKit", Bandage = "Bandage", Tape = "Tape", Instructions = "Instructions",
    ExtractionSpeedCandy = "Extraction Candy", SkillCheckCandy = "SkillCheck Candy",
    StaminaCandy = "Stamina Candy", StealthCandy = "Stealth Candy", SpeedCandy = "Speed Candy",
    Gumball = "Gumball", BonBon = "BonBon", Chocolate = "Chocolate", ChocolateBox = "Chocolate Box",
    Pop = "Pop", PopBottle = "Pop Bottle", JumperCable = "Jumper Cable", Stopwatch = "Stopwatch",
    ChristmasCookie = "Christmas Cookie", DandyEasterEggs = "Dandy Easter Eggs", Pumpkin = "Pumpkins",
    FakeCapsule = "Fake Capsule", Ornament = "Ornament", Basket = "Basket", DandCorn = "DandCorn",
    GlitterGlue = "Glitter Glue", Valve = "Valve", AlarmClock = "Alarm Clock", ExtraHeart = "Extra Heart",
    Ichorling = "Ichorling"
}

local cols = {
    ["Air Horn"] = Color3.fromRGB(255, 50, 50), ["Smoke Bomb"] = Color3.fromRGB(135, 206, 250),
    ["Research Capsule"] = Color3.fromRGB(0, 255, 0), ["Protein Bar"] = Color3.fromRGB(0, 100, 0),
    ["Jawbreaker"] = Color3.fromRGB(148, 0, 211), ["Eject Button"] = Color3.fromRGB(255, 255, 0),
    ["MedKit"] = Color3.fromRGB(255, 0, 127), ["Bandage"] = Color3.fromRGB(255, 20, 147),
    ["Tape"] = Color3.fromRGB(128, 128, 128), ["Instructions"] = Color3.fromRGB(148, 0, 211),
    ["Extraction Candy"] = Color3.fromRGB(148, 0, 211), ["Skill Check Candy"] = Color3.fromRGB(255, 140, 0),
    ["Stamina Candy"] = Color3.fromRGB(0, 100, 0), ["Stealth Candy"] = Color3.fromRGB(135, 206, 250),
    ["Speed Candy"] = Color3.fromRGB(255, 255, 0), ["Gumball"] = Color3.fromRGB(135, 206, 250),
    ["Bon Bon"] = Color3.fromRGB(255, 182, 193), ["Chocolate"] = Color3.fromRGB(255, 255, 0),
    ["Chocolate Box"] = Color3.fromRGB(255, 255, 0), ["Pop"] = Color3.fromRGB(0, 100, 0),
    ["Pop Bottle"] = Color3.fromRGB(255, 0, 0), ["Jumper Cable"] = Color3.fromRGB(148, 0, 211),
    ["Stopwatch"] = Color3.fromRGB(255, 255, 255), ["Christmas Cookie"] = Color3.fromRGB(255, 255, 0),
    ["Dandy Easter Eggs"] = Color3.fromRGB(255, 255, 0), ["Pumpkins"] = Color3.fromRGB(255, 140, 0),
    ["Ornament"] = Color3.fromRGB(132, 238, 178), ["Basket"] = Color3.fromRGB(255, 105, 180),
    ["Fake Capsule"] = Color3.fromRGB(255, 255, 0), ["DandCorn"] = Color3.fromRGB(255, 255, 0),
    ["Glitter Glue"] = Color3.fromRGB(255, 105, 230), ["Valve"] = Color3.fromRGB(255, 170, 40),
    ["Alarm Clock"] = Color3.fromRGB(255, 215, 90),
    ["Extra Heart"] = Color3.fromRGB(255, 60, 90),
    ["Ichorling"] = Color3.fromRGB(200, 60, 255)
}

-- an "Ichorling" only shows in Item ESP when it is not a humanoid and its health is 3
-- (health is read from a Health attribute, or a Health / HP number value inside it)
local watchedIchorlings = setmetatable({}, {__mode = "k"})

local function getIchorlingHealth(obj)
    for _, attrName in ipairs({"Health", "health", "HP"}) do
        local attr = obj:GetAttribute(attrName)
        if type(attr) == "number" then return attr end
    end
    for _, valueName in ipairs({"Health", "HP"}) do
        local v = obj:FindFirstChild(valueName, true)
        if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then return v.Value end
    end
    return nil
end

local function isTrackedIchorling(obj)
    if obj.Name ~= "Ichorling" then return true end
    if obj:IsA("Humanoid") or obj:FindFirstChildWhichIsA("Humanoid", true) then return false end
    return getIchorlingHealth(obj) == 3
end

local function applyItemESP(obj)
    if not obj or not itemMap[obj.Name] then return end
    if not isRealValveItem(obj) then return end

    if obj.Name == "Ichorling" then
        watchedIchorlings[obj] = true
        if not isTrackedIchorling(obj) then
            local stale = obj:FindFirstChild("ESP_Added")
            if stale then stale:Destroy() end
            return
        end
    end

    if itemBlacklist[obj.Name] then
        local added = obj:FindFirstChild("ESP_Added")
        if added then added:Destroy() end
        return
    end

    if obj.Name == "Tape" then
        local hasPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not hasPrompt then return end

        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant.Name == "Tape" and (descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("TextLabel")) then
                descendant:Destroy()
            end
        end
    end

    if obj.Name == "AlarmClock" then
        -- the clock can have a second "AlarmClock" nested inside it, which gave it two name tags:
        -- only the outermost one gets the ESP, and any tag already put on an inner one is removed
        if obj:FindFirstAncestor("AlarmClock") then return end
        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant.Name == "AlarmClock" then
                local inner = descendant:FindFirstChild("ESP_Added")
                if inner then inner:Destroy() end
            end
        end
    end

    if obj:FindFirstChild("ESP_Added") then return end

    local tagFolder = Instance.new("Folder")
    tagFolder.Name = "ESP_Added"
    tagFolder.Parent = obj

    local formattedName = itemMap[obj.Name]
    local monsterNameRaw = ""

    if obj.Name == "ResearchCapsule" then
        local promptFolder = obj:FindFirstChild("Prompt")
        if promptFolder then
            local monsterVal = promptFolder:FindFirstChild("Monster")
            if monsterVal then
                monsterNameRaw = tostring(monsterVal.Value):gsub("Monster", "")
                formattedName = "Research Capsule | Twisted " .. monsterNameRaw
            end
        end
    end

    local itemColor = cols[itemMap[obj.Name]] or Color3.fromRGB(255, 165, 0)

    local hi = Instance.new("Highlight")
    hi.Name = "ItemChams"
    hi.Adornee = obj
    hi.FillColor = itemColor
    hi.FillTransparency = 0.5
    hi.OutlineColor = itemColor
    hi.OutlineTransparency = 0
    hi.Parent = tagFolder

    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or (obj:IsA("BasePart") and obj)
    if part then
        local bb = Instance.new("BillboardGui")
        bb.Name = "ItemNametag"
        bb.Adornee = part
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = not itemDisableNametags
        bb.Parent = tagFolder

        table.insert(activeItemNametags, bb)

        local txt = Instance.new("TextLabel", bb)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = formattedName
        txt.TextColor3 = itemColor
        txt.TextSize = 9
        txt.Font = Enum.Font.FredokaOne
        txt.TextStrokeTransparency = 0
        txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

        local capsuleList1 = {["shelly"]=true, ["astro"]=true, ["vee"]=true, ["pebble"]=true, ["sprout"]=true}
        local capsuleList2 = {["ribecca"]=true, ["gourdy"]=true, ["soulvester"]=true, ["eclipse"]=true}
        local capsuleList3 = {["bobette"]=true, ["coal"]=true, ["ginger"]=true, ["rudie"]=true}
        local capsuleList4 = {["bassie"]=true, ["cocoa"]=true, ["eggson"]=true, ["flyte"]=true}
        local capsuleList5 = {["dandy"]=true, ["dyle"]=true, ["dioda"]=true, ["dessa"]=true}

        local mLower = monsterNameRaw:lower()

        -- same rarity colors the Twisted ESP uses, for Twisteds with no special fade
        local capsuleCommon = {["boxten"]=true, ["poppy"]=true, ["brusha"]=true, ["shrimpo"]=true, ["yatta"]=true, ["tisha"]=true, ["looey"]=true, ["cosmo"]=true}
        local capsuleUncommon = {["finn"]=true, ["teagan"]=true, ["rodger"]=true, ["razzledazzle"]=true, ["connie"]=true, ["brightney"]=true, ["toodles"]=true}
        local capsuleRare = {["gigi"]=true, ["scraps"]=true, ["goob"]=true, ["waxwell"]=true, ["glisten"]=true, ["flutter"]=true, ["squirm"]=true, ["blott"]=true}
        local capsuleBase = nil
        if capsuleCommon[mLower] then capsuleBase = Color3.fromRGB(180, 180, 180)
        elseif capsuleUncommon[mLower] then capsuleBase = Color3.fromRGB(50, 255, 50)
        elseif capsuleRare[mLower] then capsuleBase = Color3.fromRGB(100, 200, 255) end

        local colorsSet = {
            Color3.fromRGB(30,144,255), Color3.fromRGB(65,105,225), Color3.fromRGB(135,206,250),
            Color3.fromRGB(148,0,211), Color3.fromRGB(138,43,226), Color3.fromRGB(186,85,211),
            Color3.fromRGB(255,105,180), Color3.fromRGB(255,20,147), Color3.fromRGB(255,182,193),
        }
        local rbFrom, rbTo, rbStart = math.random(#colorsSet), math.random(#colorsSet), tick()

        task.spawn(function()
            while itemEspEnabled and obj and obj.Parent and hi and txt do
                local t = tick()
                if obj.Name == "Ichorling" and not isTrackedIchorling(obj) then
                    tagFolder:Destroy()
                    break
                end
                if capsuleList1[mLower] then
                    local alpha = (t - rbStart) / 1.0
                    if alpha >= 1 then
                        rbFrom = rbTo
                        repeat rbTo = math.random(#colorsSet) until rbTo ~= rbFrom
                        rbStart = t
                        alpha = 0
                    end
                    local lerped = colorsSet[rbFrom]:Lerp(colorsSet[rbTo], alpha)
                    hi.FillColor = lerped; hi.OutlineColor = lerped; txt.TextColor3 = lerped
                elseif capsuleList2[mLower] then
                    local c1, c2 = Color3.fromRGB(148,0,211), Color3.fromRGB(255,128,0)
                    local alpha = math.abs((t % 2) - 1)
                    local lerped = c1:Lerp(c2, alpha)
                    hi.FillColor = lerped; hi.OutlineColor = lerped; txt.TextColor3 = lerped
                elseif capsuleList3[mLower] then
                    local c1, c2 = Color3.fromRGB(0,204,153), Color3.fromRGB(255,51,51)
                    local alpha = math.abs((t % 2) - 1)
                    local lerped = c1:Lerp(c2, alpha)
                    hi.FillColor = lerped; hi.OutlineColor = lerped; txt.TextColor3 = lerped
                elseif capsuleList4[mLower] then
                    local c1, c2 = Color3.fromRGB(255,255,153), Color3.fromRGB(255,153,204)
                    local alpha = math.abs((t % 2) - 1)
                    local lerped = c1:Lerp(c2, alpha)
                    hi.FillColor = lerped; hi.OutlineColor = lerped; txt.TextColor3 = lerped
                elseif capsuleList5[mLower] then
                    local lerped = Color3.fromHSV((t * 0.4) % 1, 1, 1)
                    hi.FillColor = lerped; hi.OutlineColor = lerped; txt.TextColor3 = lerped
                elseif capsuleBase then
                    hi.FillColor = capsuleBase; hi.OutlineColor = capsuleBase; txt.TextColor3 = capsuleBase
                elseif obj.Name == "AlarmClock" then
                    -- the name text cycles through the rainbow (the highlight keeps its own color)
                    txt.TextColor3 = Color3.fromHSV((t * 0.4) % 1, 1, 1)
                elseif obj.Name == "ExtraHeart" then
                    -- the name text and the highlight fade blue -> green -> cyan -> back to blue
                    local heartColors = {Color3.fromRGB(40,120,255), Color3.fromRGB(50,255,100), Color3.fromRGB(0,255,255)}
                    local pos = (t * 0.6) % #heartColors
                    local i = math.floor(pos)
                    local heartColor = heartColors[i + 1]:Lerp(heartColors[(i + 1) % #heartColors + 1], pos - i)
                    hi.FillColor = heartColor; hi.OutlineColor = heartColor; txt.TextColor3 = heartColor
                else
                    local c1, c2 = nil, nil
                    if obj.Name == "HealthKit" or obj.Name == "Bandage" then
                        c1, c2 = Color3.fromRGB(255, 105, 180), Color3.fromRGB(255, 0, 0)
                    elseif obj.Name == "ChocolateBox" or obj.Name == "BoxOfChocolates" then
                        c1, c2 = Color3.fromRGB(0, 100, 0), Color3.fromRGB(255, 255, 0)
                    elseif obj.Name == "PopBottle" or obj.Name == "BottleOfPop" then
                        c1, c2 = Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 100, 0)
                    elseif obj.Name == "SmokeBomb" then
                        c1, c2 = Color3.fromRGB(148, 0, 211), Color3.fromRGB(135, 206, 250)
                    elseif obj.Name == "Pumpkin" then
                        c1, c2 = Color3.fromRGB(255, 140, 0), Color3.fromRGB(148, 0, 211)
                    elseif obj.Name == "Ornament" then
                        c1, c2 = Color3.fromRGB(132, 238, 178), Color3.fromRGB(255, 51, 51)
                    elseif obj.Name == "Basket" then
                        c1, c2 = Color3.fromRGB(255, 182, 193), Color3.fromRGB(255, 255, 204)
                    end
                    if c1 and c2 then
                        local alpha = math.abs(((t / 2) % 2) - 1)
                        local lerpedColor = c1:Lerp(c2, alpha)
                        hi.FillColor = lerpedColor; hi.OutlineColor = lerpedColor; txt.TextColor3 = lerpedColor
                    end
                end
                if mLower ~= "" then
                    -- research capsules: highlight fill fades slight purple -> dark blue -> back, like the Twisted ESP
                    local fade = (math.sin(t * 2) + 1) / 2
                    local fadeColor = Color3.fromRGB(170, 120, 230):Lerp(Color3.fromRGB(10, 25, 110), fade)
                    hi.FillColor = fadeColor
                    hi.OutlineColor = fadeColor
                end
                task.wait((mLower ~= "" or obj.Name == "AlarmClock" or obj.Name == "ExtraHeart") and 0.05 or 0.15)
            end
        end)
    end
end

EspTab:CreateToggle({
    Name = "Item Esp",
    CurrentValue = false,
    Flag = "ItemEspToggle",
    Callback = function(v)
        itemEspEnabled = v
        if itemEspEnabled then
            for _, o in ipairs(workspace:GetDescendants()) do
                applyItemESP(o)
            end

            if itemConnection then itemConnection:Disconnect() end
            itemConnection = workspace.DescendantAdded:Connect(function(o)
                if itemEspEnabled then
                    task.wait(0.1)
                    applyItemESP(o)
                end
            end)

            -- ichorlings change health over time, so re-check the ones we've seen once a second
            task.spawn(function()
                while itemEspEnabled do
                    for o in pairs(watchedIchorlings) do
                        if not o.Parent then
                            watchedIchorlings[o] = nil
                        elseif not o:FindFirstChild("ESP_Added") then
                            applyItemESP(o)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            if itemConnection then
                itemConnection:Disconnect()
                itemConnection = nil
            end
            activeItemNametags = {}
            for _, o in ipairs(workspace:GetDescendants()) do
                local added = o:FindFirstChild("ESP_Added")
                if added then added:Destroy() end
            end
        end
    end
})

EspTab:CreateToggle({
    Name = "Disable Item Esp Nametags",
    CurrentValue = false,
    Flag = "ItemDisableNametagsToggle",
    Callback = function(v)
        itemDisableNametags = v
        for _, tag in ipairs(activeItemNametags) do
            if tag and tag.Parent then
                tag.Enabled = not itemDisableNametags
            end
        end
    end
})

EspTab:CreateSection("Machine ESP")

local generatorEspEnabled = false
local generatorDisableNametags = false
local activeGeneratorNametags = {}
local generatorConn = nil

local function isMachineCompleted(model)
    local stats = model:FindFirstChild("Stats") or (model.Parent and model.Parent:FindFirstChild("Stats"))
    if stats then
        local completed = stats:FindFirstChild("Completed")
        if completed and completed.Value == true then
            return true
        end
    end
    return false
end

EspTab:CreateToggle({
    Name = "Machine Esp",
    CurrentValue = false,
    Flag = "GeneratorEspToggle",
    Callback = function(v)
        generatorEspEnabled = v
        if generatorEspEnabled then
            local ignoredNames = {
                ["VendingMachine"] = true, ["Cooking_ExpressoMachine"] = true,
                ["DanceMachine"] = true, ["Gachapon_Arcade_01"] = true,
                ["Gachapon_Arcade_02"] = true, ["Gachapon_Arcade_03"] = true
            }

            local function applyESP(model)
                if not model or not model:IsA("Model") or ignoredNames[model.Name] or model.Name == "BaseMachine" or model.Name == "BaseMachine_Mirror" or model:FindFirstChild("CustomESP") then return end

                local nameLower = model.Name:lower()
                local isMachine = (nameLower == "generator" or nameLower == "generators" or nameLower:find("generator") or nameLower:find("dual_generator") or nameLower:find("dualgen") or nameLower:find("machine") or nameLower:find("trickortreatgen"))
                if not isMachine then return end

                local hasPrompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not hasPrompt then return end

                if isMachineCompleted(model) then return end

                local folder = Instance.new("Folder")
                folder.Name = "CustomESP"
                folder.Parent = model

                local highlight = Instance.new("Highlight")
                highlight.Name = "Chams"
                highlight.Adornee = model
                highlight.FillColor = Color3.fromRGB(80, 80, 80)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.4
                highlight.OutlineTransparency = 0
                highlight.Parent = folder

                local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "Nametag"
                    billboard.Adornee = part
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Enabled = not generatorDisableNametags
                    billboard.Parent = folder

                    table.insert(activeGeneratorNametags, billboard)

                    local textLabel = Instance.new("TextLabel", billboard)
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Text = "Machine | 0/0"
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.TextSize = 9
                    textLabel.Font = Enum.Font.FredokaOne
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

                    task.spawn(function()
                        while generatorEspEnabled and model and model.Parent and folder and folder.Parent do
                            if model.Name == "BaseMachine" or model.Name == "BaseMachine_Mirror" or isMachineCompleted(model) then
                                folder:Destroy()
                                break
                            end

                            local stats = model:FindFirstChild("Stats")
                            local reqValObj = (stats and stats:FindFirstChild("RequiredAmount")) or model:FindFirstChild("RequiredAmount", true)
                            local curValObj = (stats and stats:FindFirstChild("CurrentAmount")) or model:FindFirstChild("CurrentAmount", true)
                            local compValObj = (stats and stats:FindFirstChild("Completed")) or model:FindFirstChild("Completed", true)

                            local reqAmt = reqValObj and reqValObj.Value or 0
                            local curAmt = curValObj and curValObj.Value or 0
                            local isCompleted = compValObj and compValObj.Value == true

                            if isCompleted then
                                folder:Destroy()
                                local bm = workspace:FindFirstChild("BaseMachine", true)
                                if bm and bm:FindFirstChild("CustomESP") then bm.CustomESP:Destroy() end
                                local bmm = workspace:FindFirstChild("BaseMachine_Mirror", true)
                                if bmm and bmm:FindFirstChild("CustomESP") then bmm.CustomESP:Destroy() end
                                break
                            end

                            local simpleCurAmt = math.floor(tonumber(curAmt) or 0)
                            local simpleReqAmt = math.floor(tonumber(reqAmt) or 0)

                            -- ActivePlayer & ActivePlayer2 verification ADICIONADO
                            local activePlayerVal = stats and stats:FindFirstChild("ActivePlayer")
                            local activePlayer2Val = stats and stats:FindFirstChild("ActivePlayer2")
                            
                            local isBeingExtracted = (activePlayerVal and activePlayerVal.Value ~= nil and activePlayerVal.Value ~= "" and activePlayerVal.Value ~= "None") or
                                                     (activePlayer2Val and activePlayer2Val.Value ~= nil and activePlayer2Val.Value ~= "" and activePlayer2Val.Value ~= "None")

                            local connieVal = model:FindFirstChild("Connie", true)
                            if connieVal and connieVal.Value == true then
                                highlight.FillColor = Color3.fromRGB(135, 206, 250)
                                highlight.OutlineColor = Color3.fromRGB(135, 206, 250)
                                textLabel.TextColor3 = Color3.fromRGB(135, 206, 250)
                                textLabel.Text = "Possesed Machine"
                            elseif isBeingExtracted then
                                highlight.FillColor = Color3.fromRGB(20, 20, 20)
                                highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                                highlight.FillTransparency = 0.7
                                textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                                textLabel.Text = "Machine | " .. tostring(simpleCurAmt) .. "/" .. tostring(simpleReqAmt) .. "\nGetting Extracted.."
                            else
                                highlight.FillColor = Color3.fromRGB(80, 80, 80)
                                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                highlight.FillTransparency = 0.4
                                textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                textLabel.Text = "Machine | " .. tostring(simpleCurAmt) .. "/" .. tostring(simpleReqAmt)
                            end

                            task.wait(0.2)
                        end
                    end)
                end
            end

            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") then applyESP(obj) end
            end

            if not generatorConn then
                generatorConn = workspace.DescendantAdded:Connect(function(obj)
                    if generatorEspEnabled and obj:IsA("Model") then
                        task.wait(0.1)
                        if obj.Name == "BaseMachine" or obj.Name == "BaseMachine_Mirror" then
                            local custom = obj:FindFirstChild("CustomESP")
                            if custom then custom:Destroy() end
                        else
                            applyESP(obj)
                        end
                    end
                end)
            end
        else
            if generatorConn then
                generatorConn:Disconnect()
                generatorConn = nil
            end
            activeGeneratorNametags = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local custom = obj:FindFirstChild("CustomESP")
                    if custom then custom:Destroy() end
                end
            end
        end
    end
})

EspTab:CreateToggle({
    Name = "Disable Machine Esp Nametags",
    CurrentValue = false,
    Flag = "GeneratorDisableNametagsToggle",
    Callback = function(v)
        generatorDisableNametags = v
        for _, tag in ipairs(activeGeneratorNametags) do
            if tag and tag.Parent then tag.Enabled = not generatorDisableNametags end
        end
    end
})

EspTab:CreateSection("More ESP")

local function createKeywordEsp(toggleName, flag, color, matches)
    local enabled = false
    local tracked = {}
    local conn = nil

    local function insideTracked(obj)
        local p = obj.Parent
        while p and p ~= workspace do
            if tracked[p] then return true end
            p = p.Parent
        end
        return false
    end

    local function addEsp(obj)
        if not enabled or tracked[obj] then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        if not matches(obj) then return end
        if insideTracked(obj) then return end

        local adornee = obj
        if obj:IsA("Model") then
            adornee = obj:FindFirstChild("Head") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        if not adornee then return end

        local hi = Instance.new("Highlight")
        hi.Name = "AstroExtraESP"
        hi.Adornee = obj
        hi.FillColor = color
        hi.OutlineColor = color
        hi.FillTransparency = 0.5
        hi.OutlineTransparency = 0
        hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hi.Parent = obj

        local bb = Instance.new("BillboardGui")
        bb.Name = "AstroExtraESPTag"
        bb.Adornee = adornee
        bb.Size = UDim2.new(0, 180, 0, 24)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = obj

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = obj.Name
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.4
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.Parent = bb

        tracked[obj] = {hi = hi, bb = bb}
    end

    EspTab:CreateToggle({
        Name = toggleName,
        CurrentValue = false,
        Flag = flag,
        Callback = function(v)
            enabled = v
            if v then
                for _, o in ipairs(workspace:GetDescendants()) do addEsp(o) end
                if conn then conn:Disconnect() end
                conn = workspace.DescendantAdded:Connect(function(o)
                    task.wait(0.1)
                    addEsp(o)
                end)
                task.spawn(function()
                    while enabled do
                        for obj, d in pairs(tracked) do
                            if not obj.Parent then
                                d.hi:Destroy(); d.bb:Destroy()
                                tracked[obj] = nil
                            end
                        end
                        task.wait(1)
                    end
                end)
            else
                if conn then conn:Disconnect(); conn = nil end
                for _, d in pairs(tracked) do
                    d.hi:Destroy(); d.bb:Destroy()
                end
                tracked = {}
            end
        end
    })
end

createKeywordEsp("Star Pillow ESP", "StarPillowEspToggle", Color3.fromRGB(255, 230, 90), function(o)
    local n = o.Name:lower()
    return n:find("starpillow", 1, true) ~= nil or n:find("star pillow", 1, true) ~= nil
end)

createKeywordEsp("Ichorling ESP", "IchorlingEspToggle", Color3.fromRGB(200, 60, 255), function(o)
    return o.Name:lower():find("ichorling", 1, true) ~= nil
end)

createKeywordEsp("Ichor Flask ESP", "IchorFlaskEspToggle", Color3.fromRGB(255, 120, 60), function(o)
    return o.Name:lower() == "beaker_ichorlow"
end)

EspTab:CreateSection("Esp Blacklist")

local itemBlacklistOptions = {
    "Jawbreaker", "JumperCable", "ExtractionSpeedCandy", "SkillCheckCandy", "HealthKit",
    "Bandage", "SpeedCandy", "StealthCandy", "StaminaCandy", "ProteinBar", "Tape",
    "SmokeBomb", "Instructions", "AirHorn", "Gumball", "PopBottle", "Pop", "Chocolate",
    "ChocolateBox", "DandyEasterEggs", "ChristmasCookie", "FakeCapsule", "BonBon",
    "ResearchCapsule", "EjectButton", "Stopwatch", "Ornament", "Pumpkins", "Basket", "GlitterGlue", "Valve", "AlarmClock", "ExtraHeart", "Ichorling"
}

EspTab:CreateDropdown({
    Name = "Item Esp Blacklist",
    Options = itemBlacklistOptions,
    MultiSelect = true,
    CurrentOption = {},
    Flag = "ItemEspBlacklistDropdown",
    Callback = function(selectedMap)
        itemBlacklist = selectedMap or {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if itemBlacklist[obj.Name] then
                local added = obj:FindFirstChild("ESP_Added")
                if added then added:Destroy() end
            elseif itemEspEnabled then
                applyItemESP(obj)
            end
        end
    end
})

local function getOtherPlayersNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

local playerDropdown = EspTab:CreateDropdown({
    Name = "Player Esp Blacklist",
    Options = getOtherPlayersNames(),
    MultiSelect = true,
    CurrentOption = {},
    Flag = "PlayerEspBlacklistDropdown",
    Callback = function(selectedMap)
        playerBlacklist = selectedMap or {}
        for _, p in ipairs(Players:GetPlayers()) do
            if playerBlacklist[p.Name] and p.Character then
                if p.Character:FindFirstChild("CustomChams") then p.Character.CustomChams:Destroy() end
                if p.Character:FindFirstChild("CustomNametag") then p.Character.CustomNametag:Destroy() end
            end
        end
    end
})

Players.PlayerAdded:Connect(function()
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown.Refresh(getOtherPlayersNames())
    end
end)

Players.PlayerRemoving:Connect(function()
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown.Refresh(getOtherPlayersNames())
    end
end)

local TeleportTab = Window:CreateTab("Teleport", 122323156868835)

TeleportTab:CreateButton({ Name = "Teleport To Elevator", Callback = function()
    if not Character or not HumanoidRootPart then return end
    local elevatorsFolder = Workspace:FindFirstChild("Elevators")
    local targetPos = nil
    if elevatorsFolder then
        local elevator = elevatorsFolder:FindFirstChild("Elevator") or elevatorsFolder:FindFirstChildOfClass("Model")
        if elevator then
            local part = elevator.PrimaryPart or elevator:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPos = part.Position end
        end
    end
    if not targetPos then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Elevator" or obj.Name == "ElevatorDoor" then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or (obj:IsA("BasePart") and obj)
                if part then targetPos = part.Position; break end
            end
        end
    end
    if targetPos then
        if isTwistedNearby(targetPos, 30) then
            Rayfield:Notify({ Title = "Teleport", Content = "Twisted Nearby.", Duration = 2 })
            return
        end
        HumanoidRootPart.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
    else
        teleportTo("elevator", false)
    end
end })

TeleportTab:CreateButton({
    Name = "Teleport To Machine",
    Callback = function()
        performTeleportToMachine()
    end
})

local screenGuiButton = nil

TeleportTab:CreateToggle({
    Name = "Teleport To Machine Button",
    CurrentValue = false,
    Flag = "TpMachineButtonToggle",
    Callback = function(v)
        if v then
            if not screenGuiButton then
                local sg = Instance.new("ScreenGui")
                sg.Name = "TpMachineButtonGui"
                sg.ResetOnSpawn = false

                local parentGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                pcall(function()
                    if gethui then
                        parentGui = gethui()
                    elseif game:GetService("CoreGui") then
                        parentGui = game:GetService("CoreGui")
                    end
                end)
                sg.Parent = parentGui

                local imgButton = Instance.new("ImageButton")
                imgButton.Name = "TpMachineBtn"
                imgButton.Size = UDim2.new(0, 65, 0, 65)
                imgButton.Position = UDim2.new(0.85, 0, 0.5, 0)
                imgButton.BackgroundTransparency = 1
                imgButton.Image = "rbxassetid://123753414381011"
                imgButton.ScaleType = Enum.ScaleType.Fit
                imgButton.Active = true
                imgButton.Draggable = true
                imgButton.Parent = sg

                imgButton.MouseButton1Down:Connect(function()
                    imgButton.Size = UDim2.new(0, 58, 0, 58)
                end)

                imgButton.MouseButton1Up:Connect(function()
                    imgButton.Size = UDim2.new(0, 65, 0, 65)
                end)

                onTap(imgButton, function()
                    performTeleportToMachine()
                end)

                screenGuiButton = sg
            end
        else
            if screenGuiButton then
                screenGuiButton:Destroy()
                screenGuiButton = nil
            end
        end
    end
})

TeleportTab:CreateSection("Items Teleport")
local itemsList = {"AirHorn", "SmokeBomb", "ResearchCapsule", "ProteinBar", "Jawbreaker", "EjectButton", "HealthKit", "Bandage", "Tape", "Instructions", "ExtractionSpeedCandy", "SkillCheckCandy", "StaminaCandy", "StealthCandy", "SpeedCandy", "Gumball", "BonBon", "Chocolate", "ChocolateBox", "Pop", "PopBottle", "JumperCable", "Stopwatch", "ChristmasCookie", "DandyEasterEggs", "Pumpkin", "Ornament", "Basket", "FakeCapsule", "GlitterGlue", "Valve", "AlarmClock", "ExtraHeart"}
local selectedItem = itemsList[1]
TeleportTab:CreateDropdown({ Name = "Select Your Item", Options = itemsList, CurrentOption = {itemsList[1]}, Flag = "SelectedItemTp", Callback = function(opt) selectedItem = type(opt) == "table" and opt[1] or opt end })
TeleportTab:CreateButton({ Name = "Teleport to Selected Item", Callback = function() teleportTo(selectedItem, true) end })

local PlayerTab = Window:CreateTab("Player", 73824491911988)

local adPopupsBlockEnabled = false
local popUpEventConnection = nil

PlayerTab:CreateToggle({
    Name = "Anti Twisted Vee Popup",
    CurrentValue = false,
    Flag = "TwistedVeeAdPopupsBlockToggle",
    Callback = function(v)
        adPopupsBlockEnabled = v
        if adPopupsBlockEnabled then
            pcall(function()
                local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                if eventsFolder then
                    local popUpEvent = eventsFolder:FindFirstChild("PopUpEvent")
                    if popUpEvent and getconnections then
                        for _, conn in ipairs(getconnections(popUpEvent.OnClientEvent)) do
                            conn:Disable()
                        end
                    end
                end
            end)

            if not popUpEventConnection then
                popUpEventConnection = ReplicatedStorage.DescendantAdded:Connect(function(descendant)
                    if adPopupsBlockEnabled and descendant.Name == "PopUpEvent" and descendant:IsA("RemoteEvent") then
                        pcall(function()
                            for _, conn in ipairs(getconnections(descendant.OnClientEvent)) do
                                conn:Disable()
                            end
                        end)
                    end
                end)
            end
        else
            if popUpEventConnection then
                popUpEventConnection:Disconnect()
                popUpEventConnection = nil
            end
            pcall(function()
                local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                if eventsFolder then
                    local popUpEvent = eventsFolder:FindFirstChild("PopUpEvent")
                    if popUpEvent and getconnections then
                        for _, conn in ipairs(getconnections(popUpEvent.OnClientEvent)) do
                            conn:Enable()
                        end
                    end
                end
            end)
        end
    end
})

local noSlipperyEnabled = false
local defaultPhysicalProperties = {}
local brakeConnection = nil

PlayerTab:CreateToggle({
    Name = "No Slippery",
    CurrentValue = false,
    Flag = "NoSlipperyToggle",
    Callback = function(v)
        noSlipperyEnabled = v
        local char = LocalPlayer.Character

        if noSlipperyEnabled then
            local physicalProperties = PhysicalProperties.new(15.0, 3.0, 0.0, 1.0, 1.0)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if not defaultPhysicalProperties[part] then defaultPhysicalProperties[part] = part.CustomPhysicalProperties end
                        part.CustomPhysicalProperties = physicalProperties
                    end
                end
            end

            if not brakeConnection then
                brakeConnection = RunService.RenderStepped:Connect(function(dt)
                    if not noSlipperyEnabled then return end
                    local currentCharacter = LocalPlayer.Character
                    if not currentCharacter then return end

                    local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
                    local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")

                    if humanoid and rootPart and humanoid.Health > 0 then
                        local velocity = rootPart.AssemblyLinearVelocity
                        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
                        if humanoid.MoveDirection.Magnitude == 0 and horizontalVelocity.Magnitude > 0.5 then
                            local brakeFactor = math.clamp(dt * 25, 0, 1)
                            rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X * (1 - brakeFactor), velocity.Y, velocity.Z * (1 - brakeFactor))
                        end
                    end
                end)
            end
        else
            if brakeConnection then brakeConnection:Disconnect(); brakeConnection = nil end
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CustomPhysicalProperties = defaultPhysicalProperties[part]
                    end
                end
            end
            defaultPhysicalProperties = {}
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    if noSlipperyEnabled then
        task.delay(1, function()
            if noSlipperyEnabled and char then
                local physicalProperties = PhysicalProperties.new(15.0, 3.0, 0.0, 1.0, 1.0)
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CustomPhysicalProperties = physicalProperties end
                end
            end
        end)
    end
end)

local itemAuraEnabled = false
PlayerTab:CreateToggle({
    Name = "Item Aura",
    CurrentValue = false,
    Flag = "ItemAuraToggle",
    Callback = function(v)
        itemAuraEnabled = v
    end
})

task.spawn(function()
    while true do
        if itemAuraEnabled and HumanoidRootPart then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local parentPart = obj.Parent
                        if parentPart then
                            local promptPos = parentPart:IsA("BasePart") and parentPart.Position or (parentPart:IsA("Model") and (parentPart.PrimaryPart and parentPart.PrimaryPart.Position or parentPart:GetPivot().Position))
                            if promptPos then
                                if (promptPos - HumanoidRootPart.Position).Magnitude <= (obj.MaxActivationDistance or 15) then
                                    local isForbidden = false
                                    local currentAncestor = parentPart
                                    while currentAncestor and currentAncestor ~= workspace do
                                        if currentAncestor.Name == "GourdyMonster" or currentAncestor.Name == "FakeCapsule" then
                                            isForbidden = true
                                            break
                                        end
                                        currentAncestor = currentAncestor.Parent
                                    end

                                    local isNearElevator = isElevatorNearby(promptPos, 15)

                                    if not isForbidden and not isNearElevator and canInteractWithPosition(promptPos) then
                                        fireproximityprompt(obj)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        else
            task.wait(0.25)
        end
    end
end)

-- Infinite Stamina Toggle Integration
local infStaminaEnabled = false
local infStaminaConnections = {}

PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStaminaToggle",
    Callback = function(state)
        infStaminaEnabled = state
        if infStaminaEnabled then
            pcall(function()
                local plrsrv = game:GetService("Players")
                local replicated = game:GetService("ReplicatedStorage")
                local userinputservice = game:GetService("UserInputService")
                local plr = plrsrv.LocalPlayer
                local localcharacter = plr.Character or plr.CharacterAdded:Wait()
                local plrgui = plr:WaitForChild("PlayerGui")
                local screengui = plrgui:FindFirstChild("ScreenGui")

                local sprintevent = replicated.Events:WaitForChild("SprintEvent")
                local updateEnabled = false
                local sprinting = localcharacter:WaitForChild("Stats"):WaitForChild("Sprinting")
                local humanoid = localcharacter:WaitForChild("Humanoid")

                local serversidesprint = nil

                local function applySprintSpeed()
                    if updateEnabled then
                        local maxSpeed = plr:GetAttribute("KM_MAX_PLAYER_SPEED")
                        if maxSpeed then
                            humanoid.WalkSpeed = maxSpeed
                        end
                        sprinting.Value = true
                    end
                end

                local conn1 = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    if updateEnabled then
                        local maxSpeed = plr:GetAttribute("KM_MAX_PLAYER_SPEED")
                        if maxSpeed and humanoid.WalkSpeed < maxSpeed and humanoid.WalkSpeed > 0 then
                            task.defer(function()
                                if updateEnabled then
                                    humanoid.WalkSpeed = maxSpeed
                                end
                            end)
                        end
                    end
                end)
                table.insert(infStaminaConnections, conn1)

                local function enablelooprunspeed()
                    updateEnabled = true
                    applySprintSpeed()
                end

                local function disablelooprunspeed()
                    updateEnabled = false
                    humanoid.WalkSpeed = 16 
                    sprinting.Value = false
                end

                for i, connection in pairs(getconnections(sprintevent.OnClientEvent)) do
                    connection:Disable()
                end

                local conn2 = sprintevent.OnClientEvent:Connect(function(arg1)
                    serversidesprint = false
                    enablelooprunspeed()
                end)
                table.insert(infStaminaConnections, conn2)

                if screengui and screengui:FindFirstChild("MobileRun") then
                    for i, connection in pairs(getconnections(screengui.MobileRun.Activated)) do
                        connection:Disable()
                    end

                    local conn3 = screengui.MobileRun.Activated:Connect(function()
                        if screengui.MobileRun.TextLabel.Text == "SPRINT: OFF" then
                            screengui.MobileRun.TextLabel.Text = "SPRINT: ON"
                            screengui.MobileRun.Image = "rbxassetid://11866539249"
                            sprintevent:FireServer(true)
                            serversidesprint = true
                            screengui.SprintIcon.Visible = false
                            enablelooprunspeed()
                            return
                        end
                        disablelooprunspeed()
                        screengui.MobileRun.TextLabel.Text = "SPRINT: OFF"
                        screengui.MobileRun.Image = "rbxassetid://11866517702"
                        screengui.SprintIcon.Visible = false
                        sprintevent:FireServer(false)
                        serversidesprint = false
                    end)
                    table.insert(infStaminaConnections, conn3)
                end

                local isprocessed = false
                local conn4 = userinputservice.InputBegan:Connect(function(inputobj, processevent)
                    if processevent then return end
                    if inputobj.KeyCode == Enum.KeyCode.ButtonR1 or inputobj.KeyCode == Enum.KeyCode.LeftShift then
                        if inputobj.KeyCode == Enum.KeyCode.ButtonR1 and isprocessed then return end
                        enablelooprunspeed()
                        serversidesprint = true
                        if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then isprocessed = true end
                        if inputobj.KeyCode == Enum.KeyCode.LeftShift then sprintevent:FireServer(true) end
                    end
                end)
                table.insert(infStaminaConnections, conn4)

                local conn5 = userinputservice.InputEnded:Connect(function(inputobj, processevent)
                    if processevent then return end
                    if inputobj.KeyCode == Enum.KeyCode.ButtonR1 or inputobj.KeyCode == Enum.KeyCode.LeftShift then
                        disablelooprunspeed()
                        sprintevent:FireServer(false)
                        serversidesprint = false
                        if inputobj.KeyCode == Enum.KeyCode.ButtonR1 then isprocessed = false end
                    end
                end)
                table.insert(infStaminaConnections, conn5)
            end)
        else
            for _, conn in ipairs(infStaminaConnections) do
                pcall(function() conn:Disconnect() end)
            end
            infStaminaConnections = {}
            pcall(function()
                if Humanoid then Humanoid.WalkSpeed = 16 end
            end)
        end
    end
})

local infiniteRangeEnabled = false
local originalRadius = setmetatable({}, {__mode = "k"})

local function applyInfiniteRange(on)
    pcall(function()
        local toonsTable = {Shelly = true, Sprout = true, Cosmo = true, Scraps = true, Glisten = true}
        for _, conn in pairs(getconnections(RunService.RenderStepped)) do
            local func = conn.Function
            if func then
                local ok, upvals = pcall(getupvalues, func)
                if ok and upvals then
                    for _, val in pairs(upvals) do
                        if typeof(val) == "table" and val.Name and toonsTable[val.Name] and val.PlayerRadius then
                            if on then
                                if originalRadius[val] == nil then originalRadius[val] = val.PlayerRadius end
                                val.PlayerRadius = 500
                            elseif originalRadius[val] ~= nil then
                                val.PlayerRadius = originalRadius[val]
                                originalRadius[val] = nil
                            end
                        end
                    end
                end
            end
        end
    end)
end

PlayerTab:CreateToggle({
    Name = "Ability Infinite Range",
    CurrentValue = false,
    Flag = "AbilityInfiniteRangeToggle",
    Callback = function(v)
        infiniteRangeEnabled = v
        applyInfiniteRange(v)
    end
})

task.spawn(function()
    while true do
        if infiniteRangeEnabled then
            applyInfiniteRange(true)
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

PlayerTab:CreateSection("movement", true)

local speedValue, speedEnabled = 16, false
local tpWalkSpeed, tpWalkEnabled = 0.1, false

PlayerTab:CreateSlider({
    Name = "Speed",
    Range = {16, 30},
    Increment = 1,
    CurrentValue = 16,
    Flag = "PlayerSpeed",
    Toggle = true,
    Callback = function(v, on)
        speedValue = v
        speedEnabled = on
        if Humanoid then
            Humanoid.WalkSpeed = on and v or 16
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        if Value then
            applyNoclip()
            if not NoclipConnection then
                NoclipConnection = RunService.Stepped:Connect(function()
                    local character = LocalPlayer.Character
                    if character then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
            end
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Tpwalk Speed",
    Range = {0.1, 0.3},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "TPWalkSpeed",
    Toggle = true,
    Callback = function(v, on)
        tpWalkSpeed = v
        tpWalkEnabled = on
    end,
})

RunService.RenderStepped:Connect(function(delta)
    if speedEnabled and Humanoid and Humanoid.WalkSpeed ~= speedValue then
        Humanoid.WalkSpeed = speedValue
    end
    if tpWalkEnabled and Character and HumanoidRootPart and Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + (Humanoid.MoveDirection * tpWalkSpeed * delta * 60)
    end
end)

local MachineTab = Window:CreateTab("Machine", 120555476154580)
MachineTab:CreateToggle({ Name = "Instant Skillcheck", CurrentValue = false, Flag = "InstantSkillcheck", Callback = function(v) getgenv().scinstant = v end })

local instantStashGigiEnabled = false
local originalHoldDurations = {}

MachineTab:CreateToggle({
    Name = "Instant Stash Gigi Machine Prompt",
    CurrentValue = false,
    Flag = "InstantStashGigiPrompt",
    Callback = function(v)
        instantStashGigiEnabled = v
        if instantStashGigiEnabled then
            task.spawn(function()
                while instantStashGigiEnabled do
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            if not originalHoldDurations[obj] then originalHoldDurations[obj] = obj.HoldDuration end
                            obj.HoldDuration = 0
                        end
                    end
                    task.wait(2)
                end
            end)
        else
            for prompt, originalDuration in pairs(originalHoldDurations) do
                if prompt and prompt.Parent then prompt.HoldDuration = originalDuration end
            end
            originalHoldDurations = {}
        end
    end
})

local arcadeLoaded = false
MachineTab:CreateToggle({
    Name = "Auto Arcade Machine",
    CurrentValue = false,
    Flag = "AutoArcadeMachineToggle",
    Callback = function(v)
        if v and not arcadeLoaded then
            arcadeLoaded = true
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/christmas-cookie/extensions/refs/heads/main/arcademachine", true))()
            end)
        end
    end,
})

task.spawn(function()
    getgenv().scinstant = false
    pcall(function()
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        if events then
            local event = events:FindFirstChild("SkillcheckUpdate")
            if event and getcallbackvalue then
                local ogcb = getcallbackvalue(event, "OnClientInvoke")
                if ogcb then
                    local hook
                    hook = hookfunction(ogcb, function(...)
                        if getgenv().scinstant then return "supercomplete" end
                        return hook(...)
                    end)
                end
            end
        end
    end)
end)

local MapTab = Window:CreateTab("Map", 113248535106613)

local altFbConn = nil
MapTab:CreateToggle({
    Name = "Alternative Fullbright",
    CurrentValue = false,
    Flag = "AltFullbrightToggle",
    Callback = function(v)
        if v then
            local function setFb()
                Lighting.Brightness, Lighting.GlobalShadows, Lighting.OutdoorAmbient, Lighting.Ambient, Lighting.ClockTime, Lighting.FogEnd, Lighting.FogStart = 2, true, Color3.fromRGB(120,120,120), Color3.fromRGB(100,100,100), 14, 100000, 0
            end
            setFb()
            altFbConn = Lighting.Changed:Connect(setFb)
        else
            if altFbConn then altFbConn:Disconnect(); altFbConn = nil end
            Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127); Lighting.Ambient = Color3.fromRGB(0, 0, 0); Lighting.ClockTime = 12; Lighting.FogEnd = 10000
        end
    end
})

local fbConn = nil
MapTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "FullbrightToggle",
    Callback = function(v)
        if v then
            local function clearFogAndBright()
                Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 999999; Lighting.FogStart = 0; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255); Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            end
            clearFogAndBright()
            fbConn = RunService.RenderStepped:Connect(clearFogAndBright)
        else
            if fbConn then fbConn:Disconnect(); fbConn = nil end
            Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.FogEnd = 10000; Lighting.FogStart = 0; Lighting.GlobalShadows = true; Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127); Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
    end
})

local FunTab = Window:CreateTab("Fun", 71680025256265)

local spinning = false
local spinSpeed = 25
local spinConnection = nil

FunTab:CreateToggle({ Name = "Spin", CurrentValue = false, Callback = function(v)
    spinning = v
    if spinning then
        spinConnection = RunService.RenderStepped:Connect(function()
            if HumanoidRootPart then
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
            end
        end)
    else
        if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
    end
end })

FunTab:CreateSlider({ Name = "Spin Speed", Range = {1, 100}, Increment = 1, CurrentValue = 25, Flag = "SpinSpeedFlag", Callback = function(v) spinSpeed = v end })

local fovEnabled = false
local fovValue = 70
local fovConnection = nil

FunTab:CreateToggle({
    Name = "FOV Changer",
    CurrentValue = false,
    Flag = "FovToggle",
    Callback = function(v)
        fovEnabled = v
        if fovEnabled then
            fovConnection = RunService.RenderStepped:Connect(function()
                if Camera then Camera.FieldOfView = fovValue end
            end)
        else
             if fovConnection then fovConnection:Disconnect(); fovConnection = nil end
            if Camera then Camera.FieldOfView = 70 end
        end
    end
})

FunTab:CreateSlider({
    Name = "FOV Value", Range = {10, 120}, Increment = 1, CurrentValue = 70, Flag = "FovSlider",
    Callback = function(v)
        fovValue = v
        if fovEnabled and Camera then Camera.FieldOfView = fovValue end
    end
})

local jumpEnabled = false
local jumpPowerVal = 50
local jumpConnection = nil

FunTab:CreateToggle({ Name = "Enable Jump", CurrentValue = false, Flag = "EnableJumpToggle", Callback = function(v)
    jumpEnabled = v
    if jumpEnabled then
        jumpConnection = RunService.RenderStepped:Connect(function()
            if Humanoid then
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = jumpPowerVal
                pcall(function() LocalPlayer.Character:SetAttribute("CanJump", true) end)
            end
        end)
    else
        if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    end
end })

FunTab:CreateSlider({ Name = "Jump Power", Range = {10, 250}, Increment = 5, CurrentValue = 50, Flag = "JumpPowerSlider", Callback = function(v)
    jumpPowerVal = v
    if jumpEnabled and Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = jumpPowerVal
    end
end })

UserInputService.JumpRequest:Connect(function()
    if jumpEnabled and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

FunTab:CreateButton({ Name = "Kill Yourself", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end })

local SettingsTab = Window:CreateTab("Settings", 85280212335165)

SettingsTab:CreateSection("Device")

SettingsTab:CreateDropdown({
    Name = "Device",
    Options = {"PC", "Mobile"},
    CurrentOption = {Window.device or "PC"},
    Flag = "DeviceMode",
    Callback = function(opt)
        Window:SetDevice(opt)
    end,
})

SettingsTab:CreateSection("Tab Banner")

SettingsTab:CreateToggle({
    Name = "Show Tab Banner",
    CurrentValue = AstroCfg.data.tabBanner ~= false,
    Flag = "TabBannerToggle",
    Callback = function(v)
        AstroCfg.data.tabBanner = v and true or false
        AstroCfg.save()
        if not v then Window:HideTabBanner(true) end
    end
})

SettingsTab:CreateSection("Launcher Button")

SettingsTab:CreateDropdown({
    Name = "Button Position",
    Options = {"Left", "Top", "Right"},
    CurrentOption = {"Top"},
    Flag = "ButtonPosition",
    Callback = function(opt)
        Window:SetButtonSide(opt)
    end,
})

SettingsTab:CreateDropdown({
    Name = "Button Size",
    Options = {"40 x 40", "50 x 50", "60 x 60", "70 x 70", "80 x 80", "90 x 90", "100 x 100"},
    CurrentOption = {"60 x 60"},
    Flag = "ButtonSize",
    Callback = function(opt)
        local px = tonumber(string.match(opt, "(%d+)"))
        if px then Window:SetButtonSize(px) end
    end,
})

SettingsTab:CreateSection("Window Size")

local sizeOptions = {"Auto"}
for i = 1, 10 do
    table.insert(sizeOptions, tostring(i * 100))
end

SettingsTab:CreateDropdown({
    Name = "Gui Width",
    Options = sizeOptions,
    CurrentOption = {"Auto"},
    Flag = "GuiWidth",
    Callback = function(opt)
        if opt == "Auto" then
            Window:SetWidth(nil)
        else
            Window:SetWidth(tonumber(opt))
        end
    end,
})

SettingsTab:CreateDropdown({
    Name = "Gui Height",
    Options = sizeOptions,
    CurrentOption = {"Auto"},
    Flag = "GuiHeight",
    Callback = function(opt)
        if opt == "Auto" then
            Window:SetHeight(nil)
        else
            Window:SetHeight(tonumber(opt))
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Reset Window To Center",
    Callback = function()
        Window:Center()
    end,
})

SettingsTab:CreateSection("Configurations")

local HttpService = game:GetService("HttpService")
local CFG_DIR = "astro_hates_you_configs"
local CFG_SKIP = {
    DeviceMode = true, ButtonPosition = true, ButtonSize = true, GuiWidth = true, GuiHeight = true,
    TabBannerToggle = true, ItemEspBlacklistDropdown = true, PlayerEspBlacklistDropdown = true,
    ConfigNameInput = true, ConfigListDropdown = true,
}
local cfgName = ""
local cfgSelected = nil
local cfgDropdown

local function cfgNotify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "astro", Text = msg, Duration = 3})
    end)
end

local function cfgList()
    local out = {}
    pcall(function()
        if makefolder and isfolder and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
        if listfiles then
            for _, path in ipairs(listfiles(CFG_DIR)) do
                local name = tostring(path):match("([^/\\]+)%.json$")
                if name then table.insert(out, name) end
            end
        end
    end)
    table.sort(out)
    return out
end

local function cfgRefresh()
    if cfgDropdown then
        local list = cfgList()
        cfgDropdown.Refresh(#list > 0 and list or {"(none)"})
    end
end

local function cfgCollect()
    local data = {}
    for flag, obj in pairs(Window.flags) do
        if not CFG_SKIP[flag] and obj.Get then
            local ok, v = pcall(obj.Get)
            if ok then
                if obj.GetEnabled then
                    local _, e = pcall(obj.GetEnabled)
                    data[flag] = {t = "slider", v = v, e = e and true or false}
                elseif type(v) == "boolean" then
                    data[flag] = {t = "toggle", v = v}
                elseif type(v) == "number" then
                    data[flag] = {t = "slider", v = v}
                elseif type(v) == "string" then
                    data[flag] = {t = "drop", v = v}
                elseif type(v) == "table" then
                    local arr = {}
                    for k, val in pairs(v) do
                        if type(k) == "number" then table.insert(arr, val) elseif val then table.insert(arr, k) end
                    end
                    data[flag] = {t = "multi", v = arr}
                end
            end
        end
    end
    return data
end

local function cfgApply(data)
    for flag, entry in pairs(data) do
        local obj = Window.flags[flag]
        if obj and not CFG_SKIP[flag] and type(entry) == "table" then
            pcall(function()
                if entry.t == "toggle" then
                    obj.Set(entry.v, true)
                elseif entry.t == "slider" then
                    obj.Set(entry.v, true)
                    if entry.e ~= nil and obj.SetEnabled then obj.SetEnabled(entry.e, true) end
                elseif entry.t == "drop" or entry.t == "multi" then
                    obj.Set(entry.v, true)
                end
            end)
        end
    end
end

SettingsTab:CreateInput({
    Name = "Config Name",
    Placeholder = "my config",
    Flag = "ConfigNameInput",
    Callback = function(text) cfgName = (text or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "") end,
})

cfgDropdown = SettingsTab:CreateDropdown({
    Name = "Saved Configs",
    Options = (function() local l = cfgList() return #l > 0 and l or {"(none)"} end)(),
    CurrentOption = {"(none)"},
    Flag = "ConfigListDropdown",
    Callback = function(opt) cfgSelected = (opt ~= "(none)") and opt or nil end,
})

SettingsTab:CreateButton({
    Name = "Create / Save Config",
    Callback = function()
        local name = cfgName ~= "" and cfgName or cfgSelected
        if not name or name == "" then cfgNotify("Type a config name first") return end
        if not (writefile and HttpService) then cfgNotify("Your executor can't save files") return end
        local ok = pcall(function()
            if makefolder and isfolder and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
            writefile(CFG_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(cfgCollect()))
        end)
        cfgNotify(ok and ("Saved: " .. name) or "Save failed")
        cfgRefresh()
    end,
})

SettingsTab:CreateButton({
    Name = "Load Selected Config",
    Callback = function()
        if not cfgSelected then cfgNotify("Select a config first") return end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CFG_DIR .. "/" .. cfgSelected .. ".json"))
        end)
        if ok and type(data) == "table" then
            cfgApply(data)
            cfgNotify("Loaded: " .. cfgSelected)
        else
            cfgNotify("Load failed")
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Overwrite Selected Config",
    Callback = function()
        if not cfgSelected then cfgNotify("Select a config first") return end
        local ok = pcall(function()
            writefile(CFG_DIR .. "/" .. cfgSelected .. ".json", HttpService:JSONEncode(cfgCollect()))
        end)
        cfgNotify(ok and ("Overwrote: " .. cfgSelected) or "Save failed")
    end,
})

SettingsTab:CreateButton({
    Name = "Delete Selected Config",
    Callback = function()
        if not cfgSelected then cfgNotify("Select a config first") return end
        pcall(function() if delfile then delfile(CFG_DIR .. "/" .. cfgSelected .. ".json") end end)
        cfgNotify("Deleted: " .. cfgSelected)
        cfgSelected = nil
        cfgRefresh()
    end,
})

SettingsTab:CreateButton({
    Name = "Refresh Config List",
    Callback = cfgRefresh,
})
