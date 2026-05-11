require "TimedActions/ISBaseTimedAction"
local Utils = require "STA_EngineRebuild_Utils"

STA_EngineRebuild_ISEngineRebuildAction = ISBaseTimedAction:derive("STA_EngineRebuild_ISEngineRebuildAction")

function STA_EngineRebuild_ISEngineRebuildAction:isValid()
    return true
end

function STA_EngineRebuild_ISEngineRebuildAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function STA_EngineRebuild_ISEngineRebuildAction:update()
    self.character:faceThisObject(self.vehicle)
    self.item:setJobDelta(self:getJobDelta())

    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function STA_EngineRebuild_ISEngineRebuildAction:start()
    self.item:setJobType(getText("IGUI_STA_EngineRebuild_RebuildEngine"))
    self:setActionAnim("VehicleWorkOnMid")
end

function STA_EngineRebuild_ISEngineRebuildAction:stop()
    self.item:setJobDelta(0)
    ISBaseTimedAction.stop(self)
end

function STA_EngineRebuild_ISEngineRebuildAction:perform()
    self.item:setJobDelta(0)
    ISBaseTimedAction.perform(self)
end

function STA_EngineRebuild_ISEngineRebuildAction:complete()
    local engineRepairLevel = self.vehicle:getScript():getEngineRepairLevel()
    local giveXP = self.character:getMechanicsItem(self.vehicle:getMechanicalID() .. "2") == nil
    local requiredParts = engineRepairLevel * Utils.getSandboxInt("EnginePartsRequired")

    if self.vehicle and self.part then
        if Utils.getSandboxBool("EnableIncrementalIncrease") then
            local incr = Utils.getSandboxInt("EngineIncrementAmount")
            if self.vehicle:getEngineQuality() + incr >= 100 then
                self.part:repair()
            else
                local oldQuality = self.vehicle:getEngineQuality()
                local newQuality = oldQuality + incr

                local loudness = self.vehicle:getScript():getEngineLoudness() * SandboxVars["ZombieAttractionMultiplier"]

                local oldPower = self.vehicle:getEnginePower()
                local maxPower = self.vehicle:getScript():getEngineForce()

                local newPower = oldPower + (incr / (100 - oldQuality)) * (maxPower - oldPower)
                newPower = math.min(newPower, maxPower)

                self.vehicle:setEngineFeature(newQuality, loudness, newPower)

                self.vehicle:updatePartStats()
                self.vehicle:updateBulletStats()
            end
        else
            self.part:repair()
        end
        if giveXP then
            addXp(self.character, Perks.Mechanics, 2 * requiredParts)
        end
        local items = self.character:getInventory():RemoveAll("EngineParts", tonumber(requiredParts))
        sendRemoveItemsFromContainer(self.character:getInventory(), items)
        self.vehicle:transmitEngine()
    end
    return true
end

function STA_EngineRebuild_ISEngineRebuildAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return self.maxTime
end

---@param character IsoPlayer
---@param part VehiclePart
---@param item InventoryItem
---@param maxTime integer
---@return ISBaseTimedAction
function STA_EngineRebuild_ISEngineRebuildAction:new(character, part, item, maxTime)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.vehicle = part:getVehicle()
    o.part = part
    o.item = item
    o.maxTime = maxTime
    o.jobType = "Rebuild Engine"
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    return o
end

return STA_EngineRebuild_ISEngineRebuildAction