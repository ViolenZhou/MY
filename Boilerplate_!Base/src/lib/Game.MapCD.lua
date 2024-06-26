--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.MapCD')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ��ȡ�ؾ�CD�б��첽��
-- (table) X.GetMapSaveCopy(fnAction)
-- (number|nil) X.GetMapSaveCopy(dwMapID, fnAction)
do
local QUEUE = {}
local SAVED_COPY_CACHE, REQUEST_FRAME
function X.GetMapSaveCopy(arg0, arg1)
	local dwMapID, fnAction
	if X.IsFunction(arg0) then
		fnAction = arg0
	elseif X.IsNumber(arg0) then
		if X.IsFunction(arg1) then
			fnAction = arg1
		end
		dwMapID = arg0
	end
	if SAVED_COPY_CACHE then
		if dwMapID then
			if fnAction then
				fnAction(SAVED_COPY_CACHE[dwMapID])
			end
			return SAVED_COPY_CACHE[dwMapID]
		else
			if fnAction then
				fnAction(SAVED_COPY_CACHE)
			end
			return SAVED_COPY_CACHE
		end
	else
		if fnAction then
			table.insert(QUEUE, { dwMapID = dwMapID, fnAction = fnAction })
		end
		if REQUEST_FRAME ~= GetLogicFrameCount() then
			ApplyMapSaveCopy()
			REQUEST_FRAME = GetLogicFrameCount()
		end
	end
end

function X.IsDungeonResetable(dwMapID)
	if not SAVED_COPY_CACHE then
		return
	end
	if not X.IsDungeonMap(dwMapID, false) then
		return false
	end
	return SAVED_COPY_CACHE[dwMapID]
end

local function onApplyPlayerSavedCopyRespond()
	SAVED_COPY_CACHE = arg0
	for _, v in ipairs(QUEUE) do
		if v.dwMapID then
			v.fnAction(SAVED_COPY_CACHE[v.dwMapID])
		else
			v.fnAction(SAVED_COPY_CACHE)
		end
	end
	QUEUE = {}
end
X.RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND', onApplyPlayerSavedCopyRespond)

local function onCopyUpdated()
	SAVED_COPY_CACHE = nil
end
X.RegisterEvent('ON_RESET_MAP_RESPOND', onCopyUpdated)
X.RegisterEvent('ON_MAP_COPY_PROGRESS_UPDATE', onCopyUpdated)
end

