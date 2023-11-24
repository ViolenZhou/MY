--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ս����־ ��ʽ����ԭʼ�¼�����
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_CombatLogs'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^17.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_CombatLogs', _L['Raid'], {
	bEnable = { -- ���ݼ�¼�ܿ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nMaxHistory = { -- �����ʷ��������
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 300,
	},
	nMinFightTime = { -- ��Сս��ʱ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
	bEnableInDungeon = { -- ���ؾ�������
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableInArena = { -- ���������������
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bEnableInBattleField = { -- ��ս��������
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableInOtherMaps = { -- ���������͵�ͼ������
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bNearbyAll = { -- ���渽�����н�ɫ�¼���¼
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTargetInformation = { -- �����ɫ״̬����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nTargetInformationThrottle = { -- �����ɫ״̬���ݽ���ʱ����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 200,
	},
})
local D = {}
local DS_ROOT = {'userdata/combat_logs/', X.PATH_TYPE.ROLE}

local LOG_ENABLE = false -- ����������ܿ��أ���������ʱ����
local LOG_TARGET_INFORMATION_ENABLE = false -- ���������Ŀ��״̬��¼���أ���������ʱ����
local LOG_TARGET_INFORMATION_THROTTLE = 0 -- ���������Ŀ��״̬��¼��������������ʱ����
local LOG_TIME = 0
local LOG_FILE -- ��ǰ��־�ļ������ڴ���ģʽ���������߼�ս��״̬ʱ��Ϊ��
local LOG_CACHE = {} -- ��δ���̵����ݣ����ʹ���ѹ����
local LOG_CACHE_LIMIT = 20 -- �������ݴﵽ������������
local LOG_CRC = 0
local LOG_TARGET_INFO_TIME = {} -- Ŀ����Ϣ��¼ʱ��
local LOG_TARGET_INFO_TIME_LIMIT = 10000 -- Ŀ����Ϣ�ٴμ�¼��Сʱ����
local LOG_DOODAD_INFO_TIME = {} -- ���������Ϣ��¼ʱ��
local LOG_DOODAD_INFO_TIME_LIMIT = 10000 -- ���������Ϣ�ٴμ�¼��Сʱ����
local LOG_NAMING_COUNT = {} -- ��¼��NPC���ἰ������ͳ�ƣ�����������¼�ļ�
local LOG_TARGET_LOCATION_TIME = {} -- ��¼��ɫ�������������

local LOG_REPLAY = {} -- ��������� ����սʱ�����������ѹ������
local LOG_REPLAY_FRAME = X.ENVIRONMENT.GAME_FPS * 1 -- ��սʱ�򽫶�õ�����ѹ�������߼�֡��

local LOG_TYPE = {
	FIGHT_TIME                            = 1,  -- ս��ʱ��
	PLAYER_ENTER_SCENE                    = 2,  -- ��ҽ��볡��
	PLAYER_LEAVE_SCENE                    = 3,  -- ����뿪����
	PLAYER_INFO                           = 4,  -- �����Ϣ����
	PLAYER_FIGHT_HINT                     = 5,  -- ���ս��״̬�ı�
	NPC_ENTER_SCENE                       = 6,  -- NPC ���볡��
	NPC_LEAVE_SCENE                       = 7,  -- NPC �뿪����
	NPC_INFO                              = 8,  -- NPC ��Ϣ����
	NPC_FIGHT_HINT                        = 9,  -- NPC ս��״̬�ı�
	DOODAD_ENTER_SCENE                    = 10, -- ����������볡��
	DOODAD_LEAVE_SCENE                    = 11, -- ��������뿪����
	DOODAD_INFO                           = 12, -- ���������Ϣ����
	BUFF_UPDATE                           = 13, -- BUFF ˢ��
	PLAYER_SAY                            = 14, -- ��ɫ����������¼NPC��
	ON_WARNING_MESSAGE                    = 15, -- ��ʾ�����
	PARTY_ADD_MEMBER                      = 16, -- �Ŷ���ӳ�Ա
	PARTY_SET_MEMBER_ONLINE_FLAG          = 17, -- �Ŷӳ�Ա����״̬�ı�
	MSG_SYS                               = 18, -- ϵͳ��Ϣ
	SYS_MSG_UI_OME_SKILL_CAST_LOG         = 19, -- ����ʩ����־
	SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG = 20, -- ����ʩ�Ž����־
	SYS_MSG_UI_OME_SKILL_EFFECT_LOG       = 21, -- �������ղ�����Ч��������ֵ�ı仯��
	SYS_MSG_UI_OME_SKILL_BLOCK_LOG        = 22, -- ����־
	SYS_MSG_UI_OME_SKILL_SHIELD_LOG       = 23, -- ���ܱ�������־
	SYS_MSG_UI_OME_SKILL_MISS_LOG         = 24, -- ����δ����Ŀ����־
	SYS_MSG_UI_OME_SKILL_HIT_LOG          = 25, -- ��������Ŀ����־
	SYS_MSG_UI_OME_SKILL_DODGE_LOG        = 26, -- ���ܱ�������־
	SYS_MSG_UI_OME_COMMON_HEALTH_LOG      = 27, -- ��ͨ������־
	SYS_MSG_UI_OME_DEATH_NOTIFY           = 28, -- ������־
	TARGET_INFORMATION                    = 29, -- Ŀ��״̬��Ϣ
}

-- ��������״̬
function D.UpdateEnable()
	local bEnable = D.bReady and O.bEnable
	if bEnable then
		if X.IsInDungeonMap() then
			bEnable = O.bEnableInDungeon
		elseif X.IsInArenaMap() then
			bEnable = O.bEnableInArena
		elseif X.IsInBattlefieldMap() then
			bEnable = O.bEnableInBattleField
		else
			bEnable = O.bEnableInOtherMaps
		end
	end
	if not bEnable and LOG_ENABLE then
		D.CloseCombatLogs()
	elseif bEnable and not LOG_ENABLE and X.IsFighting() then
		D.OpenCombatLogs()
	end
	LOG_ENABLE = bEnable
	LOG_TARGET_INFORMATION_ENABLE = false
	if bEnable and O.bTargetInformation and X.IsInArenaMap() then
		LOG_TARGET_INFORMATION_ENABLE = true
	end
	LOG_TARGET_INFORMATION_THROTTLE = O.nTargetInformationThrottle
end
X.RegisterEvent('LOADING_ENDING', D.UpdateEnable)

-- ������ʷ�����б�
function D.GetHistoryFiles()
	local aFiles = {}
	local szRoot = X.FormatPath(DS_ROOT)
	for _, v in ipairs(CPath.GetFileList(szRoot)) do
		if v:find('.jcl.tsv$') then
			table.insert(aFiles, v)
		end
	end
	table.sort(aFiles, function(a, b) return a > b end)
	for k, v in ipairs(aFiles) do
		aFiles[k] = szRoot .. v
	end
	return aFiles
end

-- ������ʷ��������
function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = O.nMaxHistory + 1, #aFiles do
		CPath.DelFile(aFiles[i])
	end
end

-- ���ӵ��µ���־�ļ�
function D.OpenCombatLogs()
	D.CloseCombatLogs()
	local szRoot = X.FormatPath(DS_ROOT)
	CPath.MakeDir(szRoot)
	local szTime = X.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd-%hh-%mm-%ss')
	local szMapName = ''
	local me = X.GetClientPlayer()
	if me then
		local map = X.GetMapInfo(me.GetMapID())
		if map then
			szMapName = '-' .. map.szName
		end
		szMapName = szMapName .. '(' .. me.GetMapID().. ')'
	end
	LOG_FILE = szRoot .. szTime .. szMapName .. '.jcl.log'
	LOG_TIME = GetCurrentTime()
	LOG_CACHE = {}
	LOG_TARGET_INFO_TIME = {}
	LOG_DOODAD_INFO_TIME = {}
	LOG_TARGET_LOCATION_TIME = {}
	LOG_NAMING_COUNT = {}
	LOG_CRC = 0
	Log(LOG_FILE, '', 'clear')
end

-- �رյ���־�ļ�������
function D.CloseCombatLogs()
	if not LOG_FILE then
		return
	end
	D.FlushLogs(true)
	Log(LOG_FILE, '', 'close')
	if GetCurrentTime() - LOG_TIME < O.nMinFightTime then
		CPath.DelFile(LOG_FILE)
	else
		local szName, nCount = '', 0
		for _, p in pairs(LOG_NAMING_COUNT) do
			if p.nCount > nCount then
				nCount = p.nCount
				szName = '-' .. p.szName .. '(' .. p.dwTemplateID .. ')'
			end
		end
		CPath.Move(LOG_FILE, X.StringSubW(LOG_FILE, 1, -9) .. szName .. '.jcl')
	end
	LOG_FILE = nil
end
X.RegisterReload('MY_CombatLogs', D.CloseCombatLogs)

-- ����������д�����
function D.FlushLogs(bForce)
	if not LOG_FILE then
		return
	end
	if not bForce and #LOG_CACHE < LOG_CACHE_LIMIT then
		return
	end
	for _, v in ipairs(LOG_CACHE) do
		Log(LOG_FILE, v)
	end
	LOG_CACHE = {}
end

-- �����¼�����
function D.InsertLog(szEvent, oData, bReplay)
	if not LOG_ENABLE then
		return
	end
	assert(szEvent, 'error: missing event id')
	-- ������־��
	local nLFC = GetLogicFrameCount()
	local szLog = nLFC
		.. '\t' .. GetCurrentTime()
		.. '\t' .. GetTime()
		.. '\t' .. szEvent
		.. '\t' .. X.StringReplaceW(X.StringReplaceW(X.EncodeLUAData(oData), '\\\n', '\\n'), '\t', '\\t')
	local nCRC = GetStringCRC(LOG_CRC .. szLog .. X.SECRET['HASH::MY_COMBAT_JCL'])
	-- ���뻺��
	table.insert(LOG_CACHE, nCRC .. '\t' .. szLog .. '\n')
	-- ��������¼���
	if bReplay ~= false then
		while LOG_REPLAY[1] and nLFC - LOG_REPLAY[1].nLFC > LOG_REPLAY_FRAME do
			table.remove(LOG_REPLAY, 1)
		end
		table.insert(LOG_REPLAY, { nLFC = nLFC, szLog = szLog })
	end
	-- ������ʽУ����
	LOG_CRC = nCRC
	-- ������ݴ���
	D.FlushLogs()
end

-- �ط�����¼�
function D.ImportRecentLogs()
	-- �������¼�����뻺��
	local nLFC, nCRC = GetLogicFrameCount(), LOG_CRC
	for _, v in ipairs(LOG_REPLAY) do
		if nLFC - v.nLFC <= LOG_REPLAY_FRAME then
			nCRC = GetStringCRC(nCRC .. v.szLog .. X.SECRET['HASH::MY_COMBAT_JCL'])
			table.insert(LOG_CACHE, nCRC .. '\t' .. v.szLog .. '\n')
		end
	end
	-- ������ʽУ����
	LOG_CRC = nCRC
	-- ������ݴ���
	D.FlushLogs()
end

-- ��ͼ�����ǰս������
X.RegisterEvent({ 'LOADING_ENDING', 'RELOAD_UI_ADDON_END', 'BATTLE_FIELD_END', 'ARENA_END', 'MY_CLIENT_PLAYER_LEAVE_SCENE' }, function()
	D.FlushLogs(true)
end)

-- �˳�ս�� ��������
X.RegisterEvent('MY_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local bFighting, szUUID, nDuring = arg0, arg1, arg2
	local dwMapID = X.GetMapID()
	if not bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring, dwMapID })
	end
	if bFighting then -- �����µ�ս��
		D.OpenCombatLogs()
		D.ImportRecentLogs()
	else
		D.CloseCombatLogs()
	end
	if bFighting then
		D.InsertLog(LOG_TYPE.FIGHT_TIME, { bFighting, szUUID, nDuring, dwMapID })
	end
end)

function D.WillRecID(dwID)
	if not D.bReady then
		return false
	end
	if not O.bNearbyAll then
		if not X.IsPlayer(dwID) then
			local npc = X.GetNpc(dwID)
			if npc then
				dwID = npc.dwEmployer
			end
		end
		return dwID == X.GetClientPlayerID()
	end
	return true
end

-- ����Ŀ����Ϣ
function D.OnTargetUpdate(dwID, bForce)
	if not X.IsNumber(dwID) then
		return
	end
	local bIsPlayer = X.IsPlayer(dwID)
	if bIsPlayer and not X.IsParty(dwID) and not X.IsInArenaMap() and not X.IsInBattlefieldMap() then
		return
	end
	if not bIsPlayer then
		if not LOG_NAMING_COUNT[dwID] then
			LOG_NAMING_COUNT[dwID] = {
				nCount = 0,
				szName = '',
			}
		end
		LOG_NAMING_COUNT[dwID].nCount = LOG_NAMING_COUNT[dwID].nCount + 1
	end
	if not bForce and LOG_TARGET_INFO_TIME[dwID] and GetTime() - LOG_TARGET_INFO_TIME[dwID] < LOG_TARGET_INFO_TIME_LIMIT then
		D.OnTargetInformationUpdate(bIsPlayer and TARGET.PLAYER or TARGET.NPC, dwID)
		return
	end
	if bIsPlayer then
		local player = X.GetPlayer(dwID)
		if not player then
			return
		end
		local szName = player.szName
		local dwForceID = player.dwForceID
		local dwMountKungfuID = -1
		if dwID == X.GetClientPlayerID() then
			dwMountKungfuID = UI_GetPlayerMountKungfuID()
		else
			local info = GetClientTeam().GetMemberInfo(dwID)
			if info and not X.IsEmpty(info.dwMountKungfuID) then
				dwMountKungfuID = info.dwMountKungfuID
			else
				local kungfu = player.GetKungfuMount()
				if kungfu then
					dwMountKungfuID = kungfu.dwSkillID
				end
			end
		end
		local szGUID = X.GetPlayerGUID(dwID) or ''
		local aEquip, nEquipScore, aTalent, tZhenPai
		local function OnGet()
			D.InsertLog(LOG_TYPE.PLAYER_INFO, { dwID, szName, dwForceID, dwMountKungfuID, nEquipScore, aEquip, aTalent, szGUID, tZhenPai })
		end
		X.GetPlayerEquipScore(dwID, function(nScore)
			nEquipScore = nScore
			OnGet()
		end)
		X.GetPlayerEquipInfo(dwID, function(tEquip)
			aEquip = {}
			for nEquipIndex, tEquipInfo in pairs(tEquip) do
				table.insert(aEquip, {
					nEquipIndex,
					tEquipInfo.dwTabType,
					tEquipInfo.dwTabIndex,
					tEquipInfo.nStrengthLevel,
					tEquipInfo.aSlotItem,
					tEquipInfo.dwPermanentEnchantID,
					tEquipInfo.dwTemporaryEnchantID,
					tEquipInfo.dwTemporaryEnchantLeftSeconds,
				})
			end
			OnGet()
		end)
		X.GetPlayerTalentInfo(dwID, function(a)
			aTalent = {}
			for i, p in ipairs(a) do
				aTalent[i] = {
					p.nIndex,
					p.dwSkillID,
					p.dwSkillLevel,
				}
			end
			OnGet()
		end)
		X.GetPlayerZhenPaiInfo(dwID, function(a)
			tZhenPai = {}
			for k, p in pairs(a) do
				if p ~= 0 then
					tZhenPai[k] = p
				end
			end
			OnGet()
		end)
		D.OnTargetInformationUpdate(TARGET.PLAYER, dwID)
	else
		local npc = X.GetNpc(dwID)
		if not npc then
			return
		end
		local szName = X.GetObjectName(npc, 'never') or ''
		LOG_NAMING_COUNT[dwID].szName = szName
		LOG_NAMING_COUNT[dwID].dwTemplateID = npc.dwTemplateID
		D.InsertLog(LOG_TYPE.NPC_INFO, { dwID, szName, npc.dwTemplateID, npc.dwEmployer, npc.nX, npc.nY, npc.nZ, npc.nFaceDirection })
	end
	LOG_TARGET_INFO_TIME[dwID] = GetTime()
end

-- ���潻�������Ϣ
function D.OnDoodadUpdate(dwID, bForce)
	if not bForce and LOG_DOODAD_INFO_TIME[dwID] and GetTime() - LOG_DOODAD_INFO_TIME[dwID] < LOG_DOODAD_INFO_TIME_LIMIT then
		return
	end
	local doodad = X.GetDoodad(dwID)
	if not doodad then
		return
	end
	D.InsertLog(LOG_TYPE.DOODAD_INFO, { dwID, doodad.dwTemplateID, doodad.nX, doodad.nY, doodad.nZ, doodad.nFaceDirection })
	LOG_DOODAD_INFO_TIME[dwID] = GetTime()
end

function D.OnTargetInformationUpdate(dwType, dwID)
	if not LOG_TARGET_INFORMATION_ENABLE then
		return
	end
	if LOG_TARGET_LOCATION_TIME[dwID] and GetTime() - LOG_TARGET_LOCATION_TIME[dwID] < LOG_TARGET_INFORMATION_THROTTLE then
		return
	end
	local tar
	if dwType == TARGET.PLAYER then
		tar = X.GetPlayer(dwID)
	elseif dwType == TARGET.NPC then
		tar = X.GetNpc(dwID)
	elseif dwType == TARGET.DOODAD then
		tar = X.GetDoodad(dwID)
	end
	if tar then
		local nLife, nMaxLife = X.GetObjectLife(tar)
		local nMana, nMaxMana = X.GetObjectMana(tar)
		local nDamageAbsorbValue = tar.nDamageAbsorbValue
		D.InsertLog(LOG_TYPE.TARGET_INFORMATION, {
			dwType, dwID,
			tar.nX, tar.nY, tar.nZ, tar.nFaceDirection,
			nLife, nMaxLife, nMana, nMaxMana, nDamageAbsorbValue,
		})
	end
	LOG_TARGET_LOCATION_TIME[dwID] = GetTime() -- ���� doodad �� player �� id ��ͻ��Ϊ�����ܣ�һ��Ҳ�����ͻ
end

-- ϵͳ��־��أ�����Դ��
X.RegisterEvent('SYS_MSG', function()
	if not LOG_ENABLE then
		return
	end
	if arg0 == 'UI_OME_SKILL_CAST_LOG' then
		-- ����ʩ����־��
		-- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID (arg3)dwLevel�����ܵȼ�
		-- D.OnSkillCast(arg1, arg2, arg3)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_LOG, { arg1, arg2, arg3 })
		end
	elseif arg0 == 'UI_OME_SKILL_CAST_RESPOND_LOG' then
		-- ����ʩ�Ž����־��
		-- (arg1)dwCaster������ʩ���� (arg2)dwSkillID������ID
		-- (arg3)dwLevel�����ܵȼ� (arg4)nRespond����ö����[[SKILL_RESULT_CODE]]
		-- D.OnSkillCastRespond(arg1, arg2, arg3, arg4)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_CAST_RESPOND_LOG, { arg1, arg2, arg3, arg4 })
		end
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
		-- if not X.IsInArenaMap() then
		-- �������ղ�����Ч��������ֵ�ı仯����
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)bReact���Ƿ�Ϊ���� (arg4)nType��Effect���� (arg5)dwID:Effect��ID
		-- (arg6)dwLevel��Effect�ĵȼ� (arg7)bCriticalStrike���Ƿ���� (arg8)nCount��tResultCount���ݱ���Ԫ�ظ��� (arg9)tResultCount����ֵ����
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_EFFECT_LOG, { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 })
		end
	elseif arg0 == 'UI_OME_SKILL_BLOCK_LOG' then
		-- ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)nType��Effect������
		-- (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ� (arg6)nDamageType���˺����ͣ���ö����[[SKILL_RESULT_TYPE]]
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_BLOCK_LOG, { arg1, arg2, arg3, arg4, arg5, arg6 })
		end
	elseif arg0 == 'UI_OME_SKILL_SHIELD_LOG' then
		-- ���ܱ�������־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_SHIELD_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_MISS_LOG' then
		-- ����δ����Ŀ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_MISS_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_HIT_LOG' then
		-- ��������Ŀ����־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_HIT_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_SKILL_DODGE_LOG' then
		-- ���ܱ�������־��
		-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ��
		-- (arg3)nType��Effect������ (arg4)dwID��Effect��ID (arg5)dwLevel��Effect�ĵȼ�
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_SKILL_DODGE_LOG, { arg1, arg2, arg3, arg4, arg5 })
		end
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		-- ��ͨ������־��
		-- (arg1)dwCharacterID���������ID (arg2)nDeltaLife������Ѫ��ֵ
		-- D.OnCommonHealth(arg1, arg2)
		if D.WillRecID(arg1) then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_COMMON_HEALTH_LOG, { arg1, arg2 })
		end
	elseif arg0 == 'UI_OME_DEATH_NOTIFY' then
		-- ������־��
		-- (arg1)dwCharacterID������Ŀ��ID (arg2)dwKiller����ɱ��ID
		if D.WillRecID(arg1) or D.WillRecID(arg2) then
			D.OnTargetUpdate(arg1)
			D.OnTargetUpdate(arg2)
			D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { arg1, arg2 })
		end
	end
