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
    if self.vehicle and self.part then
        sendClientCommand(self.character, "STA_EngineRebuild", "RebuildEngine", { vehicleId = self.vehicle:getId(), partId = self.part:getId() })
    end
    ISBaseTimedAction.perform(self)
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