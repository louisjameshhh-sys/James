-- BrainrotClient (LocalScript en StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local pickupEvent = ReplicatedStorage:WaitForChild("PickupBrainrotEvent")
local teleportEvent = ReplicatedStorage:WaitForChild("TeleportToBaseEvent")
local dropEvent = ReplicatedStorage:FindFirstChild("DropBrainrotEvent")

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local function criarBotao(nome, pos, callback)
    local botao = Instance.new("TextButton")
    botao.Size = UDim2.new(0, 160, 0, 36)
    botao.Position = pos
    botao.Text = nome
    botao.TextColor3 = Color3.new(1,1,1)
    botao.BackgroundColor3 = Color3.fromRGB(45,45,45)
    botao.BackgroundTransparency = 0
    botao.BorderSizePixel = 0
    botao.Parent = screenGui
    botao.MouseButton1Click:Connect(callback)
    return botao
end

-- Botones
local btnPickup = criarBotao("Recoger Brainrot (Cerca)", UDim2.new(0, 10, 0, 10), function()
    -- Buscar Brainrot más cercano en workspace.Brains
    local brains = workspace:FindFirstChild("Brains")
    if not brains then return end

    local closest = nil
    local bestDist = math.huge
    for _, br in pairs(brains:GetChildren()) do
        if br:IsA("Model") and br.PrimaryPart then
            local d = (hrp.Position - br.PrimaryPart.Position).Magnitude
            if d < bestDist then
                bestDist = d
                closest = br
            end
        end
    end

    if closest and bestDist <= 8 then
        -- request server to pickup
        pickupEvent:FireServer(closest)
    else
        -- Mensaje sencillo mientras (puedes hacer un Label)
        print("No hay Brainrot cerca")
    end
end)

local btnDrop = criarBotao("Soltar", UDim2.new(0, 10, 0, 56), function()
    if dropEvent then
        dropEvent:FireServer()
    else
        print("No hay evento de soltar en ReplicatedStorage (opcional).")
    end
end)

local btnTeleport = criarBotao("Ir a mi Base (con Brainrot)", UDim2.new(0, 10, 0, 102), function()
    teleportEvent:FireServer()
end)

-- Indicador visual sencillo: si el jugador sostiene un Brainrot (cliente no confía ciegamente en servidor,
-- pero para UX podemos monitorizar si el brain está parented al character)
local holding = false
local function checkHolding()
    local found = false
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Model") and child.Name ~= nil and child:FindFirstChild("PrimaryPart") then
            -- heurística simple: Brainrots que vienen de workspace.Brains pueden tener un nombre específico como "Brainrot"
            if child.Name:lower():find("brain") then
                found = true
                break
            end
        end
    end
    if found ~= holding then
        holding = found
        -- actualizar UI (cambiar color del botón)
        if holding then
            btnTeleport.BackgroundColor3 = Color3.fromRGB(50,150,50) -- verde si sostiene
        else
            btnTeleport.BackgroundColor3 = Color3.fromRGB(180,50,50) -- rojo si no
        end
    end
end

-- Reconectar cuando character reaparece
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    -- esperar un momento antes de chequear
    wait(0.2)
    checkHolding()
end)

-- Revisa cada 0.3s estado de holding (para feedback)
while true do
    checkHolding()
    wait(0.3)
end
