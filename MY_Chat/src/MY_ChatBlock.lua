--------------------------------------------
-- @Desc  : ���츨��
-- @Author: ���� @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2016-12-29 14:24:10
--------------------------------------------
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatBlock'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------
local TALK_CHANNEL_MSG_TYPE = {
	[PLAYER_TALK_CHANNEL.NEARBY       ] = 'MSG_NORMAL'        ,
	[PLAYER_TALK_CHANNEL.SENCE        ] = 'MSG_MAP'           ,
	[PLAYER_TALK_CHANNEL.WORLD        ] = 'MSG_WORLD'         ,
	[PLAYER_TALK_CHANNEL.TEAM         ] = 'MSG_PARTY'         ,
	[PLAYER_TALK_CHANNEL.RAID         ] = 'MSG_TEAM'          ,
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD ] = 'MSG_BATTLE_FILED'  ,
	[PLAYER_TALK_CHANNEL.TONG         ] = 'MSG_GUILD'         ,
	[PLAYER_TALK_CHANNEL.FORCE        ] = 'MSG_SCHOOL'        ,
	[PLAYER_TALK_CHANNEL.CAMP         ] = 'MSG_CAMP'          ,
	[PLAYER_TALK_CHANNEL.WHISPER      ] = 'MSG_WHISPER'       ,
	[PLAYER_TALK_CHANNEL.FRIENDS      ] = 'MSG_FRIEND'        ,
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = 'MSG_GUILD_ALLIANCE',
	[PLAYER_TALK_CHANNEL.LOCAL_SYS    ] = 'MSG_SYS'           ,
}
local MSG_TYPE_TALK_CHANNEL = X.FlipObjectKV(TALK_CHANNEL_MSG_TYPE)

local DEFAULT_KW_CONFIG = {
	szKeyword = '',
	tMsgType = {
		['MSG_NORMAL'        ] = true,
		['MSG_MAP'           ] = true,
		['MSG_WORLD'         ] = true,
		['MSG_SCHOOL'        ] = true,
		['MSG_CAMP'          ] = true,
		['MSG_WHISPER'       ] = true,
	},
	bIgnoreAcquaintance = true,
	bIgnoreCase = true, bIgnoreEnEm = true, bIgnoreSpace = true,
}

local O = X.CreateUserSettingsModule('MY_ChatBlock', _L['Chat'], {
	bBlockWords = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatBlock'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	aBlockWords = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_ChatBlock'],
		xSchema = X.Schema.Collection(X.Schema.Record({
			uuid = X.Schema.Optional(X.Schema.String),
			szKeyword = X.Schema.String,
			tMsgType = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
			bIgnoreAcquaintance = X.Schema.Boolean,
			bIgnoreCase = X.Schema.Boolean,
			bIgnoreEnEm = X.Schema.Boolean,
			bIgnoreSpace = X.Schema.Boolean,
		})),
		xDefaultValue = {},
	},
})
local D = {}

function D.IsBlockMsg(szText, szMsgType, dwTalkerID)
	local bAcquaintance = dwTalkerID
		and (X.GetFriend(dwTalkerID) or X.GetFoe(dwTalkerID) or X.GetTongMember(dwTalkerID))
		or false
	for _, bw in ipairs(D.aBlockWords) do
		if bw.tMsgType[szMsgType] and (not bAcquaintance or not bw.bIgnoreAcquaintance)
		and X.StringSimpleMatch(szText, bw.szKeyword, not bw.bIgnoreCase, not bw.bIgnoreEnEm, bw.bIgnoreSpace) then
			return true
		end
	end
	return false
end

function D.OnTalkFilter(nChannel, t, dwTalkerID, szName, bEcho, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
	local szType = TALK_CHANNEL_MSG_TYPE[nChannel]
	if not szType then
		return
	end
	local szText = X.StringifyChatText(t)
	if D.IsBlockMsg(szText, szType, dwTalkerID) then
		return true
	end
end

function D.OnMsgFilter(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName)
	if D.IsBlockMsg(bRich and GetPureText(szMsg) or szMsg, szType, dwTalkerID) then
		return true
	end
end

function D.CheckEnable()
	UnRegisterTalkFilter(D.OnTalkFilter)
	UnRegisterMsgFilter(D.OnMsgFilter)
	if not D.bReady or not D.aBlockWords or not O.bBlockWords then
		return
	end
	local tChannel, tMsgType = {}, {}
	for _, bw in ipairs(D.aBlockWords) do
		for szType, bEnable in pairs(bw.tMsgType) do
			if bEnable then
				if MSG_TYPE_TALK_CHANNEL[szType] then
					tChannel[MSG_TYPE_TALK_CHANNEL[szType]] = true
				end
				tMsgType[szType] = true
			end
		end
	end
	local aChannel, aMsgType = {}, {}
	for k, _ in pairs(tChannel) do
		table.insert(aChannel, k)
	end
	for k, _ in pairs(tMsgType) do
		table.insert(aMsgType, k)
	end
	if not X.IsEmpty(aChannel) then
		RegisterTalkFilter(D.OnTalkFilter, aChannel)
	end
	if not X.IsEmpty(aMsgType) then
		RegisterMsgFilter(D.OnMsgFilter, aMsgType)
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatBlock', function()
	D.bReady = true
	D.aBlockWords = O.aBlockWords
	D.CheckEnable()
end)
X.RegisterUserSettingsUpdate('@@UNINIT@@', 'MY_ChatBlock', function()
	D.bReady = false
	D.CheckEnable()
end)

