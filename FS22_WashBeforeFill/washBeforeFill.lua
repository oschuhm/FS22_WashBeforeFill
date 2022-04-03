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
  SpecializationUtil.registerEventListener(vehicleType, "onUpdate", washBeforeFill)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", washBeforeFill)
end

function washBeforeFill:onLoad(savegame)
  self.setNodeDirtAmount = Utils.appendedFunction(self.setNodeDirtAmount, washBeforeFill.appendToWash)

  if self.stopTipping ~= nil then
    self.stopTipping = Utils.appendedFunction(self.stopTipping, washBeforeFill.appendStopTipping)
  end

  if self.handleDischarge ~= nil then
    self.handleDischarge = Utils.appendedFunction(self.handleDischarge, washBeforeFill.shovelHandleDischarge)
  end

  if self.setWorkMode ~= nil then
    self.setWorkMode = Utils.appendedFunction(self.setWorkMode, washBeforeFill.setWorkMode)
  end

  self.lastDirtAmount = 0
end

function washBeforeFill:onUpdate(dt)
end

function washBeforeFill:shovelHandleDischarge(myObject)
    print("append shovelHandleDischarge")
end

function washBeforeFill:setWorkMode(myObject)
    print("append setWorkMode")
    print(" WorkMode: " .. self:getIsTurnedOn())
end

function washBeforeFill:appendStopTipping(myObject)
    print("appendStopTipping")

     if self:getFillUnits() ~= nil then

        for _, fillUnitTable in pairs(self:getFillUnits()) do
            if fillUnitTable.fillLevel <= 0 then
                print ("  we have to refill a little bit")
                self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitTable.fillUnitIndex, 0.001, fillUnitTable.lastValidFillType, ToolType.UNDEFINED, nil)
            else
                print ("  there is still something in the trailer, nothing to do")
            end
        end
     end

end

function washBeforeFill.appendToWash(dirtAmount)

     dirtAmount.isCoverOpen = true
     dirtAmount.fillTypesToIgnore = {
       [g_fillTypeManager:getFillTypeByName("DIESEL").index] = true,
       [g_fillTypeManager:getFillTypeByName("DEF").index] = true,
       [g_fillTypeManager:getFillTypeByName("AIR").index] = true
       }


     dirtAmount.currentDirtAmount = dirtAmount:getDirtAmount()

     if dirtAmount:getFillUnits() ~= nil and dirtAmount.currentDirtAmount <= dirtAmount.lastDirtAmount then
        --DebugUtil.printTableRecursively(dirtAmount.fillTypesToIgnore,'ignore .. ',1,2)
        for _, fillUnitTable in pairs(dirtAmount:getFillUnits()) do

            if dirtAmount.fillTypesToIgnore[fillUnitTable.fillType] == nil then

                -- read cover status
                if dirtAmount.spec_cover ~= nil then
                    if dirtAmount.spec_cover.hasCovers and dirtAmount.spec_cover.state == 0 then
                        dirtAmount.isCoverOpen = false
                    end
                end

                if fillUnitTable.fillLevel > 0 and dirtAmount.isCoverOpen then
                    print ("  cleaning process active")
                    dirtAmount:addFillUnitFillLevel(dirtAmount:getOwnerFarmId(), fillUnitTable.fillUnitIndex, -0.1, fillUnitTable.fillType, ToolType.UNDEFINED, nil)
                end

                if fillUnitTable.fillLevel <= 0 then
                    fillUnitTable.lastValidFillType = 1
                end
            end
        end
     end

     dirtAmount.lastDirtAmount = dirtAmount.currentDirtAmount

end