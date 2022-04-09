--
-- WashBeforeFill for LS 22
--
-- # Author:  	LS-Farmers.de
-- # date: 		23.03.2022
--

washBeforeFill = {}
washBeforeFill.MOD_NAME = g_currentModName

function washBeforeFill.prerequisitesPresent(specializations)
  return true
end

function washBeforeFill.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", washBeforeFill)
  if SpecializationUtil.hasSpecialization(Sprayer, vehicleType.specializations) then
    print("listen to Sprayer:onTurnOff Event")
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", washBeforeFill)
  end
end

function washBeforeFill.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "addLittleBit", washBeforeFill.addLittleBit)
end

function washBeforeFill:onLoadFinished(savegame)
  self.setNodeDirtAmount = Utils.appendedFunction(self.setNodeDirtAmount, washBeforeFill.appendToWash)

  if self.handleDischargeOnEmpty ~= nil then
    self.handleDischargeOnEmpty = Utils.appendedFunction(self.handleDischargeOnEmpty, washBeforeFill.handleDischargeOnEmpty)
  end

  if self.getCanDischargeToObject ~= nil then
    self.getCanDischargeToObject = Utils.overwrittenFunction(self.getCanDischargeToObject, washBeforeFill.getCanDischargeToObject)
  end

  if self.getCanDischargeToGround ~= nil then
    self.getCanDischargeToGround = Utils.overwrittenFunction(self.getCanDischargeToGround, washBeforeFill.getCanDischargeToGround)
  end

  if self.spec_sprayer ~= nil and self.getCanBeTurnedOn ~= nil then
    print("overwrite function getCanBeTurnedOn")
    self.getCanBeTurnedOn = Utils.overwrittenFunction(self.getCanBeTurnedOn, washBeforeFill.getCanBeTurnedOn)
  end

  if self.spec_fillUnit ~= nil then
    if self.spec_fillUnit.fillTypeChangeThreshold ~= nil then
        self.spec_fillUnit.fillTypeChangeThreshold = 0
    end
  end

end

function washBeforeFill:handleDischargeOnEmpty(myObject)
    print("append handleDischargeOnEmpty")
    self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
    self:addLittleBit()
end

function washBeforeFill:appendStopTipping(myObject)
    print("appendStopTipping")
    self:addLittleBit()
end

function washBeforeFill:onTurnedOff()
    print("washBeforeFill:onTurnedOff")
    self:addLittleBit()
end

function washBeforeFill:getCanBeTurnedOn(superFunc)
    local spec = self.spec_sprayer
    local myFillLevel = self:getFillUnitFillLevel(self:getSprayerFillUnitIndex())
    if myFillLevel <= 1 and spec.needsToBeFilledToTurnOn and not self:getIsAIActive() then
      return false
    end

    return superFunc(self)

end

function washBeforeFill:getCanDischargeToObject(superFunc,dischargeNode)
    local myFillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
    if myFillLevel <= 1 then
      self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
      return false
    end

    return superFunc(self, dischargeNode)

end

function washBeforeFill:getCanDischargeToGround(superFunc,dischargeNode)
    local myFillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
    if myFillLevel <= 1 then
      self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
      return false
    end

    return superFunc(self, dischargeNode)

end

function washBeforeFill:addLittleBit()
    print("addLittleBit")

     if self:getFillUnits() ~= nil and self:getDirtAmount() > 0 then

        for _, fillUnitTable in pairs(self:getFillUnits()) do
            if fillUnitTable.fillLevel <= 0 then
                print ("  we have to refill a little bit " .. g_fillTypeManager:getFillTypeNameByIndex(fillUnitTable.lastValidFillType))
                self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitTable.fillUnitIndex, 1, fillUnitTable.lastValidFillType, ToolType.UNDEFINED, nil)
                self:setFillUnitFillType(fillUnitTable.fillUnitIndex,fillUnitTable.lastValidFillType)
            else
                print ("  there is still something in the vehicle, nothing to do")
            end
        end
     end

end

function washBeforeFill.appendToWash(nodeData, dirtAmount, force)

     nodeData.isCoverOpen = true
     nodeData.fillTypesToIgnore = {
       [g_fillTypeManager:getFillTypeByName("DIESEL").index] = true,
       [g_fillTypeManager:getFillTypeByName("DEF").index] = true,
       [g_fillTypeManager:getFillTypeByName("AIR").index] = true
       }

     if nodeData:getFillUnits() ~= nil and nodeData:getDirtAmount() == 0 then
        --DebugUtil.printTableRecursively(dirtAmount.fillTypesToIgnore,'ignore .. ',1,2)
        for _, fillUnitTable in pairs(nodeData:getFillUnits()) do

            if nodeData.fillTypesToIgnore[fillUnitTable.fillType] == nil then

                -- read cover status
                if nodeData.spec_cover ~= nil then
                    if nodeData.spec_cover.hasCovers and nodeData.spec_cover.state == 0 then
                        nodeData.isCoverOpen = false
                    end
                end

                if fillUnitTable.fillLevel > 0 and nodeData.isCoverOpen then
                    print ("  cleaning process active")
                    nodeData:addFillUnitFillLevel(nodeData:getOwnerFarmId(), fillUnitTable.fillUnitIndex, -1, fillUnitTable.fillType, ToolType.UNDEFINED, nil)
                end

                if fillUnitTable.fillLevel <= 0 then
                    fillUnitTable.lastValidFillType = 1
                end
            end
        end
     end

end

function washBeforeFill:equipHandtool(superFunc, handtoolFilename, force, noEventSend, equippedCallbackFunction, equippedCallbackTarget)

    print("Overwrite equipHandTool")

    return superFunc(self, handtoolFilename, force, noEventSend, equippedCallbackFunction, equippedCallbackTarget)

end

function washBeforeFill:onActivate(superFunc, allowInput)

    print("Overwrite HandTool:onActivate")

    return superFunc(self, allowInput)

end

function washBeforeFill:setIsWashing(superFunc, doWashing, force, noEventSend)

    --print("Overwrite HighPressureWasherLance.setIsWashing")
    --print("doWashing -> " .. Utils.getNoNil(tostring(doWashing),"not set"))

    if Utils.getNoNil(self.customEnvironment,"unknown") == "FS22_WashBeforeFill" and doWashing then
        --print("This is the special high pressure washer")
        --print("doWashing -> " .. Utils.getNoNil(tostring(doWashing),"not set"))
        --DebugUtil.printTableRecursively(g_currentMission.enterables,'enterables .. ',1,2)
        local engineTurnedOn = false
        if g_currentMission.enterables ~= nil then
            for _, vehicle in pairs(g_currentMission.enterables) do
                --DebugUtil.printTableRecursively(vehicle,'vehicle .. ',1,1)
                --print("-------------------------------------------")
                --print("engineOn before    -> " .. tostring(engineTurnedOn))
                --print("motor started      -> " .. tostring(vehicle:getIsMotorStarted()))
                --print("player node        -> " .. self.currentPlayerHandNode)
                --print("distance to player -> " .. vehicle:getDistanceToNode(self.currentPlayerHandNode))
                if vehicle:getIsMotorStarted() and vehicle:getDistanceToNode(self.currentPlayerHandNode) ~= math.huge then
                    engineTurnedOn = true
                end
                --print("engineOn after     -> " .. tostring(engineTurnedOn))
            end
        end
        if not engineTurnedOn then
            --print("no active engine near player")
            doWashing = false
        end
    end

    return superFunc(self, doWashing, force, noEventSend)

end
