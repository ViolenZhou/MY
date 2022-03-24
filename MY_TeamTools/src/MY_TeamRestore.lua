--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �����Ŷ�
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
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamRestore'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------

local DATA_PATH = {'userdata/team_restore.jx3dat', X.PATH_TYPE.SERVER}
local D = {}
local O = {
	bKeepMark = true,
	bKeepForm = true,
	SaveList = X.LoadLUAData(DATA_PATH) or {},
	szMarkImage = PARTY_MARK_ICON_PATH,
	tMarkFrame = PARTY_MARK_ICON_FRAME_LIST,
}

function D.LoadLUAData()
	O.SaveList = X.LoadLUAData(DATA_PATH) or {}
end

function D.SaveLUAData()
	X.SaveLUAData(DATA_PATH, O.SaveList)
end

function D.Save(nIndex, szName)
	local tList, tList2, me, team = {}, {}, GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return X.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	end
	local tSave = {}
	tSave.szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
	tSave.szMark = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK))
	tSave.szDistribute = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE))
	tSave.nLootMode = team.nLootMode
	local tMark = team.GetTeamMark()
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		tList2[nGroup] = {}
		for _, dwID in ipairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			local info = team.GetMemberInfo(dwID)
			if szName then
				local item = {}
				item.nGroup = nGroup
				item.nMark = tMark[dwID]
				item.bForm = dwID == tGroupInfo.dwFormationLeader
				tList[szName] = item
				table.insert(tList2[nGroup], {
					dwMountKungfuID = info.dwMountKungfuID,
					nMark = tMark[dwID],
					bForm = dwID == tGroupInfo.dwFormationLeader,
					nGroup = nGroup,
				})
			end
		end
	end
	szName = X.TrimString(szName)
	if X.IsEmpty(szName) then
		szName = X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
	end
	tSave.name = szName
	tSave.data = tList
	tSave.data2 = tList2
	-- saved ok
	if not nIndex or nIndex > #O.SaveList then
		nIndex = #O.SaveList + 1
	end
	O.SaveList[nIndex] = tSave
	D.SaveLUAData()
	X.Sysmsg(_L['Team list data saved'])
end
function D.Delete(nIndex)
	table.remove(O.SaveList, nIndex)
	D.SaveLUAData()
end
function D.SyncMember(team, dwID, szName, state)
	if O.bKeepForm and state.bForm then --������֮ǰ������
		team.SetTeamFormationLeader(dwID, state.nGroup) -- ���۸���
		X.Sysmsg(_L('Restore formation of %d group: %s', state.nGroup + 1, szName))
	end
	if O.bKeepMark and state.nMark then -- ������֮ǰ�б��
		team.SetTeamMark(state.nMark, dwID) -- ��Ǹ���
		X.Sysmsg(_L('Restore player marked as [%s]: %s', X.GetMarkName(state.nMark), szName))
	end
end

function D.GetWrongIndex(tWrong, bState)
	for k, v in ipairs(tWrong) do
		if not bState or v.state then
			return k
		end
	end
end

