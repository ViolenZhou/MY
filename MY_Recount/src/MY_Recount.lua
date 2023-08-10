--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ս��ͳ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Recount/MY_Recount'
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^16.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local DK = MY_Recount_DS.DK
local DK_REC = MY_Recount_DS.DK_REC
local DK_REC_STAT = MY_Recount_DS.DK_REC_STAT
local DK_REC_STAT_DETAIL = MY_Recount_DS.DK_REC_STAT_DETAIL
local DK_REC_STAT_SKILL = MY_Recount_DS.DK_REC_STAT_SKILL
local DK_REC_STAT_SKILL_DETAIL = MY_Recount_DS.DK_REC_STAT_SKILL_DETAIL
local DK_REC_STAT_SKILL_TARGET = MY_Recount_DS.DK_REC_STAT_SKILL_TARGET
local DK_REC_STAT_TARGET = MY_Recount_DS.DK_REC_STAT_TARGET
local DK_REC_STAT_TARGET_DETAIL = MY_Recount_DS.DK_REC_STAT_TARGET_DETAIL
local DK_REC_STAT_TARGET_SKILL = MY_Recount_DS.DK_REC_STAT_TARGET_SKILL
local SKILL_RESULT = MY_Recount_DS.SKILL_RESULT
local SKILL_RESULT_NAME = MY_Recount_DS.SKILL_RESULT_NAME

local MAX_HISTORY_DISP = 50

local STAT_TYPE = { -- ͳ������
	DPS  = 1, -- ���ͳ��
	HPS  = 2, -- ����ͳ��
	BDPS = 3, -- ����ͳ��
	BHPS = 4, -- ����ͳ��
	APS  = 5, -- ����ͳ��
}
local STAT_TYPE_LIST = {
	'DPS' , -- ���ͳ��
	'HPS' , -- ����ͳ��
	'BDPS', -- ����ͳ��
	'BHPS', -- ����ͳ��
	'APS' , -- ����ͳ��
}
local STAT_TYPE_KEY = { -- ͳ������������
	[STAT_TYPE.DPS ] = DK.DAMAGE,
	[STAT_TYPE.HPS ] = DK.HEAL,
	[STAT_TYPE.BDPS] = DK.BE_DAMAGE,
	[STAT_TYPE.BHPS] = DK.BE_HEAL,
	[STAT_TYPE.APS ] = DK.ABSORB,
}
local STAT_TYPE_NAME = {
	[STAT_TYPE.DPS ] = g_tStrings.STR_DAMAGE_STATISTIC    , -- �˺�ͳ��
	[STAT_TYPE.HPS ] = g_tStrings.STR_THERAPY_STATISTIC   , -- ����ͳ��
	[STAT_TYPE.BDPS] = g_tStrings.STR_BE_DAMAGE_STATISTIC , -- ����ͳ��
	[STAT_TYPE.BHPS] = g_tStrings.STR_BE_THERAPY_STATISTIC, -- ����ͳ��
	[STAT_TYPE.APS ] = _L['Absorb statistics']            , -- ����ͳ��
}
local STAT_TYPE_UNIT = {
	[STAT_TYPE.DPS ] = 'DPS',
	[STAT_TYPE.HPS ] = 'HPS',
	[STAT_TYPE.BDPS] = 'DPS',
	[STAT_TYPE.BHPS] = 'HPS',
	[STAT_TYPE.APS ] = 'APS',
}
local IMPORTANT_EFFECT = {
	[SKILL_EFFECT_TYPE.SKILL .. ',371,1'] = true, -- ��ɽ��
	[SKILL_EFFECT_TYPE.SKILL .. ',15054,1'] = true, -- ÷����Ū
}
local PUBLISH_MODE = {
	EFFECT = 1, -- ֻ��ʾ��Чֵ
	TOTAL  = 2, -- ֻ��ʾ����ֵ
	BOTH   = 3, -- ͬʱ��ʾ��Ч������
}

local O = X.CreateUserSettingsModule('MY_Recount', _L['Raid'], {
	nPublishMode = { -- ����ģʽ
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Number,
		xDefaultValue = PUBLISH_MODE.EFFECT,
	},
})
local D = {}

local DataDisplay

function D.GetTargetShowName(szName, bPlayer)
	if bPlayer and MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
		szName = MY_ChatMosaics.MosaicsString(szName)
	end
	return szName
end

function D.IsImportantEffect(v)
	if not v then
		return false
	end
	if X.IsTable(v) then
		for k, v in pairs(v) do
			if IMPORTANT_EFFECT[k] or IMPORTANT_EFFECT[v] then
				return true
			end
		end
		return false
	end
	if IMPORTANT_EFFECT[v] then
		return true
	end
