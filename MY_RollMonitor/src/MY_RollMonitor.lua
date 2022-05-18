--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ROLL����
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RollMonitor/MY_RollMonitor'
local PLUGIN_NAME = 'MY_RollMonitor'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RollMonitor'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^13.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SORT_TYPE = {
	FIRST = 1,  -- ֻ��¼��һ��
	LAST  = 2,  -- ֻ��¼���һ��
	MAX   = 3,  -- ���ҡ��ȡ��ߵ�
	MIN   = 4,  -- ���ҡ��ȡ��͵�
	AVG   = 5,  -- ���ҡ��ȡƽ��ֵ
	AVG2  = 6,  -- ȥ��������ȡƽ��ֵ
}
local SORT_TYPE_LIST = {
	SORT_TYPE.FIRST, SORT_TYPE.LAST, SORT_TYPE.MAX,
	SORT_TYPE.MIN  , SORT_TYPE.AVG , SORT_TYPE.AVG2,
}
local SORT_TYPE_INFO = {
	[SORT_TYPE.FIRST] = { -- ֻ��¼��һ��
 		szName = _L['only first score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			return aRecord[nIndex1].nRoll
		end
	},
	[SORT_TYPE.LAST] = { -- ֻ��¼���һ��
 		szName = _L['only last score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			return aRecord[nIndex2].nRoll
		end
	},
	[SORT_TYPE.MAX] = { -- ���ҡ��ȡ��ߵ�
 		szName = _L['highest score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = math.max(nRoll, aRecord[i].nRoll)
			end
			return nRoll
		end
	},
	[SORT_TYPE.MIN] = { -- ���ҡ��ȡ��͵�
 		szName = _L['lowest score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = math.min(nRoll, aRecord[i].nRoll)
			end
			return nRoll
		end
	},
	[SORT_TYPE.AVG] = { -- ���ҡ��ȡƽ��ֵ
 		szName = _L['average score'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nRoll = 0
			for i = nIndex1, nIndex2 do
				nRoll = nRoll + aRecord[i].nRoll
			end
			return nRoll / (nIndex2 - nIndex1 + 1)
		end
	},
	[SORT_TYPE.AVG2] = { -- ȥ��������ȡƽ��ֵ
 		szName = _L['average score with out pole'],
		fnCalc = function(aRecord, nIndex1, nIndex2)
			local nTotal, nMax, nMin = 0, 0, 0
			local nCount = nIndex2 - nIndex1 + 1
			for i = nIndex1, nIndex2 do
				local nRoll = aRecord[i].nRoll
				nMin = math.min(nMin, nRoll)
				nMax = math.max(nMax, nRoll)
				nTotal = nTotal + nRoll
			end
			if nCount > 2 then
				nCount = nCount - 2
				nTotal = nTotal - nMax - nMin
			end
			return nTotal / nCount
		end
	},
}
local PUBLISH_CHANNELS = {
	{ nChannel = PLAYER_TALK_CHANNEL.TEAM, szName = _L['PTC_TEAM_CHANNEL'], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.RAID, szName = _L['PTC_RAID_CHANNEL'], rgb = GetMsgFontColor('MSG_TEAM'  , true) },
	{ nChannel = PLAYER_TALK_CHANNEL.TONG, szName = _L['PTC_TONG_CHANNEL'], rgb = GetMsgFontColor('MSG_GUILD' , true) },
}
local TIME_LIMIT = {-1, 60, 120, 180, 300, 600, 1200, 1800, 3600}
local TIME_LIMIT_TITLE = {
	 [-1  ] = _L['unlimited time'],
	 [60  ] = _L('last %d minute(s)', 1),
	 [120 ] = _L('last %d minute(s)', 2),
	 [180 ] = _L('last %d minute(s)', 3),
	 [300 ] = _L('last %d minute(s)', 5),
	 [600 ] = _L('last %d minute(s)', 10),
	 [1200] = _L('last %d minute(s)', 20),
	 [1800] = _L('last %d minute(s)', 30),
	 [3600] = _L('last %d minute(s)', 60),
}
local PS = { nPriority = 3 }
local m_uiBoard       -- ���ui�ؼ�
local m_tRecords = {} -- ��ʷROLL����ϸ��¼
local m_aRecTime = {} -- �¼�¼��ʱ����������ػ���壩
--[[
m_tRecords = {
	['����'] = {
		szName = '����',
		{nTime = 1446516554, nRoll = 100},
		{nTime = 1446516577, nRoll = 50 },
	}, ...
}
]]
local O = X.CreateUserSettingsModule('MY_RollMonitor', _L['General'], {
	nSortType = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nTimeLimit = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Number,
		xDefaultValue = -1,
	},
	nPublish = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nPublishChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Number,
		xDefaultValue = PLAYER_TALK_CHANNEL.RAID,
	},
	bPublishUnroll = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPublishRestart = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RollMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

-- �¼���Ӧ����
-- �����
-- (void) D.OpenPanel()
function D.OpenPanel()
	X.ShowPanel()
	X.FocusPanel()
	X.SwitchTab('RollMonitor')
end

-- ���ROLL��
-- (void) D.Clear(nChannel, bEcho)
-- (boolean) bEcho   : �Ƿ������¿�ʼ������Ϣ
-- (number)  nChannel: ����Ƶ��
function D.Clear(bEcho, nChannel)
	if bEcho == nil then
		bEcho = O.bPublishRestart
	end
	if bEcho then
		nChannel = nChannel or O.nPublishChannel
		X.SendChat(nChannel, _L['----------- roll restart -----------'] .. '\n')
	end
	m_tRecords = {}
	D.DrawBoard()
end

-- ��ø���ROLL����
-- D.GetPersonResult(szName, nSortType, nTimeLimit)
-- D.GetPersonResult(aRecord, nSortType, nTimeLimit)
-- (string)    szName     : Ҫ��ȡ���������
-- (table)     aRecord    : Ҫ��ȡ��ԭʼ����
-- (SORT_TYPE) nSortType  : ����ʽ ֵ�μ�ö��
-- (number)    nTimeLimit : ���ʱ������ �����5������300
function D.GetPersonResult(szName, nSortType, nTimeLimit)
	-- ��ʽ������
	nSortType = nSortType or O.nSortType
	nTimeLimit = nTimeLimit or O.nTimeLimit
	local nStartTime = 0
	if nTimeLimit > 0 then
		nStartTime = GetCurrentTime() - nTimeLimit
	end
	local aRecord
	if type(szName) == 'table' then
		aRecord = szName
	else
		aRecord = m_tRecords[szName] or X.CONSTANT.EMPTY_TABLE
	end
	-- ������ЧRoll�������±�
	local aTime = {}
	local nIndex1, nIndex2 = 0, #aRecord
	for i, rec in ipairs(aRecord) do
		if rec.nTime < nStartTime then
			nIndex1 = i
		else
			table.insert(aTime, rec.nTime)
		end
	end
	nIndex1 = nIndex1 + 1
	if nIndex1 > nIndex2 then
		return
	end
	local t = {
		szName = aRecord.szName,
		nRoll  = SORT_TYPE_INFO[nSortType].fnCalc(aRecord, nIndex1, nIndex2),
		nCount = nIndex2 - nIndex1 + 1,
		aTime  = aTime,
	}
	return t
end

-- ���ȫ��������
-- (void) D.GetResult(nSortType, nTimeLimit)
-- (SORT_TYPE) nSortType  : ����ʽ ֵ�μ�ö��
-- (number)    nTimeLimit : ���ʱ������ �����5������300(-1��ʾ����ʱ)
function D.GetResult(nSortType, nTimeLimit)
	-- ��ʽ������
	nSortType = nSortType or O.nSortType
	nTimeLimit = nTimeLimit or O.nTimeLimit
	-- ��ȡ���������
	local t = {}
	for _, aRecord in pairs(m_tRecords) do
		aRecord = D.GetPersonResult(aRecord, nSortType, nTimeLimit)
		if aRecord then
			table.insert(t, aRecord)
		end
	end
	table.sort(t, function(v1, v2) return v1.nRoll > v2.nRoll end)
	return t
end

-- ����ROLL��
-- (void) D.Echo(nSortType, nLimit, nChannel, bShowUnroll)
-- (enum)    nSortType  : ����ʽ ö��[SORT_TYPE]
-- (number)  nLimit     : �����ʾ��������
-- (number)  nChannel   : ����Ƶ��
-- (boolean) bShowUnroll: �Ƿ���ʾδROLL��
function D.Echo(nSortType, nLimit, nChannel, bShowUnroll)
	if bShowUnroll == nil then
		bShowUnroll = O.bPublishUnroll
	end
	nSortType = nSortType or O.nSortType
	nLimit    = nLimit    or O.nPublish
	nChannel  = nChannel  or O.nPublishChannel

	X.SendChat(nChannel, ('[%s][%s][%s]%s\n'):format(
		X.PACKET_INFO.SHORT_NAME, _L['roll monitor'],
		TIME_LIMIT_TITLE[O.nTimeLimit],
		SORT_TYPE_INFO[nSortType].szName
	), { parsers = { name = false } })
	X.SendChat(nChannel, _L['-------------------------------'] .. '\n')
	local tNames = {}
	for i, aRecord in ipairs(D.GetResult(nSortType)) do
		if nLimit <= 0 or i <= nLimit then
			X.SendChat(nChannel, _L('[%s] rolls for %d times, valid score is %s.', aRecord.szName, aRecord.nCount, string.gsub(aRecord.nRoll, '(%d+%.%d%d)%d+','%1')) .. '\n')
		end
		tNames[aRecord.szName] = true
	end
	local team = GetClientTeam()
	if team and bShowUnroll then
		local szUnrolledNames = ''
		for _, dwID in ipairs(team.GetTeamMemberList()) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not tNames[szName] then
				szUnrolledNames = szUnrolledNames .. '[' .. szName .. ']'
			end
		end
		if szUnrolledNames~='' then
			X.SendChat(nChannel, szUnrolledNames .. _L['haven\'t roll yet.']..'\n')
		end
	end
	X.SendChat(nChannel, _L['-------------------------------'] .. '\n')
end

-- ���»��ƽ����ʾ����
-- (void) D.DrawBoard(ui uiBoard)
function D.DrawBoard(ui)
	if not ui then
		ui = m_uiBoard
	end
	m_aRecTime = {}
	if ui then
		local szMsg = ''
		local tNames = {}
		for _, aRecord in ipairs(D.GetResult()) do
			szMsg = szMsg ..
				X.GetChatCopyXML() ..
				GetFormatText('['..aRecord.szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0') ..
				GetFormatText(_L( ' rolls for %d times, valid score is %s.', aRecord.nCount, (string.gsub(aRecord.nRoll,'(%d+%.%d%d)%d+','%1')) ) .. '\n')
			for _, nTime in ipairs(aRecord.aTime) do
				table.insert(m_aRecTime, nTime)
			end
			tNames[aRecord.szName] = true
		end
		table.sort(m_aRecTime)
		local team = GetClientTeam()
		if team then
			local szUnrolledNames = ''
			for _, dwID in ipairs(team.GetTeamMemberList()) do
				local szName = team.GetClientTeamMemberName(dwID)
				if not tNames[szName] then
					szUnrolledNames = szUnrolledNames .. GetFormatText('['..szName..']', nil, nil, nil, nil, 515, nil, 'namelink_0')
				end
			end
			if szUnrolledNames ~= '' then
				szMsg = szMsg ..
				X.GetChatCopyXML() ..
				szUnrolledNames .. GetFormatText(_L['haven\'t roll yet.'])
			end
		end
		szMsg = X.RenderChatLink(szMsg)
		if MY_ChatEmotion and MY_ChatEmotion.Render then
			szMsg = MY_ChatEmotion.Render(szMsg)
		end
		if MY_Farbnamen and MY_Farbnamen.Render then
			szMsg = MY_Farbnamen.Render(szMsg)
		end
		ui:Clear():Append(szMsg)
	end
end

-- ����Ƿ���Ҫ�ػ� �����ػ������»���
local function CheckBoardRedraw()
	if m_aRecTime[1]
	and m_aRecTime[1] < GetCurrentTime() then
		D.DrawBoard()
	end
end

-- ϵͳƵ����ش�����
local function OnMsgArrive(szMsg, nFont, bRich, r, g, b)
	local isRoll = false
	for szName, nRoll in string.gmatch(szMsg, _L['ROLL_MONITOR_EXP'] ) do
		-- ��ʽ����ֵ
		nRoll = tonumber(nRoll)
		if not nRoll then
			return
		end
		isRoll = true
		-- �жϻ����и�����Ƿ��Ѵ��ڼ�¼
		if not m_tRecords[szName] then
			m_tRecords[szName] = { szName = szName }
		end
		local aRecord = m_tRecords[szName]
		-- ��ʽ������ ���¸���ֵ
		table.insert(m_aRecTime, GetCurrentTime())
		table.insert(aRecord, {nTime = GetCurrentTime(), nRoll = nRoll})
	end
	if not isRoll then
		return
	end
	D.DrawBoard()
end
RegisterMsgMonitor(OnMsgArrive, {'MSG_SYS'})


-- Global exports
do
local settings = {
	name = 'MY_RollMonitor',
	exports = {
		{
			fields = {
				OpenPanel = D.OpenPanel,
				Clear = D.Clear,
			},
		},
	},
}
MY_RollMonitor = X.CreateModule(settings)
end


-- ��ǩ������Ӧ����
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local w, h = ui:Size()
	-- ��¼ģʽ
	ui:Append('WndComboBox', {
		x = 20, y = 10, w = 180,
		text = SORT_TYPE_INFO[O.nSortType].szName,
		menu = function(raw)
			local t = {}
			for _, nSortType in ipairs(SORT_TYPE_LIST) do
				table.insert(t, {
					szOption = SORT_TYPE_INFO[nSortType].szName,
					fnAction = function()
						O.nSortType = nSortType
						D.DrawBoard()
						X.UI(raw):Text(SORT_TYPE_INFO[nSortType].szName)
						return 0
					end,
				})
			end
			return t
		end
	})
	-- ��Чʱ��
	ui:Append('WndComboBox', {
		x = 210, y = 10, w = 120,
		text = TIME_LIMIT_TITLE[O.nTimeLimit],
		menu = function(raw)
			local t = {}
			for _, nSec in ipairs(TIME_LIMIT) do
				table.insert(t, {
					szOption = TIME_LIMIT_TITLE[nSec],
					fnAction = function()
						X.UI(raw):Text(TIME_LIMIT_TITLE[nSec])
						O.nTimeLimit = nSec
						D.DrawBoard()
						return 0
					end,
				})
			end
			return t
		end
	})
	-- ���
	ui:Append('WndButton', {
		x = w - 176, y = 10, w = 90, text = _L['restart'],
		onLClick = function(nButton) D.Clear() end,
		menuRClick = function()
			local t = {{
				szOption = _L['publish while restart'],
				bCheck = true, bMCheck = false, bChecked = O.bPublishRestart,
				fnAction = function() O.bPublishRestart = not O.bPublishRestart end,
			}, { bDevide = true }}
			for _, tChannel in ipairs(PUBLISH_CHANNELS) do
				table.insert(t, {
					szOption = tChannel.szName,
					rgb = tChannel.rgb,
					bCheck = true, bMCheck = true, bChecked = O.nPublishChannel == tChannel.nChannel,
					fnAction = function()
						O.nPublishChannel = tChannel.nChannel
					end
				})
			end
			return t
		end,
		tip = {
			render = _L['left click to restart, right click to open setting.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	})
	-- ����
	ui:Append('WndButton', {
		x = w - 86, y = 10, w = 80, text = _L['publish'],
		onLClick = function() D.Echo() end,
		menuRClick = function()
			local t = { {
				szOption = _L['publish setting'], {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 3,
					fnAction = function() O.nPublish = 3 end,
					szOption = _L('publish top %d', 3)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 5,
					fnAction = function() O.nPublish = 5 end,
					szOption = _L('publish top %d', 5)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 10,
					fnAction = function() O.nPublish = 10 end,
					szOption = _L('publish top %d', 10)
				}, {
					bCheck = true, bMCheck = true, bChecked = O.nPublish == 0,
					fnAction = function() O.nPublish = 0 end,
					szOption = _L['publish all']
				}, { bDevide = true }, {
					bCheck = true, bChecked = O.bPublishUnroll,
					fnAction = function() O.bPublishUnroll = not O.bPublishUnroll end,
					szOption = _L['publish unroll']
				}
			}, { bDevide = true } }
			for _, tChannel in ipairs(PUBLISH_CHANNELS) do
				table.insert( t, {
					szOption = tChannel.szName,
					rgb = tChannel.rgb,
					bCheck = true, bMCheck = true, bChecked = O.nPublishChannel == tChannel.nChannel,
					fnAction = function()
						O.nPublishChannel = tChannel.nChannel
					end
				} )
			end
			return t
		end,
		tip = {
			render = _L['left click to publish, right click to open setting.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
			offset = { x = -80 },
		},
	})
	-- �����
	m_uiBoard = ui:Append('WndScrollHandleBox',{
		x = 20,  y = 40, w = w - 26, h = h - 60,
		handleStyle = 3, text = _L['average score with out pole']
	})
	D.DrawBoard()
	X.BreatheCall('MY_RollMonitorRedraw', 1000, CheckBoardRedraw)
end

function PS.OnPanelDeactive()
	m_uiBoard = nil
	X.BreatheCall('MY_RollMonitorRedraw', false)
end

X.RegisterPanel(_L['General'], 'RollMonitor', _L['roll monitor'], 287, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
