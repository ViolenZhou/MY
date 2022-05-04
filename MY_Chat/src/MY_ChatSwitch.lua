--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����Ƶ���л�
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Chat/MY_ChatSwitch'
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatSwitch'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule(MODULE_NAME, _L['Chat'], {
	bDisplayPanel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 10, y = -60, s = 'BOTTOMLEFT', r = 'BOTTOMLEFT' },
	},
	bLockPostion = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tChennalVisible = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
	aWhisper = {
		ePathType = X.PATH_TYPE.ROLE,
		bUserData = true,
		xSchema = X.Schema.Collection(
			X.Schema.Tuple(
				X.Schema.String, -- szName
				X.Schema.Collection( -- aHistory
					X.Schema.OneOf(
						X.Schema.String, -- szMsg
						X.Schema.Tuple(X.Schema.String, X.Schema.Number) -- szMsg, nTime
					)
				)
			)
		),
		xDefaultValue = {},
	},
	szAway = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	szBusy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	tChannelCount = {
		ePathType = X.PATH_TYPE.ROLE,
		bUserData = true,
		xSchema = X.Schema.Record({
			szDate = X.Schema.String,
			tCount = X.Schema.Map(X.Schema.Number, X.Schema.Number),
		}),
		xDefaultValue = {
			szDate = '',
			tCount = {},
		},
	},
	bAlertBeforeClear = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoSwitchBfChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_Chat/ui/MY_ChatSwitch.ini'
local CD_REFRESH_OFFSET = 7 * 60 * 60 -- 7�����CD

local function UpdateChannelDailyLimit(hRadio, bPlus)
	local me = GetClientPlayer()
	local shaCount = hRadio and hRadio.shaCount
	if not (me and shaCount) then
		return
	end

	local dwPercent = 1
	local info = hRadio.info
	local nChannel = info.channel
	if nChannel then
		local szDate = X.FormatTime(GetCurrentTime() - CD_REFRESH_OFFSET, '%yyyy%MM%dd')
		local tChannelCount = D.tChannelCount
		if tChannelCount.szDate ~= szDate then
			tChannelCount = {
				szDate = szDate,
				tCount = {},
			}
			D.tChannelCount = tChannelCount
			D.bChannelCountChanged = true
		end
		local nDailyCount = (tChannelCount.tCount[nChannel] or 0) + (bPlus and 1 or 0)
		if nDailyCount ~= tChannelCount.tCount[nChannel] then
			tChannelCount.tCount[nChannel] = nDailyCount
			D.bChannelCountChanged = true
		end
		local nDailyLimit = X.GetChatChannelDailyLimit(me.nLevel, nChannel)
		if nDailyLimit then
			if nDailyLimit > 0 then
				dwPercent = (nDailyLimit - nDailyCount) / nDailyLimit
				hRadio.szTip = GetFormatText(_L('Today: %d\nDaily limit: %d', nDailyCount, nDailyLimit), nil, 255, 255, 0)
			else
				hRadio.szTip = GetFormatText(_L('Today: %d\nDaily limit: no limitation', nDailyCount), nil, 255, 255, 0)
			end
		end
	end
	X.UI(shaCount):DrawCircle(nil, nil, nil, info.color[1], info.color[2], info.color[3], 100, math.pi / 2, math.pi * 2 * dwPercent)
end