end)

-- ϵͳBUFF��أ�����Դ��
X.RegisterEvent('BUFF_UPDATE', function()
	-- local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
	--     = arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
	if not LOG_ENABLE then
		return
	end
	-- buff update��
	-- arg0��dwPlayerID��arg1��bDelete��arg2��nIndex��arg3��bCanCancel
	-- arg4��dwBuffID��arg5��nStackNum��arg6��nEndFrame��arg7����update all?
	-- arg8��nLevel��arg9��dwSkillSrcID
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.BUFF_UPDATE, { arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 })
	end
end)

X.RegisterEvent('PLAYER_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_ENTER_SCENE, { arg0 })
	end
end)

X.RegisterEvent('PLAYER_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.PLAYER_LEAVE_SCENE, { arg0 })
	end
end)

X.RegisterEvent('NPC_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_ENTER_SCENE, { arg0 })
	end
end)

X.RegisterEvent('NPC_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	if D.WillRecID(arg0) then
		D.OnTargetUpdate(arg0)
		D.InsertLog(LOG_TYPE.NPC_LEAVE_SCENE, { arg0 })
	end
end)

X.RegisterEvent('DOODAD_ENTER_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_ENTER_SCENE, { arg0 })
end)

X.RegisterEvent('DOODAD_LEAVE_SCENE', function()
	if not LOG_ENABLE then
		return
	end
	D.OnDoodadUpdate(arg0)
	D.InsertLog(LOG_TYPE.DOODAD_LEAVE_SCENE, { arg0 })
end)

