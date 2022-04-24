--
-- register
--
-- # Author: LS-Farmers.de
-- # date: 23.03.2022
--

if g_specializationManager:getSpecializationByName('washBeforeFill') == nil then
    g_specializationManager:addSpecialization('washBeforeFill', 'washBeforeFill', Utils.getFilename('washBeforeFill.lua', g_currentModDirectory),nil)
end

for vehicleTypeName, vehicleType in pairs(g_vehicleTypeManager.types) do
    if vehicleType ~= nil and SpecializationUtil.hasSpecialization(Washable, vehicleType.specializations) and SpecializationUtil.hasSpecialization(FillVolume, vehicleType.specializations) and SpecializationUtil.hasSpecialization(FillUnit, vehicleType.specializations) and not SpecializationUtil.hasSpecialization(Locomotive, vehicleType.specializations) then
        g_vehicleTypeManager:addSpecialization(vehicleTypeName, 'washBeforeFill')
		print ("  added washBeforeFill to " .. vehicleTypeName)
	else
		--print ("  skipped washBeforeFill for " .. vehicleTypeName)
    end

end

--Player.equipHandtool = Utils.overwrittenFunction(Player.equipHandtool, washBeforeFill.equipHandtool)
--HandTool.onActivate = Utils.overwrittenFunction(HandTool.onActivate, washBeforeFill.onActivate)
HighPressureWasherLance.setIsWashing = Utils.overwrittenFunction(HighPressureWasherLance.setIsWashing, washBeforeFill.setIsWashing)
ForageWagon.onStartWorkAreaProcessing = Utils.overwrittenFunction(ForageWagon.onStartWorkAreaProcessing, washBeforeFill.onStartWorkAreaProcessing)
ForageWagon.processForageWagonArea = Utils.overwrittenFunction(ForageWagon.processForageWagonArea, washBeforeFill.processForageWagonArea)
Baler.processBalerArea = Utils.overwrittenFunction(Baler.processBalerArea, washBeforeFill.processBalerArea)