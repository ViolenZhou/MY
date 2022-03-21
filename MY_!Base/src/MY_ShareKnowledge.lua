--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �������ݷ���ģ��
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
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_!Base'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '*') then
	return
end
--------------------------------------------------------------------------

---------------
-- ϵͳ�¼�
---------------
do
local FREQUENCY_LIMIT = 10000
local NEXT_AWAKE_TIME = 0
local CURRENT_EVENT = {}

MY_RSS.RegisterAdapter('share-event', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, p in ipairs(data) do
			if X.IsString(p[1]) then
				local r = { name = p[1], argv = {}, argc = p[3] }
				if X.IsTable(p[2]) then
					for key, value in pairs(p[2]) do
						if X.IsNumber(key) and key > 0 then
							r.argv['arg' .. (key - 1)] = value
						end
					end
				end
				table.insert(t, r)
			end
		end
	end
	return t
end)

X.RegisterEvent('MY_RSS_UPDATE', function()
	for k, _ in pairs(CURRENT_EVENT) do
		X.RegisterEvent(k, 'MY_ShareKnowledge__Event', false)
	end
	CURRENT_EVENT = {}
	local rss = MY_RSS.Get('share-event')
	if not rss then
		return
	end
	for _, p in ipairs(rss) do
		X.RegisterEvent(p.name, 'MY_ShareKnowledge__Event', function()
			if not MY_Serendipity.bEnable then
				return
			end
			if GetTime() < NEXT_AWAKE_TIME then
				return
			end
			for key, value in pairs(p.argv) do
				if _G[key] ~= value then
					return
				end
			end
			local argv = {}
			for i = 0, p.argc - 1 do
				argv[i + 1] = _G['arg' .. i]
			end
			local szArgs = X.JsonEncode(argv)
			X.EnsureAjax({
				url = 'https://push.j3cx.com/api/share-event?'
					.. X.EncodePostData(X.UrlEncode(X.SignPostData({
						l = AnsiToUTF8(GLOBAL.GAME_LANG),
						L = AnsiToUTF8(GLOBAL.GAME_EDITION),
						region = AnsiToUTF8(X.GetRealServer(1)), -- Region
						server = AnsiToUTF8(X.GetRealServer(2)), -- Server
						event = AnsiToUTF8(p.name), -- Event
						args = AnsiToUTF8(szArgs), -- Arguments
						time = GetCurrentTime(), -- Time
					}, X.SECRET.SHARE_EVENT)))
				})
			NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
		end)
		CURRENT_EVENT[p.name] = true
	end
end)
end

---------------
-- ����ץȡ
---------------
do
local FREQUENCY_LIMIT = 10000
local NEXT_AWAKE_TIME = 0
local CACHE = {}

MY_RSS.RegisterAdapter('share-ui', function(data)
	local paths = {}
	if X.IsTable(data) then
		for _, v in ipairs(data) do
			if X.IsString(v) then
				table.insert(paths, { v })
			elseif X.IsTable(v) and X.IsString(v[1]) and X.IsString(v[2]) then
				table.insert(paths, { v[1], v[2] })
			end
		end
	end
	local t = {}
	for _, path in ipairs(paths) do
		table.insert(t, {
			key = X.JsonEncode(path),
			path = path,
		})
	end
	return t
end)

local function SerializeElement(el)
	local info = { type = el:GetType(), name = el:GetName() }
	if el:GetBaseType() == 'Wnd' then
		local h = el:Lookup('', '')
		if h then
			info.handle = SerializeElement(h)
		end
		local c = el:GetFirstChild()
		if c then
			info.children = {}
		end
		while c do
			table.insert(c.children, SerializeElement(c))
			c = c:GetNext()
		end
	end
	if info.type == 'Text' then
		info.text = el:GetText()
	elseif info.type == 'Image' or info.type == 'Animate' then
		local image, frame = el:GetImagePath()
		info.image = image
		info.frame = frame
	end
	return info
end

