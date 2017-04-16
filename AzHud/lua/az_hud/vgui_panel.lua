local PANEL = {}

--[[
	You can call this part of code a configuration.
]]

-- Scaling.
local hud_height			= function() return math.ceil(ScrH() * (128 / 1080)) 	end	-- 128 on 1920x1080
local hud_width				= function() return math.ceil(ScrH() * (384 / 1080)) 	end	-- 384 on 1920x1080
local red_line_height		= function() return math.ceil(ScrH() * (4 / 1080)) 		end	-- 4 on 1920x1080
local avatar_margin 		= function() return math.ceil(ScrH() * (4 / 1080)) 		end -- 4 on 1920x1080
local avatar_border_round	= function() return math.ceil(ScrH() * (4 / 1080)) 		end -- 4 on 1920x1080
local stats_cnt_margin		= function() return math.ceil(ScrH() * (4 / 1080)) 		end -- 4 on 1920x1080

local player_name_font_sz	= function() return math.ceil(ScrH() * (24 / 1080))		end -- 20 on 1920x1080
local stats_font_sz			= function() return math.ceil(ScrH() * (20 / 1080))		end -- 20 on 1920x1080

local stats_bar_size		= function() return math.ceil(ScrH() * (24 / 1080))		end -- 24 on 1920x1080
local suit_bar_size			= function() return math.ceil(ScrH() * (10 / 1080))		end -- 10 on 1920x1080
local stats_bar_topmargin	= function() return math.ceil(ScrH() * (4 / 1080))		end -- 4 on 1920x1080

local bar_inner_margin		= function() return math.ceil(ScrH() * (2 / 1080))		end -- 2 on 1920x1080
local bar_dropout_speed		= function() return math.ceil(ScrH() * (0.5 / 1080))	end -- 0.5 on 1920x1080

-- Set this to false if you want Windows 8
local ROUNDED = true
local DEFAULT_ROUND = 8

-- Set this to false if you don't want it to be pink/blue on max velocity
local SPEED_BAR_GRADATION_CLAMP = true

-- This is how fast bar value changes (0 - speed of the snail, 1 - blink of the eye)
local HP_BAR_CHANGESPEED = 0.1
local SUIT_BAR_CHANGESPEED = 0.1

-- Set this to true if you want HP bar to display "Undead" when player is alive with HP <= 0.
local HP_BAR_UNDEAD = false

