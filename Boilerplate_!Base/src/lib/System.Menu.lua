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

do

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
			fnAction = X.TogglePanel,
			rgb = X.PACKET_INFO.MENU_COLOR,
			bCheck = true,
			bChecked = X.IsPanelVisible(),

			szIcon = X.PACKET_INFO.LOGO_UITEX,
			nFrame = X.PACKET_INFO.LOGO_MENU_FRAME,
			nMouseOverFrame = X.PACKET_INFO.LOGO_MENU_HOVER_FRAME,
			szLayer = 'ICON_RIGHT',
			fnClickIcon = X.TogglePanel,
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

do
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
end

do
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
end

do
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
end
end

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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
