# 一个文明六mod的简单教程

UI代码的教程可以看 [Siqi的文明6mod教程](./Siqi的文明6mod教程.md)

能在GP端使用的一些常用函数可以看 [GP端的辅助函数文件](./GP_Support_Function.lua)

能在UI端使用的一些常用函数可以看 [UI端的辅助函数文件](./UI_Support_Function.lua)

部分函数是双端都能用的，不过我还是重复写了。

#### GP,UI双端可用：

###### 常量

```lua
-- 二进制函数会用到
local SiqiBinaryList = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536}
local GAME_SPEED = GameConfiguration.GetGameSpeedType()
local GAME_SPEED_MULTIPLIER = GameInfo.GameSpeeds[GAME_SPEED] and GameInfo.GameSpeeds[GAME_SPEED].CostMultiplier / 100 or 1 -- 获取游戏速度的倍率
```

###### 是否是目标文明

```lua
function IsCivilization(playerID, sCivilizationType)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return false; end
    if pPlayerConfig:GetCivilizationTypeName() == sCivilizationType then return true;
    else return false; end
end
```

###### 是否是目标领袖

```lua
function IsLeader(playerID, sleaderType)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return false; end
    if pPlayerConfig:GetLeaderTypeName() == sleaderType then return true;
    else return false; end
end
```

###### 是否拥有某个特性

```lua
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
```

###### 是否拥有某个属性（常用于Adjust Property）

```lua
function HasProperty(pOdject, sProperty)
    if not pOdject then return false; end
    local property = pOdject:GetProperty(sProperty)
    if not property then return false; end
    if type(property) ~= "number" then return false; end
    if property <= 0 then return false; end
    return true
end
```

###### 获取玩家文明类型

```lua
function GetPlayerCivilizationType(playerID)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return nil; end
    return pPlayerConfig:GetCivilizationTypeName()
end
```

###### 获取玩家领袖类型

```lua
function GetPlayerLeaderType(playerID)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return nil; end
    return pPlayerConfig:GetLeaderTypeName()
end
```

###### 对数值进行格式化（正数+，负数-，0显示0）

```lua
function FormatValue(value)
    if value == 0 then
        return Locale.ToNumber(value)
    else
        return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
    end
end
```

###### 获取Yield显示字符串（图标+名称）

```lua
function GetYieldString(YieldType)
    if not GameInfo.Yields[YieldType] then return ""; end
    return GameInfo.Yields[YieldType].IconString .. Locale.Lookup(GameInfo.Yields[YieldType].Name)
end
```

###### 红色文字

```lua
function Red(str)
    return "[COLOR_RED]" .. str .. "[ENDCOLOR]"
end
```

###### 绿色文字

```lua
function Green(str)
    return "[COLOR_GREEN]" .. str .. "[ENDCOLOR]"
end
```

###### 自定义RGBA颜色

```lua
function ColorRGB(str, color)
    local a, b, c, d = color.R, color.G, color.B, color.A or 255
    if not (a and b and c) then return str; end
    return "[COLOR:" .. a .. "," .. b .. "," .. c .. "," .. d .. "]" .. str .. "[ENDCOLOR]"
end
```

###### 数字转二进制表

```lua
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
```

###### 二进制表转数字

```lua
function TwoToNum(t)
    local num = 0
    for i = 1, #t do
        if t[i] == 1 then
            num = num + SiqiBinaryList[i]
        end
    end
    return num
end
```

###### 获取地块二进制属性数组

```lua
function GetPlotTwo(plotID, sproperty)
    local plot = Map.GetPlotByIndex(plotID)
    if not plot then return NumToTwo(0, #SiqiBinaryList); end
    local t = {}
    for i = 1, #SiqiBinaryList do
        table.insert(t, plot:GetProperty(sproperty .. SiqiBinaryList[i]) or 0)
    end
    return t
end
```

###### 获取地块数值属性

