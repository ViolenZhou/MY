--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���ѡ�����Ա����������ʾ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_FooterTip'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^12.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_FooterTip', _L['General'], {
	bFriend = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFriendNav = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFriendDungeonHide = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTongMember = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTongMemberNav = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTongMemberDungeonHide = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

function D.Apply()
	-- ���Ѹ���
	if Navigator_Remove then
		Navigator_Remove('MY_FRIEND_TIP')
	end
	if D.bReady and O.bFriend and not X.IsInShieldedMap() and (not O.bFriendDungeonHide or not X.IsInDungeon()) then
		local hShaList = X.UI.GetShadowHandle('MY_FriendHeadTip')
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID)
			local tar = GetPlayer(dwID)
			local me = GetClientPlayer()
			if not tar or not me
			or X.IsIsolated(tar) ~= X.IsIsolated(me) then
				return
			end
			local p = X.GetFriend(dwID)
			if p then
				if O.bFriendNav and Navigator_SetID then
					Navigator_SetID('MY_FRIEND_TIP.' .. dwID, TARGET.PLAYER, dwID, p.name)
				else
					local sha = hShaList:Lookup(tostring(dwID))
					if not sha then
						hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
						sha = hShaList:Lookup(tostring(dwID))
					end
					local r, g, b, a = 255,255,255,255
					local szTip = '>> ' .. p.name .. ' <<'
					sha:ClearTriangleFanPoint()
					sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
					sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
					sha:Show()
				end
			end
		end
		local function OnPlayerLeave(dwID)
			if not D.bReady then
				X.DelayCall(500, function() OnPlayerLeave(dwID) end)
				return
			end
			if O.bFriendNav and Navigator_Remove then
				Navigator_Remove('MY_FRIEND_TIP.' .. dwID)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					table.insert(hShaList.freeShadows, sha)
				end
			end
		end
		local function RescanNearby()
			for _, p in ipairs(X.GetNearPlayer()) do
				OnPlayerEnter(p.dwID)
			end
		end
		RescanNearby()
		X.RegisterEvent('ON_ISOLATED', 'MY_FRIEND_TIP', function(event)
			-- dwCharacterID, nIsolated
			local me = GetClientPlayer()
			if arg0 == UI_GetClientPlayerID() then
				for _, p in ipairs(X.GetNearPlayer()) do
					if X.IsIsolated(p) == X.IsIsolated(me) then
						OnPlayerEnter(p.dwID)
					else
						OnPlayerLeave(p.dwID)
					end
				end
			else
				local tar = GetPlayer(arg0)
				if tar then
					if X.IsIsolated(tar) == X.IsIsolated(me) then
						OnPlayerEnter(arg0)
					else
						OnPlayerLeave(arg0)
					end
				end
			end
		end)
		X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_FRIEND_TIP', function(event) OnPlayerEnter(arg0) end)
		X.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_FRIEND_TIP', function(event) OnPlayerLeave(arg0) end)
		X.RegisterEvent('DELETE_FELLOWSHIP', 'MY_FRIEND_TIP', function(event) RescanNearby() end)
		X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE', 'MY_FRIEND_TIP', function(event) RescanNearby() end)
		X.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE', 'MY_FRIEND_TIP', function(event) RescanNearby() end)
	else
		X.RegisterEvent('ON_ISOLATED', 'MY_FRIEND_TIP', false)
		X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_FRIEND_TIP', false)
		X.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_FRIEND_TIP', false)
		X.RegisterEvent('DELETE_FELLOWSHIP', 'MY_FRIEND_TIP', false)
		X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE', 'MY_FRIEND_TIP', false)
		X.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE', 'MY_FRIEND_TIP', false)
		X.UI.GetShadowHandle('MY_FriendHeadTip'):Hide()
	end
	-- ����Ա����
	if Navigator_Remove then
		Navigator_Remove('MY_GUILDMEMBER_TIP')
	end
	if D.bReady and O.bTongMember and not X.IsInShieldedMap() and (not O.bTongMemberDungeonHide or not X.IsInDungeon()) then
		local hShaList = X.UI.GetShadowHandle('MY_TongMemberHeadTip')
		if not hShaList.freeShadows then
			hShaList.freeShadows = {}
		end
		hShaList:Show()
		local function OnPlayerEnter(dwID, nRetryCount)
			nRetryCount = nRetryCount or 0
			if not D.bReady then
				X.DelayCall(500, function() OnPlayerEnter(dwID, nRetryCount) end)
				return
			end
			if nRetryCount > 5 then
				return
			end
			local tar = GetPlayer(dwID)
			local me = GetClientPlayer()
			if not tar or not me
			or me.dwTongID == 0
			or me.dwID == tar.dwID
			or tar.dwTongID ~= me.dwTongID
			or X.IsIsolated(tar) ~= X.IsIsolated(me) then
				return
			end
			if tar.szName == '' then
				X.DelayCall(500, function() OnPlayerEnter(dwID, nRetryCount + 1) end)
				return
			end
			if O.bTongMemberNav and Navigator_SetID then
				Navigator_SetID('MY_GUILDMEMBER_TIP.' .. dwID, TARGET.PLAYER, dwID, tar.szName)
			else
				local sha = hShaList:Lookup(tostring(dwID))
				if not sha then
					hShaList:AppendItemFromString('<shadow>name="' .. dwID .. '"</shadow>')
					sha = hShaList:Lookup(tostring(dwID))
				end
				local r, g, b, a = 255,255,255,255
				local szTip = '> ' .. tar.szName .. ' <'
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(dwID, false, r, g, b, a, 0, 40, szTip, 0, 1)
				sha:Show()
			end
		end
		local function OnPlayerLeave(dwID)
			if not D.bReady then
				X.DelayCall(500, function() OnPlayerLeave(dwID) end)
				return
			end
			if O.bTongMemberNav and Navigator_Remove then
				Navigator_Remove('MY_GUILDMEMBER_TIP.' .. dwID)
			else
				local sha = hShaList:IsValid() and hShaList:Lookup(tostring(dwID))
				if sha then
					sha:Hide()
					table.insert(hShaList.freeShadows, sha)
				end
			end
		end
		for _, p in ipairs(X.GetNearPlayer()) do
			OnPlayerEnter(p.dwID)
		end
		X.RegisterEvent('ON_ISOLATED', 'MY_GUILDMEMBER_TIP', function(event)
			-- dwCharacterID, nIsolated
			local me = GetClientPlayer()
			if arg0 == UI_GetClientPlayerID() then
				for _, p in ipairs(X.GetNearPlayer()) do
					if X.IsIsolated(p) == X.IsIsolated(me) then
						OnPlayerEnter(p.dwID)
					else
						OnPlayerLeave(p.dwID)
					end
				end
			else
				local tar = GetPlayer(arg0)
				if tar then
					if X.IsIsolated(tar) == X.IsIsolated(me) then
						OnPlayerEnter(arg0)
					else
						OnPlayerLeave(arg0)
					end
				end
			end
		end)
		X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_GUILDMEMBER_TIP', function(event) OnPlayerEnter(arg0) end)
		X.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_GUILDMEMBER_TIP', function(event) OnPlayerLeave(arg0) end)
	else
		X.RegisterEvent('ON_ISOLATED', 'MY_GUILDMEMBER_TIP', false)
		X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_GUILDMEMBER_TIP', false)
		X.RegisterEvent('PLAYER_LEAVE_SCENE', 'MY_GUILDMEMBER_TIP', false)
		X.UI.GetShadowHandle('MY_TongMemberHeadTip'):Hide()
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_FooterTip', function()
	D.bReady = true
	D.Apply()