-- ��ȡ�ճ��ܳ��´�ˢ��ʱ���ˢ������
-- (dwTime, dwCircle) X.GetRefreshTime(szType)
-- @param szType {string} ˢ������ daily weekly half-weekly
-- @return dwTime {number} �´�ˢ��ʱ��
-- @return dwCircle {number} ˢ������
function X.GetRefreshTime(szType)
	local nNextTime, nCircle = 0, 0
	local nTime = GetCurrentTime()
	local date = TimeToDate(nTime)
	if szType == 'daily' then -- ÿ��7��
		if date.hour < 7 then
			nNextTime = nTime + (7 - date.hour) * 3600 + (0 - date.minute) * 60 + (0 - date.second)
		else
			nNextTime = nTime + (7 + 24 - date.hour) * 3600 + (0 - date.minute) * 60 + (0 - date.second)
		end
		nCircle = 86400
	elseif szType == 'half-weekly' then -- ��һ7�� ����7��
		if ((date.weekday == 1 and date.hour >= 7) or date.weekday >= 2)
		and ((date.weekday == 5 and date.hour < 7) or date.weekday <= 4) then -- ��һ7�� - ����7��
			nNextTime = nTime + (5 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			nCircle = 345600
		else
			if date.weekday == 0 or date.weekday == 1 then -- ����0�� - ��һ7��
				nNextTime = nTime + (1 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			else -- ����7�� - ����24��
				nNextTime = nTime + (8 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
			end
			nCircle = 259200
		end
	else -- if szType == 'weekly' then -- ��һ7��
		if date.weekday == 0 or (date.weekday == 1 and date.hour < 7) then -- ����0�� - ��һ7��
			nNextTime = nTime + (1 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
		else -- ��һ7�� - ����24��
			nNextTime = nTime + (8 - date.weekday) * 86400 + (7 * 3600 - date.hour * 3600) + (0 - date.minute) * 60 + (0 - date.second)
		end
		nCircle = 604800
	end
	return nNextTime, nCircle
end

function X.IsInSameRefreshTime(szType, dwTime)
	local nNextTime, nCircle = X.GetRefreshTime(szType)
	return nNextTime > dwTime and nNextTime - dwTime <= nCircle
end

-- ��ȡ�ؾ���ͼˢ��ʱ��
-- (number nNextTime, number nCircle) X.GetDungeonRefreshTime(dwMapID)
function X.GetDungeonRefreshTime(dwMapID)
	local _, nMapType, nMaxPlayerCount = GetMapParams(dwMapID)
	if nMapType == MAP_TYPE.DUNGEON then
		if nMaxPlayerCount <= 5 then -- 5�˱�
			return X.GetRefreshTime('daily')
		end
		if nMaxPlayerCount <= 10 then -- 10�˱�
			return X.GetRefreshTime('half-weekly')
		end
		if nMaxPlayerCount <= 25 then -- 25�˱�
			return X.GetRefreshTime('weekly')
		end
	end
	return 0, 0
end

---��ȡ��ͼ�ؾ�������Ϣ
---@param dwMapID number @Ҫ��ȡ�ĵ�ͼID
---@return table @�ؾ����������״̬�б�
function X.GetMapCDProcessInfo(dwMapID)
	if GetCDProcessInfo then
		local aInfo = {}
		for _, v in ipairs(GetCDProcessInfo(dwMapID) or X.CONSTANT.EMPTY_TABLE) do
			table.insert(aInfo, {
				dwBossIndex = v.BossIndex,
				dwMapID = v.MapID,
				szName = v.Name,
				dwProgressID = v.ProgressID,
			})
		end
		return aInfo
	end
	return Table_GetCDProcessBoss(dwMapID)
end

do
local MAP_CD_PROGRESS_REQUEST_FRAME = {}
local MAP_CD_PROGRESS_UPDATE_RECEIVE = {}
local MAP_CD_PROGRESS_PENDING_ACTION = {}
---��ȡ��ɫ��ͼ�ؾ�����
---@param dwMapID number @Ҫ��ȡ�ĵ�ͼID
---@param dwPlayerID number @Ҫ��ȡ���ȵĽ�ɫID
---@param fnAction function @��ȡ�ɹ��ص�����
---@return table @��ɫ�ؾ�����״̬
function X.GetMapCDProgress(dwMapID, dwPlayerID, fnAction)
	local szKey = dwMapID .. '||' .. dwPlayerID
	local tProgress = {}
	for _, tInfo in ipairs(X.GetMapCDProcessInfo(dwMapID) or X.CONSTANT.EMPTY_TABLE) do
		tProgress[tInfo.dwProgressID] = GetDungeonRoleProgress(dwMapID, dwPlayerID, tInfo.dwProgressID)
	end
	if MAP_CD_PROGRESS_UPDATE_RECEIVE[szKey] then
		fnAction(tProgress)
	elseif MAP_CD_PROGRESS_REQUEST_FRAME[szKey] ~= GetLogicFrameCount() then
		MAP_CD_PROGRESS_REQUEST_FRAME[szKey] = GetLogicFrameCount()
		if fnAction then
			table.insert(MAP_CD_PROGRESS_PENDING_ACTION, {
				dwMapID = dwMapID, dwPlayerID = dwPlayerID, fnAction = fnAction,
			})
		end
		ApplyDungeonRoleProgress(dwMapID, dwPlayerID) -- �ɹ��ص� UPDATE_DUNGEON_ROLE_PROGRESS(dwMapID, dwPlayerID)
	end
	return tProgress
end
X.RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS', 'LIB#MapCDProgress', function()
	local dwMapID, dwPlayerID = arg0, arg1
	local aProgress = {}
	for _, tInfo in ipairs(X.GetMapCDProcessInfo(dwMapID) or X.CONSTANT.EMPTY_TABLE) do
		aProgress[tInfo.dwProgressID] = GetDungeonRoleProgress(dwMapID, dwPlayerID, tInfo.dwProgressID)
	end
	for _, v in ipairs(MAP_CD_PROGRESS_PENDING_ACTION) do
		if v.dwMapID == dwMapID and v.dwPlayerID == dwPlayerID then
			v.fnAction(aProgress)
		end
	end
	for i, v in X.ipairs_r(MAP_CD_PROGRESS_PENDING_ACTION) do
		if v.dwMapID == dwMapID and v.dwPlayerID == dwPlayerID then
			table.remove(MAP_CD_PROGRESS_PENDING_ACTION, i)
		end
	end
end)
end

---��ȡ�����ͼ�ؾ�����
---@param dwMapID number @Ҫ��ȡ�ĵ�ͼID
---@param fnAction function @��ȡ�ɹ��ص�����
---@return table @�����ؾ�����״̬
function X.GetClientPlayerMapCDProgress(dwMapID, fnAction)
	return X.GetMapCDProgress(dwMapID, X.GetClientPlayerID(), fnAction)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