```lua
function GetPlotNum(plotID, sproperty)
    local t = GetPlotTwo(plotID, sproperty)
    return TwoToNum(t)
end
```

###### 获取已研发科技数量

```lua
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
```

###### 获取已研发市政数量

```lua
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
```

###### 获取科技进度比例

```lua
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
```

###### 获取市政进度比例

```lua
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
```

###### 玩家总进度修正值

```lua
function GetPlayerProgress(playerID)
    local techProgress = GetTechsProgress(playerID)
    local civicProgress = GetCultsProgress(playerID)
    local modifier = (1 + 9 * math.floor(math.max(techProgress, civicProgress) * 100) / 100)
    return modifier
end
```

###### 获取城市主流宗教

```lua
function GetCityReligion(playerID, cityID)
    local pCity = CityManager.GetCity(playerID, cityID)
    if not pCity then return nil; end
    return pCity:GetReligion():GetMajorityReligion()
end
```

###### 获取城市宜居度（GP版）

```lua
function GetCityAminity(playerID, cityID)
    local City = CityManager.GetCity(playerID, cityID)
    local CityGrowth = City:GetGrowth()
    local TotalAmenities = CityGrowth:GetAmenities()
    local Population = City:GetPopulation()
    local CITY_POP_PER_AMENITY = GameInfo.GlobalParameters['CITY_POP_PER_AMENITY'].Value
    local AmenitiesNeeded_FromPopulation = math.ceil(Population / CITY_POP_PER_AMENITY)
    local CITY_AMENITIES_FOR_FREE = GameInfo.GlobalParameters['CITY_AMENITIES_FOR_FREE'].Value
    local Count = TotalAmenities + CITY_AMENITIES_FOR_FREE - AmenitiesNeeded_FromPopulation
    return Count
end
```

###### 获取城市宜居度（UI版）

```lua
function GetCityAminity(playerID, cityID)
    local pCity = CityManager.GetCity(playerID, cityID)
    if not pCity then return 0; end
    local pCityGrowth = pCity:GetGrowth()
    return pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded()
end
```

#### 仅GP端可用：

###### 世界文本提示（通常用于产出变化）

```lua
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
```

###### 设置地块二进制属性数组

```lua
function SetPlotTwo(plotID, sproperty, t)
    local plot = Map.GetPlotByIndex(plotID)
    if not plot then return; end
    local oldt = GetPlotTwo(plotID, sproperty)
    for i = 1, #t do
        if t[i] ~= oldt[i] then
            plot:SetProperty(sproperty .. SiqiBinaryList[i], t[i])
        end
    end
end
```

###### 设置地块数值属性

```lua
function SetPlotNum(plotID, sproperty, num, n)
    local t = NumToTwo(num, n)
    SetPlotTwo(plotID, sproperty, t)
end
```

###### 修改地块数值属性（可支持负向缓存）

```lua
function ChangeplotNum(plotID, sproperty, amount, n, NEG, m)
    local num = GetPlotNum(plotID, sproperty)
    local Negnum = 0
    if NEG then Negnum = GetPlotNum(plotID, NEG .. sproperty); end
    local oldnum = num - Negnum
    if amount == 0 then return; end
    local newnum = oldnum + amount
    if newnum >= 0 then
        SetPlotNum(plotID, sproperty, newnum, n)
        if NEG then SetPlotNum(plotID, NEG .. sproperty, 0, m) end
    elseif NEG and newnum < 0 then
        SetPlotNum(plotID, sproperty, 0, n)
        SetPlotNum(plotID, NEG .. sproperty, -newnum, m)
    else
        SetPlotNum(plotID, sproperty, 0, n)
    end
end
```

###### 增加当前科技进度

```lua
function ChangeScience(playerID, amount)
    local pPlayer = Players[playerID]
    pPlayer:GetTechs():ChangeCurrentResearchProgress(amount)
end
```

###### 增加当前市政进度

