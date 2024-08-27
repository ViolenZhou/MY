--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Near')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- �����б�
--------------------------------------------------------------------------------

do
local NEARBY_NPC = {}      -- ������NPC
local NEARBY_PET = {}      -- ������PET
local NEARBY_BOSS = {}     -- ����������
local NEARBY_PLAYER = {}   -- ���������
local NEARBY_PLAYER_SYNCING = {} -- �ս���ͬ����Χ����ͬ�����ݵ����
local NEARBY_DOODAD = {}   -- ��������Ʒ
local NEARBY_FIGHT = {}    -- ������Һ�NPCս��״̬����

-- ��ȡָ������
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]number dwID)
-- (KObject, info, bIsInfo) X.GetObject([number dwType, ]string szName)
-- dwType: [��ѡ]��������ö�� TARGET.*
-- dwID  : ����ID
-- return: ���� dwType ���ͺ� dwID ȡ�ò�������
--         ������ʱ����nil, nil
function X.GetObject(arg0, arg1, arg2)
	local dwType, dwID, szName
	if X.IsNumber(arg0) then
		if X.IsNumber(arg1) then
			dwType, dwID = arg0, arg1
		elseif X.IsString(arg1) then
			dwType, szName = arg0, arg1
		elseif X.IsNil(arg1) then
			dwID = arg0
		end
	elseif X.IsString(arg0) then
		szName = arg0
	end
	if not dwID and not szName then
		return
	end

	if dwID and not dwType then
		if NEARBY_PLAYER[dwID] then
			dwType = TARGET.PLAYER
		elseif NEARBY_DOODAD[dwID] then
			dwType = TARGET.DOODAD
		elseif NEARBY_NPC[dwID] then
			dwType = TARGET.NPC
		end
	elseif not dwID and szName then
		local tSearch = {}
		if dwType == TARGET.PLAYER then
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
		elseif dwType == TARGET.NPC then
			tSearch[TARGET.NPC] = NEARBY_NPC
		elseif dwType == TARGET.DOODAD then
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		else
			tSearch[TARGET.PLAYER] = NEARBY_PLAYER
			tSearch[TARGET.NPC] = NEARBY_NPC
			tSearch[TARGET.DOODAD] = NEARBY_DOODAD
		end
		for dwObjectType, NEARBY_OBJECT in pairs(tSearch) do
			for dwObjectID, KObject in pairs(NEARBY_OBJECT) do
				if X.GetObjectName(KObject) == szName then
					dwType, dwID = dwObjectType, dwObjectID
					break
				end
			end
		end
	end
	if not dwType or not dwID then
		return
	end

	local p, info, b
	if dwType == TARGET.PLAYER then
		local me = X.GetClientPlayer()
		if me and dwID == me.dwID then
			p, info, b = me, me, false
		elseif not X.ENVIRONMENT.RUNTIME_OPTIMIZE and me and me.IsPlayerInMyParty(dwID) then
			p, info, b = X.GetPlayer(dwID), GetClientTeam().GetMemberInfo(dwID), true
		else
			p, info, b = X.GetPlayer(dwID), X.GetPlayer(dwID), false
		end
	elseif dwType == TARGET.NPC then
		p, info, b = X.GetNpc(dwID), X.GetNpc(dwID), false
	elseif dwType == TARGET.DOODAD then
		p, info, b = X.GetDoodad(dwID), X.GetDoodad(dwID), false
	elseif dwType == TARGET.ITEM then
		p, info, b = GetItem(dwID), GetItem(dwID), GetItem(dwID)
	end
	return p, info, b
end

