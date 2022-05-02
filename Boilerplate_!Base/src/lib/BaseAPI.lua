--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸͨ�ú���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
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
	local DECODE_PATH = DECODE_ROOT .. GetCurrentTime() .. GetTime() .. math.random(0, 999999) .. '.jx3dat'
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
	if not api and _DEBUG_LEVEL_ < X.DEBUG_LEVEL.NONE then
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
	X.SafeCall(X.Log, 'ERROR_LOG', szFull)
	FireUIEvent('CALL_LUA_ERROR', szFull)
end

-- ��ʼ�����Թ���
if X.PACKET_INFO.DEBUG_LEVEL < X.DEBUG_LEVEL.NONE then
	if not X.SHARED_MEMORY.ECHO_LUA_ERROR then
		RegisterEvent('CALL_LUA_ERROR', function()
			OutputMessage('MSG_SYS', 'CALL_LUA_ERROR:\n' .. arg0 .. '\n')
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
Log('[' .. X.PACKET_INFO.NAME_SPACE .. '] Debug level ' .. X.PACKET_INFO.DEBUG_LEVEL .. ' / delog level ' .. X.PACKET_INFO.DELOG_LEVEL)
