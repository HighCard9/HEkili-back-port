-- Replace mask/atlas based glows with an original-client pulsing border.
local C=Hekili335Compat
local glow={}
C.Glow=glow
local function start(button,color)
    if not button then return end
    local f=button.Hekili335Glow
    if not f then
        f=C.CreateFrame('Frame',nil,button)
        f:SetAllPoints(button)
        f:SetFrameLevel(button:GetFrameLevel()+5)
        f:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
        f:SetScript('OnUpdate',function(self)
            self:SetAlpha(.65+.35*math.sin(GetTime()*6)^2)
        end)
        button.Hekili335Glow=f
    end
    color=color or {1,.82,0,1}
    f:SetBackdropBorderColor(unpack(color));f:Show()
end
local function stop(button)
    if button and button.Hekili335Glow then button.Hekili335Glow:Hide() end
end
glow.PixelGlow_Start=start;glow.PixelGlow_Stop=stop
glow.AutoCastGlow_Start=start;glow.AutoCastGlow_Stop=stop
glow.ButtonGlow_Start=start;glow.ButtonGlow_Stop=stop
glow.ProcGlow_Start=start;glow.ProcGlow_Stop=stop
