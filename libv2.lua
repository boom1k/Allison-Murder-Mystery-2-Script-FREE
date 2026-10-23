--//Made by astral @semi_final and ChatGPT Astra 6 at Ultra
--//R.I.P Turkey Boy (Samet)



--//ui
local Environment = _G
pcall(function()
    if type(getgenv) == "function" then
        local Shared = getgenv()
        if type(Shared) == "table" then
            Environment = Shared
        end
    end
end)
local PreviousSessions = {}
for _, Shared in { _G, Environment } do
    local Previous = Shared.MyhoeUI
    if type(Previous) == "table" and not PreviousSessions[Previous] then
        PreviousSessions[Previous] = true
        if type(Previous.Destroy) == "function" then
            pcall(function()
                Previous:Destroy()
            end)
        end
    end
end
table.clear(PreviousSessions)

-- Core/Scope
local ConnectionManager = (function()
    local Scope = {}
    Scope.__index = Scope

    local function Dispose(Resource)
        local Kind = typeof(Resource)
        if Kind == "RBXScriptConnection" then
            Resource:Disconnect()
        elseif Kind == "Instance" then
            Resource:Destroy()
        elseif Kind == "function" then
            Resource()
        elseif Kind == "thread" then
            if coroutine.status(Resource) ~= "dead" then
                task.cancel(Resource)
            end
        elseif Kind == "table" then
            local Method = Resource.Destroy or Resource.Disconnect or Resource.Cancel
            if Method then
                Method(Resource)
            end
        end
    end

    function Scope.New()
        return setmetatable({ Alive = true, _resources = {}, _sequence = 0 }, Scope)
    end

    function Scope:Add(Resource)
        if Resource == nil then
            return nil
        end
        if not self.Alive then
            local Success, Reason = pcall(Dispose, Resource)
            if not Success then
                warn("Myhoe cleanup: " .. tostring(Reason))
            end
            return Resource
        end
        if self._resources[Resource] == nil then
            self._sequence += 1
            self._resources[Resource] = self._sequence
        end
        return Resource
    end

    function Scope:Remove(Resource)
        self._resources[Resource] = nil
        return Resource
    end

    function Scope:Connect(Signal: RBXScriptSignal, Callback)
        if not self.Alive then
            return nil
        end
        return self:Add(Signal:Connect(function(...)
            if self.Alive then
                Callback(...)
            end
        end))
    end

    function Scope:Delay(Seconds: number, Callback)
        if not self.Alive then
            return nil
        end
        local Pending = true
        local Thread
        local Cancel
        Cancel = function()
            if not Pending then
                return
            end
            Pending = false
            self:Remove(Cancel)
            if Thread and coroutine.status(Thread) ~= "dead" then
                pcall(task.cancel, Thread)
            end
        end
        self:Add(Cancel)
        Thread = task.delay(math.max(0, Seconds), function()
            if not Pending then
                return
            end
            Pending = false
            self:Remove(Cancel)
            if self.Alive then
                local Success, Reason = pcall(Callback)
                if not Success then
                    warn("Myhoe scheduled callback: " .. tostring(Reason))
                end
            end
        end)
        return Cancel
    end

    function Scope:Child()
        local Child = Scope.New()
        Child._parent = self
        return self:Add(Child)
    end

    function Scope:Destroy()
        if not self.Alive then
            return
        end
        self.Alive = false
        if self._parent then
            self._parent:Remove(self)
            self._parent = nil
        end
        local Resources = {}
        for Resource, Sequence in self._resources do
            table.insert(Resources, { Resource = Resource, Sequence = Sequence })
        end
        table.clear(self._resources)
        table.sort(Resources, function(First, Second)
            return First.Sequence > Second.Sequence
        end)
        for _, Entry in Resources do
            local Success, Reason = pcall(Dispose, Entry.Resource)
            if not Success then
                warn("Myhoe cleanup: " .. tostring(Reason))
            end
        end
    end

    return Scope
end)()

-- Core/Palettes
local ThemePalettes = (function()
    local function Palette(Background, Surface, Text, Element, Accent, Border, Muted, Shadow, Gradient, Hover)
        return {
            Background = Color3.fromRGB(unpack(Background)),
            Surface = Color3.fromRGB(unpack(Surface)),
            Text = Color3.fromRGB(unpack(Text)),
            Raised = Color3.fromRGB(unpack(Element)),
            Accent = Color3.fromRGB(unpack(Accent)),
            Border = Color3.fromRGB(unpack(Border)),
            SubText = Color3.fromRGB(unpack(Muted)),
            Shadow = Color3.fromRGB(unpack(Shadow or { 0, 0, 0 })),
            Image = Color3.new(1, 1, 1),
            DarkGradient = Color3.fromRGB(unpack(Gradient or { 211, 211, 211 })),
            Hover = Color3.fromRGB(unpack(Hover or { 46, 53, 61 })),
        }
    end
    return {
        Myhoe = Palette(
            { 21, 23, 25 },
            { 26, 28, 31 },
            { 221, 237, 241 },
            { 42, 45, 50 },
            { 147, 181, 255 },
            { 37, 40, 44 },
            { 102, 109, 111 }
        ),
        Preset = Palette(
            { 16, 18, 21 },
            { 22, 25, 29 },
            { 255, 255, 255 },
            { 34, 39, 45 },
            { 196, 231, 255 },
            { 32, 36, 42 },
            { 185, 185, 185 }
        ),
        Halloween = Palette(
            { 11, 10, 9 },
            { 23, 18, 16 },
            { 198, 198, 198 },
            { 42, 32, 26 },
            { 253, 133, 21 },
            { 42, 35, 32 },
            { 179, 179, 179 },
            { 253, 133, 21 },
            { 211, 202, 195 }
        ),
        Aqua = Palette(
            { 19, 21, 23 },
            { 31, 35, 39 },
            { 245, 245, 245 },
            { 58, 66, 77 },
            { 31, 106, 181 },
            { 48, 56, 63 },
            { 185, 185, 185 }
        ),
        ["One Tap"] = Palette(
            { 51, 51, 51 },
            { 30, 30, 30 },
            { 245, 245, 245 },
            { 45, 45, 45 },
            { 237, 170, 0 },
            { 0, 0, 0 },
            { 185, 185, 185 }
        ),
        Midnight = Palette(
            { 16, 20, 30 },
            { 23, 29, 42 },
            { 224, 231, 245 },
            { 34, 43, 60 },
            { 123, 163, 238 },
            { 38, 46, 64 },
            { 126, 139, 162 },
            nil,
            { 204, 215, 234 },
            { 45, 58, 81 }
        ),
        Rose = Palette(
            { 28, 21, 25 },
            { 38, 29, 35 },
            { 240, 224, 232 },
            { 54, 42, 49 },
            { 222, 147, 177 },
            { 58, 44, 53 },
            { 162, 132, 147 },
            nil,
            { 224, 207, 216 },
            { 70, 52, 64 }
        ),
        Jade = Palette(
            { 18, 26, 24 },
            { 26, 36, 32 },
            { 222, 237, 229 },
            { 39, 51, 45 },
            { 125, 194, 161 },
            { 42, 57, 50 },
            { 126, 151, 138 },
            nil,
            { 203, 224, 213 },
            { 48, 67, 57 }
        ),
        Amber = Palette(
            { 28, 24, 18 },
            { 38, 32, 23 },
            { 241, 231, 213 },
            { 54, 45, 31 },
            { 219, 179, 102 },
            { 59, 49, 34 },
            { 167, 148, 113 },
            nil,
            { 231, 220, 197 },
            { 73, 60, 39 }
        ),
        Slate = Palette(
            { 26, 29, 33 },
            { 34, 38, 43 },
            { 231, 235, 241 },
            { 49, 55, 63 },
            { 172, 188, 212 },
            { 56, 63, 72 },
            { 145, 154, 166 },
            nil,
            { 214, 218, 224 },
            { 63, 71, 83 }
        ),
        Coffee = Palette(
            { 27, 22, 20 },
            { 37, 30, 27 },
            { 236, 225, 211 },
            { 52, 42, 36 },
            { 192, 157, 123 },
            { 59, 47, 40 },
            { 158, 138, 122 },
            nil,
            { 221, 208, 192 },
            { 69, 55, 46 }
        ),
    }
end)()

-- Core/Motion
local Animation = (function()
    local TweenService = game:GetService("TweenService")

    local Motion = {}
    local Active = setmetatable({}, { __mode = "k" })

    Motion.Presets = table.freeze({
        Hover = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Fast = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Control = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        PopupClose = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        BindRow = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Hud = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Focus = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Press = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Toggle = TweenInfo.new(0.17, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
        Slider = TweenInfo.new(0.055, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        Popup = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Page = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Tab = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Window = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Close = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        Notification = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    })

    function Motion.Cancel(Instance: Instance, Property: string)
        local Slots = Active[Instance]
        if Slots and Slots[Property] then
            Slots[Property].Cancel()
        end
    end

    function Motion.To(CleanupScope, Instance: Instance, Preset, Properties)
        if CleanupScope and not CleanupScope.Alive then
            return nil
        end
        local Info = if typeof(Preset) == "TweenInfo" then Preset else Motion.Presets[Preset or "Hover"]
        assert(Info, "Unknown motion preset: " .. tostring(Preset))
        local Slots = Active[Instance]
        if not Slots then
            Slots = {}
            Active[Instance] = Slots
        end
        local Group = { Tweens = {} }
        local Records = {}
        function Group:Cancel()
            for Record in Records do
                Record.Cancel()
            end
        end
        Group.Destroy = Group.Cancel
        for Property, Goal in Properties do
            if Slots[Property] then
                Slots[Property].Cancel()
            end
            Active[Instance] = Slots
            local Tween = TweenService:Create(Instance, Info, { [Property] = Goal })
            local Record = {}
            local Completed
            local Finished = false
            local function Release(Cancelled)
                if Finished then
                    return
                end
                Finished = true
                if Completed then
                    Completed:Disconnect()
                    Completed = nil
                end
                if Slots[Property] == Record then
                    Slots[Property] = nil
                end
                if next(Slots) == nil then
                    Active[Instance] = nil
                end
                Records[Record] = nil
                if CleanupScope and CleanupScope.Remove then
                    CleanupScope:Remove(Record.Cancel)
                end
                if Cancelled then
                    Tween:Cancel()
                end
            end
            Record.Cancel = function()
                Release(true)
            end
            Records[Record] = true
            Slots[Property] = Record
            table.insert(Group.Tweens, Tween)
            Completed = Tween.Completed:Connect(function()
                Release(false)
            end)
            if CleanupScope then
                CleanupScope:Add(Record.Cancel)
            end
            if not Finished then
                Tween:Play()
            end
        end
        return Group
    end

    return Motion
end)()

-- Core/Signal
local Signal = (function()
    local Signal = {}
    Signal.__index = Signal

    function Signal.New()
        return setmetatable({ Subscribers = {}, Destroyed = false }, Signal)
    end

    function Signal:Subscribe(Callback, Scope)
        assert(type(Callback) == "function", "Subscriptions require a callback")
        if self.Destroyed then
            return function() end
        end
        local Subscriber = { Callback = Callback }
        local Cleanup
        Cleanup = function()
            self.Subscribers[Subscriber] = nil
            if Scope then
                Scope:Remove(Cleanup)
            end
        end
        self.Subscribers[Subscriber] = true
        Subscriber.Cleanup = Cleanup
        if Scope then
            Scope:Add(Cleanup)
        end
        return Cleanup
    end

    function Signal:Fire(...)
        for Subscriber in table.clone(self.Subscribers) do
            if self.Subscribers[Subscriber] then
                local Success, Reason = pcall(Subscriber.Callback, ...)
                if not Success then
                    warn("Myhoe subscription: " .. tostring(Reason))
                end
            end
        end
    end

    function Signal:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        for Subscriber in table.clone(self.Subscribers) do
            Subscriber.Cleanup()
        end
    end

    return Signal
end)()

-- Core/Theme
local ThemeManager = (function()
    local Motion = Animation
    local Signal = Signal

    local Theme = {}
    Theme.__index = Theme

    local function FontEnum(Name, Fallback)
        local Success, ValueValue = pcall(function()
            return Enum.Font[Name]
        end)
        return if Success then ValueValue else Fallback
    end

    -- FontFace and palette are read from the supplied Myhoe ScreenGui.
    local BodyFont = Enum.Font.BuilderSansMedium
    local BodyFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold)
    local Defaults = table.freeze({
        Canvas = Color3.fromRGB(21, 23, 25),
        Background = Color3.fromRGB(21, 23, 25),
        Sidebar = Color3.fromRGB(21, 23, 25),
        Popup = Color3.fromRGB(26, 28, 31),
        Notification = Color3.fromRGB(14, 15, 18),
        Surface = Color3.fromRGB(26, 28, 31),
        Raised = Color3.fromRGB(42, 45, 50),
        Header = Color3.fromRGB(26, 28, 31),
        SectionHeader = Color3.fromRGB(29, 30, 34),
        SurfaceSecondary = Color3.fromRGB(42, 45, 50),
        Hover = Color3.fromRGB(46, 53, 61),
        Accent = Color3.fromRGB(147, 181, 255),
        AccentSoft = Color3.fromRGB(39, 48, 65),
        NavSelected = Color3.fromRGB(32, 34, 38),
        SliderFill = Color3.fromRGB(147, 181, 255),
        AccentMuted = Color3.fromRGB(147, 181, 255),
        Track = Color3.fromRGB(42, 45, 50),
        SliderTrack = Color3.fromRGB(42, 45, 50),
        Unchecked = Color3.fromRGB(42, 45, 50),
        CheckboxOff = Color3.fromRGB(42, 45, 50),
        Chip = Color3.fromRGB(42, 45, 50),
        Text = Color3.fromRGB(221, 237, 241),
        TextSecondary = Color3.fromRGB(102, 109, 111),
        TextDisabled = Color3.fromRGB(108, 112, 122),
        HeaderText = Color3.fromRGB(250, 250, 250),
        LogoText = Color3.fromRGB(221, 237, 241),
        LogoHighlight = Color3.fromRGB(147, 181, 255),
        InactiveTab = Color3.fromRGB(102, 109, 111),
        ProfileText = Color3.fromRGB(147, 181, 255),
        ProfileName = Color3.fromRGB(147, 181, 255),
        SearchIcon = Color3.fromRGB(102, 109, 111),
        CategoryText = Color3.fromRGB(102, 109, 111),
        SubText = Color3.fromRGB(102, 109, 111),
        DimText = Color3.fromRGB(102, 109, 111),
        Border = Color3.fromRGB(37, 40, 44),
        BorderActive = Color3.fromRGB(147, 181, 255),
        SubtleBorder = Color3.fromRGB(37, 40, 44),
        MutedText = Color3.fromRGB(102, 109, 111),
        Surface2 = Color3.fromRGB(42, 45, 50),
        Selected = Color3.fromRGB(39, 48, 65),
        Disabled = Color3.fromRGB(108, 112, 122),
        Success = Color3.fromRGB(174, 255, 0),
        Warning = Color3.fromRGB(255, 225, 0),
        Error = Color3.fromRGB(255, 60, 63),
        BindAccent = Color3.fromRGB(221, 237, 241),
        Shadow = Color3.new(0, 0, 0),
        Image = Color3.new(1, 1, 1),
        DarkGradient = Color3.fromRGB(211, 211, 211),
        White = Color3.new(1, 1, 1),
        Black = Color3.new(0, 0, 0),
        Font = BodyFont,
        FontMedium = BodyFont,
        FontBold = BodyFont,
        FontFace = BodyFace,
        FontFaceMedium = BodyFace,
        FontFaceBold = BodyFace,
        TextSize = 14,
        Radius = 5,
        BackgroundTransparency = 0,
        SurfaceTransparency = 0,
    })

    local Aliases = table.freeze({
        { "MutedText", "SubText" },
        { "DimText", "SubText" },
        { "Surface2", "Raised" },
        { "Selected", "AccentSoft" },
        { "CheckboxOff", "Unchecked" },
        { "ProfileText", "ProfileName" },
        { "SubtleBorder", "Border" },
        { "TextSecondary", "SubText" },
        { "TextDisabled", "Disabled" },
        { "SurfaceSecondary", "Raised" },
        { "Header", "SectionHeader" },
        { "AccentMuted", "SliderFill" },
        { "SliderTrack", "Track" },
    })
    Theme.FontRoles =
        table.freeze({ Font = "FontFace", FontMedium = "FontFaceMedium", FontBold = "FontFaceBold" })

    local function Validate(Overrides)
        assert(type(Overrides) == "table", "Theme overrides must be a table")
        for TokenValue, ValueValue in Overrides do
            local Default = Defaults[TokenValue]
            assert(Default ~= nil, "Unknown theme token: " .. tostring(TokenValue))
            assert(typeof(ValueValue) == typeof(Default), "Invalid theme value for " .. TokenValue)
            if typeof(Default) == "EnumItem" then
                assert(ValueValue.EnumType == Enum.Font, "Font must be an Enum.Font value")
            elseif typeof(Default) == "number" then
                assert(
                    ValueValue == ValueValue and ValueValue >= 0 and ValueValue < math.huge,
                    "Invalid theme metric: " .. TokenValue
                )
                if TokenValue == "BackgroundTransparency" or TokenValue == "SurfaceTransparency" then
                    assert(ValueValue <= 1, "Theme transparency must be between 0 and 1: " .. TokenValue)
                end
            end
        end
    end

    function Theme.New(Overrides)
        local self = setmetatable({
            Values = table.clone(Defaults),
            Changed = Signal.New(),
            _bindings = {},
            _properties = setmetatable({}, { __mode = "k" }),
        }, Theme)
        if Overrides then
            self:Set(Overrides)
        end
        return self
    end

    function Theme:Bind(CleanupScope, Instance: Instance, Property: string, TokenValue)
        assert(
            type(TokenValue) == "function" or self.Values[TokenValue] ~= nil,
            "Unknown theme binding: " .. tostring(TokenValue)
        )
        local Properties = self._properties[Instance]
        if not Properties then
            Properties = {}
            self._properties[Instance] = Properties
        end
        if Properties[Property] then
            Properties[Property].Cleanup()
        end
        local Binding = { Instance = Instance, Property = Property, Token = TokenValue }
        local Removed = false
        local Cleanup
        Cleanup = function()
            if Removed then
                return
            end
            Removed = true
            self._bindings[Binding] = nil
            if Properties[Property] == Binding then
                Properties[Property] = nil
            end
            if next(Properties) == nil then
                self._properties[Instance] = nil
            end
            if CleanupScope and CleanupScope.Remove then
                CleanupScope:Remove(Cleanup)
            end
        end
        Binding.Cleanup = Cleanup
        Properties[Property] = Binding
        self._properties[Instance] = Properties
        self._bindings[Binding] = true
        if CleanupScope then
            CleanupScope:Add(Cleanup)
        end
        if not Removed then
            local Success, Reason = pcall(function()
                local ValueValue = if type(TokenValue) == "function"
                    then TokenValue(self.Values)
                    else self.Values[TokenValue]
                Motion.Cancel(Instance, Property)
                Instance[Property] = ValueValue
                Binding.Value = ValueValue
            end)
            if not Success then
                Cleanup()
                error(Reason, 2)
            end
        end
        return Cleanup
    end

    function Theme:Set(Overrides)
        Validate(Overrides)
        local Previous = table.clone(self.Values)
        for TokenValue, ValueValue in Overrides do
            self.Values[TokenValue] = ValueValue
        end
        for Role, Face in Theme.FontRoles do
            if Overrides[Role] ~= nil and Overrides[Face] == nil then
                self.Values[Face] = Font.fromEnum(Overrides[Role])
            end
        end
        local Changed = {}
        for _, Pair in Aliases do
            local Alias, Canonical = Pair[1], Pair[2]
            if Overrides[Alias] ~= nil and Overrides[Canonical] == nil and not Changed[Canonical] then
                self.Values[Canonical], Changed[Canonical] = Overrides[Alias], true
            end
        end
        for _, Pair in Aliases do
            self.Values[Pair[1]] = self.Values[Pair[2]]
        end
        self:Refresh()
        local Changes = {}
        for Token, Value in self.Values do
            if Previous[Token] ~= Value then
                Changes[Token] = Value
            end
        end
        if next(Changes) then
            self.Changed:Fire(self, "Theme", Changes)
        end
        return self
    end

    function Theme:Subscribe(Callback, Scope)
        return self.Changed:Subscribe(Callback, Scope)
    end

    function Theme:Validate(Values)
        Validate(Values)
        return true
    end

    function Theme:GetSerializable()
        local Result = {}
        for Token, Value in self.Values do
            if typeof(Value) == "Color3" or type(Value) == "number" then
                Result[Token] = Value
            end
        end
        return Result
    end

    function Theme:Refresh()
        for Binding in self._bindings do
            local Success, Reason = pcall(function()
                local TokenValue = Binding.Token
                local ValueValue = if type(TokenValue) == "function"
                    then TokenValue(self.Values)
                    else self.Values[TokenValue]
                if ValueValue ~= Binding.Value then
                    Motion.Cancel(Binding.Instance, Binding.Property)
                end
                Binding.Instance[Binding.Property] = ValueValue
                Binding.Value = ValueValue
            end)
            if not Success then
                Binding.Cleanup()
                warn("Myhoe theme binding: " .. tostring(Reason))
            end
        end
    end

    function Theme:Destroy()
        self.Changed:Destroy()
        local Bindings = {}
        for Binding in self._bindings do
            table.insert(Bindings, Binding)
        end
        for _, Binding in Bindings do
            Binding.Cleanup()
        end
    end

    return Theme
end)()

-- Core/Input
local InputManager = (function()
    local UserInputService = game:GetService("UserInputService")

    local Input = {}
    Input.__index = Input

    local function Invoke(Callback, ...)
        local Success, Reason = pcall(Callback, ...)
        if not Success then
            warn("Myhoe input callback: " .. tostring(Reason))
        end
    end

    local function GetPosition(InputObject: InputObject): Vector2
        return Vector2.new(InputObject.Position.X, InputObject.Position.Y)
    end

    function Input.GetBinding(InputObject)
        if InputObject.UserInputType == Enum.UserInputType.Keyboard then
            return InputObject.KeyCode
        end
        if
            InputObject.UserInputType == Enum.UserInputType.MouseButton1
            or InputObject.UserInputType == Enum.UserInputType.MouseButton2
            or InputObject.UserInputType == Enum.UserInputType.MouseButton3
        then
            return InputObject.UserInputType
        end
        return nil
    end

    function Input.New(Scope)
        local self = setmetatable({
            Scope = Scope,
            Capturing = false,
            _listeners = {},
            _active = nil,
            _capture = nil,
            Pressed = {},
            Suppressed = {},
            Consumed = setmetatable({}, { __mode = "k" }),
        }, Input)
        Scope:Connect(UserInputService.InputBegan, function(InputObject, Processed)
            local Key = Input.GetBinding(InputObject)
            if self._capture then
                if Key then
                    self.Consumed[InputObject] = true
                    self.Suppressed[Key] = true
                    if Key == Enum.KeyCode.Escape then
                        Key = nil
                    elseif Key == Enum.KeyCode.Backspace or Key == Enum.KeyCode.Delete then
                        Key = Enum.KeyCode.Unknown
                    end
                    self._capture.Finish(Key, true)
                end
                return
            end
            if UserInputService:GetFocusedTextBox() then
                return
            end
            if Key then
                if self.Pressed[Key] then
                    return
                end
                self.Pressed[Key] = InputObject
            end
            self:_Dispatch(InputObject, true, Processed)
        end)
        Scope:Connect(UserInputService.InputEnded, function(InputObject, Processed)
            local Key = Input.GetBinding(InputObject)
            if Key then
                self.Pressed[Key] = nil
                if self.Suppressed[Key] then
                    self.Suppressed[Key] = nil
                    return
                end
            end
            self:_Dispatch(InputObject, false, Processed)
        end)
        Scope:Connect(UserInputService.WindowFocusReleased, function()
            self:ReleasePressed()
            self:CancelDrag()
            self:CancelCapture()
        end)
        Scope:Connect(UserInputService.TextBoxFocused, function()
            self:ReleasePressed()
        end)
        Scope:Add(function()
            self:CancelDrag()
            if self._capture then
                self._capture.Finish(nil, false)
            end
            table.clear(self.Pressed)
            table.clear(self.Suppressed)
            table.clear(self._listeners)
        end)
        return self
    end

    function Input:_Dispatch(InputObject, Began, Processed)
        for Listener in self._listeners do
            if Listener.Scope.Alive then
                Invoke(Listener.Callback, InputObject, Began, Processed)
            end
        end
    end

    function Input:ReleasePressed()
        local Pressed = self.Pressed
        self.Pressed = {}
        for _, InputObject in Pressed do
            self:_Dispatch(InputObject, false, true)
        end
    end

    function Input:IsDown(Key)
        return self.Pressed[Key] ~= nil
    end

    function Input:IsConsumed(InputObject)
        return InputObject ~= nil and self.Consumed[InputObject] == true
    end

    function Input:Listen(Scope, Callback)
        assert(type(Callback) == "function", "Input listener requires a callback")
        local Listener = { Scope = Scope, Callback = Callback }
        local Removed = false
        local Cleanup
        Cleanup = function()
            if Removed then
                return
            end
            Removed = true
            self._listeners[Listener] = nil
            Scope:Remove(Cleanup)
        end
        self._listeners[Listener] = true
        Scope:Add(Cleanup)
        return Cleanup
    end

    function Input:Capture(Scope, Callback)
        if self._capture then
            self._capture.Finish(nil, true)
        end
        self:CancelDrag()
        self:ReleasePressed()
        if not Scope.Alive or not self.Scope.Alive then
            return nil
        end
        local Capture = { Scope = Scope }
        local Finished = false
        local Cleanup
        Capture.Finish = function(Key, Notify)
            if Finished then
                return
            end
            Finished = true
            Scope:Remove(Cleanup)
            if self._capture == Capture then
                self._capture = nil
                self.Capturing = false
            end
            if Notify and Scope.Alive then
                Invoke(Callback, Key)
            end
        end
        Cleanup = function()
            Capture.Finish(nil, false)
        end
        self._capture = Capture
        self.Capturing = true
        Scope:Add(Cleanup)
        return function()
            Capture.Finish(nil, true)
        end
    end

    function Input:CancelDrag()
        if self._active then
            self._active.Finish()
        end
    end

    function Input:CancelCapture()
        if self._capture then
            self._capture.Finish(nil, true)
        end
    end

    function Input:Drag(Scope, GuiObject: GuiObject, Callback)
        return Scope:Connect(GuiObject.InputBegan, function(InputObject)
            if self.Capturing or self:IsConsumed(InputObject) or not self.Scope.Alive then
                return
            end
            local IsTouch = InputObject.UserInputType == Enum.UserInputType.Touch
            if not IsTouch and InputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            self:CancelDrag()
            local Drag = { Position = GetPosition(InputObject), Input = InputObject }
            local MovingConnection, EndingConnection, UnfocusedConnection
            local Finished = false
            local Cleanup
            Drag.Finish = function(FinalInput)
                if Finished then
                    return
                end
                Finished = true
                if MovingConnection then
                    MovingConnection:Disconnect()
                end
                if EndingConnection then
                    EndingConnection:Disconnect()
                end
                if UnfocusedConnection then
                    UnfocusedConnection:Disconnect()
                end
                Scope:Remove(Cleanup)
                if self._active == Drag then
                    self._active = nil
                end
                if FinalInput then
                    Drag.Position = GetPosition(FinalInput)
                end
                if Scope.Alive and self.Scope.Alive then
                    Invoke(Callback, Drag.Position, "End", FinalInput or InputObject)
                end
            end
            Cleanup = function()
                Drag.Finish()
            end
            self._active = Drag
            Scope:Add(Cleanup)
            MovingConnection = UserInputService.InputChanged:Connect(function(ChangedInput)
                if Finished then
                    return
                end
                if
                    (IsTouch and ChangedInput == InputObject)
                    or (not IsTouch and ChangedInput.UserInputType == Enum.UserInputType.MouseMovement)
                then
                    Drag.Position = GetPosition(ChangedInput)
                    Invoke(Callback, Drag.Position, "Change", ChangedInput)
                end
            end)
            EndingConnection = UserInputService.InputEnded:Connect(function(EndedInput)
                if
                    (IsTouch and EndedInput == InputObject)
                    or (not IsTouch and EndedInput.UserInputType == Enum.UserInputType.MouseButton1)
                then
                    Drag.Finish(EndedInput)
                end
            end)
            UnfocusedConnection = UserInputService.WindowFocusReleased:Connect(function()
                Drag.Finish()
            end)
            Invoke(Callback, Drag.Position, "Begin", InputObject)
        end)
    end

    return Input
end)()

-- Core/Compat
local Compatibility = (function()
    local Players = game:GetService("Players")

    local Compat = {}

    local function Environment()
        local Result = {}
        local Success, Environment = pcall(function()
            return getfenv(0)
        end)
        if Success and type(Environment) == "table" then
            Result = Environment
        end
        local Getter = Result.getgenv or _G.getgenv
        if type(Getter) == "function" then
            local Success, Global = pcall(Getter)
            if Success and type(Global) == "table" then
                return setmetatable({}, {
                    __index = function(_, Key)
                        return Global[Key] or Result[Key] or _G[Key]
                    end,
                })
            end
        end
        return setmetatable({}, {
            __index = function(_, Key)
                return Result[Key] or _G[Key]
            end,
        })
    end

    function Compat.Files()
        local Environment = Environment()
        local Files = {}
        for _, Name in { "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile" } do
            if type(Environment[Name]) == "function" then
                Files[Name] = Environment[Name]
            end
        end
        local Complete = true
        for _, Name in { "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile" } do
            if not Files[Name] then
                Complete = false
                break
            end
        end
        if not Complete then
            local Cache = _G.MyhoeProfileCache
            if type(Cache) ~= "table" or type(Cache.Files) ~= "table" or type(Cache.Folders) ~= "table" then
                Cache = { Files = {}, Folders = {} }
                _G.MyhoeProfileCache = Cache
            end
            local function Path(Name)
                return tostring(Name):gsub("\\", "/"):gsub("/+$", "")
            end
            Files = {
                SessionOnly = true,
                writefile = function(Name, Data)
                    assert(type(Data) == "string", "Expected profile text")
                    Cache.Files[Path(Name)] = Data
                end,
                readfile = function(Name)
                    local Data = Cache.Files[Path(Name)]
                    assert(Data ~= nil, "Profile not found")
                    return Data
                end,
                isfile = function(Name)
                    return Cache.Files[Path(Name)] ~= nil
                end,
                isfolder = function(Name)
                    return Cache.Folders[Path(Name)] == true
                end,
                makefolder = function(Name)
                    Cache.Folders[Path(Name)] = true
                end,
                delfile = function(Name)
                    Cache.Files[Path(Name)] = nil
                end,
                listfiles = function(Name)
                    local Prefix = Path(Name) .. "/"
                    local Result = {}
                    for File in Cache.Files do
                        if
                            File:sub(1, #Prefix) == Prefix and not File:sub(#Prefix + 1):find("/", 1, true)
                        then
                            table.insert(Result, File)
                        end
                    end
                    return Result
                end,
            }
        end
        return Files
    end

    local CachedAssets = {}

    function Compat.CacheAsset(Name: string, Bytes: string)
        if
            type(Name) ~= "string"
            or not Name:match("^[%w][%w%._%-]*$")
            or Name:find("..", 1, true)
            or type(Bytes) ~= "string"
            or #Bytes == 0
        then
            return nil, "Invalid embedded asset"
        end
        local Cached = CachedAssets[Name]
        if Cached and Cached.Bytes == Bytes then
            return Cached.Uri
        end
        local Environment = Environment()
        local Loaders = {}
        for _, Capability in { "getcustomasset", "getsynasset" } do
            if type(Environment[Capability]) == "function" then
                table.insert(Loaders, Environment[Capability])
            end
        end
        if #Loaders == 0 or type(Environment.writefile) ~= "function" then
            return nil, "Custom asset caching is unavailable"
        end
        local Path = "Myhoe_" .. Name
        if type(Environment.isfolder) == "function" and type(Environment.makefolder) == "function" then
            local Created = pcall(function()
                for _, Folder in { "Myhoe", "Myhoe/Assets" } do
                    if not Environment.isfolder(Folder) then
                        Environment.makefolder(Folder)
                    end
                end
            end)
            if Created then
                Path = "Myhoe/Assets/" .. Name
            end
        end
        local Written, Reason = pcall(function()
            if
                type(Environment.isfile) == "function"
                and type(Environment.readfile) == "function"
                and Environment.isfile(Path)
                and Environment.readfile(Path) == Bytes
            then
                return
            end
            Environment.writefile(Path, Bytes)
        end)
        if not Written then
            return nil, tostring(Reason)
        end
        for _, Loader in Loaders do
            local Success, Uri = pcall(Loader, Path)
            if Success and type(Uri) == "string" and #Uri > 0 then
                CachedAssets[Name] = { Bytes = Bytes, Uri = Uri }
                return Uri
            end
        end
        return nil, "The custom asset loader rejected the embedded asset"
    end

    local function TryParent(ScreenGui, ParentObject)
        if typeof(ParentObject) ~= "Instance" then
            return false
        end
        local Success = pcall(function()
            ScreenGui.Parent = ParentObject
        end)
        return Success and ScreenGui.Parent == ParentObject
    end

    function Compat.Parent(ScreenGui: ScreenGui, ExplicitParent: Instance?)
        local Capabilities = Environment()
        local Protectors = {
            Capabilities.protect_gui,
            Capabilities.protectgui,
            type(Capabilities.syn) == "table" and Capabilities.syn.protect_gui or nil,
        }
        for _, Protect in pairs(Protectors) do
            if type(Protect) == "function" then
                pcall(Protect, ScreenGui)
            end
        end
        if ExplicitParent then
            assert(TryParent(ScreenGui, ExplicitParent), "Myhoe could not use the supplied UI parent")
            return ExplicitParent
        end
        local GetHiddenUI = Environment().gethui
        if type(GetHiddenUI) == "function" then
            local Success, ParentObject = pcall(GetHiddenUI)
            if Success and TryParent(ScreenGui, ParentObject) then
                return ParentObject
            end
        end
        local Player = Players.LocalPlayer
        if Player then
            local ParentObject = Player:FindFirstChildOfClass("PlayerGui")
                or Player:WaitForChild("PlayerGui", 5)
            if ParentObject and TryParent(ScreenGui, ParentObject) then
                return ParentObject
            end
        end
        local Success, Core = pcall(function()
            return game:GetService("CoreGui")
        end)
        if Success and TryParent(ScreenGui, Core) then
            return Core
        end
        error(
            "Myhoe requires a client context. Run it from a LocalScript or provide a writable UI parent.",
            2
        )
    end

    return Compat
end)()

-- Config/Store
local ConfigManager = (function()
    local HttpService = game:GetService("HttpService")
    local Compat = Compatibility
    local Signal = Signal

    local Store = {}
    Store.__index = Store

    local Kinds = table.freeze({
        Toggle = true,
        Checkbox = true,
        Slider = true,
        Dropdown = true,
        MultiDropdown = true,
        Textbox = true,
        Keybind = true,
        ColorPicker = true,
        State = true,
    })

    local function IsFiniteNumber(Value)
        return type(Value) == "number" and Value == Value and math.abs(Value) < math.huge
    end

    local function IsScalar(Value)
        return type(Value) == "string" or type(Value) == "boolean" or IsFiniteNumber(Value)
    end

    local function EncodeValue(Value, Depth, Seen)
        assert(Depth < 20, "Config value nesting is too deep")
        local Kind = typeof(Value)
        if Value == nil then
            return { Type = "Nil" }
        end
        if Kind == "Color3" then
            assert(
                IsFiniteNumber(Value.R)
                    and IsFiniteNumber(Value.G)
                    and IsFiniteNumber(Value.B)
                    and Value.R >= 0
                    and Value.R <= 1
                    and Value.G >= 0
                    and Value.G <= 1
                    and Value.B >= 0
                    and Value.B <= 1,
                "Invalid color channels"
            )
            return { Type = "Color3", R = Value.R, G = Value.G, B = Value.B }
        end
        if Kind == "Vector2" then
            assert(IsFiniteNumber(Value.X) and IsFiniteNumber(Value.Y), "Invalid vector coordinates")
            return { Type = "Vector2", X = Value.X, Y = Value.Y }
        end
        if Kind == "Vector3" then
            assert(
                IsFiniteNumber(Value.X) and IsFiniteNumber(Value.Y) and IsFiniteNumber(Value.Z),
                "Invalid vector coordinates"
            )
            return { Type = "Vector3", X = Value.X, Y = Value.Y, Z = Value.Z }
        end
        if Kind == "EnumItem" then
            return { Type = "Enum", Enum = tostring(Value.EnumType):gsub("^Enum%.", ""), Name = Value.Name }
        end
        if IsScalar(Value) then
            return Value
        end
        assert(Kind == "table", "Unsupported config value type: " .. Kind)
        assert(not Seen[Value], "Config values cannot contain cycles")
        Seen[Value] = true
        local Result = {}
        local NumericKeys, StringKeys, LargestIndex = 0, 0, 0
        for Key, Child in Value do
            assert(
                type(Key) == "string" or (IsFiniteNumber(Key) and Key >= 1 and Key % 1 == 0),
                "Invalid config table key"
            )
            if type(Key) == "number" then
                NumericKeys += 1
                LargestIndex = math.max(LargestIndex, Key)
            else
                StringKeys += 1
            end
            Result[Key] = EncodeValue(Child, Depth + 1, Seen)
        end
        Seen[Value] = nil
        if NumericKeys > 0 and (StringKeys > 0 or LargestIndex ~= NumericKeys) then
            local Pairs = {}
            for Key, Child in Result do
                table.insert(Pairs, { Key = Key, Value = Child })
            end
            return { Type = "Map", Entries = Pairs }
        end
        return { Type = "Table", Entries = Result }
    end

    local function DecodeValue(Value, Depth)
        assert(Depth < 20, "Config value nesting is too deep")
        if IsScalar(Value) then
            return Value
        end
        assert(type(Value) == "table", "Invalid encoded config value")
        if Value.Type == "Nil" then
            return nil
        end
        if Value.Type == "Color3" then
            for _, Channel in { "R", "G", "B" } do
                assert(
                    IsFiniteNumber(Value[Channel]) and Value[Channel] >= 0 and Value[Channel] <= 1,
                    "Invalid color channel"
                )
            end
            return Color3.new(Value.R, Value.G, Value.B)
        end
        if Value.Type == "Enum" then
            assert(type(Value.Enum) == "string", "Invalid enum type")
            assert(type(Value.Name) == "string", "Invalid enum name")
            local Item = Enum[Value.Enum][Value.Name]
            assert(Item ~= nil, "Unknown enum value")
            return Item
        end
        if Value.Type == "Vector2" or Value.Type == "Vector3" then
            assert(IsFiniteNumber(Value.X) and IsFiniteNumber(Value.Y), "Invalid vector coordinates")
            if Value.Type == "Vector2" then
                return Vector2.new(Value.X, Value.Y)
            end
            assert(IsFiniteNumber(Value.Z), "Invalid vector coordinates")
            return Vector3.new(Value.X, Value.Y, Value.Z)
        end
        if Value.Type == "Map" then
            assert(type(Value.Entries) == "table", "Invalid config map")
            local Result, SeenKeys = {}, {}
            for _, Pair in Value.Entries do
                assert(type(Pair) == "table", "Invalid config map entry")
                local Key = Pair.Key
                assert(
                    type(Key) == "string" or (IsFiniteNumber(Key) and Key >= 1 and Key % 1 == 0),
                    "Invalid config map key"
                )
                assert(not SeenKeys[Key], "Duplicate config map key")
                SeenKeys[Key] = true
                Result[Key] = DecodeValue(Pair.Value, Depth + 1)
            end
            return Result
        end
        assert(Value.Type == "Table" and type(Value.Entries) == "table", "Invalid encoded config table")
        local Result = {}
        for Key, Child in Value.Entries do
            Result[Key] = DecodeValue(Child, Depth + 1)
        end
        return Result
    end

    local function ValidateKind(Kind, Value)
        if Kind == "State" then
            local Accepted, Reason = pcall(EncodeValue, Value, 0, {})
            return Accepted, if Accepted then nil else tostring(Reason)
        end
        if Kind == "Toggle" or Kind == "Checkbox" then
            return type(Value) == "boolean", "expected a boolean"
        end
        if Kind == "Slider" then
            return IsFiniteNumber(Value), "expected a finite number"
        end
        if Kind == "Textbox" then
            return type(Value) == "string", "expected a string"
        end
        if Kind == "Dropdown" then
            return Value == nil or IsScalar(Value), "expected an option value"
        end
        if Kind == "ColorPicker" then
            return typeof(Value) == "Color3", "expected Color3"
        end
        if Kind == "Keybind" then
            return typeof(Value) == "EnumItem"
                and (Value.EnumType == Enum.KeyCode or Value.EnumType == Enum.UserInputType),
                "expected a key or mouse binding"
        end
        if Kind == "MultiDropdown" then
            if type(Value) ~= "table" then
                return false, "expected an option array"
            end
            local Seen, Count = {}, 0
            for Index, Item in Value do
                if
                    type(Index) ~= "number"
                    or Index < 1
                    or Index % 1 ~= 0
                    or not IsScalar(Item)
                    or Seen[Item]
                then
                    return false, "expected unique options in a contiguous array"
                end
                Seen[Item] = true
                Count += 1
            end
            for Index = 1, Count do
                if Value[Index] == nil then
                    return false, "option array contains gaps"
                end
            end
            return true
        end
        return false, "unknown control kind"
    end

    local function ValidateEntry(Entry, Value)
        local Valid, Reason = ValidateKind(Entry.Kind, Value)
        if not Valid then
            return false, Reason
        end
        if type(Entry.Control.Validate) == "function" then
            local Success, Accepted, Detail = pcall(Entry.Control.Validate, Entry.Control, Value)
            if not Success then
                return false, tostring(Accepted)
            end
            if Accepted ~= true then
                return false, Detail or "control rejected the value"
            end
        end
        return true
    end

    local function NormalizeFolder(Value)
        assert(
            type(Value) == "string" and #Value > 0 and #Value <= 200,
            "Config folder must be a relative folder name"
        )
        Value = Value:gsub("\\", "/"):gsub("/+$", "")
        assert(
            Value ~= "" and not Value:match("^/") and not Value:find('[<>:%"|%?%*%c]'),
            "Config folder contains invalid path characters"
        )
        for Segment in (Value .. "/"):gmatch("(.-)/") do
            assert(
                Segment ~= "" and Segment ~= "." and Segment ~= ".." and not Segment:match("[%. ]$"),
                "Config folder contains an invalid path segment"
            )
        end
        return Value
    end

    local function ValidateName(Name)
        if type(Name) ~= "string" or #Name == 0 or #Name > 80 then
            return false, "Config name must contain 1–80 characters"
        end
        if Name == "." or Name == ".." or Name:find('[<>:%"/\\|%?%*%c]') or Name:match("[%. ]$") then
            return false, "Config name contains invalid filename characters"
        end
        local Base = (Name:match("^([^%.]+)") or Name):upper()
        if
            Base == "CON"
            or Base == "PRN"
            or Base == "AUX"
            or Base == "NUL"
            or Base:match("^COM[1-9]$")
            or Base:match("^LPT[1-9]$")
        then
            return false, "Config name is reserved by the filesystem"
        end
        return true
    end

    function Store.New(Options)
        Options = Options or {}
        local Storage = Options.Storage or Compat.Files()
        assert(type(Storage) == "table", "Config Storage must be a filesystem-compatible table")
        local self = setmetatable({
            Folder = NormalizeFolder(Options.Folder or "Myhoe"),
            Storage = Storage,
            Changed = Signal.New(),
            _controls = {},
            _alive = true,
        }, Store)
        self.Flags = setmetatable({}, {
            __index = function(_, Id)
                local Entry = self._controls[Id]
                return if Entry then Entry.Control:Get() else nil
            end,
            __newindex = function(_, Id, Value)
                assert(self._alive, "Config store has been destroyed")
                local Entry = self._controls[Id]
                assert(Entry, "Unknown control flag: " .. tostring(Id))
                local Result, Reason = Entry.Control:Set(Value)
                assert(Result ~= false, Reason or "Control rejected flag value")
            end,
            __iter = function()
                return next, self:GetValues(), nil
            end,
            __metatable = "Myhoe flags",
        })
        self.Available = true
        self.SessionOnly = Storage.SessionOnly == true
        for _, Name in { "writefile", "readfile", "isfile", "isfolder", "makefolder", "listfiles", "delfile" } do
            if type(Storage[Name]) ~= "function" then
                self.Available = false
            end
        end
        return self
    end

    function Store:GetValues()
        local Values = {}
        for Id, Entry in self._controls do
            Values[Id] = Entry.Control:Get()
        end
        return Values
    end

    function Store:Register(Id: string, Control, Kind: string)
        assert(self._alive, "Config store has been destroyed")
        assert(type(Id) == "string" and #Id > 0, "Persistent controls require a stable, nonempty Id")
        assert(not self._controls[Id], "Duplicate control Id: " .. Id)
        assert(Kinds[Kind], "Unsupported config control kind: " .. tostring(Kind))
        assert(
            type(Control.Get) == "function" and type(Control.Set) == "function",
            "Persistent controls need Get and Set methods"
        )
        local Entry = { Control = Control, Kind = Kind }
        self._controls[Id] = Entry
        return function()
            if self._controls[Id] == Entry then
                self._controls[Id] = nil
            end
        end
    end

    function Store:Subscribe(Callback, Scope)
        return self.Changed:Subscribe(Callback, Scope)
    end

    function Store:RegisterState(Id: string, GetOrAdapter, SetOrScope, Validate)
        local Adapter, OwnerScope
        if type(GetOrAdapter) == "table" then
            Adapter, OwnerScope = GetOrAdapter, SetOrScope
        else
            assert(
                type(GetOrAdapter) == "function" and type(SetOrScope) == "function",
                "State adapters require Get and Set"
            )
            Adapter = {
                Get = function()
                    return GetOrAdapter()
                end,
                Set = function(_, Value, Options)
                    return SetOrScope(Value, Options)
                end,
                Validate = if Validate
                    then function(_, Value)
                        return Validate(Value)
                    end
                    else nil,
            }
        end
        local Unregister = self:Register(Id, Adapter, "State")
        if OwnerScope then
            OwnerScope:Add(Unregister)
        end
        return Unregister
    end

    function Store:Export(): string
        assert(self._alive, "Config store has been destroyed")
        local Controls = {}
        for Id, Entry in self._controls do
            local Value = Entry.Control:Get()
            local Valid, Reason = ValidateEntry(Entry, Value)
            assert(Valid, "Invalid value for " .. Id .. ": " .. tostring(Reason))
            Controls[Id] = { Kind = Entry.Kind, Value = EncodeValue(Value, 0, {}) }
        end
        return HttpService:JSONEncode({ Version = 1, Controls = Controls })
    end

    function Store:Import(Json: string, Silent: boolean?)
        if not self._alive then
            return false, "Config store has been destroyed"
        end
        if self.Applying then
            return false, "A config transaction is already being applied"
        end
        if type(Json) ~= "string" or #Json > 8 * 1024 * 1024 then
            return false, "Config must be JSON text under 8 MiB"
        end
        local Success, Document = pcall(HttpService.JSONDecode, HttpService, Json)
        if not Success then
            return false, "Invalid config JSON: " .. tostring(Document)
        end
        if type(Document) ~= "table" or Document.Version ~= 1 or type(Document.Controls) ~= "table" then
            return false, "Unsupported config format or version"
        end
        local Pending = {}
        for Id, Saved in Document.Controls do
            if type(Id) ~= "string" or type(Saved) ~= "table" or not Kinds[Saved.Kind] then
                return false, "Malformed config control entry"
            end
            local Entry = self._controls[Id]
            if Entry then
                if Saved.Kind ~= Entry.Kind then
                    return false, "Control kind changed for " .. Id
                end
                local Decoded, Value = pcall(DecodeValue, Saved.Value, 0)
                if not Decoded then
                    return false, "Invalid value for " .. Id .. ": " .. tostring(Value)
                end
                local Valid, Reason = ValidateEntry(Entry, Value)
                if not Valid then
                    return false, "Invalid value for " .. Id .. ": " .. tostring(Reason)
                end
                local Captured, Previous = pcall(function()
                    local GetSnapshot = Entry.Control.GetSnapshot or Entry.Control.Get
                    return EncodeValue(GetSnapshot(Entry.Control), 0, {})
                end)
                if not Captured then
                    return false, "Cannot snapshot " .. Id .. ": " .. tostring(Previous)
                end
                table.insert(Pending, { Id = Id, Entry = Entry, Value = Value, Previous = Previous })
            end
        end
        table.sort(Pending, function(Left, Right)
            local LeftPriority = Left.Entry.Control.Priority or (if Left.Entry.Kind == "State" then 10 else 0)
            local RightPriority = Right.Entry.Control.Priority
                or (if Right.Entry.Kind == "State" then 10 else 0)
            if LeftPriority ~= RightPriority then
                return LeftPriority < RightPriority
            end
            return Left.Id < Right.Id
        end)
        self.Applying = true
        for Index, Item in Pending do
            local Applied, Result, Reason =
                pcall(Item.Entry.Control.Set, Item.Entry.Control, Item.Value, { Silent = Silent == true })
            if not Applied or Result == false then
                for Rollback = Index, 1, -1 do
                    local PreviousItem = Pending[Rollback]
                    pcall(
                        PreviousItem.Entry.Control.Set,
                        PreviousItem.Entry.Control,
                        DecodeValue(PreviousItem.Previous, 0),
                        { Silent = true, Rollback = true }
                    )
                end
                self.Applying = false
                local Failure = "Could not apply "
                    .. Item.Id
                    .. ": "
                    .. tostring(if Applied then Reason or "control rejected value" else Result)
                self.Changed:Fire(self, "Import", false, Failure)
                return false, Failure
            end
        end
        self.Applying = false
        self.Changed:Fire(self, "Import", true)
        return true
    end

    function Store:SetFolder(Folder: string)
        self.Folder = NormalizeFolder(Folder)
        return self
    end

    function Store:_require(Names)
        if not self._alive then
            return false, "Config store has been destroyed"
        end
        for _, Name in Names do
            if type(self.Storage[Name]) ~= "function" then
                return false,
                    "Config persistence unavailable: "
                        .. Name
                        .. " is not supported. Export and Import remain available."
            end
        end
        return true
    end

    function Store:_path(Name)
        local Valid, Reason = ValidateName(Name)
        if not Valid then
            return nil, Reason
        end
        return self.Folder .. "/" .. Name .. ".json"
    end

    function Store:_ensureFolder()
        local Supported, Reason = self:_require({ "isfolder", "makefolder" })
        if not Supported then
            return false, Reason
        end
        local Success, Detail = pcall(function()
            local Path = ""
            for Segment in self.Folder:gmatch("[^/]+") do
                Path = if Path == "" then Segment else Path .. "/" .. Segment
                if not self.Storage.isfolder(Path) then
                    self.Storage.makefolder(Path)
                end
            end
        end)
        return Success, if not Success then tostring(Detail) else nil
    end

    function Store:Save(Name: string)
        local Path, Reason = self:_path(Name)
        if not Path then
            return false, Reason
        end
        local Supported, Detail = self:_require({ "writefile" })
        if not Supported then
            return false, Detail
        end
        local Encoded, Json = pcall(self.Export, self)
        if not Encoded then
            return false, tostring(Json)
        end
        local Ready, FolderError = self:_ensureFolder()
        if not Ready then
            return false, FolderError
        end
        local Success, Failure = pcall(self.Storage.writefile, Path, Json)
        return Success, if not Success then tostring(Failure) else nil
    end

    function Store:Load(Name: string, Silent: boolean?)
        local Path, Reason = self:_path(Name)
        if not Path then
            return false, Reason
        end
        local Supported, Detail = self:_require({ "isfile", "readfile" })
        if not Supported then
            return false, Detail
        end
        local Exists, Found = pcall(self.Storage.isfile, Path)
        if not Exists then
            return false, tostring(Found)
        end
        if not Found then
            return false, "Config does not exist: " .. Name
        end
        local Success, Json = pcall(self.Storage.readfile, Path)
        if not Success then
            return false, tostring(Json)
        end
        return self:Import(Json, Silent)
    end

    function Store:Delete(Name: string)
        local Path, Reason = self:_path(Name)
        if not Path then
            return false, Reason
        end
        local Supported, Detail = self:_require({ "isfile", "delfile" })
        if not Supported then
            return false, Detail
        end
        local Exists, Found = pcall(self.Storage.isfile, Path)
        if not Exists then
            return false, tostring(Found)
        end
        if not Found then
            return false, "Config does not exist: " .. Name
        end
        local Autoload = self:GetAutoload()
        local Success, Failure = pcall(self.Storage.delfile, Path)
        if not Success then
            return false, tostring(Failure)
        end
        if Autoload == Name then
            local Cleared, ClearReason = self:ClearAutoload()
            if not Cleared then
                return true,
                    "Config deleted, but its autoload preference could not be cleared: " .. tostring(
                        ClearReason
                    )
            end
        end
        return true
    end

    function Store:GetAutoload()
        local Supported, Reason = self:_require({ "isfile", "readfile" })
        if not Supported then
            return nil, Reason
        end
        local Success, Name, Detail = pcall(function()
            local Path = self.Folder .. "/autoload.state"
            if not self.Storage.isfile(Path) then
                return nil
            end
            local Json = self.Storage.readfile(Path)
            if type(Json) ~= "string" or #Json > 8192 then
                return nil, "Invalid autoload preference"
            end
            local Document = HttpService:JSONDecode(Json)
            if type(Document) ~= "table" or Document.Version ~= 1 then
                return nil, "Unsupported autoload preference"
            end
            if Document.ProfileName == false then
                return nil
            end
            local Valid, ValidationReason = ValidateName(Document.ProfileName)
            if not Valid then
                return nil, "Invalid autoload profile: " .. tostring(ValidationReason)
            end
            local ProfilePath = self:_path(Document.ProfileName)
            if not self.Storage.isfile(ProfilePath) then
                return nil, "Autoload config does not exist: " .. Document.ProfileName
            end
            return Document.ProfileName
        end)
        if not Success then
            return nil, "Could not read autoload preference: " .. tostring(Name)
        end
        return Name, Detail
    end

    function Store:SetAutoload(Name: string?)
        if Name == nil then
            return self:ClearAutoload()
        end
        local Path, Reason = self:_path(Name)
        if not Path then
            return false, Reason
        end
        local Supported, Detail = self:_require({ "isfile", "writefile" })
        if not Supported then
            return false, Detail
        end
        local Checked, Exists = pcall(self.Storage.isfile, Path)
        if not Checked then
            return false, tostring(Exists)
        end
        if not Exists then
            return false, "Save the config before selecting it for autoload: " .. Name
        end
        local Ready, FolderReason = self:_ensureFolder()
        if not Ready then
            return false, FolderReason
        end
        local Success, Failure = pcall(function()
            self.Storage.writefile(
                self.Folder .. "/autoload.state",
                HttpService:JSONEncode({
                    Version = 1,
                    ProfileName = Name,
                })
            )
        end)
        return Success, if not Success then tostring(Failure) else nil
    end

    function Store:ClearAutoload()
        local Supported, Reason = self:_require({ "isfile" })
        if not Supported then
            return false, Reason
        end
        local Path = self.Folder .. "/autoload.state"
        local Checked, Exists = pcall(self.Storage.isfile, Path)
        if not Checked then
            return false, tostring(Exists)
        end
        if not Exists then
            return true
        end
        local Success, Failure
        if type(self.Storage.delfile) == "function" then
            Success, Failure = pcall(self.Storage.delfile, Path)
        elseif type(self.Storage.writefile) == "function" then
            Success, Failure = pcall(function()
                self.Storage.writefile(Path, HttpService:JSONEncode({ Version = 1, ProfileName = false }))
            end)
        else
            return false, "Config persistence unavailable: clearing autoload requires delfile or writefile"
        end
        return Success, if not Success then tostring(Failure) else nil
    end

    function Store:LoadAutoload(Silent: boolean?)
        local Name, Reason = self:GetAutoload()
        if not Name then
            return false, Reason or "No autoload profile is selected"
        end
        local Success, Failure = self:Load(Name, Silent)
        return Success, Failure, Name
    end

    function Store:List()
        local Supported, Reason = self:_require({ "isfolder", "listfiles" })
        if not Supported then
            return {}, Reason
        end
        local Success, Files = pcall(function()
            if not self.Storage.isfolder(self.Folder) then
                return {}
            end
            return self.Storage.listfiles(self.Folder)
        end)
        if not Success then
            return {}, tostring(Files)
        end
        if type(Files) ~= "table" then
            return {}, "Filesystem returned an invalid file list"
        end
        local Names, Seen = {}, {}
        for _, Path in Files do
            if type(Path) == "string" then
                local Name = Path:gsub("\\", "/"):match("([^/]+)%.json$")
                if Name and ValidateName(Name) and not Seen[Name] then
                    Seen[Name] = true
                    table.insert(Names, Name)
                end
            end
        end
        table.sort(Names, function(Left, Right)
            if Left:lower() == Right:lower() then
                return Left < Right
            end
            return Left:lower() < Right:lower()
        end)
        return Names
    end

    function Store:Destroy()
        if not self._alive then
            return
        end
        self._alive = false
        self.Changed:Destroy()
        table.clear(self._controls)
    end

    return Store
end)()

-- Core/Keybind
local KeybindManager = (function()
    local KeybindManager = {}
    KeybindManager.__index = KeybindManager
    local Binding = {}
    Binding.__index = Binding

    local Modes = table.freeze({ Toggle = true, Hold = true, Always = true, ["Not Held"] = true })
    local SupportedKinds = table.freeze({
        Toggle = true,
        Checkbox = true,
        Button = true,
        Keybind = true,
        Slider = true,
        Dropdown = true,
        MultiDropdown = true,
    })
    local ShortNames = {
        LeftControl = "LCtrl",
        RightControl = "RCtrl",
        LeftShift = "LShift",
        RightShift = "RShift",
        LeftAlt = "LAlt",
        RightAlt = "RAlt",
        MouseButton1 = "M1",
        MouseButton2 = "M2",
        MouseButton3 = "M3",
        Backspace = "Back",
        Return = "Enter",
        PageUp = "PgUp",
        PageDown = "PgDn",
        CapsLock = "Caps",
        Unknown = "None",
    }

    local function ParseKey(Value)
        if Value == nil or Value == "" or Value == "None" then
            return Enum.KeyCode.Unknown
        end
        if type(Value) == "string" then
            local Name = Value:match("([^%.]+)$")
            for FullName, ShortName in ShortNames do
                if Name == ShortName then
                    Name = FullName
                    break
                end
            end
            local Success, Item = pcall(function()
                return Enum.KeyCode[Name]
            end)
            if Success then
                Value = Item
            else
                Success, Item = pcall(function()
                    return Enum.UserInputType[Name]
                end)
                if not Success then
                    return nil
                end
                Value = Item
            end
        end
        if typeof(Value) ~= "EnumItem" then
            return nil
        end
        if Value.EnumType == Enum.KeyCode then
            return Value
        end
        if
            Value == Enum.UserInputType.MouseButton1
            or Value == Enum.UserInputType.MouseButton2
            or Value == Enum.UserInputType.MouseButton3
        then
            return Value
        end
        return nil
    end

    local function CopyValue(Value)
        if type(Value) ~= "table" then
            return Value
        end
        local Result = {}
        for Key, Child in Value do
            Result[Key] = CopyValue(Child)
        end
        return Result
    end

    local function ReadValue(Element)
        local Getter = Element.GetValue or Element.Get
        if type(Getter) == "function" then
            return Getter(Element)
        end
        return nil
    end

    local function Invoke(Callback, ...)
        if type(Callback) ~= "function" then
            return
        end
        local Success, Reason = pcall(Callback, ...)
        if not Success then
            warn("Myhoe keybind callback: " .. tostring(Reason))
        end
    end

    function KeybindManager.New(Library, Scope)
        local self = setmetatable({
            Library = Library,
            Input = Library.Input,
            Scope = Scope or Library.Scope:Child(),
            Elements = {},
            ElementIds = {},
            Bindings = {},
            OrderedBindings = {},
            Subscribers = {},
            NextId = 0,
            NextOrder = 0,
            Applying = {},
            Destroyed = false,
        }, KeybindManager)
        self.Input:Listen(self.Scope, function(InputObject, Began, Processed)
            self:_HandleInput(InputObject, Began, Processed)
        end)
        self.Scope:Add(Library.Config:RegisterState("@Keybinds", {
            Priority = 100,
            Get = function()
                return self:GetState()
            end,
            GetSnapshot = function()
                return self:GetSnapshot()
            end,
            Validate = function(_, Value)
                return self:ValidateState(Value)
            end,
            Set = function(_, Value, Options)
                return self:SetState(Value, Options)
            end,
        }))
        self.Scope:Add(function()
            self:Destroy()
        end)
        return self
    end

    function KeybindManager:GetKeyName(Key)
        local Parsed = ParseKey(Key)
        return if Parsed then ShortNames[Parsed.Name] or Parsed.Name else "None"
    end

    function KeybindManager:_Notify(Reason, ChangedBinding)
        if self.Destroyed then
            return
        end
        for Subscriber in self.Subscribers do
            if Subscriber.Scope.Alive then
                Invoke(Subscriber.Callback, self, Reason, ChangedBinding)
            end
        end
    end

    function KeybindManager:Subscribe(Scope, Callback)
        assert(type(Callback) == "function", "Keybind subscription requires a callback")
        local Subscriber = { Scope = Scope, Callback = Callback }
        local Cleanup
        Cleanup = function()
            self.Subscribers[Subscriber] = nil
            Scope:Remove(Cleanup)
        end
        self.Subscribers[Subscriber] = true
        Scope:Add(Cleanup)
        return Cleanup
    end

    function KeybindManager:RegisterElement(Element, StableId, Scope)
        assert(not self.Destroyed and type(Element) == "table", "Cannot register this element")
        if self.ElementIds[Element] then
            return self.ElementIds[Element]
        end
        Scope = Scope or Element.Scope
        assert(Scope and Scope.Alive, "Keybind elements require a live scope")
        StableId = StableId or Element.Id
        if StableId == nil then
            self.NextId += 1
            StableId = "@Element:" .. self.NextId
        end
        StableId = tostring(StableId)
        assert(#StableId > 0 and not self.Elements[StableId], "Duplicate keybind element Id: " .. StableId)
        self.Elements[StableId], self.ElementIds[Element] = Element, StableId
        Element.KeybindId = StableId
        Scope:Add(function()
            self:Remove(Element, { Silent = true, PreserveValue = true })
            if self.Elements[StableId] == Element then
                self.Elements[StableId] = nil
            end
            self.ElementIds[Element] = nil
        end)
        return StableId
    end

    function KeybindManager:_SetActive(Current, Active, Options)
        if Current.Destroyed then
            return false, "Keybind has been destroyed"
        end
        Options = Options or {}
        Active = Active == true
        local Element = Current.Element
        local Changed = Current.Active ~= Active
        local Previous = Current.Active
        Current.Active = Active
        self.Applying[Element] = true
        local Success, Result, Reason = pcall(function()
            if not Element.Scope.Alive then
                return true
            end
            if Element.Kind == "Toggle" or Element.Kind == "Checkbox" then
                if ReadValue(Element) ~= Active then
                    return (Element.SetValue or Element.Set)(Element, Active, Options)
                end
            elseif Element.Kind == "Button" then
                if Options.InvokeButton and not Options.NoAction and not Options.Silent then
                    return Element:Press()
                end
            elseif Element.Kind == "Keybind" then
                if Changed then
                    Invoke(Element.OnBindingChanged, Element, Active, Current.Key, Options)
                end
            elseif (Changed or Options.ForceValue) and Current.Value ~= nil then
                local Value = if Active then Current.Value else Current.OriginalValue
                return (Element.SetValue or Element.Set)(Element, CopyValue(Value), Options)
            end
            return true
        end)
        self.Applying[Element] = nil
        if not Success or Result == false then
            Current.Active = Previous
            return false,
                tostring(if Success then Reason or "Element rejected keybind activation" else Result)
        end
        if Changed then
            self:_Notify("Active", Current)
        end
        return true
    end

    function KeybindManager:NotifyElementChanged(Element)
        if self.Applying[Element] then
            return
        end
        local Current = self.Bindings[Element]
        if not Current or Current.Destroyed then
            return
        end
        if self.Library.Config.Applying then
            if Element.Kind == "Toggle" or Element.Kind == "Checkbox" then
                Current.Active = ReadValue(Element) == true
            end
            return
        end
        if (Element.Kind == "Dropdown" or Element.Kind == "MultiDropdown") and Element.Validate then
            local Repaired = false
            if Current.Value ~= nil then
                local Success, Accepted = pcall(Element.Validate, Element, Current.Value)
                if not Success or Accepted ~= true then
                    Current.Value = CopyValue(ReadValue(Element))
                    Repaired = true
                end
            end
            local Success, Accepted = pcall(Element.Validate, Element, Current.OriginalValue)
            if not Success or Accepted ~= true then
                Current.OriginalValue = CopyValue(ReadValue(Element))
                Repaired = true
            end
            if Repaired then
                self:_Notify("TargetValue", Current)
            end
        end
        if Element.Disabled then
            Current.Pressed = false
            Current:CancelCapture()
            if Current.Mode ~= "Toggle" then
                self:_SetActive(Current, false, { NoAction = true })
            end
            self:_Notify("Disabled", Current)
            return
        end
        if Current.Mode == "Always" then
            self:_SetActive(Current, true, { Silent = true, NoAction = true })
            return
        end
        if Element.Kind == "Toggle" or Element.Kind == "Checkbox" then
            local Active = ReadValue(Element) == true
            if Current.Active ~= Active then
                Current.Active = Active
                self:_Notify("Active", Current)
            end
        elseif Element.Kind ~= "Button" and Element.Kind ~= "Keybind" then
            Current.OriginalValue = CopyValue(ReadValue(Element))
        end
    end

    function KeybindManager:_HandleInput(InputObject, Began, Processed)
        if self.Destroyed then
            return
        end
        if Began and (Processed or self.Input.Capturing) then
            return
        end
        local Key = self.Input.GetBinding(InputObject)
        if not Key then
            return
        end
        for _, Current in self:GetBindings() do
            if Current.Key ~= Key or Current.Key == Enum.KeyCode.Unknown or Current.Mode == "Always" then
                continue
            end
            if Current.Element.Disabled then
                Current.Pressed = false
                if Current.Mode == "Hold" or Current.Mode == "Not Held" then
                    self:_SetActive(Current, false, { NoAction = true })
                end
                continue
            end
            if Began then
                if Current.Pressed then
                    continue
                end
                Current.Pressed = true
                local Active = if Current.Mode == "Toggle"
                    then not Current:IsActive()
                    else Current.Mode == "Hold"
                local Success, Reason =
                    self:_SetActive(Current, Active, { InvokeButton = Current.Mode ~= "Not Held" })
                if not Success then
                    warn("Myhoe keybind: " .. tostring(Reason))
                end
            else
                if not Current.Pressed then
                    continue
                end
                Current.Pressed = false
                if Current.Mode == "Hold" or Current.Mode == "Not Held" then
                    self:_SetActive(
                        Current,
                        Current.Mode == "Not Held",
                        { InvokeButton = Current.Mode == "Not Held" }
                    )
                end
            end
        end
    end

    function KeybindManager:Attach(Element, Options)
        assert(
            not self.Destroyed and Element.Scope and Element.Scope.Alive,
            "Keybind target has been destroyed"
        )
        assert(SupportedKinds[Element.Kind], "This element does not support keybinds")
        Options = Options or {}
        local Current = self.Bindings[Element]
        local Key = if Options.Key ~= nil
            then ParseKey(Options.Key)
            elseif Options.Default ~= nil then ParseKey(Options.Default)
            elseif Current then Current.Key
            else Enum.KeyCode.Unknown
        local Mode = Options.Mode or (Current and Current.Mode) or "Toggle"
        assert(Key ~= nil, "Expected a keyboard key or mouse button")
        assert(Modes[Mode], "Unsupported keybind mode: " .. tostring(Mode))
        assert(
            Options.ShowInBinds == nil or type(Options.ShowInBinds) == "boolean",
            "ShowInBinds must be a boolean"
        )
        if Options.Value ~= nil and Element.Validate then
            local Accepted, Reason = Element:Validate(Options.Value)
            assert(Accepted, Reason or "Invalid bound element value")
        end
        if Current then
            if Options.Changed ~= nil then
                Current.Changed = Options.Changed
            end
            local Accepted, Reason = Current:SetKey(Key, Options)
            assert(Accepted ~= false, Reason)
            if Options.Value ~= nil then
                Current.Value = CopyValue(Options.Value)
            end
            Accepted, Reason = Current:SetMode(Mode, Options)
            assert(Accepted ~= false, Reason)
            if Options.ShowInBinds ~= nil then
                Current:SetShowInBinds(Options.ShowInBinds, Options)
            end
            return Current
        end
        local Id = self:RegisterElement(Element, Element.Id, Element.Scope)
        self.NextOrder += 1
        Current = setmetatable({
            Manager = self,
            Scope = Element.Scope:Child(),
            Element = Element,
            Id = Id,
            Name = Options.Name or Element.Name or Id,
            Key = Key,
            Mode = Mode,
            ShowInBinds = Options.ShowInBinds ~= false,
            Active = false,
            Pressed = false,
            Capturing = false,
            Destroyed = false,
            Order = self.NextOrder,
            Value = CopyValue(Options.Value),
            OriginalValue = CopyValue(ReadValue(Element)),
            DisplayKey = self:GetKeyName(Key),
            Changed = Options.Changed,
        }, Binding)
        self.Bindings[Element] = Current
        table.insert(self.OrderedBindings, Current)
        Element.Keybind = Current
        Current.Scope:Add(function()
            if not Current.Destroyed then
                self:Remove(Element, { Silent = true, PreserveValue = true })
            end
        end)
        local Active = not Element.Disabled
            and (
                Mode == "Always"
                or Mode == "Not Held"
                or (
                    Mode == "Toggle"
                    and (Element.Kind == "Toggle" or Element.Kind == "Checkbox")
                    and ReadValue(Element) == true
                )
            )
        if not Options.DeferActivation then
            self:_SetActive(Current, Active, { Silent = Options.Silent, NoAction = true })
        end
        self:_Notify("Attached", Current)
        return Current
    end

    function KeybindManager:Get(Element)
        return self.Bindings[Element]
    end

    function KeybindManager:GetBindings()
        local Result = {}
        for _, Current in self.OrderedBindings do
            if not Current.Destroyed and Current.Element.Scope.Alive then
                table.insert(Result, Current)
            end
        end
        return Result
    end

    function KeybindManager:Remove(Element, Options)
        local Current = self.Bindings[Element]
        if not Current then
            return false
        end
        Options = Options or {}
        Current:CancelCapture()
        if not Options.PreserveValue and Element.Scope.Alive and Current.Mode ~= "Toggle" then
            self:_SetActive(Current, false, { Silent = Options.Silent, NoAction = true })
        end
        Current.Destroyed, Current.Active, Current.Pressed = true, false, false
        self.Bindings[Element] = nil
        if Element.Keybind == Current then
            Element.Keybind = nil
        end
        local Index = table.find(self.OrderedBindings, Current)
        if Index then
            table.remove(self.OrderedBindings, Index)
        end
        Current.Scope:Destroy()
        self:_Notify("Removed", Current)
        return true
    end

    function KeybindManager:GetState()
        local Entries = {}
        for _, Current in self:GetBindings() do
            table.insert(Entries, {
                Id = Current.Id,
                Key = Current.Key.Name,
                Mode = Current.Mode,
                ShowInBinds = Current.ShowInBinds,
                Value = CopyValue(Current.Value),
                OriginalValue = if Current.Value ~= nil then CopyValue(Current.OriginalValue) else nil,
                HasOriginalValue = if Current.Value ~= nil then true else nil,
            })
        end
        return { Bindings = Entries }
    end

    function KeybindManager:ValidateState(State)
        if type(State) ~= "table" or type(State.Bindings) ~= "table" then
            return false, "Expected a keybind state table"
        end
        local Seen, Count = {}, 0
        for Index, Entry in State.Bindings do
            if type(Index) ~= "number" or Index < 1 or Index % 1 ~= 0 or type(Entry) ~= "table" then
                return false, "Expected a keybind array"
            end
            Count += 1
            if type(Entry.Id) ~= "string" or #Entry.Id == 0 or Seen[Entry.Id] then
                return false, "Invalid or duplicate keybind Id"
            end
            Seen[Entry.Id] = true
            if
                Entry.Key == nil
                or not ParseKey(Entry.Key)
                or not Modes[Entry.Mode]
                or type(Entry.ShowInBinds) ~= "boolean"
            then
                return false, "Invalid keybind properties"
            end
            if Entry.HasOriginalValue ~= nil and type(Entry.HasOriginalValue) ~= "boolean" then
                return false, "Invalid original keybind value marker"
            end
            if Entry.HasOriginalValue and Entry.Value == nil then
                return false, "An original keybind value requires a bound value"
            end
            local Element = self.Elements[Entry.Id]
            if Element and not SupportedKinds[Element.Kind] then
                return false, "Unsupported keybind target"
            end
            if Element and Entry.Value ~= nil and Element.Validate then
                local Success, Accepted, Reason = pcall(Element.Validate, Element, Entry.Value)
                if not Success or Accepted ~= true then
                    return false, tostring(if Success then Reason else Accepted)
                end
                if Entry.HasOriginalValue or Entry.OriginalValue ~= nil then
                    Success, Accepted, Reason = pcall(Element.Validate, Element, Entry.OriginalValue)
                    if not Success or Accepted ~= true then
                        return false,
                            "Invalid original keybind value: " .. tostring(
                                if Success then Reason else Accepted
                            )
                    end
                end
            end
        end
        for Index = 1, Count do
            if State.Bindings[Index] == nil then
                return false, "Keybind array contains gaps"
            end
        end
        return true
    end

    function KeybindManager:GetSnapshot()
        local Snapshot = self:GetState()
        Snapshot.Runtime = {}
        for _, Current in self:GetBindings() do
            Snapshot.Runtime[Current.Id] = { Active = Current:IsActive(), Pressed = Current.Pressed }
        end
        return Snapshot
    end

    function KeybindManager:SetState(State, Options)
        local Accepted, Reason = self:ValidateState(State)
        if not Accepted then
            return false, Reason
        end
        Options = Options or {}
        local Incoming = {}
        for _, Entry in State.Bindings do
            Incoming[Entry.Id] = Entry
        end
        for _, Current in self:GetBindings() do
            if not Incoming[Current.Id] then
                self:Remove(Current.Element, { Silent = true, PreserveValue = true })
            end
        end
        for _, Entry in State.Bindings do
            local Element = self.Elements[Entry.Id]
            if Element and Element.Scope.Alive then
                local Current = self:Attach(Element, {
                    Key = Entry.Key,
                    Mode = Entry.Mode,
                    ShowInBinds = Entry.ShowInBinds,
                    Value = Entry.Value,
                    Silent = true,
                    DeferActivation = true,
                })
                Current.Value = CopyValue(Entry.Value)
                if Entry.HasOriginalValue or Entry.OriginalValue ~= nil then
                    Current.OriginalValue = CopyValue(Entry.OriginalValue)
                else
                    Current.OriginalValue = CopyValue(ReadValue(Element))
                end
                local Runtime = Options.Rollback and State.Runtime and State.Runtime[Current.Id]
                Current.Pressed = Runtime and Runtime.Pressed == true or false
                local Active = not Element.Disabled
                    and (
                        Current.Mode == "Always"
                        or Current.Mode == "Not Held"
                        or (
                            Current.Mode == "Toggle"
                            and (Element.Kind == "Toggle" or Element.Kind == "Checkbox")
                            and ReadValue(Element) == true
                        )
                    )
                if Runtime then
                    Active = Runtime.Active == true and not Element.Disabled
                end
                local Success, Failure = self:_SetActive(
                    Current,
                    Active,
                    { Silent = Options.Silent, NoAction = true, ForceValue = true }
                )
                if not Success then
                    return false, Failure
                end
            end
        end
        self:_Notify("Loaded")
        return true
    end

    function KeybindManager:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        for _, Current in self:GetBindings() do
            self:Remove(Current.Element, { Silent = true, PreserveValue = true })
        end
        table.clear(self.Elements)
        table.clear(self.ElementIds)
        table.clear(self.Subscribers)
        self.Scope:Destroy()
    end

    function Binding:GetKey()
        return self.Key
    end
    function Binding:GetMode()
        return self.Mode
    end
    function Binding:GetShowInBinds()
        return self.ShowInBinds
    end
    function Binding:GetTargetValue()
        return CopyValue(self.Value)
    end
    function Binding:SetTargetValue(Value, Options)
        if self.Destroyed then
            return false, "Keybind has been destroyed"
        end
        local Element = self.Element
        if Element.Kind ~= "Slider" and Element.Kind ~= "Dropdown" and Element.Kind ~= "MultiDropdown" then
            return false, "This element does not have a bound value"
        end
        if Value == nil then
            return false, "A bound value is required"
        end
        if type(Element.Validate) == "function" then
            local Success, Accepted, Reason = pcall(Element.Validate, Element, Value)
            if not Success or Accepted ~= true then
                return false, tostring(if Success then Reason or "Invalid bound value" else Accepted)
            end
        end
        local Previous = self.Value
        self.Value = CopyValue(Value)
        if self:IsActive() then
            local Accepted, Reason = self.Manager:_SetActive(self, true, {
                Silent = Options and Options.Silent,
                ForceValue = true,
            })
            if not Accepted then
                self.Value = Previous
                return false, Reason
            end
        end
        self.Manager:_Notify("TargetValue", self)
        return self
    end
    function Binding:GetKeyName()
        return self.Manager:GetKeyName(self.Key)
    end
    function Binding:IsActive()
        if self.Destroyed or self.Element.Disabled then
            return false
        end
        if self.Element.Kind == "Toggle" or self.Element.Kind == "Checkbox" then
            return ReadValue(self.Element) == true
        end
        return self.Active
    end

    function Binding:SetKey(Value, Options)
        if self.Destroyed then
            return false, "Keybind has been destroyed"
        end
        local Key = ParseKey(Value)
        if not Key then
            return false, "Expected a keyboard key or mouse button"
        end
        if Key == self.Key then
            return self
        end
        local Previous = self.Key
        self.Key, self.Pressed = Key, false
        self.DisplayKey = self.Manager:GetKeyName(Key)
        if not (Options and Options.DeferActivation) and (self.Mode == "Hold" or self.Mode == "Not Held") then
            local Success, Reason =
                self.Manager:_SetActive(self, not self.Element.Disabled and self.Mode == "Not Held", Options)
            if not Success then
                self.Key = Previous
                self.DisplayKey = self.Manager:GetKeyName(Previous)
                return false, Reason
            end
        end
        self.Manager:_Notify("Key", self)
        if not (Options and Options.Silent) then
            Invoke(self.Changed, Key)
        end
        return self
    end

    function Binding:SetMode(Mode, Options)
        if self.Destroyed then
            return false, "Keybind has been destroyed"
        end
        if not Modes[Mode] then
            return false, "Unsupported keybind mode"
        end
        if self.Mode == Mode then
            return self
        end
        local Previous = self.Mode
        self.Mode, self.Pressed = Mode, false
        if not (Options and Options.DeferActivation) then
            local Success, Reason = self.Manager:_SetActive(
                self,
                not self.Element.Disabled and (Mode == "Always" or Mode == "Not Held"),
                Options
            )
            if not Success then
                self.Mode = Previous
                return false, Reason
            end
        end
        self.Manager:_Notify("Mode", self)
        return self
    end

    function Binding:SetShowInBinds(Visible, OptionsValue)
        if self.Destroyed then
            return false, "Keybind has been destroyed"
        end
        if type(Visible) ~= "boolean" then
            return false, "ShowInBinds must be a boolean"
        end
        if self.ShowInBinds ~= Visible then
            self.ShowInBinds = Visible
            self.Manager:_Notify("Visibility", self)
        end
        return self
    end

    function Binding:Capture(Callback, OwnerScope)
        if self.Destroyed or self.Manager.Destroyed or self.Element.Disabled then
            return nil
        end
        if type(Callback) == "table" then
            OwnerScope, Callback = Callback, nil
        end
        self:CancelCapture()
        self.Capturing = true
        self.Manager:_Notify("Capture", self)
        local Cancel
        Cancel = self.Manager.Input:Capture(self.Scope, function(Key)
            self.Capturing = false
            self.CancelListening = nil
            if OwnerScope and Cancel then
                OwnerScope:Remove(Cancel)
            end
            if Key ~= nil then
                self:SetKey(Key)
            end
            self.Manager:_Notify("Capture", self)
            Invoke(Callback, Key)
        end)
        self.CancelListening = Cancel
        if not Cancel then
            self.Capturing = false
        end
        if OwnerScope and Cancel then
            OwnerScope:Add(Cancel)
        end
        return Cancel
    end

    function Binding:CancelCapture()
        if self.CancelListening then
            self.CancelListening()
        end
        self.CancelListening = nil
        self.Capturing = false
    end

    function Binding:Destroy()
        self.Manager:Remove(self.Element)
    end
    Binding.Set = Binding.SetKey
    Binding.Get = Binding.GetKey
    Binding.SetValue = Binding.SetKey
    Binding.GetValue = Binding.GetKey
    KeybindManager.Modes = Modes
    return KeybindManager
end)()

-- Core/Icons
local Icons = (function()
    local Icons = {}

    local Aliases = { Globe = "World", Eye = "View", Person = "Players", Path = "Movement" }

    function Icons.Draw(RenderContext, ParentObject, Name, Properties, Token, CleanupScope)
        local IconProperties = {
            Name = "Icon",
            Parent = ParentObject,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(20, 20),
        }
        local Weight = if Name == "Gear" then 1.5 elseif Name == "SectionCorners" then 2 else 1.8
        for Key, Value in Properties or {} do
            if Key == "Thickness" then
                Weight = Value
            else
                IconProperties[Key] = Value
            end
        end
        Token = Token or "SubText"
        if
            type(Name) == "number"
            or (type(Name) == "string" and (Name:find("rbxasset") or Name:find("rbxthumb") or tonumber(Name)))
        then
            IconProperties.Image = if tonumber(Name) then "rbxassetid://" .. tostring(Name) else Name
            return RenderContext:Create("ImageLabel", IconProperties, { ImageColor3 = Token }, CleanupScope)
        end
        Name = Aliases[Name] or Name
        local Root = RenderContext:Create("Frame", IconProperties, nil, CleanupScope)
        local function Line(X1, Y1, X2, Y2, ScaleWidth)
            local Delta = Vector2.new(X2 - X1, Y2 - Y1)
            local Part = RenderContext:Create("Frame", {
                Name = "Stroke",
                Parent = Root,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale((X1 + X2) / 48, (Y1 + Y2) / 48),
                ZIndex = Root.ZIndex,
                Size = if ScaleWidth
                    then UDim2.fromScale(Delta.Magnitude / 24, ScaleWidth)
                    else UDim2.new(Delta.Magnitude / 24, 0, 0, Weight),
                Rotation = math.deg(math.atan2(Delta.Y, Delta.X)),
            }, { BackgroundColor3 = Token }, CleanupScope)
            if not ScaleWidth then
                RenderContext:Corner(Part, Weight / 2)
            end
            return Part
        end
        local function Path(Points, Close, ScaleWidth)
            for Index = 1, #Points - 1 do
                Line(
                    Points[Index][1],
                    Points[Index][2],
                    Points[Index + 1][1],
                    Points[Index + 1][2],
                    ScaleWidth
                )
            end
            if Close then
                Line(Points[#Points][1], Points[#Points][2], Points[1][1], Points[1][2], ScaleWidth)
            end
        end
        local function Ring(Horizontal, Vertical, Width, Height)
            local Part = RenderContext:Create("Frame", {
                Name = "Ring",
                Parent = Root,
                BackgroundTransparency = 1,
                ZIndex = Root.ZIndex,
                Position = UDim2.fromScale(Horizontal / 24, Vertical / 24),
                Size = UDim2.fromScale(Width / 24, Height / 24),
            }, nil, CleanupScope)
            RenderContext:Corner(Part, math.max(Width, Height))
            local Stroke = RenderContext:Stroke(Part, Token, CleanupScope)
            Stroke.Thickness = Weight
        end
        local function Dot(Horizontal, Vertical, Size)
            local Part = RenderContext:Create("Frame", {
                Name = "Dot",
                Parent = Root,
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = Root.ZIndex,
                Position = UDim2.fromScale(Horizontal / 24, Vertical / 24),
                Size = UDim2.fromOffset(Size or 2, Size or 2),
            }, { BackgroundColor3 = Token }, CleanupScope)
            RenderContext:Corner(Part, 3)
        end
        if Name == "Myhoe" then
            Path({ { 5, 3 }, { 18, 3 }, { 22, 9 }, { 19, 20 }, { 6, 21 }, { 2, 14 } }, true)
            Path({ { 7, 15 }, { 7, 8 }, { 12, 13 }, { 17, 8 }, { 17, 15 } })
        elseif Name == "Chevron" then
            Path({ { 5, 9 }, { 12, 16 }, { 19, 9 } })
        elseif Name == "Search" then
            Ring(3, 3, 13, 13)
            Line(14, 14, 21, 21)
        elseif Name == "Close" then
            Line(6, 6, 18, 18)
            Line(18, 6, 6, 18)
        elseif Name == "Minus" then
            Line(5, 12, 19, 12)
        elseif Name == "Plus" then
            Line(5, 12, 19, 12)
            Line(12, 5, 12, 19)
        elseif Name == "Back" then
            Path({ { 10, 5 }, { 3, 12 }, { 10, 19 } })
            Line(3, 12, 21, 12)
        elseif Name == "Down" then
            for Row = 0, 5 do
                RenderContext:Create("Frame", {
                    Name = "Triangle",
                    Parent = Root,
                    AnchorPoint = Vector2.new(0.5, 0),
                    ZIndex = Root.ZIndex,
                    Position = UDim2.fromScale(0.5, Row / 6),
                    Size = UDim2.fromScale(1 - Row / 6, 1 / 6),
                }, { BackgroundColor3 = Token }, CleanupScope)
            end
        elseif Name == "Gear" then
            local Points = {}
            for Index = 0, 31 do
                local Angle = math.rad(Index * 360 / 32 - 90)
                local Radius = if Index % 4 == 0 or Index % 4 == 3 then 10 else 7.7
                table.insert(Points, { 12 + math.cos(Angle) * Radius, 12 + math.sin(Angle) * Radius })
            end
            Path(Points, true)
            Ring(8.5, 8.5, 7, 7)
        elseif Name == "Players" then
            Ring(6, 2, 9, 9)
            Path({ { 2, 21 }, { 3, 17 }, { 6, 14 }, { 10, 13 }, { 13, 14 } })
            Ring(15, 12, 6, 6)
            Path({ { 13, 22 }, { 14, 20 }, { 17, 19 }, { 20, 20 }, { 22, 22 } })
        elseif Name == "World" then
            Ring(2, 2, 20, 20)
            Path({ { 5, 5 }, { 9, 5 }, { 11, 8 }, { 9, 11 }, { 5, 10 }, { 3, 12 } })
            Path({
                { 12, 3 },
                { 14, 7 },
                { 19, 8 },
                { 21, 11 },
                { 17, 12 },
                { 16, 16 },
                { 13, 16 },
                { 12, 21 },
            })
            Path({ { 5, 15 }, { 8, 14 }, { 10, 18 }, { 9, 21 } })
        elseif Name == "View" then
            Path({
                { 2, 12 },
                { 5, 8 },
                { 9, 6 },
                { 15, 6 },
                { 19, 8 },
                { 22, 12 },
                { 19, 16 },
                { 15, 18 },
                {
                    9,
                    18,
                },
                {
                    5,
                    16,
                },
            }, true)
            Ring(8, 8, 8, 8)
        elseif Name == "Movement" then
            Ring(4, 6, 16, 16)
            Line(9, 2, 15, 2)
            Line(12, 2, 12, 4)
            Line(18, 5, 20, 7)
            Line(12, 14, 16, 10)
        elseif Name == "Exploits" then
            Path({
                { 5, 4 },
                { 12, 2 },
                { 20, 6 },
                { 20, 13 },
                { 17, 18 },
                { 12, 22 },
                { 7, 18 },
                { 4, 13 },
                {
                    4,
                    8,
                },
            })
            Line(2, 2, 22, 22)
        elseif Name == "Config" then
            for _, Vertical in { 5, 12, 19 } do
                Dot(3, Vertical, 1.5)
                Line(7, Vertical, 11, Vertical)
                Line(14, Vertical, 22, Vertical)
            end
        elseif Name == "Bell" then
            Path({
                { 4, 18 },
                { 6, 15 },
                { 6, 9 },
                { 7, 6 },
                { 9, 3 },
                { 12, 2 },
                { 15, 3 },
                { 17, 6 },
                { 18, 9 },
                { 18, 15 },
                { 20, 18 },
            }, true)
            Path({ { 10, 21 }, { 11, 22 }, { 13, 22 }, { 14, 21 } })
        elseif Name == "SectionCorners" then
            Path({ { 8, 2 }, { 8, 8 }, { 2, 8 } })
            Path({ { 16, 2 }, { 16, 8 }, { 22, 8 } })
            Path({ { 2, 16 }, { 8, 16 }, { 8, 22 } })
            Path({ { 16, 22 }, { 16, 16 }, { 22, 16 } })
        elseif Name == "Grip" then
            for _, Vertical in { 4, 12, 20 } do
                for _, Horizontal in { 4, 12, 20 } do
                    Dot(Horizontal, Vertical, 2.4)
                end
            end
        elseif Name == "Logo" then
            local function Segment(X1, Y1, X2, Y2)
                local Delta = Vector2.new(X2 - X1, Y2 - Y1)
                RenderContext:Create("Frame", {
                    Name = "Stroke",
                    Parent = Root,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ZIndex = Root.ZIndex,
                    Position = UDim2.fromScale((X1 + X2) / 200, (Y1 + Y2) / 140),
                    Size = UDim2.fromScale(Delta.Magnitude / 100, 10 / 70),
                    Rotation = math.deg(math.atan2(Delta.Y, Delta.X)),
                }, { BackgroundColor3 = Token }, CleanupScope)
            end
            Segment(-2, 29, 19, 47)
            Segment(29, 28, 48, 9)
            Segment(48, 9, 67, 28)
            Segment(31, 63, 49, 43)
            Segment(49, 43, 65, 58)
            Segment(65, 58, 94, 30)
            RenderContext:Create("Frame", {
                Name = "ChevronJoin",
                Parent = Root,
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = Root.ZIndex,
                Position = UDim2.fromScale(48 / 100, 9 / 70),
                Size = UDim2.fromScale(10 / 100, 10 / 70),
                Rotation = 45,
            }, { BackgroundColor3 = Token }, CleanupScope)
        elseif Name == "Sliders" then
            for Index = 1, 3 do
                local Vertical = Index * 6
                local Horizontal = if Index == 2 then 16 else 8
                Line(2, Vertical, Horizontal - 2, Vertical)
                Line(Horizontal + 2, Vertical, 22, Vertical)
                Ring(Horizontal - 2, Vertical - 2, 4, 4)
            end
        elseif Name == "Palette" then
            Ring(2, 3, 20, 17)
            Ring(5, 7, 2, 2)
            Ring(10, 5, 2, 2)
            Ring(16, 8, 2, 2)
            Ring(10, 13, 4, 4)
        elseif Name == "Folder" then
            Path({ { 3, 5 }, { 9, 5 }, { 12, 8 }, { 21, 8 }, { 21, 20 }, { 3, 20 } }, true)
        else
            Ring(3, 3, 18, 18)
            Line(12, 0, 12, 7)
            Line(12, 17, 12, 24)
            Line(0, 12, 7, 12)
            Line(17, 12, 24, 12)
        end
        return Root
    end

    return Icons
end)()

-- Core/Context
local RenderContext = (function()
    local Motion = Animation

    local TextService = game:GetService("TextService")
    local TextCache, TextCacheCount = {}, 0

    local Context = {}
    Context.__index = Context

    function Context.New(OwnerLibrary, CleanupScope)
        return setmetatable({
            Library = OwnerLibrary,
            Scope = CleanupScope,
            Theme = OwnerLibrary.Theme,
            Input = OwnerLibrary.Input,
            Config = OwnerLibrary.Config,
        }, Context)
    end

    function Context:Create(Class, Properties, Tokens, CleanupScope)
        Properties, Tokens = Properties or {}, Tokens or {}
        local InstanceObject = Instance.new(Class)
        if InstanceObject:IsA("GuiObject") then
            InstanceObject.BorderSizePixel = 0
        end
        if InstanceObject:IsA("GuiButton") then
            InstanceObject.AutoButtonColor = false
        end
        local ParentObject = Properties.Parent
        for Key, Value in Properties do
            if Key ~= "Parent" then
                InstanceObject[Key] = Value
            end
        end
        local Owner = CleanupScope or self.Scope
        Owner:Add(InstanceObject)
        if
            InstanceObject:IsA("TextLabel")
            or InstanceObject:IsA("TextButton")
            or InstanceObject:IsA("TextBox")
        then
            if
                Properties.Font == nil
                and Properties.FontFace == nil
                and Tokens.Font == nil
                and Tokens.FontFace == nil
            then
                self:Bind(InstanceObject, "Font", "Font", CleanupScope)
            end
            if Properties.TextSize == nil and Tokens.TextSize == nil then
                self:Bind(InstanceObject, "TextSize", "TextSize", CleanupScope)
            end
        end
        for Property, Token in Tokens do
            self:Bind(InstanceObject, Property, Token, CleanupScope)
        end
        InstanceObject.Parent = ParentObject
        return InstanceObject
    end

    function Context:Text(ParentObject, Text, Properties, CleanupScope)
        local TextProperties = {
            Name = "Text",
            Parent = ParentObject,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = tostring(Text or ""),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            RichText = false,
        }
        for Key, Value in Properties or {} do
            TextProperties[Key] = Value
        end
        local Tokens = if TextProperties.TextColor3 == nil then { TextColor3 = "Text" } else nil
        return self:Create("TextLabel", TextProperties, Tokens, CleanupScope)
    end

    function Context.MeasureText(Text, Label, Width)
        Text, Width = tostring(Text), math.max(1, Width or 10000)
        local Face, Size = Label.FontFace, Label.TextSize
        local Key = table.concat(
            { Face.Family, tostring(Face.Weight), tostring(Face.Style), tostring(Size), tostring(Width), Text },
            "\0"
        )
        if TextCache[Key] then
            return TextCache[Key]
        end
        local Params = Instance.new("GetTextBoundsParams")
        Params.Text, Params.Font, Params.Size, Params.Width = Text, Face, Size, Width
        local OK, Bounds = pcall(TextService.GetTextBoundsAsync, TextService, Params)
        Params:Destroy()
        if not OK then
            Bounds = TextService:GetTextSize(Text, Size, Enum.Font.ArialBold, Vector2.new(Width, 10000))
        end
        if TextCacheCount >= 512 then
            table.clear(TextCache)
            TextCacheCount = 0
        end
        TextCache[Key], TextCacheCount = Bounds, TextCacheCount + 1
        return Bounds
    end

    function Context:Corner(InstanceObject, Radius)
        local Corner = InstanceObject:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Radius or self.Theme.Values.Radius)
        Corner.Parent = InstanceObject
        return Corner
    end

    function Context:Corners(Target, TopLeft, TopRight, BottomRight, BottomLeft)
        local Corner = self:Corner(Target, math.max(TopLeft, TopRight, BottomRight, BottomLeft))
        local OK = pcall(function()
            Corner.TopLeftRadius = UDim.new(0, TopLeft)
            Corner.TopRightRadius = UDim.new(0, TopRight)
            Corner.BottomRightRadius = UDim.new(0, BottomRight)
            Corner.BottomLeftRadius = UDim.new(0, BottomLeft)
        end)
        return Corner, OK
    end

    function Context:Gradient(Target, Scope)
        return self:Create("UIGradient", {
            Parent = Target,
            Rotation = 84,
        }, {
            Color = function(T)
                return ColorSequence.new(Color3.new(1, 1, 1), T.DarkGradient)
            end,
        }, Scope)
    end

    function Context:Stroke(InstanceObject, Token, CleanupScope)
        return self:Create(
            "UIStroke",
            { Parent = InstanceObject, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
            { Color = Token or "Border" },
            CleanupScope
        )
    end

    function Context:Bind(InstanceObject, Property, Token, CleanupScope)
        local Face = self.Theme.FontRoles[Token]
        if Property == "Font" and Face then
            Property, Token = "FontFace", Face
        end
        return self.Theme:Bind(CleanupScope or self.Scope, InstanceObject, Property, Token)
    end

    function Context:Shadow(Target, Options, CleanupScope)
        Options, CleanupScope = Options or {}, (CleanupScope or self.Scope):Child()
        local Spread = math.clamp(Options.Spread or 12, 1, 40)
        local Strength = math.clamp(Options.Strength or 0.16, 0, 1)
        local Radius = Options.Radius or self.Theme.Values.Radius
        local Offset = Options.Offset or Vector2.new(0, 3)
        local Shadow = self:Create(
            "Frame",
            {
                Name = Target.Name .. "Shadow",
                Parent = Target.Parent,
                BackgroundTransparency = 1,
                Active = false,
            },
            nil,
            CleanupScope
        )
        local Layers = {}
        for Index = 6, 1, -1 do
            local Distance = Spread * Index / 6
            local Layer = self:Create("Frame", {
                Name = "Penumbra",
                Parent = Shadow,
                Active = false,
                Position = UDim2.fromOffset(Offset.X - Distance, Offset.Y - Distance),
                Size = UDim2.new(1, Distance * 2, 1, Distance * 2),
                BackgroundTransparency = 1,
            }, { BackgroundColor3 = "Black" }, CleanupScope)
            self:Corner(Layer, Radius + Distance)
            table.insert(Layers, { Object = Layer, Opacity = Strength * (1 - (Index - 1) / 8) / 3 })
        end
        local Scale
        local function Sync()
            Shadow.Parent, Shadow.Size, Shadow.Position = Target.Parent, Target.Size, Target.Position
            Shadow.AnchorPoint, Shadow.Rotation, Shadow.Visible =
                Target.AnchorPoint, Target.Rotation, Target.Visible
            Shadow.ZIndex = math.max(0, Target.ZIndex - 1)
            local Fade = if Target:IsA("CanvasGroup") then Target.GroupTransparency else 0
            for _, Layer in Layers do
                Layer.Object.ZIndex = Shadow.ZIndex
                Layer.Object.BackgroundTransparency = 1 - Layer.Opacity * (1 - Fade)
            end
        end
        local TrackedScale, ScaleConnection
        local function TrackScale()
            local Source = Target:FindFirstChildOfClass("UIScale")
            if Source == TrackedScale then
                return
            end
            if ScaleConnection then
                CleanupScope:Remove(ScaleConnection)
                ScaleConnection:Disconnect()
                ScaleConnection = nil
            end
            TrackedScale = Source
            if not Scale then
                Scale = self:Create("UIScale", { Parent = Shadow }, nil, CleanupScope)
            end
            Scale.Scale = if Source then Source.Scale else 1
            if Source then
                ScaleConnection = self:Connect(Source:GetPropertyChangedSignal("Scale"), function()
                    if Source == TrackedScale then
                        Scale.Scale = Source.Scale
                    end
                end, CleanupScope)
            end
        end
        for _, Property in { "Parent", "Position", "Size", "AnchorPoint", "Rotation", "Visible", "ZIndex" } do
            self:Connect(Target:GetPropertyChangedSignal(Property), Sync, CleanupScope)
        end
        if Target:IsA("CanvasGroup") then
            self:Connect(Target:GetPropertyChangedSignal("GroupTransparency"), Sync, CleanupScope)
        end
        self:Connect(Target.ChildAdded, TrackScale, CleanupScope)
        self:Connect(Target.ChildRemoved, TrackScale, CleanupScope)
        self:Connect(Target.Destroying, function()
            CleanupScope:Destroy()
        end, CleanupScope)
        self:Connect(Shadow.Destroying, function()
            CleanupScope:Destroy()
        end, CleanupScope)
        Sync()
        TrackScale()
        return Shadow
    end

    function Context:Tween(InstanceObject, Preset, Properties, CleanupScope)
        return Motion.To(CleanupScope or self.Scope, InstanceObject, Preset, Properties)
    end

    function Context:Connect(Signal, Callback, CleanupScope)
        return (CleanupScope or self.Scope):Connect(Signal, function(...)
            local EventInput = ...
            if
                typeof(EventInput) == "InputObject"
                and self.Input.IsConsumed
                and self.Input:IsConsumed(EventInput)
            then
                return
            end
            Callback(...)
        end)
    end

    function Context:RefreshTheme()
        self.Theme:Refresh()
    end
    function Context:Callback(Callback, ...)
        if type(Callback) ~= "function" then
            return
        end
        local Success, ErrorMessage = pcall(Callback, ...)
        if not Success then
            warn("[Myhoe callback] " .. tostring(ErrorMessage))
        end
    end

    function Context:Register(Control, Options, Kind, CleanupScope)
        local Owner = CleanupScope or Control.Scope or self.Scope
        local Identifier = Options.Id or Options.Flag
        if Identifier then
            Owner:Add(self.Config:Register(tostring(Identifier), Control, Kind))
        end
        if self.Window and not Control._SearchRegistered then
            Control._SearchRegistered = true
            local Record = {
                Control = Control,
                Name = tostring(Options.Name or Control.Name or Kind),
                Tab = Control.Tab or (Control.Section and Control.Section.Tab) or self.Tab,
                Kind = Kind,
                Section = Control.Section or self.Section,
                SettingsOwner = Control.SettingsOwner or self.SettingsOwner,
            }
            table.insert(self.Window.SearchItems, Record)
            Owner:Add(function()
                local Index = table.find(self.Window.SearchItems, Record)
                if Index then
                    table.remove(self.Window.SearchItems, Index)
                end
            end)
        end
    end

    function Context:Hover(InstanceObject, CleanupScope, Base, Hover)
        CleanupScope = CleanupScope or self.Scope
        Base, Hover = Base or "Surface", Hover or "Hover"
        local Over = false
        self:Bind(InstanceObject, "BackgroundColor3", function(Palette)
            return Palette[if Over then Hover else Base]
        end, CleanupScope)
        self:Connect(InstanceObject.MouseEnter, function()
            Over = true
            self:Tween(InstanceObject, "Hover", { BackgroundColor3 = self.Theme.Values[Hover] }, CleanupScope)
        end, CleanupScope)
        self:Connect(InstanceObject.MouseLeave, function()
            Over = false
            self:Tween(InstanceObject, "Hover", { BackgroundColor3 = self.Theme.Values[Base] }, CleanupScope)
        end, CleanupScope)
        if InstanceObject:IsA("GuiButton") then
            self:Connect(InstanceObject.MouseButton1Down, function()
                self:Tween(
                    InstanceObject,
                    "Press",
                    { BackgroundColor3 = self.Theme.Values.AccentSoft },
                    CleanupScope
                )
            end, CleanupScope)
            self:Connect(InstanceObject.MouseButton1Up, function()
                self:Tween(
                    InstanceObject,
                    "Hover",
                    { BackgroundColor3 = self.Theme.Values[if Over then Hover else Base] },
                    CleanupScope
                )
            end, CleanupScope)
        end
    end

    function Context:Tooltip(InstanceObject, Text, CleanupScope)
        if Text and self.Window then
            self.Window.Overlay:Tooltip(InstanceObject, Text, CleanupScope or self.Scope)
        end
    end

    function Context:Popup(Anchor, Size, Builder, CleanupScope, Options)
        if typeof(Size) == "Vector2" then
            Size = UDim2.fromOffset(Size.X, Size.Y)
        end
        return self.Window.Overlay:Open(Anchor, Size, Builder, CleanupScope or self.Scope, Options)
    end

    return Context
end)()

-- Overlay/Hud
local HudManager = (function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local MarketplaceService = game:GetService("MarketplaceService")
    local Icons = Icons
    local Motion = Animation
    local Signal = Signal

    local MeasureText = RenderContext.MeasureText

    local Hud = {}
    Hud.__index = Hud
    local Component = {}
    Component.__index = Component
    local Watermark = setmetatable({}, { __index = Component })
    Watermark.__index = Watermark
    local KeybindList = setmetatable({}, { __index = Component })
    KeybindList.__index = KeybindList
    local Builtins = { FPS = true, Ping = true, Time = true, PlayerName = true, GameName = true }

    local function Escape(Value)
        return (tostring(Value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
    end

    local function Finite(Value)
        return type(Value) == "number" and Value == Value and math.abs(Value) < math.huge
    end

    local function PositionValue(Value)
        if typeof(Value) == "Vector2" then
            return Value
        end
        if type(Value) == "table" and Finite(Value.X or Value[1]) and Finite(Value.Y or Value[2]) then
            return Vector2.new(Value.X or Value[1], Value.Y or Value[2])
        end
        error("HUD position must be Vector2 or {X, Y}", 3)
    end

    local function SharedUpdater(Library)
        if Library.HudUpdater then
            return Library.HudUpdater
        end
        local Scope = Library.Scope:Child()
        local Updater = {
            Scope = Scope,
            Watermarks = {},
            Elapsed = 0,
            Frames = 0,
            FPS = nil,
            Ping = nil,
            GameName = game.Name,
        }
        Library.HudUpdater = Updater
        Scope:Connect(RunService.Heartbeat, function(Delta)
            Updater.Elapsed += Delta
            Updater.Frames += 1
            if Updater.Elapsed < 0.5 then
                return
            end
            Updater.FPS = math.floor(Updater.Frames / Updater.Elapsed + 0.5)
            Updater.Elapsed, Updater.Frames = 0, 0
            local Success, Ping = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if Success and Finite(Ping) then
                Updater.Ping = math.floor(Ping + 0.5)
            end
            for Mark in Updater.Watermarks do
                if Mark.Scope.Alive and Mark.Visible then
                    Mark:Refresh()
                end
            end
        end)
        Scope:Delay(0, function()
            if game.PlaceId <= 0 then
                return
            end
            local Success, Info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
            if Scope.Alive and Success and type(Info) == "table" and type(Info.Name) == "string" then
                Updater.GameName = Info.Name
                for Mark in Updater.Watermarks do
                    if Mark.Scope.Alive then
                        Mark:Refresh()
                    end
                end
            end
        end)
        Scope:Add(function()
            table.clear(Updater.Watermarks)
            if Library.HudUpdater == Updater then
                Library.HudUpdater = nil
            end
        end)
        return Updater
    end

    function Component:GetViewport()
        local Window = self.Hud.Window
        local Scale = math.max(0.001, Window:GetScale())
        local Origin = (Window.Screen.AbsolutePosition - Window.Scene.AbsolutePosition) / Scale
        return Origin, Window.Screen.AbsoluteSize / Scale, Scale
    end

    function Component:SetPosition(Value)
        local Previous = self.Position
        local Position = PositionValue(Value)
        assert(Finite(Position.X) and Finite(Position.Y), "HUD position must be finite")
        local Origin, View = self:GetViewport()
        local Extent = Vector2.new(self.Frame.Size.X.Offset, self.Frame.Size.Y.Offset)
        if View.X < 1 or View.Y < 1 then
            self.Position = Position
            self.Frame.Position = UDim2.fromOffset(Position.X, Position.Y)
            if Previous ~= self.Position then
                self.Changed:Fire(self, "Position")
            end
            return self
        end
        self.Position = Vector2.new(
            math.clamp(Position.X, Origin.X + 4, math.max(Origin.X + 4, Origin.X + View.X - Extent.X - 4)),
            math.clamp(Position.Y, Origin.Y + 4, math.max(Origin.Y + 4, Origin.Y + View.Y - Extent.Y - 4))
        )
        Motion.Cancel(self.Frame, "Position")
        self.Frame.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
        if Previous ~= self.Position then
            self.Changed:Fire(self, "Position")
        end
        return self
    end

    function Component:Subscribe(Callback, Scope)
        return self.Changed:Subscribe(Callback, Scope)
    end

    function Component:GetPosition()
        return self.Position
    end
    function Component:GetVisible()
        return self.Visible
    end
    function Component:SetDraggable(Value)
        local Previous = self.Draggable
        self.Draggable = Value == true
        self.DragHandle.Active = self.Visible and self.Draggable
        if Previous ~= self.Draggable then
            self.Changed:Fire(self, "Draggable")
        end
        return self
    end
    function Component:SetVisible(Value)
        local Previous = self.Visible
        self.Visible = Value == true
        self.VisibilitySerial = (self.VisibilitySerial or 0) + 1
        local Serial = self.VisibilitySerial
        if self.Visible then
            self.Frame.Visible = true
            if self.Refresh then
                self:Refresh()
            end
            self.Context:Tween(self.Frame, "Hud", { GroupTransparency = 0 }, self.Scope)
        else
            self.Context:Tween(self.Frame, "Hud", { GroupTransparency = 1 }, self.Scope)
            self.Scope:Delay(0.18, function()
                if Serial == self.VisibilitySerial and not self.Visible then
                    self.Frame.Visible = false
                end
            end)
        end
        self.DragHandle.Active = self.Visible and self.Draggable
        if Previous ~= self.Visible then
            self.Changed:Fire(self, "Visible")
        end
        return self
    end

    function Component:Destroy()
        if not self.Scope.Alive then
            return
        end
        self.Scope:Destroy()
    end

    local function InitializeComponent(Self, Owner, Name, Position, Size, Visible)
        Self.Hud, Self.Context, Self.Scope = Owner, Owner.Context, Owner.Scope:Child()
        Self.Changed = Self.Scope:Add(Signal.New())
        Self.Position, Self.Visible, Self.Draggable = Position, Visible, true
        local Context, Scope = Self.Context, Self.Scope
        Self.Frame = Context:Create("CanvasGroup", {
            Name = Name,
            Parent = Owner.Layer,
            Position = UDim2.fromOffset(Position.X, Position.Y),
            Size = UDim2.fromOffset(Size.X, Size.Y),
            Visible = Visible,
            GroupTransparency = if Visible then 0 else 1,
            ZIndex = 4,
        }, { BackgroundColor3 = "Surface" }, Scope)
        Context:Corner(Self.Frame, 3)
        Self.DragHandle = Context:Create("TextButton", {
            Name = "Drag",
            Parent = Self.Frame,
            Size = UDim2.new(1, 0, 0, 28),
            Text = "",
            BackgroundTransparency = 1,
            ZIndex = 8,
            Active = Visible,
        }, nil, Scope)
        local PointerStart, PositionStart
        Owner.Library.Input:Drag(Scope, Self.DragHandle, function(Pointer, Phase)
            if not Self.Draggable or not Self.Visible then
                return
            end
            if Phase == "Begin" then
                PointerStart, PositionStart = Pointer, Self.Position
            elseif Phase == "Change" and PointerStart then
                Self:SetPosition(PositionStart + (Pointer - PointerStart) / Owner.Window:GetScale())
            else
                PointerStart, PositionStart = nil, nil
            end
        end)
        local function Clamp()
            if Scope.Alive then
                Self:SetPosition(Self.Position)
            end
        end
        Scope:Connect(Owner.Window.Screen:GetPropertyChangedSignal("AbsoluteSize"), Clamp)
        Scope:Connect(Owner.Window.Scene:GetPropertyChangedSignal("AbsolutePosition"), Clamp)
        Scope:Connect(Owner.Window.Scale:GetPropertyChangedSignal("Scale"), Clamp)
        Scope:Connect(Self.Frame:GetPropertyChangedSignal("Size"), Clamp)
        Clamp()
    end

    function Watermark.New(Owner, Options)
        Options = Options or {}
        local self = setmetatable({
            Id = tostring(Options.Id or "Main"),
            Name = tostring(Options.Name or "myhoe"),
            Items = {},
            Values = {},
        }, Watermark)
        InitializeComponent(
            self,
            Owner,
            "Watermark",
            PositionValue(Options.Position or Vector2.new(16, 16)),
            Vector2.new(Options.Width or 354, 35),
            Options.Visible ~= false
        )
        local Context, Scope = self.Context, self.Scope
        self.Frame.UICorner.CornerRadius = UDim.new(0, 7)
        Context:Stroke(self.Frame, "Border", Scope).Transparency = 0.6
        Icons.Draw(
            Context,
            self.Frame,
            "Myhoe",
            { Position = UDim2.fromOffset(7, 6), Size = UDim2.fromOffset(22, 22), Thickness = 1.6 },
            "Accent",
            Scope
        )
        self.DragHandle.Size = UDim2.fromScale(1, 1)
        self.Label = Context:Text(self.Frame, "", {
            Name = "Status",
            Position = UDim2.fromOffset(35, 0),
            Size = UDim2.new(1, -42, 1, 0),
            TextSize = 14,
            RichText = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, Scope)
        Context:Bind(self.Label, "Text", function(Theme)
            return self:Format(Theme)
        end, Scope)
        self.Updater = SharedUpdater(Owner.Library)
        self.Updater.Watermarks[self] = true
        Scope:Add(function()
            self.Updater.Watermarks[self] = nil
            Owner.Watermarks[self.Id] = nil
            if Owner.Watermark == self then
                Owner.Watermark = nil
            end
            Owner.Library:_UpdateReferences()
            if next(self.Updater.Watermarks) == nil then
                self.Updater.Scope:Destroy()
            end
        end)
        self:SetItems(Options.Items or { "FPS", "Ping", "GameName", "PlayerName" })
        self:SetDraggable(Options.Draggable ~= false)
        Owner.Library.Config:RegisterState("@Watermark:" .. Owner.ConfigId .. ":" .. self.Id, self, Scope)
        return self
    end

    function Watermark:Format(Theme)
        local Parts = {}
        if self.Name ~= "" then
            table.insert(Parts, Escape(self.Name))
        end
        for _, Item in self.Items do
            if Item.Visible ~= false and self.Values[Item.Id] ~= nil then
                local Text = Escape(self.Values[Item.Id])
                if Item.Provider == "FPS" then
                    Text ..= "fps"
                elseif Item.Provider == "Ping" then
                    Text ..= "ms"
                end
                table.insert(Parts, Text)
            end
        end
        return table.concat(Parts, " | ")
    end

    function Watermark:Refresh()
        if not self.Scope.Alive or not self.Updater then
            return self
        end
        for _, Item in self.Items do
            local Provider, Value = Item.Provider, Item.Value
            if type(Provider) == "function" then
                local Success, Result = pcall(Provider, self)
                Value = if Success and Result ~= nil then Result else "—"
            elseif Provider == "FPS" then
                Value = self.Updater.FPS or "—"
            elseif Provider == "Ping" then
                Value = self.Updater.Ping or "—"
            elseif Provider == "Time" then
                Value = os.date("%I:%M %p"):gsub("^0", "")
            elseif Provider == "PlayerName" then
                Value = Players.LocalPlayer and Players.LocalPlayer.DisplayName or "—"
            elseif Provider == "GameName" then
                Value = self.Updater.GameName
            end
            self.Values[Item.Id] = Value
        end
        local Text = self:Format(self.Context.Theme.Values)
        if self.Label.Text ~= Text then
            self.Label.Text = Text
            local Params = Instance.new("GetTextBoundsParams")
            Params.Text, Params.Font, Params.Size, Params.Width =
                Text:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">"), self.Label.FontFace, 14, 10000
            local OK, Bounds = pcall(
                game:GetService("TextService").GetTextBoundsAsync,
                game:GetService("TextService"),
                Params
            )
            Params:Destroy()
            if self.Scope.Alive then
                local _, View = self:GetViewport()
                self.Frame.Size =
                    UDim2.fromOffset(math.min(OK and Bounds.X + 44 or #Text * 7 + 44, View.X - 16), 35)
            end
        end
        return self
    end

    function Watermark:SetName(Value)
        local Previous = self.Name
        self.Name = tostring(Value)
        self:Refresh()
        if Previous ~= self.Name then
            self.Changed:Fire(self, "Name")
        end
        return self
    end
    local function ItemValue(Name, Value, Previous)
        assert(type(Name) == "string" and Name ~= "", "Watermark item needs a name")
        local Item = { Id = Name, Visible = if Previous then Previous.Visible ~= false else true }
        if type(Value) == "function" or (type(Value) == "string" and Builtins[Value]) then
            Item.Provider = Value
        elseif type(Value) == "table" then
            Item.Provider, Item.Value, Item.Visible =
                Value.Provider, if Value.Value ~= nil then Value.Value else Value.Text, Value.Visible ~= false
            assert(
                Item.Provider == nil or type(Item.Provider) == "function" or Builtins[Item.Provider],
                "Unknown watermark provider"
            )
        else
            Item.Value = Value
        end
        return Item
    end
    local function SameItem(Left, Right)
        return Left
            and Right
            and Left.Id == Right.Id
            and Left.Provider == Right.Provider
            and Left.Value == Right.Value
            and (Left.Visible ~= false) == (Right.Visible ~= false)
    end
    function Watermark:SetItem(Name, Value)
        local Previous, Position
        for Index, Current in self.Items do
            if Current.Id == Name then
                Previous, Position = Current, Index
                break
            end
        end
        local Item = ItemValue(Name, Value, Previous)
        if SameItem(Previous, Item) then
            return self
        end
        if Position then
            self.Items[Position] = Item
        else
            table.insert(self.Items, Item)
        end
        self:Refresh()
        self.Changed:Fire(self, "Items")
        return self
    end
    function Watermark:RemoveItem(Name)
        local Removed = false
        for Index, Item in self.Items do
            if Item.Id == Name then
                table.remove(self.Items, Index)
                self.Values[Name] = nil
                Removed = true
                break
            end
        end
        self:Refresh()
        if Removed then
            self.Changed:Fire(self, "Items")
        end
        return self
    end
    function Watermark:SetItems(Items)
        assert(type(Items) == "table", "Watermark Items must be an array")
        local Prepared, Positions = {}, {}
        for _, Value in Items do
            local Item
            if type(Value) == "string" then
                Item = ItemValue(Value, Value)
            else
                assert(type(Value) == "table", "Watermark item must be text or a table")
                Item = ItemValue(Value.Id or Value.Name, Value)
            end
            if Positions[Item.Id] then
                Prepared[Positions[Item.Id]] = Item
            else
                table.insert(Prepared, Item)
                Positions[Item.Id] = #Prepared
            end
        end
        local Different = #Prepared ~= #self.Items
        for Index, Item in Prepared do
            if not SameItem(Item, self.Items[Index]) then
                Different = true
                break
            end
        end
        if not Different then
            return self
        end
        self.Items = Prepared
        table.clear(self.Values)
        self:Refresh()
        self.Changed:Fire(self, "Items")
        return self
    end
    function Watermark:Configure(Options)
        if Options.Name ~= nil then
            self:SetName(Options.Name)
        end
        if Options.Items then
            self:SetItems(Options.Items)
        end
        if Options.Position then
            self:SetPosition(Options.Position)
        end
        if Options.Width then
            self.Frame.Size = UDim2.fromOffset(math.clamp(Options.Width, 80, 1000), 30)
        end
        if Options.Visible ~= nil then
            self:SetVisible(Options.Visible)
        end
        if Options.Draggable ~= nil then
            self:SetDraggable(Options.Draggable)
        end
        return self
    end
    function Watermark:Get()
        local Items = {}
        for _, Item in self.Items do
            table.insert(Items, {
                Id = Item.Id,
                Provider = if type(Item.Provider) == "string" then Item.Provider else nil,
                Value = if type(Item.Value) == "string"
                        or type(Item.Value) == "number"
                        or type(Item.Value) == "boolean"
                    then Item.Value
                    else nil,
                Custom = type(Item.Provider) == "function",
                Visible = Item.Visible ~= false,
            })
        end
        return {
            Name = self.Name,
            Visible = self.Visible,
            Draggable = self.Draggable,
            Position = { X = self.Position.X, Y = self.Position.Y },
            Items = Items,
        }
    end
    function Watermark:Validate(Value)
        if
            type(Value) ~= "table"
            or type(Value.Name) ~= "string"
            or type(Value.Visible) ~= "boolean"
            or type(Value.Draggable) ~= "boolean"
            or type(Value.Position) ~= "table"
            or not Finite(Value.Position.X)
            or not Finite(Value.Position.Y)
            or type(Value.Items) ~= "table"
        then
            return false, "Invalid watermark state"
        end
        local Seen = {}
        for _, Item in Value.Items do
            if
                type(Item) ~= "table"
                or type(Item.Id) ~= "string"
                or Seen[Item.Id]
                or (Item.Provider ~= nil and not Builtins[Item.Provider])
                or (
                    Item.Value ~= nil
                    and type(Item.Value) ~= "string"
                    and type(Item.Value) ~= "boolean"
                    and not Finite(Item.Value)
                )
            then
                return false, "Invalid watermark item"
            end
            Seen[Item.Id] = true
        end
        return true
    end
    function Watermark:Set(Value)
        local Valid, Reason = self:Validate(Value)
        assert(Valid, Reason)
        local Existing = {}
        for _, Item in self.Items do
            Existing[Item.Id] = Item
        end
        local Items = {}
        for _, Saved in Value.Items do
            local Item = table.clone(Saved)
            if Saved.Custom and Existing[Saved.Id] then
                Item.Provider = Existing[Saved.Id].Provider
            end
            table.insert(Items, Item)
        end
        self:SetItems(Items)
        self:SetName(Value.Name)
        self:SetDraggable(Value.Draggable)
        self:SetPosition(Value.Position)
        self:SetVisible(Value.Visible)
        return self:Refresh()
    end

    function KeybindList.New(Owner)
        local self = setmetatable({ Rows = {}, OnlyActive = true, ShowModes = true }, KeybindList)
        InitializeComponent(self, Owner, "ActiveKeybinds", Vector2.new(24, 116), Vector2.new(118, 30), true)
        local C, Scope = self.Context, self.Scope
        self.Frame.BackgroundTransparency = 1
        self.Frame.UICorner:Destroy()
        local Header = C:Create(
            "Frame",
            {
                Name = "Header",
                Parent = self.Frame,
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.fromOffset(116, 28),
                BackgroundTransparency = 0,
            },
            { BackgroundColor3 = "Surface" },
            Scope
        )
        C:Corner(Header, 7)
        C:Stroke(Header, "Border", Scope).Transparency = 0.6
        C:Text(
            Header,
            "Keybinds",
            { Name = "Title", Size = UDim2.fromScale(1, 1), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center },
            Scope
        )
        self.Header = Header
        self.DragHandle.Position = UDim2.fromOffset(1, 1)
        self.DragHandle.Size = UDim2.fromOffset(116, 28)
        self.List = C:Create("ScrollingFrame", {
            Name = "Bindings",
            Parent = self.Frame,
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.new(1, 0, 1, -32),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, nil, Scope)
        Owner.Library.KeybindManager:Subscribe(Scope, function()
            self:Refresh()
        end)
        C.Theme:Subscribe(function()
            self:Refresh()
        end, Scope)
        Owner.Library.Config:RegisterState("@KeybindList:" .. Owner.ConfigId, self, Scope)
        Scope:Connect(Owner.Window.Screen:GetPropertyChangedSignal("AbsoluteSize"), function()
            self:Refresh()
        end)
        return self
    end

    function KeybindList:SetOnlyActive(Value)
        local Previous = self.OnlyActive
        self.OnlyActive = Value == true
        self:Refresh()
        if Previous ~= self.OnlyActive then
            self.Changed:Fire(self, "OnlyActive")
        end
        return self
    end
    function KeybindList:GetOnlyActive()
        return self.OnlyActive
    end
    function KeybindList:SetShowModes(Value)
        local Previous = self.ShowModes
        self.ShowModes = Value == true
        self:Refresh()
        if Previous ~= self.ShowModes then
            self.Changed:Fire(self, "ShowModes")
        end
        return self
    end
    function KeybindList:GetShowModes()
        return self.ShowModes
    end
    function KeybindList:Refresh()
        if not self.Scope.Alive then
            return self
        end
        self.RefreshSerial = (self.RefreshSerial or 0) + 1
        local Serial = self.RefreshSerial
        local Included, Ordered = {}, {}
        for _, Binding in self.Hud.Library.KeybindManager:GetBindings() do
            if
                Binding:GetShowInBinds()
                and (Binding:GetKey() ~= Enum.KeyCode.Unknown or Binding:GetMode() == "Always")
                and (not self.OnlyActive or Binding:IsActive())
            then
                Included[Binding] = true
                table.insert(Ordered, Binding)
            end
        end
        local C = self.Context
        for Binding, Row in self.Rows do
            if not Included[Binding] and not Row.Closing then
                Row.Closing = true
                Row.Serial = (Row.Serial or 0) + 1
                local Serial = Row.Serial
                C:Tween(
                    Row.Frame,
                    "BindRow",
                    { GroupTransparency = 1, Position = Row.Frame.Position - UDim2.fromOffset(4, 0) },
                    Row.Scope
                )
                Row.Scope:Delay(0.17, function()
                    if Row.Closing and Row.Serial == Serial then
                        Row.Scope:Destroy()
                        self.Rows[Binding] = nil
                        self:Refresh()
                    end
                end)
            end
        end
        local Width, ContentHeight = 116, math.max(0, #Ordered * 28 - 2)
        for Binding, Row in self.Rows do
            if Row.Closing and not Included[Binding] then
                Width = math.max(Width, Row.Frame.Size.X.Offset)
                ContentHeight =
                    math.max(ContentHeight, Row.Frame.Position.Y.Offset + Row.Frame.Size.Y.Offset + 1)
            end
        end
        for Index, Binding in Ordered do
            local Row = self.Rows[Binding]
            if not Row then
                local Scope = self.Scope:Child()
                local Frame = C:Create(
                    "CanvasGroup",
                    {
                        Name = "Binding",
                        Parent = self.List,
                        BackgroundTransparency = 0,
                        GroupTransparency = 1,
                        Size = UDim2.fromOffset(116, 24),
                        Position = UDim2.fromOffset(-3, 1 + (Index - 1) * 28),
                    },
                    { BackgroundColor3 = "Surface" },
                    Scope
                )
                C:Corner(Frame, 7)
                C:Stroke(Frame, "Border", Scope).Transparency = 0.6
                Row = { Frame = Frame, Scope = Scope, Binding = Binding }
                Row.Label = C:Text(
                    Frame,
                    "",
                    {
                        Name = "BindingText",
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -16, 1, 0),
                        TextSize = 14,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    },
                    Scope
                )
                C:Bind(Row.Label, "Font", "FontBold", Scope)
                C:Bind(Row.Label, "TextColor3", function(T)
                    return Binding:IsActive() and T.Text or T.InactiveTab
                end, Scope)
                self.Rows[Binding] = Row
            end
            Row.Closing = false
            Row.Serial = (Row.Serial or 0) + 1
            local Key, Mode = Binding.DisplayKey, Binding:GetMode()
            Row.Label.Text = Binding.Name
                .. (self.ShowModes and " - " .. string.lower(Mode) or "")
                .. (Mode == "Always" and "" or " [" .. Key .. "]")
            Row.Label.TextColor3 = C.Theme.Values[Binding:IsActive() and "Text" or "InactiveTab"]
            local Bounds = MeasureText(Row.Label.Text, Row.Label, 10000)
            if not self.Scope.Alive or Serial ~= self.RefreshSerial then
                return self
            end
            local _, View = self:GetViewport()
            local RowWidth = math.min(math.max(64, math.ceil(Bounds.X) + 16), View.X - 18)
            Row.Frame.Size = UDim2.fromOffset(RowWidth, 24)
            Width = math.max(Width, RowWidth)
            C:Tween(
                Row.Frame,
                "BindRow",
                { GroupTransparency = 0, Position = UDim2.fromOffset(1, 1 + (Index - 1) * 28) },
                Row.Scope
            )
        end
        local _, View = self:GetViewport()
        self.List.Visible = next(self.Rows) ~= nil
        self.List.CanvasSize = UDim2.fromOffset(0, ContentHeight)
        local Height = self.List.Visible and 32 + ContentHeight or 30
        C:Tween(
            self.Frame,
            "BindRow",
            { Size = UDim2.fromOffset(
                math.min(Width + 2, View.X - 16),
                math.min(Height, math.max(58, View.Y - 16))
            ) },
            self.Scope
        )
        return self
    end
    function KeybindList:Get()
        return {
            Visible = self.Visible,
            OnlyActive = self.OnlyActive,
            ShowModes = self.ShowModes,
            Position = { X = self.Position.X, Y = self.Position.Y },
        }
    end
    function KeybindList:Validate(Value)
        return type(Value) == "table"
            and type(Value.Visible) == "boolean"
            and type(Value.OnlyActive) == "boolean"
            and (Value.ShowModes == nil or type(Value.ShowModes) == "boolean")
            and type(Value.Position) == "table"
            and Finite(Value.Position.X)
            and Finite(Value.Position.Y),
            "Invalid keybind HUD state"
    end
    function KeybindList:Set(Value)
        local Valid, Reason = self:Validate(Value)
        assert(Valid, Reason)
        self:SetOnlyActive(Value.OnlyActive)
        self:SetShowModes(Value.ShowModes ~= false)
        self:SetPosition(Value.Position)
        self:SetVisible(Value.Visible)
        return self
    end

    function Hud.New(Library, Window)
        local self = setmetatable({
            Library = Library,
            Window = Window,
            Context = Window.Context,
            Scope = Window.Scope:Child(),
            ConfigId = tostring(Window.ConfigId or "Main"),
            Watermarks = {},
        }, Hud)
        self.Layer = self.Context:Create("Frame", {
            Name = "Hud",
            Parent = Window.Scene,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 50,
        }, nil, self.Scope)
        Window.Hud = self
        self.Watermark = self:CreateWatermark({})
        self.KeybindList = KeybindList.New(self)
        return self
    end
    function Hud:CreateWatermark(Options)
        Options = Options or {}
        local Id = tostring(Options.Id or "Main")
        local Existing = self.Watermarks[Id]
        if Existing and Existing.Scope.Alive then
            return Existing:Configure(Options)
        end
        local Mark = Watermark.New(self, Options)
        self.Watermarks[Id] = Mark
        if Id == "Main" then
            self.Watermark = Mark
            self.Library:_UpdateReferences()
        end
        return Mark
    end
    function Hud:Destroy()
        self.Scope:Destroy()
    end
    return Hud
end)()

-- Core/Templates
local VisualTemplates = (function()
    -- Visual templates extracted from StarterGui.myhoe in Interface Place.
    local Templates = {}
    local Shapes = {
        Window = {
            Class = "CanvasGroup",
            Properties = {
                LayoutOrder = 0,
                Active = false,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "MainFrame",
                Visible = true,
                Size = UDim2.new(0, 600, 0, 532),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = 0,
                BackgroundTransparency = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
            },
            Tokens = { BackgroundColor3 = "Background" },
            Children = {
                {
                    Class = "UICorner",
                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 12) },
                    Tokens = {},
                    Children = {},
                },
                { Class = "UIShadow", Properties = { Name = "UIShadow" }, Tokens = {}, Children = {} },
                {
                    Class = "UIStroke",
                    Properties = {
                        Thickness = 1,
                        Transparency = 0,
                        Name = "UIStroke",
                        Color = Color3.fromRGB(37, 40, 44),
                        Enabled = true,
                        LineJoinMode = Enum.LineJoinMode.Round,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Side",
                        Visible = true,
                        Size = UDim2.new(0, 81, 1, 0),
                        AnchorPoint = Vector2.new(0, 0),
                        Rotation = 0,
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.None,
                    },
                    Tokens = { BackgroundColor3 = "Surface" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 12) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "_",
                                Visible = true,
                                Size = UDim2.new(0, 1, 1, 0),
                                AnchorPoint = Vector2.new(0, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(1, 0, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                            },
                            Tokens = { BackgroundColor3 = "Border" },
                            Children = {},
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Shadow",
                                Visible = true,
                                Size = UDim2.new(0, 12, 1, 0),
                                AnchorPoint = Vector2.new(0, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(1, 1, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 0,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0.86875, 0),
                                            NumberSequenceKeypoint.new(0.34663, 0.94375, 0),
                                            NumberSequenceKeypoint.new(1, 1, 0),
                                        }),
                                        Name = "UIGradient",
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                                        }),
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                            },
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Holder",
                                Visible = true,
                                Size = UDim2.new(1, 0, 1, 0),
                                AnchorPoint = Vector2.new(0, 0),
                                Rotation = 0,
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 0, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "LogoBackground",
                                        Visible = true,
                                        Size = UDim2.new(0, 45, 0, 45),
                                        AnchorPoint = Vector2.new(0.5, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0.5, 0, 0, 15),
                                        BorderSizePixel = 0,
                                        ZIndex = 2,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                    },
                                    Tokens = { BackgroundColor3 = "Accent" },
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 12) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIGradient",
                                            Properties = {
                                                Rotation = 40,
                                                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0, 0),
                                                    NumberSequenceKeypoint.new(1, 0, 0),
                                                }),
                                                Name = "UIGradient",
                                                Enabled = true,
                                                Offset = Vector2.new(0, 0),
                                            },
                                            Tokens = {
                                                Color = function(T)
                                                    return ColorSequence.new(
                                                        T.Accent,
                                                        T.Accent:Lerp(Color3.new(), 0.32)
                                                    )
                                                end,
                                            },
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Image = "rbxassetid://93452315279322",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 2,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 28, 0, 28),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                                SliceScale = 1,
                                                Name = "Icon",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Image = "rbxassetid://93452315279322",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 28, 0, 28),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ImageColor3 = Color3.fromRGB(0, 0, 0),
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0.5,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0.5, 2, 0.5, 2),
                                                SliceScale = 1,
                                                Name = "Shadow",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "Frame",
                                            Properties = {
                                                LayoutOrder = 0,
                                                Active = false,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Name = "_",
                                                Visible = true,
                                                Size = UDim2.new(0, 45, 0, 1),
                                                AnchorPoint = Vector2.new(0.5, 0),
                                                Rotation = 0,
                                                BackgroundTransparency = 0,
                                                Position = UDim2.new(0.5, 0, 1, 18),
                                                BorderSizePixel = 0,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                            },
                                            Tokens = { BackgroundColor3 = "Border" },
                                            Children = {},
                                        },
                                    },
                                },
                                {
                                    Class = "UIPadding",
                                    Properties = {
                                        PaddingTop = UDim.new(0, 18),
                                        Name = "UIPadding",
                                        PaddingBottom = UDim.new(0, 0),
                                        PaddingLeft = UDim.new(0, 0),
                                        PaddingRight = UDim.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "Pages",
                                        Visible = true,
                                        Size = UDim2.new(1, -20, 1, -176),
                                        AnchorPoint = Vector2.new(0, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 1,
                                        Position = UDim2.new(0, 10, 0, 86),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UIListLayout",
                                            Properties = {
                                                FillDirection = Enum.FillDirection.Vertical,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                                VerticalFlex = Enum.UIFlexAlignment.None,
                                                VerticalAlignment = Enum.VerticalAlignment.Top,
                                                SortOrder = Enum.SortOrder.LayoutOrder,
                                                Name = "UIListLayout",
                                                Padding = UDim.new(0, 12),
                                                Wraps = false,
                                                HorizontalFlex = Enum.UIFlexAlignment.None,
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIPadding",
                                            Properties = {
                                                PaddingTop = UDim.new(0, 37),
                                                Name = "UIPadding",
                                                PaddingBottom = UDim.new(0, 8),
                                                PaddingLeft = UDim.new(0, 0),
                                                PaddingRight = UDim.new(0, 0),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                    },
                                },
                                {
                                    Class = "UIListLayout",
                                    Properties = {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalFlex = Enum.UIFlexAlignment.None,
                                        VerticalAlignment = Enum.VerticalAlignment.Top,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        Name = "UIListLayout",
                                        Padding = UDim.new(0, 0),
                                        Wraps = false,
                                        HorizontalFlex = Enum.UIFlexAlignment.None,
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                            },
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Bottom",
                                Visible = true,
                                Size = UDim2.new(1, 0, 0, 79),
                                AnchorPoint = Vector2.new(0, 1),
                                Rotation = 0,
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 0, 1, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "ImageLabel",
                                    Properties = {
                                        Visible = true,
                                        Active = false,
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Image = "rbxassetid://104071533684582",
                                        ImageRectSize = Vector2.new(0, 0),
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        Size = UDim2.new(0, 45, 0, 45),
                                        ScaleType = Enum.ScaleType.Stretch,
                                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        LayoutOrder = 0,
                                        SliceCenter = Rect.new(0, 0, 0, 0),
                                        ImageTransparency = 0,
                                        Rotation = 0,
                                        ImageRectOffset = Vector2.new(0, 0),
                                        BackgroundTransparency = 1,
                                        Position = UDim2.new(0.5, 0, 0.5, -1),
                                        SliceScale = 1,
                                        Name = "Avatar",
                                        BorderSizePixel = 0,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 6) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "Frame",
                                            Properties = {
                                                LayoutOrder = 0,
                                                Active = false,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Name = "SearchBackground",
                                                Visible = true,
                                                Size = UDim2.new(0, 24, 0, 24),
                                                AnchorPoint = Vector2.new(1, 0),
                                                Rotation = 0,
                                                BackgroundTransparency = 0,
                                                Position = UDim2.new(1, 4, 0, -3),
                                                BorderSizePixel = 0,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                            },
                                            Tokens = { BackgroundColor3 = "Surface" },
                                            Children = {
                                                {
                                                    Class = "UICorner",
                                                    Properties = {
                                                        Name = "UICorner",
                                                        CornerRadius = UDim.new(1, 0),
                                                    },
                                                    Tokens = {},
                                                    Children = {},
                                                },
                                                {
                                                    Class = "ImageButton",
                                                    Properties = {
                                                        Visible = true,
                                                        Active = true,
                                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                                        Image = "rbxassetid://95715134255947",
                                                        ImageRectSize = Vector2.new(0, 0),
                                                        ZIndex = 1,
                                                        AutomaticSize = Enum.AutomaticSize.None,
                                                        Size = UDim2.new(0, 16, 0, 16),
                                                        ScaleType = Enum.ScaleType.Stretch,
                                                        LayoutOrder = 0,
                                                        ClipsDescendants = false,
                                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                        SliceCenter = Rect.new(0, 0, 0, 0),
                                                        ImageTransparency = 0,
                                                        AutoButtonColor = false,
                                                        Rotation = 0,
                                                        ImageRectOffset = Vector2.new(0, 0),
                                                        BackgroundTransparency = 1,
                                                        Position = UDim2.new(0.5, 0, 0.5, 0),
                                                        SliceScale = 1,
                                                        Name = "Search",
                                                        BorderSizePixel = 0,
                                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                                    },
                                                    Tokens = { ImageColor3 = "InactiveTab" },
                                                    Children = {},
                                                },
                                            },
                                        },
                                    },
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "_",
                                        Visible = true,
                                        Size = UDim2.new(0, 45, 0, 1),
                                        AnchorPoint = Vector2.new(0.5, 1),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0.5, 0, 0, -2),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                    },
                                    Tokens = { BackgroundColor3 = "Border" },
                                    Children = {},
                                },
                            },
                        },
                    },
                },
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Content",
                        Visible = true,
                        Size = UDim2.new(1, -82, 1, 0),
                        AnchorPoint = Vector2.new(0, 0),
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 82, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = {},
                    Children = {
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "PathOutline",
                                Visible = true,
                                Size = UDim2.new(0, 0, 0, 35),
                                AnchorPoint = Vector2.new(1, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(1, -10, 0, 10),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.X,
                            },
                            Tokens = { BackgroundColor3 = "Border" },
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIPadding",
                                    Properties = {
                                        PaddingTop = UDim.new(0, 1),
                                        Name = "UIPadding",
                                        PaddingBottom = UDim.new(0, 1),
                                        PaddingLeft = UDim.new(0, 1),
                                        PaddingRight = UDim.new(0, 1),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "Path",
                                        Visible = true,
                                        Size = UDim2.new(1, 0, 1, 0),
                                        AnchorPoint = Vector2.new(0, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0, 0, 0, 0),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                    },
                                    Tokens = { BackgroundColor3 = "NavSelected" },
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIListLayout",
                                            Properties = {
                                                FillDirection = Enum.FillDirection.Horizontal,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                                VerticalFlex = Enum.UIFlexAlignment.None,
                                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                                SortOrder = Enum.SortOrder.LayoutOrder,
                                                Name = "UIListLayout",
                                                Padding = UDim.new(0, 8),
                                                Wraps = false,
                                                HorizontalFlex = Enum.UIFlexAlignment.None,
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0, 0),
                                                Image = "rbxassetid://88475069824972",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 18, 0, 18),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0, 0, 0, 0),
                                                SliceScale = 1,
                                                Name = "TabIcon",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = { ImageColor3 = "InactiveTab" },
                                            Children = {},
                                        },
                                        {
                                            Class = "TextLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                TextTransparency = 0,
                                                TextStrokeTransparency = 1,
                                                AnchorPoint = Vector2.new(0, 0.5),
                                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                                TextTruncate = Enum.TextTruncate.None,
                                                TextWrapped = false,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.XY,
                                                Size = UDim2.new(0, 0, 0, 0),
                                                BorderSizePixel = 0,
                                                RichText = false,
                                                Name = "TabText",
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Text = "Combat",
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                TextSize = 14,
                                                Rotation = 0,
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0, 34, 0.5, 0),
                                                LayoutOrder = 0,
                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                TextScaled = false,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = { FontFace = "FontFaceBold", TextColor3 = "InactiveTab" },
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0, 0),
                                                Image = "rbxassetid://85616949262640",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 14, 0, 14),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0, 0, 0, 0),
                                                SliceScale = 1,
                                                Name = "Arrow",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = { ImageColor3 = "Text" },
                                            Children = {},
                                        },
                                        {
                                            Class = "UIPadding",
                                            Properties = {
                                                PaddingTop = UDim.new(0, 0),
                                                Name = "UIPadding",
                                                PaddingBottom = UDim.new(0, 0),
                                                PaddingLeft = UDim.new(0, 8),
                                                PaddingRight = UDim.new(0, 8),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0, 0),
                                                Image = "rbxassetid://83974014297455",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 18, 0, 18),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0, 0, 0, 0),
                                                SliceScale = 1,
                                                Name = "SubTabIcon",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = { ImageColor3 = "InactiveTab" },
                                            Children = {},
                                        },
                                        {
                                            Class = "TextLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                TextTransparency = 0,
                                                TextStrokeTransparency = 1,
                                                AnchorPoint = Vector2.new(0, 0.5),
                                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                                TextTruncate = Enum.TextTruncate.None,
                                                TextWrapped = false,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.XY,
                                                Size = UDim2.new(0, 0, 0, 0),
                                                BorderSizePixel = 0,
                                                RichText = false,
                                                Name = "SubTabText",
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Text = "Rage",
                                                TextXAlignment = Enum.TextXAlignment.Center,
                                                TextSize = 14,
                                                Rotation = 0,
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0, 34, 0.5, 0),
                                                LayoutOrder = 0,
                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                TextScaled = false,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = { FontFace = "FontFaceBold", TextColor3 = "InactiveTab" },
                                            Children = {},
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        SideTab = {
            Class = "TextButton",
            Properties = {
                Visible = true,
                Active = true,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Name = "ActiveOutline",
                TextTruncate = Enum.TextTruncate.None,
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.new(0, 45, 0, 45),
                TextWrapped = false,
                RichText = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "",
                TextSize = 14,
                AutoButtonColor = false,
                Rotation = 0,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 0, 0, 0),
                LayoutOrder = 0,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false,
            },
            Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Border" },
            Children = {
                {
                    Class = "UICorner",
                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 12) },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "UIPadding",
                    Properties = {
                        PaddingTop = UDim.new(0, 1),
                        Name = "UIPadding",
                        PaddingBottom = UDim.new(0, 1),
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                    },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "TextButton",
                    Properties = {
                        Visible = true,
                        Active = true,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Inner",
                        TextTruncate = Enum.TextTruncate.None,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        Size = UDim2.new(1, 0, 1, 0),
                        TextWrapped = false,
                        RichText = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "",
                        TextSize = 14,
                        AutoButtonColor = false,
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                    },
                    Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "NavSelected" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 12) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "ImageLabel",
                            Properties = {
                                Visible = true,
                                Active = false,
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Image = "rbxassetid://88475069824972",
                                ImageRectSize = Vector2.new(0, 0),
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                Size = UDim2.new(0, 22, 0, 22),
                                ScaleType = Enum.ScaleType.Stretch,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                LayoutOrder = 0,
                                SliceCenter = Rect.new(0, 0, 0, 0),
                                ImageTransparency = 0,
                                Rotation = 0,
                                ImageRectOffset = Vector2.new(0, 0),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                SliceScale = 1,
                                Name = "Icon",
                                BorderSizePixel = 0,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 40,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {
                                        Color = function(T)
                                            return ColorSequence.new(
                                                T.Accent,
                                                T.Accent:Lerp(Color3.new(), 0.32)
                                            )
                                        end,
                                    },
                                    Children = {},
                                },
                            },
                        },
                    },
                },
            },
        },
        PageTab = {
            Class = "TextButton",
            Properties = {
                Visible = true,
                Active = true,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Name = "ActiveOutline",
                TextTruncate = Enum.TextTruncate.None,
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 45, 0, 35),
                TextWrapped = false,
                RichText = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "",
                TextSize = 14,
                AutoButtonColor = false,
                Rotation = 0,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 0, 0, 0),
                LayoutOrder = 0,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false,
            },
            Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Border" },
            Children = {
                {
                    Class = "UICorner",
                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "UIPadding",
                    Properties = {
                        PaddingTop = UDim.new(0, 1),
                        Name = "UIPadding",
                        PaddingBottom = UDim.new(0, 1),
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                    },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "TextButton",
                    Properties = {
                        Visible = true,
                        Active = true,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Inner",
                        TextTruncate = Enum.TextTruncate.None,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        Size = UDim2.new(1, 0, 1, 0),
                        TextWrapped = false,
                        RichText = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "",
                        TextSize = 14,
                        AutoButtonColor = false,
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                    },
                    Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "NavSelected" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "ImageLabel",
                            Properties = {
                                Visible = true,
                                Active = false,
                                AnchorPoint = Vector2.new(0, 0.5),
                                Image = "rbxassetid://83974014297455",
                                ImageRectSize = Vector2.new(0, 0),
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                Size = UDim2.new(0, 18, 0, 18),
                                ScaleType = Enum.ScaleType.Stretch,
                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                LayoutOrder = 0,
                                SliceCenter = Rect.new(0, 0, 0, 0),
                                ImageTransparency = 0,
                                Rotation = 0,
                                ImageRectOffset = Vector2.new(0, 0),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 0, 0.5, 0),
                                SliceScale = 1,
                                Name = "Icon",
                                BorderSizePixel = 0,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 40,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {
                                        Color = function(T)
                                            return ColorSequence.new(
                                                T.Accent,
                                                T.Accent:Lerp(Color3.new(), 0.32)
                                            )
                                        end,
                                    },
                                    Children = {},
                                },
                            },
                        },
                        {
                            Class = "TextLabel",
                            Properties = {
                                Visible = true,
                                Active = false,
                                TextTransparency = 0,
                                TextStrokeTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0.5),
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextTruncate = Enum.TextTruncate.None,
                                TextWrapped = false,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.XY,
                                Size = UDim2.new(0, 0, 0, 0),
                                BorderSizePixel = 0,
                                RichText = false,
                                Name = "Label",
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Text = "Rage",
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextSize = 14,
                                Rotation = 0,
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 26, 0.5, 0),
                                LayoutOrder = 0,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                TextScaled = false,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                            Children = {},
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 0),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 0),
                                PaddingLeft = UDim.new(0, 8),
                                PaddingRight = UDim.new(0, 8),
                            },
                            Tokens = {},
                            Children = {},
                        },
                    },
                },
            },
        },
        Section = {
            Class = "Frame",
            Properties = {
                LayoutOrder = 0,
                Active = false,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "SectionOutline",
                Visible = true,
                Size = UDim2.new(1, 0, 0, 80),
                AnchorPoint = Vector2.new(0, 0),
                Rotation = 0,
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            },
            Tokens = { BackgroundColor3 = "Border" },
            Children = {
                {
                    Class = "UICorner",
                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "UIPadding",
                    Properties = {
                        PaddingTop = UDim.new(0, 1),
                        Name = "UIPadding",
                        PaddingBottom = UDim.new(0, 1),
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                    },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Section",
                        Visible = true,
                        Size = UDim2.new(1, 0, 1, 0),
                        AnchorPoint = Vector2.new(0, 0),
                        Rotation = 0,
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                    },
                    Tokens = { BackgroundColor3 = "Surface" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 8) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Top",
                                Visible = true,
                                Size = UDim2.new(1, 0, 0, 35),
                                AnchorPoint = Vector2.new(0, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(0, 0, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 2,
                                AutomaticSize = Enum.AutomaticSize.None,
                            },
                            Tokens = { BackgroundColor3 = "SectionHeader" },
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 10) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "_",
                                        Visible = true,
                                        Size = UDim2.new(1, 0, 0, 1),
                                        AnchorPoint = Vector2.new(0, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0, 0, 1, 0),
                                        BorderSizePixel = 0,
                                        ZIndex = 2,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                    },
                                    Tokens = { BackgroundColor3 = "Border" },
                                    Children = {},
                                },
                                {
                                    Class = "ImageLabel",
                                    Properties = {
                                        Visible = true,
                                        Active = false,
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        Image = "rbxassetid://128242806404957",
                                        ImageRectSize = Vector2.new(0, 0),
                                        ZIndex = 2,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        Size = UDim2.new(0, 16, 0, 16),
                                        ScaleType = Enum.ScaleType.Stretch,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        LayoutOrder = 0,
                                        SliceCenter = Rect.new(0, 0, 0, 0),
                                        ImageTransparency = 0,
                                        Rotation = 0,
                                        ImageRectOffset = Vector2.new(0, 0),
                                        BackgroundTransparency = 1,
                                        Position = UDim2.new(0, 10, 0.5, 0),
                                        SliceScale = 1,
                                        Name = "Icon",
                                        BorderSizePixel = 0,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = { ImageColor3 = "Text" },
                                    Children = {
                                        {
                                            Class = "UIGradient",
                                            Properties = {
                                                Rotation = 40,
                                                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0, 0),
                                                    NumberSequenceKeypoint.new(1, 0, 0),
                                                }),
                                                Name = "UIGradient",
                                                Enabled = false,
                                                Offset = Vector2.new(0, 0),
                                            },
                                            Tokens = {
                                                Color = function(T)
                                                    return ColorSequence.new(
                                                        T.Accent,
                                                        T.Accent:Lerp(Color3.new(), 0.32)
                                                    )
                                                end,
                                            },
                                            Children = {},
                                        },
                                        {
                                            Class = "Frame",
                                            Properties = {
                                                LayoutOrder = 0,
                                                Active = false,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Name = "Seperator",
                                                Visible = true,
                                                Size = UDim2.new(0, 1, 0, 15),
                                                AnchorPoint = Vector2.new(0, 0.5),
                                                Rotation = 0,
                                                BackgroundTransparency = 0,
                                                Position = UDim2.new(1, 10, 0.5, 0),
                                                BorderSizePixel = 0,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                            },
                                            Tokens = { BackgroundColor3 = "Border" },
                                            Children = {
                                                {
                                                    Class = "UIStroke",
                                                    Properties = {
                                                        Thickness = 1,
                                                        Transparency = 0.6,
                                                        Name = "UIStroke",
                                                        Color = Color3.fromRGB(37, 40, 44),
                                                        Enabled = true,
                                                        LineJoinMode = Enum.LineJoinMode.Miter,
                                                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                                    },
                                                    Tokens = {},
                                                    Children = {},
                                                },
                                            },
                                        },
                                    },
                                },
                                {
                                    Class = "TextLabel",
                                    Properties = {
                                        Visible = true,
                                        Active = false,
                                        TextTransparency = 0,
                                        TextStrokeTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                        TextTruncate = Enum.TextTruncate.None,
                                        TextWrapped = false,
                                        ZIndex = 2,
                                        AutomaticSize = Enum.AutomaticSize.XY,
                                        Size = UDim2.new(0, 0, 0, 0),
                                        BorderSizePixel = 0,
                                        RichText = false,
                                        Name = "Label",
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Text = "Ragebot",
                                        TextXAlignment = Enum.TextXAlignment.Center,
                                        TextSize = 14,
                                        Rotation = 0,
                                        BackgroundTransparency = 1,
                                        Position = UDim2.new(0, 48, 0.5, 0),
                                        LayoutOrder = 0,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        TextScaled = false,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                                    Children = {},
                                },
                            },
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Content",
                                Visible = true,
                                Size = UDim2.new(1, 0, 0, 0),
                                AnchorPoint = Vector2.new(0, 0),
                                Rotation = 0,
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 0, 0, 41),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.Y,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "UIListLayout",
                                    Properties = {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                        VerticalFlex = Enum.UIFlexAlignment.None,
                                        VerticalAlignment = Enum.VerticalAlignment.Top,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        Name = "UIListLayout",
                                        Padding = UDim.new(0, 6),
                                        Wraps = false,
                                        HorizontalFlex = Enum.UIFlexAlignment.None,
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIPadding",
                                    Properties = {
                                        PaddingTop = UDim.new(0, 1),
                                        Name = "UIPadding",
                                        PaddingBottom = UDim.new(0, -2),
                                        PaddingLeft = UDim.new(0, 6),
                                        PaddingRight = UDim.new(0, 6),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                            },
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 0),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 10),
                                PaddingLeft = UDim.new(0, 0),
                                PaddingRight = UDim.new(0, 0),
                            },
                            Tokens = {},
                            Children = {},
                        },
                    },
                },
            },
        },
        Toggle = {
            Class = "TextButton",
            Properties = {
                Visible = true,
                Active = true,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Toggle",
                TextTruncate = Enum.TextTruncate.None,
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.new(1, 0, 0, 18),
                TextWrapped = false,
                RichText = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "",
                TextSize = 14,
                AutoButtonColor = false,
                Rotation = 0,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                LayoutOrder = 0,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            },
            Tokens = { FontFace = "FontFaceBold" },
            Children = {
                {
                    Class = "TextLabel",
                    Properties = {
                        Visible = true,
                        Active = false,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextTruncate = Enum.TextTruncate.None,
                        TextWrapped = false,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        Size = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        RichText = false,
                        Name = "Label",
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "Enabled",
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 14,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0.5, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                    Children = {},
                },
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "IndicatorOutline",
                        Visible = true,
                        Size = UDim2.new(0, 26, 1, 0),
                        AnchorPoint = Vector2.new(1, 0),
                        Rotation = 0,
                        BackgroundTransparency = 0,
                        Position = UDim2.new(1, 0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                    },
                    Tokens = { BackgroundColor3 = "Border" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(1, 0) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 1),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 1),
                                PaddingLeft = UDim.new(0, 1),
                                PaddingRight = UDim.new(0, 1),
                            },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Indicator",
                                Visible = true,
                                Size = UDim2.new(1, 0, 1, 0),
                                AnchorPoint = Vector2.new(1, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(1, 0, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = {},
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(1, 0) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIPadding",
                                    Properties = {
                                        PaddingTop = UDim.new(0, 1),
                                        Name = "UIPadding",
                                        PaddingBottom = UDim.new(0, 1),
                                        PaddingLeft = UDim.new(0, 1),
                                        PaddingRight = UDim.new(0, 1),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 40,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
                                        }),
                                        Enabled = false,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "Circle",
                                        Visible = true,
                                        Size = UDim2.new(0, 12, 0, 12),
                                        AnchorPoint = Vector2.new(1, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(1, -1, 0, 1),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(1, 0) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIGradient",
                                            Properties = {
                                                Rotation = 40,
                                                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0.6, 0),
                                                    NumberSequenceKeypoint.new(1, 0.88125, 0),
                                                }),
                                                Name = "UIGradient",
                                                Color = ColorSequence.new({
                                                    ColorSequenceKeypoint.new(
                                                        0,
                                                        Color3.fromRGB(255, 255, 255)
                                                    ),
                                                    ColorSequenceKeypoint.new(
                                                        1,
                                                        Color3.fromRGB(200, 200, 200)
                                                    ),
                                                }),
                                                Enabled = false,
                                                Offset = Vector2.new(0, 0),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                    },
                                },
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 40,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {
                                        Color = function(T)
                                            return ColorSequence.new(
                                                T.Accent,
                                                T.Accent:Lerp(Color3.new(), 0.32)
                                            )
                                        end,
                                    },
                                    Children = {},
                                },
                            },
                        },
                    },
                },
            },
        },
        Checkbox = {
            Class = "TextButton",
            Properties = {
                Visible = true,
                Active = true,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Checkbox",
                TextTruncate = Enum.TextTruncate.None,
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.new(1, 0, 0, 18),
                TextWrapped = false,
                RichText = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "",
                TextSize = 14,
                AutoButtonColor = false,
                Rotation = 0,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                LayoutOrder = 0,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            },
            Tokens = { FontFace = "FontFaceBold" },
            Children = {
                {
                    Class = "TextLabel",
                    Properties = {
                        Visible = true,
                        Active = false,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextTruncate = Enum.TextTruncate.None,
                        TextWrapped = false,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        Size = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        RichText = false,
                        Name = "Label",
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "Enabled",
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 14,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0.5, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                    Children = {},
                },
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "IndicatorOutline",
                        Visible = true,
                        Size = UDim2.new(0, 18, 0, 18),
                        AnchorPoint = Vector2.new(1, 0),
                        Rotation = 0,
                        BackgroundTransparency = 0,
                        Position = UDim2.new(1, 0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                    },
                    Tokens = { BackgroundColor3 = "Border" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 4) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 1),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 1),
                                PaddingLeft = UDim.new(0, 1),
                                PaddingRight = UDim.new(0, 1),
                            },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "Frame",
                            Properties = {
                                LayoutOrder = 0,
                                Active = false,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "Indicator",
                                Visible = true,
                                Size = UDim2.new(1, 0, 1, 0),
                                AnchorPoint = Vector2.new(1, 0),
                                Rotation = 0,
                                BackgroundTransparency = 0,
                                Position = UDim2.new(1, 0, 0, 0),
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                            },
                            Tokens = { BackgroundColor3 = "Raised" },
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 4) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 40,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
                                        }),
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "Accent",
                                        Visible = true,
                                        Size = UDim2.new(1, 0, 1, 0),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0.5, 0, 0.5, 0),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 4) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIGradient",
                                            Properties = {
                                                Rotation = 40,
                                                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0, 0),
                                                    NumberSequenceKeypoint.new(1, 0, 0),
                                                }),
                                                Name = "UIGradient",
                                                Enabled = true,
                                                Offset = Vector2.new(0, 0),
                                            },
                                            Tokens = {
                                                Color = function(T)
                                                    return ColorSequence.new(
                                                        T.Accent,
                                                        T.Accent:Lerp(Color3.new(), 0.32)
                                                    )
                                                end,
                                            },
                                            Children = {},
                                        },
                                        {
                                            Class = "ImageLabel",
                                            Properties = {
                                                Visible = true,
                                                Active = false,
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Image = "rbxassetid://74297669278475",
                                                ImageRectSize = Vector2.new(0, 0),
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                Size = UDim2.new(0, 12, 0, 12),
                                                ScaleType = Enum.ScaleType.Stretch,
                                                ImageColor3 = Color3.fromRGB(255, 255, 255),
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                LayoutOrder = 0,
                                                SliceCenter = Rect.new(0, 0, 0, 0),
                                                ImageTransparency = 0,
                                                Rotation = 0,
                                                ImageRectOffset = Vector2.new(0, 0),
                                                BackgroundTransparency = 1,
                                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                                SliceScale = 1,
                                                Name = "Icon",
                                                BorderSizePixel = 0,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        Button = {
            Class = "TextButton",
            Properties = {
                Visible = true,
                Active = true,
                TextTransparency = 0,
                TextStrokeTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Button",
                TextTruncate = Enum.TextTruncate.None,
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.new(1, 0, 0, 26),
                TextWrapped = false,
                RichText = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "",
                TextSize = 14,
                AutoButtonColor = false,
                Rotation = 0,
                TextColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0,
                Position = UDim2.new(0, 0, 0, 0),
                LayoutOrder = 0,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false,
            },
            Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Border" },
            Children = {
                {
                    Class = "UICorner",
                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 4) },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "UIPadding",
                    Properties = {
                        PaddingTop = UDim.new(0, 1),
                        Name = "UIPadding",
                        PaddingBottom = UDim.new(0, 1),
                        PaddingLeft = UDim.new(0, 1),
                        PaddingRight = UDim.new(0, 1),
                    },
                    Tokens = {},
                    Children = {},
                },
                {
                    Class = "TextButton",
                    Properties = {
                        Visible = true,
                        Active = true,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "RealButton",
                        TextTruncate = Enum.TextTruncate.None,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        Size = UDim2.new(1, 0, 1, 0),
                        TextWrapped = false,
                        RichText = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "",
                        TextSize = 14,
                        AutoButtonColor = false,
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                    },
                    Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Raised" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 4) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "UIGradient",
                            Properties = {
                                Rotation = 90,
                                Transparency = NumberSequence.new({
                                    NumberSequenceKeypoint.new(0, 0, 0),
                                    NumberSequenceKeypoint.new(1, 0, 0),
                                }),
                                Name = "UIGradient",
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
                                }),
                                Enabled = true,
                                Offset = Vector2.new(0, 0),
                            },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "TextLabel",
                            Properties = {
                                Visible = true,
                                Active = false,
                                TextTransparency = 0,
                                TextStrokeTransparency = 1,
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                TextTruncate = Enum.TextTruncate.None,
                                TextWrapped = false,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.XY,
                                Size = UDim2.new(0, 0, 0, 0),
                                BorderSizePixel = 0,
                                RichText = false,
                                Name = "Label",
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Text = "Button",
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextSize = 14,
                                Rotation = 0,
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                LayoutOrder = 0,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                TextScaled = false,
                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            },
                            Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                            Children = {},
                        },
                    },
                },
            },
        },
        Slider = {
            Class = "TextButton",
            Properties = {
                LayoutOrder = 0,
                Active = false,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Slider",
                Visible = true,
                Size = UDim2.new(1, 0, 0, 33),
                AnchorPoint = Vector2.new(0, 0),
                Rotation = 0,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Text = "",
                AutoButtonColor = false,
            },
            Tokens = {},
            Children = {
                {
                    Class = "TextLabel",
                    Properties = {
                        Visible = true,
                        Active = false,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextTruncate = Enum.TextTruncate.None,
                        TextWrapped = false,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        Size = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        RichText = false,
                        Name = "Label",
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "sliderrrhjashbgsahgb",
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 14,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                    Children = {},
                },
                {
                    Class = "TextButton",
                    Properties = {
                        Visible = true,
                        Active = true,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 1),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "RealSliderOutline",
                        TextTruncate = Enum.TextTruncate.None,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        Size = UDim2.new(1, 0, 0, 10),
                        TextWrapped = false,
                        RichText = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "",
                        TextSize = 14,
                        AutoButtonColor = false,
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 1, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                    },
                    Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Border" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 5) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 1),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 1),
                                PaddingLeft = UDim.new(0, 1),
                                PaddingRight = UDim.new(0, 1),
                            },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "TextButton",
                            Properties = {
                                Visible = true,
                                Active = true,
                                TextTransparency = 0,
                                TextStrokeTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "RealSlider",
                                TextTruncate = Enum.TextTruncate.None,
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                Size = UDim2.new(1, 0, 1, 0),
                                TextWrapped = false,
                                RichText = false,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Text = "",
                                TextSize = 14,
                                AutoButtonColor = false,
                                Rotation = 0,
                                TextColor3 = Color3.fromRGB(0, 0, 0),
                                BackgroundTransparency = 0,
                                Position = UDim2.new(0, 0, 0, 0),
                                LayoutOrder = 0,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                TextScaled = false,
                            },
                            Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Raised" },
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 5) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 90,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
                                        }),
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "Accent",
                                        Visible = true,
                                        Size = UDim2.new(0.4, 0, 1, 0),
                                        AnchorPoint = Vector2.new(0, 0),
                                        Rotation = 0,
                                        BackgroundTransparency = 0,
                                        Position = UDim2.new(0, 0, 0, 0),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 5) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "UIGradient",
                                            Properties = {
                                                Rotation = 90,
                                                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0, 0),
                                                    NumberSequenceKeypoint.new(1, 0, 0),
                                                }),
                                                Name = "UIGradient",
                                                Enabled = true,
                                                Offset = Vector2.new(0, 0),
                                            },
                                            Tokens = {
                                                Color = function(T)
                                                    return ColorSequence.new(
                                                        T.Accent,
                                                        T.Accent:Lerp(Color3.new(), 0.32)
                                                    )
                                                end,
                                            },
                                            Children = {},
                                        },
                                    },
                                },
                                {
                                    Class = "Frame",
                                    Properties = {
                                        LayoutOrder = 0,
                                        Active = false,
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Name = "DraggerOutline",
                                        Visible = true,
                                        Size = UDim2.new(0, 14, 0, 14),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Rotation = 0,
                                        BackgroundTransparency = 0.8,
                                        Position = UDim2.new(0.4, 0, 0.5, 0),
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.None,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = {},
                                    Children = {
                                        {
                                            Class = "UIPadding",
                                            Properties = {
                                                PaddingTop = UDim.new(0, 1),
                                                Name = "UIPadding",
                                                PaddingBottom = UDim.new(0, 1),
                                                PaddingLeft = UDim.new(0, 1),
                                                PaddingRight = UDim.new(0, 1),
                                            },
                                            Tokens = {},
                                            Children = {},
                                        },
                                        {
                                            Class = "Frame",
                                            Properties = {
                                                LayoutOrder = 0,
                                                Active = false,
                                                ClipsDescendants = false,
                                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                                Name = "Dragger",
                                                Visible = true,
                                                Size = UDim2.new(1, 0, 1, 0),
                                                AnchorPoint = Vector2.new(0, 0),
                                                Rotation = 0,
                                                BackgroundTransparency = 0,
                                                Position = UDim2.new(0, 0, 0, 0),
                                                BorderSizePixel = 0,
                                                ZIndex = 1,
                                                AutomaticSize = Enum.AutomaticSize.None,
                                                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                            },
                                            Tokens = {},
                                            Children = {
                                                {
                                                    Class = "UIGradient",
                                                    Properties = {
                                                        Rotation = 90,
                                                        Transparency = NumberSequence.new({
                                                            NumberSequenceKeypoint.new(0, 0, 0),
                                                            NumberSequenceKeypoint.new(1, 0, 0),
                                                        }),
                                                        Name = "UIGradient",
                                                        Color = ColorSequence.new({
                                                            ColorSequenceKeypoint.new(
                                                                0,
                                                                Color3.fromRGB(255, 255, 255)
                                                            ),
                                                            ColorSequenceKeypoint.new(
                                                                1,
                                                                Color3.fromRGB(200, 200, 200)
                                                            ),
                                                        }),
                                                        Enabled = true,
                                                        Offset = Vector2.new(0, 0),
                                                    },
                                                    Tokens = {},
                                                    Children = {},
                                                },
                                                {
                                                    Class = "UICorner",
                                                    Properties = {
                                                        Name = "UICorner",
                                                        CornerRadius = UDim.new(1, 0),
                                                    },
                                                    Tokens = {},
                                                    Children = {},
                                                },
                                            },
                                        },
                                        {
                                            Class = "UICorner",
                                            Properties = { Name = "UICorner", CornerRadius = UDim.new(1, 0) },
                                            Tokens = {},
                                            Children = {},
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                {
                    Class = "TextLabel",
                    Properties = {
                        Visible = true,
                        Active = false,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextTruncate = Enum.TextTruncate.None,
                        TextWrapped = false,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        Size = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        RichText = false,
                        Name = "Value",
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "40%",
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextSize = 14,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "InactiveTab" },
                    Children = {},
                },
            },
        },
        Dropdown = {
            Class = "TextButton",
            Properties = {
                LayoutOrder = 0,
                Active = false,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Dropdown",
                Visible = true,
                Size = UDim2.new(1, 0, 0, 47),
                AnchorPoint = Vector2.new(0, 0),
                Rotation = 0,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Text = "",
                AutoButtonColor = false,
            },
            Tokens = {},
            Children = {
                {
                    Class = "TextLabel",
                    Properties = {
                        Visible = true,
                        Active = false,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        TextTruncate = Enum.TextTruncate.None,
                        TextWrapped = false,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.XY,
                        Size = UDim2.new(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        RichText = false,
                        Name = "Label",
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "Hitpart",
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 14,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    },
                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                    Children = {},
                },
                {
                    Class = "TextButton",
                    Properties = {
                        Visible = true,
                        Active = true,
                        TextTransparency = 0,
                        TextStrokeTransparency = 1,
                        AnchorPoint = Vector2.new(0, 1),
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "RealDropdownOutline",
                        TextTruncate = Enum.TextTruncate.None,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                        Size = UDim2.new(1, 0, 0, 26),
                        TextWrapped = false,
                        RichText = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Text = "",
                        TextSize = 14,
                        AutoButtonColor = false,
                        Rotation = 0,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, 0, 1, 0),
                        LayoutOrder = 0,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = false,
                    },
                    Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Border" },
                    Children = {
                        {
                            Class = "UICorner",
                            Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 5) },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "UIPadding",
                            Properties = {
                                PaddingTop = UDim.new(0, 1),
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0, 1),
                                PaddingLeft = UDim.new(0, 1),
                                PaddingRight = UDim.new(0, 1),
                            },
                            Tokens = {},
                            Children = {},
                        },
                        {
                            Class = "TextButton",
                            Properties = {
                                Visible = true,
                                Active = true,
                                TextTransparency = 0,
                                TextStrokeTransparency = 1,
                                AnchorPoint = Vector2.new(0, 0),
                                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                Name = "RealDropdown",
                                TextTruncate = Enum.TextTruncate.None,
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                AutomaticSize = Enum.AutomaticSize.None,
                                Size = UDim2.new(1, 0, 1, 0),
                                TextWrapped = false,
                                RichText = false,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ClipsDescendants = false,
                                BorderColor3 = Color3.fromRGB(0, 0, 0),
                                Text = "",
                                TextSize = 14,
                                AutoButtonColor = false,
                                Rotation = 0,
                                TextColor3 = Color3.fromRGB(0, 0, 0),
                                BackgroundTransparency = 0,
                                Position = UDim2.new(0, 0, 0, 0),
                                LayoutOrder = 0,
                                TextYAlignment = Enum.TextYAlignment.Center,
                                TextScaled = false,
                            },
                            Tokens = { FontFace = "FontFaceBold", BackgroundColor3 = "Raised" },
                            Children = {
                                {
                                    Class = "UICorner",
                                    Properties = { Name = "UICorner", CornerRadius = UDim.new(0, 5) },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "UIGradient",
                                    Properties = {
                                        Rotation = 90,
                                        Transparency = NumberSequence.new({
                                            NumberSequenceKeypoint.new(0, 0, 0),
                                            NumberSequenceKeypoint.new(1, 0, 0),
                                        }),
                                        Name = "UIGradient",
                                        Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
                                        }),
                                        Enabled = true,
                                        Offset = Vector2.new(0, 0),
                                    },
                                    Tokens = {},
                                    Children = {},
                                },
                                {
                                    Class = "TextLabel",
                                    Properties = {
                                        Visible = true,
                                        Active = false,
                                        TextTransparency = 0,
                                        TextStrokeTransparency = 1,
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                                        TextTruncate = Enum.TextTruncate.None,
                                        TextWrapped = false,
                                        ZIndex = 1,
                                        AutomaticSize = Enum.AutomaticSize.XY,
                                        Size = UDim2.new(0, 0, 0, 0),
                                        BorderSizePixel = 0,
                                        RichText = false,
                                        Name = "Value",
                                        ClipsDescendants = false,
                                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                                        Text = "Hitpart",
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextSize = 14,
                                        Rotation = 0,
                                        BackgroundTransparency = 1,
                                        Position = UDim2.new(0, 8, 0.5, 0),
                                        LayoutOrder = 0,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        TextScaled = false,
                                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    },
                                    Tokens = { FontFace = "FontFaceBold", TextColor3 = "Text" },
                                    Children = {},
                                },
                            },
                        },
                    },
                },
            },
        },
        Separator = {
            Class = "Frame",
            Properties = {
                LayoutOrder = 0,
                Active = false,
                ClipsDescendants = false,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Seperator",
                Visible = true,
                Size = UDim2.new(1, 0, 0, 1),
                AnchorPoint = Vector2.new(0, 0),
                Rotation = 0,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            },
            Tokens = {},
            Children = {
                {
                    Class = "Frame",
                    Properties = {
                        LayoutOrder = 0,
                        Active = false,
                        ClipsDescendants = false,
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "_",
                        Visible = true,
                        Size = UDim2.new(1, 12, 0, 1),
                        AnchorPoint = Vector2.new(0, 0),
                        Rotation = 0,
                        BackgroundTransparency = 0,
                        Position = UDim2.new(0, -6, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        AutomaticSize = Enum.AutomaticSize.None,
                    },
                    Tokens = { BackgroundColor3 = "Border" },
                    Children = {},
                },
            },
        },
    }
    local function Build(Node, Context, Parent, Scope)
        local Properties = table.clone(Node.Properties)
        Properties.Parent = Parent
        local Tokens = table.clone(Node.Tokens)
        if Node.Class == "UIStroke" and Properties.Color == Color3.fromRGB(37, 40, 44) then
            Tokens.Color = "Border"
        end
        if Node.Class == "UIGradient" and Properties.Color and not Tokens.Color then
            local Points = Properties.Color.Keypoints
            local Last = Points[#Points].Value
            if Last.R == Last.G and Last.G == Last.B and Last.R < 0.9 and Last.R > 0.7 then
                Tokens.Color = function(T)
                    return ColorSequence.new(Color3.new(1, 1, 1), T.DarkGradient)
                end
            end
        end
        if
            (Node.Class == "ImageLabel" or Node.Class == "ImageButton")
            and Properties.ImageColor3 == Color3.new(1, 1, 1)
        then
            Tokens.ImageColor3 = "Image"
        end
        local Object = Context:Create(Node.Class, Properties, Tokens, Scope)
        for _, Child in Node.Children do
            Build(Child, Context, Object, Scope)
        end
        return Object
    end
    function Templates.Create(Name, Context, Parent, Scope)
        assert(Shapes[Name], "Unknown visual template: " .. Name)
        return Build(Shapes[Name], Context, Parent, Scope or Context.Scope)
    end
    function Templates.Has(Name)
        return Shapes[Name] ~= nil
    end
    return Templates
end)()

-- Overlay/Manager
local PopupManager = (function()
    local MeasureText = RenderContext.MeasureText
    local UserInputService = game:GetService("UserInputService")
    local Icons = Icons
    local Templates = VisualTemplates
    local Motion = Animation
    local Signal = Signal

    local Manager = {}
    Manager.__index = Manager
    local PopupIn = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local PopupOut = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local Placements = {
        Reference = true,
        TopLeft = true,
        TopRight = true,
        BottomLeft = true,
        BottomRight = true,
        TopCenter = true,
        BottomCenter = true,
    }

    local function Dimensions(Size)
        if typeof(Size) == "Vector2" then
            return UDim2.fromOffset(Size.X, Size.Y)
        end
        assert(typeof(Size) == "UDim2", "Popup size must be Vector2 or UDim2")
        return Size
    end

    local function Contains(Frame, Point)
        local Origin, Extent = Frame.AbsolutePosition, Frame.AbsoluteSize
        return Frame.Visible
            and Point.X >= Origin.X
            and Point.X <= Origin.X + Extent.X
            and Point.Y >= Origin.Y
            and Point.Y <= Origin.Y + Extent.Y
    end

    function Manager.New(Window)
        local self = setmetatable({
            Window = Window,
            Context = Window.Context,
            Scope = Window.Scope,
            Notices = {},
            Stack = {},
            TooltipEpoch = 0,
            Placement = "BottomCenter",
            MaxVisible = 6,
            ClosingNotices = 0,
            ReflowUntil = 0,
        }, Manager)
        local Context = self.Context
        local Retiring, RetirementId = {}, 0
        self.PopupRetirement = Context:Create("BindableEvent", { Name = "PopupRetirement" })
        self.Scope:Connect(self.PopupRetirement.Event, function(Id)
            local Popup = Retiring[Id]
            if not Popup then
                return
            end
            Popup.Scope:Delay(0.19, function()
                Retiring[Id] = nil
                Popup.Scope:Destroy()
            end)
        end)
        self.RetirePopup = function(Popup)
            RetirementId += 1
            local Id = RetirementId
            Retiring[Id] = Popup
            Popup.Scope:Add(function()
                Retiring[Id] = nil
            end)
            self.PopupRetirement:Fire(Id)
        end
        self.Layer = Context:Create("Frame", {
            Name = "Overlays",
            Parent = Window.Scene,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 100,
        })
        self.NoticeLayer = Context:Create("Frame", {
            Name = "Notifications",
            Parent = Window.Scene,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 400,
        })
        self.Notifications = { Changed = self.Scope:Add(Signal.New()) }
        function self.Notifications:Subscribe(Callback, Scope)
            return self.Changed:Subscribe(Callback, Scope)
        end
        function self.Notifications:SetPosition(Value)
            self.Manager:SetNotificationPosition(Value)
            return self
        end
        function self.Notifications:GetPosition()
            return self.Manager:GetNotificationPosition()
        end
        function self.Notifications:GetMaxVisible()
            return self.Manager.MaxVisible
        end
        function self.Notifications:SetMaxVisible(Value)
            assert(
                type(Value) == "number" and Value == Value and math.abs(Value) < math.huge,
                "Notification cap must be finite"
            )
            local Previous = self.Manager.MaxVisible
            self.Manager.MaxVisible = math.clamp(math.floor(Value), 1, 12)
            self.Manager:Arrange()
            if Previous ~= self.Manager.MaxVisible then
                self.Changed:Fire(self, "MaxVisible")
            end
            return self
        end
        function self.Notifications:Notify(Options)
            return self.Manager:Notify(Options)
        end
        function self.Notifications:Clear()
            for _, Notice in table.clone(self.Manager.Notices) do
                Notice.Close()
            end
        end
        self.Notifications.Manager = self
        local State = {}
        function State:Get()
            local Value = self.Manager.Placement
            return {
                Position = if typeof(Value) == "Vector2" then { X = Value.X, Y = Value.Y } else Value,
                MaxVisible = self.Manager.MaxVisible,
            }
        end
        function State:Validate(Value)
            if
                type(Value) ~= "table"
                or type(Value.MaxVisible) ~= "number"
                or Value.MaxVisible % 1 ~= 0
                or Value.MaxVisible < 1
                or Value.MaxVisible > 12
            then
                return false, "Invalid notification state"
            end
            local Position = Value.Position
            if type(Position) == "string" then
                return Placements[Position] == true, "Unknown notification placement"
            end
            return type(Position) == "table"
                and type(Position.X) == "number"
                and type(Position.Y) == "number"
                and Position.X == Position.X
                and Position.Y == Position.Y
                and math.abs(Position.X) < math.huge
                and math.abs(Position.Y) < math.huge,
                "Invalid notification position"
        end
        function State:Set(Value)
            local Valid, Reason = self:Validate(Value)
            assert(Valid, Reason)
            self.Manager.Notifications:SetMaxVisible(Value.MaxVisible)
            self.Manager:SetNotificationPosition(
                if type(Value.Position) == "table"
                    then Vector2.new(Value.Position.X, Value.Position.Y)
                    else Value.Position
            )
        end
        State.Manager = self
        if Window.Library.Config.RegisterState then
            Window.Library.Config:RegisterState(
                "@Notifications:" .. tostring(Window.ConfigId or "Main"),
                State,
                self.Scope
            )
        end
        self.Scope:Connect(Window.Screen:GetPropertyChangedSignal("AbsoluteSize"), function()
            self:Arrange()
        end)
        self.Scope:Connect(self.NoticeLayer:GetPropertyChangedSignal("AbsoluteSize"), function()
            self:Arrange()
        end)
        self.Scope:Connect(UserInputService.InputBegan, function(Input)
            if not self.Active then
                return
            end
            if
                Input.KeyCode == Enum.KeyCode.Escape
                and UserInputService:GetFocusedTextBox()
                and not Window.Library.Input.Capturing
            then
                self:CloseTop()
            elseif
                Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.MouseButton2
                or Input.UserInputType == Enum.UserInputType.Touch
            then
                self:HandlePointer(Vector2.new(Input.Position.X, Input.Position.Y))
            end
        end)
        self.Scope:Add(function()
            table.clear(self.Notices)
            table.clear(self.Stack)
        end)
        return self
    end
    Manager.new = Manager.New

    function Manager:GetBounds(Layer)
        local Scale = math.max(0.001, self.Window:GetScale())
        return Layer.AbsoluteSize / Scale, Scale
    end

    function Manager:GetViewport()
        local Scale = math.max(0.001, self.Window:GetScale())
        local Origin = (self.Window.Screen.AbsolutePosition - self.Layer.AbsolutePosition) / Scale
        return Origin, self.Window.Screen.AbsoluteSize / Scale, Scale
    end

    function Manager:RefreshActive()
        self.Active = self.Stack[#self.Stack]
        self.ActiveDropdown, self.ActiveColorPicker, self.ActiveSettings, self.ActiveContextMenu, self.ActiveKeybindEditor =
            nil, nil, nil, nil, nil
        local Fields = {
            Dropdown = "ActiveDropdown",
            Color = "ActiveColorPicker",
            ColorPicker = "ActiveColorPicker",
            Settings = "ActiveSettings",
            Context = "ActiveContextMenu",
            KeybindEditor = "ActiveKeybindEditor",
        }
        for _, Popup in self.Stack do
            if Fields[Popup.Kind] then
                self[Fields[Popup.Kind]] = Popup
            end
        end
    end

    function Manager:HideTooltip()
        self.TooltipEpoch += 1
        if self.TooltipScope then
            self.TooltipScope:Destroy()
            self.TooltipScope = nil
        end
        self.TooltipTarget, self.TooltipFrame, self.ActiveTooltip = nil, nil, nil
    end

    function Manager:Close()
        self:HideTooltip()
        for Index = #self.Stack, 1, -1 do
            local Popup = self.Stack[Index]
            if Popup then
                Popup.Close()
            end
        end
    end

    function Manager:CloseTop()
        self:HideTooltip()
        if self.Active then
            self.Active.Close()
        end
    end

    function Manager:HandlePointer(Point)
        if self.Active and not self.Active.InputReady then
            return
        end
        local Hit
        for Index = #self.Stack, 1, -1 do
            local Popup = self.Stack[Index]
            if not Popup.Closing and Contains(Popup.Frame, Point) then
                Hit = Popup
                break
            end
        end
        if Hit then
            for _, Child in table.clone(Hit.Children) do
                Child.Close()
            end
        else
            self:Close()
        end
    end

    function Manager:OpenPopup(Anchor, Point, Size, Builder, Owner, Options)
        self:HideTooltip()
        Size, Options = Dimensions(Size), Options or {}
        local Parent = Options.Parent
        if Parent and (Parent.Closing or not Parent.Scope.Alive) then
            Parent = nil
        end
        if not Parent and Anchor then
            for Index = #self.Stack, 1, -1 do
                if Anchor:IsDescendantOf(self.Stack[Index].Frame) then
                    Parent = self.Stack[Index]
                    break
                end
            end
        end
        if Parent then
            for _, Child in table.clone(Parent.Children) do
                Child.Close()
            end
        else
            self:Close()
        end
        local Context, Scope = self.Context, (Owner or self.Scope):Child()
        local Frame = Context:Create("CanvasGroup", {
            Name = Options.Kind or "Popup",
            Parent = self.Layer,
            Size = Size,
            GroupTransparency = 1,
            ClipsDescendants = true,
            Active = true,
            ZIndex = 4 + #self.Stack * 4,
        }, { BackgroundColor3 = "Popup", BackgroundTransparency = "SurfaceTransparency" }, Scope)
        Context:Corner(Frame, 3)
        Context:Stroke(Frame, "Border", Scope)
        Context:Shadow(Frame, { Spread = 14, Strength = 0.35, Radius = 3, Offset = Vector2.new(0, 2) }, Scope)
        local Popup = {
            Frame = Frame,
            Scope = Scope,
            Parent = Parent,
            Children = {},
            Kind = Options.Kind or "Popup",
            Closing = false,
            Closed = false,
            InputReady = false,
            ClosedCallbacks = {},
        }
        if Options.OnClosed then
            table.insert(Popup.ClosedCallbacks, Options.OnClosed)
        end
        if Parent then
            table.insert(Parent.Children, Popup)
        end
        table.insert(self.Stack, Popup)
        self:RefreshActive()
        local FullSize = Size
        local Slide = Options.Kind == "KeybindEditor"
            or Options.Kind == "Settings"
            or Options.Kind == "Search"
        local SlideInfo = TweenInfo.new(0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
        local function Remove()
            local Index = table.find(self.Stack, Popup)
            if Index then
                table.remove(self.Stack, Index)
            end
            if Parent then
                local ChildIndex = table.find(Parent.Children, Popup)
                if ChildIndex then
                    table.remove(Parent.Children, ChildIndex)
                end
            end
            self:RefreshActive()
        end
        local function Finalize()
            if Popup.Closed then
                return
            end
            Popup.Closed = true
            for _, Child in table.clone(Popup.Children) do
                Child.Scope:Destroy()
            end
            if not Popup.Closing then
                Popup.Closing = true
                Context:Callback(Options.OnClose, Popup)
            end
            Remove()
            for _, Callback in Popup.ClosedCallbacks do
                Context:Callback(Callback, Popup)
            end
            table.clear(Popup.ClosedCallbacks)
        end
        Popup.Close = function()
            if Popup.Closing or not Scope.Alive then
                return
            end
            self:HideTooltip()
            Popup.Closing = true
            for _, Child in table.clone(Popup.Children) do
                Child.Close()
            end
            Remove()
            Context:Callback(Options.OnClose, Popup)
            local Focused = UserInputService:GetFocusedTextBox()
            if Focused and Focused:IsDescendantOf(Frame) then
                Focused:ReleaseFocus()
            end
            Frame.Active = false
            Frame.Interactable = false
            if Slide then
                Context:Tween(
                    Frame,
                    SlideInfo,
                    { GroupTransparency = 1, Position = Frame.Position - UDim2.fromOffset(0, 5) },
                    Scope
                )
            else
                Context:Tween(
                    Frame,
                    PopupOut,
                    { GroupTransparency = 1, Size = FullSize
                        - UDim2.fromOffset(0, math.min(8, FullSize.Y.Offset * 0.1)) },
                    Scope
                )
            end
            self.RetirePopup(Popup)
        end
        function Popup:OnClosed(Callback)
            assert(type(Callback) == "function", "OnClosed expects a callback")
            if self.Closed then
                Context:Callback(Callback, self)
            else
                table.insert(self.ClosedCallbacks, Callback)
            end
            return self
        end
        local function Position()
            if not Scope.Alive or Popup.Closing then
                return
            end
            local ViewOrigin, View, Scale = self:GetViewport()
            local Width = math.min(Size.X.Scale * View.X + Size.X.Offset, math.max(1, View.X - 16))
            local Height = math.min(Size.Y.Scale * View.Y + Size.Y.Offset, math.max(1, View.Y - 16))
            FullSize = UDim2.fromOffset(Width, Height)
            local Horizontal, Vertical =
                Point and Point.X or ViewOrigin.X + 8, Point and Point.Y or ViewOrigin.Y + 8
            if Anchor then
                local Origin = (Anchor.AbsolutePosition - self.Layer.AbsolutePosition) / Scale
                local Extent = Anchor.AbsoluteSize / Scale
                if Options.Placement == "Side" then
                    Horizontal, Vertical = Origin.X + Extent.X + 7, Origin.Y
                    if Horizontal + Width > ViewOrigin.X + View.X - 8 then
                        Horizontal = Origin.X - Width - 7
                    end
                else
                    Horizontal, Vertical = Origin.X, Origin.Y + Extent.Y + 5
                    if Vertical + Height > ViewOrigin.Y + View.Y - 8 then
                        Vertical = Origin.Y - Height - 5
                    end
                end
            end
            Frame.Position = UDim2.fromOffset(
                math.clamp(
                    Horizontal,
                    ViewOrigin.X + 8,
                    math.max(ViewOrigin.X + 8, ViewOrigin.X + View.X - Width - 8)
                ),
                math.clamp(
                    Vertical,
                    ViewOrigin.Y + 8,
                    math.max(ViewOrigin.Y + 8, ViewOrigin.Y + View.Y - Height - 8)
                )
            )
            Motion.Cancel(Frame, "Size")
            Frame.Size = FullSize
        end
        function Popup:Resize(Value)
            Size = Dimensions(Value)
            Position()
            return self
        end
        Popup.Reposition = Position
        Position()
        if Anchor then
            Scope:Connect(Anchor:GetPropertyChangedSignal("AbsolutePosition"), Position)
            Scope:Connect(Anchor:GetPropertyChangedSignal("AbsoluteSize"), Position)
            Scope:Connect(Anchor.Destroying, Popup.Close)
            local Ancestor = Anchor
            while Ancestor and Ancestor ~= self.Window.Gui do
                if Ancestor:IsA("GuiObject") then
                    local Tracked = Ancestor
                    Scope:Connect(Tracked:GetPropertyChangedSignal("Visible"), function()
                        if not Tracked.Visible then
                            Popup.Close()
                        end
                    end)
                end
                if Ancestor:IsA("ScrollingFrame") then
                    Scope:Connect(Ancestor:GetPropertyChangedSignal("CanvasPosition"), Popup.Close)
                end
                Ancestor = Ancestor.Parent
            end
        end
        Scope:Connect(self.Layer:GetPropertyChangedSignal("AbsoluteSize"), Position)
        Scope:Connect(self.Layer:GetPropertyChangedSignal("AbsolutePosition"), Position)
        Scope:Connect(self.Window.Screen:GetPropertyChangedSignal("AbsoluteSize"), Position)
        local Success, Reason = pcall(Builder, Frame, Scope, Popup.Close, Popup)
        Scope:Add(Finalize)
        if not Success then
            Scope:Destroy()
            error(Reason, 2)
        end
        Scope:Delay(0, function()
            Popup.InputReady = true
        end)
        if Slide then
            local Destination = Frame.Position
            Frame.Position = Destination - UDim2.fromOffset(0, 5)
            Context:Tween(Frame, SlideInfo, { GroupTransparency = 0, Position = Destination }, Scope)
        else
            Frame.Size = FullSize - UDim2.fromOffset(0, math.min(8, FullSize.Y.Offset * 0.1))
            Context:Tween(Frame, PopupIn, { GroupTransparency = 0, Size = FullSize }, Scope)
        end
        return Popup
    end

    function Manager:Open(Anchor, Size, Builder, Owner, Options)
        assert(typeof(Anchor) == "Instance" and Anchor:IsA("GuiObject"), "Popup anchor must be a GuiObject")
        return self:OpenPopup(Anchor, nil, Size, Builder, Owner, Options)
    end

    function Manager:OpenAt(Position, Size, Builder, Owner, Options)
        assert(typeof(Position) == "Vector2", "Popup position must be Vector2 in scene coordinates")
        return self:OpenPopup(nil, Position, Size, Builder, Owner, Options)
    end

    function Manager:Tooltip(Target, Text, Owner)
        local function Hide()
            if self.TooltipTarget == Target and self.TooltipScope then
                local Scope, Tip = self.TooltipScope, self.TooltipFrame
                self.TooltipScope, self.TooltipTarget, self.TooltipFrame, self.ActiveTooltip =
                    nil, nil, nil, nil
                if Scope.Alive then
                    self.Context:Tween(Tip, "Hover", {
                        GroupTransparency = 1,
                        Position = Tip.Position + UDim2.fromOffset(0, 2),
                    }, Scope)
                    Scope:Delay(0.13, function()
                        Scope:Destroy()
                    end)
                end
            end
        end
        Owner:Connect(Target.MouseEnter, function()
            if
                (self.Active and not Target:IsDescendantOf(self.Active.Frame))
                or self.Dialog
                or not Target.Visible
                or not self.Window.IsOpen
            then
                return
            end
            if self.TooltipScope then
                self.TooltipScope:Destroy()
            end
            local Context, Scope = self.Context, Owner:Child()
            self.TooltipScope, self.TooltipTarget = Scope, Target
            local Tip = Context:Create(
                "CanvasGroup",
                {
                    Name = "Tooltip",
                    Parent = self.Layer,
                    ZIndex = 300,
                    GroupTransparency = 1,
                    Visible = false,
                },
                { BackgroundColor3 = "Popup", BackgroundTransparency = "SurfaceTransparency" },
                Scope
            )
            self.TooltipFrame, self.ActiveTooltip = Tip, Tip
            Scope:Add(function()
                if self.TooltipScope == Scope then
                    self.TooltipScope, self.TooltipTarget, self.TooltipFrame, self.ActiveTooltip =
                        nil, nil, nil, nil
                end
            end)
            Context:Corner(Tip, 3)
            Context:Shadow(Tip, { Spread = 6, Strength = 0.14, Radius = 3 }, Scope)
            local Label = Context:Text(Tip, Text, {
                Position = UDim2.fromOffset(7, 4),
                Size = UDim2.new(1, -14, 1, -8),
                TextWrapped = true,
                TextSize = 12,
            }, Scope)
            local function Layout()
                local ViewOrigin, View, Scale = self:GetViewport()
                local Natural = MeasureText(Text, Label, 2000)
                local Width =
                    math.clamp(math.ceil(Natural.X) + 14, 24, math.max(24, math.min(250, View.X - 16)))
                local Bounds = MeasureText(Text, Label, Width - 14)
                if not Scope.Alive or self.TooltipScope ~= Scope then
                    return
                end
                local Height = math.max(20, math.ceil(Bounds.Y) + 8)
                local Origin = (Target.AbsolutePosition - self.Layer.AbsolutePosition) / Scale
                local Horizontal, Vertical = Origin.X + 6, Origin.Y + Target.AbsoluteSize.Y / Scale + 6
                if Vertical + Height > ViewOrigin.Y + View.Y - 8 then
                    Vertical = Origin.Y - Height - 6
                end
                Tip.Size = UDim2.fromOffset(Width, Height)
                Tip.Position = UDim2.fromOffset(
                    math.clamp(
                        Horizontal,
                        ViewOrigin.X + 8,
                        math.max(ViewOrigin.X + 8, ViewOrigin.X + View.X - Width - 8)
                    ),
                    math.clamp(
                        Vertical,
                        ViewOrigin.Y + 8,
                        math.max(ViewOrigin.Y + 8, ViewOrigin.Y + View.Y - Height - 8)
                    )
                )
            end
            Layout()
            if not Scope.Alive or self.TooltipScope ~= Scope then
                return
            end
            Tip.Visible = true
            Scope:Connect(Label:GetPropertyChangedSignal("FontFace"), Layout)
            Scope:Connect(Target:GetPropertyChangedSignal("AbsolutePosition"), Layout)
            Scope:Connect(Target:GetPropertyChangedSignal("AbsoluteSize"), Layout)
            Scope:Connect(self.Layer:GetPropertyChangedSignal("AbsoluteSize"), Layout)
            local Destination = Tip.Position
            Tip.Position += UDim2.fromOffset(0, 2)
            Context:Tween(Tip, PopupIn, { GroupTransparency = 0, Position = Destination }, Scope)
        end)
        Owner:Connect(Target.MouseLeave, Hide)
        Owner:Connect(Target.InputBegan, function(Input)
            local Kind = Input.UserInputType
            if
                Kind == Enum.UserInputType.MouseButton1
                or Kind == Enum.UserInputType.MouseButton2
                or Kind == Enum.UserInputType.MouseButton3
                or Kind == Enum.UserInputType.Touch
                or Kind == Enum.UserInputType.Keyboard
            then
                Hide()
            end
        end)
        Owner:Add(Hide)
    end

    function Manager:Confirm(Options)
        Options = Options or {}
        self:Close()
        if self.Dialog then
            self.Dialog.Cancel()
        end
        local Context, Scope = self.Context, self.Scope:Child()
        local Shield = Context:Create("TextButton", {
            Name = "DialogShield",
            Parent = self.Layer,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            BackgroundTransparency = 1,
            ZIndex = 200,
        }, { BackgroundColor3 = "Black" }, Scope)
        local Panel = Context:Create("CanvasGroup", {
            Name = "Confirmation",
            Parent = Shield,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(320, 142),
            GroupTransparency = 1,
            ZIndex = 4,
        }, { BackgroundColor3 = "Surface", BackgroundTransparency = "SurfaceTransparency" }, Scope)
        Context:Corner(Panel, 8)
        Context:Stroke(Panel, "Border", Scope)
        Context:Shadow(Panel, { Spread = 16, Strength = 0.22, Radius = 8 }, Scope)
        local Title = Context:Text(Panel, Options.Title or "Confirm action", {
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.new(1, -24, 0, 18),
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, Scope)
        Context:Bind(Title, "Font", "FontBold", Scope)
        Context:Bind(Title, "TextColor3", "Text", Scope)
        Title.TextSize = 14
        local Description = Context:Text(Panel, Options.Description or "Continue with this action?", {
            Position = UDim2.fromOffset(12, 43),
            Size = UDim2.new(1, -24, 1, -91),
            TextSize = 12,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, Scope)
        Context:Bind(Description, "TextColor3", "SubText", Scope)
        Context:Create("Frame", {
            Name = "Separator",
            Parent = Panel,
            Position = UDim2.fromOffset(0, 35),
            Size = UDim2.new(1, 0, 0, 1),
        }, { BackgroundColor3 = "Border" }, Scope)
        local function Button(Name, Text, Horizontal, Tone)
            local Holder = Templates.Create("Button", Context, Panel, Scope)
            Holder.Name = Name
            Holder.AnchorPoint = Vector2.new(0, 1)
            Holder.Position = UDim2.new(0, Horizontal, 1, -12)
            Holder.Size = UDim2.fromOffset(144, 26)
            local Object = Holder.RealButton
            Object.Label.Text = Text
            Context:Hover(Object, Scope, "Raised", "Hover")
            return Object
        end
        local Cancel = Button("Cancel", Options.CancelText or "Cancel", 12, "Text")
        local Confirm = Button("Confirm", Options.ConfirmText or "Confirm", 164, "Accent")
        local Center
        local Resolved = false
        local function Layout()
            if Resolved then
                return
            end
            local Bounds = MeasureText(Description.Text, Description, 296)
            if not Scope.Alive or Resolved then
                return
            end
            Panel.Size = UDim2.fromOffset(320, math.max(142, math.min(Bounds.Y, 110) + 96))
            local View, Scale = self:GetBounds(self.Layer)
            local Origin = (self.Window.Root.AbsolutePosition - self.Layer.AbsolutePosition) / Scale
            local Extent = self.Window.Root.AbsoluteSize / Scale
            Center = Vector2.new(
                math.clamp(Origin.X + Extent.X / 2, 168, math.max(168, View.X - 168)),
                math.clamp(
                    Origin.Y + Extent.Y / 2,
                    Panel.Size.Y.Offset / 2 + 8,
                    math.max(Panel.Size.Y.Offset / 2 + 8, View.Y - Panel.Size.Y.Offset / 2 - 8)
                )
            )
            Panel.Position = UDim2.fromOffset(Center.X, Center.Y)
        end
        Layout()
        Scope:Connect(Description:GetPropertyChangedSignal("FontFace"), Layout)
        Scope:Connect(self.Layer:GetPropertyChangedSignal("AbsoluteSize"), Layout)
        Scope:Connect(self.Window.Root:GetPropertyChangedSignal("AbsolutePosition"), Layout)
        local Dialog = {}
        local function Resolve(Value)
            if Resolved or not Scope.Alive then
                return
            end
            Resolved = true
            if self.Dialog == Dialog then
                self.Dialog = nil
            end
            Confirm.Active, Cancel.Active = false, false
            Context:Tween(
                Panel,
                PopupOut,
                { GroupTransparency = 1, Position = Panel.Position + UDim2.fromOffset(0, 4) },
                Scope
            )
            Context:Tween(Shield, PopupOut, { BackgroundTransparency = 1 }, Scope)
            Scope:Delay(0.19, function()
                Scope:Destroy()
            end)
            Context:Callback(Options.Callback, Value)
            if Value then
                Context:Callback(Options.OnConfirm)
            else
                Context:Callback(Options.OnCancel)
            end
        end
        Dialog.Confirm = function()
            Resolve(true)
        end
        Dialog.Cancel = function()
            Resolve(false)
        end
        Dialog.Destroy = Dialog.Cancel
        self.Dialog = Dialog
        Scope:Add(function()
            if self.Dialog == Dialog then
                self.Dialog = nil
            end
        end)
        Scope:Connect(Confirm.Activated, Dialog.Confirm)
        Scope:Connect(Cancel.Activated, Dialog.Cancel)
        Panel.Position += UDim2.fromOffset(0, 4)
        Context:Tween(
            Panel,
            PopupIn,
            { GroupTransparency = 0, Position = UDim2.fromOffset(Center.X, Center.Y) },
            Scope
        )
        Context:Tween(Shield, PopupIn, { BackgroundTransparency = 0.65 }, Scope)
        return Dialog
    end

    function Manager:SetNotificationPosition(Value)
        if type(Value) == "string" then
            assert(Placements[Value], "Unknown notification placement")
        else
            assert(
                typeof(Value) == "Vector2"
                    and Value.X == Value.X
                    and Value.Y == Value.Y
                    and math.abs(Value.X) < math.huge
                    and math.abs(Value.Y) < math.huge,
                "Notification position must be a placement name or Vector2"
            )
        end
        local Previous = self.Placement
        self.Placement = Value
        self:Arrange()
        if Previous ~= Value then
            self.Notifications.Changed:Fire(self.Notifications, "Position")
        end
        return self
    end

    function Manager:GetNotificationPosition()
        return self.Placement
    end

    local ToastFade = TweenInfo.new(0.12, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
    local ToastMove = TweenInfo.new(0.14, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    function Manager:Arrange()
        if not self.Scope.Alive then
            return
        end
        while #self.Notices > self.MaxVisible do
            self.Notices[1].Close()
        end
        local Origin, View = self:GetViewport()
        local Placement = self.Placement
        local Bottom = type(Placement) == "string"
            and (Placement:find("Bottom") ~= nil or Placement == "Reference")
        for Index, Notice in self.Notices do
            local Width = math.min(Notice.Width, View.X - 24)
            local X, Y
            if typeof(Placement) == "Vector2" then
                X, Y = Placement.X, Placement.Y + (Index - 1) * 29
            else
                X = if Placement:find("Right")
                    then View.X - Width - 14
                    elseif Placement:find("Left") then 14
                    else (View.X - Width) / 2
                Y = if Bottom then View.Y * 0.88 - (Index - 1) * 29 else 16 + (Index - 1) * 29
                X += Origin.X
                Y += Origin.Y
            end
            X = math.clamp(X, Origin.X + 8, math.max(Origin.X + 8, Origin.X + View.X - Width - 8))
            Y = math.clamp(Y, Origin.Y + 8, math.max(Origin.Y + 8, Origin.Y + View.Y - 32))
            Notice.Frame.Size = UDim2.fromOffset(Width, 24)
            local Target = UDim2.fromOffset(X, Y)
            if not Notice.Started then
                Notice.Frame.Position = Target
                Notice.Started = true
            end
            self.Context:Tween(Notice.Frame, ToastMove, { Position = Target }, Notice.Scope)
        end
    end
    function Manager:Notify(Options)
        if type(Options) == "string" then
            Options = { Text = Options }
        end
        Options = Options or {}
        local C, Scope = self.Context, self.Scope:Child()
        local Duration = tonumber(Options.Duration) or 2
        assert(
            Duration == Duration and math.abs(Duration) < math.huge,
            "Notification duration must be finite"
        )
        Duration = math.clamp(Duration, 0.5, 120)
        local Tone = ({ Info = "Accent", Success = "Success", Warning = "Warning", Error = "Error" })[Options.Type or "Info"]
            or "Accent"
        local Message = Options.Text or Options.Message
        if not Message then
            Message = tostring(Options.Title or "myhoe")
            if Options.Description and Options.Description ~= "" then
                Message ..= " — " .. tostring(Options.Description)
            end
        end
        Message = tostring(Message)
        local Frame = C:Create("CanvasGroup", {
            Name = "Notification",
            Parent = self.NoticeLayer,
            Size = UDim2.fromOffset(200, 24),
            GroupTransparency = 1,
            BackgroundTransparency = 0.11,
            ZIndex = 4,
        }, { BackgroundColor3 = "Background" }, Scope)
        C:Corner(Frame, 7)
        C:Shadow(Frame, { Spread = 8, Strength = 0.16, Radius = 7, Offset = Vector2.zero }, Scope)
        Icons.Draw(
            C,
            Frame,
            Options.Icon or "Bell",
            { Name = "TypeIcon", Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(12, 12), Thickness = 1.2 },
            function(T)
                return Options.Accent or T.Accent
            end,
            Scope
        )
        local Label = C:Text(
            Frame,
            Message,
            {
                Name = "Message",
                Position = UDim2.fromOffset(26, 0),
                Size = UDim2.new(1, -32, 1, 0),
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
            },
            Scope
        )
        local Bounds = MeasureText(Message, Label, 10000)
        local Width = math.ceil(Bounds.X) + 34
        local Notice =
            { Frame = Frame, Scope = Scope, Width = Width, Height = 24, Duration = Duration, Closing = false }
        Notice.Close = function()
            if Notice.Closing or not Scope.Alive then
                return
            end
            Notice.Closing = true
            local Index = table.find(self.Notices, Notice)
            if Index then
                table.remove(self.Notices, Index)
            end
            C:Tween(Frame, ToastFade, { GroupTransparency = 1 }, Scope)
            Scope:Delay(0.13, function()
                Scope:Destroy()
                self:Arrange()
            end)
        end
        Notice.Destroy, Notice.Dismiss = Notice.Close, Notice.Close
        Scope:Add(function()
            local Index = table.find(self.Notices, Notice)
            if Index then
                table.remove(self.Notices, Index)
            end
        end)
        table.insert(self.Notices, Notice)
        self:Arrange()
        C:Tween(Frame, ToastFade, { GroupTransparency = 0 }, Scope)
        Scope:Delay(Duration, Notice.Close)

        return Notice
    end

    function Manager:UpdateBinds()
        if self.Window.Hud and self.Window.Hud.KeybindList then
            self.Window.Hud.KeybindList:Refresh()
        end
    end

    return Manager
end)()

-- Controls/Color
local ColorPicker = (function()
    local Color = {}

    function Color.Hex(Value, Alpha)
        local Result = string.format(
            "#%02X%02X%02X",
            math.round(Value.R * 255),
            math.round(Value.G * 255),
            math.round(Value.B * 255)
        )
        return Alpha ~= nil and Result .. string.format("%02X", math.round(math.clamp(Alpha, 0, 1) * 255))
            or Result
    end

    function Color.FromHex(Value)
        if type(Value) ~= "string" then
            return nil
        end
        local Clean = Value:gsub("#", ""):gsub("%s", "")
        if #Clean == 3 or #Clean == 4 then
            Clean = Clean:gsub(".", function(Character)
                return Character .. Character
            end)
        end
        if (#Clean ~= 6 and #Clean ~= 8) or not Clean:match("^%x+$") then
            return nil
        end
        local Result = Color3.fromRGB(
            tonumber(Clean:sub(1, 2), 16),
            tonumber(Clean:sub(3, 4), 16),
            tonumber(Clean:sub(5, 6), 16)
        )
        return Result, #Clean == 8 and tonumber(Clean:sub(7, 8), 16) / 255 or nil
    end

    function Color.Open(Context, Anchor, OwnerScope, Initial, OnChange, Options)
        Options = Options or {}
        local Controller = { Updating = false }
        local Hue, Saturation, Brightness = Initial:ToHSV()
        local Current, Alpha = Initial, math.clamp(Options.Alpha or 1, 0, 1)
        local HasAlpha = Options.EnableAlpha ~= false
        local HasHex, HasRGB = Options.ShowHex == true, Options.ShowRGB == true
        local FieldsY = 313
        local PopupHeight = FieldsY + (HasHex and 32 or 0) + (HasRGB and 32 or 0)
        local Update
        Controller.Popup = Context:Popup(Anchor, Vector2.new(219, PopupHeight), function(Frame, Scope)
            Controller.Scope = Scope
            Context:Corner(Frame, 5)
            local Square = Context:Create("Frame", {
                Name = "SaturationValue",
                Parent = Frame,
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.fromOffset(203, 157),
                BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
                Active = true,
            }, nil, Scope)
            Context:Corner(Square, 5)
            Square.ClipsDescendants = true
            local White = Context:Create(
                "Frame",
                { Parent = Square, Size = UDim2.fromScale(1, 1) },
                { BackgroundColor3 = "White" },
                Scope
            )
            Context:Create("UIGradient", {
                Parent = White,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, nil, Scope)
            local Black = Context:Create(
                "Frame",
                { Parent = Square, Size = UDim2.fromScale(1, 1) },
                { BackgroundColor3 = "Black" },
                Scope
            )
            Context:Create("UIGradient", {
                Parent = Black,
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, nil, Scope)
            local Cursor = Context:Create("Frame", {
                Name = "ColorCursor",
                Parent = Square,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(4, 4),
                BackgroundTransparency = 1,
                ZIndex = 3,
            }, nil, Scope)
            Context:Corner(Cursor, 8)
            Context:Stroke(Cursor, "White", Scope)
            local HueRail = Context:Create("Frame", {
                Name = "Hue",
                Parent = Frame,
                Position = UDim2.fromOffset(8, 174),
                Size = UDim2.fromOffset(203, 18),
                Active = true,
            }, { BackgroundColor3 = "White" }, Scope)
            Context:Corner(HueRail, 5)
            local Sequence = {}
            for Index = 0, 6 do
                table.insert(Sequence, ColorSequenceKeypoint.new(Index / 6, Color3.fromHSV(Index / 6, 1, 1)))
            end
            Context:Create(
                "UIGradient",
                { Parent = HueRail, Color = ColorSequence.new(Sequence) },
                nil,
                Scope
            )
            local function CreateCursor(Rail, Name)
                local Knob = Context:Create("Frame", {
                    Name = Name,
                    Parent = Rail,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.fromOffset(3, 10),
                }, { BackgroundColor3 = "White" }, Scope)
                Context:Corner(Knob, 4)
                Context:Stroke(Knob, "Black", Scope)
                return Knob
            end
            local HueCursor = CreateCursor(HueRail, "HueCursor")
            local AlphaRail, AlphaGradient, AlphaCursor
            if HasAlpha then
                AlphaRail = Context:Create("Frame", {
                    Name = "Alpha",
                    Parent = Frame,
                    Position = UDim2.fromOffset(8, 201),
                    Size = UDim2.fromOffset(203, 18),
                    Active = true,
                }, { BackgroundColor3 = "White" }, Scope)
                Context:Corner(AlphaRail, 5)
                AlphaGradient = Context:Create("UIGradient", { Parent = AlphaRail }, nil, Scope)
                AlphaCursor = CreateCursor(AlphaRail, "AlphaCursor")
            end
            if Options.BuildAnimations then
                Options.BuildAnimations(Frame, Scope)
            end
            local function CreateEntry(Name, Position, Width)
                local Entry = Context:Create("TextBox", {
                    Name = Name,
                    Parent = Frame,
                    Position = Position,
                    Size = UDim2.fromOffset(Width, 24),
                    ClearTextOnFocus = false,
                    BackgroundTransparency = 0.3,
                    Text = "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, { BackgroundColor3 = "Surface", TextColor3 = "Text", Font = "Font" }, Scope)
                Context:Create(
                    "UIPadding",
                    { Parent = Entry, PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) },
                    nil,
                    Scope
                )
                Context:Corner(Entry, 3)
                Context:Bind(Entry, "TextSize", function(Theme)
                    return math.max(9, Theme.TextSize - 1)
                end, Scope)
                Context:Stroke(Entry, "Border", Scope).Transparency = 0.55
                return Entry
            end
            local HexEntry
            if HasHex then
                HexEntry = CreateEntry("Hex", UDim2.fromOffset(8, FieldsY), 203)
                FieldsY += 32
            end
            local RGBEntries = {}
            if HasRGB then
                for Index, Name in ipairs({ "R", "G", "B" }) do
                    local Entry = CreateEntry(Name, UDim2.fromOffset(8 + (Index - 1) * 69, FieldsY), 65)
                    Entry.PlaceholderText = Name
                    table.insert(RGBEntries, Entry)
                end
            end
            Update = function(Force)
                Square.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                Cursor.Position = UDim2.fromScale(Saturation, 1 - Brightness)
                HueCursor.Position = UDim2.fromScale(Hue, 0.5)
                if AlphaCursor then
                    AlphaCursor.Position = UDim2.fromScale(Alpha, 0.5)
                    AlphaGradient.Color = ColorSequence.new(Context.Theme.Values.Track, Current)
                end
                if HexEntry and (Force or not HexEntry:IsFocused()) then
                    HexEntry.Text = Color.Hex(Current, HasAlpha and Alpha or nil)
                end
                for Index, Channel in ipairs({ Current.R, Current.G, Current.B }) do
                    local Entry = RGBEntries[Index]
                    if Entry and (Force or not Entry:IsFocused()) then
                        Entry.Text = tostring(math.round(Channel * 255))
                    end
                end
            end
            local function Commit()
                Current = Color3.fromHSV(Hue, Saturation, Brightness)
                Update()
                Controller.Updating = true
                OnChange(Current, Alpha)
                Controller.Updating = false
            end
            for Index = 0, 7 do
                local Preset = if Index == 6
                    then Color3.new(1, 1, 1)
                    elseif Index == 7 then Color3.fromRGB(24, 26, 30)
                    else Color3.fromHSV(Index / 6, 0.8, 1)
                local Button = Context:Create(
                    "TextButton",
                    {
                        Name = "Preset" .. Index,
                        Parent = Frame,
                        Position = UDim2.fromOffset(8 + Index * 26, 227),
                        Size = UDim2.fromOffset(20, 20),
                        Text = "",
                        BackgroundColor3 = Preset,
                    },
                    nil,
                    Scope
                )
                Context:Corner(Button, 4)
                Context:Stroke(Button, "Border", Scope)
                Context:Connect(Button.Activated, function()
                    Hue, Saturation, Brightness = Preset:ToHSV()
                    Commit()
                end, Scope)
            end
            Context.Input:Drag(Scope, Square, function(Position, Phase)
                if Phase == "End" then
                    return
                end
                local Relative = Position - Square.AbsolutePosition
                Saturation = math.clamp(Relative.X / math.max(1, Square.AbsoluteSize.X), 0, 1)
                Brightness = 1 - math.clamp(Relative.Y / math.max(1, Square.AbsoluteSize.Y), 0, 1)
                Commit()
            end)
            Context.Input:Drag(Scope, HueRail, function(Position, Phase)
                if Phase == "End" then
                    return
                end
                Hue = math.clamp(
                    (Position.X - HueRail.AbsolutePosition.X) / math.max(1, HueRail.AbsoluteSize.X),
                    0,
                    1
                )
                Commit()
            end)
            if AlphaRail then
                Context.Input:Drag(Scope, AlphaRail, function(Position, Phase)
                    if Phase == "End" then
                        return
                    end
                    Alpha = math.clamp(
                        (Position.X - AlphaRail.AbsolutePosition.X) / math.max(1, AlphaRail.AbsoluteSize.X),
                        0,
                        1
                    )
                    Commit()
                end)
            end
            if HexEntry then
                Context:Connect(HexEntry.FocusLost, function()
                    local Parsed, ParsedAlpha = Color.FromHex(HexEntry.Text)
                    if Parsed then
                        Hue, Saturation, Brightness = Parsed:ToHSV()
                        if HasAlpha and ParsedAlpha ~= nil then
                            Alpha = ParsedAlpha
                        end
                        Commit()
                    end
                    Update(true)
                end, Scope)
            end
            for _, Entry in ipairs(RGBEntries) do
                Context:Connect(Entry.FocusLost, function()
                    local Channels = {}
                    for _, ChannelEntry in ipairs(RGBEntries) do
                        local Channel = tonumber(ChannelEntry.Text)
                        if not Channel or Channel ~= Channel or math.abs(Channel) == math.huge then
                            Update(true)
                            return
                        end
                        table.insert(Channels, math.clamp(Channel, 0, 255))
                    end
                    Hue, Saturation, Brightness = Color3.fromRGB(Channels[1], Channels[2], Channels[3])
                        :ToHSV()
                    Commit()
                    Update(true)
                end, Scope)
            end
            Update()
        end, OwnerScope, { Kind = "Color" })
        function Controller:Set(Value, NewAlpha)
            if self.Updating or not self.Scope or not self.Scope.Alive then
                return
            end
            Current = Value
            if NewAlpha ~= nil then
                Alpha = NewAlpha
            end
            Hue, Saturation, Brightness = Value:ToHSV()
            if Update then
                Update(true)
            end
        end
        function Controller:Close()
            if self.Popup then
                self.Popup.Close()
            end
        end
        return Controller
    end

    return Color
end)()

-- Controls/ColorAnimation
local ColorAnimationManager = (function()
    local RunService = game:GetService("RunService")
    local Animation = {}
    local Owners = setmetatable({}, { __mode = "k" })
    function Animation.Set(Element, Modes)
        local Library = Element.Context.Library
        local Owner = Owners[Library]
        if not Owner then
            Owner = { Entries = {}, Elapsed = 0 }
            Owners[Library] = Owner
            Library.Scope:Add(function()
                if Owner.Connection then
                    Owner.Connection:Disconnect()
                end
                Owners[Library] = nil
            end)
        end
        if #Modes > 0 then
            Owner.Entries[Element] = true
        else
            Owner.Entries[Element] = nil
        end
        if next(Owner.Entries) and not Owner.Connection then
            Owner.Connection = RunService.Heartbeat:Connect(function(Dt)
                Owner.Elapsed += Dt
                if Owner.Elapsed < 1 / 30 then
                    return
                end
                Owner.Elapsed = 0
                local Time = os.clock()
                for Item in Owner.Entries do
                    if not Item.Scope.Alive then
                        Owner.Entries[Item] = nil
                    else
                        local Color = table.find(Item.Animations, "rainbow")
                                and Color3.fromHSV(math.abs(math.sin(Time * 0.32)), 1, 1)
                            or Item.BaseColor
                        local Alpha = table.find(Item.Animations, "breathing") and math.abs(
                            math.sin(Time * 0.8)
                        ) or Item.BaseAlpha
                        Item:Set(Color, Alpha, { AnimationTick = true })
                    end
                end
                if not next(Owner.Entries) then
                    Owner.Connection:Disconnect()
                    Owner.Connection = nil
                end
            end)
        elseif not next(Owner.Entries) and Owner.Connection then
            Owner.Connection:Disconnect()
            Owner.Connection = nil
        end
    end
    return Animation
end)()

-- Controls/Settings
local ElementSettings = (function()
    local RenderContext = RenderContext
    local Icons = Icons

    local Settings = {}
    local BindableKinds = { Toggle = true, Checkbox = true, Button = true, Keybind = true }

    local function GetManager(Element)
        return Element.Context.Library.KeybindManager
    end

    local function ScenePosition(Element, Position)
        local Window = Element.Context.Window
        return (Position - Window.Scene.AbsolutePosition) / math.max(0.1, Window:GetScale())
    end

    local function LayoutAccessories(E)
        local Right = E.Kind == "Toggle" and 32 or E.Kind == "Checkbox" and 24 or 0
        for _, Picker in E.AttachedColors or {} do
            if Picker.Scope.Alive then
                Picker.Instance.Position = UDim2.new(1, -Right, 0.5, 0)
                Right += 22
            end
        end
        if E.SettingsButton then
            E.SettingsButton.Position = UDim2.new(1, -Right, 0.5, 0)
            E.SettingsButton.Size = UDim2.fromOffset(18, 24)
            Right += 22
        end
        if E.AddKeybindButton then
            E.AddKeybindButton.Position = UDim2.new(1, -Right, 0.5, 0)
            Right += 40
        end
        E.Label.Size = UDim2.new(1, -Right - 4, 1, 0)
    end

    local function EnsureGear(Element)
        if Element.SettingsButton then
            return Element.SettingsButton
        end
        local Context, Scope = Element.Context, Element.Scope
        assert(
            Element.Kind == "Toggle" or Element.Kind == "Checkbox",
            "Attached settings are available on toggles and checkboxes"
        )
        local RightOffset = Element.Kind == "Toggle" and 36 or 28
        local Gear = Context:Create("TextButton", {
            Name = "Settings",
            Parent = Element.Instance,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -(Element.Options.SettingsOffset or RightOffset), 0, 10),
            Size = UDim2.fromOffset(22, 24),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 5,
        }, nil, Scope)
        local Hovered = false
        local Icon = Icons.Draw(
            Context,
            Gear,
            "Gear",
            { Position = UDim2.fromOffset(2, 5), Size = UDim2.fromOffset(14, 14) },
            function(Theme)
                return Hovered and Theme.Accent or Theme.SubText
            end,
            Scope
        )
        local function SetHovered(Value)
            Hovered = Value and not Element.Disabled
            local Tint = Hovered and Context.Theme.Values.Accent or Context.Theme.Values.SubText
            for _, Part in ipairs(Icon:GetDescendants()) do
                if Part:IsA("UIStroke") then
                    Context:Tween(Part, "Hover", { Color = Tint }, Scope)
                elseif Part:IsA("GuiObject") and Part.BackgroundTransparency < 1 then
                    Context:Tween(Part, "Hover", { BackgroundColor3 = Tint }, Scope)
                end
            end
        end
        Context:Connect(Gear.MouseEnter, function()
            SetHovered(true)
        end, Scope)
        Context:Connect(Gear.MouseLeave, function()
            SetHovered(false)
        end, Scope)
        Context:Connect(Gear.Activated, function()
            if Element.Disabled then
                return
            end
            if
                Element.SettingsPopup
                and Element.SettingsPopup.Scope.Alive
                and not Element.SettingsPopup.Closing
            then
                Element.SettingsPopup.Close()
            else
                Element:OpenSettings()
            end
        end, Scope)
        Element.SettingsButton = Gear
        LayoutAccessories(Element)
        return Gear
    end

    function Settings.Create(Element, Factory, Options)
        assert(
            Element.Kind == "Toggle" or Element.Kind == "Checkbox",
            "Use Toggle:Settings() or Checkbox:Settings()"
        )
        if Element.SettingsContainer and Element.SettingsContainer.Scope.Alive then
            return Element.SettingsContainer
        end
        Options = Options or {}
        local Scope = Element.Scope:Child()
        local ChildContext = RenderContext.New(Element.Context.Library, Scope)
        ChildContext.Window, ChildContext.Tab, ChildContext.Section =
            Element.Context.Window, Element.Tab, Element.Section
        local Container = {
            Element = Element,
            Scope = Scope,
            Context = ChildContext,
            Tab = Element.Tab,
            Window = ChildContext.Window,
            Controls = {},
            NextOrder = 0,
            Width = Options.Width or 220,
            NoSeparators = true,
            Height = 24,
        }
        ChildContext.SettingsOwner = Container
        Container.Content = ChildContext:Create("Frame", {
            Name = "SettingsContent",
            Parent = Element.Instance,
            Size = UDim2.fromOffset(Container.Width - 24, 0),
            BackgroundTransparency = 1,
            Visible = false,
        }, nil, Scope)
        Container.Layout = ChildContext:Create("UIListLayout", {
            Parent = Container.Content,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, Options.Gap or 8),
        }, nil, Scope)
        local function Resize()
            if not Scope.Alive then
                return
            end
            local Height, Count = 0, 0
            for _, Control in ipairs(Container.Controls) do
                if Control.Scope.Alive and Control.Instance.Visible then
                    Height += Control.Instance.Size.Y.Offset
                    Count += 1
                end
            end
            Height += math.max(0, Count - 1) * (Options.Gap or 8)
            Container.Height = math.max(24, Height + 20)
            Container.Content.Size = UDim2.fromOffset(Container.Width - 24, Height)
            if Container.Popup and not Container.Popup.Closing then
                Container.Popup:Resize(Vector2.new(Container.Width, Container.Height))
            end
        end
        function Container:Open(Position)
            if not Scope.Alive or Element.Disabled then
                return self
            end
            if Element.SettingsOwner then
                Element.SettingsOwner:Open()
            end
            if self.Popup and self.Popup.Scope.Alive and not self.Popup.Closing then
                return self
            end
            Resize()
            local Popup
            local function Build(Frame)
                Frame.Name = "SettingsPanel"
                self.Content.Parent, self.Content.Position, self.Content.Visible =
                    Frame, UDim2.fromOffset(12, 10), true
            end
            local PopupOptions = {
                Kind = "Settings",
                Parent = Element.SettingsOwner and Element.SettingsOwner.Popup,
                Placement = "Side",
                OnClose = function(Closed)
                    if self.Popup == Closed then
                        self.Popup = nil
                    end
                    if Element.SettingsPopup == Closed then
                        Element.SettingsPopup = nil
                    end
                end,
                OnClosed = function(Closed)
                    if Scope.Alive and self.Content.Parent == Closed.Frame then
                        self.Content.Parent, self.Content.Visible = Element.Instance, false
                    end
                end,
            }
            local Overlay = ChildContext.Window.Overlay
            if typeof(Position) == "Vector2" then
                Popup =
                    Overlay:OpenAt(Position, Vector2.new(self.Width, self.Height), Build, Scope, PopupOptions)
            else
                Popup = Overlay:Open(
                    EnsureGear(Element),
                    Vector2.new(self.Width, self.Height),
                    Build,
                    Scope,
                    PopupOptions
                )
            end
            self.Popup, Element.SettingsPopup = Popup, Popup

            return self
        end
        function Container:Close()
            if self.Popup then
                self.Popup.Close()
            end
            return self
        end
        function Container:Destroy()
            self:Close()
            Scope:Destroy()
            if Element.SettingsContainer == self then
                Element.SettingsContainer = nil
            end
        end
        for Method, Kind in
            {
                AddButton = "Button",
                AddToggle = "Toggle",
                AddCheckbox = "Checkbox",
                AddSlider = "Slider",
                AddRangeSlider = "RangeSlider",
                AddList = "List",
                AddDropdown = "Dropdown",
                AddMultiDropdown = "MultiDropdown",
                AddTextbox = "Textbox",
                AddKeybind = "Keybind",
                AddLabel = "Label",
                AddParagraph = "Paragraph",
                AddDivider = "Divider",
                AddColorPicker = "ColorPicker",
                AddProgressBar = "Progress",
            }
        do
            Container[Method] = function(Self, ChildOptions)
                if type(ChildOptions) == "string" then
                    ChildOptions = { Name = ChildOptions, Text = ChildOptions }
                end
                local Control = Factory[Kind](Self, ChildOptions or {})
                Control.SettingsOwner, Control.Section = Container, Element.Section
                ChildContext:Register(Control, {}, Control.Kind, Control.Scope)
                ChildContext:Connect(Control.Instance:GetPropertyChangedSignal("Size"), Resize, Control.Scope)
                ChildContext:Connect(
                    Control.Instance:GetPropertyChangedSignal("Visible"),
                    Resize,
                    Control.Scope
                )
                Control.Scope:Add(function()
                    Scope:Delay(0, Resize)
                end)
                Resize()
                return Control
            end
        end
        Container.AddColorpicker = Container.AddColorPicker
        Container.AddTextBox, Container.AddProgress = Container.AddTextbox, Container.AddProgressBar
        Element.SettingsContainer = Container
        EnsureGear(Element)
        return Container
    end

    function Settings.OpenKeybind(Element, Position)
        if Element.Disabled or not Element.Scope.Alive or not BindableKinds[Element.Kind] then
            return Element
        end
        local Manager, Context, Scope = GetManager(Element), Element.Context, Element.Scope
        if Element.SettingsOwner then
            Element.SettingsOwner:Open()
        end
        local Binding = Manager:Get(Element) or Element:AddKeybind({ Default = Enum.KeyCode.Unknown })
        Element.Keybind = Binding
        if Element.SettingsPopup then
            Element.SettingsPopup.Close()
        end
        local Width, Height = 170, Element.Kind == "Button" and 42 or 99
        local Names = { Toggle = "toggled", Hold = "held", ["Not Held"] = "not held", Always = "always" }
        local Modes = { toggled = "Toggle", held = "Hold", ["not held"] = "Not Held", always = "Always" }
        local function Build(Frame, PopupScope)
            Frame.Name = "KeybindEditor"
            Context:Text(
                Frame,
                "key",
                { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(62, 22), TextSize = 13 },
                PopupScope
            )
            local Key = Context:Create("TextButton", {
                Name = "CaptureKey",
                Parent = Frame,
                Position = UDim2.fromOffset(Width - 76, 10),
                Size = UDim2.fromOffset(66, 22),
                Text = "",
                TextSize = 13,
            }, { BackgroundColor3 = "Raised", TextColor3 = "Text" }, PopupScope)
            Context:Corner(Key, 4)
            Context:Hover(Key, PopupScope, "Raised", "Hover")
            Context:Connect(Key.Activated, function()
                Binding:Capture(nil, PopupScope)
            end, PopupScope)
            local ModeControl
            if Element.Kind ~= "Button" then
                local EditorContext = RenderContext.New(Context.Library, PopupScope)
                EditorContext.Window, EditorContext.Tab = Context.Window, Element.Tab
                local Holder = {
                    Context = EditorContext,
                    Scope = PopupScope,
                    Tab = Element.Tab,
                    Controls = {},
                    NextOrder = 0,
                    NoSeparators = true,
                }
                Holder.Content = Context:Create(
                    "Frame",
                    {
                        Name = "Activation",
                        Parent = Frame,
                        Position = UDim2.fromOffset(10, 40),
                        Size = UDim2.fromOffset(Width - 20, 47),
                        BackgroundTransparency = 1,
                    },
                    nil,
                    PopupScope
                )
                ModeControl = Element.ComponentFactory.Dropdown(Holder, {
                    Name = "activate when",
                    Options = { "toggled", "not held", "held", "always" },
                    Default = Names[Binding:GetMode()],
                    Searchable = false,
                    Callback = function(Value)
                        Binding:SetMode(Modes[Value])
                    end,
                })
                ModeControl.Label.TextSize = 13
            end
            local function Render()
                if not PopupScope.Alive then
                    return
                end
                if Manager:Get(Element) ~= Binding then
                    if Element.SettingsPopup then
                        Element.SettingsPopup.Close()
                    end
                    return
                end
                Key.Text = Binding.Capturing and "..." or Binding.DisplayKey
                if ModeControl then
                    ModeControl:Set(Names[Binding:GetMode()], { Silent = true })
                end
            end
            Manager:Subscribe(PopupScope, Render)
            Render()
        end
        local Options = {
            Kind = "KeybindEditor",
            Parent = Element.SettingsOwner and Element.SettingsOwner.Popup,
            OnClose = function(Popup)
                Binding:CancelCapture()
                if Element.SettingsPopup == Popup then
                    Element.SettingsPopup = nil
                end
            end,
        }
        local Overlay = Context.Window.Overlay
        if typeof(Position) == "Vector2" then
            Element.SettingsPopup =
                Overlay:OpenAt(Position, Vector2.new(Width, Height), Build, Scope, Options)
        else
            Element.SettingsPopup = Overlay:Open(
                Element.AddKeybindButton or Element.Instance,
                Vector2.new(Width, Height),
                Build,
                Scope,
                Options
            )
        end
        return Element
    end

    function Settings.OpenContext(Element, Position)
        if Element.Disabled or not Element.Scope.Alive then
            return Element
        end
        local Context, Manager = Element.Context, GetManager(Element)
        local Actions = {}
        if BindableKinds[Element.Kind] and (Element.AllowKeybind or Manager:Get(Element)) then
            if Manager:Get(Element) then
                table.insert(Actions, {
                    Name = "edit keybind",
                    Callback = function()
                        Settings.OpenKeybind(Element, Position)
                    end,
                })
                table.insert(Actions, {
                    Name = "delete keybind",
                    Callback = function()
                        Element:RemoveKeybind()
                    end,
                })
            else
                table.insert(Actions, {
                    Name = "create keybind",
                    Callback = function()
                        Settings.OpenKeybind(Element, Position)
                    end,
                })
            end
        end
        if Element.Kind == "ColorPicker" then
            table.insert(Actions, {
                Name = "Copy Color",
                Callback = function()
                    Element:CopyColor()
                end,
            })
            table.insert(Actions, {
                Name = "Paste Color",
                Enabled = Context.Library.ColorClipboard ~= nil,
                Callback = function()
                    Element:PasteColor()
                end,
            })
        end
        for _, Action in ipairs(Element.ContextActions) do
            local Visible = Action.Visible
            if type(Visible) == "function" then
                local Success, Result = pcall(Visible, Element)
                Visible = Success and Result
            end
            if Visible ~= false then
                table.insert(Actions, Action)
            end
        end
        if #Actions == 0 then
            return Element
        end
        Element.ContextPopup = Context.Window.Overlay:OpenAt(
            Position,
            Vector2.new(170, #Actions * 27 + 8),
            function(Frame, Scope, Close)
                Frame.Name = "ElementContext"
                for Index, Action in ipairs(Actions) do
                    local Enabled = Action.Enabled
                    if type(Enabled) == "function" then
                        local Success, Result = pcall(Enabled, Element)
                        Enabled = Success and Result
                    end
                    Enabled = Enabled ~= false
                    local Button = Context:Create("TextButton", {
                        Name = Action.Name,
                        Parent = Frame,
                        Text = Action.Name,
                        Position = UDim2.fromOffset(8, 4 + (Index - 1) * 27),
                        Size = UDim2.new(1, -16, 0, 27),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 13,
                    }, { TextColor3 = Enabled and "Text" or "SubText" }, Scope)
                    Context:Connect(Button.MouseEnter, function()
                        if Enabled then
                            Context:Tween(
                                Button,
                                "Hover",
                                { TextColor3 = Context.Theme.Values.Accent },
                                Scope
                            )
                        end
                    end, Scope)
                    Context:Connect(Button.MouseLeave, function()
                        if Enabled then
                            Context:Tween(Button, "Hover", { TextColor3 = Context.Theme.Values.Text }, Scope)
                        end
                    end, Scope)
                    Context:Connect(Button.Activated, function()
                        if not Enabled then
                            return
                        end
                        Close()
                        Element.Scope:Delay(0, function()
                            Context:Callback(Action.Callback, Element)
                        end)
                    end, Scope)
                end
            end,
            Element.Scope,
            {
                Kind = "Context",
                Parent = Element.SettingsOwner and Element.SettingsOwner.Popup,
                OnClose = function(Popup)
                    if Element.ContextPopup == Popup then
                        Element.ContextPopup = nil
                    end
                end,
            }
        )
        return Element
    end

    local function EnsureKeybindButton(Element)
        if
            Element.AddKeybindButton
            or Element.Options.HideKeybindButton
            or (Element.Kind ~= "Toggle" and Element.Kind ~= "Checkbox")
        then
            return
        end
        local Manager = GetManager(Element)
        local Offset = Element.Kind == "Toggle" and 36 or 28
        local Add = Element.Context:Create("TextButton", {
            Name = "AddKeybind",
            Parent = Element.Instance,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Offset, 0, 9),
            Size = UDim2.fromOffset(34, 20),
            BackgroundTransparency = 1,
            Text = "None",
            TextSize = 12,
            ZIndex = 6,
        }, { TextColor3 = "SubText" }, Element.Scope)
        Element.AddKeybindButton = Add
        Element.Context:Tooltip(Add, "Add or edit keybind", Element.Scope)
        Element.Context:Connect(Add.Activated, function()
            if not Element.Disabled then
                Element:OpenContext(
                    ScenePosition(Element, Add.AbsolutePosition + Vector2.new(0, Add.AbsoluteSize.Y + 5))
                )
            end
        end, Element.Scope)
        local function RenderBinding()
            local B = Manager:Get(Element)
            Add.Text = B and (B.Capturing and "..." or B.DisplayKey) or "None"
        end
        Manager:Subscribe(Element.Scope, RenderBinding)
        RenderBinding()
        LayoutAccessories(Element)
    end

    function Settings.Install(Element, Factory)
        local Manager = GetManager(Element)
        Element.ComponentFactory = Factory
        Element.ContextActions = {}
        function Element:AddContextAction(Action)
            assert(
                type(Action) == "table"
                    and type(Action.Name) == "string"
                    and type(Action.Callback) == "function",
                "Context actions require a Name and Callback"
            )
            table.insert(self.ContextActions, table.clone(Action))
            return self
        end
        function Element:SetContextActions(Actions)
            assert(type(Actions) == "table", "Context actions must be an array")
            table.clear(self.ContextActions)
            for _, Action in ipairs(Actions) do
                self:AddContextAction(Action)
            end
            return self
        end
        if Element.Options.ContextActions then
            Element:SetContextActions(Element.Options.ContextActions)
        end
        if Element.Kind == "ColorPicker" then
            function Element:CopyColor()
                self.Context.Library.ColorClipboard = self:GetState()
                return self:GetHex(self.EnableAlpha)
            end
            function Element:PasteColor(Options)
                local Value = self.Context.Library.ColorClipboard
                if not Value then
                    return false, "Copy a color first"
                end
                self:SetState(Value, Options)
                return true
            end
        end
        Element.Id = Element.Id or Element.Options.Id or Element.Options.Flag
        Element.Id = Manager:RegisterElement(Element, Element.Id, Element.Scope)
        if Element.Kind == "Slider" or Element.Kind == "Dropdown" or Element.Kind == "MultiDropdown" then
            local Set = Element.Set
            function Element:Set(...)
                local Result = Set(self, ...)
                Manager:NotifyElementChanged(self)
                return Result
            end
        end
        function Element:SetValue(...)
            return self:Set(...)
        end
        function Element:GetValue(...)
            return self:Get(...)
        end
        function Element:Settings(Options)
            return Settings.Create(self, Factory, Options)
        end
        Element.CreateSettings = Element.Settings
        Element.settings = Element.Settings
        Element.AttachedColors = {}
        function Element:AddColorPicker(Options)
            assert(
                self.Kind == "Toggle" or self.Kind == "Checkbox" or self.Kind == "Label",
                "Attach color pickers to a toggle, checkbox, or label"
            )
            local ChildScope = self.Scope:Child()
            local Context = RenderContext.New(self.Context.Library, ChildScope)
            Context.Window, Context.Tab, Context.Section = self.Context.Window, self.Tab, self.Section
            local Holder = {
                Scope = ChildScope,
                Context = Context,
                Content = self.Instance,
                Tab = self.Tab,
                Controls = {},
                NextOrder = 0,
                NoSeparators = true,
            }
            local Picker = Factory.ColorPicker(Holder, Options or {})
            Picker.Instance.AnchorPoint = Vector2.new(1, 0.5)
            Picker.Instance.Size = UDim2.fromOffset(16, 18)
            Picker.Label.Visible = false
            Picker.AttachedOwner = self
            table.insert(self.AttachedColors, Picker)
            LayoutAccessories(self)
            Picker.Scope:Add(function()
                self.Scope:Delay(0, function()
                    LayoutAccessories(self)
                end)
            end)
            return Picker
        end
        Element.Colorpicker, Element.ColorPicker, Element.colorpicker =
            Element.AddColorPicker, Element.AddColorPicker, Element.AddColorPicker
        function Element:Colorpickers(Options)
            local Pickers = {}
            for _, Item in Options do
                table.insert(Pickers, self:AddColorPicker(Item))
            end
            return Pickers
        end
        function Element:AddKeybind(Options)
            assert(BindableKinds[self.Kind], "Keybinds attach to buttons, toggles, and checkboxes")
            self.AllowKeybind = true
            self.Keybind = Manager:Attach(self, Options or {})
            EnsureKeybindButton(self)
            return self.Keybind
        end
        Element.SetKeybind, Element.keybind = Element.AddKeybind, Element.AddKeybind
        function Element:GetKeybind()
            return Manager:Get(self)
        end
        function Element:RemoveKeybind()
            Manager:Remove(self)
            self.Keybind = nil
            return self
        end
        function Element:OpenSettings(Position)
            if self.SettingsContainer then
                self.SettingsContainer:Open(Position)
            end
            return self
        end
        function Element:OpenKeybindEditor(Position)
            return Settings.OpenKeybind(self, Position)
        end
        function Element:OpenContext(Position)
            return Settings.OpenContext(self, Position or ScenePosition(self, self.Instance.AbsolutePosition))
        end
        if Element.Kind == "Button" then
            Element.Press = Element.Click
        end
        if Element.Options.Keybind and BindableKinds[Element.Kind] and not Manager:Get(Element) then
            Element:AddKeybind(type(Element.Options.Keybind) == "table" and Element.Options.Keybind or {})
        end
        if Element.Options.Settings and (Element.Kind == "Toggle" or Element.Kind == "Checkbox") then
            Settings.Create(
                Element,
                Factory,
                type(Element.Options.Settings) == "table" and Element.Options.Settings or nil
            )
        end
        Element.Context:Connect(Element.Instance.InputBegan, function(Input)
            if
                Input.UserInputType == Enum.UserInputType.MouseButton2
                and (
                    BindableKinds[Element.Kind]
                    or Element.Kind == "ColorPicker"
                    or #Element.ContextActions > 0
                )
            then
                Settings.OpenContext(
                    Element,
                    ScenePosition(Element, Vector2.new(Input.Position.X, Input.Position.Y))
                )
            end
        end, Element.Scope)
        return Element
    end

    return Settings
end)()

-- Core/Spacing
local Spacing = (function()
    return table.freeze({
        XS = 4,
        SM = 8,
        MD = 14,
        LG = 24,
        Corner = 5,
        WindowWidth = 600,
        WindowHeight = 532,
        HeaderHeight = 35,
        SectionHeader = 35,
        SectionGap = 10,
        SectionPadding = 6,
        RowHeight = 18,
        CheckboxSize = 18,
        SliderThickness = 10,
        PopupPadding = 8,
        PopupRowHeight = 25,
    })
end)()

-- Controls/Range
local RangeSliderComponent = (function()
    return function(CreateBase)
        return function(Section, Options)
            Options = Options or {}
            local E, C, Row, Scope, Label = CreateBase(Section, Options, "RangeSlider", 33)
            local Min, Max = Options.Min or 0, Options.Max or 100
            local Step = Options.Increment or 1
            local function Finite(V)
                return type(V) == "number" and V == V and math.abs(V) < math.huge
            end
            assert(
                Finite(Min) and Finite(Max) and Max >= Min and Finite(Step) and Step > 0,
                "Invalid range bounds"
            )
            local Span = Max - Min
            local Places = 0
            for _, V in { Min, Max, Step } do
                local N = 0
                while N < 6 and math.abs(V * 10 ^ N - math.round(V * 10 ^ N)) > 0.00001 do
                    N += 1
                end
                Places = math.max(Places, N)
            end
            local Format = "%." .. Places .. "f"
            local ValueText = Row.Value
            ValueText.AutomaticSize = Enum.AutomaticSize.None
            ValueText.AnchorPoint = Vector2.new(1, 0)
            ValueText.Position = UDim2.new(1, 0, 0, 0)
            ValueText.Size = UDim2.fromOffset(105, 17)
            ValueText.TextXAlignment = Enum.TextXAlignment.Right
            Label.Size = UDim2.new(1, -112, 0, 17)
            local Track = Row.RealSliderOutline.RealSlider
            local Fill, Low = Track.Accent, Track.DraggerOutline
            local High = Low:Clone()
            High.Name = "UpperHandle"
            High.Parent = Track
            Scope:Add(High)
            local Hit = C:Create(
                "Frame",
                {
                    Name = "RangeInput",
                    Parent = Row,
                    Position = UDim2.fromOffset(0, 16),
                    Size = UDim2.new(1, 0, 0, 17),
                    BackgroundTransparency = 1,
                    Active = true,
                    ZIndex = 8,
                },
                nil,
                Scope
            )
            E.Track, E.Input, E.Handles, E.Fill = Track, Hit, { Low, High }, Fill
            E.Min, E.Max, E.Increment = Min, Max, Step
            local function Quantize(V)
                if V >= Max then
                    return Max
                end
                return math.clamp(
                    math.round((Min + math.round((V - Min) / Step) * Step) * 1e6) / 1e6,
                    Min,
                    Max
                )
            end
            function E:Get()
                return table.clone(self.Value)
            end
            function E:Validate(V)
                return type(V) == "table"
                    and #V == 2
                    and Finite(V[1])
                    and Finite(V[2])
                    and V[1] >= Min
                    and V[2] <= Max
                    and V[1] <= V[2],
                    "Expected {lower, upper} within range"
            end
            function E:Render(Alpha, Index)
                local A = Span == 0 and 0 or (self.Value[1] - Min) / Span
                local B = Span == 0 and 0 or (self.Value[2] - Min) / Span
                if Alpha then
                    if Index == 1 then
                        A = math.min(Alpha, B)
                    else
                        B = math.max(Alpha, A)
                    end
                end
                C:Tween(Low, "Slider", { Position = UDim2.fromScale(A, 0.5) }, Scope)
                C:Tween(High, "Slider", { Position = UDim2.fromScale(B, 0.5) }, Scope)
                C:Tween(
                    Fill,
                    "Slider",
                    {
                        Position = UDim2.fromScale(A, 0),
                        Size = UDim2.fromScale(B - A, 1),
                        BackgroundTransparency = self.Disabled and 0.5 or 0,
                    },
                    Scope
                )
                ValueText.Text = string.format(Format, self.Value[1])
                    .. " - "
                    .. string.format(Format, self.Value[2])
                    .. (Options.Suffix or "")
            end
            function E:Set(Value, Upper, SetOptions)
                if type(Value) == "table" then
                    SetOptions = Upper
                else
                    Value = { Value, Upper }
                end
                assert(
                    type(Value) == "table" and Finite(Value[1]) and Finite(Value[2]),
                    "RangeSlider:Set expects {lower, upper} or two numbers"
                )
                local A, B = Quantize(Value[1]), Quantize(Value[2])
                if A > B then
                    A, B = B, A
                end
                local Changed = not self.Value or self.Value[1] ~= A or self.Value[2] ~= B
                self.Value = { A, B }
                self:Render(SetOptions and SetOptions.RawAlpha, SetOptions and SetOptions.Handle)
                if Changed and not (SetOptions and SetOptions.Silent) then
                    C:Callback(Options.Callback, self:Get())
                end
                return self
            end
            E:Set(Options.Default or { Min, Max }, { Silent = true })
            local Selected = 1
            C.Input:Drag(Scope, Hit, function(Position, Phase)
                if E.Disabled then
                    return
                end
                if Phase == "End" then
                    E:Render()
                    return
                end
                local A = math.clamp(
                    (Position.X - Track.AbsolutePosition.X) / math.max(1, Track.AbsoluteSize.X),
                    0,
                    1
                )
                local V = Min + A * Span
                if Phase == "Begin" then
                    local DL, DH = math.abs(V - E.Value[1]), math.abs(V - E.Value[2])
                    Selected = if DL == DH then (V >= E.Value[2] and 2 or 1) elseif DL < DH then 1 else 2
                end
                local Pair = E:Get()
                Pair[Selected] = Selected == 1 and math.min(Quantize(V), Pair[2])
                    or math.max(Quantize(V), Pair[1])
                E:Set(Pair, { RawAlpha = A, Handle = Selected })
            end)
            C:Register(E, Options, "State", Scope)
            return E
        end
    end
end)()

-- Controls/List
local ListComponent = (function()
    return function(CreateBase, NormalizeOptions)
        return function(Section, Options)
            Options = Options or {}
            local Height = math.max(110, Options.Height or 154)
            local E, C, Row, Scope, Label = CreateBase(Section, Options, "List", Height, false)
            Label.Size = UDim2.new(1, 0, 0, 18)
            local Body = C:Create(
                "Frame",
                { Name = "ListBody", Parent = Row, Position = UDim2.fromOffset(0, 23), Size = UDim2.new(
                    1,
                    0,
                    1,
                    -23
                ) },
                { BackgroundColor3 = "Surface" },
                Scope
            )
            C:Corner(Body, 5)
            C:Stroke(Body, "Border", Scope)
            local Searchable = Options.Searchable ~= false
            local Search
            if Searchable then
                Search = C:Create(
                    "TextBox",
                    {
                        Name = "Search",
                        Parent = Body,
                        Position = UDim2.fromOffset(8, 4),
                        Size = UDim2.new(1, -16, 0, 24),
                        Text = "",
                        PlaceholderText = "Search…",
                        ClearTextOnFocus = false,
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 13,
                    },
                    { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
                    Scope
                )
            end
            local Top = Searchable and 30 or 4
            local Scroller = C:Create(
                "ScrollingFrame",
                {
                    Name = "Options",
                    Parent = Body,
                    Position = UDim2.fromOffset(4, Top),
                    Size = UDim2.new(1, -8, 1, -Top - 4),
                    BackgroundTransparency = 1,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                },
                { ScrollBarImageColor3 = "Accent" },
                Scope
            )
            C:Create(
                "UIListLayout",
                { Parent = Scroller, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) },
                nil,
                Scope
            )
            E.Multiple = Options.Multi == true
            E.Value = E.Multiple and {} or nil
            E.Items = {}
            E.SearchBox = Search
            E.Scroller = Scroller
            local Rows, ItemsScope = {}, nil
            local function Find(Value)
                for _, Item in E.Items do
                    if Item.Value == Value and not Item.Disabled then
                        return Item
                    end
                end
            end
            local function Selected(Value)
                return E.Multiple and table.find(E.Value, Value) ~= nil or not E.Multiple and E.Value == Value
            end
            function E:Get()
                return self.Multiple and table.clone(self.Value) or self.Value
            end
            function E:Validate(Value)
                if not self.Multiple then
                    return Value == nil or Find(Value) ~= nil, "Unknown list option"
                end
                if type(Value) ~= "table" then
                    return false, "Expected an option array"
                end
                local Seen = {}
                for _, V in Value do
                    if Seen[V] or not Find(V) then
                        return false, "Unknown or repeated list option"
                    end
                    Seen[V] = true
                end
                return true
            end
            function E:Render()
                for _, Entry in Rows do
                    local On = Selected(Entry.Item.Value)
                    C:Tween(Entry.Button, "Hover", { BackgroundTransparency = On and 0 or 1 }, ItemsScope)
                    C:Tween(
                        Entry.Text,
                        "Hover",
                        {
                            TextColor3 = C.Theme.Values[On and "Accent" or Entry.Item.Disabled and "SubText" or "Text"],
                        },
                        ItemsScope
                    )
                    Entry.Mark.Visible = On
                end
            end
            function E:Set(Value, SetOptions)
                assert(self:Validate(Value), "List:Set received an unknown option")
                local Changed = self.Value ~= Value
                if self.Multiple then
                    Changed = #self.Value ~= #Value
                    for Index, Item in Value do
                        if self.Value[Index] ~= Item then
                            Changed = true
                            break
                        end
                    end
                end
                self.Value = self.Multiple and table.clone(Value) or Value
                self:Render()
                if Changed and not (SetOptions and SetOptions.Silent) then
                    C:Callback(Options.Callback, self:Get())
                end
                return self
            end
            local Empty
            local function Filter()
                local Query = Search and Search.Text:lower() or ""
                local Count = 0
                for _, Entry in Rows do
                    Entry.Button.Visible = Entry.Item.Name:lower():find(Query, 1, true) ~= nil
                    if Entry.Button.Visible then
                        Count += 1
                    end
                end
                if Empty then
                    Empty.Visible = Count == 0
                end
                Scroller.CanvasPosition = Vector2.zero
            end
            function E:Refresh(OptionsList, Preserve)
                if ItemsScope then
                    ItemsScope:Destroy()
                end
                ItemsScope = Scope:Child()
                Rows = {}
                self.Items = NormalizeOptions(OptionsList)
                local NextValue = self.Multiple and {} or nil
                if Preserve ~= false then
                    if self.Multiple then
                        for _, V in self.Value do
                            if Find(V) then
                                table.insert(NextValue, V)
                            end
                        end
                    elseif Find(self.Value) then
                        NextValue = self.Value
                    end
                end
                self.Value = NextValue
                for Index, Item in self.Items do
                    local Button = C:Create(
                        "TextButton",
                        {
                            Name = Item.Name,
                            Parent = Scroller,
                            Size = UDim2.new(1, -4, 0, 25),
                            LayoutOrder = Index,
                            Text = "",
                            BackgroundTransparency = 1,
                        },
                        { BackgroundColor3 = "Raised" },
                        ItemsScope
                    )
                    C:Corner(Button, 4)
                    local Text = C:Text(
                        Button,
                        Item.Name,
                        {
                            Position = UDim2.fromOffset(7, 0),
                            Size = UDim2.new(1, -31, 1, 0),
                            TextSize = 13,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                        },
                        ItemsScope
                    )
                    local Mark = C:Text(
                        Button,
                        "✓",
                        { Position = UDim2.new(1, -22, 0, 0), Size = UDim2.fromOffset(18, 25), TextSize = 13 },
                        ItemsScope
                    )
                    C:Bind(Mark, "TextColor3", "Accent", ItemsScope)
                    table.insert(Rows, { Button = Button, Text = Text, Mark = Mark, Item = Item })
                    C:Connect(Button.MouseEnter, function()
                        if not Item.Disabled then
                            C:Tween(Button, "Hover", { BackgroundTransparency = 0.35 }, ItemsScope)
                        end
                    end, ItemsScope)
                    C:Connect(Button.MouseLeave, function()
                        E:Render()
                    end, ItemsScope)
                    C:Connect(Button.Activated, function()
                        if E.Disabled or Item.Disabled then
                            return
                        end
                        if E.Multiple then
                            local Value = E:Get()
                            local I = table.find(Value, Item.Value)
                            if I then
                                table.remove(Value, I)
                            else
                                table.insert(Value, Item.Value)
                            end
                            E:Set(Value)
                        else
                            E:Set(Item.Value)
                        end
                    end, ItemsScope)
                end
                Empty = C:Text(
                    Scroller,
                    "No matches",
                    { Name = "Empty", Size = UDim2.new(1, 0, 0, 25), TextSize = 13 },
                    ItemsScope
                )
                C:Bind(Empty, "TextColor3", "SubText", ItemsScope)
                self:Render()
                Filter()
                return self
            end
            E.SetOptions = E.Refresh
            if Search then
                C:Connect(Search:GetPropertyChangedSignal("Text"), Filter, Scope)
            end
            E:Refresh(Options.Options or Options.Values or {}, false)
            if Options.Default ~= nil then
                E:Set(Options.Default, { Silent = true })
            end
            C.Theme:Subscribe(function()
                E:Render()
            end, Scope)
            C:Register(E, Options, E.Multiple and "MultiDropdown" or "Dropdown", Scope)
            return E
        end
    end
end)()

-- Controls/Factory
local Components = (function()
    local Templates = VisualTemplates
    local Color = ColorPicker
    local ColorAnimation = ColorAnimationManager
    local Icons = Icons
    local Settings = ElementSettings
    local Spacing = Spacing
    local TextService = game:GetService("TextService")

    local Factory = {}

    local function IsFinite(Value)
        return type(Value) == "number" and Value == Value and math.abs(Value) < math.huge
    end

    local function IsSilent(Options)
        return type(Options) == "table" and Options.Silent == true
    end

    local function CloneArray(Value)
        return table.clone(Value)
    end

    local function EmitChanged(Context, Callback, Value, Options)
        if not IsSilent(Options) then
            Context:Callback(Callback, Value)
        end
    end

    local MeasureText = RenderContext.MeasureText

    local function GetLabelColor(Element, Theme)
        local Options = Element.Options
        if Element.Disabled or Options.Dimmed then
            return Theme.SubText
        end
        if Options.DimWhenOff and not Element.Value then
            return Theme.SubText
        end
        return Theme.Text
    end

    local function CreateBase(Section, Options, Kind, Height, Interactive)
        Options = Options or {}
        local Context, Scope = Section.Context, Section.Scope:Child()
        Section.NextOrder = (Section.NextOrder or 0) + 1
        local Element = {
            Context = Context,
            Scope = Scope,
            Name = Options.Name or Kind,
            Kind = Kind,
            Disabled = Options.Disabled == true,
            Value = nil,
            Hovered = false,
            Options = Options,
            Section = Context.Section or Section,
            Tab = Section.Tab,
            SettingsOwner = Context.SettingsOwner,
            Id = Options.Id or Options.Flag,
        }
        local VisualKind = Kind == "RangeSlider" and "Slider"
            or Kind == "MultiDropdown" and "Dropdown"
            or Kind
        local Row, Label
        if Templates.Has(VisualKind) then
            Row = Templates.Create(VisualKind, Context, Section.Content, Scope)
            Label = if VisualKind == "Button" then Row.RealButton.Label else Row.Label
            Label.AutomaticSize = Enum.AutomaticSize.None
            Label.AnchorPoint = Vector2.zero
            Label.Position = UDim2.fromOffset(0, 0)
            Label.Size = UDim2.new(1, -70, 0, (Kind == "Toggle" or Kind == "Checkbox") and 18 or 17)
            Label.Text = Element.Name
        else
            Row = Context:Create(Interactive == false and "Frame" or "TextButton", {
                Parent = Section.Content,
                Size = UDim2.new(1, 0, 0, Options.Height or Height or Spacing.RowHeight),
                BackgroundTransparency = 1,
            }, nil, Scope)
            if Row:IsA("TextButton") then
                Row.Text = ""
            end
            Label = Context:Text(
                Row,
                Element.Name,
                { Size = UDim2.new(1, -100, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd },
                Scope
            )
        end
        Row.Name = Element.Name
        Row.LayoutOrder = Section.NextOrder * 2
        if Options.Height then
            Row.Size = UDim2.new(1, 0, 0, Options.Height)
        end
        local RowSeparator
        if Section.NextOrder > 1 and not Section.NoSeparators and Kind ~= "Divider" then
            local Separator = Templates.Create("Separator", Context, Section.Content, Scope)
            Separator.LayoutOrder = Section.NextOrder * 2 - 1
            RowSeparator = Separator
        end
        Label.TextTruncate = Enum.TextTruncate.AtEnd
        Context:Bind(Label, "TextColor3", function(Theme)
            return GetLabelColor(Element, Theme)
        end, Scope)
        Context:Bind(Label, "Font", "FontBold", Scope)
        Context:Bind(Label, "TextSize", "TextSize", Scope)
        Element.Instance, Element.Label = Row, Label
        function Element:Get()
            return self.Value
        end
        function Element:RefreshLabel()
            Context:Tween(Label, "Toggle", { TextColor3 = GetLabelColor(self, Context.Theme.Values) }, Scope)
        end
        function Element:SetVisible(Visible)
            if not self.Scope.Alive then
                return self
            end
            self.Instance.Visible = Visible == true
            if RowSeparator then
                RowSeparator.Visible = Visible == true
            end
            if not Visible then
                self:ClosePopup()
                if self.ContextPopup then
                    self.ContextPopup.Close()
                end
                if self.SettingsPopup then
                    self.SettingsPopup.Close()
                end
                if self.CancelCapture then
                    self:CancelCapture()
                end
                if self.Keybind then
                    self.Keybind:CancelCapture()
                end
            end
            return self
        end
        function Element:SetDisabled(Disabled)
            self.Disabled = Disabled == true
            if self.Disabled and self.Keybind then
                self.Keybind:CancelCapture()
            end
            if Context.Library.KeybindManager then
                Context.Library.KeybindManager:NotifyElementChanged(self)
            end
            if self.Disabled then
                self:ClosePopup()
                if self.ContextPopup then
                    self.ContextPopup.Close()
                end
                if self.SettingsPopup then
                    self.SettingsPopup.Close()
                end
            end
            if self.OnDisabled then
                self:OnDisabled()
            end
            if self.Render then
                self:Render()
            end
            self:RefreshLabel()
            return self
        end
        function Element:Destroy()
            if not self.Scope.Alive then
                return
            end
            self:ClosePopup()
            if self.ContextPopup then
                self.ContextPopup.Close()
            end
            if self.SettingsPopup then
                self.SettingsPopup.Close()
            end
            self.Scope:Destroy()
            local Index = table.find(Section.Controls, self)
            if Index then
                table.remove(Section.Controls, Index)
            end
        end
        function Element:ClosePopup()
            if self.Popup then
                self.Popup.Close()
                self.Popup = nil
            end
        end
        Context:Connect(Row.MouseEnter, function()
            Element.Hovered = true
        end, Scope)
        Context:Connect(Row.MouseLeave, function()
            Element.Hovered = false
        end, Scope)
        if Options.Tooltip then
            Context:Tooltip(Row, Options.Tooltip, Scope)
        end
        Scope:Connect(Row.Destroying, function()
            if Scope.Alive then
                Element:Destroy()
            end
        end)
        table.insert(Section.Controls, Element)
        return Element, Context, Row, Scope, Label
    end

    local function CreateTriangle(Context, Parent, Position, Token, Scope)
        local ArrowRoot = Context:Create("Frame", {
            Name = "Arrow",
            Parent = Parent,
            Position = Position,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(8, 7),
            BackgroundTransparency = 1,
        }, nil, Scope)
        for Index = 0, 6 do
            Context:Create("Frame", {
                Parent = ArrowRoot,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(Index * 0.5, Index),
                Size = UDim2.fromOffset(8 - Index, 1),
            }, { BackgroundColor3 = Token }, Scope)
        end
        return ArrowRoot
    end

    local function CreateCheckbox(Context, Parent, Position, Size, Scope)
        local Checkbox = Context:Create("Frame", {
            Name = "Indicator",
            Parent = Parent,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = Position,
            Size = UDim2.fromOffset(Size, Size),
            BorderSizePixel = 0,
        }, nil, Scope)
        Context:Corner(Checkbox, 4)
        Context:Gradient(Checkbox, Scope)
        local Checkmark = Context:Create("CanvasGroup", {
            Name = "Check",
            Parent = Checkbox,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
        }, nil, Scope)
        for _, Endpoints in ipairs({ { 4, 9, 7, 13 }, { 7, 13, 14, 4 } }) do
            local StartPoint, EndPoint =
                Vector2.new(Endpoints[1], Endpoints[2]), Vector2.new(Endpoints[3], Endpoints[4])
            local Delta, Center = EndPoint - StartPoint, (StartPoint + EndPoint) / 2
            local Segment = Context:Create("Frame", {
                Parent = Checkmark,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(Center.X / 18, Center.Y / 18),
                Size = UDim2.new(Delta.Magnitude / 18, 0, 0, 1.8),
                Rotation = math.deg(math.atan2(Delta.Y, Delta.X)),
                BorderSizePixel = 0,
            }, { BackgroundColor3 = "Background" }, Scope)
            Context:Corner(Segment, 1)
        end
        return Checkbox, Checkmark
    end

    local function IsValidBinding(Value)
        local Mouse = Value == Enum.UserInputType.MouseButton1
            or Value == Enum.UserInputType.MouseButton2
            or Value == Enum.UserInputType.MouseButton3
        return typeof(Value) == "EnumItem" and (Value.EnumType == Enum.KeyCode or Mouse)
    end

    local function CreateValueLabel(Context, Row, Scope, Width)
        local Label = Context:Text(Row, "", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, Width or 94, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = Row.ZIndex + 2,
        }, Scope)
        Context:Bind(Label, "Font", "Font", Scope)
        Context:Bind(Label, "TextSize", function(Theme)
            return math.max(9, Theme.TextSize - 1)
        end, Scope)
        return Label
    end

    function Factory.Button(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "Button", 25)
        Label.Size = UDim2.new(1, 0, 1, 0)
        Context:Hover(Row.RealButton, Scope, "Raised", "Hover")
        Label.TextXAlignment = Enum.TextXAlignment.Center
        Element.Value = Element.Name
        function Element:Set(Value)
            self.Value, self.Name = tostring(Value), tostring(Value)
            Label.Text = self.Name
            return self
        end
        function Element:Click()
            if self.Disabled or not self.Scope.Alive then
                return self
            end

            Context:Tween(Label, "Press", { TextColor3 = Context.Theme.Values.Accent }, Scope)
            Scope:Delay(0.1, function()
                self:RefreshLabel()
            end)
            Context:Callback(Options.Callback)
            return self
        end
        Context:Connect(Row.RealButton.Activated, function()
            Element:Click()
        end, Scope)
        return Element
    end

    local function CreateBoolean(Section, Options, Kind)
        Options = table.clone(Options or {})
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, Kind)
        Label.Size = UDim2.new(1, (Options.Keybind or Options.Settings) and -48 or -28, 1, 0)
        local Indicator = Row.IndicatorOutline.Indicator
        local Checkmark = Kind == "Checkbox" and Indicator.Accent or nil
        local Knob = Kind == "Toggle" and Indicator.Circle or nil
        local Gradients = {}
        for _, V in Indicator:GetChildren() do
            if V:IsA("UIGradient") then
                table.insert(Gradients, V)
            end
        end
        Element.Indicator, Element.Checkmark, Element.Knob = Indicator, Checkmark, Knob
        function Element:Render()
            local Theme = Context.Theme.Values
            if Checkmark then
                Context:Tween(
                    Checkmark,
                    "Toggle",
                    {
                        Size = UDim2.fromScale(self.Value and 1 or 0, self.Value and 1 or 0),
                        BackgroundTransparency = self.Value and 0 or 1,
                    },
                    Scope
                )
                Context:Tween(Checkmark.Icon, "Toggle", { ImageTransparency = self.Value and 0 or 1 }, Scope)
            else
                for Index, G in Gradients do
                    G.Enabled = (Index == #Gradients) == self.Value
                end
                Context:Tween(
                    Knob,
                    "Toggle",
                    {
                        AnchorPoint = Vector2.new(self.Value and 1 or 0, 0),
                        Position = UDim2.new(self.Value and 1 or 0, self.Value and -1 or 1, 0, 1),
                        BackgroundTransparency = self.Value and 0 or 0.6,
                    },
                    Scope
                )
                local G = Knob:FindFirstChildOfClass("UIGradient")
                if G then
                    G.Enabled = not self.Value
                end
            end
            Context:Tween(
                Indicator,
                "Toggle",
                {
                    BackgroundColor3 = if Knob and self.Value
                        then Theme.White
                        elseif self.Hovered and not self.Disabled then Theme.Hover
                        else Theme.Raised,
                },
                Scope
            )
            self:RefreshLabel()
        end
        function Element:Validate(Value)
            return type(Value) == "boolean", "Toggle requires a boolean"
        end
        function Element:Set(Value, SetOptions)
            assert(type(Value) == "boolean", "Toggle:Set expects a boolean")
            local PreviousValue = self.Value
            self.Value = Value
            self:Render()
            if Context.Library.KeybindManager then
                Context.Library.KeybindManager:NotifyElementChanged(self)
            end
            if PreviousValue ~= self.Value then
                EmitChanged(Context, Options.Callback, self.Value, SetOptions)
            end
            return self
        end
        Element:Set(Options.Default == true, { Silent = true })
        Context:Connect(Row.MouseEnter, function()
            Element.Hovered = true
            if not Element.Disabled then
                Element:Render()
            end
        end, Scope)
        Context:Connect(Row.MouseLeave, function()
            Element.Hovered = false
            Element:Render()
        end, Scope)
        Context:Connect(Row.Activated, function()
            if Element.Disabled then
                return
            end
            if Element.Keybind and Element.Keybind.Mode == "Always" then
                return
            end

            Element:Set(not Element.Value)
        end, Scope)
        Context:Register(Element, Options, Kind, Scope)
        return Element
    end

    function Factory.Toggle(Section, Options)
        return CreateBoolean(Section, Options, "Toggle")
    end
    function Factory.Checkbox(Section, Options)
        return CreateBoolean(Section, Options, "Checkbox")
    end

    function Factory.Slider(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope = CreateBase(Section, Options, "Slider", 38)
        local Minimum = IsFinite(Options.Min) and Options.Min or 0
        local Maximum = IsFinite(Options.Max) and math.max(Minimum, Options.Max) or math.max(Minimum, 100)
        local Increment = IsFinite(Options.Increment) and Options.Increment > 0 and Options.Increment or 1
        local Range = Maximum - Minimum
        local Decimals = Options.Decimals
        if not IsFinite(Decimals) then
            Decimals = 0
            for _, Metric in ipairs({ Increment, Minimum, Maximum }) do
                local Places = 0
                while
                    Places < 6
                    and math.abs(Metric * 10 ^ Places - math.round(Metric * 10 ^ Places)) > 0.00001
                do
                    Places += 1
                end
                Decimals = math.max(Decimals, Places)
            end
        end
        Decimals = math.clamp(math.floor(Decimals), 0, 6)
        Element.Label.Size = UDim2.new(1, -90, 0, 17)
        local ValueText = Row.Value
        ValueText.AutomaticSize = Enum.AutomaticSize.None
        ValueText.Size = UDim2.fromOffset(65, 17)
        ValueText.AnchorPoint = Vector2.new(1, 0)
        ValueText.Position = UDim2.new(1, 0, 0, 0)
        ValueText.TextXAlignment = Enum.TextXAlignment.Right
        local Track = Row.RealSliderOutline.RealSlider
        local Fill = Track.Accent
        local Endpoint = Track.DraggerOutline
        local Hitbox = Context:Create(
            "Frame",
            {
                Name = "SliderInput",
                Parent = Row,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, 0, 0, 17),
                BackgroundTransparency = 1,
                Active = true,
                ZIndex = 8,
            },
            nil,
            Scope
        )
        Element.Track, Element.Input, Element.Fill, Element.Knob = Track, Hitbox, Fill, Endpoint
        Element.Min, Element.Max, Element.Increment = Minimum, Maximum, Increment
        local function Quantize(Value)
            if Value >= Maximum then
                return Maximum
            end
            if Value <= Minimum then
                return Minimum
            end
            local Stepped = Minimum
                + math.round((math.clamp(Value, Minimum, Maximum) - Minimum) / Increment) * Increment
            return math.clamp(math.round(Stepped * 1000000) / 1000000, Minimum, Maximum)
        end
        function Element:Render(RawAlpha)
            local Alpha = RawAlpha or (Range == 0 and 0 or (self.Value - Minimum) / Range)
            Alpha = math.clamp(Alpha, 0, 1)
            Context:Tween(
                Fill,
                "Slider",
                { Size = UDim2.fromScale(Alpha, 1), BackgroundTransparency = self.Disabled and 0.5 or 0 },
                Scope
            )
            Context:Tween(
                Endpoint,
                "Slider",
                {
                    Position = UDim2.fromScale(Alpha, 0.5),
                    BackgroundTransparency = self.Disabled and 0.5 or 0,
                },
                Scope
            )
            if Options.FormatValue or Options.Format then
                local Success, Formatted = pcall(Options.FormatValue or Options.Format, self.Value)
                ValueText.Text = Success and tostring(Formatted) or tostring(self.Value)
            else
                ValueText.Text = string.format("%." .. Decimals .. "f", self.Value) .. (Options.Suffix or "")
            end
        end
        function Element:Validate(Value)
            return IsFinite(Value) and Value >= Minimum and Value <= Maximum,
                "Slider value is outside its range"
        end
        function Element:Set(Value, SetOptions)
            assert(IsFinite(Value), "Slider:Set expects a finite number")
            local NextValue = Quantize(Value)
            local HasChanged = self.Value ~= NextValue
            self.Value = NextValue
            self:Render(SetOptions and SetOptions.RawAlpha)
            if HasChanged then
                EmitChanged(Context, Options.Callback, NextValue, SetOptions)
            end
            return self
        end
        Element:Set(IsFinite(Options.Default) and Options.Default or Minimum, { Silent = true })
        Context.Input:Drag(Scope, Hitbox, function(Position, Phase)
            if Element.Disabled then
                return
            end
            if Phase == "End" then
                Element:Render()
                return
            end
            local Alpha =
                math.clamp((Position.X - Track.AbsolutePosition.X) / math.max(1, Track.AbsoluteSize.X), 0, 1)
            Element:Set(Minimum + Alpha * Range, { RawAlpha = Alpha })
        end)
        Context:Connect(Row.InputBegan, function(Input)
            if Element.Disabled then
                return
            end
            if Input.KeyCode == Enum.KeyCode.Left then
                Element:Set(Element.Value - Increment)
            elseif Input.KeyCode == Enum.KeyCode.Right then
                Element:Set(Element.Value + Increment)
            end
        end, Scope)
        Context:Register(Element, Options, "Slider", Scope)
        return Element
    end

    local function NormalizeOptions(RawOptions)
        local Result, Seen = {}, {}
        for _, Item in ipairs(RawOptions or {}) do
            local Value, Name, Disabled
            if type(Item) == "table" then
                Value = Item.Value
                if Value == nil then
                    Value = Item.Name or Item.Label
                end
                Name = Item.Name or Item.Label or tostring(Value)
                Disabled = Item.Disabled == true
            else
                Value, Name = Item, tostring(Item)
            end
            if
                (type(Value) == "string" or IsFinite(Value) or type(Value) == "boolean") and not Seen[Value]
            then
                Seen[Value] = true
                table.insert(Result, { Name = tostring(Name), Value = Value, Disabled = Disabled })
            end
        end
        return Result
    end

    local function CreateDropdown(Section, Options, Multiple)
        Options = Options or {}
        local Kind = Multiple and "MultiDropdown" or "Dropdown"
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, Kind, 47)
        Label.Size = UDim2.new(1, 0, 0, 17)
        local Field = Row.RealDropdownOutline
        local Inner = Field.RealDropdown
        local Summary = Inner.Value
        Summary.AutomaticSize = Enum.AutomaticSize.None
        Summary.AnchorPoint = Vector2.new(0, 0.5)
        Summary.Size = UDim2.new(1, -34, 1, 0)
        Summary.TextTruncate = Enum.TextTruncate.AtEnd
        local Arrow = Icons.Draw(
            Context,
            Inner,
            "Chevron",
            { Position = UDim2.new(1, -19, 0.5, -6), Size = UDim2.fromOffset(12, 12), Thickness = 1.2 },
            "InactiveTab",
            Scope
        )
        Context:Hover(Inner, Scope, "Raised", "Hover")
        Element.Field = Field
        Element.RequiredOne = Options.RequiredOne == true
            or Options.RequiresOne == true
            or Options.Required == true
        Element.RawItems = Options.Options or Options.Values or {}
        Element.Items = NormalizeOptions(Element.RawItems)
        Element.Value = Multiple and {} or nil
        local PopupRefresh
        local ActivePopupScope
        local function FindOption(Value)
            for _, Item in ipairs(Element.Items) do
                if Item.Value == Value then
                    return Item
                end
            end
            return nil
        end
        local function IsSelected(Value)
            return Multiple and table.find(Element.Value, Value) ~= nil
                or not Multiple and Element.Value == Value
        end
        function Element:Render()
            local Names = {}
            if Multiple then
                for _, Value in ipairs(self.Value) do
                    local Item = FindOption(Value)
                    if Item then
                        table.insert(Names, Item.Name)
                    end
                end
            else
                local Item = FindOption(self.Value)
                if Item then
                    table.insert(Names, Item.Name)
                end
            end
            Summary.Text = #Names > 0 and table.concat(Names, ", ") or (Options.Placeholder or "Select")
            if PopupRefresh then
                PopupRefresh()
            end
        end
        function Element:Validate(Value)
            if Multiple then
                if type(Value) ~= "table" then
                    return false, "MultiDropdown requires an array"
                end
                if Element.RequiredOne and #Element.Items > 0 and #Value == 0 then
                    return false, "At least one option is required"
                end
                local Seen = {}
                for Key, Item in pairs(Value) do
                    if
                        type(Key) ~= "number"
                        or Key < 1
                        or Key % 1 ~= 0
                        or Key > #Value
                        or not FindOption(Item)
                        or Seen[Item]
                    then
                        return false, "MultiDropdown has an unknown or duplicate option"
                    end
                    Seen[Item] = true
                end
                return true
            end
            return (Value == nil and (not Element.RequiredOne or #Element.Items == 0))
                or FindOption(Value) ~= nil,
                "Dropdown requires a valid option"
        end
        function Element:Get()
            return Multiple and CloneArray(self.Value) or self.Value
        end
        function Element:Set(Value, SetOptions)
            local Valid, Reason = self:Validate(Value)
            assert(Valid, Reason)
            local HasChanged = false
            if Multiple then
                HasChanged = #Value ~= #self.Value
                if not HasChanged then
                    for Index, Item in ipairs(Value) do
                        if Item ~= self.Value[Index] then
                            HasChanged = true
                            break
                        end
                    end
                end
                self.Value = CloneArray(Value)
            else
                HasChanged = Value ~= self.Value
                self.Value = Value
            end
            self:Render()
            if HasChanged then
                EmitChanged(Context, Options.Callback, self:Get(), SetOptions)
            end
            return self
        end
        function Element:ClosePopup()
            PopupRefresh = nil
            ActivePopupScope = nil
            if self.Popup then
                self.Popup.Close()
                self.Popup = nil
            end
            if Scope.Alive then
                Context:Tween(Arrow, "Popup", { Rotation = 0 }, Scope)
            end
        end
        function Element:Open()
            if self.Disabled then
                return self
            end
            self:ClosePopup()
            local Searchable = Options.Searchable ~= false
            local Header = Searchable and 34 or 0
            local Height = math.min(198, math.max(33, #self.Items * 25 + 8) + Header)
            local WindowScale = Context.Window and Context.Window:GetScale() or 1
            local PopupWidth = Options.PopupWidth
                or math.max(140, Field.AbsoluteSize.X / math.max(0.1, WindowScale))
            self.Popup = Context:Popup(
                Field,
                Vector2.new(PopupWidth, Height),
                function(Frame, PopupScope, Close)
                    ActivePopupScope = PopupScope
                    Context:Corner(Frame, 5)
                    local Scroller = Context:Create("ScrollingFrame", {
                        Parent = Frame,
                        Position = UDim2.fromOffset(4, 4 + Header),
                        Size = UDim2.new(1, -8, 1, -8 - Header),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 2,
                        CanvasSize = UDim2.new(),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                    }, { ScrollBarImageColor3 = "Accent" }, PopupScope)
                    Context:Create(
                        "UIListLayout",
                        { Parent = Scroller, SortOrder = Enum.SortOrder.LayoutOrder },
                        nil,
                        PopupScope
                    )
                    local Rendered = {}
                    for Index, Item in ipairs(self.Items) do
                        local OptionRow = Context:Create("TextButton", {
                            Parent = Scroller,
                            Size = UDim2.new(1, 0, 0, 25),
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false,
                            LayoutOrder = Index,
                            BackgroundTransparency = 1,
                        }, { BackgroundColor3 = "Hover" }, PopupScope)
                        Context:Corner(OptionRow, 2)
                        local OptionLabel = Context:Text(OptionRow, Item.Name, {
                            Position = UDim2.fromOffset(5, 0),
                            Size = UDim2.new(1, -10, 1, 0),
                            TextTransparency = Item.Disabled and 0.55 or 0,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                        }, PopupScope)
                        Context:Bind(OptionLabel, "Font", "Font", PopupScope)
                        Context:Bind(OptionLabel, "TextSize", "TextSize", PopupScope)
                        Context:Bind(OptionLabel, "TextColor3", function(Theme)
                            return IsSelected(Item.Value) and Theme.Accent or Theme.Text
                        end, PopupScope)
                        Context:Connect(OptionRow.MouseEnter, function()
                            if not Item.Disabled then
                                Context:Tween(
                                    OptionRow,
                                    "Hover",
                                    { BackgroundTransparency = 0.65 },
                                    PopupScope
                                )
                            end
                        end, PopupScope)
                        Context:Connect(OptionRow.MouseLeave, function()
                            Context:Tween(OptionRow, "Hover", { BackgroundTransparency = 1 }, PopupScope)
                        end, PopupScope)
                        Context:Connect(OptionRow.Activated, function()
                            if Item.Disabled or Element.Disabled then
                                return
                            end

                            if Multiple then
                                local NextValue = CloneArray(Element.Value)
                                local SelectedIndex = table.find(NextValue, Item.Value)
                                if SelectedIndex then
                                    if Element.RequiredOne and #NextValue == 1 then
                                        return
                                    end
                                    table.remove(NextValue, SelectedIndex)
                                else
                                    table.insert(NextValue, Item.Value)
                                end
                                Element:Set(NextValue)
                            else
                                Element:Set(Item.Value)
                                Close()
                            end
                        end, PopupScope)
                        table.insert(Rendered, { Row = OptionRow, Label = OptionLabel, Item = Item })
                    end
                    local Empty = Context:Text(Scroller, #self.Items == 0 and "No options" or "No matches", {
                        Name = "EmptyState",
                        Size = UDim2.new(1, 0, 0, 25),
                        LayoutOrder = #self.Items + 1,
                        Visible = #self.Items == 0,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    }, PopupScope)
                    Context:Create("UIPadding", {
                        Parent = Empty,
                        PaddingLeft = UDim.new(0, 5),
                        PaddingRight = UDim.new(0, 5),
                    }, nil, PopupScope)
                    Context:Bind(Empty, "TextColor3", "SubText", PopupScope)
                    if Searchable then
                        local Search = Context:Create("TextBox", {
                            Name = "Search",
                            Parent = Frame,
                            Position = UDim2.fromOffset(9, 6),
                            Size = UDim2.new(1, -18, 0, 25),
                            BackgroundTransparency = 1,
                            Text = "",
                            PlaceholderText = "Search options…",
                            ClearTextOnFocus = false,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        }, {
                            TextColor3 = "Text",
                            PlaceholderColor3 = "SubText",
                            Font = "Font",
                            TextSize = "TextSize",
                        }, PopupScope)
                        Context:Connect(Search:GetPropertyChangedSignal("Text"), function()
                            local Query, Count = Search.Text:lower(), 0
                            for _, Entry in ipairs(Rendered) do
                                Entry.Row.Visible = string.find(Entry.Item.Name:lower(), Query, 1, true)
                                    ~= nil
                                if Entry.Row.Visible then
                                    Count += 1
                                end
                            end
                            Empty.Visible = Count == 0
                            Scroller.CanvasPosition = Vector2.zero
                        end, PopupScope)
                    end
                    PopupRefresh = function()
                        if not PopupScope.Alive then
                            return
                        end
                        for _, Entry in ipairs(Rendered) do
                            local Active = IsSelected(Entry.Item.Value)
                            Context:Tween(Entry.Label, "Toggle", {
                                TextColor3 = Active and Context.Theme.Values.Accent
                                    or Context.Theme.Values.Text,
                            }, PopupScope)
                        end
                    end
                    PopupScope:Add(function()
                        if ActivePopupScope ~= PopupScope then
                            return
                        end
                        ActivePopupScope = nil
                        PopupRefresh = nil
                        if Scope.Alive then
                            Context:Tween(Arrow, "Popup", { Rotation = 0 }, Scope)
                        end
                    end)
                    PopupRefresh()
                end,
                Scope,
                {
                    Kind = "Dropdown",
                    OnClose = function(Popup)
                        if self.Popup ~= Popup then
                            return
                        end
                        self.Popup, PopupRefresh, ActivePopupScope = nil, nil, nil
                        if Scope.Alive then
                            Context:Tween(Arrow, "Popup", { Rotation = 0 }, Scope)
                        end
                    end,
                }
            )
            Context:Tween(Arrow, "Popup", { Rotation = 180 }, Scope)

            return self
        end
        function Element:Refresh(Items, Preserve, SetOptions)
            self:ClosePopup()
            if Items ~= nil then
                self.RawItems = Items
            end
            self.Items = NormalizeOptions(self.RawItems)
            if Multiple then
                local Retained = {}
                if Preserve ~= false then
                    for _, Value in ipairs(self.Value) do
                        if FindOption(Value) then
                            table.insert(Retained, Value)
                        end
                    end
                end
                if self.RequiredOne and #Retained == 0 and #self.Items > 0 then
                    Retained = { self.Items[1].Value }
                end
                self:Set(Retained, SetOptions)
            else
                local Retained
                if Preserve ~= false and FindOption(self.Value) then
                    Retained = self.Value
                end
                if Retained == nil and self.RequiredOne and #self.Items > 0 then
                    Retained = self.Items[1].Value
                end
                self:Set(Retained, SetOptions)
            end
            return self
        end
        function Element:SetOptions(Items, SetOptions)
            return self:Refresh(Items, true, SetOptions)
        end
        function Element:GetOptions()
            return table.clone(self.RawItems)
        end
        if Options.Default ~= nil then
            Element:Set(Options.Default, { Silent = true })
        elseif Element.RequiredOne and #Element.Items > 0 then
            Element:Set(Multiple and { Element.Items[1].Value } or Element.Items[1].Value, { Silent = true })
        else
            Element:Render()
        end
        Context:Connect(Inner.Activated, function()
            if Element.Popup and Element.Popup.Scope and Element.Popup.Scope.Alive then
                Element:ClosePopup()
            else
                Element:Open()
            end
        end, Scope)
        Context:Register(Element, Options, Kind, Scope)
        return Element
    end

    function Factory.Dropdown(Section, Options)
        return CreateDropdown(Section, Options, false)
    end
    function Factory.MultiDropdown(Section, Options)
        return CreateDropdown(Section, Options, true)
    end

    function Factory.Textbox(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label =
            CreateBase(Section, Options, "Textbox", Options.Multiline and 85 or 47, false)
        Label.Size = UDim2.new(1, 0, 0, 17)
        local Focused = false
        local Entry = Context:Create("TextBox", {
            Name = "Input",
            Parent = Row,
            AnchorPoint = Vector2.zero,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 1, -22),
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            Text = "",
            PlaceholderText = Options.Placeholder or "Enter text…",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            MultiLine = Options.Multiline == true,
            TextWrapped = Options.Multiline == true,
            TextEditable = not Element.Disabled,
        }, {
            TextColor3 = function(Theme)
                return Element.Disabled and Theme.SubText or Theme.Text
            end,
            PlaceholderColor3 = "SubText",
            BackgroundColor3 = "Raised",
            Font = "Font",
            TextSize = "TextSize",
        }, Scope)
        Context:Corner(Entry, 4)
        Context:Gradient(Entry, Scope)
        Context:Bind(Entry, "TextSize", function(Theme)
            return math.max(9, Theme.TextSize - 1)
        end, Scope)
        Context:Create(
            "UIPadding",
            { Parent = Entry, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) },
            nil,
            Scope
        )
        Element.Input = Entry
        local Writing = false
        local MaxLength = IsFinite(Options.MaxLength) and math.max(0, math.floor(Options.MaxLength)) or nil
        function Element:Validate(Value)
            return type(Value) == "string" and (not MaxLength or #Value <= MaxLength),
                "Textbox requires a string within MaxLength"
        end
        function Element:Render()
            Entry.TextEditable = not self.Disabled
        end
        function Element:Set(Value, SetOptions)
            assert(type(Value) == "string", "Textbox:Set expects a string")
            if MaxLength then
                Value = Value:sub(1, MaxLength)
            end
            local HasChanged = self.Value ~= Value
            self.Value = Value
            Writing = true
            if Entry.Text ~= Value then
                Entry.Text = Value
            end
            Writing = false
            if HasChanged then
                EmitChanged(Context, Options.Callback, Value, SetOptions)
            end
            return self
        end
        Element:Set(Options.Default or "", { Silent = true })
        Context:Connect(Entry.Focused, function()
            if Element.Disabled then
                Entry:ReleaseFocus()
                return
            end
            Focused = true
            Entry.TextXAlignment = Enum.TextXAlignment.Left
            Context:Tween(
                Entry,
                "Hover",
                { BackgroundTransparency = 0.6, TextColor3 = Context.Theme.Values.Text },
                Scope
            )
        end, Scope)
        Context:Connect(Entry.FocusLost, function(EnterPressed)
            Focused = false
            Entry.TextXAlignment = Enum.TextXAlignment.Left
            Context:Tween(Entry, "Hover", {
                BackgroundTransparency = 0,
                TextColor3 = Element.Disabled and Context.Theme.Values.SubText or Context.Theme.Values.Text,
            }, Scope)

            if not Element.Disabled then
                Element:Set(Entry.Text)
                if EnterPressed then
                    Context:Callback(Options.OnSubmit, Element.Value)
                end
            end
        end, Scope)
        Context:Connect(Entry:GetPropertyChangedSignal("Text"), function()
            if Writing or Element.Disabled then
                return
            end
            if MaxLength and #Entry.Text > MaxLength then
                Writing = true
                Entry.Text = Entry.Text:sub(1, MaxLength)
                Writing = false
            end
            if Options.Live then
                Element:Set(Entry.Text)
            end
        end, Scope)
        Context:Register(Element, Options, "Textbox", Scope)
        return Element
    end

    function Factory.Keybind(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "Keybind")
        Label.Size = UDim2.new(1, -70, 1, 0)
        local KeyText = CreateValueLabel(Context, Row, Scope, 62)
        KeyText.Position = UDim2.new(1, 0, 0.5, 0)
        KeyText.AnchorPoint = Vector2.new(1, 0.5)
        KeyText.Size = UDim2.fromOffset(62, 20)
        KeyText.TextXAlignment = Enum.TextXAlignment.Center
        KeyText.TextTruncate = Enum.TextTruncate.AtEnd
        Context:Bind(KeyText, "TextColor3", "Text", Scope)
        KeyText.BackgroundTransparency = 0
        Context:Bind(KeyText, "BackgroundColor3", "Raised", Scope)
        Context:Corner(KeyText, 4)
        local Manager = Context.Library.KeybindManager
        Element.Id = Manager:RegisterElement(Element, Element.Id, Scope)
        Element.Active = false
        function Element:OnBindingChanged(Active, Key, SetOptions)
            self.Active = Active
            if not IsSilent(SetOptions) then
                Context:Callback(Options.Callback, Active, Key)
            end
        end
        local BindingOptions = table.clone(Options)
        BindingOptions.Mode = Options.Mode or "Hold"
        BindingOptions.Callback = nil
        BindingOptions.Silent = true
        Element.Keybind = Manager:Attach(Element, BindingOptions)
        local function EnsureBinding()
            return Manager:Get(Element) or Manager:Attach(Element, BindingOptions)
        end
        function Element:Render()
            local Binding = Manager:Get(self)
            KeyText.Text = Binding and (Binding.Capturing and "Press a key…" or Binding.DisplayKey)
                or "None"
            self.Value = Binding and Binding:GetKey() or Enum.KeyCode.Unknown
            self.Mode = Binding and Binding:GetMode() or BindingOptions.Mode
        end
        function Element:Validate(Value)
            return IsValidBinding(Value), "Keybind requires a key or mouse button"
        end
        function Element:Set(Value, SetOptions)
            local Accepted, Reason = EnsureBinding():SetKey(Value, SetOptions)
            assert(Accepted ~= false, Reason)
            self:Render()
            return self
        end
        function Element:Get()
            local Binding = Manager:Get(self)
            return Binding and Binding:GetKey() or Enum.KeyCode.Unknown
        end
        function Element:IsActive()
            local Binding = Manager:Get(self)
            return Binding ~= nil and Binding:IsActive()
        end
        Element.SetKey, Element.GetKey = Element.Set, Element.Get
        function Element:GetMode()
            local Binding = Manager:Get(self)
            return Binding and Binding:GetMode() or BindingOptions.Mode
        end
        function Element:SetMode(Mode, SetOptions)
            local Accepted, Reason = EnsureBinding():SetMode(Mode, SetOptions)
            assert(Accepted ~= false, Reason)
            self:Render()
            return self
        end
        function Element:Capture()
            if not self.Disabled then
                EnsureBinding():Capture(nil, Scope)
            end
            return self
        end
        function Element:CancelCapture()
            local Binding = Manager:Get(self)
            if Binding then
                Binding:CancelCapture()
            end
            return self
        end
        function Element:OnDisabled()
            Manager:NotifyElementChanged(self)
        end
        Manager:Subscribe(Scope, function(_, _, Updated)
            if Updated == nil or Updated.Element == Element then
                Element:Render()
            end
        end)
        Element:Render()
        Context:Connect(Row.Activated, function()
            Element:Capture()
        end, Scope)
        Context:Register(Element, {}, "Keybind", Scope)
        return Element
    end

    function Factory.Label(Section, Options)
        if type(Options) == "string" then
            Options = { Name = Options }
        end
        Options = Options or {}
        local Element, _, Row, _, Label = CreateBase(Section, Options, "Label", Options.Height or 24, false)
        Row.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.TextWrapped = Options.Wrapped == true
        function Element:Set(Value)
            self.Value = tostring(Value)
            Label.Text = self.Value
            return self
        end
        Element:Set(Options.Text or Options.Name or "Label")
        return Element
    end

    function Factory.Paragraph(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "Paragraph", 62, false)
        Label.Position = UDim2.fromOffset(0, 0)
        Label.Size = UDim2.new(1, 0, 0, 18)
        local Body = Context:Text(Row, "", {
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 0, 30),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, Scope)
        Context:Bind(Body, "TextColor3", "SubText", Scope)
        Context:Bind(Body, "Font", "Font", Scope)
        Context:Bind(Body, "TextSize", "TextSize", Scope)
        local MeasureVersion = 0
        local function Measure()
            MeasureVersion += 1
            local Version = MeasureVersion
            local WindowScale = Context.Window and Context.Window:GetScale() or 1
            local Width = math.max(80, Row.AbsoluteSize.X / math.max(0.1, WindowScale))
            local Bounds = MeasureText(Element.Value or "", Body, Width)
            if not Scope.Alive or Version ~= MeasureVersion then
                return
            end
            local Height = math.max(17, Bounds.Y + 2)
            Body.Size = UDim2.new(1, 0, 0, Height)
            Row.Size = UDim2.new(1, 0, 0, math.max(Options.Height or 0, Height + 24))
        end
        function Element:Set(Value, Title)
            self.Value = tostring(Value)
            Body.Text = self.Value
            if Title then
                self.Name = tostring(Title)
                Label.Text = self.Name
            end
            Measure()
            return self
        end
        Element:Set(Options.Content or Options.Text or "")
        Context:Connect(Row:GetPropertyChangedSignal("AbsoluteSize"), Measure, Scope)
        Context:Connect(Body:GetPropertyChangedSignal("TextSize"), Measure, Scope)
        Context:Connect(Body:GetPropertyChangedSignal("FontFace"), Measure, Scope)
        return Element
    end

    function Factory.Divider(Section, Options)
        if type(Options) == "string" then
            Options = { Name = Options }
        end
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "Divider", 18, false)
        Row.BackgroundTransparency = 1
        Context:Create("Frame", {
            Parent = Row,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.3,
        }, { BackgroundColor3 = "Border" }, Scope)
        Label.BackgroundTransparency = 0
        Context:Bind(Label, "BackgroundColor3", "Surface", Scope)
        Context:Bind(Label, "TextColor3", "SubText", Scope)
        Context:Bind(Label, "TextSize", function(Theme)
            return math.max(9, Theme.TextSize - 1)
        end, Scope)
        function Element:Set(Value)
            self.Value = tostring(Value or "")
            Label.Text = self.Value
            Label.Visible = self.Value ~= ""
            local Current = self.Value
            local Width = MeasureText(Current, Label, 1000).X + 9
            if not Scope.Alive or self.Value ~= Current then
                return self
            end
            Label.Size = UDim2.fromOffset(Width, 18)
            return self
        end
        Element:Set(Options.Name or "")
        return Element
    end

    function Factory.ColorPicker(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "ColorPicker")
        Label.Size = UDim2.new(1, -42, 1, 0)
        local Text
        if Options.ShowHex then
            Label.Size = UDim2.new(1, -125, 1, 0)
            Text = CreateValueLabel(Context, Row, Scope, 78)
            Text.Position = UDim2.new(1, -34, 0, 0)
            Context:Bind(Text, "TextColor3", "SubText", Scope)
        end
        local Swatch = Context:Create("Frame", {
            Name = "Swatch",
            Parent = Row,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BorderSizePixel = 0,
        }, nil, Scope)
        Element.Swatch = Swatch
        Context:Corner(Swatch, 4)
        Context:Gradient(Swatch, Scope)
        Context:Stroke(Swatch, "Border", Scope).Transparency = 0.55
        local Picker
        Element.Animations = {}
        function Element:GetAnimations()
            return table.clone(self.Animations)
        end
        function Element:SetAnimations(Modes)
            assert(type(Modes) == "table", "Color animations must be an array")
            local Seen = {}
            for _, Mode in Modes do
                assert(
                    (Mode == "rainbow" or Mode == "breathing") and not Seen[Mode],
                    "Unknown or repeated color animation"
                )
                Seen[Mode] = true
            end
            self.Animations = table.clone(Modes)
            ColorAnimation.Set(self, self.Animations)
            if #Modes == 0 and self.BaseColor then
                self:Set(self.BaseColor, self.BaseAlpha)
            end
            return self
        end
        Scope:Add(function()
            Element.Animations = {}
            ColorAnimation.Set(Element, {})
        end)
        Element.EnableAlpha = Options.EnableAlpha ~= false
        Element.Alpha = IsFinite(Options.Alpha) and math.clamp(Options.Alpha, 0, 1) or 1
        function Element:Validate(Value)
            return typeof(Value) == "Color3", "ColorPicker requires a Color3"
        end
        function Element:Get()
            return self.Value, self.Alpha
        end
        function Element:GetAlpha()
            return self.Alpha
        end
        function Element:GetTransparency()
            return 1 - self.Alpha
        end
        function Element:Set(Value, AlphaOrOptions, SetOptions)
            assert(typeof(Value) == "Color3", "ColorPicker:Set expects a Color3")
            local Alpha = self.Alpha
            if type(AlphaOrOptions) == "number" then
                assert(IsFinite(AlphaOrOptions), "ColorPicker alpha must be finite")
                Alpha = math.clamp(AlphaOrOptions, 0, 1)
            else
                SetOptions = AlphaOrOptions
            end
            local HasChanged = self.Value ~= Value or self.Alpha ~= Alpha
            self.Value = Value
            self.Alpha = Alpha
            if not (SetOptions and SetOptions.AnimationTick) then
                self.BaseColor, self.BaseAlpha = Value, Alpha
            end
            if Text then
                Text.Text = Color.Hex(Value)
            end
            Context:Tween(
                Swatch,
                "Slider",
                { BackgroundColor3 = Value, BackgroundTransparency = self.EnableAlpha and 1 - Alpha or 0 },
                Scope
            )
            if Picker then
                Picker:Set(Value, Alpha)
            end
            if HasChanged and not IsSilent(SetOptions) then
                Context:Callback(Options.Callback, Value, Alpha)
            end
            return self
        end
        function Element:SetAlpha(Value, SetOptions)
            assert(IsFinite(Value), "ColorPicker alpha must be finite")
            return self:Set(self.Value, Value, SetOptions)
        end
        function Element:SetTransparency(Value, SetOptions)
            assert(IsFinite(Value), "ColorPicker transparency must be finite")
            return self:SetAlpha(1 - Value, SetOptions)
        end
        function Element:GetHex(IncludeAlpha)
            return Color.Hex(self.Value, IncludeAlpha and self.Alpha or nil)
        end
        function Element:SetHex(Value, SetOptions)
            local Parsed, Alpha = Color.FromHex(Value)
            assert(Parsed, "ColorPicker HEX requires 3, 4, 6 or 8 hexadecimal digits")
            return self:Set(Parsed, Alpha or self.Alpha, SetOptions)
        end
        function Element:GetRGB()
            return math.round(self.Value.R * 255),
                math.round(self.Value.G * 255),
                math.round(self.Value.B * 255)
        end
        function Element:SetRGB(Red, Green, Blue, SetOptions)
            assert(
                IsFinite(Red) and IsFinite(Green) and IsFinite(Blue),
                "ColorPicker RGB requires finite channels"
            )
            return self:Set(
                Color3.fromRGB(math.clamp(Red, 0, 255), math.clamp(Green, 0, 255), math.clamp(Blue, 0, 255)),
                SetOptions
            )
        end
        function Element:GetState()
            return {
                Color = self.BaseColor or self.Value,
                Alpha = self.BaseAlpha or self.Alpha,
                Animations = self:GetAnimations(),
            }
        end
        function Element:ValidateState(Value)
            return type(Value) == "table"
                and typeof(Value.Color) == "Color3"
                and IsFinite(Value.Alpha)
                and Value.Alpha >= 0
                and Value.Alpha <= 1,
                "ColorPicker state requires Color3 Color and Alpha from 0 to 1"
        end
        function Element:SetState(Value, SetOptions)
            assert(self:ValidateState(Value), "Invalid ColorPicker state")
            self:Set(Value.Color, Value.Alpha, SetOptions)
            self:SetAnimations(Value.Animations or {})
            return self
        end
        function Element:ClosePopup()
            if Picker then
                Picker:Close()
                Picker = nil
            end
        end
        function Element:Open()
            if self.Disabled then
                return self
            end
            self:ClosePopup()
            local PickerOptions = table.clone(Options)
            PickerOptions.Alpha, PickerOptions.EnableAlpha = self.Alpha, self.EnableAlpha
            PickerOptions.BuildAnimations = function(Frame, PopupScope)
                local ChildContext = RenderContext.New(Context.Library, PopupScope)
                ChildContext.Window, ChildContext.Tab = Context.Window, Element.Tab
                local Holder = {
                    Context = ChildContext,
                    Scope = PopupScope,
                    Controls = {},
                    NextOrder = 0,
                    NoSeparators = true,
                    Tab = Element.Tab,
                }
                Holder.Content = Context:Create(
                    "Frame",
                    {
                        Name = "Animations",
                        Parent = Frame,
                        Position = UDim2.fromOffset(8, 257),
                        Size = UDim2.new(1, -16, 0, 47),
                        BackgroundTransparency = 1,
                    },
                    nil,
                    PopupScope
                )
                Factory.MultiDropdown(Holder, {
                    Name = "Animations",
                    Options = { "rainbow", "breathing" },
                    Default = self:GetAnimations(),
                    Searchable = false,
                    Callback = function(Modes)
                        self:SetAnimations(Modes)
                    end,
                })
            end
            Picker = Color.Open(Context, Swatch, Scope, self.Value, function(Value, Alpha)
                self:Set(Value, Alpha)
            end, PickerOptions)
            self.Picker = Picker

            return self
        end
        Element:Set(Options.Default or Context.Theme.Values.Accent, { Silent = true })
        Context:Connect(Row.Activated, function()
            if Picker and Picker.Scope and Picker.Scope.Alive then
                Element:ClosePopup()
            else
                Element:Open()
            end
        end, Scope)
        do
            local Adapter = {}
            function Adapter:Get()
                return Element:GetState()
            end
            function Adapter:Validate(Value)
                return Element:ValidateState(Value)
            end
            function Adapter:Set(Value, SetOptions)
                Element:SetState(Value, SetOptions)
                return self
            end
            if Options.Id or Options.Flag then
                Scope:Add(Context.Config:Register(tostring(Options.Id or Options.Flag), Adapter, "State"))
            end
            Context:Register(Element, {}, "ColorPicker", Scope)
        end
        return Element
    end

    function Factory.Progress(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope = CreateBase(Section, Options, "Progress", 27, false)
        local ValueText = CreateValueLabel(Context, Row, Scope, 80)
        local Fill = Context:Create("Frame", {
            Name = "Fill",
            Parent = Row,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromOffset(0, 2),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.15,
            ZIndex = Row.ZIndex + 1,
        }, { BackgroundColor3 = "Accent" }, Scope)
        Context:Corner(Fill, 1)
        function Element:Validate(Value)
            return IsFinite(Value) and Value >= 0 and Value <= 1, "Progress expects a value from 0 to 1"
        end
        function Element:Set(Value, SetOptions)
            assert(IsFinite(Value), "Progress:Set expects a finite number")
            local NextValue = math.clamp(Value, 0, 1)
            local HasChanged = NextValue ~= self.Value
            self.Value = NextValue
            Context:Tween(Fill, "Page", { Size = UDim2.new(NextValue, 0, 0, 2) }, Scope)
            ValueText.Text = string.format("%d%%", math.round(NextValue * 100))
            if HasChanged then
                EmitChanged(Context, Options.Callback, NextValue, SetOptions)
            end
            return self
        end
        Element:Set(Options.Default or 0, { Silent = true })
        return Element
    end

    function Factory.ButtonGroup(Section, Options)
        Options = Options or {}
        local Element, Context, Row, Scope, Label = CreateBase(Section, Options, "ButtonGroup", 26, false)
        Label.Visible = false
        local Items = Options.Buttons or {}
        assert(#Items > 0, "AddButtons requires a nonempty Buttons array")
        local Group = {
            Context = Context,
            Scope = Scope,
            Content = Row,
            Controls = {},
            NoSeparators = true,
            NextOrder = 0,
            Tab = Section.Tab,
        }
        Element.Buttons = {}
        for Index, Item in Items do
            local Button = Factory.Button(Group, Item)
            Button.Instance.Size = UDim2.new(1 / #Items, -6 * (#Items - 1) / #Items, 1, 0)
            Button.Instance.Position = UDim2.new((Index - 1) / #Items, 6 * (Index - 1) / #Items, 0, 0)
            table.insert(Element.Buttons, Button)
        end
        function Element:Click(Index)
            self.Buttons[Index or 1]:Click()
            return self
        end
        return Element
    end

    Factory.RangeSlider = RangeSliderComponent(CreateBase)
    Factory.List = ListComponent(CreateBase, NormalizeOptions)

    for Name, Constructor in table.clone(Factory) do
        Factory[Name] = function(Section, Options)
            local Element = Constructor(Section, Options)
            Element._Checkbox = CreateCheckbox
            return Settings.Install(Element, Factory)
        end
    end

    Factory.TextBox = Factory.Textbox
    Factory.ProgressBar = Factory.Progress
    return Factory
end)()

-- Window/Section
local Section = (function()
    local Templates = VisualTemplates
    local Context = RenderContext
    local Factory = Components
    local Icons = Icons
    local Motion = Animation
    local Spacing = Spacing
    local Section = {}
    Section.__index = Section
    function Section.New(Tab, Options)
        if type(Options) == "string" then
            Options = { Name = Options }
        end
        Options = Options or {}
        local CleanupScope = Tab.Scope:Child()
        local RenderContext = Context.New(Tab.Window.Library, CleanupScope)
        RenderContext.Window, RenderContext.Tab = Tab.Window, Tab
        local self = setmetatable({
            Scope = CleanupScope,
            Context = RenderContext,
            Tab = Tab,
            Window = Tab.Window,
            Name = Options.Name or "Section",
            Controls = {},
            NextOrder = 0,
            Collapsed = false,
            PaddingTop = Options.PaddingTop or 10,
            PaddingBottom = Options.PaddingBottom or 8,
            FixedHeight = Options.Height,
        }, Section)
        RenderContext.Section = self
        local Column = math.clamp(Options.Column or 1, 1, #Tab.Columns)
        self.Instance = Templates.Create("Section", RenderContext, Tab.Columns[Column], CleanupScope)
        self.Instance.Name = self.Name
        self.Instance.AutomaticSize = Enum.AutomaticSize.None
        self.Instance.ClipsDescendants = true
        self.Instance.Size = UDim2.new(1, -4, 0, 80)
        self.Instance.LayoutOrder = #Tab.Sections + 1
        local Body = self.Instance.Section
        Body.AutomaticSize = Enum.AutomaticSize.None
        self.Header = Body.Top
        RenderContext:Corners(self.Header, 7, 7, 0, 0)
        self.Header.Label.Text = self.Name
        self.Content = Body.Content
        self.Content.AutomaticSize = Enum.AutomaticSize.Y
        self.Layout = self.Content.UIListLayout
        self.Layout.Padding = UDim.new(0, Options.Gap or 6)
        local HeaderInput = RenderContext:Create(
            "TextButton",
            {
                Name = "Collapse",
                Parent = self.Header,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                BackgroundTransparency = 1,
                ZIndex = 8,
            }
        )
        local function Resize()
            if not self.Scope.Alive then
                return
            end
            self.NaturalHeight = self.FixedHeight
                or math.ceil(53 + self.Layout.AbsoluteContentSize.Y / self.Window:GetScale())
            if not self.Collapsed then
                Motion.Cancel(self.Instance, "Size")
                self.Instance.Size = UDim2.new(1, -4, 0, self.NaturalHeight)
            end
        end
        CleanupScope:Connect(self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), Resize)
        CleanupScope:Connect(self.Window.Scale:GetPropertyChangedSignal("Scale"), Resize)
        CleanupScope:Connect(HeaderInput.Activated, function()
            self:SetCollapsed(not self.Collapsed)
        end)
        Resize()
        table.insert(Tab.Sections, self)
        return self
    end
    function Section:SetCollapsed(Value)
        self.Collapsed = Value == true
        self.Window.Overlay:Close()
        self.Context:Tween(self.Instance, "Popup", {
            Size = UDim2.new(
                1,
                -4,
                0,
                if self.Collapsed then 35 else self.NaturalHeight or self.FixedHeight or 80
            ),
        })
        return self
    end
    function Section:SetVisible(Value)
        self.Instance.Visible = Value == true
        return self
    end
    function Section:Destroy()
        local Index = table.find(self.Tab.Sections, self)
        if Index then
            table.remove(self.Tab.Sections, Index)
        end
        self.Scope:Destroy()
    end
    for Name, FactoryValue in
        {
            AddButton = "Button",
            AddButtons = "ButtonGroup",
            AddToggle = "Toggle",
            AddCheckbox = "Checkbox",
            AddSlider = "Slider",
            AddRangeSlider = "RangeSlider",
            AddList = "List",
            AddDropdown = "Dropdown",
            AddMultiDropdown = "MultiDropdown",
            AddTextbox = "Textbox",
            AddKeybind = "Keybind",
            AddLabel = "Label",
            AddParagraph = "Paragraph",
            AddDivider = "Divider",
            AddColorPicker = "ColorPicker",
            AddProgressBar = "Progress",
        }
    do
        Section[Name] = function(self, Options)
            if type(Options) == "string" then
                Options = { Name = Options, Text = Options }
            end
            local InstanceObject = Factory[FactoryValue](self, Options or {})
            InstanceObject.Tab, InstanceObject.Section = self.Tab, self
            self.Context:Register(
                InstanceObject,
                {},
                InstanceObject.Kind or FactoryValue,
                InstanceObject.Scope
            )
            return InstanceObject
        end
    end
    Section.AddProgress = Section.AddProgressBar
    Section.AddColorpicker = Section.AddColorPicker
    Section.AddTextBox = Section.AddTextbox
    Section.AddListbox = Section.AddList
    return Section
end)()

-- Window/Tab
local NavigationTab = (function()
    local Context = RenderContext
    local Templates = VisualTemplates
    local Section = Section
    local Tab = {}
    Tab.__index = Tab
    local Assets = {
        Sliders = "88475069824972",
        Gear = "137039251077896",
        View = "128846658670419",
        Movement = "85406268654944",
        Folder = "131339438783920",
        Palette = "128846658670419",
        Config = "131339438783920",
        Crosshair = "83974014297455",
        Bell = "128242806404957",
    }
    local function Asset(Name, Fallback)
        local Value = Assets[Name] or Name or Fallback
        return tostring(Value):find("rbxasset") and tostring(Value) or "rbxassetid://" .. tostring(Value)
    end
    function Tab.New(Window, Options, Parent)
        if type(Options) == "string" then
            Options = { Name = Options }
        end
        Options = Options or {}
        local Scope = Window.Scope:Child()
        local C = Context.New(Window.Library, Scope)
        local self = setmetatable(
            {
                Window = Window,
                Scope = Scope,
                Context = C,
                Name = Options.Name or "Tab",
                PageName = Options.PageName,
                Sections = {},
                Columns = {},
                Children = {},
                ParentTab = Parent,
                IconId = Asset(Options.Icon, Parent and "83974014297455" or "88475069824972"),
            },
            Tab
        )
        self.SideIconId = self.IconId
        C.Window, C.Tab = Window, self
        self.Content = C:Create(
            "CanvasGroup",
            {
                Name = self.Name,
                Parent = Window.BodyContent,
                Position = UDim2.fromOffset(10, 55),
                Size = UDim2.new(1, -20, 1, -65),
                BackgroundTransparency = 1,
                Visible = false,
            }
        )
        self.Instance = self.Content
        local Count = math.clamp(Options.Columns or 2, 1, 3)
        for Index = 1, Count do
            local Column = C:Create(
                "ScrollingFrame",
                {
                    Name = "Column" .. Index,
                    Parent = self.Content,
                    Size = UDim2.new(1 / Count, -10 * (Count - 1) / Count, 1, 0),
                    Position = UDim2.new((Index - 1) / Count, 10 * (Index - 1) / Count, 0, 0),
                    BackgroundTransparency = 1,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 0,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                }
            )
            C:Create(
                "UIPadding",
                {
                    Parent = Column,
                    PaddingLeft = UDim.new(0, 2),
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2),
                }
            )
            C:Create(
                "UIListLayout",
                { Parent = Column, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }
            )
            self.Columns[Index] = Column
        end
        local Root = Parent or self
        if not Parent then
            self.SideButton = Templates.Create("SideTab", C, Window.NavList, Scope)
            self.SideButton.Name = self.Name
            self.SideButton.LayoutOrder = #Window.Tabs + 1
            self.SideButton.Inner.Icon.Image = self.IconId
            C:Connect(self.SideButton.Inner.Activated, function()
                (self.SelectedSubtab or self):Select()
            end)
            C:Tooltip(self.SideButton, self.Name, Scope)
            self.Subnav = C:Create(
                "ScrollingFrame",
                {
                    Name = self.Name .. "Pages",
                    Parent = Window.BodyContent,
                    Position = UDim2.fromOffset(10, 10),
                    Size = UDim2.new(1, -207, 0, 35),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollingDirection = Enum.ScrollingDirection.X,
                    Visible = false,
                }
            )
            C:Create(
                "UIListLayout",
                {
                    Parent = self.Subnav,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }
            )
            table.insert(Window.Tabs, self)
        else
            table.insert(Parent.Children, self)
        end
        self.Button = Templates.Create("PageTab", C, Root.Subnav, Scope)
        self.Button.Name = self.PageName or self.Name
        self.Button.AutomaticSize = Enum.AutomaticSize.None
        self.Button.Size = UDim2.fromOffset(110, 35)
        self.Button.LayoutOrder = Parent and #Parent.Children or 0
        self.Button.Inner.Label.Text = self.PageName or self.Name
        self.Button.Inner.Icon.Image = self.IconId
        local function PageTransparency()
            return Window.SelectedPage == self and 0 or 1
        end
        C:Bind(self.Button, "BackgroundTransparency", PageTransparency)
        C:Bind(self.Button.Inner, "BackgroundTransparency", PageTransparency)
        C:Bind(self.Button.Inner.Label, "TextColor3", function(T)
            return T[Window.SelectedPage == self and "Text" or "InactiveTab"]
        end)
        C:Bind(self.Button.Inner.Icon, "ImageColor3", function(T)
            return T[Window.SelectedPage == self and "Image" or "InactiveTab"]
        end)
        if self.SideButton then
            local function SideTransparency()
                return Window.SelectedTab == self and 0 or 1
            end
            C:Bind(self.SideButton, "BackgroundTransparency", SideTransparency)
            C:Bind(self.SideButton.Inner, "BackgroundTransparency", SideTransparency)
            C:Bind(self.SideButton.Inner.Icon, "ImageColor3", function(T)
                return T[Window.SelectedTab == self and "Image" or "InactiveTab"]
            end)
        end
        function self:FitLabel()
            local Width = Context.MeasureText(self.Button.Inner.Label.Text, self.Button.Inner.Label, 10000).X
            if Scope.Alive then
                self.Button.Size = UDim2.fromOffset(math.ceil(Width) + 52, 35)
            end
        end
        Scope:Connect(self.Button.Inner.Label:GetPropertyChangedSignal("Text"), function()
            self:FitLabel()
        end)
        Scope:Connect(self.Button.Inner.Label:GetPropertyChangedSignal("FontFace"), function()
            self:FitLabel()
        end)
        self:FitLabel()
        C.Theme:Subscribe(function()
            self:RenderNavigation()
        end, Scope)
        C:Connect(self.Button.Inner.Activated, function()
            self:Select()
        end)
        local function Hover(On)
            if Window.SelectedPage ~= self then
                C:Tween(
                    self.Button.Inner.Label,
                    "Hover",
                    { TextColor3 = C.Theme.Values[On and "Text" or "InactiveTab"] }
                )
            end
        end
        C:Connect(self.Button.MouseEnter, function()
            Hover(true)
        end)
        C:Connect(self.Button.MouseLeave, function()
            Hover(false)
        end)
        self:RenderNavigation(true)
        return self
    end
    function Tab:RenderNavigation(Instant)
        local C = self.Context
        local function Apply(Object, Properties)
            if Instant then
                for Key, Value in Properties do
                    Object[Key] = Value
                end
            else
                C:Tween(Object, "Tab", Properties)
            end
        end
        local Active = self.Window.SelectedPage == self
        Apply(self.Button, { BackgroundTransparency = Active and 0 or 1 })
        Apply(self.Button.Inner, { BackgroundTransparency = Active and 0 or 1 })
        Apply(self.Button.Inner.Label, { TextColor3 = C.Theme.Values[Active and "Text" or "InactiveTab"] })
        self.Button.Inner.Icon.UIGradient.Enabled = Active
        self.Button.Inner.Icon.ImageColor3 = C.Theme.Values[Active and "Image" or "InactiveTab"]
        if self.SideButton then
            local Selected = self.Window.SelectedTab == self
            Apply(self.SideButton, { BackgroundTransparency = Selected and 0 or 1 })
            Apply(self.SideButton.Inner, { BackgroundTransparency = Selected and 0 or 1 })
            self.SideButton.Inner.Icon.UIGradient.Enabled = Selected
            self.SideButton.Inner.Icon.ImageColor3 = C.Theme.Values[Selected and "Image" or "InactiveTab"]
        end
    end
    function Tab:AddPage(Options)
        assert(not self.ParentTab, "Pages cannot contain nested pages")
        if type(Options) == "string" then
            Options = { Name = Options }
        end
        Options = Options or {}
        if not self.PageName and #self.Sections == 0 and #self.Children == 0 then
            self.PageName = Options.Name or "Page"
            self.Button.Inner.Label.Text = self.PageName
            self:FitLabel()
            if Options.Icon then
                self.Button.Inner.Icon.Image = Asset(Options.Icon)
                self.IconId = Asset(Options.Icon)
            end
            if self.Window.SelectedPage == self then
                self.Window.Path.Path.SubTabText.Text = self.PageName
            end
            return self
        end
        return Tab.New(self.Window, Options, self)
    end
    Tab.AddSubTab = Tab.AddPage
    function Tab:AddSection(Options)
        return Section.New(self, Options)
    end
    function Tab:Select()
        self.Window:_SelectPage(self)
        return self
    end
    function Tab:SetVisible(Value)
        self.Hidden = Value ~= true
        self.Button.Visible = not self.Hidden
        if self.SideButton then
            self.SideButton.Visible = not self.Hidden
        end
        if self.Hidden and (self.Window.SelectedPage == self or self.Window.SelectedTab == self) then
            self.Content.Visible = false
            self.Window.SelectedPage = nil
            local Root = self.ParentTab or self
            if self.ParentTab and not Root.Hidden then
                Root:Select()
            else
                for _, Page in self.Window.Tabs do
                    if not Page.Hidden then
                        Page:Select()
                        break
                    end
                end
            end
        elseif not self.Window.SelectedPage then
            self:Select()
        end
        self.Window:_LayoutNavigation()
        return self
    end
    function Tab:Destroy()
        if not self.Scope.Alive then
            return
        end
        self:SetVisible(false)
        for _, Child in table.clone(self.Children) do
            Child:Destroy()
        end
        local List = self.ParentTab and self.ParentTab.Children or self.Window.Tabs
        local Index = table.find(List, self)
        if Index then
            table.remove(List, Index)
        end
        self.Scope:Destroy()
        self.Window:_LayoutNavigation()
    end
    return Tab
end)()

-- Window/Shell
local Window = (function()
    local Context = RenderContext
    local Compat = Compatibility
    local Templates = VisualTemplates
    local Overlay = PopupManager
    local Tab = NavigationTab
    local UIS = game:GetService("UserInputService")
    local Shell = {}
    Shell.__index = Shell
    function Shell.New(Library, Options)
        Options = Options or {}
        Library.NextWindowId = (Library.NextWindowId or 0) + 1
        local Scope = Library.Scope:Child()
        local C = Context.New(Library, Scope)
        local self = setmetatable(
            {
                Library = Library,
                Scope = Scope,
                Context = C,
                Tabs = {},
                SearchItems = {},
                IsOpen = false,
                Minimized = false,
                Destroyed = false,
                AnimationSerial = 0,
                PageSerial = 0,
                Width = Options.Width or 600,
                Height = Options.Height or 532,
                UserScale = Options.Scale or 1,
                Position = Vector2.zero,
                Keybind = Options.Keybind or Enum.KeyCode.RightShift,
                ConfigId = tostring(Options.Id or Library.NextWindowId),
            },
            Shell
        )
        C.Window = self
        for _, W in Library.Windows do
            assert(W.ConfigId ~= self.ConfigId, "Duplicate window Id: " .. self.ConfigId)
        end
        self.Gui = C:Create(
            "ScreenGui",
            {
                Name = "myhoe",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                DisplayOrder = 95,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        )
        Compat.Parent(self.Gui, Options.Parent)
        Scope:Connect(self.Gui.Destroying, function()
            self:Destroy()
        end)
        self.Screen = C:Create(
            "Frame",
            { Name = "Screen", Parent = self.Gui, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }
        )
        self.Scene = C:Create("Frame", { Name = "Scene", Parent = self.Screen, BackgroundTransparency = 1 })
        self.Scale = C:Create("UIScale", { Parent = self.Scene })
        self.Root = Templates.Create("Window", C, self.Scene, Scope)
        self.Root.AnchorPoint = Vector2.zero
        self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
        self.Root.Visible = false
        self.Root.GroupTransparency = 1
        self.Root.ClipsDescendants = true
        C:Shadow(self.Root, { Spread = 16, Strength = 0.22, Radius = 12 }, Scope)
        self.BodyContent = self.Root.Content
        self.Side = self.Root.Side
        local _, IndividualCorners = C:Corners(self.Side, 12, 0, 0, 12)
        if not IndividualCorners then
            C:Create(
                "Frame",
                {
                    Name = "InnerEdge",
                    Parent = self.Side,
                    Position = UDim2.new(1, -12, 0, 0),
                    Size = UDim2.new(0, 12, 1, 0),
                    ZIndex = 1,
                },
                { BackgroundColor3 = "Surface" }
            )
        end
        self.NavList = self.Side.Holder.Pages
        self.Path = self.BodyContent.PathOutline
        self.Path.Position = UDim2.new(1, -14, 0, 10)
        Scope:Connect(self.Path:GetPropertyChangedSignal("AbsoluteSize"), function()
            self:_LayoutHeader()
        end)
        local Logo = self.Side.Holder.LogoBackground
        C:Create(
            "Frame",
            { Name = "LogoSpace", Parent = Logo.Parent, Size = Logo.Size, LayoutOrder = -1, BackgroundTransparency = 1 }
        )
        Logo.Parent = self.Root
        Logo.AnchorPoint = Vector2.zero
        Logo.Position = UDim2.fromOffset(18, 18)
        self.Logo = Logo
        self.WindowStroke = self.Root:FindFirstChildOfClass("UIStroke")
        local Drag = C:Create(
            "TextButton",
            { Name = "Drag", Parent = Logo, Size = UDim2.fromScale(1, 1), Text = "", BackgroundTransparency = 1, ZIndex = 8 }
        )
        local HeaderDrag = C:Create(
            "TextButton",
            {
                Name = "WindowDrag",
                Parent = self.Root,
                Position = UDim2.fromOffset(82, 0),
                Size = UDim2.new(1, -82, 0, 10),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 20,
            }
        )
        self.HeaderDrag = HeaderDrag
        local Start, Origin, Moved
        local function DragWindow(Point, Phase)
            if Phase == "Begin" then
                Start, Origin, Moved = Point, self.Position, false
                self.Overlay:Close()
            elseif Phase == "Change" and Start then
                Moved = Moved or (Point - Start).Magnitude >= 4
                if Moved then
                    self:SetPosition(Origin + (Point - Start) / self:GetScale())
                end
            elseif Phase == "End" then
                Start = nil
            end
        end
        Library.Input:Drag(Scope, Drag, DragWindow)
        Library.Input:Drag(Scope, HeaderDrag, DragWindow)
        C:Connect(Drag.Activated, function()
            if self.Minimized and not Moved then
                self:Restore()
            end
        end)
        self.Overlay = Overlay.New(self)
        C:Tooltip(Logo, "Drag to move · right-click for window actions", Scope)
        C:Connect(Drag.MouseButton2Click, function()
            C:Popup(Logo, Vector2.new(118, 36), function(Frame, PopupScope, Close)
                local B = C:Create(
                    "TextButton",
                    {
                        Parent = Frame,
                        Position = UDim2.fromOffset(6, 4),
                        Size = UDim2.new(1, -12, 0, 28),
                        Text = self.Minimized and "Restore" or "Minimize",
                        TextSize = 13,
                        BackgroundTransparency = 1,
                    },
                    { TextColor3 = "Text" },
                    PopupScope
                )
                C:Hover(B, PopupScope)
                C:Connect(B.Activated, function()
                    Close()
                    self:Toggle()
                end, PopupScope)
            end, Scope)
        end)
        local Avatar = self.Side.Bottom.Avatar
        local Player = game:GetService("Players").LocalPlayer
        local Portrait = Avatar
        if not Avatar:IsA("ImageLabel") and not Avatar:IsA("ImageButton") then
            Portrait = C:Create(
                "ImageLabel",
                { Name = "Portrait", Parent = Avatar, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }
            )
            C:Corner(Portrait, 100)
        end
        Avatar.SearchBackground.ZIndex = 5
        if Player then
            Portrait.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150"
            C:Tooltip(Avatar, Player.DisplayName .. " (@" .. Player.Name .. ")", Scope)
            Scope:Delay(0, function()
                local OK, Image = pcall(
                    game:GetService("Players").GetUserThumbnailAsync,
                    game:GetService("Players"),
                    Player.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size150x150
                )
                if OK and Scope.Alive then
                    Portrait.Image = Image
                end
            end)
        end
        local Search = Avatar.SearchBackground.Search
        self.SearchPanel = C:Create(
            "CanvasGroup",
            {
                Name = "Search",
                Parent = self.Root,
                Position = UDim2.new(0, 92, 1, -44),
                Size = UDim2.new(1, -106, 0, 30),
                Visible = false,
                ZIndex = 40,
            },
            { BackgroundColor3 = "Raised" }
        )
        C:Corner(self.SearchPanel, 5)
        C:Stroke(self.SearchPanel)
        self.SearchBox = C:Create(
            "TextBox",
            {
                Name = "Input",
                Parent = self.SearchPanel,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.new(1, -16, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = "Search controls",
                ClearTextOnFocus = false,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            },
            { TextColor3 = "Text", PlaceholderColor3 = "InactiveTab" }
        )
        C:Connect(Search.Activated, function()
            self:Search()
        end)
        Scope:Connect(self.SearchBox:GetPropertyChangedSignal("Text"), function()
            self:_SearchResults()
        end)
        Scope:Connect(self.SearchBox.FocusLost, function()
            if self.SearchBox.Text == "" then
                self:_SetSearchVisible(false)
            end
        end)
        Library.Input:Listen(Scope, function(Input, Down, Processed)
            if not Down or Processed or Library.Input.Capturing then
                return
            end
            if Input.KeyCode == self.Keybind then
                self:Toggle()
            elseif Input.KeyCode == Enum.KeyCode.Escape then
                if self.Overlay.Dialog then
                    self.Overlay.Dialog.Cancel()
                else
                    self.Overlay:CloseTop()
                end
                self:_SetSearchVisible(false)
            elseif
                Input.KeyCode == Enum.KeyCode.K
                and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl))
            then
                self:Search()
            end
        end)
        Scope:Connect(self.Screen:GetPropertyChangedSignal("AbsoluteSize"), function()
            self:_Fit()
        end)
        table.insert(Library.Windows, self)
        self:_Fit()
        Scope:Delay(0, function()
            self:_Fit()
            self:Show()
        end)
        return self
    end
    function Shell:GetScale()
        return self.Scale.Scale
    end
    function Shell:_Fit()
        if self.Destroyed then
            return
        end
        local View = self.Screen.AbsoluteSize
        if View.X < 1 or View.Y < 1 then
            return
        end
        self.Scale.Scale =
            math.max(0.2, math.min(self.UserScale, (View.X - 24) / self.Width, (View.Y - 24) / self.Height))
        self.Scene.Size = UDim2.fromOffset(View.X / self:GetScale(), View.Y / self:GetScale())
        if not self.UserPosition then
            self.Position = (View / self:GetScale() - Vector2.new(self.Width, self.Height)) / 2
        end
        self:SetPosition(self.Position, true)
    end
    function Shell:SetPosition(Value, Automatic)
        if not Automatic then
            self.UserPosition = true
        end
        local View = self.Screen.AbsoluteSize / math.max(0.001, self:GetScale())
        local Width, Height =
            if self.Minimized then 45 else self.Width, if self.Minimized then 45 else self.Height
        self.Position = Vector2.new(
            math.clamp(Value.X, 8, math.max(8, View.X - Width - 8)),
            math.clamp(Value.Y, 8, math.max(8, View.Y - Height - 8))
        )
        self.Root.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
        return self
    end
    function Shell:SetScale(Value)
        self.UserScale = math.clamp(tonumber(Value) or 1, 0.35, 2)
        self:_Fit()
        return self
    end
    function Shell:_LayoutHeader()
        local Reserved = self.Path.AbsoluteSize.X / math.max(0.001, self:GetScale()) + 36
        for _, Root in self.Tabs do
            Root.Subnav.Position = UDim2.fromOffset(12, 10)
            Root.Subnav.Size = UDim2.new(1, -Reserved, 0, 35)
        end
    end
    function Shell:_LayoutNavigation()
        self:_LayoutHeader()
        for _, Root in self.Tabs do
            Root:RenderNavigation()
            for _, Page in Root.Children do
                Page:RenderNavigation()
            end
        end
    end
    function Shell:ReleaseTextFocus()
        local Box = UIS:GetFocusedTextBox()
        if Box and Box:IsDescendantOf(self.Gui) then
            Box:ReleaseFocus()
        end
    end
    function Shell:SetOpen(Value)
        return self:SetMinimized(Value ~= true)
    end
    function Shell:Show()
        return self:SetOpen(true)
    end
    function Shell:Hide()
        return self:SetOpen(false)
    end
    function Shell:Toggle()
        return self:SetMinimized(not self.Minimized)
    end
    function Shell:SetMinimized(Value)
        Value = Value == true
        if self.Destroyed or (self.IsOpen and self.Minimized == Value) then
            return self
        end
        self.Minimized = Value
        self.IsOpen = true
        self.AnimationSerial += 1
        self.Library.Input:CancelCapture()
        self.Library.Input:CancelDrag()
        self:ReleaseTextFocus()
        self:_SetSearchVisible(false)
        self.Overlay:Close()
        self.Overlay:HideTooltip()
        if self.Overlay.Dialog then
            self.Overlay.Dialog.Cancel()
        end
        self.Root.Visible = true
        self.Context:Tween(
            self.Root,
            "Window",
            {
                Size = UDim2.fromOffset(Value and 45 or self.Width, Value and 45 or self.Height),
                GroupTransparency = 0,
                BackgroundTransparency = Value and 1 or 0,
            }
        )
        self.Context:Tween(
            self.Logo,
            "Window",
            { Position = UDim2.fromOffset(Value and 0 or 18, Value and 0 or 18) }
        )
        self.BodyContent.Visible = not Value
        self.Side.Visible = not Value
        self.HeaderDrag.Visible = not Value
        self.Logo._.Visible = not Value
        if self.WindowStroke then
            self.WindowStroke.Enabled = not Value
        end
        self:SetPosition(self.Position, true)
        return self
    end
    function Shell:Minimize()
        return self:SetMinimized(true)
    end
    function Shell:Restore()
        return self:SetMinimized(false)
    end
    function Shell:AddTab(Options)
        local Page = Tab.New(self, Options)
        if not self.SelectedPage then
            Page:Select()
        end
        self:_LayoutNavigation()
        return Page
    end
    function Shell:_SelectPage(Page)
        if self.SelectedPage == Page or Page.Hidden or not Page.Scope.Alive then
            return
        end
        local Root = Page.ParentTab or Page
        if Root.Hidden then
            return
        end
        self:ReleaseTextFocus()
        self.Overlay:Close()
        self.Library.Input:CancelCapture()
        self.PageSerial += 1
        self.SelectedPage, self.SelectedTab = Page, Root
        Root.SelectedSubtab = Page
        for _, Group in self.Tabs do
            Group.Subnav.Visible = Group == Root
            for _, P in { Group, unpack(Group.Children) } do
                P.Content.Visible = P == Page
            end
        end
        Page.Content.GroupTransparency = 1
        self.Context:Tween(Page.Content, "Page", { GroupTransparency = 0 }, Page.Scope)
        self.Path.Path.TabText.Text = Root.Name
        self.Path.Path.SubTabText.Text = Page.PageName or Page.Name
        self.Path.Path.TabIcon.Image = Root.SideIconId
        self.Path.Path.SubTabIcon.Image = Page.IconId
        self:_LayoutNavigation()
    end
    function Shell:Notify(Options)
        return self.Overlay:Notify(Options)
    end
    function Shell:Confirm(Options)
        return self.Overlay:Confirm(Options)
    end
    function Shell:CreateWatermark(Options)
        return self.Hud:CreateWatermark(Options)
    end
    function Shell:SetKeybindListVisible(Value)
        self.Hud.KeybindList:SetVisible(Value)
        return self
    end
    function Shell:SetNotificationPosition(Value)
        self.Overlay:SetNotificationPosition(Value)
        return self
    end
    function Shell:_SetSearchVisible(Visible)
        self.SearchSerial = (self.SearchSerial or 0) + 1
        local Serial = self.SearchSerial
        if Visible then
            if not self.SearchPanel.Visible then
                self.SearchPanel.GroupTransparency = 1
                self.SearchPanel.Position = UDim2.new(0, 92, 1, -38)
            end
            self.SearchPanel.Visible = true
            self.Context:Tween(
                self.SearchPanel,
                TweenInfo.new(0.18, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
                { GroupTransparency = 0, Position = UDim2.new(0, 92, 1, -44) }
            )
        else
            self.Context:Tween(
                self.SearchPanel,
                "PopupClose",
                { GroupTransparency = 1, Position = UDim2.new(0, 92, 1, -38) }
            )
            self.Scope:Delay(0.15, function()
                if Serial == self.SearchSerial then
                    self.SearchPanel.Visible = false
                end
            end)
            if self.SearchPopup then
                self.SearchPopup.Close()
                self.SearchPopup = nil
            end
        end
    end
    function Shell:Search(Initial)
        self:Restore()
        self:_SetSearchVisible(true)
        if Initial ~= nil then
            self.SearchBox.Text = tostring(Initial)
        end
        self.SearchBox:CaptureFocus()
        return self.SearchBox
    end
    function Shell:_SearchResults()
        local Query = string.lower(self.SearchBox.Text):match("^%s*(.-)%s*$")
        if self.SearchPopup then
            self.SearchPopup.Close()
            self.SearchPopup = nil
        end
        if Query == "" then
            return
        end
        local Matches = {}
        for _, Record in self.SearchItems do
            local Element = Record.Control
            local Page = Record.Tab
            local Section = Record.Section or Element.Section
            local Settings = Record.SettingsOwner or Element.SettingsOwner
            local Haystack = table
                .concat({
                    Record.Name,
                    Section and Section.Name or "",
                    Page and Page.Name or "",
                    Page and Page.PageName or "",
                    Page and Page.ParentTab and Page.ParentTab.Name or "",
                    Settings and Settings.Element and Settings.Element.Name or "",
                }, " ")
                :lower()
            local Match = Element.Scope.Alive
            for Word in Query:gmatch("%S+") do
                if not Haystack:find(Word, 1, true) then
                    Match = false
                    break
                end
            end
            if Match then
                table.insert(Matches, Record)
                if #Matches >= 9 then
                    break
                end
            end
        end
        local RenderContext = self.Context
        self.SearchPopup = RenderContext:Popup(
            self.SearchBox,
            UDim2.fromOffset(260, math.max(28, #Matches * 34 + 8)),
            function(Frame, Cleanup, Close)
                if #Matches == 0 then
                    RenderContext:Text(
                        Frame,
                        "No results",
                        { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 1, 0) },
                        Cleanup
                    )
                end
                for Index, Record in Matches do
                    local Page = Record.Tab
                    local Section = Record.Section or Record.Control.Section
                    local Button = RenderContext:Create("TextButton", {
                        Name = "Result",
                        Parent = Frame,
                        Position = UDim2.fromOffset(4, 4 + (Index - 1) * 34),
                        Size = UDim2.new(1, -8, 0, 34),
                        Text = "",
                        BackgroundTransparency = 1,
                    }, { BackgroundColor3 = "Hover" }, Cleanup)
                    RenderContext:Text(
                        Button,
                        Record.Name,
                        { Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 0, 19), TextSize = 12 },
                        Cleanup
                    )
                    local Breadcrumb = RenderContext:Text(
                        Button,
                        (Page and (Page.PageName or Page.Name) or "")
                            .. (Section and " / " .. Section.Name or ""),
                        { Position = UDim2.fromOffset(5, 19), Size = UDim2.new(1, -10, 0, 12), TextSize = 10 },
                        Cleanup
                    )
                    RenderContext:Bind(Breadcrumb, "TextColor3", "InactiveTab", Cleanup)
                    Cleanup:Connect(Button.MouseEnter, function()
                        RenderContext:Tween(Button, "Hover", { BackgroundTransparency = 0 }, Cleanup)
                    end)
                    Cleanup:Connect(Button.MouseLeave, function()
                        RenderContext:Tween(Button, "Hover", { BackgroundTransparency = 1 }, Cleanup)
                    end)
                    Cleanup:Connect(Button.Activated, function()
                        if
                            self.Destroyed
                            or not Record.Control.Scope.Alive
                            or (Page and not Page.Scope.Alive)
                        then
                            return
                        end
                        Close()
                        self.SearchBox:ReleaseFocus()
                        self.SearchBox.Text = ""
                        if Page then
                            if Page.ParentTab then
                                Page.ParentTab:SetVisible(true)
                            end
                            if Page.Category then
                                Page.Category:SetVisible(true)
                            end
                            Page:SetVisible(true)
                            Page:Select()
                        end
                        local Settings = Record.SettingsOwner or Record.Control.SettingsOwner
                        local Target = Settings and Settings.Element or Record.Control
                        if Target.Section and Target.Section.SetCollapsed then
                            Target.Section:SetCollapsed(false)
                        end
                        Target:SetVisible(true)
                        Record.Control:SetVisible(true)
                        self.Scope:Delay(0.45, function()
                            if
                                self.Destroyed
                                or not self.IsOpen
                                or not Target.Scope.Alive
                                or (Page and self.SelectedPage ~= Page)
                            then
                                return
                            end
                            local Parent = Target.Instance.Parent
                            while Parent and Parent ~= self.Gui do
                                if Parent:IsA("ScrollingFrame") then
                                    Parent.CanvasPosition = Vector2.new(
                                        Parent.CanvasPosition.X,
                                        math.max(
                                            0,
                                            Parent.CanvasPosition.Y
                                                + (Target.Instance.AbsolutePosition.Y - Parent.AbsolutePosition.Y) / self:GetScale()
                                                - 5
                                        )
                                    )
                                    break
                                end
                                Parent = Parent.Parent
                            end
                            if Settings and Settings.Open then
                                Settings:Open()
                            end
                            local FocusScope = Record.Control.Scope:Child()
                            local Highlight =
                                RenderContext:Stroke(Record.Control.Instance, "Accent", FocusScope)
                            Highlight.Transparency = 0.25
                            FocusScope:Delay(0.6, function()
                                RenderContext:Tween(Highlight, "Focus", { Transparency = 1 }, FocusScope)
                                FocusScope:Delay(0.25, function()
                                    FocusScope:Destroy()
                                end)
                            end)
                        end)
                    end)
                end
            end,
            self.Scope,
            { Kind = "Search" }
        )
    end

    function Shell:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Scope:Destroy()
        local Index = table.find(self.Library.Windows, self)
        if Index then
            table.remove(self.Library.Windows, Index)
        end
        self.Library:_UpdateReferences()
    end
    return Shell
end)()

-- Library
local MyhoeSession = (function()
    local ConnectionManager = ConnectionManager
    local Palettes = ThemePalettes
    local ThemeManager = ThemeManager
    local InputManager = InputManager
    local ConfigManager = ConfigManager
    local KeybindManager = KeybindManager
    local HudManager = HudManager
    local Window = Window
    local Spacing = Spacing

    local Library = {}
    Library.__index = Library

    function Library.New(Options)
        Options = Options or {}
        local self = setmetatable({
            Scope = ConnectionManager.New(),
            Windows = {},
            Version = "1.0.0",
            Destroyed = false,
            Spacing = Spacing,
        }, Library)
        self.Theme = ThemeManager.New(Options.Theme)
        self.Input = InputManager.New(self.Scope)
        self.Config = ConfigManager.New(Options.Config)
        self.Flags = self.Config.Flags
        self.ThemePresets = table.clone(Palettes)
        self.ThemeConfig = ConfigManager.New({ Folder = "Myhoe/Themes", Storage = self.Config.Storage })
        self.Scope:Add(self.ThemeConfig)
        self.Scope:Add(self.ThemeConfig:RegisterState("Palette", function()
            return self.Theme:GetSerializable()
        end, function(V)
            self:SetTheme(V)
        end, function(V)
            return self.Theme:Validate(V)
        end))
        self.Scope:Add(self.Config)
        self.Scope:Add(self.Theme)
        self.KeybindManager = KeybindManager.New(self)
        self.Scope:Add(self.KeybindManager)
        self.Scope:Add(self.Config:RegisterState("@Theme", function()
            return self.Theme:GetSerializable()
        end, function(Values)
            self.Theme:Set(Values)
        end, function(Values)
            return self.Theme:Validate(Values)
        end))
        return self
    end

    function Library:CreateWindow(Options)
        assert(not self.Destroyed, "This library was destroyed; use Library.New() for a new session")
        local CreatedWindow = Window.New(self, Options)
        CreatedWindow.Hud = HudManager.New(self, CreatedWindow)
        self:_UpdateReferences()
        return CreatedWindow
    end

    function Library:_UpdateReferences()
        local ActiveWindow = self.Windows[1]
        self.Keybinds = ActiveWindow and ActiveWindow.Hud and ActiveWindow.Hud.KeybindList or nil
        self.Watermark = ActiveWindow and ActiveWindow.Hud and ActiveWindow.Hud.Watermark or nil
        self.Notifications = ActiveWindow and ActiveWindow.Overlay.Notifications or nil
    end

    function Library:SetTheme(Values)
        if type(Values) == "string" then
            assert(self.ThemePresets[Values], "Unknown theme preset")
            Values = self.ThemePresets[Values]
        end
        Values = table.clone(Values)
        for Alias, Token in
            { Inline = "Surface", Element = "Raised", ["Inactive Text"] = "SubText", ["Dark Gradient"] = "DarkGradient" }
        do
            if Values[Alias] then
                Values[Token] = Values[Alias]
                Values[Alias] = nil
            end
        end
        local function Spread(Source, Targets)
            if Values[Source] then
                for _, Key in Targets do
                    if not Values[Key] then
                        Values[Key] = Values[Source]
                    end
                end
            end
        end
        Spread("Surface", { "Popup", "SectionHeader", "Sidebar" })
        Spread("Raised", { "Chip", "Track", "Unchecked" })
        Spread("SubText", { "InactiveTab", "CategoryText", "SearchIcon" })
        Spread("Text", { "HeaderText", "LogoText", "BindAccent" })
        if Values.Accent and not Values.AccentSoft then
            Values.AccentSoft = Values.Accent:Lerp(Values.Background or self.Theme.Values.Background, 0.84)
        end
        if Values.Accent and not Values.AccentMuted and not Values.SliderFill then
            Values.SliderFill = Values.Accent
        end
        if Values.Accent and not Values.BorderActive then
            Values.BorderActive = Values.Accent
        end
        self.Theme:Set(Values)
        return self
    end

    function Library:ChangeTheme(Token, Value)
        return self:SetTheme({ [Token] = Value })
    end
    function Library:GetThemePresets()
        local Names = {}
        for Name in self.ThemePresets do
            table.insert(Names, Name)
        end
        table.sort(Names)
        return Names
    end
    function Library:SaveTheme(Name)
        return self.ThemeConfig:Save(Name)
    end
    function Library:LoadTheme(Name)
        if self.ThemePresets[Name] then
            self:SetTheme(Name)
            return true
        end
        return self.ThemeConfig:Load(Name)
    end
    function Library:DeleteTheme(Name)
        return self.ThemeConfig:Delete(Name)
    end
    function Library:ListThemes()
        return self.ThemeConfig:List()
    end
    function Library:ExportTheme()
        return self.ThemeConfig:Export()
    end
    function Library:ImportTheme(Json)
        return self.ThemeConfig:Import(Json)
    end

    function Library:GetTheme()
        return table.clone(self.Theme.Values)
    end
    function Library:GetFlags()
        return self.Config:GetValues()
    end
    function Library:CreateWatermark(Options)
        assert(self.Windows[1], "Create a window before creating a watermark")
        return self.Windows[1]:CreateWatermark(Options)
    end

    function Library:SetNotificationPosition(Position)
        assert(self.Notifications, "Create a window before positioning notifications")
        self.Notifications:SetPosition(Position)
        return self
    end

    function Library:Notify(Options)
        assert(self.Windows[1], "Create a window before sending a notification")
        return self.Windows[1]:Notify(Options)
    end

    Library.CreateNotification = Library.Notify

    function Library:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        for _, CreatedWindow in table.clone(self.Windows) do
            CreatedWindow:Destroy()
        end
        self.Scope:Destroy()
        self.Keybinds, self.Watermark, self.Notifications = nil, nil, nil
        local Seen = {}
        local function ClearReference(Environment)
            if type(Environment) ~= "table" or Seen[Environment] then
                return
            end
            Seen[Environment] = true
            pcall(function()
                if Environment.MyhoeUI == self then
                    Environment.MyhoeUI = nil
                end
            end)
        end
        ClearReference(self.Environment)
        for _, Environment in self.Environments or {} do
            ClearReference(Environment)
        end
    end

    Library.Unload = Library.Destroy
    Library.new = Library.New
    return Library.New()
end)()

local Library = MyhoeSession
Library.Environment = Environment
Library.Environments = { _G, Environment }
for _, Shared in Library.Environments do
    pcall(function()
        Shared.MyhoeUI = Library
    end)
end

-- STARTUP EXAMPLE - edit this block to build your own interface.
local Showcase = true
if Showcase then
    Library.Config:SetFolder("Myhoe/Configs")
    local Window = Library:CreateWindow({
        Title = "myhoe",
        Subtitle = "v1.0",
        Id = "Main",
        Keybind = Enum.KeyCode.RightShift,
    })
    local Controls = {}
    local Main = Window:AddTab({ Name = "Main", Icon = "Sliders" })
    Main:AddPage({ Name = "Elements", Icon = "Crosshair" })
    local Tools = Window:AddTab({ Name = "Tools", Icon = "Gear" })
    Tools:AddPage({ Name = "Feedback", Icon = "Bell" })
    local Modes = Tools:AddPage({ Name = "Bindings", Icon = "Movement" })
    local Appearance = Window:AddTab({ Name = "Style", Icon = "Palette" })
    Appearance:AddPage("Theme")
    local Profiles = Window:AddTab({ Name = "Profiles", Icon = "Folder" })
    Profiles:AddPage("Storage")
    local Events = 0
    local function Changed(Name, Value)
        Events += 1
        if Controls.Status then
            Controls.Status:Set(Name .. ": " .. tostring(Value))
        end
        if Controls.Events then
            Controls.Events:Set("Changes received: " .. Events)
        end
    end
    local Elements = Main:AddSection({ Name = "Elements", Icon = "Sliders", Column = 1 })
    Controls.Checkbox = Elements:AddCheckbox({
        Name = "Checkbox",
        Flag = "Example.Checkbox",
        Default = true,
        Tooltip = "Click the square to turn this example on or off. Press B to toggle it, or click B to edit its binding.",
        Callback = function(Value)
            Changed("Checkbox", Value)
        end,
    })
    Controls.Checkbox:AddKeybind({
        Name = "Checkbox",
        Default = Enum.KeyCode.B,
        Mode = "Toggle",
        ShowInBinds = true,
    })
    Controls.Toggle = Elements:AddToggle({
        Name = "Toggle",
        Flag = "Example.Toggle",
        Default = false,
        Tooltip = "Click the switch to turn this example on or off. Click None to add a keybind, or a color swatch to change its color.",
        Callback = function(Value)
            Changed("Toggle", Value)
        end,
    })
    Controls.Toggle:AddKeybind({ Name = "Toggle", Default = Enum.KeyCode.Unknown, Mode = "Toggle" })
    Controls.Amount = Elements:AddSlider({
        Name = "Amount",
        Flag = "Example.Amount",
        Min = 0,
        Max = 100,
        Default = 65,
        Increment = 1,
        Callback = function(Value)
            if Controls.Progress then
                Controls.Progress:Set(Value / 100)
            end
            Changed("Amount", Value)
        end,
    })
    Controls.Precision = Elements:AddSlider({
        Name = "Precision",
        Flag = "Example.Precision",
        Min = -1,
        Max = 1,
        Default = 0.25,
        Increment = 0.05,
        Callback = function(Value)
            Changed("Precision", Value)
        end,
    })
    Controls.Dropdown = Elements:AddDropdown({
        Name = "Dropdown",
        Flag = "Example.Dropdown",
        Options = { "First", "Second", "Third" },
        Default = "First",
        Callback = function(Value)
            Changed("Dropdown", Value)
        end,
    })
    Controls.Multi = Elements:AddMultiDropdown({
        Name = "Multi select",
        Flag = "Example.Multi",
        Options = { "First", "Second", "Third", "Fourth" },
        Default = { "First", "Third" },
        Callback = function(Value)
            Changed("Multi select", table.concat(Value, ", "))
        end,
    })
    local More = Main:AddPage({ Name = "More", Icon = "Gear" })
    local Ranges = More:AddSection({ Name = "Ranges & text", Column = 1 })
    Controls.Range = Ranges:AddRangeSlider({
        Name = "Range",
        Flag = "Example.Range",
        Min = 0,
        Max = 100,
        Default = { 30, 60 },
        Increment = 1,
        Callback = function(Value)
            Changed("Range", Value[1] .. " - " .. Value[2])
        end,
    })
    Controls.DecimalRange = Ranges:AddRangeSlider({
        Name = "Decimals",
        Flag = "Example.DecimalRange",
        Min = -1,
        Max = 1,
        Increment = 0.05,
        Default = { -0.3, 0.6 },
        Callback = function(Value)
            Changed("Decimal range", Value[1] .. " - " .. Value[2])
        end,
    })
    Controls.TextInput = Ranges:AddTextbox({
        Name = "Text input",
        Flag = "Example.TextInput",
        Default = "Type here",
        MaxLength = 80,
        Callback = function(Value)
            Changed("Text input", Value)
        end,
    })
    Controls.Notes = Ranges:AddTextbox({
        Name = "Notes",
        Flag = "Example.Notes",
        Multiline = true,
        Placeholder = "Multiple lines",
        MaxLength = 500,
        Callback = function(Value)
            Changed("Notes", #Value .. " characters")
        end,
    })
    Controls.RangeButtons = Ranges:AddButtons({
        Buttons = {
            {
                Name = "Clear text",
                Callback = function()
                    Controls.TextInput:Set("")
                    Controls.Notes:Set("")
                end,
            },
            {
                Name = "Reset ranges",
                Callback = function()
                    Controls.Range:Set(30, 60)
                    Controls.DecimalRange:Set(-0.3, 0.6)
                end,
            },
        },
    })
    local Choices = More:AddSection({ Name = "Named options", Column = 1 })
    Controls.NamedDropdown = Choices:AddDropdown({
        Name = "Quality",
        Flag = "Example.Quality",
        Searchable = true,
        Options = {
            { Name = "Low", Value = 1 },
            { Name = "Balanced", Value = 2 },
            { Name = "High", Value = 3 },
            { Name = "Unavailable", Value = 4, Disabled = true },
        },
        Default = 2,
        Tooltip = "Display names and stored values can differ. The last option is disabled.",
        Callback = function(Value)
            Changed("Quality value", Value)
        end,
    })
    Controls.CompactDropdown = Choices:AddDropdown({
        Name = "Compact menu",
        Flag = "Example.Compact",
        Searchable = false,
        Options = { "Left", "Center", "Right" },
        Default = "Center",
        Callback = function(Value)
            Changed("Compact menu", Value)
        end,
    })
    local Lists = More:AddSection({ Name = "Lists", Column = 2 })
    Controls.List = Lists:AddList({
        Name = "Single selection",
        Flag = "Example.List",
        Options = { "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth" },
        Default = "First",
        Height = 154,
        Callback = function(Value)
            Changed("List", Value)
        end,
    })
    Controls.MultiList = Lists:AddList({
        Name = "Multiple selection",
        Flag = "Example.MultiList",
        Options = { "Red", "Blue", "Green", "Yellow", "Orange", "White" },
        Default = { "Blue", "Green" },
        Multi = true,
        Height = 154,
        Callback = function(Value)
            Changed("Multi list", table.concat(Value, ", "))
        end,
    })
    Controls.ListButtons = Lists:AddButtons({
        Buttons = {
            {
                Name = "Add options",
                Callback = function()
                    Controls.List:Refresh({
                        "First",
                        "Second",
                        "Third",
                        "Fourth",
                        "Fifth",
                        "Sixth",
                        "Seventh",
                        "Eighth",
                        "Ninth",
                        "Tenth",
                    }, true)
                    Controls.MultiList:Refresh(
                        { "Red", "Blue", "Green", "Yellow", "Orange", "White", "Black", "Violet" },
                        true
                    )
                    Library:Notify({ Text = "Both lists updated; selections preserved", Type = "Success" })
                end,
            },
            {
                Name = "Reset",
                Callback = function()
                    Controls.List:Set("First")
                    Controls.MultiList:Set({ "Blue", "Green" })
                end,
            },
        },
    })
    local Status = Main:AddSection({ Name = "Live values", Icon = "View", Column = 1 })
    Controls.Status = Status:AddLabel({ Text = "Change a control to see its value" })
    Controls.Progress = Status:AddProgress({ Name = "Amount", Default = 0.65 })
    Controls.Events = Status:AddLabel({ Text = "Changes received: 0" })

    local Bindings = Main:AddSection({ Name = "Bindings & settings", Icon = "Gear", Column = 2 })
    Controls.Custom = Bindings:AddToggle({
        Name = "Attached settings",
        Flag = "Example.Settings",
        Default = true,
        Tooltip = "Turn this example on or off. Click the gear to open its attached settings.",
        Callback = function(Value)
            Changed("Attached settings", Value)
        end,
    })
    Controls.ToggleColor = Controls.Toggle:Colorpicker({
        Name = "Toggle color",
        Flag = "Example.ToggleColor",
        Default = Color3.fromRGB(147, 181, 255),
        Alpha = 1,
        Callback = function(Value)
            Changed("Toggle color", Value:ToHex())
        end,
    })
    Controls.ToggleColor2 = Controls.Toggle:Colorpicker({
        Name = "Secondary color",
        Flag = "Example.ToggleColor2",
        Default = Color3.fromRGB(230, 160, 120),
        Alpha = 1,
        Callback = function(Value)
            Changed("Secondary color", Value:ToHex())
        end,
    })
    Controls.CheckboxColor = Controls.Checkbox:Colorpicker({
        Name = "Checkbox color",
        Flag = "Example.CheckboxColor",
        Default = Color3.fromRGB(120, 200, 180),
        Alpha = 0.8,
        Callback = function(Value)
            Changed("Checkbox color", Value:ToHex())
        end,
    })
    local Attached = Controls.Custom:Settings()
    Controls.NestedCheckbox = Attached:AddCheckbox({
        Name = "Enabled",
        Flag = "Settings.Enabled",
        Default = true,
        Tooltip = "Enable or disable this nested option. Its value is saved with your profile.",
        Callback = function(Value)
            Changed("Settings enabled", Value)
        end,
    })
    Controls.NestedSlider = Attached:AddSlider({
        Name = "Intensity",
        Flag = "Settings.Intensity",
        Min = 0,
        Max = 1,
        Increment = 0.01,
        Default = 0.5,
        Callback = function(Value)
            Changed("Intensity", Value)
        end,
    })
    Controls.NestedDropdown = Attached:AddDropdown({
        Name = "Behavior",
        Flag = "Settings.Behavior",
        Options = { "First", "Second", "Third" },
        Default = "Second",
        Callback = function(Value)
            Changed("Behavior", Value)
        end,
    })
    Controls.NestedColor = Attached:AddColorPicker({
        Name = "Color",
        Flag = "Settings.Color",
        Default = Color3.fromRGB(147, 181, 255),
        Alpha = 0.8,
        EnableAlpha = true,
        Callback = function(Value)
            Changed("Settings color", Value:ToHex())
        end,
    })
    Controls.Keybind = Bindings:AddKeybind({
        Name = "Peek",
        Flag = "Example.Keybind",
        Default = Enum.KeyCode.H,
        Mode = "Hold",
        ShowInBinds = true,
        Callback = function(Active)
            Changed("Hold binding", Active)
        end,
    })
    Bindings:AddParagraph({
        Name = "Your controls, your bindings",
        Content = "Bindings are opt-in with Toggle:AddKeybind(). Click None or a key to edit. Only attached settings add a gear.",
    })
    local Actions = Main:AddSection({ Name = "Actions", Icon = "Bell", Column = 2 })
    Controls.Message = Actions:AddTextbox({
        Name = "Message",
        Flag = "Example.Message",
        Default = "myhoe is ready",
        MaxLength = 140,
        Callback = function(Value)
            Changed("Message", Value)
        end,
    })
    Controls.Notify = Actions:AddButton({
        Name = "Send notification",
        Callback = function()
            Library:Notify({ Text = Controls.Message:Get(), Type = "Info", Duration = 3 })
        end,
    })
    Controls.Confirm = Actions:AddButton({
        Name = "Confirmation dialog",
        Callback = function()
            Window:Confirm({
                Title = "Reset the amount?",
                Description = "This sets the amount slider back to 65.",
                ConfirmText = "Reset",
                CancelText = "Cancel",
                Callback = function(Accepted)
                    if Accepted then
                        Controls.Amount:Set(65)
                        Library:Notify({ Text = "Amount reset", Type = "Success" })
                    end
                end,
            })
        end,
    })
    Controls.RefreshDropdown = Actions:AddButton({
        Name = "Refresh dropdown options",
        Callback = function()
            Controls.Dropdown:Refresh({
                "First",
                "Second",
                "Third",
                "Fourth",
                "Fifth",
                "Sixth",
                "Seventh",
                "Eighth",
                "Ninth",
                "Tenth",
                "Eleventh",
                "Twelfth",
            }, true)
            Library:Notify({ Text = "Dropdown updated with 12 searchable options", Type = "Success" })
        end,
    })

    local Feedback = Tools:AddSection({ Name = "Notifications", Icon = "Bell", Column = 1 })
    Controls.NotificationDuration = Feedback:AddSlider({
        Name = "Duration",
        Flag = "Example.NotificationDuration",
        Min = 1,
        Max = 10,
        Default = 4,
        Increment = 0.5,
        Suffix = "s",
    })
    Controls.NotificationButtons = {}
    for _, Kind in { "Info", "Success", "Warning", "Error" } do
        Controls.NotificationButtons[Kind] = Feedback:AddButton({
            Name = Kind,
            Callback = function()
                Library:Notify({
                    Text = Kind .. " · " .. Controls.Message:Get(),
                    Type = Kind,
                    Duration = Controls.NotificationDuration:Get(),
                })
            end,
        })
    end
    Feedback:AddButton({
        Name = "Show a notification stack",
        Callback = function()
            Library:Notify({ Text = "First notification", Type = "Info", Duration = 2 })
            Library:Notify({ Text = "Second notification", Type = "Success", Duration = 3 })
            Library:Notify({ Text = "Last notification", Type = "Warning", Duration = 4 })
        end,
    })
    local Navigation = Tools:AddSection({ Name = "Window & search", Icon = "View", Column = 1 })
    local function ConfirmUnload()
        Window:Confirm({
            Title = "Unload myhoe?",
            Description = "Removes the interface, bindings, and displays. Saved profiles stay available.",
            ConfirmText = "Unload",
            Callback = function(Yes)
                if Yes then
                    Library:Unload()
                end
            end,
        })
    end
    Navigation:AddButton({
        Name = "Search controls",
        Tooltip = "Search every page and jump directly to a matching control.",
        Callback = function()
            Window:Search("")
        end,
    })
    Controls.Minimize = Navigation:AddButton({
        Name = "Minimize",
        Callback = function()
            Window:Minimize()
        end,
    })
    Controls.Unload = Navigation:AddButton({
        Name = "Unload myhoe",
        Tooltip = "Remove the UI and its connections. Execute the script again to start a fresh session.",
        Callback = ConfirmUnload,
    })
    Navigation:AddParagraph({
        Name = "Restore the menu",
        Content = "RightShift minimizes or restores myhoe. Click the compact logo to restore the window. Drag the logo to move it.",
    })
    local State = Tools:AddSection({ Name = "Dynamic controls", Icon = "Sliders", Column = 2 })
    Controls.StateEnabled = State:AddCheckbox({
        Name = "Enable sample",
        Flag = "Example.StateEnabled",
        Default = true,
        Tooltip = "Allow changes to the Sample slider. Turning this off keeps its current value.",
        Callback = function(Value)
            if Controls.StateValue then
                Controls.StateValue:SetDisabled(not Value)
            end
        end,
    })
    Controls.StateVisible = State:AddCheckbox({
        Name = "Show sample",
        Flag = "Example.StateVisible",
        Default = true,
        Tooltip = "Show or hide the Sample slider without resetting its value.",
        Callback = function(Value)
            if Controls.StateValue then
                Controls.StateValue:SetVisible(Value)
            end
        end,
    })
    Controls.StateValue = State:AddSlider({
        Name = "Sample",
        Flag = "Example.StateValue",
        Min = 0,
        Max = 10,
        Default = 5,
        Increment = 0.5,
        Callback = function(Value)
            Changed("Dynamic sample", Value)
        end,
    })
    State:AddDivider({ Text = "Set / Get" })
    State:AddButtons({
        Buttons = {
            {
                Name = "Set 7.5",
                Callback = function()
                    Controls.StateValue:Set(7.5)
                end,
            },
            {
                Name = "Read value",
                Callback = function()
                    Library:Notify({ Text = "Sample = " .. Controls.StateValue:Get(), Type = "Info" })
                end,
            },
        },
    })
    State:AddParagraph({
        Name = "Shared behavior",
        Content = "Disabling a control keeps its value. Hiding it removes its row. Set updates the value, visuals, and callback.",
    })
    local Tips = Tools:AddSection({ Name = "Text & tooltips", Icon = "Crosshair", Column = 2 })
    Controls.TooltipLabel = Tips:AddLabel({
        Text = "Hover over this label",
        Tooltip = "Tooltips inherit the current theme and stay inside the viewport.",
    })
    Tips:AddDivider({ Text = "Paragraph" })
    Tips:AddParagraph({
        Name = "Everything is editable",
        Content = "Use the example at the bottom of the script to create your own tabs, sections, controls, and callbacks. Every saved control has its own flag.",
    })
    local KeyModes = Modes:AddSection({ Name = "Activation modes", Icon = "Movement", Column = 1 })
    Controls.ToggleBind = KeyModes:AddKeybind({
        Name = "Toggle action",
        Flag = "Example.ToggleBind",
        Default = Enum.KeyCode.J,
        Mode = "Toggle",
        ShowInBinds = false,
        Callback = function(Value)
            Changed("Toggle action", Value)
        end,
    })
    Controls.NotHeldBind = KeyModes:AddKeybind({
        Name = "Not held action",
        Flag = "Example.NotHeldBind",
        Default = Enum.KeyCode.K,
        Mode = "Not Held",
        ShowInBinds = false,
        Callback = function(Value)
            Changed("Not held action", Value)
        end,
    })
    Controls.AlwaysBind = KeyModes:AddKeybind({
        Name = "Always action",
        Flag = "Example.AlwaysBind",
        Default = Enum.KeyCode.Unknown,
        Mode = "Always",
        ShowInBinds = false,
        Callback = function(Value)
            Changed("Always action", Value)
        end,
    })
    Controls.MouseBind = KeyModes:AddKeybind({
        Name = "Mouse hold",
        Flag = "Example.MouseBind",
        Default = Enum.UserInputType.MouseButton2,
        Mode = "Hold",
        ShowInBinds = false,
        Callback = function(Value)
            Changed("Mouse hold", Value)
        end,
    })
    KeyModes:AddParagraph({
        Name = "Hold / toggle / always",
        Content = "Peek on Main uses hold. J toggles. K is active when not held. Always needs no key. Mouse hold accepts a mouse button.",
    })
    local BindDisplay = Modes:AddSection({ Name = "Binding list", Icon = "View", Column = 2 })
    Controls.ShowExtraBinds = BindDisplay:AddCheckbox({
        Name = "Show all mode examples",
        Default = false,
        Tooltip = "Add the toggle, not-held, always, and mouse examples to the floating keybind list.",
        Callback = function(Value)
            Controls.ToggleBind.Keybind:SetShowInBinds(Value)
            Controls.NotHeldBind.Keybind:SetShowInBinds(Value)
            Controls.AlwaysBind.Keybind:SetShowInBinds(Value)
            Controls.MouseBind.Keybind:SetShowInBinds(Value)
        end,
    })
    BindDisplay:AddButton({
        Name = "Restore example keys",
        Callback = function()
            Controls.Checkbox.Keybind:SetKey(Enum.KeyCode.B)
            Controls.Keybind:Set(Enum.KeyCode.H):SetMode("Hold")
            Controls.ToggleBind:Set(Enum.KeyCode.J):SetMode("Toggle")
            Controls.NotHeldBind:Set(Enum.KeyCode.K):SetMode("Not Held")
            Controls.AlwaysBind:Set(Enum.KeyCode.Unknown):SetMode("Always")
            Controls.MouseBind:Set(Enum.UserInputType.MouseButton2):SetMode("Hold")
            Library:Notify({ Text = "Example keys restored", Type = "Success" })
        end,
    })
    BindDisplay:AddParagraph({
        Name = "Separate tiles",
        Content = "The Keybinds title and each binding have their own rounded background. Drag the title to move the list. Style controls its visibility.",
    })

    local PalettePage = Appearance:AddPage({ Name = "Palette", Icon = "Palette" })
    local PaletteSettings = PalettePage:AddSection({ Name = "Theme colors", Column = 1 })
    Controls.ThemeColors = {}
    for _, Entry in
        {
            { "Background", "Background" },
            { "Inline", "Surface" },
            { "Element", "Raised" },
            { "Accent", "Accent" },
            { "Border", "Border" },
            { "Text", "Text" },
            { "Inactive text", "SubText" },
            { "Image", "Image" },
            { "Shadow", "Shadow" },
            { "Dark gradient", "DarkGradient" },
        }
    do
        local Token = Entry[2]
        Controls.ThemeColors[Token] = PaletteSettings:AddColorPicker({
            Name = Entry[1],
            Default = Library:GetTheme()[Token],
            EnableAlpha = false,
            Callback = function(Value)
                Library:ChangeTheme(Token, Value)
            end,
        })
    end
    local Presets = PalettePage:AddSection({ Name = "Presets & custom themes", Column = 2 })
    Controls.ThemePreset = Presets:AddDropdown({
        Name = "Preset",
        Options = Library:GetThemePresets(),
        Default = "Myhoe",
        Callback = function(Name)
            Library:SetTheme(Name)
        end,
    })
    local ThemeName = Presets:AddTextbox({ Name = "Theme name", Default = "Custom", MaxLength = 48 })
    local ThemeList = Presets:AddDropdown({
        Name = "Saved themes",
        Options = Library:ListThemes() or {},
        Placeholder = "No saved themes",
    })
    Controls.ThemeName, Controls.ThemeList = ThemeName, ThemeList
    Presets:AddButton({
        Name = "Save theme",
        Disabled = not Library.ThemeConfig.Available,
        Callback = function()
            local OK, Reason = Library:SaveTheme(ThemeName:Get())
            Library:Notify({
                Text = OK and "Theme saved" or tostring(Reason),
                Type = OK and "Success" or "Error",
            })
            ThemeList:Refresh(Library:ListThemes() or {}, true)
            if OK then
                ThemeList:Set(ThemeName:Get())
            end
        end,
    })
    Presets:AddButton({
        Name = "Load theme",
        Disabled = not Library.ThemeConfig.Available,
        Callback = function()
            local OK, Reason = Library:LoadTheme(ThemeList:Get() or ThemeName:Get())
            Library:Notify({
                Text = OK and "Theme loaded" or tostring(Reason),
                Type = OK and "Success" or "Error",
            })
        end,
    })
    Presets:AddButton({
        Name = "Delete theme",
        Disabled = not Library.ThemeConfig.Available,
        Callback = function()
            local Name = ThemeList:Get() or ThemeName:Get()
            Window:Confirm({
                Title = "Delete theme?",
                Description = Name,
                ConfirmText = "Delete",
                Callback = function(Yes)
                    if not Yes then
                        return
                    end
                    local OK, Reason = Library:DeleteTheme(Name)
                    Library:Notify({
                        Text = OK and "Theme deleted" or tostring(Reason),
                        Type = OK and "Success" or "Error",
                    })
                    ThemeList:Refresh(Library:ListThemes() or {}, true)
                end,
            })
        end,
    })
    Presets:AddParagraph({
        Name = "Live theming",
        Content = "Choose a preset or edit individual colors. Existing controls, popups, notifications, and displays update immediately. Save custom themes here.",
    })
    local Theme = Appearance:AddSection({ Name = "Theme", Icon = "Palette", Column = 1 })
    Controls.Accent = Theme:AddColorPicker({
        Name = "Accent",
        Default = Library:GetTheme().Accent,
        EnableAlpha = false,
        Callback = function(Value)
            Library:SetTheme({ Accent = Value })
        end,
    })
    Controls.Background = Theme:AddColorPicker({
        Name = "Background",
        Default = Library:GetTheme().Background,
        EnableAlpha = false,
        Callback = function(Value)
            Library:SetTheme({ Background = Value })
        end,
    })
    Controls.AlphaColor = Theme:AddColorPicker({
        Name = "Color & opacity",
        Flag = "Example.Color",
        Default = Color3.fromRGB(100, 170, 210),
        EnableAlpha = true,
        Alpha = 0.75,
        Callback = function(Value, Alpha)
            Changed("Color", Value:ToHex() .. " / " .. math.round(Alpha * 100) .. "%")
        end,
    })
    Controls.OpaqueColor = Theme:AddColorPicker({
        Name = "Opaque color",
        Flag = "Example.OpaqueColor",
        Default = Color3.fromRGB(230, 160, 120),
        EnableAlpha = false,
        ShowHex = true,
        Callback = function(Value)
            Changed("Opaque color", Value:ToHex())
        end,
    })
    Theme:AddDivider({ Text = "Window" })
    Controls.Scale = Theme:AddSlider({
        Name = "Scale",
        Min = 0.6,
        Max = 1.4,
        Default = 1,
        Increment = 0.05,
        Callback = function(Value)
            Window:SetScale(Value)
        end,
    })
    Theme:AddButton({
        Name = "Restore default theme",
        Callback = function()
            Library:SetTheme("Myhoe")
        end,
    })
    local Animation = Appearance:AddSection({ Name = "Color animations", Icon = "Palette", Column = 1 })
    Controls.ColorAnimationButtons = Animation:AddButtons({
        Buttons = {
            {
                Name = "Rainbow",
                Callback = function()
                    Controls.AlphaColor:SetAnimations({ "rainbow" })
                end,
            },
            {
                Name = "Breathing",
                Callback = function()
                    Controls.AlphaColor:SetAnimations({ "breathing" })
                end,
            },
            {
                Name = "Stop",
                Callback = function()
                    Controls.AlphaColor:SetAnimations({})
                end,
            },
        },
    })
    Animation:AddParagraph({
        Name = "Live color",
        Content = "These buttons animate Color & opacity above. Its picker can combine both animations. Stop restores the base color.",
    })
    local Watermark = Library.Watermark
    Watermark:SetName("myhoe")
    Library.Keybinds:SetOnlyActive(false)
    local Hud = Appearance:AddSection({ Name = "On-screen displays", Icon = "View", Column = 2 })
    Controls.Watermark = Hud:AddCheckbox({
        Name = "Watermark",
        Default = true,
        Tooltip = "Show or hide the watermark. Drag it to change its position.",
        Callback = function(Value)
            Watermark:SetVisible(Value)
        end,
    })
    local WatermarkSettings = Controls.Watermark:Settings({ Width = 240 })
    Controls.Binds = Hud:AddCheckbox({
        Name = "Keybind list",
        Default = true,
        Tooltip = "Show or hide the floating binding tiles. Drag the Keybinds title to move them.",
        Callback = function(Value)
            Library.Keybinds:SetVisible(Value)
        end,
    })
    local KeybindSettings = Controls.Binds:Settings({ Width = 240 })
    Controls.ShowModes = KeybindSettings:AddCheckbox({
        Name = "Show binding modes",
        Default = true,
        Tooltip = "Include hold, toggle, not held, or always beside each binding name.",
        Callback = function(Value)
            Library.Keybinds:SetShowModes(Value)
        end,
    })
    Controls.ActiveOnly = KeybindSettings:AddCheckbox({
        Name = "Only active bindings",
        Default = false,
        Tooltip = "Show only bindings that are currently active. Turn this off to also see inactive bindings.",
        Callback = function(Value)
            Library.Keybinds:SetOnlyActive(Value)
        end,
    })
    Controls.WatermarkName = WatermarkSettings:AddTextbox({
        Name = "Watermark name",
        Default = "myhoe",
        Callback = function(Value)
            Watermark:SetName(Value)
        end,
    })
    Controls.Providers = WatermarkSettings:AddMultiDropdown({
        Name = "Watermark items",
        Options = {
            "FPS",
            "Ping",
            { Name = "Game name", Value = "GameName" },
            { Name = "Player name", Value = "PlayerName" },
            "Time",
        },
        Default = { "FPS", "Ping", "GameName", "PlayerName" },
        Searchable = false,
        Callback = function(Value)
            Watermark:SetItems(Value)
        end,
    })
    Hud:AddParagraph({
        Name = "Drag to position",
        Content = "Click either gear to configure its display. Drag the watermark or Keybinds header to move it. Both stay visible while the menu is minimized.",
    })

    local Storage = Profiles:AddSection({ Name = "Saved profiles", Icon = "Folder", Column = 1 })
    Controls.ProfileName = Storage:AddTextbox({ Name = "Profile name", Default = "Default", MaxLength = 48 })
    Controls.Profile =
        Storage:AddDropdown({ Name = "Profiles", Options = {}, Placeholder = "No saved profiles" })
    local function Report(OK, Reason, Success)
        Library:Notify({
            Text = OK and Success or tostring(Reason),
            Type = OK and "Success" or "Error",
            Duration = 3,
        })
    end
    local function RefreshProfiles()
        local List = Library.Config:List()
        Controls.Profile:Refresh(type(List) == "table" and List or {}, true)
    end
    Controls.SaveProfile = Storage:AddButton({
        Name = "Save profile",
        Disabled = not Library.Config.Available,
        Callback = function()
            local OK, Reason = Library.Config:Save(Controls.ProfileName:Get())
            Report(OK, Reason, "Profile saved")
            RefreshProfiles()
            if OK then
                Controls.Profile:Set(Controls.ProfileName:Get())
            end
        end,
    })
    Controls.LoadProfile = Storage:AddButton({
        Name = "Load profile",
        Disabled = not Library.Config.Available,
        Callback = function()
            local OK, Reason = Library.Config:Load(Controls.Profile:Get() or Controls.ProfileName:Get())
            Report(OK, Reason, "Profile loaded")
        end,
    })
    Controls.DeleteProfile = Storage:AddButton({
        Name = "Delete profile",
        Disabled = not Library.Config.Available,
        Callback = function()
            local Name = Controls.Profile:Get() or Controls.ProfileName:Get()
            Window:Confirm({
                Title = "Delete profile?",
                Description = Name,
                ConfirmText = "Delete",
                Callback = function(Yes)
                    if Yes then
                        local OK, Reason = Library.Config:Delete(Name)
                        Report(OK, Reason, "Profile deleted")
                        RefreshProfiles()
                    end
                end,
            })
        end,
    })
    Storage:AddButton({ Name = "Refresh profiles", Callback = RefreshProfiles })
    Storage:AddParagraph({
        Name = "Persistence",
        Content = Library.Config.SessionOnly
                and "Profiles are available for this play session. They reset when Studio stops. Executors with file access retain profiles between runs."
            or "Profiles are saved to Myhoe/Configs and include flagged controls, bindings, colors, the theme, and display positions.",
    })
    local Session = Profiles:AddSection({ Name = "Session", Icon = "Config", Column = 2 })
    local Snapshot
    Controls.SaveSnapshot = Session:AddButton({
        Name = "Save session snapshot",
        Callback = function()
            Snapshot = Library.Config:Export()
            Library:Notify({ Text = "Session snapshot saved", Type = "Success" })
        end,
    })
    Controls.RestoreSnapshot = Session:AddButton({
        Name = "Restore session snapshot",
        Callback = function()
            if not Snapshot then
                Library:Notify({ Text = "Save a snapshot first", Type = "Warning" })
                return
            end
            local OK, Reason = Library.Config:Import(Snapshot)
            Report(OK, Reason, "Session snapshot restored")
        end,
    })
    Session:AddParagraph({
        Name = "Try a round trip",
        Content = "Save a profile or snapshot, change the controls, then load it again. Ranges, selections, text, colors, bindings, and HUD settings return together.",
    })
    Session:AddDivider({ Text = "Library" })
    Controls.ProfileUnload = Session:AddButton({
        Name = "Unload myhoe",
        Callback = ConfirmUnload,
    })
    local function Sync()
        local Silent = { Silent = true }
        for Token, Picker in Controls.ThemeColors do
            Picker:Set(Library:GetTheme()[Token], Silent)
        end
        Controls.Accent:Set(Library:GetTheme().Accent, Silent)
        Controls.Background:Set(Library:GetTheme().Background, Silent)
        Controls.Watermark:Set(Watermark:GetVisible(), Silent)
        Controls.WatermarkName:Set(Watermark.Name, Silent)
        local Providers = {}
        for _, Item in Watermark.Items do
            if Item.Visible ~= false and type(Item.Provider) == "string" then
                table.insert(Providers, Item.Provider)
            end
        end
        Controls.Providers:Set(Providers, Silent)
        Controls.Binds:Set(Library.Keybinds:GetVisible(), Silent)
        Controls.ActiveOnly:Set(Library.Keybinds:GetOnlyActive(), Silent)
        Controls.ShowModes:Set(Library.Keybinds:GetShowModes(), Silent)
        Controls.Progress:Set(Controls.Amount:Get() / 100, Silent)
        Controls.StateValue:SetDisabled(not Controls.StateEnabled:Get())
        Controls.StateValue:SetVisible(Controls.StateVisible:Get())
    end
    Library.Theme:Subscribe(Sync, Window.Scope)
    Library.Config:Subscribe(Sync, Window.Scope)
    Watermark:Subscribe(Sync, Window.Scope)
    Library.Keybinds:Subscribe(Sync, Window.Scope)
    RefreshProfiles()
    Library.Keybinds:Refresh()
    Main:Select()
    Library:Notify({
        Text = "myhoe loaded · RightShift toggles the menu · Main, Tools, Style, Profiles",
        Duration = 5,
    })
    local Demo = {
        Window = Window,
        Controls = Controls,
        Settings = Attached,
        KeybindSettings = KeybindSettings,
        WatermarkSettings = WatermarkSettings,
        Watermark = Watermark,
        Tabs = {
            Main = Main,
            More = More,
            Tools = Tools,
            Modes = Modes,
            Appearance = Appearance,
            Palette = PalettePage,
            Profiles = Profiles,
        },
    }
    Library.Demo = Demo
end

return Library
