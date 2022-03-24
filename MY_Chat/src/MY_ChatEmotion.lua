--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���츨��
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatEmotion'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_ChatEmotion', _L['Chat'], {
	bFixSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Number,
		xDefaultValue = 20,
	},
})
local D = {}

function D.Render(szMsg)
	if D.bReady and O.bFixSize then
		local aXMLNode = X.XMLDecode(szMsg)
		if aXMLNode then
			for _, node in ipairs(aXMLNode) do
				local szType = X.XMLGetNodeType(node)
				local szName = X.XMLGetNodeData(node, 'name')
				if (szType == 'animate' or szType == 'image')
				and szName and szName:sub(1, 8) == 'emotion_' then
					X.XMLSetNodeData(node, 'w', O.nSize)
					X.XMLSetNodeData(node, 'h', O.nSize)
					X.XMLSetNodeData(node, 'disablescale', 0)
				end
			end
			szMsg = X.XMLEncode(aXMLNode)
		end
	end
	return szMsg
end

X.RegisterInit('MY_ChatEmotion', function()
	X.HookChatPanel('BEFORE', 'MY_ChatEmotion', function(h, szMsg, ...)
		return D.Render(szMsg), ...
	end)
end)

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatEmotion', function()
	D.bReady = true
end)

X.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_ChatEmotion', function()
	D.bReady = false
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 250,
		text = _L['Resize emotion'],
		checked = O.bFixSize,
		oncheck = function(bChecked)
			O.bFixSize = bChecked
		end,
	}):AutoWidth():Width() + 5
	ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 100, h = 25,
		value = O.nSize,
		range = {1, 300},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Size: %d', v) end,
		onchange = function(val)
			O.nSize = val
		end,
		autoenable = function() return O.bFixSize end,
	})
	nY = nY + nLH

	return nX, nY
end

--------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChatEmotion',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
				Render = D.Render,
			},
		},
	},
}
MY_ChatEmotion = X.CreateModule(settings)
end
