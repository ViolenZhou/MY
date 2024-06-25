--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸͨ�ú���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------

-- Lua �������л�
---@overload fun(data: any, indent: string, level: number): string
---@param data any @Ҫ���л�������
---@param indent string @�����ַ���
---@param level number @��ǰ�㼶
---@return string @���л�����ַ���
X.EncodeLUAData = _G.var2str

-- Lua ���ݷ����л�
---@overload fun(data: string): any
---@param data string @Ҫ�����л����ַ���
---@return any @�����л��������
X.DecodeLUAData = _G.str2var or function(szText)
	local DECODE_ROOT = X.PACKET_INFO.DATA_ROOT .. '#cache/decode/'
	local DECODE_PATH = DECODE_ROOT .. GetCurrentTime() .. GetTime() .. X.Random(1000000000, 9999999999) .. '.jx3dat'
	CPath.MakeDir(DECODE_ROOT)
	SaveDataToFile(szText, DECODE_PATH)
	local data = LoadLUAData(DECODE_PATH)
	CPath.DelFile(DECODE_PATH)
	return data
end

-- ��ȡ��Ϸ�ӿ�
---@param szAddon string @�ӿڵ�������
---@param szInside string @�ӿ�ԭʼ����
---@return any @�ӿڶ���
function X.GetGameAPI(szAddon, szInside)
	local api = _G[szAddon]
	if not api and X.PACKET_INFO.DEBUG_LEVEL < X.DEBUG_LEVEL.NONE then
		local env = GetInsideEnv()
		if env then
			api = env[szInside or szAddon]
		end
	end
	return api
end

-- ��ȡ��Ϸ���ݱ�
---@param szTable string @���ݱ�����
---@param bPrintError boolean @�Ƿ��ӡ������Ϣ
---@return any @���ݱ����
function X.GetGameTable(szTable, bPrintError)
	local b, t = (bPrintError and X.Call or pcall)(function() return g_tTable[szTable] end)
	if b then
		return t
	end
end

-- ��ȡ��ǰ��������
---@return string @��������
function X.GetRegionName()
	local szRegionDisplayName, _, szRegionName, _ = GetUserServer()
	return szRegionName or szRegionDisplayName
end

-- ��ȡ��ǰ����������
---@return string @����������
function X.GetServerName()
	local _, szServerDisplayName, _, szServerName = GetUserServer()
	return szServerName or szServerDisplayName
end

-- ��ȡ���ݻ�ͨ����������
---@return string @���ݻ�ͨ����������
function X.GetRegionOriginName()
	local szRegionDisplayName, _, _, _, szRegionOriginName, _ = GetUserServer()
	return szRegionOriginName or szRegionDisplayName
end

-- ��ȡ���ݻ�ͨ������������
---@return string @���ݻ�ͨ������������
function X.GetServerOriginName()
	local _, szServerDisplayName, _, _, _, szServerOriginName = GetUserServer()
	return szServerOriginName or szServerDisplayName
end

-- ��ȡ������ID
---@return number @������ID
function X.GetServerID()
	if not GetCenterID then
		return 0
	end
	return GetCenterID() or 0
end

-- ͨ�����������ID��ȡ����������
---@param dwServerID number @������ID
---@return string|nil @���������ƣ��������򷵻ؿ�
function X.GetServerNameByID(dwServerID)
	if not GetCenterNameByCenterID then
		return
	end
	return GetCenterNameByCenterID(dwServerID)
end

-- ��ȡ ID �Ƿ�Ϊ��ң������� NPC��
---@param dwID number @ID
---@return boolean @�Ƿ�Ϊ���
function X.IsPlayer(dwID)
	return IsPlayer(dwID)
end

-- ��ȡ������Ҷ���
---@return userdata | nil @������Ҷ��󣬻�ȡʧ�ܷ��ؿ�
function X.GetClientPlayer()
	return GetClientPlayer()
end

-- ��ȡ��¼��ɫID
---@return number @��¼��ɫID
function X.GetClientPlayerID()
	return UI_GetClientPlayerID()
end

-- ��ȡ��ǰ���ƽ�ɫ����
---@return userdata | nil @��ǰ���ƽ�ɫ���󣬻�ȡʧ�ܷ��ؿ�
function X.GetControlPlayer()
	return GetControlPlayer()
end

-- ��ȡ��ǰ���ƽ�ɫID���磺ƽɳ����Ŀ��ID��
---@return number @��ǰ���ƽ�ɫID
function X.GetControlPlayerID()
	return GetControlPlayerID()
end

-- ��ȡ��Ҷ���
---@param dwID number @���ID
---@return userdata | nil @��Ҷ��󣬻�ȡʧ�ܷ��ؿ�
function X.GetPlayer(dwID)
	if dwID == X.GetClientPlayerID() then
		return X.GetClientPlayer()
	end
	return GetPlayer(dwID)
end

-- ��ȡ NPC ����
---@param dwID number @NPC ID
---@return userdata | nil @NPC ���󣬻�ȡʧ�ܷ��ؿ�
function X.GetNpc(dwID)
	return GetNpc(dwID)
