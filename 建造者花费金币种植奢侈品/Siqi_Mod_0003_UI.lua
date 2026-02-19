
include('InstanceManager')

local m_SiqiTeachIM = InstanceManager:new("SiqiTeachInstance", "Top", Controls.SiqiTeachButtonStack)
local SiqiResource = {}

function SiqiResource:new(RecourceType)
    local info = GameInfo.Resources[RecourceType]
    local t = {}
    setmetatable(t, self)
    self.__index = self
    t.RecourceType = info.ResourceType
    t.Index = info.Index
    t.Hash = info.Hash
    t.Name = info.Name
    t.ResourceClassType = info.ResourceClassType
    t.IconString = "[ICON_"..info.ResourceType.."]"
    t.ValidFeatures = SiqiResource:GetValidFeatures(info.ResourceType) -- 可用地貌
    t.ValidTerrains = SiqiResource:GetValidTerrains(info.ResourceType) -- 可用地形
    t.Improvements = SiqiResource:GetImprovements(info.ResourceType) -- 可用改良
    t.Yields = SiqiResource:GetYields(info.ResourceType) -- 资源产出
    return t
end

function SiqiResource:GetValidFeatures(r)
    local Features = {}
    for row in GameInfo.Resource_ValidFeatures() do
        if row.ResourceType == r then
            Features[row.FeatureType] = true
        end
    end
    return Features
end

function SiqiResource:GetValidTerrains(r)
    local Terrains = {}
    for row in GameInfo.Resource_ValidTerrains() do
        if row.ResourceType == r then
            Terrains[row.TerrainType] = true
        end
    end
    return Terrains
end

function SiqiResource:GetImprovements(r)
    local Improvements = {}
    for row in GameInfo.Improvement_ValidResources() do
        if row.ResourceType == r then
            Improvements[row.ImprovementType] = true
        end
    end
    return Improvements
end

function SiqiResource:GetYields(r)
    local Yields = {}
    for row in GameInfo.Resource_YieldChanges() do
        if row.ResourceType == r then
            Yields[row.YieldType] = row.YieldChange
        end
    end
    return Yields
end

function SiqiResource:CanSee(playerID)
    local resourceData = Players[playerID]:GetResources()
    if not resourceData:IsResourceVisible(self.Hash) then return false; end
    return true 
end

function SiqiResource:CanPlaceHere(playerID, pPlot)
    if pPlot:GetResourceType() ~= -1 then  -- 如果地块有资源
        local Res = SiqiResource:new(pPlot:GetResourceType()) -- 获得该地块的资源对象
        if Res:CanSee(playerID) then return false; end -- 如果这个资源看不见，那就可以种资源，符合直觉。
    end
    if pPlot:GetImprovementType() ~= -1 then
        local ImprovementType = GameInfo.Improvements[pPlot:GetImprovementType()].ImprovementType or -1
        local CanPlace = self.Improvements[ImprovementType]
        return CanPlace
    end
    if pPlot:GetFeatureType() ~= -1 then
        local FeatureType = GameInfo.Features[pPlot:GetFeatureType()].FeatureType or -1
        local CanPlace = self.ValidFeatures[FeatureType]
        return CanPlace
    end
    local terrainType = GameInfo.Terrains[pPlot:GetTerrainType()].TerrainType or -1
    local CanPlace = self.ValidTerrains[terrainType] or false
    return CanPlace
end

function SiqiResource:GetChangeYieldsTooltip()
    local tooltip = Locale.Lookup('LOC_SIQITEACH_RESOURCE_CHANGE')
    local outTip = ''
    for key, val in pairs(self.Yields) do
        local tip = 'LOC_SIQITEACH_RESOURCE_' .. key
        outTip = outTip .. Locale.Lookup(tip, val)
    end
    if outTip == '' then
        outTip = Locale.Lookup('LOC_SIQITEACH_RESOURCE_NOCHANGE')
    end
    return tooltip .. outTip
end

