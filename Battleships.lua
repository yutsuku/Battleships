Battleships = {}
local version = GetAddOnMetadata("Battleships", "Version") or "alpha"
local playerName = UnitName("player")
local _G = _G
local netPrefix = "Battleships"
local Clock = nil
local debug = false

local BattleshipFrame
local GUI_Label
local GUI_Label_Me
local GUI_Label_Enemy
local GUI_Warning
local GUI_Warning_Label
local GUI_Button_Ready
local GUI_Button_Clear

local GUI_Button_Ship1
local GUI_Button_Ship2
local GUI_Button_Ship3
local GUI_Button_Ship4
local GUI_Button_Ship5

local IsShaking = nil
local ShakeIntensity = 90
local ShakeDuration = 0.2
local OldFramePoints = {}
local shakeTarget = _G.WorldFrame
local frame = CreateFrame'Frame'
frame:Hide()

frame:SetScript('OnUpdate', function(self, elapsed)
	if type(IsShaking) == 'number' then
		IsShaking = IsShaking - elapsed
		if IsShaking <= 0 then
			IsShaking = nil
			shakeTarget:ClearAllPoints()
			for index, value in pairs(OldFramePoints) do
				shakeTarget:SetPoint(value.point, value.xOffset, value.yOffset)
			end
            frame:Hide()
		else
			shakeTarget:ClearAllPoints()
			local moveBy
			moveBy = math.random(-100, 100)/(101 - ShakeIntensity)
			for index, value in pairs(OldFramePoints) do
				shakeTarget:SetPoint(value.point, value.xOffset + moveBy, value.yOffset + moveBy);
			end
		end
	end
end)

function Battleships:ShakeScreen(intensity, duration, target)
	if not IsShaking then
	
		if not intensity then
			ShakeIntensity = 90
		else
			ShakeIntensity = intensity
		end
		
		if not duration then
			ShakeDuration = 0.2
		else
			ShakeDuration = duration
		end
		
		if not target then
			shakeTarget = _G.WorldFrame
		else
			if type(target) ~= "table" then
				target = _G[target]
			end
			
			shakeTarget = target
		end

		OldFramePoints = {}
		for i = 1, shakeTarget:GetNumPoints() do
			local point, frame, relPoint, xOffset, yOffset = shakeTarget:GetPoint(i)
			OldFramePoints[i] = {
				["point"] = point,
				["frame"] = frame,
				["relPoint"] = relPoint,
				["xOffset"] = xOffset,
				["yOffset"] = yOffset,
			}
		end
		IsShaking = ShakeDuration
        frame:Show()
	end
end

local soundbase = [[Interface\AddOns\Battleships\sound\]]
local sound = {
	["hit"] = {
		["enemy"] = function()
			local file = {
				[[hit_enemy1.wav]],
				[[hit_enemy2.wav]],
				[[hit_enemy3.wav]],
				[[hit_enemy4.wav]]
			}
			return soundbase..file[random(1,4)]
		end,
		["player"] = function()
			local file = {
				[[shot1.wav]],
				[[shot2.wav]],
				[[shot3.wav]]
			}
			return soundbase..file[random(1,3)]
		end,
		["explosion"] = function()
			local file = {
				[[ship_explosion1.wav]],
				[[ship_explosion2.wav]],
				[[ship_explosion3.wav]],
				[[ship_explosion4.wav]]
			}
			return soundbase..file[random(1,4)]
		end,
	},
	["miss"] = {
		["enemy"] = function()
			local file = {
				[[miss_enemy1.wav]],
				[[miss_enemy1.wav]],
				[[miss_enemy1.wav]]
			}
			return soundbase..file[random(1,3)]
		end,
		["player"] = function()
			local file = {
				[[horn1.wav]],
				[[horn2.wav]],
				[[horn3.wav]],
				[[horn4.wav]],
				[[horn5.wav]]
			}
			return soundbase..file[random(1,5)]
		end,
	},
	["shot"] = function()
		local file = {
			[[shot1.wav]],
			[[shot2.wav]],
			[[shot3.wav]]
		}
		return soundbase..file[random(1,3)]
	end,
}
--PlaySoundFile([[Interface\AddOns\HawkenPlates\sound\explosion\]] .. file[random(1,9)])

Battleships.currentCell = nil
Battleships.InviteText = ""
Battleships.InviteTextBase = " wants to play ships with you.\n"

Battleships.Message = {}
Battleships.Message["FALSE"] 			= "0"
Battleships.Message["TRUE"] 			= "1"
Battleships.Message["REQ_MATCH"]		= "2"
Battleships.Message["ACK_MATCH"]		= "3"
Battleships.Message["REQ_CONFIRMMATCH"]	= "4"
Battleships.Message["ACK_CONFIRMMATCH"]	= "5"
Battleships.Message["DNY_MATCH"]		= "6"
Battleships.Message["IN_MATCH"] 		= "7"
Battleships.Message["REQ_HIT_CHECK"]	= "8"
Battleships.Message["ACK_HIT"]			= "9"
Battleships.Message["ACK_MISS"]			= "10"
Battleships.Message["GAME_END_EARLY"]	= "11"
Battleships.Message["GAME_LOST"]		= "12"
Battleships.Message["REQ_VERSION"]		= "13"
Battleships.Message["ACK_VERSION"]		= "14"
Battleships.Message["IN_READY"]			= "15"
Battleships.Message["REQ_READY_ROLL"]	= "16"
Battleships.Message["REQ_READY_REROLL"]	= "17"
Battleships.Message["ACK_READY_ROLL"]	= "18"

Battleships.NetworkPrefix = netPrefix
Battleships.NetworkQueue = {}
Battleships.NetworkQueue.busy = false
Battleships.NetworkQueue.busyWith = nil
Battleships.NetworkQueue.busyPlayer = nil
Battleships.NetworkQueue.readyEnemy = nil
Battleships.NetworkQueue.readyPlayer = nil
Battleships.NetworkQueue.rollPlayer = nil
Battleships.NetworkQueue.rollEnemy = nil
Battleships.NetworkQueue.turnPlayer = nil
Battleships.NetworkQueue.firstTurn = nil

Battleships.ClockQueue = {}

Battleships.Game = {}
Battleships.Game.playing = false
Battleships.Game.finished = false

