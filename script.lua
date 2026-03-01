Создай мне репозиторий в git hub вставь туда этот код -- WIZARD WEST AUTOFARM V10 | TopNov DEVELOPER
-- Orion UI | RightShift = скрыть/показать

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local WS       = game:GetService("Workspace")
local VU       = game:GetService("VirtualUser")
local VIM      = game:GetService("VirtualInputManager")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui  = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = WS.CurrentCamera

local Events  = RS:WaitForChild("Events", 10)
local TrSell  = Events and Events:FindFirstChild("TrinketSellEvent")
local SELL_POS = Vector3.new(209.69, 75.88, -381.90)

-- ====== КОНФИГ (сохраняется между сессиями) ======
local Cfg = {
    Enabled       = false,
    WeaponKey     = "R",
    HealKey       = "",
    HealHP        = 40,
    Skill1        = "",
    Skill2        = "",
    Skill3        = "",
    FlySpeed      = 50,
    AtkDelay      = 0.3,
    MobHeight     = 8,
    SellEvery     = 3,
    ArtFarm       = false,
    NoClip        = false,
    NoFall        = false,
    SellTP        = nil,
    SellWalk      = nil,
}

local St = { Chests=0, Sold=0, ArtActive=false, Target=nil }

-- ====== УТИЛИТЫ ======
local function getChar()
    local c = LP.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChild("Humanoid")
    if r and h and h.Health > 0 then return c,r,h end
end
local function alive() return getChar() ~= nil end

local function stopFly()
    local c = LP.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    for _,v in ipairs(r:GetChildren()) do
        if v.Name == "FarmAtt" or v.Name == "FarmBP" then v:Destroy() end
    end
    pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
end

local KeyMap = {["1"]="One",["2"]="Two",["3"]="Three",["4"]="Four",["5"]="Five",
                ["6"]="Six",["7"]="Seven",["8"]="Eight",["9"]="Nine",["0"]="Zero"}
local function pressKey(k)
    if not k or k=="" then return end
    local n = KeyMap[k:upper()] or k:upper()
    local ok,e = pcall(function() return Enum.KeyCode[n] end)
    if ok and e then
        VIM:SendKeyEvent(true,e,false,game); task.wait(0.05)
        VIM:SendKeyEvent(false,e,false,game)
    end
end

-- ====== АНТИЧИТ ОБХОДЫ ======

-- 1. NoClip - проходим сквозь стены
RunSvc.Stepped:Connect(function()
    if not Cfg.NoClip then return end
    local c = LP.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.CanCollide = false
        end
    end
end)

-- 2. Нет урона от падения
RunSvc.Heartbeat:Connect(function()
    if not Cfg.NoFall then return end
    local c = LP.Character; if not c then return end
    local h = c:FindFirstChild("Humanoid")
    if h then h.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall then
            h:ChangeState(Enum.HumanoidStateType.Running)
        end
    end) end
end)

