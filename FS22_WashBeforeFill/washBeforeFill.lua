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
end

function washBeforeFill.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "addLittleBit", washBeforeFill.addLittleBit)
end

function washBeforeFill:onLoadFinished(savegame)
  self.setNodeDirtAmount = Utils.appendedFunction(self.setNodeDirtAmount, washBeforeFill.appendToWash)

  if self.stopTipping ~= nil then
    --self.stopTipping = Utils.appendedFunction(self.stopTipping, washBeforeFill.appendStopTipping)
  end

  if self.handleDischargeOnEmpty ~= nil then
    self.handleDischargeOnEmpty = Utils.appendedFunction(self.handleDischargeOnEmpty, washBeforeFill.handleDischargeOnEmpty)
  end

  if self.getCanDischargeToObject ~= nil then
    self.getCanDischargeToObject = Utils.overwrittenFunction(self.getCanDischargeToObject, washBeforeFill.getCanDischargeToObject)
  end

  if self.getCanDischargeToGround ~= nil then
    self.getCanDischargeToGround = Utils.overwrittenFunction(self.getCanDischargeToGround, washBeforeFill.getCanDischargeToGround)
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