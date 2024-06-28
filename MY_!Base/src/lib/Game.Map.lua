--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Map')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local MAP_LIST
local function GenerateMapInfo()
	if not MAP_LIST then
		MAP_LIST = {}
		for _, dwMapID in ipairs(GetMapList()) do
			local map = {
				dwID     = dwMapID,
				dwMapID  = dwMapID,
				szName   = X.CONSTANT.MAP_NAME[dwMapID]
					and X.RenderTemplateString(X.CONSTANT.MAP_NAME[dwMapID])
					or Table_GetMapName(dwMapID),
				bDungeon = false,
			}
			local DungeonInfo = X.GetGameTable('DungeonInfo', true)
			if DungeonInfo then
				local tDungeonInfo = DungeonInfo:Search(dwMapID)
				if tDungeonInfo and tDungeonInfo.dwClassID == 3 then
					map.bDungeon = true
				end
			end
			MAP_LIST[map.dwID] = map
			MAP_LIST[map.szName] = map
		end
		MAP_LIST = X.FreezeTable(MAP_LIST)
	end
	return MAP_LIST
end

---��ȡһ����ͼ����Ϣ
---(table) X.GetMapInfo(dwMapID)
---(table) X.GetMapInfo(szMapName)
---@param arg0 number | string @��ͼID���ͼ����
---@return table @��ͼ��Ϣ
function X.GetMapInfo(arg0)
	if not MAP_LIST then
		GenerateMapInfo()
	end
	if arg0 and X.CONSTANT.MAP_MERGE[arg0] then
		arg0 = X.CONSTANT.MAP_MERGE[arg0]
	end
	return MAP_LIST[arg0]
end
end

function X.GetMapNameList()
	local aList, tMap = {}, {}
	for k, v in X.ipairs_r(GetMapList()) do
		local szName = Table_GetMapName(v)
		if not tMap[szName] then
			tMap[szName] = true
			table.insert(aList, szName)
		end
	end
	return aList
end

---��ȡ���ǵ�ǰ���ڵ�ͼ
---@param bFix boolean @�Ƿ�������
---@return number @���ڵ�ͼID
function X.GetMapID(bFix)
	local dwMapID = X.GetClientPlayer().GetMapID()
	return bFix and X.CONSTANT.MAP_MERGE[dwMapID] or dwMapID
end

do
local ARENA_MAP
---�ж�һ����ͼ�ǲ�����������ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ�����������ͼ
function X.IsArenaMap(dwMapID)
	if not ARENA_MAP then
		ARENA_MAP = {}
		local tTitle = {
			{f = 'i', t = 'dwMapID'},
			{f = 'i', t = 'nEnableGroup0'},
			{f = 'i', t = 'nEnableGroup1'},
			{f = 'i', t = 'nEnableGroup2'},
			{f = 'i', t = 'nEnableGroup3'},
			{f = 'i', t = 'dwPQTemplateID'},
			{f = 'i', t = 'nVisitorCount'},
			{f = 'i', t = 'nGMVisitorCount'},
			{f = 's', t = 'szScript'},
			{f = 'i', t = 'nCritical'},
			X.IS_CLASSIC and {f = 'i', t = 'nIs1V1'} or false,
		}
		for i, v in X.ipairs_r(tTitle) do
			if not v then
				table.remove(tTitle, i)
			end
		end
		local tab = KG_Table.Load('settings\\ArenaMap.tab', tTitle, FILE_OPEN_MODE.NORMAL)
		local nRow = tab:GetRowCount()
		for i = 1, nRow do
			local tLine = tab:GetRow(i)
			ARENA_MAP[tLine.dwMapID] = true
		end
	end
	return ARENA_MAP[dwMapID]
end
end

---�жϵ�ǰ��ͼ�ǲ�����������ͼ
---@return boolean @��ǰ��ͼ�Ƿ�����������ͼ
function X.IsInArenaMap()
	local me = X.GetClientPlayer()
	return me and X.IsArenaMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ���ս����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ���ս����ͼ
function X.IsBattlefieldMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.BATTLE_FIELD and not X.IsArenaMap(dwMapID)
end