-- 3. Убираем локальные AC-скрипты
-- Из скана: AntiSpeed (Char), BoundryCheck (Flight), FlySmoke (Visuals)
-- Они в StarterCharacterScripts/LocalScript - убиваем на клиенте
task.spawn(function()
    while task.wait(3) do
        local function killAC(container)
            if not container then return end
            for _,v in ipairs(container:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                    local n = v.Name:lower()
                    if n:find("anti") or n:find("bound") or n:find("flysmoke") or n:find("speed") then
                        pcall(function() v.Disabled = true end)
                        pcall(function() v:Destroy() end)
                    end
                end
            end
        end
        killAC(LP.Character)
        killAC(LP.PlayerScripts)
    end
end)

-- 4. Во время полёта не даём коллайдерам ломать нас
RunSvc.Stepped:Connect(function()
    local c = LP.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    if r and r:FindFirstChild("FarmAtt") then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

LP.Idled:Connect(function()
    VU:Button2Down(Vector2.zero, Camera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.zero, Camera.CFrame)
end)

-- ====== ПОЛЁТ ======
local function flyTo(pos, spd)
    local _,root = getChar(); if not root then return false end
    stopFly()
    local att = Instance.new("Attachment",root); att.Name="FarmAtt"
    local lv = Instance.new("LinearVelocity",att); lv.Name="FarmLV"
    lv.Attachment0=att; lv.MaxForce=9e5; lv.RelativeTo=Enum.ActuatorRelativeTo.World
    local speed = spd or Cfg.FlySpeed
    local t,ok = 0,false
    while Cfg.Enabled and alive() and t<20 do
        local _,r = getChar(); if not r then break end
        if (r.Position-pos).Magnitude < 4 then ok=true; break end
        lv.VectorVelocity = (pos-r.Position).Unit * speed
        t = t + task.wait()
    end
    stopFly(); return ok
end

-- ====== КАМЕРА ======
RunSvc.RenderStepped:Connect(function()
    pcall(function()
        if Cfg.Enabled and St.Target and St.Target.Parent then
            local h = St.Target.Parent:FindFirstChild("Humanoid")
            if h and h.Health > 0 then
                local _,r = getChar(); if not r then return end
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.lookAt(r.Position+Vector3.new(0,8,12), St.Target.Position)
                return
            end
        end
        St.Target = nil
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
    end)
end)

-- ====== ПРОДАЖА ======
local function doSell()
    local pos = Cfg.SellTP or SELL_POS
    if not flyTo(pos) then return end
    if not alive() then return end
    if Cfg.SellWalk then
        local _,r,h = getChar()
        if r and h then
            h:MoveTo(Cfg.SellWalk)
            local t=0
            while alive() and (r.Position-Cfg.SellWalk).Magnitude>5 and t<6 do
                task.wait(0.2); t+=0.2
            end
        end
    end
    for _=1,5 do pcall(function() TrSell:FireServer() end); task.wait(0.25) end
    St.Sold += St.Chests; St.Chests = 0
end

-- ====== МИССИИ ======
local function getNearestMission()
    local folder = WS:FindFirstChild("Missions")
    local _,root = getChar()
    if not folder or not root then return end
    local best,bestD,bestPos = nil,math.huge,nil
    for _,m in ipairs(folder:GetChildren()) do
        if m.Name == "ArtifactMission" then continue end
        local left = m:GetAttribute("EnemiesLeft")
        if not left or left<=0 or m:GetAttribute("Completed") then continue end
        local smoke = m:FindFirstChild("SmokePart")
        if not smoke then continue end
        local pos = smoke:GetPivot().Position
        local d = (root.Position-pos).Magnitude
        if d<bestD then bestD=d; best=m; bestPos=pos end
    end
    return best,bestPos
end

local function getClosestMob(center)
    local _,myRoot = getChar(); if not myRoot then return end
    local best,bestD = nil,200
    for _,cont in ipairs({"CapturedAI","Missions"}) do
        local f = WS:FindFirstChild(cont); if not f then continue end
        for _,v in ipairs(f:GetDescendants()) do
            if not v:IsA("Model") then continue end
            if Players:GetPlayerFromCharacter(v) then continue end
            local h = v:FindFirstChild("Humanoid")
            local r = v:FindFirstChild("HumanoidRootPart")
            if h and h.Health>0 and r and (center-r.Position).Magnitude<200 then
                local d=(myRoot.Position-r.Position).Magnitude
                if d<bestD then bestD=d; best=v end
            end
        end
    end
    return best
end

-- ====== БОЙ ======
local function fightMob(mob, mission)
    local mobHum = mob:FindFirstChild("Humanoid")
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobHum or not mobRoot then return end
    local _,root = getChar(); if not root then return end

    local function behind()
        if not mobRoot.Parent then return nil end
        return (mobRoot.CFrame*CFrame.new(0,Cfg.MobHeight,5)).Position
    end

    local bp = behind()
    if bp and (root.Position-bp).Magnitude>20 then
        if not flyTo(bp) then return end
    end
    if not alive() then return end

    local _,r = getChar(); stopFly()
    local bpObj = Instance.new("BodyPosition",r)
    bpObj.Name="FarmBP"; bpObj.MaxForce=Vector3.new(9e5,9e5,9e5)
    bpObj.D=800; bpObj.P=8000; bpObj.Position=behind() or r.Position

    St.Target = mobRoot
    local atkT,healT,startHp = 0,0,mobHum.Health

    while mobHum.Health>0 and alive() and Cfg.Enabled do
        if not mobRoot.Parent then break end
        if mission:GetAttribute("EnemiesLeft")==0 then break end
        -- Прерываем ради артефакта
        if Cfg.ArtFarm and not St.ArtActive then
            local am = WS:FindFirstChild("Missions")
            if am and am:FindFirstChild("ArtifactMission") then break end
        end

        local _,rr,hum = getChar(); if not rr then break end
        local newBp = behind(); if newBp then bpObj.Position=newBp end

        if Cfg.HealKey~="" and hum.Health<hum.MaxHealth*(Cfg.HealHP/100) then
            if tick()-healT>3 then pressKey(Cfg.HealKey); healT=tick() end
        end

        local prm = mob:FindFirstChildWhichIsA("ProximityPrompt",true)
        if prm and prm.Enabled then
            for _=1,8 do
                local p=mob:FindFirstChildWhichIsA("ProximityPrompt",true)
                if not p or not p.Enabled then break end
                pcall(fireproximityprompt,p); task.wait(0.3)
            end
        end

        if mobHum.Health<startHp then startHp=mobHum.Health; atkT=0
        elseif atkT>8 then break end

        local tool = LP.Character:FindFirstChildOfClass("Tool")
        if not tool then
            pressKey(Cfg.WeaponKey); task.wait(0.1)
        else
            pcall(function() tool:Activate() end)
            VU:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2))
        end
        if Cfg.Skill1~="" then pressKey(Cfg.Skill1) end
        if Cfg.Skill2~="" then pressKey(Cfg.Skill2) end
        if Cfg.Skill3~="" then pressKey(Cfg.Skill3) end

        atkT += Cfg.AtkDelay; task.wait(Cfg.AtkDelay)
    end

    St.Target=nil; Camera.CameraType=Enum.CameraType.Custom; stopFly(); task.wait(0.2)
