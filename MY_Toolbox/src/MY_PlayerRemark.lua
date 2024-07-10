--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ɫ��ע
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_PlayerRemark'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_PlayerRemark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_PlayerRemark.Export', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local D = {}
local DB_ERR_COUNT, DB_MAX_ERR_COUNT = 0, 5
local DB, DBP_W, DBP_DN, DBP_DG, DBP_R, DBP_RI, DBP_RN, DBP_RGI

local function InitDB()
	if DB then
		return true
	end
	if DB_ERR_COUNT > DB_MAX_ERR_COUNT then
		return false
	end
	CPath.MakeDir(X.FormatPath({'userdata/player_remark/', X.PATH_TYPE.GLOBAL}))
	DB = X.SQLiteConnect(_L['MY_PlayerRemark'], {'userdata/player_remark/player_remark.v3.db', X.PATH_TYPE.GLOBAL})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		X.OutputSystemMessage(_L['MY_PlayerRemark'], szMsg, X.CONSTANT.MSG_THEME.ERROR)
		return false
	end
	X.SQLiteExecute(DB, [[
		CREATE TABLE IF NOT EXISTS Info (
			key NVARCHAR(128) NOT NULL,
			value NVARCHAR(4096) NOT NULL,
			PRIMARY KEY (key)
		)
	]])
	X.SQLiteExecute(DB, [[INSERT INTO Info (key, value) VALUES ('version', '3')]])
	X.SQLiteExecute(DB, [[
		CREATE TABLE IF NOT EXISTS PlayerRemark (
			server NVARCHAR(10) NOT NULL,
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			guid NVARCHAR(20) NOT NULL,
			remark NVARCHAR(255) NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY (server, id)
		)
	]])
	X.SQLiteExecute(DB, 'CREATE UNIQUE INDEX IF NOT EXISTS player_info_server_name_u_idx ON PlayerRemark(server, name)')
	X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS player_info_guid_idx ON PlayerRemark(guid)')
	DBP_W = X.SQLitePrepare(DB, 'REPLACE INTO PlayerRemark (server, id, name, guid, remark, extra) VALUES (?, ?, ?, ?, ?, ?)')
	DBP_DN = X.SQLitePrepare(DB, 'DELETE FROM PlayerRemark WHERE server = ? AND name = ?')
	DBP_DG = X.SQLitePrepare(DB, 'DELETE FROM PlayerRemark WHERE guid = ?')
	DBP_R = X.SQLitePrepare(DB, 'SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark')
	DBP_RI = X.SQLitePrepare(DB, 'SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE server = ? AND id = ?')
	DBP_RN = X.SQLitePrepare(DB, 'SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE server = ? AND name = ?')
	DBP_RGI = X.SQLitePrepare(DB, 'SELECT server as szServerName, id as dwID, name as szName, guid as szGlobalID, remark as szRemark, extra as szExtra FROM PlayerRemark WHERE guid = ?')

	return true
end
InitDB()

local function ReleaseDB()
	if not DB then
		return
	end
	DB:Release()
end

