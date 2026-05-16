if _G.__f17_squitgame_client_loaded then
    return
end
_G.__f17_squitgame_client_loaded = true

local activeGame = false
local gameRunning = false
local gamePhase = 'green'
local gameStartAt = 0
local gameEndsAt = 0
local phaseEndsAt = 0
local phaseDuration = 0
local redAnchor = nil
local redStartedAt = 0
local oldOutfit = nil
local finishBlip = nil
local guards = {}
local guardsShooting = false
local doll = nil
local raceSlot = 1
local ending = false
local returningToStart = false
local outfitKvpKey = 'f17_squitgame_old_outfit'

local function clearSavedOutfitKvp()
    DeleteResourceKvp(outfitKvpKey)
end

local function saveOutfitKvp()
    if oldOutfit then
        SetResourceKvp(outfitKvpKey, json.encode(oldOutfit))
    end
end

local function loadOutfitKvp()
    local raw = GetResourceKvpString(outfitKvpKey)
    if not raw or raw == '' then return nil end

    local ok, data = pcall(json.decode, raw)
    if ok and data then
        return data
    end

    clearSavedOutfitKvp()
    return nil
end

local function notify(message, notifyType, duration)
    if no and no.Notify then
        no:Notify(message, notifyType or 'primary', duration or 3500)
    elseif QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, notifyType or 'primary', duration or 3500)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function formatTime(seconds)
    local total = math.max(0, math.floor(seconds))
    return string.format('%02d:%02d', math.floor(total / 60), total % 60)
end

local function getPedSex(ped)
    return IsPedModel(ped, `mp_f_freemode_01`) and 'female' or 'male'
end

local function saveCurrentOutfit()
    local ped = PlayerPedId()

    if GetResourceState('fivem-appearance') == 'started' then
        local ok, appearance = pcall(function()
            return exports['fivem-appearance']:getPedAppearance(ped)
        end)

        if ok and appearance then
            oldOutfit = { appearance = appearance }
            saveOutfitKvp()
            return
        end
    end

    oldOutfit = { components = {}, props = {} }

    for component = 0, 11 do
        oldOutfit.components[component] = {
            drawable = GetPedDrawableVariation(ped, component),
            texture = GetPedTextureVariation(ped, component),
            palette = GetPedPaletteVariation(ped, component)
        }
    end

    for prop = 0, 7 do
        oldOutfit.props[prop] = {
            drawable = GetPedPropIndex(ped, prop),
            texture = GetPedPropTextureIndex(ped, prop)
        }
    end

    saveOutfitKvp()
end

local function applySportsOutfit()
    local ped = PlayerPedId()
    local outfit = Config.SportsOutfit[getPedSex(ped)]
    if not outfit then return end

    SetPedComponentVariation(ped, 3, outfit.arms or 0, 0, 0)
    SetPedComponentVariation(ped, 4, outfit.pants_1 or 0, outfit.pants_2 or 0, 0)
    SetPedComponentVariation(ped, 6, outfit.shoes_1 or 0, outfit.shoes_2 or 0, 0)
    SetPedComponentVariation(ped, 8, outfit.tshirt_1 or 0, outfit.tshirt_2 or 0, 0)
    SetPedComponentVariation(ped, 11, outfit.torso_1 or 0, outfit.torso_2 or 0, 0)

    if outfit.helmet_1 and outfit.helmet_1 >= 0 then
        SetPedPropIndex(ped, 0, outfit.helmet_1, outfit.helmet_2 or 0, true)
    else
        ClearPedProp(ped, 0)
    end

    if outfit.glasses_1 and outfit.glasses_1 >= 0 then
        SetPedPropIndex(ped, 1, outfit.glasses_1, outfit.glasses_2 or 0, true)
    else
        ClearPedProp(ped, 1)
    end
end

local function saveAndApplyOutfit()
    saveCurrentOutfit()

    if GetResourceState('fivem-appearance') == 'started' then
        -- Native component apply keeps this resource independent while still compatible.
        applySportsOutfit()
        return
    end

    if GetResourceState('qb-clothing') == 'started' then
        applySportsOutfit()
        return
    end

    applySportsOutfit()
end

