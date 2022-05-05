--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������ ���ؼ��ֹ��˻�ȡ������Ϣ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Chat/MY_ChatMonitor'
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatMonitor'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^12.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
--[[
	RECORD_LIST = {
		-- �����鲿�֣���ؼ�¼
		{
			html = ��ϢA��UI���л�ֵ(szMsg) ��ϢԴ����UI XML,
			hash = ��ϢA��HASHֵ ���㵱ǰ��Ϣ�Ĺ�ϣ ���ڹ�����ͬ,
			text = ��ϢA�Ĵ��ı� ���㵱ǰ��Ϣ�Ĵ��������� ����ƥ��,
		}, ...
	}
	RECORD_HASH = {
		-- ����ϣ���֣���¼����
		[��ϢA��HASHֵ] = ��ͬ����ϢA���������, -- ��Ϊ0ʱɾ����HASH
		...
	}
]]
local DATA_FILE = 'userdata/chatmonitor.jx3dat'
local CONFIG_FILE = 'config/chatmonitor.jx3dat'
local RECORD_LIST, RECORD_HASH = {}, {}
local DEFAULE_CHANNEL = {
	['MSG_NORMAL'] = true, ['MSG_CAMP' ] = true, ['MSG_WORLD' ] = true, ['MSG_MAP'     ] = true,
	['MSG_SCHOOL'] = true, ['MSG_GUILD'] = true, ['MSG_FRIEND'] = true, ['MSG_IDENTITY'] = true,
}
local O = X.CreateUserSettingsModule('MY_ChatMonitor', _L['Chat'], {
	aKeyword = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Collection(X.Schema.Record({
			szKeyword = X.Schema.String,
			bEnable = X.Schema.Boolean,
			bIsRegexp = X.Schema.Boolean,
			tChannel = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		})),
		xDefaultValue = {{
			szKeyword = _L.CHAT_MONITOR_KEYWORDS_SAMPLE,
			bEnable = true,
			bIsRegexp = false,
			tChannel = X.Clone(DEFAULE_CHANNEL),
		}},
	},
	bCapture = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nMaxRecord = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
	bShowPreview = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bPlaySound = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bRedirectSysChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bIgnoreSame = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	-- bRealtimeSave = {
	-- 	ePathType = X.PATH_TYPE.ROLE,
	-- 	szLabel = _L['MY_ChatMonitor'],
	-- 	xSchema = X.Schema.Boolean,
	-- 	xDefaultValue = false,
	-- },
	bDistinctServer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szTimestrap = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.String,
		xDefaultValue = '[%hh:%mm:%ss]',
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatMonitor'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = -100, y = -150, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
	},
})
local D = {}

local l_uiBtn, l_uiBoard

function D.LoadConfig()
	local szPath = X.FormatPath({CONFIG_FILE, X.PATH_TYPE.GLOBAL})
	local aKeyword = X.LoadLUAData(szPath)
	if aKeyword then
		CPath.DelFile(szPath)
		-- ���ݱ���
		for i, p in ipairs(aKeyword) do
			if X.IsString(p) then
				aKeyword[i] = {
					szKeyword = p,
					bEnable = true,
					bIsRegexp = false,
					tChannel = X.Clone(DEFAULE_CHANNEL),
				}
			end
		end
		O.aKeyword = aKeyword
	end
end

function D.SaveData()
	local TYPE = O.bDistinctServer
		and X.PATH_TYPE.SERVER or X.PATH_TYPE.ROLE
	X.SaveLUAData({DATA_FILE, TYPE}, {list = RECORD_LIST, hash = RECORD_HASH})
end

function D.LoadData()
	local data = O.bDistinctServer
		and (X.LoadLUAData({DATA_FILE, X.PATH_TYPE.SERVER}) or {})
		or (X.LoadLUAData({DATA_FILE, X.PATH_TYPE.ROLE}) or {})
	RECORD_LIST = data.list or {}
	RECORD_HASH = data.hash or {}
end

