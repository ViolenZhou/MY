--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �ַ�������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/String')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local AnsiToUTF8 = AnsiToUTF8 or _G.ansi_to_utf8

-- �ָ��ַ���
---@param szText string @ԭʼ�ַ���
---@param aSplitter string | string[] @�ָ�����ָ�������
---@param bIgnoreEmptyPart boolean @�Ƿ���Կ��ַ�������'123;234;'��';'�ֳ�{'123','234'}����{'123','234',''}
---@param nMaxPart number @���ֳɼ��ݣ���'1;2;3;4'��';'�ָ�ʱ��������������õ�{'1','2','3;4'}
---@return string[] @�ָ�����ַ�������
function X.SplitString(szText, aSplitter, bIgnoreEmptyPart, nMaxPart)
	if X.IsString(aSplitter) then
		aSplitter = {aSplitter}
	end
	local nOffset, nLen = 1, #szText
	local aResult, nResult = {}, 0
	local nPos, szPart = nil, nil
	local nSplitterPos, szSplitterFound = nil, nil
	while true do
		nSplitterPos, szSplitterFound = nil, nil
		if (not nMaxPart or nMaxPart > nResult + 1) and nOffset <= nLen then
			for _, szSplitter in ipairs(aSplitter) do
				if szSplitter == '' then
					nPos = #X.StringSubW(string.sub(szText, nOffset), 1, 1)
					if nPos == 0 then
						nPos = nil
					else
						nPos = nOffset + nPos
					end
				else
					nPos = X.StringFindW(szText, szSplitter, nOffset)
				end
				if nPos and (not nSplitterPos or nPos <= nSplitterPos) then
					nSplitterPos, szSplitterFound = nPos, szSplitter
				end
			end
		end
		if not nSplitterPos then
			szPart = nOffset <= nLen
				and string.sub(szText, nOffset, string.len(szText))
				or ''
			if not bIgnoreEmptyPart or szPart ~= '' then
				nResult = nResult + 1
				table.insert(aResult, szPart)
			end
			break
		end
		szPart = string.sub(szText, nOffset, nSplitterPos - 1)
		if not bIgnoreEmptyPart or szPart ~= '' then
			nResult = nResult + 1
			table.insert(aResult, szPart)
		end
		nOffset = nSplitterPos + string.len(szSplitterFound)
	end
	return aResult
end

function X.EscapeString(s)
	return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1'))
end

function X.TrimString(szText)
	if not szText or szText == '' then
		return ''
	end
	return (string.gsub(szText, '^%s*(.-)%s*$', '%1'))
end

