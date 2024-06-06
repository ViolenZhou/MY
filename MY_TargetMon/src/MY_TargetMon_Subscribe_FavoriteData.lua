--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Ŀ���ض�������
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TargetMon/MY_TargetMon_Subscribe_FavoriteData'
local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.3') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {
	GetRawURL          = MY_TargetMon_Subscribe_Data.GetRawURL         ,
	GetBlobURL         = MY_TargetMon_Subscribe_Data.GetBlobURL        ,
	GetShortURL        = MY_TargetMon_Subscribe_Data.GetShortURL       ,
	GetAttachRawURL    = MY_TargetMon_Subscribe_Data.GetAttachRawURL   ,
	GetAttachBlobURL   = MY_TargetMon_Subscribe_Data.GetAttachBlobURL  ,
	IsDownloading      = MY_TargetMon_Subscribe_Data.IsDownloading     ,
	IsSubscripted      = MY_TargetMon_Subscribe_Data.IsSubscripted     ,
	Subscribe          = MY_TargetMon_Subscribe_Data.Subscribe         ,
	Unsubscribe        = MY_TargetMon_Subscribe_Data.Unsubscribe       ,
	FetchSubscribeItem = MY_TargetMon_Subscribe_Data.FetchSubscribeItem,
	SyncTeam           = MY_TargetMon_Subscribe_Data.SyncTeam          ,
}

local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_TargetMon/ui/MY_TargetMon_Subscribe_FavoriteData.ini'
local DATA_SELECTED_KEY
local META_DOWNLOADING = {}

function D.Load()
	return X.LoadLUAData({'userdata/target_mon/metalist.jx3dat', X.PATH_TYPE.GLOBAL}) or {}
end

function D.Save(aMetaInfo)
	X.SaveLUAData({'userdata/target_mon/metalist.jx3dat', X.PATH_TYPE.GLOBAL}, aMetaInfo)
	FireUIEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__LIST_UPDATE')
end

function D.Add(info, szReplaceKey)
	local aMetaInfo = D.Load()
	local nIndex
	if szReplaceKey then
		for i, p in X.ipairs_r(aMetaInfo) do
			if p.szKey == szReplaceKey then
				table.remove(aMetaInfo, i)
				nIndex = i
			end
		end
	end
	for i, p in X.ipairs_r(aMetaInfo) do
		if p.szKey == info.szKey then
			table.remove(aMetaInfo, i)
			nIndex = i
		end
	end
	if nIndex then
		table.insert(aMetaInfo, nIndex, info)
	else
		table.insert(aMetaInfo, info)
	end
	D.Save(aMetaInfo)
end

function D.Remove(info)
	-- if info.bEmbedded then
	-- 	X.OutputAnnounceMessage(_L['Embedded dataset cannot be removed!'])
	-- 	return
	-- end
	X.Confirm(_L['Confirm?'], function()
		local aMetaInfo = D.Load()
		for i, p in X.ipairs_r(aMetaInfo) do
			if p.szKey == info.szKey then
				table.remove(aMetaInfo, i)
			end
		end
		if DATA_SELECTED_KEY == info.szKey then
			DATA_SELECTED_KEY = nil
		end
		D.Save(aMetaInfo)
	end)
end

function D.Fetch()
	for _, info in ipairs(D.Load()) do
		META_DOWNLOADING[info.szKey] = true
		D.FetchSubscribeItem(info.szURL)
			:Then(function(res)
				D.Add(res, info.szKey)
				META_DOWNLOADING[info.szKey] = nil
				FireUIEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__FETCH_UPDATE')
			end)
			:Catch(function(err)
				X.OutputDebugMessage(
					_L['MY_TargetMon_Subscribe_FavoriteData'],
					err.message ..'\n' ..  info.szURL,
					X.DEBUG_LEVEL.WARNING)
				META_DOWNLOADING[info.szKey] = nil
				FireUIEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__FETCH_UPDATE')
			end)
	end
	FireUIEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__FETCH_UPDATE')
end

function D.GetSelectedInfo()
	if not DATA_SELECTED_KEY then
		return
	end
	for _, info in ipairs(D.Load()) do
		if info.szKey == DATA_SELECTED_KEY then
			return info
		end
	end
end

function D.UpdateList(page)
	if not page or not page:IsValid() then
		return
	end
	local szSel, bExistSelect = DATA_SELECTED_KEY, false
	local container = page:Lookup('Wnd_Total/WndScroll_Subscribe/WndContainer_Subscribe')
	container:Clear()
	for _, info in ipairs(D.Load()) do
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
		local bIsSubscripted, bIsLatest = D.IsSubscripted(info)
		if D.IsSubscripted(info) then
			X.UI(wnd):Append('WndButton', {
				name = 'Btn_Unsubscribe',
				x = 765, y = 1, w = 90, h = 30,
				buttonStyle = 'SKEUOMORPHISM',
				text = _L['Unsubscribe'],
				onClick = function() D.Unsubscribe(info) end,
			})
		end
		X.UI(wnd):Append('WndButton', {
			name = 'Btn_Download',
			x = 860, y = 1, w = 90, h = 30,
			buttonStyle = 'SKEUOMORPHISM',
			text = (META_DOWNLOADING[info.szKey] and _L['Fetching...'])
				or (D.IsDownloading(info.szKey) and _L['Downloading...'])
				or (bIsSubscripted and (
					bIsLatest
						and _L['Subscribed']
						or _L['Can update']))
				or _L['Subscribe'],
			enable = not META_DOWNLOADING[info.szKey] and not D.IsDownloading(info.szKey),
			onClick = function() D.Subscribe(info) end,
		})
		wnd.info = info
	end
	if not bExistSelect then
		page.szMetaInfoKeySel = nil
	end
	container:FormatAllContentPos()
