--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��Ʒ�ٿƲ�ѯ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_ItemWiki'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ItemWiki', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nW = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 850,
	},
	nH = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 610,
	},
})
local D = {}

function D.OnWebSizeChange()
	if X.UI(this):FrameVisualState() == X.UI.FRAME_VISUAL_STATE.NORMAL then
		O.nW, O.nH = this:GetSize()
	end
end

function D.Open(dwTabType, dwTabIndex, nBookID)
	if nBookID < 0 then
		nBookID = nil
	end
	local szName = X.GetObjectName('ITEM_INFO', dwTabType, dwTabIndex, nBookID)
	if not szName then
		return
	end
	local szURL = MY_RSS.PAGE_BASE_URL .. '/item/' .. table.concat({dwTabType, dwTabIndex, nBookID}, '/') .. '?'
		.. X.EncodeQuerystring(X.ConvertToUTF8({
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			player = GetUserRoleName(),
		}))
	local szKey = 'ItemWiki_' .. table.concat({dwTabType, dwTabIndex, nBookID}, '_')
	local szTitle = szName
	szKey = X.UI.OpenBrowser(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
		readonly = true,
	})
	X.UI(X.UI.LookupBrowser(szKey)):Size(D.OnWebSizeChange)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Item wiki'],
		checked = MY_ItemWiki.bEnable,
		onCheck = function(bChecked)
			MY_ItemWiki.bEnable = bChecked
		end,
		tip = {
			render = _L['Hold SHIFT and r-click bag box to show item wiki'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
	}):Width() + 5
	return nX, nY
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ItemWiki',
	exports = {
		{
			fields = {
				'Open',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
}
MY_ItemWiki = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------
Box_AppendAddonMenu({function(box)
	if not X.IsElement(box) or box:GetType() ~= 'Box' or not O.bEnable then
		return
	end
	local _, dwBox, dwX = box:GetObjectData()
	if not dwBox or not dwX then
		return
	end
	local item = GetPlayerItem(X.GetClientPlayer(), dwBox, dwX)
	if not item then
		return
	end
	local dwTabType = item.dwTabType
	local dwTabIndex = item.dwIndex
	local nBookID = item.nGenre == ITEM_GENRE.BOOK and item.nBookID or -1
	return {{ szOption = _L['Item wiki'], fnAction = function() D.Open(dwTabType, dwTabIndex, nBookID) end }}
end})

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
