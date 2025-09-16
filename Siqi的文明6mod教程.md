
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

这里主要是给出一些辅助函数，附带简单的解释。

##### 1.2.1 判断玩家

使用lua写一些文明领袖能力时，我们总要判断玩家的特质，这里给出四种判断玩家类型的方法：

**直接判断玩家的文明类型和领袖类型**
优点：简单直接
缺点：兼容性差，只有这个文明/领袖可用
```lua
--判断玩家是不是目标文明 返回布尔值
function IsCivilizationType(playerID, civilizationType)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return false; end
    if pPlayerConfig:GetCivilizationTypeName() == civilizationType then return true;
    else return false; end
end

--判断玩家是不是目标领袖 返回布尔值
function IsLeaderType(playerID, leaderType)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return false; end
    if pPlayerConfig:GetLeaderTypeName() == leaderType then return true;
    else return false; end
end
```

**判断玩家的Trait**
优点：兼容性更好
缺点：代码更复杂
```lua
-- 判断玩家是否拥有目标Trait 返回布尔值
function PlayerHasTrait(playerID, sTrait)
	if playerID == nil or sTrait== nil then return false; end --首先，获取玩家配置
	local playerConfig = PlayerConfigurations[playerID]
	if playerConfig == nil then return false; end --然后，获取玩家的文明和领袖类型
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
**判断玩家的Property**
优点：非常自由
缺点：要写配合的Modifier，麻烦。
```lua
-- 判断玩家是否拥有目标Property 返回布尔值
function Siqi_HasTraitProperty(playerID, sProperty)
    local pPlayer = Players[playerID]
    if not pPlayer then return false; end
    local property = pPlayer:GetProperty(sProperty)
    if not property or property <= 0 then return false; end
    return true
end
```

##### 1.2.2 字符串

```lua
-- 获得产出的字符串 示例：[ICON_Food]食物
function GetYieldString(YieldType)
    return GameInfo.Yields[YieldType].IconString..Locale.Lookup(GameInfo.Yields[YieldType].Name)
end
```

##### 1.2.3 二进制转产

二进制转产已经成为我大部分mod的核心了，其核心REQ就是
**REQUIREMENT_PLOT_PROPERTY_MATCHES**
参数为：PropertyName和PropertyMinimum

基本原理：REQUIREMENT_PLOT_PROPERTY_MATCHES判断的是单元格的Property值，而我们是可以在lua中设置Property值的，因此这也是我们能在lua控制modifier的开关的方法。这种方法有缺点，但总体而言大幅提高了modder的自由度。

为了方便讲解，我们先设定一个简单的目标：
```
城市每点宜居度额外+2科技值。
```
先新建一个sql文件：*_Modifiers.sql（这里的 *表示前缀，按需填写就行）

然后这样写：
```sql
-- 这里是通用能力，当然也可以改成TraitModifiers然后绑定领袖或文明，不过ModifierType也需要对应修改。
INSERT INTO  GameModifiers (ModifierId) VALUES
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_1'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_2'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_4'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_8'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_16'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_32'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_64');

INSERT INTO  Modifiers(ModifierId, ModifierType, SubjectRequirementSetId) VALUES
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_1'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_2'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_4'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_8'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_16'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_32'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'MODIFIER_ALL_CITIES_ADJUST_CITY_YIELD_CHANGE', 'SIQI_MOD2_CITY_YIELD_SCIENCE_64');

INSERT INTO  ModifierArguments (ModifierId, Name, Value) VALUES
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_1','Amount','1'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_1','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_2','Amount','2'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_2','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_4','Amount','4'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_4','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_8','Amount','8'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_8','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_16','Amount','16'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_16','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_32','Amount','32'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_32','YieldType','YIELD_SCIENCE'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_64','Amount','64'),
('MODIFIER_SIQI_MOD2_CITY_YIELD_SCIENCE_64','YieldType','YIELD_SCIENCE');
 
INSERT INTO  RequirementSets (RequirementSetId, RequirementSetType) VALUES
('SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'REQUIREMENTSET_TEST_ALL'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO  RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_1'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_2'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_4'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_8'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_16'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_32'),
('SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_64');

INSERT INTO  Requirements (RequirementId, RequirementType) VALUES
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'REQUIREMENT_PLOT_PROPERTY_MATCHES');

INSERT INTO  RequirementArguments (RequirementId, Name, Value) VALUES
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_1'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_1', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_2'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_2', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_4'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_4', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_8'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_8', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_16'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_16', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_32'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_32', 'PropertyMinimum', 1),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'PropertyName', 'REQ_SIQI_MOD2_PROPERTY_64'),
('REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_64', 'PropertyMinimum', 1);

