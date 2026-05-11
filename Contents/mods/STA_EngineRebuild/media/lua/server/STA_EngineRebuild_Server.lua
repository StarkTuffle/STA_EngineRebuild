local Utils = require "STA_EngineRebuild_Utils"

local Server = STA_EngineRebuild_Server or {}

local function onClientCommand(module, command, playerObj, args)
    if module ~= "STA_EngineRebuild" then return end
    if command == "RebuildEngine" then
        if not playerObj then return end
        if not (args.vehicleId and args.partId) then return end

        local vehicle = getVehicleById(args.vehicleId)
        if not vehicle then return end
        local part = vehicle:getPartById(args.partId)
        if not part then return end

        local engineRepairLevel = vehicle:getScript():getEngineRepairLevel()
        local giveXP = playerObj:getMechanicsItem(vehicle:getMechanicalID() .. "2") == nil
        local requiredParts = engineRepairLevel * Utils.getSandboxInt("EnginePartsRequired")

        if Utils.getSandboxBool("EnableIncrementalIncrease") then
            local incr = Utils.getSandboxInt("EngineIncrementAmount")
            if vehicle:getEngineQuality() + incr >= 100 then
                part:repair()
            else
                local oldQuality = vehicle:getEngineQuality()
                local newQuality = oldQuality + incr

                local loudness = vehicle:getScript():getEngineLoudness() * SandboxVars["ZombieAttractionMultiplier"]

                local oldPower = vehicle:getEnginePower()
                local maxPower = vehicle:getScript():getEngineForce()

                local newPower = oldPower + (incr / (100 - oldQuality)) * (maxPower - oldPower)
                newPower = math.min(newPower, maxPower)

                vehicle:setEngineFeature(newQuality, loudness, newPower)

                vehicle:updatePartStats()
                vehicle:updateBulletStats()
            end
        else
            part:repair()
        end
        if giveXP then
            playerObj:getXp():AddXP(Perks.Mechanics, 2 * requiredParts)
            -- addXp(playerObj, Perks.Mechanics, 2 * requiredParts)
        end

        -- local items = playerObj:getInventory():RemoveAll("EngineParts", tonumber(requiredParts))
        playerObj:sendObjectChange('removeItemType', { type = "Base.EngineParts", count = tonumber(requiredParts) })
        vehicle:transmitEngine()
    end
end

Events.OnClientCommand.Add(onClientCommand)

_G.STA_EngineRebuild_Server = Server
return Server