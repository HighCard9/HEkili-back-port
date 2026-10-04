-- Experimental Hekili Wrath -> original 3.3.5a compatibility layer.
-- Deliberately keeps legacy aura/spell APIs unchanged for other addons.
local addon, ns = ...
table.unpack = table.unpack or unpack
local C = {}
ns.Compat335 = C
Hekili335Compat = C
local nativeSpellInfo, nativeBuff, nativeDebuff = GetSpellInfo, UnitBuff, UnitDebuff
local nativeCast, nativeChannel, nativeFrame, nativeClass = UnitCastingInfo, UnitChannelInfo, CreateFrame, UnitClass
local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local classIDs = {}
for id, file in ipairs(classes) do classIDs[file] = id end
function C.UnitClass(unit)
    local name, file = nativeClass(unit)
    return name, file, classIDs[file]
end
UnitClassBase = UnitClassBase or function(unit) return select(2, nativeClass(unit)) end
GetNumClasses = GetNumClasses or function() return 10 end
GetClassInfo = GetClassInfo or function(id)
    local file = classes[id]
    if file then return LOCALIZED_CLASS_NAMES_MALE[file], file, id end
end
WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE or 1
WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC or 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5
WOW_PROJECT_WRATH_CLASSIC = WOW_PROJECT_WRATH_CLASSIC or 11
WOW_PROJECT_ID = WOW_PROJECT_ID or WOW_PROJECT_WRATH_CLASSIC
Enum = Enum or {}
Enum.PowerType = Enum.PowerType or {
    None=-1, Mana=0, Rage=1, Focus=2, Energy=3, ComboPoints=4,
    Runes=5, RunicPower=6, SoulShards=7, LunarPower=8, HolyPower=9,
    Alternate=10, Maelstrom=11, Chi=12, Insanity=13, Obsolete=14,
    Obsolete2=15, ArcaneCharges=16, Fury=17, Pain=18, Essence=19,
    RuneBlood=20, RuneFrost=21, RuneUnholy=22, HealthCost=-2
}
Enum.ItemSlotFilterTypeMeta = Enum.ItemSlotFilterTypeMeta or {MaxValue=19}
C_Container = C_Container or {GetItemCooldown=GetItemCooldown}
C_AddOns = C_AddOns or {GetAddOnMetadata=GetAddOnMetadata}
Mixin = Mixin or function(object, ...)
    for i=1,select('#', ...) do
        local mixin = select(i, ...)
        if mixin then for k,v in pairs(mixin) do object[k]=v end end
    end
    return object
end
-- Missing template is removed by C.CreateFrame; backdrop methods are native in 3.3.5.
BackdropTemplateMixin = BackdropTemplateMixin or {}

local spellIDs, talentRanks = {}, {}
function C.RefreshSpellbook()
    wipe(spellIDs); wipe(talentRanks)
    for tab=1,GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for index=offset+1,offset+count do
            local name, rank = GetSpellName(index, BOOKTYPE_SPELL or 'spell')
            local link = GetSpellLink(index, BOOKTYPE_SPELL or 'spell')
            local id = link and tonumber(link:match('spell:(%d+)'))
            if name and id then
                spellIDs[name]=id -- spellbook orders successive ranks from low to high.
                spellIDs[name .. '\001' .. (rank or '')]=id
            end
        end
    end
    for tab=1,GetNumTalentTabs() do
        for index=1,GetNumTalents(tab) do
            local name, _, _, _, rank = GetTalentInfo(tab,index)
            if name then talentRanks[name]=rank or 0 end
        end
    end
end
function C.GetSpellID(name, rank)
    return rank and spellIDs[name .. '\001' .. rank] or spellIDs[name]
end
GetSpellBookItemName = GetSpellBookItemName or GetSpellName
GetSpellBookItemInfo = GetSpellBookItemInfo or function(index,book)
    local link=GetSpellLink(index,book)
    local id=link and tonumber(link:match('spell:(%d+)'))
    if id then return 'SPELL',id end
