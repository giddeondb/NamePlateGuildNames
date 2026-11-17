local addonName = ...
local events = CreateFrame("Frame")
local active, labels = {}, {}
local castOwners, hookedCasts = {}, {}
local db
local failures, lastError = 0, nil
local MAX_ATTEMPTS = 8

local function Say(message)
    print("|cff88ccffNamePlateGuildNames:|r " .. message)
end

local function Plain(value)
    return not (issecretvalue and issecretvalue(value))
end

local function Accessible(frame)
    return frame and not frame:IsForbidden()
end

local function Position(state)
    local anchor = state.healthAnchor
    if Accessible(state.castContainer) and Accessible(state.castBar) then
        local visible = state.castBar:IsVisible()
        if not Plain(visible) then return end
        if visible then anchor = state.castContainer end
    end
    state.label:ClearAllPoints()
    state.label:SetPoint("TOP", anchor, "BOTTOM", 0, db.offset)
end

local function CastVisibilityChanged(frame)
    local state = castOwners[frame]
    if not state or not state.shown then return end
    local ok, err = pcall(Position, state)
    if not ok then
        failures = failures + 1
        lastError = Plain(err) and tostring(err) or "restricted layout error"
        -- Stop repeated callbacks until this plate is refreshed.
        castOwners[frame] = nil
    end
end

local function WatchCast(frame, state)
    if not Accessible(frame) then return end
    if not hookedCasts[frame] then
        frame:HookScript("OnShow", CastVisibilityChanged)
        frame:HookScript("OnHide", CastVisibilityChanged)
        hookedCasts[frame] = true
    end
    castOwners[frame] = state
end

local function Hide(state)
    -- Pooled cast frames must never keep a removed player's label alive.
    if state.castBar and castOwners[state.castBar] == state then castOwners[state.castBar] = nil end
    if state.castContainer and castOwners[state.castContainer] == state then castOwners[state.castContainer] = nil end
    if state.label and Accessible(state.label) then
        state.label:Hide()
        state.label:SetText("")
    end
    state.shown = false
end

local function Remove(unit)
    local state = active[unit]
    if state then Hide(state) end
    active[unit] = nil
end

local function Update(unit, state)
    Hide(state)
    if not db.enabled then state.reason = "disabled"; return end
    local exists = UnitExists(unit)
    local player = UnitIsPlayer(unit)
    local friendly = UnitIsFriend("player", unit)
    if not Plain(exists) or not Plain(player) or not Plain(friendly) then
        state.reason = "restricted data"; return
    end
    if not exists or not player then
        state.reason = "not a player"
        state.attempts = MAX_ATTEMPTS
        return
    end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not Accessible(plate) then state.reason = "no accessible plate"; return end
    local guild = GetGuildInfo(unit)
    if not Plain(guild) then state.reason = "restricted guild"; return end
    if type(guild) ~= "string" or guild == "" then
        state.reason = "guild absent or unavailable"; return
    end
    -- Keep our label on the base plate, since Blizzard pools its UnitFrame separately.
    local anchor = plate
    if Accessible(plate.UnitFrame) and Accessible(plate.UnitFrame.HealthBarsContainer) then
        anchor = plate.UnitFrame.HealthBarsContainer
    end
    local label = labels[plate]
    if not label then
        label = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        labels[plate] = label
    end
    state.label = label
    state.healthAnchor = anchor
    state.castContainer, state.castBar = nil, nil
    if Accessible(plate.UnitFrame) then
        local container = plate.UnitFrame.CastBarsContainer
        if Accessible(container) and Accessible(container.castBar) then
            state.castContainer, state.castBar = container, container.castBar
            WatchCast(container, state)
            WatchCast(container.castBar, state)
        end
    end
    Position(state)
    label:SetFont(STANDARD_TEXT_FONT, db.size, "OUTLINE")
    if friendly then
        label:SetTextColor(0.65, 0.65, 1)
    else
        label:SetTextColor(1, 0.45, 0.45)
    end
    label:SetWidth(240)
    label:SetWordWrap(false)
    label:SetJustifyH("CENTER")
    label:SetText("<" .. guild .. ">")
    label:Show()
    state.shown, state.reason = true, "shown"
    state.attempts = MAX_ATTEMPTS
