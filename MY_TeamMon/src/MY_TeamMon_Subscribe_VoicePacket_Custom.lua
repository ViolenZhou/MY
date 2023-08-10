--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ŶӼ�ض�������
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_Subscribe_VoicePacket_Custom'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^16.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_Subscribe_VoicePacket_Custom.ini'
local D = {}

local DATA_PAGINATION = {
	nIndex = 1,
	nSize = 30,
	nTotal = 0,
	nPageTotal = 1,
}
local DATA_LIST = {}
local DATA_SELECTED_KEY

function D.UpdateList(page)
	if not page or not page:IsValid() then
		return
	end
	local szSel, bExistSelect = DATA_SELECTED_KEY, false
	local dwCurrentPacketID, szVersion = MY_TeamMon_VoiceAlarm.GetCurrentPacketID('CUSTOM')
	local container = page:Lookup('Wnd_Total/WndScroll_Subscribe/WndContainer_Subscribe')
	container:Clear()
	for _, info in ipairs(DATA_LIST) do
		local bSel = szSel and info.szKey == szSel
		if bSel then
			bExistSelect = true
		end
		local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
		wnd:Lookup('', 'Text_Item_Author'):SetText(X.ReplaceSensitiveWord(info.szAuthor))
		wnd:Lookup('', 'Text_Item_Title'):SetText(X.ReplaceSensitiveWord(info.szTitle))
		wnd:Lookup('', 'Text_Item_Download'):SetText(X.ReplaceSensitiveWord(info.szUpdateTime))
		wnd:Lookup('', 'Image_Item_Sel'):SetVisible(bSel)
		if not X.IsEmpty(info.szAboutURL) then
			X.UI(wnd):Append('WndButton', {
				name = 'Btn_Info',
				x = 760, y = 1, w = 90, h = 30,
				buttonStyle = 'LINK',
				text = _L['See details'],
			})
		end
		local bIsSubscripted = info.dwID == dwCurrentPacketID
		local bIsSubscriptedCanUpdate = bIsSubscripted and info.szVersion ~= szVersion
		local fProgress = MY_TeamMon_VoiceAlarm.GetPacketDownloadProgress(info.dwID)
		X.UI(wnd):Append('WndButton', {
			name = 'Btn_Download',
			x = 860, y = 1, w = 90, h = 30,
			buttonStyle = 'SKEUOMORPHISM',
			text = (fProgress == 0 and _L['Downloading...'])
				or (fProgress and ('%.2f%%'):format(fProgress * 100))
				or (bIsSubscriptedCanUpdate and _L['Can update'])
				or (bIsSubscripted and _L['Current selected'])
				or _L['Select'],
			enable = not fProgress,
			onClick = function()
				if not fProgress and not bIsSubscriptedCanUpdate and bIsSubscripted then
					MY_TeamMon_VoiceAlarm.SetCurrentPacketID('CUSTOM', 0)
				else
					MY_TeamMon_VoiceAlarm.SetCurrentPacketID('CUSTOM', info.dwID)
				end
			end,
		})
		wnd.info = info
	end
	if not bExistSelect then
		page.szMetaInfoKeySel = nil
	end
	container:FormatAllContentPos()
	-- �Ƽ�ҳ��
	page:Lookup('Wnd_Total/Btn_PrevPage'):Enable(DATA_PAGINATION.nIndex > 1)
	page:Lookup('Wnd_Total/Btn_NextPage'):Enable(DATA_PAGINATION.nIndex < DATA_PAGINATION.nPageTotal)
	page:Lookup('Wnd_Total', 'Text_Page'):SetText(DATA_PAGINATION.nIndex .. ' / ' .. DATA_PAGINATION.nPageTotal)
end

