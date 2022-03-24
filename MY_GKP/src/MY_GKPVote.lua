--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���ż�¼ ����ͶƱ���
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
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------

-- ���ʽ���
local TEAM_VOTE_REQUEST = {}
X.RegisterEvent('TEAM_VOTE_REQUEST', function()
	if arg0 == 1 then
		TEAM_VOTE_REQUEST = {}
		local team = GetClientTeam()
		for k, v in ipairs(team.GetTeamMemberList()) do
			TEAM_VOTE_REQUEST[v] = false
		end
	end
end)

X.RegisterEvent('TEAM_VOTE_RESPOND', function()
	if arg0 == 1 and not X.IsEmpty(TEAM_VOTE_REQUEST) then
		if arg2 == 1 then
			TEAM_VOTE_REQUEST[arg1] = true
		end
		local team  = GetClientTeam()
		local num   = team.GetTeamSize()
		local agree = 0
		for k, v in pairs(TEAM_VOTE_REQUEST) do
			if v then
				agree = agree + 1
			end
		end
		X.Topmsg(_L('Team Members: %d, %d agree %d%%', num, agree, agree / num * 100))
	end
end)

X.RegisterEvent('TEAM_INCOMEMONEY_CHANGE_NOTIFY', function()
	local nTotalRaidMoney = GetClientTeam().nInComeMoney
	if nTotalRaidMoney and nTotalRaidMoney == 0 then
		TEAM_VOTE_REQUEST = {}
	end
end)