-- Global exports
do
local settings = {
	name = 'MY_ChatBlock',
	exports = {
		{
			fields = {
				'bBlockWords',
			},
			root = O,
		},
	},
}
MY_ChatBlock = X.CreateModule(settings)
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 0, 0

	ui:Append('WndCheckBox', {
		x = x, y = y, w = 70,
		text = _L['Enable'],
		checked = O.bBlockWords,
		oncheck = function(bCheck)
			O.bBlockWords = bCheck
			D.CheckEnable()
		end,
	})
	x = x + 70

	local edit = ui:Append('WndEditBox', {
		name = 'WndEditBox_Keyword',
		x = x, y = y, w = w - 160 - x, h = 25,
		placeholder = _L['Type keyword, right click list to config.'],
	})
	x, y = 0, y + 30

	local aBlockWords = O.aBlockWords
	local function SeekBlockWord(uuid)
		for i = #aBlockWords, 1, -1 do
			if aBlockWords[i].uuid == uuid then
				return aBlockWords[i]
			end
		end
	end

	local function RemoveBlockWord(uuid)
		for i = #aBlockWords, 1, -1 do
			if aBlockWords[i].uuid == uuid then
				table.remove(aBlockWords, i)
			end
		end
	end

	local list = ui:Append('WndListBox', { x = x, y = y, w = w, h = h - 30 })
	local function ReloadBlockWords()
		O('reload', {'aBlockWords'})
		aBlockWords = O.aBlockWords

		local bSave = false
		for _, bw in ipairs(aBlockWords) do
			if not bw.uuid then
				bw.uuid = X.GetUUID()
				bSave = true
			end
		end
		if bSave then
			O.aBlockWords = aBlockWords
		end
		aBlockWords = O.aBlockWords

		D.aBlockWords = aBlockWords
		D.CheckEnable()

		local tSelected = {}
		for _, v in ipairs(list:ListBox('select', 'selected')) do
			if v.selected and v.id then
				tSelected[v.id] = true
			end
		end
		list:ListBox('clear')
		for _, bw in ipairs(aBlockWords) do
			list:ListBox('insert', {
				id = bw.uuid,
				text = bw.szKeyword,
				data = bw,
				selected = tSelected[bw.uuid],
			})
		end
	end
	ReloadBlockWords()

	local function SaveBlockWords()
		O.aBlockWords = aBlockWords
		ReloadBlockWords()
	end

	list:ListBox('onmenu', function(id, text, data)
		local menu = X.GetMsgTypeMenu(function(szType)
			local bw = SeekBlockWord(id)
			if bw then
				if bw.tMsgType[szType] then
					bw.tMsgType[szType] = nil
				else
					bw.tMsgType[szType] = true
				end
				SaveBlockWords()
			end
		end, data.tMsgType)
		table.insert(menu, 1, CONSTANT.MENU_DIVIDER)
		table.insert(menu, 1, {
			szOption = _L['Edit'],
			fnAction = function()
				GetUserInput(_L['Please input keyword:'], function(szText)
					szText = X.TrimString(szText)
					if X.IsEmpty(szText) then
						return
					end
					local bw = SeekBlockWord(id)
					if bw then
						bw.szKeyword = szText
						SaveBlockWords()
					end
				end, nil, nil, nil, data.szKeyword)
			end,
		})
		table.insert(menu, CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Ignore spaces'],
			bCheck = true, bChecked = data.bIgnoreSpace,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreSpace = not bw.bIgnoreSpace
					SaveBlockWords()
				end
			end,
		})
		table.insert(menu, {
			szOption = _L['Ignore enem'],
			bCheck = true, bChecked = data.bIgnoreEnEm,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreEnEm = not bw.bIgnoreEnEm
					SaveBlockWords()
				end
			end,
		})
		table.insert(menu, {
			szOption = _L['Ignore case'],
			bCheck = true, bChecked = data.bIgnoreCase,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreCase = not bw.bIgnoreCase
					SaveBlockWords()
				end
			end,
		})
		table.insert(menu, {
			szOption = _L['Ignore acquaintance'],
			bCheck = true, bChecked = data.bIgnoreAcquaintance,
			fnAction = function()
				local bw = SeekBlockWord(id)
				if bw then
					bw.bIgnoreAcquaintance = not bw.bIgnoreAcquaintance
					SaveBlockWords()
				end
			end,
		})
		table.insert(menu, CONSTANT.MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['Delete'],
			fnAction = function()
				RemoveBlockWord(id)
				SaveBlockWords()
				UI.ClosePopupMenu()
			end,
		})
		menu.szOption = _L['Channels']
		return menu
	end):ListBox('onlclick', function(id, text, data, selected)
		edit:Text(text)
	end)
	-- add
	ui:Append('WndButton', {
		x = w - 160, y=  0, w = 80,
		text = _L['Add'],
		onclick = function()
			local szText = X.TrimString(edit:Text())
			if X.IsEmpty(szText) then
				return
			end
			O('reload', {'aBlockWords'})
			local bw = X.Clone(DEFAULT_KW_CONFIG)
			bw.uuid = X.GetUUID()
			bw.szKeyword = szText
			table.insert(aBlockWords, 1, bw)
			SaveBlockWords()
		end,
	})
	-- del
	ui:Append('WndButton', {
		x = w - 80, y =  0, w = 80,
		text = _L['Delete'],
		onclick = function()
			O('reload', {'aBlockWords'})
			for _, v in ipairs(list:ListBox('select', 'selected')) do
				RemoveBlockWord(v.id)
			end
			SaveBlockWords()
		end,
	})
end
X.RegisterPanel(_L['Chat'], 'MY_ChatBlock', _L['MY_ChatBlock'], 'UI/Image/Common/Money.UITex|243', PS)