X.BreatheCall('MY_ShareKnowledge__UI', 1000, function()
	if not MY_Serendipity.bEnable then
		return
	end
	local rss = MY_RSS.Get('share-ui')
	if not rss then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	for _, v in ipairs(rss) do
		local el = Station.Lookup(unpack(v.path))
		if el then
			local szContent = X.JsonEncode(SerializeElement(el))
			if CACHE[v.key] ~= szContent then
				X.EnsureAjax({
					url = 'https://push.j3cx.com/api/share-ui?'
						.. X.EncodePostData(X.UrlEncode(X.SignPostData({
							l = AnsiToUTF8(GLOBAL.GAME_LANG),
							L = AnsiToUTF8(GLOBAL.GAME_EDITION),
							region = AnsiToUTF8(X.GetRealServer(1)), -- Region
							server = AnsiToUTF8(X.GetRealServer(2)), -- Server
							path = AnsiToUTF8(v.path[1]), -- Path
							subpath = v.path[2] and AnsiToUTF8(v.path[2]), -- Subpath
							content = AnsiToUTF8(szContent), -- Content
							time = GetCurrentTime(), -- Time
						}, X.SECRET.SHARE_UI)))
					})
				CACHE[v.key] = szContent
				break
			end
		end
	end
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end

---------------
-- NPC �Ի���
---------------
do
local FREQUENCY_LIMIT = 1000
local NEXT_AWAKE_TIME = 0

MY_RSS.RegisterAdapter('share-npc-chat', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, k in ipairs(data) do
			t[k] = true
		end
	end
	return t
end)

X.RegisterEvent('OPEN_WINDOW', 'MY_ShareKnowledge__Npc', function()
	if not MY_Serendipity.bEnable then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwTargetID = arg3
	local npc = GetNpc(dwTargetID)
	if not npc then
		return
	end
	local rss = MY_RSS.Get('share-npc-chat')
	if not rss or not rss[npc.dwTemplateID] then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	local szContent = arg1
	local map = X.GetMapInfo(me.GetMapID())
	local szDelayID
	local function fnAction(line)
		X.EnsureAjax({
			url = 'https://push.j3cx.com/api/share-npc-chat?'
				.. X.EncodePostData(X.UrlEncode(X.SignPostData({
					l = AnsiToUTF8(GLOBAL.GAME_LANG),
					L = AnsiToUTF8(GLOBAL.GAME_EDITION),
					r = AnsiToUTF8(X.GetRealServer(1)), -- Region
					s = AnsiToUTF8(X.GetRealServer(2)), -- Server
					c = AnsiToUTF8(szContent), -- Content
					t = GetCurrentTime(), -- Time
					cn = line and AnsiToUTF8(line.szCenterName) or '', -- Center Name
					ci = line and line.dwCenterID or -1, -- Center ID
					li = line and line.nLineIndex or -1, -- Line Index
					mi = map and map.dwID, -- Map ID
					mn = map and AnsiToUTF8(map.szName), -- Map Name
					nt = npc.dwTemplateID, -- NPC Template ID
					nn = X.GetObjectName(npc), -- NPC Name
				}, X.SECRET.SHARE_NPC_CHAT)))
			})
		X.DelayCall(szDelayID, false)
	end
	szDelayID = X.DelayCall(5000, fnAction)
	X.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex }, fnAction)
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end

---------------
-- ϵͳ��Ϣ
---------------
do
local FREQUENCY_LIMIT = 0
local NEXT_AWAKE_TIME = 0

MY_RSS.RegisterAdapter('share-sysmsg', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, szPattern in ipairs(data) do
			if X.IsString(szPattern) then
				table.insert(t, szPattern)
			end
		end
	end
	return t
end)

X.RegisterMsgMonitor('MSG_SYS', 'MY_ShareKnowledge__Sysmsg', function(szChannel, szMsg, nFont, bRich, r, g, b)
	if not MY_Serendipity.bEnable then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local rss = MY_RSS.Get('share-sysmsg')
	if not rss then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	-- ����������
	if IsRemotePlayer(me.dwID) then
		return
	end
	-- ȷ������ʵϵͳ��Ϣ
	if X.ContainsEchoMsgHeader(szMsg) then
		return
	end
	-- OutputMessage('MSG_SYS', "<image>path=\"UI/Image/Minimap/Minimap.UITex\" frame=184</image><text>text=\"��һֻ���ܶܡ���ʿ����Ϊ�˴�����������䴥��������ѩɽ���𡿣����ǣ��������У�ƫ����֢����ѩ�����ˣ�ȴ�������Ե��\" font=10 r=255 g=255 b=0 </text><text>text=\"\\\n\"</text>", true)
	-- �����ֹս����ʿ��Ե��ǳ�������������������硿����ǧ����Ե�������������������������������
	-- ��ϲ��ʿ��������25��Ӣ�ۻ�ս�����л��ϡ�е���[ҹ��������]��
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	for _, szPattern in ipairs(rss) do
		if string.find(szMsg, szPattern) then
			X.EnsureAjax({
				url = 'https://push.j3cx.com/api/share-sysmsg?'
					.. X.EncodePostData(X.UrlEncode(X.SignPostData({
						l = AnsiToUTF8(GLOBAL.GAME_LANG),
						L = AnsiToUTF8(GLOBAL.GAME_EDITION),
						region = AnsiToUTF8(X.GetRealServer(1)), -- Region
						server = AnsiToUTF8(X.GetRealServer(2)), -- Server
						content = AnsiToUTF8(szMsg), -- Content
						time = GetCurrentTime(), -- Time
					}, X.SECRET.SHARE_SYSMSG)))
				})
			break
		end
	end
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end