local CHANNEL_LIST = {
	{ -- ˵
		id = 'nearby',
		title = _L['SAY'],
		head = '/s ',
		channel = PLAYER_TALK_CHANNEL.NEARBY,
		cd = 0,
		color = {255, 255, 255},
	},
	{ -- ��
		id = 'sence',
		title = _L['MAP'],
		head = '/y ',
		channel = PLAYER_TALK_CHANNEL.SENCE,
		cd = 10,
		color = {255, 126, 126},
	},
	{ -- ��
		id = 'world',
		title = _L['WORLD'],
		head = '/h ',
		channel = PLAYER_TALK_CHANNEL.WORLD,
		cd = 60,
		color = {252, 204, 204},
	},
	{ -- ��
		id = 'team',
		title = _L['PARTY'],
		head = '/p ',
		channel = PLAYER_TALK_CHANNEL.TEAM,
		cd = 0,
		color = {140, 178, 253},
	},
	{ -- ��
		id = 'raid',
		title = _L['TEAM'],
		head = '/t ',
		channel = PLAYER_TALK_CHANNEL.RAID,
		cd = 0,
		color = { 73, 168, 241},
	},
	{ -- ս
		id = 'battle_field',
		title = _L['BATTLE'],
		head = '/b ',
		channel = PLAYER_TALK_CHANNEL.BATTLE_FIELD,
		cd = 0,
		color = {255, 126, 126},
	},
	{ -- ��
		id = 'tong',
		title = _L['FACTION'],
		head = '/g ',
		channel = PLAYER_TALK_CHANNEL.TONG,
		cd = 0,
		color = {  0, 200,  72},
	},
	{ -- ��
		id = 'force',
		title = _L['SCHOOL'],
		head = '/f ',
		channel = PLAYER_TALK_CHANNEL.FORCE,
		cd = 20,
		color = {  0, 255, 255},
	},
	{ -- ��
		id = 'camp',
		title = _L['CAMP'],
		head = '/c ',
		channel = PLAYER_TALK_CHANNEL.CAMP,
		cd = 30,
		color = {155, 230,  58},
	},
	{ -- ��
		id = 'friends',
		title = _L['FRIEND'],
		head = '/o ',
		channel = PLAYER_TALK_CHANNEL.FRIENDS,
		cd = 10,
		color = {241, 114, 183},
	},
	{ -- ��
		id = 'tong_alliance',
		title = _L['ALLIANCE'],
		head = '/a ',
		channel = PLAYER_TALK_CHANNEL.TONG_ALLIANCE,
		cd = 0,
		color = {178, 240, 164},
	},
	{ -- ��
		id = 'whisper',
		title = _L['WHISPER'],
		channel = PLAYER_TALK_CHANNEL.WHISPER,
		cd = 0,
		onClick = function()
			local t = {}
			for i, whisper in ipairs(D.aWhisper) do
				local info = MY_Farbnamen and MY_Farbnamen.Get(whisper[1])
				table.insert(t, {
					szOption = whisper[1],
					rgb = info and info.rgb or {202, 126, 255},
					fnAction = function()
						X.SwitchChatChannel(whisper[1])
						X.DelayCall(X.FocusChatInput)
					end,
					szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
					nFrame = 49,
					nMouseOverFrame = 51,
					nIconWidth = 17,
					nIconHeight = 17,
					szLayer = 'ICON_RIGHTMOST',
					fnClickIcon = function()
						for i = #D.aWhisper, 1, -1 do
							if D.aWhisper[i][1] == whisper[1] then
								table.remove(D.aWhisper, i)
								X.UI.ClosePopupMenu()
							end
						end
						O.aWhisper = D.aWhisper
						D.bWhisperChanged = false
					end,
					fnMouseEnter = function()
						local t = {}
						local today = X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd')
						local r, g, b = GetMsgFontColor('MSG_WHISPER')
						for _, v in ipairs(whisper[2]) do
							if X.IsString(v) then
								table.insert(t, v)
							elseif X.IsTable(v) and X.IsString(v[1]) then
								if today == X.FormatTime(v[2], '%yyyy%MM%dd') then
									table.insert(t, X.GetChatTimeXML(v[2], {r = r, g = g, b = b, s = '[%hh:%mm:%ss]'}) .. v[1])
								else
									table.insert(t, X.GetChatTimeXML(v[2], {r = r, g = g, b = b, s = '[%M.%dd.%hh:%mm:%ss]'}) .. v[1])
								end
							end
						end
						local szMsg = table.concat(t, '')
						if MY_ChatEmotion and MY_ChatEmotion.Render then
							szMsg = MY_ChatEmotion.Render(szMsg)
						end
						if MY_Farbnamen then
							szMsg = MY_Farbnamen.Render(szMsg)
						end
						OutputTip(szMsg, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
					end,
				})
			end
			local x, y = this:GetAbsPos()
			t.x = x
			t.y = y - #D.aWhisper * 24 - 24 - 20 - 8
			if #t > 0 then
				table.insert(t, 1, X.CONSTANT.MENU_DIVIDER)
				table.insert(t, 1, {
					szOption = g_tStrings.CHANNEL_WHISPER_SIGN,
					rgb = {202, 126, 255},
					fnAction = function()
						X.SwitchChatChannel(PLAYER_TALK_CHANNEL.WHISPER)
						X.DelayCall(X.FocusChatInput)
					end,
				})
				PopupMenu(t)
			else
				X.SwitchChatChannel(PLAYER_TALK_CHANNEL.WHISPER)
			end
			this:Check(false)
		end,
		color = {202, 126, 255},
	},
	{ -- ��
		id = 'cls',
		title = _L['CLS'],
		onClick = function()
			local function Cls(bAll)
				for i = 1, 32 do
					local h = Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
					local hCheck = Station.Lookup('Lowest2/ChatPanel' .. i .. '/CheckBox_Title')
					if h and (bAll or (hCheck and hCheck:IsCheckBoxChecked())) then
						h:Clear()
						h:FormatAllItemPos()
					end
				end
			end
			if IsCtrlKeyDown() then
				Cls()
			elseif IsAltKeyDown() then
				MessageBox({
					szName = 'CLS_CHATPANEL_ALL',
					szMessage = _L['Are you sure you want to clear all message panel?'], {
						szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
							Cls(true)
						end
					}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
				})
			else
				MessageBox({
					szName = 'CLS_CHATPANEL',
					szMessage = _L['Are you sure you want to clear current message panel?\nPress CTRL when click can clear without alert.\nPress ALT when click can clear all window.'], {
						szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
							Cls()
						end
					}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
				})
			end
			X.UI(this):Check(false)
		end,
		color = {255, 0, 0},
	},
	{ -- ��
		id = 'away',
		title = _L['AWAY'],
		onCheck = function()
			X.SwitchChatChannel('/afk')
			local edit = X.GetChatInput()
			if edit then
				edit:GetRoot():Show()
				if edit:GetText() == '' then
					edit:InsertText(
						X.IsEmpty(O.szAway)
							and g_tStrings.STR_AUTO_REPLAY_LEAVE
							or O.szAway
					)
					edit:SelectAll()
				end
				Station.SetFocusWindow(edit)
			end
		end,
		onuncheck = function()
			X.SwitchChatChannel('/cafk')
		end,
		tip = function()
			return X.IsEmpty(O.szAway)
				and g_tStrings.STR_AUTO_REPLAY_LEAVE
				or O.szAway
		end,
		color = {255, 255, 255},
	},
	{ -- ��
		id = 'busy',
		title = _L['BUSY'],
		onCheck = function()
			X.SwitchChatChannel('/atr')
			local edit = X.GetChatInput()
			if edit then
				edit:GetRoot():Show()
				if edit:GetText() == '' then
					edit:InsertText(
						X.IsEmpty(O.szBusy)
							and g_tStrings.STR_AUTO_REPLAY_LEAVE
							or O.szBusy
					)
					edit:SelectAll()
				end
				Station.SetFocusWindow(edit)
			end
		end,
		onuncheck = function()
			X.SwitchChatChannel('/catr')
		end,
		tip = function()
			return X.IsEmpty(O.szBusy)
				and g_tStrings.STR_AUTO_REPLAY_LEAVE
				or O.szBusy
		end,
		color = {255, 255, 255},
	},
	{ -- ��
		id = 'mosaics',
		title = _L['MOSAICS'],
		onCheck = function()
			MY_ChatMosaics.bEnabled = true
		end,
		onuncheck = function()
			MY_ChatMosaics.bEnabled = false
		end,
		color = {255, 255, 255},
	},
}

local CHANNEL_CD_TIME = {}
for i, v in ipairs(CHANNEL_LIST) do
	if v.channel then
		CHANNEL_CD_TIME[v.channel] = v.cd
	end
end
local m_tChannelTime = {}

local function OnChannelCheck()
	X.SwitchChatChannel(this.info.channel)
	local edit = X.GetChatInput()
	if edit then
		edit:GetRoot():Show()
		Station.SetFocusWindow(edit)
	end
	this:Check(false)
end

function D.ApplyBattlefieldChannelSwitch()
	-- ��������Զ��л��Ŷ�Ƶ��
	if O.bAutoSwitchBfChannel then
		X.RegisterEvent('LOADING_ENDING', 'MY_ChatSwitch__AutoSwitchBattlefieldChannel', function()
			local bIsBattleField = (GetClientPlayer().GetScene().nType == MAP_TYPE.BATTLE_FIELD)
			local nChannel, szName = EditBox_GetChannel()
			if bIsBattleField and (nChannel == PLAYER_TALK_CHANNEL.RAID or nChannel == PLAYER_TALK_CHANNEL.TEAM) then
				O.JJCAutoSwitchChatChannel_OrgChannel = nChannel
				X.SwitchChatChannel(PLAYER_TALK_CHANNEL.BATTLE_FIELD)
			elseif not bIsBattleField and nChannel == PLAYER_TALK_CHANNEL.BATTLE_FIELD then
				X.SwitchChatChannel(O.JJCAutoSwitchChatChannel_OrgChannel or PLAYER_TALK_CHANNEL.RAID)
			end
		end)
	else
		X.RegisterEvent('LOADING_ENDING', 'MY_ChatSwitch__AutoSwitchBattlefieldChannel')
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatSwitch__AutoSwitchBattlefieldChannel', function()
	D.aWhisper = O.aWhisper
	D.tChannelCount = O.tChannelCount
	D.ApplyBattlefieldChannelSwitch()
end)

