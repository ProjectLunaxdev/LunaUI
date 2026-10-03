if not _G.PotassiumCompatLoaded then

local StarterGui = game:GetService("StarterGui")

local function shimNotify(text, title, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "Notice",
			Text = text or "",
			Duration = duration or 3,
		})
	end)
end

local function shimWorldToScreen(worldPos)
	local camera = workspace.CurrentCamera
	if not camera then return Vector2.new(0, 0), false end
	local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function shimHookmetamethod(obj, methodName, hook)
	local mt = getrawmetatable(obj)
	local original = mt[methodName]
	local wasReadonly = isreadonly(mt)
	setreadonly(mt, false)
	local realOriginal = hookfunction(original, hook)
	setreadonly(mt, wasReadonly)
	return realOriginal
end

local hadNativeHookmetamethod = typeof(hookmetamethod) == "function"

local genv = getgenv()
genv.notify = shimNotify
genv.WorldToScreen = shimWorldToScreen
if not hadNativeHookmetamethod then
	genv.hookmetamethod = shimHookmetamethod
end

print("[Potassium Compat] notify / WorldToScreen installed" .. (hadNativeHookmetamethod and "" or " (+ hookmetamethod polyfill)"))
_G.PotassiumCompatLoaded = true
end


if getgenv().LunaLibrary ~= nil then
	pcall(function() getgenv().LunaLibrary:Unload() end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
	Ground   = Color3.fromHex("#161826"),
	Window   = Color3.fromHex("#1b1d2b"),
	Surface  = Color3.fromHex("#232532"),
	Field    = Color3.fromHex("#1a1c28"),
	Line     = Color3.fromHex("#3f424d"),
	LineSoft = Color3.fromHex("#292b31"),
	Text     = Color3.fromHex("#e9e9ed"),
	Muted    = Color3.fromHex("#9397ab"),
	Dim      = Color3.fromHex("#75798c"),
	Accent   = Color3.fromHex("#9184d9"),
}
local ACCENTS = { "#9184d9", "#d98ea4", "#84bfd9", "#8fcf9a", "#d4a35a", "#cfd3e5" }

local THEME_ORDER = { "Nocturne", "Obsidian", "Rosewood", "Glacier", "Moss" }
local THEMES = {
	Nocturne = { Ground = "#161826", Window = "#1b1d2b", Surface = "#232532", Field = "#1a1c28", Line = "#3f424d", LineSoft = "#292b31", Text = "#e9e9ed", Muted = "#9397ab", Dim = "#75798c", Accent = "#9184d9" },
	Obsidian = { Ground = "#111214", Window = "#16171a", Surface = "#1e1f23", Field = "#141518", Line = "#3a3c42", LineSoft = "#26272b", Text = "#ececee", Muted = "#9a9ca3", Dim = "#7a7c83", Accent = "#d4a35a" },
	Rosewood = { Ground = "#1c1417", Window = "#22181c", Surface = "#2b1f24", Field = "#1f161a", Line = "#4a3a40", LineSoft = "#33262b", Text = "#f0e6e9", Muted = "#a8959b", Dim = "#86747a", Accent = "#d98ea4" },
	Glacier  = { Ground = "#121a20", Window = "#162027", Surface = "#1d2931", Field = "#141d24", Line = "#38474f", LineSoft = "#25323a", Text = "#e6eef2", Muted = "#8fa3ad", Dim = "#71848d", Accent = "#84bfd9" },
	Moss     = { Ground = "#141a15", Window = "#18201a", Surface = "#1f2921", Field = "#161d17", Line = "#3a473c", LineSoft = "#263128", Text = "#e7eee8", Muted = "#94a597", Dim = "#758679", Accent = "#8fcf9a" },
}

local FONT = Enum.Font.GothamMedium
local FONT_LIGHT = Enum.Font.Gotham
local WINDOW = Vector2.new(860, 600)
local HEADER_H, FOOTER_H, SIDEBAR_W = 54, 72, 140

local H = Enum.FillDirection.Horizontal
local AUTO_X, AUTO_Y = Enum.AutomaticSize.X, Enum.AutomaticSize.Y

local function create(className, props, children)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end

local TEXT_DEFAULTS = {
	BackgroundTransparency = 1, BorderSizePixel = 0, Font = FONT, TextSize = 12,
	TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}
local function label(props, children)
	local p = table.clone(TEXT_DEFAULTS)
	for k, v in pairs(props) do p[k] = v end
	return create("TextLabel", p, children)
end

local function corner(r)
	return create("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r) })
end
local function stroke(color, transparency)
	return create("UIStroke", { Color = color, Thickness = 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(t, r, b, l)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t),
		PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t),
	})
end
local function list(direction, gap, hAlign, vAlign)
	return create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
	})
end
local function tween(inst, goal, time)
	local t = TweenService:Create(inst, TweenInfo.new(time or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local Library = {
	Flags = {}, Options = {}, Configs = {},
	_listeners = {}, _searchables = {}, _accentTargets = {}, _refresh = {},
	_listening = false, _connections = {}, _onUnload = {},
	ThemeName = "Nocturne",
	ThemeNames = THEME_ORDER,
}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library._connections, c)
	return c
end

function Library:OnUnload(fn)
	table.insert(self._onUnload, fn)
end

function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	self:ClosePopup()
	for _, fn in ipairs(self._onUnload) do pcall(fn) end
	for _, c in ipairs(self._connections) do c:Disconnect() end
	table.clear(self._connections)
	if self.Gui then self.Gui:Destroy() end
end

function Library:SetTheme(name)
	local new = THEMES[name]
	if not new or name == self.ThemeName then return end

	self._suspendPopupClose = true
	local map = {}
	for role, color in pairs(Theme) do
		if role ~= "Accent" and new[role] then map[color:ToHex()] = Color3.fromHex(new[role]) end
	end
	local PROPS = { "BackgroundColor3", "TextColor3", "PlaceholderColor3", "ScrollBarImageColor3", "ImageColor3", "Color" }
	if self.Gui then
		for _, inst in ipairs(self.Gui:GetDescendants()) do
			for _, prop in ipairs(PROPS) do
				local ok, value = pcall(function() return inst[prop] end)
				if ok and typeof(value) == "Color3" then
					local repl = map[value:ToHex()]
					if repl then inst[prop] = repl end
				end
			end
		end
	end
	for role, hex in pairs(new) do
		if role ~= "Accent" then Theme[role] = Color3.fromHex(hex) end
	end
	self.ThemeName = name
	self:SetAccent(Color3.fromHex(new.Accent))
	self._suspendPopupClose = false
end

function Library:SetFlag(flag, value)
	if not flag then return end
	self.Flags[flag] = value
	for _, fn in ipairs(self._listeners[flag] or {}) do task.spawn(fn, value) end
	if self._anyFlag then task.spawn(self._anyFlag, flag, value) end
end

function Library:OnChanged(flag, fn)
	self._listeners[flag] = self._listeners[flag] or {}
	table.insert(self._listeners[flag], fn)
	if self.Flags[flag] ~= nil then task.spawn(fn, self.Flags[flag]) end
end

function Library:_accent(inst, prop)
	inst[prop] = Theme.Accent
	table.insert(self._accentTargets, { inst, prop })
end

function Library:ShowTooltip(anchor, text)
	if not self._tooltip then
		local f = create("Frame", {
			Name = "Tooltip", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
			Size = UDim2.fromOffset(0, 0), AutomaticSize = AUTO_X, Visible = false, ZIndex = 200, Parent = self.Gui,
		}, { corner(6), stroke(Theme.Line), pad(6, 8, 6, 8) })
		local t = label({ Text = "", TextWrapped = true, Size = UDim2.fromOffset(220, 0), AutomaticSize = AUTO_Y, TextSize = 11, TextColor3 = Theme.Muted, Parent = f })
		self._tooltip, self._tooltipText = f, t
	end
	local f, t = self._tooltip, self._tooltipText
	f.Visible = false
	t.Text = text or ""
	task.defer(function()
		if t.Text ~= text then return end
		local inset = GuiService:GetGuiInset()
		local vp = workspace.CurrentCamera.ViewportSize
		local w, h2 = f.AbsoluteSize.X, f.AbsoluteSize.Y
		local x = math.clamp(anchor.AbsolutePosition.X, 4, math.max(4, vp.X - w - 4))
		local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
		if y + h2 > vp.Y - 4 then y = anchor.AbsolutePosition.Y - h2 - 4 end
		f.Position = UDim2.fromOffset(x + inset.X, y + inset.Y)
		f.Visible = true
	end)
end

function Library:HideTooltip()
	if self._tooltip then self._tooltip.Visible = false end
end

function Library:SetAccent(color)
	Theme.Accent = color
	for _, t in ipairs(self._accentTargets) do
		if t[1].Parent then t[1][t[2]] = color end
	end

	local ownsSuspend = not self._suspendPopupClose
	if ownsSuspend then self._suspendPopupClose = true end
	for _, fn in ipairs(self._refresh) do fn() end
	if ownsSuspend then self._suspendPopupClose = false end
end

function Library:Filter(query)
	query = string.lower(query)
	for _, e in ipairs(self._searchables) do
		e.Row.Visible = query == "" or string.find(e.Text, query, 1, true) ~= nil
	end
	if query == "" or not self.Window then return end
	local win = self.Window
	for _, e in ipairs(self._searchables) do
		if e.Row.Visible and e.Owner and e.Owner.tab == win.Current then
			return
		end
	end
	for _, e in ipairs(self._searchables) do
		if e.Row.Visible and e.Owner then
			win:SelectTab(e.Owner.tab)
			if e.Owner.sub then e.Owner.tab:Select(e.Owner.sub) end
			return
		end
	end
end

function Library:SaveConfig(name)
	local snapshot = {}
	for flag, opt in pairs(self.Options) do
		if opt.Saveable ~= false then snapshot[flag] = opt:Get() end
	end
	self.Configs[name] = snapshot
	if self.OnConfigSaved then task.spawn(self.OnConfigSaved, name, snapshot) end
end

function Library:LoadConfig(name)
	local snapshot = self.Configs[name]
	if not snapshot then return end
	for flag, value in pairs(snapshot) do
		if self.Options[flag] then self.Options[flag]:Set(value) end
	end
end

function Library:ResetToDefault()
	for _, opt in pairs(self.Options) do
		if opt.Default ~= nil and opt.Saveable ~= false then opt:Set(opt.Default) end
	end
end

local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.14, 0),
	NumberSequenceKeypoint.new(0.86, 0), NumberSequenceKeypoint.new(1, 1),
})
local function rule(props, vertical)
	local isAccent = props.BackgroundColor3 == nil
	local line = create("Frame", { BorderSizePixel = 0, ZIndex = 2 })
	for k, v in pairs(props) do if k ~= "Parent" then line[k] = v end end
	if isAccent then Library:_accent(line, "BackgroundColor3") end
	create("UIGradient", { Transparency = FADE, Rotation = vertical and 90 or 0, Parent = line })
	line.Parent = props.Parent
	return line
end

