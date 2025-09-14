
-- ===========================================================================
-- ================================定义=======================================
-- ============================================================================

-- 允许的单位类型
local AllowUnits = {}
AllowUnits['UNIT_BUILDER'] = true
local GAME_SPEED = GameConfiguration.GetGameSpeedType()
local GAME_SPEED_MULTIPLIER = GameInfo.GameSpeeds[GAME_SPEED] and GameInfo.GameSpeeds[GAME_SPEED].CostMultiplier / 100 or 1 -- 获取游戏速度的倍率
local BASE_AMOUNT = 10 -- 基础数值


-- ===========================================================================
function GetTechProgress(playerID)
    local pPlayer = Players[playerID]
	local pPlayerTechs = pPlayer:GetTechs()
	local i, total = 0, 0
	for row in GameInfo.Technologies() do
		if pPlayerTechs:HasTech(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end
-- ===========================================================================
function GetCivicProgress(playerID)
    local pPlayer = Players[playerID]
	local pPlayerCulture = pPlayer:GetCulture()
	local i, total = 0, 0
	for row in GameInfo.Civics() do
		if pPlayerCulture:HasCivic(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end
-- ===========================================================================
-- 获取玩家的游戏进度
function GetPlayerProgress(playerID)
    local pPlayer = Players[playerID]
    local techProgress = GetTechProgress(playerID)
	local civicProgress = GetCivicProgress(playerID)
	local modifier = (1 + 9* math.floor( math.max(techProgress, civicProgress) * 100 ) / 100)
    return modifier
end


-- 单位按钮初始化
function Init()
	local pContext = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
	if pContext ~= nil then
		Controls.UnitGrid:ChangeParent(pContext)
        Controls.UnitButton:RegisterCallback(Mouse.eLClick, OnButtonClicked)
	end
end

-- 刷新函数
function Refresh()
    local pUnit = UI.GetHeadSelectedUnit()
    if pUnit == nil then return end
    if IsButtonHide() then
	Controls.UnitGrid:SetHide(true)
    else
	Controls.UnitGrid:SetHide(false)
        local disabled, str = IsButtonDisabled()
	Controls.UnitButton:SetDisabled(disabled)
        Controls.UnitButton:SetToolTipString(str)
    end
end
-- 单位移动完成时
function OnUnitMoveComplete(playerID, unitID, iX, iY)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end
    Refresh()
end
-- 单位选择改变时
function OnUnitSelectionChanged(playerID, unitID, plotX, plotY, plotZ, bSelected, bEditable)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end
    if bSelected then
        Refresh()
    end
end

-- 判断按钮是否隐藏
function IsButtonHide()

    local pUnit = UI.GetHeadSelectedUnit() -- 获取所选单位
    if not pUnit then return true end --如果不存在就返回true

    local UnitInfo = GameInfo.Units[pUnit:GetType()] -- 获取单位信息
    if not AllowUnits[UnitInfo.UnitType] then return true end --如果不是建造者就返回true

    local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY()) -- 获取单位所在地块
    local playerID = Game.GetLocalPlayer() -- 获取本地玩家
    if pPlot:GetOwner() ~= playerID then return true end --如果不是所有者的领土就返回true

    local ResourceType = pPlot:GetResourceType() or -1 --获取单元格资源类型，注意这里是Index数字
    if ResourceType == -1 then return true end -- 没有资源就直接返回true
    local ResourseInfo = GameInfo.Resources[ResourceType] -- 获取资源信息
    if ResourseInfo.ResourceClassType ~= 'RESOURCECLASS_LUXURY' then return true end -- 不是奢侈品资源就返回true

    if pUnit:GetMovementMovesRemaining() <= 0 then return true end -- 判断单位是否有剩余移动力

    return false --历经千辛万苦，终于可以出现了。
end

-- 判断按钮是否禁用
function IsButtonDisabled()
    local pUnit = UI.GetHeadSelectedUnit() -- 获取所选单位
    local playerID = Game.GetLocalPlayer() -- 获取本地玩家 

    -- 初始化
    local str = ''
    local disabled = false

    local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY()) -- 获得单位所在地块
    local ResourceType = pPlot:GetResourceType()  -- 获得单位所在地块资源
    local ResourseInfo = GameInfo.Resources[ResourceType] -- 获得资源信息
    local ResourseName = Locale.Lookup(ResourseInfo.Name) -- 获得资源名字
    local ResourseIcon = "[ICON_"..ResourseInfo.ResourceType.."]"
    local Amount = math.floor(BASE_AMOUNT * GAME_SPEED_MULTIPLIER * GetPlayerProgress(playerID)) -- 获得给予的科文数值
    str = Locale.Lookup('LOC_SIQI_UI_REMOVE_RESOURSE', ResourseIcon.. ResourseName, Amount) -- 获得最终文本

    return disabled, str
end

-- 按钮点击事件
function OnButtonClicked()
    local pUnit = UI.GetHeadSelectedUnit() -- 获取所选单位
    local playerID = Game.GetLocalPlayer() -- 获取本地玩家
    local Amount = math.floor(BASE_AMOUNT * GAME_SPEED_MULTIPLIER * GetPlayerProgress(playerID)) -- 获得给予的科文数值

    local params = {}
    params.OnStart = 'OnSiqiRemoveResourse' -- 字符串，名字不要重复
    params.iX = pUnit:GetX()
    params.iY = pUnit:GetY()
    params.Amount = Amount
    params.UnitID = pUnit:GetID()

    UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, params)
    Controls.UnitGrid:SetHide(true) -- 让按钮重新隐藏
end

-- Initialize通常用来初始化整个lua文件的函数
function Initialize()
    Init()  
    --刷新
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)--单位选择改变时刷新
    Events.UnitMoveComplete.Add(OnUnitMoveComplete)--单位移动完成时刷新
end

Events.LoadGameViewStateDone.Add(Initialize)