end

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(INI_PATH, 'MY_TargetMon_Subscribe_FavoriteData')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	wnd:SetRelPos(0, 0)
	X.UI.CloseFrame(frameTemp)

	wnd:Lookup('', 'Text_Break1'):SetText(_L['Author'])
	wnd:Lookup('', 'Text_Break2'):SetText(_L['Title'])
	wnd:Lookup('Btn_SyncTeam', 'Text_SyncTeam'):SetText(_L['Sync team'])
	wnd:Lookup('Btn_CheckUpdate', 'Text_CheckUpdate'):SetText(_L['Check update'])
	wnd:Lookup('Btn_AddUrl', 'Text_AddUrl'):SetText(_L['Add url'])
	wnd:Lookup('Btn_RemoveUrl', 'Text_RemoveUrl'):SetText(_L['Remove url'])
	wnd:Lookup('Btn_ExportUrl', 'Text_ExportUrl'):SetText(_L['Export meta url'])

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__LIST_UPDATE')
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__FETCH_UPDATE')
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE')
	frame:RegisterEvent('MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE')

	D.UpdateList(this)
end

function D.OnActivePage()
end

function D.OnEvent(event)
	if event == 'MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__LIST_UPDATE'
	or event == 'MY_TARGET_MON__SUBSCRIBE_FAVORITE_DATA__FETCH_UPDATE'
	or event == 'MY_TARGET_MON__SUBSCRIBE_DATA__DOWNLOAD_UPDATE'
	or event == 'MY_TARGET_MON__SUBSCRIBE_DATA__SUBSCRIBE_UPDATE' then
		D.UpdateList(this)
	end
end

function D.OnFrameDestroy()
	DATA_SELECTED_KEY = nil
end

function D.OnLButtonClick()
	local name = this:GetName()
	local frame = this:GetRoot()
	if name == 'Btn_AddUrl' then
		GetUserInput(_L['Please input meta address:'], function(szText)
			local aURL = X.SplitString(szText, ';')
			local nPending = 0
			local aErrmsg = {}
			local function ProcessQueue()
				nPending = nPending + 1
				local szURL = aURL[nPending]
				if not szURL then
					if #aErrmsg > 0 then
						X.Alert(table.concat(aErrmsg, '\n'))
					end
					return
				end
				D.FetchSubscribeItem(szURL)
					:Then(function(info)
						D.Add(info)
						ProcessQueue()
					end)
					:Catch(function(error)
						if error then
							table.insert(aErrmsg, error.message)
						end
						ProcessQueue()
					end)
			end
			ProcessQueue()
		end)
	elseif name == 'Btn_RemoveUrl' then
		local info = D.GetSelectedInfo()
		if not info then
			return X.OutputAnnounceMessage(_L['Please select one dataset first!'])
		end
		D.Remove(info)
	elseif name == 'Btn_ExportUrl' then
		local aMetaInfoURL = {}
		for _, info in ipairs(D.Load()) do
			table.insert(aMetaInfoURL, D.GetShortURL(info.szURL) or D.GetRawURL(info.szURL))
		end
		X.UI.OpenTextEditor(table.concat(aMetaInfoURL, ';'))
	elseif name == 'Btn_Info' then
		X.OpenBrowser(this:GetParent().info.szAboutURL)
	elseif name == 'Btn_SyncTeam' then
		D.SyncTeam(D.GetSelectedInfo())
	elseif name == 'Btn_CheckUpdate' then
		D.Fetch()
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

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local t = {{
			szOption = _L['Copy meta url'],
			fnAction = function()
				X.UI.OpenTextEditor(wnd.info.szURL)
			end,
		}}
		local szShortURL = D.GetShortURL(wnd.info.szURL)
		if szShortURL then
			table.insert(t, {
				szOption = _L['Copy short meta url'],
				fnAction = function()
					X.UI.OpenTextEditor(szShortURL)
				end,
			})
		end
		table.insert(t, {
			szOption = _L['Sync team'],
			fnAction = function()
				D.SyncTeam(wnd.info)
			end,
		})
		PopupMenu(t)
	end
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent()
		local szTip = ''
		if not X.IsEmpty(wnd.info.szURL) then
			szTip = szTip .. _L('MetaInfo URL: %s', wnd.info.szURL)
		end
		local szShortURL = D.GetShortURL(wnd.info.szURL)
		if not X.IsEmpty(szShortURL) then
			szTip = szTip .. _L('(Short URL: %s)', szShortURL)
		end
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
-- ģ�鵼��
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMon_Subscribe_FavoriteData',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
			},
			root = D,
		},
	},
}
MY_TargetMon_Subscribe.RegisterModule('FavoriteData', _L['Favorite list'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TargetMon_Subscribe_FavoriteData',
	exports = {
		{
			root = D,
			fields = {
				'Load',
				'Save',
				'Add',
				'Remove',
				'Fetch',
			},
			preset = 'UIEvent',
		},
	},
}
MY_TargetMon_Subscribe_FavoriteData = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