function D.GetHTML(rec)
	-- render link event
	local szMsg = X.RenderChatLink(rec.html)
	if MY_ChatEmotion and MY_ChatEmotion.Render then
		szMsg = MY_ChatEmotion.Render(szMsg)
	end
	if MY_Farbnamen and MY_Farbnamen.Render then
		szMsg = MY_Farbnamen.Render(szMsg)
	end
	szMsg = X.GetChatTimeXML(rec.time, {
		r = rec.r, g = rec.g, b = rec.b,
		f = rec.font, s = O.szTimestrap,
		richtext = szMsg,
	}) .. szMsg
	return szMsg
end

function D.OnNotifyCB()
	X.ShowPanel()
	X.FocusPanel()
	X.SwitchTab('MY_ChatMonitor')
	X.DismissNotify('MY_ChatMonitor')
end

-- ������������ʱ���������Ϣ
function D.OnMsgArrive(szChannel, szMsg, nFont, bRich, r, g, b, dwTalkerID, szName)
	-- is enabled
	if not D.bReady or not O.bCapture then
		return
	end
	--------------------------------------------------------------------------------------
	-- ��ʼ����һ����¼
	local rec = { text = '', hash = '', html = '' }
	-- ������ϢԴ����UI
	if bRich then
		rec.html = szMsg
		-- ��ʽ����Ϣ
		local tMsgContent = X.ParseChatData(szMsg)
		-- ƴ����Ϣ
		if szChannel == 'MSG_SYS' then -- ϵͳ��Ϣ
			for i, v in ipairs(tMsgContent) do
				rec.text = rec.text .. v.text
			end
			rec.hash = rec.text
		else -- �������ϵͳ��Ϣ���ڹ�ϣ��������һ������֮ǰ�Ķ��� ���ơ�[��Ӫ][������][����]˵����
			-- STR_TALK_HEAD_WHISPER = '���ĵ�˵��',
			-- STR_TALK_HEAD_WHISPER_REPLY = '�����ĵض�',
			-- STR_TALK_HEAD_SAY = '˵��',
			-- STR_TALK_HEAD_SAY1 = '��',
			-- STR_TALK_HEAD_SAY2 = '��������',
			local bSkiped = false
			for i, v in ipairs(tMsgContent) do
				if (i < 4 and not bSkiped) and (
					v.text == g_tStrings.STR_TALK_HEAD_WHISPER or
					v.text == g_tStrings.STR_TALK_HEAD_SAY or
					v.text == g_tStrings.STR_TALK_HEAD_SAY1 or
					v.text == g_tStrings.STR_TALK_HEAD_SAY2
				) then
					bSkiped = true
					rec.hash = ''
				else
					rec.text = rec.text .. v.text
					rec.hash = rec.hash .. v.text
				end
			end
		end
	else
		rec.text = szMsg
		rec.hash = szMsg
		rec.html = GetFormatText(szMsg, nil, GetMsgFontColor('MSG_SYS'))
	end

	rec.fuzzy_text = rec.text
	local szChannelName = g_tStrings.tChannelName[szChannel]
	if szChannelName then
		rec.fuzzy_text = '[' .. szChannelName .. ']\t' .. rec.fuzzy_text
	end
	rec.fuzzy_text = StringLowerW(rec.fuzzy_text)

	rec.hash = string.gsub(rec.hash, '[\n%s]+', '')
	--------------------------------------------------------------------------------------
	-- ��ʼ�����Ƿ���Ϲ�����Ҫ��
	local bMatch = false
	for _, p in ipairs(O.aKeyword) do
		if p.bEnable and p.tChannel[szChannel] then
			if p.bIsRegexp then -- regexp
				if string.find(rec.text, p.szKeyword) then
					bMatch = true
					break
				end
			else -- normal
				if X.StringSimpleMatch(rec.text, p.szKeyword) then
					bMatch = true
					break
				end
			end
		end
	end
	if not bMatch then
		return
	end
	-- ��֤��Ϣ��ϣ �����������������Ϣ
	if O.bIgnoreSame and RECORD_HASH[rec.hash] then
		return
	end
	--------------------------------------------------------------------------------------
	-- �������Ҫ��
	-- ��ʼ��Ⱦһ����¼��UIXML�ַ���
	rec.r, rec.g, rec.b = r, g, b
	rec.font = nFont
	rec.time = GetCurrentTime()
	local html = D.GetHTML(rec)
	-- ��������ض���ϵͳ��Ϣ����������ʱ�Ӹ���Ƿ�ֹ�ֱ��Լ���׽����ѭ����
	if O.bRedirectSysChannel and szChannel ~= 'MSG_SYS' then
		OutputMessage('MSG_SYS', X.EncodeEchoMsgHeader(szChannel) .. szMsg, true)
	end
	-- �㲥��Ϣ
	OutputMessage('MSG_MY_MONITOR', szMsg, true, nil, nil, dwTalkerID, szName)
	-- ����UI
	if l_uiBoard then
		local nPos = l_uiBoard:Scroll()
		l_uiBoard:Append(html)
		if nPos == 100 or nPos == -1 then
			l_uiBoard:Scroll(100)
		end
	end
	X.CreateNotify({
		szKey = 'MY_ChatMonitor',
		szMsg = html,
		fnAction = D.OnNotifyCB,
		bPlaySound = O.bPlaySound,
		szSound = PLUGIN_ROOT .. '/audio/MsgArrive.ogg',
		szCustomSound = 'MsgArrive.ogg',
		bPopupPreview = O.bShowPreview,
	})
	--------------------------------------------------------------------------------------
	-- ��ʼ�����¼�����ݱ���
	-- ���»������� ��ϣ��
	table.insert(RECORD_LIST, rec)
	RECORD_HASH[rec.hash] = (RECORD_HASH[rec.hash] or 0) + 1
	-- ��֤��¼�Ƿ񳬹���������
	local nOverflowed = #RECORD_LIST - O.nMaxRecord
	if nOverflowed > 0 then
		-- �����¼�б�
		for i = nOverflowed, 1, -1 do
			local hash = RECORD_LIST[1].hash
			if hash and RECORD_HASH[hash] then
				RECORD_HASH[hash] = RECORD_HASH[hash] - 1
				if RECORD_HASH[hash] <= 0 then
					RECORD_HASH[hash] = nil
				end
			end
			if l_uiBoard then
				l_uiBoard:RemoveItemUntilNewLine()
			end
			table.remove(RECORD_LIST, 1)
		end
	end
	-- if O.bRealtimeSave then
	--     D.SaveData()
	-- end