do
local CACHE = X.CreateCache('LIB#GetObjectType.v')
-- α���� �п�ɾ��
function X.GetObjectType(obj)
	if not CACHE[obj] then
		if NEARBY_PLAYER[obj.dwID] == obj then
			CACHE[obj] = 'PLAYER'
		elseif NEARBY_NPC[obj.dwID] == obj then
			CACHE[obj] = 'NPC'
		elseif NEARBY_DOODAD[obj.dwID] == obj then
			CACHE[obj] = 'DOODAD'
		else
			local szStr = tostring(obj)
			if szStr:find('^KGItem:%w+$') then
				CACHE[obj] = 'ITEM'
			elseif szStr:find('^KGLuaItemInfo:%w+$') then
				CACHE[obj] = 'ITEM_INFO'
			elseif szStr:find('^KDoodad:%w+$') then
				CACHE[obj] = 'DOODAD'
			elseif szStr:find('^KNpc:%w+$') then
				CACHE[obj] = 'NPC'
			elseif szStr:find('^KPlayer:%w+$') then
				CACHE[obj] = 'PLAYER'
			else
				CACHE[obj] = 'UNKNOWN'
			end
		end
	end
	return CACHE[obj]
end
end

-- ��ȡ����NPC�б�
-- (table) X.GetNearNpc(void)
function X.GetNearNpc(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_NPC) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_NPC[k] = nil
		else
			table.insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function X.GetNearNpcID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_NPC) do
		table.insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function X.GetNearNpcTable()
	return NEARBY_NPC
end
end

-- ��ȡ����PET�б�
-- (table) X.GetNearPet(void)
function X.GetNearPet(nLimit)
	local aPet = {}
	for k, _ in pairs(NEARBY_PET) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_PET[k] = nil
		else
			table.insert(aPet, npc)
			if nLimit and #aPet == nLimit then
				break
			end
		end
	end
	return aPet
end

function X.GetNearPetID(nLimit)
	local aPetID = {}
	for k, _ in pairs(NEARBY_PET) do
		table.insert(aPetID, k)
		if nLimit and #aPetID == nLimit then
			break
		end
	end
	return aPetID
end

if IsDebugClient() then
function X.GetNearPetTable()
	return NEARBY_PET
end
end

-- ��ȡ����������
-- (table) X.GetNearBoss(void)
function X.GetNearBoss(nLimit)
	local aNpc = {}
	for k, _ in pairs(NEARBY_BOSS) do
		local npc = X.GetNpc(k)
		if not npc then
			NEARBY_BOSS[k] = nil
		else
			table.insert(aNpc, npc)
			if nLimit and #aNpc == nLimit then
				break
			end
		end
	end
	return aNpc
end

function X.GetNearBossID(nLimit)
	local aNpcID = {}
	for k, _ in pairs(NEARBY_BOSS) do
		table.insert(aNpcID, k)
		if nLimit and #aNpcID == nLimit then
			break
		end
	end
	return aNpcID
end

if IsDebugClient() then
function X.GetNearBossTable()
	return NEARBY_BOSS
end
end

X.RegisterEvent(X.NSFormatString('{$NS}_SET_BOSS'), 'LIB#GetNearBoss', function()
	local dwMapID, tBoss = X.GetMapID(), {}
	for _, npc in ipairs(X.GetNearNpc()) do
		if X.IsBoss(dwMapID, npc.dwTemplateID) then
			NEARBY_BOSS[npc.dwID] = npc
		end
	end
	NEARBY_BOSS = tBoss
end)

-- ��ȡ��������б�
-- (table) X.GetNearPlayer(void)
function X.GetNearPlayer(nLimit)
	local aPlayer = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		local p = X.GetPlayer(k)
		if not p then
			NEARBY_PLAYER[k] = nil
		else
			table.insert(aPlayer, p)
			if nLimit and #aPlayer == nLimit then
				break
			end
		end
	end
	return aPlayer
end

function X.GetNearPlayerID(nLimit)
	local aPlayerID = {}
	for k, _ in pairs(NEARBY_PLAYER) do
		table.insert(aPlayerID, k)
		if nLimit and #aPlayerID == nLimit then
			break
		end
	end
	return aPlayerID
