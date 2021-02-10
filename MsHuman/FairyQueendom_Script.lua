-- LuaScript1
-- Author: LI Kun
-- DateCreated: 2021-2-4 7:51:29 PM
--------------------------------------------------------------

--init


local BuildingList = {}
local BuildingIndices = {}
local GrantedDessetList = {}
local NotificationList = {}
local DessertList = {}
local LuxuriesList = {}
local tFQPlayers = {}
local fDessertAddProgress = 0.2
local fLuxuryAddProgress = 0.1
local fFairiesCountAddProgress = 0.02
local fStoredProgressMaximum = 1
local iFairiesID
local iDisableFairyID
local iEnableFairyID
local tBCList = {}
local iMaxXSize = 1000
local iTheatreID
local bInited = false
local nFairyBCKillDistance = 3
local nFairyUnhappyDamage = 30


function Initialize()
	for NotificationInfo in GameInfo.Notifications() do
		print(NotificationInfo.NotificationType, NotificationInfo.Index)
		NotificationList[NotificationInfo.NotificationType] = NotificationInfo.Index
	end
	for ProjectInfo in GameInfo.Projects() do
		if ProjectInfo.ProjectType == "PROJECT_DISABLE_GENERATE_FAIRY" then iDisableFairyID = ProjectInfo.Index end
		if ProjectInfo.ProjectType == "PROJECT_ENABLE_GENERATE_FAIRY" then iEnableFairyID = ProjectInfo.Index end
	end

	for UnitInfo in GameInfo.Units() do
		if UnitInfo.UnitType == 'UNIT_THE_FAIRIES' then
			iFairiesID = UnitInfo.Index
		end
	end

	for BuildingInfo in GameInfo.Buildings() do
		BuildingList[BuildingInfo.Index] = BuildingInfo.BuildingType
		BuildingIndices[BuildingInfo.BuildingType] = BuildingInfo.Index
	end


	for ResourceInfo in GameInfo.Resources() do
		if ResourceInfo.ResourceClassType == "RESOURCECLASS_LUXURY" then
			local t = ResourceInfo.ResourceType
			if string.find(t,'DESSERT') then
				DessertList[ResourceInfo.Index] = t
			else
				LuxuriesList[ResourceInfo.Index] = t
			end
		end
	end
	InitFairies()
	InitFairiesGeneration()

	Events.UnitRemovedFromMap.Add(OnUnitRemoved)
	GameEvents.PlayerTurnStarted.Add(TheFairiesCheck)
	GameEvents.BuildingConstructed.Add(BuildingConstructed)
	Events.CityProjectCompleted.Add(OnProjectFinished)
	Events.BuildingRemovedFromMap.Add(BuildingRemoved)
	print("FQ load finish")
end

function InitFairies()
	for i, v in ipairs(Players) do
		if PlayerConfigurations[i]:GetCivilizationTypeName() == "CIVILIZATION_FAIRY_QUEENDOM" then
			tFQPlayers[i] = {}
			tFQPlayers[i].tFairies = {}
			tFQPlayers[i].nFairies = 0
			tFQPlayers[i].fFairiesProgress = 0
			local PlayerUnitInfo = Players[i]:GetUnits()
			for _, u in PlayerUnitInfo:Members() do
				if u:GetType() == iFairiesID then
					tFQPlayers[i].nFairies = tFQPlayers[i].nFairies+1
					tFQPlayers[i].tFairies[u:GetID()] = true
				end
			end
		end
	end
end

function InitFairiesGeneration()
	for i, v in ipairs(Players) do
		local PlayerCityInfo = Players[i]:GetCities()
		if PlayerCityInfo then
			for _, hCity in PlayerCityInfo:Members() do
				local CityBuildingInfo = hCity:GetBuildings()
				if CityBuildingInfo:HasBuilding(BuildingIndices.BUILDING_BROADCAST_CENTER) then
					tBCList[CityBuildingInfo:GetBuildingLocation(BuildingIndices.BUILDING_BROADCAST_CENTER)] = true
				end
			end
		end
	end
end

function BuildingRemoved(iX, iY)
	--print("building removed at",iX,iY)
	tBCList[Map.GetPlot(iX,iY):GetIndex()] = nil
end

function GetDessertHouseCount(playerID)
	local CityList = Players[playerID]:GetCities()
	local nDH = 0
	for iCity, hCity in CityList:Members() do
		buildings = hCity:GetBuildings()
		if buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_ENABLED) or
			buildings:HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_DISABLED) or
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
function BuildingConstructed(playerID, cityID, buildingID, plotID, bOriginalConstruction)
	if buildingID == BuildingIndices.BUILDING_DESSERT_HOUSE then
		local nDessertHouseCount = GetDessertHouseCount(playerID)
		if nDessertHouseCount <= 6 then
			if not GrantedDessetList[nDessertHouseCount] then
				GrantedDessetList[nDessertHouseCount] = true
				local city = Players[playerID]:GetCities():FindID(cityID)
				city:GetBuildings():RemoveBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE)
				city:GetBuildQueue():CreateBuilding(BuildingIndices["BUILDING_DESSERT_HOUSE_" .. tostring(nDessertHouseCount)])
				city:GetBuildings():RemoveBuilding(BuildingIndices["BUILDING_DESSERT_HOUSE_" .. tostring(nDessertHouseCount)])
				city:GetBuildQueue():CreateBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_ENABLED)
			end
		end
	end
	
	if buildingID == BuildingIndices.BUILDING_BROADCAST_CENTER then
		tBCList[plotID] = true
	end