-- ϵͳ��Ϣ��־
X.RegisterMsgMonitor('MSG_SYS', 'MY_Recount_DS_Everything', function(szChannel, szMsg, nFont, bRich)
	if not LOG_ENABLE then
		return
	end
	local szText = szMsg
	if bRich then
		if X.ContainsEchoMsgHeader(szMsg) then
			return
		end
		szText = X.GetPureText(szMsg)
	end
	szText = szText:gsub('\r', '')
	D.InsertLog(LOG_TYPE.MSG_SYS, { szText, szChannel })
end)

-- ��ɫ������־
X.RegisterEvent('PLAYER_SAY', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szContent, arg1: dwTalkerID, arg2: nChannel, arg3: szName, arg4: bOnlyShowBallon
	-- arg5: bSecurity, arg6: bGMAccount, arg7: bCheater, arg8: dwTitleID, arg9: szMsg
	if not X.IsPlayer(arg1) and D.WillRecID(arg1) then
		local szText = X.GetPureText(arg0)
		if szText and szText ~= '' then
			D.OnTargetUpdate(arg1)
			D.InsertLog(LOG_TYPE.PLAYER_SAY, { szText, arg1, arg2, arg3 })
		end
	end
end)

-- ϵͳ�������־
X.RegisterEvent('ON_WARNING_MESSAGE', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: szWarningType, arg1: szText
	D.InsertLog(LOG_TYPE.ON_WARNING_MESSAGE, { arg0, arg1 })
end)

