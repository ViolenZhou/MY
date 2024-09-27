--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤ϵͳ�˵�
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Menu')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local function menuSorter(m1, m2)
	return #m1 < #m2
end

local function RegisterMenu(aList, tKey, arg0, arg1)
	local szKey, oMenu
	if X.IsString(arg0) then
		szKey = arg0
		if X.IsTable(arg1) or X.IsFunction(arg1) then
			oMenu = arg1
		end
	elseif X.IsTable(arg0) or X.IsFunction(arg0) then
		oMenu = arg0
	end
	if szKey then
		for i, v in X.ipairs_r(aList) do
			if v.szKey == szKey then
				table.remove(aList, i)
			end
		end
		tKey[szKey] = nil
	end
	if oMenu then
		if not szKey then
			szKey = GetTickCount()
			while tKey[tostring(szKey)] do
				szKey = szKey + 0.1
			end
			szKey = tostring(szKey)
		end
		tKey[szKey] = true
		table.insert(aList, { szKey = szKey, oMenu = oMenu })
	end
	return szKey
end

local function GenerateMenu(aList, bMainMenu, dwTarType, dwTarID)
	if not X.AssertVersion('', '', '*') then
		return
	end
	local menu = {}
	if bMainMenu then
		menu = {
			szOption = X.PACKET_INFO.NAME,
			fnAction = X.Panel.Toggle,
			rgb = X.PACKET_INFO.MENU_COLOR,
			bCheck = true,
			bChecked = X.Panel.IsVisible(),

			szIcon = X.PACKET_INFO.LOGO_IMAGE,
			nFrame = X.PACKET_INFO.LOGO_MENU_FRAME,
			nMouseOverFrame = X.PACKET_INFO.LOGO_MENU_HOVER_FRAME,
			szLayer = 'ICON_RIGHT',
			fnClickIcon = X.Panel.Toggle,
		}
	end
	for _, p in ipairs(aList) do
		local m = p.oMenu
		if X.IsFunction(m) then
			m = m(dwTarType, dwTarID)
		end
		if not m or m.szOption then
			m = {m}
		end
		for _, v in ipairs(m) do
			if not v.rgb and not bMainMenu then
				v.rgb = X.PACKET_INFO.MENU_COLOR
			end
			table.insert(menu, v)
		end
	end
	table.sort(menu, menuSorter)
	return bMainMenu and {menu} or menu
end

--------------------------------------------------------------------------------
-- ���ͷ��˵�
--------------------------------------------------------------------------------
local PLAYER_MENU, PLAYER_MENU_HASH = {}, {} -- ���ͷ��˵�
-- ע�����ͷ��˵�
-- ע��
-- (void) X.RegisterPlayerAddonMenu(Menu)
-- (void) X.RegisterPlayerAddonMenu(szName, tMenu)
-- (void) X.RegisterPlayerAddonMenu(szName, fnMenu)
-- ע��
-- (void) X.RegisterPlayerAddonMenu(szName, false)
function X.RegisterPlayerAddonMenu(arg0, arg1)
	return RegisterMenu(PLAYER_MENU, PLAYER_MENU_HASH, arg0, arg1)
end
function X.GetPlayerAddonMenu()
	return GenerateMenu(PLAYER_MENU, true)
end
Player_AppendAddonMenu({X.GetPlayerAddonMenu})

--------------------------------------------------------------------------------
-- �������˵�
--------------------------------------------------------------------------------
local TRACE_MENU, TRACE_MENU_HASH = {}, {} -- �������˵�
-- ע�Ṥ�����˵�
-- ע��
-- (void) X.RegisterTraceButtonAddonMenu(Menu)
-- (void) X.RegisterTraceButtonAddonMenu(szName, tMenu)
-- (void) X.RegisterTraceButtonAddonMenu(szName, fnMenu)
-- ע��
-- (void) X.RegisterTraceButtonAddonMenu(szName, false)
function X.RegisterTraceButtonAddonMenu(arg0, arg1)
	return RegisterMenu(TRACE_MENU, TRACE_MENU_HASH, arg0, arg1)
end
function X.GetTraceButtonAddonMenu()
	return GenerateMenu(TRACE_MENU, true)
end
TraceButton_AppendAddonMenu({X.GetTraceButtonAddonMenu})

--------------------------------------------------------------------------------
-- Ŀ��ͷ��˵�
--------------------------------------------------------------------------------
local TARGET_MENU, TARGET_MENU_HASH = {}, {} -- Ŀ��ͷ��˵�
-- ע��Ŀ��ͷ��˵�
-- ע��
-- (void) X.RegisterTargetAddonMenu(Menu)
-- (void) X.RegisterTargetAddonMenu(szName, tMenu)
-- (void) X.RegisterTargetAddonMenu(szName, fnMenu)
-- ע��
-- (void) X.RegisterTargetAddonMenu(szName, false)
function X.RegisterTargetAddonMenu(arg0, arg1)
	return RegisterMenu(TARGET_MENU, TARGET_MENU_HASH, arg0, arg1)
end
local function GetTargetAddonMenu(dwTarID, dwTarType)
	return GenerateMenu(TARGET_MENU, false, dwTarType, dwTarID)
end
Target_AppendAddonMenu({GetTargetAddonMenu})

--------------------------------------------------------------------------------
-- ������������ֲ˵�
--------------------------------------------------------------------------------
local CHAT_PLAYER_MENU, CHAT_PLAYER_MENU_HASH = {}, {} -- ���������ֲ˵�
-- ע��������������ֲ˵�
-- ע��
-- (void) X.RegisterChatPlayerAddonMenu(Menu)
-- (void) X.RegisterChatPlayerAddonMenu(szName, tMenu)
-- (void) X.RegisterChatPlayerAddonMenu(szName, fnMenu)
-- ע��
-- (void) X.RegisterChatPlayerAddonMenu(szName, false)
function X.RegisterChatPlayerAddonMenu(arg0, arg1)
	return RegisterMenu(CHAT_PLAYER_MENU, CHAT_PLAYER_MENU_HASH, arg0, arg1)