-- 首先预先写一个存储着奢侈品的资源对象表
local Resources = {}
-- 通过遍历判断并且加入到表
for row in GameInfo.Resources() do
    if row.Frequency ~= 0 or row.SeaFrequency ~= 0 then -- 需要能在地图上出现
        if  row.ResourceClassType == 'RESOURCECLASS_LUXURY' then -- 需要是奢侈品
            local Res = SiqiResource:new(row.ResourceType) -- 获取资源对象
            Resources[row.ResourceType] = Res -- 加入资源对象到表中
        end
    end
end

function GetDetail() -- 仅限UI
    local pUnit = UI.GetHeadSelectedUnit()
    local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY())
    local playerID = Game.GetLocalPlayer()
    local detail = {}
    for _, resource in pairs(Resources) do
        -- 如果资源可以放置在这个地块，并且可以看的见这个资源（战略资源需要，不过这里是奢侈品，倒是没必要）
        if resource:CanPlaceHere(playerID, pPlot) and resource:CanSee(playerID)then
            table.insert(detail, resource)
        end
    end;
    return detail
end

function Refresh()
    local pUnit = UI.GetHeadSelectedUnit()
    local unitPanel = ContextPtr:LookUpControl("/InGame/UnitPanel") -- 获取单位面板UI
    if not Hide() then
        unitPanel:RequestRefresh() -- 刷新一下面板
        Controls.SiqiTeachGrid:SetHide(false)
        ResourseRefresh() -- 刷新资源
    else
        unitPanel:RequestRefresh() -- 刷新一下面板
        Controls.SiqiTeachGrid:SetHide(true)     
    end
end

function Hide()
    local pUnit = UI.GetHeadSelectedUnit()
    if not pUnit then return true; end -- 如果没有选中单位，则隐藏按钮
    local unitInfo = GameInfo.Units[pUnit:GetType()]
    if (not unitInfo) or unitInfo.UnitType ~= "UNIT_BUILDER" then return true; end -- 如果单位不是建造者，则隐藏按钮
    if pUnit:GetBuildCharges() <= 0 then return true; end -- 如果单位没有建造次数，则隐藏按钮
    if pUnit:GetMovesRemaining() <= 0 then return true; end -- 如果单位没有剩余移动点，则隐藏按钮
    local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY())
    if pPlot:GetDistrictType() ~= -1 then return true; end -- 如果地块有区域，则隐藏按钮
    local ResourceID = pPlot:GetResourceType()
    local resourceHash = pPlot:GetResourceTypeHash()
    local pResource = Players[pUnit:GetOwner()]:GetResources()
    if ResourceID ~= -1 and pResource:IsResourceVisible(resourceHash) then
        return true -- 如果有资源且资源可见就隐藏
    end
    return false -- 否则不隐藏按钮
end