function D.Migrate()
	if not X.GetClientPlayer() then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_PlayerRemark.Migrate', 'Client player not exist! Cannot migrate!', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	local szFilePath = X.FormatPath({'config/anmerkungen.jx3dat', X.PATH_TYPE.SERVER})
	if not IsLocalFileExist(szFilePath) then
		return
	end
	local szServerName = X.GetServerOriginName()
	if IsLocalFileExist(szFilePath) then
		local data = X.LoadLUAData(szFilePath)
		if data then
			for _, v in pairs(data.data or {}) do
				X.SQLitePrepareExecute(
					DBP_W,
					AnsiToUTF8(szServerName),
					v.dwID,
					AnsiToUTF8(v.szName),
					'',
					AnsiToUTF8(v.szContent),
					X.EncodeLUAData({
						bTipWhenGroup = v.bTipWhenGroup,
						bAlertWhenGroup = v.bAlertWhenGroup,
					})
				)
			end
		end
		-- CPath.Move(szFilePath, szFilePath .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
	end
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

function D.GetAll()
	if not InitDB() then
		return
	end
	return X.SQLitePrepareGetAllANSI(DBP_R)
end

---ͨ����ɫ��ID���ɫΨһID��ȡ��Ϣ����ȡ��ɫ�ļ�¼
---@param xKey string | number @��ɫ������ɫID���ɫΨһID������ͨ��IDֻ�ܻ�ȡ��ǰ��������ɫ��¼������ҽ�ɫ��¼��ͨ����ɫ�����ɫΨһID���Ի�ȡ������������ɫ��¼
---@return table | nil @��ȡ�ɹ����ؼ�¼�����򷵻ؿ�
function D.Get(xKey)
	if not InitDB() then
		return
	end
	local tInfo
	if X.IsNumber(xKey) then
		local szServer = X.GetServerOriginName()
		tInfo = X.SQLitePrepareGetOneANSI(DBP_RI, szServer, xKey)
	elseif X.IsGlobalID(xKey) then
		tInfo = X.SQLitePrepareGetOneANSI(DBP_RGI, xKey)
	elseif X.IsString(xKey) then
		local szName, szServer = X.DisassemblePlayerGlobalName(xKey, true)
		xKey = X.AssemblePlayerGlobalName(szName, szServer)
		tInfo = X.SQLitePrepareGetOneANSI(DBP_RN, szServer, szName)
	end
	if tInfo then
		local tExtra = X.DecodeLUAData(tInfo.szExtra) or {}
		tInfo.szExtra = nil
		tInfo.bTipWhenGroup = tExtra.bTipWhenGroup
		tInfo.bAlertWhenGroup = tExtra.bAlertWhenGroup
	end
	return tInfo
end

-- ����һ����ҵļ�¼
function D.Set(szServerName, dwID, szName, szGlobalID, szRemark, bTipWhenGroup, bAlertWhenGroup)
	X.SQLitePrepareExecuteANSI(
		DBP_W,
		szServerName,
		dwID,
		szName,
		szGlobalID,
		szRemark,
		X.EncodeLUAData({
			bTipWhenGroup = bTipWhenGroup,
			bAlertWhenGroup = bAlertWhenGroup,
		})
	)
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

---ɾ��һ����ҵļ�¼
function D.Delete(szServerName, szName, szGlobalID)
	if szServerName and szName then
		X.SQLitePrepareExecuteANSI(DBP_DN, szServerName, szName)
	end
	if szGlobalID then
		X.SQLitePrepareExecuteANSI(DBP_DG, szGlobalID)
	end
	FireUIEvent('MY_PLAYER_REMARK_UPDATE')
end

-- ������ҽ���ʱ
function D.CheckPartyPlayer(dwID)
	local bLeader = X.IsLeader(dwID)
	local tMember = X.GetTeamMemberInfo(dwID)
	local tPlayer = D.Get(tMember.szGlobalID or tMember.szName)
	if tPlayer then
		if tPlayer.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_PlayerRemark_' .. tPlayer.dwID,
				szMessage = bLeader
					and _L('Tip: [%s](Leader) is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark)
					or _L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if tPlayer.bTipWhenGroup then
			X.OutputSystemMessage(_L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark))
		end
	end
end

-- ������ҽ�����ʱ
function D.CheckRoomPlayer(szGlobalID)
	local tMember = X.GetRoomMemberInfo(szGlobalID)
	local szServerName = tMember and X.GetServerNameByID(tMember.dwServerID)
	local tPlayer = (tMember and D.Get(tMember.szGlobalID))
		or (szServerName and D.Get(X.AssemblePlayerGlobalName(tMember.szName, szServerName)))
	if tPlayer then
		if tPlayer.bAlertWhenGroup then
			MessageBox({
				szName = 'MY_PlayerRemark_' .. tPlayer.dwID,
				szMessage = _L('Tip: [%s] is in your room.\nRemark: %s', tPlayer.szName, tPlayer.szRemark),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if tPlayer.bTipWhenGroup then
			X.OutputSystemMessage(_L('Tip: [%s] is in your team.\nRemark: %s', tPlayer.szName, tPlayer.szRemark))
		end
	end
end

-- ��һ����ҵļ�¼�༭��
function D.OpenPlayerRemarkEditPanel(szServerName, dwID, szName, szGlobalID)
	if not MY_Farbnamen then
		return X.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local szRemark, bTipWhenGroup, bAlertWhenGroup = '', false, false
	do
		local tInfo
		if not tInfo and X.IsGlobalID(szGlobalID) then
			tInfo = D.Get(szGlobalID)
		end
		if not tInfo then
			tInfo = D.Get(X.AssemblePlayerGlobalName(szName, szServerName))
		end
		if not tInfo and not IsRemotePlayer(dwID) then
			tInfo = D.Get(dwID)
		end
		if tInfo then
			-- szServerName = tInfo.szServerName
			dwID = X.IIf(IsRemotePlayer(dwID), tInfo.dwID, dwID)
			szRemark = tInfo.szRemark
			bTipWhenGroup = tInfo.bTipWhenGroup
			bAlertWhenGroup = tInfo.bAlertWhenGroup
		end
	end
	if IsRemotePlayer(dwID) then
		dwID = 0
	end

	local nW, nH = 400, 360
	local nPaddingX, nPaddingY = 35, 50
	local nX, nY = nPaddingX, nPaddingY
	local nRightW = 250

	local ui = X.UI.CreateFrame('MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. dwID, {
		w = nW, h = nH, anchor = 'CENTER',
		text = _L['MY_PlayerRemark Edit'],
	})

	ui:Remove(function()
		X.RegisterEsc('MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. dwID)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end)

	ui:Append('Text', { x = nX, y = nY, text = _L['Server:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		multiline = false, enable = false, color = {200,200,200},
		text = szServerName,
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Name:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		multiline = false, enable = false, color = {200,200,200},
		text = szName,
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['ID:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		text = dwID,
		multiline = false, enable = false, color = {200,200,200},
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['GUID:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 25,
		text = szGlobalID,
		multiline = false, enable = false, color = {200,200,200},
	})
	nY = nY + 30

	nX = nPaddingX
	ui:Append('Text', { x = nX, y = nY, text = _L['Remark:'] })
	nX = nX + 80
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nRightW, h = 80,
		multiline = true, text = szRemark,
		onChange = function (szText)
			szRemark = szText
		end,
	})
	nY = nY + 90

	nX = nPaddingX
	nX = nX + 80 - 2
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = nRightW,
		text = _L['Alert when group'],
		checked = bAlertWhenGroup,
		onCheck = function(bChecked)
			bAlertWhenGroup = bChecked
		end,
	})
	nY = nY + 20

	nX = nPaddingX
	nX = nX + 80 - 2
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = nRightW,
		text = _L['Tip when group'],
		checked = bTipWhenGroup,
		onCheck = function(bChecked)
			bTipWhenGroup = bChecked
		end,
	})
	nY = nY + 30

	nX = nPaddingX
	nX = nX + 80 - 2
	nX = nX + ui:Append('WndButton', {
		name = 'WndButton_Submit',
		x = nX, y = nY, h = 30, minWidth = nRightW / 3,
		text = _L['sure'],
		onClick = function()
			D.Set(
				szServerName,
				dwID,
				szName,
				szGlobalID,
				szRemark,
				bTipWhenGroup,
				bAlertWhenGroup
			)
			ui:Remove()
		end,
	}):Width() + 3
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, h = 30, minWidth = nRightW / 3,
		text = _L['cancel'],
		onClick = function() ui:Remove() end,
	}):Width() + 3
	nX = nX + ui:Append('Text', {
		x = nX, y = nY - 3, h = 30 + 3, minWidth = nRightW / 3, alpha = 200,
		alignHorizontal = 1, alignVertical = 1,
		text = _L['Delete'], color = {255,0,0},
		onHover = function(bIn) X.UI(this):Alpha((bIn and 255) or 200) end,
		onClick = function()
			D.Delete(
				szServerName,
				szName,
				szGlobalID
			)
			ui:Remove()
		end,
	}):Width() + 3

	-- init
	X.RegisterEsc(
		'MY_PlayerRemark_Edit_' .. GetStringCRC(szServerName) ..  '_' .. (dwID or 0),
		function()
			return ui and ui:Count() > 0
		end,
		function()
			ui:Remove()
			return true
		end
	)
	Station.SetFocusWindow(ui[1])
	ui:Children('#WndEditBox_Name'):Change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_PlayerRemark',
	exports = {
		{
			fields = {
				'Get',
			},
			root = D,
		},
	},
}
MY_PlayerRemark = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterTargetAddonMenu('MY_PlayerRemark', function()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.PLAYER then
		local kPlayer = X.GetObject(dwType, dwID)
		return {
			szOption = _L['Edit player remark'],
			fnAction = function()
				local szName, szServerName = X.DisassemblePlayerGlobalName(kPlayer.szName, true)
				local szGlobalID = X.GetPlayerGlobalID(dwID)
				D.OpenPlayerRemarkEditPanel(szServerName, dwID, szName, szGlobalID)
			end
		}
	end
end)