end

function D.StatContainsImportantEffect(rec)
	for szEffectID, p in ipairs(rec[DK_REC_STAT.SKILL]) do
		if IMPORTANT_EFFECT[szEffectID] and p[DK_REC_STAT_SKILL.NZ_COUNT] > 0 then
			return true
		end
	end
	return false
end

function D.StatSkillContainsImportantEffect(szEffectID, p)
	return D.IsImportantEffect(szEffectID)
		or D.IsImportantEffect(p.tEffectID)
end

function D.StatTargetContainsImportantEffect(rec)
	for szEffectID, p in pairs(rec[DK_REC_STAT_TARGET.SKILL]) do
		if MY_Recount.IsImportantEffect(szEffectID)
		or MY_Recount.IsImportantEffect(p.tEffectID) then
			return true
		end
	end
	return false
end

-- ���õ�ǰ��ʾ��¼
-- D.SetDisplayData(string szFilePath): ��ʾָ���ļ�����ʷ��¼ ��'CURRENT'ʱ��ʾ��ǰ��¼
-- D.SetDisplayData(table  data): ��ʾ����Ϊdata����ʷ��¼
function D.SetDisplayData(szFilePath)
	local data = X.IsTable(szFilePath)
		and szFilePath
		or MY_Recount_DS.Get(szFilePath)
	if not X.IsTable(data) then
		return
	end
	D.bHistoryMode = szFilePath ~= 'CURRENT'
	DataDisplay = data
	FireUIEvent('MY_RECOUNT_DISP_DATA_UPDATE')
end

-- ��ȡ��ǰ��ʾ��¼
function D.GetDisplayData()
	return DataDisplay, D.bHistoryMode
end

