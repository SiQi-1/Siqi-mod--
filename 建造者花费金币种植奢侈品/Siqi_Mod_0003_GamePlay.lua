-- 减少单位的劳动力
function ReduceUnitBuildCharge(playerID, unitID)
    local pUnit = UnitManager.GetUnit(playerID, unitID) -- 获取玩家的单位
    if pUnit == nil then return; end -- 如果单位不存在则返回
    local pUnitAbility = pUnit:GetAbility()
    for i = 1,16 do
        if pUnitAbility:GetAbilityCount("ABILITY_SIQI_TEACH_REDUCED_CHARGE_"..i) == 0 then
            pUnitAbility:ChangeAbilityCount("ABILITY_SIQI_TEACH_REDUCED_CHARGE_"..i, 1);
            break
        end
    end
end

function SiqiTeachCreated(playerID, params)
    local pUnit = UnitManager.GetUnit(playerID, params.UnitID)
    local pPlot = Map.GetPlot(params.X, params.Y)
    local pPlayer = Players[playerID]
    ResourceBuilder.SetResourceType(pPlot, params.Index, 1)
    UnitManager.FinishMoves(pUnit) -- 结束单位的移动
    ReduceUnitBuildCharge(playerID, params.UnitID)
    pPlayer:GetTreasury():ChangeGoldBalance(-100) -- 扣除100金币
end

function Initialize()
    GameEvents.SiqiTeachCreated.Add(SiqiTeachCreated)
end

Events.LoadGameViewStateDone.Add(Initialize)