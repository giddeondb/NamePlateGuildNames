local path = assert(arg[1])
local handler, tick
local plates, units, messages = {}, {}, {}
local function region()
    local r = {visible=false}
    function r:IsForbidden() return self.forbidden or false end
    function r:HookScript(event, callback)
        self.hooks = self.hooks or {}
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], callback)
    end
    function r:IsVisible() return self.visible end
    function r:Hide()
        local changed = self.visible
        self.visible=false
        if changed then for _, f in ipairs(self.hooks and self.hooks.OnHide or {}) do f(self) end end
    end
    function r:Show()
        local changed = not self.visible
        self.visible=true
        if changed then for _, f in ipairs(self.hooks and self.hooks.OnShow or {}) do f(self) end end
    end
    function r:SetText(s) self.text=s end
    function r:ClearAllPoints() end
    function r:SetPoint(...) self.point={...} end
    function r:SetFont(...) end
    function r:SetTextColor(...) self.color={...} end
    function r:SetWidth(...) end
    function r:SetWordWrap(...) end
    function r:SetJustifyH(...) end
    return r
end
function CreateFrame()
    return {SetScript=function(_, _, f) handler=f end, RegisterEvent=function() end}
end
function print(s) messages[#messages+1]=s end
function issecretvalue(v) return v == 'SECRET' end
function UnitExists(u) return units[u] ~= nil end
function UnitIsPlayer(u) return units[u] and units[u].player end
function UnitIsFriend(_, u) return units[u] and units[u].friendly end
function GetGuildInfo(u)
    if units[u].error then error('mock restricted API') end
    return units[u].guild
end
function GetBuildInfo() return '1.60.1','70938' end
C_NamePlate = {
 GetNamePlateForUnit=function(u) return plates[u] end,
 GetNamePlates=function() local out={} for _, p in pairs(plates) do out[#out+1]=p end return out end,
}
C_Timer={NewTicker=function(_, f) tick=f end}
C_AddOns={GetAddOnMetadata=function(name, key)
    assert(name=='NamePlateGuildNames' and key=='Version')
    return '9.8.7'
end}
SlashCmdList={}
STANDARD_TEXT_FONT='font'
assert(loadfile(path))('NamePlateGuildNames')
handler(nil,'ADDON_LOADED','NamePlateGuildNames')
assert(messages[#messages]:find('v9.8.7 loaded',1,true), 'load message uses TOC version')
local function add(u, guild, p)
    units[u]={player=true, friendly=true, guild=guild}
    p=p or region()
    p.unitToken=u
    p.UnitFrame=region()
    p.UnitFrame.HealthBarsContainer=region()
    p.UnitFrame.CastBarsContainer=region()
    p.UnitFrame.CastBarsContainer.castBar=region()
    function p:CreateFontString() self.label=region(); return self.label end
    plates[u]=p
    handler(nil,'NAME_PLATE_UNIT_ADDED',u)
    return p
end
local p=add('nameplate1','Slash Played')
assert(p.label.visible and p.label.text=='<Slash Played>', 'untargeted label')
local castContainer = p.UnitFrame.CastBarsContainer
local castBar = castContainer.castBar
assert(p.label.point[2]==p.UnitFrame.HealthBarsContainer, 'idle anchor')
castBar:Show()
assert(p.label.point[2]==castContainer, 'cast anchors below bar and spell text')
castBar:Hide()
assert(p.label.point[2]==p.UnitFrame.HealthBarsContainer, 'cast end restores anchor')
castBar:Show()
SlashCmdList.NAMEPLATEGUILDNAMES('refresh')
assert(p.label.point[2]==castContainer, 'already casting on refresh')
assert(#castBar.hooks.OnShow==1, 'refresh does not duplicate hooks')
handler(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1')
castBar:Hide()
castBar:Show()
assert(not p.label.visible, 'removed cast callbacks cannot show stale label')
plates.nameplate1=nil; units.nameplate1=nil
assert(not p.label.visible and p.label.text=='', 'remove clears label')
add('nameplate2',nil,p)
assert(not p.label.visible, 'recycled guildless plate stays blank')
units.nameplate2.guild='Late Guild'; tick()
assert(p.label.visible and p.label.text=='<Late Guild>', 'late guild retry')
local currentAnchor = p.label.point[2]
castBar:Hide()
assert(p.label.point[2]==currentAnchor, 'old pooled frame cannot reposition new label')
SlashCmdList.NAMEPLATEGUILDNAMES('off')
assert(not p.label.visible, 'disable hides')
SlashCmdList.NAMEPLATEGUILDNAMES('on')
assert(p.label.visible, 'enable rescans')
SlashCmdList.NAMEPLATEGUILDNAMES('offset -10')
assert(p.label.point[5]==-10, 'offset updates')
units.nameplate2.friendly=false
handler(nil,'UNIT_FACTION','nameplate2')
assert(p.label.visible and p.label.color[1]==1 and p.label.color[2]==0.45, 'enemy guild is red')
units.nameplate2.friendly=true
handler(nil,'UNIT_FACTION','nameplate2')
assert(p.label.visible and p.label.color[1]==0.65 and p.label.color[3]==1, 'friendly recolors lavender')
units.nameplate2.friendly='SECRET'
handler(nil,'UNIT_FACTION','nameplate2')
assert(not p.label.visible, 'restricted reaction hides label')
units.nameplate2.friendly=false
units.nameplate2.player=false
handler(nil,'UNIT_FACTION','nameplate2')
assert(not p.label.visible, 'non-player NPC or pet excluded')
units.nameplate2.player=true
units.nameplate2.guild=nil
handler(nil,'UNIT_NAME_UPDATE','nameplate2')
assert(not p.label.visible, 'guildless enemy hidden')
units.nameplate2.guild='Enemy Guild'; tick()
assert(p.label.visible and p.label.text=='<Enemy Guild>' and p.label.color[2]==0.45, 'late enemy guild')
local q=region(); q.forbidden=true
add('nameplate3','Forbidden',q)
assert(not q.label, 'forbidden plate skipped')
local s=add('nameplate4','SECRET')
assert(not s.label, 'secret guild skipped')
local delayed=add('nameplate5',nil)
for i=1,10 do tick() end
units.nameplate5.guild='After Retry Window'; tick()
assert(not delayed.label, 'retry is bounded')
SlashCmdList.NAMEPLATEGUILDNAMES('refresh')
assert(delayed.label.visible, 'manual refresh retries expired lookup')
units.nameplate5.error=true
handler(nil,'UNIT_NAME_UPDATE','nameplate5')
assert(not delayed.label.visible, 'API error hides old text')
SlashCmdList.NAMEPLATEGUILDNAMES('status')
assert(table.concat(messages,'\n'):find('mock restricted API',1,true), 'error diagnosis')
assert(table.concat(messages,'\n'):find('v9.8.7; client',1,true), 'status uses TOC version')
io.write('PASS: untargeted label, removal, reuse, delayed data, toggle, offset, hostility, forbidden/secret data, bounded retries, refresh, API errors, cast start/stop, active cast refresh, stale hooks\n')