end

-- ====== ЛУТ СУНДУКОВ ======
local function lootChests(missionPos)
    local entities = WS:FindFirstChild("Entities"); if not entities then return end
    -- ФИКС: проходим ВСЕ сундуки, не только первый
    for attempt=1,10 do
        if not alive() then return end
        local found = false
        for _,obj in ipairs(entities:GetChildren()) do
            if not obj:FindFirstChild("Weld") then continue end
            local loot = obj:FindFirstChild("LootGiver")
            if not loot or not loot:IsA("ProximityPrompt") then continue end
            if (obj:GetPivot().Position-missionPos).Magnitude>150 then continue end
            -- Проверяем не открыт ли уже нами
            local ob = loot:GetAttribute("OpenedBy") or ""
            if ob:find(LP.Name,1,true) then continue end
            flyTo(obj:GetPivot().Position+Vector3.new(0,3,0))
            task.wait(0.4)
            if alive() then
                for _=1,5 do pcall(fireproximityprompt,loot); task.wait(0.2) end
                St.Chests+=1; St.Earned=(St.Earned or 0)+1
                found = true
            end
        end
        if not found then return end -- нет новых сундуков
        task.wait(0.5)
    end
end

-- ====== АРТЕФАКТ ======
-- Порядок: сундуки -> артефакт -> вверх 600 -> висим -> вниз -> продаём

local LootedArts = {}

