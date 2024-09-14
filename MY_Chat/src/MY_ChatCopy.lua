--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���츨��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Chat/MY_ChatCopy'
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatCopy'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^27.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_ChatCopy', _L['Chat'], {
	bChatCopy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bChatQuickCopy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bChatTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	eChatTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.String,
		xDefaultValue = 'HOUR_MIN_SEC',
	},
	bChatCopyAlwaysShowMask = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bChatCopyAlwaysWhite = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bChatCopyNoCopySysmsg = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bChatNamelinkEx = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

X.HookChatPanel('AFTER', 'MY_ChatCopy', function(h, i, szMsg, szChannel, dwTime, nR, nG, nB)
	if szMsg and i and D.bReady and h:GetItemCount() > i and (O.bChatTime or O.bChatCopy) then
		-- chat time
		local nFont
		local tInfo = MY_Chat.ParseMessageInfo(h, i, h:GetItemCount() - 1)
		if tInfo then
			dwTime        = tInfo.dwTime
			nFont         = tInfo.nFont
			nR            = tInfo.nR
			nG            = tInfo.nG
			nB            = tInfo.nB
			szChannel     = tInfo.szChannel
		end
		for ii = i, h:GetItemCount() - 1 do
			local el = h:Lookup(ii)
			if el:GetType() == 'Text' and not el:GetName():find('^namelink_%d+$') and el:GetText() ~= '' then
				nFont = el:GetFontScheme()
				nR, nG, nB = el:GetFontColor()
				break
			end
		end
		-- check if timestamp can insert
		if O.bChatCopyNoCopySysmsg and szChannel == 'SYS_MSG' then
			return
		end
		-- check chat copy settings
		local bChatCopy = true
		local bChatQuickCopy = O.bChatQuickCopy == true
		if szChannel == 'MSG_IDENTITY' then
			bChatCopy = false
			bChatQuickCopy = false
		end
		-- create timestamp text
		local szTime = ''
		if O.bChatCopy and (O.bChatCopyAlwaysShowMask or not O.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if O.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = X.GetChatCopyXML(_L[' * '], {
				r = _r, g = _g, b = _b, f = nFont,
				richtext = szMsg,
				lclick = bChatCopy,
				rclick = bChatQuickCopy,
			})
		elseif O.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if O.bChatTime then
			if O.eChatTime == 'HOUR_MIN_SEC' then
				szTime = szTime .. X.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = nFont,
					s = '[%hh:%mm:%ss]',
					richtext = szMsg,
					lclick = bChatCopy,
					rclick = bChatQuickCopy,
				})
			else
				szTime = szTime .. X.GetChatTimeXML(dwTime, {
					r = nR, g = nG, b = nB, f = nFont,
					s = '[%hh:%mm]',
					richtext = szMsg,
					lclick = bChatCopy,
					rclick = bChatQuickCopy,
				})
			end
		end
		-- insert timestamp text
		h:InsertItemFromString(i, false, szTime)
	end
end)

function D.OnChatPanelNamelinkLButtonDown(...)
	X.ChatLinkEventHandlers.OnNameLClick(...)
end

function D.CheckNamelinkHook(h, nIndex, nEnd)
	local bEnable = D.bReady and O.bChatNamelinkEx
	if not nEnd then
		nEnd = h:GetItemCount() - 1
	end
	for i = nIndex, nEnd do
		local hItem = h:Lookup(i)
		if hItem:GetName():find('^namelink_%d+$') then
			UnhookTableFunc(hItem, 'OnItemLButtonDown', D.OnChatPanelNamelinkLButtonDown)
			if bEnable then
				HookTableFunc(hItem, 'OnItemLButtonDown', D.OnChatPanelNamelinkLButtonDown, { bAfterOrigin = true })
			end
		end
	end
end

X.HookChatPanel('AFTER', 'MY_ChatCopy__Namelink', function(h, nIndex)
	D.CheckNamelinkHook(h, nIndex)
end)

function D.CheckNamelinkEnable()
	for i = 1, 10 do
		local h = Station.Lookup('Lowest2/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
			or Station.Lookup('Normal1/ChatPanel' .. i .. '/Wnd_Message', 'Handle_Message')
		if h then
			D.CheckNamelinkHook(h, 0)
		end
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['chat copy'],
		checked = O.bChatCopy,
		onCheck = function(bChecked)
			O.bChatCopy = bChecked
		end,
	}):AutoWidth():Width()
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Right click quick copy chat'],
		checked = O.bChatQuickCopy,
		onCheck = function(bChecked)
			O.bChatQuickCopy = bChecked
		end,
		autoEnable = function() return O.bChatCopy end,
	})
	nY = nY + nLH

	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['chat time'],
		checked = O.bChatTime,
		onCheck = function(bChecked)
			if bChecked and _G.HM_ToolBox then
				_G.HM_ToolBox.bChatTime = false
			end
			O.bChatTime = bChecked
		end,
	}):AutoWidth():Width()

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = 150,
		text = _L['chat time format'],
		menu = function()
			return {{
				szOption = _L['hh:mm'],
				bMCheck = true,
				bChecked = O.eChatTime == 'HOUR_MIN',
				fnAction = function()
					O.eChatTime = 'HOUR_MIN'
				end,
				fnDisable = function()
					return not O.bChatTime
				end,
			},{
				szOption = _L['hh:mm:ss'],
				bMCheck = true,
				bChecked = O.eChatTime == 'HOUR_MIN_SEC',
				fnAction = function()
					O.eChatTime = 'HOUR_MIN_SEC'
				end,
				fnDisable = function()
					return not O.bChatTime
				end,
			}}
		end,
	})
	nY = nY + nLH

	nX = nPaddingX + 25
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['always show *'],
		checked = O.bChatCopyAlwaysShowMask,
		onCheck = function(bChecked)
			O.bChatCopyAlwaysShowMask = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	nY = nY + nLH

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['always be white'],
		checked = O.bChatCopyAlwaysWhite,
		onCheck = function(bChecked)
			O.bChatCopyAlwaysWhite = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	nY = nY + nLH

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['hide system msg copy'],
		checked = O.bChatCopyNoCopySysmsg,
		onCheck = function(bChecked)
			O.bChatCopyNoCopySysmsg = bChecked
		end,
		isdisable = function()
			return not O.bChatCopy
		end,
	})
	nY = nY + nLH

	nX = nPaddingX
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Chat panel namelink ext function'],
		checked = O.bChatNamelinkEx,
		onCheck = function(bChecked)
			O.bChatNamelinkEx = bChecked
			D.CheckNamelinkEnable()
		end,
		tip = {
			render = _L['Alt show equip, shift select.'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	})
	nY = nY + nLH

	return nX, nY
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatCopy',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_ChatCopy = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_ChatCopy', function()
	D.bReady = true
	D.CheckNamelinkEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
