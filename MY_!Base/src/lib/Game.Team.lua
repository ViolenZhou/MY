--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Team')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.IsMarker(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == dwID
end

function X.IsLeader(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwID
end

function X.IsDistributor(...)
	local dwID = select('#', ...) == 0 and X.GetClientPlayerID() or ...
	return GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == dwID
end
X.IsDistributer = X.IsDistributor

-- �ж��Լ��ڲ��ڶ�����
-- (bool) X.IsInParty()
function X.IsInParty()
	local me = X.GetClientPlayer()
	return me and me.IsInParty()
end

-- �ж��Լ��ڲ����Ŷ���
-- (bool) X.IsInRaid()
function X.IsInRaid()
	local me = X.GetClientPlayer()
	return me and me.IsInRaid()
end

---�жϵ�ǰ�Ŷӡ������л�״̬
---@return '"TEAM"' | '"ROOM"' @��ǰ��ͼ�������л������ǩ
function X.GetCurrentTeamSwitchType()
	if TeamSwitchBtn_IsCheckRoom then
		return TeamSwitchBtn_IsCheckRoom()
			and 'ROOM'
			or 'TEAM'
	end
	return 'TEAM'
end

-- ���ñ��Ŀ��
---@param nMark number @�������
---@param dwID number @Ŀ��ID
---@return boolean @�Ƿ�ɹ�
function X.SetTeamMarkTarget(nMark, dwID)
	local npc = not X.IsPlayer(dwID) and X.GetNpc(dwID) or nil
	if npc and X.IsShieldedNpc(npc.dwTemplateID) then
		return false
	end
	return GetClientTeam().SetTeamMark(nMark, dwID) or false
end

-- ��ȡ���б��Ŀ��
---@return table @���б��Ŀ��
function X.GetTeamMark()
	if not X.IsInParty() then
		return X.CONSTANT.EMPTY_TABLE
	end
	return GetClientTeam().GetTeamMark() or X.CONSTANT.EMPTY_TABLE
end

-- ��ȡ���Ŀ��
---@param nMark number @�������
---@return number @Ŀ��ID
function X.GetTeamMarkTarget(nMark)
	local tMark = X.GetTeamMark()
	return tMark[nMark]
end

-- ��ȡĿ����
---@param dwID number @Ŀ��ID
---@return number @�������
function X.GetTargetTeamMark(dwID)
	if not X.IsInParty() then
		return
	end
	return GetClientTeam().GetMarkIndex(dwID)
end

-- ���浱ǰ�Ŷ���Ϣ
-- (table) X.GetTeamInfo([table tTeamInfo])
function X.GetTeamInfo(tTeamInfo)
	local tList, me, team = {}, X.GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	end
	tTeamInfo = tTeamInfo or {}
	tTeamInfo.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tTeamInfo.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tTeamInfo.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tTeamInfo.nLootMode = team.nLootMode

	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
			end
		end
	end
	tTeamInfo.tList = tList
	return tTeamInfo
end

do
local function GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end
local function SyncMember(team, dwID, szName, state)
	if state.bForm then --������֮ǰ������
		team.SetTeamFormationLeader(dwID, state.nGroup) -- ���۸���
		X.Sysmsg(_L('Restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if state.nMark then -- ������֮ǰ�б��
		team.SetTeamMark(state.nMark, dwID) -- ��Ǹ���
		X.Sysmsg(_L('Restore player marked as [%s]: %s', X.CONSTANT.TEAM_MARK_NAME[state.nMark], szName))
	end
end
-- �ָ��Ŷ���Ϣ
-- (bool) X.SetTeamInfo(table tTeamInfo)
function X.SetTeamInfo(tTeamInfo)
	local me, team = X.GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return false
	elseif not tTeamInfo then
		return false
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return X.Sysmsg(_L['You are not team leader, permission denied'])
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = tTeamInfo.tList, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				X.Sysmsg(_L('Unable get player of %d group: #%d', nGroup + 1, dwID))
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					X.Sysmsg(_L('Unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					SyncMember(team, dwID, szName, state)
					X.Sysmsg(_L('Need not adjust: %s', szName))
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == tTeamInfo.szLeader then
					dwLeader = dwID
				end
				if szName == tTeamInfo.szMark then
					dwMark = dwID
				end
				if szName == tTeamInfo.szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE, dwID)
					X.Sysmsg(_L('Restore distributor: %s', szName))
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = GetWrongIndex(tWrong[src.state.nGroup], false)
			table.remove(tWrong[nGroup], nIndex)
			-- do adjust
			if not dIndex then
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, 0) -- ֱ�Ӷ���ȥ
			else
				local dst = tWrong[src.state.nGroup][dIndex]
				table.remove(tWrong[src.state.nGroup], dIndex)
				team.ChangeMemberGroup(src.dwID, src.state.nGroup, dst.dwID)
				if not dst.state or dst.state.nGroup ~= nGroup then
					table.insert(tWrong[nGroup], dst)
				else -- bingo
					X.Sysmsg(_L('Change group of [%s] to %d', dst.szName, nGroup + 1))
					SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			X.Sysmsg(_L('Change group of [%s] to %d', src.szName, src.state.nGroup + 1))
			SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= tTeamInfo.nLootMode then
		team.SetTeamLootMode(tTeamInfo.nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		X.Sysmsg(_L('Restore team marker: %s', tTeamInfo.szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		X.Sysmsg(_L('Restore team leader: %s', tTeamInfo.szLeader))
	end
	X.Sysmsg(_L['Team list restored'])
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
