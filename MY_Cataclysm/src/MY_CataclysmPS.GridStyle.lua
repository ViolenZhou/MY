--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Ŷ���������ʽ
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
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------
local CFG, PS = MY_Cataclysm.CFG, { nPriority = 2 }

function PS.OnPanelActive(frame)
	local ui = UI(frame)
	local nPaddingX, nPaddingY = 20, 20
	local x, y = nPaddingX, nPaddingY

	y = y + ui:Append('Text', { x = x, y = y, text = _L['Grid Style'], font = 27 }):Height()

	y = y + 5

	x = nPaddingX + 10
	y = y + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show AllGrid'],
		checked = CFG.bShowAllGrid,
		oncheck = function(bCheck)
			CFG.bShowAllGrid = bCheck
			MY_CataclysmMain.ReloadCataclysmPanel()
		end,
	}):AutoWidth():Height() + 5

	x = nPaddingX
	y = y + 10

	-- ���֡�ͼ�ꡢ������Ѫ����ʾ����
	x = nPaddingX
	y = y + ui:Append('Text', { x = x, y = y, text = _L['Name/Icon/Mana/Life Display'], font = 27 }):Height()

	-- ����
	x = nPaddingX + 10
	y = y + 5
	for _, p in ipairs({
		{ 1, _L['Name colored by force'] },
		{ 2, _L['Name colored by camp'] },
		{ 0, _L['Name without color'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namecolor', checked = CFG.nColoredName == p[1],
			oncheck = function()
				CFG.nColoredName = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, false, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true ,true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	y = y + ui:Append('WndTrackbar', {
		x = x, y = y - 1,
		value = CFG.fNameFontScale * 100,
		range = {1, 400},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(val) return _L('Scale %d%%', val) end,
		onchange = function(val)
			CFG.fNameFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallRefreshImages(nil, nil, nil, nil, true)
			end
		end,
	}):Height()

	x = nPaddingX + 10
	for _, p in ipairs({
		{ 0, _L['Top'] },
		{ 1, _L['Middle'] },
		{ 2, _L['Bottom'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namevali', checked = CFG.nNameVAlignment == p[1],
			oncheck = function()
				CFG.nNameVAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	for _, p in ipairs({
		{ 0, _L['Left'] },
		{ 1, _L['Center'] },
		{ 2, _L['Right'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'namehali', checked = CFG.nNameHAlignment == p[1],
			oncheck = function()
				CFG.nNameHAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	-- ���������޸�
	x = x + ui:Append('WndButton', {
		x = x, y = y - 3,
		text = _L['Name font'],
		buttonstyle = 'FLAT',
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				CFG.nNameFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, false, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
	}):AutoWidth():Width() + 5
	y = y + 25

	-- Ѫ����ʾ��ʽ
	x = nPaddingX + 10
	y = y + 10
	for _, p in ipairs({
		{ 2, g_tStrings.STR_RAID_LIFE_LEFT },
		{ 1, g_tStrings.STR_RAID_LIFE_LOSE },
		{ 0, g_tStrings.STR_RAID_LIFE_HIDE },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifemode', checked = CFG.nHPShownMode2 == p[1],
			oncheck = function()
				CFG.nHPShownMode2 = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	ui:Append('WndTrackbar', {
		x = x, y = y - 1,
		value = CFG.fLifeFontScale * 100,
		range = {1, 400},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(val) return _L('Scale %d%%', val) end,
		onchange = function(val)
			CFG.fLifeFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
		autoenable = function() return CFG.nHPShownMode2 ~= 0 end,
	})
	y = y + 25

	-- Ѫ����ֵ��ʾ����
	x = nPaddingX + 10
	for _, p in ipairs({
		{ 1, _L['Show Format value'] },
		{ 2, _L['Show Percentage value'] },
		{ 3, _L['Show full value'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifval', checked = CFG.nHPShownNumMode == p[1],
			autoenable = function() return CFG.nHPShownMode2 ~= 0 end,
			oncheck = function()
				CFG.nHPShownNumMode = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end

	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show Decimal'],
		checked = CFG.bShowHPDecimal,
		oncheck = function(bCheck)
			CFG.bShowHPDecimal = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5
	y = y + 25

	x = nPaddingX + 10
	for _, p in ipairs({
		{ 0, _L['Top'] },
		{ 1, _L['Middle'] },
		{ 2, _L['Bottom'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifvali', checked = CFG.nHPVAlignment == p[1],
			autoenable = function() return CFG.nHPShownMode2 ~= 0 end,
			oncheck = function()
				CFG.nHPVAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	for _, p in ipairs({
		{ 0, _L['Left'] },
		{ 1, _L['Center'] },
		{ 2, _L['Right'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'lifhali', checked = CFG.nHPHAlignment == p[1],
			autoenable = function() return CFG.nHPShownMode2 ~= 0 end,
			oncheck = function()
				CFG.nHPHAlignment = p[1]
				MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
			end,
		}):AutoWidth():Width() + 5
	end
	ui:Append('WndButton', {
		x = x, y = y - 1,
		text = _L['Life font'],
		buttonstyle = 'FLAT',
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				CFG.nLifeFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoenable = function() return CFG.nHPShownMode2 ~= 0 end,
	}):AutoWidth()
	y = y + 25

	-- ͼ����ʾ����
	x = nPaddingX + 10
	y = y + 10
	for _, p in ipairs({
		{ 1, _L['Show Force Icon'] },
		{ 2, g_tStrings.STR_SHOW_KUNGFU },
		{ 3, _L['Show Camp Icon'] },
		{ 4, _L['Show Text Force'] },
	}) do
		x = x + ui:Append('WndRadioBox', {
			x = x, y = y, text = p[2],
			group = 'icon', checked = CFG.nShowIcon == p[1],
			oncheck = function()
				CFG.nShowIcon = p[1]
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallRefreshImages(true, false, true, nil, true)
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end,
		}):AutoWidth():Width() + 5
	end
	y = y + 25

	-- ������ʾ
	x = nPaddingX + 10
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, text = _L['Show ManaCount'],
		checked = CFG.nShowMP,
		oncheck = function(bCheck)
			CFG.nShowMP = bCheck
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
	}):AutoWidth():Width() + 5

	x = x + ui:Append('WndButton', {
		x = x, y = y,
		text = g_tStrings.STR_SKILL_MANA .. g_tStrings.FONT,
		buttonstyle = 'FLAT',
		onclick = function()
			UI.OpenFontPicker(function(nFont)
				CFG.nManaFont = nFont
				if MY_CataclysmMain.GetFrame() then
					MY_CataclysmParty:CallDrawHPMP(true, true)
				end
			end)
		end,
		autoenable = function() return CFG.nShowMP end,
	}):Width() + 5

	ui:Append('WndTrackbar', {
		x = x, y = y - 1,
		value = CFG.fManaFontScale * 100,
		range = {1, 400},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(val) return _L('Scale %d%%', val) end,
		onchange = function(val)
			CFG.fManaFontScale = val / 100
			if MY_CataclysmMain.GetFrame() then
				MY_CataclysmParty:CallDrawHPMP(true, true)
			end
		end,
		autoenable = function() return CFG.nShowMP end,
	})
	y = y + 25
end
X.RegisterPanel(_L['Raid'], 'MY_Cataclysm_GridStyle', _L['Grid Style'], 'ui/Image/UICommon/RaidTotal.uitex|68', PS)