function ResourseRefresh()
    local pUnit = UI.GetHeadSelectedUnit()
    m_SiqiTeachIM:DestroyInstances()
    m_SiqiTeachIM:ResetInstances()
    Controls.SiqiTeachGrid:SetHide(false)
    local playerID = pUnit:GetOwner()
    local pPlayer = Players[playerID]
    local GoldBalance = pPlayer:GetTreasury():GetGoldBalance() -- 玩家的金币余额
    local Detail = GetDetail() -- 获取资源详细信息
    -- 这个详细信息实际上是之前写的资源对象表。
    local count = #Detail -- 获取资源详细信息的数量
    for i = 1, count, 3 do -- 每三个一列
        local columnInstance = m_SiqiTeachIM:GetInstance() -- 创建新实例
        for iRow = 1, 3, 1 do -- 第一到三行
            if (i + iRow) - 1 <= count then -- 限制资源数量，不会超过可用的最大资源数
                local resource = Detail[i + iRow - 1]
                local slotName = "Row" .. tostring(iRow) -- 第iRow行的控件ID
                local instance = {} -- 创建一个空实例
                -- 将ResourseInstance绑在columnInstance[slotName]，也就是SiqiTeachInstance的Row1/2/3上
                -- 并且将生成的实例赋予instance这个实例上
                -- 是常见的临时绑实例的方法
                ContextPtr:BuildInstanceForControl("ResourseInstance", instance, columnInstance[slotName])
                -- the resource icon
                instance.ResourseIcon:SetIcon('ICON_' .. resource.RecourceType)
                -- 按钮点击效果
                instance.ResourseButton:RegisterCallback(Mouse.eLClick,
                    function()
                        local pUnit = UI.GetHeadSelectedUnit()
                        if pUnit == nil then return end
                        local x, y = pUnit:GetX(), pUnit:GetY()
                        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                            PlayerOperations.EXECUTE_SCRIPT, {
                                UnitID = pUnit:GetID(),
                                X = x,
                                Y = y,
                                Index = resource.Index,
                                OnStart = 'SiqiTeachCreated',
                            }
                        ); 
                        Network.BroadcastPlayerInfo();
                        Controls.SiqiTeachGrid:SetHide(true) 
                    end
                )
                -- tooltip 鼠标悬空文本
                local tooltip = Locale.Lookup('LOC_SIQITEACH_CREATE_RESOURCE', resource.IconString, resource.Name)
                tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. resource:GetChangeYieldsTooltip() -- 获取资源产出文本
                if GoldBalance >= 100 then -- 看看是否有足够金币种植资源，不够就显示红色
                    tooltip = tooltip .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_SIQITEACH_CREATE_NEED_GOLD')
                else
                    tooltip = tooltip .. '[NEWLINE][NEWLINE][COLOR:Civ6Red]'..Locale.Lookup('LOC_SIQITEACH_CREATE_NEED_GOLD')..'[ENDCOLOR]'
                end
                instance.ResourseButton:SetToolTipString(tooltip)
                instance.ResourseButton:SetDisabled(GoldBalance <= 100) -- 按钮是否可用
            end
        end
    end
    -- 处理与改良面板的位置冲突
    local RES_PANEL_ART_PADDING_X = 24;
    local RES_PANEL_ART_PADDING_Y = 20;
    Controls.SiqiTeachButtonStack:CalculateSize(); -- 重新计算排列容器尺寸
    local stackWidth  = Controls.SiqiTeachButtonStack:GetSizeX();
    local stackHeight = Controls.SiqiTeachButtonStack:GetSizeY();
    Controls.SiqiTeachGrid:SetSizeX(stackWidth + RES_PANEL_ART_PADDING_X) -- 重新设置排列容器尺寸的宽
    Controls.SiqiTeachGrid:SetSizeY(stackHeight + RES_PANEL_ART_PADDING_Y) -- 重新设置排列容器尺寸的高
    local container = ContextPtr:LookUpControl('/InGame/UnitPanel/UnitPanelBaseContainer') -- 单位基础面板
    local container2 = ContextPtr:LookUpControl('/InGame/UnitPanel/BuildActionsStack') -- 改良面板
    Controls.SiqiTeachGrid:SetOffsetX(container:GetSizeX() + container2:GetSizeX() + 182) -- 设置一下偏移，让资源面板始终出现在改良面板左侧，182可以酌情修改
end

-- 单位移动完成时刷新函数
function OnUnitMoveComplete(playerID, unitID, iX, iY)
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
	Refresh()
end

-- 单位选择时刷新函数
function OnUnitSelectionChanged(playerID, unitID, plotX, plotY, plotZ, bSelected, bEditable)
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
    if bSelected then
        Refresh()
    end
end

function Initialize()
	local PanelSlide = ContextPtr:LookUpControl("/InGame/UnitPanel/UnitPanelSlide")
    if PanelSlide then
        Controls.SiqiTeachGrid:ChangeParent(PanelSlide)
        ContextPtr:LookUpControl('/InGame/UnitPanel/UnitPanelBaseContainer'):Reparent()
    end
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
    Events.UnitMoveComplete.Add(OnUnitMoveComplete)
end
Events.LoadGameViewStateDone.Add(Initialize)