-- 本文件的辅助函数允许在UI端使用

-- 共用常量
local SiqiBinaryList = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536}


-- 是否是目标文明
function IsCivilization(playerID, sCivilizationType)
	local pPlayerConfig = PlayerConfigurations[playerID]
	if pPlayerConfig == nil then return false; end
	if pPlayerConfig:GetCivilizationTypeName() == sCivilizationType then return true;
	else return false; end
end

-- 是否是目标领袖
function IsLeader(playerID, sleaderType)
	local pPlayerConfig = PlayerConfigurations[playerID]
	if pPlayerConfig == nil then return false; end
	if pPlayerConfig:GetLeaderTypeName() == sleaderType then return true;
	else return false; end
end

-- 是否拥有某个特性
function HasTrait(playerID, sTrait)
	if playerID == nil or sTrait == nil then return false; end
	local playerConfig = PlayerConfigurations[playerID]
	if playerConfig == nil then return false; end
	local sCiv = playerConfig:GetCivilizationTypeName()
	local sLea = playerConfig:GetLeaderTypeName()
	for tRow in GameInfo.CivilizationTraits() do
		if (tRow.CivilizationType == sCiv and tRow.TraitType == sTrait) then return true; end
	end
	for tRow in GameInfo.LeaderTraits() do
		if (tRow.LeaderType == sLea and tRow.TraitType == sTrait) then return true; end
	end
	return false;
end

-- 是否拥有某个属性，通常用于Adjust Property的情况
function HasProperty(pOdject, sProperty)
	if not pOdject then return false; end
	local property = pOdject:GetProperty(sProperty)
	if not property then return false; end
	if type(property) ~= "number" then return false; end
	if property <= 0 then return false; end
	return true
end

-- 获取玩家文明类型
function GetPlayerCivilizationType(playerID)
	local pPlayerConfig = PlayerConfigurations[playerID]
	if pPlayerConfig == nil then return nil; end
	return pPlayerConfig:GetCivilizationTypeName()
end

-- 获取玩家领袖类型
function GetPlayerLeaderType(playerID)
	local pPlayerConfig = PlayerConfigurations[playerID]
	if pPlayerConfig == nil then return nil; end
	return pPlayerConfig:GetLeaderTypeName()
end

-- 对数值进行格式化，正数显示+，负数显示-，0显示0
function FormatValue(value)
	if value == 0 then
		return Locale.ToNumber(value)
	else
		return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
	end
end

-- 获取Yield的显示字符串，包含图标和名称
function GetYieldString(YieldType)
	if not GameInfo.Yields[YieldType] then return ""; end
	return GameInfo.Yields[YieldType].IconString .. Locale.Lookup(GameInfo.Yields[YieldType].Name)
end

-- 令字符串变色，红色通常表示负面，绿色通常表示正面，ColorRGB可以自定义颜色
function Red(str)
	return "[COLOR_RED]" .. str .. "[ENDCOLOR]"
end

function Green(str)
	return "[COLOR_GREEN]" .. str .. "[ENDCOLOR]"
end

function ColorRGB(str, color)
	local a, b, c, d = color.R, color.G, color.B, color.A or 255
	if not (a and b and c) then return str; end
	return "[COLOR:" .. a .. "," .. b .. "," .. c .. "," .. d .. "]" .. str .. "[ENDCOLOR]"
end

-- 在世界上显示一个文本，通常用于提示玩家获得了什么产出奖励
-- 调用了函数 GetYieldString FormatValue
function AddYieldStringToWorld(Amount, YieldType, iX, iY)
	for row in GameInfo.Yields() do
		if row.YieldType == YieldType then
			local str = GetYieldString(YieldType)
			str = FormatValue(Amount) .. str
			Game.AddWorldViewText(0, str, iX, iY)
			break
		end
	end
end

-- 二进制相关
function NumToTwo(num, n)
	local t = {}
	for i = n, 1, -1 do
		if num >= SiqiBinaryList[i] then
			table.insert(t, 1)
			num = num - SiqiBinaryList[i]
		else
			table.insert(t, 0)
		end
	end
	local tt = {}
	for i = #t, 1, -1 do
		table.insert(tt, t[i])
	end
	return tt
end

function TwoToNum(t)
	local num = 0
	for i = 1, #t do
		if t[i] == 1 then
			num = num + SiqiBinaryList[i]
		end
	end
	return num
