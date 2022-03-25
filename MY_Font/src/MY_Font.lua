--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��Ϸ����
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
local PLUGIN_NAME = 'MY_Font'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Font'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

-- ���ر���
local OBJ = {}
local FONT_TYPE = {
	{ tIDs = {0, 1, 2, 3, 4, 6    }, szName = _L['content'] },
	{ tIDs = {Font.GetChatFontID()}, szName = _L['chat'   ] },
	{ tIDs = {7                   }, szName = _L['fight'  ] },
}
local CONFIG

-- ������������
local CONFIG_PATH = {'config/fontconfig.jx3dat', X.PATH_TYPE.GLOBAL}
do
	local szOrgFile = X.GetLUADataPath({'config/MY_FONT/{$lang}.jx3dat', X.PATH_TYPE.DATA})
	local szFilePath = X.GetLUADataPath(CONFIG_PATH)
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	CONFIG = X.LoadLUAData(szFilePath) or {}
end

-- ��ʼ������
do
	local bChanged = false
	for dwID, tConfig in pairs(CONFIG) do
		local szName, szFile, nSize, tStyle = unpack(tConfig)
		if IsFileExist(szFile) then
			local szCurName, szCurFile, nCurSize, tCurStyle = Font.GetFont(dwID)
			local szNewName, szNewFile, nNewSize, tNewStyle = szName or szCurName, szFile or szCurFile, nSize or nCurSize, tStyle or tCurStyle
			if not X.IsEquals(szNewName, szCurName) or not X.IsEquals(szNewFile, szCurFile)
			or not X.IsEquals(nNewSize, nCurSize) or not X.IsEquals(tNewStyle, tCurStyle) then
				Font.SetFont(dwID, szNewName, szNewFile, nNewSize, tNewStyle)
				bChanged = true
			end
		end
	end
	if bChanged then
		Station.SetUIScale(Station.GetUIScale(), true)
	end
end

-- ��������
function OBJ.SetFont(tIDs, szName, szFile, nSize, tStyle)
	-- tIDs  : Ҫ�ı�����������飨����/�ı�/���� �ȣ�
	-- szName: ��������
	-- szFile: ����·��
	-- nSize : �����С
	-- tStyle: {
	--     ['vertical'] = (bool),
	--     ['border'  ] = (bool),
	--     ['shadow'  ] = (bool),
	--     ['mono'    ] = (bool),
	--     ['mipmap'  ] = (bool),
	-- }
	-- Ex: SetFont(Font.GetChatFontID(), '����', '\\UI\\Font\\��������_GBK.ttf', 16, {['shadow'] = true})
	for _, dwID in ipairs(tIDs) do
		local szName1, szFile1, nSize1, tStyle1 = Font.GetFont(dwID)
		Font.SetFont(dwID, szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1)
		if dwID == Font.GetChatFontID() then
			Wnd.OpenWindow('ChatSettingPanel')
			OutputWarningMessage('MSG_REWARD_GREEN', _L['please click apply or sure button to save change!'], 10)
		end
		CONFIG[dwID] = {szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1}
	end
	X.SaveLUAData(CONFIG_PATH, CONFIG)
	Station.SetUIScale(Station.GetUIScale(), true)
end

-- ���ý���
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30
	local w, h = ui:Size()
	local aFontList = X.GetFontList()
	local aFontName, aFontPath = {}, {}

	for _, p in ipairs(aFontList) do
		table.insert(aFontName, p.szName)
		table.insert(aFontPath, p.szFile)
	end

	for _, p in ipairs(FONT_TYPE) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
		if tStyle then
			-- local ui = ui:Append('WndWindow', { w = w, h = 60 })
			local acFile, acName, btnSure
			local function UpdateBtnEnable()
				local szNewFile = acFile:Text()
				local bFileExist = IsFileExist(szNewFile)
				acFile:Color(bFileExist and {255, 255, 255} or {255, 0, 0})
				btnSure:Enable(bFileExist and szNewFile ~= szFile)
			end
			x = 10
			ui:Append('Text', { text = _L[' * '] .. p.szName, x = x, y = y })
			y = y + 40

			acFile = ui:Append('WndAutocomplete', {
				x = x, y = y, w = w - 180 - 30,
				text = szFile,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szFile) == szText then
							if acName:Text() ~= p.szName then
								acName:Text(p.szName)
							end
							return
						end
					end
					acName:Text(g_tStrings.STR_CUSTOM_TEAM)
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):Autocomplete('close')
					else
						UI(this):Autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontPath}},
			})

			ui:Append('WndButton', {
				x = w - 180 - x - 10, y = y, w = 25,
				text = '...',
				onclick = function()
					local file = GetOpenFileName(_L['Please select your font file.'], 'Font File(*.ttf;*.otf;*.fon)\0*.ttf;*.otf;*.fon\0All Files(*.*)\0*.*\0\0')
					if not X.IsEmpty(file) then
						file = X.GetRelativePath(file, '') or file
						acFile:Text(wstring.gsub(file, '/', '\\'))
					end
				end,
			})

			acName = ui:Append('WndAutocomplete', {
				w = 100, h = 25, x = w - 180 + x, y = y,
				text = szName,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szName) == szText
						and acFile:Text() ~= p.szFile then
							acFile:Text(p.szFile)
							return
						end
					end
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):Autocomplete('close')
					else
						UI(this):Autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontName}},
			})

			btnSure = ui:Append('WndButton', {
				w = 60, h = 25, x = w - 60, y = y,
				text = _L['apply'], enable = false,
				onclick = function()
					MY_Font.SetFont(p.tIDs, acName:Text(), acFile:Text())
					szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
					UpdateBtnEnable()
				end
			})
			y = y + 60
		end
	end
end
X.RegisterPanel(_L['System'], 'MY_Font', _L['MY_Font'], 'ui/Image/UICommon/CommonPanel7.UITex|36', PS)

MY_Font = OBJ
