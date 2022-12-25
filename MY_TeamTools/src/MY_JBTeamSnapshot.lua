--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBTeamSnapshot'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^14.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_JBTeamSnapshot', _L['Raid'], {
	szTeam = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
})
local D = {}

function D.CreateSnapshot()
	local dwID = X.GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		X.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	if X.IsEmpty(O.szTeam) then
		X.ShowPanel()
		X.SwitchTab('MY_JX3BOX')
		return X.Alert(_L['Please input team name/id.'])
	end
	local aTeammate = {}
	local team = X.IsInParty() and GetClientTeam()
	if team then
		for _, dwTarID in ipairs(team.GetTeamMemberList()) do
			local info = team.GetMemberInfo(dwTarID)
			local guid = X.GetPlayerGUID(dwTarID) or 0
			table.insert(aTeammate, info.szName .. ',' .. dwTarID .. ',' .. guid .. ',' .. info.dwMountKungfuID)
		end
	end
	local me = X.GetClientPlayer()
	X.Ajax({
		url = 'https://push.j3cx.com/team/snapshot',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			team = O.szTeam,
			cguid = X.GetClientGUID(),
			jx3id = X.GetPlayerGUID(),
			server = X.GetServerOriginName(),
			teammate = table.concat(aTeammate, ';'),
		},
		signature = X.SECRET['J3CX::TEAM_SNAPSHOT'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if X.Get(res, {'code'}) == 0 then
				X.Alert(_L['Upload snapshot succeed!'])
			else
				X.Alert(_L['Upload snapshot failed!'] .. X.ReplaceSensitiveWord(X.Get(res, {'msg'}, _L['Request failed.'])))
			end
		end,
		error = function()
			X.Alert(_L['Upload snapshot failed!'])
		end,
	})
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	-- �������
	nX = nPaddingX
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Team Snapshot'], font = 27 }):Height() + 2

	nX = nPaddingX + 10
	local bLoading
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Team name/id:'] }):Width()
	ui:Append('Text', {
		x = nX, y = nY + nLH, h = 25,
		text = _L['(Input: Team@Server:Passcode)'],
		color = { 172, 172, 172 },
	}):AutoWidth()
	nX = nX + ui:Append('WndEditBox', {
		x = nX, y = nY + 2, w = 300, h = 25,
		text = O.szTeam,
		onChange = function(szText)
			O.szTeam = szText
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonStyle = 'FLAT', text = _L['Upload Snapshot'],
		onClick = function()
			D.CreateSnapshot()
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButtonBox', {
		x = nX, y = nY + 5, w = 130, h = 20,
		color = { 234, 235, 185 },
		buttonStyle = 'LINK',
		text = _L['>> View Snapshots <<'],
		onClick = function()
			X.OpenBrowser('https://page.j3cx.com/jx3box/team/snapshot')
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
end

-- Global exports
do
local settings = {
	name = 'MY_JBTeamSnapshot',
	exports = {
		{
			fields = {
				'CreateSnapshot',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'szTeam',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'szTeam',
			},
			root = O,
		},
	},
}
MY_JBTeamSnapshot = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
