--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Relation')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ��ɫ��ϵ��ؽӿ�
--------------------------------------------------------------------------------

-- �ж��ǲ��Ƕ���
---@param xKey number | string @��ɫID����ɫ������ɫΨһID
---@return boolean @�ý�ɫ�ǲ��Ƕ���
function X.IsTeammate(xKey)
	if X.IsString(xKey) then
		if xKey == X.GetClientPlayerName() or xKey == X.GetClientPlayerGlobalID() then
			return true
		end
		local team = GetClientTeam()
		for _, dwTarID in ipairs(team.GetTeamMemberList()) do
			local tMember = X.GetTeamMemberInfo(dwTarID)
			if xKey == tMember.szName or xKey == tMember.szGlobalID then
				return true
			end
		end
		return false
	end
	if xKey == X.GetClientPlayerID() then
		return true
	end
	local me = X.GetClientPlayer()
	return me and me.IsPlayerInMyParty(xKey)
end

-- �ж��ǲ�����ͬ����
---@param szGlobalID string @��ɫȫ��ID
---@return boolean @�ý�ɫ�ǲ��Ƿ����Ա
function X.IsRoommate(szGlobalID)
	if szGlobalID == X.GetClientPlayerGlobalID() then
		return true
	end
	for _, s in ipairs(X.GetRoomMemberList()) do
		if szGlobalID == s then
			return true
		end
	end
	return false
end

-- �жϹ�ϵ
---@param dwSelfID number @��Դ��ɫID
---@param dwPeerID number @Ŀ���ɫID
---@return "'Self'"|"'Party'"|"'Neutrality'"|"'Foe'"|"'Enemy'"|"'Ally'" @Ŀ���ɫ�����Դ��ɫ�Ĺ�ϵ
function X.GetCharacterRelation(dwSelfID, dwPeerID)
	if not dwPeerID then
		dwPeerID = dwSelfID
		dwSelfID = X.GetControlPlayerID()
	end
	if not X.IsPlayer(dwPeerID) then
		local npc = X.GetNpc(dwPeerID)
		if npc
		and npc.dwEmployer ~= 0 and X.GetPlayer(npc.dwEmployer)
		and not X.IsPartnerNpc(npc.dwTemplateID) then
			dwPeerID = npc.dwEmployer
		end
	end
	if X.IsCharacterRelationSelf(dwSelfID, dwPeerID) then
		return 'Self'
	end
	local dwSrcID, dwTarID = dwSelfID, dwPeerID
	if not X.IsPlayer(dwTarID) then
		dwSrcID, dwTarID = dwTarID, dwSrcID
	end
	if IsParty(dwSrcID, dwTarID) then
		return 'Party'
	elseif IsNeutrality(dwSrcID, dwTarID) then
		return 'Neutrality'
	elseif IsEnemy(dwSrcID, dwTarID) then -- �жԹ�ϵ
		if X.GetFoeInfo(dwPeerID) then
			return 'Foe'
		else
			return 'Enemy'
		end
	elseif IsAlly(dwSrcID, dwTarID) then -- ��ͬ��Ӫ
		return 'Ally'
	else
		return 'Enemy' -- 'Other'
	end
end

-- �ж��ǲ��Ǻ���
---@param dwSelfID number @��Դ��ɫID
---@param dwPeerID number @Ŀ���ɫID
---@return boolean @Ŀ���ɫ�����Դ��ɫ�ǲ��Ǻ���
function X.IsCharacterRelationEnemy(dwSelfID, dwPeerID)
	return X.GetCharacterRelation(dwSelfID, dwPeerID) == 'Enemy'
end

function X.IsCharacterRelationSelf(dwSrcID, dwTarID)
	if X.IsFunction(IsSelf) then
		return IsSelf(dwSrcID, dwTarID)
	end
	return dwSrcID ~= 0 and dwSrcID == dwTarID and X.IsPlayer(dwSrcID) and X.IsPlayer(dwTarID)
end

local AUTHOR_GLOBAL_ID, AUTHOR_ROLE
function X.IsAuthorPlayer(dwID, szName, szGlobalID)
	if not AUTHOR_GLOBAL_ID or not AUTHOR_ROLE then
		AUTHOR_GLOBAL_ID, AUTHOR_ROLE = {}, {}
		for _, v in ipairs(X.PACKET_INFO.AUTHOR_ROLE_LIST) do
			if X.IsGlobalID(v.szGlobalID) then
				AUTHOR_GLOBAL_ID[v.szGlobalID] = true
			end
			if X.IsString(v.szName) and X.IsNumber(v.dwID) then
				AUTHOR_ROLE[v.dwID] = v.szName
			end
		end
	end
	local kTarget = dwID and X.GetPlayer(dwID)
	if kTarget then
		if not szGlobalID then
			szGlobalID = kTarget.GetGlobalID()
		end
		if not szName then
			szName = kTarget.szName
		end
	end
	if szGlobalID and AUTHOR_GLOBAL_ID[szGlobalID] then
		return true
	end
	if dwID and (
		AUTHOR_ROLE[dwID] == szName
			or AUTHOR_ROLE[dwID] == X.ExtractPlayerOriginName(szName)
			or AUTHOR_ROLE[dwID] == X.ExtractPlayerBaseName(szName)
	) then
		return true
	end
	return false
end

local AUTHOR_PLAYER_NAME
function X.IsAuthorPlayerName(szName)
	if not AUTHOR_PLAYER_NAME then
		AUTHOR_PLAYER_NAME = {}
		for _, v in ipairs(X.PACKET_INFO.AUTHOR_ROLE_LIST) do
			if X.IsString(v.szName) and v.dwID == '*' then
				AUTHOR_PLAYER_NAME[v.szName] = true
			end
		end
	end
	return AUTHOR_PLAYER_NAME[szName]
		or AUTHOR_PLAYER_NAME[X.ExtractPlayerOriginName(szName)]
		or AUTHOR_PLAYER_NAME[X.ExtractPlayerBaseName(szName)]
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