local function restoreOutfit()
    if not oldOutfit then return end

    local ped = PlayerPedId()

    if oldOutfit.appearance and GetResourceState('fivem-appearance') == 'started' then
        pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, oldOutfit.appearance)
        end)
        oldOutfit = nil
        clearSavedOutfitKvp()
        return
    end

    for component, data in pairs(oldOutfit.components or {}) do
        SetPedComponentVariation(ped, component, data.drawable, data.texture, data.palette)
    end

    for prop, data in pairs(oldOutfit.props or {}) do
        if data.drawable and data.drawable >= 0 then
            SetPedPropIndex(ped, prop, data.drawable, data.texture or 0, true)
        else
            ClearPedProp(ped, prop)
        end
    end

    oldOutfit = nil
    clearSavedOutfitKvp()
end

local function getGridCoords(coords, slot)
    local index = math.max((slot or 1) - 1, 0)
    local column = index % (Config.StartGridColumns or 6)
    local row = math.floor(index / (Config.StartGridColumns or 6))
    local spacing = Config.StartGridSpacing or 1.5
    local heading = math.rad(coords.w)
    local forward = vector3(-math.sin(heading), math.cos(heading), 0.0)
    local right = vector3(math.cos(heading), math.sin(heading), 0.0)
    local lateral = (column - (((Config.StartGridColumns or 6) - 1) / 2)) * spacing
    local back = row * spacing * 1.4

    return vector4(
        coords.x + right.x * lateral - forward.x * back,
        coords.y + right.y * lateral - forward.y * back,
        coords.z,
        coords.w
    )
end

local function clearFinishBlip()
    if finishBlip and DoesBlipExist(finishBlip) then
        RemoveBlip(finishBlip)
    end
    finishBlip = nil
end

local function createFinishBlip()
    clearFinishBlip()
    finishBlip = AddBlipForCoord(Config.FinishCoords.x, Config.FinishCoords.y, Config.FinishCoords.z)
    SetBlipSprite(finishBlip, 38)
    SetBlipColour(finishBlip, 2)
    SetBlipScale(finishBlip, 0.9)
    SetBlipAsShortRange(finishBlip, false)
    SetBlipRoute(finishBlip, true)
    SetBlipRouteColour(finishBlip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Lang.finishBlip)
    EndTextCommandSetBlipName(finishBlip)
end

local function getHash(value)
    if type(value) == 'number' then return value end
    return GetHashKey(value)
end