```

这样我们就得到了一系列由REQUIREMENT_PLOT_PROPERTY_MATCHES控制的modifier，假设我们需要10科技值产出，那么只需要：
REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_8和REQ_SIQI_MOD2_CITY_YIELD_SCIENCE_2启用，将对应的PropertyName的值设为1，其他的设为0，就可以轻松做到了。我们可以自由组合出1到127的科技值产出。

城市宜居度是会上下变动的，因此我们需要反复刷新，控制modifier的启用与否。

#### 1.3 UI界面设计

本节我们将尝试制作UI界面，以及一些常用的控件使用方法；由于UI界面设计较为复杂，我们将从一个最简单的界面设计开始，带大家一步步深入探讨。

##### 1.2.1 设计一个简单面板

本小节我们先从设计一个最简单的UI面板开始，假如我们要设计如下面板：
![alt text](img/image1.jpg)

###### **1、xml部分：面板内容**

xml部分记录了这个面板上所包涵的所有内容。首先我们来分析一下这个面板上有哪些内容：
![alt text](img/image2.jpg)
通过观察不难发现，这个面板包括：1. 一个主容器：就是目前我们看到的最外面的边框；主容器的背景图片：使用宗教背景的纹理图片；
2.一个标题栏（容器），包括：标题内容（教程面板）；
3.主容器的一个外边框装饰；
4.一个关闭按钮，位于右上角；
5.面板的主体部分，包括：（1）一个标签页选择按钮（第一页），位于标题栏正下方；（2）该标签页对应的内容，包括：1>一个容器，使用深蓝色背景纹理，且四周还有圆角效果；2>中间显示了一个文本，内容是“请输入内容”。

以上内容我们都要在xml里面写出来，具体代码如下：
```xml
    <Container ID="MainContainer" Anchor="C,C" Size="900,600" Offset="0,0">
        <Image ID="ModalBG" Size="parent,parent" Texture="Religion_BG" StretchMode="Tile" ConsumeMouse="1"/>  
        <Grid Size="parent,40" Texture="Controls_SubHeader2" ConsumeMouse="1" SliceCorner="20,2" SliceTextureSize="40,40">
            <Label ID="ScreenTitle" String="LOC_KIANA_WINDOW_TITLE" Anchor="C,C" Style="FontFlair22" FontStyle="glow" ColorSet="ShellHeader" />
        </Grid> 
        <Grid Offset="-8,-8" Size="parent+16,parent+16" Style="ScreenFrame"/>
        <Button ID="CloseButton" Anchor="R,T" Size="44,44" Texture="Controls_CloseLarge"/>
        <Tab ID="TabControl" Anchor="L,T" Size="parent-40, 520" Offset="0,30">
            <Stack ID="TabButtons" Anchor="C,T" Offset="0,10" StackGrowth="Right">
                <GridButton ID="SelectTab_FirstPage" Style="TabButton" Size="100,35">
                    <Label Style="FontFlair14" String="LOC_KIANA_FIRST_PAGE_TAB" Anchor="C,C" FontStyle="stroke" ColorSet="TopBarValueCS"/>
                </GridButton>
            </Stack>
            <Container ID="TabContainer" Size="parent,parent" Offset="0,0">
                <Grid ID="FirstPage" Size="parent,parent-20" Offset="20,50" Texture="Religion_OverviewFrame" SliceCorner="15,15" >
                    <Label ID="NoteLabel1" Offset="20,60" Anchor="L,T" WrapWidth="850" Style="FontFlair20" FontStyle="shadow" ColorSet="ShellHeader" String="LOC_KIANA_FIRST_PAGE"/>
                </Grid>
            </Container>
        </Tab>
    </Container>  
```
下面我们来逐行分析一下：
第一行：
```xml
    <Container ID="MainContainer" Anchor="C,C" Size="900,600" Offset="0,0">
```
这里定义了一个主容器，ID为MainContainer；锚点是Anchor="C,C"，表示这个容器生成在游戏界面的正中间（C,C表示上下居中，左右居中，类似的L表示左边，R表示右边，T表示顶部，B表示底部，比如Anchor="L,T"就表示靠左置顶）；大小为Size="900,600"，表示长为900像素，宽为600像素；偏移量为0：Offset="0,0"。

第二行：
```xml
        <Image ID="ModalBG" Size="parent,parent" Texture="Religion_BG" StretchMode="Tile" ConsumeMouse="1"/>  
```
这里是定义背景图片的，图片的ID为ModalBG；Size="parent,parent"：尺寸大小与父控件相同，即长为900像素，宽为600像素；Texture="Religion_BG"：使用宗教界面的背景纹理图片（这是官方定义好的图片，这里直接拿来用了。如果想用自己的图片，需要在这里填上自己图片的名称（一定要以dds为后缀，后面我们设顶部按钮的图片还会重点介绍）；StretchMode="Tile"：图片以平铺方式填充；ConsumeMouse="1"：阻止鼠标点击事件穿透到下层。

第三~五行：
```xml
        <Grid Size="parent,40" Texture="Controls_SubHeader2" ConsumeMouse="1" SliceCorner="20,2" SliceTextureSize="40,40">
            <Label ID="ScreenTitle" String="LOC_KIANA_WINDOW_TITLE" Anchor="C,C" Style="FontFlair22" FontStyle="glow" ColorSet="ShellHeader" />
        </Grid> 
