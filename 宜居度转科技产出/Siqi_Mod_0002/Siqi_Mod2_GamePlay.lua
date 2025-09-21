SiqiBinaryList = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536} -- 全局二进制位列表

-- 输入一个数和位数n，输出n位的二进制数组
function Siqi_10to2(num, n)
    local result = {}
    for i = n, 1, -1 do
        if num >= SiqiBinaryList[i] then
            table.insert(result, 1)
            num = num - SiqiBinaryList[i]
        else
            table.insert(result, 0)
        end
    end
    local list = {}
    for i = 1, #result do
        list[i] = result[#result - i + 1]
    end
    return list
end

-- 输入一个二进制数组，输出对应的数
function Siqi_2to10(binaryArray)
    local result = 0
    for i, bitValue in ipairs(binaryArray) do
        result = result + bitValue * SiqiBinaryList[i]
    end
    return result
end

-- 获取单元格的property值
function Siqi_GetPlotProperty(plotIndex, sProperty)
    local pPlot = Map.GetPlotByIndex(plotIndex)
    local property = {}
    for i = 1, #SiqiBinaryList do
        table.insert(property, pPlot:GetProperty(sProperty .. SiqiBinaryList[i]) or 0)
    end
    return property
end

-- 设置单元格的property值 UI端无法使用
function Siqi_SetPlotProperty(plotIndex, newproperty, sProperty)
    local pPlot = Map.GetPlotByIndex(plotIndex)
    local oldproperty = Siqi_GetPlotProperty(plotIndex, sProperty) -- 获取当前单元格的属性值
    for i = 1, #newproperty do
        if newproperty[i] and newproperty[i] ~= oldproperty[i] then
            pPlot:SetProperty(sProperty .. SiqiBinaryList[i], newproperty[i])
        end
    end
end

-- 来自马良的计算城市宜居度，爱来自马良
function Ruivo_FROM_CITY_SURPLUS_AMENITIES(City)
    local CityGrowth = City:GetGrowth();
    local TotalAmenities = CityGrowth:GetAmenities();
    --print("本城总宜居度：", TotalAmenities);
    local Population = City:GetPopulation();
    local CITY_POP_PER_AMENITY = GameInfo.GlobalParameters['CITY_POP_PER_AMENITY'].Value
    --print("消耗1个宜居度的人口数：", CITY_POP_PER_AMENITY)
    local AmenitiesNeeded_FromPopulation = math.ceil(Population / CITY_POP_PER_AMENITY);--向上取整，1个人口也消耗1宜居，2个也消耗1宜居
    --print("人口消耗宜居度（向上取整）：", AmenitiesNeeded_FromPopulation);
    local CITY_AMENITIES_FOR_FREE = GameInfo.GlobalParameters['CITY_AMENITIES_FOR_FREE'].Value
    local Count = TotalAmenities + CITY_AMENITIES_FOR_FREE - AmenitiesNeeded_FromPopulation;
    --print("溢出宜居度：", Count);
    --print("-==============================")
    return Count;
end

function Refresh(playerID,CityID)
    local pCity = CityManager.GetCity(playerId, CityID);  --获取城市
    if pCity == nil then return; end   --如果城市不存在，则不执行
    local Amenities = Ruivo_FROM_CITY_SURPLUS_AMENITIES(pCity);  --获取城市的宜居度
    local Amount_10 = 2*Amenities

    local pPlot = Map.GetPlot(pCity:GetX(), pCity:GetY());
    local OldAmount_2 = Siqi_GetPlotProperty(pPlot:GetIndex(), "REQ_SIQI_MOD2_PROPERTY_")  --获取原有的科技值
    local OldAmount_10 = Siqi_2to10(OldAmount_2)  --转换为十进制

    local NewAmount_2 = Siqi_10to2(Amount_10 , 7)

    Siqi_SetPlotProperty(pPlot:GetIndex(), NewAmount_2 , 'REQ_SIQI_MOD2_PROPERTY_')
end



-- ========================================刷新函数========================================================
-- 玩家回合结束时，遍历所有城市刷新宜居度
function SiqiOnPlayerTurnDeactivatedRe(playerID)
    local pPlayer = Players[playerID];  --获取玩家
    for i, pCity in pPlayer:GetCities():Members() do -- 遍历玩家城市
        local CityID = pCity:GetID();  --获取城市ID
        Refresh(playerID, CityID);  --设置城市的宜居度properties
    end
end

-- 城市完成生产时，该城市刷新宜居度
function SiqiOnCityProductionCompletedRe(playerID, cityID, orderType, unitType, canceled, typeModifier)
    Refresh(playerID, cityID);  --设置城市的宜居度properties
end

-- 城市公民改变时，该城市刷新宜居度
function SiqiOnCityWorkerChangedRe(playerID, cityID, iX, iY)
    Refresh(playerID, cityID);  --设置城市的宜居度properties
end

-- 玩家伟人激活时，所有城市刷新宜居度
function SiqiOnUnitGreatPersonActivatedRe(unitOwner, unitID, greatPersonClassID, greatPersonIndividualID)
    SiqiOnPlayerTurnDeactivatedRe(unitOwner);  --调用玩家回合结束时的函数，刷新宜居度 
end

-- 添加改良时，城市刷新宜居度
function OnImprovementAddedToMap(iX, iY, eImprovement, playerID)
    local pPlot = Map.GetPlot(iX, iY);
    local pCity = Cities.GetPlotPurchaseCity(pPlot);
    if not pCity then return; end
    local cityID = pCity:GetID();
    Refresh(playerID, cityID);  --设置城市的宜居度properties
end

-- 移除改良时，城市刷新宜居度，这里直接调用添加改良的函数
function OnImprovementRemovedFromMap( locX :number, locY :number, eOwner :number )
    OnImprovementAddedToMap(locX, locY, -1, eOwner);
end

-- 城市建成时，刷新城市宜居度
function SiqiOnCityBuiltRe(playerID, cityID, cityX , cityY)
    Refresh(playerID, cityID);  --设置城市的宜居度properties
end



function Initialize()
    --===============宜居度刷新事件===================================
    Events.PlayerTurnDeactivated.Add(SiqiOnPlayerTurnDeactivatedRe)              --玩家回合结束时
    Events.CityProductionCompleted.Add(SiqiOnCityProductionCompletedRe)          --城市生产完成时
    Events.CityWorkerChanged.Add(SiqiOnCityWorkerChangedRe)                      --城市公民改变时
    Events.UnitGreatPersonActivated.Add(SiqiOnUnitGreatPersonActivatedRe)        --伟人激活时
    Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap )                  --地图上添加改良时
    Events.ImprovementRemovedFromMap.Add( OnImprovementRemovedFromMap )          --地图上移除改良时
    GameEvents.CityBuilt.Add(SiqiOnCityBuiltRe)                                  --城市建造时
    --===============================================================
end


Events.LoadGameViewStateDone.Add(Initialize)