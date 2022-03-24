--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ʱ�����ں���ģ��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------
-- ʱ�Ӻ�����������
---------------------------------------------------------------------
-- ����        ����        �ô�         ʱ�䵥λ    ��Сʱ�侫��(ms)
-- DelayCall   �ӳٵ���   ����ʱ         ����       1 / GLOBAL.GAME_FPS
-- BreatheCall ��������   ÿ֡����       ����       1 / GLOBAL.GAME_FPS
-- FrameCall   ��֡����   ÿ֡����       ����֡     1 / GLOBAL.GAME_FPS
-- RenderCall  ��Ⱦ����   ÿ����Ⱦ����   ����       1 / ÿ����Ⱦ����
-- Debounce    ���÷���   �ӳٵ���һ��   ����       1 / GLOBAL.GAME_FPS
-- Throttle    ���ý���   �ֶ�Ƶ������   ����       1 / GLOBAL.GAME_FPS
-- FinallyThrottle ȷ���ӳٵ��õĽ���    ����       1 / GLOBAL.GAME_FPS
---------------------------------------------------------------------
if DelayCall and BreatheCall and FrameCall and RenderCall then
	local NS_PREFIX = X.NSFormatString('{$NS}__')
	local function WrapIntervalCall(szIntervalName, IntervalCall)
		return function(szKey, nInterval, fnAction, oArg)
			local bUnreg
			if type(szKey) == 'function' then
				-- DelayCall(fnAction[, oArg])
				szKey, nInterval, fnAction, oArg = nil, 0, szKey, nInterval
			elseif type(szKey) == 'number' then
				-- DelayCall(nInterval, fnAction[, oArg])
				szKey, nInterval, fnAction, oArg = nil, szKey, nInterval, fnAction
			elseif type(nInterval) == 'function' then
				-- DelayCall(szKey, fnAction[, oArg])
				nInterval, fnAction, oArg = 0, nInterval, fnAction
			elseif type(nInterval) == 'boolean' then
				-- DelayCall(szKey, false)
				nInterval, bUnreg = nil, true
			elseif nInterval and type(fnAction) ~= 'function' then
				-- DelayCall(szKey, nInterval)
				fnAction = nil
			end
			if fnAction then -- reg
				--[[#DEBUG BEGIN]]
				local f = fnAction
				local function GetXpCallReturnVal(res, ...)
					if res then
						return ...
					end
					local xpErrMsg, xpTraceback = ...
					local xpErrLog = szIntervalName .. ' failed: '
						.. tostring(xpErrMsg or '') .. '\n' .. tostring(xpTraceback or '')
					Log(xpErrLog)
					FireUIEvent('CALL_LUA_ERROR', xpErrLog .. '\n')
				end
				fnAction = function(...)
					return GetXpCallReturnVal(X.XpCall(f, ...))
				end
				--[[#DEBUG END]]
				if not szKey then -- ��������
					szKey = GetTickCount()
					while IntervalCall(NS_PREFIX .. tostring(szKey)) do
						szKey = szKey + 0.1
					end
					szKey = tostring(szKey)
				end
			end
			assert(X.IsString(szKey), 'IntervalCall Key MUST be string.')
			local szNSKey = NS_PREFIX .. szKey
			local aRetVal = bUnreg
				and {IntervalCall(szNSKey, false)}
				or {IntervalCall(szNSKey, nInterval, fnAction, oArg)}
			if X.IsString(aRetVal[1]) then
				aRetVal[1] = szKey
			end
			return unpack(aRetVal)
		end
	end
	X.DelayCall   = WrapIntervalCall('DelayCall'  , DelayCall  )
	X.BreatheCall = WrapIntervalCall('BreatheCall', BreatheCall)
	X.FrameCall   = WrapIntervalCall('FrameCall'  , FrameCall  )
	X.RenderCall  = WrapIntervalCall('RenderCall' , RenderCall )
else

local _time      -- current time
local _count = 0 -- the count of onactive
local _no_active

local function LuaActive_Enable(bEnable)
	_no_active = not bEnable
end

--================================= breathe call ================================================
-- DelayCall(szKey, nInterval, fnAction, oArg)
-- DelayCall('CASTING') -- ��ȡ����ΪCASTING��DelayCall����Ϣ
-- DelayCall('CASTING', false) -- ע������ΪCASTING��DelayCall
-- DelayCall('CASTING', function() end, oArg) -- ע������ΪCASTING���ü��Ϊ��Сֵ��DelayCall
-- DelayCall('CASTING', 100, function() end, oArg) -- ע������ΪCASTING���ü��Ϊ100��DelayCall
-- DelayCall('CASTING', 200) -- ������ΪCASTING��DelayCall����ʱ���Ϊ200����
--===============================================================================================
local _tDelayCall = {} -- bc�� ��ֵ�Լ���
local _delaycalls = {} -- a mirror table to avoid error: invalid key to 'next'
local _delaycall_t   -- ѭ��ʹ��bc�� ����Ƶ��ע�ᷴע��ʱ�½���Ŀ���

local function onDelayCall()
	_time = GetTime()
	-- create mirror
	for szKey, dc in pairs(_tDelayCall) do
		_delaycalls[szKey] = dc
	end
	-- traverse dc calls
	for szKey, dc in pairs(_delaycalls) do
		if dc.nNext <= _time then
			local res, err, trace = X.XpCall(dc.fnAction, dc.oArg)
			if not res then
				X.ErrorLog(err, 'onDelayCall: ' .. szKey, trace)
			end
			_count = _count - 1
			_delaycall_t = _tDelayCall[szKey]
			_tDelayCall[szKey] = nil
			if _count == 0 then
				LuaActive_Enable(false)
			end
		end
		_delaycalls[szKey] = nil
	end
end

function X.DelayCall(szKey, nInterval, fnAction, oArg)
	local bUnreg
	if type(szKey) == 'function' then
		-- DelayCall(fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, 0, szKey, nInterval
	elseif type(szKey) == 'number' then
		-- DelayCall(nInterval, fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, szKey, nInterval, fnAction
	elseif type(nInterval) == 'function' then
		-- DelayCall(szKey, fnAction[, oArg])
		nInterval, fnAction, oArg = 0, nInterval, fnAction
	elseif type(nInterval) == 'boolean' then
		-- DelayCall(szKey, false)
		nInterval, bUnreg = nil, true
	elseif nInterval and type(fnAction) ~= 'function' then
		-- DelayCall(szKey, nInterval)
		fnAction = nil
	end
	if fnAction then -- reg
		if not szKey then -- ����bc����
			szKey = GetTickCount()
			while _tDelayCall[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		if not _tDelayCall[szKey] then
			_tDelayCall[szKey] = _delaycall_t or {}
			_delaycall_t = nil
			_count = _count + 1
			LuaActive_Enable(true)
		end
		local dc = _tDelayCall[szKey]
		dc.fnAction = fnAction
		dc.oArg = oArg
		dc.nNext = GetTime() + nInterval
		dc.nInterval = nInterval or 0
	elseif nInterval then -- modify
		local dc = _tDelayCall[szKey]
		if dc then
			dc.nInterval = nInterval
			dc.nNext = GetTime() + nInterval
		end
	elseif szKey and bUnreg then -- unreg
		if _tDelayCall[szKey] then
			_count = _count - 1
			_delaycall_t = _tDelayCall[szKey]
			_tDelayCall[szKey] = nil
			if _count == 0 then
				LuaActive_Enable(false)
			end
		end
	elseif szKey then -- get registered breathecall info
		local dc = _tDelayCall[szKey]
		if dc then
			return szKey, dc.nInterval, dc.nNext - GetTime()
		end
		return
	end
	return szKey
end

--================================= breathe call ================================================
-- BreatheCall(szKey, nInterval, fnAction, oArg)
-- BreatheCall('CASTING') -- ��ȡ����ΪCASTING��BreatheCall����Ϣ
-- BreatheCall('CASTING', false) -- ע������ΪCASTING��BreatheCall
-- BreatheCall('CASTING', function() end, oArg) -- ע������ΪCASTING���ü��Ϊ��Сֵ��BreatheCall
-- BreatheCall('CASTING', 100, function() end, oArg) -- ע������ΪCASTING���ü��Ϊ100��BreatheCall
-- BreatheCall('CASTING', 200) -- ������ΪCASTING��BreatheCall���ü����Ϊ200����
-- BreatheCall('CASTING', 200, true) -- ������ΪCASTING��BreatheCall�´ε����ӳٸ�Ϊ200����
-- ע��fnAction����0��ʾ��BreatheCall���Ƴ��Լ�
--===============================================================================================
local _tBreatheCall = {} -- bc�� ��ֵ�Լ���
local _breathecalls = {} -- a mirror table to avoid error: invalid key to 'next'
local _breathecall_t   -- ѭ��ʹ��bc�� ����Ƶ��ע�ᷴע��ʱ�½���Ŀ���

local function onBreatheCall()
	_time = GetTime()
	-- create mirror
	for szKey, bc in pairs(_tBreatheCall) do
		_breathecalls[szKey] = bc
	end
	-- traverse bc calls
	for szKey, bc in pairs(_breathecalls) do
		if bc.nNext <= _time then
			bc.nNext = _time + bc.nInterval
			local res, err, trace = X.XpCall(bc.fnAction, bc.oArg)
			if not res then
				X.ErrorLog(err, 'onBreatheCall: ' .. szKey, trace)
			elseif err == 0 then
				_count = _count - 1
				_breathecall_t = _tBreatheCall[szKey]
				_tBreatheCall[szKey] = nil
				if _count == 0 then
					LuaActive_Enable(false)
				end
			end
		end
		_breathecalls[szKey] = nil
	end
end

function X.BreatheCall(szKey, nInterval, fnAction, oArg)
	local bOnce, bUnreg
	if type(szKey) == 'function' then
		-- BreatheCall(fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, 0, szKey, nInterval
	elseif type(szKey) == 'number' then
		-- BreatheCall(nInterval, fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, szKey, nInterval, fnAction
	elseif type(nInterval) == 'function' then
		-- BreatheCall(szKey, fnAction[, oArg])
		nInterval, fnAction, oArg = 0, nInterval, fnAction
	elseif type(nInterval) == 'boolean' then
		-- BreatheCall(szKey, false)
		nInterval, bUnreg = nil, true
	elseif nInterval and type(fnAction) ~= 'function' then
		-- BreatheCall(szKey, nInterval, bOnce)
		fnAction, bOnce = nil, fnAction
	end
	if fnAction then -- reg
		if not szKey then -- ����bc����
			szKey = GetTickCount()
			while _tBreatheCall[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		if not _tBreatheCall[szKey] then
			_tBreatheCall[szKey] = _breathecall_t or {}
			_breathecall_t = nil
			_count = _count + 1
			LuaActive_Enable(true)
		end
		local bc = _tBreatheCall[szKey]
		bc.fnAction = fnAction
		bc.oArg = oArg
		bc.nNext = GetTime()
		bc.nInterval = nInterval or 0
	elseif nInterval then -- modify
		local bc = _tBreatheCall[szKey]
		if bc then
			if not bOnce then
				bc.nInterval = nInterval
			end
			bc.nNext = GetTime() + nInterval
		end
	elseif szKey and bUnreg then -- unreg
		if _tBreatheCall[szKey] then
			_count = _count - 1
			_breathecall_t = _tBreatheCall[szKey]
			_tBreatheCall[szKey] = nil
			if _count == 0 then
				LuaActive_Enable(false)
			end
		end
	elseif szKey then -- get registered breathecall info
		local bc = _tBreatheCall[szKey]
		if bc then
			return szKey, bc.nInterval, bc.nNext - GetTime()
		end
		return
	end
	return szKey
end

--================================= frame call ==================================================
-- FrameCall(szKey, nInterval, fnAction, oArg)
-- FrameCall('CASTING') -- ��ȡ����ΪCASTING��FrameCall����Ϣ
-- FrameCall('CASTING', false) -- ע������ΪCASTING��FrameCall
-- FrameCall('CASTING', function() end, oArg) -- ע������ΪCASTING���ü��Ϊ��Сֵ��FrameCall
-- FrameCall('CASTING', 10, function() end, oArg) -- ע������ΪCASTING���ü��Ϊ100֡��FrameCall
-- FrameCall('CASTING', 20) -- ������ΪCASTING��FrameCall���ü����Ϊ20֡
-- FrameCall('CASTING', 20, true) -- ������ΪCASTING��FrameCall�´ε����ӳٸ�Ϊ20֡
-- ע��fnAction����0��ʾ��FrameCall���Ƴ��Լ�
--===============================================================================================
local _tFrameCall = {} -- fc�� ��ֵ�Լ���
local _framecalls = {} -- a mirror table to avoid error: invalid key to 'next'
local _framecount = 0  -- ֡������
local _framecall_t   -- ѭ��ʹ��fc�� ����Ƶ��ע�ᷴע��ʱ�½���Ŀ���

local function onFrameCall()
	_framecount = _framecount + 1
	-- create mirror
	for szKey, fc in pairs(_tFrameCall) do
		_framecalls[szKey] = fc
	end
	-- traverse fc calls
	for szKey, fc in pairs(_framecalls) do
		if fc.nNext <= _framecount then
			fc.nNext = _framecount + fc.nInterval
			local res, err, trace = X.XpCall(fc.fnAction, fc.oArg)
			if not res then
				X.ErrorLog(err, 'onFrameCall: ' .. szKey, trace)
			elseif err == 0 then
				_count = _count - 1
				_framecall_t = _tFrameCall[szKey]
				_tFrameCall[szKey] = nil
				if _count == 0 then
					LuaActive_Enable(false)
				end
			end
		end
		_framecalls[szKey] = nil
	end
end

function X.FrameCall(szKey, nInterval, fnAction, oArg)
	local bOnce, bUnreg
	if type(szKey) == 'function' then
		-- FrameCall(fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, 0, szKey, nInterval
	elseif type(szKey) == 'number' then
		-- FrameCall(nInterval, fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, szKey, nInterval, fnAction
	elseif type(nInterval) == 'function' then
		-- FrameCall(szKey, fnAction[, oArg])
		nInterval, fnAction, oArg = 0, nInterval, fnAction
	elseif type(nInterval) == 'boolean' then
		-- FrameCall(szKey, false)
		nInterval, bUnreg = nil, true
	elseif nInterval and type(fnAction) ~= 'function' then
		-- FrameCall(szKey, nInterval, bOnce)
		fnAction, bOnce = nil, fnAction
	end
	if fnAction then -- reg
		if not szKey then -- ����fc����
			szKey = GetTickCount()
			while _tFrameCall[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		if not _tFrameCall[szKey] then
			_tFrameCall[szKey] = _framecall_t or {}
			_framecall_t = nil
			_count = _count + 1
			LuaActive_Enable(true)
		end
		local fc = _tFrameCall[szKey]
		fc.fnAction = fnAction
		fc.oArg = oArg
		fc.nNext = _framecount
		fc.nInterval = nInterval or 0
	elseif nInterval then -- modify
		local fc = _tFrameCall[szKey]
		if fc then
			if not bOnce then
				fc.nInterval = nInterval
			end
			fc.nNext = _framecount + nInterval
		end
	elseif szKey and bUnreg then -- unreg
		if _tFrameCall[szKey] then
			_count = _count - 1
			_framecall_t = _tFrameCall[szKey]
			_tFrameCall[szKey] = nil
			if _count == 0 then
				LuaActive_Enable(false)
			end
		end
	elseif szKey then -- get registered breathecall info
		local fc = _tFrameCall[szKey]
		if fc then
			return szKey, fc.nInterval, fc.nNext - _framecount
		end
		return
	end
	return szKey
end

--================================= render call ===============================================
-- RenderCall(szKey, nInterval, fnAction, oArg)
-- RenderCall('CASTING') -- ��ȡ����ΪCASTING��RenderCall����Ϣ
-- RenderCall('CASTING', false) -- ע������ΪCASTING��RenderCall
-- RenderCall('CASTING', function() end, oArg) -- ע������ΪCASTING���ü��Ϊ��Сֵ��RenderCall
-- RenderCall('CASTING', 100, function() end, oArg) -- ע������ΪCASTING���ü��Ϊ100��RenderCall
-- RenderCall('CASTING', 200) -- ������ΪCASTING��RenderCall���ü����Ϊ200����
-- RenderCall('CASTING', 200, true) -- ������ΪCASTING��RenderCall�´ε����ӳٸ�Ϊ200����
-- ע��fnAction����0��ʾ��RenderCall���Ƴ��Լ�
--=============================================================================================
local _tRenderCall = {} -- rc�� ��ֵ�Լ���
local _rendercalls = {} -- a mirror table to avoid error: invalid key to 'next'
local _rendercall_c = 0 -- the count of rendercalls
local _rendercall_t   -- ѭ��ʹ��rc�� ����Ƶ��ע�ᷴע��ʱ�½���Ŀ���
local _rendercall_ref -- ע���¼���� ����û��rc����ʱ��ע���¼�

local function onRenderCall()
	_time = GetTime()
	-- create mirror
	for szKey, rc in pairs(_tRenderCall) do
		_rendercalls[szKey] = rc
	end
	-- traverse rc calls
	for szKey, rc in pairs(_rendercalls) do
		if rc.nNext <= _time then
			rc.nNext = _time + rc.nInterval
			local res, err, trace = X.XpCall(rc.fnAction, rc.oArg)
			if not res then
				X.ErrorLog(err, 'onRenderCall: ' .. szKey, trace)
			elseif err == 0 then
				_rendercall_c = _rendercall_c - 1
				_rendercall_t = _tRenderCall[szKey]
				_tRenderCall[szKey] = nil
				if _rendercall_c == 0 then
					UnRegisterEvent('RENDER_FRAME_UPDATE', _rendercall_ref)
					_rendercall_ref = nil
				end
			end
		end
		_rendercalls[szKey] = nil
	end
end

function X.RenderCall(szKey, nInterval, fnAction, oArg)
	local bOnce, bUnreg
	if type(szKey) == 'function' then
		-- RenderCall(fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, 0, szKey, nInterval
	elseif type(szKey) == 'number' then
		-- RenderCall(nInterval, fnAction[, oArg])
		szKey, nInterval, fnAction, oArg = nil, szKey, nInterval, fnAction
	elseif type(nInterval) == 'function' then
		-- RenderCall(szKey, fnAction[, oArg])
		nInterval, fnAction, oArg = 0, nInterval, fnAction
	elseif type(nInterval) == 'boolean' then
		-- RenderCall(szKey, false)
		nInterval, bUnreg = nil, true
	elseif nInterval and type(fnAction) ~= 'function' then
		-- RenderCall(szKey, nInterval, bOnce)
		fnAction, bOnce = nil, fnAction
	end
	if fnAction then -- reg
		if not szKey then -- ����rc����
			szKey = GetTickCount()
			while _tRenderCall[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		if not _tRenderCall[szKey] then
			_tRenderCall[szKey] = _rendercall_t or {}
			_rendercall_t = nil
			_rendercall_c = _rendercall_c + 1
		end
		local rc = _tRenderCall[szKey]
		rc.fnAction = fnAction
		rc.oArg = oArg
		rc.nNext = GetTime()
		rc.nInterval = nInterval or 0
		if not _rendercall_ref then
			_rendercall_ref = X.RegisterEvent('RENDER_FRAME_UPDATE', onRenderCall)
		end
	elseif nInterval then -- modify
		local rc = _tRenderCall[szKey]
		if rc then
			if not bOnce then
				rc.nInterval = nInterval
			end
			rc.nNext = GetTime() + nInterval
		end
	elseif szKey and bUnreg then -- unreg
		if _tRenderCall[szKey] then
			_rendercall_c = _rendercall_c - 1
			_rendercall_t = _tRenderCall[szKey]
			_tRenderCall[szKey] = nil
			if _rendercall_c == 0 then
				UnRegisterEvent('RENDER_FRAME_UPDATE', _rendercall_ref)
				_rendercall_ref = nil
			end
		end
	elseif szKey then -- get registered rendercall info
		local rc = _tRenderCall[szKey]
		if rc then
			return szKey, rc.nInterval, rc.nNext - GetTime()
		end
		return
	end
	return szKey
end

--================================= onactive ===============================================
-- ʱ�Ӻ���
--==========================================================================================
local function __OnActive()
	if _no_active then
		return
	end
	onDelayCall()
	onFrameCall()
	onBreatheCall()
end

local frame = Wnd.OpenWindow(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndFrameEmpty.ini', X.NSFormatString('{$NS}#Interval'))
frame.OnFrameBreathe = __OnActive
frame:Hide()

LuaActive_Enable(false)

end

--=================================== debounce ================================================
-- Debounce(szKey, nTime, fnAction, oArg)
-- Debounce('CASTING') -- ��ȡ����ΪCASTING��Debounce����Ϣ
-- Debounce('CASTING', false) -- ע������ΪCASTING��Debounce
-- Debounce('CASTING', 100, function() end, oArg) -- ע������ΪCASTING����ʱ��Ϊ100��Debounce
-- Debounce('CASTING', 200) -- ������ΪCASTING��Debounce����ʱ���Ϊ200����
--=============================================================================================
do
local _tDebounce = {}
function X.Debounce(szKey, nTime, fnAction, oArg)
	local bUnreg
	if type(szKey) == 'number' then
		-- Debounce(nTime, fnAction[, oArg])
		szKey, nTime, fnAction, oArg = nil, szKey, nTime, fnAction
	elseif type(nTime) == 'boolean' then
		-- Debounce(szKey, false)
		nTime, bUnreg = nil, true
	end
	if fnAction then -- reg
		if not szKey then -- ����rc����
			szKey = GetTickCount()
			while _tDebounce[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		_tDebounce[szKey] = {
			nTime = nTime,
			nNext = GetTime() + nTime,
			fnAction = fnAction,
			oArg = oArg,
		}
	elseif nTime then -- modify
		if _tDebounce[szKey] then
			_tDebounce[szKey].nTime = nTime
			_tDebounce[szKey].nNext = GetTime() + nTime
		end
	elseif szKey and bUnreg then -- unreg
		_tDebounce[szKey] = nil
	elseif szKey then -- get registered rendercall info
		local d = _tDebounce[szKey]
		if d then
			return szKey, d.nTime, d.nNext - GetTime()
		end
		return
	end
	return szKey
end
X.BreatheCall(X.NSFormatString('{$NS}#Debounce'), function()
	local nTime = GetTime()
	for szKey, d in pairs(_tDebounce) do
		if nTime >= d.nNext then
			local res, err, trace = X.XpCall(d.fnAction, d.oArg)
			if not res then
				X.ErrorLog(err, 'onDebounce: ' .. szKey, trace)
			end
			_tDebounce[szKey] = nil
		end
	end
end)
end

--=================================== throttle ================================================
-- Throttle(szKey, nTime, fnAction, oArg)
-- Throttle('CASTING') -- ��ȡ����ΪCASTING��Throttle����Ϣ
-- Throttle('CASTING', false) -- ע������ΪCASTING��Throttle
-- Throttle('CASTING', 100, function() end, oArg) -- ע������ΪCASTING����ʱ��Ϊ100��Throttle
-- Throttle('CASTING', 200) -- ������ΪCASTING��Throttle����ʱ���Ϊ200����
--=============================================================================================
do
local _tThrottle = {}
function X.Throttle(szKey, nTime, fnAction, oArg)
	local bUnreg, bThrottle
	if type(szKey) == 'number' then
		-- Throttle(nTime, fnAction[, oArg])
		szKey, nTime, fnAction, oArg = nil, szKey, nTime, fnAction
	elseif type(nTime) == 'boolean' then
		-- Throttle(szKey, false)
		nTime, bUnreg = nil, true
	end
	if fnAction then -- reg
		if not szKey then -- ����rc����
			szKey = GetTickCount()
			while _tThrottle[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		if _tThrottle[szKey] and _tThrottle[szKey].nNext > GetTime() then
			bThrottle = true
		else
			_tThrottle[szKey] = {
				nTime = nTime,
				nNext = GetTime() + nTime,
				fnAction = fnAction,
				oArg = oArg,
			}
			local res, err, trace = X.XpCall(fnAction, oArg)
			if not res then
				X.ErrorLog(err, 'onThrottle: ' .. szKey, trace)
			end
		end
	elseif nTime then -- modify
		if _tThrottle[szKey] then
			_tThrottle[szKey].nTime = nTime
			_tThrottle[szKey].nNext = GetTime() + nTime
		end
	elseif szKey and bUnreg then -- unreg
		_tThrottle[szKey] = nil
	elseif szKey then -- get registered rendercall info
		local d = _tThrottle[szKey]
		if d then
			return szKey, d.nTime, d.nNext - GetTime()
		end
		return
	end
	return szKey, bThrottle
end
X.BreatheCall(X.NSFormatString('{$NS}#Throttle'), function()
	local nTime = GetTime()
	for szKey, d in pairs(_tThrottle) do
		if nTime >= d.nNext then
			_tThrottle[szKey] = nil
		end
	end
end)
end

function X.FinallyThrottle(...)
	local _, bThrottle = X.Throttle(...)
	if bThrottle then
		X.Debounce(...)
	end
end
