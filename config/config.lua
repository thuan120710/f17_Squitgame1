Config = {}
QBCore = exports["qb-core"]:GetCoreObject()

Config.Debug = false
Config.Command = 'squitgame'
Config.StartEventName = 'f17_squitgame:start'

Config.UseRoutingBucket = true
Config.RoutingBucket = 1
Config.PassiveOnGame = true
Config.EnableSound = true
Config.EnableEffects = true
Config.CountdownSeconds = 5
Config.GameDurationSeconds = 240
Config.MarkerDrawDistance = 250.0
Config.FinishDistance = 4.5
Config.StartGridColumns = 6
Config.StartGridSpacing = 1.5

Config.StartCoords = vector4(1691.28, 3252.39, 40.98, 104.0)
Config.FinishCoords = vector3(1292.73, 3141.78, 40.41)
Config.SafeReturnCoords = vector4(-2621.66, 5253.71, 2108.04, 0.0)

Config.Guards = {
    enabled = true,
    model = 's_m_y_blackops_01',
    weapon = `WEAPON_CARBINERIFLE`,
    shootDelayMs = 900,
    positions = {
        vector4(1326.79, 3166.14, 40.53, 256.54),
        vector4(1327.11, 3163.3, 40.5, 298.65),
        vector4(1331.37, 3139.83, 40.45, 263.17),
        vector4(1332.14, 3135.56, 40.5, 292.12),
        vector4(1623.01, 3246.89, 40.54, 262.19),
        vector4(1623.87, 3244.13, 40.54, 281.13),
        vector4(1631.99, 3216.32, 40.48, 293.86),
        vector4(1633.03, 3212.43, 40.53, 266.95),
        vector4(1483.71, 3208.63, 40.53, 294.38),
        vector4(1484.78, 3206.14, 40.5, 281.81),
        vector4(1489.9, 3183.28, 40.45, 292.25),
        vector4(1491.01, 3180.6, 40.48, 281.15)

    }
}

Config.Cycle = {
    green = { min = 7500, max = 10500 },
    yellow = { min = 1300, max = 1800 },
    red = { min = 1200, max = 3600 }
}

Config.RedCheckIntervalMs = 175
Config.RedMoveThreshold = 0.26
Config.RedGraceMs = 1200
Config.AllowSlightVelocity = 0.22
Config.EliminateKillsPlayer = true

Config.SportsOutfit = {
    male = {
        tshirt_1 = 15, tshirt_2 = 0,
        torso_1 = 178, torso_2 = 0,
        arms = 30,
        pants_1 = 77, pants_2 = 0,
        shoes_1 = 5, shoes_2 = 0,
        helmet_1 = -1, helmet_2 = 0,
        glasses_1 = -1, glasses_2 = 0
    },
    female = {
        tshirt_1 = 14, tshirt_2 = 0,
        torso_1 = 180, torso_2 = 0,
        arms = 36,
        pants_1 = 79, pants_2 = 0,
        shoes_1 = 5, shoes_2 = 0,
        helmet_1 = -1, helmet_2 = 0,
        glasses_1 = -1, glasses_2 = 0
    }
}

Config.Rewards = {
    [1] = {
        points = 20,
        money = 10000,
        moneyType = 'tienkhoa',
        items = {
            { name = 'vatphamhoatdong', amount = 10 },
            { name = 'homf17city', amount = 1 }
        },
        xp = 20
    },
    [2] = {
        points = 15,
        money = 7500,
        moneyType = 'tienkhoa',
        items = {
            { name = 'vatphamhoatdong', amount = 7 },
            { name = 'hopquamayrui', amount = 1 }
        },
        xp = 15
    },
    [3] = {
        points = 10,
        money = 5000,
        moneyType = 'tienkhoa',
        items = {
            { name = 'vatphamhoatdong', amount = 5 }
        },
        xp = 10
    },
    [4] = {
        points = 5,
        money = 5000,
        moneyType = 'tienkhoa',
        items = {
            { name = 'vatphamhoatdong', amount = 3 }
        },
        xp = 10
    },
    [5] = {
        points = 0,
        money = 2000,
        moneyType = 'tienkhoa',
        items = {
            { name = 'vatphamhoatdong', amount = 1 }
        },
        xp = 5
    }
}

Config.ReviveFunction = function()
    TriggerEvent('ambulance:client:Revive', { Admin = true })
end

Config.LostPlayer = function(source)
end

Config.Lang = {
    starting = 'SQUID GAME sap bat dau',
    alreadyPlaying = 'Ban dang tham gia Squid Game roi.',
    win = 'Ban da ve dich!',
    loseMove = 'Ban da di chuyen khi DEN DO.',
    loseTime = 'Het gio, ban chua ve dich.',
    cancelled = 'Ban da roi khoi Squid Game.',
    finishBlip = 'Squid Game Finish'
}