X.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_ChatSwitch__AutoSwitchBattlefieldChannel', function()
	if D.bWhisperChanged then
		O.aWhisper = D.aWhisper
	end
	if D.bChannelCountChanged then
		O.tChannelCount = D.tChannelCount
	end
end)

function D.OnFrameCreate()
	this.tRadios = {}
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PLAYER_SAY')
	this:RegisterEvent('LOADING_ENDING')
	this:EnableDrag(not O.bLockPostion)

	local nWidth, nHeight = 0, 0
	local container = this:Lookup('WndContainer_Radios')
	container:Clear()
	for i, v in ipairs(CHANNEL_LIST) do
		if O.tChennalVisible[v.id] ~= false then
			local wnd, chk, txtTitle, txtCooldown, shaCount
			if v.head then
				wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Channel')
				chk = wnd:Lookup('WndRadioChannel')
				txtTitle = chk:Lookup('', 'Text_Channel')
				txtCooldown = chk:Lookup('', 'Text_CD')
				shaCount = chk:Lookup('', 'Shadow_Count')
				chk.OnCheckBoxCheck = OnChannelCheck
			elseif v.onClick then
				wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Channel')
				chk = wnd:Lookup('WndRadioChannel')
				txtTitle = chk:Lookup('', 'Text_Channel')
				txtCooldown = chk:Lookup('', 'Text_CD')
				shaCount = chk:Lookup('', 'Shadow_Count')
				chk.OnCheckBoxCheck = v.onClick
			else
				wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_CheckBox')
				chk = wnd:Lookup('WndCheckBox')
				txtTitle = chk:Lookup('', 'Text_CheckBox')
				chk.OnCheckBoxCheck = v.onCheck
				chk.OnCheckBoxUncheck = v.onuncheck
			end
			wnd:SetRelX(nWidth)
			nWidth = nWidth + math.ceil(wnd:GetW())
			nHeight = math.max(nHeight, math.ceil(wnd:GetH()))
			chk.txtTitle = txtTitle
			chk.txtCooldown = txtCooldown
			chk.shaCount = shaCount
			if v.channel then
				this.tRadios[v.channel] = chk
			end
			if v.tip then
				X.UI(chk):Tip(v.tip, X.UI.TIP_POSITION.CENTER)
			end
			if txtTitle then
				txtTitle:SetText(v.title)
				txtTitle:SetFontScheme(197)
				txtTitle:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			if txtCooldown then
				txtCooldown:SetText('')
				txtCooldown:SetFontScheme(197)
				txtCooldown:SetFontColor(unpack(v.color or {255, 255, 255}))
			end
			if shaCount then
				X.UI(shaCount):DrawCircle(0, 0, 0)
			end
			chk.info = v
			UpdateChannelDailyLimit(chk)
		end
	end
	container:SetSize(nWidth, nHeight)

	this:Lookup('', 'Image_Bar'):SetW(nWidth + 35)
	this:SetW(nWidth + 60)
	D.UpdateAnchor(this)