Battleships.Ships = {}
Battleships.Ships["Size"] = {}
Battleships.Ships["Size"][1] = 5 -- Aircraft
Battleships.Ships["Size"][2] = 4 -- Battleship
Battleships.Ships["Size"][3] = 3 -- Submarine
Battleships.Ships["Size"][4] = 3 -- Destroyer
Battleships.Ships["Size"][5] = 2 -- Cruiser

Battleships.Ships.Placed = 0
Battleships.Ships.MaxPlaced = 5
Battleships.Ships.Alive = 5
Battleships.Ships.AllowPlacing = true

Battleships.Ships.ClickResult = {}
Battleships.Ships.ClickResult.Hit = "Hit"
Battleships.Ships.ClickResult.Miss = "Miss"

Battleships.Ships.Player = {}
-- Battleships.Ships.Player[0] = {}
-- Battleships.Ships.Player[0].body = {1, 11, 21, 31, 41} -- placed in top left corner
-- Battleships.Ships.Player[0].damage = {41} -- last segment got hit
-- Battleships.Ships.Player[0].alive = true

Battleships.Ships.Picker = {}
Battleships.Ships.Picker.currentButton = nil
Battleships.Ships.Picker.enabled = false
Battleships.Ships.Picker.size = 0
Battleships.Ships.Picker.rotation = 0

function Battleships:OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("Battleships " .. version .. " loaded")
	Battleships:DisableGridEnemy()
	this:RegisterEvent("CHAT_MSG_ADDON")
	BattleshipFrame = _G["BattleshipsFrame"]
	Clock = _G["BattleshipsClockFrame"]
	
	GUI_Label = _G["BattleshipsFrameLabel"]
	GUI_Label_Me = _G["BattleshipsFrameMeLabel"]
	GUI_Label_Enemy = _G["BattleshipsFrameEnemyLabel"]
	GUI_Warning = _G["BattleshipsFrameWarning"]
	GUI_Warning_Label = _G["BattleshipsFrameWarningText"]
	GUI_Button_Ready = _G["BattleshipsFrameReadyButton"]
	GUI_Button_Clear = _G["BattleshipsFrameClearButton"]

	GUI_Button_Ship1 = _G["BattleshipsFrameButtonAircraft"]
	GUI_Button_Ship2 = _G["BattleshipsFrameButtonBattleship"]
	GUI_Button_Ship3 = _G["BattleshipsFrameButtonSubmarine"]
	GUI_Button_Ship4 = _G["BattleshipsFrameButtonDestroyer"]
	GUI_Button_Ship5 = _G["BattleshipsFrameButtonCruiser"]
end

function Battleships:BuildMessage(...)
	return strjoin(";", ...)
end

function Battleships:ProcessMessage(message, limit)
	if limit then
		return strsplit(";", message, limit)
	end
	
	return strsplit(";", message)
end

function Battleships:Clock_OnUpdate(self, elapsed)
	self.timer = self.timer + elapsed

	if #Battleships.ClockQueue == 0 then
		self:Hide()
	else
		for index, value in pairs(Battleships.ClockQueue) do
			if Battleships.ClockQueue[index].delay ~= nil and self.timer >= Battleships.ClockQueue[index].delay then
				if type(Battleships.ClockQueue[index].func) == "function" then
					Battleships.ClockQueue[index].func()
					tremove(Battleships.ClockQueue, index)
				end
			end
		end
	end
	
end

--[[
	obj = {
		delay: time in seconds,
		func: yourFunctionToRun
	}
]]
function Battleships:Clock_Add(obj)
	table.insert(Battleships.ClockQueue, obj)
	Clock:Show()
end