end

function D.Init()
	D.bReady = true
	D.LoadConfig()
	D.LoadData()
	D.RegisterMsgMonitor()
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_CHATMONITOR', D.Init)

X.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_CHATMONITOR', function()
	D.bReady = false
	D.RegisterMsgMonitor()
end)

function D.Exit()
	D.SaveData()
end
X.RegisterExit('MY_ChatMonitor', D.Exit)

function D.RegisterMsgMonitor()
	for _, szChannel in ipairs(D.aCurrentChannel or X.CONSTANT.EMPTY_TABLE) do
		X.RegisterMsgMonitor(szChannel, 'MY_ChatMonitor', false)
	end
	local aChannel = {}
	if D.bReady then
		local tChannel = {}
		for _, p in ipairs(O.aKeyword) do
			if p.bEnable then
				for szChannel, bCapture in pairs(p.tChannel) do
					if bCapture then
						tChannel[szChannel] = true
					end
				end
			end
		end
		for szChannel, _ in pairs(tChannel) do
			table.insert(aChannel, szChannel)
		end
		for _, szChannel in ipairs(aChannel) do
			X.RegisterMsgMonitor(szChannel, 'MY_ChatMonitor', D.OnMsgArrive)
		end
	end
	D.aCurrentChannel = aChannel
end

-------------------------------------------------------------------------------------------------------
-- ��ݼ�����
-------------------------------------------------------------------------------------------------------
X.RegisterHotKey('MY_ChatMonitor_Hotkey', _L['MY_ChatMonitor'], function()
	if O.bCapture then
		if l_uiBtn then
			l_uiBtn:Text(_L['start'])
		end
		O.bCapture = false
	else
		if l_uiBtn then
			l_uiBtn:Text(_L['stop'])
		end
		O.bCapture = true
	end
end, nil)