local function requestModel(model)
    local hash = getHash(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasModelLoaded(hash) and hash or nil
end

local function getGroundedCoords(coords, zOffset)
    zOffset = zOffset or 0.03
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    for _ = 1, 30 do
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
        if found then
            return coords.x, coords.y, groundZ + zOffset
        end

        Wait(0)
    end

    return coords.x, coords.y, coords.z + zOffset
end

local function applyEntityScale(entity, scale)
    scale = tonumber(scale) or 1.0
    if scale == 1.0 or not DoesEntityExist(entity) then return end

    local coords = GetEntityCoords(entity)
    local forward = GetEntityForwardVector(entity)
    local rightX = forward.y
    local rightY = -forward.x

    SetEntityMatrix(
        entity,
        forward.x * scale, forward.y * scale, forward.z * scale,
        rightX * scale, rightY * scale, 0.0,
        0.0, 0.0, scale,
        coords.x, coords.y, coords.z
    )
end

local function deleteGuards()
    guardsShooting = false

    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end

    guards = {}
end

local function deleteDoll()
    if doll and DoesEntityExist(doll) then
        DeleteEntity(doll)
    end

    doll = nil
end

local function spawnGuards()
    deleteGuards()

    if not Config.Guards or not Config.Guards.enabled then return end

    local model = requestModel(Config.Guards.model or 's_m_y_blackops_01')
    if not model then return end

    local weapon = getHash(Config.Guards.weapon or `WEAPON_CARBINERIFLE`)
    for _, coords in ipairs(Config.Guards.positions or {}) do
        local x, y, z = getGroundedCoords(coords, Config.Guards.groundOffset or 0.35)
        local guard = CreatePed(4, model, x, y, z, coords.w or 0.0, false, true)
        if DoesEntityExist(guard) then
            SetEntityAsMissionEntity(guard, true, true)
            SetEntityCoordsNoOffset(guard, x, y, z, false, false, false)
            SetEntityInvincible(guard, true)
            FreezeEntityPosition(guard, true)
            SetBlockingOfNonTemporaryEvents(guard, true)
            SetPedCanRagdoll(guard, false)
            SetPedFleeAttributes(guard, 0, false)
            SetPedCombatAttributes(guard, 46, true)
            GiveWeaponToPed(guard, weapon, 999, false, true)
            SetCurrentPedWeapon(guard, weapon, true)
            table.insert(guards, guard)
        end
    end

    SetModelAsNoLongerNeeded(model)
end

local function spawnDoll()
    deleteDoll()

    if not Config.Doll or not Config.Doll.enabled then return end

    local model = requestModel(Config.Doll.model or 'prop_alien_egg_01')
    if not model then
        -- if Config.Debug then
        --     print(('[f17_Squitgame] Failed to load doll model: %s'):format(Config.Doll.model or 'prop_alien_egg_01'))
        -- end
        return
    end

    local coords = Config.Doll.coords
    if not coords then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local x, y, z = getGroundedCoords(coords, Config.Doll.groundOffset or 0.03)

    if Config.Doll.type == 'object' then
        doll = CreateObjectNoOffset(model, x, y, z, false, true, false)
        
        if DoesEntityExist(doll) then
            SetEntityHeading(doll, coords.w or 0.0)
            SetEntityCoordsNoOffset(doll, x, y, z, false, false, false)
            PlaceObjectOnGroundProperly(doll)
            SetEntityInvincible(doll, true)
            FreezeEntityPosition(doll, true)
            SetEntityCollision(doll, true, true)
            
            local scale = Config.Doll.scale or 1.0
            applyEntityScale(doll, scale)
            
            -- if Config.Debug then
            --     print(('[f17_Squitgame] Object doll spawned with scale: %.2f'):format(scale))
            -- end
        end
    else
        doll = CreatePed(4, model, x, y, z, coords.w or 0.0, false, true)
        
        if DoesEntityExist(doll) then
            SetEntityAsMissionEntity(doll, true, true)
            SetEntityHeading(doll, coords.w or 0.0)
            SetEntityCoordsNoOffset(doll, x, y, z, false, false, false)
            SetEntityInvincible(doll, true)
            FreezeEntityPosition(doll, true)
            SetEntityCollision(doll, true, true)

            local scale = Config.Doll.scale or 1.0
            SetPedConfigFlag(doll, 223, true)
            applyEntityScale(doll, scale)

            SetBlockingOfNonTemporaryEvents(doll, true)
            SetPedCanRagdoll(doll, false)
            SetPedFleeAttributes(doll, 0, false)
            
            -- if Config.Debug then
            --     print(('[f17_Squitgame] Ped doll spawned with scale: %.2f'):format(scale))
            -- end
        end
    end

    SetModelAsNoLongerNeeded(model)
end

local function guardsShootPlayer()
    if guardsShooting then return end
    guardsShooting = true
    if #guards == 0 then return end

    local shootDelay = (Config.Guards and Config.Guards.shootDelayMs) or 900
    local ped = PlayerPedId()
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            FreezeEntityPosition(guard, false)
            ClearPedTasksImmediately(guard)
            TaskAimGunAtEntity(guard, ped, 450, false)
        end
    end

    Wait(250)

    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            TaskShootAtEntity(guard, ped, shootDelay, `FIRING_PATTERN_FULL_AUTO`)
        end
    end

    Wait(shootDelay)
end

local function sendUi(action, payload)
    payload = payload or {}
    payload.action = action
    SendNUIMessage(payload)
end

local function getUiStatePayload()
    local now = GetGameTimer()
    local remaining = 0
    local currentPhaseRemaining = 0

    if gameEndsAt > 0 then
        remaining = math.ceil(math.max(0, gameEndsAt - now) / 1000)
    end

    if phaseEndsAt > 0 then
        currentPhaseRemaining = math.max(0, phaseEndsAt - now)
    end

    return {
        phase = gamePhase,
        phaseDuration = phaseDuration,
        phaseRemaining = currentPhaseRemaining,
        remaining = remaining
    }
end

local function syncUi(action, extra)
    local payload = getUiStatePayload()

    if extra then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end

    sendUi(action, payload)
end

local function playSound(name, volume)
    if not Config.EnableSound then return end
    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = name,
        transactionVolume = volume or 0.45
    })
end

