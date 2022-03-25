--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��������֧�ֿ�
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
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
-------------------------------------------------------------------------------------------------------------

-- (void) X.RemoteRequest(string szUrl, func fnAction)       -- ����Զ�� HTTP ����
-- szUrl        -- ��������� URL������ http:// �� https://��
-- fnAction     -- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle, szContent)]]
function X.RemoteRequest(szUrl, fnSuccess, fnError, nTimeout)
	local settings = {
		url     = szUrl,
		success = fnSuccess,
		error   = fnError,
		timeout = nTimeout,
	}
	return X.Ajax(settings)
end

do
local RRWP_FREE = {}
local RRWC_FREE = {}
local CALL_AJAX = {}
local AJAX_TAG = X.NSFormatString('{$NS}_AJAX#')
local AJAX_BRIDGE_WAIT = 10000
local AJAX_BRIDGE_PATH = X.PACKET_INFO.DATA_ROOT .. '#cache/curl/'

local function CreateWebPageFrame()
	local szRequestID, hFrame
	repeat
		szRequestID = ('%X%X'):format(GetTickCount(), math.floor(math.random() * 0xEFFF) + 0x1000)
	until not Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWP_') .. szRequestID)
	--[[#DEBUG BEGIN]]
	X.Debug('CreateWebPageFrame: ' .. szRequestID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	hFrame = Wnd.OpenWindow(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebPage.ini', X.NSFormatString('{$NS}RRWP_') .. szRequestID)
	hFrame:Hide()
	return szRequestID, hFrame
end

local Curl_Create = pcall(_G.Curl_Create, '') and _G.Curl_Create or nil
local CURL_HttpRqst = pcall(_G.CURL_HttpRqst, '') and _G.CURL_HttpRqst or nil
local CURL_HttpPost = (pcall(_G.CURL_HttpPostEx, 'TEST', '') and _G.CURL_HttpPostEx)
	or (pcall(_G.CURL_HttpPost, 'TEST', '') and _G.CURL_HttpPost)
	or nil

function X.CanAjax(driver, method)
	if driver == 'curl' then
		if not Curl_Create then
			return false, 'Curl_Create does not exist.'
		end
	elseif driver == 'webcef' then
		if method ~= 'get' then
			return false, 'Webcef only support get method, got ' .. method .. '.'
		end
	elseif driver == 'webbrowser' then
		if method ~= 'get' then
			return false, 'Webbrowser only support get method, got ' .. method .. '.'
		end
	else -- if driver == 'origin' then
		if method == 'post' then
			if not CURL_HttpPost then
				return false, 'CURL_HttpPost does not exist.'
			end
		else
			if not CURL_HttpRqst then
				return false, 'CURL_HttpRqst does not exist.'
			end
		end
	end
	return true
end

-- (void) X.Ajax(settings)       -- ����Զ�� HTTP ����
-- settings           -- ����������
-- settings.url       -- �����ַ
-- settings.data      -- ��������
-- settings.method    -- ����ʽ
-- settings.payload   -- ����ʵ������
-- settings.driver    -- ����������ʽ
-- settings.timeout   -- ����ʱʱ��
-- settings.charset   -- ������뷽ʽ
-- settings.complete  -- ������ɻص��¼������۳ɹ�ʧ�ܣ��ص����� complete -> fulfilled -> success
-- settings.fulfilled -- ����ɹ��ص��¼������������ݣ��ص����� complete -> fulfilled -> success
-- settings.success   -- ����ɹ��ص��¼���Я�����ݣ��ص����� complete -> fulfilled -> success
-- settings.error     -- ����ʧ�ܻص��¼�������Я�����ݣ��ص����� complete -> error
function X.Ajax(settings)
	assert(X.IsTable(settings) and X.IsString(settings.url))
	-- standradize settings
	local id = string.lower(X.GetUUID())
	local oncomplete, onerror = settings.complete, settings.error
	local onfulfilled, onsuccess = settings.fulfilled, settings.success
	local config = {
		id      = id,
		url     = settings.url,
		data    = X.IIf(X.IsEmpty(settings.data), nil, settings.data),
		driver  = settings.driver  or 'auto',
		method  = settings.method  or 'auto',
		payload = settings.payload or 'form',
		timeout = settings.timeout or 60000 ,
		charset = settings.charset or 'utf8',
	}
	local settings = {
		config = setmetatable({}, {
			__index = function(_, k)
				return config[k]
			end,
			__newindex = function(_, k, v) end,
			__metatable = true,
		}),
	}

	-------------------------------
	-- convert encoding
	-------------------------------
	local xurl, xdata = config.url, config.data
	if config.charset == 'utf8' then
		xurl  = X.ConvertToUTF8(xurl)
		xdata = X.ConvertToUTF8(xdata)
	end

	-------------------------------
	-- auto settings
	-------------------------------
	-- select auto method
	local method = config.method
	if method == 'auto' then
		if Curl_Create then
			method = 'get'
		elseif CURL_HttpRqst then
			method = 'get'
		elseif CURL_HttpPost then
			method = 'post'
		else
			method = 'get'
		end
	end
	-- select auto driver
	local driver = config.driver
	if driver == 'auto' then
		if Curl_Create then
			driver = 'curl'
		elseif CURL_HttpRqst and method == 'get' then
			driver = 'origin'
		elseif CURL_HttpPost and method == 'post' then
			driver = 'origin'
		elseif onsuccess then
			driver = 'webbrowser'
		else
			driver = 'webcef'
		end
	end
	if (method == 'get' or method == 'delete') and xdata then
		local data = X.EncodeQuerystring(xdata)
		if data ~= '' then
			if not wstring.find(xurl, '?') then
				xurl = xurl .. '?'
			elseif wstring.sub(xurl, -1) ~= '&' then
				xurl = xurl .. '&'
			end
			xurl = xurl .. data
		end
		xdata = nil
	end
	assert(method == 'post' or method == 'get' or method == 'put' or method == 'delete', X.NSFormatString('[{$NS}_AJAX] Unknown http request type: ') .. method)

	-------------------------------
	-- data signature
	-------------------------------
	if config.signature then
		local pos = wstring.find(xurl, '?')
		if pos then
			xurl = string.sub(xurl, 1, pos)
				.. X.EncodeQuerystring(
					X.SignPostData(
						X.DecodeQuerystring(string.sub(xurl, pos + 1)),
						config.signature
					)
				)
		end
		if xdata then
			xdata = X.SignPostData(xdata, config.signature)
		end
	end

	-------------------------------
	-- correct ansi url and data
	-------------------------------
	if config.charset == 'utf8' then
		config.url  = X.ConvertToAnsi(xurl)
		config.data = X.ConvertToAnsi(xdata)
	end

	-------------------------------
	-- finalize settings
	-------------------------------
	--[[#DEBUG BEGIN]]
	X.Debug(
		'AJAX',
		config.url .. ' - ' .. config.driver .. '/' .. config.method
			.. ' (' .. driver .. '/' .. method .. ')'
			.. ': PREPARE READY'
			.. config.data and ('\n[BODY]' .. X.EncodeQuerystring(config.data)) or '',
		X.DEBUG_LEVEL.LOG
	)
	--[[#DEBUG END]]
	local bridgewait = GetTime() + AJAX_BRIDGE_WAIT
	local bridgewaitkey = X.NSFormatString('{$NS}_AJAX_') .. id
	local fulfilled = false
	settings.callback = function(html, status)
		if fulfilled then
			--[[#DEBUG BEGIN]]
			X.Debug(
				'AJAX_DUP_CB',
				config.url .. ' - ' .. config.driver .. '/' .. config.method
					.. ' (' .. driver .. '/' .. method .. ')'
					.. ': ' .. (status or '')
					.. '\n' .. debug.traceback(),
				X.DEBUG_LEVEL.WARNING
			)
			--[[#DEBUG END]]
			return
		end
		local connected = html and status
		--[[#DEBUG BEGIN]]
		X.Debug(
			'AJAX',
			config.url .. ' - ' .. config.driver .. '/' .. config.method
				.. ' (' .. driver .. '/' .. method .. ')'
				.. ': ' .. (status or 'FAILED'),
			X.IIf(connected, X.DEBUG_LEVEL.LOG, X.DEBUG_LEVEL.WARNING)
		)
		--[[#DEBUG END]]
		local function resolve()
			fulfilled = true
			X.SafeCallWithThis(settings.config, oncomplete, html, status, not X.IsEmpty(status))
			if X.IsNumber(status) and status >= 200 and status < 400 then
				X.SafeCallWithThis(settings.config, onfulfilled)
				X.SafeCallWithThis(settings.config, onsuccess, html, status)
			else
				X.SafeCallWithThis(settings.config, onerror, html, status)
			end
			X.XpCall(settings.closebridge)
		end
		if connected then
			resolve()
		else
			X.DelayCall(bridgewaitkey, bridgewait - GetTime(), resolve)
		end
	end

	-------------------------------
	-- each driver handlers
	-------------------------------
	-- bridge
	local bridgekey = X.NSFormatString('{$NS}RRDF_TO_') .. id
	local bridgein = AJAX_BRIDGE_PATH .. id .. '.' .. ENVIRONMENT.GAME_LANG .. '.jx3dat'
	local bridgeout = AJAX_BRIDGE_PATH .. id .. '.result.' .. ENVIRONMENT.GAME_LANG .. '.jx3dat'
	local bridgetimeout = GetTime() + config.timeout
	settings.closebridge = function()
		CPath.DelFile(bridgein)
		CPath.DelFile(bridgeout)
		X.DelayCall(bridgewaitkey, false)
		X.BreatheCall(bridgekey, false)
		X.DelayCall(bridgekey, false)
		X.RegisterExit(bridgekey, false)
	end
	X.SaveLUAData(bridgein, config, { crc = false, passphrase = false })
	X.BreatheCall(bridgekey, 200, function()
		local data = X.LoadLUAData(bridgeout, { passphrase = false })
		if X.IsTable(data) then
			settings.callback(data.content, data.status)
		elseif GetTime() > bridgetimeout then
			settings.callback()
		end
	end)
	X.DelayCall(bridgekey, config.timeout, settings.closebridge)
	X.RegisterExit(bridgekey, settings.closebridge)

	local canajax, errmsg = X.CanAjax(driver, method)
	if not canajax then
		X.Debug(X.NSFormatString('{$NS}_AJAX'), errmsg, X.DEBUG_LEVEL.WARNING)
		settings.callback()
		return
	end

	if driver == 'curl' then
		local curl = Curl_Create(xurl)
		if method == 'post' then
			curl:SetMethod('POST')
			local data = xdata
			if config.payload == 'json' then
				data = X.EncodeJSON(data)
				curl:AddHeader('Content-Type: application/json')
			else -- if config.payload == 'form' then
				data = X.EncodeQuerystring(data)
				curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
			end
			curl:AddPostRawData(data)
		elseif method == 'get' then
			curl:AddHeader('Content-Type: application/x-www-form-urlencoded')
		end
		-- curl:OnComplete(function(html, code, success)
		-- 	if config.charset == 'utf8' then
		-- 		html = UTF8ToAnsi(html)
		-- 	end
		-- 	settings.callback(html, code)
		-- end)
		curl:OnSuccess(function(html, code)
			if config.charset == 'utf8' then
				html = UTF8ToAnsi(html)
			end
			settings.callback(html, code)
		end)
		curl:OnError(function(html, code, connected)
			if connected then
				if config.charset == 'utf8' then
					html = UTF8ToAnsi(html)
				end
			else
				html, code = nil, nil
			end
			settings.callback(html, code)
		end)
		curl:SetConnTimeout(config.timeout)
		curl:Perform()
	elseif driver == 'webcef' then
		local RequestID, hFrame
		local nFreeWebPages = #RRWC_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWC_FREE[nFreeWebPages]
			hFrame = Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWC_') .. RequestID)
			table.remove(RRWC_FREE)
		end
		-- create page
		if not hFrame then
			RequestID = ('%X_%X'):format(GetTickCount(), math.floor(math.random() * 65536))
			hFrame = Wnd.OpenWindow(X.PACKET_INFO.UICOMPONENT_ROOT .. 'WndWebCef.ini', X.NSFormatString('{$NS}RRWC_') .. RequestID)
			hFrame:Hide()
		end
		local wWebCef = hFrame:Lookup('WndWebCef')

		-- bind callback function
		wWebCef.OnWebLoadEnd = function()
			-- local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
			local szContent = ''
			--[[#DEBUG BEGIN]]
			-- X.Debug(X.NSFormatString('{$NS}RRWC::OnDocumentComplete'), string.format('%s - %s', szTitle, szUrl), X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- ע����ʱ����ʱ��
			X.DelayCall(X.NSFormatString('{$NS}RRWC_TO_') .. RequestID, false)
			-- �ص�����
			settings.callback(szContent, 200)
			-- ��崻����⣬���� FREE �أ�ֱ�����پ��
			-- table.insert(RRWC_FREE, RequestID)
			Wnd.CloseWindow(this:GetRoot())
		end

		-- do with this remote request
		--[[#DEBUG BEGIN]]
		X.Debug(X.NSFormatString('{$NS}RRWC'), config.url, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		-- register request timeout clock
		if config.timeout > 0 then
			X.DelayCall(X.NSFormatString('{$NS}RRWC_TO_') .. RequestID, config.timeout, function()
				--[[#DEBUG BEGIN]]
				X.Debug(X.NSFormatString('{$NS}RRWC::Timeout'), config.url, X.DEBUG_LEVEL.WARNING) -- log
				--[[#DEBUG END]]
				-- request timeout, call timeout function.
				settings.callback()
				-- ��崻����⣬���� FREE �أ�ֱ�����پ��
				-- table.insert(RRWC_FREE, RequestID)
				Wnd.CloseWindow(hFrame)
			end)
		end

		-- start chrome navigate
		wWebCef:Navigate(xurl)
	elseif driver == 'webbrowser' then
		local RequestID, hFrame
		local function OnWebPageFrameCreate()
			local wWebPage = hFrame:Lookup('WndWebPage')
			-- bind callback function
			wWebPage.OnDocumentComplete = function()
				local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
				if szUrl ~= szTitle or szContent ~= '' then
					--[[#DEBUG BEGIN]]
					X.Debug(X.NSFormatString('{$NS}RRWP::OnDocumentComplete'), string.format('%s - %s', szTitle, szUrl), X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					-- ע����ʱ����ʱ��
					X.DelayCall(X.NSFormatString('{$NS}RRWP_TO_') .. RequestID, false)
					-- �ص�����
					settings.callback(szContent, 200)
					-- ��崻����⣬���� FREE �أ�ֱ�����پ��
					table.insert(RRWP_FREE, RequestID)
					-- Wnd.CloseWindow(this:GetRoot())
				end
			end
			-- do with this remote request
			--[[#DEBUG BEGIN]]
			X.Debug(X.NSFormatString('{$NS}RRWP'), config.url, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			-- register request timeout clock
			if config.timeout > 0 then
				X.DelayCall(X.NSFormatString('{$NS}RRWP_TO_') .. RequestID, config.timeout, function()
					--[[#DEBUG BEGIN]]
					X.Debug(X.NSFormatString('{$NS}RRWP::Timeout'), config.url, X.DEBUG_LEVEL.WARNING) -- log
					--[[#DEBUG END]]
					settings.callback()
					-- ��崻����⣬���� FREE �أ�ֱ�����پ��
					table.insert(RRWP_FREE, RequestID)
					-- Wnd.CloseWindow(hFrame)
				end)
			end
			-- start ie navigate
			wWebPage:Navigate(xurl)
		end
		local nFreeWebPages = #RRWP_FREE
		if nFreeWebPages > 0 then
			RequestID = RRWP_FREE[nFreeWebPages]
			hFrame = Station.Lookup(X.NSFormatString('Lowest/{$NS}RRWP_') .. RequestID)
			table.remove(RRWP_FREE)
		end
		-- create page
		if hFrame then
			OnWebPageFrameCreate()
		else
			local szKey = X.NSFormatString('{$NS}_AJAX#RRWP#') .. config.id
			X.BreatheCall(szKey, function()
				if X.IsFighting() or not Cursor.IsVisible() then
					return
				end
				X.BreatheCall(szKey, false)
				RequestID, hFrame = CreateWebPageFrame()
				OnWebPageFrameCreate()
			end)
		end
	else -- if driver == 'origin' then
		local szKey = GetTickCount() * 100
		while CALL_AJAX['__addon_' .. AJAX_TAG .. szKey] do
			szKey = szKey + 1
		end
		szKey = AJAX_TAG .. szKey
		local ssl = xurl:sub(1, 6) == 'https:'
		if method == 'post' then
			local data = xdata
			if X.IsTable(xdata) then
				data = {}
				for _, kvp in ipairs(X.SplitString(X.EncodeQuerystring(xdata), '&', true)) do
					kvp = X.SplitString(kvp, '=')
					local k, v = kvp[1], kvp[2]
					data[X.DecodeURIComponent(k)] = X.DecodeURIComponent(v)
				end
			end
			CURL_HttpPost(szKey, xurl, data or '', ssl, config.timeout)
		else
			CURL_HttpRqst(szKey, xurl, ssl, config.timeout)
		end
		local info = {
			settings = settings,
			keys = { szKey, '__addon_' .. szKey },
		}
		for _, k in ipairs(info.keys) do
			CALL_AJAX[k] = info
		end
	end
end

local function OnCurlRequestResult()
	local szKey        = arg0
	local bSuccess     = arg1
	local html         = arg2
	local dwBufferSize = arg3
	local info = CALL_AJAX[szKey]
	if not info then
		return
	end
	local settings = info.settings
	if dwBufferSize == 0 then
		settings.callback()
	else
		local status = bSuccess and 200 or 500
		if settings.config.charset == 'utf8' then
			html = UTF8ToAnsi(html)
		end
		settings.callback(html, status)
	end
	for _, k in ipairs(info.keys) do
		CALL_AJAX[k] = nil
	end
end
X.RegisterEvent('CURL_REQUEST_RESULT', 'AJAX', OnCurlRequestResult)
end

function X.DownloadFile(szPath, resolve, reject)
	local downloader = X.UI.GetTempElement(X.NSFormatString('Image.{$NS}#DownloadFile-') .. GetStringCRC(szPath) .. '#' .. GetTime())
	downloader.FromTextureFile = function(_, szPath)
		X.Call(resolve, szPath)
	end
	downloader:FromRemoteFile(szPath, false, function(image, szURL, szAbsPath, bSuccess)
		if not bSuccess then
			X.Call(reject)
		end
		downloader:GetParent():RemoveItem(downloader)
	end)
end

-- �������ݽӿڰ�ȫ�ȶ��Ķ������ Ajax ����
-- ע��ýӿ���ֻ�������ϴ� ��Ϊ��֧�ַ��ؽ������
function X.EnsureAjax(options)
	local key = GetStringCRC(X.EncodeLUAData({options.url, options.data}))
	local configs, i, dc = {{'curl', 'post'}, {'origin', 'post'}, {'origin', 'get'}, {'webcef', 'get'}}, 1, nil
	-- �Ƴ��޷����ʵĵ��÷�ʽ�������ٱ���һ�����ڳ����Ž�ͨ��
	for i, config in X.ipairs_r(configs) do
		if i >= 1 and not X.CanAjax(config[1], config[2]) then
			table.remove(configs, i)
		end
	end
	--[[#DEBUG BEGIN]]
	X.Debug('Ensure ajax ' .. key .. ' preparing: ' .. options.url, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	local function TryUploadWithNextDriver()
		local config = configs[i]
		if not config then
			X.SafeCall(options.error)
			return 0
		end
		local driver, method = unpack(config)
		--[[#DEBUG BEGIN]]
		X.Debug('Ensure ajax ' .. key .. ' try mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		dc, i = X.DelayCall(30000, TryUploadWithNextDriver), i + 1 -- �����ȷ��𱣻���������Ϊ������ܻ�����ʧ�ܴ���gc
		local opt = {
			driver = driver,
			method = method,
			url = options.url,
			data = options.data,
			fulfilled = function(...)
				--[[#DEBUG BEGIN]]
				X.Debug('Ensure ajax ' .. key .. ' succeed with mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				X.DelayCall(dc, false)
				X.SafeCall(options.fulfilled, ...)
			end,
			error = function()
				--[[#DEBUG BEGIN]]
				X.Debug('Ensure ajax ' .. key .. ' failed with mode ' .. driver .. '/' .. method, X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				X.DelayCall(dc, false)
				TryUploadWithNextDriver()
			end,
		}
		X.Ajax(opt)
	end
	TryUploadWithNextDriver()
end

do local function StringSorter(p1, p2)
	local k1, k2, c1, c2 = tostring(p1.k), tostring(p2.k)
	for i = 1, math.max(#k1, #k2) do
		c1, c2 = string.byte(k1, i, i), string.byte(k2, i, i)
		if not c1 then
			if not c2 then
				return false
			end
			return true
		end
		if not c2 then
			return false
		end
		if c1 ~= c2 then
			return c1 < c2
		end
	end
end
function X.GetPostDataCRC(tData, szPassphrase)
	local a, r = {}, {}
	for k, v in pairs(tData) do
		table.insert(a, { k = k, v = v })
	end
	table.sort(a, StringSorter)
	if szPassphrase then
		table.insert(r, szPassphrase)
	end
	for _, v in ipairs(a) do
		if v.k ~= '_' and v.k ~= '_c' then
			table.insert(r, tostring(v.k) .. ':' .. tostring(v.v))
		end
	end
	return GetStringCRC(table.concat(r, ';'))
end
end

function X.SignPostData(tData, szPassphrase)
	tData._t = GetCurrentTime()
	tData._c = X.GetPostDataCRC(tData, szPassphrase)
	return tData
end