-------------------------------------------------------------------------------------------------------
-- ���ý���
-------------------------------------------------------------------------------------------------------
local PS = {}

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local w, h = ui:Size()

	ui:Append('Text', { x = 22, y = 15, w = 100, h = 25, text = _L['key words:'] })

	ui:Append('WndComboBox', {
		x = 80, y = 15, w = w - 246, h = 25,
		text = _L['Click to config monitors'],
		menu = function()
			local aKeyword = O.aKeyword
			local menu = { bAlignWidth = true }
			for i, p in ipairs(aKeyword) do
				local m = X.GetMsgTypeMenu(function(szChannel)
					p.tChannel[szChannel] = not p.tChannel[szChannel]
					O.aKeyword = aKeyword
					D.RegisterMsgMonitor()
				end, p.tChannel)
				for _, mm in ipairs(m) do
					mm.fnDisable = function()
						return not p.bEnable
					end
				end
				table.insert(m, 1, X.CONSTANT.MENU_DIVIDER)
				table.insert(m, 1, {
					szOption = _L['Edit'],
					fnAction = function()
						GetUserInput(_L['Please input keyword:'], function(szText)
							szText = X.TrimString(szText)
							if X.IsEmpty(szText) then
								return
							end
							p.szKeyword = szText
							O.aKeyword = aKeyword
							D.RegisterMsgMonitor()
						end, nil, nil, nil, p.szKeyword)
					end,
				})
				table.insert(m, 1, X.CONSTANT.MENU_DIVIDER)
				table.insert(m, 1, {
					szOption = _L['Enable'],
					bCheck = true, bChecked = p.bEnable,
					fnAction = function()
						p.bEnable = not p.bEnable
						O.aKeyword = aKeyword
						D.RegisterMsgMonitor()
					end,
				})
				table.insert(m, X.CONSTANT.MENU_DIVIDER)
				table.insert(m, {
					szOption = _L['regular expression'],
					bCheck = true, bChecked = p.bIsRegexp,
					fnAction = function()
						if p.bIsRegexp or IsShiftKeyDown() then
							p.bIsRegexp = not p.bIsRegexp
							O.aKeyword = aKeyword
						else
							MessageBox({
								szName = 'MY_ChatMonitor_Regexp',
								szMessage = _L['Are you sure you want to turn on regex mode?\nRegex is something advanced, make sure you know what you are doing.\nHold shift key next time to skip this alert.'],
								{
									szOption = g_tStrings.STR_HOTKEY_SURE,
									fnAction = function()
										p.bIsRegexp = not p.bIsRegexp
										O.aKeyword = aKeyword
									end,
								},
								{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
							})
						end
					end,
					fnDisable = function() return not p.bEnable end,
				})
				table.insert(m, X.CONSTANT.MENU_DIVIDER)
				table.insert(m, {
					szOption = _L['Delete'],
					fnAction = function()
						table.remove(aKeyword, i)
						O.aKeyword = aKeyword
						O.aKeyword = aKeyword
						D.RegisterMsgMonitor()
						X.UI.ClosePopupMenu()
					end,
				})
				m.szOption = p.szKeyword
				table.insert(menu, m)
			end
			if #menu > 0 then
				table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			end
			table.insert(menu, {
				szOption = _L['Add'],
				fnAction = function()
					GetUserInput(_L['Please input keyword:'], function(szText)
						szText = X.TrimString(szText)
						if X.IsEmpty(szText) then
							return
						end
						table.insert(aKeyword, {
							szKeyword = szText,
							bEnable = true,
							bIsRegexp = false,
							tChannel = X.Clone(DEFAULE_CHANNEL),
						})
						O.aKeyword = aKeyword
						O.aKeyword = aKeyword
						D.RegisterMsgMonitor()
					end)
				end,
			})
			return menu
		end,
	})

	ui:Append('Image', {
		image = 'UI/Image/UICommon/Commonpanel2.UITex', imageFrame = 48,
		x = w - 160, y = 18, w = 20, h = 20, alpha = 180,
		onHover = function(bIn) this:SetAlpha(bIn and 255 or 180) end,
		onClick = function()
			local szText = GetFormatText(_L['CHAT_MONITOR_TIP'], 162)
			local x, y = Cursor.GetPos()
			local w, h = this:GetSize()
			OutputTip(szText, 450, {x, y, w, h})
		end,
	})

	ui:Append('WndButton', {
		x = w - 26, y = 15, w = 25, h = 25,
		buttonStyle = 'OPTION',
		menu = function()
			local t = {
				{
					szOption = _L['timestrap format'], {
						szOption = '[%hh:%mm:%ss]',
						fnAction = function()
							O.szTimestrap = '[%hh:%mm:%ss]'
						end,
						bCheck = true, bMCheck = true,
						bChecked = O.szTimestrap == '[%hh:%mm:%ss]'
					}, {
						szOption = '[%MM/%dd %hh:%mm:%ss]',
						fnAction = function()
							O.szTimestrap = '[%MM/%dd %hh:%mm:%ss]'
						end,
						bCheck = true, bMCheck = true,
						bChecked = O.szTimestrap == '[%MM/%dd %hh:%mm:%ss]'
					}, {
						szOption = _L['custom'],
						fnAction = function()
							GetUserInput(_L['custom timestrap (eg:[%yyyy/%MM/%dd_%hh:%mm:%ss])'], function(szText)
								O.szTimestrap = szText
							end, nil, nil, nil, O.szTimestrap)
						end,
					},
				},
				{
					szOption = _L['max record count'],
					fnAction = function()
						GetUserInputNumber(O.nMaxRecord, 1000, nil, function(val)
							O.nMaxRecord = val or O.nMaxRecord
						end, nil, function() return not X.IsPanelVisible() end)
					end,
				},
				{
					szOption = _L['show message preview box'],
					fnAction = function()
						O.bShowPreview = not O.bShowPreview
					end,
					bCheck = true,
					bChecked = O.bShowPreview
				},
				{
					szOption = _L['play new message alert sound'],
					fnAction = function()
						O.bPlaySound = not O.bPlaySound
					end,
					bCheck = true,
					bChecked = O.bPlaySound
				},
				{
					szOption = _L['output to system channel'],
					fnAction = function()
						O.bRedirectSysChannel = not O.bRedirectSysChannel
					end,
					bCheck = true,
					bChecked = O.bRedirectSysChannel
				},
				{
					szOption = _L['ignore same message'],
					fnAction = function()
						O.bIgnoreSame = not O.bIgnoreSame
					end,
					bCheck = true,
					bChecked = O.bIgnoreSame
				}
			}
			if IsShiftKeyDown() then
				-- table.insert(t, {
				--     szOption = _L['Realtime save'],
				--     fnAction = function()
				--         O.bRealtimeSave = not O.bRealtimeSave
				--     end,
				--     bCheck = true,
				--     bChecked = O.bRealtimeSave
				-- })
				table.insert(t, {
					szOption = _L['Distinct server'],
					fnAction = function()
						O.bDistinctServer = not O.bDistinctServer
						D.LoadData()
						X.SwitchTab('MY_ChatMonitor', true)
					end,
					bCheck = true,
					bChecked = O.bDistinctServer
				})
			end
			return t
		end,
	})

	l_uiBtn = ui:Append('WndButton', {
		name = 'Button_ChatMonitor_Switcher',
		x = w - 134, y = 15, w = 50,
		text = (O.bCapture and _L['stop']) or _L['start'],
		onClick = function()
			if O.bCapture then
				X.UI(this):Text(_L['start'])
				O.bCapture = false
			else
				X.UI(this):Text(_L['stop'])
				O.bCapture = true
			end
		end,
	})

	ui:Append('WndButton', {
		x = w - 79, y = 15, w = 50,
		text = _L['clear'],
		onClick = function()
			RECORD_LIST = {}
			RECORD_HASH = {}
			l_uiBoard:Clear()
		end,
	})

	l_uiBoard = ui:Append('WndScrollHandleBox', {
		name = 'WndScrollHandleBox_TalkList',
		x = 20, y = 50, w = w - 21, h = h - 70, handleStyle = 3,
	})

	for i = 1, #RECORD_LIST, 1 do
		l_uiBoard:Append(D.GetHTML(RECORD_LIST[i]))
	end
	l_uiBoard:Scroll(100)
end

function PS.OnPanelDeactive()
	l_uiBtn = nil
	l_uiBoard = nil
end

X.RegisterPanel(_L['Chat'], 'MY_ChatMonitor', _L['MY_ChatMonitor'], 'UI/Image/Minimap/Minimap.UITex|197', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