local function crosshair(size)
	local root = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) })
	local ringStroke = create("UIStroke", { Thickness = 2 })
	Library:_accent(ringStroke, "Color")
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.62), BackgroundTransparency = 1, Parent = root,
	}, { corner(UDim.new(1, 0)), ringStroke })
	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0, Parent = root,
	}, { corner(UDim.new(1, 0)) })
	Library:_accent(dot, "BackgroundColor3")
	local len = math.max(3, math.floor(size * 0.2))
	for _, spec in ipairs({
		{ Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromOffset(2, len) },
		{ Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromOffset(2, len) },
		{ Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromOffset(len, 2) },
		{ Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromOffset(len, 2) },
	}) do
		local tick = create("Frame", { AnchorPoint = spec[1], Position = spec[2], Size = spec[3], BorderSizePixel = 0, Parent = root })
		Library:_accent(tick, "BackgroundColor3")
	end
	return root
end

function Library:ClosePopup()
	if self._suspendPopupClose then return end
	if self._popup then self._popup:Destroy(); self._popup = nil end
	if self._catcher then self._catcher.Visible = false end
	for _, c in ipairs(self._popupConns or {}) do c:Disconnect() end
	self._popupConns = {}
	self._popupOwner = nil
end

function Library:OpenPanel(anchor, owner, width, height)
	self:ClosePopup()
	local s = self.Scale.Scale
	if not self._catcher then
		self._catcher = create("TextButton", {
			Name = "PopupCatcher", BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1), ZIndex = 90, Visible = false, Parent = self.Gui,
		})
		self._catcher.MouseButton1Click:Connect(function() self:ClosePopup() end)
	end
	self._catcher.Visible = true
	local vp = workspace.CurrentCamera.ViewportSize
	local inset = GuiService:GetGuiInset()
	local w, h = width * s, height * s
	local x = math.clamp(anchor.AbsolutePosition.X + anchor.AbsoluteSize.X - w, 4, math.max(4, vp.X - w - 4))
	local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
	if y + h > vp.Y - 4 then y = anchor.AbsolutePosition.Y - 4 - h end
	local pop = create("Frame", {
		Name = "Popup", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 100, Active = true,
		Position = UDim2.fromOffset(x + inset.X, math.max(4, y) + inset.Y), Size = UDim2.fromOffset(width, height), Parent = self.Gui,
	}, { corner(8), stroke(Theme.Line), create("UIScale", { Scale = s }) })
	self._popup, self._popupOwner = pop, owner
	return pop
end