-- ��ҽ����˳�ս����־
X.RegisterEvent('MY_PLAYER_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = X.GetObject(TARGET.PLAYER, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = X.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.PLAYER_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- NPC �����˳�ս����־
X.RegisterEvent('MY_NPC_FIGHT_HINT', function()
	if not LOG_ENABLE then
		return
	end
	local dwID, bFight = arg0, arg1
	if not D.WillRecID(dwID) then
		return
	end
	local KObject = X.GetObject(TARGET.NPC, dwID)
	local fCurrentLife, fMaxLife, nCurrentMana, nMaxMana = -1, -1, -1, -1
	if KObject then
		fCurrentLife, fMaxLife = X.GetObjectLife(KObject)
		nCurrentMana, nMaxMana = KObject.nCurrentMana, KObject.nMaxMana
	end
	D.OnTargetUpdate(dwID, true)
	D.InsertLog(LOG_TYPE.NPC_FIGHT_HINT, { dwID, bFight, fCurrentLife, fMaxLife, nCurrentMana, nMaxMana })
end)

-- ����������־
X.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nOnlineFlag
	if not D.WillRecID(arg1) then
		return
	end
	D.OnTargetUpdate(arg1)
	D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { arg0, arg1, arg2 })
end)

-- ����ս�������¼
X.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function() -- ��սɨ����� ��¼��ս������/���ߵ���
	if not LOG_ENABLE then
		return
	end
	local team = GetClientTeam()
	local me = X.GetClientPlayer()
	if not team or not me or (not me.IsInParty() and not me.IsInRaid()) then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwID)
		if info and D.WillRecID(dwID) then
			D.OnTargetUpdate(dwID)
			if not info.bIsOnLine then
				D.InsertLog(LOG_TYPE.PARTY_SET_MEMBER_ONLINE_FLAG, { team.dwTeamID, dwID, 0 })
			elseif info.bDeathFlag then
				D.InsertLog(LOG_TYPE.SYS_MSG_UI_OME_DEATH_NOTIFY, { dwID, nil })
			end
		end
	end