local function setPhase(phase, duration, remaining)
    gamePhase = phase
    phaseDuration = tonumber(duration) or 0
    phaseEndsAt = GetGameTimer() + (tonumber(remaining) or phaseDuration)

    if phase == 'red' then
        redAnchor = GetEntityCoords(PlayerPedId())
        redStartedAt = GetGameTimer()
        playSound('rightchose', 0.5)
    else
        redAnchor = nil
        redStartedAt = 0
        if phase == 'yellow' then
            playSound('rightchose', 0.42)
        end
    end

    syncUi('state')
end

local function cleanupGame()
    activeGame = false
    gameRunning = false
    ending = false
    returningToStart = false
    gamePhase = 'green'
    phaseDuration = 0
    phaseEndsAt = 0
    redAnchor = nil
    guardsShooting = false
    clearFinishBlip()
    deleteGuards()
    deleteDoll()
    restoreOutfit()
    sendUi('hide')

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    if Config.PassiveOnGame then
        SetLocalPlayerAsGhost(false)
    end

    if Config.UseRoutingBucket then
        TriggerServerEvent('f17_squitgame:server:setRoutingBucket', 0)
    end
end

local function returnPlayerToStart(reason, shootBeforeReturn)
    if returningToStart or not activeGame or ending then return end
    returningToStart = true

    local coords = getGridCoords(Config.StartCoords, raceSlot or 1)
    local ped = PlayerPedId()

    notify(reason or Config.Lang.loseMove, 'error', 3500)

    if shootBeforeReturn then
        guardsShootPlayer()
    end

    DoScreenFadeOut(300)
    Wait(350)

    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) or LocalPlayer.state.isDead then
        Config.ReviveFunction()
        Wait(300)
        ped = PlayerPedId()
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w)
    SetEntityHealth(ped, math.max(GetEntityHealth(ped), 200))
    DoScreenFadeIn(300)

    if gamePhase == 'red' then
        redAnchor = GetEntityCoords(ped)
        redStartedAt = GetGameTimer()
    end

    guardsShooting = false
    returningToStart = false
end

local function finishGame()
    if not activeGame or ending then return end
    ending = true

    local elapsed = GetGameTimer() - gameStartAt
    sendUi('result', { result = 'win' })
    notify(Config.Lang.win, 'success', 5000)
    TriggerServerEvent('f17_squitgame:server:finish', elapsed)

    Wait(900)
    cleanupGame()
end

local function cancelGame()
    if not activeGame or ending then return end
    ending = true

    sendUi('result', { result = 'cancel' })
    notify(Config.Lang.cancelled, 'error', 3500)
    TriggerServerEvent('f17_squitgame:server:cancel')

    Wait(900)
    cleanupGame()
end

local function timeoutGame()
    if not activeGame or ending then return end
    ending = true

    sendUi('result', { result = 'lose', reason = Config.Lang.loseTime })
    notify(Config.Lang.loseTime, 'error', 5000)
    TriggerServerEvent('f17_squitgame:server:timeout')

    Wait(900)
    cleanupGame()
end

local function isPedIgnoredForMovement(ped)
    return IsEntityDead(ped)
        or IsPedDeadOrDying(ped, true)
        or IsPedRagdoll(ped)
        or IsPedFalling(ped)
        or IsPedGettingUp(ped)
        or IsPedBeingStunned(ped)
        or IsPedInParachuteFreeFall(ped)
        or IsPedSwimming(ped)
end

local function startGame(slot)
    if activeGame then
        notify(Config.Lang.alreadyPlaying, 'error', 3500)
        return
    end

    local ped = PlayerPedId()
    local coords = getGridCoords(Config.StartCoords, slot or 1)
    raceSlot = slot or 1
    ending = false
    returningToStart = false
    gamePhase = 'green'
    phaseDuration = 0
    phaseEndsAt = 0
    activeGame = true
    gameRunning = false

    if Config.UseRoutingBucket then
        TriggerServerEvent('f17_squitgame:server:setRoutingBucket', Config.RoutingBucket)
    end

    DoScreenFadeOut(450)
    Wait(550)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w)
    ClearPedTasksImmediately(ped)
    DoScreenFadeIn(450)

    saveAndApplyOutfit()
    spawnGuards()
    spawnDoll()

    FreezeEntityPosition(ped, true)
    playSound('5count', 0.5)

    for count = (Config.CountdownSeconds or 5), 1, -1 do
        sendUi('countdown', { seconds = count })
        Wait(1000)
    end

    sendUi('countdownHide')

    gameStartAt = GetGameTimer()
    gameEndsAt = gameStartAt + (Config.GameDurationSeconds * 1000)
    FreezeEntityPosition(ped, false)
    if Config.PassiveOnGame then
        SetLocalPlayerAsGhost(true)
    end
    if Config.EnableEffects then
        StartScreenEffect("MinigameEndFranklin", 0, 0)
    end

    createFinishBlip()
    sendUi('show', {
        duration = Config.GameDurationSeconds,
        remaining = Config.GameDurationSeconds,
        phase = gamePhase,
        phaseDuration = 0,
        phaseRemaining = 0
    })
    gameRunning = true
    TriggerServerEvent('f17_squitgame:server:ready')

    CreateThread(function()
        Wait(1500)
        if activeGame and not ending and phaseDuration <= 0 then
            if Config.Debug then
                print('[f17_Squitgame] Phase sync missing, requesting again')
            end
            TriggerServerEvent('f17_squitgame:server:ready')
        end
    end)