local function screenPos(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
	end
	return UserInputService:GetMouseLocation()
end

local WHEEL_BARS = 90
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
function Library:OpenColorWheel(anchor, owner, color, palette, onChange, opts)
	opts = opts or {}
	local hasAlpha = opts.Alpha ~= nil
	local PW, PH, WS = 196, hasAlpha and 282 or 252, 150
	local pop = self:OpenPanel(anchor, owner, PW, PH)
	local h, s, v = color:ToHSV()
	local alpha = hasAlpha and opts.Alpha or 1
	local rowY = 194

	local wheel = create("Frame", { Position = UDim2.fromOffset((PW - WS) / 2, 10), Size = UDim2.fromOffset(WS, WS), BackgroundTransparency = 1, ZIndex = 101, Parent = pop })
	for i = 0, WHEEL_BARS - 1 do
		local a = i * (180 / WHEEL_BARS)
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 6, 1, 0),
			Rotation = a, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 101, Parent = wheel,
		}, { create("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(a / 360, 1, 1)),
			ColorSequenceKeypoint.new(0.5, WHITE),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(((a + 180) % 360) / 360, 1, 1)),
		}) }) })
	end
	local dark = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 102, Parent = wheel }, { corner(UDim.new(1, 0)) })
	local marker = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, ZIndex = 103, Parent = wheel },
		{ corner(UDim.new(1, 0)), create("UIStroke", { Color = WHITE, Thickness = 2 }) })
	local wheelHit = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 104, Parent = wheel })

	local bar = create("Frame", { Position = UDim2.fromOffset(12, 172), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 101, Parent = pop }, { corner(4) })
	local barGrad = create("UIGradient", { Parent = bar })
	local knob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 14), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 102, Parent = bar }, { corner(2) })
	local barHit = create("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(12, 166), Size = UDim2.new(1, -24, 0, 20), ZIndex = 104, Parent = pop })

	local alphaBar, alphaGrad, alphaKnob, alphaHit
	if hasAlpha then
		alphaBar = create("Frame", { Position = UDim2.fromOffset(12, rowY + 6), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 101, Parent = pop }, { corner(4) })
		alphaGrad = create("UIGradient", { Parent = alphaBar })
		alphaKnob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 14), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 102, Parent = alphaBar }, { corner(2) })
		alphaHit = create("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(12, rowY), Size = UDim2.new(1, -24, 0, 20), ZIndex = 104, Parent = pop })
		rowY += 30
	end

	local preview = create("Frame", { Position = UDim2.fromOffset(12, rowY), Size = UDim2.fromOffset(26, 24), BorderSizePixel = 0, ZIndex = 101, Parent = pop }, { corner(5), stroke(Theme.Line) })
	local hexStroke = stroke(Theme.LineSoft)
	local hexBox = create("TextBox", {
		Position = UDim2.fromOffset(46, rowY), Size = UDim2.new(1, -58, 0, 24), BackgroundColor3 = Theme.Field, BorderSizePixel = 0,
		Font = FONT, TextSize = 12, TextColor3 = Theme.Text, ClearTextOnFocus = false, ZIndex = 101, Parent = pop,
	}, { corner(5), hexStroke })

	local function render(fire)
		local c = Color3.fromHSV(h, s, v)
		local ang = h * math.pi * 2
		marker.Position = UDim2.fromScale(0.5 + math.sin(ang) * s / 2, 0.5 - math.cos(ang) * s / 2)
		marker.BackgroundColor3 = c
		dark.BackgroundTransparency = v
		barGrad.Color = ColorSequence.new(BLACK, Color3.fromHSV(h, s, 1))
		knob.Position = UDim2.fromScale(v, 0.5)
		preview.BackgroundColor3 = c
		if not hexBox:IsFocused() then hexBox.Text = "#" .. string.upper(c:ToHex()) end
		if hasAlpha then
			alphaGrad.Color = ColorSequence.new(c, c)
			alphaGrad.Transparency = NumberSequence.new(1, 0)
			alphaKnob.Position = UDim2.fromScale(alpha, 0.5)
		end
		if fire then onChange(c, alpha) end
	end

	local mode
	local function update(input)
		local p = screenPos(input)
		if mode == "wheel" then
			local center = wheel.AbsolutePosition + wheel.AbsoluteSize / 2
			local dx, dy = p.X - center.X, p.Y - center.Y
			h = (math.deg(math.atan2(dx, -dy)) % 360) / 360
			s = math.clamp(math.sqrt(dx * dx + dy * dy) / (wheel.AbsoluteSize.X / 2), 0, 1)
		elseif mode == "value" then
			v = math.clamp((p.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		elseif mode == "alpha" then
			alpha = math.clamp((p.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
		end
		render(true)
	end
	local function begin(which)
		return function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mode = which
				update(input)
			end
		end
	end
	wheelHit.InputBegan:Connect(begin("wheel"))
	barHit.InputBegan:Connect(begin("value"))
	if hasAlpha then alphaHit.InputBegan:Connect(begin("alpha")) end
	table.insert(self._popupConns, UserInputService.InputChanged:Connect(function(input)
		if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
	end))
	table.insert(self._popupConns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then mode = nil end
	end))

	hexBox.Focused:Connect(function() hexStroke.Color = Theme.Accent end)
	hexBox.FocusLost:Connect(function()
		hexStroke.Color = Theme.LineSoft
		local text = string.gsub(hexBox.Text, "%s", "")
		local ok, c = pcall(Color3.fromHex, text)
		if ok and #string.gsub(text, "#", "") == 6 then
			h, s, v = c:ToHSV()
			render(true)
		else
			render(false)
		end
	end)

	local presets = create("Frame", { Position = UDim2.fromOffset(12, rowY + 34), Size = UDim2.new(1, -24, 0, 14), BackgroundTransparency = 1, ZIndex = 101, Parent = pop }, { list(H, 6) })
	for i, hex in ipairs(palette) do
		if i > 7 then break end
		local sw = create("TextButton", { Size = UDim2.fromOffset(20, 14), BackgroundColor3 = Color3.fromHex(hex), AutoButtonColor = false, Text = "", LayoutOrder = i, ZIndex = 101, Parent = presets },
			{ corner(3), stroke(Theme.Line) })
		sw.MouseButton1Click:Connect(function()
			h, s, v = Color3.fromHex(hex):ToHSV()
			render(true)
		end)
	end

	render(false)
	return pop
end

local DANGER = Color3.fromRGB(224, 108, 108)
function Library:CreateDialog(opts)
	opts = opts or {}
	local backdrop = create("Frame", {
		Name = "DialogBackdrop", BackgroundColor3 = BLACK, BackgroundTransparency = 0.5, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 150, Active = true, Parent = self.Gui,
	})
	local panel = create("Frame", {
		Name = "Dialog", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(300, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = Theme.Window, BorderSizePixel = 0,
		ZIndex = 151, Parent = backdrop,
	}, { corner(10), stroke(Theme.LineSoft), pad(16), list(nil, 10) })
	label({ Text = opts.Title or "", TextSize = 15, TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = panel })
	label({ Text = opts.Content or "", Font = FONT_LIGHT, TextWrapped = true, TextColor3 = Theme.Muted, TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = 2, Parent = panel })
	local btnRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 3, Parent = panel }, { list(H, 8, Enum.HorizontalAlignment.Right) })

	local function close()
		backdrop:Destroy()
	end

	for _, b in ipairs(opts.Buttons or { { Title = "OK" } }) do
		local btnStroke = stroke(Theme.LineSoft)
		local btn = create("TextButton", {
			Size = UDim2.fromOffset(0, 26), AutomaticSize = AUTO_X, BackgroundColor3 = Theme.Field,
			AutoButtonColor = false, Text = "", Parent = btnRow,
		}, { corner(6), btnStroke, pad(0, 12, 0, 12) })
		label({
			Text = b.Title or "OK", TextSize = 12, TextColor3 = b.Danger and DANGER or Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = btn,
		})
		btn.MouseEnter:Connect(function() tween(btnStroke, { Color = b.Danger and DANGER or Theme.Accent }) end)
		btn.MouseLeave:Connect(function() tween(btnStroke, { Color = Theme.LineSoft }) end)
		btn.MouseButton1Click:Connect(function()
			close()
			if b.Callback then task.spawn(b.Callback) end
		end)
	end

	return { Close = close }
end

function Library:OpenPopup(anchor, owner, count, build)
	self:ClosePopup()
	local s = self.Scale.Scale
	if not self._catcher then
		self._catcher = create("TextButton", {
			Name = "PopupCatcher", BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1), ZIndex = 90, Visible = false, Parent = self.Gui,
		})
		self._catcher.MouseButton1Click:Connect(function() self:ClosePopup() end)
	end
	self._catcher.Visible = true

	local vp = workspace.CurrentCamera.ViewportSize
	local inset = GuiService:GetGuiInset()
	local h = math.min(count, 8) * 22 + 8
	local x = math.clamp(anchor.AbsolutePosition.X, 4, math.max(4, vp.X - anchor.AbsoluteSize.X - 4))
	local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 3
	if y + h * s > vp.Y - 4 then y = anchor.AbsolutePosition.Y - 3 - h * s end
	local pop = create("ScrollingFrame", {
		Name = "Popup", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 100,
		Position = UDim2.fromOffset(x + inset.X, math.max(4, y) + inset.Y), Size = UDim2.fromOffset(anchor.AbsoluteSize.X / s, h),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Line, Parent = self.Gui,
	}, { corner(6), stroke(Theme.Line), create("UIScale", { Scale = s }), pad(4), list() })
	self._popup, self._popupOwner = pop, owner
	build(pop)
	return pop
end

local function attachTooltip(rowFrame, text)
	local hovering = false
	rowFrame.MouseEnter:Connect(function()
		hovering = true
		task.delay(0.35, function()
			if hovering then Library:ShowTooltip(rowFrame, text) end
		end)
	end)
	rowFrame.MouseLeave:Connect(function()
		hovering = false
		Library:HideTooltip()
	end)
end

local function buildGroup(column, title, owner)
	local Group = {}
	local order = 0

	local box = create("Frame", {
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0), AutomaticSize = AUTO_Y,
		LayoutOrder = #column:GetChildren(), Parent = column,
	}, { corner(8), stroke(Theme.LineSoft), list() })
	Group.Frame = box

	local head = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = box })
	label({ Text = title, TextSize = 13, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Parent = head })
	rule({ Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.25, Parent = head })

	local content = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = AUTO_Y,
		LayoutOrder = 1, Parent = box,
	}, { pad(10, 12, 12, 12), list(nil, 6) })

	local function row(h, searchText, tooltipText)
		order += 1
		local r = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, Parent = content })
		if searchText then table.insert(Library._searchables, { Row = r, Text = string.lower(searchText), Owner = owner }) end
		if tooltipText then attachTooltip(r, tooltipText) end
		return r
	end

	local function register(o, obj)
		obj.Default = o.Default
		if o.Flag then Library.Options[o.Flag] = obj end
		return obj
	end

	local function field(parent, props)
		local s = stroke(Theme.LineSoft)
		local f = create("TextButton", {
			BackgroundColor3 = Theme.Field, AutoButtonColor = false, Text = "", BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 22), Parent = parent,
		}, { corner(5), s })
		for k, v in pairs(props or {}) do f[k] = v end
		f.MouseEnter:Connect(function() tween(s, { Color = Theme.Line }) end)
		f.MouseLeave:Connect(function() tween(s, { Color = Theme.LineSoft }) end)
		return f, s
	end

	function Group:AddToggle(o)
		local state = o.Default == true
		local r = row(20, o.Text, o.Tooltip)
		local inner = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = r },
			{ list(H, 9, nil, Enum.VerticalAlignment.Center) })
		local boxStroke = stroke(Theme.Line)
		local box = create("Frame", { Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Field, LayoutOrder = 1, Parent = inner },
			{ corner(3), boxStroke })
		local txt = label({ Text = o.Text, Size = UDim2.new(1, -21, 1, 0), TextColor3 = Theme.Muted, LayoutOrder = 2, Parent = inner })
		local hit = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = r })

		local obj = {}
		function obj:Set(v)
			state = v == true

			tween(box, { BackgroundColor3 = state and Theme.Accent or Theme.Field })
			tween(boxStroke, { Color = state and Theme.Accent or Theme.Line })
			tween(txt, { TextColor3 = state and Theme.Text or Theme.Muted })
			Library:SetFlag(o.Flag, state)
			if o.Callback then task.spawn(o.Callback, state) end
		end
		function obj:Get() return state end
		hit.MouseButton1Click:Connect(function() obj:Set(not state) end)
		hit.MouseEnter:Connect(function() if not state then tween(txt, { TextColor3 = Theme.Text }) end end)
		hit.MouseLeave:Connect(function() if not state then tween(txt, { TextColor3 = Theme.Muted }) end end)

		table.insert(Library._refresh, function()
			if state then
				box.BackgroundColor3 = Theme.Accent
				boxStroke.Color = Theme.Accent
			end
		end)
		obj:Set(state)
		return register(o, obj)
	end

	function Group:AddSlider(o)
		local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
		local value = o.Default or min
		local r = row(32, o.Text, o.Tooltip)
		local txt = label({ RichText = true, Size = UDim2.new(1, 0, 0, 16), Parent = r })
		local track = create("Frame", {
			Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = Theme.Field, BorderSizePixel = 0, Parent = r,
		}, { corner(3), stroke(Theme.LineSoft) })
		local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.1, Parent = track }, { corner(3) })
		Library:_accent(fill, "BackgroundColor3")
		local knob = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(4, 10), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 2, Parent = track,
		}, { corner(2) })
		local hit = create("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 18), ZIndex = 3, Parent = r })

		local function format(v)
			if o.ValueText then local s = o.ValueText(v); if s then return s end end
			local decimals = o.Decimals or 0
			local s = decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(math.floor(v + 0.5))
			return s .. (o.Suffix or "")
		end

		local obj = {}
		function obj:Set(v)
			v = math.clamp(v, min, max)
			v = min + math.floor((v - min) / step + 0.5) * step
			value = v
			local pct = (max == min) and 0 or (v - min) / (max - min)
			fill.Size = UDim2.fromScale(pct, 1)
			knob.Position = UDim2.fromScale(pct, 0.5)
			txt.Text = string.format('%s <font color="#%s">- %s</font>', o.Text, Theme.Dim:ToHex(), format(v))
			Library:SetFlag(o.Flag, v)
			if o.Callback then task.spawn(o.Callback, v) end
		end
		function obj:Get() return value end

		local dragging = false
		local function update(x)
			local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			obj:Set(min + pct * (max - min))
		end
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input.Position.X)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input.Position.X)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		obj:Set(value)
		table.insert(Library._refresh, function() obj:Set(value) end)
		return register(o, obj)
	end

	function Group:AddDropdown(o)
		local options = o.Options or {}
		local multi = o.Multi == true
		local selected
		if multi then
			selected = {}
			for _, v in ipairs(o.Default or {}) do selected[v] = true end
		else
			selected = o.Default or options[1]
		end

		local r = row(o.Text and 40 or 22, o.Text, o.Tooltip)
		if o.Text then label({ Text = o.Text, Size = UDim2.new(1, 0, 0, 16), Parent = r }) end
		local box = field(r, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1) })
		local valueLabel = label({
			Font = FONT_LIGHT, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -30, 1, 0), Parent = box,
		})
		label({
			Text = multi and "≡" or "▾", TextSize = multi and 13 or 11, TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 22, 1, 0), Parent = box,
		})

		local obj = {}
		local function display()
			if multi then
				local out = {}
				for _, v in ipairs(options) do if selected[v] then table.insert(out, v) end end
				return #out > 0 and table.concat(out, ", ") or "-"
			end
			return selected or "-"
		end
		local function emit()
			valueLabel.Text = display()
			local value = selected
			if multi then
				value = {}
				for _, v in ipairs(options) do if selected[v] then table.insert(value, v) end end
			end
			Library:SetFlag(o.Flag, value)
			if o.Callback then task.spawn(o.Callback, value) end
		end
		function obj:Set(v)
			if multi then
				selected = {}
				for _, x in ipairs(v or {}) do selected[x] = true end
			else
				selected = v
			end
			emit()
		end
		function obj:Get()
			if not multi then return selected end
			local out = {}
			for _, v in ipairs(options) do if selected[v] then table.insert(out, v) end end
			return out
		end
		function obj:SetOptions(newOptions)
			options = newOptions
			if not multi and not table.find(options, selected) then selected = options[1] end
			emit()
		end

		box.MouseButton1Click:Connect(function()
			if Library._popupOwner == obj then Library:ClosePopup(); return end
			Library:OpenPopup(box, obj, #options, function(pop)
				for i, opt in ipairs(options) do
					local b = create("TextButton", {
						BackgroundColor3 = Theme.LineSoft, BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
						Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, ZIndex = 101, Parent = pop,
					}, { corner(4) })
					local t = label({ Text = opt, Font = FONT_LIGHT, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 1, 0), ZIndex = 102, Parent = b })
					local function paint()
						local on = (multi and selected[opt]) or (not multi and selected == opt)
						t.TextColor3 = on and Theme.Accent or Theme.Muted
					end
					paint()
					b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0 }) end)
					b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }) end)
					b.MouseButton1Click:Connect(function()
						if multi then
							selected[opt] = not selected[opt] or nil
							paint()
							emit()
						else
							selected = opt
							emit()
							Library:ClosePopup()
						end
					end)
				end
			end)
		end)
		emit()
		return register(o, obj)
	end

	local MODES = { "Toggle", "Hold", "Always On", "Always Off" }
	local SHORT = { MouseButton2 = "MB2", MouseButton3 = "MB3" }
	function Group:AddKeybind(o)
		local key = o.Default
		local mode = o.Mode or (key and "Toggle" or "Always Off")
		local active = mode == "Always On"
		local listening = false

		local r = row(20, o.Text, o.Tooltip)
		label({ Text = o.Text, Size = UDim2.new(1, -90, 1, 0), TextColor3 = Theme.Muted, Parent = r })
		local pill = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(0, 16), AutomaticSize = AUTO_X,
			BackgroundColor3 = Theme.Field, AutoButtonColor = false, Font = FONT, TextSize = 11,
			TextColor3 = Theme.Muted, Parent = r,
		}, { corner(4), stroke(Theme.LineSoft), pad(0, 7, 0, 7) })

		local obj = { Saveable = o.Saveable }
		local function name()
			if not key then return "None" end
			return SHORT[key.Name] or key.Name
		end
		local function paint()
			if listening then
				pill.Text = "..."
			elseif mode == "Always On" or mode == "Always Off" then
				pill.Text = mode
			else
				pill.Text = "Key: " .. name()
			end
			pill.TextColor3 = active and Theme.Accent or Theme.Muted
		end
		local function resolve(n)
			if not n then return nil end
			local ok, k = pcall(function() return Enum.KeyCode[n] end)
			if ok and k then return k end
			ok, k = pcall(function() return Enum.UserInputType[n] end)
			return ok and k or nil
		end
		local function setActive(v)
			active = v
			paint()
			Library:SetFlag(o.Flag, active)
			if o.Callback then task.spawn(o.Callback, active) end
			if o.SyncToggle then pcall(function() o.SyncToggle:Set(active) end) end
			if Library.OnKeybindChanged then task.spawn(Library.OnKeybindChanged) end
		end
		function obj:Set(v)
			if typeof(v) == "table" then
				key, mode = resolve(v.Key), v.Mode or mode
			elseif typeof(v) == "EnumItem" then
				key = v
			end
			paint()
			if o.KeyChanged then task.spawn(o.KeyChanged, key) end
			setActive(mode == "Always On")
		end
		function obj:Get() return { Key = key and key.Name or nil, Mode = mode } end
		function obj:GetKey() return key end
		function obj:GetMode() return mode end
		function obj:IsActive() return active end
		function obj:KeyName() return key and name() or nil end
		if not o.KeyOnly then
			Library.Keybinds = Library.Keybinds or {}
			table.insert(Library.Keybinds, { Text = o.Text, Bind = obj })
		end

		pill.MouseButton1Click:Connect(function()
			listening = true
			Library._listening = true
			paint()
		end)
		pill.MouseButton2Click:Connect(function()
			if o.KeyOnly then return end
			mode = MODES[(table.find(MODES, mode) or 0) % #MODES + 1]
			setActive(mode == "Always On")
		end)

		connect(UserInputService.InputBegan, function(input, processed)
			if listening then
				local t = input.UserInputType
				if t == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						key = nil
					else
						key = input.KeyCode
					end
				elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
					key = t
				else
					return
				end
				listening = false
				task.defer(function() Library._listening = false end)
				if key and (mode == "Always Off" or mode == "Always On") then mode = "Toggle" end
				if o.KeyChanged then task.spawn(o.KeyChanged, key) end
				setActive(mode == "Always On")
				return
			end
			if processed or not key then return end
			if input.KeyCode == key or input.UserInputType == key then
				if mode == "Toggle" then setActive(not active)
				elseif mode == "Hold" then setActive(true) end
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if mode == "Hold" and key and (input.KeyCode == key or input.UserInputType == key) then setActive(false) end
		end)
		setActive(active)
		return register(o, obj)
	end

	function Group:AddSegment(o)
		local current = o.Default or o.Options[1]
		local r = row(24, table.concat(o.Options, " "))
		local wrap = create("Frame", { BackgroundColor3 = Theme.Field, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = r },
			{ corner(5), stroke(Theme.LineSoft), list(H) })
		local items = {}
		local obj = {}
		for i, opt in ipairs(o.Options) do
			local b = create("TextButton", {
				BackgroundTransparency = 1, AutoButtonColor = false, Text = opt, Font = FONT, TextSize = 12,
				TextColor3 = Theme.Muted, Size = UDim2.fromScale(1 / #o.Options, 1), LayoutOrder = i, Parent = wrap,
			})
			local mark = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(0.5, 0, 0, 2),
				BorderSizePixel = 0, BackgroundTransparency = 1, Parent = b,
			}, { corner(1) })
			Library:_accent(mark, "BackgroundColor3")
			if i > 1 then
				create("Frame", { Size = UDim2.new(0, 1, 1, -8), Position = UDim2.fromOffset(0, 4), BackgroundColor3 = Theme.LineSoft, BorderSizePixel = 0, Parent = b })
			end
			items[opt] = { b, mark }
			b.MouseButton1Click:Connect(function() obj:Set(opt) end)
		end
		function obj:Set(v)
			current = v
			for opt, pair in pairs(items) do
				local on = opt == v
				tween(pair[1], { TextColor3 = on and Theme.Text or Theme.Muted })
				tween(pair[2], { BackgroundTransparency = on and 0 or 1 })
			end
			Library:SetFlag(o.Flag, v)
			if o.Callback then task.spawn(o.Callback, v) end
		end
		function obj:Get() return current end
		obj:Set(current)
		return register(o, obj)
	end

	function Group:AddColor(o)
		local palette = o.Palette or ACCENTS
		local current = o.Default or palette[1]
		local r = row(20, o.Text, o.Tooltip)
		label({ Text = o.Text, Size = UDim2.new(1, -40, 1, 0), Parent = r })
		local swatch = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(24, 12),
			AutoButtonColor = false, Text = "", Parent = r,
		}, { corner(3), stroke(Theme.Line) })
		local alpha = o.Transparency and (1 - (o.DefaultTransparency or 0)) or 1
		local obj = {}
		function obj:Set(hex)
			if typeof(hex) == "Color3" then hex = "#" .. hex:ToHex() end
			current = hex
			local c = Color3.fromHex(hex)
			swatch.BackgroundColor3 = c
			Library:SetFlag(o.Flag, c)
			if o.Callback then task.spawn(o.Callback, c) end
		end
		function obj:Get() return current end
		function obj:GetAlpha() return alpha end
		function obj:SetAlpha(a)
			alpha = math.clamp(a, 0, 1)
			if o.AlphaFlag then Library:SetFlag(o.AlphaFlag, 1 - alpha) end
			if o.AlphaCallback then task.spawn(o.AlphaCallback, alpha) end
		end
		swatch.MouseButton1Click:Connect(function()
			if Library._popupOwner == obj then Library:ClosePopup(); return end
			Library:OpenColorWheel(swatch, obj, Color3.fromHex(current), palette, function(c, a)
				obj:Set(c)
				if o.Transparency then obj:SetAlpha(a) end
			end, o.Transparency and { Alpha = alpha } or nil)
		end)
		obj:Set(current)
		if o.Transparency then obj:SetAlpha(alpha) end
		return register(o, obj)
	end

	function Group:AddButton(o)
		local r = row(22, o.Text, o.Tooltip)
		local b, s = field(r, { Text = o.Text, Font = FONT, TextSize = 12, TextColor3 = Theme.Muted })
		b.MouseEnter:Connect(function() tween(b, { TextColor3 = Theme.Text }); tween(s, { Color = Theme.Accent }) end)
		b.MouseLeave:Connect(function() tween(b, { TextColor3 = Theme.Muted }) end)
		b.MouseButton1Click:Connect(function()
			b.BackgroundColor3 = Theme.LineSoft
			tween(b, { BackgroundColor3 = Theme.Field }, 0.3)
			if o.Callback then task.spawn(o.Callback) end
		end)
		return b
	end

	function Group:AddTextBox(o)
		local r = row(o.Text and 40 or 22, o.Text, o.Tooltip)
		if o.Text then label({ Text = o.Text, Size = UDim2.new(1, 0, 0, 16), Parent = r }) end
		local s = stroke(Theme.LineSoft)
		local holder = create("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Theme.Field, BorderSizePixel = 0, Parent = r,
		}, { corner(5), s })
		local box = create("TextBox", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
			Font = FONT_LIGHT, TextSize = 12, Text = o.Default or "", PlaceholderText = o.Placeholder or "Enter text",
			PlaceholderColor3 = Theme.Dim, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false, Parent = holder,
		})
		box.Focused:Connect(function() tween(s, { Color = Theme.Accent }) end)
		box.FocusLost:Connect(function()
			tween(s, { Color = Theme.LineSoft })
			Library:SetFlag(o.Flag, box.Text)
			if o.Callback then task.spawn(o.Callback, box.Text) end
		end)
		if o.Numeric then
			box:GetPropertyChangedSignal("Text"):Connect(function()
				local t = box.Text
				local neg = t:sub(1, 1) == "-"
				local body = t:gsub("%-", ""):gsub("[^%d%.]", "")
				local firstDot = body:find("%.")
				if firstDot then
					body = body:sub(1, firstDot) .. body:sub(firstDot + 1):gsub("%.", "")
				end
				local filtered = (neg and "-" or "") .. body
				if filtered ~= t then box.Text = filtered end
			end)
		end
		return box
	end

	function Group:AddLabel(text)
		local r = row(16, text)
		return label({ Text = text, Font = FONT_LIGHT, TextColor3 = Theme.Dim, TextSize = 11, Size = UDim2.fromScale(1, 1), Parent = r })
	end

	function Group:AddDivider()
		local r = row(9)
		rule({ Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Line, Parent = r })
	end

	function Group:AddParagraph(o)
		order += 1
		local r = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = order, Parent = content }, { list(nil, 2) })
		if o.Title then
			label({ Text = o.Title, TextSize = 13, TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = r })
		end
		label({ Text = o.Content or "", Font = FONT_LIGHT, TextWrapped = true, TextColor3 = Theme.Muted, TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = 2, Parent = r })
		if o.Tooltip then attachTooltip(r, o.Tooltip) end
		return r
	end

	return Group
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local Window = { Tabs = {}, Visible = true }
	Library.Window = Window
	Library.ToggleKey = opts.ToggleKey or Enum.KeyCode.Insert

	local old = PlayerGui:FindFirstChild("LunaMenu")
	if old then old:Destroy() end

	local gui = create("ScreenGui", {
		Name = "LunaMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100, Parent = PlayerGui,
	})
	Library.Gui = gui

	local main = create("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WINDOW.X, WINDOW.Y), BackgroundColor3 = Theme.Window, BorderSizePixel = 0,
		Active = true, ZIndex = 10, Parent = gui,
	}, { corner(10), stroke(Theme.LineSoft) })
	local uiScale = create("UIScale", { Parent = main })
	Library.Scale = uiScale
	Window.Frame = main

	local MIN_W, MIN_H = WINDOW.X, WINDOW.Y
	local MAX_W, MAX_H = WINDOW.X + 360, WINDOW.Y + 280
	local resizeHandle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 20, Parent = main,
	})
	for i = 1, 3 do
		create("Frame", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4 - (i - 1) * 4),
			Size = UDim2.fromOffset(11 - (i - 1) * 3, 1), Rotation = -45, BackgroundColor3 = Theme.Line, BorderSizePixel = 0, ZIndex = 20, Parent = resizeHandle,
		})
	end
	local resizing = false
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local newW = math.clamp(main.AbsoluteSize.X + input.Delta.X, MIN_W, MAX_W)
			local newH = math.clamp(main.AbsoluteSize.Y + input.Delta.Y, MIN_H, MAX_H)
			main.Size = UDim2.fromOffset(newW, newH)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
	end)

	local header = create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEADER_H), Parent = main })
	local brand = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(0, 240, 1, 0), Parent = header },
		{ list(H, 10, nil, Enum.VerticalAlignment.Center) })

	label({ Text = "🌗", TextSize = 24, Size = UDim2.fromOffset(26, 26), TextXAlignment = Enum.TextXAlignment.Center, Parent = brand })
	label({ Text = opts.Title or "Luna", Font = FONT_LIGHT, TextSize = 22, AutomaticSize = AUTO_X, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 2, Parent = brand })
	rule({ Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.35, Parent = header })

	local searchStroke = stroke(Theme.LineSoft)
	local search = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(180, 28),
		BackgroundColor3 = Theme.Field, BorderSizePixel = 0, Parent = header,
	}, { corner(6), searchStroke })
	create("Frame", { Position = UDim2.new(0, 10, 0.5, -6), Size = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Parent = search },
		{ corner(UDim.new(1, 0)), create("UIStroke", { Color = Theme.Muted, Thickness = 1.5 }) })
	create("Frame", { Position = UDim2.new(0, 16, 0.5, 3), Size = UDim2.fromOffset(5, 2), Rotation = 45, BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = search })
	local searchBox = create("TextBox", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -36, 1, 0),
		Font = FONT_LIGHT, TextSize = 12, Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Theme.Dim,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = search,
	})
	searchBox:GetPropertyChangedSignal("Text"):Connect(function() Library:Filter(searchBox.Text) end)
	searchBox.Focused:Connect(function() tween(searchStroke, { Color = Theme.Accent }) end)
	searchBox.FocusLost:Connect(function() tween(searchStroke, { Color = Theme.LineSoft }) end)

	local body = create("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 1, -(HEADER_H + FOOTER_H)), Parent = main })
	local sidebar = create("Frame", { Name = "Sidebar", BackgroundColor3 = Theme.Ground, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(0, SIDEBAR_W, 1, 0), Parent = body })
	rule({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Line, Parent = sidebar }, true)
	local pages = create("Frame", { Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(SIDEBAR_W, 0), Size = UDim2.new(1, -SIDEBAR_W, 1, 0), Parent = body })

	local footer = create("Frame", {
		Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, FOOTER_H),
		BackgroundColor3 = Theme.Ground, BorderSizePixel = 0, Parent = main,
	}, { corner(10) })
	create("Frame", { BackgroundColor3 = Theme.Ground, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 12), Parent = footer })
	rule({ Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Line, Parent = footer })

	local tabBar = create("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Line, Parent = footer,
	}, { list(H, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center) })

	function Window:SelectTab(tab)
		Library:ClosePopup()
		for _, t in ipairs(Window.Tabs) do
			t:Style(t == tab)
			t.SideList.Visible = t == tab
			for _, s in ipairs(t.SubTabs) do s.Page.Visible = false end
		end
		local hasSide = #tab.SubTabs > 1
		sidebar.Visible = hasSide
		pages.Position = UDim2.fromOffset(hasSide and SIDEBAR_W or 0, 0)
		pages.Size = UDim2.new(1, hasSide and -SIDEBAR_W or 0, 1, 0)
		Window.Current = tab
		if tab.Current then tab:Select(tab.Current) end
		if Window.OnTabSelected then Window.OnTabSelected(tab) end
	end

	function Window:AddTab(name, icon)
		local Tab = { Name = name, SubTabs = {} }
		local btn = create("TextButton", {
			Size = UDim2.fromOffset(74, 56), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1,
			AutoButtonColor = false, Text = "", LayoutOrder = #Window.Tabs + 1, Parent = tabBar,
		}, { corner(8) })
		local iconObj
		if icon and string.find(icon, "rbxasset") then
			iconObj = create("ImageLabel", { BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Dim, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 9), Size = UDim2.fromOffset(20, 20), Parent = btn })
		else
			iconObj = label({ Text = icon or "•", TextSize = 18, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 7), Size = UDim2.fromOffset(24, 24), Parent = btn })
		end
		local lbl = label({ Text = name, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 14), TextColor3 = Theme.Dim, Parent = btn })
		Tab.SideList = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Line, Parent = sidebar,
		}, { list(nil, 2), pad(12, 0, 12, 0) })

		function Tab:Style(active)
			Tab.Active = active
			tween(btn, { BackgroundTransparency = active and 0 or 1 })
			local c = active and Theme.Accent or Theme.Dim
			if iconObj:IsA("ImageLabel") then tween(iconObj, { ImageColor3 = c }) else tween(iconObj, { TextColor3 = c }) end
			tween(lbl, { TextColor3 = active and Theme.Text or Theme.Dim })
		end
		table.insert(Library._refresh, function() if Tab.Active then Tab:Style(true) end end)
		btn.MouseEnter:Connect(function() if not Tab.Active then tween(lbl, { TextColor3 = Theme.Muted }) end end)
		btn.MouseLeave:Connect(function() if not Tab.Active then tween(lbl, { TextColor3 = Theme.Dim }) end end)
		btn.MouseButton1Click:Connect(function() Window:SelectTab(Tab) end)

		function Tab:Select(sub)
			Library:ClosePopup()
			Tab.Current = sub
			for _, s in ipairs(Tab.SubTabs) do s:Style(s == sub) end
		end

		function Tab:AddSubTab(subName)
			local Sub = { Name = subName }
			local sbtn = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = "", LayoutOrder = #Tab.SubTabs + 1, Parent = Tab.SideList,
			})
			local bar = create("Frame", { Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = sbtn })
			Library:_accent(bar, "BackgroundColor3")
			local slbl = label({ Text = subName, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0), TextColor3 = Theme.Muted, Parent = sbtn })

			local page = create("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
				ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Line, CanvasSize = UDim2.new(),
				AutomaticCanvasSize = AUTO_Y, ScrollingDirection = Enum.ScrollingDirection.Y,
				Visible = false, Parent = pages,
			}, { pad(14), list(H, 12) })
			local columns = {}
			for i = 1, 3 do
				columns[i] = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1 / 3, -8, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = i, Parent = page }, { list(nil, 12) })
			end
			page:GetPropertyChangedSignal("CanvasPosition"):Connect(function() Library:ClosePopup() end)
			Sub.Page = page

			function Sub:Style(active)
				tween(sbtn, { BackgroundTransparency = active and 0.3 or 1 })
				tween(bar, { BackgroundTransparency = active and 0 or 1 })
				tween(slbl, { TextColor3 = active and Theme.Text or Theme.Muted })
				page.Visible = active
			end
			sbtn.MouseEnter:Connect(function() if Tab.Current ~= Sub then tween(slbl, { TextColor3 = Theme.Text }) end end)
			sbtn.MouseLeave:Connect(function() if Tab.Current ~= Sub then tween(slbl, { TextColor3 = Theme.Muted }) end end)
			sbtn.MouseButton1Click:Connect(function() Tab:Select(Sub) end)

			function Sub:AddGroup(title, column)
				return buildGroup(columns[math.clamp(column or 1, 1, 3)], title, { tab = Tab, sub = Sub })
			end

			table.insert(Tab.SubTabs, Sub)
			if not Tab.Current then Tab.Current = Sub end
			return Sub
		end

		function Tab:AddGroup(title, column)
			Tab.Default = Tab.Default or Tab:AddSubTab(name)
			return Tab.Default:AddGroup(title, column)
		end

		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then task.defer(function() Window:SelectTab(Tab) end) end
		return Tab
	end

	local baseScale = 1
	Window.DPI = opts.DPI or 1
	Window.ExtraRight = 0
	local function clampCenter(cx, cy)
		local vp = workspace.CurrentCamera.ViewportSize
		local hw, hh = WINDOW.X * uiScale.Scale / 2, WINDOW.Y * uiScale.Scale / 2
		local extra = Window.ExtraRight * uiScale.Scale
		return math.clamp(cx, hw, math.max(hw, vp.X - hw - extra)), math.clamp(cy, hh, math.max(hh, vp.Y - hh))
	end
	local function keepOnScreen()
		local c = main.AbsolutePosition + main.AbsoluteSize / 2
		local cx, cy = clampCenter(c.X, c.Y)
		local inset = GuiService:GetGuiInset()
		main.Position = UDim2.fromOffset(cx + inset.X, cy + inset.Y)
	end
	local function fit()
		local vp = workspace.CurrentCamera.ViewportSize
		local fitScale = math.min((vp.X - 24) / (WINDOW.X + Window.ExtraRight), (vp.Y - 24) / WINDOW.Y)
		baseScale = math.clamp(math.min(Window.DPI, fitScale), 0.4, 2)
		uiScale.Scale = baseScale
		Library:ClosePopup()
		task.defer(keepOnScreen)
	end
	function Window:SetDPI(scale)
		Window.DPI = scale
		fit()
	end
	function Window:SetExtraRight(px)
		Window.ExtraRight = px
		fit()
	end
	fit()
	connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fit)

	function Window:SetVisible(v)
		Window.Visible = v
		Library:ClosePopup()
		if Window.OnVisibleChanged then task.spawn(Window.OnVisibleChanged, v) end
		if v then
			main.Visible = true
			uiScale.Scale = baseScale * 0.96
			tween(uiScale, { Scale = baseScale }, 0.18)
		else
			main.Visible = false
		end
	end

	local dragging, dragStart, startCenter
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart = true, input.Position
			startCenter = main.AbsolutePosition + main.AbsoluteSize / 2
			Library:ClosePopup()
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			local cx, cy = clampCenter(startCenter.X + d.X, startCenter.Y + d.Y)
			local inset = GuiService:GetGuiInset()
			main.Position = UDim2.fromOffset(cx + inset.X, cy + inset.Y)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if processed or Library._listening then return end
		if input.KeyCode == Library.ToggleKey then Window:SetVisible(not Window.Visible) end
	end)

	if UserInputService.TouchEnabled then
		local s = stroke(Theme.Line)
		local touchBtn = create("TextButton", {
			Position = UDim2.fromOffset(16, 64), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.Surface,
			AutoButtonColor = false, Text = "LU", Font = FONT, TextSize = 14, TextColor3 = Theme.Text, ZIndex = 5, Parent = gui,
		}, { corner(8), s })
		touchBtn.MouseButton1Click:Connect(function() Window:SetVisible(not Window.Visible) end)
	end

	return Window
