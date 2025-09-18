SiqiBinaryList = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536} -- 全局二进制位列表

-- 输入一个数和位数n，输出n位的二进制数组
function Siqi_10to2(num, n)
    local result = {}
    for i = 1, n do
        local bitValue = (num % 2)
        table.insert(result, bitValue)
        num = math.floor(num / 2)
    end
    return result
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
end

