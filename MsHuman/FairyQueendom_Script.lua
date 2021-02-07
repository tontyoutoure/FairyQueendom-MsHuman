-- LuaScript1
-- Author: LI Kun
-- DateCreated: 2021-2-4 7:51:29 PM
--------------------------------------------------------------

--init
local BuildingList = {}
local BuildingIndices = {}
local GrantedDessetList = {}

for BuildingInfo in GameInfo.Buildings() do
	BuildingList[BuildingInfo.Index] = BuildingInfo.BuildingType
	BuildingIndices[BuildingInfo.BuildingType] = BuildingInfo.Index
	print(BuildingInfo.BuildingType, BuildingInfo.Index)
end

function GetDessertHouseCount(playerID)
	local CityList = Players[playerID]:GetCities()
	local nDH = 0
	for iCity, hCity in CityList:Members() do
		buildings = hCity:GetBuildings()
		if buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_1) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_2) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_3) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_4) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_5) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_6) then
			nDH = nDH+1
		end
	end
	return nDH
end

-- replace with dessert house that actually gives deseert
function OnDessertHouseConstructed(playerID, cityID, buildingID, plotID, bOriginalConstruction)
	if buildingID == BuildingIndices.BUILDING_DESSERT_HOUSE then
		local nDessertHouseCount = GetDessertHouseCount(playerID)
		if nDessertHouseCount <= 6 then
			if not GrantedDessetList[nDessertHouseCount] then
				GrantedDessetList[nDessertHouseCount] = true
				local city = Players[playerID]:GetCities():FindID(cityID)
				city:GetBuildings():RemoveBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE)
				print(city:GetPlot(), plotID)
				city:GetBuildQueue():CreateBuilding(BuildingIndices["BUILDING_DESSERT_HOUSE_" .. tostring(nDessertHouseCount)])
				--city:GetBuildQueue():CreateBuilding(city, BuildingIndices["BUILDING_GODDESS_STATUE"], 100,city:GetPlot())
				print(city:GetBuildings():HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_1))
				--print(city:GetBuildings():HasBuilding(BuildingIndices.BUILDING_GODDESS_STATUE))
			end
		end
	end
end


GameEvents.BuildingConstructed.Add(OnDessertHouseConstructed)

print("FQ load finish")