```
这里定义了标题栏：Size="parent,40"：标题栏的大小为：长与父控件相同，即900像素，宽为40像素；Texture="Controls_SubHeader2"：使用游戏内名为Controls_SubHeader2的纹理作为背景；ConsumeMouse="1"：阻止鼠标点击事件穿透到下层；SliceCorner="20,2"和SliceTextureSize="40,40"用于控制纹理的九宫格拉伸：SliceTextureSize="40,40"：定义了源纹理中被视为“角”的区域大小（40x40像素）；SliceCorner="20,2"：定义了在目标（这个Grid）上，每个角应该占用多大区域。这里水平方向角宽20像素，垂直方向角高2像素。简单来说，这确保了背景纹理在拉伸时，角落部分（如圆角）能保持原样，而中间部分则平滑拉伸，以适应任何宽度。

标题栏里面包涵一个文本（即标题：教程面板），ID为ID="ScreenTitle"，String="LOC_KIANA_WINDOW_TITLE"：标题的内容：LOC_KIANA_WINDOW_TITLE翻译过来为“教程面板“，这个需要在text文件里面写好对应的中文翻译；Anchor="C,C"：锚点位于正中间；Style="FontFlair22"：使用官方预定义的文本样式，FontStyle="glow"：在字体基础样式之上，再添加一个发光的效果；ColorSet="ShellHeader"：使用一个名为 ShellHeader 的预定义颜色套装。这确保了整个游戏的标题文本颜色风格统一（通常是亮色，如白色，以在深色背景上突出）。

第六行：
```xml
        <Grid Offset="-8,-8" Size="parent+16,parent+16" Style="ScreenFrame"/>
```
这里定义了一个主容器的的外边框装饰：Offset="-8,-8"：偏移量为-8，-8表示相对于其父容器（MainContainer）上下左右各超出8个像素，所以总和就是16，即Size="parent+16,parent+16"；Style="ScreenFrame"：定义了这个装饰的纹理效果。

第七行：
```xml
        <Button ID="CloseButton" Anchor="R,T" Size="44,44" Texture="Controls_CloseLarge"/>
```
这里定义了一个关闭按钮：ID为CloseButton；Anchor="R,T"：锚点在父容器右边置顶；Size="44,44"：大小为44*44像素，Texture="Controls_CloseLarge"：使用大号关闭按钮的图标。（小号关闭按钮的图标为：Style="CloseButtonSmall"，这里不需要设定尺寸）

第八行：
```xml
        <Tab ID="TabControl" Anchor="L,T" Size="parent-40, 520" Offset="0,30">
```
这里定义了标签页容器：包括标签页选择按钮及其对应的区域，容器的ID为TabControl，锚点在左边置顶，尺寸大小为：长为父容器-40像素，宽为520像素（也可以写parent-80），偏移量为左右偏移量为0，上下偏移量为30.

第九~十三行：
```xml
            <Stack ID="TabButtons" Anchor="C,T" Offset="0,10" StackGrowth="Right">
                <GridButton ID="SelectTab_FirstPage" Style="TabButton" Size="100,35">
                    <Label Style="FontFlair14" String="LOC_KIANA_FIRST_PAGE_TAB" Anchor="C,C" FontStyle="stroke" ColorSet="TopBarValueCS"/>
                </GridButton>
            </Stack>
```
这里定义了标签页选择按钮：首先它在一个容器里，这个容器的堆叠方式为：StackGrowth="Right"：将里面的元素从左到右的顺序依次放置（前面有讲过），锚点为居中顶部，偏移量为向下偏移10像素。该容器里面包括一个按钮，按钮ID为SelectTab_FirstPage：

>**注意脚下**：ID="SelectTab_FirstPage"
>
>可能你已经注意到了，这个ID与其他的略有不同。前面是SelectTab，然后用下划线连接着FirstPage，细心的你一定注意到了，我们接下来Container里面包含的容器Grid ID="FirstPage"正好与这个ID下划线后面的内容相同：
>   ```xml        
>           <Container ID="TabContainer" Size="parent,parent" Offset="0,0">
>               <Grid ID="FirstPage" Size="parent,parent-20" Offset="20,50" Texture="Religion_OverviewFrame" SliceCorner="15,15" >
>                   <Label ID="NoteLabel1" Offset="20,60" Anchor="L,T" WrapWidth="850" Style="FontFlair20" FontStyle="shadow" ColorSet="ShellHeader" String="LOC_KIANA_FIRST_PAGE"/>
>               </Grid>
>           </Container>
>   ```
>注意这里标签页选择按钮的ID是固定写法：即前面是'SelectTab'加上下划线'_'再加上该标签页对应的容器的ID。容器的ID前面的'SelectTab'不能写成其他的，除此之外下划线也一定要有，不然我们点击该标签页选择按钮就无法跳转到其对应的界面。

Style="TabButton": 应用一个名为"TabButton"的预定义样式，尺寸为：长是100像素，宽是35像素，其中按钮内部包含一个文本，Style="FontFlair14"：字体样式为使用14号的“Flair”字体样式，内容为String="LOC_KIANA_FIRST_PAGE_TAB"翻译过来是”第一页“，Anchor="C,C"：字体显示在按钮正中间；FontStyle="stroke"：为文字添加描边效果； ColorSet="TopBarValueCS"：使用一个名为 "TopBarValueCS" 的预定义颜色方案。

第十四~十八行：
```xml        
           <Container ID="TabContainer" Size="parent,parent" Offset="0,0">
               <Grid ID="FirstPage" Size="parent,parent-20" Offset="20,50" Texture="Religion_OverviewFrame" SliceCorner="15,15" >
                   <Label ID="NoteLabel1" Offset="20,60" Anchor="L,T" WrapWidth="850" Style="FontFlair20" FontStyle="shadow" ColorSet="ShellHeader" String="LOC_KIANA_FIRST_PAGE"/>
               </Grid>
           </Container>