---�жϵ�ǰ��ͼ�ǲ���ս����ͼ
---@return boolean @��ǰ��ͼ�Ƿ���ս����ͼ
function X.IsInBattlefieldMap()
	local me = X.GetClientPlayer()
	return me and X.IsBattlefieldMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ����ؾ���ͼ
---@param dwMapID number | string @Ҫ�жϵĵ�ͼID���ͼ����
---@param bRaid boolean @�Ƿ�ǿ��Ҫ���Ŷ��ؾ���С���ؾ�
---@return boolean @�Ƿ����ؾ���ͼ
function X.IsDungeonMap(dwMapID, bRaid)
	local map = X.GetMapInfo(dwMapID)
	if map then
		dwMapID = map.dwMapID
	end
	if bRaid == true then -- �ϸ��ж�25�˱�
		return map and map.bDungeon
	elseif bRaid == false then -- �ϸ��ж�5�˱�
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON and not (map and map.bDungeon)
	else -- ֻ�жϵ�ͼ������
		return select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
	end
end

---�жϵ�ǰ��ͼ�ǲ����ؾ���ͼ
---@param bRaid boolean @�Ƿ�ǿ��Ҫ���Ŷ��ؾ���С���ؾ�
---@return boolean @��ǰ��ͼ�Ƿ����ؾ���ͼ
function X.IsInDungeonMap(bRaid)
	local me = X.GetClientPlayer()
	return me and X.IsDungeonMap(me.GetMapID(), bRaid)
end

---�ж�һ����ͼ�ǲ��Ǹ���CD�ؾ���ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��Ǹ���CD�ؾ���ͼ
function X.IsCDProgressMap(dwMapID)
	return (select(8, GetMapParams(dwMapID)))
end

---�жϵ�ǰ��ͼ�ǲ��Ǹ���CD�ؾ���ͼ
---@return boolean @��ǰ��ͼ�Ƿ��Ǹ���CD�ؾ���ͼ
function X.IsInCDProgressMap()
	local me = X.GetClientPlayer()
	return me and X.IsCDProgressMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ������ǵ�ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ������ǵ�ͼ
function X.IsCityMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CITY and true or false
end

---�жϵ�ǰ��ͼ�ǲ������ǵ�ͼ
---@return boolean @��ǰ��ͼ�Ƿ������ǵ�ͼ
function X.IsInCityMap()
	local me = X.GetClientPlayer()
	return me and X.IsCityMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ���Ұ���ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ���Ұ���ͼ
function X.IsVillageMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.VILLAGE and true or false
end

---�жϵ�ǰ��ͼ�ǲ���Ұ���ͼ
---@return boolean @��ǰ��ͼ�Ƿ���Ұ���ͼ
function X.IsInVillageMap()
	local me = X.GetClientPlayer()
	return me and X.IsVillageMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ�����Ӫ��ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ�����Ӫ��ͼ
function X.IsCampMap(dwMapID)
	local tType = Table_GetMapType(dwMapID)
	return tType and tType.CAMP and true or false
end

---�жϵ�ǰ��ͼ�ǲ�����Ӫ��ͼ
---@return boolean @��ǰ��ͼ�Ƿ�����Ӫ��ͼ
function X.IsInCampMap()
	local me = X.GetClientPlayer()
	return me and X.IsCampMap(me.GetMapID())
end

do
local PUBG_MAP = {}
---�жϵ�ͼ�ǲ��Ǿ���ս����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��Ǿ���ս����ͼ
function X.IsPubgMap(dwMapID)
	if PUBG_MAP[dwMapID] == nil then
		PUBG_MAP[dwMapID] = X.Table.IsTreasureBattleFieldMap(dwMapID) or false
	end
	return PUBG_MAP[dwMapID]
end
end

---�жϵ�ǰ��ͼ�ǲ��Ǿ���ս����ͼ
---@return boolean @��ǰ��ͼ�Ƿ��Ǿ���ս����ͼ
function X.IsInPubgMap()
	local me = X.GetClientPlayer()
	return me and X.IsPubgMap(me.GetMapID())