end
function C.GetSpellInfo(spell, book)
    local name, rank, icon, cost, funnel, power, cast, low, high = nativeSpellInfo(spell,book)
    if not name then return end
    local id
    if book then
        local link=GetSpellLink(spell,book)
        id=link and tonumber(link:match('spell:(%d+)'))
    elseif type(spell)=='number' then id=spell
    else id=C.GetSpellID(name,rank) or C.GetSpellID(name) end
    return name, rank, icon, cast, low, high, id, icon
end
-- Exact modern positional shape consumed by Hekili, including spellID at index 10.
local function aura(api,unit,index,filter)
    local name,rank,icon,count,kind,duration,expires,caster,steal,id = api(unit,index,filter)
    if not name then return end
    return name,icon,count or 0,kind,duration or 0,expires or 0,caster,steal,false,id,true,false,false,1,1,0,0,0
end
function C.UnitBuff(unit,index,filter) return aura(nativeBuff,unit,index,filter) end
function C.UnitDebuff(unit,index,filter) return aura(nativeDebuff,unit,index,filter) end
function C.UnitAura(unit,index,filter)
    return aura(filter and filter:find('HARMFUL') and nativeDebuff or nativeBuff,unit,index,filter)
end
function C.UnitCastingInfo(unit)
    local name,rank,text,icon,start,finish,trade,id,locked=nativeCast(unit)
    if not name then return end
    return name,text,icon,start,finish,trade,id,locked,C.GetSpellID(name,rank) or C.GetSpellID(name)
end
function C.UnitChannelInfo(unit)
    local name,rank,text,icon,start,finish,trade,locked=nativeChannel(unit)
    if not name then return end
    return name,text,icon,start,finish,trade,locked,C.GetSpellID(name,rank) or C.GetSpellID(name)
end
IsPlayerSpell = IsPlayerSpell or function(id)
    if IsSpellKnown(id) then return true end
    local name,rank=nativeSpellInfo(id)
    local learned=name and talentRanks[name]
    if not learned or learned==0 then return false end
    local required=tonumber((rank or ''):match('(%d+)')) or 1
    return learned>=required
end
IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown or IsSpellKnown
GetItemIcon = GetItemIcon or function(id) return select(10,GetItemInfo(id)) or 'Interface\\Icons\\INV_Misc_QuestionMark' end
GetSpellTexture = GetSpellTexture or function(id) return select(3,nativeSpellInfo(id)) end
GetSpellDescription = GetSpellDescription or function() return '' end
GetSpellCharges = GetSpellCharges or function() return nil end
GetNumGroupMembers = GetNumGroupMembers or function()
    local raid=GetNumRaidMembers()
    return raid>0 and raid or (GetNumPartyMembers()>0 and GetNumPartyMembers()+1 or 0)
end
GetNumSubgroupMembers = GetNumSubgroupMembers or GetNumPartyMembers
IsInRaid = IsInRaid or function() return GetNumRaidMembers()>0 end
IsInGroup = IsInGroup or function() return GetNumRaidMembers()>0 or GetNumPartyMembers()>0 end
GetNormalizedRealmName = GetNormalizedRealmName or function() return (GetRealmName():gsub('[%s%-]','')) end
GetUnitSpeed = GetUnitSpeed or function(unit) return unit=='player' and GetPlayerSpeed() or 0 end
GetPowerRegen = GetPowerRegen or function() return GetManaRegen() end
GetPowerRegenForPowerType = GetPowerRegenForPowerType or GetPowerRegen
UnitSpellHaste = UnitSpellHaste or function() return GetCombatRatingBonus(CR_HASTE_SPELL) end
GetSpellBaseCooldown = GetSpellBaseCooldown or function(id)
    local cd = ({[53595]=6,[61411]=6,[48952]=8,[48819]=8,[53408]=10,[20271]=10,[48827]=30})[id] or 0
    return cd*1000,1500
