-- LOADER (init.lua)
local BASE_URL = "https://raw.githubusercontent.com/hodinkola55-eng/wizard-west-autofarm/main/"

local function safeLoad(name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. name .. ".lua"))()
    end)
    if not success then
        warn("Failed to load module: " .. name .. " | Error: " .. tostring(result))
        return nil
    end
    return result
end

print("WW V10: Loading modules...")

local Farm = safeLoad("farm")
local UI = safeLoad("ui")

if Farm and UI then
    task.spawn(function()
        UI.init(Farm)
    end)
    
    task.spawn(function()
        Farm.mainLoop()
    end)
    
    print("WW V10: Successfully loaded!")
else
    warn("WW V10: Critical loading error. Check URLs.")
end