local function findArtData()
    local ms = WS:FindFirstChild("Missions"); if not ms then return end
    local am = ms:FindFirstChild("ArtifactMission"); if not am then return end
    local loot = am:FindFirstChild("Loot"); if not loot then return end
    local art = loot:FindFirstChild("Pillar")
    art = art and art:FindFirstChild("Artifact")
    local artPrm = art and art:FindFirstChild("LootGiver")
    if not artPrm then return end
    if LootedArts[artPrm] then return end
    local ob = artPrm:GetAttribute("OpenedBy") or ""
    if ob:find(LP.Name,1,true) then LootedArts[artPrm]=true; return end

    -- Собираем оба сундука WagonLoot (те что ещё не наши)
    local chests = {}
    for _,v in ipairs(loot:GetChildren()) do
        if v.Name=="WagonLoot" then
            local p=v:FindFirstChild("LootGiver")
            if p then
                local cob = p:GetAttribute("OpenedBy") or ""
                if not cob:find(LP.Name,1,true) then
                    table.insert(chests,{model=v,prompt=p})
                end
            end
        end
    end
    return artPrm, chests, art
end

local function doArtifact()
    if St.ArtActive or not alive() then return end
    local artPrm,chests,artModel = findArtData()
    if not artPrm then return end
    St.ArtActive = true

    local artPos = artModel:GetPivot().Position

    -- 1. Лутаем ОБА сундука до кражи (нет розыска)
    for _,chest in ipairs(chests) do
        if not alive() then break end
        local cpos = chest.model:GetPivot().Position
        if flyTo(cpos+Vector3.new(0,3,0)) then
            task.wait(0.4)
            for _=1,5 do pcall(fireproximityprompt,chest.prompt); task.wait(0.2) end
            St.Chests+=1
        end
    end

    -- 2. Летим к артефакту и проверяем что реально рядом
    if not flyTo(artPos+Vector3.new(0,3,0)) then St.ArtActive=false; return end
    local _,r = getChar()
    if not r or (r.Position-artPos).Magnitude>20 or not artPrm.Parent then
        St.ArtActive=false; return
    end

    -- 3. Крадём
    for _=1,6 do pcall(fireproximityprompt,artPrm); task.wait(0.15) end
    LootedArts[artPrm]=true
    local stoleAt = tick()

    -- 4. Вверх 600 студов
    local _,r2 = getChar()
    if r2 then flyTo(Vector3.new(r2.Position.X, r2.Position.Y+600, r2.Position.Z), 100) end

    -- 5. Висим BodyPosition пока не останется 5 сек
    local _,rr = getChar()
    if rr then
        stopFly()
        local hold = Instance.new("BodyPosition",rr)
        hold.Name="FarmBP"; hold.MaxForce=Vector3.new(9e5,9e5,9e5)
        hold.P=1e5; hold.D=2000; hold.Position=rr.Position
        while tick()-stoleAt<25 and Cfg.Enabled and alive() do
            local _,rrr = getChar()
            if rrr and rrr:FindFirstChild("FarmBP") then
                rrr.FarmBP.Position = rrr.Position
            end
            task.wait(0.5)
        end
        stopFly()
    end

    -- 6. Вниз + ждём деньги
    if alive() then
        flyTo(Vector3.new(artPos.X, artPos.Y+5, artPos.Z), 60)
        task.wait(2.5)
    end

    -- 7. Продаём
    doSell()
    St.ArtActive = false
end

-- ====== ГЛАВНЫЙ ЦИКЛ ======
task.spawn(function()
    while task.wait(0.5) do
        if not Cfg.Enabled then continue end
        if not alive() then
            St.Target=nil; St.ArtActive=false
            Camera.CameraType=Enum.CameraType.Custom; stopFly()
            repeat task.wait(0.5) until alive()
            task.wait(2); continue
        end

        if St.Chests>=Cfg.SellEvery then doSell(); continue end

        if Cfg.ArtFarm and not St.ArtActive and findArtData() then
            doArtifact(); continue
        end

        local mission,missionPos = getNearestMission()
        if not mission or not missionPos then task.wait(1); continue end

        flyTo(missionPos); if not alive() then continue end

        local idle=0
        while mission:GetAttribute("EnemiesLeft")>0 and Cfg.Enabled and alive() do
            if Cfg.ArtFarm and not St.ArtActive then
                local ms=WS:FindFirstChild("Missions")
                if ms and ms:FindFirstChild("ArtifactMission") and findArtData() then break end
            end
            local mob=getClosestMob(missionPos)
            if not mob then
                idle+=0.5; if idle>=6 then break end
                task.wait(0.5); continue
            end
            idle=0; fightMob(mob,mission)
        end

        if alive() then lootChests(missionPos) end
    end
end)

