MsgC(Color(255, 128, 0), "> AzHud Loaded\n")
MsgC(Color(255, 128, 0), "> Copyright (c) Nivea\n")

include( "az_hud/sh_init.lua" )   
if SERVER then
	AddCSLuaFile( "az_hud/cl_init.lua" )
	AddCSLuaFile( "az_hud/sh_init.lua" )
	include( "az_hud/sv_init.lua" ) 
elseif CLIENT then
	include( "az_hud/cl_init.lua" )
end