```
这里定义了一个所有标签页内容的总父容器，你可以把它想象成一个画板，不同的标签页（FirstPage, SecondPage等）就像是画板上的透明图层。一次只显示一个“图层”，其他的则被隐藏。Grid ID="FirstPage":这是第一个标签页对应的容器，Size="parent,parent-20"：大小为：长为父容器像素，宽比父容器小20像素；Offset="20,50"：向右偏移20像素，向下偏移50像素；Texture="Religion_OverviewFrame"：使用一个名为 Religion_OverviewFrame 的纹理作为这个内容面板的背景（图中显示为深蓝色）；SliceCorner="15,15"： 使用九宫格拉伸，确保这个背景板的圆角（15x15像素）在任何尺寸下都能正确显示，不会变形。

>**笔记笔记**：
>```xml   
>               <Grid ID="FirstPage" Size="parent,parent-20" Offset="20,50" Texture="Religion_OverviewFrame" SliceCorner="15,15" >
>```
> Texture="Religion_OverviewFrame" SliceCorner="15,15",这个代码是设定容器的边框的，如果不写这两个代码，那么该界面（FirstPage）的边框将不会显示，这里写上是为了更好的看到该容器的大小，以便以后往里面添加内容时好调整间距。此外，SliceCorner="15,>15" 是固定写法，这个背景板的圆角：15x15像素 写成其他任何像素值该效果都不会生效。

该容器（FirstPage）内部包涵一个文本：ID为NoteLabel1；WrapWidth="850"：换行宽度：即文本显示的一行字的长度超过1340像素才会换行；Style="FontFlair20"：字体样式为使用使用官方预定义的文本样式；FontStyle="shadow"：在基础样式之上添加额外的阴影效果；ColorSet="ShellHeader"：使用一个预定义的颜色配置集；String="LOC_KIANA_FIRST_PAGE"：该文本内容是：“请输入内容”。

###### **2、xml部分：启动按钮**
现在我们已经在xml文件里面写上了该面板所包涵的所有内容。接下来我们要写打开这个面板的启动按钮（注意我们左上角自定义的按钮）。
这里我们的节点要写成<Instance>: 这不是一个直接显示在界面上的元素，而是一个模板（或蓝图）。它可以被游戏的其他部分或Lua脚本多次“实例化”和调用，从而避免重复编写相同的UI代码。
我们在xml里面写上这个启动按钮，具体代码如下：
```xml
    <Instance Name="LaunchKianaItem">
        <Button ID="LaunchKianaItemButton" Anchor="L,C" Size="49,49" Texture="LaunchBar_Hook_GreatWorksButton" Style="ButtonNormalText" TextureOffset="0,2" StateOffsetIncrement="0,49" ToolTip="LOC_ETStudio_ENTRY_BUTTON_TOOLTIP">
            <Image ID="LaunchItemIcon" Texture="KianaEntryIcon.dds" Size="35,35" Anchor="C,C" Offset="0,-1" Hidden="0"/>
            <Label ID="IconAlter" String="[ICON_CapitalLarge]" Anchor="C,C" Offset="0,0" Hidden="1"/>   
        </Button>
    </Instance>
```
下面我们来逐行分析一下：
第一行：
```xml
    <Instance Name="LaunchKianaItem">
```
Name="LaunchBarItem3": 这个模板的唯一名称。其他代码可以通过这个名称来引用并使用它创建实际的按钮。（在lua里面我们会重点介绍它的用法）

第二行：
```xml
    <Button ID="LaunchKianaItemButton" Anchor="L,C" Size="49,49" Texture="LaunchBar_Hook_GreatWorksButton" Style="ButtonNormalText" TextureOffset="0,2" StateOffsetIncrement="0,49" ToolTip="LOC_KIANA_ENTRY_BUTTON_TOOLTIP">
```
ID="LaunchItem3Button": 按钮实例的标识符。在由这个模板创建出的每个实际按钮中，这个ID可能都会存在，便于单独控制；
Texture="LaunchBar_Hook_GreatWorksButton"：这是按钮的背景纹理；
Style="ButtonNormalText"：应用一个基础的按钮样式；
TextureOffset="0,2"：纹理偏移。将背景纹理在Y轴上向下移动2像素，这通常是一个微调属性，用于让背景图案在视觉上与其他图标更好地对齐，实现像素级的精确布局；
StateOffsetIncrement="0,49"：这是一个非常重要的属性，用于处理按钮的不同状态（如正常、悬停、按下、禁用），它表示状态纹理在源纹理集（Texture Atlas）中的偏移量增量。0,49 意味着：不同状态（悬停、按下等）对应的纹理位于当前纹理正下方49像素的位置。这是一种常见的“纹理集”或“精灵图（Sprite Sheet）”技术，将多个状态的图像放在一张大图上，通过偏移来切换；
ToolTip="LOC_KIANA_ENTRY_BUTTON_TOOLTIP"：按钮的鼠标悬停提示：定义鼠标悬停在按钮上时显示的工具提示文本。

第三行：
```xml
            <Image ID="LaunchItemIcon" Texture="KianaEntryIcon.dds" Size="35,35" Anchor="C,C" Offset="0,-1" Hidden="0"/>