end

if IsDebugClient() then
function X.GetNearPlayerTable()
	return NEARBY_PLAYER
end
end

-- ��ȡ������Ʒ�б�
-- (table) X.GetNearPlayer(void)
function X.GetNearDoodad(nLimit)
	local aDoodad = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		local doodad = X.GetDoodad(dwID)
		if not doodad then
			NEARBY_DOODAD[dwID] = nil
		else
			table.insert(aDoodad, doodad)
			if nLimit and #aDoodad == nLimit then
				break
			end
		end
	end
	return aDoodad
end

function X.GetNearDoodadID(nLimit)
	local aDoodadID = {}
	for dwID, _ in pairs(NEARBY_DOODAD) do
		table.insert(aDoodadID, dwID)
		if nLimit and #aDoodadID == nLimit then
			break
		end
	end
	return aDoodadID
end

if IsDebugClient() then
function X.GetNearDoodadTable()
	return NEARBY_DOODAD
end
end

X.BreatheCall(X.NSFormatString('{$NS}#FIGHT_HINT_TRIGGER'), function()
	for dwID, tar in pairs(NEARBY_NPC) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(X.NSFormatString('{$NS}_NPC_FIGHT_HINT'), dwID, tar.bFightState)
		end
	end
	for dwID, tar in pairs(NEARBY_PLAYER) do
		if tar.bFightState ~= NEARBY_FIGHT[dwID] then
			NEARBY_FIGHT[dwID] = tar.bFightState
			FireUIEvent(X.NSFormatString('{$NS}_PLAYER_FIGHT_HINT'), dwID, tar.bFightState)
		end
	end
end)
X.RegisterEvent('NPC_ENTER_SCENE', function()
	local npc = X.GetNpc(arg0)
	if npc and npc.dwEmployer ~= 0 then
		NEARBY_PET[arg0] = npc
	end
	if npc and X.IsBoss(X.GetMapID(), npc.dwTemplateID) then
		NEARBY_BOSS[arg0] = npc
	end
	NEARBY_NPC[arg0] = npc
	NEARBY_FIGHT[arg0] = npc and npc.bFightState or false
end)
X.RegisterEvent('NPC_LEAVE_SCENE', function()
	NEARBY_PET[arg0] = nil
	NEARBY_BOSS[arg0] = nil
	NEARBY_NPC[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
X.RegisterEvent('PLAYER_ENTER_SCENE', function()
	local player = X.GetPlayer(arg0)
	NEARBY_PLAYER[arg0] = player
	NEARBY_PLAYER_SYNCING[arg0] = player
	NEARBY_FIGHT[arg0] = player and player.bFightState or false
	if X.GetClientPlayerID() == arg0 then
		FireUIEvent(X.NSFormatString('{$NS}_CLIENT_PLAYER_ENTER_SCENE'))
	end
end)
X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if X.GetClientPlayerID() == arg0 then
		FireUIEvent(X.NSFormatString('{$NS}_CLIENT_PLAYER_LEAVE_SCENE'))
	end
	NEARBY_PLAYER[arg0] = nil
	NEARBY_PLAYER_SYNCING[arg0] = nil
	NEARBY_FIGHT[arg0] = nil
end)
X.FrameCall('LIB#NEARBY_PLAYER_SYNCING', function()
	for dwID, kTarget in pairs(NEARBY_PLAYER_SYNCING) do
		if kTarget.szName ~= '' then
			NEARBY_PLAYER_SYNCING[dwID] = nil
			FireUIEvent(X.NSFormatString('{$NS}_PLAYER_ENTER_SCENE'), dwID)
		end
	end
end)
X.RegisterEvent('DOODAD_ENTER_SCENE', function() NEARBY_DOODAD[arg0] = X.GetDoodad(arg0) end)
X.RegisterEvent('DOODAD_LEAVE_SCENE', function() NEARBY_DOODAD[arg0] = nil end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