end

-- ��ȡ�����������
---@param dwID number @�������ID
---@return userdata | nil @����������󣬻�ȡʧ�ܷ��ؿ�
function X.GetDoodad(dwID)
	return GetDoodad(dwID)
end

local CLIENT_PLAYER_GLOBAL_ID
function X.GetClientPlayerGlobalID()
	if not CLIENT_PLAYER_GLOBAL_ID then
		local szUID = GetClientPlayerGlobalID and GetClientPlayerGlobalID()
		if X.IsEmpty(szUID) or szUID == '0' then
			szUID = nil
		end
		if not szUID then
			local me = X.GetClientPlayer()
			if me then
				szUID = me.GetGlobalID()
				if szUID == '0' then
					szUID = '0' .. GetStringCRC(X.GetRegionOriginName()) .. GetStringCRC(X.GetServerOriginName()) .. me.dwID
				end
			end
		end
		if X.IsEmpty(szUID) or szUID == '0' then
			szUID = nil
		end
		CLIENT_PLAYER_GLOBAL_ID = szUID
	end
	return CLIENT_PLAYER_GLOBAL_ID
end

-- ��ȡ���ѿ�Ƭ����������
---@return userdata | nil @���ѿ�Ƭ���������󣬻�ȡʧ�ܷ��ؿ�
function X.GetFellowshipCardClient()
	return GetFellowshipCardClient and GetFellowshipCardClient()
end

-- ��ȡ�罻����������
---@return userdata | nil @�罻���������󣬻�ȡʧ�ܷ��ؿ�
function X.GetSocialManagerClient()
	return GetSocialManagerClient and GetSocialManagerClient()
end

local LOG_MAX_FILE = 30
local LOG_MAX_LINE = 5000
local LOG_LINE_COUNT = 0
local LOG_CACHE
local LOG_PATH, LOG_DATE
local LOG_TAG = (GetCurrentTime() + 8 * 60 * 60) % (24 * 60 * 60)

