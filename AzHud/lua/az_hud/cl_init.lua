include("vgui_panel.lua")    
AzHud.Inited = AzHud.Inited or false         
  
function AzHud.Init()   
	if (AzHud.Hud || IsValid(AzHud)) then             
		AzHud.Hud:Remove()                                                       
	end       
	AzHud.Hud = vgui.CreateFromTable( AzHud.Class )    
end

hook.Add("Initialize", "AzHud Initialize", function()
	AzHud.Init()
	AzHud.Inited = true
end)
   
-- Handle reload                 
if (AzHud.Inited) then  
	AzHud.Init()
end                                

hook.Add("Think", "AzHud Hide", function()
	if (!IsValid(AzHud.Hud)) then    
		return
	end

	local should = hook.Run("HUDShouldDraw", "CAzHud")
	if (should && !AzHud.Hud:IsVisible()) then
		AzHud.Hud:Show()
	elseif (!should && AzHud.Hud:IsVisible()) then
		AzHud.Hud:Hide()
	end
end)

local hide = {
	CHudHealth = true,
	CHudBattery = true,
}

hook.Add( "HUDShouldDraw", "Az_Hud Hide", function( name )
	if (hide[name]) then return false end
end)                              