```
这里定义了按钮的图片，ID为LaunchItemIcon，这里采用自定义图片，名称是KianaEntryIcon.dds，大小为35*35像素，锚点为居中，偏移量为向下偏移1个像素，Hidden="0"：默认显示（如果Hidden="1"就是默认隐藏）。

>**笔记笔记**：
>  关于图片的加载，有两种方法：第一种是直接在modinfo里面的<ImportFiles>节点填上图片的路径：  
>```modinfo 
>      <ImportFiles id="KianaInclude">
>          <File>KianaEntryIcon.dds</File>
>      </ImportFiles>
>``` 
>第二种方法是创建一个xlp文件，最后生成blp文件，这里为了方便我们采用第一种方法。（采用第二种方法不要忘记创建一个*.artdef文件，不然游戏读不出来图片）

第四行：
```xml
            <Label ID="IconAlter" String="[ICON_CapitalLarge]" Anchor="C,C" Offset="0,0" Hidden="1"/>  
```
这是一个备用显示方案。如果自定义图标因为某种原因无法加载，可能会回退到这里显示这个备用图标。String="[ICON_CapitalLarge]": 这是官方的图标代码。Hidden="1": 1 表示默认隐藏。因为这个是备用方案，所以正常情况下不显示。

除此之外我们最好写一个启动栏标记点模板，这个模板创建了一个小圆点，这类小元素在游戏UI中常常用于指示状态、进度或当前位置，比如表示某个功能有新通知，或者作为多页面启动栏的页码指示器。
我们在xml里面写上相关代码，具体代码如下：
```xml
    <Instance Name="LaunchKianaPinInstance">
    <Image ID="KianaPin" Anchor="L,C" Offset="0,-2" Size="7,7" Texture="LaunchBar_TrackPip" Color="255,255,255,200"/>
    </Instance>
```
ID="KianaPin"： 该图像元素的标识符。
Anchor="L,C"： 锚定在父容器的左侧中间位置。
Offset="0,-2"： 视觉微调。在锚定位置的基础上，再向上偏移2像素。
Size="7,7"： 定义图像的显示大小为7x7像素。这是一个非常小的尺寸，明确表明它是一个点缀性的指示器，而不是主要按钮。
Texture="LaunchBar_TrackPip"：指定了要显示的图像来源。
Color="255,255,255,200"：颜色覆盖属性，这意味着它是半透明的，不是纯白。

**至此我们xml部分就全部写完了，接下来我们来写lua部分的代码。**

###### **3、lua部分**

关于lua部分，首先我们先在文件开头写上以下几行代码：
```lua
include("InstanceManager");  -- 引入游戏引擎的实例管理系统

local m_LaunchItemInstanceManager = InstanceManager:new("LaunchKianaItem", "LaunchKianaItemButton")
local m_LaunchBarPinInstanceManager = InstanceManager:new("LaunchKianaPinInstance", "KianaPin")
```
我们一行一行来看，第一行：
```lua
include("InstanceManager");  
```
这行代码引入了游戏引擎提供的一个名为InstanceManager.lua的脚本文件，这个文件定义了一个叫做InstanceManager的类（Class）。这个类是文明6UI系统的基石，它提供了一种强大且高效的方法来动态创建、重复使用和销毁由XML模板定义的UI控件。可以说，我们以后写UI界面，这个是必须要有的，而且在开头就直接写上。

第二行和第三行：
```lua
local m_LaunchItemInstanceManager = InstanceManager:new("LaunchKianaItem", "LaunchKianaItemButton")
local m_LaunchBarPinInstanceManager = InstanceManager:new("LaunchKianaPinInstance", "KianaPin")
```
这两行就是创建一个新的实例管理器（InstanceManager）对象，专门用于管理我们在xml里面写好的UI实例。
`InstanceManager:new()`: 调用 InstanceManager 类的构造函数，创建一个新的管理器，后面跟了两个参数，分别是`LaunchKianaItem`和`LaunchKianaItemButton`，其中第一个参数LaunchKianaItem是我们在xml里面创建的面板启动按钮实例的模板名。它告诉管理器：“当你需要创建新实例时，请去查找我们在XML文件中用 <Instance Name="LaunchKianaItem"> 定义的那个模板”。第二个参数LaunchKianaItemButton是根控件的ID，在我们的代码中它是一个按钮的ID：<Button ID="LaunchKianaItemButton"……。它告诉管理器：“在那个模板里，真正的根元素是一个ID为LaunchKianaItemButton的控件（Button），请把它作为这个实例的代表返回给我”。
后面`local m_LaunchBarPinInstanceManager = InstanceManager:new("LaunchKianaPinInstance", "KianaPin")`同理，就是把启动栏标记点模板也写进去。

>**笔记笔记**
>所以，一般我们写xml的时候，都在<Instance></Instance>里面再套一层容器，比如这里就是<Button></Button>，有些代码里面会是<Container></Container>,这样我们在lua里面调用这个实例的时候，就会把<Instance>里面定义的所有内容全都包含进去。
>其实这个函数`InstanceManager:new()`不止上面提到的两个参数，它还有第三个参数，只是这里我们暂时用不到，后面我们在写记录文本以及新建按钮的时候会用到，到时候会再跟大家详细解释这个函数。

之后，我们写上按钮的初始化代码：

```lua
local EntryButtonInstance = nil  -- 启动栏按钮实例（后续通过GetInstance()赋值）
local LaunchBarPinInstance = nil  -- 启动栏标记点实例

