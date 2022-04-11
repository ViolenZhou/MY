--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_SocialRequest.ini'
local O = X.CreateUserSettingsModule('MY_SocialRequest', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

local REQUEST_MSG = {}
local REQUEST_LIST = {}

for k, v in pairs({
	['ADD_FRIEND_FELLOWSHIP'] = g_tStrings.STR_FRIEND_NEED_ADD_FRIEND_FELLOWSHIP,
	['ADD_FRIEND'           ] = g_tStrings.STR_FRIEND_NEED_ADD_FRIEND,
}) do
	REQUEST_MSG[k] = v:gsub('<D0>', '^(.-)')
end

function D.GetMenu()
	local menu = {
		szOption = _L['MY_SocialRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = MY_SocialRequest.bEnable,
			fnAction = function()
				MY_SocialRequest.bEnable = not MY_SocialRequest.bEnable
			end,
		},
	}
	return menu
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Accept' then
		D.AcceptRequest(this:GetParent().info)
	elseif name == 'Btn_Refuse' then
		D.RefuseRequest(this:GetParent().info)
	end
end

function D.OnRButtonClick()
	if this.info then
		PopupMenu(X.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
	end
end

function D.OnMouseEnter()
	if this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = GetFormatText(this.info.szDesc)
		OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	end
end

function D.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function D.AcceptRequest(info)
	REQUEST_LIST[info.szName] = nil
	UI.RemoveRequest('MY_SocialRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	REQUEST_LIST[info.szName] = nil
	UI.RemoveRequest('MY_SocialRequest', info.szName)
	info.fnRefuse()
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	if not O.bEnable or not frame or not frame:IsValid() then
		return
	end
	if szMsgName == 'NeedAddFriend' then
		local hContent = frame:Lookup('Wnd_All', 'Handle_Message')
		local txt = hContent and hContent:Lookup(0)
		local szMsg, szType, szName = txt and txt:GetType() == 'Text' and txt:GetText()
		for k, szMsgTpl in pairs(REQUEST_MSG) do
			szName = szMsg:match(szMsgTpl)
			if szName then
				szType = k
				break
			end
		end
		if szType then
			local fnAccept = X.Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
			local fnRefuse = X.Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
			if fnAccept and fnRefuse then
				local info = REQUEST_LIST[szName]
				if not info then
					info = {}
					REQUEST_LIST[szName] = info
				end
				info.szType = szType
				info.szName = szName
				info.szDesc = szMsg
				info.fnAccept = function()
					REQUEST_LIST[szName] = nil
					X.Call(fnAccept)
				end
				info.fnRefuse = function()
					REQUEST_LIST[szName] = nil
					X.Call(fnRefuse)
				end
				-- ��ȡdwID
				local tar = X.GetObject(TARGET.PLAYER, szName)
				if not info.dwID and tar then
					info.dwID = tar.dwID
				end
				if not info.dwID and MY_Farbnamen and MY_Farbnamen.Get then
					local data = MY_Farbnamen.Get(szName)
					if data then
						info.dwID = data.dwID
					end
				end
				UI.ReplaceRequest('MY_SocialRequest', info.szName, info)
				-- �رնԻ���
				frame.fnAutoClose = nil
				frame.fnCancelAction = nil
				frame.szCloseSound = nil
				Wnd.CloseWindow(frame)
			end
		end
	end
end

X.RegisterEvent('ON_MESSAGE_BOX_OPEN', 'MY_SocialRequest' , D.OnMessageBoxOpen)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 120,
		text = _L['MY_SocialRequest'],
		menu = D.GetMenu,
		tip = _L['Optimize social friend request'],
		tipPosType = UI.TIP_POSITION.TOP_BOTTOM,
	}):Width() + 5

	nX = nPaddingX
	nY = nY + 20
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_SocialRequest',
	exports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_SocialRequest = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- ע������
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'FromIconID',
	nIconFrame = 2118,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Request')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('', 'Text_Name'):SetText(info.szName)

	local ui = UI(wnd)
	ui:Append('WndButton', {
		name = 'Btn_Accept',
		x = 326, y = 9, w = 60, h = 34,
		buttonStyle = 'FLAT',
		text = _L['Add'],
		onClick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Refuse',
		x = 393, y = 9, w = 60, h = 34,
		buttonStyle = 'FLAT',
		text = _L['Ignore'],
		onClick = D.OnLButtonClick,
	})

	return wnd
end

function R.GetTip(info)
	return GetFormatText(info.szDesc)
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	REQUEST_LIST = {}
end

UI.RegisterRequest('MY_SocialRequest', R)