-- ���һ����־����־�ļ�
---@vararg string ��־����㼶1, ��־����㼶2, ��־����㼶3, ..., ��־����㼶n, ��־����
function X.Log(...)
	local nType = select('#', ...) - 1
	local szText = select(nType + 1, ...)
	local tTime = TimeToDate(GetCurrentTime())
	local szDate = string.format('%04d-%02d-%02d', tTime.year, tTime.month, tTime.day)
	local szType = ''
	for i = 1, nType do
		szType = szType .. '[' .. select(i, ...) .. ']'
	end
	if szType ~= '' then
		szType = szType .. ' '
	end
	local szLog = string.format('%04d/%02d/%02d_%02d:%02d:%02d %s%s\n', tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second, szType, szText)
	if LOG_DATE ~= szDate or LOG_LINE_COUNT >= LOG_MAX_LINE then
		-- ϵͳδ��ʼ����ɣ����뻺������ȴ�д��
		if not X.FormatPath or not X.GetClientPlayerGlobalID or not X.GetClientPlayerGlobalID() then
			if not LOG_CACHE then
				LOG_CACHE = {}
			end
			table.insert(LOG_CACHE, szLog)
			return
		end
		if LOG_PATH then
			Log(LOG_PATH, '', 'close')
		end
		LOG_PATH = X.FormatPath({
			'logs/'
				.. szDate .. '/JX3_'
				.. X.PACKET_INFO.NAME_SPACE
				.. '_' .. X.ENVIRONMENT.GAME_PROVIDER
				.. '_' .. X.ENVIRONMENT.GAME_EDITION
				.. '_' .. X.ENVIRONMENT.GAME_VERSION
				.. '_' .. LOG_TAG
				.. '_' .. string.format('%04d-%02d-%02d_%02d-%02d-%02d', tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
				.. '.log',
			X.PATH_TYPE.ROLE
		})
		LOG_DATE = szDate
		LOG_LINE_COUNT = 0
	end
	-- ������ڻ������ݣ��ȴ���
	if LOG_CACHE then
		for _, szLog in ipairs(LOG_CACHE) do
			Log(LOG_PATH, szLog)
			LOG_LINE_COUNT = LOG_LINE_COUNT + 1
		end
		LOG_CACHE = nil
	end
	LOG_LINE_COUNT = LOG_LINE_COUNT + 1
	Log(LOG_PATH, szLog, 'close')
end

-- ������־�ļ�
function X.DeleteAncientLogs()
	local szRoot = X.FormatPath({'logs/', X.PATH_TYPE.ROLE})
	local aFiles = {}
	for _, filename in ipairs(CPath.GetFileList(szRoot)) do
		local year, month, day = filename:match('^(%d+)%-(%d+)%-(%d+)$')
		if year then
			year = tonumber(year)
			month = tonumber(month)
			day = tonumber(day)
			table.insert(aFiles, { time = DateToTime(year, month, day, 0, 0, 0), filepath = szRoot .. filename })
		end
	end
	if #aFiles <= LOG_MAX_FILE then
		return
	end
	table.sort(aFiles, function(a, b)
		return a.time > b.time
	end)
	for i = LOG_MAX_FILE + 1, #aFiles do
		CPath.DelDir(aFiles[i].filepath)
	end
end

-- ����һ�������ջ��־�������¼�
---@vararg string @������Ϣ���ı�
---@return void
function X.ErrorLog(...)
	local aLine, xLine = {}, nil
	for i = 1, select('#', ...) do
		xLine = select(i, ...)
		aLine[i] = tostring(xLine)
	end
	local szFull = table.concat(aLine, '\n') .. '\n'
	FireUIEvent('CALL_LUA_ERROR', szFull)
end

-- �ռ����ܺ�ʱ���
---@param aRank table @ͳ�����ݼ�
---@param szID string @��ǰ�ɼ���ģ������
---@param nTime number @��ǰ�ɼ���ģ���ʱ
---@return void
function X.CollectUsageRank(aRank, szID, nTime)
	--[[#DEBUG BEGIN]]
	table.insert(aRank, { szID = szID, nTime = nTime })
	--[[#DEBUG END]]
end

-- ������ܺ�ʱ���ͳ��
---@param szHeader string @���ͳ�Ʊ���
---@param aRank table @ͳ�����ݼ�
---@return void
function X.ReportUsageRank(szHeader, aRank)
	--[[#DEBUG BEGIN]]
	-- �ܺ�ͳ��
	local nTotalTime = 0
	for _, rank in ipairs(aRank) do
		nTotalTime = nTotalTime + rank.nTime
	end
	X.Log(szHeader, 'All ' .. #aRank .. ' tasks finished in ' .. nTotalTime .. 'ms.')
	-- ����ͳ��
	table.sort(aRank, function(a, b) return a.nTime > b.nTime end)
	local aTop, nMaxID = {}, 0
	for i, p in ipairs(aRank) do
		if i > 10 or p.nTime < 5 then
			break
		end
		nMaxID = math.max(nMaxID, p.szID:len())
		table.insert(aTop, p)
	end
	if #aTop > 0 then
		X.Log(szHeader, 'Top ' .. #aTop ..  ' loading time:')
	end
	local nTopTime = 0
	for i, p in ipairs(aTop) do
		nTopTime = nTopTime + p.nTime
		X.Log(szHeader, string.format('%d. %' .. nMaxID .. 's: %dms', i, p.szID, p.nTime))
	end
	X.Log(szHeader, string.format('Top modules total loading time: %dms', nTopTime))
	-- �������
	for i = #aRank, 1, -1 do
		aRank[i] = nil
	end
	--[[#DEBUG END]]
end

--[[#DEBUG BEGIN]]
local MODULE_TIME = {}
local MODULE_TIME_USAGE = {}
RegisterEvent('LOADING_END', function()
	for szModule, _ in pairs(MODULE_TIME) do
		X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" missing FINISH report!!!')
	end
	X.ReportUsageRank('MODULE_LOADING_REPORT', MODULE_TIME_USAGE)
end)
--[[#DEBUG END]]

-- �ű��������ܼ��
---@param szModule string @ģ������
---@param szStatus "'START'" | "'FINISH'" @����״̬
---@return void
function X.ReportModuleLoading(szModule, szStatus)
	--[[#DEBUG BEGIN]]
	if szStatus == 'START' then
		if MODULE_TIME[szModule] then
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" is already START!!!')
		else
			MODULE_TIME[szModule] = GetTime()
		end
	elseif szStatus == 'FINISH' then
		if MODULE_TIME[szModule] then
			local nTime = GetTime() - MODULE_TIME[szModule]
			MODULE_TIME[szModule] = nil
			X.CollectUsageRank(MODULE_TIME_USAGE, szModule, nTime)
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" loaded during ' .. nTime .. 'ms.')
		else
			X.Log('MODULE_LOADING_REPORT', '"' .. szModule .. '" not exist!!!')
		end
	end
	--[[#DEBUG END]]
end

-- ��ʼ�����Թ���
if X.PACKET_INFO.DEBUG_LEVEL < X.DEBUG_LEVEL.NONE then
	if not X.SHARED_MEMORY.ECHO_LUA_ERROR then
		RegisterEvent('CALL_LUA_ERROR', function()
			OutputMessage('MSG_SYS', GetFormatText('CALL_LUA_ERROR:\n' .. arg0 .. '\n', nil, 255, 170, 170), true)
		end)
		X.SHARED_MEMORY.ECHO_LUA_ERROR = X.PACKET_INFO.NAME_SPACE
	end
	if not X.SHARED_MEMORY.RELOAD_UI_ADDON then
		TraceButton_AppendAddonMenu({{
			szOption = 'ReloadUIAddon',
			fnAction = function()
				ReloadUIAddon()
			end,
		}})
		X.SHARED_MEMORY.RELOAD_UI_ADDON = X.PACKET_INFO.NAME_SPACE
	end
end
X.Log('[' .. X.PACKET_INFO.NAME_SPACE .. '] Debug level ' .. X.PACKET_INFO.DEBUG_LEVEL .. ' / log level ' .. X.PACKET_INFO.LOG_LEVEL)
