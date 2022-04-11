--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ɫ����
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
local MODULE_NAME = 'MY_TeamTools'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
X.RegisterRestriction('MY_CharInfo.Daddy', { ['*'] = true })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_CharInfo', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

local CharInfo = {}

function CharInfo.GetFrame(dwID)
	return Station.Lookup('Normal/MY_CharInfo' .. dwID)
end

function CharInfo.CreateFrame(dwID, szName)
	local ui = UI.CreateFrame('MY_CharInfo' .. dwID, { w = 240, h = 400, text = '', close = true })
	local frame = CharInfo.GetFrame(dwID)
	local x, y = 20, 10
	x = x + ui:Append('Image', {
		name = 'Image_Kungfu',
		x = x, y = y, w = 30, h = 30,
	}):Width() + 5
	ui:Append('Text', {
		name = 'Text_Name',
		x = x, y = y + 2, w = 240 - 2 * x,
		text = wstring.sub(szName, 1, 6), alignHorizontal = 1,
	}) -- UI����
	ui:Append('WndButton', {
		name = 'LOOKUP', x = 70, y = 360,
		text = g_tStrings.STR_LOOKUP,
		buttonStyle = 'FLAT',
		onClick = function()
			ViewInviteToPlayer(dwID)
		end,
	})
	ui:Append('Text', { name = 'Text_Info', x = 20, y = 72, text = _L['Asking...'], w = 200, h = 70, font = 27, multiline = true })
	frame.pending = true
end

function CharInfo.UpdateFrame(frame, status, data)
	if not frame or not frame.pending then
		return
	end
	local ui = UI(frame)
	if status == 'REFUSE' then
		ui:Children('#Text_Info'):Text(_L['Refuse request']):Show()
		frame.pending = false
	elseif status == 'PROGRESS' then
		ui:Children('#Text_Info'):Text(_L('Syncing: %.2f%%.', data)):Show()
	elseif status == 'ACCEPT' and data and type(data) == 'table' then
		local self_data = X.GetCharInfo()
		local function GetSelfValue(label, value)
			for i = 1, #self_data do
				local v = self_data[i]
				if v.label == label then
					local sc = tonumber((tostring(v.value):gsub('%%', '')))
					local tc = tonumber((tostring(value):gsub('%%', '')))
					if sc and tc then
						return tc > sc and { 200, 255, 200 } or tc < sc and { 255, 200, 200 } or { 255, 255, 255 }
					end
				end
			end
			return { 255, 255, 255 }
		end
		-- ���û�������
		ui:Children('#Image_Kungfu'):Icon((select(2, X.GetSkillName(data.dwMountKungfuID, 1))))
		ui:Children('#Text_Name'):Color({ X.GetForceColor(data.dwForceID) })
		-- ����������
		local y0 = 20
		for i = 1, #data do
			local v = data[i]
			if v.category then
				ui:Append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, alignHorizontal = 1, text = v.label })
			else
				ui:Append('Text', { x = 20, y = y0 + i * 25, w = 200, h = 25, alignHorizontal = 0, text = v.label })
				ui:Append('Text', {
					x = 20, y = y0 + i * 25, w = 200, h = 25,
					alignHorizontal = 2, text = v.value,
					color = GetSelfValue(v.label, v.value),
					onHover = function(bHover)
						if not v.tip or v.szTip then
							return
						end
						if bHover then
							local x, y = this:GetAbsPos()
							local w, h = this:GetSize()
							OutputTip(v.tip or v.szTip, 550, { x, y, w, h })
						else
							HideTip()
						end
					end,
				})
			end
		end
		-- �����С����
		ui:Size(240, y0 + 75 + #data * 25)
		ui:Children('#LOOKUP'):Pos(70, y0 + 35 + #data * 25)
		ui:Anchor('CENTER')
		ui:Children('#Text_Info'):Hide()
		frame.pending = false
	end
end

X.RegisterBgMsg('CHAR_INFO', function(szMsgID, aData, nChannel, dwID, szName, bIsSelf)
	local szAction, dwTarID, oData = aData[1], aData[2], aData[3]
	if not bIsSelf and dwTarID == UI_GetClientPlayerID() then
		local frame = CharInfo.GetFrame(dwID)
		if not frame then
			return
		end
		CharInfo.UpdateFrame(frame, szAction, oData)
	end
end, function(szMsgID, nSegCount, nSegRecv, nSegIndex, nChannel, dwID, szName, bIsSelf)
	if bIsSelf then
		return
	end
	local frame = CharInfo.GetFrame(dwID)
	if not frame then
		return
	end
	CharInfo.UpdateFrame(frame, 'PROGRESS', nSegRecv / nSegCount * 100)
end)

-- public API
function D.ViewCharInfoToPlayer(dwID)
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
	end
	local nChannel, szName
	if X.IsParty(dwID) then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(dwID)
		if info then
			nChannel = PLAYER_TALK_CHANNEL.RAID
			szName = info.szName
		end
	end
	if not nChannel then
		local tar = GetPlayer(dwID)
		if tar then
			nChannel = tar.szName
			szName = tar.szName
		end
	end
	if not nChannel and MY_Farbnamen and MY_Farbnamen.Get then
		local info = MY_Farbnamen.Get(dwID)
		if info then
			nChannel = info.szName
			szName = info.szName
		end
	end
	if not nChannel or not szName then
		X.Alert(_L['Party limit'])
	else
		CharInfo.CreateFrame(dwID, szName)
		X.SendBgMsg(nChannel, 'CHAR_INFO', {'ASK', dwID, X.IsRestricted('MY_CharInfo.Daddy') and 'DEBUG'})
	end
end

do
local function GetInfoPanelMenu()
	local dwType, dwID = X.GetTarget()
	if dwType == TARGET.PLAYER and dwID ~= UI_GetClientPlayerID() then
		return {
			szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR,
			fnAction = function()
				D.ViewCharInfoToPlayer(dwID)
			end
		}
	end
end
X.RegisterTargetAddonMenu('MY_CharInfo', GetInfoPanelMenu)
end


-- Global exports
do
local settings = {
	name = 'MY_CharInfo',
	exports = {
		{
			fields = {
				'ViewCharInfoToPlayer',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_CharInfo = X.CreateModule(settings)
end
