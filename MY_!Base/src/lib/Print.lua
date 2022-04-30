--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local THEME_LIST = {
	-- [CONSTANT.MSG_THEME.NORMAL ] = { r = 255, g = 255, b =   0 },
	[CONSTANT.MSG_THEME.ERROR  ] = { r = 255, g =  86, b =  86 },
	[CONSTANT.MSG_THEME.WARNING] = { r = 255, g = 170, b = 170 },
	[CONSTANT.MSG_THEME.SUCCESS] = { r =   0, g = 255, b = 127 },
}

local DEBUG_THEME = {
	[X.DEBUG_LEVEL.PMLOG  ] = { r =   0, g = 255, b = 255 },
	[X.DEBUG_LEVEL.LOG    ] = { r =   0, g = 255, b = 127 },
	[X.DEBUG_LEVEL.WARNING] = { r = 255, g = 170, b = 170 },
	[X.DEBUG_LEVEL.ERROR  ] = { r = 255, g =  86, b =  86 },
}

function X.EncodeEchoMsgHeader(szChannel, oData)
	return '<text>text="" addonecho=1 channel=' .. X.XMLEncodeComponent(X.EncodeLUAData(szChannel))
		.. ' data=' .. X.XMLEncodeComponent(X.EncodeLUAData(oData)) .. ' </text>'
end

function X.ContainsEchoMsgHeader(szMsg)
	return string.find(szMsg, '<text>text="" addonecho=1 channel="', nil, true) ~= nil
end

function X.DecodeEchoMsgHeader(aXMLNode)
	if X.XMLIsNode(aXMLNode) then
		if X.XMLGetNodeData(aXMLNode, 'addonecho') then
			local szChannel = X.DecodeLUAData(X.XMLGetNodeData(aXMLNode, 'channel'))
			local oData = X.DecodeLUAData(X.XMLGetNodeData(aXMLNode, 'data'))
			return true, szChannel, oData
		end
	elseif X.IsArray(aXMLNode) then
		for _, node in ipairs(aXMLNode) do
			local bHasInfo, szChannel, oData = X.DecodeEchoMsgHeader(node)
			if bHasInfo then
				return bHasInfo, szChannel, oData
			end
		end
	end
end

local function StringifySysmsgObject(aMsg, oContent, cfg, bTitle, bEcho)
	local cfgContent = setmetatable({}, { __index = cfg })
	if X.IsTable(oContent) then
		cfgContent.rich, cfgContent.wrap = oContent.rich, oContent.wrap
		cfgContent.r, cfgContent.g, cfgContent.b, cfgContent.f = oContent.r, oContent.g, oContent.b, oContent.f
	else
		oContent = {oContent}
	end
	-- ��ʽ���������
	for _, v in ipairs(oContent) do
		local tContent, aPart = setmetatable(X.IsTable(v) and X.Clone(v) or {v}, { __index = cfgContent }), {}
		for _, oPart in ipairs(tContent) do
			table.insert(aPart, tostring(oPart))
		end
		if tContent.rich then
			table.insert(aMsg, table.concat(aPart))
		else
			local szContent = table.concat(aPart, bTitle and '][' or '')
			if szContent ~= '' and bTitle then
				szContent = '[' .. szContent .. ']'
			end
			table.insert(aMsg, GetFormatText(szContent, tContent.f, tContent.r, tContent.g, tContent.b))
		end
	end
	if cfgContent.wrap and not bTitle then
		table.insert(aMsg, GetFormatText('\n', cfgContent.f, cfgContent.r, cfgContent.g, cfgContent.b))
	end
	if bEcho then
		table.insert(aMsg, 1, X.EncodeEchoMsgHeader())
	end
end

local function OutputMessageEx(szType, eTheme, oTitle, oContent, bEcho)
	local aMsg = {}
	-- ������ɫ���ȼ��������ڵ� > ���ڵ㶨�� > Ԥ����ʽ > Ƶ������
	-- Ƶ������
	local cfg = {
		rich = false,
		wrap = true,
		f = GetMsgFont(szType),
	}
	cfg.r, cfg.g, cfg.b = GetMsgFontColor(szType)
	-- Ԥ����ʽ
	local tTheme = X.IsTable(eTheme)
		and eTheme
		or (eTheme and THEME_LIST[eTheme])
	if tTheme then
		cfg.r = tTheme.r or cfg.r
		cfg.g = tTheme.g or cfg.g
		cfg.b = tTheme.b or cfg.b
		cfg.f = tTheme.f or cfg.f
	end
	-- ���ڵ㶨��
	if X.IsTable(oContent) then
		cfg.r = oContent.r or cfg.r
		cfg.g = oContent.g or cfg.g
		cfg.b = oContent.b or cfg.b
		cfg.f = oContent.f or cfg.f
	end
	-- ��������
	StringifySysmsgObject(aMsg, oTitle, cfg, true, bEcho)
	StringifySysmsgObject(aMsg, oContent, cfg, false, false)
	OutputMessage(szType, table.concat(aMsg), true)
end