```lua
function ChangeCulture(playerID, amount)
    local pPlayer = Players[playerID]
    pPlayer:GetCulture():ChangeCurrentCulturalProgress(amount)
end
```

###### 改变金币余额

```lua
function ChangeGold(playerID, amount)
    local pPlayer = Players[playerID]
    pPlayer:GetTreasury():ChangeGoldBalance(amount)
end
```

###### 改变信仰余额

```lua
function ChangeFaith(playerID, amount)
    local pPlayer = Players[playerID]
    pPlayer:GetReligion():ChangeFaithBalance(amount)
end
```

###### 改变生产力进度（全城或单城）

```lua
function ChangeProduction(playerID, amount, cityID)
    local player = Players[playerID]
    if not cityID then
        local pCities = player:GetCities()
        for _, pCity in pCities:Members() do
            pCity:GetBuildQueue():AddProgress(amount)
        end
        return
    end
    local pCity = CityManager.GetCity(playerID, cityID)
    if pCity then
        pCity:GetBuildQueue():AddProgress(amount)
    end
end
```

###### 直接完成生产（全城或单城）

```lua
function FinishProduction(playerID, cityID)
    local pPlayer = Players[playerID]
    if not cityID then
        local pCities = pPlayer:GetCities()
        for _, pCity in pCities:Members() do
            pCity:GetBuildQueue():FinishProgress()
        end
        return
    end
    local pCity = CityManager.GetCity(playerID, cityID)
    if pCity then
        pCity:GetBuildQueue():FinishProgress()
    end
end
```

###### 改变伟人点数

```lua
function ChangeGreatPeoplePoints(playerID, amount, class)
    local player = Players[playerID]
    local i = GameInfo.GreatPersonClasses[class].Index
    player:GetGreatPeoplePoints():ChangePointsTotal(i, amount)
end
```

###### 改变单位伤害（可设置不致死）

```lua
function ChangeUnitDamage(playerID, unitID, amount, NotKilled)
    local pUnit = UnitManager.GetUnit(playerID, unitID)
    if pUnit == nil then return; end
    local MaxDamage = pUnit:GetMaxDamage()
    local unitdamage = pUnit:GetDamage()
    if unitdamage + amount >= MaxDamage then
        if NotKilled then
            pUnit:SetDamage(MaxDamage - 1)
        else
            UnitManager.Kill(pUnit, true)
        end
    else
        pUnit:ChangeDamage(amount)
    end
end
```

###### 授予建筑（指定城市或首都）

```lua
function GrantBuilding(playerID, building, cityID)
    if not GameInfo.Buildings[building] then return; end
    if cityID then
        local pCity = CityManager.GetCity(playerID, cityID)
        if pCity and not pCity:GetBuildings():HasBuilding(GameInfo.Buildings[building].Index) then
            pCity:GetBuildQueue():CreateBuilding(GameInfo.Buildings[building].Index)
        end
    else
        local pPlayer = Players[playerID]
        local pCapitals = pPlayer:GetCities():GetCapitalCity()
        if pCapitals and not pCapitals:GetBuildings():HasBuilding(GameInfo.Buildings[building].Index) then
            pCapitals:GetBuildQueue():CreateBuilding(GameInfo.Buildings[building].Index)
        end
    end
end
```

###### 移除建筑（指定城市或首都）

```lua
function RemoveBuilding(playerID, building, cityID)
    if not GameInfo.Buildings[building] then return; end
    if cityID then
        local pCity = CityManager.GetCity(playerID, cityID)
        if pCity and pCity:GetBuildings():HasBuilding(GameInfo.Buildings[building].Index) then
            pCity:GetBuildings():RemoveBuilding(GameInfo.Buildings[building].Index)
        end
    else
        local pPlayer = Players[playerID]
        local pCapitals = pPlayer:GetCities():GetCapitalCity()
        if pCapitals and pCapitals:GetBuildings():HasBuilding(GameInfo.Buildings[building].Index) then
            pCapitals:GetBuildings():RemoveBuilding(GameInfo.Buildings[building].Index)
        end
    end
end
```