end

function Library:MakeDraggable(frame)
	local dragging, start, origin
	frame.Active = true
	connect(frame.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, start, origin = true, input.Position, frame.AbsolutePosition
			frame.AnchorPoint = Vector2.zero
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local vp = workspace.CurrentCamera.ViewportSize
			local d = input.Position - start
			local x = math.clamp(origin.X + d.X, 0, math.max(0, vp.X - frame.AbsoluteSize.X))
			local y = math.clamp(origin.Y + d.Y, 0, math.max(0, vp.Y - frame.AbsoluteSize.Y))
			local inset = GuiService:GetGuiInset()
			frame.Position = UDim2.fromOffset(x + inset.X, y + inset.Y)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

function Library:CreateKeybindList()
	local frame = create("Frame", {
		Name = "KeybindList", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.fromOffset(200, 0), AutomaticSize = AUTO_Y,
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = self.Gui,
	}, { corner(6), stroke(Theme.LineSoft), list() })
	local head = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = frame })
	local title = label({ Text = "Keybinds", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), Parent = head })
	rule({ Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = head })
	local body = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = AUTO_Y, LayoutOrder = 2, Parent = frame }, { pad(6, 10, 8, 10), list(nil, 4) })
	local strokeObj = frame:FindFirstChildOfClass("UIStroke")
	self:MakeDraggable(frame)

	local function refresh()
		local F = self.Flags
		frame.Visible = F.KeybindList == true
		if not frame.Visible then return end
		local t = (F.KeybindListTransparency or 0) / 100
		frame.BackgroundTransparency = t
		strokeObj.Transparency = t
		title.Text = "Keybinds" .. (F.KeybindListMode and ("  ·  " .. (F.Mode or "")) or "")
		for _, c in ipairs(body:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		local onlyActive, count = F.KeybindListActive == true, 0
		for _, e in ipairs(self.Keybinds or {}) do
			local b = e.Bind
			local mode, active = b:GetMode(), b:IsActive()
			local bound = b:GetKey() ~= nil or mode == "Always On"
			if bound and (active or not onlyActive) then
				count += 1
				local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = count, Parent = body })
				label({ Text = e.Text, Size = UDim2.new(1, -90, 1, 0), TextColor3 = active and Theme.Text or Theme.Muted, Parent = row })
				label({
					Text = "[" .. (b:KeyName() or "-") .. "] " .. mode, TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 88, 1, 0),
					TextColor3 = active and Theme.Accent or Theme.Dim, Parent = row,
				})
			end
		end
		if count == 0 then
			label({ Text = onlyActive and "No active keybinds" or "No keybinds set", Font = FONT_LIGHT, TextColor3 = Theme.Dim, Size = UDim2.new(1, 0, 0, 16), Parent = body })
		end
	end
	self.OnKeybindChanged = refresh
	for _, flag in ipairs({ "KeybindList", "KeybindListActive", "KeybindListTransparency", "KeybindListMode", "Mode" }) do
		self:OnChanged(flag, refresh)
	end
	table.insert(self._refresh, refresh)
	refresh()
	return frame