end

do
local ZOMBIE_MAP = {}
---�жϵ�ͼ�ǲ�����ɹ����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ�����ɹ����ͼ
function X.IsZombieMap(dwMapID)
	if ZOMBIE_MAP[dwMapID] == nil then
		ZOMBIE_MAP[dwMapID] = Table_IsZombieBattleFieldMap
			and Table_IsZombieBattleFieldMap(dwMapID) or false
	end
	return ZOMBIE_MAP[dwMapID]
end
end

---�жϵ�ǰ��ͼ�ǲ�����ɹ����ͼ
---@return boolean @��ǰ��ͼ�Ƿ�����ɹ����ͼ
function X.IsInZombieMap()
	local me = X.GetClientPlayer()
	return me and X.IsZombieMap(me.GetMapID())
end

do
local MONSTER_MAP = {}
---�жϵ�ͼ�ǲ��ǰ�ս��ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��ǰ�ս��ͼ
function X.IsMonsterMap(dwMapID)
	if MONSTER_MAP[dwMapID] == nil then
		if GDAPI_SpiritEndurance_IsSEMap then
			MONSTER_MAP[dwMapID] = GDAPI_SpiritEndurance_IsSEMap(dwMapID) or false
		else
			MONSTER_MAP[dwMapID] = X.CONSTANT.MONSTER_MAP[dwMapID] or false
		end
	end
	return MONSTER_MAP[dwMapID]
end
end

---�жϵ�ǰ��ͼ�ǲ��ǰ�ս��ͼ
---@return boolean @��ǰ��ͼ�Ƿ��ǰ�ս��ͼ
function X.IsInMonsterMap()
	local me = X.GetClientPlayer()
	return me and X.IsMonsterMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ��������龳��ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��������龳��ͼ
-- (bool) X.IsMobaMap(dwMapID)
function X.IsMobaMap(dwMapID)
	return X.CONSTANT.MOBA_MAP[dwMapID] or false
end

---�жϵ�ǰ��ͼ�ǲ��������龳��ͼ
---@return boolean @��ǰ��ͼ�Ƿ��������龳��ͼ
function X.IsInMobaMap()
	local me = X.GetClientPlayer()
	return me and X.IsMobaMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ����˿��е�ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ����˿��е�ͼ
function X.IsStarveMap(dwMapID)
	return X.CONSTANT.STARVE_MAP[dwMapID] or false
end

---�жϵ�ǰ��ͼ�ǲ����˿��е�ͼ
---@return boolean @��ǰ��ͼ�Ƿ����˿��е�ͼ
function X.IsInStarveMap()
	local me = X.GetClientPlayer()
	return me and X.IsStarveMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ��Ǽ�԰��ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��Ǽ�԰��ͼ
function X.IsHomelandMap(dwMapID)
	return select(2, GetMapParams(dwMapID)) == MAP_TYPE.HOMELAND
end

---�жϵ�ǰ��ͼ�ǲ��Ǽ�԰��ͼ
---@return boolean @��ǰ��ͼ�Ƿ��Ǽ�԰��ͼ
function X.IsInHomelandMap()
	local me = X.GetClientPlayer()
	return me and X.IsHomelandMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ��ǰ���ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��ǰ���ͼ
function X.IsGuildTerritoryMap(dwMapID)
	return dwMapID == 74
end

---�жϵ�ǰ��ͼ�ǲ��ǰ���ͼ
---@return boolean @��ǰ��ͼ�Ƿ��ǰ���ͼ
function X.IsInGuildTerritoryMap()
	local me = X.GetClientPlayer()
	return me and X.IsGuildTerritoryMap(me.GetMapID())
end

do
local ROGUELIKE_MAP = {}
---�жϵ�ͼ�ǲ��ǰ˻ĺ����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��ǰ˻ĺ��ͼ
function X.IsRoguelikeMap(dwMapID)
	if ROGUELIKE_MAP[dwMapID] == nil then
		if Table_IsRougeLikeMap then
			ROGUELIKE_MAP[dwMapID] = Table_IsRougeLikeMap(dwMapID) or false
		else
			ROGUELIKE_MAP[dwMapID] = X.CONSTANT.ROGUELIKE_MAP[dwMapID] or false
		end
	end
	return ROGUELIKE_MAP[dwMapID]