function SetupKianaLaunchBarButton()  
    local ctrl = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")  --通过路径查找UI控件
    if ctrl == nil then-- 兼容性检查，如果没有找到控件，就返回，这个检查可以防止脚本因找不到控件而抛出错误，导致游戏崩溃
        return
    end
    if EntryButtonInstance == nil then  -- 单例模式：防止多次创建同一个按钮。EntryButtonInstance 是一个全局变量，初始为nil。首次运行后，它会保存创建的按钮实例。这个检查确保即使函数被多次调用，也只会创建一个按钮实例，避免在启动栏上出现重复按钮。
        EntryButtonInstance = m_LaunchItemInstanceManager:GetInstance(ctrl)    -- 创建按钮实例并挂载到游戏UI
        LaunchBarPinInstance = m_LaunchBarPinInstanceManager:GetInstance(ctrl)  --创建一个标记点实例并添加到启动栏
        EntryButtonInstance.LaunchKianaItemButton:RegisterCallback(Mouse.eLClick,    -- 注册按钮点击事件：打开界面（LaunchKianaItemButton是我们在xml里面定义好的按钮ID）
        function()
            ShowKIANAWindow()  --调用函数打开界面
        end)
    end
end

function ShowKIANAWindow() -- 打开界面
    ContextPtr:SetHide(false)  -- 显示窗口
    UI.PlaySound("UI_Screen_Open") -- 播放打开音效
end

function Initialize()
    SetupKianaLaunchBarButton()
end
Events.LoadGameViewStateDone.Add(Initialize)
```
看到这里，或许你会有疑问，为什么这里要定义两个全局变量呢？
`local EntryButtonInstance = nil`
 `local LaunchBarPinInstance = nil`
其实这是一个引用变量。它的目的是为了后续存储从m_LaunchItemInstanceManager函数里面生成出来的第一个按钮实例，在下面的SetupKianaLaunchBarButton()函数中，你会看到这行代码：EntryButtonInstance = m_LaunchItemInstanceManager:GetInstance(ctrl)，这时，EntryButtonInstance 就不再是 nil，而是一个包含真实UI按钮的对象，程序可以通过它来操作这个具体的按钮（如注册点击事件，判断按钮可见性，等等）。

举个例子，比如说我们现在给这个按钮增加一个可见性检查，只有当玩家选择阿基坦的埃莉诺（法国）这个领袖的时候，按钮才可见，代码如下：

```lua
local m_iCurrentPlayerID = Game.GetLocalPlayer() -- 当前玩家ID
local m_pCurrentPlayer = Players[m_iCurrentPlayerID]  -- 当前玩家对象
local ELEANOR_FRANCE = "LEADER_ELEANOR_FRANCE"  -- 阿基坦的埃莉诺（法国）

function KianaIsPlayerLeader(playerID, leaderType)
    local pPlayerConfig = PlayerConfigurations[playerID]
    if pPlayerConfig == nil then return false; end
   if pPlayerConfig:GetLeaderTypeName() == leaderType then
        return true
    else
        return false
    end
end

function KianaButtonIsHide()
    if not KianaIsPlayerLeader(m_iCurrentPlayerID, ELEANOR_FRANCE) then
        EntryButtonInstance.LaunchKianaItemButton:SetHide(true);
    else
        EntryButtonInstance.LaunchKianaItemButton:SetHide(false);
    end
end

function SetupKianaLaunchBarButton()  
    local ctrl = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")  --通过路径查找UI控件
    if ctrl == nil then-- 兼容性检查，如果没有找到控件，就返回，这个检查可以防止脚本因找不到控件而抛出错误，导致游戏崩溃
        return
    end
    if EntryButtonInstance == nil then  -- 单例模式：防止多次创建同一个按钮。EntryButtonInstance 是一个全局变量，初始为nil。首次运行后，它会保存创建的按钮实例。这个检查确保即使函数被多次调用，也只会创建一个按钮实例，避免在启动栏上出现重复按钮。
        EntryButtonInstance = m_LaunchItemInstanceManager:GetInstance(ctrl)    -- 创建按钮实例并挂载到游戏UI
        LaunchBarPinInstance = m_LaunchBarPinInstanceManager:GetInstance(ctrl)  --创建一个标记点实例并添加到启动栏
        KianaButtonIsHide()  --添加按钮可见性检查
        EntryButtonInstance.LaunchKianaItemButton:RegisterCallback(Mouse.eLClick,    -- 注册按钮点击事件：打开界面
        function()
            ShowKIANAWindow()  --调用函数打开界面
        end)
    end
