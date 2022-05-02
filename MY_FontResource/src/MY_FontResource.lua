--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������Դ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_FontResource'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_FontResource'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '>=3.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {}
local FONT_DIR = X.PACKET_INFO.ROOT:gsub('%./', '/') .. 'MY_FontResource/font/'
local FONT_LIST = X.LoadLUAData(FONT_DIR .. '{$lang}.jx3dat') or {}

function D.GetList()
	local aList, tExist, szLang = {}, {}, X.ENVIRONMENT.GAME_LANG
	for _, p in ipairs(Font.GetFontPathList() or {}) do
		local szFile = p.szFile:gsub('/', '\\')
		local szKey = szFile:lower()
		if not tExist[szKey] then
			table.insert(aList, { szName = p.szName, szFile = szFile })
			tExist[szKey] = true
		end
	end
	for _, p in ipairs(FONT_LIST) do
		if p.tLang[szLang] then
			local szFile = p.szFile:gsub('^%./', FONT_DIR):gsub('/', '\\')
			local szKey = szFile:lower()
			if not tExist[szKey] then
				table.insert(aList, { szName = p.szName, szFile = szFile })
				tExist[szKey] = true
			end
		end
	end
	for i, p in X.ipairs_r(aList) do
		if not IsFileExist(p.szFile) then
			table.remove(aList, i)
		end
	end
	return aList
end

-- Global exports
do
local settings = {
	name = 'MY_FontResource',
	exports = {
		{
			fields = {
				GetList = D.GetList,
			},
		},
	},
}
MY_FontResource = X.CreateModule(settings)
end
