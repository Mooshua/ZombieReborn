local Infect = {}
local Util = require("ZombieReborn.util.functions")

function Infect.InfectPlayer(hInflictor, hInfected, bKeepPosition)
    local vecOrigin = hInfected:GetOrigin()
    local vecAngles = hInfected:EyeAngles()

    --Give proper kill credit
    --By killing the player before they suicide from SetTeam
    if hInflictor then
        --SOS: Cannot get hAttacker to work
        --CTakeDamageInfo CreateDamageInfo (handle hInflictor, handle hAttacker, Vector force, Vector hitPos, float flDamage, int damageTypes)
        local cDamageInfo = CreateDamageInfo(hInflictor, nil, Vector(0,0,100), Vector(0,0,0), 1000, DMG_BULLET)
        hInfected:TakeDamage(cDamageInfo)
        DestroyDamageInfo(cDamageInfo)
    end

    hInfected:SetTeam(CS_TEAM_T)
    if bKeepPosition == false then return end
    hInfected:SetOrigin(vecOrigin)
    hInfected:SetAngles(vecAngles.x, vecAngles.y, vecAngles.z)
end

--  Expose infect to global scope to allow I/O to easily access it
Infect = Infect.Infect

function Infect.Infect_PickMotherZombies()
    local iMZRatio = CVARS.Infect.SpawnMZRatio
    local iMZMinimumCount = CVARS.Infect.SpawnMZMinCount
    local bSpawnType = (CVARS.Infect.SpawnType == 0)
    local tPlayerTable = Entities:FindAllByClassname("player")
    local iPlayerCount = #tPlayerTable--also counting spectators
    local iMotherZombieCount = math.floor(iPlayerCount / iMZRatio)
    local tMotherZombies = {}

    if iMotherZombieCount < iMZMinimumCount then iMotherZombieCount = iMZMinimumCount end
    
    -- remove players that belong to invalid teams from player table before proceeding with first infection logic
    for key,player in ipairs(tPlayerTable) do
        if player:GetTeam() < 2 then
            table.remove(tPlayerTable,key)
        end
    end
    
    -- make players who've been picked as MZ recently less likely to be picked again
    -- store a variable in player's script scope, which gets initialized with value 100 if they are picked to be a mother zombie
    -- the value represents a % chance of the player being skipped next time they are picked to be a mother zombie
    -- If the player is skipped, next random player is picked to be mother zombie (and same skip chance logic applies to him)
    -- the variable gets decreased by 20 every round (if it exists inside player's scope)
    local function PickMotherZombies()
        
        -- No players to choose from
        if tPlayerTable == nil or #tPlayerTable == 0 then
            iMotherZombieCount = #tMotherZombies
            return
        end
        
        local tPlayerTableShuffled = Util.shuffle(tPlayerTable)

        for idx = 1, #tPlayerTableShuffled do
            local hPlayer = tPlayerTableShuffled[idx]
            local tPlayerScope = hPlayer:GetOrCreatePrivateScriptScope()

            local iSkipChance = tPlayerScope.MZSpawn_SkipChance or 0
            -- if MZSpawn_SkipChance is not initialized, then the if below is guaranteed to not pass
            -- Roll for player's chance to skip being picked as MZ
            if math.random(1, 100) <= iSkipChance then
                -- player succeeded the roll and avoided being picked as MZ,
                -- reduce the value of his SkipChance script scope variable (just for good measure)
                tPlayerScope.MZSpawn_SkipChance = tPlayerScope.MZSpawn_SkipChance - 20
            else
                -- player failed the roll, pick him as MZ and initialize/refresh value of the SkipChance variable in his script scope
                tPlayerScope.MZSpawn_SkipChance = 100
                table.insert(tMotherZombies, hPlayer)

                -- remove player from players table so they can't be chosen again
                Util.removeValue(tPlayerTable, hPlayer)
            end

            if #tMotherZombies == iMotherZombieCount then return end
        end
    end

    repeat PickMotherZombies() until #tMotherZombies == iMotherZombieCount

    -- can iterate over the tMotherZombies here to print players who got picked as MZ to console
    -- (in the future, when we surely get access to player's steamid and nickname from lua)

    for index,player in pairs(tMotherZombies) do
        Infect(nil, player, bSpawnType)
    end
    print("Player count: " .. iPlayerCount .. ", Mother Zombies Spawned: " .. iMotherZombieCount)

    -- Mother zombie spawned
    ZR_ZOMBIE_SPAWNED = true
end

function Infect.Infect_OnRoundFreezeEnd()
    local iMZSpawntimeMinimum = CVARS.Infect.SpawnTimeMin
    local iMZSpawntimeMaximum = CVARS.Infect.SpawnTimeMax
    local iMZSpawntime = math.random(iMZSpawntimeMinimum,iMZSpawntimeMaximum)

    -- reduce mother zombie spawn skip chance for players who have that variable in their script scope
    for k,player in pairs(Entities:FindAllByClassname("player")) do
        local scope = player:GetOrCreatePrivateScriptScope()
        if scope.MZSpawn_SkipChance then scope.MZSpawn_SkipChance = scope.MZSpawn_SkipChance - 20 end
    end

    -- announce time remaining to infection and do infection at countdown<=0
    local MZSelection_Countdown = iMZSpawntime
    Timers:CreateTimer("MZSelection_Timer",{
        callback = function()
            if MZSelection_Countdown <= 0 then
                ScriptPrintMessageCenterAll("First infection has started!")
                ScriptPrintMessageChatAll(" \x04[Zombie:Reborn]\x01 First infection has started! Good luck, survivors!")
                Infect_PickMotherZombies()
                Timers:RemoveTimer("MZSelection_Timer")
            elseif MZSelection_Countdown <= 15 then
                if MZSelection_Countdown == 1 then ScriptPrintMessageCenterAll("First infection in \x071 second\x01!")
                else ScriptPrintMessageCenterAll("First infection in \x07"..MZSelection_Countdown.." seconds\x01!") end
                if MZSelection_Countdown % 5 == 0 then
                    ScriptPrintMessageChatAll(" \x04[Zombie:Reborn]\x01 First infection in \x07"..MZSelection_Countdown.." seconds\x01!")
                end
            end
            MZSelection_Countdown = MZSelection_Countdown - 1
            return 1
        end
    })
end

return Infect