end

function GetPlotTwo(plotID, sproperty)
	local plot = Map.GetPlotByIndex(plotID)
	if not plot then return NumToTwo(0, #SiqiBinaryList); end
	local t = {}
	for i = 1, #SiqiBinaryList do
		table.insert(t, plot:GetProperty(sproperty .. SiqiBinaryList[i]) or 0)
	end
	return t
end

function GetPlotNum(plotID, sproperty)
	local t = GetPlotTwo(plotID, sproperty)
	return TwoToNum(t)
end

function GetTechsNum(playerID)
	local pPlayer = Players[playerID]
	if not pPlayer then return 0; end
	local pPlayerTechs = pPlayer:GetTechs()
	local count = 0
	for row in GameInfo.Technologies() do
		if pPlayerTechs:HasTech(row.Index) then
			count = count + 1
		end
	end
	return count
end

function GetCultsNum(playerID)
	local pPlayer = Players[playerID]
	if not pPlayer then return 0; end
	local pPlayerCults = pPlayer:GetCulture()
	local count = 0
	for row in GameInfo.Civics() do
		if pPlayerCults:HasCivic(row.Index) then
			count = count + 1
		end
	end
	return count
end

function GetTechsProgress(playerID)
	local pPlayer = Players[playerID]
	if not pPlayer then return 0; end
	local pPlayerTechs = pPlayer:GetTechs()
	local total = 0
	local current = 0
	for row in GameInfo.Technologies() do
		total = total + 1
		if pPlayerTechs:HasTech(row.Index) then
			current = current + 1
		end
	end
	return current / total
end

function GetCultsProgress(playerID)
	local pPlayer = Players[playerID]
	if not pPlayer then return 0; end
	local pPlayerCults = pPlayer:GetCulture()
	local total = 0
	local current = 0
	for row in GameInfo.Civics() do
		total = total + 1
		if pPlayerCults:HasCivic(row.Index) then
			current = current + 1
		end
	end
	return current / total
end

function GetPlayerProgress(playerID)
	local techProgress = GetTechsProgress(playerID)
	local civicProgress = GetCultsProgress(playerID)
	local modifier = (1 + 9 * math.floor(math.max(techProgress, civicProgress) * 100) / 100)
	return modifier
end

-- 城市宜居度
function GetCityAminity(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end
	local pCityGrowth = pCity:GetGrowth()
	return pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded()
end

-- 城市电力
function GetCityPower(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end
	local pCityPower = pCity:GetPower()
	if pCityPower == nil then return 0 end

	local requiredPower = pCityPower:GetRequiredPower()
	if pCityPower:IsFullyPoweredByActiveProject() then
		return requiredPower
	end

	local freePower = pCityPower:GetFreePower()
	local temporaryPower = pCityPower:GetTemporaryPower()
	local currentPower = freePower + temporaryPower
	return currentPower - requiredPower
end

-- 城市可用区域位
function GetCityDistrictsSlot(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end
	local pCityDistricts = pCity:GetDistricts()
	return pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()
end

-- 城市剩余区域位
function GetCityDistrictsSlotLeft(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end
	local pCityDistricts = pCity:GetDistricts()
	local districtsPossibleNum = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()
	local districtsNum = pCityDistricts:GetNumZonedDistrictsRequiringPopulation()
	return districtsPossibleNum - districtsNum
end

-- 城市是否被围城
function IsCityBesieged(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	local pPlayer = Players[playerID]
	if not pCity or not pPlayer then return false; end
	local pDistrict = pPlayer:GetDistricts():FindID(pCity:GetDistrictID())
	if pDistrict then
		return pDistrict:IsUnderSiege()
	end
	return false
end

-- 获取城市主流宗教
function GetCityReligion(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return nil; end
	return pCity:GetReligion():GetMajorityReligion()
end

-- 获取城市宗教信徒总数（不含泛神论）
function GetCityFollows(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end

	local pReligions = pCity:GetReligion():GetReligionsInCity()
	local followersAll = 0
	for _, religionData in pairs(pReligions) do
		local religionType = (religionData.Religion > 0) and GameInfo.Religions[religionData.Religion].ReligionType or "RELIGION_PANTHEON"
		if religionType ~= "RELIGION_PANTHEON" then
			followersAll = followersAll + religionData.Followers
		end
	end
	return followersAll
end

-- 获取城市信仰玩家宗教的信徒数
function GetCityPlayerFollows(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end

	local pPlayer = Players[playerID]
	if not pPlayer then return 0; end

	local iReligionType = -1
	local pReligion = pPlayer:GetReligion()
	if pReligion then
		iReligionType = pReligion:GetReligionTypeCreated()
	end

	local cityReligion = pCity:GetReligion()
	if not cityReligion then return 0; end

	local count = 0
	if iReligionType ~= -1 then
		count = cityReligion:GetNumFollowers(iReligionType)
	end
	return count
end

-- 获取城市商路数量
function GetCityTradeRoutesNum(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end

	local pCityTrade = pCity:GetTrade()
	if not pCityTrade then return 0; end

	local outgoingRoutes = pCityTrade:GetOutgoingRoutes()
	local num = 0
	for _, _ in ipairs(outgoingRoutes) do
		num = num + 1
	end
	return num
end

-- 获取城市通往国外商路数量
function GetCityForeignTradeRoutesNum(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end

	local pCityTrade = pCity:GetTrade()
	if not pCityTrade then return 0; end

	local outgoingRoutes = pCityTrade:GetOutgoingRoutes()
	local num = 0
	for _, route in ipairs(outgoingRoutes) do
		local destplayerID = route.DestinationCityPlayer
		if destplayerID ~= playerID then
			num = num + 1
		end
	end
	return num
end

-- 获取某种生产任务的造价
function GetProductionCost(playerID, cityID, iConstructionType, itemID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return 0; end

	local cityBuildQueue = pCity:GetBuildQueue()
	local cost = 0
	if iConstructionType == 0 then
		cost = cityBuildQueue:GetUnitCost(itemID) or GameInfo.Units[itemID].Cost
	elseif iConstructionType == 1 then
		cost = cityBuildQueue:GetBuildingCost(itemID) or GameInfo.Buildings[itemID].Cost
	elseif iConstructionType == 2 then
		cost = cityBuildQueue:GetDistrictCost(itemID) or GameInfo.Districts[itemID].Cost
	elseif iConstructionType == 3 then
		cost = cityBuildQueue:GetProjectCost(itemID) or GameInfo.Projects[itemID].Cost
	end
	return cost
end

-- 获取城市正在建造的任务进度
function GetCityProductionProgress(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then
		return { Cost = 0, Progress = 0, ProductionType = 'NONE', Name = '', Hash = -1, Percent = -1 }
	end

	local cityBuildQueue = pCity:GetBuildQueue()
	local currentProductionHash = cityBuildQueue:GetCurrentProductionTypeHash()
	local data = {}

	if currentProductionHash == 0 then
		data.Cost = 0
		data.Progress = 0
		data.ProductionType = 'NONE'
		data.Name = ''
		data.Hash = -1
		data.Percent = -1
	elseif GameInfo.Buildings[currentProductionHash] then
		local buildingID = GameInfo.Buildings[currentProductionHash].Index
		data.Cost = cityBuildQueue:GetBuildingCost(buildingID)
		data.Progress = cityBuildQueue:GetBuildingProgress(buildingID)
		data.ProductionType = 'BUILDING'
		data.Name = GameInfo.Buildings[buildingID].Name
		data.Hash = currentProductionHash
		data.Percent = math.floor(100 * data.Progress / data.Cost)
	elseif GameInfo.Units[currentProductionHash] then
		local unitDef = GameInfo.Units[currentProductionHash]
		local unitID = unitDef.Index
		local eMilitaryFormationType = cityBuildQueue:GetCurrentProductionTypeModifier()

		if eMilitaryFormationType == MilitaryFormationTypes.STANDARD_FORMATION then
			data.Cost = cityBuildQueue:GetUnitCost(unitID)
			data.Progress = cityBuildQueue:GetUnitProgress(unitID)
			data.ProductionType = 'UNIT'
			data.Name = unitDef.Name
			data.Hash = currentProductionHash
			data.Percent = math.floor(100 * data.Progress / data.Cost)
		elseif eMilitaryFormationType == MilitaryFormationTypes.CORPS_FORMATION then
			data.Cost = cityBuildQueue:GetUnitCorpsCost(unitID)
			data.Progress = cityBuildQueue:GetUnitProgress(unitID)
			data.ProductionType = 'UNIT'
			if unitDef.Domain == "DOMAIN_SEA" then
				data.Name = unitDef.Name .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
			else
				data.Name = unitDef.Name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
			end
			data.Hash = currentProductionHash
			data.Percent = math.floor(100 * data.Progress / data.Cost)
		elseif eMilitaryFormationType == MilitaryFormationTypes.ARMY_FORMATION then
			data.Cost = cityBuildQueue:GetUnitArmyCost(unitID)
			data.Progress = cityBuildQueue:GetUnitProgress(unitID)
			data.ProductionType = 'UNIT'
			if unitDef.Domain == "DOMAIN_SEA" then
				data.Name = unitDef.Name .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
			else
				data.Name = unitDef.Name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
			end
			data.Hash = currentProductionHash
			data.Percent = math.floor(100 * data.Progress / data.Cost)
		end
	elseif GameInfo.Projects[currentProductionHash] then
		local projectID = GameInfo.Projects[currentProductionHash].Index
		data.Cost = cityBuildQueue:GetProjectCost(projectID)
		data.Progress = cityBuildQueue:GetProjectProgress(projectID)
		data.ProductionType = 'PROJECT'
		data.Hash = currentProductionHash
		data.Name = GameInfo.Projects[projectID].Name
		data.Percent = math.floor(100 * data.Progress / data.Cost)
	elseif GameInfo.Districts[currentProductionHash] then
		local districtID = GameInfo.Districts[currentProductionHash].Index
		data.Cost = cityBuildQueue:GetDistrictCost(districtID)
		data.Progress = cityBuildQueue:GetDistrictProgress(districtID)
		data.ProductionType = 'DISTRICT'
		data.Name = GameInfo.Districts[districtID].Name
		data.Hash = currentProductionHash
		data.Percent = math.floor(100 * data.Progress / data.Cost)
	end

	if not data.Cost then data.Cost = 0; end
	if not data.Progress then data.Progress = 0; end
	if not data.Percent then data.Percent = -1; end
	if not data.Name then data.Name = ''; end
	if not data.Hash then data.Hash = -1; end
	if not data.ProductionType then data.ProductionType = 'NONE'; end
	return data
end

-- 获取城市当前总督，没有就返回nil
function GetCityGovernor(playerID, cityID)
	local pCity = CityManager.GetCity(playerID, cityID)
	if not pCity then return nil; end
	local pPlayerGovernors = pPlayer:GetGovernors();
	local pCurrentGovernor = pPlayerGovernors and pPlayerGovernors:GetAssignedGovernor(pCity) or nil;
	if pCurrentGovernor then
		local pCurrentGovernorDef = GameInfo.Governors[pCurrentGovernor:GetType()];
		return pCurrentGovernorDef and pCurrentGovernorDef.GovernorType or nil;
	end
	return nil;
end

-- 获取总督所在城市，没有就返回nil，有就返回城市对象
function GetGovernorCity(playerID, governorType)
	local pPlayer = Players[playerID]
	if not pPlayer then return nil; end
	local pPlayerGovernors = pPlayer:GetGovernors();
	local bHasGovernors, tGovernorList = pPlayerGovernors:GetGovernorList();
    for i,governor in ipairs(tGovernorList) do
        local igovernorType = governor:GetType();
        local governorDef = GameInfo.Governors[igovernorType];
        if governorDef.GovernorType == governorType then
            local pCity = governor:GetAssignedCity();
			if pCity then
				return pCity;
			end
		end
	end
	return nil;
end

-- 总督是否拥有某晋升
function GovernorHasPromotion(playerID, governorType, promotionType)
	local pPlayer = Players[playerID]
	if not pPlayer then return false; end
	local pPlayerGovernors = pPlayer:GetGovernors();
	local bHasGovernors, tGovernorList = pPlayerGovernors:GetGovernorList();
	for i,governor in ipairs(tGovernorList) do
		local igovernorType = governor:GetType();
		local governorDef = GameInfo.Governors[igovernorType];
		if governorDef.GovernorType == governorType then
			local PromotionDef = GameInfo.GovernorPromotions[promotionType];
			if not PromotionDef then return false; end
			return governor:HasPromotion(PromotionDef.Hash);
		end
	end
	return false;
end
