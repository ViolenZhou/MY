--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤ʱ��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Time')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- Format `prime`:
--   It's not particularly common for expressions of time.
--   It's similar to degrees-minutes-seconds: instead of decimal degrees (38.897212��,-77.036519��) you write (38�� 53�� 49.9632��, -77�� 2�� 11.4678��).
--   Both are derived from a sexagesimal counting system such as that devised in Ancient Babylon:
--   the single prime represents the first sexagesimal division and the second the next, and so on.
--   17th-century astronomers used a third division of 1/60th of a second.
--   The advantage of using minute and second symbols for time is that it obviously expresses a duration rather than a time.
--   From the time 01:00:00 to the time 02:34:56 is a duration of 1 hour, 34 minutes and 56 seconds (1h 34�� 56��)
--   Prime markers start single and are multiplied for subsequent appearances, so minutes use a single prime �� and seconds use a double-prime ��.
--   They are pronounced minutes and seconds respectively in the case of durations like this.
--   Note that a prime �� is not a straight-apostrophe ' or a printer's apostrophe ��, although straight-apostrophes are a reasonable approximation and printer's apostrophes do occur as well.

---@class FormatDurationUnitItem @��ʽ��ʱ�����������
---@field normal string @������ʾ��ʽ
---@field fixed string @�̶������ʾ��ʽ
---@field skipNull boolean @Ϊ���Ƿ�����
---@field delimiter string @�ָ���

---@class FormatDurationUnit @��ʽ��ʱ�����ò���
---@field year FormatDurationUnitItem | string @����
---@field day FormatDurationUnitItem | string @����
---@field hour FormatDurationUnitItem | string @Сʱ��
---@field minute FormatDurationUnitItem | string @������
---@field second FormatDurationUnitItem | string @������

---@type table<string, FormatDurationUnit>
local FORMAT_TIME_COUNT_PRESET = {
	['CHINESE'] = {
		year = { normal = '%d' .. g_tStrings.STR_YEAR, fixed = '%04d' .. g_tStrings.STR_YEAR, skipNull = true },
		day = { normal = '%d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, fixed = '%02d' .. g_tStrings.STR_BUFF_H_TIME_D_SHORT, skipNull = true },
		hour = { normal = '%d' .. g_tStrings.STR_TIME_HOUR, fixed = '%02d' .. g_tStrings.STR_TIME_HOUR, skipNull = true },
		minute = { normal = '%d' .. g_tStrings.STR_TIME_MINUTE, fixed = '%02d' .. g_tStrings.STR_TIME_MINUTE, skipNull = true },
		second = { normal = '%d' .. g_tStrings.STR_TIME_SECOND, fixed = '%02d' .. g_tStrings.STR_TIME_SECOND, skipNull = true },
	},
	['ENGLISH_ABBR'] = {
		year = { normal = '%dy', fixed = '%04dy' },
		day = { normal = '%dd', fixed = '%02dd' },
		hour = { normal = '%dh', fixed = '%02dh' },
		minute = { normal = '%dm', fixed = '%02dm' },
		second = { normal = '%ds', fixed = '%02ds' },
	},
	['PRIME'] = {
		minute = { normal = '%d\'', fixed = '%02d\'' },
		second = { normal = '%d"', fixed = '%02d"' },
	},
	['SYMBOL'] = {
		hour = { normal = '%d', fixed = '%02d', delimiter = ':' },
		minute = { normal = '%d', fixed = '%02d', delimiter = ':' },
		second = { normal = '%d', fixed = '%02d' },
	},
}
local FORMAT_TIME_UNIT_LIST = {
	{ key = 'year' },
	{ key = 'day', radix = 365 },
	{ key = 'hour', radix = 24 },
	{ key = 'minute', radix = 60 },
	{ key = 'second', radix = 60 },
}

---@class FormatDurationControl @��ʽ��ʱ����Ʋ���
---@field mode "'normal'" | "'fixed'" | "'fixed-except-leading'" @��ʽ��ģʽ
---@field maxUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @��ʼ��λ�����ֻ��ʾ���õ�λ��Ĭ��ֵ��'year'��
---@field keepUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @��ֵҲ�����ĵ�λλ�ã�Ĭ��ֵ��'second'��
---@field accuracyUnit "'year'" | "'day'" | "'hour'" | "'minute'" | "'second'" @���Ƚ�����λ�����ȵ��ڸõ�λ�����ݽ���ʡȥ��Ĭ��ֵ��'second'��

-- ��ʽ����ʱʱ��
---@param nTime number @ʱ��
---@param tUnitFmt FormatDurationUnit | string @��ʽ������ �� Ԥ�跽�������� `FORMAT_TIME_COUNT_PRESET`��
---@param tControl FormatDurationControl @���Ʋ���
function X.FormatDuration(nTime, tUnitFmt, tControl)
	if X.IsString(tUnitFmt) then
		tUnitFmt = FORMAT_TIME_COUNT_PRESET[tUnitFmt]
	end
	if not X.IsTable(tUnitFmt) then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: invalid UnitFormat.'))
	end
	-- ��ʽ��ģʽ
	local mode = tControl and tControl.mode or 'normal'
	-- ��ʼ��λ�����ֻ��ʾ���õ�λ
	local maxUnit = tControl and tControl.maxUnit or 'year'
	local maxUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == maxUnit then
			maxUnitIndex = i
			break
		end
	end
	if maxUnitIndex == -1 then
		maxUnitIndex = 1
		maxUnit = FORMAT_TIME_UNIT_LIST[maxUnitIndex].key
	end
	-- ��ֵҲ�����ĵ�λλ��
	local keepUnit = tControl and tControl.keepUnit or 'second'
	local keepUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == keepUnit then
			keepUnitIndex = i
			break
		end
	end
	if keepUnitIndex == -1 then
		keepUnitIndex = #FORMAT_TIME_UNIT_LIST
		keepUnit = FORMAT_TIME_UNIT_LIST[keepUnitIndex].key
	end
	-- ���Ƚ�����λ�����ȵ��ڸõ�λ�����ݽ���ʡȥ
	local accuracy = tControl and tControl.accuracyUnit or 'second'
	local accuracyUnitIndex = -1
	for i, v in ipairs(FORMAT_TIME_UNIT_LIST) do
		if v.key == accuracy then
			accuracyUnitIndex = i
			break
		end
	end
	if accuracyUnitIndex == -1 then
		accuracyUnitIndex = #FORMAT_TIME_UNIT_LIST
		accuracy = FORMAT_TIME_UNIT_LIST[accuracyUnitIndex].key
	end
	if maxUnitIndex > keepUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than keepUnit.'))
	end
	if maxUnitIndex > accuracyUnitIndex then
		assert(false, X.NSFormatString('{$NS}.FormatDuration: maxUnit must be less than accuracyUnit.'))
	end
	-- ��������������λ����
	local aValue = {}
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > 1 then
			aValue[i] = nTime % unit.radix
			nTime = math.floor(nTime / unit.radix)
		else
			aValue[i] = nTime
		end
	end
	-- �ϲ�������ʼ��λ�򲻴��ڵĵ�λ���ݵ��¼���λ��
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		if i < maxUnitIndex or not tUnitFmt[unit.key] then
			local nextUnit = FORMAT_TIME_UNIT_LIST[i + 1]
			if nextUnit then
				aValue[i + 1] = aValue[i + 1] + aValue[i] * nextUnit.radix
				aValue[i] = 0
			end
		end
	end
	-- �ϲ��������ȵ�λ�����ݵ��ϼ���λ��
	for i, unit in X.ipairs_r(FORMAT_TIME_UNIT_LIST) do
		if i > accuracyUnitIndex then
			local prevUnit = FORMAT_TIME_UNIT_LIST[i - 1]
			if prevUnit then
				aValue[i - 1] = aValue[i - 1] + aValue[i] / unit.radix
				aValue[i] = 0
			end
		end
	end
	-- ��λ����ƴ��
	local szText, szSplitter = '', ''
	for i, unit in ipairs(FORMAT_TIME_UNIT_LIST) do
		local fmt = tUnitFmt[unit.key]
		if X.IsString(fmt) then
			fmt = { normal = fmt }
		end
		if i >= maxUnitIndex and i <= accuracyUnitIndex -- ��λ�������С������ʾ֮��
		and fmt -- ���ҵ�λ�Զ����ʽ�����ݴ���
		and (
			aValue[i] > 0 --���ݲ�Ϊ��
			or (szText ~= '' and not fmt.skipNull) -- ��������Ϊ�յ���λ��ֵ�Ҹõ�λ��ʽ������Ҫ�󲻿�ʡ��
			or i >= keepUnitIndex -- ��λλ����ֵ������λ֮��
		) then
			local formatString = (mode == 'normal' or (mode == 'fixed-except-leading' and szText == ''))
				and (fmt.normal)
				or (fmt.fixed or fmt.normal)
			szText = szText .. szSplitter .. formatString:format(math.ceil(aValue[i]))
			szSplitter = fmt.delimiter or ''
		end
	end
	return szText
end

-- ��ʽ��ʱ��
-- (string) X.FormatTime(nTimestamp, szFormat)
-- nTimestamp UNIXʱ���
-- szFormat   ��ʽ���ַ���
--   %yyyy �����λ����
--   %yy   �����λ����
--   %MM   �·���λ����
--   %dd   ������λ����
--   %y    ���
--   %m    �·�
--   %d    ����
--   %hh   Сʱ��λ����
--   %mm   ������λ����
--   %ss   ������λ����
--   %h    Сʱ
--   %m    ����
--   %s    ����
function X.FormatTime(nTimestamp, szFormat)
	local t = TimeToDate(nTimestamp)
	szFormat = X.StringReplaceW(szFormat, '%yyyy', string.format('%04d', t.year  ))
	szFormat = X.StringReplaceW(szFormat, '%yy'  , string.format('%02d', t.year % 100))
	szFormat = X.StringReplaceW(szFormat, '%MM'  , string.format('%02d', t.month ))
	szFormat = X.StringReplaceW(szFormat, '%dd'  , string.format('%02d', t.day   ))
	szFormat = X.StringReplaceW(szFormat, '%hh'  , string.format('%02d', t.hour  ))
	szFormat = X.StringReplaceW(szFormat, '%mm'  , string.format('%02d', t.minute))
	szFormat = X.StringReplaceW(szFormat, '%ss'  , string.format('%02d', t.second))
	szFormat = X.StringReplaceW(szFormat, '%y', t.year  )
	szFormat = X.StringReplaceW(szFormat, '%M', t.month )
	szFormat = X.StringReplaceW(szFormat, '%d', t.day   )
	szFormat = X.StringReplaceW(szFormat, '%h', t.hour  )
	szFormat = X.StringReplaceW(szFormat, '%m', t.minute)
	szFormat = X.StringReplaceW(szFormat, '%s', t.second)
	return szFormat
end

function X.GetEndTime(nEndFrame, bAllowNegative)
	if bAllowNegative then
		return (nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
	end
	return math.max(0, nEndFrame - GetLogicFrameCount()) / X.ENVIRONMENT.GAME_FPS
end

function X.DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
	return DateToTime(nYear, nMonth, nDay, nHour, nMin, nSec)
end

function X.TimeToDate(nTimestamp)
	local date = TimeToDate(nTimestamp)
	return date.year, date.month, date.day, date.hour, date.minute, date.second
end

---��ʽ������С����
---(string) X.FormatNumberDot(nValue, nDot, bDot, bSimple)
---@param nValue number @Ҫ��ʽ��������
---@param nDot number @С����λ��
---@param bDot boolean @С���㲻�㲹λ0
---@param bSimple boolean @�Ƿ���ʾ������ֵ
function X.FormatNumberDot(nValue, nDot, bDot, bSimple)
	if not nDot then
		nDot = 0
	end
	local szUnit = ''
	if bSimple then
		if nValue >= 100000000 then
			nValue = nValue / 100000000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[3]
		elseif nValue > 100000 then
			nValue = nValue / 10000
			szUnit = g_tStrings.DIGTABLE.tCharDiH[2]
		end
	end
	return math.floor(nValue * math.pow(10, nDot)) / math.pow(10, nDot) .. szUnit
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