end
GetSpellLossOfControlCooldown = GetSpellLossOfControlCooldown or function() return 0,0 end
HasOverrideActionBar = HasOverrideActionBar or function() return false end
IsEncounterInProgress = IsEncounterInProgress or function() return false end
GetTimePreciseSec = GetTimePreciseSec or GetTime
C_LossOfControl = C_LossOfControl or {GetActiveLossOfControlDataCount=function() return 0 end,GetActiveLossOfControlData=function() end}
C_NamePlate = C_NamePlate or {GetNamePlateForUnit=function() end}
C_Texture = C_Texture or {GetAtlasInfo=function() end}
C_Spell = C_Spell or {}
-- All valid spells are in the old client's DBC; invalid modern IDs cannot be downloaded.
C_Spell.IsSpellDataCached = function() return true end
C_Spell.RequestLoadSpellData = function() end
for _,color in pairs(RAID_CLASS_COLORS) do
    if not color.GetRGBA then color.GetRGBA=function(self) return self.r,self.g,self.b,1 end end
end

-- OnUpdate scheduler, including cancellation used by talent-change debouncing.
C_Timer = C_Timer or {}
local timers={}
local timerFrame=nativeFrame('Frame')
local function schedule(delay,callback,ticker)
    local t={ends=GetTime()+math.max(0.01,delay),callback=callback,delay=delay,ticker=ticker}
    function t:Cancel() self.cancelled=true end
    function t:IsCancelled() return self.cancelled or false end
    timers[#timers+1]=t
    timerFrame:Show()
    return t
end
function C_Timer.After(delay,callback) schedule(delay,callback) end
function C_Timer.NewTimer(delay,callback) return schedule(delay,callback) end
function C_Timer.NewTicker(delay,callback,iterations) return schedule(delay,callback,iterations or -1) end
timerFrame:SetScript('OnUpdate',function()
    local now=GetTime()
    for i=#timers,1,-1 do
        local t=timers[i]
        if t.cancelled or now>=t.ends then
            table.remove(timers,i)
            if not t.cancelled then
                if t.ticker and t.ticker~=1 then
                    if t.ticker>0 then t.ticker=t.ticker-1 end
                    t.ends=now+math.max(.01,t.delay);timers[#timers+1]=t
                end
                local ok,err=pcall(t.callback,t)
                if not ok then geterrorhandler()(err) end
            end
        end
    end
    if #timers==0 then timerFrame:Hide() end
end)
timerFrame:Hide()

-- Original-client item cache adapter. Bounded polling replaces Item mixins.
C.Item={}
function C.Item:CreateFromItemID(id)
    local item={id=id}
    function item:IsItemEmpty() return type(self.id)~='number' or self.id<=0 or self.id>60000 end
    function item:GetItemName() return GetItemInfo(self.id) end
    function item:GetItemLink() return select(2,GetItemInfo(self.id)) end
    function item:GetItemIcon() return select(10,GetItemInfo(self.id)) end
    function item:ContinueOnItemLoad(callback)
        local tries=0
        local function check()
            if GetItemInfo(self.id) then callback(true);return end
            tries=tries+1
            if tries<20 then C_Timer.After(.5,check) end
        end
        check()
    end
    return item
end

-- Frame adapters are confined to this addon and its embedded libraries.
local function textureAdapter(texture)
    if not texture.SetColorTexture then
        texture.SetColorTexture=function(self,r,g,b,a) self:SetTexture(r,g,b,a or 1) end
    end
    return texture
end
function C.CreateFrame(kind,name,parent,template,...)
    if template then
        template=template:gsub('BackdropTemplate,?',''):gsub(',$','')
        if template=='' then template=nil end
    end
    local f=nativeFrame(kind,name,parent,template,...)
    f.IsAnchoringRestricted=f.IsAnchoringRestricted or function() return false end
    local createTexture=f.CreateTexture
    f.CreateTexture=function(self,...) return textureAdapter(createTexture(self,...)) end
    if not f.SetResizeBounds and f.SetMinResize then
        f.SetResizeBounds=function(self,minW,minH,maxW,maxH)
            self:SetMinResize(minW,minH)
            if maxW and maxH then self:SetMaxResize(maxW,maxH) end
        end
    end
    if kind=='Cooldown' then
        f.SetSwipeColor=f.SetSwipeColor or function() end
        f.SetDrawBling=f.SetDrawBling or function() end
        f.SetHideCountdownNumbers=f.SetHideCountdownNumbers or function() end
        f.SetEdgeScale=f.SetEdgeScale or function() end
    end
    if not f.RegisterUnitEvent then f.RegisterUnitEvent=function(self,event) self:RegisterEvent(event) end end
    return f
end

function C.NPCID(guid)
    if not guid then return end
    if guid:sub(1,2)=='0x' then
        local kind=guid:sub(3,6):upper()
        if kind=='F130' or kind=='F140' or kind=='F150' then return tonumber(guid:sub(7,12),16) end
        return
    end
    return tonumber(guid:match('(%d+)-%x-$'))
end
function C.NormalizeCombatLog(timestamp,event,sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags,...)
    return timestamp,event,false,sourceGUID,sourceName,sourceFlags,0,destGUID,destName,destFlags,0,...
end
local currentCombatLog
CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo or function()
    if currentCombatLog then return unpack(currentCombatLog,1,currentCombatLog.n) end
end
local function cacheCombatLog(...)
    currentCombatLog={n=select('#',...),...}
    return ...
end
function C.NormalizeEvent(event,...)
    if event=='COMBAT_LOG_EVENT_UNFILTERED' then return cacheCombatLog(C.NormalizeCombatLog(...)) end
    if event:find('^UNIT_SPELLCAST_') then
        local unit,name,rank,a,b=...
        local id=C.GetSpellID(name,rank) or C.GetSpellID(name)
        if event=='UNIT_SPELLCAST_SENT' then return unit,a,nil,id end
        return unit,a,id
    end
    return ...
end
local unsupported={
    NAME_PLATE_UNIT_ADDED=true,NAME_PLATE_UNIT_REMOVED=true,
    SPELL_ACTIVATION_OVERLAY_GLOW_SHOW=true,SPELL_ACTIVATION_OVERLAY_GLOW_HIDE=true,
    SPELL_DATA_LOAD_RESULT=true,ENCOUNTER_START=true,ENCOUNTER_END=true,
    PLAYER_STARTED_MOVING=true,PLAYER_STOPPED_MOVING=true,PLAYER_SPECIALIZATION_CHANGED=true,
    DISPLAY_SIZE_CHANGED=true,GET_ITEM_INFO_RECEIVED=true,
    UPDATE_OVERRIDE_ACTIONBAR=true,UPDATE_ALL_UI_WIDGETS=true,PLAYER_MOUNT_DISPLAY_CHANGED=true,
}
function C.RegisterEvent(frame,event)
    if unsupported[event] or event:find('^AZERITE_') or event:find('^CHROMIE_') or event:find('^PET_BATTLE_') or event:find('^CLIENT_SCENE_') then return end
    return frame:RegisterEvent(event)
end
function C.RegisterUnitEvent(frame,event,unit)
    if event=='UNIT_POWER_UPDATE' then
        for _,old in ipairs({'UNIT_MANA','UNIT_RAGE','UNIT_ENERGY','UNIT_RUNIC_POWER','UNIT_MAXMANA'}) do frame:RegisterEvent(old) end
    elseif not unsupported[event] then frame:RegisterEvent(event) end
end
local powerEvents={UNIT_MANA='MANA',UNIT_MAXMANA='MANA',UNIT_RAGE='RAGE',UNIT_ENERGY='ENERGY',UNIT_RUNIC_POWER='RUNIC_POWER'}
function C.PowerEvent(event) return powerEvents[event] end
local bookFrame=nativeFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','SPELLS_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED'}) do bookFrame:RegisterEvent(event) end
bookFrame:SetScript('OnEvent',C.RefreshSpellbook)
C.RefreshSpellbook()