end
end

---�жϵ�ǰ��ͼ�ǲ��ǰ˻ĺ����ͼ
---@return boolean @��ǰ��ͼ�Ƿ��ǰ˻ĺ����ͼ
function X.IsInRoguelikeMap()
	local me = X.GetClientPlayer()
	return me and X.IsRoguelikeMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ����±�����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ����±�����ͼ
function X.IsInventoryPackageLimitedMap(dwMapID)
	return X.IsPubgMap(dwMapID) or X.IsMobaMap(dwMapID) or X.IsStarveMap(dwMapID)
end

---�жϵ�ǰ��ͼ�ǲ����±�����ͼ
---@return boolean @��ǰ��ͼ�Ƿ����±�����ͼ
function X.IsInInventoryPackageLimitedMap()
	local me = X.GetClientPlayer()
	return me and X.IsInventoryPackageLimitedMap(me.GetMapID())
end

---�ж�һ����ͼ�ǲ��Ǳ�����ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��Ǳ�����ͼ
function X.IsCompetitionMap(dwMapID)
	return X.IsArenaMap(dwMapID) or X.IsBattlefieldMap(dwMapID)
		or X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID)
		or X.IsMobaMap(dwMapID)
		or dwMapID == 173 -- �����
		or dwMapID == 181 -- ��Ӱ��
end

---�жϵ�ǰ��ͼ�ǲ��Ǳ�����ͼ
---@return boolean @��ǰ��ͼ�Ƿ��Ǳ�����ͼ
function X.IsInCompetitionMap()
	local me = X.GetClientPlayer()
	return me and X.IsCompetitionMap(me.GetMapID())
end

---�жϵ�ͼ�ǲ��ǹ������ε�ͼ
---@param dwMapID number @Ҫ�жϵĵ�ͼID
---@return boolean @�Ƿ��ǹ������ε�ͼ
function X.IsShieldedMap(dwMapID)
	if X.IsPubgMap(dwMapID) or X.IsZombieMap(dwMapID) then
		return true
	end
	if IsAddonBanMap and IsAddonBanMap(dwMapID) then
		return true
	end
	return false
end

---�жϵ�ǰ��ͼ�ǲ��ǹ������ε�ͼ
---@return boolean @��ǰ��ͼ�Ƿ��ǹ������ε�ͼ
function X.IsInShieldedMap()
	local me = X.GetClientPlayer()
	return me and X.IsShieldedMap(me.GetMapID())
end

---@class GetDungeonMenuOptions @��ȡ�ؾ��˵�����
---@field tChecked table<number, boolean> @Ĭ��ѡ�е��ؾ�
---@field fnAction fun(tMapNameID: table<string, string | number>) @���ʱ�ص�����
---@field bPartyMap boolean @�Ƿ����С�ӵ�ͼ
---@field bRaidMap boolean @�Ƿ�����Ŷӵ�ͼ
---@field bHomelandMap boolean @�Ƿ������԰��ͼ
---@field bMonsterMap boolean @�Ƿ������ս��ͼ
---@field bZombieMap boolean @�Ƿ������ʬ��ͼ
---@field bStarveMap boolean @�Ƿ�����˿��е�ͼ
do
local function RecruitItemToDungeonMenu(p, tOptions)
	if p.bParent then
		local t = { szOption = p.TypeName or p.SubTypeName }
		for _, pp in ipairs(p) do
			table.insert(t, RecruitItemToDungeonMenu(pp, tOptions))
		end
		if #t > 0 then
			return t
		end
	else
		-- ������Ӫ �е�ͼID 7�㿪ʼ ����24Сʱ ���������ؾ���
		if p.nCamp == 7
		and p.nStartTime == 7 and p.nLastTime == 24
		and p.dwMapID and X.IsDungeonMap(p.dwMapID)
		and not (tOptions.bPartyMap == false and X.IsDungeonMap(p.dwMapID, false))
		and not (tOptions.bRaidMap == false and X.IsDungeonMap(p.dwMapID, true))
		and not (tOptions.bHomelandMap == false and X.IsHomelandMap(p.dwMapID))
		and not (tOptions.bMonsterMap == false and X.IsMonsterMap(p.dwMapID))
		and not (tOptions.bZombieMap == false and X.IsZombieMap(p.dwMapID))
		and not (tOptions.bStarveMap == false and X.IsStarveMap(p.dwMapID)) then
			return {
				szOption = p.szName,
				bCheck = tOptions.tChecked and true or false,
				bChecked = tOptions.tChecked and tOptions.tChecked[p.dwMapID] or false,
				bDisable = false,
				UserData = {
					dwID = p.dwMapID,
					szName = p.szName,
				},
				fnAction = tOptions.fnAction,
			}
		end
	end
	return nil