end

function Library:CreateWatermark()
	local frame = create("Frame", {
		Position = UDim2.fromOffset(16, 64), Size = UDim2.fromOffset(0, 24), AutomaticSize = AUTO_X,
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 4, Parent = self.Gui,
	}, { corner(6), stroke(Theme.LineSoft), pad(0, 10, 0, 10) })
	if UserInputService.TouchEnabled then frame.Position = UDim2.fromOffset(70, 74) end
	rule({ Size = UDim2.new(1, 20, 0, 1), Position = UDim2.fromOffset(-10, 0), Parent = frame })
	local text = label({ RichText = true, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, Parent = frame })
	local frames, elapsed = 0, 0
	local sep = string.format('  <font color="#%s">|</font>  ', Theme.Line:ToHex())
	connect(RunService.RenderStepped, function(dt)
		frames += 1
		elapsed += dt
		if elapsed >= 0.5 then
			local fps = math.floor(frames / elapsed + 0.5)
			local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
			text.Text = "Luna" .. sep .. LocalPlayer.Name .. sep .. fps .. " fps" .. sep .. ping .. " ms"
			frames, elapsed = 0, 0
		end
	end)
	self:OnChanged("HideWatermark", function(v) frame.Visible = not v end)
	self:MakeDraggable(frame)
	return frame