X.RegisterAddonMenu('MY_PlayerRemark', {
	szOption = _L['View player remark'],
	fnAction = function()
		X.ShowPanel()
		X.FocusPanel()
		X.SwitchTab('MY_PlayerRemark')
	end,
})

X.RegisterEvent('PARTY_ADD_MEMBER', function()
	D.CheckPartyPlayer(arg1)
end)
-- X.RegisterEvent('PARTY_SYNC_MEMBER_DATA', OnPartyAddMember)

-- ������ʱ
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', 'MY_PlayerRemark', function()
	local team = GetClientTeam()
	if not team then
		return
	end
	for _, dwID in ipairs(team.GetTeamMemberList()) do
		D.CheckPartyPlayer(dwID)
	end
end)

X.RegisterEvent('JOIN_GLOBAL_ROOM', 'MY_PlayerRemark', function()
	X.DelayCall(2000, function()
		for _, szGlobalID in ipairs(X.GetRoomMemberList()) do
			D.CheckRoomPlayer(szGlobalID)
		end
	end)
end)

X.RegisterEvent('GLOBAL_ROOM_MEMBER_CHANGE', 'MY_PlayerRemark', function()
	local szGlobalID = arg1
	local bJoin = arg2
	local szName = arg3
	local dwSeverID = arg4
	if not bJoin then
		return
	end
	local szServerName = X.GetServerNameByID(dwSeverID)
	if not szServerName then
		return
	end
	D.CheckRoomPlayer(szGlobalID)
end)