end

-- ��ȡ�ؾ�ѡ��˵�
---@param tOptions GetDungeonMenuOptions @�������
---@return table @ѡ��˵�����
function X.GetDungeonMenu(tOptions)
	local t = {}
	for _, p in ipairs(X.Table.GetTeamRecruit() or {}) do
		table.insert(t, RecruitItemToDungeonMenu(p, tOptions or {}))
	end
	return t
end
end

function X.GetTypeGroupMap()
	-- �����ͼ����
	local tGroupMap, tMapExist = {}, {}
	local function GroupMapIterator(dwMapID, szGroup, szMapName)
		if szGroup then
			if X.CONSTANT.MAP_MERGE[dwMapID] then
				dwMapID = X.CONSTANT.MAP_MERGE[dwMapID]
			end
			if tMapExist[dwMapID] then
				return
			end
			if not tGroupMap[szGroup] then
				tGroupMap[szGroup] = {}
			end
			table.insert(tGroupMap[szGroup], { dwID = dwMapID, szName = X.IsEmpty(szMapName) and ('#' .. dwMapID) or szMapName })
		end
		tMapExist[dwMapID] = szGroup or 'IGNORE'
	end
	-- ��������Ȩ��
	local tWeight = {} -- { ['������'] = 20, ['������ - С���ؾ�'] = 21 }
	local DLCInfo = X.GetGameTable('DLCInfo', true)
	if DLCInfo then
		for i = 2, DLCInfo:GetRowCount() do
			local tLine = DLCInfo:GetRow(i)
			local szVersionName = X.TrimString(tLine.szDLCName)
			tWeight[szVersionName] = 2000 + i * 10
		end
	end
	for i, szVersionName in ipairs(_L.GAME_VERSION_NAME) do
		tWeight[szVersionName] = 1000 + i * 10
	end
	tWeight[_L.MAP_GROUP['Birth / School']] = 100
	tWeight[_L.MAP_GROUP['City / Old city']] = 99
	tWeight[_L.MAP_GROUP['Village / Camp']] = 98
	tWeight[_L.MAP_GROUP['Battle field / Arena']] = 97
	tWeight[_L.MAP_GROUP['Other dungeon']] = 96
	tWeight[_L.MAP_GROUP['Other']] = 95
	-- ��ȡ�ؾ�����
	local DungeonInfo = X.GetGameTable('DungeonInfo', true)
	if DungeonInfo then
		for i = 2, DungeonInfo:GetRowCount() do
			local tLine = DungeonInfo:GetRow(i)
			local szVersionName = X.TrimString(tLine.szVersionName)
			local szGroup = szVersionName
			if tLine.dwClassID == 1 or tLine.dwClassID == 2 then
				szGroup = szGroup .. ' - ' .. _L['Team dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 2
			elseif tLine.dwClassID == 3 then
				szGroup = szGroup .. ' - ' .. _L['Raid dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 3
			elseif tLine.dwClassID == 4 then
				szGroup = szGroup .. ' - ' .. _L['Duo dungeon']
				tWeight[szGroup] = (tWeight[szVersionName] or 0) + 1
			end
			GroupMapIterator(tLine.dwMapID, szGroup, tLine.szLayer3Name .. tLine.szOtherName)
		end
	end
	-- ���ؾ�
	local MapList = X.GetGameTable('MapList', true)
	if MapList then
		for i = 2, MapList:GetRowCount() do
			local tLine, szGroup = MapList:GetRow(i), nil
			if tLine.szType == 'BIRTH' or tLine.szType == 'SCHOOL' then
				szGroup = _L.MAP_GROUP['Birth / School']
			elseif tLine.szType == 'CITY' or tLine.szType == 'OLD_CITY' then
				szGroup = _L.MAP_GROUP['City / Old city']
			elseif tLine.szType == 'VILLAGE' or tLine.szType == 'OLD_VILLAGE' then
				szGroup = _L.MAP_GROUP['Village / Camp']
			elseif tLine.szType == 'BATTLE_FIELD' or tLine.szType == 'ARENA' then
				szGroup = _L.MAP_GROUP['Battle field / Arena']
			elseif tLine.szType == 'DUNGEON' or tLine.szType == 'RAID' then
				szGroup = _L.MAP_GROUP['Other dungeon']
			elseif tLine.szType ~= 'TEST' then -- tLine.szType == 'OTHER'
				szGroup = _L.MAP_GROUP['Other']
			end
			GroupMapIterator(tLine.nID, szGroup, tLine.szName)
		end
	end
	-- �߼�������
	for _, dwMapID in ipairs(GetMapList()) do
		GroupMapIterator(
			dwMapID,
			select(2, GetMapParams(dwMapID)) == MAP_TYPE.DUNGEON
				and _L.MAP_GROUP['Other dungeon']
				or _L.MAP_GROUP['Other'],
			Table_GetMapName(dwMapID))
	end
	-- ��ϣת����
	local aGroup = {}
	for szGroup, aMapInfo in pairs(tGroupMap) do
		table.insert(aGroup, { szGroup = szGroup, aMapInfo = aMapInfo })
	end
	-- ����
	table.sort(aGroup, function(a, b)
		if not tWeight[a.szGroup] then
			return false
		elseif not tWeight[b.szGroup] then
			return true
		else
			return tWeight[a.szGroup] > tWeight[b.szGroup]
		end
	end)
	return aGroup
end

function X.GetRegionGroupMap()
	local tMapRegion = {}
	local MapList = X.GetGameTable('MapList', true)
	if MapList then
		local nCount = MapList:GetRowCount()
		for i = 2, nCount do
			local tLine = MapList:GetRow(i)
			if tLine.dwRegionID > 0 then
				local dwRegionID = tLine.dwRegionID
				if not tMapRegion[dwRegionID] then
					tMapRegion[dwRegionID] = {}
				end
				local tRegion = tMapRegion[dwRegionID]
				if tLine.nGroup == 4 then -- GROUP_TYPE_COPY
					if tLine.szType == 'RAID' then
						if not tRegion.aRaid then
							tRegion.aRaid = {}
						end
						table.insert(tRegion.aRaid, { dwID = tLine.nID, szName = tLine.szMiddleMap })
					else
						if not tRegion.aDungeon then
							tRegion.aDungeon = {}
						end
						table.insert(tRegion.aDungeon, { dwID = tLine.nID, szName = tLine.szMiddleMap })
					end
				else
					if not tRegion.aMap then
						tRegion.aMap = {}
					end
					table.insert(tRegion.aMap, { dwID = tLine.nID, szName = tLine.szMiddleMap })
				end
			end
		end
	end
	local aRegion = {}
	local RegionMap = X.GetGameTable('RegionMap', true)
	if RegionMap then
		local nCount = RegionMap:GetRowCount()
		for i = 2, nCount do
			local tLine = RegionMap:GetRow(i)
			local info = tMapRegion[tLine.dwRegionID]
			if info then
				table.insert(aRegion, {
					dwID = tLine.dwRegionID,
					szName = tLine.szRegionName,
					aMapInfo = info.aMap,
					aRaidInfo = info.aRaid,
					aDungeonInfo = info.aDungeon,
				})
			end
		end
	end
	return aRegion
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