end

function D.OnEvent(event)
	if event == 'PLAYER_SAY' then
		local szContent, dwTalkerID, nChannel, szName, szMsg = arg0, arg1, arg2, arg3, arg9
		if not X.IsString(arg9) then
			szMsg = arg11
		elseif X.IsString(arg11) then
			szMsg = #arg9 > #arg11 and arg9 or arg11
		end
		if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
			local t
			for i = #D.aWhisper, 1, -1 do
				if D.aWhisper[i][1] == szName then
					t = table.remove(D.aWhisper, i)
				end
			end
			while #D.aWhisper > 20 do
				table.remove(D.aWhisper, 1)
			end
			if not t then
				t = {szName, {}}
			end
			while #t[2] > 20 do
				table.remove(t[2], 1)
			end
			table.insert(t[2], {szMsg, GetCurrentTime()})
			table.insert(D.aWhisper, t)
			D.bWhisperChanged = true
		end
		if dwTalkerID ~= UI_GetClientPlayerID() then
			return
		end
		local hRadio = this.tRadios[nChannel]
		if hRadio then
			UpdateChannelDailyLimit(hRadio, true)
			m_tChannelTime[nChannel] = GetCurrentTime()
		end
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'LOADING_ENDING' then
		for nChannel, hRadio in pairs(this.tRadios) do
			UpdateChannelDailyLimit(hRadio)
		end
	end
