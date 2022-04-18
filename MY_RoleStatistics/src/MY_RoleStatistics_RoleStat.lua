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
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/role/')
-------------------------------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
-------------------------------------------------------------------------------------------------------

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DATA_FILE = {'userdata/role_statistics/role_stat.jx3dat', X.PATH_TYPE.GLOBAL}

-------------------------------------------------------------------------------------------------------

local function GetFormatSysmsgText(szText)
	return GetFormatText(szText, GetMsgFont('MSG_SYS'), GetMsgFontColor('MSG_SYS'))
end

local DATA_ENV = setmetatable(
	{
		_L                         = _L                          ,
		math                       = math                        ,
		pairs                      = pairs                       ,
		ipairs                     = ipairs                      ,
		tonumber                   = tonumber                    ,
		wstring                    = X.wstring                   ,
		count_c                    = X.count_c                   ,
		pairs_c                    = X.pairs_c                   ,
		ipairs_c                   = X.ipairs_c                  ,
		ipairs_r                   = X.ipairs_r                  ,
		spairs                     = X.spairs                    ,
		spairs_r                   = X.spairs_r                  ,
		sipairs                    = X.sipairs                   ,
		sipairs_r                  = X.sipairs_r                 ,
		IsArray                    = X.IsArray                   ,
		IsDictionary               = X.IsDictionary              ,
		IsEquals                   = X.IsEquals                  ,
		IsNil                      = X.IsNil                     ,
		IsBoolean                  = X.IsBoolean                 ,
		IsNumber                   = X.IsNumber                  ,
		IsUserdata                 = X.IsUserdata                ,
		IsHugeNumber               = X.IsHugeNumber              ,
		IsElement                  = X.IsElement                 ,
		IsEmpty                    = X.IsEmpty                   ,
		IsString                   = X.IsString                  ,
		IsTable                    = X.IsTable                   ,
		IsFunction                 = X.IsFunction                ,
		GetAccount                 = X.GetAccount                ,
		GetRealServer              = X.GetRealServer             ,
		GetItemAmountInAllPackages = X.GetItemAmountInAllPackages,
		RegisterFrameCreate        = X.RegisterFrameCreate       ,
		ITEM_TABLE_TYPE            = ITEM_TABLE_TYPE             ,
		GetFormatSysmsgText        = GetFormatSysmsgText         ,
		GetFormatText              = GetFormatText               ,
		GetMoneyText               = GetMoneyText                ,
		GetMsgFont                 = GetMsgFont                  ,
		GetMsgFontColor            = GetMsgFontColor             ,
		MoneyOptAdd                = MoneyOptAdd                 ,
		MoneyOptCmp                = MoneyOptCmp                 ,
		MoneyOptSub                = MoneyOptSub                 ,
		Output                     = Output                      ,
	},
	{
		__index = function(t, k)
			if k == 'me' then
				return GetClientPlayer()
			end
			if k:find('^arg%d+$') then
				return _G[k]
			end
		end,
	})

-------------------------------------------------------------------------------------------------------

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