-- ====== ORION UI ======
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

OrionLib:MakeNotification({
    Name = "WW V10",
    Content = "RightShift - скрыть/показать | TopNov",
    Time = 4
})

local Win = OrionLib:MakeWindow({
    Name = "WIZARD WEST V10 | TopNov",
    HidePremium = true,
    SaveConfig = true,           -- Orion сам сохраняет
    ConfigFolder = "WizWestV10",
    IntroEnabled = false,
})

-- TAB: Основное
local TabMain = Win:MakeTab({ Name="Фарм", Icon="rbxassetid://4483362458", PremiumOnly=false })

TabMain:AddToggle({
    Name = "AutoFarm",
    Default = false,
    Save = true,
    Flag = "Farm",
    Callback = function(v)
        Cfg.Enabled = v
        if not v then
            St.Target=nil; St.ArtActive=false
            Camera.CameraType=Enum.CameraType.Custom; stopFly()
        end
    end
})

TabMain:AddToggle({
    Name = "Авто-Артефакт",
    Default = false,
    Save = true,
    Flag = "ArtFarm",
    Callback = function(v)
        Cfg.ArtFarm = v
        LootedArts = {}  -- сбрасываем память
    end
})

TabMain:AddSlider({
    Name = "Продавать каждые N",
    Min = 1, Max = 10, Default = 3,
    Save = true, Flag = "SellEvery",
    Callback = function(v) Cfg.SellEvery = v end
})

TabMain:AddSlider({
    Name = "Скорость полёта",
    Min = 20, Max = 150, Default = 50,
    Save = true, Flag = "FlySpeed",
    Callback = function(v) Cfg.FlySpeed = v end
})

TabMain:AddSlider({
    Name = "Высота над мобом",
    Min = 0, Max = 25, Default = 8,
    Save = true, Flag = "MobH",
    Callback = function(v) Cfg.MobHeight = v end
})

TabMain:AddButton({
    Name = "Сохранить TP Point",
    Callback = function()
        local _,r = getChar()
        if r then
            Cfg.SellTP = r.Position
            OrionLib:MakeNotification({Name="OK",Content=("TP: %.0f %.0f %.0f"):format(r.Position.X,r.Position.Y,r.Position.Z),Time=2})
        end
    end
})

TabMain:AddButton({
    Name = "Сохранить Walk Point",
    Callback = function()
        local _,r = getChar()
        if r then
            Cfg.SellWalk = r.Position
            OrionLib:MakeNotification({Name="OK",Content=("Walk: %.0f %.0f %.0f"):format(r.Position.X,r.Position.Y,r.Position.Z),Time=2})
        end
    end
})

TabMain:AddButton({
    Name = "Сбросить точки (хардкод)",
    Callback = function()
        Cfg.SellTP=nil; Cfg.SellWalk=nil
        OrionLib:MakeNotification({Name="OK",Content="Продавец: хардкод из скана",Time=2})
    end
})

-- TAB: Бой
local TabCombat = Win:MakeTab({ Name="Бой", Icon="rbxassetid://4483362458", PremiumOnly=false })

TabCombat:AddTextbox({
    Name = "Клавиша оружия",
    Default = "R",
    TextDisappear = false,
    Save = true,
    Flag = "WeaponKey",
    Callback = function(v) if v~="" then Cfg.WeaponKey=v end end
})