end

RegisterNetEvent(Config.StartEventName, function()
    TriggerServerEvent('f17_squitgame:server:join')
end)

RegisterNetEvent('f17_squitgame:client:startGame', startGame)
RegisterNetEvent('f17_squitgame:client:notify', notify)
RegisterNetEvent('f17_squitgame:client:setPhase', function(phase, duration, remaining)
    if not activeGame or ending then return end
    -- if Config.Debug then
    --     print(('[f17_Squitgame] Phase sync: %s duration=%s remaining=%s'):format(tostring(phase), tostring(duration), tostring(remaining)))
    -- end
    setPhase(phase, duration, remaining)
    gameRunning = true
end)
RegisterNetEvent('f17_squitgame:client:forceCancel', function()
    cancelGame()
end)

RegisterCommand(Config.Command, function()
    TriggerServerEvent('f17_squitgame:server:join')
end, false)

RegisterCommand('squit_cancel', function()
    cancelGame()
end, false)

RegisterCommand('exit', function()
    if activeGame then
        cancelGame()
    end
end, false)

CreateThread(function()
    while true do
        if not activeGame or not gameRunning then
            Wait(500)
        else
            local now = GetGameTimer()
            if now >= gameEndsAt then
                timeoutGame()
            end

            syncUi('state')
            Wait(250)
        end
    end
end)

CreateThread(function()
    while true do
        if not activeGame or not gameRunning then
            Wait(500)
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local finish = Config.FinishCoords
            local dist = #(coords - finish)

            if dist <= (Config.MarkerDrawDistance or 250.0) then
                DrawMarker(4, finish.x, finish.y, finish.z - 1.0, 0, 0, 0, 0, 0, 0, 12.0, 0.1, 150.0, 80, 255, 145, 85, false, true, 2, false, false, false, false)
            end

            if dist <= (Config.FinishDistance or 4.5) then
                finishGame()
            end

            Wait(dist <= 80.0 and 0 or 180)
        end
    end
end)

CreateThread(function()
    while true do
        if not activeGame or not gameRunning or returningToStart or gamePhase ~= 'red' then
            Wait(250)
        else
            Wait(Config.RedCheckIntervalMs or 175)

            if activeGame and gameRunning and gamePhase == 'red' then
                local ped = PlayerPedId()
                if redAnchor and not isPedIgnoredForMovement(ped) and (GetGameTimer() - redStartedAt) >= (Config.RedGraceMs or 350) then
                    local coords = GetEntityCoords(ped)
                    local moved = #(coords - redAnchor)
                    local velocity = GetEntitySpeed(ped)

                    if moved > (Config.RedMoveThreshold or 0.22) and velocity > (Config.AllowSlightVelocity or 0.18) then
                        returnPlayerToStart(Config.Lang.loseMove, true)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        if not activeGame or returningToStart then
            Wait(500)
        else
            Wait(350)
            local ped = PlayerPedId()
            if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) or LocalPlayer.state.isDead then
                returnPlayerToStart('Ban da bi loai.')
            end
        end
    end
end)

CreateThread(function()
    Wait(1500)
    local savedOutfit = loadOutfitKvp()
    if savedOutfit then
        oldOutfit = savedOutfit
        restoreOutfit()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    cleanupGame()
    _G.__f17_squitgame_client_loaded = nil
end)
