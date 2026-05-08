local Utils = STA_EngineRebuild_Utils or {}

-- Variables
Utils.modID = "STA_EngineRebuild"

Utils.SandboxDefaults = {
    ["MinMechanicsLevel"] = 2,
    ["EnginePartsRequired"] = 3,
    ["MinEngineCondition"] = 95,
}

-- Sandbox Functions

---@param key string
---@return any
local function getSandboxValue(key)
    local moduleName = Utils.modID
    if SandboxVars and SandboxVars[moduleName] and SandboxVars[moduleName][key] then
        return SandboxVars[moduleName][key]
    end
    return nil
end

---@param key string
---@return number|nil
function Utils.getSandboxNum(key)
    local defaultVal = Utils.SandboxDefaults[key]
    local val = getSandboxValue(key)
    if val == nil then return type(defaultVal) == "number" and defaultVal or nil end
    if type(val) == "number" then return val end
    if type(val) == "boolean" then return val and 1 or 0 end
    if type(val) == "string" then
        local num = tonumber(val)
        if num then return num end
    end
    return type(defaultVal) == "number" and defaultVal or nil
end

---@param key String
---@return Integer
function Utils.getSandboxInt(key)
    local num = Utils.getSandboxNum(key)
    return math.floor(num or 0)
end

_G.STA_EngineRebuild_Utils = Utils
return Utils