-- ��ȡ���ò˵�
function D.GetMenu()
	local function IsUIDisabled()
		return not MY_Recount_DS.bEnable or not MY_Recount_UI.bEnable
	end
	local t = {
		szOption = _L['Fight recount'],
		{
			szOption = _L['Enable recording'],
			bCheck = true,
			bChecked = MY_Recount_DS.bEnable,
			fnAction = function()
				MY_Recount_DS.bEnable = not MY_Recount_DS.bEnable
			end,
		},
		{
			szOption = _L['Enable UI'],
			bCheck = true,
			bChecked = MY_Recount_UI.bEnable,
			fnAction = function()
				MY_Recount_UI.bEnable = not MY_Recount_UI.bEnable
			end,
			fnDisable = function() return not MY_Recount_DS.bEnable end,
		},
		{
			szOption = _L['Display as per second'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowPerSec,
			fnAction = function()
				MY_Recount_UI.bShowPerSec = not MY_Recount_UI.bShowPerSec
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Display effective value'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowEffect,
			fnAction = function()
				MY_Recount_UI.bShowEffect = not MY_Recount_UI.bShowEffect
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Uncount awaytime'],
			bCheck = true,
			bChecked = MY_Recount_UI.bAwayMode,
			fnAction = function()
				MY_Recount_UI.bAwayMode = not MY_Recount_UI.bAwayMode
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Show nodata teammate'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowNodataTeammate,
			fnAction = function()
				MY_Recount_UI.bShowNodataTeammate = not MY_Recount_UI.bShowNodataTeammate
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Use system time count'],
			bCheck = true,
			bChecked = MY_Recount_UI.bSysTimeMode,
			fnAction = function()
				MY_Recount_UI.bSysTimeMode = not MY_Recount_UI.bSysTimeMode
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Group npc with same name'],
			bCheck = true,
			bChecked = MY_Recount_UI.bGroupSameNpc,
			fnAction = function()
				MY_Recount_UI.bGroupSameNpc = not MY_Recount_UI.bGroupSameNpc
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Group effect with same name'],
			bCheck = true,
			bChecked = MY_Recount_UI.bGroupSameEffect,
			fnAction = function()
				MY_Recount_UI.bGroupSameEffect = not MY_Recount_UI.bGroupSameEffect
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Hide anonymous effect'],
			bCheck = true,
			bChecked = MY_Recount_UI.bHideAnonymous,
			fnAction = function()
				MY_Recount_UI.bHideAnonymous = not MY_Recount_UI.bHideAnonymous
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Show zero value effect'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowZeroVal,
			fnAction = function()
				MY_Recount_UI.bShowZeroVal = not MY_Recount_UI.bShowZeroVal
			end,
			fnDisable = IsUIDisabled,
		},
		{
			szOption = _L['Record everything'],
			bCheck = true,
			bChecked = MY_Recount_DS.bRecEverything,
			fnAction = function()
				MY_Recount_DS.bRecEverything = not MY_Recount_DS.bRecEverything
			end,
			fnDisable = IsUIDisabled,
		},
		{   -- �л�ͳ������
			szOption = _L['Switch recount mode'],
			fnDisable = IsUIDisabled,
			{
				szOption = _L['Display only npc record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.NPC,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.NPC
				end,
			},
			{
				szOption = _L['Display only player record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.PLAYER,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.PLAYER
				end,
			},
			{
				szOption = _L['Display all record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.BOTH,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.BOTH
				end,
			}
		}
	}

	-- ���˶�ʱ���¼
	local t1 = {
		szOption = _L['Filter short fight'],
		fnDisable = function() return not MY_Recount_DS.bEnable end,
	}
	for _, i in pairs({ -1, 10, 15, 20, 25, 30, 45, 60, 90, 120, 180 }) do
		local szOption
		if i < 0 then
			szOption = _L['No time limit']
		elseif i < 60 then
			szOption = _L('Less than %d second', i)
		elseif i == 90 then
			szOption = _L('Less than %d minute and a half', i / 60)
		else
			szOption = _L('Less than %d minute', i / 60)
		end
		table.insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_DS.nMinFightTime == i,
			fnAction = function()
				MY_Recount_DS.nMinFightTime = i
			end,
			fnDisable = function() return not MY_Recount_DS.bEnable end,
		})
	end
	table.insert(t, t1)

	-- ���ѡ��
	local t1 = {
		szOption = _L['Theme'],
		fnDisable = IsUIDisabled,
	}
	for i, _ in ipairs(MY_Recount_UI.FORCE_BAR_CSS) do
		local t2 = {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_UI.nCss == i,
			fnAction = function()
				MY_Recount_UI.nCss = i
			end,
			fnDisable = IsUIDisabled,
		}
		if i == 1 then
			t2.szOption = _L['Global Color']
			t2.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t2.nFrame = 105
			t2.nMouseOverFrame = 106
			t2.szLayer = 'ICON_RIGHT'
			t2.fnClickIcon = function()
				X.ShowPanel()
				X.FocusPanel()
				X.SwitchTab('GlobalColor')
			end
		end
		table.insert(t1, t2)
	end
	table.insert(t, t1)

	-- ��ֵˢ������
	local t1 = {
		szOption = _L['Redraw interval'],
		fnDisable = IsUIDisabled,
	}
	for _, i in ipairs({1, X.ENVIRONMENT.GAME_FPS / 2, X.ENVIRONMENT.GAME_FPS, X.ENVIRONMENT.GAME_FPS * 2}) do
		local szOption
		if i == 1 then
			szOption = _L['Realtime refresh']
		else
			szOption = _L('Every %.1f second', i / X.ENVIRONMENT.GAME_FPS)
		end
		table.insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_UI.nDrawInterval == i,
			fnAction = function()
				MY_Recount_UI.nDrawInterval = i
			end,
			fnDisable = IsUIDisabled,
		})
	end
	table.insert(t, t1)

	-- �����ʷ��¼
	local t1 = {
		szOption = _L['Max history'],
		nMaxHeight = 500,
		fnDisable = function() return not MY_Recount_DS.bEnable end,
	}
	for _, i in ipairs({ 5, 10, 20, 30, 50, 100, 200, 500, 1000 }) do
		table.insert(t1, {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_DS.nMaxHistory == i,
			fnAction = function()
				MY_Recount_DS.nMaxHistory = i
			end,
			fnDisable = function() return not MY_Recount_DS.bEnable end,
		})
	end
	table.insert(t, t1)

	return t
end

