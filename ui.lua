-- UI MODULE (ui.lua)
local UI = {}

function UI.init(Farm)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    
    local Window = Fluent:CreateWindow({
        Title = "WIZARD WEST V10 | TopNov",
        SubTitle = "Modular Mobile",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Фарм", Icon = "home" }),
        Combat = Window:AddTab({ Title = "Бой", Icon = "sword" }),
        Cheats = Window:AddTab({ Title = "Читы", Icon = "zap" })
    }

    Tabs.Main:AddToggle("AutoFarm", {Title = "AutoFarm", Default = false}):OnChanged(function(v) Farm.Cfg.Enabled = v end)
    Tabs.Main:AddToggle("AutoArt", {Title = "Авто-Артефакт", Default = false}):OnChanged(function(v) Farm.Cfg.ArtFarm = v end)
    Tabs.Main:AddSlider("SellEvery", {Title = "Продавать каждые N", Default = 3, Min = 1, Max = 10, Rounding = 0}):OnChanged(function(v) Farm.Cfg.SellEvery = v end)
    Tabs.Main:AddSlider("FlySpeed", {Title = "Скорость полёта", Default = 50, Min = 20, Max = 150, Rounding = 0}):OnChanged(function(v) Farm.Cfg.FlySpeed = v end)
    Tabs.Main:AddSlider("MobHeight", {Title = "Высота над мобом", Default = 8, Min = 0, Max = 25, Rounding = 0}):OnChanged(function(v) Farm.Cfg.MobHeight = v end)

    Tabs.Combat:AddInput("WeaponKey", {Title = "Клавиша оружия", Default = "R"}):OnChanged(function(v) Farm.Cfg.WeaponKey = v end)
    Tabs.Combat:AddInput("HealKey", {Title = "Клавиша хила", Default = ""}):OnChanged(function(v) Farm.Cfg.HealKey = v end)
    Tabs.Combat:AddSlider("HealHP", {Title = "Хил при HP%", Default = 40, Min = 10, Max = 90, Rounding = 0}):OnChanged(function(v) Farm.Cfg.HealHP = v end)
    Tabs.Combat:AddSlider("AtkDelay", {Title = "Задержка атаки (мс)", Default = 300, Min = 100, Max = 1500, Rounding = 0}):OnChanged(function(v) Farm.Cfg.AtkDelay = v/1000 end)

    Tabs.Cheats:AddToggle("NoClip", {Title = "NoClip", Default = false}):OnChanged(function(v) Farm.Cfg.NoClip = v end)
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
    Fluent:Notify({Title = "WW V10", Content = "Интерфейс загружен!", Duration = 3})
end

return UI
