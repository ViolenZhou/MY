--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ɫͳ��
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
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_RoleStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DB = X.SQLiteConnect(_L['MY_RoleStatistics_RoleStat'], {'userdata/role_statistics/role_stat.v3.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.Sysmsg(_L['MY_RoleStatistics_RoleStat'], _L['Cannot connect to database!!!'], CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_RoleStat.ini'

DB:Execute([[
	CREATE TABLE IF NOT EXISTS RoleInfo (
		guid NVARCHAR(20) NOT NULL,
		account NVARCHAR(255) NOT NULL,
		region NVARCHAR(20) NOT NULL,
		server NVARCHAR(20) NOT NULL,
		name NVARCHAR(20) NOT NULL,
		force INTEGER NOT NULL,
		level INTEGER NOT NULL,
		equip_score INTEGER NOT NULL,
		pet_score INTEGER NOT NULL,
		gold INTEGER NOT NULL,
		silver INTEGER NOT NULL,
		copper INTEGER NOT NULL,
		stamina INTEGER NOT NULL,
		stamina_max INTEGER NOT NULL,
		stamina_remain INTEGER NOT NULL,
		vigor INTEGER NOT NULL,
		vigor_max INTEGER NOT NULL,
		vigor_remain INTEGER NOT NULL,
		contribution INTEGER NOT NULL,
		contribution_remain INTEGER NOT NULL,
		justice INTEGER NOT NULL,
		justice_remain INTEGER NOT NULL,
		prestige INTEGER NOT NULL,
		prestige_remain INTEGER NOT NULL,
		camp_point INTEGER NOT NULL,
		camp_point_percentage INTEGER NOT NULL,
		camp_level INTEGER NOT NULL,
		arena_award INTEGER NOT NULL,
		arena_award_remain INTEGER NOT NULL,
		exam_print INTEGER NOT NULL,
		exam_print_remain INTEGER NOT NULL,
		achievement_score INTEGER NOT NULL,
		coin INTEGER NOT NULL,
		mentor_score INTEGER NOT NULL,
		starve INTEGER NOT NULL,
		starve_remain INTEGER NOT NULL,
		architecture INTEGER NOT NULL,
		architecture_remain INTEGER NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(guid)
	)
]])
local DB_RoleInfoW = DB:Prepare([[
	REPLACE INTO RoleInfo (
		guid, account, region, server, name, force, level, equip_score, pet_score, gold, silver, copper,
		stamina, stamina_max, stamina_remain, vigor, vigor_max, vigor_remain,
		contribution, contribution_remain, justice, justice_remain, prestige, prestige_remain, camp_point,
		camp_point_percentage, camp_level, arena_award, arena_award_remain,
		exam_print, exam_print_remain, achievement_score, coin, mentor_score, starve, starve_remain, architecture, architecture_remain,
		time, extra
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]])
local DB_RoleInfoCoinW = DB:Prepare('UPDATE RoleInfo SET coin = ? WHERE account = ? AND region = ?')
local DB_RoleInfoG = DB:Prepare('SELECT * FROM RoleInfo WHERE guid = ?')
local DB_RoleInfoR = DB:Prepare('SELECT * FROM RoleInfo WHERE account LIKE ? OR name LIKE ? OR region LIKE ? OR server LIKE ? ORDER BY time DESC')
local DB_RoleInfoD = DB:Prepare('DELETE FROM RoleInfo WHERE guid = ?')

local O = X.CreateUserSettingsModule('MY_RoleStatistics_RoleStat', _L['General'], {
	aColumn = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Collection(X.Schema.String),
		xDefaultValue = {
			'name',
			'force',
			'level',
			'achievement_score',
			'pet_score',
			'justice',
			'justice_remain',
			'exam_print',
			'coin',
			'money',
			'time_days',
		},
	},
	szSort = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.String,
		xDefaultValue = 'time_days',
	},
	szSortOrder = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.String,
		xDefaultValue = 'desc',
	},
	aAlertColumn = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Collection(X.Schema.String),
		xDefaultValue = {
			'money',
			'achievement_score',
			'pet_score',
			'contribution',
			'justice',
			'starve',
			'prestige',
			'camp_point',
			'arena_award',
			'exam_print',
		},
	},
	tAlertTodayVal = {
		ePathType = X.PATH_TYPE.ROLE,
		bUserData = true,
		xSchema = X.Schema.Any,
		xDefaultValue = nil,
	},
	tSummaryIgnoreGUID = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Any,
		xDefaultValue = {},
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	dwLastAlertTime = 0,
}

function D.GetPlayerGUID(me)
	return me.GetGlobalID() ~= '0' and me.GetGlobalID() or me.szName
end

local function GetFormatSysmsgText(szText)
	return GetFormatText(szText, GetMsgFont('MSG_SYS'), GetMsgFontColor('MSG_SYS'))
end

local function GeneCommonFormatText(id)
	return function(r)
		return GetFormatText(r[id], 162, 255, 255, 255)
	end
end
local function GeneCommonSummaryFormatText(id)
	return function(rs)
		local v = 0
		for _, r in ipairs(rs) do
			if X.IsNumber(r[id]) then
				v = v + r[id]
			end
		end
		return GetFormatText(v, 162, 255, 255, 255)
	end
end
local function GeneCommonCompare(id)
	return function(r1, r2)
		if r1[id] == r2[id] then
			return 0
		end
		return r1[id] > r2[id] and 1 or -1
	end
end
local function GeneWeeklyFormatText(id)
	return function(r)
		local nNextTime, nCircle = X.GetRefreshTime('weekly')
		local szText = (nNextTime - nCircle < r.time and r[id] and r[id] >= 0)
			and r[id]
			or _L['--']
		return GetFormatText(szText, 162, 255, 255, 255)
	end
end
local function GeneWeeklySummaryFormatText(id)
	return function(rs)
		local nNextTime, nCircle = X.GetRefreshTime('weekly')
		local v = nil
		for _, r in ipairs(rs) do
			if nNextTime - nCircle < r.time and X.IsNumber(r[id]) and r[id] >= 0 then
				if not v then
					v = 0
				end
				v = v + r[id]
			end
		end
		return GetFormatText(v or '--', 162, 255, 255, 255)
	end