end

function Library:CreateEspPreview(Window, VisualsTab)
	local PANEL_W, GAP, BOX_W, BOX_H = 250, 8, 92, 132
	local F = Library.Flags
	local open, current, hp = false, nil, 0.62

	local function flagOption(flag, default)
		local obj = { Default = default }
		function obj:Set(v) Library:SetFlag(flag, v == true) end
		function obj:Get() return F[flag] end
		Library.Options[flag] = obj
		Library:SetFlag(flag, default)
	end
	flagOption("Esp", true)
	flagOption("EspBoxes", true)
	flagOption("EspTracers", false)
	flagOption("EspHealth", true)
	flagOption("EspArmor", false)
	flagOption("EspAmmo", true)
	flagOption("EspNames", true)
	flagOption("EspWeapon", true)
	flagOption("EspDistance", true)

	local panel = create("Frame", {
		Name = "EspPreview", Position = UDim2.new(1, GAP, 0, 0), Size = UDim2.new(0, PANEL_W, 1, 0),
		BackgroundColor3 = Theme.Window, BorderSizePixel = 0, Visible = false, Active = true, Parent = Window.Frame,
	}, { corner(10), stroke(Theme.LineSoft) })
	local head = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = panel })
	label({ Text = "Enemy", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = head })
	rule({ Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.35, Parent = head })

	local function barSettings(key, full, empty)
		return function(g)
			g:AddColor({ Text = "Color", Flag = key .. "Color", Default = full })
			g:AddColor({ Text = "Color (Empty)", Flag = key .. "Empty", Default = empty })
			g:AddColor({ Text = "Background Color", Flag = key .. "Bg", Default = "#26272e" })
			g:AddSlider({ Text = "Size", Flag = key .. "Size", Min = 1, Max = 8, Default = 3, Suffix = "px" })
		end
	end
	local function textSettings(key, color, size)
		return function(g)
			g:AddColor({ Text = "Color", Flag = key .. "Color", Default = color })
			g:AddSlider({ Text = "Size", Flag = key .. "Size", Min = 9, Max = 16, Default = size, Suffix = "px" })
		end
	end
	local SECTIONS = {
		{ Icon = "⚙", Name = "General", Chips = {
			{ Name = "Box", Flag = "EspBoxes", Build = function(g)
				g:AddColor({ Text = "Color", Flag = "EspBoxColor", Default = "#e6e6ee" })
				g:AddToggle({ Text = "Filled", Flag = "EspBoxFill" })
				g:AddToggle({ Text = "Outline", Flag = "EspBoxOutline", Default = true })
			end },
			{ Name = "Tracers", Flag = "EspTracers", Build = function(g)
				g:AddColor({ Text = "Color", Flag = "EspTracerColor", Default = "#9184d9" })
				g:AddSegment({ Flag = "EspTracerOrigin", Options = { "Bottom", "Top" } })
				g:AddSlider({ Text = "Thickness", Flag = "EspTracerThickness", Min = 1, Max = 3, Default = 1, Suffix = "px" })
			end },
		} },
		{ Icon = "☰", Name = "Bars", Chips = {
			{ Name = "Health", Flag = "EspHealth", Build = barSettings("EspHealth", "#8fcf9a", "#d98ea4") },
			{ Name = "Armor", Flag = "EspArmor", Build = barSettings("EspArmor", "#84bfd9", "#44464f") },
			{ Name = "Ammo", Flag = "EspAmmo", Build = barSettings("EspAmmo", "#d4a35a", "#7c8090") },
		} },
		{ Icon = "A", Name = "Text", Chips = {
			{ Name = "Name", Flag = "EspNames", Build = textSettings("EspName", "#e6e6ee", 12) },
			{ Name = "Weapon", Flag = "EspWeapon", Build = textSettings("EspWeapon", "#9a9eb0", 11) },
			{ Name = "Distance", Flag = "EspDistance", Build = textSettings("EspDistance", "#9a9eb0", 11) },
		} },
	}

	local toolbar = create("Frame", {
		Position = UDim2.new(0, 10, 1, -38), Size = UDim2.fromOffset(0, 28), AutomaticSize = AUTO_X,
		BackgroundColor3 = Theme.Field, BorderSizePixel = 0, Parent = panel,
	}, { corner(6), stroke(Theme.LineSoft), pad(2), list(H, 2) })
	local toolButtons = {}
	local masterStroke = stroke(Theme.Line)
	local master = create("TextButton", {
		Position = UDim2.new(0, 104, 1, -34), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Theme.Field,
		AutoButtonColor = false, Text = "", Parent = panel,
	}, { corner(5), masterStroke })
	local masterMark = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Parent = master }, { corner(3) })
	Library:_accent(masterMark, "BackgroundColor3")
	master.MouseButton1Click:Connect(function() Library.Options.Esp:Set(F.Esp == false) end)
	local secLabel = label({ Text = "Preview", TextColor3 = Theme.Muted, Position = UDim2.new(0, 134, 1, -38), Size = UDim2.new(1, -144, 0, 28), Parent = panel })

	local drawer = create("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -54), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = AUTO_Y,
		BackgroundColor3 = Theme.Window, BorderSizePixel = 0, Visible = false, ZIndex = 5, Active = true, Parent = panel,
	}, { corner(8), stroke(Theme.Line), pad(8), list(nil, 8) })
	local sectionFrames, sectionState = {}, {}
	local function paintChips()
		for _, st in ipairs(sectionState) do for _, c in ipairs(st.chips) do c.paint() end end
	end
	for i, sec in ipairs(SECTIONS) do
		local frame = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = AUTO_Y, Visible = false, LayoutOrder = i, Parent = drawer }, { list(nil, 8) })
		local chipRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = frame }, { list(H, 6) })
		local st = { selected = 1, chips = {} }
		sectionState[i] = st
		for j, chip in ipairs(sec.Chips) do
			local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = AUTO_Y, LayoutOrder = 1 + j, Parent = frame })
			chip.Build(buildGroup(holder, chip.Name))
			local cs, bs = stroke(Theme.LineSoft), stroke(Theme.Line)
			local btn = create("TextButton", {
				Size = UDim2.fromOffset(0, 24), AutomaticSize = AUTO_X, BackgroundColor3 = Theme.Field,
				AutoButtonColor = false, Text = "", LayoutOrder = j, Parent = chipRow,
			}, { corner(5), cs, pad(0, 8, 0, 6), list(H, 6, nil, Enum.VerticalAlignment.Center) })
			local box = create("TextButton", { Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Field, AutoButtonColor = false, Text = "", LayoutOrder = 1, Parent = btn }, { corner(3), bs })
			local mark = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = box }, { corner(2) })
			Library:_accent(mark, "BackgroundColor3")
			local txt = label({ Text = chip.Name, TextTruncate = Enum.TextTruncate.None, Size = UDim2.fromOffset(0, 24), AutomaticSize = AUTO_X, LayoutOrder = 2, Parent = btn })
			local entry = {}
			function entry.paint()
				local on, sel = F[chip.Flag] == true, st.selected == j
				mark.BackgroundTransparency = on and 0 or 1
				bs.Color = on and Theme.Accent or Theme.Line
				cs.Color = sel and Theme.Accent or Theme.LineSoft
				txt.TextColor3 = (on or sel) and Theme.Text or Theme.Muted
				holder.Visible = sel
			end
			box.MouseButton1Click:Connect(function()
				local opt = Library.Options[chip.Flag]
				if opt then opt:Set(F[chip.Flag] ~= true) end
			end)
			btn.MouseButton1Click:Connect(function() st.selected = j; paintChips() end)
			table.insert(st.chips, entry)
		end
		sectionFrames[i] = frame

		local tb = create("TextButton", {
			Size = UDim2.fromOffset(26, 24), BackgroundColor3 = Theme.LineSoft, BackgroundTransparency = 1,
			AutoButtonColor = false, Text = sec.Icon, Font = FONT, TextSize = 15, TextColor3 = Theme.Muted, LayoutOrder = i, Parent = toolbar,
		}, { corner(4) })
		toolButtons[i] = tb
		tb.MouseButton1Click:Connect(function()
			Library:ClosePopup()
			current = (current == i) and nil or i
			drawer.Visible = current ~= nil
			for k, f in ipairs(sectionFrames) do f.Visible = k == current end
			secLabel.Text = current and SECTIONS[current].Name or "Preview"
			for k, b in ipairs(toolButtons) do
				b.BackgroundTransparency = k == current and 0 or 1
				b.TextColor3 = k == current and Theme.Accent or Theme.Muted
			end
		end)
	end

	local canvas = create("Frame", {
		Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 1, -92), BackgroundColor3 = Theme.Field,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = panel,
	}, { corner(8), stroke(Theme.LineSoft) })
	local boxRoot = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -10), Size = UDim2.fromOffset(BOX_W, BOX_H), BackgroundTransparency = 1, Parent = canvas })
	for _, p in ipairs({ { 35, 8, 22, 22 }, { 26, 32, 40, 44 }, { 8, 32, 16, 44 }, { 68, 32, 16, 44 }, { 26, 78, 19, 46 }, { 47, 78, 19, 46 } }) do
		create("Frame", { Position = UDim2.fromOffset(p[1], p[2]), Size = UDim2.fromOffset(p[3], p[4]), BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Parent = boxRoot }, { corner(3) })
	end
	local espLayer = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = boxRoot })
	local disabledNote = label({ Text = "ESP disabled", TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 12), Size = UDim2.fromOffset(160, 16), Parent = boxRoot })
	label({ Text = "Click the dummy to test damage", Font = FONT_LIGHT, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -20, 0, 14), Parent = canvas })

	local tracer = create("Frame", { BorderSizePixel = 0, Parent = espLayer })
	local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.84, BorderSizePixel = 0, Parent = espLayer })
	local fullOutline = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = espLayer }, { create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 3, Transparency = 0.5 }) })
	local fullStroke = create("UIStroke", { Thickness = 1 })
	local fullBox = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = espLayer }, { fullStroke })
	local backStroke = create("UIStroke", { Thickness = 1, Transparency = 0.55 })
	local backBox = create("Frame", { Position = UDim2.fromOffset(8, -8), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = espLayer }, { backStroke })
	local corners = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = espLayer })
	local cornerPieces, cornerOutlines = {}, {}
	for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		for _, sz in ipairs({ UDim2.fromOffset(16, 1), UDim2.fromOffset(1, 16) }) do
			local o = create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.4 })
			local piece = create("Frame", { AnchorPoint = Vector2.new(c[1], c[2]), Position = UDim2.fromScale(c[1], c[2]), Size = sz, BorderSizePixel = 0, Parent = corners }, { o })
			table.insert(cornerPieces, piece)
			table.insert(cornerOutlines, o)
		end
	end
	local function makeBar(fromBottom)
		local track = create("Frame", { BorderSizePixel = 0, Parent = espLayer })
		local f = create("Frame", { AnchorPoint = fromBottom and Vector2.new(0, 1) or Vector2.zero, Position = fromBottom and UDim2.fromScale(0, 1) or UDim2.new(), BorderSizePixel = 0, Parent = track })
		return track, f
	end
	local hTrack, hFill = makeBar(true)
	local aTrack, aFill = makeBar(true)
	local amTrack, amFill = makeBar(false)
	local function espText(text, anchorY)
		return label({ Text = text, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.5, AnchorPoint = Vector2.new(0.5, anchorY), Parent = espLayer })
	end
	local nameLbl = espText("Player2", 1)
	nameLbl.Position = UDim2.new(0.5, 0, 0, -5)
	local weaponLbl = espText("Rifle  18/30", 0)
	local distLbl = espText("42 studs", 0)

	local function refresh()
		local on = F.Esp ~= false
		espLayer.Visible, disabledNote.Visible = on, not on
		masterMark.BackgroundTransparency = on and 0 or 1
		masterStroke.Color = on and Theme.Accent or Theme.Line

		local style, bc, boxOn = F.EspBoxStyle or "Corner", F.EspBoxColor or Theme.Text, F.EspBoxes == true
		local outline = F.EspBoxOutline ~= false
		fullBox.Visible = boxOn and style ~= "Corner"
		fullOutline.Visible = fullBox.Visible and outline
		backBox.Visible = boxOn and style == "3D"
		corners.Visible = boxOn and style == "Corner"
		fullStroke.Color, backStroke.Color, fill.BackgroundColor3 = bc, bc, bc
		for _, p in ipairs(cornerPieces) do p.BackgroundColor3 = bc end
		for _, o in ipairs(cornerOutlines) do o.Enabled = outline end
		fill.Visible = boxOn and F.EspBoxFill == true

		local function bar(key, track, f, pct, side)
			local show = F[key] == true
			track.Visible = show
			if not show then return 0 end
			local size = F[key .. "Size"] or 3
			track.BackgroundColor3 = F[key .. "Bg"] or Theme.LineSoft
			f.BackgroundColor3 = (F[key .. "Empty"] or Theme.Line):Lerp(F[key .. "Color"] or Theme.Accent, pct)
			if side == "bottom" then
				track.Size, track.Position = UDim2.new(1, 0, 0, size), UDim2.new(0, 0, 1, 4)
				f.Size = UDim2.fromScale(pct, 1)
			else
				track.Size = UDim2.new(0, size, 1, 0)
				track.Position = side == "left" and UDim2.new(0, -(size + 4), 0, 0) or UDim2.new(1, 4, 0, 0)
				f.Size = UDim2.fromScale(1, pct)
			end
			return size
		end
		bar("EspHealth", hTrack, hFill, hp, "left")
		bar("EspArmor", aTrack, aFill, 0.4, "right")
		local ammo = bar("EspAmmo", amTrack, amFill, 0.6, "bottom")

		local function text(lbl, key, flag)
			lbl.Visible = F[flag] == true
			lbl.TextColor3 = F[key .. "Color"] or Theme.Text
			lbl.TextSize = F[key .. "Size"] or 12
			lbl.Size = UDim2.fromOffset(200, lbl.TextSize + 2)
			return lbl.Visible and lbl.TextSize + 3 or 0
		end
		text(nameLbl, "EspName", "EspNames")
		local y = BOX_H + 4 + (ammo > 0 and ammo + 4 or 0)
		weaponLbl.Position = UDim2.new(0.5, 0, 0, y)
		y += text(weaponLbl, "EspWeapon", "EspWeapon")
		distLbl.Position = UDim2.new(0.5, 0, 0, y)
		text(distLbl, "EspDistance", "EspDistance")

		tracer.Visible = F.EspTracers == true
		tracer.BackgroundColor3 = F.EspTracerColor or Theme.Accent
		local th = F.EspTracerThickness or 1
		if (F.EspTracerOrigin or "Bottom") == "Bottom" then
			tracer.AnchorPoint, tracer.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 1)
		else
			tracer.AnchorPoint, tracer.Position = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0)
		end
		tracer.Size = UDim2.fromOffset(th, 600)
	end

	local hit = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = boxRoot })
	hit.MouseButton1Click:Connect(function()
		hp = hp <= 0.21 and 1 or hp - 0.2
		refresh()
	end)

	Library._anyFlag = function(flag)
		if string.sub(flag, 1, 3) == "Esp" then refresh(); paintChips() end
	end
	table.insert(Library._refresh, function() refresh(); paintChips() end)

	local function applyVisibility()
		local show = open and (not VisualsTab or Window.Current == VisualsTab)
		panel.Visible = show
		if Window.EspButton then Window.EspButton.Text = open and "Hide ESP Preview" or "ESP Preview" end
		Window:SetExtraRight(show and (PANEL_W + GAP) or 0)
	end
	function Window:ToggleEspPreview()
		open = not open
		applyVisibility()
	end
	Window.OnTabSelected = applyVisibility
	refresh()
	paintChips()