-- ��ʾ������Ϣ X.Sysmsg(oTitle, oContent, eTheme)
--   X.Sysmsg({'Error!', wrap = true}, '����', CONSTANT.MSG_THEME.ERROR)
--   X.Sysmsg({'New message', r = 0, g = 0, b = 0, wrap = true}, '����')
--   X.Sysmsg({{'New message', r = 0, g = 0, b = 0, rich = false}, wrap = true}, '����')
--   X.Sysmsg('New message', {'����', '����2', r = 0, g = 0, b = 0})
function X.Sysmsg(...)
	local argc, oTitle, oContent, eTheme = select('#', ...), nil, nil, nil
	if argc == 1 then
		oContent = ...
		oTitle, eTheme = nil, nil
	elseif argc == 2 then
		if X.IsNumber(select(2, ...)) then
			oContent, eTheme = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			eTheme = nil
		end
	elseif argc == 3 then
		oTitle, oContent, eTheme = ...
	end
	if not oTitle then
		oTitle = X.PACKET_INFO.SHORT_NAME
	end
	if not X.IsNumber(eTheme) then
		eTheme = CONSTANT.MSG_THEME.NORMAL
	end
	return OutputMessageEx('MSG_SYS', eTheme, oTitle, oContent)
end

-- ��ʾ������Ϣ X.Topmsg(oTitle, oContent, eTheme)
--   �μ� X.Sysmsg ��������
function X.Topmsg(...)
	local argc, oTitle, oContent, eTheme = select('#', ...), nil, nil, nil
	if argc == 1 then
		oContent = ...
		oTitle, eTheme = nil, nil
	elseif argc == 2 then
		if X.IsNumber(select(2, ...)) then
			oContent, eTheme = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			eTheme = nil
		end
	elseif argc == 3 then
		oTitle, oContent, eTheme = ...
	end
	if not oTitle then
		oTitle = CONSTANT.EMPTY_TABLE
	end
	if not X.IsNumber(eTheme) then
		eTheme = CONSTANT.MSG_THEME.NORMAL
	end
	local szType = eTheme == CONSTANT.MSG_THEME.ERROR
		and 'MSG_ANNOUNCE_RED'
		or 'MSG_ANNOUNCE_YELLOW'
	return OutputMessageEx(szType, eTheme, oTitle, oContent)
end

function X.Systopmsg(...)
	X.Topmsg(...)
	X.Sysmsg(...)
end

-- ���һ��������Ϣ
function X.OutputWhisper(szMsg, szHead)
	szHead = szHead or X.PACKET_INFO.SHORT_NAME
	OutputMessage('MSG_WHISPER', '[' .. szHead .. ']' .. g_tStrings.STR_TALK_HEAD_WHISPER .. szMsg .. '\n')
	PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

local LOG_MAX_FILE = 30
local LOG_MAX_LINE = 300
local LOG_LINE_COUNT = 0
local LOG_PATH, LOG_DATE
-- ���һ����־����־�ļ�
-- @param szText ��־����
function X.Log(szType, szText)
	if not X.IsString(szText) then
		szType, szText = 'UNKNOWN', szType
	end
	local szDate = X.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd')
	if LOG_DATE ~= szDate or LOG_LINE_COUNT >= LOG_MAX_LINE then
		if LOG_PATH then
			Log(LOG_PATH, '', 'close')
		end
		LOG_PATH = X.FormatPath({
			'logs/'
				.. szDate .. '/JX3_'
				.. X.PACKET_INFO.NAME_SPACE
				.. '_' .. ENVIRONMENT.GAME_PROVIDER
				.. '_' .. ENVIRONMENT.GAME_EDITION
				.. '_' .. ENVIRONMENT.GAME_VERSION
				.. '_' .. X.FormatTime(GetCurrentTime(), '%yyyy-%MM-%dd_%hh-%mm-%ss') .. '.log',
			X.PATH_TYPE.ROLE
		})
		LOG_DATE = szDate
		LOG_LINE_COUNT = 0
	end
	LOG_LINE_COUNT = LOG_LINE_COUNT + 1
	Log(LOG_PATH, X.FormatTime(GetCurrentTime(), '%yyyy/%MM/%dd_%hh:%mm:%ss') .. ' [' .. szType .. '] ' .. szText .. '\n')
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

-- Debug���
-- (void)X.Debug(szTitle, oContent, nLevel)
-- szTitle  Debugͷ
-- oContent Debug��Ϣ
-- nLevel   Debug����[���ڵ�ǰ����ֵ���������]
function X.Debug(...)
	local argc, oTitle, oContent, nLevel, szTitle, szContent, eTheme = select('#', ...), nil, nil, nil, nil, nil, nil
	if argc == 1 then
		oContent = ...
		oTitle, nLevel = nil, nil
	elseif argc == 2 then
		if X.IsNumber(select(2, ...)) then
			oContent, nLevel = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			nLevel = nil
		end
	elseif argc == 3 then
		oTitle, oContent, nLevel = ...
	end
	if not oTitle then
		oTitle = X.NSFormatString('{$NS}_DEBUG')
	end
	if not X.IsNumber(nLevel) then
		nLevel = X.DEBUG_LEVEL.WARNING
	end
	if X.IsTable(oTitle) then
		szTitle = table.concat(oTitle, '\n')
	else
		szTitle = tostring(oTitle)
	end
	if X.IsTable(oContent) then
		szContent = table.concat(oContent, '\n')
	else
		szContent = tostring(oContent)
	end
	if nLevel >= X.PACKET_INFO.DEBUG_LEVEL then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. szContent)
		return OutputMessageEx('MSG_SYS', DEBUG_THEME[nLevel], szTitle, oContent, true)
	end
	if nLevel >= X.PACKET_INFO.DELOG_LEVEL then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. szContent)
	end
	X.Log('DEBUG::L' .. nLevel .. '::' .. szTitle, szContent)
end
