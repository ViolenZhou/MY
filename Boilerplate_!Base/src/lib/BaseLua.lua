--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : LUA ��������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------

local RANDOM_VALUE = nil
-- ��֤����һ�ν����ͬ�����������������������ֵʱ�򲻱�֤
---@param nMin number @����
---@param nMax number @����
---@return number @������
function X.Random(...)
	-- init
	if not RANDOM_VALUE then
		-- math.randomseed(os.clock() * math.random(os.time()))
		math.randomseed(GetTickCount() * math.random(GetCurrentTime()))
	end
	-- do random
	local fValue = math.random()
	local nRetry = 0 --[[#DEBUG LINE]]
	while fValue == RANDOM_VALUE do
		--[[#DEBUG BEGIN]]
		if nRetry >= 200 then
			X.Debug(X.PACKET_INFO.NAME_SPACE, 'Random retried for ' .. nRetry .. ' times, but still get same value: ' .. fValue .. ', you should be attention about this!', X.DEBUG_LEVEL.ERROR)
			break
		end
		nRetry = nRetry + 1
		--[[#DEBUG END]]
		fValue = math.random()
	end
	RANDOM_VALUE = fValue
	-- finalize
	local nArgs = select('#', ...)
	if nArgs == 0 or nArgs > 2 then
		return fValue
	end
	local nMin, nMax = 1, 1
	if nArgs == 1 then
		nMin, nMax = 1, ...
	elseif nArgs == 2 then
		nMin, nMax = ...
	end
	return math.floor(fValue * (nMax - nMin)) + nMin
end

-- ��ȡ����ջ
---@param str string @����ջ�����ַ���
---@return string @��������ջ
function X.GetTraceback(str)
	local traceback = debug and debug.traceback and debug.traceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	if traceback then
		if str then
			str = str .. '\n' .. traceback
		else
			str = traceback
		end
	end
	return str or ''
end

-- ��Ԫ����
---@generic T1, T2
---@param condition boolean @����
---@param trueValue T1 @����Ϊ��ʱ��ֵ
---@param falseValue T2 @����Ϊ��ʱ��ֵ
---@return T1 | T2 @����Ϊ��ʱ��ֵ������Ϊ����Ϊ��ʱ��ֵ
function X.IIf(condition, trueValue, falseValue)
	if condition then
		return trueValue
	end
	return falseValue
end

-- ��¡����
---@generic T
---@param var T @��Ҫ��¡������
---@return T @��¡�������
function X.Clone(var)
	if type(var) == 'table' then
		local ret = {}
		for k, v in pairs(var) do
			ret[X.Clone(k)] = X.Clone(v)
		end
		return ret
	else
		return var
	end
end

-- ��ȡ����
---@param var any @��Ҫ��ȡ������
---@param keys string | string[] @��Ҫ��ȡ�ļ�
---@param dft any @Ĭ��ֵ
---@return any @��ȡ�������
function X.Get(var, keys, dft)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		for _, k in ipairs(keys) do
			if type(var) == 'table' then
				var, res = var[k], true
			else
				var, res = dft, false
				break
			end
		end
	end
	if var == nil then
		var, res = dft, false
	end
	return var, res
end

-- ��������
---@param var any @��Ҫ���õ�����
---@param keys string | string[] @��Ҫ���õļ�
---@param val any @��Ҫ���õ�ֵ
---@return void
function X.Set(var, keys, val)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		local n = #keys
		for i = 1, n do
			local k = keys[i]
			if type(var) == 'table' then
				if i == n then
					var[k], res = val, true
				else
					if var[k] == nil then
						var[k] = {}
					end
					var = var[k]
				end
			else
				break
			end
		end
	end
	return res
end

-- �������
---@vararg any @��Ҫ���������
---@return table @����������
X.Pack = table.pack or function(...)
	return { n = select("#", ...), ... }
end

-- �������
---@param t table @��Ҫ���������
---@param i number @����Ŀ�ʼλ��
---@param j number @����Ľ���λ��
---@return any @����������
X.Unpack = table.unpack or unpack

-- ���ݳ���
---@param t table | string @��Ҫ���㳤�ȵ�����
---@return number @���ݳ���
function X.Len(t)
	if type(t) == 'table' then
		return t.n or #t
	end
	return #t
end

-- �ϲ�����
---@generic T
---@vararg T @��Ҫ�ϲ�������
---@return T @�ϲ��������
function X.Assign(t, ...)
	for index = 1, select('#', ...) do
		local t1 = select(index, ...)
		if type(t1) == 'table' then
			for k, v in pairs(t1) do
				t[k] = v
			end
		end
	end
	return t
end

-- �ж��Ƿ�Ϊ��
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ��
function X.IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end

-- ����ж����
---@param o1 any @��Ҫ�жϵ�����1
---@param o2 any @��Ҫ�жϵ�����2
---@return boolean @�Ƿ����
function X.IsEquals(o1, o2)
	if o1 == o2 then
		return true
	elseif type(o1) ~= type(o2) then
		return false
	elseif type(o1) == 'table' then
		local t = {}
		for k, v in pairs(o1) do
			if X.IsEquals(o1[k], o2[k]) then
				t[k] = true
			else
				return false
			end
		end
		for k, v in pairs(o2) do
			if not t[k] then
				return false
			end
		end
		return true
	end
	return false
end

-- �������
---@param var any[] @��Ҫ���������
---@return any @���������
function X.RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[math.random(1, #var)]
	end
end

-- �ж������Ƿ�Ϊ����
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ����
function X.IsArray(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return false
		end
		i = i + 1
	end
	return true
end

-- �ж������Ƿ�Ϊ�ֵ�
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ�ֵ�
function X.IsDictionary(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return true
		end
		i = i + 1
	end
	return false
end

-- �ж������Ƿ�Ϊ��
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ��
function X.IsNil(var)
	return type(var) == 'nil'
end

-- �ж������Ƿ�Ϊ��
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ��
function X.IsTable(var)
	return type(var) == 'table'
end

-- �ж������Ƿ�Ϊ����
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ����
function X.IsNumber(var)
	return type(var) == 'number'
end

-- �ж������Ƿ�Ϊ�ַ���
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ�ַ���
function X.IsString(var)
	return type(var) == 'string'
end

-- �ж������Ƿ�Ϊ����ֵ
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ����ֵ
function X.IsBoolean(var)
	return type(var) == 'boolean'
end

-- �ж������Ƿ�Ϊ����
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ����
function X.IsFunction(var)
	return type(var) == 'function'
end

-- �ж������Ƿ�Ϊ C++ ����
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ C++ ����
function X.IsUserdata(var)
	return type(var) == 'userdata'
end

-- �ж������Ƿ�Ϊ������
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ������
function X.IsHugeNumber(var)
	return X.IsNumber(var) and not (var < math.huge and var > -math.huge)
end

-- �ж������Ƿ�Ϊ��Ч�Ľ���Ԫ�ز���ָ��
---@param var any @��Ҫ�жϵ�����
---@return boolean @�Ƿ�Ϊ��Ч�Ľ���Ԫ�ز���ָ��
function X.IsElement(var)
	return type(var) == 'table' and var.IsValid
		and var:IsValid()
		or false
end

-- ��������Ϊֻ��
---@generic T
---@param t T ��Ҫ��Ϊֻ���ı�
---@return T ��Ϊֻ���ı�
function X.SetmetaReadonly(t)
	local p = setmetatable({}, { __index = t })
	for k, v in pairs(t) do
		if type(v) == 'table' then
			p[k] = X.SetmetaReadonly(v)
		else
			p[k] = v
		end
	end
	return setmetatable({}, {
		__index     = p,
		__newindex  = function() assert(false, 'table is readonly\n') end,
		__metatable = {
			const_table = t,
		},
	})
end

-- ��������Ϊ������
---@generic T
---@param t T @��Ҫ��Ϊ�����صı�
---@param _keyLoader table<string, fun(k: string): any> @�����ݵ������غ���
---@param fallbackLoader fun(k: string): any @�����ݵ�ͨ�������غ���
---@return T @��Ϊ�����صı�
function X.SetmetaLazyload(t, _keyLoader, fallbackLoader)
	local keyLoader = X.Clone(_keyLoader)
	local p = setmetatable({}, { __index = t })
	for k, v in pairs(t) do
		p[k] = v
	end
	return setmetatable(p, {
		__index = function(t, k)
			local loader = keyLoader[k]
			if loader then
				keyLoader[k] = nil
				if not next(keyLoader) then
					setmetatable(t, nil)
				end
			else
				loader = fallbackLoader
			end
			if loader then
				local v = loader(k)
				t[k] = v
				return v
			end
		end,
	})
end

-- ��ֵ������ת����
---@param kvp any[][] @��ֵ������
---@return table @����
function X.KvpToObject(kvp)
	local t = {}
	for _, v in ipairs(kvp) do
		if not X.IsNil(v[1]) then
			t[v[1]] = v[2]
		end
	end
	return t
end

-- �б�ת�б�ֵΪ���Ķ���
---@param arr any[] @�б�
---@return table @����
function X.ArrayToObject(arr)
	if not arr then
		return
	end
	local t = {}
	for k, v in pairs(arr) do
		t[v] = true
	end
	return t
end

-- ��ת�����ֵ
---@param obj table @����
---@return table @����
function X.FlipObjectKV(obj)
	local t = {}
	for k, v in pairs(obj) do
		t[v] = k
	end
	return t
end

-- �������ݲ���
---@param oBase any @ԭʼ����
---@param oData any @Ŀ������
---@return table @��������
function X.GetPatch(oBase, oData)
	-- dictionary patch
	if X.IsDictionary(oData) or (X.IsDictionary(oBase) and X.IsTable(oData) and X.IsEmpty(oData)) then
		-- dictionary raw value patch
		if not X.IsTable(oBase) then
			return { v = oData }
		end
		-- dictionary children patch
		local tKeys, bDiff = {}, false
		local oPatch = {}
		for k, v in pairs(oData) do
			local patch = X.GetPatch(oBase[k], v)
			if not X.IsNil(patch) then
				bDiff = true
				table.insert(oPatch, { k = k, v = patch })
			end
			tKeys[k] = true
		end
		for k, v in pairs(oBase) do
			if not tKeys[k] then
				bDiff = true
				table.insert(oPatch, { k = k, v = nil })
			end
		end
		if not bDiff then
			return nil
		end
		return oPatch
	end
	if not X.IsEquals(oBase, oData) then
		-- nil value patch
		if X.IsNil(oData) then
			return { t = 'nil' }
		end
		-- table value patch
		if X.IsTable(oData) then
			return { v = oData }
		end
		-- other patch value
		return oData
	end
	-- empty patch
	return nil
end

-- ����Ӧ�ò���
---@param oBase any @ԭʼ����
---@param oPatch any @��������
---@param bNew boolean @�Ƿ񴴽��µ����ݣ��������޸Ĵ�������ݣ�
---@return any @Ӧ�ú������
function X.ApplyPatch(oBase, oPatch, bNew)
	if bNew ~= false then
		oBase = X.Clone(oBase)
		oPatch = X.Clone(oPatch)
	end
	-- patch in dictionary type can only be a special value patch
	if X.IsDictionary(oPatch) then
		-- nil value patch
		if oPatch.t == 'nil' then
			return nil
		end
		-- raw value patch
		if not X.IsNil(oPatch.v) then
			return oPatch.v
		end
	end
	-- dictionary patch
	if X.IsTable(oPatch) and X.IsDictionary(oPatch[1]) then
		if not X.IsTable(oBase) then
			oBase = {}
		end
		for _, patch in ipairs(oPatch) do
			if X.IsNil(patch.v) then
				oBase[patch.k] = nil
			else
				oBase[patch.k] = X.ApplyPatch(oBase[patch.k], patch.v, false)
			end
		end
		return oBase
	end
	-- empty patch
	if X.IsNil(oPatch) then
		return oBase
	end
	-- other patch value
	return oPatch
end

-----------------------------------------------
-- ѡ����
-----------------------------------------------

---@type fun(t: table): number @��ȡֻ������
X.count_c  = count_c

---@type fun(t: table): fun(tab: table, index: number), table, number @����ֻ����
X.pairs_c  = pairs_c

---@type fun(t: table): fun(tab: table, index: number), table, number @�������ֻ������
X.ipairs_c = ipairs_c

local function IpairsIterR(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end

-- ��������ѡ���� -- for i, v in X.ipairs_r(data) do
---@param tab table @��Ҫ�����ı�
---@return fun(tab: table, index: number), table, number @��������
function X.ipairs_r(tab)
	return IpairsIterR, tab, #tab + 1
end

local function SafePairsIter(a, i)
	i = i + 1
	if a[i] then
		return i, a[i][1], a[i][2], a[i][3]
	end
end

-- ��ȫ�Ķ������ѡ���� -- for i, v, d, di in X.sipairs(data1, data2, ...) do
---@vararg table @��Ҫ�����ı�
---@return fun(tab: table, index: number), table, number @��������
function X.sipairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIter, iters, 0
end

-- ��ȫ�Ķ��ѡ���� -- for i, v, d, di in X.spairs(data1, data2, ...) do
---@vararg table @��Ҫ�����ı�
---@return fun(tab: table, index: number), table, number @��������
function X.spairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIter, iters, 0
end

local function SafePairsIterR(a, i)
	i = i - 1
	if i > 0 then
		return i, a[i][1], a[i][2], a[i][3]
	end
end

-- ��ȫ�Ķ�����鵹��ѡ���� -- for i, v, d, di in X.sipairs_r(data1, data2, ...) do
---@vararg table @��Ҫ�����ı�
---@return fun(tab: table, index: number), table, number @��������
function X.sipairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIterR, iters, #iters + 1
end

-- ��ȫ�Ķ����ѡ���� -- for i, v, d, di in X.spairs_r(data1, data2, ...) do
---@vararg table @��Ҫ�����ı�
---@return fun(tab: table, index: number), table, number @��������
function X.spairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if X.IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafePairsIterR, iters, #iters + 1
end

-----------------------------------------------
-- ��
-----------------------------------------------
local function ClassCreateInstance(c, ins, ...)
	if not ins then
		ins = c
	end
	if c.ctor then
		c.ctor(ins, ...)
	end
	return c
end

-- ������
---@param className string @����
---@param super table @����
---@return table @��
function X.Class(className, super)
	local classPrototype
	if type(super) == 'string' then
		className, super = super, nil
	end
	if not className then
		className = 'Unnamed Class'
	end
	classPrototype = (function ()
		local proxys = {}
		if super then
			proxys.super = super
			setmetatable(proxys, { __index = super })
		end
		return setmetatable({}, {
			__index = proxys,
			__tostring = function(t) return className .. ' (class prototype)' end,
			__call = function (...)
				return ClassCreateInstance(setmetatable({}, {
					__index = classPrototype,
					__tostring = function(t) return className .. ' (class instance)' end,
				}), nil, ...)
			end,
		})
	end)()
	return classPrototype
end

-----------------------------------------------
-- ��ȫ����
-----------------------------------------------
do
local xpAction, xpArgs, xpErrMsg, xpTraceback, xpErrLog
local function CallHandler()
	return xpAction(X.Unpack(xpArgs))
end
local function CallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = X.GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	xpErrLog = (errMsg or '') .. '\n' .. xpTraceback
	Log(xpErrLog)
	FireUIEvent('CALL_LUA_ERROR', xpErrLog .. '\n')
end
local function XpCallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = X.GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
end

-- ��ȫ���ã��������������־
---@param fnAction fun(...) @���ú���
---@param ... any @���ò���
---@return boolean, any @���ý��
function X.Call(fnAction, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = fnAction, X.Pack(...), nil, nil
	local res = X.Pack(xpcall(CallHandler, CallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return X.Unpack(res)
end

-- ��ȫ���ã������������־
---@param fnAction fun(...) @���ú���
---@param ... any @���ò���
---@return boolean, any @���ý��
function X.XpCall(fnAction, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = fnAction, X.Pack(...), nil, nil
	local res = X.Pack(xpcall(CallHandler, XpCallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return X.Unpack(res)
end
end

-- Ԥ�����ö����Ƿ�Ϊ�����İ�ȫ���ã��������������־
---@param fnAction fun(...) @���ú���
---@param ... any @���ò���
---@return boolean, any @���ý��
function X.SafeCall(fnAction, ...)
	if not X.IsFunction(fnAction) then
		return false, 'NOT CALLABLE'
	end
	return X.Call(fnAction, ...)
end

-- ���������ĵİ�ȫ���ã��������������־
---@param fnAction fun(...) @���ú���
---@param ... any @���ò���
---@return boolean, any @���ý��
function X.CallWithThis(context, fnAction, ...)
	local _this = this
	this = context
	local rtc = X.Pack(X.Call(fnAction, ...))
	this = _this
	return X.Unpack(rtc)
end

-- Ԥ�����ö����Ƿ�Ϊ���������������ĵİ�ȫ���ã��������������־
---@param fnAction fun(...) @���ú���
---@param ... any @���ò���
---@return boolean, any @���ý��
function X.SafeCallWithThis(context, fnAction, ...)
	local _this = this
	this = context
	local rtc = X.Pack(X.SafeCall(fnAction, ...))
	this = _this
	return X.Unpack(rtc)
end

-----------------------------------------------
-- ���ַ�
-----------------------------------------------

-- ��ȡ�ַ�������
---@param s string @��Ҫ��ȡ���ȵ��ַ���
---@return number @�ַ�������
X.StringLenW = wstring.len

-- ��ȡ�ַ���
---@param str string ��Ҫ��ȡ���ַ���
---@param s number ��ʼλ��
---@param e number ����λ��
---@return string ��ȡ����ַ���
function X.StringSubW(str, s, e)
	if s < 0 or not e or e < 0 then
		local nLen = wstring.len(str)
		if s < 0 then
			s = nLen + s + 1
		end
		if not e then
			e = nLen
		elseif e < 0 then
			e = nLen + e + 1
		end
	end
	return wstring.sub(str, s, e)
end

-- �ַ����ַ�������
---@param str string @��Ҫ�������ַ���
---@param func function(s: string): void @������
---@return void
X.StringEachW = wstring.char_task

-- �ַ�������
---@param s string @��Ҫ���ҵ��ַ���
---@param p string @���ҵ��ַ���
---@return number, number @[nStartPos, nEndPos] ��ʼλ�ã�����λ��
X.StringFindW = StringFindW or wstring.find

-- �ַ����и�
---@param s string @��Ҫ�и���ַ���
---@param p string @�ָ���
---@return string[] @�и����ַ���
X.StringSplitW = wstring.split

-- �ַ���ת���
---@param s string @��Ҫת��ǵ��ַ���
---@return string @ת��Ǻ���ַ���
X.StringEnerW = StringEnerW or wstring.ener

-- �ַ���תСд
---@param s string @��ҪתСд���ַ���
---@return string @תСд����ַ���
X.StringLowerW = StringLowerW or wstring.lower

-- �ַ����滻
---@param s string @��Ҫ�滻���ַ���
---@param p string @���ҵ��ַ���
---@param r string @�滻���ַ���
---@return string @�滻����ַ���
X.StringReplaceW = StringReplaceW or wstring.replace