function drawBar(x, y, w, h, color, rounding, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
	-- It's better to turn off rounding at this point at all. It looks ultimately crappy.
	if (ScrW() <= 1280) then
		rounding = 0
	end
	
	if (rounding == 0 || !ROUNDED || !(roundTopLeft || roundTopRight || roundBottomLeft || roundBottomRight)) then
		surface.SetDrawColor(color)
		surface.DrawRect(x, y, w, h)
	else
		if (rounding < 2) then
			rounding = 2
		end
	
		roundTopLeft = roundTopLeft or false
		roundTopRight = roundTopRight or false
		roundBottomLeft = roundBottomLeft or false
		roundBottomRight = roundBottomRight or false
	
		if (type(rounding) != "number") then
			rounding = 0
		end
		
		draw.RoundedBoxEx(rounding, x, y, w, h, color, roundTopLeft, roundTopRight, roundBottomLeft, roundBottomRight)
	end
end

function PANEL:Init()
	local mainPanel = self
	for k, v in pairs(self:GetChildren()) do
		v:Remove()
	end
	
	self:Relayout()
	
	self.Container = self:Add("DPanel")
	self.Container:Dock(TOP)
	self.Container:SetTall(hud_height() - red_line_height())
	function self.Container:Paint(w, h)
		drawBar(0, 0, w, h, Color(0, 0, 0, 160), DEFAULT_ROUND, false, true)
	end
	
	local redline = self:Add("DPanel")
	redline:Dock(BOTTOM)
	redline:SetTall(red_line_height())
	function redline:Paint(w, h)
		-- This is never going to be rounded, so...
		surface.SetDrawColor(Color(255, 128, 0, 160))
		surface.DrawRect(0, 0, w, h)
	end
	
	local frame_margin = red_line_height() -- Because it's the same
	local avatar_frame = self.Container:Add("DPanel")
	avatar_frame:DockMargin(frame_margin, frame_margin, frame_margin, frame_margin)
	avatar_frame:Dock(LEFT)
	avatar_frame:SetWide(self.Container:GetTall() - frame_margin * 2)
	function avatar_frame:Paint(w, h)
		local color = Color(255, 191, 0, 160)
		if (IsValid(mainPanel.Player)) then
			local teamcolor = team.GetColor(mainPanel.Player:Team())
			color = Color(teamcolor.r, teamcolor.g, teamcolor.b, alpha)
		end
	
		drawBar(0, 0, w, h, color, avatar_border_round(), true, true, true, true)
	end
	
	local margin = avatar_margin()
	self.Avatar = avatar_frame:Add("AvatarImage")
	self.Avatar:Dock(FILL)
	self.Avatar:DockMargin(margin, margin, margin, margin)
	function self.Avatar:Think()
		-- Avoid resetting avatar at hummingbird speed
		if (self.Player != mainPanel.Player) then
			self:SetPlayer(mainPanel.Player, hud_height() - red_line_height() - (frame_margin * 2 + margin * 2))
			self.Player = mainPanel.Player
		end
	end

	local margin = stats_cnt_margin()
	local stats_container = self.Container:Add("DPanel")
	stats_container:Dock(FILL)
	stats_container:DockMargin(math.abs(margin - frame_margin), margin, margin, margin)
	function stats_container:Paint() end
	
	local player_name = stats_container:Add("DLabel")
	player_name:Dock(TOP)
	player_name:SetTall( player_name_font_sz() * 0.9 )
	player_name:SetFont("AzHud PlayerName")
	player_name:SetContentAlignment(5)
	player_name:SetTextColor(Color(255, 255, 255))
	function player_name:Think()
		local name = (IsValid(mainPanel.Player) && mainPanel.Player.Name) && mainPanel.Player:Name() || "N/A"
	
		if (self:GetText() != name) then
			self:SetText(name)
		end
	end
	
	local hp_bar = stats_container:Add("DPanel")
	hp_bar:Dock(TOP)
	hp_bar:DockMargin(0, stats_bar_topmargin(), 0, 0)
	hp_bar:SetTall(stats_bar_size() + suit_bar_size())
	function hp_bar:Paint(w, h)
		local target = (IsValid(mainPanel.Player) && mainPanel.Player:Alive() && mainPanel.Player.Armor && mainPanel.Player:Armor() > 0) && h || stats_bar_size()
		
		-- This is for cinematic drop-out
		self.DrawHeight = math.Approach((self.DrawHeight or h), target, bar_dropout_speed())
		
		drawBar(0, 0, w, self.DrawHeight, Color(0, 0, 0, 160), DEFAULT_ROUND, true, true, true, true)
		
		local text = "Dead"
		local margin = bar_inner_margin()
		
		if (IsValid(mainPanel.Player) && mainPanel.Player:Alive() && mainPanel.Player.Health && mainPanel.Player:Health() > 0) then
			local hp = mainPanel.Player:Health() / mainPanel.Player:GetMaxHealth()
			self.DisplayHP = math.Approach(self.DisplayHP or 0, hp, math.max(math.abs(((self.DisplayHP or 0) - hp) * HP_BAR_CHANGESPEED, 2)))
			
			local hp_width = (w - margin * 2) * self.DisplayHP
			local posx, posy = self:LocalToScreen(0, 0)
			render.SetScissorRect(posx + margin, posy, posx + margin + hp_width, posy + stats_bar_size(), true)
				drawBar(margin, margin, w - margin * 2, stats_bar_size() - margin * 2, Color(255, 0, 0, 192), DEFAULT_ROUND, true, true, true, true)
			render.SetScissorRect(0, 0, 0, 0, false)
			
			text = string.format("%s%% HP", math.ceil(mainPanel.Player:Health()))
			
			if (mainPanel.Player.Armor && mainPanel.Player:Armor() > 0) then
				local armor = mainPanel.Player:Armor() / 100
				
				self.DisplayArmor = math.Approach(self.DisplayArmor or 0, armor, math.max(math.abs(((self.DisplayArmor or 0) - armor) * SUIT_BAR_CHANGESPEED, 2)))
				
				local armor_width = (w - margin * 2) * (self.DisplayArmor or 0)
				local posx, posy = self:LocalToScreen(0, 0)
				render.SetScissorRect(posx + margin, posy, posx + margin + armor_width, posy + self.DrawHeight, true)
					drawBar(margin * 4, stats_bar_size() + margin * 0.35, w - margin * 8, suit_bar_size() - margin * 2, Color(127, 255, 255, 192), DEFAULT_ROUND / 2, true, true, true, true)
				render.SetScissorRect(0, 0, 0, 0, false)
			end
		end
		
		if (HP_BAR_UNDEAD && IsValid(mainPanel.Player) && mainPanel.Player:Alive() && mainPanel.Player:Health() <= 0) then
			text = "Undead"
		end
		
		-- We don't really need to scale outline there.
		-- Do we?
		draw.SimpleTextOutlined( text, "AzHud Stats", margin * 4, stats_bar_size() / 2 - 1, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0) ) 
	end
	
	local speed_bar = stats_container:Add("DPanel")
	speed_bar:Dock(BOTTOM)
	speed_bar:DockMargin(0, stats_bar_topmargin(), 0, 0)
	speed_bar:SetTall(stats_bar_size())
	speed_bar.Velocity = 0
	speed_bar.MaxVelocity = 220
	function speed_bar:Paint(w, h)
		drawBar(0, 0, w, h, Color(0, 0, 0, 160), DEFAULT_ROUND, true, true, true, true)
		
		local margin = bar_inner_margin()
		local text
		
		if (IsValid(mainPanel.Player)) then
			local vel = self.Velocity / self.MaxVelocity
			
			local vel_width = (w - margin * 2) * vel
			local posx, posy = self:LocalToScreen(0, 0)
			
			local hue = (1 - vel) * 90
			
			if (SPEED_BAR_GRADATION_CLAMP) then
				hue = math.Clamp(hue, 0, 90)
			end
			local color = HSVToColor(hue, 1, 1)
			
			render.SetScissorRect(posx + margin, posy, posx + margin + vel_width, posy + h, true)
				drawBar(margin, margin, w - margin * 2, h - margin * 2, color, DEFAULT_ROUND, true, true, true, true)
			render.SetScissorRect(0, 0, 0, 0, false)
			
			local mph = (self.RealVelocity * 0.01905) * 2.23694
			text = string.format("%.1f unit/s, %.1f miles/h", self.RealVelocity, mph)
		end
		
		if (text) then
			draw.SimpleTextOutlined( text, "AzHud Stats", margin * 4, stats_bar_size() / 2 - 1, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0) )
		end
	end
	function speed_bar:Think()
		local velocity = 0
		local maxvel = (IsValid(mainPanel.Player) && mainPanel.Player:GetRunSpeed()) && mainPanel.Player:GetRunSpeed() or 220
		
		if (IsValid(mainPanel.Player) && mainPanel.Player:Alive()) then
			velocity = mainPanel.Player:GetVelocity()
			if (mainPanel.Player:InVehicle() && IsValid(mainPanel.Player:GetVehicle())) then
				velocity = mainPanel.Player:GetVehicle():GetVelocity()
			end
			velocity = velocity:Length()
		end
		
		self.RealVelocity = velocity
		self.Velocity = math.Approach(self.Velocity, velocity, math.max(math.abs(velocity - self.Velocity) * 0.15, 0.5))
		self.MaxVelocity = math.Approach(self.MaxVelocity, math.max(velocity, maxvel), math.max(math.abs(velocity - self.MaxVelocity) * 0.01, 0.25))
	end
