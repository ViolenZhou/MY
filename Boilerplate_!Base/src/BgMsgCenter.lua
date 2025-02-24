--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ����ͨѶ����������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/BgMsgCenter')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/BgMsgCenter/')
--------------------------------------------------------------------------------

local D = {}

function D.GetReplyChannel(nChannel, szTalkerName)
	if nChannel == PLAYER_TALK_CHANNEL.WHISPER then
		return szTalkerName
	end
	return nChannel
end

function D.NeedReply(aRequestID, aRefreshID, dwID, szGlobalID, bNotChange)
	if not aRequestID then
		return true
	end
	for _, v in ipairs(aRequestID) do
		if v == dwID or v == szGlobalID then
			return true
		end
	end
	if bNotChange then
		return false
	end
	if not aRefreshID then
		return true
	end
	for _, v in ipairs(aRefreshID) do
		if v == dwID or v == szGlobalID then
			return true
		end
	end
	return false
end

-- �����ã�������λ�ã�
X.RegisterBgMsg('ASK_CURRENT_LOC', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf then
		return
	end
	MessageBox({
		szName = 'ASK_CURRENT_LOC' .. dwTalkerID,
		szMessage = _L('[%s] wants to get your location, would you like to share?', szTalkerName), {
			szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
				local me = X.GetClientPlayer()
				local nReplyChannel = D.GetReplyChannel(nChannel, szTalkerName)
				X.SendBgMsg(nReplyChannel, 'REPLY_CURRENT_LOC', { me.GetMapID(), me.nX, me.nY, me.nZ }, true)
			end
		}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
	})
end)

-- �����ã��鿴�汾��Ϣ��
X.RegisterBgMsg(X.NSFormatString('{$NS}_VERSION_CHECK'), function(_, oData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf then
		return
	end
	local bSilent = oData[1]
	if not bSilent and X.IsClientPlayerInParty() then
		X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('I\'ve installed %s v%s', X.PACKET_INFO.NAME, X.PACKET_INFO.VERSION))
	end
	local nReplyChannel = D.GetReplyChannel(nChannel, szTalkerName)
	X.SendBgMsg(nReplyChannel, X.NSFormatString('{$NS}_VERSION_REPLY'), {X.PACKET_INFO.VERSION, X.PACKET_INFO.BUILD}, true)
end)

-- �����ã����Թ��ߣ�
X.RegisterBgMsg(X.NSFormatString('{$NS}_GFN_CHECK'), function(_, oData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if bSelf or X.IsDebugging() then
		return
	end
	X.SendBgMsg(szTalkerName, X.NSFormatString('{$NS}_GFN_REPLY'), {oData[1], X.XpCall(X.Get(_G, oData[2]), select(3, X.Unpack(oData)))}, true)
end)

-- ����鿴����
X.RegisterBgMsg('RL', function(_, data, nChannel, dwTalkerID, szTalkerName, bIsSelf)
	if not bIsSelf then
		local nReplyChannel = D.GetReplyChannel(nChannel, szTalkerName)
		if data[1] == 'ASK' then
			X.Confirm(_L('[%s] want to see your info, OK?', szTalkerName), function()
				local me = X.GetClientPlayer()
				local nGongZhan = X.GetBuff(me, 3219) and 1 or 0
				local bEx = X.IsAuthorPlayer(me.dwID) and 'Author' or 'Player'
				X.SendBgMsg(nReplyChannel, 'RL', {'Feedback', me.dwID, UI_GetPlayerMountKungfuID(), nGongZhan, bEx}, true)
			end)
		end
	end
end)

-- �鿴��������
X.RegisterBgMsg('CHAR_INFO', function(_, data, nChannel, dwTalkerID, szTalkerName, bIsSelf)
	if not bIsSelf and data[2] == X.GetClientPlayerID() then
		local nReplyChannel = X.IsTeammate(dwTalkerID)
			and PLAYER_TALK_CHANNEL.RAID
			or D.GetReplyChannel(nChannel, szTalkerName)
		if data[1] == 'ASK'  then
			if not _G.MY_CharInfo or _G.MY_CharInfo.bEnable or data[3] == 'DEBUG' then
				local aInfo = X.GetClientPlayerCharInfo()
				if not X.IsTeammate(dwTalkerID) and not data[3] == 'DEBUG' then
					for _, v in ipairs(aInfo) do
						v.tip = nil
					end
				end
				X.SendBgMsg(nReplyChannel, 'CHAR_INFO', {'ACCEPT', dwTalkerID, aInfo}, true)
			else
				X.SendBgMsg(nReplyChannel, 'CHAR_INFO', {'REFUSE', dwTalkerID}, true)
			end
		end
	end
end)

-- ����JH_ABOUT
X.RegisterBgMsg(X.NSFormatString('{$NS}_ABOUT'), function(_, data, nChannel, dwTalkerID, szTalkerName, bIsSelf)
	local nReplyChannel = D.GetReplyChannel(nChannel, szTalkerName)
	if data[1] == 'Author' then -- �汾��� ���� ���Ի�����ϸ���
		local me, szTong = X.GetClientPlayer(), ''
		if me.dwTongID > 0 then
			szTong = X.GetTongName(me.dwTongID) or 'Failed'
		end
		local szServer = select(2, GetUserServer())
		X.SendBgMsg(nReplyChannel, X.NSFormatString('{$NS}_ABOUT'), {'info',
			me.GetTotalEquipScore(),
			me.GetMapID(),
			szTong,
			me.nRoleType,
			X.PACKET_INFO.VERSION,
			szServer,
			X.GetBuff(me, 3219)
		}, true)
	elseif data[1] == 'TeamAuth' then -- ��ֹ����˯�� �����˲�ֹһ����
		local team = GetClientTeam()
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwTalkerID)
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwTalkerID)
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwTalkerID)
	elseif data[1] == 'TeamLeader' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwTalkerID)
	elseif data[1] == 'TeamMark' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwTalkerID)
	elseif data[1] == 'TeamDistribute' then
		GetClientTeam().SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwTalkerID)
	elseif data[1] == 'RESTRICTION' then
		X.SetRestricted(data[2], data[3])
	elseif data[1] == 'DEBUG' then
		X.SetDebugging(data[2], data[3])
	end