end
--后续代码……
```
在KianaButtonIsHide()这个函数中，我们直接写上：
`EntryButtonInstance.LaunchKianaItemButton:SetHide(true);`
`EntryButtonInstance.LaunchKianaItemButton:SetHide(false);`
来判断按钮是否可见。

到这里还没结束，虽然我们定义了打开界面的代码逻辑，但是并没有写关闭界面的代码逻辑，这个时候进入游戏，你会发现只要打开这个界面就关不掉了。所以我们还要继续添加关闭界面的代码逻辑。此时你应该会想到，我们在xml里面定义了一个关闭按钮：ID为CloseButton，位于右上角。接下来我们为这个按钮写上关闭界面的功能，代码如下：
```lua
function HideKIANAWindow() --- 关闭界面
    if not ContextPtr:IsHidden() then   -- 检查窗口是否已显示
        ContextPtr:SetHide(true) -- 隐藏窗口
        UI.PlaySound("UI_Screen_Close") -- 播放关闭音效
    end
end
```
除此之外我们还要为这个关闭按钮注册回调函数，在Initialize()函数里添加回调函数：
```lua
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, HideKIANAWindow)  -- 关闭按钮
```
这时你的Initialize()函数看起来会是这样：
```lua
function Initialize()
    SetupKianaLaunchBarButton()
    KianaButtonIsHide() --再次调用按钮可见性函数
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, HideKIANAWindow)  -- 关闭按钮
end
Events.LoadGameViewStateDone.Add(Initialize)
```
这里可能大家会有疑问，为什么在前面的SetupKianaLaunchBarButton()函数中已经调用过按钮可见性的函数，这里为什么还要再调用一次呢？其实，这种看似“重复”的操作通常是有意为之的，是一种防御性编程和确保兼容性的重要技巧，主要原因有以下几点：

>**笔记笔记**
>1. 初始化时序的不确定性
>这是最主要的原因。游戏UI的加载和初始化是一个多阶段的过程：
>第一阶段：你的Lua文件被加载，Initialize() 函数被定义，但尚未执行。
>第二阶段：Events.LoadGameViewStateDone.Add(Initialize) 确保在游戏主界面完全加载后，才执行你的 Initialize() 函数。
>第三阶段：在 Initialize() 内部，你调用 SetupKianaLaunchBarButton()。
>问题在于：即使在 SetupKianaLaunchBarButton() 中成功创建了按钮并设置了初始可见性，从这时到游戏完全准备就绪之间，游戏状态可能仍会发生微小变化。例如，玩家的最终配置、其他Mod的干扰或游戏内部的后续初始化步骤都可能影响按钮应该显示的状态。
>在 Initialize() 的末尾再次调用 KianaButtonIsHide()，相当于在所有初始化代码执行完毕后，进行一次最终的状态同步，确保按钮的可见性是基于100%确定的游戏状态。
>
>2. 模块化与函数职责
>SetupKianaLaunchBarButton() 的主要职责是“创建和设置按钮”。调用 KianaButtonIsHide() 是其设置过程的一部分，确保按钮创建后有一个合理的初始状态。
>Initialize() 的主要职责是“确保整个Mod处于正确的初始状态”。在它看来，按钮的可见性是这种状态的一部分。因此，它需要亲自验证并强制执行一次，无论之前的函数做了什么。
>
>3. 代码可读性与维护性
>从代码维护的角度看，在 Initialize() 中明确地调用 KianaButtonIsHide()，清晰地传达了我们的设计意图：“在初始化结束时，按钮的可见性必须根据当前条件重新计算一次”。这使得后续的维护者能够更轻松地理解整个初始化流程的最终目标。

到这一步，我们的lua部分就差不多写完了。最后再添加一些管理UI界面生命周期和交互的函数，可以确保Mod的稳定性、与游戏本身的良好集成以及高效的内存使用。具体如下：

```lua
function KianaInputHandler(uiMsg, wParam, lParam)  --输入处理 InputHandler()
    if (uiMsg == KeyEvents.KeyUp) then  -- 检测按键事件
        if (wParam == Keys.VK_ESCAPE) then-- 如果是ESC键
            if Controls.MainContainer:IsVisible() then  --我们创建的UI界面可见
                HideKIANAWindow() -- 关闭窗口
                return true   -- 阻止事件继续传递
            end
        end
    end
    return false -- 其他按键不拦截
end

function KianaInitHandler()  --初始化逻辑 InitHandler()
    SetupKianaLaunchBarButton()   -- 初始化游戏主界面的入口按钮
end

