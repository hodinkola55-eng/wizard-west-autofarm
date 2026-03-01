-- UI MODULE (ui.lua)
local UI = {}

function UI.init(Farm)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    
    local Window = Fluent:CreateWindow({
        Title = "WIZARD WEST V10 | TopNov",
        SubTitle = "Mobile Fixed",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift
    })

    -- ПЛАВАЮЩАЯ КНОПКА ДЛЯ ТЕЛЕФОНА
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WW_MobileUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.IgnoreGuiInset = true

    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenMenu"
    OpenBtn.Parent = ScreenGui
    OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    OpenBtn.BorderSizePixel = 2
    OpenBtn.Position = UDim2.new(0, 10, 0.5, 0)
    OpenBtn.Size = UDim2.new(0, 60, 0, 60)
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.Text = "MENU"
    OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenBtn.TextSize = 14
    OpenBtn.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 30)
    corner.Parent = OpenBtn

    OpenBtn.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    local Tabs = {
        Main = Window:AddTab({ Title = "Фарм", Icon = "home" }),
        Combat = Window:AddTab({ Title = "Бой", Icon = "sword" }),
        Cheats = Window:AddTab({ Title = "Читы", Icon = "zap" })
    }

    -- TAB: ФАРМ (ЗАМЕНА СЛАЙДЕРОВ НА ВВОД ДЛЯ ТОЧНОСТИ)
    Tabs.Main:AddToggle("AutoFarm", {Title = "AutoFarm", Default = false}):OnChanged(function(v) Farm.Cfg.Enabled = v end)
    Tabs.Main:AddToggle("AutoArt", {Title = "Авто-Артефакт", Default = false}):OnChanged(function(v) Farm.Cfg.ArtFarm = v end)
    
    Tabs.Main:AddInput("SellEvery", {Title = "Продавать каждые N (1-10)", Default = "3"}):OnChanged(function(v) 
        local n = tonumber(v)
        if n then Farm.Cfg.SellEvery = math.clamp(n, 1, 10) end
    end)
    
    Tabs.Main:AddInput("FlySpeed", {Title = "Скорость полёта (20-150)", Default = "50"}):OnChanged(function(v) 
        local n = tonumber(v)
        if n then Farm.Cfg.FlySpeed = math.clamp(n, 20, 150) end
    end)
    
    Tabs.Main:AddInput("MobHeight", {Title = "Высота над мобом (0-25)", Default = "8"}):OnChanged(function(v) 
        local n = tonumber(v)
        if n then Farm.Cfg.MobHeight = math.clamp(n, 0, 25) end
    end)

    Tabs.Main:AddButton({
        Title = "Сохранить TP Point (Продажа)",
        Callback = function()
            local _,r = Farm.getChar()
            if r then
                Farm.Cfg.SellTP = r.Position
                Fluent:Notify({Title = "OK", Content = "Точка ТП сохранена", Duration = 2})
            end
        end
    })

    Tabs.Main:AddButton({
        Title = "Сохранить Walk Point (Продажа)",
        Callback = function()
            local _,r = Farm.getChar()
            if r then
                Farm.Cfg.SellWalk = r.Position
                Fluent:Notify({Title = "OK", Content = "Точка ходьбы сохранена", Duration = 2})
            end
        end
    })

    -- TAB: БОЙ
    Tabs.Combat:AddInput("WeaponKey", {Title = "Клавиша оружия", Default = "R"}):OnChanged(function(v) Farm.Cfg.WeaponKey = v end)
    Tabs.Combat:AddInput("HealKey", {Title = "Клавиша хила", Default = ""}):OnChanged(function(v) Farm.Cfg.HealKey = v end)
    
    Tabs.Combat:AddInput("HealHP", {Title = "Хил при HP% (10-90)", Default = "40"}):OnChanged(function(v) 
        local n = tonumber(v)
        if n then Farm.Cfg.HealHP = math.clamp(n, 10, 90) end
    end)
    
    Tabs.Combat:AddInput("Skill1", {Title = "Скилл 1", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill1 = v end)
    Tabs.Combat:AddInput("Skill2", {Title = "Скилл 2", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill2 = v end)
    Tabs.Combat:AddInput("Skill3", {Title = "Скилл 3", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill3 = v end)
    
    Tabs.Combat:AddInput("AtkDelay", {Title = "Задержка атаки (мс) (100-1500)", Default = "300"}):OnChanged(function(v) 
        local n = tonumber(v)
        if n then Farm.Cfg.AtkDelay = math.clamp(n, 100, 1500)/1000 end
    end)

    -- TAB: ЧИТЫ
    Tabs.Cheats:AddToggle("NoClip", {Title = "NoClip (Сквозь стены)", Default = false}):OnChanged(function(v) Farm.Cfg.NoClip = v end)
    Tabs.Cheats:AddToggle("NoFall", {Title = "Нет урона от падения", Default = false}):OnChanged(function(v) Farm.Cfg.NoFall = v end)

    Tabs.Cheats:AddButton({
        Title = "Убить AC-скрипты",
        Callback = function()
            local killed = 0
            local function killAC(container)
                if not container then return end
                for _,v in ipairs(container:GetDescendants()) do
                    if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                        local n=v.Name:lower()
                        if n:find("anti") or n:find("bound") or n:find("flysmoke") or n:find("speed") then
                            pcall(function() v.Disabled=true end)
                            pcall(function() v:Destroy() end)
                            killed = killed + 1
                        end
                    end
                end
            end
            killAC(game:GetService("Players").LocalPlayer.Character)
            killAC(game:GetService("Players").LocalPlayer.PlayerScripts)
            Fluent:Notify({Title = "AC", Content = "Убито: "..killed, Duration = 3})
        end
    })

    Window:SelectTab(1)
    Fluent:Notify({Title = "WW V10", Content = "Мобильные фиксы применены!", Duration = 3})
end

return UI