local COLUMN_LIST = {
	-- guid
	{
		szKey = 'guid',
		GetValue = function(prevVal, prevRec)
			return D.GetPlayerGUID(GetClientPlayer())
		end,
	},
	-- account
	{
		szKey = 'account',
		GetValue = function(prevVal, prevRec)
			return X.GetAccount() or ''
		end,
	},
	-- ����
	{
		szKey = 'region',
		bTable = true,
		bRowTip = true,
		bFloatTip = false,
		nMinWidth = 100,
		nMaxWidth = 100,
		GetValue = function(prevVal, prevRec)
			return X.GetRealServer(1)
		end,
	},
	-- ������
	{
		szKey = 'server',
		bTable = true,
		bRowTip = true,
		bFloatTip = false,
		nMinWidth = 100,
		nMaxWidth = 100,
		GetValue = function(prevVal, prevRec)
			return X.GetRealServer(2)
		end,
	},
	-- ����
	{
		szKey = 'name',
		bTable = true,
		bRowTip = true,
		bFloatTip = false,
		nMinWidth = 110,
		nMaxWidth = 200,
		GetValue = function(prevVal, prevRec)
			return GetClientPlayer().szName
		end,
		GetSummaryValue = function()
			return 'SUMMARY'
		end,
		GetFormatText = function(name, rec)
			if name == 'SUMMARY' then
				return GetFormatText(_L['Summary'], 162)
			end
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				name = MY_ChatMosaics.MosaicsString(name)
			end
			return GetFormatText(name, 162, X.GetForceColor(rec.force, 'foreground'))
		end,
	},
	-- ����
	{
		szKey = 'force',
		bTable = true,
		bRowTip = true,
		bFloatTip = false,
		nMinWidth = 50,
		nMaxWidth = 70,
		GetValue = function(prevVal, prevRec)
			return GetClientPlayer().dwForceID
		end,
		GetSummaryValue = function()
			return 'SUMMARY'
		end,
		GetFormatText = function(force)
			if force == 'SUMMARY' then
				return GetFormatText('--', 162)
			end
			return GetFormatText(g_tStrings.tForceTitle[force], 162, 255, 255, 255)
		end,
	},
	-- �ȼ�
	{
		szKey = 'level',
		bTable = true,
		bRowTip = true,
		bFloatTip = false,
		nMinWidth = 50,
		nMaxWidth = 50,
		GetValue = function(prevVal, prevRec)
			return GetClientPlayer().nLevel
		end,
		GetSummaryValue = function()
			return 'SUMMARY'
		end,
		GetFormatText = function(level)
			if level == 'SUMMARY' then
				return GetFormatText('--', 162)
			end
			return GetFormatText(level, 162, 255, 255, 255)
		end,
	},
}
-- �ְ汾������
do
	local f = X.LoadLUAData(PLUGIN_ROOT .. '/data/role/{$edition}.jx3dat')
	if X.IsFunction(f) then
		local t = f(DATA_ENV)
		if X.IsTable(t) then
			for _, v in ipairs(t) do
				table.insert(COLUMN_LIST, v)
			end
		end
	end
end
-- ʱ��
table.insert(COLUMN_LIST, {
	szKey = 'time',
	bTable = true,
	bRowTip = true,
	bFloatTip = false,
	nMinWidth = 165,
	nMaxWidth = 200,
	GetValue = function(prevVal, prevRec)
		return GetCurrentTime()
	end,
	GetSummaryValue = function()
		return 'SUMMARY'
	end,
	GetFormatText = function(time)
		if time == 'SUMMARY' then
			return GetFormatText('--', 162)
		end
		return GetFormatText(X.FormatTime(time, '%yyyy/%MM/%dd %hh:%mm:%ss'), 162, 255, 255, 255)
	end,
})
-- ʱ���ʱ
table.insert(COLUMN_LIST, {
	szKey = 'time_days',
	bTable = true,
	bRowTip = true,
	bFloatTip = false,
	nMinWidth = 120,
	nMaxWidth = 120,
	GetValue = function(prevVal, prevRec)
		return GetCurrentTime()
	end,
	GetSummaryValue = function()
		return 'SUMMARY'
	end,
	Compare = function(v1, v2, r1, r2)
		v1, v2 = r1.time, r2.time
		if v1 == v2 then
			return 0
		end
		return v1 > v2 and 1 or -1
	end,
	GetFormatText = function(v, rec)
		if v == 'SUMMARY' then
			return GetFormatText('--', 162)
		end
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
})

local COLUMN_DICT = {}
for _, col in ipairs(COLUMN_LIST) do
	col.szTitle = _L.COLUMN_TITLE[col.szKey]
	col.szTitleAbbr = _L.COLUMN_TITLE_ABBR[col.szKey] or _L.COLUMN_TITLE[col.szKey]
	if not col.GetFormatText then
		col.GetFormatText = function(v, rec)
			if not v then
				return GetFormatText('--', 162, 255, 255, 255)
			end
			return GetFormatText(v, 162, 255, 255, 255)
		end
	end
	if not col.Compare then
		col.Compare = function(v1, v2)
			if v1 == v2 then
				return 0
			end
			if not v1 then
				return -1
			end
			if not v2 then
				return 1
			end
			return v1 > v2 and 1 or -1
		end
	end
	if col.bAlertChange and not col.GetCompareText then
		col.GetCompareText = function(v1, v2, r1, r2)
			if v1 == v2 or not X.IsNumber(v1) or not X.IsNumber(v2) then
				return
			end
			local f = v1 <= v2
				and _L.COLUMN_COMPARE_INCREASE[col.szKey]
				or _L.COLUMN_COMPARE_DECREASE[col.szKey]
			if not f then
				return
			end
			return GetFormatSysmsgText(f:format(math.abs(v2 - v1)))
		end
	end
	if not col.GetSummaryValue then
		col.GetSummaryValue = function(values, records)
			local summary
			for _, v in ipairs(values) do
				if X.IsNumber(v) then
					summary = (summary or 0) + v
				end
			end
			if not summary then
				return ''
			end
			return summary
		end
	end
	COLUMN_DICT[col.szKey] = col