-- ��ȡ��ʷ��¼�˵�
function D.GetHistoryMenu()
	local t = {{
		szOption = _L['Current fight'],
		rgb = (MY_Recount_DS.Get('CURRENT') == DataDisplay and {255, 255, 0}) or nil,
		fnAction = function()
			if IsCtrlKeyDown() then
				MY_Recount_FP_Open(MY_Recount_DS.Get('CURRENT'))
			else
				D.SetDisplayData('CURRENT')
			end
			X.UI.ClosePopupMenu()
		end,
		fnMouseEnter = function()
			if not MY_Recount_DS.bRecEverything then
				return
			end
			local nX, nY = this:GetAbsX(), this:GetAbsY()
			local nW, nH = this:GetW(), this:GetH()
			OutputTip(GetFormatText(_L['Hold ctrl click to review whole fight'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.RIGHT_LEFT)
		end,
		fnMouseLeave = function()
			HideTip()
		end,
	}}

	local tt, nCount = { bInline = true, nMaxHeight = 450 }, 0
	for _, file in ipairs(MY_Recount_DS.GetHistoryFiles()) do
		if nCount >= MAX_HISTORY_DISP then
			break
		end
		local t1 = {
			szOption = file.bossname .. ' (' .. X.FormatDuration(file.during, 'SYMBOL', { mode = 'fixed-except-leading', maxUnit = 'minute', keepUnit = 'minute' }) .. ')',
			rgb = (file.time == DataDisplay[DK.TIME_BEGIN] and {255, 255, 0}) or nil,
			fnAction = function()
				local data = MY_Recount_DS.Get(file.fullpath)
				if IsCtrlKeyDown() then
					MY_Recount_FP_Open(data)
				else
					D.SetDisplayData(data)
				end
				X.UI.ClosePopupMenu()
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				MY_Recount_DS.Del(file.fullpath)
				X.UI.ClosePopupMenu()
			end,
			fnMouseEnter = function()
				local aXml = {}
				table.insert(aXml, GetFormatText(file.bossname .. '(' .. X.FormatDuration(file.during, 'SYMBOL', { mode = 'fixed-except-leading', maxUnit = 'minute', keepUnit = 'minute' }) .. ')\n', nil, 255, 255, 255))
				table.insert(aXml, GetFormatText(X.FormatTime(file.time, '%yyyy/%MM/%dd %hh:%mm:%ss\n'), nil, 255, 255, 255))
				if MY_Recount_DS.bRecEverything then
					table.insert(aXml, GetFormatText('\n' .. _L['Hold ctrl click to review whole fight'], nil, 255, 255, 0))
				end
				local nX, nY = this:GetAbsX(), this:GetAbsY()
				local nW, nH = this:GetW(), this:GetH()
				OutputTip(table.concat(aXml), 600, {nX, nY, nW, nH}, ALW.RIGHT_LEFT)
			end,
			fnMouseLeave = function()
				HideTip()
			end,
		}
		table.insert(tt, t1)
		nCount = nCount + 1
	end
	table.insert(t, tt)

	table.insert(t, { bDevide = true })
	if MY_Recount_DS.bRecEverything and (not MY_Recount_DS.bREOnlyDungeon or IsShiftKeyDown()) then
		table.insert(t, {
			szOption = _L['Rec everything only in dungeon'],
			bCheck = true,
			bChecked = MY_Recount_DS.bREOnlyDungeon,
			fnAction = function()
				MY_Recount_DS.bREOnlyDungeon = not MY_Recount_DS.bREOnlyDungeon
			end,
			fnDisable = function() return not MY_Recount_DS.bRecEverything end,
		})
	end
	table.insert(t, {
		szOption = _L['Save history on exit'],
		bCheck = true, bChecked = MY_Recount_DS.bSaveHistoryOnExit,
		fnAction = function()
			MY_Recount_DS.bSaveHistoryOnExit = not MY_Recount_DS.bSaveHistoryOnExit
		end,
	})
	table.insert(t, {
		szOption = _L['Save history immediately'],
		bCheck = true,
		bChecked = MY_Recount_DS.bSaveHistoryOnExFi,
		fnAction = function()
			MY_Recount_DS.bSaveHistoryOnExFi = not MY_Recount_DS.bSaveHistoryOnExFi
		end,
	})
	if MY_Recount_DS.bSaveEverything or IsShiftKeyDown() then
		table.insert(t, {
			szOption = _L['Do not save history everything'],
			bCheck = true,
			bChecked = not MY_Recount_DS.bSaveEverything,
			fnAction = function()
				MY_Recount_DS.bSaveEverything = not MY_Recount_DS.bSaveEverything
			end,
			fnDisable = function()
				return not MY_Recount_DS.bSaveHistoryOnExit and not MY_Recount_DS.bSaveHistoryOnExFi
			end,
		})
	end

	return t
end

-- ��ȡ�����˵�
function D.GetPublishMenu()
	local t = {}

	-- ��������
	table.insert(t, {
		szOption = _L['Publish mode'],
		{
			szOption = _L['Only effect value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.EFFECT
			end,
		}, {
			szOption = _L['Only total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.TOTAL
			end,
		}, {
			szOption = _L['Effect and total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.BOTH,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.BOTH
			end,
		}
	})

	local function Publish(nChannel, nLimit)
		local frame = Station.Lookup('Normal/MY_Recount_UI')
		if not frame then
			return
		end
		local DataDisplay = MY_Recount.GetDisplayData()
		local eTimeChannel = MY_Recount_UI.bSysTimeMode and STAT_TYPE_KEY[MY_Recount_UI.nChannel]
		X.SendChat(
			nChannel,
			'[' .. X.PACKET_INFO.SHORT_NAME .. ']'
			.. _L['Fight recount'] .. ' - '
			.. frame:Lookup('Wnd_Title', 'Text_Title'):GetText()
			.. ' ' .. ((DataDisplay[DK.BOSSNAME] and ' - ' .. DataDisplay[DK.BOSSNAME]) or '')
			.. '(' .. X.FormatDuration(MY_Recount_DS.GeneFightTime(DataDisplay, eTimeChannel), 'SYMBOL', { mode = 'fixed-except-leading', maxUnit = 'minute', keepUnit = 'minute' }) .. ')',
			{ parsers = { name = false } }
		)
		X.SendChat(nChannel, '------------------------')
		local hList      = frame:Lookup('Wnd_Main', 'Handle_List')
		local szUnit     = (' ' .. hList.szUnit) or ''
		local nTimeCount = hList.nTimeCount or 0
		local aResult = {} -- �ռ�����
		local nMaxNameLen = 0
		for i = 0, math.min(hList:GetItemCount(), nLimit) - 1 do
			local hItem = hList:Lookup(i)
			table.insert(aResult, hItem.data)
			nMaxNameLen = math.max(nMaxNameLen, X.StringLenW(hItem.data.szName))
		end
		if not MY_Recount_UI.bShowPerSec then
			nTimeCount = 1
			szUnit = ''
		end
		-- ��������
		for i, p in ipairs(aResult) do
			local szText = string.format('%02d', i) .. '.[' .. p.szName .. ']'
			for i = X.StringLenW(p.szName), nMaxNameLen - 1 do
				szText = szText .. g_tStrings.STR_ONE_CHINESE_SPACE
			end
			if MY_Recount.nPublishMode == PUBLISH_MODE.BOTH then
				szText = szText .. _L('%7d%s(Effect) %7d%s(Total)',
					p.nEffectValue / nTimeCount, szUnit,
					p.nValue / nTimeCount, szUnit
				)
			elseif MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT then
				szText = szText .. _L('%7d%s(Effect)',
					p.nEffectValue / nTimeCount, szUnit
				)
			elseif MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL then
				szText = szText .. _L('%7d%s(Total)',
					p.nValue / nTimeCount, szUnit
				)
			end

			X.SendChat(nChannel, szText)
		end

		X.SendChat(nChannel, '------------------------')
	end
	for nChannel, szChannel in pairs({
		[PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
		[PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
		[PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
	}) do
		local t1 = {
			szOption = g_tStrings.tChannelName[szChannel],
			bCheck = true, -- �����óɿ�ѡ���ܵ�q�ɨr(���ᣩ�q�ɨr����
			fnAction = function()
				Publish(nChannel, math.huge)
				X.UI.ClosePopupMenu()
			end,
			rgb = GetMsgFontColor(szChannel, true),
		}
		for _, nLimit in ipairs({1, 2, 3, 4, 5, 8, 10, 15, 20, 30, 50, 100}) do
			table.insert(t1, {
				szOption = _L('Top %d', nLimit),
				fnAction = function() Publish(nChannel, nLimit) end,
			})
		end
		table.insert(t, t1)
	end

	return t
end

X.RegisterAddonMenu('MY_RECOUNT_MENU', D.GetMenu)

-- �µ�ս������ʱ
X.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function()
	if not D.bHistoryMode then
		D.SetDisplayData('CURRENT')
	end
end)

-- Global exports
do
local settings = {
	name = 'MY_Recount',
	exports = {
		{
			fields = {
				STAT_TYPE = STAT_TYPE,
				STAT_TYPE_LIST = STAT_TYPE_LIST,
				STAT_TYPE_KEY = STAT_TYPE_KEY,
				STAT_TYPE_NAME = STAT_TYPE_NAME,
				STAT_TYPE_UNIT = STAT_TYPE_UNIT,
				PUBLISH_MODE = PUBLISH_MODE,
				SKILL_RESULT = SKILL_RESULT,
				SKILL_RESULT_NAME = SKILL_RESULT_NAME,
				'SetDisplayData',
				'GetDisplayData',
				'GetMenu',
				'GetHistoryMenu',
				'GetPublishMenu',
				'GetTargetShowName',
				'IsImportantEffect',
				'StatContainsImportantEffect',
				'StatSkillContainsImportantEffect',
				'StatTargetContainsImportantEffect',
			},
			root = D,
		},
		{
			fields = {
				'nPublishMode',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'nPublishMode',
			},
			root = O,
		},
	},
}
MY_Recount = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
