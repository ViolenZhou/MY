--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Environment')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.AssertVersion(szKey, szCaption, szRequireVersion)
	if not X.IsString(szRequireVersion) then
		X.OutputDebugMessage(
			X.PACKET_INFO.NAME_SPACE,
			_L(
				'%s requires a invalid base library version value: %s.',
				szCaption, X.EncodeLUAData(szRequireVersion)
			),
			X.DEBUG_LEVEL.ERROR)
		return IsDebugClient() or false
	end
	if not (X.Semver(X.PACKET_INFO.VERSION) % szRequireVersion) then
		X.OutputDebugMessage(
			X.PACKET_INFO.NAME_SPACE,
			_L(
				'%s requires base library version at %s, current at %s.',
				szCaption, szRequireVersion, X.PACKET_INFO.VERSION
			),
			X.DEBUG_LEVEL.ERROR)
		return IsDebugClient() or false
	end
	return true
end

-- ��ȡ�������εȼ�
do
local DELAY_EVENT = {}
local RESTRICTION = {}

-- ע�Ṧ���ڲ�ͬ��֧������״̬
-- X.RegisterRestriction('SomeFunc', { ['*'] = true, intl = false })
function X.RegisterRestriction(szKey, tBranchRestricted)
	local bRestricted = nil
	if X.IsTable(tBranchRestricted) then
		if X.IsBoolean(tBranchRestricted[X.ENVIRONMENT.GAME_BRANCH]) then
			bRestricted = tBranchRestricted[X.ENVIRONMENT.GAME_BRANCH]
		elseif X.IsBoolean(tBranchRestricted['*']) then
			bRestricted = tBranchRestricted['*']
		end
	end
	if not X.IsBoolean(bRestricted) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Restriction should be a boolean value: ' .. szKey, X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	RESTRICTION[szKey] = bRestricted
end

-- ��ȡ�����ڵ�ǰ��֧�Ƿ�������
-- X.IsRestricted('SomeFunc')
function X.IsRestricted(szKey, ...)
	if select('#', ...) == 1 then
		-- ����ֵ
		local bRestricted = ...
		if not X.IsNil(bRestricted) then
			bRestricted = not not bRestricted
		end
		if RESTRICTION[szKey] == bRestricted then
			return
		end
		RESTRICTION[szKey] = bRestricted
		-- �����¼�֪ͨ
		local szEvent = X.NSFormatString('{$NS}.RESTRICTION')
		if szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				X.DelayCall(k, false)
			end
			DELAY_EVENT = {}
			szKey = nil
		else
			szEvent = szEvent .. '.' .. szKey
		end
		X.DelayCall(szEvent, 75, function()
			if X.IsPanelOpened() then
				X.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(X.NSFormatString('{$NS}_RESTRICTION'), szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not X.IsNil(RESTRICTION['!']) then
			return RESTRICTION['!']
		end
		return RESTRICTION[szKey] or false
	end
end
end

-- ��ȡ�Ƿ���Կͻ���
-- (bool) X.IsDebugClient()
-- (bool) X.IsDebugClient(bool bManually = false)
-- (bool) X.IsDebugClient(string szKey[, bool bDebug, bool bSet])
do
local DELAY_EVENT = {}
local DEBUG = { ['*'] = X.PACKET_INFO.DEBUG_LEVEL <= X.DEBUG_LEVEL.DEBUG }
function X.IsDebugClient(szKey, bDebug, bSet)
	if not X.IsString(szKey) then
		szKey, bDebug, bSet = '*', szKey, bDebug
	end
	if bSet then
		-- ͨ�ý�ֹ��Ϊ��
		if szKey == '*' and X.IsNil(bDebug) then
			return
		end
		-- ����ֵ
		if DEBUG[szKey] == bDebug then
			return
		end
		DEBUG[szKey] = bDebug
		-- �����¼�֪ͨ
		local szEvent = X.NSFormatString('{$NS}#DEBUG')
		if szKey == '*' or szKey == '!' then
			for k, _ in pairs(DELAY_EVENT) do
				X.DelayCall(k, false)
			end
			szKey = nil
		else
			szEvent = szEvent .. '#' .. szKey
		end
		X.DelayCall(szEvent, 75, function()
			if X.IsPanelOpened() then
				X.ReopenPanel()
			end
			DELAY_EVENT[szEvent] = nil
			FireUIEvent(X.NSFormatString('{$NS}_DEBUG'), szKey)
		end)
		DELAY_EVENT[szEvent] = true
	else
		if not X.IsNil(DEBUG['!']) then
			return DEBUG['!']
		end
		if szKey == '*' and not bDebug then
			return IsDebugClient()
		end
		if not X.IsNil(DEBUG[szKey]) then
			return DEBUG[szKey]
		end
		return DEBUG['*']
	end
end
end

-- ��ȡ�Ƿ���Է�����
function X.IsDebugServer()
	local ip = X.ENVIRONMENT.SERVER_ADDRESS
	if ip:find('^10%.') -- 10.0.0.0/8
		or ip:find('^127%.') -- 127.0.0.0/8
		or ip:find('^172%.1[6-9]%.') -- 172.16.0.0/12
		or ip:find('^172%.2[0-9]%.') -- 172.16.0.0/12
		or ip:find('^172%.3[0-1]%.') -- 172.16.0.0/12
		or ip:find('^192%.168%.') -- 192.168.0.0/16
	then
		return true
	end
	return false
end

function X.IsMobileClient(nClientVersionType)
	return nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_ANDROID
		or nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_IOS
		or nClientVersionType == X.CONSTANT.CLIENT_VERSION_TYPE.MOBILE_PC
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