###### 对城市造成伤害（先城墙后本体）

```lua
function ChangeCityDamage(playerID, cityID, amount)
    local pCity = CityManager.GetCity(playerID, cityID)
    if pCity then
        ChangeDistrictDamage(playerID, pCity:GetX(), pCity:GetY(), amount)
    end
end
```

###### 对区域造成伤害（先城墙后本体）

```lua
function ChangeDistrictDamage(playerID, iX, iY, amount)
    local pDistrict = CityManager.GetDistrictAt(iX, iY)
    if pDistrict then
        local wallHitpoints = pDistrict:GetMaxDamage(DefenseTypes.DISTRICT_OUTER)
        local currentWallDamage = pDistrict:GetDamage(DefenseTypes.DISTRICT_OUTER)
        if currentWallDamage < wallHitpoints then
            pDistrict:ChangeDamage(DefenseTypes.DISTRICT_OUTER, amount)
        else
            pDistrict:ChangeDamage(DefenseTypes.DISTRICT_GARRISON, amount)
        end
    end
end
```

###### 判断地块能否放置单位

```lua
function Siqi_CanHaveUnit(plotIndex)
    local pPlot = Map.GetPlotByIndex(plotIndex)
    if pPlot:IsImpassable() then return false end
    if pPlot:IsMountain() then return false end
    if pPlot:IsUnit() then return false end
    if pPlot:IsCity() then return false end
    if pPlot:IsWater() then return false end
    local iDistrict = pPlot:GetDistrictType()
    if iDistrict ~= -1 and GameInfo.Districts[iDistrict].HitPoints > 0 then return false end
    return true
end
```

###### 三环内放置单位

```lua
function Siqi_InitUnit(iX, iY, unitType, playerID)
    local pPlot = Map.GetPlot(iX, iY)
    if Siqi_CanHaveUnit(pPlot:GetIndex()) then
        UnitManager.InitUnit(playerID, unitType, iX, iY)
        return iX, iY
    end
    local kplot = Map.GetNeighborPlots(iX, iY, 3)
    for _, plot in ipairs(kplot) do
        if Siqi_CanHaveUnit(plot:GetIndex()) then
            UnitManager.InitUnit(playerID, unitType, plot:GetX(), plot:GetY())
            return plot:GetX(), plot:GetY()
        end
    end
    return false
end
```

#### 仅UI端可用：

###### 获取城市电力差值

```lua
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
```

###### 获取城市可用区域位

```lua
function GetCityDistrictsSlot(playerID, cityID)
    local pCity = CityManager.GetCity(playerID, cityID)
    if not pCity then return 0; end
    local pCityDistricts = pCity:GetDistricts()
    return pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()
end
```

###### 获取城市剩余区域位

```lua
function GetCityDistrictsSlotLeft(playerID, cityID)
    local pCity = CityManager.GetCity(playerID, cityID)
    if not pCity then return 0; end
    local pCityDistricts = pCity:GetDistricts()
    local districtsPossibleNum = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()
    local districtsNum = pCityDistricts:GetNumZonedDistrictsRequiringPopulation()
    return districtsPossibleNum - districtsNum
end
```

###### 城市是否被围城

```lua
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
```

###### 获取城市宗教信徒总数（不含泛神论）

```lua
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
```

###### 获取城市中玩家宗教信徒数

```lua
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
```

###### 获取城市商路数量

```lua
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
```

###### 获取城市通往国外商路数量

```lua
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
```

###### 获取生产任务造价

```lua
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
```

###### 获取城市当前生产进度信息

```lua
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
```

###### 获取城市当前总督（无则nil）

```lua
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
```

###### 获取总督所在城市（无则nil）

```lua
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
```