TabCombat:AddTextbox({
    Name = "Клавиша хила",
    Default = "",
    TextDisappear = false,
    Save = true,
    Flag = "HealKey",
    Callback = function(v) Cfg.HealKey=v end
})

TabCombat:AddSlider({
    Name = "Хил при HP%",
    Min = 10, Max = 90, Default = 40,
    Save = true, Flag = "HealHP",
    Callback = function(v) Cfg.HealHP=v end
})

TabCombat:AddTextbox({
    Name = "Скилл 1",
    Default = "",
    TextDisappear = false,
    Save = true,
    Flag = "Skill1",
    Callback = function(v) Cfg.Skill1=v end
})

TabCombat:AddTextbox({
    Name = "Скилл 2",
    Default = "",
    TextDisappear = false,
    Save = true,
    Flag = "Skill2",
    Callback = function(v) Cfg.Skill2=v end
})

TabCombat:AddTextbox({
    Name = "Скилл 3",
    Default = "",
    TextDisappear = false,
    Save = true,
    Flag = "Skill3",
    Callback = function(v) Cfg.Skill3=v end
})

TabCombat:AddSlider({
    Name = "Задержка атаки x0.1s",
    Min = 1, Max = 15, Default = 3,
    Save = true, Flag = "AtkDelay",
    Callback = function(v) Cfg.AtkDelay=v*0.1 end
})

-- TAB: Читы
local TabCheat = Win:MakeTab({ Name="Обходы AC", Icon="rbxassetid://4483362458", PremiumOnly=false })

TabCheat:AddToggle({
    Name = "NoClip (сквозь стены)",
    Default = false,
    Save = true,
    Flag = "NoClip",
    Callback = function(v) Cfg.NoClip=v end
})

TabCheat:AddToggle({
    Name = "Нет урона от падения",
    Default = false,
    Save = true,
    Flag = "NoFall",
    Callback = function(v)
        Cfg.NoFall=v
        local c=LP.Character
        if c then
            local h=c:FindFirstChild("Humanoid")
            if h then h.PlatformStand = false end
        end
    end
})

TabCheat:AddButton({
    Name = "Убить локальные AC-скрипты",
    Callback = function()
        local killed = 0
        local function killAC(container)
            if not container then return end
            for _,v in ipairs(container:GetDescendants()) do
                if (v:IsA("LocalScript") or v:IsA("ModuleScript")) then
                    local n=v.Name:lower()
                    if n:find("anti") or n:find("bound") or n:find("flysmoke") or n:find("speed") or n:find("cheat") then
                        pcall(function() v.Disabled=true end)
                        pcall(function() v:Destroy() end)
                        killed+=1
                    end
                end
            end
        end
        killAC(LP.Character)
        killAC(LP.PlayerScripts)
        killAC(LP.PlayerGui)
        OrionLib:MakeNotification({Name="AC",Content="Убито скриптов: "..killed,Time=3})
    end
})

TabCheat:AddButton({
    Name = "Чёрный экран (FPS++)",
    Callback = function()
        -- Прячем всё кроме персонажа
        for _,v in ipairs(WS:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Model")) then
                pcall(function() v.Transparency=1 end)
            end
        end
        Lighting.Brightness = 0
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        OrionLib:MakeNotification({Name="FPS",Content="Чёрный экран активирован!",Time=2})
    end
})

-- TAB: Статистика
local TabInfo = Win:MakeTab({ Name="Стат", Icon="rbxassetid://4483362458", PremiumOnly=false })

TabInfo:AddButton({
    Name = "Показать статистику",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Статистика",
            Content = ("Сундуков: %d | Продано: %d | Артефакт: %s"):format(
                St.Chests, St.Sold, St.ArtActive and "ACTIVE" or "ожидание"),
            Time = 5
        })
    end
})

-- RightShift скрыть/показать
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        OrionLib:ToggleUI()
    end
end)

OrionLib:Init()