X.RegisterEvent('MY_PLAYER_REMARK_UPDATE', 'MY_PlayerRemark', function()
	if X.GetCurrentTabID() == 'MY_PlayerRemark' then
		X.SwitchTab('MY_PlayerRemark', true)
	end
end)

X.RegisterInit('MY_PlayerRemark', function()
	D.Migrate()
end)

X.RegisterExit('MY_PlayerRemark', ReleaseDB)

--------------------------------------------------------------------------------
-- ����ע��
--------------------------------------------------------------------------------
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nX, nY = 0, 0

	local list = ui:Append('WndListBox', {
		x = nX, y = nY,
		w = nW, h = nH,
		listBox = {{
			'onlclick',
			function(szID, szText, data, bSelected)
				D.OpenPlayerRemarkEditPanel(data.szServerName, data.dwID, data.szName, data.szGlobalID)
				return false
			end,
		}},
	})
	for _, tInfo in ipairs(D.GetAll()) do
		list:ListBox('insert', {
			id = X.AssemblePlayerGlobalName(tInfo.szName, tInfo.szServerName),
			text = _L('[%s] %s', X.AssemblePlayerGlobalName(tInfo.szName, tInfo.szServerName), tInfo.szRemark),
			data = tInfo,
		})
	end
end
X.RegisterPanel(_L['Target'], 'MY_PlayerRemark', _L['Player remark'], 'ui/Image/button/ShopButton.UITex|12', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