end

function Library:CreateMenuBackdrop(Window)
	local Lighting = game:GetService("Lighting")
	local blur = Lighting:FindFirstChild("LunaMenuBlur") or Instance.new("BlurEffect")
	blur.Name, blur.Size, blur.Parent = "LunaMenuBlur", 0, Lighting
	local dim = create("Frame", {
		BackgroundColor3 = Theme.Ground, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = Library.Gui,
	})
	local function apply()
		local on = Window.Visible and Library.Flags.MenuBlur
		tween(blur, { Size = on and 12 or 0 }, 0.2)
		tween(dim, { BackgroundTransparency = on and 0.55 or 1 }, 0.2)
	end
	Window.OnVisibleChanged = apply
	Library:OnChanged("MenuBlur", apply)
	Library:OnUnload(function() blur:Destroy() end)
end

getgenv().LunaLibrary = Library

	local Adapter = {}

	Adapter.Theme = {
		Background = Color3.fromHex("#161826"),
		Panel = Color3.fromHex("#232532"),
		PanelLight = Color3.fromHex("#1b1d2b"),
		Border = Color3.fromHex("#3f424d"),
		Text = Color3.fromHex("#e9e9ed"),
		SubText = Color3.fromHex("#9397ab"),
		Accent = Color3.fromHex("#9184d9"),
		AccentDark = Color3.fromHex("#6f65a8"),
		Success = Color3.fromRGB(120, 200, 120),
		Danger = Color3.fromRGB(175, 21, 21),
	}

	local KeyCodes = {}
	for _, name in ipairs({
		"LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt",
		"Insert", "Delete", "Home", "End", "PageUp", "PageDown", "Space", "Return", "Tab",
		"Escape", "Backspace", "Up", "Down", "Left", "Right", "CapsLock",
		"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
	}) do
		KeyCodes[name] = Enum.KeyCode[name]
	end
	for i = 0, 25 do
		local letter = string.char(65 + i)
		KeyCodes[letter] = Enum.KeyCode[letter]
	end
	local DIGIT_NAMES = { [0] = "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
	for i = 0, 9 do
		KeyCodes[tostring(i)] = Enum.KeyCode[DIGIT_NAMES[i]]
	end
	setmetatable(KeyCodes, {
		__index = function(t, name)
			if type(name) ~= "string" then return nil end
			local ok, code = pcall(function() return Enum.KeyCode[name] end)
			if ok and typeof(code) == "EnumItem" then
				rawset(t, name, code)
				return code
			end
			return nil
		end,
	})
	Adapter.KeyCodes = KeyCodes

	Adapter.ThemeNames = Library.ThemeNames

	local function keyToName(key)
		if key == nil then return nil end
		if typeof(key) == "EnumItem" then return key.Name end
		return nil
	end

	function Adapter.ExportConfig()
		local data = {}
		for flag, ctrl in pairs(Library.Options) do
			local ok, value = pcall(function() return ctrl:Get() end)
			if ok then data[flag] = value end
		end
		return data
	end
	function Adapter.ApplyConfig(data)
		if type(data) ~= "table" then return 0 end
		local applied = 0
		for flag, value in pairs(data) do
			local ctrl = Library.Options[flag]
			if ctrl and typeof(ctrl.Set) == "function" then
				local ok = pcall(function() ctrl:Set(value) end)
				if ok then applied = applied + 1 end
			end
		end
		return applied
	end

	local usedFlags = {}
	local function makeFlag(owner, name, kind)
		local prefix = (owner and owner._configPrefix) or "General"
		local base = prefix .. " > " .. (name or kind)
		local flag = base
		local suffix = 1
		while usedFlags[flag] do
			suffix = suffix + 1
			flag = base .. " #" .. suffix
		end
		usedFlags[flag] = true
		return flag
	end

	local Section = {}
	Section.__index = Section

	function Section:Toggle(opts)
		opts = opts or {}
		local flag = makeFlag(self, opts.Name, "toggle")
		return self._group:AddToggle({
			Text = opts.Name or "",
			Default = opts.Default and true or false,
			Flag = flag,
			Tooltip = opts.Tooltip,
			Callback = function(v) if opts.Callback then pcall(opts.Callback, v) end end,
		})
	end

	function Section:Slider(opts)
		opts = opts or {}
		local flag = makeFlag(self, opts.Name, "slider")
		return self._group:AddSlider({
			Text = opts.Name or "",
			Min = opts.Min or 0,
			Max = opts.Max or 100,
			Step = opts.Step or 1,
			Default = opts.Default or opts.Min or 0,
			Suffix = opts.Suffix,
			Decimals = opts.Decimals,
			Flag = flag,
			Tooltip = opts.Tooltip,
			Callback = function(v) if opts.Callback then pcall(opts.Callback, v) end end,
		})
	end

	local Label = {}
	Label.__index = Label

	function Label:AddKeybind(opts)
		opts = opts or {}
		local flag = makeFlag(self._owner, opts.ConfigName or self._text, "keybind")
		local defaultKey = opts.Default and Adapter.KeyCodes[opts.Default] or nil
		local bind = self._group:AddKeybind({
			Text = self._text or "",
			Default = defaultKey,
			Flag = flag,
			KeyOnly = true,
			Tooltip = opts.Tooltip,
			SyncToggle = opts.SyncToggle,
			KeyChanged = function(key)
				if opts.OnChanged then pcall(opts.OnChanged, keyToName(key)) end
			end,
		})
		Library.Keybinds = Library.Keybinds or {}
		table.insert(Library.Keybinds, { Text = self._text or "", Bind = bind })
		return self
	end

	function Section:Label(text)
		local native = self._group:AddLabel(text or "")
		local state = { text = text or "" }
		return setmetatable({}, {
			__index = function(t, k)
				if k == "text" then return state.text end
				if k == "AddKeybind" then
					return function(_, opts)
						local proxy = setmetatable({ _text = state.text, _group = self._group, _owner = self }, Label)
						return proxy:AddKeybind(opts)
					end
				end
				return nil
			end,
			__newindex = function(t, k, v)
				if k == "text" then
					state.text = v
					native.Text = v
				end
			end,
		})
	end

	function Section:TextBox(opts)
		opts = opts or {}
		local flag = makeFlag(self, opts.Name, "textbox")
		local box = self._group:AddTextBox({
			Text = opts.Name,
			Default = opts.Default or "",
			Placeholder = opts.Placeholder,
			Flag = flag,
			Numeric = opts.Numeric,
			Tooltip = opts.Tooltip,
			Callback = function(v) if opts.OnChanged then pcall(opts.OnChanged, v, true) end end,
		})
		return {
			Get = function(_) return box.Text end,
			Set = function(_, text) box.Text = text or "" end,
			_native = box,
		}
	end

	function Section:Button(opts)
		opts = opts or {}
		return self._group:AddButton({
			Text = opts.Name or "Button",
			Tooltip = opts.Tooltip,
			Callback = function() if opts.Callback then pcall(opts.Callback) end end,
		})
	end

	function Section:Color(opts)
		opts = opts or {}
		local flag = makeFlag(self, opts.Name, "color")
		local default = opts.Default
		if typeof(default) == "Color3" then default = "#" .. default:ToHex() end
		local alphaFlag = opts.Transparency and makeFlag(self, (opts.Name or "Color") .. " Transparency", "slider") or nil
		local ctrl = self._group:AddColor({
			Text = opts.Name or "",
			Default = default,
			Flag = flag,
			Tooltip = opts.Tooltip,
			Transparency = opts.Transparency,
			DefaultTransparency = opts.DefaultTransparency,
			AlphaFlag = alphaFlag,
			AlphaCallback = function(a) if opts.TransparencyCallback then pcall(opts.TransparencyCallback, 1 - a) end end,
			Callback = function(v) if opts.Callback then pcall(opts.Callback, v) end end,
		})
		return {
			Get = function(_) return Color3.fromHex(ctrl:Get()) end,
			Set = function(_, v) ctrl:Set(v) end,
			GetTransparency = function(_) return 1 - ctrl:GetAlpha() end,
			SetTransparency = function(_, t) ctrl:SetAlpha(1 - t) end,
			_native = ctrl,
		}
	end

	function Section:Divider()
		self._group:AddDivider()
	end

	function Section:Paragraph(opts)
		opts = opts or {}
		self._group:AddParagraph({ Title = opts.Title, Content = opts.Content, Tooltip = opts.Tooltip })
	end

	local function wrapGetSet(native)
		return {
			Get = function(_) return native:Get() end,
			Set = function(_, v) native:Set(v) end,
			_native = native,
		}
	end

	function Section:Selector(opts)
		opts = opts or {}
		local flag = not opts.NoConfig and makeFlag(self, opts.Name or "Selector", "selector") or nil
		local dropdown = self._group:AddDropdown({
			Options = opts.Options or {},
			Multi = opts.Multi,
			Default = opts.Default or (not opts.Multi and opts.Options and opts.Options[1]) or nil,
			Flag = flag,
			Callback = function(v) if opts.Callback then pcall(opts.Callback, v) end end,
		})
		return wrapGetSet(dropdown)
	end

	local groupCounter = 0
	function Section:Group(opts)
		opts = opts or {}
		groupCounter = groupCounter + 1
		local prefix
		if opts.Name then
			prefix = self._configPrefix and (self._configPrefix .. " - " .. opts.Name) or opts.Name
		else
			prefix = (self._configPrefix or "Group") .. " " .. groupCounter
		end

		local nativeGroup = self._container:AddGroup(opts.Name or prefix, self._column)
		local group = setmetatable({
			_group = nativeGroup, _container = self._container, _column = self._column,
			_configPrefix = prefix, side = self._column,
			_window = self._window, _topTab = self._topTab,
		}, Section)
		group._frame = nativeGroup.Frame
		return group
	end

	function Section:EspPreviewButton(opts)
		opts = opts or {}
		if not self._window then return nil end
		local btn = self._group:AddButton({
			Text = opts.Name or "ESP Preview",
			Callback = function() self._window:ToggleEspPreview() end,
		})
		self._window.EspButton = btn
		if not self._window._espPreviewBuilt then
			Library:CreateEspPreview(self._window, self._topTab)
			self._window._espPreviewBuilt = true
		end
		return btn
	end

	function Section:KeybindsOverlaySection(opts)
		opts = opts or {}
		if not Library._keybindListBuilt then
			Library:CreateKeybindList()
			Library._keybindListBuilt = true
		end
		local enableToggle = self._group:AddToggle({
			Text = "Keybinds Overlay", Flag = "KeybindList", Default = opts.Default ~= false,
		})
		self._group:AddToggle({ Text = "Only Active Binds", Flag = "KeybindListActive", Default = false })
		self._group:AddSlider({ Text = "Overlay Transparency", Flag = "KeybindListTransparency", Min = 0, Max = 90, Default = 0, Suffix = "%" })
		return enableToggle
	end

	local TabWrap = {}
	TabWrap.__index = TabWrap

	function TabWrap:Section(opts)
		opts = opts or {}
		local column = (opts.Side == 2) and 2 or 1
		local nativeGroup = self._native:AddGroup(opts.Name or "", column)
		return setmetatable({
			_group = nativeGroup, _container = self._native, _column = column,
			_configPrefix = opts.Name, side = column,
			_window = self._window, _topTab = self._topTab,
		}, Section)
	end

	function TabWrap:BottomSelector(opts)
		opts = opts or {}
		local name = (self._configPrefix and (self._configPrefix .. " ") or "") .. "Actions"
		local nativeGroup = self._native:AddGroup(name, opts.Column or 2)
		local dropdown = nativeGroup:AddDropdown({
			Options = opts.Options or {},
			Default = opts.Default or (opts.Options and opts.Options[1]),
			Callback = function(v) if opts.Callback then pcall(opts.Callback, v) end end,
		})
		return wrapGetSet(dropdown)
	end

	local SideNav = {}
	SideNav.__index = SideNav

	function SideNav:Page(opts)
		opts = opts or {}
		local nativeSub = self._nativeTab:AddSubTab(opts.Name or "Page")
		return setmetatable({
			_native = nativeSub, _configPrefix = opts.Name,
			_window = self._window, _topTab = self._topTab,
		}, TabWrap)
	end

	function TabWrap:SideNav(opts)
		return setmetatable({ _nativeTab = self._native, _window = self._window, _topTab = self._topTab }, SideNav)
	end

	local Window = {}
	Window.__index = Window

	function Window:Tab(opts)
		opts = opts or {}
		local nativeTab = self._native:AddTab(opts.Name or "Tab", opts.Icon)
		return setmetatable({
			_native = nativeTab, _configPrefix = opts.Name,
			_window = self._native, _topTab = nativeTab,
		}, TabWrap)
	end

	function Window:Destroy()
		Library:Unload()
	end

	function Window:SetDPI(scale)
		self._native:SetDPI(scale)
	end

	function Window:SetTheme(name)
		Library:SetTheme(name)
	end
	function Window:SetAccent(color)
		Library:SetAccent(color)
	end

	function Window:Dialog(opts)
		return Library:CreateDialog(opts)
	end

	function Window:ResetToDefault()
		Library:ResetToDefault()
	end

	function Adapter:Window(opts)
		opts = opts or {}
		local nativeWindow = Library:CreateWindow({ Title = opts.Title or "" })
		Library:CreateMenuBackdrop(nativeWindow)

		return setmetatable({ _native = nativeWindow }, {
			__index = function(t, k)
				if k == "keybind" then return Library.ToggleKey end
				if k == "blurEnabled" then return Library.Flags.MenuBlur == true end
				return Window[k]
			end,
			__newindex = function(t, k, v)
				if k == "keybind" then
					Library.ToggleKey = v
				elseif k == "blurEnabled" then
					Library:SetFlag("MenuBlur", v == true)
				else
					rawset(t, k, v)
				end
			end,
		})
	end

	function Adapter:StatusBar(opts)
		opts = opts or {}
		local name = opts.Name or "Luna"
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local LocalPlayer = Players.LocalPlayer

		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, -16, 0, 16)
		frame.Size = UDim2.fromOffset(0, 24)
		frame.AutomaticSize = Enum.AutomaticSize.X
		frame.BackgroundColor3 = Adapter.Theme.Panel
		frame.BorderSizePixel = 0
		frame.ZIndex = 5
		frame.Parent = Library.Gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Adapter.Theme.Border
		stroke.Parent = frame
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = frame

		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.Gotham
		text.TextSize = 13
		text.TextColor3 = Adapter.Theme.Text
		text.Size = UDim2.new(0, 0, 1, 0)
		text.AutomaticSize = Enum.AutomaticSize.X
		text.Parent = frame

		local frameCount, elapsed = 0, 0
		local updateConn = RunService.RenderStepped:Connect(function(dt)
			frameCount = frameCount + 1
			elapsed = elapsed + dt
			if elapsed >= 0.5 then
				local fps = math.floor(frameCount / elapsed + 0.5)
				local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
				text.Text = string.format("%s  |  %s  |  %d fps  |  %d ms", name, LocalPlayer.Name, fps, ping)
				frameCount, elapsed = 0, 0
			end
		end)

		Library:MakeDraggable(frame)

		local posObj = {}
		function posObj:Get()
			local pos = frame.Position
			return {
				AX = frame.AnchorPoint.X, AY = frame.AnchorPoint.Y,
				SX = pos.X.Scale, OX = pos.X.Offset,
				SY = pos.Y.Scale, OY = pos.Y.Offset,
			}
		end
		function posObj:Set(v)
			if type(v) ~= "table" then return end
			frame.AnchorPoint = Vector2.new(v.AX or 1, v.AY or 0)
			frame.Position = UDim2.new(v.SX or 1, v.OX or -16, v.SY or 0, v.OY or 16)
		end
		Library.Options["Watermark Position"] = posObj

		return {
			Destroy = function()
				updateConn:Disconnect()
				frame:Destroy()
			end,
		}
	end

	return Adapter
