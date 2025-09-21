
include("CityPanel");

local BASE_ViewMain = ViewMain

local SiqiBinaryList = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536} -- 全局二进制位列表

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

function Siqi_GetCityScienceFromAmenity(pCity)
    if not pCity then return 0; end
    local pPlot = Map.GetPlot(pCity:GetX(), pCity:GetY());
    local property = Siqi_GetPlotProperty(pPlot:GetIndex(), "REQ_SIQI_MOD2_PROPERTY_")
    return Siqi_2to10(property)
end

local FROM_MODIFIER = Locale.Lookup("LOC_SIQI_UI_FROM_MODIFIERS_TEXT")
local FROM_MODIFIER_MATCH = "%+(%d+)%" .. FROM_MODIFIER

-- 提取字符串中修正值的部分
function GetModifierValue(originalString)
    return tonumber(string.match(originalString, FROM_MODIFIER_MATCH))
end

function SetModifierValue(originalString, newValue)
    if newValue == 0 then
        local s = string.gsub(originalString, "%s*%+%d+%" .. FROM_MODIFIER, "") or originalString
        return string.gsub(s, "^%[NEWLINE%]", "") or s
    end
    if newValue < 0 then
        return string.gsub(originalString, FROM_MODIFIER_MATCH, newValue..FROM_MODIFIER) or originalString
    end
    return string.gsub(originalString, FROM_MODIFIER_MATCH, "+"..newValue..FROM_MODIFIER) or originalString
end

function ViewMain( data:table)
    local pCity = UI.GetHeadSelectedCity() -- 获取当前选中的城市
    local Amount = Siqi_GetCityScienceFromAmenity(pCity); -- 获取城市宜居度转化的科技值
    if Amount > 0 then
        local originalSciencePerTurn = GetModifierValue(data.SciencePerTurnToolTip) or 0; -- 提取原有修正值
        local newSciencePerTurn = originalSciencePerTurn - Amount; -- 计算新的修正值
        data.SciencePerTurnToolTip = SetModifierValue(data.SciencePerTurnToolTip, newSciencePerTurn); -- 设置新的修正值
        data.SciencePerTurnToolTip = data.SciencePerTurnToolTip .. "[NEWLINE]" .. Locale.Lookup("LOC_SIQI_UI_FROM_AMENITY_TO_SCIENCE", Amount); -- 添加新的文本
    end
    BASE_ViewMain(data); -- 调用原始的ViewMain函数
end






