require "Vehicles/ISUI/ISVehicleMenu"


local ISVehicleMenu_onSleep = ISVehicleMenu.onSleep
---@param playerObj IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function ISVehicleMenu.onSleep(playerObj, vehicle)
	ISVehicleMenu_onSleep(playerObj, vehicle)
	if not playerObj:isAsleep() and not vehicle:isDriver(playerObj) then
		local playerNum = playerObj:getPlayerNum()
		local modal = ISModalDialog:new(0,0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, ISVehicleMenu.onConfirmSleep, playerNum, playerNum, nil);
		modal:initialise()
		modal:addToUIManager()
		if JoypadState.players[playerNum+1] then
			setJoypadFocus(playerNum, modal)
		end
	end
end


local ISVehicleMenu_showRadialMenu = ISVehicleMenu.showRadialMenu
function ISVehicleMenu.showRadialMenu(playerObj)

	ISVehicleMenu_showRadialMenu(playerObj)

	---Checks from vanilla function <compressed>
	if (UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0) then return end
	local vehicle = playerObj:getVehicle() if not vehicle then ISVehicleMenu.showRadialMenuOutside(playerObj) return end
	---@type ISRadialMenu|ISPanelJoypad|ISUIElement|ISBaseObject
	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
	if menu:isReallyVisible() then if menu.joyfocus then setJoypadFocus(playerObj:getPlayerNum(), nil) end menu:undisplay() return end

	local sleepSliceIndex
	for index,slice in pairs(menu.slices) do
		if slice.text == getText("IGUI_PlayerText_CanNotSleepInMovingCar") then
			print("SLICE SLEEP INDEX: "..index)
			sleepSliceIndex = index
		end
	end

	if sleepSliceIndex and (not isClient() or getServerOptions():getBoolean("SleepAllowed")) then
		local newText = ""

		print(" -- A")

		if (not isClient() or getServerOptions():getBoolean("SleepAllowed")) then
			local doSleep = true
			local sleepNeeded = not isClient() or getServerOptions():getBoolean("SleepNeeded")

			print(" -- B")

			if sleepNeeded and (playerObj:getStats():getFatigue() <= 0.3) then
				newText = "IGUI_Sleep_NotTiredEnough"
				doSleep = false
				print(" -- C1")

			elseif vehicle:isDriver(playerObj) and (vehicle:getCurrentSpeedKmHour() > 1 or vehicle:getCurrentSpeedKmHour() < -1) then
				newText = "IGUI_PlayerText_CanNotSleepInMovingCar"
				doSleep = false
				print(" -- C2 - BINGO")

			else
				print(" -- C3")
				if playerObj:getSleepingTabletEffect() < 2000 then

					if playerObj:getMoodles():getMoodleLevel(MoodleType.Pain) >= 2 and playerObj:getStats():getFatigue() <= 0.85 then
						newText = "ContextMenu_PainNoSleep"
						doSleep = false

					elseif playerObj:getMoodles():getMoodleLevel(MoodleType.Panic) >= 1 then
						newText = "ContextMenu_PanicNoSleep"
						doSleep = false

					elseif sleepNeeded and ((playerObj:getHoursSurvived() - playerObj:getLastHourSleeped()) <= 1) then
						newText = "ContextMenu_NoSleepTooEarly"
						doSleep = false
					end
				end
			end
			if doSleep then
				print(" -- D1 - BINGO-ER")
				newText = "ContextMenu_Sleep"
				menu:setSliceText(sleepSliceIndex, getText(newText))
				menu.slices[sleepSliceIndex].command = {ISVehicleMenu.onSleep, playerObj, vehicle}
			end

		end
	end
end