end

for _, col in ipairs(COLUMN_LIST) do
	X.SafeCall(col.Collector)
end

function D.GetPlayerRecords()
	local result = X.LoadLUAData(DATA_FILE) or {}
	for _, data in pairs(result) do
		if data.time then
			for _, col in ipairs(COLUMN_LIST) do
				-- �Ƴ�����ͬһ��ˢ�������ڵ������ֶ�
				if col.szRefreshCircle then
					local dwTime, dwCircle = X.GetRefreshTime(col.szRefreshCircle)
					if dwTime - dwCircle >= data.time then
						data[col.szKey] = nil
					end
				end
			end
		end
	end
	return result
end

function D.GetClientPlayerRec()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rec = D.recInitial
	if not rec then
		rec = {}
		local data = D.GetPlayerRecords()[X.GetPlayerGUID()]
		if data then
			for _, col in ipairs(COLUMN_LIST) do
				rec[col.szKey] = data[col.szKey]
			end
		end
		D.recInitial = rec
	end
	-- ��ȡ��������
	for _, col in ipairs(COLUMN_LIST) do
		rec[col.szKey] = col.GetValue(rec[col.szKey], rec)
	end
	return X.Clone(rec)
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/role_stat.v2.db', X.PATH_TYPE.GLOBAL})
	local DB_V3_PATH = X.FormatPath({'userdata/role_statistics/role_stat.v3.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) and not IsLocalFileExist(DB_V3_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			local data = X.LoadLUAData(DATA_FILE) or {}
			-- ת��V2�ɰ�����
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					local aRoleInfo = X.ConvertToAnsi(DB_V2:Execute('SELECT * FROM RoleInfo WHERE guid IS NOT NULL AND name IS NOT NULL'))
					if aRoleInfo then
						for _, rec in ipairs(aRoleInfo) do
							if not data[rec.guid] or data[rec.guid].time <= rec.time then
								data[rec.guid] = {
									guid = rec.guid,
									account = rec.account,
									region = rec.region,
									server = rec.server,
									name = rec.name,
									force = rec.force,
									level = rec.level,
									equip_score = rec.equip_score,
									pet_score = rec.pet_score,
									money = {
										nGold = rec.gold,
										nSilver = rec.silver,
										nCopper = rec.copper,
									},
									account_stamina = rec.stamina and rec.stamina >= 0 and rec.stamina_max and rec.stamina_max >= 0
										and {
											current = rec.stamina,
											max = rec.stamina_max,
										}
										or nil,
									role_stamina = rec.vigor and rec.vigor >= 0 and rec.vigor_max and rec.vigor_max >= 0
										and {
											current = rec.vigor,
											max = rec.vigor_max,
										}
										or nil,
									role_stamina_remain = rec.stamina_remain and rec.stamina_remain >= 0
										and rec.stamina_remain
										or nil,
									contribution = rec.contribution,
									contribution_remain = rec.contribution_remain,
									justice = rec.justice,
									justice_remain = rec.justice_remain,
									prestige = rec.prestige,
									prestige_remain = rec.prestige_remain,
									camp_point = rec.camp_point,
									camp_level = { level = rec.camp_level, percent = rec.camp_point_percentage },
									arena_award = rec.arena_award,
									arena_award_remain = rec.arena_award_remain,
									exam_print = rec.exam_print,
									exam_print_remain = rec.exam_print_remain,
									achievement_score = rec.achievement_score,
									coin = { owner = rec.account .. '#' .. rec.region, value = rec.coin },
									mentor_score = rec.mentor_score,
									starve = rec.starve,
									starve_remain = rec.starve_remain >= 0 and rec.starve_remain or nil,
									architecture = rec.architecture,
									architecture_remain = rec.architecture_remain,
									time = rec.time,
								}
							end
						end
					end
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- ת��V3�ɰ�����
			if IsLocalFileExist(DB_V3_PATH) then
				local DB_V3 = SQLite3_Open(DB_V3_PATH)
				if DB_V3 then
					local aRoleInfo = X.ConvertToAnsi(DB_V3:Execute('SELECT * FROM RoleInfo WHERE guid IS NOT NULL AND name IS NOT NULL'))
					if aRoleInfo then
						for _, rec in ipairs(aRoleInfo) do
							if not data[rec.guid] or data[rec.guid].time <= rec.time then
								data[rec.guid] = {
									guid = rec.guid,
									account = rec.account,
									region = rec.region,
									server = rec.server,
									name = rec.name,
									force = rec.force,
									level = rec.level,
									equip_score = rec.equip_score,
									pet_score = rec.pet_score,
									money = {
										nGold = rec.gold,
										nSilver = rec.silver,
										nCopper = rec.copper,
									},
									account_stamina = rec.stamina and rec.stamina >= 0 and rec.stamina_max and rec.stamina_max >= 0
										and {
											current = rec.stamina,
											max = rec.stamina_max,
										}
										or nil,
									role_stamina = rec.vigor and rec.vigor >= 0 and rec.vigor_max and rec.vigor_max >= 0
										and {
											current = rec.vigor,
											max = rec.vigor_max,
										}
										or nil,
									role_stamina_remain = rec.stamina_remain and rec.stamina_remain >= 0
										and rec.stamina_remain
										or nil,
									contribution = rec.contribution,
									contribution_remain = rec.contribution_remain,
									justice = rec.justice,
									justice_remain = rec.justice_remain,
									prestige = rec.prestige,
									prestige_remain = rec.prestige_remain,
									camp_point = rec.camp_point,
									camp_level = { level = rec.camp_level, percent = rec.camp_point_percentage },
									arena_award = rec.arena_award,
									arena_award_remain = rec.arena_award_remain,
									exam_print = rec.exam_print,
									exam_print_remain = rec.exam_print_remain,
									achievement_score = rec.achievement_score,
									coin = { owner = rec.account .. '#' .. rec.region, value = rec.coin },
									mentor_score = rec.mentor_score,
									starve = rec.starve,
									starve_remain = rec.starve_remain >= 0 and rec.starve_remain or nil,
									architecture = rec.architecture,
									architecture_remain = rec.architecture_remain,
									time = rec.time,
								}
							end
						end
					end
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			X.SaveLUAData(DATA_FILE, data)
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

	local data = X.LoadLUAData(DATA_FILE) or {}
	data[X.GetPlayerGUID()] = D.GetClientPlayerRec()
	X.SaveLUAData(DATA_FILE, data)

	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.Debug('MY_RoleStatistics_RoleStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
end
X.RegisterFlush('MY_RoleStatistics_RoleStat', D.FlushDB)

function D.UpdateSaveDB()
	if not D.bReady then
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
		local data = X.LoadLUAData(DATA_FILE) or {}
		data[X.GetPlayerGUID()] = nil
		X.SaveLUAData(DATA_FILE, data)
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_RoleStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_ROLE_UPDATE')
end

function D.GetTableColumns()
	local aCol = {}
	local nFixIndex = -1
	for nIndex, szKey in ipairs(O.aColumn) do
		if szKey == 'name' then
			nFixIndex = nIndex
			break
		end
	end
	for nIndex, szKey in ipairs(O.aColumn) do
		local col = COLUMN_DICT[szKey]
		if col then
			local bFixed = nIndex <= nFixIndex
			local c = {
				key = col.szKey,
				title = col.szTitleAbbr,
				titleTip = col.szTitle,
				alignHorizontal = col.szAlignHorizontal or 'center',
				render = col.GetFormatText
					and function(value, record, index)
						return col.GetFormatText(value, record)
					end
					or nil,
				sorter = col.Compare
					and function(v1, v2, r1, r2)
						return col.Compare(v1, v2, r1, r2)
					end
					or nil,
			}
			if bFixed then
				c.fixed = true
				c.width = col.nMinWidth or 100
			else
				c.minWidth = col.nMinWidth
				c.maxWidth = col.nMaxWidth
			end
			table.insert(aCol, c)
		end
	end
	return aCol
end

function D.UpdateUI(page)
	local ui = UI(page)

	-- ����
	local szSearch = ui:Fetch('WndEditBox_Search'):Text()
	local data = D.GetPlayerRecords()
	local result = {}
	for _, rec in pairs(data) do
		if wstring.find(tostring(rec.account or ''), szSearch)
		or wstring.find(tostring(rec.name or ''), szSearch)
		or wstring.find(tostring(rec.region or ''), szSearch)
		or wstring.find(tostring(rec.server or ''), szSearch) then
			table.insert(result, rec)
		end
	end

	-- ����
	local aSumRec, tSumVal = {}, {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bTable then
			tSumVal[col.szKey] = {}
		end
	end
	for _, rec in ipairs(result) do
		if X.IsEmpty(O.tSummaryIgnoreGUID) or not O.tSummaryIgnoreGUID[rec.guid] then
			for _, col in ipairs(COLUMN_LIST) do
				if col.bTable then
					table.insert(tSumVal[col.szKey], rec[col.szKey])
				end
			end
			table.insert(aSumRec, rec)
		end
	end
	local summary = {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bTable then
			summary[col.szKey] = col.GetSummaryValue(tSumVal[col.szKey], aSumRec)
		end
	end

	ui:Fetch('WndTable_Stat')
		:Columns(D.GetTableColumns())
		:DataSource(result)
		:Summary(summary)
end

function D.GetRowTip(rec)
	local aXml = {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bRowTip then
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec[col.szKey], rec))
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	return table.concat(aXml)
end

function D.OutputFloatEntryTip(this, rec)
	local rec = D.GetClientPlayerRec()
	if not rec then
		return
	end
	local aXml = {}
	for _, col in ipairs(COLUMN_LIST) do
		if col.bFloatTip then
			table.insert(aXml, GetFormatText(col.szTitle, 162, 255, 255, 0))
			table.insert(aXml, GetFormatText(':  ', 162, 255, 255, 0))
			table.insert(aXml, col.GetFormatText(rec[col.szKey], rec))
			table.insert(aXml, GetFormatText('\n', 162, 255, 255, 255))
		end
	end
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(table.concat(aXml), 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
end

function D.CloseFloatEntryTip()
	HideTip()
end

function D.OnInitPage()
	local page = this
	local ui = UI(page)

	ui:Append('WndEditBox', {
		name = 'WndEditBox_Search',
		x = 20, y = 20, w = 388, h = 25,
		appearance = 'SEARCH_RIGHT',
		placeholder = _L['Press ENTER to search...'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.UpdateUI(page)
				return 1
			end
		end,
	})

	-- ��ʾ��
	ui:Append('WndComboBox', {
		x = 800, y = 20, w = 180,
		text = _L['Columns'],
		menu = function()
			local t = {}
			local function UpdateMenu()
				local c = {}
				for i = 1, #t do
					t[i] = nil
				end
				for nIndex, szKey in ipairs(O.aColumn) do
					local col = COLUMN_DICT[szKey]
					if col then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local nOffset = IsShiftKeyDown() and 1 or -1
								if nIndex + nOffset < 1 or nIndex + nOffset > #O.aColumn then
									return
								end
								local aColumn = O.aColumn
								aColumn[nIndex], aColumn[nIndex + nOffset] = aColumn[nIndex + nOffset], aColumn[nIndex]
								O.aColumn = aColumn
								UpdateMenu()
								D.UpdateUI(page)
							end,
							fnMouseEnter = function()
								if #O.aColumn == 1 then
									return
								end
								local szText = _L['Click to move up, Hold SHIFT to move down.']
								if nIndex == 1 then
									szText = _L['Hold SHIFT click to move down.']
								elseif nIndex == #O.aColumn then
									szText = _L['Click to move up.']
								end
								local nX, nY = this:GetAbsX(), this:GetAbsY()
								local nW, nH = this:GetW(), this:GetH()
								OutputTip(GetFormatText(szText, nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.LEFT_RIGHT)
							end,
							fnMouseLeave = function()
								HideTip()
							end,
							{
								szOption = _L['Move up'],
								fnAction = function()
									if nIndex > 1 then
										local aColumn = O.aColumn
										aColumn[nIndex], aColumn[nIndex - 1] = aColumn[nIndex - 1], aColumn[nIndex]
										O.aColumn = aColumn
										UpdateMenu()
										D.UpdateUI(page)
									end
								end,
							},
							{
								szOption = _L['Move down'],
								fnAction = function()
									if nIndex < #O.aColumn then
										local aColumn = O.aColumn
										aColumn[nIndex], aColumn[nIndex + 1] = aColumn[nIndex + 1], aColumn[nIndex]
										O.aColumn = aColumn
										UpdateMenu()
										D.UpdateUI(page)
									end
								end,
							},
							CONSTANT.MENU_DIVIDER,
							{
								szOption = _L['Delete'],
								fnAction = function()
									local aColumn = O.aColumn
									table.remove(aColumn, nIndex)
									O.aColumn = aColumn
									UpdateMenu()
									D.UpdateUI(page)
								end,
								rgb = { 255, 128, 128 },
							},
						})
						c[szKey] = true
					end
				end
				for _, col in ipairs(COLUMN_LIST) do
					if col.bTable and not c[col.szKey] then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local aColumn = O.aColumn
								table.insert(aColumn, col.szKey)
								O.aColumn = aColumn
								UpdateMenu()
								D.UpdateUI(page)
							end,
						})
					end
				end
			end
			UpdateMenu()
			return t
		end,
	})

	-- ESC��ʾ��
	ui:Append('WndComboBox', {
		x = 600, y = 20, w = 180,
		text = _L['Columns alert when esc'],
		menu = function()
			local t = {}
			local function UpdateMenu()
				local c = {}
				for i = 1, #t do
					t[i] = nil
				end
				for nIndex, szKey in ipairs(O.aAlertColumn) do
					local col = COLUMN_DICT[szKey]
					if col then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local nOffset = IsShiftKeyDown() and 1 or -1
								if nIndex + nOffset < 1 or nIndex + nOffset > #O.aAlertColumn then
									return
								end
								local aAlertColumn = O.aAlertColumn
								aAlertColumn[nIndex], aAlertColumn[nIndex + nOffset] = aAlertColumn[nIndex + nOffset], aAlertColumn[nIndex]
								O.aAlertColumn = aAlertColumn
								UpdateMenu()
							end,
							fnMouseEnter = function()
								if #O.aAlertColumn == 1 then
									return
								end
								local szText = _L['Click to move up, Hold SHIFT to move down.']
								if nIndex == 1 then
									szText = _L['Hold SHIFT click to move down.']
								elseif nIndex == #O.aAlertColumn then
									szText = _L['Click to move up.']
								end
								local nX, nY = this:GetAbsX(), this:GetAbsY()
								local nW, nH = this:GetW(), this:GetH()
								OutputTip(GetFormatText(szText, nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.LEFT_RIGHT)
							end,
							fnMouseLeave = function()
								HideTip()
							end,
							{
								szOption = _L['Move up'],
								fnAction = function()
									if nIndex > 1 then
										local aAlertColumn = O.aAlertColumn
										aAlertColumn[nIndex], aAlertColumn[nIndex - 1] = aAlertColumn[nIndex - 1], aAlertColumn[nIndex]
										O.aAlertColumn = aAlertColumn
										UpdateMenu()
									end
								end,
							},
							{
								szOption = _L['Move down'],
								fnAction = function()
									if nIndex < #O.aAlertColumn then
										local aAlertColumn = O.aAlertColumn
										aAlertColumn[nIndex], aAlertColumn[nIndex + 1] = aAlertColumn[nIndex + 1], aAlertColumn[nIndex]
										O.aAlertColumn = aAlertColumn
										UpdateMenu()
									end
								end,
							},
							CONSTANT.MENU_DIVIDER,
							{
								szOption = _L['Delete'],
								fnAction = function()
									local aAlertColumn = O.aAlertColumn
									table.remove(aAlertColumn, nIndex)
									O.aAlertColumn = aAlertColumn
									UpdateMenu()
								end,
								rgb = { 255, 128, 128 },
							},
						})
						c[szKey] = true
					end
				end
				for _, col in ipairs(COLUMN_LIST) do
					if not c[col.szKey] and col.bAlertChange then
						table.insert(t, {
							szOption = col.szTitle,
							fnAction = function()
								local aAlertColumn = O.aAlertColumn
								table.insert(aAlertColumn, col.szKey)
								O.aAlertColumn = aAlertColumn
								UpdateMenu()
							end,
						})
					end
				end
			end
			UpdateMenu()
			return t
		end,
	})

	ui:Append('WndTable', {
		name = 'WndTable_Stat',
		x = 20, y = 60, w = 960, h = 530,
		sort = O.szSort,
		sortOrder = O.szSortOrder,
		onSortChange = function(szSort, szSortOrder)
			O.szSort, O.szSortOrder = szSort, szSortOrder
		end,
		rowTip = {
			render = function(rec)
				return D.GetRowTip(rec), true
			end,
			position = UI.TIP_POSITION.RIGHT_LEFT,
		},
		rowMenuRClick = function(rec, index)
			local menu = {
				{
					szOption = _L['Delete'],
					fnAction = function()
						local data = X.LoadLUAData(DATA_FILE) or {}
						data[rec.guid] = nil
						X.SaveLUAData(DATA_FILE, data)
						D.UpdateUI(page)
					end,
					rgb = { 255, 128, 128 },
				},
			}
			PopupMenu(menu)
		end,
	})

	ui:Append('WndButton', {
		x = 25, y = 562, w = 25, h = 25,
		buttonStyle = 'OPTION',
		onClick = function()
			local menu = {}
			local data = {}
			for _, v in pairs(D.GetPlayerRecords()) do
				table.insert(data, v)
			end
			table.sort(data, function(d1, d2)
				if d1 == d2 then
					return false
				end
				if not d1 then
					return true
				end
				if not d2 then
					return false
				end
				return d1.force < d2.force
			end)
			for _, rec in ipairs(data) do
				table.insert(menu, {
					szOption = rec.name,
					rgb = {X.GetForceColor(rec.force, 'foreground')},
					bCheck = true,
					bChecked = not O.tSummaryIgnoreGUID[rec.guid],
					fnAction = function(_, bChecked)
						local tSummaryIgnoreGUID = O.tSummaryIgnoreGUID
						if bChecked then
							tSummaryIgnoreGUID[rec.guid] = nil
						else
							tSummaryIgnoreGUID[rec.guid] = true
						end
						O.tSummaryIgnoreGUID = tSummaryIgnoreGUID
						D.UpdateUI(page)
					end,
				})
			end
			UI.PopupMenu(menu)
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
			D.UpdateUI(page)
		end)
	end
end

X.RegisterInit('MY_RoleStatistics_RoleStat__AlertCol', function()
	if not X.IsTable(O.tAlertTodayVal) or not X.IsNumber(O.tAlertTodayVal.nTime)
	or not X.IsInSameRefreshTime('daily', O.tAlertTodayVal.nTime) then
		local rec = D.GetClientPlayerRec()
		rec.nTime = GetCurrentTime()
		O.tAlertTodayVal = rec
	end
	D.tAlertSessionVal = D.GetClientPlayerRec()
end)

X.RegisterFrameCreate('OptionPanel', 'MY_RoleStatistics_RoleStat__AlertCol', function()
	local rec = D.GetClientPlayerRec()

	local aText, aDailyText = {}, {}
	for _, szKey in ipairs(O.aAlertColumn) do
		local col = COLUMN_DICT[szKey]
		if col and col.bAlertChange then
			local szCompare = col.GetCompareText(
				D.tAlertSessionVal[szKey],
				rec[szKey],
				D.tAlertSessionVal,
				rec
			)
			table.insert(aText, szCompare)
			local szDailyCompare = col.GetCompareText(
				O.tAlertTodayVal[szKey],
				rec[szKey],
				O.tAlertTodayVal,
				rec
			)
			table.insert(aDailyText, szDailyCompare)
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
			D.OutputFloatEntryTip(this)
		end
		btn.OnMouseLeave = function()
			D.CloseFloatEntryTip()
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
	if not ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
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