end



function TheFairiesCheck(iPlayer)
	if tFQPlayers[iPlayer] then
		-- generate fairy
		local fProgress1t = tFQPlayers[iPlayer].nFairies * fFairiesCountAddProgress
		local resouces = Players[iPlayer]:GetResources()
		for i, v in pairs(DessertList) do
			if resouces:HasResource(i) then
				fProgress1t = fProgress1t + fDessertAddProgress
			end
		end
		for i, v in pairs(LuxuriesList) do
			if resouces:HasResource(i) then
				fProgress1t = fProgress1t + fLuxuryAddProgress
			end
		end
		tFQPlayers[iPlayer].fFairiesProgress = tFQPlayers[iPlayer].fFairiesProgress + fProgress1t
		local tEnabledCities = {}
		local nEnabledCities = 0
		local cities = Players[iPlayer]:GetCities()
		for iCity, hCity in cities:Members() do
			if hCity:GetBuildings():HasBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_ENABLED) then
				table.insert(tEnabledCities, hCity:GetID())
				nEnabledCities = nEnabledCities+1
			end
		end

		local units = Players[iPlayer]:GetUnits()
		if nEnabledCities > 0 then
			while tFQPlayers[iPlayer].fFairiesProgress >= nEnabledCities do
				for i, v in ipairs(tEnabledCities) do
					local hCity = CityManager:GetCity(iPlayer, v)
					local hFairy = units:Create(iFairiesID, hCity:GetX(), hCity:GetY())
					tFQPlayers[iPlayer].tFairies[hFairy:GetID()] = true
				end
				tFQPlayers[iPlayer].fFairiesProgress = tFQPlayers[iPlayer].fFairiesProgress-nEnabledCities;
			end
		else
			if tFQPlayers[iPlayer].fFairiesProgress > fStoredProgressMaximum then tFQPlayers[iPlayer].fFairiesProgress = fStoredProgressMaximum end
		end
		print(tFQPlayers[iPlayer].fFairiesProgress)
		local tUnhappyCityPlots = {}
		for iCity, hCity in cities:Members() do
			if hCity:GetGrowth():GetAmenities()-math.ceil(hCity:GetPopulation()/2) < 0 then
				tUnhappyCityPlots[hCity:GetID()] = hCity:GetPlot():GetIndex()
			end
		end
		for iFairiesID, v in pairs(tFQPlayers[iPlayer].tFairies) do
			local fairy = units:FindID(iFairiesID)
			local location = fairy:GetLocation()
			local fairy_plot_id = Map.GetPlot(location.x, location.y):GetIndex()
			local bKilled = false
			for iBCPlot, _ in pairs(tBCList) do
				if Map.GetPlotDistance(iBCPlot,fairy_plot_id) <= nFairyBCKillDistance then
					UnitManager.Kill(fairy)
							NotificationManager.SendNotification(iPlayer, NotificationList.NOTIFICATION_FAIRY_DIE_RADIO, "LOC_NOTIFICATION_FAIRY_DIE_RADIO_MESSAGE", "LOC_NOTIFICATION_FAIRY_DIE_RADIO_SUMMARY", location.x, location.y)
					bKilled = true
					break
				end
			end
			if not bKilled then 
				for iCity, iCityPlot in pairs(tUnhappyCityPlots) do
					if Map.GetPlotDistance(iCityPlot,fairy_plot_id) <= nFairyBCKillDistance then
						local iDamage = fairy:GetDamage()
						if 100-iDamage <= nFairyUnhappyDamage then
							UnitManager.Kill(fairy)
							NotificationManager.SendNotification(iPlayer, NotificationList.NOTIFICATION_FAIRY_DIE_UNHAPPY, "LOC_NOTIFICATION_FAIRY_DIE_UNHAPPY_MESSAGE", "LOC_NOTIFICATION_FAIRY_DIE_UNHAPPY_SUMMARY", location.x, location.y)
							bKilled = true
						end
							fairy:SetDamage(iDamage + nFairyUnhappyDamage)
						break -- only damage once
					end
				end
			end
		end
	end
end





function OnUnitRemoved(iPlayer, iUnit)
	if tFQPlayers[iPlayer] and tFQPlayers[iPlayer].tFairies[iUnit] then
		tFQPlayers[iPlayer].tFairies[iUnit] = nil;
		tFQPlayers[iPlayer].nFairies = tFQPlayers[iPlayer].nFairies-1
		print("fairy removed")
	end
end

function OnProjectFinished(iPlayer, iCity, iProject, iBuildingID, iX, iY, bCancelled)
	if iProject == iDisableFairyID then 
		local hCity = CityManager:GetCity(iPlayer, iCity)
		hCity:GetBuildings():RemoveBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_ENABLED)
		hCity:GetBuildQueue():CreateBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_DISABLED)
	end
	if iProject == iEnableFairyID then 
		local hCity = CityManager:GetCity(iPlayer, iCity)
		hCity:GetBuildings():RemoveBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_DISABLED)
		hCity:GetBuildQueue():CreateBuilding(BuildingIndices.BUILDING_DESSERT_HOUSE_ENABLED)
	end
end


Initialize()