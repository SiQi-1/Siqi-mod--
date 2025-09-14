function ReduceUnitBuildCharge(playerID, UnitID)
    local pUnit = UnitManager.GetUnit(playerID, UnitID) -- 获取玩家的单位
    if pUnit == nil then return; end -- 如果单位不存在则返回
    local pUnitAbility = pUnit:GetAbility()
    for i = 1,10 do
        if pUnitAbility:GetAbilityCount("ABILITY_SIQI_LOSE_CHARGE_"..i) == 0 then
            pUnitAbility:ChangeAbilityCount("ABILITY_SIQI_LOSE_CHARGE_"..i, 1);
            break
        end
    end
end

function OnSiqiRemoveResourse(playerID, params)

    local pPlot = Map.GetPlot(params.iX, params.iY)
    ResourceBuilder.SetResourceType(pPlot, -1)-- 清除资源

    local pPlayer = Players[playerID]
    local Amount = params.Amount
    pPlayer:GetTechs():ChangeCurrentResearchProgress(Amount) -- 获得科技
    pPlayer:GetCulture():ChangeCurrentCulturalProgress(Amount) -- 获得文化

    local pUnit = UnitManager.GetUnit(playerID, params.UnitID)
    UnitManager.FinishMoves(pUnit)
    ReduceUnitBuildCharge(playerID, params.UnitID)

    -- 地图浮动文字
    Game.AddWorldViewText(playerID , '+'..Amount..GameInfo.Yields['YIELD_SCIENCE'].IconString..Locale.Lookup(GameInfo.Yields['YIELD_SCIENCE'].Name),params.iX, params.iY)
    Game.AddWorldViewText(playerID , '+'..Amount..GameInfo.Yields['YIELD_CULTURE'].IconString..Locale.Lookup(GameInfo.Yields['YIELD_CULTURE'].Name),params.iX, params.iY)
end

function Initialize()
    GameEvents.OnSiqiRemoveResourse.Add(OnSiqiRemoveResourse)
end

Events.LoadGameViewStateDone.Add(Initialize)