local waitingPlayers = {}
local waitingOrder = {}
local activePlayers = {}
local raceState = 'idle'
local currentRaceId = 0
local finishOrder = 0
local totalPlayers = 0
local lobbyThreadRunning = false
local lobbyEndsAt = 0
local phaseThreadRunning = false
local currentPhase = 'green'
local phaseDuration = 0
local phaseEndsAt = 0

local function getTimer()
    if GetGameTimer then
        return GetGameTimer()
    end

    return os.time() * 1000
end

local function randomDuration(name)
    local phase = Config.Cycle[name] or Config.Cycle.green
    return math.random(phase.min, phase.max)
end

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

local function notifyWaitingPlayers(message, notifyType, duration)
    for src in pairs(waitingPlayers) do
        notify(src, message, notifyType, duration)
    end
end

local function clearWaitingPlayers()
    waitingPlayers = {}
    waitingOrder = {}
end

local function sendPhase(src)
    local remaining = math.max(0, phaseEndsAt - getTimer())
    -- if Config.Debug then
    --     print(('[f17_Squitgame] Send phase %s to %s duration=%d remaining=%d'):format(currentPhase, src, phaseDuration, remaining))
    -- end
    TriggerClientEvent('f17_squitgame:client:setPhase', src, currentPhase, phaseDuration, remaining)
end

local function broadcastPhase()
    for src, session in pairs(activePlayers) do
        if session.ready then
            sendPhase(src)
        end
    end
end

local function nextPhase(phase)
    if phase == 'green' then
        return 'yellow'
    end

    if phase == 'yellow' then
        return 'red'
    end

    return 'green'
end

local function startPhaseLoop()
    if phaseThreadRunning then return end

    phaseThreadRunning = true
    local raceId = currentRaceId

    CreateThread(function()
        currentPhase = 'green'

        while raceState == 'active' and currentRaceId == raceId and countTable(activePlayers) > 0 do
            phaseDuration = randomDuration(currentPhase)
            phaseEndsAt = getTimer() + phaseDuration
            broadcastPhase()

            local waitUntil = phaseEndsAt
            while raceState == 'active' and currentRaceId == raceId and getTimer() < waitUntil and countTable(activePlayers) > 0 do
                Wait(250)
            end

            currentPhase = nextPhase(currentPhase)
        end

        phaseThreadRunning = false
        currentPhase = 'green'
        phaseDuration = 0
        phaseEndsAt = 0
    end)
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
        name = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or ''),
        ready = false
    }

    TriggerClientEvent('f17_squitgame:client:startGame', src, slot)
end

local function startWaitingPlayers()
    if raceState ~= 'waiting' then return end

    currentRaceId = currentRaceId + 1
    finishOrder = 0
    totalPlayers = 0
    activePlayers = {}
    raceState = 'active'

    for _, src in ipairs(waitingOrder) do
        if waitingPlayers[src] and QBCore.Functions.GetPlayer(src) then
            totalPlayers = totalPlayers + 1
            notify(src, Config.Lang.starting, 'primary', 5000)
            registerActivePlayer(src, totalPlayers)
        end
    end

    clearWaitingPlayers()

    if totalPlayers == 0 then
        raceState = 'idle'
        finishOrder = 0
    end
end

local function startJoinLobby()
    if lobbyThreadRunning then return end

    lobbyThreadRunning = true
    raceState = 'waiting'

    local waitSeconds = Config.JoinWaitSeconds or 30
    lobbyEndsAt = getTimer() + (waitSeconds * 1000)
    CreateThread(function()
        Wait(0)
        notifyWaitingPlayers((Config.Lang.lobbyStarted):format(waitSeconds), 'primary', 7000)

        for remaining = waitSeconds, 1, -1 do
            if raceState ~= 'waiting' then break end

            if remaining == 10 or remaining <= 5 then
                notifyWaitingPlayers(('Squid Game bat dau sau %d giay.'):format(remaining), 'primary', 1200)
            end

            Wait(1000)
        end

        lobbyThreadRunning = false
        lobbyEndsAt = 0
        startWaitingPlayers()
    end)
end

RegisterNetEvent('f17_squitgame:server:join', function()
    local src = source
    if activePlayers[src] then
        notify(src, Config.Lang.alreadyPlaying, 'error')
        return
    end

    if waitingPlayers[src] then
        notify(src, Config.Lang.lobbyAlreadyJoined, 'error')
        return
    end

    if raceState == 'idle' then
        clearWaitingPlayers()
        startJoinLobby()
    end

    if raceState ~= 'waiting' then
        notify(src, Config.Lang.gameRunning, 'error', 5000)
        return
    end

    waitingPlayers[src] = {
        joinedAt = getTimer()
    }
    waitingOrder[#waitingOrder + 1] = src

    notify(src, Config.Lang.lobbyJoined, 'success', 5000)
    if lobbyEndsAt > 0 then
        local remaining = math.ceil(math.max(0, lobbyEndsAt - getTimer()) / 1000)
        notify(src, ('Squid Game bat dau sau %d giay.'):format(remaining), 'primary', 5000)
    end
end)

RegisterNetEvent('f17_squitgame:server:ready', function()
    local src = source
    local session = activePlayers[src]
    if not session then return end

    session.ready = true

    if phaseThreadRunning and phaseDuration > 0 then
        sendPhase(src)
        return
    end

    startPhaseLoop()
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

RegisterNetEvent('f17_squitgame:server:timeout', function()
    local src = source
    if not activePlayers[src] then return end

    activePlayers[src] = nil

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
    clearWaitingPlayers()
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

    -- print(('[f17_Squitgame] Started %s with %d players'):format(label or 'Squit Game', totalPlayers))
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