function X.EncryptString(szText)
	local map = X.SECRET['CRYPTO::STRING_ENCRYPTION_MAP']
	if not map then
		return (szText:gsub('.', function (c) return string.format('%02X', (string.byte(c) + 13) % 256) end):gsub(' ', '+'))
	end
	local seed = math.random(0, 0xFF)
	local dist = math.random(0, 0xFF)
	local a = {szText:byte(1, #szText)}
	for i, v in ipairs(a) do
		a[i] = string.char((map[(v + seed + i - 1) % 0x100 + 1] + i - 1) % 0x100)
	end
	table.insert(a, 1, (string.char(dist)))
	table.insert(a, (string.char(X.NumberBitXor(dist, seed))))
	return '2,' .. X.Base64Encode(table.concat(a)):gsub('/', '-'):gsub('+', '_'):gsub('=', '.')
end

function X.DecryptString(szText)
	local map = X.SECRET['CRYPTO::STRING_DECRYPTION_MAP']
	if not map then
		local a, n = {}, nil
		for i = 1, #szText, 2 do
			n = tonumber('0x' .. szText:sub(i, i + 1))
			if not n then
				return
			end
			a[(i + 1) / 2] = string.char((n - 13 + 256) % 256)
		end
		return table.concat(a)
	end
	if szText:sub(1, 2) ~= '2,' then
		return
	end
	szText = szText:sub(3):gsub('-', '/'):gsub('_', '+'):gsub('%.', '=')
	szText = X.Base64Decode(szText)
	if not szText then
		return
	end
	local a = {}
	for i = 1, #szText do
		a[i] = szText:byte(i)
	end
	local seed = table.remove(a)
	local dist = table.remove(a, 1)
	if not dist or not seed then
		return
	end
	seed = X.NumberBitXor(seed, dist)
	for i, v in ipairs(a) do
		v = (v - (i - 1)) % 0x100
		if v < 0 then
			v = v + 0x100
		end
		v = (map[v] - seed - (i - 1)) % 0x100
		if v < 0 then
			v = v + 0x100
		end
		a[i] = string.char(v)
	end
	return table.concat(a)
end

function X.SimpleEncryptString(szText)
	local a = {}
	for i = 1, #szText do
		a[i] = string.char((szText:byte(i) + 13) % 256)
	end
	return (X.Base64Encode(table.concat(a)):gsub('/', '-'):gsub('+', '_'):gsub('=', '.'))
end

function X.SimpleDecryptString(szCipher)
	local szBin = X.Base64Decode((szCipher:gsub('-', '/'):gsub('_', '+'):gsub('%.', '=')))
	if not szBin then
		return
	end
	local a = {}
	for i = 1, #szBin do
		a[i] = string.char((szBin:byte(i) - 13 + 256) % 256)
	end
	return table.concat(a)
end

function X.SimpleDecodeString(szCipher, bTripSlashes)
	local aPhrase = {'v', 'u', 'S', 'r', 'q', '9', 'O', 'b'}
	local nPhrase = #aPhrase
	for i, v in ipairs(aPhrase) do
		aPhrase[i] = v:byte()
	end

	local aText, ch1, ch2 = {}, nil, nil
	for i = 1, #szCipher, 2 do
		ch1 = szCipher:byte(i) - 65;
		ch2 = szCipher:byte(i + 1) - 65;
		ch1 = X.NumberBitOr(X.NumberBitShl(ch1, 4, 64), ch2)
		aText[(i + 1) / 2] = string.char(X.NumberBitXor(ch1, aPhrase[(((i + 1) / 2) - 1) % nPhrase + 1]))
	end
	return table.concat(aText)
end

function X.CompressLUAData(xData)
	local szBin = X.EncodeLUAData(xData)
	local szCompressBin = X.Deflate:CompressZlib(szBin)
	local szCompressBinBase64 = X.EncodeURIComponentBase64(szCompressBin)
	return szCompressBinBase64
end

function X.DecompressLUAData(szCompressBinBase64)
	local szCompressBin = X.DecodeURIComponentBase64(szCompressBinBase64)
	local szBin = X.Deflate:DecompressZlib(szCompressBin)
	local xData = X.DecodeLUAData(szBin)
	return xData
end

function X.KGUIEncrypt(szText)
	if not X.IsString(szText) then
		return
	end
	if EncodeData then
		szText = EncodeData(X.SimpleEncryptString(szText)) or szText
	end
	if KGUIEncrypt then
		szText = KGUIEncrypt(X.SimpleEncryptString(szText)) or szText
	end
	return MD5 and string.lower(MD5(X.SimpleEncryptString(szText))) or X.SimpleEncryptString(szText)
end
X.KE = X.KGUIEncrypt

-- ��ȡ URI ����Ŀ¼
---@param szURI string @��Ҫ��ȡ����Ŀ¼�� URI
---@return string @����Ŀ¼��������βĿ¼�ָ���
function X.GetParentURI(szURI)
	local szURI = X.NormalizeURI(szURI)
	if not szURI:find('/') then
		return '.'
	end
	local szParent = szURI:gsub('/[^/]+/*$', '')
	if szParent == '' and szURI:sub(1, 1) == '/' then
		szParent = '/'
	end
	return szParent
end

-- ƴ�� URI �ַ���
---@vararg string @��Ҫƴ�ӵ� URI ����
---@return string @ƴ�Ӻ�� URI
function X.ConcatURI(...)
	local aPath = {...}
	local szPath = ''
	for _, s in ipairs(aPath) do
		s = tostring(s):gsub('^[/]+', '')
		if s ~= '' then
			szPath = szPath:gsub('[/]+$', '')
			if szPath ~= '' then
				szPath = szPath .. '/'
			end
			szPath = szPath .. s
		end
	end
	return szPath
end

-- ��׼�� URI �ַ���ɾ�� URI �е�/./��/../
---@param szURI string @Ҫ����� URI �ַ���
---@return string @��׼����� URI �ַ���
function X.NormalizeURI(szURI)
	szURI = szURI:gsub('/%./', '/')
	local nPos1, nPos2
	while true do
		nPos1, nPos2 = szURI:find('[^/]*/%.%./')
		if not nPos1 then
			break
		end
		szURI = szURI:sub(1, nPos1 - 1) .. szURI:sub(nPos2 + 1)
	end
	return szURI
end

-- ���ڶ����� URI ���б��룺��������������ַ����� [a-zA-Z0-9-_.!~*'():/?#]
---@param data string @��Ҫ���������
---@return string @����������
function X.EncodeURI(data)
	return (data:gsub('([^a-zA-Z0-9-_.!~*\'():/?#])', function (c) return string.format('%%%02X', string.byte(c)) end))
end

-- ���ڶ� URI �е�ÿ��������б��룺��������������ַ����� [a-zA-Z0-9-_.!~*'()]
---@generic T
---@param data T @��Ҫ���������
---@return T @����������
local function EncodeURIComponent(data)
	if type(data) == 'string' then
		return (data:gsub('([^a-zA-Z0-9-_.!~*\'()])', function (c) return string.format('%%%02X', string.byte(c)) end))
	end
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			t[EncodeURIComponent(k)] = EncodeURIComponent(v)
		end
		return t
	end
	return data
end
X.EncodeURIComponent = EncodeURIComponent

-- ���� URL �еĲ���
-- @param {any} data ��Ҫ���������
-- @return {typeof data} ����������
local function DecodeURIComponent(data)
	if type(data) == 'string' then
		return (data:gsub('+', ' '):gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end))
	end
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			t[DecodeURIComponent(k)] = DecodeURIComponent(v)
		end
		return t
	end
	return data
end
X.DecodeURIComponent = DecodeURIComponent

-- ���ڶ��ļ�Э��·������ URI ���룺��������������ַ����� [a-zA-Z0-9-_.!~*'():/?]
---@param szFilePath string @��Ҫ�����·��
---@return string @������ URI
function X.EncodeFileURI(szFilePath)
	return 'file:///' .. szFilePath:gsub('([^a-zA-Z0-9-_.!~*\'():/?])', function (c) return string.format('%%%02X', string.byte(c)) end)
end

local function EncodeQuerystring(t, prefix, data)
	if type(data) == 'table' then
		local first = true
		for k, v in pairs(data) do
			if first then
				first = false
			else
				table.insert(t, '&')
			end
			k = EncodeURIComponent(tostring(k))
			if prefix == '' then
				EncodeQuerystring(t, k, v)
			else
				EncodeQuerystring(t, prefix .. '[' .. k .. ']', v)
			end
		end
	else
		if prefix ~= '' then
			table.insert(t, prefix)
			table.insert(t, '=')
		end
		table.insert(t, EncodeURIComponent(tostring(data)))
	end
	return t
end

-- �� POST ���ݼ�ֵ��ת��Ϊ application/x-www-form-urlencoded ���������ַ���
-- @param {table} data POST ���ݼ�ֵ��
-- @return {string} ���������ַ���
function X.EncodeQuerystring(data)
	return table.concat(EncodeQuerystring({}, '', data))
end

-- �� application/x-www-form-urlencoded ���������ַ���ת��Ϊ POST ���ݼ�ֵ��
-- @param {string} ���������ַ���
-- @return {table} data POST ���ݼ�ֵ��
function X.DecodeQuerystring(s)
	local data = {}
	for _, kvp in ipairs(X.SplitString(s, '&', true)) do
		kvp = X.SplitString(kvp, '=')
		local k, v = kvp[1], kvp[2]
		local pos = X.StringFindW(k, '[')
		if pos then
			local ks = { DecodeURIComponent(string.sub(k, 1, pos - 1)) }
			k = string.sub(k, pos)
			while X.StringSubW(k, 1, 1) == '[' do
				pos = X.StringFindW(k, ']') or (string.len(k) + 1)
				table.insert(ks, DecodeURIComponent(string.sub(k, 2, pos - 1)))
				k = string.sub(k, pos + 1)
			end
			X.Set(data, ks, DecodeURIComponent(v))
		else
			data[DecodeURIComponent(k)] = DecodeURIComponent(v)
		end
	end
	return data
end

local function ConvertToUTF8(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == 'string' then
				t[ConvertToUTF8(k)] = ConvertToUTF8(v)
			else
				t[k] = ConvertToUTF8(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return AnsiToUTF8(data)
	else
		return data
	end
end
X.ConvertToUTF8 = ConvertToUTF8

local function ConvertToANSI(data)
	if type(data) == 'table' then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == 'string' then
				t[ConvertToANSI(k)] = ConvertToANSI(v)
			else
				t[k] = ConvertToANSI(v)
			end
		end
		return t
	elseif type(data) == 'string' then
		return UTF8ToAnsi(data)
	else
		return data
	end
end
X.ConvertToANSI = ConvertToANSI

local m_simpleMatchCache = setmetatable({}, { __mode = 'v' })
function X.StringSimpleMatch(szText, szFind, bDistinctCase, bDistinctEnEm, bIgnoreSpace)
	if not bDistinctCase then
		szFind = StringLowerW(szFind)
		szText = StringLowerW(szText)
	end
	if not bDistinctEnEm then
		szText = StringEnerW(szText)
	end
	if bIgnoreSpace then
		szFind = X.StringReplaceW(szFind, ' ', '')
		szFind = X.StringReplaceW(szFind, g_tStrings.STR_ONE_CHINESE_SPACE, '')
		szText = X.StringReplaceW(szText, ' ', '')
		szText = X.StringReplaceW(szText, g_tStrings.STR_ONE_CHINESE_SPACE, '')
	end
	local me = X.GetClientPlayer()
	if me then
		szFind = szFind:gsub('$zj', me.szName)
		local szTongName = X.GetTongName(me.dwTongID) or ''
		szFind = szFind:gsub('$bh', szTongName)
		szFind = szFind:gsub('$gh', szTongName)
	end
	local tFind = m_simpleMatchCache[szFind]
	if not tFind then
		tFind = {}
		for _, szKeywordsLine in ipairs(X.SplitString(szFind, ';', true)) do
			local tKeyWordsLine = {}
			for _, szKeywords in ipairs(X.SplitString(szKeywordsLine, ',', true)) do
				local tKeyWords = {}
				for _, szKeyword in ipairs(X.SplitString(szKeywords, '|', true)) do
					local bNegative = szKeyword:sub(1, 1) == '!'
					if bNegative then
						szKeyword = szKeyword:sub(2)
					end
					if not bDistinctEnEm then
						szKeyword = StringEnerW(szKeyword)
					end
					table.insert(tKeyWords, { szKeyword = szKeyword, bNegative = bNegative })
				end
				table.insert(tKeyWordsLine, tKeyWords)
			end
			table.insert(tFind, tKeyWordsLine)
		end
		m_simpleMatchCache[szFind] = tFind
	end
	-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������;��ս
	local bKeyWordsLine = false
	for _, tKeyWordsLine in ipairs(tFind) do         -- ����һ������
		-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������
		local bKeyWords = true
		for _, tKeyWords in ipairs(tKeyWordsLine) do -- ����ȫ������
			-- 10|ʮ��
			local bKeyWord = false
			for _, info in ipairs(tKeyWords) do      -- ����һ������
				-- szKeyword = X.EscapeString(szKeyword) -- ����wstring��Escape���ݱ�
				if info.bNegative then               -- !С��������
					if info.szKeyword ~= '' and not X.StringFindW(szText, info.szKeyword) then
						bKeyWord = true
					end
				else                                                    -- ʮ��   -- 10
					if info.szKeyword ~= '' and X.StringFindW(szText, info.szKeyword) then
						bKeyWord = true
					end
				end
				if bKeyWord then
					break
				end
			end
			bKeyWords = bKeyWords and bKeyWord
			if not bKeyWords then
				break
			end
		end
		bKeyWordsLine = bKeyWordsLine or bKeyWords
		if bKeyWordsLine then
			break
		end
	end
	return bKeyWordsLine
end

function X.IsSensitiveWord(szText)
	if not _G.TextFilterCheck then
		return false
	end
	return not _G.TextFilterCheck(szText)
end

function X.ReplaceSensitiveWord(szText)
	if not _G.TextFilterReplace then
		return szText
	end
	local bResult, szResult = _G.TextFilterReplace(szText)
	if not bResult then
		return szText
	end
	return szResult
end

do
local CACHE = setmetatable({}, { __mode = 'v' })
function X.GetFormatText(...)
	local szKey = X.EncodeLUAData({...})
	if not CACHE[szKey] then
		CACHE[szKey] = {GetFormatText(...)}
	end
	return CACHE[szKey][1]
end
end

do
local CACHE = setmetatable({}, { __mode = 'v' })
function X.GetPureText(szXml, szDriver)
	if not szDriver then
		szDriver = 'AUTO'
	end
	local cache = CACHE[szXml]
	if not cache then
		cache = {}
		CACHE[szXml] = cache
	end
	if X.IsNil(cache.c) and (szDriver == 'CPP' or szDriver == 'AUTO') then
		cache.c = GetPureText
			and GetPureText(szXml)
			or false
	end
	if X.IsNil(cache.l) and (szDriver == 'LUA' or (szDriver == 'AUTO' and not cache.c)) then
		local aXMLNode = X.XMLDecode(szXml)
		cache.l = X.XMLGetPureText(aXMLNode) or false
	end
	if szDriver == 'CPP' then
		return cache.c
	end
	if szDriver == 'LUA' then
		return cache.l
	end
	return cache.c or cache.l
end
end

function X.FormatCharCodeString(s, m)
	local a = {}
	for i = 1, #s do
		a[i] = string.byte(s, i)
	end
	local f = m == 'hex'
		and '0x%x'
		or '%s'
	for i, v in ipairs(a) do
		a[i] = f:format(v)
	end
	return table.concat(a, ', ')
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