function KianaShutdownHandler()  --- 关闭时资源清理
        -- 1. 释放主界面入口按钮实例（避免内存泄漏）
    if EntryButtonInstance ~= nil then
        m_LaunchItemInstanceManager:ReleaseInstance(EntryButtonInstance)
    end
        -- 2. 释放入口按钮的装饰标记实例（避免内存泄漏）
    if LaunchBarPinInstance ~= nil then
        m_LaunchBarPinInstanceManager:ReleaseInstance(LaunchBarPinInstance)
    end
end

--最后初始化函数添加下面的部分;
function Initialize()
    SetupKianaLaunchBarButton()
    KianaButtonIsHide()
    ContextPtr:SetInputHandler(KianaInputHandler)  -- 设置全局输入监听
    ContextPtr:SetInitHandler(KianaInitHandler) -- 设置界面初始化回调
    ContextPtr:SetShutdown(KianaShutdownHandler)  -- 设置界面关闭回调
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, HideKIANAWindow)  -- 关闭按钮

    LuaEvents.DiplomacyActionView_HideIngameUI.Add(HideKIANAWindow)     --当外交界面显示时，需要隐藏游戏内UI（包括我们的Mod窗口）
    LuaEvents.EndGameMenu_Shown.Add(HideKIANAWindow)                    --当结束游戏菜单（例如胜利/失败画面）显示时，隐藏我们的窗口。
    LuaEvents.FullscreenMap_Shown.Add(HideKIANAWindow)                  --当全屏地图显示时，隐藏我们的窗口。
    LuaEvents.NaturalWonderPopup_Shown.Add(HideKIANAWindow)             --当自然奇观弹出界面显示时（例如我们发现一个自然奇观），隐藏我们的窗口。
    LuaEvents.ProjectBuiltPopup_Shown.Add(HideKIANAWindow)              --当项目建成弹出界面显示时（例如完成一个太空项目），隐藏我们的窗口。
    LuaEvents.Tutorial_ToggleInGameOptionsMenu.Add(HideKIANAWindow)     --当教程中切换游戏选项菜单时（或者游戏选项菜单显示/隐藏时），隐藏我们的窗口。
    LuaEvents.WonderBuiltPopup_Shown.Add(HideKIANAWindow)               --当奇观建成弹出界面显示时（例如完成一个奇观），隐藏我们的窗口。
    LuaEvents.NaturalDisasterPopup_Shown.Add(HideKIANAWindow)           --当自然灾害弹出界面显示时（例如发生了一次洪水或火山喷发），隐藏我们的窗口。
    LuaEvents.RockBandMoviePopup_Shown.Add(HideKIANAWindow)             --当摇滚乐队电影弹出界面显示时（摇滚乐队演出时的动画），隐藏我们的窗口。
end
Events.LoadGameViewStateDone.Add(Initialize)
```
在初始化函数中，我们设置了这三个回调函数：
```lua
ContextPtr:SetInputHandler(KianaInputHandler)  -- 设置全局输入监听
ContextPtr:SetInitHandler(KianaInitHandler) -- 设置界面初始化回调
ContextPtr:SetShutdown(KianaShutdownHandler)  -- 设置界面关闭回调
```
首先，`SetInputHandler(KianaInputHandler)`：这是一个输入处理函数 ，它会告诉游戏引擎，当这个UI界面是当前焦点时，所有的键盘和鼠标输入事件都要先交给 KianaInputHandler 函数处理。这让你可以捕获按键（如ESC键）。这个函数确保了当你的Mod窗口打开时，按下ESC键会关闭你的窗口，并且这个ESC键事件不会继续传递去关闭游戏的其他界面（比如意外退出了游戏主菜单），提供了用户友好的游戏体验。

其次，`SetInitHandler(KianaInitHandler)`：这是一个延迟初始化函数。游戏引擎会在所有UI元素加载完毕、但尚未显示之前调用它。那么为什么我们要在这里调用？ 虽然我们在Initialize()函数里已经调用了SetupKianaLaunchBarButton()，但有些UI操作确保在完全初始化完成后执行会更安全。这里再次确保启动栏按钮被正确创建和设置。

最后，`SetShutdown(KianaShutdownHandler)`：这是UI的析构函数。当Mod界面被关闭或游戏结束时，游戏引擎会自动调用它。在游戏运行期间，通过 InstanceManager:GetInstance() 创建的UI实例会占用内存。如果不手动释放，即使关闭了Mod，这些内存也不会被回收，导致内存泄漏。这个很重要：如果不加上这个函数，那么有可能会导致即使把mod卸了也会触发相应的功能！

最后是LuaEvents，这些是文明6游戏引擎提供的事件系统的一部分，它们代表了游戏中发生的各种特定或随机事件。当游戏中发生这些事件时，调用我们的 HideKIANAWindow 函数，隐藏界面。这是一种非常重要的设计模式，它确保了我们的Mod界面能够与游戏原生界面正确交互和和谐共存，避免UI重叠或冲突。

至此，我们的所有工作就都做完了。最后在Text.xml里面写上翻译文本，这个mod就做完了。但是我们这个UI界面并没有什么实际的功能，下一节我们会给这个UI界面设定一个简单的功能：记录玩家的实时信息。

##### 1.2.2 设计一个记录信息功能