function D.Restore(n)
	-- ��ȡ�Լ����ŶӲ�������
	local me, team = GetClientPlayer(), GetClientTeam()
	-- update֮ǰ������Ŷ��б�
	D.LoadLUAData()

	if not me or not me.IsInParty() then
		return X.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	elseif not O.SaveList[n] then
		return X.Sysmsg(_L['You have not saved team list data'], CONSTANT.MSG_THEME.ERROR)
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return X.Sysmsg(_L['You are not team leader, permission denied'], CONSTANT.MSG_THEME.ERROR)
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	--parse wrong member
	local tSaved, tWrong, dwLeader, dwMark = O.SaveList[n].data, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		tWrong[nGroup] = {}
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for _, dwID in pairs(tGroupInfo.MemberList) do
			local szName = team.GetClientTeamMemberName(dwID)
			if not szName then
				X.Sysmsg(_L('Unable get player of %d group: #%d', nGroup + 1, dwID), CONSTANT.MSG_THEME.ERROR)
			else
				if not tSaved[szName] then
					szName = string.gsub(szName, '@.*', '')
				end
				local state = tSaved[szName]
				if not state then
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = nil })
					X.Sysmsg(_L('Unknown status: %s', szName))
				elseif state.nGroup == nGroup then
					D.SyncMember(team, dwID, szName, state)
					X.Sysmsg(_L('Need not adjust: %s', szName))
				else
					table.insert(tWrong[nGroup], { dwID = dwID, szName = szName, state = state })
				end
				if szName == O.SaveList[n].szLeader then
					dwLeader = dwID
				end
				if szName == O.SaveList[n].szMark then
					dwMark = dwID
				end
				if szName == O.SaveList[n].szDistribute and dwID ~= team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) then
					team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE,dwID)
					X.Sysmsg(_L('Restore distributor: %s', szName))
				end
			end
		end
	end
	-- loop to restore
	for nGroup = 0, team.nGroupNum - 1 do
		local nIndex = D.GetWrongIndex(tWrong[nGroup], true)
		while nIndex do
			-- wrong user to be adjusted
			local src = tWrong[nGroup][nIndex]
			local dIndex = D.GetWrongIndex(tWrong[src.state.nGroup], false)
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
					D.SyncMember(team, dst.dwID, dst.szName, dst.state)
				end
			end
			X.Sysmsg(_L('Change group of [%s] to %d', src.szName, src.state.nGroup + 1))
			D.SyncMember(team, src.dwID, src.szName, src.state)
			nIndex = D.GetWrongIndex(tWrong[nGroup], true) -- update nIndex
		end
	end
	-- restore others
	if team.nLootMode ~= O.SaveList[n].nLootMode then
		team.SetTeamLootMode(O.SaveList[n].nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		X.Sysmsg(_L('Restore team marker: %s', O.SaveList[n].szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		X.Sysmsg(_L('Restore team leader: %s', O.SaveList[n].szLeader))
	end
	X.Sysmsg(_L['Team list restored'])
end

function D.Restore2(n)
	D.LoadLUAData()
	local me, team = GetClientPlayer(), GetClientTeam()
	if not me or not me.IsInParty() then
		return X.Sysmsg(_L['You are not in a team'], CONSTANT.MSG_THEME.ERROR)
	elseif not O.SaveList[n] then
		return X.Sysmsg(_L['You have not saved team list data'], CONSTANT.MSG_THEME.ERROR)
	end
	-- get perm
	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) ~= me.dwID then
		local nGroup = team.GetMemberGroupIndex(me.dwID) + 1
		local szLeader = team.GetClientTeamMemberName(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		return X.Sysmsg(_L['You are not team leader, permission denied'], CONSTANT.MSG_THEME.ERROR)
	end

	if team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, me.dwID)
	end

	local tSaved, tWrong, dwLeader, dwMark = O.SaveList[n].data2, {}, 0, 0
	for nGroup = 0, team.nGroupNum - 1 do
		local tGroupInfo = team.GetGroupInfo(nGroup)
		for k,v in pairs(tGroupInfo.MemberList) do
			local info = team.GetMemberInfo(v)
			tWrong[v] = { nGroup = nGroup, dwMountKungfuID = info.dwMountKungfuID }
		end
	end

	local fnAction = function(dwMountKungfuID,nGroup,dwID)
		for k,v in pairs(tWrong) do
			if dwMountKungfuID and v.dwMountKungfuID == dwMountKungfuID then -- ֻҪ�ڹ�ƥ�����
				return k,v
			elseif nGroup and v.nGroup == nGroup and k ~= dwID then -- �����Լ���ͬ����Ҫһ��
				return k,v
			end
		end
		return false,false
	end

	for nGroup,tGroup in pairs(tSaved) do
		for k,v in ipairs(tGroup) do
			local tGroupInfo = team.GetGroupInfo(nGroup)
			local dwID,tab = fnAction(v.dwMountKungfuID)
			if dwID then
				local info = team.GetMemberInfo(dwID)
				if nGroup == tab.nGroup then
					tWrong[dwID] = nil
					X.Sysmsg(_L('Need not adjust: %s', info.szName))
					D.SyncMember(team, dwID, info.szName, v)
				else
					if #tGroupInfo.MemberList < 5 then
						team.ChangeMemberGroup(dwID,nGroup,0)
						tWrong[dwID] = nil
						X.Sysmsg(_L('Change group of [%s] to %d', info.szName, nGroup + 1))
						D.SyncMember(team, dwID, info.szName, v)
					else
						local ddwID,dtab = fnAction(false,nGroup,dwID)
						if ddwID then
							team.ChangeMemberGroup(dwID,nGroup,ddwID)
							tWrong[ddwID].nGroup = tab.nGroup -- update
							tWrong[dwID] = nil
							X.Sysmsg(_L('Change group of [%s] to %d', info.szName, nGroup + 1))
							D.SyncMember(team, dwID, info.szName, v)
						end
					end
				end
			end
		end
	end
	-- restore others
	if team.nLootMode ~= O.SaveList[n].nLootMode then
		team.SetTeamLootMode(O.SaveList[n].nLootMode)
	end
	if dwMark ~= 0 and dwMark ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK, dwMark)
		X.Sysmsg(_L('Restore team marker: %s', O.SaveList[n].szMark))
	end
	if dwLeader ~= 0 and dwLeader ~= me.dwID then
		team.SetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER, dwLeader)
		X.Sysmsg(_L('Restore team leader: %s', O.SaveList[n].szLeader))
	end
	X.Sysmsg(_L['Team list restored'])
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nX, y = nY + 15, text = _L['MY_TeamRestore'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = nPaddingX + 10
	nY = nY + 5
	for i, v in ipairs(O.SaveList) do
		nX = ui:Append('WndButton', {
			x = nX + 5, y = nY, w = 80, text = v.name,
			buttonstyle = 'FLAT',
			tip = v.name .. '\n' .. _L['Left click to recovery, right click for more.'],
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
			onlclick = function()
				if IsCtrlKeyDown() then
					D.Restore2(i)
				else
					D.Restore(i)
				end
			end,
			rmenu = function()
				local menu = {
					{
						szOption = _L['Restore'],
						fnAction = function()
							D.Restore(i)
						end,
					},
					{
						szOption = _L['Restore2'],
						fnAction = function()
							D.Restore2(i)
						end,
					},
					{
						szOption = _L['Delete'],
						fnAction = function()
							D.Delete(i)
							X.SwitchTab('MY_TeamTools', true)
						end,
					},
					{
						szOption = _L['Rename'],
						fnAction = function()
							GetUserInput(_L['Save team name'], function(text)
								text = X.TrimString(text)
								if not X.IsEmpty(text) then
									v.name = text
									D.SaveLUAData()
									X.SwitchTab('MY_TeamTools', true)
								end
							end, nil, nil, nil, nil, 50)
						end,
					},
					{
						szOption = _L['Replace'],
						fnAction = function()
							D.Save(i)
						end,
					},
				}
				local menu1 = { szOption = _L['Detail'] }
				table.insert(menu1, { szOption = _L('Leader:%s', v['szLeader']) })
				table.insert(menu1, { szOption = _L('Distribute:%s', v['szDistribute']) })
				table.insert(menu1, { szOption = _L('Mark:%s', v['szMark']) })
				table.insert(menu1, { bDevide = true })
				for i = 1, 5 do
					table.insert(menu1, { szOption = _L('Party %d', i) })
				end
				for kk, vv in pairs(v['data']) do
					table.insert(menu1[5 + vv.nGroup], { szOption = kk })
				end
				table.insert(menu, menu1)
				return menu
			end,
		}):Pos('BOTTOMRIGHT') + 10
		if nX + 80 > nW then
			nX = nPaddingX + 10
			nY = nY + 28
		end
	end

	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY, text = _L['Save Team'],
		buttonstyle = 'FLAT',
		onclick = function()
			GetUserInput(_L['Save team name'], function(text)
				D.Save(nil, text)
				X.SwitchTab('MY_TeamTools', true)
			end, nil, nil, nil, nil, 50)
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 28

	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_TeamRestore',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_TeamRestore = X.CreateModule(settings)
end
