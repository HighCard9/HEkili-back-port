-- Keep Hekili status/debug messages out of chat. /hek335 opens a local report.
local addon,ns=...
local C=ns.Compat335
C.messages={}
function Hekili:Print(...)
    local args={...}
    for i=1,#args do args[i]=tostring(args[i]) end
    C.messages[#C.messages+1]=table.concat(args,' ')
    if #C.messages>100 then table.remove(C.messages,1) end
end
SLASH_HEKILI3351='/hek335'
SlashCmdList.HEKILI335=function()
    local gui=LibStub('AceGUI-3.0')
    local f=gui:Create('Frame')
    f:SetTitle('Hekili 3.3.5a - Protection alpha')
    f:SetWidth(650);f:SetHeight(430);f:SetLayout('Fill')
    f:SetCallback('OnClose',function(widget) gui:Release(widget) end)
    local report=gui:Create('MultiLineEditBox')
    report:SetLabel('Local diagnostics (copy this text if reporting a problem)')
    report:SetNumLines(18);report:DisableButton(true)
    local spec=Hekili.State.spec.id
    local profile=Hekili.DB and Hekili.DB.profile
    local package=profile and profile.specs[spec] and profile.specs[spec].package or 'unavailable'
    local text={'Build: '..Hekili.Version,'Class ID: '..tostring(spec),'Priority: '..package,
        'Enabled: '..tostring(profile and profile.enabled),'Paused: '..tostring(Hekili.Pause),
        'Status messages:',table.concat(C.messages,'\n')}
    report:SetText(table.concat(text,'\n'));f:AddChild(report)
end

-- First alpha is intentionally configured for Protection, with combat-log target counting.
local initialize=Hekili.OnInitialize
function Hekili:OnInitialize()
    initialize(self)
    local options=self.DB.profile.specs[2]
    if not self.DB.profile.warmaneProtAlphaInitialized then
        options.package='Protection 96'
        options.usePackSelector=false
        options.nameplates=false
        options.settings.maintain_blessing=false
        self.DB.profile.warmaneProtAlphaInitialized=true
    end
end
