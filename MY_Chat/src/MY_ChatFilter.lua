--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �������
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
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_ChatFilter'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['Chat'], {
	bFilterDuplicate = { -- �����ظ�����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatFilter'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bFilterDuplicateIgnoreID = { -- ��ͬ����ظ�����Ҳ����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatFilter'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFilterDuplicateContinuous = { -- �������������ظ�����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatFilter'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bFilterDuplicateAddonTalk = { -- ����UUID��ͬ�Ĳ����Ϣ
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatFilter'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tApplyDuplicateChannels = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_ChatFilter'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {
			['MSG_SYS'           ] = false,
			['MSG_NORMAL'        ] = true,
			['MSG_PARTY'         ] = false,
			['MSG_MAP'           ] = true,
			['MSG_BATTLE_FILED'  ] = true,
			['MSG_GUILD'         ] = true,
			['MSG_GUILD_ALLIANCE'] = true,
			['MSG_SCHOOL'        ] = true,
			['MSG_WORLD'         ] = true,
			['MSG_TEAM'          ] = false,
			['MSG_CAMP'          ] = true,
			['MSG_GROUP'         ] = true,
			['MSG_WHISPER'       ] = false,
			['MSG_SEEK_MENTOR'   ] = true,
			['MSG_FRIEND'        ] = false,
		},
	},
})
local D = {}
local MAX_CHAT_RECORD = 10
local MAX_UUID_RECORD = 10

local l_tChannelHeader = {
	['MSG_WHISPER'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_NORMAL'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_NPC_NEARBY'] = g_tStrings.STR_TALK_HEAD_SAY,
	['MSG_PARTY'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_GUILD'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_GUILD_ALLIANCE'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_WORLD'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_SCHOOL'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_CAMP'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_FRIEND'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_TEAM'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_MAP'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_BATTLE_FILED'] = g_tStrings.STR_TALK_HEAD_SAY1,
	['MSG_NPC_PARTY'] = g_tStrings.STR_TALK_HEAD_SAY1,
}

X.HookChatPanel('FILTER', 'MY_ChatFilter', function(h, szMsg, szChannel, dwTime)
	local aXMLNode, aSay
	-- �����ϢUUID����
	if D.bReady and O.bFilterDuplicateAddonTalk then
		if not aXMLNode then
			aXMLNode = X.XMLDecode(szMsg)
			aSay = X.ParseChatData(aXMLNode)
		end
		if not h.MY_tDuplicateUUID then
			h.MY_tDuplicateUUID = {}
		end
		for _, element in ipairs(aSay) do
			if element.type == 'eventlink' and element.name == '' then
				local data = X.DecodeJSON(element.linkinfo)
				if data and data.uuid then
					local szUUID = data.uuid
					if szUUID then
						for k, uuid in pairs(h.MY_tDuplicateUUID) do
							if uuid == szUUID then
								return false
							end
						end
						table.insert(h.MY_tDuplicateUUID, 1, szUUID)
						local nCount = #h.MY_tDuplicateUUID - MAX_UUID_RECORD
						if nCount > 0 then
							for i = nCount, 1, -1 do
								table.remove(h.MY_tDuplicateUUID)
							end
						end
					end
				end
			end
		end
	end
	-- �ظ�����ˢ�����Σ�ϵͳƵ�����⣩
	if szChannel == 'MSG_SYS' and X.ContainsEchoMsgHeader(szMsg) then
		if not aXMLNode then
			aXMLNode = X.XMLDecode(szMsg)
			aSay = X.ParseChatData(aXMLNode)
		end
		local bHasEcho, szEchoChannel = X.DecodeEchoMsgHeader(aXMLNode)
		if bHasEcho and szEchoChannel then
			szChannel = szEchoChannel
		end
	end
	if D.bReady and O.bFilterDuplicate and O.tApplyDuplicateChannels[szChannel] then
		if not aXMLNode then
			aXMLNode = X.XMLDecode(szMsg)
			aSay = X.ParseChatData(aXMLNode)
		end
		-- �������촿�ַ���
		local szText = X.StringifyChatText(aSay)
		-- ��������������
		local szName = ''
		if l_tChannelHeader[szChannel] then
			local nS, nE = wstring.find(szText, l_tChannelHeader[szChannel])
			if nS and nE then
				szName = ''
				szText:sub(1, nE):gsub('(%[[^%[%]]-%])', function(s)
					szName = szName .. s
				end)
				szText = szText:sub(nE + 1)
			end
		end
		szText = szText:gsub('[ \n]', '')
		-- �ж��Ƿ����ַ�����
		if not O.bFilterDuplicateIgnoreID then
			szText = szName .. ':' .. szText
		end
		-- �ж��Ƿ���Ҫ����
		if not h.MY_tDuplicateLog then
			h.MY_tDuplicateLog = {}
		elseif O.bFilterDuplicateContinuous then
			if h.MY_tDuplicateLog[1] == szText then
				return false
			end
			h.MY_tDuplicateLog[1] = szText
		else
			for i, szRecord in ipairs(h.MY_tDuplicateLog) do
				if szRecord == szText then
					return false
				end
			end
			table.insert(h.MY_tDuplicateLog, 1, szText)
			local nCount = #h.MY_tDuplicateLog - MAX_CHAT_RECORD
			if nCount > 0 then
				for i = nCount, 1, -1 do
					table.remove(h.MY_tDuplicateLog)
				end
			end
		end
	end
	return true
end)
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChatFilter', function() D.bReady = true end)

local PS = {}

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local x, y = 20, 30

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate chat'],
		x = x, y = y, w = 400,
		checked = O.bFilterDuplicate,
		oncheck = function(bCheck)
			O.bFilterDuplicate = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate chat ignore id'],
		x = x, y = y, w = 400,
		checked = O.bFilterDuplicateIgnoreID,
		oncheck = function(bCheck)
			O.bFilterDuplicateIgnoreID = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndCheckBox', {
		text = _L['only filter continuous duplicate chat'],
		x = x, y = y, w = 400,
		checked = O.bFilterDuplicateContinuous,
		oncheck = function(bCheck)
			O.bFilterDuplicateContinuous = bCheck
		end,
	})
	y = y + 30

	ui:Append('WndComboBox', {
		x = x, y = y, w = 330, h = 25,
		menu = function()
			local t = {}
			for szChannelID, bFilter in pairs(O.tApplyDuplicateChannels) do
				table.insert(t, {
					szOption = g_tStrings.tChannelName[szChannelID],
					bCheck = true, bChecked = bFilter,
					rgb = GetMsgFontColor(szChannelID, true),
					fnAction = function()
						O.tApplyDuplicateChannels[szChannelID] = not O.tApplyDuplicateChannels[szChannelID]
						O.tApplyDuplicateChannels = O.tApplyDuplicateChannels
					end,
				})
			end
			return t
		end,
		text = _L['select duplicate channels'],
	})
	y = y + 50

	ui:Append('WndCheckBox', {
		text = _L['filter duplicate addon message'],
		x = x, y = y, w = 400,
		checked = O.bFilterDuplicateAddonTalk,
		oncheck = function(bCheck)
			O.bFilterDuplicateAddonTalk = bCheck
		end,
	})
	y = y + 30
end

X.RegisterPanel(_L['Chat'], 'MY_DuplicateChatFilter', _L['duplicate chat filter'], 'ui/Image/UICommon/yirong3.UITex|104', PS)
