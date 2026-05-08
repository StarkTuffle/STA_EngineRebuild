require "TimedActions/STA_EngineRebuild_ISEngineRebuildAction"
local Utils = require "STA_EngineRebuild_Utils"

local _old_doPartContextMenu = ISVehicleMechanics.doPartContextMenu

local function predicateNotBroken(item)
    return not item:isBroken()
end

---@param playerObj IsoPlayer
---@param part VehiclePart
---@return boolean
local function predicateCanRebuild(playerObj, part)
    if not (part:getVehicle():getEngineQuality() < 100) then return false end
    if not (part:getCondition() >= Utils.getSandboxNum("MinEngineCondition")) then return false end

    if not playerObj:getInventory():contains("Wrench") then return false end
    local engineRepairLevel = part:getVehicle():getScript():getEngineRepairLevel()
    if not (playerObj:getPerkLevel(Perks.Mechanics) >= math.min(10, Utils.getSandboxInt("MinMechanicsLevel") + engineRepairLevel)) then return false end
    if not (playerObj:getInventory():getCountTypeRecurse("Base.EngineParts") >= (Utils.getSandboxInt("EnginePartsRequired") * engineRepairLevel)) then return false end
    return true
end

---@param option umbrella.ISContextMenu.Option
---@param playerObj IsoPlayer
local function attachTooltip(option, playerObj, part)
    if not (option and playerObj) then return end

    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip.description = getText("Tooltip_craft_Needs") .. " : <LINE>"
    option.toolTip = tooltip

    local engineRepairLevel = part:getVehicle():getScript():getEngineRepairLevel()

    local engineQuality = part:getVehicle():getEngineQuality()
    if engineQuality == 100 then
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.bhs .. getText("IGUI_Vehicle_EngineQuality") .. engineQuality .. " <LINE>"
    else
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. getText("IGUI_Vehicle_EngineQuality") .. engineQuality .. " <LINE>"
    end

    local engineCondition = part:getCondition()
    if engineCondition < Utils.getSandboxInt("MinEngineCondition") then
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.bhs .. getText("Tooltip_Vehicle_EngineCondition", engineCondition) .. "/" .. Utils.getSandboxInt("MinEngineCondition") .. "% <LINE>"
    else
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. getText("Tooltip_Vehicle_EngineCondition", engineCondition) .. "/" .. Utils.getSandboxInt("MinEngineCondition") .. "% <LINE>"
    end

    local mechanicsLevel = playerObj:getPerkLevel(Perks.Mechanics)
    if mechanicsLevel < math.min(10, Utils.getSandboxInt("MinMechanicsLevel") + engineRepairLevel) then
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.bhs .. getText("IGUI_perks_Mechanics") .. " " .. mechanicsLevel .. "/" .. math.min(10, Utils.getSandboxInt("MinMechanicsLevel") + engineRepairLevel) .. " <LINE>"
    else
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. getText("IGUI_perks_Mechanics") .. " " .. mechanicsLevel .. "/" .. math.min(10, Utils.getSandboxInt("MinMechanicsLevel") + engineRepairLevel) .. " <LINE>"
    end

    local wrench = playerObj:getInventory():contains("Wrench")
    if not wrench then
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.bhs .. InventoryItemFactory.CreateItem("Base.Wrench"):getDisplayName() .. " 0/1 <LINE>"
    else
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. InventoryItemFactory.CreateItem("Base.Wrench"):getDisplayName() .. " 1/1 <LINE>"
    end

    local enginePartsCount = playerObj:getInventory():getCountTypeRecurse("Base.EngineParts")
    if enginePartsCount < (Utils.getSandboxInt("EnginePartsRequired") * engineRepairLevel) then
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.bhs .. InventoryItemFactory.CreateItem("Base.EngineParts"):getDisplayName()  .. " " .. enginePartsCount .. "/" .. (Utils.getSandboxInt("EnginePartsRequired") * engineRepairLevel) .. " <LINE>"
    else
        tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. InventoryItemFactory.CreateItem("Base.EngineParts"):getDisplayName() .. " " .. enginePartsCount .. "/" .. (Utils.getSandboxInt("EnginePartsRequired") * engineRepairLevel) .. " <LINE>"
    end
end

---@param playerObj IsoPlayer
---@param part VehiclePart
local function onEngineRebuild(playerObj, part)
    if not (playerObj and part) then return end
    if playerObj:getVehicle() then ISVehicleMenu.onExit(playerObj) end

    local item = playerObj:getInventory():getFirstTypeEvalRecurse("Base.Wrench", predicateNotBroken)
    -- local typeToItem, tagToItem = VehicleUtils.getItems(playerObj:getPlayerNum())
    -- local item = tagToItem["Wrench"][1]
    ISVehiclePartMenu.toPlayerInventory(playerObj, item)
    local parts = playerObj:getInventory():getSomeTypeRecurse("EngineParts", Utils.getSandboxInt("EnginePartsRequired") * part:getVehicle():getScript():getEngineRepairLevel())
    for i = 0, parts:size() - 1 do
        ISVehiclePartMenu.toPlayerInventory(playerObj, parts:get(i))
    end
    ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea()))

    local engineCover = nil
    local doorPart = part:getVehicle():getPartById("EngineDoor")
    if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() and not doorPart:getDoor():isOpen() then
        engineCover = doorPart
    end

    local engineRebuildLevel = math.min(10, part:getVehicle():getScript():getEngineRepairLevel() + Utils.getSandboxInt("MinMechanicsLevel"))
    local time = (engineRebuildLevel * 200) - math.max(0, (50 * (playerObj:getPerkLevel(Perks.Mechanics) - engineRebuildLevel)))

    if engineCover then
        if engineCover:getDoor():isLocked() and VehicleUtils.RequiredKeyNotFound(engineCover, playerObj) then
            ISTimedActionQueue.add(ISUnlockVehicleDoor:new(playerObj, engineCover))
        end
        ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, part:getVehicle(), engineCover))
        ISTimedActionQueue.add(STA_EngineRebuild_ISEngineRebuildAction:new(playerObj, part, item, time))
        ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, part:getVehicle(), engineCover))
    else
        ISTimedActionQueue.add(STA_EngineRebuild_ISEngineRebuildAction:new(playerObj, part, item, time))
    end
end

---@param part VehiclePart
---@param x number
---@param y number
function ISVehicleMechanics:doPartContextMenu(part, x, y)
    _old_doPartContextMenu(self, part, x, y)

    if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end

    if self.chr:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end

    if part:getId() == "Engine" and not VehicleUtils.RequiredKeyNotFound(part, self.chr) then
        if predicateCanRebuild(self.chr, part) then
            local option = self.context:addOption(getText("IGUI_STA_EngineRebuild_RebuildEngine"), self.chr, onEngineRebuild, part)
            attachTooltip(option, self.chr, part)
        else
            local option = self.context:addOption(getText("IGUI_STA_EngineRebuild_RebuildEngine"), nil, nil)
            option.notAvailable = true
            attachTooltip(option, self.chr, part)
        end
    end
end