function D.SwitchPage(nPage)
	MY_TeamMon_VoiceAlarm.FetchPacketList('CUSTOM', nPage)
		:Then(function(res)
			DATA_LIST = res.aPacket
			DATA_PAGINATION = res.tPagination
			FireUIEvent('MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__LIST_UPDATE')
		end)
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(INI_PATH, 'MY_TeamMon_Subscribe_VoicePacket_Custom')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	wnd:SetRelPos(0, 0)
	Wnd.CloseWindow(frameTemp)

	wnd:Lookup('', 'Text_Break1'):SetText(_L['Author'])
	wnd:Lookup('', 'Text_Break2'):SetText(_L['Title'])
	wnd:Lookup('Btn_CheckUpdate', 'Text_CheckUpdate'):SetText(_L['Refresh list'])
	wnd:Lookup('Btn_Preview', 'Text_Preview'):SetText(_L['Preview voice'])
	wnd:Lookup('Btn_PrevPage', 'Text_PrevPage'):SetText(_L['Prev page'])
	wnd:Lookup('Btn_NextPage', 'Text_NextPage'):SetText(_L['Next page'])

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__LIST_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__DOWNLOAD_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__SUBSCRIBE_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__VOICE_ALARM__CURRENT_PACKET_UPDATE')
	frame:RegisterEvent('MY_TEAM_MON__VOICE_ALARM__DOWNLOAD_PROGRESS')

	D.UpdateList(this)
	D.SwitchPage(1)
end

function D.OnActivePage()
end

function D.OnEvent(event)
	if event == 'MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__LIST_UPDATE'
	or event == 'MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__DOWNLOAD_UPDATE'
	or event == 'MY_TEAM_MON__SUBSCRIBE_VOICE_PACKET_CUSTOM__SUBSCRIBE_UPDATE'
	or event == 'MY_TEAM_MON__VOICE_ALARM__CURRENT_PACKET_UPDATE'
	or event == 'MY_TEAM_MON__VOICE_ALARM__DOWNLOAD_PROGRESS' then
		D.UpdateList(this)
	end
end

function D.OnFrameDestroy()
	DATA_SELECTED_KEY = nil
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_CheckUpdate' then
		D.SwitchPage(DATA_PAGINATION.nIndex)
	elseif name == 'Btn_Preview' then
		MY_TeamMon_VoiceAlarm_Previewer.Open('CUSTOM')
	elseif name == 'Btn_PrevPage' then
		D.SwitchPage(DATA_PAGINATION.nIndex - 1)
	elseif name == 'Btn_NextPage' then
		D.SwitchPage(DATA_PAGINATION.nIndex + 1)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local container = wnd:GetParent()
		for i = 0, container:GetAllContentCount() - 1 do
			local wnd = container:LookupContent(i)
			wnd:Lookup('', 'Image_Item_Sel'):Hide()
		end
		wnd:Lookup('', 'Image_Item_Sel'):Show()
		DATA_SELECTED_KEY = wnd.info.szKey
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local szTip = _L('Title: %s', X.ReplaceSensitiveWord(wnd.info.szTitle))
			.. '\n' .. _L('Author: %s', X.ReplaceSensitiveWord(wnd.info.szAuthor))
			.. '\n' .. _L('Update at: %s', X.ReplaceSensitiveWord(wnd.info.szUpdateTime))
		if IsCtrlKeyDown() then
			szTip = szTip .. '\n' .. X.EncodeLUAData(wnd.info, '  ')
		end
		if X.IsEmpty(szTip) then
			return
		end
		X.OutputTip(this, szTip)
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_Item' then
		HideTip()
	end
end

--------------------------------------------------------------------------------
-- Module exports
--------------------------------------------------------------------------------
-- do
-- local settings = {
-- 	name = 'MY_TeamMon_Subscribe_VoicePacket_Custom',
-- 	exports = {
-- 		{
-- 			preset = 'UIEvent',
-- 			fields = {
-- 				'OnInitPage',
-- 				'OnResizePage',
-- 			},
-- 			root = D,
-- 		},
-- 	},
-- }
-- MY_TeamMon_Subscribe.RegisterModule('Subscribe_VoicePacket_Custom', _L['Voice packet custom'], X.CreateModule(settings))
-- end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_Subscribe_VoicePacket_Custom',
	exports = {
		{
			root = D,
			fields = {
				'IsDownloading',
				'Subscribe',
			},
			preset = 'UIEvent',
		},
	},
}
MY_TeamMon_Subscribe_VoicePacket_Custom = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
