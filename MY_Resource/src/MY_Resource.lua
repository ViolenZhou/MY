--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��������Դ
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
local PLUGIN_NAME = X.NSFormatString('{$NS}_Resource')
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = X.NSFormatString('{$NS}_Resource')
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

local C, D = {}, {}

C.aSound = {
	-- {
	-- 	type = _L['Wuer'],
	-- 	{ id = 2, file = 'WE/voice-52001.ogg' },
	-- 	{ id = 3, file = 'WE/voice-52002.ogg' },
	-- },
}

do
local root = PLUGIN_ROOT .. '/audio/'
local function GetSoundList(tSound)
	local t = {}
	if tSound.type then
		t.szType = tSound.type
	elseif tSound.id then
		t.dwID = tSound.id
		t.szName = _L[tSound.file]
		t.szPath = root .. tSound.file
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundList(v)
		if t1 then
			table.insert(t, t1)
		end
	end
	return t
end

function D.GetSoundList()
	return GetSoundList(C.aSound)
end
end

do
local BUTTON_STYLE_CONFIG = {
	FLAT = X.SetmetaReadonly({
		nWidth = 100,
		nHeight = 25,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 8,
		nMouseOverGroup = 9,
		nMouseDownGroup = 10,
		nDisableGroup = 11,
	}),
	FLAT_LACE_BORDER = X.SetmetaReadonly({
		nWidth = 148,
		nHeight = 33,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 0,
		nMouseOverGroup = 1,
		nMouseDownGroup = 2,
		nDisableGroup = 3,
	}),
	SKEUOMORPHISM = X.SetmetaReadonly({
		nWidth = 148,
		nHeight = 33,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 4,
		nMouseOverGroup = 5,
		nMouseDownGroup = 6,
		nDisableGroup = 7,
	}),
	SKEUOMORPHISM_LACE_BORDER = X.SetmetaReadonly({
		nWidth = 224,
		nHeight = 64,
		nPaddingTop = 2,
		nPaddingRight = 9,
		nPaddingBottom = 10,
		nPaddingLeft = 6,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 12,
		nMouseOverGroup = 13,
		nMouseDownGroup = 14,
		nDisableGroup = 15,
	}),
	QUESTION = X.SetmetaReadonly({
		nWidth = 20,
		nHeight = 20,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 16,
		nMouseOverGroup = 17,
		nMouseDownGroup = 18,
		nDisableGroup = 19,
	}),
	UNDERLINE_LINK = X.SetmetaReadonly({
		nWidth = 60,
		nHeight = 26,
		nMarginTop = 14,
		nMarginBottom = 2,
		nPaddingTop = -14,
		nPaddingBottom = -2,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 20,
		nMouseOverGroup = 21,
		nMouseDownGroup = 22,
		nDisableGroup = 23,
		nNormalFont = 162,
		nMouseOverFont = 0,
		nMouseDownFont = 162,
		nDisableFont = 161,
	}),
}
function D.GetWndButtonStyleName(szImage, nNormalGroup)
	szImage = wstring.lower(X.NormalizePath(szImage))
	for e, p in pairs(BUTTON_STYLE_CONFIG) do
		if wstring.lower(X.NormalizePath(p.szImage)) == szImage and p.nNormalGroup == nNormalGroup then
			return e
		end
	end
end
function D.GetWndButtonStyleConfig(eStyle)
	return BUTTON_STYLE_CONFIG[eStyle]
end
end

-- Global exports
do
local settings = {
	name = MODULE_NAME,
	exports = {
		{
			fields = {
				'GetSoundList',
				'GetWndButtonStyleName',
				'GetWndButtonStyleConfig',
			},
			root = D,
		},
	},
}
_G[MODULE_NAME] = X.CreateModule(settings)
end