function Battleships:OnEvent(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...
		if prefix ~= Battleships.NetworkPrefix then return end
		local msg_type = Battleships:ProcessMessage(message, 2)
		
		if debug then DEFAULT_CHAT_FRAME:AddMessage(tostring(prefix) .. ' | ' .. tostring(msg_type) .. ' | ' .. tostring(message) .. ' | ' .. tostring(channel) .. ' | ' .. tostring(sender)) end
		
		if msg_type == Battleships.Message["REQ_VERSION"] then
			SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_VERSION"], version), "WHISPER", sender)
		end
		
		if msg_type == Battleships.Message["IN_READY"] and Battleships.NetworkQueue.busyPlayer == sender then
			Battleships.NetworkQueue.readyEnemy = true
			Battleships:CheckReady()
		end
		
		if msg_type == Battleships.Message["REQ_HIT_CHECK"] and Battleships.NetworkQueue.busyPlayer == sender then
			local netPrefix, position = Battleships:ProcessMessage(message)
			local hit = Battleships:HitPlayer(tonumber(position))
			
			if hit then
				SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_HIT"], position), "WHISPER", sender)
			else 
				SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_MISS"], position), "WHISPER", sender)
			end
			
			Battleships.NetworkQueue.turnPlayer = not Battleships.NetworkQueue.turnPlayer
			
			Battleships:OnTurn()
		end
		
		if msg_type == Battleships.Message["ACK_HIT"] or msg_type == Battleships.Message["ACK_MISS"] then
			Battleships.NetworkQueue.turnPlayer = not Battleships.NetworkQueue.turnPlayer
			
			Battleships:OnTurn()
		end
		
		if msg_type == Battleships.Message["ACK_HIT"] and Battleships.NetworkQueue.busyPlayer == sender then
			local netPrefix, position = Battleships:ProcessMessage(message)
			Battleships:HitEnemyShip(tonumber(position), Battleships.Ships.ClickResult.Hit)
		end
		
		if msg_type == Battleships.Message["ACK_MISS"] and Battleships.NetworkQueue.busyPlayer == sender then
			local netPrefix, position = Battleships:ProcessMessage(message)
			Battleships:HitEnemyShip(tonumber(position), Battleships.Ships.ClickResult.Miss)
		end
		
		if msg_type == Battleships.Message["ACK_VERSION"] then
			if debug then DEFAULT_CHAT_FRAME:AddMessage(Battleships.NetworkQueue.busyWith .. ' | ' .. Battleships.NetworkQueue.busyPlayer) end
			if Battleships.NetworkQueue.busyWith == Battleships.Message["REQ_VERSION"] and Battleships.NetworkQueue.busyPlayer == sender then
				Battleships.NetworkQueue.busyWith = nil
				Battleships.NetworkQueue.busyPlayer = nil
				Battleships.NetworkQueue.busy = false
				local netPrefix, netVersion = Battleships:ProcessMessage(message)
				
				if netVersion == version then
					Battleships.NetworkQueue.busyWith = Battleships.Message["REQ_MATCH"]
					Battleships.NetworkQueue.busyPlayer = sender
					Battleships.NetworkQueue.busy = true
					if debug then DEFAULT_CHAT_FRAME:AddMessage("Version confirmed") end
					local obj = {
						delay = 1,
						func = function(self)
							DEFAULT_CHAT_FRAME:AddMessage("Sending match invitation to " .. Battleships.NetworkQueue.busyPlayer)
							SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_MATCH"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
						end,
					}
					Battleships:Clock_Add(obj)
				else
					StaticPopup_Show("SHIPS_VERSION_MISMATCH")
				end
			end
		end
		
		if msg_type == Battleships.Message["IN_MATCH"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				Battleships.NetworkQueue.busyPlayer = nil
				Battleships.NetworkQueue.busy = false
				Battleships.NetworkQueue.busyWith = nil
				DEFAULT_CHAT_FRAME:AddMessage(sender .. " is busy with other game")
			end
		end
		
		if msg_type == Battleships.Message["REQ_MATCH"] then
			if Battleships.Game.playing or Battleships.Game.finished or Battleships.NetworkQueue.busy then
				DEFAULT_CHAT_FRAME:AddMessage(sender .. " requested a match but you're busy")
				SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["IN_MATCH"]), "WHISPER", sender)
			else
				Battleships.NetworkQueue.busyWith = Battleships.Message["REQ_MATCH"]
				Battleships.NetworkQueue.busyPlayer = sender
				Battleships.NetworkQueue.busy = true
				Battleships.InviteText = Battleships.NetworkQueue.busyPlayer .. Battleships.InviteTextBase
				StaticPopup_Show("SHIPS_INVITE")
			end
		end
		
		if msg_type == Battleships.Message["ACK_MATCH"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				Battleships.NetworkQueue.busyWith = Battleships.Message["IN_MATCH"]
				SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_CONFIRMMATCH"]), "WHISPER", sender)
				
				return
			end
			
			SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["DNY_MATCH"]), "WHISPER", sender)
		end
		
		if msg_type == Battleships.Message["REQ_CONFIRMMATCH"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_CONFIRMMATCH"]), "WHISPER", sender)
				Battleships:StartMatch()
			end
		end
		
		if msg_type == Battleships.Message["ACK_CONFIRMMATCH"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				Battleships:StartMatch()
			end
		end
		
		if msg_type == Battleships.Message["DNY_MATCH"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				Battleships.NetworkQueue.busyPlayer = nil
				Battleships.NetworkQueue.busy = false
				Battleships.NetworkQueue.busyWith = nil
				DEFAULT_CHAT_FRAME:AddMessage(sender .. " denied your request")
			end
		end
		
		if msg_type == Battleships.Message["REQ_READY_ROLL"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				local netPrefix, roll = Battleships:ProcessMessage(message)
				Battleships.NetworkQueue.rollEnemy = tonumber(roll)
				Battleships:OnReadyRoll()
			end
		end
		
		if msg_type == Battleships.Message["REQ_READY_REROLL"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				local netPrefix, roll = Battleships:ProcessMessage(message)
				Battleships.NetworkQueue.rollEnemy = tonumber(roll)
				Battleships:OnReadyRoll()
			end
		end
		
		if msg_type == Battleships.Message["ACK_READY_ROLL"] then
			if Battleships.NetworkQueue.busyPlayer == sender and Battleships.NetworkQueue.busyWith == msg_type then
				Battleships.NetworkQueue.turnPlayer = Battleships.NetworkQueue.rollPlayer > Battleships.NetworkQueue.rollEnemy
				
				Battleships:OnGameStart(Battleships.NetworkQueue.turnPlayer)
			end
		end
		
		if msg_type == Battleships.Message["GAME_END_EARLY"] or msg_type == Battleships.Message["GAME_LOST"] then
			if Battleships.NetworkQueue.busyPlayer == sender then
				Battleships.NetworkQueue.busyPlayer = nil
				Battleships.NetworkQueue.busy = false
				Battleships.NetworkQueue.busyWith = nil
				Battleships.NetworkQueue.readyEnemy = nil
				Battleships.NetworkQueue.readyPlayer = nil
				
				Battleships.Game.playing = false
				Battleships.Game.finished = true

				GUI_Warning_Label:SetText("Enemy gave up. You have won!")
				
				if msg_type == Battleships.Message["GAME_LOST"] then
					local netPrefix, position = Battleships:ProcessMessage(message)
					Battleships:HitEnemyShip(tonumber(position), Battleships.Ships.ClickResult.Hit)
					
					GUI_Warning_Label:SetText("You have won!")
				end
				
				Battleships:DisableGrids()
				
				GUI_Warning:Show()
				
				BattleshipFrame.shine.animIn:Play()
				BattleshipFrame.glowLeft.animIn:Play()
				BattleshipFrame.glowRight.animIn:Play()
			end
		end
		
	end
end

function Battleships:StartMatch()
	Battleships:Reset()
	Battleships.Game.playing = true
	_G["BattleshipsFrame"]:Show()
end

function Battleships:Reset()
	GUI_Warning:Hide()
	GUI_Warning_Label:SetText("")
	
	GUI_Button_Ready:Disable()
	GUI_Button_Clear:Enable()
	
	GUI_Button_Ship1:Enable()
	GUI_Button_Ship2:Enable()
	GUI_Button_Ship3:Enable()
	GUI_Button_Ship4:Enable()
	GUI_Button_Ship5:Enable()
	
	Battleships:EnableGridMe()
	
	Battleships:SetStatus("Preparing for battle")
	GUI_Label_Me:SetText("Me")
	GUI_Label_Enemy:SetText(Battleships.NetworkQueue.busyPlayer)
	
end

function Battleships:OnMouseUp(self, button)
	if button == "RightButton" and Battleships.Ships.Picker.enabled then
		if Battleships.Ships.Picker.currentButton ~= nil then
			Battleships.Ships.Picker.currentButton:Enable()
			Battleships.Ships.Picker.currentButton = nil
		end
		Battleships.Ships.Picker.enabled = false
		SetCursor(nil)
	end			
end

function Battleships:OnMouseWheel(self, delta)
	if Battleships.Ships.Picker.enabled and Battleships.currentCell ~= nil then
		PlaySound("igMainMenuOpen");
		
		Battleships:ClearShadow(Battleships.currentCell, true)
		
		if Battleships.Ships.Picker.rotation == 0 then
			Battleships.Ships.Picker.rotation = 1
		else 
			Battleships.Ships.Picker.rotation = 0
		end
		
		Battleships:DrawShadow(Battleships.currentCell)
	end			
end

function Battleships:TryReadyButton()
	if Battleships.Ships.Placed == Battleships.Ships.MaxPlaced then
		GUI_Button_Ready:Enable()
	else
		GUI_Button_Ready:Disable()
	end
end

function Battleships:ReadyButton_OnClick(self)
	self:Disable()
	GUI_Button_Clear:Disable()
	Battleships:DisableGridMe()
	Battleships.NetworkQueue.readyPlayer = true
	
	SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["IN_READY"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
	
	if not Battleships.NetworkQueue.readyEnemy then
		Battleships:SetStatus("Waiting for enemy to setup")
	end
	
	Battleships:CheckReady()
end

function Battleships:ClearButton_OnClick(self)
	Battleships:ClearShips()
end

function Battleships:ClearShips()
	Battleships.Ships.Placed = 0
	Battleships.Ships.Alive = 5
	Battleships.Ships.AllowPlacing = true
	Battleships.Ships.Player = {}
	Battleships.Ships.Picker.currentButton = nil
	Battleships.Ships.Picker.enabled = false
	Battleships.Ships.Picker.size = 0
	Battleships.Ships.Picker.rotation = 0
	
	local button, childs
	for i = 1, 100 do
		button = _G["BattleshipsFrameMeItem" .. i]
		childs = {button:GetChildren()}
		-- check for collision with other ships, if any
		for _, child in ipairs(childs) do
			child:Hide()
		end
		button:Enable()
	end
	
	for i = 1, 100 do
		button = _G["BattleshipsFrameEnemyItem" .. i]
		childs = {button:GetChildren()}
		-- check for collision with other ships, if any
		for _, child in ipairs(childs) do
			child:Hide()
		end
		button:Enable()
	end
	
	GUI_Button_Ship1:Enable()
	GUI_Button_Ship2:Enable()
	GUI_Button_Ship3:Enable()
	GUI_Button_Ship4:Enable()
	GUI_Button_Ship5:Enable()
end

function Battleships:ShipPicker_OnClick(self, id)

	if Battleships.Ships.Picker.enabled then
		if Battleships.Ships.Picker.currentButton ~= nil then
			Battleships.Ships.Picker.currentButton:Enable()
		end
	end
	
	Battleships.Ships.Picker.currentButton = self
	Battleships.Ships.Picker.enabled = true
	Battleships.Ships.Picker.size = Battleships.Ships["Size"][id]
end

function Battleships:Close_OnClick(self)
	HideParentPanel(self);
	
	if Battleships.Game.playing then
		Battleships.Game.playing = false
		SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["GAME_END_EARLY"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
	end
	
	Battleships:ClearShips()
	Battleships:OnWindowClose()
end

function Battleships:OnWindowClose()
	Battleships.Game.finished = false
	Battleships.NetworkQueue.busy = false
	Battleships.NetworkQueue.busyWith = nil
	Battleships.NetworkQueue.busyPlayer = nil
	Battleships.NetworkQueue.readyEnemy = nil
	Battleships.NetworkQueue.readyPlayer = nil
	Battleships.NetworkQueue.rollEnemy = nil
	Battleships.NetworkQueue.rollPlayer = nil
	Battleships.NetworkQueue.turnPlayer = nil
	Battleships.NetworkQueue.firstTurn = nil
	
	GUI_Button_Ship1:Disable()
	GUI_Button_Ship2:Disable()
	GUI_Button_Ship3:Disable()
	GUI_Button_Ship4:Disable()
	GUI_Button_Ship5:Disable()
	
	Battleships:DisableGrids()
end

function Battleships:Grid_OnClick(self, button)
	
end

function Battleships:GridMe_OnClick(self, button)
	if button == "LeftButton" then
		if Battleships.Ships.AllowPlacing == false or 
			Battleships.Ships.Picker.enabled == false or
			Battleships:CanPlaceShip(self) == false then 
			return
		end
		
		Battleships.Ships.Picker.enabled = false
		
		local childs = {self:GetChildren()}
		local id = self:GetID()
		local direction = "Down"
		local currentCell = self
		
		if Battleships.Ships.Picker.rotation == 0 then
			direction = "Down"
		else
			direction = "Right"
		end

		local ship = {}
		ship.body = {}
		ship.damage = {}
		ship.alive = true
		
		-- draw at mouse position
		for _, child in ipairs(childs) do
			if child:GetName() == "Ship" then
				child:Show()
				table.insert(ship.body, id)
				break
			end
		end
		
		-- draw rest of the ship
		for i = 1, Battleships.Ships.Picker.size-1 do
			currentCell = Battleships:GetNeighbourCell(currentCell, direction)
			if currentCell == nil then break end
			
			childs = {currentCell:GetChildren()}
			id = currentCell:GetID()
			for _, child in ipairs(childs) do
				if child:GetName() == "Ship" then
					child:Show()
					table.insert(ship.body, id)
					break
				end
			end
			--currentCell:Disable()
		end
		
		
		table.insert(Battleships.Ships.Player, ship)
		Battleships.Ships.Placed = Battleships.Ships.Placed + 1
		
		Battleships:TryReadyButton()
		
		--self:Disable()
		SetCursor(nil)
	elseif button == "RightButton" then
		
	end
end

function Battleships:GridEnemy_OnClick(self, button)
	if debug then DEFAULT_CHAT_FRAME:AddMessage("OnClickGridEnemy: " .. self:GetName() .. " clicked (ID: " .. self:GetID() .. ")") end
	PlaySoundFile(sound.hit.player())
	Battleships:DisableGridEnemy(true)
	Battleships:HitEnemy(self:GetID())
end

function Battleships:DisableGridEnemy(onlyMouseHandler)
	if onlyMouseHandler then
		for i = 1, 100 do
			local button = _G["BattleshipsFrameEnemyItem" .. i]
			button:EnableMouse(false)
		end
		return
	end
	
	for i = 1, 100 do
		local button = _G["BattleshipsFrameEnemyItem" .. i]
		button:Disable()
	end
end

function Battleships:DisableGridMe()
	for i = 1, 100 do
		local button = _G["BattleshipsFrameMeItem" .. i]
		button:Disable()
	end
end

function Battleships:EnableGridEnemy(onlyMouseHandler)
	if onlyMouseHandler then
		for i = 1, 100 do
			local button = _G["BattleshipsFrameEnemyItem" .. i]
			button:EnableMouse(true)
		end
		return
	end
	
	for i = 1, 100 do
		local button = _G["BattleshipsFrameEnemyItem" .. i]
		button:Enable()
	end
end

function Battleships:EnableGridMe()
	for i = 1, 100 do
		local button = _G["BattleshipsFrameMeItem" .. i]
		button:Enable()
		button:EnableMouse(true)
	end
end

function Battleships:DisableGrids()
	Battleships:DisableGridMe()
	Battleships:DisableGridEnemy()
end

function Battleships:EnableGrids()
	Battleships:EnableGridMe()
	Battleships:EnableGridEnemy()
end

-- Battleships:GetNeighbourCell(frame currentCell, string direction)
--  direction: "Up", "Down", "Left", "Right"
--  returns neighbour cell in a grid if there is any or nil
--
--  assumes grid is a square of 10x10 cells
--  frame name must contain number of the cell at the end, starting from 1 to 100
--  eg. MyGridCell5
function Battleships:GetNeighbourCell(currentCell, direction)
	local id = currentCell:GetID()
	local baseName = string.sub(currentCell:GetName(), 1, -1-strlen(id))
	
	--DEFAULT_CHAT_FRAME:AddMessage("Basename: '" .. baseName .. "', ID: '" .. id .. "', direction: " .. direction)
	
	if direction == "Up" then
		if id <= 10 then -- we're at the top row and we cant go any higher that this
			--DEFAULT_CHAT_FRAME:AddMessage("nil (1)")
			return nil
		else
			return _G[baseName .. (id-10)]
		end
	elseif direction == "Down" then
		if id > 90 then
			--DEFAULT_CHAT_FRAME:AddMessage("nil (2)")
			return nil
		else
			--DEFAULT_CHAT_FRAME:AddMessage("Returning '" .. baseName .. (id+10) .. "'")
			return _G[baseName .. (id+10)]
		end
	elseif direction == "Left" then
		if math.fmod((id-1), 10) == 0 then
			--DEFAULT_CHAT_FRAME:AddMessage("nil (3)")
			return nil
		else
			return _G[baseName .. (id-1)]
		end
	elseif direction == "Right" then
		if math.fmod(id, 10) == 0 then
			--DEFAULT_CHAT_FRAME:AddMessage("nil (4)")
			return nil
		else
			return _G[baseName .. (id+1)]
		end
	end
end

-- helper function
local function IsTouching(number, border)
	if border == "Left" then
		if math.fmod((number-1), 10) == 0 then
			return true
		else
			return false
		end
	elseif border == "Right" then
		if math.fmod(number, 10) == 0 then
			return true
		else
			return false
		end
	elseif border == "Top" then
		if number <= 10 then
			return true
		else
			return false
		end
	elseif border == "Bottom" then
		if number > 90 then
			return true
		else
			return false
		end
	end
end

-- helper function
local function IsTouchingS(ship, border)
	if border == "Left" then
		for index, number in ipairs(ship) do
			if math.fmod((number-1), 10) == 0 then
				return true
			end
		end
		return false
	elseif border == "Right" then
		for index, number in ipairs(ship) do
			if math.fmod(number, 10) == 0 then
				return true
			end
		end
		return false
	elseif border == "Top" then
		for index, number in ipairs(ship) do
			if number <= 10 then
				return true
			end
		end
		return false
	elseif border == "Bottom" then
		for index, number in ipairs(ship) do
			if number > 90 then
				return true
			end
		end
		return false
	end
end

function Battleships:ContainsShip(t)
	local baseName = "BattleshipsFrameMeItem"
	local currentCell
	
	for index, value in ipairs(t) do
		currentCell = _G[baseName .. value]
		if currentCell ~= nil then 
			childs = {currentCell:GetChildren()}
			for _, child in ipairs(childs) do
				if child:GetName() == "Ship" then
					if child:IsShown() then
						if debug then DEFAULT_CHAT_FRAME:AddMessage(baseName .. value .. " SHIP!") end
						return true
					end
					break -- not really neccessary but w/e
				end
			end
		end
		if debug then DEFAULT_CHAT_FRAME:AddMessage(baseName .. value .. " empty") end
	end
	
	return false
end

function Battleships:CanPlaceShip(button)
	if Battleships.Ships.AllowPlacing == false or 
		Battleships.Ships.Picker.enabled == false or
		not button then 
		return false 
	end
	
	local direction = "Down"
	local currentCell = button
	local id = currentCell:GetID()
	local baseName = string.sub(currentCell:GetName(), 1, -1-strlen(id))
	local baseID = id
	local childs = {currentCell:GetChildren()}
	ship = {}
	
	if Battleships.Ships.Picker.rotation == 0 then
		direction = "Down"
	else
		direction = "Right"
	end
	
	local TopLeft, TopRight, BottomLeft, BottomRight, field, height
	Battleships.fields = {}
	
	table.insert(ship, id)
	for i = 1, Battleships.Ships.Picker.size-1 do
		currentCell = Battleships:GetNeighbourCell(currentCell, direction)
	
		-- check if there is enough space for ship
		if currentCell == nil then 
			return false
		end
		
		childs = {currentCell:GetChildren()}
		id = currentCell:GetID()
		
		-- check for collision with other ships, if any
		for _, child in ipairs(childs) do
			if child:GetName() == "Ship" then
				if child:IsShown() then
					return false
				end
				break
			end
		end
		table.insert(ship, id)
	end
	
	if IsTouchingS(ship, "Left") then -- touching left border
		if debug then DEFAULT_CHAT_FRAME:AddMessage("LEFT") end
		if IsTouchingS(ship, "Bottom") then -- touching left AND bottom border
			if direction == "Down" then
				TopLeft = baseID - 10
				TopRight = TopLeft + 1
				BottomLeft = baseID
				BottomRight = baseID + 1
			elseif direction == "Right" then
				TopLeft = baseID - 10
				TopRight = TopLeft + Battleships.Ships.Picker.size
				BottomLeft = baseID 
				BottomRight = TopRight + 10
			end
		elseif IsTouchingS(ship, "Top") then -- touching left AND top border
			if direction == "Down" then
				TopLeft = baseID
				TopRight = baseID + 1
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID
				TopRight = baseID + Battleships.Ships.Picker.size
				BottomLeft = TopLeft + 10
				BottomRight = TopRight + 10
			end
		else
			if direction == "Down" then
				TopLeft = baseID - 10
				TopRight = TopLeft + 1
				BottomLeft = baseID + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID - 10
				TopRight = TopLeft + Battleships.Ships.Picker.size
				BottomLeft = baseID + 10
				BottomRight = TopRight + 20
			end
		end
	elseif IsTouchingS(ship, "Right") then -- touching right border	
		if IsTouchingS(ship, "Bottom") then -- touching right AND bottom border
			if debug then DEFAULT_CHAT_FRAME:AddMessage("RIGHTBOTTOM") end
			if direction == "Down" then
				TopLeft = baseID - 11
				TopRight = baseID - 10
				BottomLeft = baseID - 1
				BottomRight = baseID
			elseif direction == "Right" then
				TopLeft = baseID - 11
				TopRight = TopLeft + Battleships.Ships.Picker.size + 1
				if IsTouching(TopRight, "Left") then TopRight = TopRight-1 end
				BottomLeft = baseID - 1
				BottomRight = TopRight + 10
			end
		elseif IsTouchingS(ship, "Top") then -- touching right AND top border
			if debug then DEFAULT_CHAT_FRAME:AddMessage("RIGHTTOP") end
			if direction == "Down" then
				TopLeft = baseID - 1
				TopRight = baseID
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID - 1
				TopRight = TopLeft + Battleships.Ships.Picker.size + 1
				if IsTouching(TopRight, "Left") then TopRight = TopRight-1 end
				BottomLeft = TopLeft + 10
				BottomRight = TopRight + 10
			end
		else
			if debug then DEFAULT_CHAT_FRAME:AddMessage("RIGHT") end
			if direction == "Down" then
				TopLeft = baseID - 11
				TopRight = baseID - 10
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10) + 10
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID - 11
				TopRight = TopLeft + Battleships.Ships.Picker.size + 1
				if IsTouching(TopRight, "Left") then TopRight = TopRight-1 end
				BottomLeft = TopLeft + 20
				BottomRight = TopRight + 20
			end
		end
	elseif IsTouchingS(ship, "Bottom") then -- touching bottom border
		if IsTouchingS(ship, "Left") then -- touching bottom AND left border
			if debug then DEFAULT_CHAT_FRAME:AddMessage("BOTTOMLEFT") end
			if direction == "Down" then
				TopLeft = baseID - 10
				TopRight = TopLeft + 1
				BottomLeft = baseID
				BottomRight = baseID + 1
			elseif direction == "Right" then
				TopLeft = baseID - 10
				TopRight = baseID + (Battleships.Ships.Picker.size * 10) - 10
				BottomLeft = baseID 
				BottomRight = TopRight + 10
			end
		elseif IsTouchingS(ship, "Right") then -- touching bottom AND right border
			if debug then DEFAULT_CHAT_FRAME:AddMessage("BOTTOMRIGHT") end
			if direction == "Down" then
				TopLeft = baseID - 11
				TopRight = baseID - 10
				BottomLeft = baseID - 1
				BottomRight = baseID
			elseif direction == "Right" then
				TopLeft = baseID - 11
				TopRight = baseID - 10
				BottomLeft = baseID - 1
				BottomRight = baseID
			end
		else
			if debug then DEFAULT_CHAT_FRAME:AddMessage("BOTTOM") end
			if direction == "Down" then
				TopLeft = baseID - 11
				TopRight = baseID + 1 - 10
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 2
			elseif direction == "Right" then
				TopLeft = baseID - 11
				TopRight = TopLeft + Battleships.Ships.Picker.size + 1
				BottomLeft = baseID - 1
				BottomRight = TopRight + 10
			end
		end
	elseif IsTouchingS(ship, "Top") then -- touching top border
		if debug then DEFAULT_CHAT_FRAME:AddMessage("TOP") end
		if IsTouchingS(ship, "Left") then -- touching top AND left border
			if direction == "Down" then
				TopLeft = baseID
				TopRight = baseID + 1
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID
				TopRight = baseID + Battleships.Ships.Picker.size
				BottomLeft = TopLeft + 10
				BottomRight = TopRight + 10
			end
		elseif IsTouchingS(ship, "Right") then -- touching top AND right border
			if direction == "Down" then
				TopLeft = baseID - 10
				TopRight = baseID
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10) + 10
				BottomRight = BottomLeft + 1
			elseif direction == "Right" then
				TopLeft = baseID - 10
				TopRight = baseID
				BottomLeft = TopLeft + 10
				BottomRight = BottomLeft + 1
			end
		else
			if direction == "Down" then
				TopLeft = baseID - 1
				TopRight = baseID + 1
				BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10)
				BottomRight = BottomLeft + 2
			elseif direction == "Right" then
				TopLeft = baseID - 1
				TopRight = baseID + Battleships.Ships.Picker.size
				BottomLeft = TopLeft + 10
				BottomRight = TopRight + 10
			end
		end
	else -- not touching any border
		if debug then DEFAULT_CHAT_FRAME:AddMessage("NONE") end
		if direction == "Down" then
			TopLeft = baseID - 11
			TopRight = baseID + 1 - 10
			BottomLeft = TopLeft + (Battleships.Ships.Picker.size * 10) + 10
			BottomRight = TopLeft + 2
		elseif direction == "Right" then
			TopLeft = baseID - 11
			TopRight = baseID + Battleships.Ships.Picker.size - 10
			BottomLeft = TopLeft + 20
			BottomRight = baseID + Battleships.Ships.Picker.size + 10
		end
	end
	
	height = (BottomLeft - TopLeft) / 10
	
	for x = TopLeft, TopRight do
		for y = 0, height do
			field = x + (y * 10)
			table.insert(Battleships.fields, field)
		end
	end
	
	if Battleships:ContainsShip(Battleships.fields) then
		return false
	end
	
	if debug then DEFAULT_CHAT_FRAME:AddMessage("-------------") end

	return true
end

function Battleships:DrawShadow(button)
	if	Battleships.Ships.AllowPlacing == false or 
		Battleships.Ships.Picker.enabled == false or
		Battleships:CanPlaceShip(button) == false then
		return
	end
	
	local childs = {button:GetChildren()}
	local id = button:GetID()
	local direction = "Down"
	local currentCell = button
	
	Battleships.currentCell = button
	
	if Battleships.Ships.Picker.rotation == 0 then
		direction = "Down"
	else
		direction = "Right"
	end
	
	-- draw at mouse position
	for _, child in ipairs(childs) do
		if child:GetName() == "ShipShadow" then
			child:Show()
			break
		end
	end
	
	-- draw rest of the ship
	for i = 1, Battleships.Ships.Picker.size-1 do
		currentCell = Battleships:GetNeighbourCell(currentCell, direction)
		if currentCell == nil then break end
		
		childs = {currentCell:GetChildren()}
		for _, child in ipairs(childs) do
			if child:GetName() == "ShipShadow" then
				child:Show()
				break
			end
		end
	end
	
end

-- works pretty much same way as Battleships:DrawShadow(self), except in reverse mode
function Battleships:ClearShadow(self, quick)
	if Battleships.Ships.AllowPlacing == false or Battleships.Ships.Picker.enabled == false then return end
	
	local direction = "Down"
	local currentCell = self
	local childs = {self:GetChildren()}
	
	if Battleships.Ships.Picker.rotation == 0 then
		direction = "Down"
	else
		direction = "Right"
	end
	
	if quick then
		for _, child in ipairs(childs) do
			if child:GetName() == "ShipShadow" then
				child:Hide()
				break
			end
		end
		
		for i = 1, Battleships.Ships.Picker.size-1 do
			currentCell = Battleships:GetNeighbourCell(currentCell, direction)
			if currentCell == nil then break end
			
			childs = {currentCell:GetChildren()}
			for _, child in ipairs(childs) do
				if child:GetName() == "ShipShadow" then
					child:Hide()
					break
				end
			end
		end
		
		return
	end
	
	local button
	for i = 1, 100 do
		button = _G["BattleshipsFrameMeItem" .. i]
		childs = {button:GetChildren()}
		
		for _, child in ipairs(childs) do
			if child:GetName() == "ShipShadow" then
				child:Hide()
				break
			end
		end
	end
end

function Battleships:HitPlayer(position)
	local ship = Battleships:CheckForHitPlayer(position)
	if ship ~= nil then
		Battleships:HitPlayerShip(ship, position)
		return true
	else
		local baseName = "BattleshipsFrameMeItem"
		local currentCell = _G[baseName .. position]
		if currentCell ~= nil then 
			childs = {currentCell:GetChildren()}
			for _, child in ipairs(childs) do
				if child:GetName() == "Miss" then
					--child:Show()
					Battleships:OnShipMiss(position, true)
					UIFrameFlash(child, 0.5, 0.5, 1, true)
					break
				end
			end
		end
		return false
	end
end

function Battleships:CheckForHitPlayer(position)
	for index, key in ipairs(Battleships.Ships.Player) do
		if tContains(Battleships.Ships.Player[index].body, position) then
			return index
		end
	end
	return nil
end

function Battleships:HitPlayerShip(shipIndex, position)
	if tContains(Battleships.Ships.Player[shipIndex].damage, position) == nil then
	
		table.insert(Battleships.Ships.Player[shipIndex].damage, position)
		local baseName = "BattleshipsFrameMeItem"
		local currentCell

		currentCell = _G[baseName .. position]
		if currentCell ~= nil then 
			childs = {currentCell:GetChildren()}
			for _, child in ipairs(childs) do
				if child:GetName() == "Hit" then
					--child:Show()
					Battleships:OnShipHit(position, true)
					UIFrameFadeIn(child, 0.5, 0, 1)
					break
				end
			end
		end
	end
	
	if #Battleships.Ships.Player[shipIndex].damage == #Battleships.Ships.Player[shipIndex].body then
		Battleships.Ships.Player[shipIndex].alive = false
		Battleships.Ships.Alive = Battleships.Ships.Alive - 1
		
		if debug then DEFAULT_CHAT_FRAME:AddMessage(format("Damage: %s [DEAD]", shipIndex)) end
		
		Battleships:OnShipDead(position)
	end
	
	if debug then  DEFAULT_CHAT_FRAME:AddMessage(format("Damage: %d / %d", #Battleships.Ships.Player[shipIndex].damage, #Battleships.Ships.Player[shipIndex].body)) end
end

function Battleships:HitEnemy(position)
	Battleships:CheckForHitEnemy(position)
end

function Battleships:CheckForHitEnemy(position)
	-- TO-DO networking
	if not Battleships.Game.playing then return end
	
	SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_HIT_CHECK"], position), "WHISPER", Battleships.NetworkQueue.busyPlayer)
end

-- Battleships.Ships.ClickResult hitOrMiss 
function Battleships:HitEnemyShip(position, hitOrMiss)
	-- TO-DO networking
	local baseName = "BattleshipsFrameEnemyItem"
	local currentCell = _G[baseName .. position]
	if currentCell ~= nil then 
		currentCell:Disable()
		childs = {currentCell:GetChildren()}
		for _, child in ipairs(childs) do
			if child:GetName() == hitOrMiss then
				--child:Show()
				if hitOrMiss == Battleships.Ships.ClickResult.Hit then
					Battleships:OnShipHit(position, false)
					UIFrameFadeIn(child, 0.5, 0, 1)
				else
					Battleships:OnShipMiss(position, false)
					UIFrameFlash(child, 0.5, 0.5, 1, true)
				end
				break
			end
		end
	end
end

function Battleships:OnShipHit(position, isPlayer)
	if isPlayer then
        Battleships:ShakeScreen(nil, nil, _G["BattleshipsFrame"])
		PlaySoundFile(sound.hit.player())
	else
		PlaySoundFile(sound.hit.enemy())
	end
end

function Battleships:OnShipMiss(position, isPlayer)
	if isPlayer then
		PlaySoundFile(sound.miss.player())
	else
		PlaySoundFile(sound.miss.enemy())
	end
end

function Battleships:OnShipDead(position)
	if not Battleships.NetworkQueue.busyPlayer then return end
	
	Battleships:ShakeScreen(98, 1, _G["BattleshipsFrame"])
	PlaySoundFile(sound.hit.explosion())
	
	if Battleships.Ships.Alive == 0 then
		SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["GAME_LOST"], position), "WHISPER", Battleships.NetworkQueue.busyPlayer)
		
		Battleships.NetworkQueue.busyPlayer = nil
		Battleships.NetworkQueue.busy = false
		Battleships.NetworkQueue.busyWith = nil
		Battleships.NetworkQueue.readyEnemy = nil
		Battleships.NetworkQueue.readyPlayer = nil
		
		Battleships.Game.playing = false
		Battleships.Game.finished = true
		
		Battleships:DisableGrids()
		
		GUI_Warning_Label:SetText("You lost!")
		GUI_Warning:Show()
	end
end

function Battleships:Network_PreInvite(player)
	player = player:sub(1,1):upper()..player:sub(2):lower()
	
	if Battleships.NetworkQueue.busyPlayer and Battleships.NetworkQueue.busyPlayer == player then
		return
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("Sending an pre-invitation to " .. player)
	Battleships.NetworkQueue.busy = true
	Battleships.NetworkQueue.busyPlayer = player
	Battleships.NetworkQueue.busyWith = Battleships.Message["REQ_VERSION"]
	SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_VERSION"]), "WHISPER", player)
end

function Battleships:Network_AcceptInvite()
	Battleships.NetworkQueue.busy = true
	Battleships.NetworkQueue.busyWith = Battleships.Message["ACK_MATCH"]
	SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_MATCH"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
end

function Battleships:Network_DenyInvite()
	Battleships.NetworkQueue.busy = false
	Battleships.NetworkQueue.busyWith = nil
	
	if Battleships.NetworkQueue.busyPlayer then
		SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["DNY_MATCH"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
		Battleships.NetworkQueue.busyPlayer = nil
	end
end

function Battleships:CheckReady()
	if not Battleships.Game.playing then return end
	
	if Battleships.NetworkQueue.readyEnemy and not Battleships.NetworkQueue.readyPlayer then
		Battleships:SetStatus("Enemy is ready. Waiting for you.")
	end
	
	if Battleships.NetworkQueue.readyEnemy and Battleships.NetworkQueue.readyPlayer then
		Battleships:OnPlayersReady()
	end
end

function Battleships:DoStartRoll()
	Battleships.NetworkQueue.busyWith = Battleships.Message["REQ_READY_ROLL"]
	Battleships.NetworkQueue.rollPlayer = random(1,100)
	SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_READY_ROLL"], Battleships.NetworkQueue.rollPlayer), "WHISPER", Battleships.NetworkQueue.busyPlayer)
end

function Battleships:OnPlayersReady()
	Battleships:DoStartRoll()
	--Battleships:EnableGridEnemy()
	--GUI_Label:SetText("Fight!")
end

function Battleships:OnReadyRoll()
	if Battleships.NetworkQueue.rollPlayer and Battleships.NetworkQueue.rollEnemy then
		-- reroll
		if Battleships.NetworkQueue.rollPlayer == Battleships.NetworkQueue.rollEnemy then
			Battleships.NetworkQueue.rollPlayer = random(1,100)
			Battleships.NetworkQueue.rollEnemy = nil
			SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["REQ_READY_REROLL"], Battleships.NetworkQueue.rollPlayer), "WHISPER", Battleships.NetworkQueue.busyPlayer)
			return
		end
		
		-- someone won roll
		Battleships.NetworkQueue.busyWith = Battleships.Message["ACK_READY_ROLL"]
		SendAddonMessage(Battleships.NetworkPrefix, Battleships:BuildMessage(Battleships.Message["ACK_READY_ROLL"]), "WHISPER", Battleships.NetworkQueue.busyPlayer)
	end
end

function Battleships:OnGameStart(playerStarts)
	Battleships:SetStatus("Waiting for enemy turn.")
	
	if playerStarts then
		Battleships.NetworkQueue.firstTurn = true
		Battleships:EnableGridEnemy()
		Battleships:EnableGridEnemy(true)
		Battleships:SetStatus("You start first!")
	end
end

function Battleships:OnTurn()
	if Battleships.NetworkQueue.turnPlayer then
		Battleships:OnTurnPlayer()
	else
		Battleships:OnTurnEnemy()
	end
end

function Battleships:OnTurnPlayer()
	Battleships:SetStatus("Your turn.")
	
	if not Battleships.NetworkQueue.firstTurn then
		Battleships.NetworkQueue.firstTurn = true
		Battleships:EnableGridEnemy()
	end
	
	Battleships:EnableGridEnemy(true)
end

function Battleships:OnTurnEnemy()
	Battleships:SetStatus("Waiting for enemy turn.")
end

function Battleships:SetStatus(text)
	GUI_Label:SetText(text)
	UIFrameFadeIn(GUI_Label, 0.5, 0, 1)
end

SlashCmdList["BATTLESHIPS"] = function(message)
	--SendAddonMessage("Battleships", Battleships.Message["REQUEST_INFO"], "PARTY")
	if not message then return end
	Battleships:Network_PreInvite(message)
end

SLASH_BATTLESHIPS1 = "/ships";
SLASH_BATTLESHIPS2 = "/seabattle";

StaticPopupDialogs["SHIPS_INVITE"] = {
	text = Battleships.InviteText,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnShow = function(self)
		self.text:SetText(Battleships.InviteText)
	end,
	OnAccept = function(self)
		Battleships:Network_AcceptInvite()
	end,
	OnCancel = function(self)
		Battleships:Network_DenyInvite()
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["SHIPS_VERSION_MISMATCH"] = {
	text = "Battleships version mismatch",
	button1 = OKAY,
	timeout = 60,
	whileDead = 1,
};