end

function D.OnFrameBreathe()
	for nChannel, nTime in pairs(m_tChannelTime) do
		local nCooldown = (CHANNEL_CD_TIME[nChannel] or 0) - (GetCurrentTime() - nTime)
		if nCooldown <= 0 then
			m_tChannelTime[nChannel] = nil
		end

		local hCheck = this.tRadios[nChannel]
		local txtCooldown = hCheck and hCheck.txtCooldown
		if txtCooldown then
			txtCooldown:SetText(nCooldown > 0 and nCooldown or '')
		end
	end
end

function D.OnMouseEnter()
	if this.szTip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.szTip, 450, {x, y, w, h}, ALW.RIGHT_LEFT_AND_BOTTOM_TOP)
	end
end

function D.OnMouseLeave()
	HideTip()
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Option' then
		X.ShowPanel()
		X.FocusPanel()
		X.SwitchTab('MY_ChatSwitch')
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.anchor = GetFrameAnchor(this)
end

function D.OnFrameDragSetPosEnd()
	this:CorrectPos()
end

function D.UpdateAnchor(this)
	local anchor = O.anchor
	this:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	this:CorrectPos()
end

local function OnChatSetAFK()
	if type(arg0) == 'table' then
		O.szAway = X.StringifyChatText(arg0)
	else
		O.szAway = arg0 and tostring(arg0) or ''
	end
end
X.RegisterEvent('ON_CHAT_SET_AFK', OnChatSetAFK)

local function OnChatSetATR()
	if type(arg0) == 'table' then
		O.szBusy = X.StringifyChatText(arg0):sub(4)
	else
		O.szBusy = arg0 and tostring(arg0) or ''
	end
end
X.RegisterEvent('ON_CHAT_SET_ATR', OnChatSetATR)

function D.ReInitUI()
	Wnd.CloseWindow('MY_ChatSwitch')
	if not O.bDisplayPanel then
		return
	end
	Wnd.OpenWindow(INI_PATH, 'MY_ChatSwitch')
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatSwitch__UI', D.ReInitUI)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['display panel'],
		checked = O.bDisplayPanel,
		onCheck = function(bChecked)
			O.bDisplayPanel = bChecked
			D.ReInitUI()
		end,
	})
	nY = nY + nLH

	nX = nX + 25

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['lock postion'],
		checked = O.bLockPostion,
		onCheck = function(bChecked)
			O.bLockPostion = bChecked
			D.ReInitUI()
		end,
		isdisable = function()
			return not O.bDisplayPanel
		end,
	})
	nY = nY + nLH

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = 150, h = 25,
		text = _L['channel setting'],
		menu = function()
			local t = {
				szOption = _L['channel setting'],
				fnDisable = function()
					return not O.bDisplayPanel
				end,
			}
			for i, v in ipairs(CHANNEL_LIST) do
				table.insert(t, {
					szOption = v.title, rgb = v.color,
					bCheck = true, bChecked = O.tChennalVisible[v.id] ~= false,
					fnAction = function()
						O.tChennalVisible[v.id] = not O.tChennalVisible[v.id]
						O.tChennalVisible = O.tChennalVisible
						D.ReInitUI()
					end,
				})
			end
			return t
		end,
		isdisable = function()
			return not O.bDisplayPanel
		end,
	})
	nY = nY + nLH

	nX = nPaddingX
	-- �������Ƶ���л�
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto switch talk channel when into battle field'],
		checked = O.bAutoSwitchBfChannel,
		onCheck = function(bChecked)
			O.bAutoSwitchBfChannel = bChecked
			D.ApplyBattlefieldChannelSwitch()
		end,
	})
	nY = nY + nLH

	return nX, nY
end

--------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatSwitch',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
}
MY_ChatSwitch = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
