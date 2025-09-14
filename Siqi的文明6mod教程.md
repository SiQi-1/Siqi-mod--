
# 糸七 的文明6mod教程

## 前言

本文并非基础教学，而是各种实例，内容可能比较杂，可以根据目录按需观看，无需按顺序看。

## 致谢

我要感谢所有在lua方面对我有过帮助的modder，比如Hemmelfort、枫叶、优妮，以及大量modder的优质mod，让我迅速累积了大量经验来完成本教程。


## 正文

### 前置知识

本文不会从最基础的知识讲起，默认你已经学习过以下教程：

- Hemmelfort的[Github](https://github.com/Hemmelfort/Civ6ModdingNotes)和[Gitee](https://gitee.com/Hemmelfort/Civ6ModdingNotes)，以及b站[视频](https://www.bilibili.com/video/BV1VW411U7tN/)和专栏。

- 枫叶的[文明6lua教程](https://github.com/FYMapleLeaves/ml-civ6-lua-tutorial/blob/main/%E6%9E%AB%E5%8F%B6%E7%9A%84%E6%96%87%E6%98%8E6lua%E6%95%99%E7%A8%8B.md)。

文明6常用目录

- Log位置（伟大建设者包更新后）：**C:\Users\用户\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs**
- 非创意工坊mod放置位置：**C:\Users\用户\文档\My Games\Sid Meier's Civilization VI\Mods**
- 文明6游戏文件目录（Steam）：**\Steam\steamapps\common\Sid Meier's Civilization VI**
- Steam创意工坊mod文件目录：**\Steam\steamapps\workshop\content\289070**

### 1. lua


#### 1.1 UI

基础知识：加载你的UI文件

通常而言，你需要新建两个文件，通常会放在UI文件夹。

UI.xml
UI.lua

值得注意的是，尽可能不要使用可能撞名的文件名字，这里只是用作示范才取简单名字。

如果你不需要新增UI，而是为了使用一些必须在UI环境才能使用的函数，在UI.xml写下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<Context>
</Context>
```

然后再在.modinfo这样写：
```xml
<AddUserInterfaces id="UI">
  	<Properties>
    	    <Context>InGame</Context>
  	</Properties>
	<File>UI/UI.xml</File>
</AddUserInterfaces>

```
加载.xml文件后会自动加载同名的.lua文件


##### 1.1.1 单位按钮

如果只是做单位按钮，实际上h佬和枫叶佬已经讲得很详细了，所以这里借用单位按钮讲解一些基本原理。

新建两个文件，为了方便，在这里简单命名为：
Siqi_UnitPanel.lua
Siqi_UnitPanel.xml

Siqi_UnitPanel.xml这么写：

```xml
<?xml version="1.0" encoding="utf-8"?>
<Context>
	<Grid ID="UnitGrid" Anchor="R,B" Size="auto,41" AutoSizePadding="6,0" Texture="SelectionPanel_ActionGroupSlot" SliceCorner="5,19" SliceSize="1,1" SliceTextureSize="12,41" ConsumeMouse="1" Hidden="1">
		<Button ID="UnitButton" Anchor="C,B" Size="44,53" Texture="UnitPanel_ActionButton">
			<Image ID="UnitButtonIcon"		Anchor="C,C" Offset="0,-2" Size="38,38"  Icon="ICON_UNITOPERATION_HARVEST_RESOURCE"/>
		</Button>
	</Grid>
</Context>
```
> 通常而言，这个xml所表示的单位按钮长这样：![alt text](img/Imp1.png)
> ```<Grid></Grid>```是最外面的矩形框架，其参数定义了其的位置，大小，样式
> ```<Button></Button>```是中间的圆形按钮，其参数定义了其的位置，大小，样式
> ```<Image></Image>```是最里面的收割图标，Icon是对应图标的名字。


大部分参数无需理会，已经是大佬做好了的，通常只需关注Icon即可，选择合适的图标来让你的单位按钮更具特色吧。

做好了单位按钮，接下来我们需要按照下面的思路来编写lua代码：

```
按钮怎么绑在单位面板上？
什么时候显示？
什么时候可用，什么时候不可用？
对应的文本是什么？
按了之后会发生什么？
```
为了能更好的进行教程，我们来设计一个简单的小能力：
```
建造者清除领土内的奢侈品资源，并且获得科技或者文化。
```
现在，我们按照上面的思路来一步步完成代码吧：

###### **1、初始化**

```lua

-- 单位按钮初始化
function Init()
	local pContext = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
	if pContext ~= nil then
		Controls.UnitGrid:ChangeParent(pContext)
        Controls.UnitButton:RegisterCallback(Mouse.eLClick, OnButtonClicked)
	end
end

-- Initialize通常用来初始化整个lua文件的函数
function Initialize()
    Init()  
end

Events.LoadGameViewStateDone.Add(Initialize)

```

>笔记笔记：如果你按照"/InGame/UnitPanel/StandardActionsStack"来寻找并翻开找到官方文件UI/Panels/UnitPanel.xml，你会发现这个，也就是我们所绑定的UI控件。
>```xml
><!-- ACTIONS PANEL -->
><Stack					ID="ActionsStack" Anchor="R,T" Offset="2,-3" AnchorSide="I,O" StackGrowth="Left" StackPadding="2">
>	<Stack				ID="StandardActionsStack" Anchor="C,B" StackGrowth="Right" Padding="2" ConsumeMouse="1" />
>         <Grid			        ID="ExpandSecondaryActionGrid" Anchor="R,B" Size="auto,41" AutoSizePadding="6,0" Texture="SelectionPanel_ActionGroupSlot" SliceCorner="5,19" SliceSize="1,1" SliceTextureSize="12,41" ConsumeMouse="1" Alpha="0.75">
>               ......（此处省略）
>	</Grid>
></Stack>
>```
>将会发现我们绑在了一个Stack控件里，Stack是用来排列和放置控件的容器，StackGrowth为Right时，将会按照从左到右的顺序依次放置其中的控件
>然而我们绑定的控件```<Stack				ID="StandardActionsStack" Anchor="C,B" StackGrowth="Right" Padding="2" ConsumeMouse="1" />```并没有出现其他按钮出现，这是怎么回事呢？
>如果你挖掘一下，就能发现，下面的部分似乎与上面的StandardActionsStack绑定到一起了。Instance的用法在此处先不多说，容易发现，下面的Button和Image是和上面我们的按钮定义是非常相似的，而这个就是官方的单位按钮。
>```xml
>         <!-- Action definition -->
>	<Instance Name="UnitActionInstance" >
>		<Button		ID="UnitActionButton" Anchor="L,T" Size="44,53" Texture="UnitPanel_ActionButton">
>			<Image	ID="UnitActionIcon"		Anchor="C,C" Offset="0,-2" Size="38,38"  Texture="UnitActions"/>
>		</Button>
>	</Instance>
>```
>也就是说，我们的操作其实就是把我们自己写的按钮，绑定到官方的StandardActionsStack控件上
>```lua
>local pContext = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
>Controls.UnitGrid:ChangeParent(pContext)
>```
>现在再看这串代码，应该就能明白，我们实际上做了什么。
###### **2、刷新时机**
现在，我们在Initialize加上新的代码
```lua
function Initialize()
    --初始化
    Init()  
    --刷新
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)--单位选择改变时刷新
    Events.UnitMoveComplete.Add(OnUnitMoveComplete)--单位移动完成时刷新
end

Events.LoadGameViewStateDone.Add(Initialize)
```
然后，我们写出刷新函数Refresh
```lua
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
```
这些都是通用的部分，即便未来写各种各样的按钮逻辑也不必改变，而下面要写的就是IsButtonHide和IsButtonDisabled的函数逻辑了，也是我们的核心刷新逻辑，通常要根据实际情况灵活修改。

###### **3、刷新逻辑**

还记得我们一开始的目的吗？
**建造者清除领土内的奢侈品资源，并且获得科技或者文化。**

现在我们来决定这个按钮该不该出现吧~
按照我们的需求，这个单位应当有下面的条件：
1. 存在
2. 是建造者
3. 位于领土内
4. 有奢侈品
5. 有剩余移动力

那么我们就可以根据这些条件写出IsButtonHide函数：
```lua
--被允许显示的单位表，这样写可以更简单的扩展可用单位种类。
local AllowUnits = {}
AllowUnits['UNIT_BUILDER'] = true

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
```

- 然后是按钮是否可用，实际上由于不满足条件的已经被IsButtonHide函数刷下来了，所以这里通常是判断其他的，例如，我们可以要求拥有灌溉科技后才能清除种植园类奢侈品，解锁畜牧业后才能清除牧场类奢侈品。这里为了简单，不再加上这些复杂的判断逻辑，而是直接就可以清除奢侈品资源。

我们思考一下奢侈品给多少科文，为了方便，这里定义给的科文数为：
**向下取整：10 * (1 + 9 * 科文进度) 科技值与文化值**

获得科文进度的函数为：
```lua
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
```

定义下面的文本，用来给按钮显示
```sql
INSERT INTO LocalizedText (Language, Tag, Text) VALUES
('zh_Hans_CN', 'LOC_SIQI_UI_REMOVE_RESOURSE', '清除该地块的{1_str}资源[NEWLINE]+{2_num}[ICON_Science]科技和[ICON_Culture]文化。');
```

```lua
local GAME_SPEED = GameConfiguration.GetGameSpeedType()
local GAME_SPEED_MULTIPLIER = GameInfo.GameSpeeds[GAME_SPEED] and GameInfo.GameSpeeds[GAME_SPEED].CostMultiplier / 100 or 1 -- 获取游戏速度的倍率
local BASE_AMOUNT = 10 -- 基础数值

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
```

###### **4、按钮能力**
好了，按钮的刷新逻辑就这样简单的做完了，现在来看按下按钮会发生什么事情。很显然，这里是UI环境，我们需要传递信息到gameplay，然后在gameplay环境修改数据。

回到我们的目的：**建造者清除领土内的奢侈品资源，并且获得科技或者文化。**
那么我们需要在按下按钮后，发现下面的事情：
1. 资源被清除
2. 玩家获得科技和文化
3. 单位结束行动
4. 单位失去一点劳动力

对应需要的数据：
1. 地块坐标
2. 科文数值
3. 单位ID
4. 单位ID

那么我们写出最后写在UI的函数吧：

```lua
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
```
###### **5、效果实现**

新建一个文件
Siqi_Scripts.lua

然后这样写：
```lua
function OnSiqiRemoveResourse(playerID, params)

    local pPlot = Map.GetPlot(params.iX, params.iY)
    ResourceBuilder.SetResourceType(pPlot, -1)-- 清除资源

    local pPlayer = Players[playerID]
    local Amount = params.Amount
    pPlayer:GetTechs():ChangeCurrentResearchProgress(Amount) -- 获得科技
    pPlayer:GetCulture():ChangeCurrentCulturalProgress(Amount) -- 获得文化

    local pUnit = UnitManager.GetUnit(playerID, params.UnitID)
    UnitManager.FinishMoves(pUnit)

    -- 地图浮动文字
    Game.AddWorldViewText(playerID , '+'..Amount..GameInfo.Yields['YIELD_SCIENCE'].IconString..Locale.Lookup(GameInfo.Yields['YIELD_SCIENCE'].Name),params.iX, params.iY)
    Game.AddWorldViewText(playerID , '+'..Amount..GameInfo.Yields['YIELD_CULTURE'].IconString..Locale.Lookup(GameInfo.Yields['YIELD_CULTURE'].Name),params.iX, params.iY)
end

function Initialize()
    GameEvents.OnSiqiRemoveResourse.Add(OnSiqiRemoveResourse)
end

Events.LoadGameViewStateDone.Add(Initialize)
```
细心的你一定发现了，这里没有写减少劳动力，因为lua无法直接减少劳动力，需要modifier辅助。

新建一个sql文件:
Siqi_Modifiers.sql

```sql
INSERT INTO Types (Type, Kind) VALUES
('ABILITY_SIQI_LOSE_CHARGE_1', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_2', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_3', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_4', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_5', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_6', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_7', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_8', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_9', 'KIND_ABILITY'),
('ABILITY_SIQI_LOSE_CHARGE_10', 'KIND_ABILITY');

INSERT INTO TypeTags (Type, Tag) VALUES
('ABILITY_SIQI_LOSE_CHARGE_1', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_2', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_3', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_4', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_5', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_6', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_7', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_8', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_9', 'CLASS_ALL_UNITS'),
('ABILITY_SIQI_LOSE_CHARGE_10', 'CLASS_ALL_UNITS');

INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive, Permanent) VALUES
('ABILITY_SIQI_LOSE_CHARGE_1',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_2',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_3',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_4',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_5',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_6',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_7',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_8',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_9',  NULL, NULL, 1, 1),
('ABILITY_SIQI_LOSE_CHARGE_10', NULL, NULL, 1, 1);

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
('ABILITY_SIQI_LOSE_CHARGE_1',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_2',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_3',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_4',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_5',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_6',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_7',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_8',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_9',  'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES'),
('ABILITY_SIQI_LOSE_CHARGE_10', 'MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES');

INSERT INTO Modifiers(ModifierId, ModifierType) VALUES
('MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES', 'MODIFIER_SIQI_CHANGE_UNIT_ADJUST_BUILDER_CHARGES');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MODIFIER_SIQI_LOST_UNIT_BUILDER_CHARGES', 'Amount', '-1');

INSERT INTO Types (Type, Kind) VALUES
('MODIFIER_SIQI_CHANGE_UNIT_ADJUST_BUILDER_CHARGES',                          'KIND_MODIFIER'); -- 玩家单位劳动力控制

INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
('MODIFIER_SIQI_CHANGE_UNIT_ADJUST_BUILDER_CHARGES',                          'EFFECT_ADJUST_UNIT_BUILD_CHARGES',                     'COLLECTION_OWNER');

```

然后在lua补充减少劳动力的函数
```lua
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
    ...省略

    local pUnit = UnitManager.GetUnit(playerID, params.UnitID)
    UnitManager.FinishMoves(pUnit)
    ReduceUnitBuildCharge(playerID, params.UnitID)

    ...省略
end
```

于是，一个简单的建造者收割奢侈品的mod就做好了，完整版可以在**建造者收割奢侈品**文件夹里看看

#### 1.2 一些功能性函数