end

function PANEL:Relayout(reinit)
	surface.CreateFont( "AzHud PlayerName", {
		font = "Roboto",
		size = player_name_font_sz(),
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		outline = true,
		extended = true
	} )

	surface.CreateFont( "AzHud Stats", {
		font = "TruenoBdOl",
		size = stats_font_sz(),
		weight = 575,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		outline = false,
	} )

	self:SetTall(hud_height())
	self:SetWide(hud_width())
	self:SetPos(0, ScrH() - self:GetTall())
	
	-- I should call invalidatelayout here, but simple reinit is fine too.
	if (reinit) then
		self:Init()
	end
end

function PANEL:Paint(w, h)

end

function PANEL:Think()
	if (!IsValid(self.Player)) then
		if (IsValid(LocalPlayer())) then
			local ob = LocalPlayer():GetObserverTarget()
			
			if (IsValid(ob) && ob.IsPlayer && ob:IsPlayer()) then
				self.Player = ob
			else
				self.Player = LocalPlayer()
			end
		else
			self.Player = nil
		end
	end

	local x, y = self:GetPos()
	if ((x != 0) || (y != ScrH() - hud_height())) then
		self:Relayout(true)
	end
end

AzHud.Class = vgui.RegisterTable(PANEL, "EditablePanel")