end
function X.GetChatPlayerAddonMenu(szName)
	return GenerateMenu(CHAT_PLAYER_MENU, false, szName)
end
Chat_AppendPlayerMenu({X.GetChatPlayerAddonMenu})

--------------------------------------------------------------------------------
-- ���ͷ��͹������˵�
--------------------------------------------------------------------------------
-- ע�����ͷ��͹������˵�
-- ע��
-- (void) X.RegisterAddonMenu(Menu)
-- (void) X.RegisterAddonMenu(szName, tMenu)
-- (void) X.RegisterAddonMenu(szName, fnMenu)
-- ע��
-- (void) X.RegisterAddonMenu(szName, false)
function X.RegisterAddonMenu(...)
	X.RegisterPlayerAddonMenu(...)
	X.RegisterTraceButtonAddonMenu(...)
end

--------------------------------------------------------------------------------
-- �����Ҽ��˵�
--------------------------------------------------------------------------------

-- ��ȡָ�����ֵ��Ҽ��˵�
function X.InsertPlayerContextMenu(t, szName, dwID, szGlobalID)
	-- ���ݿ��ȡ dwID, szGlobalID ��ȫ��Ϣ
	if (not dwID or not szGlobalID) and _G.MY_Farbnamen and _G.MY_Farbnamen.Get then
		local tInfo = _G.MY_Farbnamen.Get(szName)
		if tInfo then
			if not dwID then
				dwID = tonumber(tInfo.dwID)
			end
			if not szGlobalID and X.IsGlobalID(tInfo.szGlobalID) then
				szGlobalID = tInfo.szGlobalID
			end
		end
	end
	-- �������
	local szOriginName, szServerName = X.DisassemblePlayerGlobalName(szName, true)
	-- ����
	table.insert(t, {
		szOption = _L['Copy to chat input'],
		fnAction = function()
			X.SendChat(X.GetClientPlayer().szName, '[' .. szName .. ']')
		end,
	})
	-- ���� ���� ������� ����
	X.Call(InsertPlayerCommonMenu, t, dwID, szName)
	-- ���
	if szName and InsertInviteTeamMenu then
		InsertInviteTeamMenu(t, szName)
	end
	-- �鿴װ��
	if (dwID and X.GetClientPlayerID() ~= dwID) or (szGlobalID and szGlobalID ~= X.GetClientPlayerGlobalID()) then
		table.insert(t, {
			szOption = _L['View equipment'],
			fnAction = function()
				if szServerName and X.IsGlobalID(szGlobalID) then
					local dwServerID = X.GetServerIDByName(szServerName)
					X.ViewOtherPlayerByGlobalID(dwServerID, szGlobalID)
				elseif dwID then
					X.ViewOtherPlayerByID(dwID)
				end
			end,
		})
	end
	-- �鿴���������Ϣ
	table.insert(t, {
		szOption = g_tStrings.LOOKUP_CORPS,
		-- fnDisable = function() return not X.GetPlayer(dwID) end,
		fnAction = function()
			X.UI.CloseFrame('ArenaCorpsPanel')
			OpenArenaCorpsPanel(true, dwID)
		end,
	})
	-- �����ɫ��ע
	if _G.MY_PlayerRemark and _G.MY_PlayerRemark.OpenEditPanel then
		table.insert(t, {
			szOption = _L['Edit in MY_PlayerRemark'],
			fnAction = function()
				_G.MY_PlayerRemark.OpenEditPanel(szServerName, dwID, szOriginName, szGlobalID)
			end,
		})
	end
	-- ��Ѩ -- ���
	if dwID and InsertTargetMenu then
		local tx = {}
		InsertTargetMenu(tx, TARGET.PLAYER, dwID, szName)
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.LOOKUP_INFO or v.szOption == g_tStrings.STR_LOOKUP_MORE then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then -- �鿴��Ѩ
						table.insert(t, vv)
						break
					end
				end
				break
			end
		end
		for _, v in ipairs(tx) do
			if v.szOption == g_tStrings.STR_ARENA_INVITE_TARGET -- ������������
			or v.szOption == g_tStrings.LOOKUP_INFO             -- �鿴������Ϣ
			or v.szOption == g_tStrings.STR_LOOKUP_MORE         -- �鿴����
			or v.szOption == g_tStrings.CHANNEL_MENTOR          -- ʦͽ
			or v.szOption == g_tStrings.STR_ADD_SHANG           -- ��������
			or v.szOption == g_tStrings.STR_MARK_TARGET         -- ���Ŀ��
			or v.szOption == g_tStrings.STR_MAKE_TRADDING       -- ����
			or v.szOption == g_tStrings.REPORT_RABOT            -- �ٱ����
			then
				table.insert(t, v)
			end
		end
	end

	if IsCtrlKeyDown() and X.IsDebugging() then
		table.insert(t, {
			szOption = _L['Copy debug information'],
			fnAction = function()
				local tDebugInfo
				if _G.MY_Farbnamen and _G.MY_Farbnamen.Get then
					tDebugInfo = _G.MY_Farbnamen.Get(szName)
				else
					tDebugInfo = {
						szName = szName,
						dwID = dwID,
						szGlobalID = szGlobalID,
					}
				end
				X.UI.OpenTextEditor(X.EncodeLUAData(tDebugInfo, '\t'))
			end,
		})
	end

	return t
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