end)
X.RegisterEvent('LOADING_ENDING', 'MY_FooterTip', D.Apply)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	-- ���Ѹ���
	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Friend headtop tips'],
		checked = MY_FooterTip.bFriend,
		onCheck = function(bCheck)
			MY_FooterTip.bFriend = not MY_FooterTip.bFriend
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Friend headtop hide in dungeon'],
		checked = MY_FooterTip.bFriendDungeonHide,
		onCheck = function(bCheck)
			MY_FooterTip.bFriendDungeonHide = not MY_FooterTip.bFriendDungeonHide
		end,
		autoEnable = function() return MY_FooterTip.bFriend end,
	}):Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Friend headtop tips nav'],
		checked = MY_FooterTip.bFriendNav,
		onCheck = function(bCheck)
			MY_FooterTip.bFriendNav = not MY_FooterTip.bFriendNav
		end,
		autoEnable = function() return MY_FooterTip.bFriend end,
	}):Width() + 5
	nY = nY + nLH

	-- ������
	nX = nPaddingX
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Tong member headtop tips'],
		checked = MY_FooterTip.bTongMember,
		onCheck = function(bCheck)
			MY_FooterTip.bTongMember = not MY_FooterTip.bTongMember
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Tong member headtop hide in dungeon'],
		checked = MY_FooterTip.bTongMemberDungeonHide,
		onCheck = function(bCheck)
			MY_FooterTip.bTongMemberDungeonHide = not MY_FooterTip.bTongMemberDungeonHide
		end,
		autoEnable = function() return MY_FooterTip.bTongMember end,
	}):Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Tong member headtop tips nav'],
		checked = MY_FooterTip.bTongMemberNav,
		onCheck = function(bCheck)
			MY_FooterTip.bTongMemberNav = not MY_FooterTip.bTongMemberNav
		end,
		autoEnable = function() return MY_FooterTip.bTongMember end,
	}):Width() + 5
	nY = nY + nLH
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_FooterTip',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bFriend',
				'bFriendNav',
				'bFriendDungeonHide',
				'bTongMember',
				'bTongMemberNav',
				'bTongMemberDungeonHide',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bFriend',
				'bFriendNav',
				'bFriendDungeonHide',
				'bTongMember',
				'bTongMemberNav',
				'bTongMemberDungeonHide',
			},
			triggers = {
				bFriend = D.Apply,
				bFriendNav = D.Apply,
				bFriendDungeonHide = D.Apply,
				bTongMember = D.Apply,
				bTongMemberNav = D.Apply,
				bTongMemberDungeonHide = D.Apply,
			},
			root = O,
		},
	},
}
MY_FooterTip = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