end

local function TryUpdate(unit, state)
    state.attempts = state.attempts + 1
    local ok, err = pcall(Update, unit, state)
    if not ok then
        pcall(Hide, state)
        state.reason = "API error"
        state.attempts = MAX_ATTEMPTS
        failures = failures + 1
        lastError = Plain(err) and tostring(err) or "restricted error"
    end
end

local function Add(unit)
    if not db or not Plain(unit) or type(unit) ~= "string" then return end
    Remove(unit)
    local state = { attempts = 0 }
    active[unit] = state
    TryUpdate(unit, state)
end

local function Refresh()
    if not db then return end
    for unit in pairs(active) do Remove(unit) end
    if not db.enabled then return end
    -- Enumeration also handles /reload while plates are already visible.
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok then return end
    for _, plate in ipairs(plates) do
        if Accessible(plate) then
            local unit = plate.namePlateUnitToken or plate.unitToken
            if not unit and Accessible(plate.UnitFrame) then unit = plate.UnitFrame.unit end
            if Plain(unit) and type(unit) == "string" then Add(unit) end
        end
    end
end

local function Status()
    local count, shown, reasons = 0, 0, {}
    for _, state in pairs(active) do
        count = count + 1
        if state.shown then shown = shown + 1 end
        local reason = state.reason or "pending"
        reasons[reason] = (reasons[reason] or 0) + 1
    end
    local version, build = GetBuildInfo()
    Say(string.format("v0.2.1; client %s/%s; %s; %d tracked, %d labels, %d errors.",
        version, build, db.enabled and "on" or "off", count, shown, failures))
    local parts = {}
    for reason, n in pairs(reasons) do parts[#parts + 1] = reason .. "=" .. n end
    table.sort(parts)
    if #parts > 0 then Say(table.concat(parts, "; ")) end
    if lastError then Say("Last error: " .. lastError) end
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" then
        if unit ~= addonName then return end
        NamePlateGuildNamesDB = type(NamePlateGuildNamesDB) == "table" and NamePlateGuildNamesDB or {}
        db = NamePlateGuildNamesDB
        if type(db.enabled) ~= "boolean" then db.enabled = true end
        db.size = math.max(8, math.min(24, tonumber(db.size) or 12))
        db.offset = math.max(-60, math.min(60, tonumber(db.offset) or -4))
        Say("v0.2.1 loaded. /ngn status for diagnostics; /ngn for controls.")
    elseif not db then
        return
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        Add(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if Plain(unit) then Remove(unit) end
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_FACTION" then
        if Plain(unit) and active[unit] then Add(unit) end
    else
        Refresh()
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED", "UNIT_NAME_UPDATE", "UNIT_FACTION", "PLAYER_GUILD_UPDATE",
    "PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED"}) do
    events:RegisterEvent(event)
end

-- Bounded retries for late guild data; no per-frame scanning or persistent name cache.
C_Timer.NewTicker(0.5, function()
    if not db or not db.enabled then return end
    for unit, state in pairs(active) do
        if state.attempts < MAX_ATTEMPTS then TryUpdate(unit, state) end
    end
end)

SLASH_NAMEPLATEGUILDNAMES1 = "/ngn"
SlashCmdList.NAMEPLATEGUILDNAMES = function(message)
    if not db then return end
    local command, arg = message:lower():match("^%s*(%S*)%s*(.-)%s*$")
    if command == "status" then Status(); return end
    if command == "on" or command == "off" then
        db.enabled = command == "on"
        Refresh()
        Say(db.enabled and "Enabled." or "Disabled.")
    elseif command == "size" or command == "offset" then
        local value = tonumber(arg)
        local low, high = command == "size" and 8 or -60, command == "size" and 24 or 60
        if not value or value ~= value or value < low or value > high then
            Say(command .. " must be between " .. low .. " and " .. high .. "."); return
        end
        db[command] = value
        Refresh()
        Say(command .. " = " .. value)
    elseif command == "refresh" then
        Refresh()
        Status()
    else
        Say("/ngn on | off | status | refresh | size 12 | offset -4")
    end
end
