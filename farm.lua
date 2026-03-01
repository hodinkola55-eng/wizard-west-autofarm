-- FARM MODULE (farm.lua)
local Farm = {}

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local WS       = game:GetService("Workspace")
local VU       = game:GetService("VirtualUser")
local VIM      = game:GetService("VirtualInputManager")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")

local LP     = Players.LocalPlayer
local Camera = WS.CurrentCamera
local Events  = RS:WaitForChild("Events", 10)
local TrSell  = Events and Events:FindFirstChild("TrinketSellEvent")
local SELL_POS = Vector3.new(209.69, 75.88, -381.90)

Farm.Cfg = {
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

Farm.St = { Chests=0, Sold=0, ArtActive=false, Target=nil }
local LootedArts = {}

function Farm.getChar()
    local c = LP.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChild("Humanoid")
    if r and h and h.Health > 0 then return c,r,h end
end

function Farm.alive() return Farm.getChar() ~= nil end

function Farm.stopFly()
    local c = LP.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    for _,v in ipairs(r:GetChildren()) do
        if v.Name == "FarmAtt" or v.Name == "FarmBP" then v:Destroy() end
    end
    pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
end

local KeyMap = {["1"]="One",["2"]="Two",["3"]="Three",["4"]="Four",["5"]="Five",
                ["6"]="Six",["7"]="Seven",["8"]="Eight",["9"]="Nine",["0"]="Zero"}
function Farm.pressKey(k)
    if not k or k=="" then return end
    local n = KeyMap[k:upper()] or k:upper()
    local ok,e = pcall(function() return Enum.KeyCode[n] end)
    if ok and e then
        VIM:SendKeyEvent(true,e,false,game); task.wait(0.05)
        VIM:SendKeyEvent(false,e,false,game)
    end
end

function Farm.flyTo(pos, spd)
    local _,root = Farm.getChar(); if not root then return false end
    Farm.stopFly()
    local att = Instance.new("Attachment",root); att.Name="FarmAtt"
    local lv = Instance.new("LinearVelocity",att); lv.Name="FarmLV"
    lv.Attachment0=att; lv.MaxForce=9e5; lv.RelativeTo=Enum.ActuatorRelativeTo.World
    local speed = spd or Farm.Cfg.FlySpeed
    local t,ok = 0,false
    while Farm.Cfg.Enabled and Farm.alive() and t<20 do
        local _,r = Farm.getChar(); if not r then break end
        if (r.Position-pos).Magnitude < 4 then ok=true; break end
        lv.VectorVelocity = (pos-r.Position).Unit * speed
        t = t + task.wait()
    end
    Farm.stopFly(); return ok
end

function Farm.doSell()
    local pos = Farm.Cfg.SellTP or SELL_POS
    if not Farm.flyTo(pos) then return end
    if not Farm.alive() then return end
    if Farm.Cfg.SellWalk then
        local _,r,h = Farm.getChar()
        if r and h then
            h:MoveTo(Farm.Cfg.SellWalk)
            local t=0
            while Farm.alive() and (r.Position-Farm.Cfg.SellWalk).Magnitude>5 and t<6 do
                task.wait(0.2); t+=0.2
            end
        end
    end
    for _=1,5 do pcall(function() TrSell:FireServer() end); task.wait(0.25) end
    Farm.St.Sold = Farm.St.Sold + Farm.St.Chests; Farm.St.Chests = 0
end

function Farm.getNearestMission()
    local folder = WS:FindFirstChild("Missions")
    local _,root = Farm.getChar()
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

function Farm.getClosestMob(center)
    local _,myRoot = Farm.getChar(); if not myRoot then return end
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

function Farm.fightMob(mob, mission)
    local mobHum = mob:FindFirstChild("Humanoid")
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobHum or not mobRoot then return end
    local _,root = Farm.getChar(); if not root then return end

    local function behind()
        if not mobRoot.Parent then return nil end
        return (mobRoot.CFrame*CFrame.new(0,Farm.Cfg.MobHeight,5)).Position
    end

    local bp = behind()
    if bp and (root.Position-bp).Magnitude>20 then
        if not Farm.flyTo(bp) then return end
    end
    if not Farm.alive() then return end

    local _,r = Farm.getChar(); Farm.stopFly()
    local bpObj = Instance.new("BodyPosition",r)
    bpObj.Name="FarmBP"; bpObj.MaxForce=Vector3.new(9e5,9e5,9e5)
    bpObj.D=800; bpObj.P=8000; bpObj.Position=behind() or r.Position

    Farm.St.Target = mobRoot
    local atkT,healT,startHp = 0,0,mobHum.Health

    while mobHum.Health>0 and Farm.alive() and Farm.Cfg.Enabled do
        if not mobRoot.Parent then break end
        if mission:GetAttribute("EnemiesLeft")==0 then break end
        if Farm.Cfg.ArtFarm and not Farm.St.ArtActive then
            local am = WS:FindFirstChild("Missions")
            if am and am:FindFirstChild("ArtifactMission") then break end
        end

        local _,rr,hum = Farm.getChar(); if not rr then break end
        local newBp = behind(); if newBp then bpObj.Position=newBp end

        if Farm.Cfg.HealKey~="" and hum.Health<hum.MaxHealth*(Farm.Cfg.HealHP/100) then
            if tick()-healT>3 then Farm.pressKey(Farm.Cfg.HealKey); healT=tick() end
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
        if not tool then Farm.pressKey(Farm.Cfg.WeaponKey) end

        if tick()-atkT>Farm.Cfg.AtkDelay then
            if tool then tool:Activate() end
            atkT=tick()
        end

        if Farm.Cfg.Skill1~="" then Farm.pressKey(Farm.Cfg.Skill1) end
        if Farm.Cfg.Skill2~="" then Farm.pressKey(Farm.Cfg.Skill2) end
        if Farm.Cfg.Skill3~="" then Farm.pressKey(Farm.Cfg.Skill3) end
        task.wait(0.1)
    end
    Farm.stopFly(); Farm.St.Target=nil
end

function Farm.lootChests(pos)
    task.wait(1)
    local chestsFound = 0
    for _,v in ipairs(WS:GetChildren()) do
        if v.Name == "Chest" and (v:GetPivot().Position-pos).Magnitude<120 then
            local prm = v:FindFirstChildWhichIsA("ProximityPrompt",true)
            if prm then
                Farm.flyTo(v:GetPivot().Position + Vector3.new(0,3,0))
                task.wait(0.5)
                local startT = tick()
                while prm.Parent and prm.Enabled and tick()-startT < 5 do
                    pcall(fireproximityprompt, prm)
                    task.wait(0.2)
                end
                chestsFound = chestsFound + 1
            end
        end
    end
    Farm.St.Chests = Farm.St.Chests + chestsFound
end

function Farm.findArtData()
    local am = WS:FindFirstChild("Missions")
    if not am then return end
    local art = am:FindFirstChild("ArtifactMission")
    if not art then return end
    local smoke = art:FindFirstChild("SmokePart")
    if not smoke then return end
    return art, smoke:GetPivot().Position
end

function Farm.doArtifact()
    local art, artPos = Farm.findArtData()
    if not art or not artPos then return end
    if LootedArts[art] then return end
    Farm.St.ArtActive = true
    if not Farm.flyTo(artPos + Vector3.new(0,50,0)) then Farm.St.ArtActive=false; return end
    local t=0
    local mobs = WS:FindFirstChild("CapturedAI")
    while t<15 and Farm.Cfg.Enabled and Farm.alive() do
        local found = false
        if mobs then
            for _,v in ipairs(mobs:GetChildren()) do
                if (v:GetPivot().Position-artPos).Magnitude < 150 then found=true; break end
            end
        end
        if found then break end
        task.wait(1); t+=1
    end
    local idle=0
    while Farm.Cfg.Enabled and Farm.alive() do
        local m = Farm.getClosestMob(artPos)
        if not m then
            idle+=1; if idle>5 then break end
            task.wait(1); continue
        end
        idle=0; Farm.fightMob(m, art)
    end
    local stoleAt = tick()
    local prm = art:FindFirstChildWhichIsA("ProximityPrompt",true)
    if prm then
        Farm.flyTo(art:GetPivot().Position+Vector3.new(0,3,0))
        for _=1,15 do
            if not prm.Parent or not prm.Enabled then break end
            pcall(fireproximityprompt,prm); task.wait(0.3)
        end
    end
    LootedArts[art] = true
    local _,rr = Farm.getChar()
    if rr then
        Farm.stopFly()
        local hold = Instance.new("BodyPosition",rr)
        hold.Name="FarmBP"; hold.MaxForce=Vector3.new(9e5,9e5,9e5)
        hold.P=1e5; hold.D=2000; hold.Position=rr.Position
        while tick()-stoleAt<25 and Farm.Cfg.Enabled and Farm.alive() do
            local _,rrr = Farm.getChar()
            if rrr and rrr:FindFirstChild("FarmBP") then
                rrr.FarmBP.Position = rrr.Position
            end
            task.wait(0.5)
        end
        Farm.stopFly()
    end
    if Farm.alive() then
        Farm.flyTo(Vector3.new(artPos.X, artPos.Y+5, artPos.Z), 60)
        task.wait(2.5)
    end
    Farm.doSell()
    Farm.St.ArtActive = false
end

function Farm.mainLoop()
    while task.wait(0.5) do
        if not Farm.Cfg.Enabled then continue end
        if not Farm.alive() then
            Farm.St.Target=nil; Farm.St.ArtActive=false
            Camera.CameraType=Enum.CameraType.Custom; Farm.stopFly()
            repeat task.wait(0.5) until Farm.alive()
            task.wait(2); continue
        end
        if Farm.St.Chests>=Farm.Cfg.SellEvery then Farm.doSell(); continue end
        if Farm.Cfg.ArtFarm and not Farm.St.ArtActive and Farm.findArtData() then
            Farm.doArtifact(); continue
        end
        local mission,missionPos = Farm.getNearestMission()
        if not mission or not missionPos then task.wait(1); continue end
        Farm.flyTo(missionPos); if not Farm.alive() then continue end
        local idle=0
        while mission:GetAttribute("EnemiesLeft")>0 and Farm.Cfg.Enabled and Farm.alive() do
            if Farm.Cfg.ArtFarm and not Farm.St.ArtActive then
                local ms=WS:FindFirstChild("Missions")
                if ms and ms:FindFirstChild("ArtifactMission") and Farm.findArtData() then break end
            end
            local mob=Farm.getClosestMob(missionPos)
            if not mob then
                idle+=0.5; if idle>=6 then break end
                task.wait(0.5); continue
            end
            idle=0; Farm.fightMob(mob,mission)
        end
        if Farm.alive() then Farm.lootChests(missionPos) end
    end
end

return Farm
