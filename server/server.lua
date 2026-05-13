local waitingPlayers = {}
local activePlayers = {}
local raceState = 'idle'
local currentRaceId = 0
local finishOrder = 0
local totalPlayers = 0

local function countTable(list)
    local count = 0
    for _ in pairs(list) do
        count = count + 1
    end
    return count
end

local function notify(src, message, notifyType, duration)
    TriggerClientEvent('f17_squitgame:client:notify', src, message, notifyType or 'primary', duration or 3500)
end

RegisterServerEvent('f17_squitgame:server:setRoutingBucket', function(dimension)
    if not Config.UseRoutingBucket then return end

    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if veh ~= 0 then
        SetEntityRoutingBucket(veh, dimension)
        SetPlayerRoutingBucket(src, dimension)
        TaskWarpPedIntoVehicle(GetPlayerPed(src), veh, -1)
    else
        SetPlayerRoutingBucket(src, dimension)
    end
end)

local function giveReward(src, top)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local index = math.min(math.max(tonumber(top) or 1, 1), 5)
    local reward = Config.Rewards[index]
    if not reward then return end

    if reward.money and reward.money > 0 then
        player.Functions.AddMoney(reward.moneyType or 'tienkhoa', reward.money, ('Squit Game Top %s'):format(index))
    end

    if reward.items and GetResourceState('ox_inventory') == 'started' then
        for _, item in ipairs(reward.items) do
            if item.name and item.amount and item.amount > 0 then
                exports.ox_inventory:AddItem(src, item.name, item.amount)
            end
        end
    end

    if reward.xp and reward.xp > 0 and GetResourceState('f17_level') == 'started' then
        exports['f17_level']:AddXP(src, reward.xp)
    end

    TriggerClientEvent('QBCore:Notify', src, ('[Squit Game]: HANG %d - nhan thuong va +%d diem xep hang!'):format(index, reward.points or 0), 'success', 15000)
end

local function resetIfEmpty()
    if raceState == 'active' and countTable(activePlayers) == 0 then
        raceState = 'idle'
        finishOrder = 0
        totalPlayers = 0
    end
end

local function registerActivePlayer(src, slot)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    activePlayers[src] = {
        raceId = currentRaceId,
        cid = player.PlayerData.citizenid,
        name = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or '')
    }

    TriggerClientEvent('f17_squitgame:client:startGame', src, slot)
end

RegisterNetEvent('f17_squitgame:server:join', function()
    local src = source
    if activePlayers[src] then
        notify(src, Config.Lang.alreadyPlaying, 'error')
        return
    end

    if raceState == 'idle' then
        currentRaceId = currentRaceId + 1
        finishOrder = 0
        totalPlayers = 1
        raceState = 'active'
        registerActivePlayer(src, 1)
        return
    end

    totalPlayers = totalPlayers + 1
    registerActivePlayer(src, totalPlayers)
end)

RegisterNetEvent('f17_squitgame:server:finish', function(elapsed)
    local src = source
    local session = activePlayers[src]
    if not session then return end

    activePlayers[src] = nil
    finishOrder = finishOrder + 1

    giveReward(src, finishOrder)

    if GetResourceState('f17_daotrentroi') == 'started' then
        local reward = Config.Rewards[math.min(finishOrder, 5)]
        if finishOrder <= 5 and reward and reward.points then
            exports['f17_daotrentroi']:AddPointsMinigame(src, '[SQUITGAME]', reward.points, finishOrder)
        else
            exports['f17_daotrentroi']:HinhPhatMinigame(src, '[SQUITGAME]', 'top', finishOrder)
        end
    end

    resetIfEmpty()
end)

RegisterNetEvent('f17_squitgame:server:eliminated', function(reason)
    local src = source
    if not activePlayers[src] then return end

    activePlayers[src] = nil

    if GetResourceState('f17_daotrentroi') == 'started' then
        exports['f17_daotrentroi']:HinhPhatMinigame(src, '[SQUITGAME]', 'thoat')
    end

    Config.LostPlayer(src)
    resetIfEmpty()
end)

RegisterNetEvent('f17_squitgame:server:cancel', function()
    local src = source
    if not activePlayers[src] then return end

    activePlayers[src] = nil

    if GetResourceState('f17_daotrentroi') == 'started' then
        exports['f17_daotrentroi']:HinhPhatMinigame(src, '[SQUITGAME]', 'thoat')
    end

    resetIfEmpty()
end)

function StartMiniGame(modeOrData, dataOrLabel, labelMiniGame)
    local data = dataOrLabel
    local label = labelMiniGame

    if type(modeOrData) == 'table' then
        data = modeOrData
        label = dataOrLabel
    end

    currentRaceId = currentRaceId + 1
    finishOrder = 0
    totalPlayers = 0
    activePlayers = {}
    waitingPlayers = {}
    raceState = 'active'

    for citizenId in pairs(data or {}) do
        local player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        if player then
            local src = player.PlayerData.source
            totalPlayers = totalPlayers + 1
            notify(src, Config.Lang.starting, 'primary', 5000)
            registerActivePlayer(src, totalPlayers)
        end
    end

    print(('[f17_Squitgame] Started %s with %d players'):format(label or 'Squit Game', totalPlayers))
end

exports('StartMiniGame', StartMiniGame)

RegisterNetEvent('f17_squitgame:server:startMiniGame', function(data, labelMiniGame)
    StartMiniGame(data, labelMiniGame)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activePlayers[src] and GetResourceState('f17_daotrentroi') == 'started' then
        exports['f17_daotrentroi']:HinhPhatMinigame(src, '[SQUITGAME]', 'thoat')
    end

    waitingPlayers[src] = nil
    activePlayers[src] = nil
    resetIfEmpty()
end)