end
local function GeneWeeklyCompare(id)
	return function(r1, r2)
		local nNextTime, nCircle = X.GetRefreshTime('weekly')
		local v1 = nNextTime - nCircle < r1.time
			and r1[id]
			or -1
		local v2 = nNextTime - nCircle < r2.time
			and r2[id]
			or -1
		if v1 == v2 then
			return 0
		end
		return v1 > v2 and 1 or -1
	end
end
local COLUMN_LIST = lodash.filter({
	-- guid,
	-- account,
	{ -- ����
		id = 'region',
		szTitle = _L['Region'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('region'),
		Compare = GeneCommonCompare('region'),
	},
	{ -- ������
		id = 'server',
		szTitle = _L['Server'],
		nMinWidth = 100, nMaxWidth = 100,
		GetFormatText = GeneCommonFormatText('server'),
		Compare = GeneCommonCompare('server'),
	},
	{ -- ����
		id = 'name',
		szTitle = _L['Name'],
		nMinWidth = 110, nMaxWidth = 200,
		GetFormatText = function(rec)
			local name = rec.name
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
		end,
		Compare = GeneCommonCompare('name'),
	},
	{ -- ����
		id = 'force',
		szTitle = _L['Force'],
		nMinWidth = 50, nMaxWidth = 70,
		GetFormatText = function(rec)
			return GetFormatText(g_tStrings.tForceTitle[rec.force], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('force'),
	},
	{ -- �ȼ�
		id = 'level',
		szTitle = _L['Level'],
		nMinWidth = 50, nMaxWidth = 50,
		GetFormatText = GeneCommonFormatText('level'),
		Compare = GeneCommonCompare('level'),
	},
	{ -- �����
		id = 'pet_score',
		bHideInFloat = true,
		szTitle = _L['PetSC'],
		nMinWidth = 55,
		GetFormatText = GeneCommonFormatText('pet_score'),
		Compare = GeneCommonCompare('pet_score'),
	},
	{ -- ��Ǯ
		id = 'money',
		szTitle = _L['Money'],
		nMinWidth = 200,
		GetFormatText = function(rec)
			return GetMoneyText({ nGold = rec.gold, nSilver = rec.silver, nCopper = rec.copper }, 105)
		end,
		Compare = function(r1, r2)
			if r1.gold == r2.gold then
				if r1.silver == r2.silver then
					if r1.copper == r2.copper then
						return 0
					end
					return r1.copper > r2.copper and 1 or -1
				end
				return r1.silver > r2.silver and 1 or -1
			end
			return r1.gold > r2.gold and 1 or -1
		end,
		GetSummaryFormatText = function(recs)
			local tMoney = { nGold = 0, nSilver = 0, nCopper = 0 }
			for _, rec in ipairs(recs) do
				tMoney = MoneyOptAdd(tMoney, { nGold = rec.gold, nSilver = rec.silver, nCopper = rec.copper })
			end
			return GetMoneyText(tMoney, 105)
		end,
	},
	{ -- �˺ž���
		id = 'account_stamina',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Account Stamina'],
		szShortTitle = _L['Account_stami'],
		nMinWidth = 70,
		GetFormatText = function(rec)
			if rec.stamina < 0 then
				return GetFormatText('--', 162, 255, 255, 255)
			end
			return GetFormatText(rec.stamina .. '/' .. rec.stamina_max, 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('stamina'),
	},
	{ -- ��ɫ����
		id = 'role_stamina',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Role Stamina'],
		szShortTitle = _L['Role_stami'],
		nMinWidth = 70,
		GetFormatText = function(rec)
			if rec.vigor < 0 then
				return GetFormatText('--', 162, 255, 255, 255)
			end
			return GetFormatText(rec.vigor .. '/' .. rec.vigor_max, 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('vigor'),
	},
	{ -- ��������
		id = 'role_stamina_remain',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Role Stamina Remain'],
		szShortTitle = _L['Role_stami_remain'],
		nMinWidth = 70,
		GetFormatText = GeneWeeklyFormatText('vigor_remain'),
		Compare = GeneCommonCompare('vigor_remain'),
	},
	{ -- ����
		id = 'contribution',
		szTitle = _L['Contribution'],
		szShortTitle = _L['Contri'],
		nMinWidth = 70,
		GetFormatText = GeneCommonFormatText('contribution'),
		Compare = GeneCommonCompare('contribution'),
	},
	{ -- ��������
		id = 'contribution_remain',
		szTitle = _L['Contribution remain'],
		szShortTitle = _L['Contri_remain'],
		nMinWidth = 70,
		GetFormatText = GeneWeeklyFormatText('contribution_remain'),
		Compare = GeneWeeklyCompare('contribution_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('contribution_remain'),
	},
	{ -- ����
		id = 'justice',
		szTitle = _L['Justice'],
		szShortTitle = _L['Justi'],
		nMinWidth = 60,
		GetFormatText = GeneCommonFormatText('justice'),
		Compare = GeneCommonCompare('justice'),
	},
	{ -- ��������
		id = 'justice_remain',
		szTitle = _L['Justice remain'],
		szShortTitle = _L['Justi_remain'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('justice_remain'),
		Compare = GeneWeeklyCompare('justice_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('justice_remain'),
	},
	{ -- �˿ͼ�
		id = 'starve',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Starve'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('starve'),
		Compare = GeneWeeklyCompare('starve'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('starve'),
	},
	{ -- �˿ͼ�����
		id = 'starve_remain',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Starve remain'],
		szShortTitle = _L['Starv_remain'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('starve_remain'),
		Compare = GeneWeeklyCompare('starve_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('starve_remain'),
	},
	{ -- ԰լ��
		id = 'architecture',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Architecture'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('architecture'),
		Compare = GeneWeeklyCompare('architecture'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('architecture'),
	},
	{ -- ԰լ������
		id = 'architecture_remain',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Architecture remain'],
		szShortTitle = _L['Arch_remain'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('architecture_remain'),
		Compare = GeneWeeklyCompare('architecture_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('architecture_remain'),
	},
	{
		-- ����
		id = 'prestige',
		szTitle = _L['Prestige'],
		szShortTitle = _L['Presti'],
		nMinWidth = 70,
		GetFormatText = GeneCommonFormatText('prestige'),
		Compare = GeneCommonCompare('prestige'),
	},
	{ -- ��������
		id = 'prestige_remain',
		szTitle = _L['Prestige remain'],
		szShortTitle = _L['Presti_remain'],
		nMinWidth = 70,
		GetFormatText = GeneWeeklyFormatText('prestige_remain'),
		Compare = GeneWeeklyCompare('prestige_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('prestige_remain'),
	},
	{
		-- ս�׻���
		id = 'camp_point',
		szTitle = _L['Camp point'],
		nMinWidth = 70,
		GetFormatText = GeneWeeklyFormatText('camp_point'),
		Compare = GeneWeeklyCompare('camp_point'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('camp_point'),
	},
	{
		-- ս�׵ȼ�
		id = 'camp_level',
		szTitle = _L['Camp level'],
		nMinWidth = 70,
		GetFormatText = function(rec)
			return GetFormatText(rec.camp_level .. ' + ' .. rec.camp_point_percentage .. '%', 162, 255, 255, 255)
		end,
		Compare = function(r1, r2)
			if r1.camp_level == r2.camp_level then
				if r1.camp_point_percentage == r2.camp_point_percentage then
					return 0
				end
				return r1.camp_point_percentage > r2.camp_point_percentage and 1 or -1
			end
			return r1.camp_level > r2.camp_level and 1 or -1
		end,
	},
	{
		-- ������
		id = 'arena_award',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Arena award'],
		nMinWidth = 60,
		GetFormatText = GeneCommonFormatText('arena_award'),
		Compare = GeneCommonCompare('arena_award'),
	},
	{
		-- ����������
		id = 'arena_award_remain',
		bVisible = ENVIRONMENT.GAME_BRANCH ~= 'classic',
		szTitle = _L['Arena award remain'],
		szShortTitle = _L['Aren awa remain'],
		nMinWidth = 60,
		GetFormatText = GeneWeeklyFormatText('arena_award_remain'),
		Compare = GeneWeeklyCompare('arena_award_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('arena_award_remain'),
	},
	{
		-- �౾
		id = 'exam_print',
		szTitle = _L['Exam print'],
		szShortTitle = _L['ExamPt'],
		nMinWidth = 55,
		GetFormatText = GeneCommonFormatText('exam_print'),
		Compare = GeneCommonCompare('exam_print'),
		GetSummaryFormatText = GeneCommonSummaryFormatText('exam_print'),
	},
	{
		-- �౾����
		id = 'exam_print_remain',
		szTitle = _L['Exam print remain'],
		szShortTitle = _L['ExamPt_remain'],
		nMinWidth = 55,
		GetFormatText = GeneWeeklyFormatText('exam_print_remain'),
		Compare = GeneWeeklyCompare('exam_print_remain'),
		GetSummaryFormatText = GeneWeeklySummaryFormatText('exam_print_remain'),
	},
	{
		-- ����
		id = 'achievement_score',
		bHideInFloat = true,
		szTitle = _L['Achievement score'],
		szShortTitle = _L['AchiSC'],
		nMinWidth = 70,
		GetFormatText = GeneCommonFormatText('achievement_score'),
		Compare = GeneCommonCompare('achievement_score'),
	},
	{
		-- ͨ��
		id = 'coin',
		bHideInFloat = true,
		szTitle = _L['Coin'],
		nMinWidth = 70,
		GetFormatText = GeneCommonFormatText('coin'),
		Compare = GeneCommonCompare('coin'),
		GetSummaryFormatText = function(recs)
			local tAccount, nCoin = {}, 0
			for _, rec in ipairs(recs) do
				if not tAccount[rec.account] and X.IsNumber(rec.coin) then
					nCoin = nCoin + rec.coin
					tAccount[rec.account] = true
				end
			end
			return GetFormatText(nCoin)
		end,
	},
	{
		-- ʦͽ��
		id = 'mentor_score',
		bHideInFloat = true,
		szTitle = _L['Mentor score'],
		nMinWidth = 70,
		GetFormatText = GeneCommonFormatText('mentor_score'),
		Compare = GeneCommonCompare('mentor_score'),
	},
	{ -- ʱ��
		id = 'time',
		szTitle = _L['Cache time'],
		nMinWidth = 165, nMaxWidth = 200,
		GetFormatText = function(rec)
			return GetFormatText(X.FormatTime(rec.time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
	{ -- ʱ���ʱ
		id = 'time_days',
		szTitle = _L['Cache time days'],
		nMinWidth = 120, nMaxWidth = 120,
		GetFormatText = function(rec)
			local nTime = GetCurrentTime() - rec.time
			local nSeconds = math.floor(nTime)
			local nMinutes = math.floor(nSeconds / 60)
			local nHours   = math.floor(nMinutes / 60)
			local nDays    = math.floor(nHours / 24)
			local nYears   = math.floor(nDays / 365)
			local nDay     = nDays % 365
			local nHour    = nHours % 24
			local nMinute  = nMinutes % 60
			local nSecond  = nSeconds % 60
			if nYears > 0 then
				return GetFormatText(_L('%d years %d days before', nYears, nDay), 162, 255, 255, 255)
			end
			if nDays > 0 then
				return GetFormatText(_L('%d days %d hours before', nDays, nHour), 162, 255, 255, 255)
			end
			if nHours > 0 then
				return GetFormatText(_L('%d hours %d mins before', nHours, nMinute), 162, 255, 255, 255)
			end
			if nMinutes > 0 then
				return GetFormatText(_L('%d mins %d secs before', nMinutes, nSecond), 162, 255, 255, 255)
			end
			if nSecond > 10 then
				return GetFormatText(_L('%d secs before', nSecond), 162, 255, 255, 255)
			end
			return GetFormatText(_L['Just now'], 162, 255, 255, 255)
		end,
		Compare = GeneCommonCompare('time'),
	},
}, function(p) return p.bVisible ~= false end)

local COLUMN_DICT = {}
for _, p in ipairs(COLUMN_LIST) do
	if not p.Compare then
		p.Compare = function(r1, r2)
			if r1[p.szKey] == r2[p.szKey] then
				return 0
			end
			return r1[p.szKey] > r2[p.szKey] and 1 or -1
		end
	end
	COLUMN_DICT[p.id] = p
end
local EXCEL_WIDTH = 960

-- С����ʾ
local function GeneCommonCompareText(id, szTitle)
	return function(r1, r2)
		if r1[id] == r2[id] then
			return
		end
		if not r1[id] or not r2[id] then
			return
		end
		local szOp = r1[id] <= r2[id]
			and ' increased by %s'
			or ' decreased by %s'
		return GetFormatSysmsgText(_L(szTitle .. szOp, math.abs(r2[id] - r1[id])))
	end
end
local ALERT_COLUMN = {
	{ -- װ��
		id = 'equip_score',
		szTitle = _L['Equip score'],
		GetValue = function(me)
			return me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
		end,
		GetCompareText = GeneCommonCompareText('equip_score', 'Equip score'),
	},
	{ -- �����
		id = 'pet_score',
		szTitle = _L['Pet score'],
		GetValue = function(me)
			return me.GetAcquiredFellowPetScore() + me.GetAcquiredFellowPetMedalScore()
		end,
		GetCompareText = GeneCommonCompareText('pet_score', 'Pet score'),
	},
	{ -- ��Ǯ
		id = 'money',
		szTitle = _L['Money'],
		nMinWidth = 200,
		GetValue = function(me)
			return me.GetMoney()
		end,
		GetCompareText = function(r1, r2)
			local money = MoneyOptSub(r2.money, r1.money)
			local nCompare = MoneyOptCmp(money, 0)
			if nCompare == 0 then
				return
			end
			local f = GetMsgFont('MSG_SYS')
			local r, g, b = GetMsgFontColor('MSG_SYS')
			local szExtra = 'font=' .. f .. ' r=' .. r .. ' g=' .. g .. ' b=' .. b
			return GetFormatSysmsgText(nCompare >= 0 and _L['Money increased by '] or _L['Money decreased by '])
				.. GetMoneyText({ nGold = math.abs(money.nGold), nSilver = math.abs(money.nSilver), nCopper = math.abs(money.nCopper) }, szExtra)
		end,
	},
	{ -- ����
		id = 'contribution',
		szTitle = _L['Contribution'],
		GetValue = function(me)
			return me.nContribution
		end,
		GetCompareText = GeneCommonCompareText('contribution', 'Contribution'),
	},
	{ -- ����
		id = 'justice',
		szTitle = _L['Justice'],
		GetValue = function(me)
			return me.nJustice
		end,
		GetCompareText = GeneCommonCompareText('justice', 'Justice'),
	},
	{ -- �˿ͼ�
		id = 'starve',
		szTitle = _L['Starve'],
		GetValue = function(me)
			return X.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, 34797, true)
				+ X.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, 40259, true)
		end,
		GetCompareText = GeneCommonCompareText('starve', 'Starve'),
	},
	{
		-- ����
		id = 'prestige',
		szTitle = _L['Prestige'],
		GetValue = function(me)
			return me.nCurrentPrestige
		end,
		GetCompareText = GeneCommonCompareText('prestige', 'Prestige'),
	},
	{
		-- ս�׻���
		id = 'camp_point',
		szTitle = _L['Camp point'],
		GetValue = function(me)
			return me.nTitlePoint
		end,
		GetCompareText = GeneCommonCompareText('camp_point', 'Camp point'),
	},
	{
		-- ������
		id = 'arena_award',
		szTitle = _L['Arena award'],
		GetValue = function(me)
			return me.nArenaAward
		end,
		GetCompareText = GeneCommonCompareText('arena_award', 'Arena award'),
	},
	{
		-- �౾
		id = 'exam_print',
		szTitle = _L['Exam print'],
		GetValue = function(me)
			return me.nExamPrint
		end,
		GetCompareText = GeneCommonCompareText('exam_print', 'Exam print'),
	},
	{
		-- ����
		id = 'achievement_score',
		szTitle = _L['Achievement score'],
		GetValue = function(me)
			return me.GetAchievementRecord()
		end,
		GetCompareText = GeneCommonCompareText('achievement_score', 'Achievement score'),
	},
	{
		-- ʦͽ��
		id = 'mentor_score',
		szTitle = _L['Mentor score'],
		GetValue = function(me)
			return me.dwTAEquipsScore
		end,
		GetCompareText = GeneCommonCompareText('mentor_score', 'Mentor score'),
	},
}
local ALERT_COLUMN_DICT = {}
for _, p in ipairs(ALERT_COLUMN) do
	ALERT_COLUMN_DICT[p.id] = p
end

do
local INFO_CACHE = {}
X.RegisterFrameCreate('regionPQreward', 'MY_RoleStatistics_RoleStat', function()
	local frame = arg0
	if not frame then
		return
	end
	local txt = frame:Lookup('', 'Text_discrible')
	txt.__SetText = txt.SetText
	txt.SetText = function(txt, szText)
		local szNum = szText:match(_L['Current week can acquire (%d+) Langke Jian.'])
			or szText:match(_L['Current week can acquire (%d+) Langke Jian or Zhushu.'])
		if szNum then
			INFO_CACHE['starve_remain'] = tonumber(szNum)
		end
		txt:__SetText(szText)
	end
end)

local REC_CACHE
function D.GetClientPlayerRec()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = REC_CACHE
	local guid = D.GetPlayerGUID(me)
	if not rec then
		rec = {
			starve_remain = -1,
		}
		-- �����ͬһ��CD���� �������ݿ��еĴ���ͳ��
		DB_RoleInfoG:ClearBindings()
		DB_RoleInfoG:BindAll(AnsiToUTF8(guid))
		local result = DB_RoleInfoG:GetAll()
		DB_RoleInfoG:Reset()
		if result and result[1] and result[1].time then
			local dwTime, dwCircle = X.GetRefreshTime('weekly')
			if dwTime - dwCircle < result[1].time then
				rec.starve_remain = result[1].starve_remain
			end
		end
		REC_CACHE = rec
	end

	-- ������Ϣ
	rec.guid = guid
	rec.account = X.GetAccount() or ''
	rec.region = X.GetRealServer(1)
	rec.server = X.GetRealServer(2)
	rec.name = me.szName
	rec.force = me.dwForceID
	rec.level = me.nLevel
	rec.equip_score = me.GetBaseEquipScore() + me.GetStrengthEquipScore() + me.GetMountsEquipScore()
	rec.pet_score = me.GetAcquiredFellowPetScore() + me.GetAcquiredFellowPetMedalScore()
	local money = me.GetMoney()
	rec.gold = money.nGold
	rec.silver = money.nSilver
	rec.copper = money.nCopper
	rec.stamina = -1
	rec.stamina_max = -1
	rec.stamina_remain = -1
	rec.vigor = -1
	rec.vigor_max = -1
	rec.vigor_remain = -1
	if ENVIRONMENT.GAME_BRANCH ~= 'classic' then
		rec.stamina = me.nCurrentStamina
		rec.stamina_max = me.nMaxStamina
		rec.stamina_remain = -1
		rec.vigor = me.nVigor
		rec.vigor_max = me.GetMaxVigor()
		rec.vigor_remain = me.GetVigorRemainSpace()
	end
	rec.contribution = me.nContribution
	rec.contribution_remain = me.GetContributionRemainSpace()
	rec.justice = me.nJustice
	rec.justice_remain = me.GetJusticeRemainSpace()
	rec.prestige = me.nCurrentPrestige
	rec.prestige_remain = me.GetPrestigeRemainSpace()
	rec.camp_point = me.nTitlePoint
	rec.camp_point_percentage = me.GetRankPointPercentage()
	rec.camp_level = me.nTitle
	rec.arena_award = me.nArenaAward
	rec.arena_award_remain = me.GetArenaAwardRemainSpace()
	rec.exam_print = me.nExamPrint
	rec.exam_print_remain = me.GetExamPrintRemainSpace()
	rec.achievement_score = me.GetAchievementRecord()
	rec.architecture = ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.nArchitecture or 0
	rec.architecture_remain = ENVIRONMENT.GAME_BRANCH ~= 'classic' and X.IsFunction(me.GetArchitectureRemainSpace) and me.GetArchitectureRemainSpace() or 0
	rec.coin = me.nCoin
	rec.mentor_score = me.dwTAEquipsScore
	rec.starve = X.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, 34797, true)
		+ X.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, 40259, true)
	rec.time = GetCurrentTime()

	for k, v in pairs(INFO_CACHE) do
		rec[k] = v
	end
	return rec
end
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/role_stat.v2.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- ת��V2�ɰ�����
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					DB:Execute('BEGIN TRANSACTION')
					local aRoleInfo = DB_V2:Execute('SELECT * FROM RoleInfo WHERE guid IS NOT NULL AND name IS NOT NULL')
					if aRoleInfo then
						for _, rec in ipairs(aRoleInfo) do
							DB_RoleInfoW:ClearBindings()
							DB_RoleInfoW:BindAll(
								rec.guid,
								rec.account,
								rec.region,
								rec.server,
								rec.name,
								rec.force,
								rec.level,
								rec.equip_score,
								rec.pet_score,
								rec.gold,
								rec.silver,
								rec.copper,
								rec.stamina or -1,
								rec.stamina_max or -1,
								rec.stamina_remain or -1,
								rec.vigor or -1,
								rec.vigor_max or -1,
								rec.vigor_remain or -1,
								rec.contribution,
								rec.contribution_remain,
								rec.justice,
								rec.justice_remain,
								rec.prestige,
								rec.prestige_remain,
								rec.camp_point,
								rec.camp_point_percentage,
								rec.camp_level,
								rec.arena_award,
								rec.arena_award_remain,
								rec.exam_print,
								rec.exam_print_remain,
								rec.achievement_score,
								rec.coin,
								rec.mentor_score,
								rec.starve,
								rec.starve_remain,
								rec.architecture,
								rec.architecture_remain,
								rec.time,
								''
							)
							DB_RoleInfoW:Execute()
						end
						DB_RoleInfoW:Reset()
					end
					DB:Execute('END TRANSACTION')
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			FireUIEvent('MY_ROLE_STAT_ROLE_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]

	local rec = X.Clone(D.GetClientPlayerRec())
	D.EncodeRow(rec)

	DB:Execute('BEGIN TRANSACTION')

	DB_RoleInfoW:ClearBindings()
	DB_RoleInfoW:BindAll(
		rec.guid, rec.account, rec.region, rec.server,
		rec.name, rec.force, rec.level, rec.equip_score,
		rec.pet_score, rec.gold, rec.silver, rec.copper,
		rec.stamina, rec.stamina_max, rec.stamina_remain, rec.vigor, rec.vigor_max, rec.vigor_remain,
		rec.contribution, rec.contribution_remain, rec.justice, rec.justice_remain,
		rec.prestige, rec.prestige_remain, rec.camp_point, rec.camp_point_percentage,
		rec.camp_level, rec.arena_award, rec.arena_award_remain, rec.exam_print,
		rec.exam_print_remain, rec.achievement_score, rec.coin, rec.mentor_score,
		rec.starve, rec.starve_remain, rec.architecture, rec.architecture_remain,
		rec.time, '')
	DB_RoleInfoW:Execute()
	DB_RoleInfoW:Reset()

	DB_RoleInfoCoinW:ClearBindings()
	DB_RoleInfoCoinW:BindAll(rec.coin, rec.account, rec.region)
	DB_RoleInfoCoinW:Execute()
	DB_RoleInfoCoinW:Reset()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.Debug('MY_RoleStatistics_RoleStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
X.RegisterFlush('MY_RoleStatistics_RoleStat', D.FlushDB)

do local INIT = false
function D.UpdateSaveDB()
	if not INIT then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_RoleStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB_RoleInfoD:ClearBindings()
		DB_RoleInfoD:BindAll(AnsiToUTF8(D.GetPlayerGUID(me)))
		DB_RoleInfoD:Execute()
		DB_RoleInfoD:Reset()
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_RoleStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_ROLE_UPDATE')
end
X.RegisterInit('MY_RoleStatistics_RoleUpdateSaveDB', function() INIT = true end)
end

function D.GetColumns()
	local aCol = {}
	for _, id in ipairs(O.aColumn) do
		local col = COLUMN_DICT[id]
		if col then
			table.insert(aCol, col)
		end
	end
	return aCol
end

function D.UpdateUI(page)
	local hCols = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_RoleStatColumns')
	hCols:Clear()

	local aCol, nX, Sorter = D.GetColumns(), 0, nil
	local nExtraWidth = EXCEL_WIDTH
	for i, col in ipairs(aCol) do
		nExtraWidth = nExtraWidth - col.nMinWidth
	end
	for i, col in ipairs(aCol) do
		local hCol = hCols:AppendItemFromIni(SZ_INI, 'Handle_RoleStatColumn')
		local txt = hCol:Lookup('Text_RoleStat_Title')
		local imgAsc = hCol:Lookup('Image_RoleStat_Asc')
		local imgDesc = hCol:Lookup('Image_RoleStat_Desc')
		local nWidth = i == #aCol
			and (EXCEL_WIDTH - nX)
			or math.min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or math.huge)
		local nSortDelta = nWidth > 70 and 25 or 15
		if i == 0 then
			hCol:Lookup('Image_RoleStat_Break'):Hide()
		end
		hCol.szSort = col.id
		hCol:SetRelX(nX)
		hCol:SetW(nWidth)
		txt:SetW(nWidth)
		txt:SetText(col.szShortTitle or col.szTitle)
		imgAsc:SetRelX(nWidth - nSortDelta)
		imgDesc:SetRelX(nWidth - nSortDelta)
		if O.szSort == col.id then
			Sorter = function(r1, r2)
				if O.szSortOrder == 'asc' then
					return col.Compare(r1, r2) < 0
				end
				return col.Compare(r1, r2) > 0
			end
		end
		imgAsc:SetVisible(O.szSort == col.id and O.szSortOrder == 'asc')
		imgDesc:SetVisible(O.szSort == col.id and O.szSortOrder == 'desc')
		hCol:FormatAllItemPos()
		nX = nX + nWidth
	end
	hCols:FormatAllItemPos()


	local szSearch = page:Lookup('Wnd_Total/Wnd_Search/Edit_Search'):GetText()
	local szUSearch = AnsiToUTF8('%' .. szSearch .. '%')
	DB_RoleInfoR:ClearBindings()
	DB_RoleInfoR:BindAll(szUSearch, szUSearch, szUSearch, szUSearch)
	local result = DB_RoleInfoR:GetAll()
	DB_RoleInfoR:Reset()

	for _, rec in ipairs(result) do
		D.DecodeRow(rec)
	end

	if Sorter then
		table.sort(result, Sorter)
	end

	local aCol = D.GetColumns()
	-- �б�
	local hList = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_List')
	hList:Clear()
	for i, rec in ipairs(result) do
		local hRow = hList:AppendItemFromIni(SZ_INI, 'Handle_Row')
		hRow.rec = rec
		hRow:Lookup('Image_RowBg'):SetVisible(i % 2 == 1)
		-- ������
		local nX = 0
		for j, col in ipairs(aCol) do
			local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- �ⲿ���в�
			local hItemContent = hItem:Lookup('Handle_ItemContent') -- �ڲ��ı����ֲ�
			hItemContent:AppendItemFromString(col.GetFormatText(rec))
			hItemContent:SetW(99999)
			hItemContent:FormatAllItemPos()
			hItemContent:SetSizeByAllItemSize()
			local nWidth = j == #aCol
				and (EXCEL_WIDTH - nX)
				or math.min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or math.huge)
			if j == #aCol then
				nWidth = EXCEL_WIDTH - nX
			end
			hItem:SetRelX(nX)
			hItem:SetW(nWidth)
			hItemContent:SetRelPos((nWidth - hItemContent:GetW()) / 2, (hItem:GetH() - hItemContent:GetH()) / 2)
			hItem:FormatAllItemPos()
			nX = nX + nWidth
		end
		-- ���Ƹ�ѡ��
		UI(hRow):Append('CheckBox', {
			x = 5, y = 2, w = EXCEL_WIDTH - 10,
			checked = X.IsEmpty(O.tSummaryIgnoreGUID) or not O.tSummaryIgnoreGUID[rec.guid] or false,
			oncheck = function(bCheck)
				O.tSummaryIgnoreGUID[rec.guid] = not bCheck or nil
				O.tSummaryIgnoreGUID = O.tSummaryIgnoreGUID
				D.UpdateUI(page)
			end,
			visible = D.bConfigSummary or false,
		})
		-- ��ʽ��λ��
		hRow:FormatAllItemPos()
	end
	hList:FormatAllItemPos()

	-- ����
	local aSum = {}
	for _, rec in ipairs(result) do
		if X.IsEmpty(O.tSummaryIgnoreGUID) or not O.tSummaryIgnoreGUID[rec.guid] then
			table.insert(aSum, rec)
		end
	end
	local hSum = page:Lookup('Wnd_Total/WndScroll_RoleStat', 'Handle_Sum')
	hSum:Clear()
	local hRow = hSum:AppendItemFromIni(SZ_INI, 'Handle_Row', 'Handle_SumRow')
	hRow:Lookup('Image_RowBg'):SetVisible(false)
	local nX = 0
	for j, col in ipairs(aCol) do
		local hItem = hRow:AppendItemFromIni(SZ_INI, 'Handle_Item') -- �ⲿ���в�
		local hItemContent = hItem:Lookup('Handle_ItemContent') -- �ڲ��ı����ֲ�
		hItemContent:AppendItemFromString(col.GetSummaryFormatText and col.GetSummaryFormatText(aSum) or GetFormatText('--'))
		hItemContent:SetW(99999)
		hItemContent:FormatAllItemPos()
		hItemContent:SetSizeByAllItemSize()
		local nWidth = j == #aCol
			and (EXCEL_WIDTH - nX)
			or math.min(nExtraWidth * col.nMinWidth / (EXCEL_WIDTH - nExtraWidth) + col.nMinWidth, col.nMaxWidth or math.huge)
		if j == #aCol then
			nWidth = EXCEL_WIDTH - nX
		end
		hItem:SetRelX(nX)
		hItem:SetW(nWidth)
		hItemContent:SetRelPos((nWidth - hItemContent:GetW()) / 2, (hItem:GetH() - hItemContent:GetH()) / 2)
		hItem:FormatAllItemPos()
		nX = nX + nWidth
	end
	hRow:FormatAllItemPos()
	hSum:FormatAllItemPos()
end

function D.EncodeRow(rec)
	rec.guid   = AnsiToUTF8(rec.guid)
	rec.name   = AnsiToUTF8(rec.name)
	rec.region = AnsiToUTF8(rec.region)
	rec.server = AnsiToUTF8(rec.server)
end

function D.DecodeRow(rec)
	rec.guid   = UTF8ToAnsi(rec.guid)
	rec.name   = UTF8ToAnsi(rec.name)
	rec.region = UTF8ToAnsi(rec.region)
	rec.server = UTF8ToAnsi(rec.server)
end

function D.OutputRowTip(this, rec)
	local aXml = {}
	local bFloat = this:GetRoot():GetName() ~= 'MY_RoleStatistics'
	for _, col in ipairs(COLUMN_LIST) do
		if not bFloat or not col.bHideInFloat then
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec))
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	local nPosType = bFloat and UI.TIP_POSITION.TOP_BOTTOM or UI.TIP_POSITION.RIGHT_LEFT
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, nPosType)
end

function D.CloseRowTip()
	HideTip()
end

function D.OnInitPage()
	local page = this
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_RoleStatistics_RoleStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(page, true, true)
	Wnd.CloseWindow(frameTemp)

	-- ��ʾ��
	UI(wnd):Append('WndComboBox', {
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t, c, nMinW = {}, {}, 0
			for i, id in ipairs(O.aColumn) do
				local col = COLUMN_DICT[id]
				if col then
					table.insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									O.aColumn[i], O.aColumn[i - 1] = O.aColumn[i - 1], O.aColumn[i]
									O.aColumn = O.aColumn
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #O.aColumn then
									O.aColumn[i], O.aColumn[i + 1] = O.aColumn[i + 1], O.aColumn[i]
									O.aColumn = O.aColumn
									D.UpdateUI(page)
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								table.remove(O.aColumn, i)
								O.aColumn = O.aColumn
								D.UpdateUI(page)
								UI.ClosePopupMenu()
							end,
						},
					})
					c[id] = true
					nMinW = nMinW + col.nMinWidth
				end
			end
			for _, col in ipairs(COLUMN_LIST) do
				if not c[col.id] then
					table.insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							if nMinW + col.nMinWidth > EXCEL_WIDTH then
								X.Alert(_L['Too many column selected, width overflow, please delete some!'])
							else
								table.insert(O.aColumn, col.id)
								O.aColumn = O.aColumn
							end
							D.UpdateUI(page)
							UI.ClosePopupMenu()
						end,
					})
				end
			end
			return t
		end,
	})

	-- ESC��ʾ��
	UI(wnd):Append('WndComboBox', {
		x = 600, y = 20, w = 180,
		text = _L['Columns alert when esc'],
		menu = function()
			local t, c = {}, {}
			for i, id in ipairs(O.aAlertColumn) do
				local col = ALERT_COLUMN_DICT[id]
				if col then
					table.insert(t, {
						szOption = col.szTitle,
						{
							szOption = _L['Move up'],
							fnAction = function()
								if i > 1 then
									O.aAlertColumn[i], O.aAlertColumn[i - 1] = O.aAlertColumn[i - 1], O.aAlertColumn[i]
									O.aAlertColumn = O.aAlertColumn
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Move down'],
							fnAction = function()
								if i < #O.aAlertColumn then
									O.aAlertColumn[i], O.aAlertColumn[i + 1] = O.aAlertColumn[i + 1], O.aAlertColumn[i]
									O.aAlertColumn = O.aAlertColumn
								end
								UI.ClosePopupMenu()
							end,
						},
						{
							szOption = _L['Delete'],
							fnAction = function()
								table.remove(O.aAlertColumn, i)
								O.aAlertColumn = O.aAlertColumn
								UI.ClosePopupMenu()
							end,
						},
					})
					c[id] = true
				end
			end
			for _, col in ipairs(ALERT_COLUMN) do
				if not c[col.id] then
					table.insert(t, {
						szOption = col.szTitle,
						fnAction = function()
							table.insert(O.aAlertColumn, col.id)
							O.aAlertColumn = O.aAlertColumn
							UI.ClosePopupMenu()
						end,
					})
				end
			end
			return t
		end,
	})

	UI(wnd):Append('WndButton', {
		x = 25, y = 552, w = 25, h = 25,
		buttonstyle = 'OPTION',
		onclick = function()
			D.bConfigSummary = not D.bConfigSummary
			D.UpdateUI(page)
		end,
	})

	local frame = page:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_ROLE_UPDATE')
end

function D.CheckAdvice()
	for _, p in ipairs({
		{
			szMsg = _L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
			szAdviceKey = 'bAdviceSaveDB',
			szSetKey = 'bSaveDB',
		},
		-- {
		-- 	szMsg = _L('%s stat float entry has not been enabled, are you willing to enable it?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]),
		-- 	szAdviceKey = 'bAdviceFloatEntry',
		-- 	szSetKey = 'bFloatEntry',
		-- },
	}) do
		if not O[p.szAdviceKey] and not O[p.szSetKey] then
			X.Confirm(p.szMsg, function()
				MY_RoleStatistics_RoleStat[p.szSetKey] = true
				MY_RoleStatistics_RoleStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end, function()
				MY_RoleStatistics_RoleStat[p.szAdviceKey] = true
				D.CheckAdvice()
			end)
			return
		end
	end
end

function D.OnActivePage()
	D.Migration()
	D.CheckAdvice()
	D.FlushDB()
	D.UpdateUI(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateUI(this)
	elseif event == 'MY_ROLE_STAT_ROLE_UPDATE' then
		D.FlushDB()
		D.UpdateUI(this)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		X.Confirm(_L('Are you sure to delete item record of %s?', wnd.name), function()
			DB_RoleInfoD:ClearBindings()
			DB_RoleInfoD:BindAll(AnsiToUTF8(wnd.guid))
			DB_RoleInfoD:Execute()
			DB_RoleInfoD:Reset()
			D.UpdateUI(page)
		end)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_RoleStatColumn' then
		if this.szSort then
			local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
			if O.szSort == this.szSort then
				O.szSortOrder = O.szSortOrder == 'asc' and 'desc' or 'asc'
			else
				O.szSort = this.szSort
			end
			D.UpdateUI(page)
		end
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Row' then
		local rec = this.rec
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		local menu = {
			{
				szOption = _L['Delete'],
				fnAction = function()
					DB_RoleInfoD:ClearBindings()
					DB_RoleInfoD:BindAll(AnsiToUTF8(rec.guid))
					DB_RoleInfoD:Execute()
					DB_RoleInfoD:Reset()
					D.UpdateUI(page)
				end,
			},
		}
		PopupMenu(menu)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_Search' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateUI(page)
		end
		return 1
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Row' then
		D.OutputRowTip(this, this.rec)
	elseif name == 'Handle_RoleStatColumn' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = GetFormatText(this:Lookup('Text_RoleStat_Title'):GetText(), 162, 255, 255, 255)
		OutputTip(szXml, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	elseif this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	HideTip()
end

local ALERT_INIT_VAL = {}
X.RegisterInit('MY_RoleStatistics_RoleStat__AlertCol', function()
	local me = GetClientPlayer()
	for _, col in ipairs(ALERT_COLUMN) do
		ALERT_INIT_VAL[col.id] = col.GetValue(me)
	end
	if not X.IsTable(O.tAlertTodayVal) or not X.IsNumber(O.tAlertTodayVal.nTime)
	or not X.IsInSameRefreshTime('daily', O.tAlertTodayVal.nTime) then
		O.tAlertTodayVal = {}
		for _, col in ipairs(ALERT_COLUMN) do
			O.tAlertTodayVal[col.id] = col.GetValue(me)
		end
		O.tAlertTodayVal.nTime = GetCurrentTime()
		O.tAlertTodayVal = O.tAlertTodayVal
	end
end)
X.RegisterFrameCreate('OptionPanel', 'MY_RoleStatistics_RoleStat__AlertCol', function()
	local me = GetClientPlayer()
	local tVal = {}
	for _, col in ipairs(ALERT_COLUMN) do
		tVal[col.id] = col.GetValue(me)
	end

	local aText, aDailyText = {}, {}
	for _, id in ipairs(O.aAlertColumn) do
		local col = ALERT_COLUMN_DICT[id]
		if col then
			table.insert(aText, (col.GetCompareText(ALERT_INIT_VAL, tVal)))
			table.insert(aDailyText, (col.GetCompareText(O.tAlertTodayVal, tVal)))
		end
	end
	local szText, szDailyText = table.concat(aText, GetFormatSysmsgText(_L[','])), table.concat(aDailyText, GetFormatSysmsgText(_L[',']))
	if GetTime() - D.dwLastAlertTime > 10000 or D.szLastAlert ~= szText or D.szLastDailyAlert ~= szDailyText then
		if not X.IsEmpty(szText) and szText ~= szDailyText then
			X.Sysmsg({ GetFormatSysmsgText(_L['Current online ']) .. szText .. GetFormatSysmsgText(_L['.']), rich = true })
		end
		if not X.IsEmpty(szDailyText) then
			X.Sysmsg({ GetFormatSysmsgText(_L['Today online ']) .. szDailyText .. GetFormatSysmsgText(_L['.']), rich = true })
		end
		D.dwLastAlertTime = GetTime()
		D.szLastAlert = szText
		D.szLastDailyAlert = szDailyText
	end
end)

-- ������
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/SprintPower')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_RoleEntry')
	if X.IsNil(bFloatEntry) then
		bFloatEntry = O.bFloatEntry
	end
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = Wnd.OpenWindow(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_RoleEntry.ini', 'MY_RoleStatistics_RoleEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_RoleEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(55, -8)
		Wnd.CloseWindow(frameTemp)
		btn.OnMouseEnter = function()
			local rec = D.GetClientPlayerRec()
			if not rec then
				return
			end
			D.OutputRowTip(this, rec)
		end
		btn.OnMouseLeave = function()
			D.CloseRowTip()
		end
		btn.OnLButtonClick = function()
			MY_RoleStatistics.Open('RoleStat')
		end
	else
		if not btn then
			return
		end
		btn:Destroy()
	end
end
function D.UpdateFloatEntry()
	if not D.bReady then
		return
	end
	D.ApplyFloatEntry(O.bFloatEntry)
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_RoleStatistics_RoleStat', function()
	D.bReady = true
	D.UpdateSaveDB()
	D.FlushDB()
	D.UpdateFloatEntry()
end)
X.RegisterReload('MY_RoleStatistics_RoleEntry', function() D.ApplyFloatEntry(false) end)
X.RegisterFrameCreate('SprintPower', 'MY_RoleStatistics_RoleEntry', D.UpdateFloatEntry)

-- Module exports
do
local settings = {
	name = 'MY_RoleStatistics_RoleStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				szSaveDB = 'MY_RoleStatistics_RoleStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_RoleStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('RoleStat', _L['MY_RoleStatistics_RoleStat'], X.CreateModule(settings))
end

-- Global exports
do
local settings = {
	name = 'MY_RoleStatistics_RoleStat',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'aColumn',
				'szSort',
				'szSortOrder',
				'aAlertColumn',
				'tAlertTodayVal',
				'tSummaryIgnoreGUID',
				'bFloatEntry',
				'bSaveDB',
				'bAdviceSaveDB',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'aColumn',
				'szSort',
				'szSortOrder',
				'aAlertColumn',
				'tSummaryIgnoreGUID',
				'bFloatEntry',
				'bSaveDB',
				'bAdviceSaveDB',
			},
			triggers = {
				bFloatEntry = D.UpdateFloatEntry,
				bSaveDB = D.UpdateSaveDB,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_RoleStat = X.CreateModule(settings)
end