end)

-- ��;���˽��� ���������¼
X.RegisterEvent('PARTY_ADD_MEMBER', function()
	if not LOG_ENABLE then
		return
	end
	-- arg0: dwTeamID, arg1: dwMemberID, arg2: nGroupIndex
	if D.WillRecID(arg1) then
		D.OnTargetUpdate(arg1)
		D.InsertLog(LOG_TYPE.PARTY_ADD_MEMBER, { arg0, arg1, arg2 })
	end
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['MY_CombatLogs'],
		checked = MY_CombatLogs.bEnable,
		onCheck = function(bChecked)
			MY_CombatLogs.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 25, h = 25,
		buttonStyle = 'OPTION',
		autoEnable = function() return MY_CombatLogs.bEnable end,
		menu = function()
			local menu = {}
			table.insert(menu, {
				szOption = _L['Enable in dungeon'],
				bCheck = true,
				bChecked = MY_CombatLogs.bEnableInDungeon,
				fnAction = function()
					MY_CombatLogs.bEnableInDungeon = not MY_CombatLogs.bEnableInDungeon
				end,
			})
			table.insert(menu, {
				szOption = _L['Enable in arena'],
				bCheck = true,
				bChecked = MY_CombatLogs.bEnableInArena,
				fnAction = function()
					MY_CombatLogs.bEnableInArena = not MY_CombatLogs.bEnableInArena
				end,
			})
			table.insert(menu, {
				szOption = _L['Enable in battlefield'],
				bCheck = true,
				bChecked = MY_CombatLogs.bEnableInBattleField,
				fnAction = function()
					MY_CombatLogs.bEnableInBattleField = not MY_CombatLogs.bEnableInBattleField
				end,
			})
			table.insert(menu, {
				szOption = _L['Enable in other maps'],
				bCheck = true,
				bChecked = MY_CombatLogs.bEnableInOtherMaps,
				fnAction = function()
					MY_CombatLogs.bEnableInOtherMaps = not MY_CombatLogs.bEnableInOtherMaps
				end,
			})
			table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			table.insert(menu, {
				szOption = _L['Save all nearby records'],
				bCheck = true,
				bChecked = MY_CombatLogs.bNearbyAll,
				fnAction = function()
					MY_CombatLogs.bNearbyAll = not MY_CombatLogs.bNearbyAll
				end,
				fnMouseEnter = function()
					local nX, nY = this:GetAbsX(), this:GetAbsY()
					local nW, nH = this:GetW(), this:GetH()
					OutputTip(GetFormatText(_L['Check to save all nearby records, otherwise only save records related to me'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
				end,
				fnMouseLeave = function()
					HideTip()
				end,
			})
			table.insert(menu, {
				szOption = _L['PVP mode'],
				bCheck = true,
				bChecked = MY_CombatLogs.bTargetInformation,
				fnAction = function()
					MY_CombatLogs.bTargetInformation = not MY_CombatLogs.bTargetInformation
				end,
				fnMouseEnter = function()
					local nX, nY = this:GetAbsX(), this:GetAbsY()
					local nW, nH = this:GetW(), this:GetH()
					OutputTip(GetFormatText(_L['Save target information on event\n(Only in arena)'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.TOP_BOTTOM)
				end,
				fnMouseLeave = function()
					HideTip()
				end,
			})
			table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			local m0 = { szOption = _L['Max history'] }
			for _, i in ipairs({10, 20, 30, 50, 100, 200, 300, 500, 1000, 2000, 5000}) do
				table.insert(m0, {
					szOption = tostring(i),
					fnAction = function()
						MY_CombatLogs.nMaxHistory = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMaxHistory == i,
				})
			end
			table.insert(menu, m0)
			local m0 = { szOption = _L['Min fight time'] }
			for _, i in ipairs({10, 20, 30, 60, 90, 120, 180, 240}) do
				table.insert(m0, {
					szOption = _L('%s second(s)', i),
					fnAction = function()
						MY_CombatLogs.nMinFightTime = i
					end,
					bCheck = true,
					bMCheck = true,
					bChecked = MY_CombatLogs.nMinFightTime == i,
				})
			end
			table.insert(menu, m0)
			table.insert(menu, {
				szOption = _L['Show data files'],
				fnAction = function()
					local szRoot = X.GetAbsolutePath(DS_ROOT)
					X.OpenFolder(szRoot)
					X.UI.OpenTextEditor(szRoot)
				end,
			})
			return menu
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_CombatLogs',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nMaxHistory',
				'nMinFightTime',
				'bEnableInDungeon',
				'bEnableInArena',
				'bEnableInBattleField',
				'bEnableInOtherMaps',
				'bNearbyAll',
				'bTargetInformation',
				'nTargetInformationThrottle',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nMaxHistory',
				'nMinFightTime',
				'bEnableInDungeon',
				'bEnableInArena',
				'bEnableInBattleField',
				'bEnableInOtherMaps',
				'bNearbyAll',
				'bTargetInformation',
				'nTargetInformationThrottle',
			},
			triggers = {
				bEnable                    = D.UpdateEnable,
				bEnableInDungeon           = D.UpdateEnable,
				bEnableInArena             = D.UpdateEnable,
				bEnableInBattleField       = D.UpdateEnable,
				bEnableInOtherMaps         = D.UpdateEnable,
				bNearbyAll                 = D.UpdateEnable,
				bTargetInformation         = D.UpdateEnable,
				nTargetInformationThrottle = D.UpdateEnable,
			},
			root = O,
		},
	},
}
MY_CombatLogs = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_CombatLogs', function()
	D.bReady = true
	D.UpdateEnable()
end)

X.RegisterUserSettingsRelease('MY_CombatLogs', function()
	D.bReady = false
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
