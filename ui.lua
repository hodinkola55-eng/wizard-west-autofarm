-- UI MODULE (ui.lua)
local UI = {}

function UI.init(Farm)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    
    local Window = Fluent:CreateWindow({
        Title = "WIZARD WEST V10 | TopNov",
        SubTitle = "Mobile Optimized",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false, -- Отключаем акрил для меньших лагов на мобилках
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Фарм", Icon = "home" }),
        Combat = Window:AddTab({ Title = "Бой", Icon = "sword" }),
        Cheats = Window:AddTab({ Title = "Читы", Icon = "zap" })
    }

    -- TAB: ФАРМ
    Tabs.Main:AddToggle("AutoFarm", {Title = "AutoFarm", Default = false}):OnChanged(function(v) Farm.Cfg.Enabled = v end)
    Tabs.Main:AddToggle("AutoArt", {Title = "Авто-Артефакт", Default = false}):OnChanged(function(v) Farm.Cfg.ArtFarm = v end)
    
    Tabs.Main:AddSlider("SellEvery", {Title = "Продавать каждые N", Default = 3, Min = 1, Max = 10, Rounding = 0}):OnChanged(function(v) Farm.Cfg.SellEvery = v end)
    Tabs.Main:AddSlider("FlySpeed", {Title = "Скорость полёта", Default = 50, Min = 20, Max = 150, Rounding = 0}):OnChanged(function(v) Farm.Cfg.FlySpeed = v end)
    Tabs.Main:AddSlider("MobHeight", {Title = "Высота над мобом", Default = 8, Min = 0, Max = 25, Rounding = 0}):OnChanged(function(v) Farm.Cfg.MobHeight = v end)

    -- ВОЗВРАЩАЕМ ТОЧКИ ПРОДАЖИ
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

    Tabs.Main:AddButton({
        Title = "Сбросить точки (Хардкод)",
        Callback = function()
            Farm.Cfg.SellTP = nil
            Farm.Cfg.SellWalk = nil
            Fluent:Notify({Title = "OK", Content = "Точки сброшены", Duration = 2})
        end
    })

    -- TAB: БОЙ
    Tabs.Combat:AddInput("WeaponKey", {Title = "Клавиша оружия", Default = "R"}):OnChanged(function(v) Farm.Cfg.WeaponKey = v end)
    Tabs.Combat:AddInput("HealKey", {Title = "Клавиша хила", Default = ""}):OnChanged(function(v) Farm.Cfg.HealKey = v end)
    Tabs.Combat:AddSlider("HealHP", {Title = "Хил при HP%", Default = 40, Min = 10, Max = 90, Rounding = 0}):OnChanged(function(v) Farm.Cfg.HealHP = v end)
    
    -- ВОЗВРАЩАЕМ НАСТРОЙКУ СКИЛЛОВ
    Tabs.Combat:AddInput("Skill1", {Title = "Скилл 1", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill1 = v end)
    Tabs.Combat:AddInput("Skill2", {Title = "Скилл 2", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill2 = v end)
    Tabs.Combat:AddInput("Skill3", {Title = "Скилл 3", Default = ""}):OnChanged(function(v) Farm.Cfg.Skill3 = v end)
    
    Tabs.Combat:AddSlider("AtkDelay", {Title = "Задержка атаки (мс)", Default = 300, Min = 100, Max = 1500, Rounding = 0}):OnChanged(function(v) Farm.Cfg.AtkDelay = v/1000 end)

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
    Fluent:Notify({Title = "WW V10", Content = "Интерфейс восстановлен!", Duration = 3})
end

return UI
