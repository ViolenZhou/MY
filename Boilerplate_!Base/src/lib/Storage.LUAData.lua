--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : LUA ����
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage.LUAData')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ������ݴ洢Ĭ����Կ
local GetLUADataPathPassphrase
do
local function GetPassphrase(nSeed, nLen)
	local a = {}
	local b, c = 0x20, 0x7e - 0x20 + 1
	for i = 1, nLen do
		table.insert(a, ((i + nSeed) % 256 * (2 * i + nSeed) % 32) % c + b)
	end
	return string.char(X.Unpack(a))
end
local szDataRoot = StringLowerW(X.FormatPath({'', X.PATH_TYPE.DATA}))
local szPassphrase = GetPassphrase(666, 233)
local szPassphraseSalted = X.SECRET['@@LUA_DATA_MANIFEST_SALT@@']
	and (X.KGUIEncrypt(X.SECRET['@@LUA_DATA_MANIFEST_SALT@@']) .. szPassphrase)
	or szPassphrase
local CACHE = {}
function GetLUADataPathPassphrase(szPath)
	-- ���Դ�Сд
	szPath = StringLowerW(szPath)
	-- ȥ��Ŀ¼ǰ׺
	if szPath:sub(1, szDataRoot:len()) ~= szDataRoot then
		return
	end
	szPath = szPath:sub(#szDataRoot + 1)
	-- ������ݷ����ַ
	local nPos = X.StringFindW(szPath, '/')
	if not nPos or nPos == 1 then
		return
	end
	local szDomain = szPath:sub(1, nPos)
	szPath = szPath:sub(nPos + 1)
	-- ���˲���Ҫ���ܵĵ�ַ
	local nPos = X.StringFindW(szPath, '/')
	if nPos then
		if szPath:sub(1, nPos - 1) == 'export' then
			return
		end
	end
	-- ��ȡ�򴴽���Կ
	local bNew = false
	if not CACHE[szDomain] or not CACHE[szDomain][szPath] then
		local szFilePath = szDataRoot .. szDomain .. '/manifest.jx3dat'
		CACHE[szDomain] = LoadLUAData(szFilePath, { passphrase = szPassphraseSalted })
			or LoadLUAData(szFilePath, { passphrase = szPassphrase })
			or {}
		if not CACHE[szDomain][szPath] then
			bNew = true
			CACHE[szDomain][szPath] = X.GetUUID():gsub('-', '')
			SaveLUAData(szFilePath, CACHE[szDomain], { passphrase = szPassphraseSalted })
		end
	end
	return CACHE[szDomain][szPath], bNew
end
end

-- ��ȡ�����Ψһ��ʾ��
do
local GUID
function X.GetClientGUID()
	if not GUID then
		local szRandom = GetLUADataPathPassphrase(X.GetLUADataPath({'GUIDv2', X.PATH_TYPE.GLOBAL}))
		local szPrefix = MD5(szRandom):sub(1, 4)
		local nCSW, nCSH = GetSystemCScreen()
		local szCS = MD5(nCSW .. ',' .. nCSH):sub(1, 4)
		GUID = ('%s%X%s'):format(szPrefix, GetStringCRC(szRandom), szCS)
	end
	return GUID
end
end

-- ���������ļ�
function X.SaveLUAData(oFilePath, oData, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = X.Clone(tConfig) or {}, nil, nil
	local szFilePath = X.GetLUADataPath(oFilePath)
	if X.IsNil(config.passphrase) then
		config.passphrase = GetLUADataPathPassphrase(szFilePath)
	end
	local data = SaveLUAData(szFilePath, oData, config)
	--[[#DEBUG BEGIN]]
	nStartTick = GetTickCount() - nStartTick
	if nStartTick > 5 then
		X.OutputDebugMessage('PMTool', _L('%s saved during %dms.', szFilePath, nStartTick), X.DEBUG_LEVEL.PM_LOG)
	end
	--[[#DEBUG END]]
	return data
end

-- ���������ļ�
function X.LoadLUAData(oFilePath, tConfig)
	--[[#DEBUG BEGIN]]
	local nStartTick = GetTickCount()
	--[[#DEBUG END]]
	local config, szPassphrase, bNew = X.Clone(tConfig) or {}, nil, nil
	local szFilePath = X.GetLUADataPath(oFilePath)
	if X.IsNil(config.passphrase) then
		szPassphrase, bNew = GetLUADataPathPassphrase(szFilePath)
		if not bNew then
			config.passphrase = szPassphrase
		end
	end
	local data = LoadLUAData(szFilePath, config)
	if bNew and data then
		config.passphrase = szPassphrase
		SaveLUAData(szFilePath, data, config)
	end
	--[[#DEBUG BEGIN]]
	nStartTick = GetTickCount() - nStartTick
	if nStartTick > 5 then
		X.OutputDebugMessage('PMTool', _L('%s loaded during %dms.', szFilePath, nStartTick), X.DEBUG_LEVEL.PM_LOG)
	end
	--[[#DEBUG END]]
	return data
end

-----------------------------------------------
-- ��������ɢ��ֵ
-----------------------------------------------
do
local function TableSorterK(a, b) return a.k > b.k end
local function GetLUADataHashSYNC(data)
	local szType = type(data)
	if szType == 'table' then
		local aChild = {}
		for k, v in pairs(data) do
			table.insert(aChild, { k = GetLUADataHashSYNC(k), v = GetLUADataHashSYNC(v) })
		end
		table.sort(aChild, TableSorterK)
		for i, v in ipairs(aChild) do
			aChild[i] = v.k .. ':' .. v.v
		end
		return GetLUADataHashSYNC('{}::' .. table.concat(aChild, ';'))
	end
	return tostring(GetStringCRC(szType .. ':' .. tostring(data)))
end

local function GetLUADataHash(data, fnAction)
	if not fnAction then
		return GetLUADataHashSYNC(data)
	end

	local __stack__ = {}
	local __retvals__ = {}

	local function __new_context__(continuation)
		local prev = __stack__[#__stack__]
		local current = {
			continuation = continuation,
			arguments = prev and prev.arguments,
			state = {},
			context = setmetatable({}, { __index = prev and prev.context }),
		}
		table.insert(__stack__, current)
		return current
	end

	local function __exit_context__()
		table.remove(__stack__)
	end

	local function __call__(...)
		table.insert(__stack__, {
			continuation = '0',
			arguments = X.Pack(...),
			state = {},
			context = {},
		})
	end

	local function __return__(...)
		__exit_context__()
		__retvals__ = X.Pack(...)
	end

	__call__(data)

	local current, continuation, arguments, state, context, timer

	timer = X.BreatheCall(function()
		local nTime = GetTime()

		while #__stack__ > 0 do
			current = __stack__[#__stack__]
			continuation = current.continuation
			arguments = current.arguments
			state = current.state
			context = current.context

			if continuation == '0' then
				if type(arguments[1]) == 'table' then
					__new_context__('1')
				else
					__return__(tostring(GetStringCRC(type(arguments[1]) .. ':' .. tostring(arguments[1]))))
				end
			elseif continuation == '1' then
				context.aChild = {}
				current.continuation = '1.1'
			elseif continuation == '1.1' then
				state.k = next(arguments[1], state.k)
				if state.k ~= nil then
					local nxt = __new_context__('2')
					nxt.context.k = state.k
					nxt.context.v = arguments[1][state.k]
				else
					table.sort(context.aChild, TableSorterK)
					for i, v in ipairs(context.aChild) do
						context.aChild[i] = v.k .. ':' .. v.v
					end
					__call__('{}::' .. table.concat(context.aChild, ';'))
					current.continuation = '1.2'
				end
			elseif continuation == '1.2' then
				__return__(X.Unpack(__retvals__))
				__return__(X.Unpack(__retvals__))
			elseif continuation == '2' then
				__call__(context.k)
				current.continuation = '2.1'
			elseif continuation == '2.1' then
				context.ks = __retvals__[1]
				__call__(context.v)
				current.continuation = '2.2'
			elseif continuation == '2.2' then
				context.vs = __retvals__[1]
				table.insert(context.aChild, { k = context.ks, v = context.vs })
				__exit_context__()
			end

			if GetTime() - nTime > 100 then
				return
			end
		end

		X.BreatheCall(timer, false)
		X.SafeCall(fnAction, X.Unpack(__retvals__))
	end)
end
X.GetLUADataHash = GetLUADataHash
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