end)

-- �л���ͼ
do
	local l_nSwitchMapID, l_nSwitchSubID
	local l_nEnteringMapID, l_nEnteringSubID, l_dwEnteringTime, l_dwEnteringSwitchTime

	-- �������ĳ��ͼ������ǰ��
	local function OnSwitchMap(dwMapID, dwSubID, aMapCopy, dwTime)
		if not X.IsClientPlayerInParty() then
			return
		end
		l_nEnteringMapID = dwMapID
		l_nEnteringSubID = dwSubID
		l_dwEnteringSwitchTime = dwTime
		--[[#DEBUG BEGIN]]
		local szDebug = 'Switch map: ' .. dwMapID
		if dwSubID then
			szDebug = szDebug .. '(' .. dwSubID .. ')'
		end
		if aMapCopy then
			szDebug = szDebug .. ' #' .. table.concat(aMapCopy, ',')
		end
		if dwTime then
			szDebug = szDebug .. ' @' .. dwTime
		end
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, szDebug, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, X.NSFormatString('{$NS}_SWITCH_MAP'), {dwMapID, dwSubID, aMapCopy, dwTime}, true)
		X.SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, X.NSFormatString('{$NS}_SWITCH_MAP'), {dwMapID, dwSubID, aMapCopy, dwTime}, true)
	end

	-- �ɹ�����ĳ��ͼ��������ɣ������
	local function OnEnterMap(dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime, nCopyIndex)
		if not X.IsClientPlayerInParty() then
			return
		end
		--[[#DEBUG BEGIN]]
		local szDebug = 'Enter map: ' .. dwMapID
		if dwSubID then
			szDebug = szDebug .. '(' .. dwSubID .. ')'
		end
		if aMapCopy then
			szDebug = szDebug .. ' #' .. table.concat(aMapCopy, ',')
		end
		if dwTime then
			szDebug = szDebug .. ' @' .. dwTime
		end
		if dwSwitchTime then
			szDebug = szDebug .. ' <- ' .. dwSwitchTime
		end
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, szDebug, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, X.NSFormatString('{$NS}_ENTER_MAP'), {dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime, nCopyIndex}, true)
		X.SendBgMsg(PLAYER_TALK_CHANNEL.ROOM, X.NSFormatString('{$NS}_ENTER_MAP'), {dwMapID, dwSubID, aMapCopy, dwTime, dwSwitchTime, nCopyIndex}, true)
	end

	local function OnCrossMapGoFB()
		local dwTime = GetCurrentTime()
		local dwMapID, dwID = this.tInfo.MapID, this.tInfo.ID
		-- �ؾ����������Ƕӳ���ᵯ��������ʾ�� �� crossmap_dungeon_reset ����
		if X.IsDungeonResetable(dwMapID) and X.IsClientPlayerTeamLeader() then
			l_nSwitchMapID, l_nSwitchSubID = dwMapID, dwID
		else
			X.GetMapSaveCopy(dwMapID, function(aMapCopy)
				OnSwitchMap(dwMapID, dwID, aMapCopy, dwTime)
			end)
		end
		return X.UI.FormatUIEventMask(true, true)
	end

	local function OnFBAppendItemFromIni(hList)
		for i = 0, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			UnhookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB)
			HookTableFunc(hItem, 'OnItemLButtonDBClick', OnCrossMapGoFB, { bAfterOrigin = true, bHookReturn = true })
		end
	end

	X.RegisterFrameCreate('CrossMap', 'LIB#CD', function(name, frame)
		local hList = frame:Lookup('Wnd_CrossFB', 'Handle_DifficultyList')
		if hList then
			OnFBAppendItemFromIni(hList)
			HookTableFunc(hList, 'AppendItemFromIni', OnFBAppendItemFromIni, { bAfterOrigin = true })
		end
		local btn = frame:Lookup('Wnd_CrossFB/Btn_GoGoGo')
		if btn then
			HookTableFunc(btn, 'OnLButtonUp', OnCrossMapGoFB, { bAfterOrigin = true })
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Cross panel hooked.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end)

	X.RegisterEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), 'LIB#CD', function()
		if arg0 ~= 'crossmap_dungeon_reset' then
			return
		end
		if arg1 == 'ACTION' and arg2 == g_tStrings.STR_HOTKEY_SURE and l_nSwitchMapID then
			OnSwitchMap(l_nSwitchMapID, l_nSwitchSubID, nil, GetCurrentTime())
		end
		l_nSwitchMapID, l_nSwitchSubID = nil, nil
	end)

	X.RegisterEvent('LOADING_ENDING', 'LIB#CD', function()
		l_dwEnteringTime = GetCurrentTime()
		local me = X.GetClientPlayer()
		local dwMapID = me.GetMapID()
		local nCopyIndex = me.GetScene().nCopyIndex
		X.GetMapSaveCopy(dwMapID, function(aMapCopy)
			local nSubID, dwSwitchTime
			if dwMapID == l_nEnteringMapID then
				nSubID, dwSwitchTime = l_nEnteringSubID, l_dwEnteringSwitchTime
			end
			OnEnterMap(dwMapID, nSubID, aMapCopy, l_dwEnteringTime, dwSwitchTime, nCopyIndex)
		end)
	end)

	X.RegisterBgMsg(X.NSFormatString('{$NS}_ENTER_MAP_REQ'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
		if not l_dwEnteringTime then
			return
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Enter map request from ' .. szTalkerName, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local me = X.GetClientPlayer()
		local dwMapID = me.GetMapID()
		local nCopyIndex = me.GetScene().nCopyIndex
		X.GetMapSaveCopy(dwMapID, function(aMapCopy)
			local nSubID, dwSwitchTime
			if dwMapID == l_nEnteringMapID then
				nSubID, dwSwitchTime = l_nEnteringSubID, l_dwEnteringSwitchTime
			end
			OnEnterMap(dwMapID, nSubID, aMapCopy, l_dwEnteringTime, dwSwitchTime, nCopyIndex)
		end)
	end)
end

X.RegisterBgMsg(X.NSFormatString('{$NS}_OUTPUT_BUFF'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	local aRes = {}
	local me = X.GetClientPlayer()
	for _, buff in X.ipairs_c(X.GetBuffList(me)) do
		table.insert(aRes, X.CloneBuff(buff, {}))
	end
	X.Output(aRes)
end)


-- ��ɫ GlobalID
do
	local LAST_TIME = 0
	X.RegisterBgMsg(X.NSFormatString('{$NS}_GLOBAL_ID_REQUEST'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
		if bSelf then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Global id request sent.', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return
		end
		if LAST_TIME + 5 > GetCurrentTime() then
			return
		end
		local aRequestID, aRefreshID = data[1], data[2]
		local dwID = X.GetClientPlayerID()
		local szGlobalID = X.GetClientPlayerGlobalID()
		local bNotChange = not X.IsNil(LAST_TIME)
		local bResponse = D.NeedReply(aRequestID, aRefreshID, dwID, szGlobalID, bNotChange)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Global id request from ' .. szTalkerName
			.. ', will ' .. (bResponse and '' or 'not ') .. 'response.', X.DEBUG_LEVEL.PM_LOG)
		--[[#DEBUG END]]
		if bResponse then
			local nReplyChannel = D.GetReplyChannel(nChannel, szTalkerName)
			X.SendBgMsg(nReplyChannel, X.NSFormatString('{$NS}_GLOBAL_ID'), X.GetClientPlayerGlobalID(), true)
			LAST_TIME = GetCurrentTime()
		end
	end)
end
--------------------------------------------------------------------------------
--- �Ӳ���Զ��屳��ͨѶ
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
