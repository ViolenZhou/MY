--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Target')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Ŀ���ȡ��ؽӿ�
--------------------------------------------------------------------------------

-- ȡ��ָ��Ŀ���Ŀ�����ͺ�ID
---@param kTar userdata @ָ����Ŀ��
---@return number, number @Ŀ���Ŀ������, Ŀ���Ŀ��ID
function X.GetTargetTarget(kTar)
	if kTar and kTar.GetTarget then
		return kTar.GetTarget()
	end
	return TARGET.NO_TARGET, 0
end

X.RegisterRestriction('X.SET_TARGET', { ['*'] = true, intl = false })

-- ���� dwType ���ͺ� dwID ����Ŀ��
---@param dwType number @Ŀ������
---@param dwID number @Ŀ��ID
---@return boolean @�Ƿ�ɹ�����
function X.SetClientPlayerTarget(dwType, dwID)
	if dwType == TARGET.PLAYER then
		if X.IsInShieldedMap() and not X.IsParty(dwID) and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetClientPlayerTarget', 'Set target to player is forbiden in current map.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.NPC then
		local npc = X.GetNpc(dwID)
		if npc and not npc.IsSelectable() and X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetClientPlayerTarget', 'Set target to unselectable npc.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	elseif dwType == TARGET.DOODAD then
		if X.IsRestricted('X.SET_TARGET') then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('SetClientPlayerTarget', 'Set target to doodad.', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return false
		end
	end
	SetTarget(dwType, dwID)
	return true
end

do
local CALLBACK_LIST
-- ��ȡ����ǰ��ɫ��ִ�к���
-- @param {function} callback �ص�����
function X.WithClientPlayer(callback)
	local me = X.GetClientPlayer()
	if me then
		X.SafeCall(callback, me)
	elseif CALLBACK_LIST then
		table.insert(CALLBACK_LIST, callback)
	else
		CALLBACK_LIST = {callback}
		X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), function()
			local me = X.GetClientPlayer()
			if me then
				for _, callback in ipairs(CALLBACK_LIST) do
					X.SafeCall(callback, me)
				end
				CALLBACK_LIST = nil
				X.BreatheCall(X.NSFormatString('{$NS}.WithClientPlayer'), false)
			end
		end)
	end
end
end

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

	if IsCtrlKeyDown() and X.IsDebugClient(true) then
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
