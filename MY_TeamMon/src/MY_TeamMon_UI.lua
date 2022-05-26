--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ŶӼ�ؽ���
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_UI'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^13.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local ParseCustomText        = MY_TeamMon.ParseCustomText
local FilterCustomText       = MY_TeamMon.FilterCustomText
local MY_TM_TYPE             = MY_TeamMon.MY_TM_TYPE
local MY_TM_SCRUTINY_TYPE    = MY_TeamMon.MY_TM_SCRUTINY_TYPE
local MY_TM_REMOTE_DATA_ROOT = MY_TeamMon.MY_TM_REMOTE_DATA_ROOT
local MY_TM_SPECIAL_MAP      = MY_TeamMon.MY_TM_SPECIAL_MAP
local MY_TMUI_INIFILE        = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI.ini'
local MY_TMUI_ITEM_L         = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_ITEM_L.ini'
local MY_TMUI_TALK_L         = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_TALK_L.ini'
local MY_TMUI_ITEM_R         = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_ITEM_R.ini'
local MY_TMUI_TALK_R         = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_UI_TALK_R.ini'
local MY_TMUI_TYPE           = { 'BUFF', 'DEBUFF', 'CASTING', 'NPC', 'DOODAD', 'TALK', 'CHAT' }
local MY_TMUI_SELECT_TYPE    = MY_TMUI_TYPE[1]
local MY_TMUI_SELECT_MAP     = _L['All data']
local MY_TMUI_TREE_EXPAND    = { [_L['All']] = true } -- Ĭ�ϵ�һ��չ��
local MY_TMUI_ITEM_PER_PAGE  = 27
local MY_TMUI_SEARCH
local MY_TMUI_MAP_SEARCH
local MY_TMUI_DRAG           = false
local MY_TMUI_GLOBAL_SEARCH  = false
local MY_TMUI_SEARCH_CACHE   = {}
local MY_TMUI_PANEL_ANCHOR   = { s = 'CENTER', r = 'CENTER', x = 0, y = 0 }
local MY_TMUI_ANCHOR         = {}
local CHECKBOX_HEIGHT        = 30
local BUTTON2_HEIGHT         = 30
local D = {}

local MY_TMUI_DOODAD_ICON = {
	[DOODAD_KIND.INVALID     ] = 1434, -- ��Ч
	[DOODAD_KIND.NORMAL      ] = 4956,
	[DOODAD_KIND.CORPSE      ] = 179 , -- ʬ��
	[DOODAD_KIND.QUEST       ] = 1676, -- ����
	[DOODAD_KIND.READ        ] = 243 , -- �Ķ�
	[DOODAD_KIND.DIALOG      ] = 3267, -- �Ի�
	[DOODAD_KIND.ACCEPT_QUEST] = 1678, -- ��������
	[DOODAD_KIND.TREASURE    ] = 3557, -- ����
	[DOODAD_KIND.ORNAMENT    ] = 1395, -- װ����
	[DOODAD_KIND.CRAFT_TARGET] = 351 ,
	[DOODAD_KIND.CHAIR       ] = 3912, -- ����
	[DOODAD_KIND.CLIENT_ONLY ] = 240 ,
	[DOODAD_KIND.GUIDE       ] = 885 , -- ·��
	[DOODAD_KIND.DOOR        ] = 1890, -- ��
	[DOODAD_KIND.NPCDROP     ] = 381 ,
}
setmetatable(MY_TMUI_DOODAD_ICON, { __index = function(me, key)
	--[[#DEBUG BEGIN]]
	X.Debug(_L['MY_TeamMon'], 'Unknown Kind: ' .. key, X.DEBUG_LEVEL.WARNING)
	--[[#DEBUG END]]
	return 369
end })

local function OpenDragPanel(el)
	local frame = Wnd.OpenWindow(X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_DRAG.ini', 'MY_TeamMon_DRAG')
	local x, y = Cursor.GetPos()
	local w, h = el:GetSize()
	-- local x, y = el:GetAbsPos()
	frame.szName = this:GetName()
	frame:SetAbsPos(x, y)
	frame:StartMoving()
	frame.data = el.dat
	local szName = D.GetDataName(MY_TMUI_SELECT_TYPE, el.dat)
	frame:Lookup('', 'Text'):SetText(szName or el.dat.key)
	frame:SetSize(w, h)
	frame:Lookup('', 'Image'):SetSize(w, h)
	frame:Lookup('', 'Text'):SetSize(w, h)
	frame:Lookup('', ''):FormatAllItemPos()
	frame:BringToTop()
	MY_TMUI_DRAG = true
end

local function CloseDragPanel()
	local frame = Station.Lookup('Normal1/MY_TeamMon_DRAG')
	if frame then
		frame:EndMoving()
		Wnd.CloseWindow(frame)
		return frame.data, frame.szName
	end
end

local function DragPanelIsOpened()
	return Station.Lookup('Normal1/MY_TeamMon_DRAG') and Station.Lookup('Normal1/MY_TeamMon_DRAG'):IsVisible()
end

function D.OnFrameCreate()
	this:RegisterEvent('MY_TMUI_TEMP_UPDATE')
	this:RegisterEvent('MY_TMUI_TEMP_RELOAD')
	this:RegisterEvent('MY_TMUI_DATA_RELOAD')
	this:RegisterEvent('MY_TMUI_SELECT_MAP')
	this:RegisterEvent('UI_SCALED')
	-- Esc
	X.RegisterEsc('MY_TeamMon', D.IsOpened, D.ClosePanel)
	-- CreateItemData
	this.hItemL = this:CreateItemData(MY_TMUI_ITEM_L, 'Handle_L')
	this.hTalkL = this:CreateItemData(MY_TMUI_TALK_L, 'Handle_TALK_L')
	this.hItemR = this:CreateItemData(MY_TMUI_ITEM_R, 'Handle_R')
	this.hTalkR = this:CreateItemData(MY_TMUI_TALK_R, 'Handle_TALK_R')
	-- tree
	this.hTreeN = this:CreateItemData(MY_TMUI_INIFILE, 'Handle_TreeNode')
	this.hTreeI = this:CreateItemData(MY_TMUI_INIFILE, 'Handle_TreeItem')
	this.hTreeH = this:Lookup('PageSet_Main/WndScroll_Tree', '')
	this.hTreeS = this:Lookup('PageSet_Main/WndScroll_Tree/Btn_Tree_All')

	MY_TMUI_SEARCH = nil -- ��������
	MY_TMUI_MAP_SEARCH = nil -- ��������
	MY_TMUI_GLOBAL_SEARCH = false
	MY_TMUI_DRAG = false

	this.hPageSet = this:Lookup('PageSet_Main')

	this:Lookup('PageSet_Main/Wnd_SearchMap/Edit_SearchMap'):SetPlaceholderText(_L['Search map'])
	this:Lookup('PageSet_Main/Wnd_SearchContent/Edit_SearchContent'):SetPlaceholderText(_L['Search content'])

	local ui = X.UI(this)
	ui:Text(_L['MY_TeamMon config panel'])
	for k, v in ipairs(MY_TMUI_TYPE) do
		this.hPageSet:Lookup('CheckBox_' .. v, 'Text_Page_' .. v):SetText(_L[v])
	end
	ui:Append('WndButton', {
		x = 900, y = 52, w = 140, h = 27,
		text = g_tStrings.SYS_MENU,
		buttonStyle = 'FLAT_LACE_BORDER',
		menu = function()
			local menu = {}
			table.insert(menu, { szOption = _L['Import data (local)'], fnAction = function() D.OpenImportPanel() end }) -- �д��� ��Ҫ��
			local szLang = X.ENVIRONMENT.GAME_LANG
			if szLang == 'zhcn' or szLang == 'zhtw' then
				table.insert(menu, { szOption = _L['Import data (web)'], fnAction = MY_TeamMon_RR.OpenPanel })
			end
			table.insert(menu, {
				szOption = _L['Clear data'],
				fnAction = function()
					D.RemoveData(nil, nil, _L['All data'])
				end,
			})
			table.insert(menu, { szOption = _L['Export data'], fnAction = D.OpenExportPanel })
			table.insert(menu, { szOption = _L['Open data folder'], fnAction = function()
				local szRoot = X.GetAbsolutePath(MY_TM_REMOTE_DATA_ROOT):gsub('/', '\\')
				X.OpenFolder(szRoot)
				X.UI.OpenTextEditor(szRoot)
			end })
			return menu
		end,
	})
	-- debug
	if X.IsDebugClient(true) then
		ui:Append('WndButton', { text = 'Reload', x = 10, y = 10, onClick = ReloadUIAddon })
		ui:Append('WndButton', {
			name = 'On', text = 'Enable', x = 110, y = 10, enable = not MY_TeamMon.bEnable,
			onClick = function()
				MY_TeamMon.bEnable = true
				this:Enable(false)
				ui:Children('#Off'):Enable(true)
			end,
		})
		ui:Append('WndButton', {
			name = 'Off', text = 'Disable', x = 210, y = 10, enable = MY_TeamMon.bEnable,
			onClick = function()
				MY_TeamMon.bEnable = false
				this:Enable(false)
				ui:Children('#On'):Enable(true)
			end,
		})
	end
	local uiPageSetMain = ui:Children('#PageSet_Main')
	uiPageSetMain:Append('WndCheckBox', {
		x = 575, y = 40, checked = MY_TMUI_GLOBAL_SEARCH, text = _L['Global search'],
		onCheck = function(bCheck)
			MY_TMUI_GLOBAL_SEARCH = bCheck
			FireUIEvent('MY_TMUI_TEMP_RELOAD')
			FireUIEvent('MY_TMUI_DATA_RELOAD')
		end,
	})
	uiPageSetMain:Append('WndButton', {
		x = 920, y = 40,
		text = _L['Clear record'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Confirm?'], function()
				MY_TeamMon.ClearTemp(MY_TMUI_SELECT_TYPE)
			end)
		end,
	})
	D.UpdateAnchor(this)
	-- �״μ���
	for k, v in ipairs(MY_TMUI_TYPE) do
		if MY_TMUI_SELECT_TYPE == v then
			this.hPageSet:ActivePage(k - 1)
			break
		end
	end
	D.ScrollMapIntoView(this)
end

function D.OnEvent(szEvent)
	if szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'MY_TMUI_TEMP_UPDATE' then
		if arg0 ~= MY_TMUI_SELECT_TYPE then
			return
		end
		D.UpdateRList(arg1)
	elseif szEvent == 'MY_TMUI_DATA_RELOAD' then
		D.RefreshTable(this, 'L')
	elseif szEvent == 'MY_TMUI_TEMP_RELOAD' then
		D.RefreshTable(this, 'R')
	elseif szEvent == 'MY_TMUI_SELECT_MAP' then
		MY_TMUI_SELECT_MAP = arg0
		D.UpdateMapList(this)
		D.ScrollMapIntoView(this)
	end
end

function D.OnFrameDragEnd()
	MY_TMUI_ANCHOR = GetFrameAnchor(this)
end

function D.RefreshTable(frame, szRefresh)
	if szRefresh == 'L' then
		D.UpdateLList()
		D.RedrawMapList(frame)
	elseif szRefresh == 'R' then
		D.UpdateRList()
	end
end
-- ����ˢ�¹����� ��ˢ������
function D.RefreshScroll(szRefresh)
	local frame = D.GetFrame()
	local szName = string.format('WndScroll_%s_%s/Btn_%s_%s_ALL', MY_TMUI_SELECT_TYPE, szRefresh, MY_TMUI_SELECT_TYPE, szRefresh)
	local hWndScroll = frame.hPageSet:GetActivePage():Lookup(szName)
	X.ExecuteWithThis(hWndScroll, D.OnScrollBarPosChanged)
end

function D.ConflictCheck()
	if MY_TMUI_SELECT_TYPE == 'BUFF' or MY_TMUI_SELECT_TYPE == 'DEBUFF'	or MY_TMUI_SELECT_TYPE == 'CASTING' then
		local data = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
		local bMsg = false
		for k, v in pairs(data) do
			if k ~= MY_TM_SPECIAL_MAP.RECYCLE_BIN then
				local tTemp = {}
				for kk, vv in ipairs(v) do
					tTemp[vv.dwID] = tTemp[vv.dwID] or {}
					table.insert(tTemp[vv.dwID], vv)
				end
				for kk, vv in pairs(tTemp) do
					if #vv > 1 then
						for kkk, vvv in ipairs(vv) do
							if not vvv.bCheckLevel then
								bMsg = true
								X.Sysmsg(
									_L['MY_TeamMon'],
									_L['Data conflict'] .. ' ' .. _L[MY_TMUI_SELECT_TYPE] .. ' '
										.. MY_TeamMon.GetMapName(k) .. ' :: ' .. vvv.dwID .. ' :: '
										.. (vvv.szName or D.GetDataName(MY_TMUI_SELECT_TYPE, vvv)),
									X.CONSTANT.MSG_THEME.ERROR)
								break
							end
						end
					end
				end
			end
		end
		if bMsg then
			X.Sysmsg(_L['MY_TeamMon'], _L['Data conflict, please check.'], X.CONSTANT.MSG_THEME.ERROR)
		end
	end
end

function D.OnActivePage()
	local nPage = this:GetActivePageIndex()
	local frame = this:GetRoot()
	MY_TMUI_SELECT_TYPE = MY_TMUI_TYPE[nPage + 1]
	D.RefreshTable(frame, 'L')
	D.RefreshTable(frame, 'R')
	FireUIEvent('MY_TMUI_SWITCH_PAGE')
	D.ConflictCheck()
	D.UpdateBG()
end

function D.UpdateBG()
	-- background
	local frame = D.GetFrame()
	local DungeonInfo = X.GetGameTable('DungeonInfo', true)
	local info = X.IsNumber(MY_TMUI_SELECT_MAP) and DungeonInfo and DungeonInfo:Search(MY_TMUI_SELECT_MAP)
	if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' and info and info.szDungeonImage2 then
		frame:Lookup('', 'Handle_BG'):Show()
		frame:Lookup('', 'Handle_BG/Image_BG'):FromUITex(info.szDungeonImage2, 0)
		frame:Lookup('', 'Handle_BG/Text_BgTitle'):SetText(info.szLayer3Name .. g_tStrings.STR_CONNECT .. info.szOtherName)
	else
		frame:Lookup('', 'Handle_BG'):Hide()
	end
end

function D.UpdateMapList(frame)
	local dwCurrentMapID, dwSelectMapID = X.GetMapID(), MY_TMUI_SELECT_MAP
	local hList, hTreeNode, hTreeItem = frame.hTreeH, nil
	for i = 0, hList:GetItemCount() - 1 do
		local el = hList:Lookup(i)
		if el:GetName() == 'Handle_TreeNode' then
			hTreeNode = el
			if hTreeNode.nCount == 0 then
				if not hTreeNode.col then
					hTreeNode.col = {hTreeNode:Lookup('Text_TreeNode'):GetFontColor()}
				end
				hTreeNode:Lookup('Text_TreeNode'):SetFontColor(222, 222, 222)
			end
			hTreeNode:Lookup('Image_TreeNodeLocation'):Hide()
		else
			hTreeItem = el
			if hTreeItem.nCount == 0 then
				if not hTreeItem.col then
					hTreeItem.col = {hTreeItem:Lookup('Text_TreeItem'):GetFontColor()}
				end
				hTreeItem:Lookup('Text_TreeItem'):SetFontColor(222, 222, 222)
			end
			if hTreeItem.dwMapID == dwCurrentMapID then
				hTreeNode:Lookup('Image_TreeNodeLocation'):Show()
			end
			hTreeItem:Lookup('Image_TreeItemBg_Sel'):SetVisible(hTreeItem.dwMapID == dwSelectMapID)
			hTreeItem:Lookup('Image_TreeItemLocation'):SetVisible(hTreeItem.dwMapID == dwCurrentMapID)
		end
	end
end

function D.RedrawMapList(frame)
	local data, aGroupMap = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE), {}
	-- ȫ��/����
	local tAll = {
		szGroup = _L['All'],
		aMapInfo = {
			_L['All data'], -- ȫ��
		},
	}
	table.insert(aGroupMap, tAll)
	-- ȫ��/����
	local tCommon = {
		szGroup = _L['Common / uncategorized'],
		aMapInfo = {
			MY_TM_SPECIAL_MAP.COMMON, -- ͨ��
			MY_TM_SPECIAL_MAP.CITY, -- ����
			MY_TM_SPECIAL_MAP.DUNGEON, -- �ؾ�
			MY_TM_SPECIAL_MAP.TEAM_DUNGEON, -- С���ؾ�
			MY_TM_SPECIAL_MAP.RAID_DUNGEON, -- �Ŷ��ؾ�
			MY_TM_SPECIAL_MAP.STARVE, -- �˿���
		},
	}
	table.insert(aGroupMap, tCommon)
	-- �ؾ�
	for _, v in ipairs(X.GetTypeGroupMap()) do
		table.insert(aGroupMap, v)
	end
	-- ����վ
	table.insert(aGroupMap, {
		szGroup = _L['Recycle bin'],
		aMapInfo = { MY_TM_SPECIAL_MAP.RECYCLE_BIN },
	})
	-- δ֪��
	local tMapExist = {}
	for _, v in ipairs(aGroupMap) do
		for _, vv in ipairs(v.aMapInfo) do
			if X.IsTable(vv) then
				vv = vv.dwID
			end
			tMapExist[vv] = true
		end
	end
	for k, v in pairs(data) do
		if X.IsNumber(k) and not tMapExist[k] then
			table.insert(tCommon.aMapInfo, k)
		end
	end
	-- ��ʽ��
	for _, v in ipairs(aGroupMap) do
		for i, vv in ipairs(v.aMapInfo) do
			if not X.IsTable(vv) then
				v.aMapInfo[i] = {
					dwID = vv,
					szName = MY_TeamMon.GetMapName(vv) or tostring(vv),
				}
			end
		end
	end
	-- ����
	if MY_TMUI_MAP_SEARCH then
		for i, v in X.ipairs_r(aGroupMap) do
			if not X.StringFindW(v.szGroup, MY_TMUI_MAP_SEARCH) then
				for i, vv in X.ipairs_r(v.aMapInfo) do
					if not X.StringFindW(vv.szName, MY_TMUI_MAP_SEARCH) then
						table.remove(v.aMapInfo, i)
					end
				end
				if #v.aMapInfo == 0 then
					table.remove(aGroupMap, i)
				end
			end
		end
	end
	-- ��Ⱦ�б�
	local hList, hTreeNode, hTreeItem = frame.hTreeH
	hList:Clear()
	for i, v in ipairs(aGroupMap) do
		hTreeNode = hList:AppendItemFromData(frame.hTreeN)
		hTreeNode.szKey = v.szGroup
		hTreeNode:Lookup('Text_TreeNode'):SetText(v.szGroup)
		for _, vv in ipairs(v.aMapInfo) do
			hTreeItem = hList:AppendItemFromData(frame.hTreeI)
			local aData = data[vv.dwID]
			local nCount = aData and #aData or 0
			if MY_TMUI_SEARCH and aData then
				nCount = 0
				for k, v in ipairs(aData) do
					if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
						nCount = nCount + 1
					end
				end
			end
			if vv.dwID ~= _L['All data'] then
				local szClassName = hTreeNode.szName or hTreeNode:Lookup('Text_TreeNode'):GetText()
				hTreeNode.szName = szClassName
				if not hTreeNode.nCount then
					hTreeNode.nCount = 0
				end
				hTreeNode.nCount = hTreeNode.nCount + nCount
				hTreeNode:Lookup('Text_TreeNode'):SetText(szClassName .. ' ('.. hTreeNode.nCount .. ')')
			end
			hTreeItem:Lookup('Text_TreeItem'):SetText(vv.szName .. ' ('.. nCount .. ')')
			hTreeItem.dwMapID = vv.dwID
			hTreeItem.nCount = nCount
			hTreeItem:SetVisible(MY_TMUI_TREE_EXPAND[v.szGroup])
		end
		D.UpdateMapNodeMouseState(hTreeNode)
	end
	hList:FormatAllItemPos()
	D.UpdateMapList(frame)
end

function D.UpdateMapNodeMouseState(hTreeNode)
	local szStatus = MY_TMUI_TREE_EXPAND[hTreeNode.szKey] and 'Collapse' or 'Expand'
	if hTreeNode.bMouseDown then
		szStatus = szStatus .. 'Down'
	elseif hTreeNode:IsMouseIn() then
		szStatus = szStatus .. 'Hover'
	end
	if not hTreeNode:Lookup('Image_TreeNodeBg_Expand') then
		return
	end
	hTreeNode:Lookup('Image_TreeNodeBg_Expand'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_ExpandDown'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_ExpandHover'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_Collapse'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_CollapseDown'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_CollapseHover'):Hide()
	hTreeNode:Lookup('Image_TreeNodeBg_' .. szStatus):Show()
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Close' then
		D.ClosePanel()
	end
end

function D.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == 'Handle_TreeNode' then
		this.bMouseDown = true
		D.UpdateMapNodeMouseState(this)
	elseif IsCtrlKeyDown() then
		if szName == 'Handle_R' or szName == 'Handle_L' then
			local data = {}
			local szName
			if this:Lookup('Text') then
				if MY_TMUI_SELECT_TYPE == 'CASTING' then
					szName = '[' .. Table_GetSkillName(this.dat.dwID, this.dat.nLevel) .. ']'
					data = {
						type = 'skill',
						skill_id = this.dat.dwID,
						skill_level = this.dat.nLevel,
						text = szName
					}
				else
					szName = this:Lookup('Text'):GetText()
					data   = { type = 'text', text = szName }
				end
			elseif this:Lookup('Text_Name') and this:Lookup('Text_Content') then
				szName = this:Lookup('Text_Name'):GetText() .. g_tStrings.STR_COLON .. this:Lookup('Text_Content'):GetText()
				data   = { type = 'text', text = szName }
			end
			if szName then
				local edit = X.GetChatInput()
				edit:InsertObj(szName, data)
				Station.SetFocusWindow(edit)
			end
		end
	end
end

function D.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == 'Handle_TreeNode' then
		this.bMouseDown = nil
		D.UpdateMapNodeMouseState(this)
	end
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_TreeNode' then
		MY_TMUI_TREE_EXPAND[this.szKey] = not MY_TMUI_TREE_EXPAND[this.szKey]
		D.UpdateMapNodeMouseState(this)
		local nIndex = this:GetIndex()
		local hList = this:GetParent()
		for i = nIndex + 1, hList:GetItemCount() - 1 do
			local hTreeItem = hList:Lookup(i)
			if hTreeItem:GetName() ~= 'Handle_TreeItem' then
				break
			end
			hTreeItem:SetVisible(MY_TMUI_TREE_EXPAND[this.szKey])
		end
		hList:FormatAllItemPos()
	elseif szName == 'Handle_TreeItem' then
		local frame = this:GetRoot()
		MY_TMUI_SELECT_MAP = this.dwMapID
		D.UpdateMapList(frame)
		D.UpdateLList()
		D.UpdateBG()
	elseif szName == 'Handle_L' then
		if MY_TMUI_DRAG or IsCtrlKeyDown() then
			return
		end
		D.OpenSettingPanel(this.dat, MY_TMUI_SELECT_TYPE)
	end
end

function D.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_TreeItem' then
		local dwMapID = this.dwMapID
		if dwMapID == _L['All data'] then
			dwMapID = nil
		end
		local menu = {}
		table.insert(menu, { szOption = this:Lookup('Text_TreeItem'):GetText(), bDisable = true })
		table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = _L['Clear this map data'], rgb = { 255, 0, 0 }, fnAction = function()
			D.RemoveData(dwMapID, nil, dwMapID
				and X.Get(MY_TeamMon.GetMapInfo(dwMapID), 'szName', _L['This data'])
				or _L['All data'])
		end })
		PopupMenu(menu)
	elseif szName == 'Handle_L' then
		local t = this.dat
		local menu = {}
		local name = this:Lookup('Text') and this:Lookup('Text'):GetText() or t.szContent
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then -- ̫��
			table.insert(menu, { szOption = g_tStrings.CHAT_NAME .. g_tStrings.STR_COLON .. name, bDisable = true })
		end
		table.insert(menu, { szOption = _L['Class'] .. g_tStrings.STR_COLON .. MY_TeamMon.GetMapName(t.dwMapID), bDisable = true })
		table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = g_tStrings.STR_FRIEND_MOVE_TO })
		table.insert(menu[#menu], { szOption = _L['Manual input'], fnAction = function()
			GetUserInput(g_tStrings.MSG_INPUT_MAP_NAME, function(szText)
				local map = MY_TeamMon.GetMapInfo(szText)
				if map then
					return D.MoveData(t.dwMapID, t.nIndex, map, IsCtrlKeyDown())
				end
				return X.Alert(_L['The map does not exist'])
			end)
		end })
		table.insert(menu[#menu], { bDevide = true })
		D.InsertDungeonMenu(menu[#menu], function(dwMapID)
			D.MoveData(t.dwMapID, t.nIndex, dwMapID, IsCtrlKeyDown())
		end)
		table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = _L['Share data'], bDisable = not X.IsInParty(), fnAction = function()
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Alert('TALK_LOCK', _L['Please unlock talk lock first.'])
			end
			if X.IsLeader() or X.IsDebugClient(true) then
				MY_TeamMon.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TM_SHARE', {MY_TMUI_SELECT_TYPE, t.dwMapID, t})
				X.Topmsg(g_tStrings.STR_MAIL_SUCCEED)
			else
				return X.Alert(_L['You are not team leader.'])
			end
		end })
		table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = g_tStrings.STR_FRIEND_DEL, rgb = { 255, 0, 0 }, fnAction = function()
			D.RemoveData(t.dwMapID, t.nIndex, name)
		end })
		PopupMenu(menu)
	elseif szName == 'Handle_R' then
		local menu = {}
		local t = this.dat
		local szName = D.GetDataName(MY_TMUI_SELECT_TYPE, t)
		-- table.insert(menu, { szOption = _L['Add to monitor list'], fnAction = function() D.OpenAddPanel(MY_TMUI_SELECT_TYPE, t) end })
		-- table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = g_tStrings.STR_DATE .. g_tStrings.STR_COLON .. FormatTime('%Y%m%d %H:%M:%S',t.nCurrentTime) , bDisable = true })
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then
			table.insert(menu, { szOption = g_tStrings.CHAT_NAME .. g_tStrings.STR_COLON .. szName, bDisable = true })
		end
		table.insert(menu, { szOption = g_tStrings.MAP_TALK .. g_tStrings.STR_COLON .. Table_GetMapName(t.dwMapID), bDisable = true })
		if MY_TMUI_SELECT_TYPE ~= 'NPC' and MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'DOODAD' then
			table.insert(menu, { szOption = g_tStrings.STR_SKILL_H_CAST_TIME .. (t.szSrcName or g_tStrings.STR_CRAFT_NONE) .. (t.bIsPlayer and _L['(player)'] or ''), bDisable = true })
		end
		if MY_TMUI_SELECT_TYPE ~= 'TALK' and MY_TMUI_SELECT_TYPE ~= 'CHAT' then
			local cmenu = { szOption = _L['Interval time'] }
			local tInterval
			if t.nLevel then
				tInterval = MY_TeamMon.GetIntervalData(MY_TMUI_SELECT_TYPE, t.dwID .. '_' .. t.nLevel)
			else
				tInterval = MY_TeamMon.GetIntervalData(MY_TMUI_SELECT_TYPE, t.dwID)
			end

			if tInterval and #tInterval > 1 then
				local nTime = tInterval[#tInterval]
				for k, v in X.ipairs_r(tInterval) do
					if #cmenu == 16 then break end
					table.insert(cmenu, { szOption = string.format('%.1f', (nTime - v) / 1000) .. g_tStrings.STR_TIME_SECOND })
					nTime = v
				end
				table.remove(cmenu, 1)
			else
				table.insert(cmenu, { szOption = g_tStrings.STR_FIGHT_NORECORD, bDisable = true })
			end
			table.insert(menu, cmenu)
		end
		PopupMenu(menu)
	end
end

function D.OnItemMouseEnter()
	local szName = this:GetName()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	if szName == 'Handle_TreeNode' then
		D.UpdateMapNodeMouseState(this)
	elseif szName == 'Handle_TreeItem' then
		local DungeonInfo = X.GetGameTable('DungeonInfo', true)
		local info = X.IsNumber(this.dwMapID) and DungeonInfo and DungeonInfo:Search(this.dwMapID)
		local szXml = GetFormatText(MY_TeamMon.GetMapName(this.dwMapID) ..' (' .. this.nCount ..  ')\n', 47, 255, 255, 0)
		if info and X.TrimString(info.szBossInfo) ~= '' then
			local tBoss = X.SplitString(info.szBossInfo, ' ')
			for k, v in ipairs(tBoss or {}) do
				if X.TrimString(v) ~= '' then
					szXml = szXml .. GetFormatText(k .. ') ' .. v .. '\n', 47, 255, 255, 255)
				end
			end
			szXml = szXml .. GetFormatImage(info.szDungeonImage3, 0, 200, 200)
		end
		if IsCtrlKeyDown() then
			szXml = szXml .. GetFormatText('\n\n' .. g_tStrings.DEBUG_INFO_ITEM_TIP .. '\nMapID:' .. this.dwMapID, 47, 255, 0, 0)
		end
		OutputTip(szXml, 300, { x, y, w, h })
	elseif szName == 'Handle_L' or szName == 'Handle_R' then
		if MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT' then
			this:Lookup('Image_Light'):Show()
		else
			this:Lookup('Image'):SetFrame(8)
			local box = this:Lookup('Box')
			box:SetObjectMouseOver(true)
		end
		D.OutputTip(MY_TMUI_SELECT_TYPE, this.dat, { x, y, w, h })
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_TreeNode' then
		D.UpdateMapNodeMouseState(this)
	elseif szName == 'Handle_TreeItem' then
		if this:Lookup('Image_TreeItemBg_Hover') then
			this:Lookup('Image_TreeItemBg_Hover'):Hide()
		end
	elseif szName == 'Handle_L' or szName == 'Handle_R' then
		if MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT' then
			if this:Lookup('Image_Light') and this:Lookup('Image_Light'):IsValid() then
				this:Lookup('Image_Light'):Hide()
			end
		else
			if this:Lookup('Image') and this:Lookup('Image'):IsValid() then
				this:Lookup('Image'):SetFrame(7)
				local box = this:Lookup('Box')
				if box and box:IsValid() then
					box:SetObjectMouseOver(false)
				end
			end
		end
	end
	HideTip()
end

function D.OnItemLButtonDrag()
	local szName = this:GetName()
	if szName == 'Handle_L' or szName == 'Handle_R' then
		OpenDragPanel(this)
	end
end

function D.OnItemLButtonDragEnd()
	local szName = this:GetName()
	if not DragPanelIsOpened() then
		return
	end
	local data, szAction = CloseDragPanel()
	if szName == 'Handle_TreeItem' then
		if szAction:find('Handle.+L') then
			if data and data.dwMapID ~= this.dwMapID then
				D.MoveData(data.dwMapID, data.nIndex, this.dwMapID, IsCtrlKeyDown())
			end
		elseif szAction:find('Handle.+R') then
			D.OpenAddPanel(MY_TMUI_SELECT_TYPE, data)
		end
	elseif szName:find('Handle.+L') then
		if szAction:find('Handle.+L') and not szName:find('Handle.+List_L') then
			if MY_TMUI_SELECT_MAP ~= _L['All data'] then
				D.Exchange(MY_TMUI_SELECT_MAP, data.nIndex, this.dat.nIndex)
			else
				D.RedrawMapList(this:GetRoot())
			end
		elseif szAction:find('Handle.+R') then
			D.OpenAddPanel(MY_TMUI_SELECT_TYPE, data)
		end
	end
	X.DelayCall(50, function() -- ���� click�� dragend ֮��
		MY_TMUI_DRAG = false
	end)
end

function D.OnEditChanged()
	local name = this:GetName()
	if name == 'Edit_SearchMap' then
		local szText = X.TrimString(this:GetText())
		if szText == '' then
			MY_TMUI_MAP_SEARCH = nil
		else
			MY_TMUI_MAP_SEARCH = szText
		end
		D.RedrawMapList(this:GetRoot())
	elseif name == 'Edit_SearchContent' then
		local szText = X.TrimString(this:GetText())
		if szText == '' then
			MY_TMUI_SEARCH = nil
		else
			MY_TMUI_SEARCH = szText
		end
		FireUIEvent('MY_TMUI_TEMP_RELOAD')
		FireUIEvent('MY_TMUI_DATA_RELOAD')
	end
end

function D.OnKillFocus()
	local name = this:GetName()
	if name == 'Edit_SearchContent' then
		FireUIEvent('MY_TMUI_FREECACHE')
	end
end

-- �Ż����ĺ��� ���ݹ�������������
function D.OnScrollBarPosChanged()
	-- print(this:GetName())
	local hWndScroll = this:GetParent()
	local szName = hWndScroll:GetName()
	local dir = szName:match('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_(.*)')
	if dir then
		local handle = hWndScroll:Lookup('', string.format('Handle_%s_List_%s', MY_TMUI_SELECT_TYPE, dir))
		local nPer = this:GetScrollPos() / math.max(1, this:GetStepCount())
		local nCount = math.ceil(handle:GetItemCount() * nPer)
		for i = math.max(0, nCount - MY_TMUI_ITEM_PER_PAGE), nCount + MY_TMUI_ITEM_PER_PAGE, 1 do -- ÿ����Ⱦ��ҳ
			local h = handle:Lookup(i)
			if h then
				if not h.bDraw then
					if MY_TMUI_SELECT_TYPE == 'BUFF' or MY_TMUI_SELECT_TYPE == 'DEBUFF' then
						D.SetBuffItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CASTING' then
						D.SetCastingItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'NPC' then
						D.SetNpcItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'DOODAD' then
						D.SetDoodadItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'TALK' then
						D.SetTalkItemAction(h)
					elseif MY_TMUI_SELECT_TYPE == 'CHAT' then
						D.SetChatItemAction(h)
					end
				end
			else
				break
			end
		end
	end
end

function D.OutputTip(szType, data, rect)
	if szType == 'BUFF' or szType == 'DEBUFF' then
		X.OutputBuffTip(rect, data.dwID, data.nLevel)
	elseif szType == 'CASTING' then
		OutputSkillTip(data.dwID, data.nLevel, rect)
	elseif szType == 'NPC' then
		X.OutputNpcTemplateTip(rect, data.dwID)
	elseif szType == 'DOODAD' then
		X.OutputDoodadTemplateTip(rect, data.dwID)
	elseif szType == 'TALK' then
		OutputTip(GetFormatText((data.szTarget or _L['Warning box']) .. '\t', 41, 255, 255, 0) .. GetFormatText(MY_TeamMon.GetMapName(data.dwMapID) .. '\n', 41, 255, 255, 255) .. GetFormatText(data.szContent, 41, 255, 255, 255), 300, rect)
	elseif szType == 'CHAT' then
		OutputTip(GetFormatText(_L['CHAT'] .. '\t', 41, 255, 255, 0) .. GetFormatText(MY_TeamMon.GetMapName(data.dwMapID) .. '\n', 41, 255, 255, 255) .. GetFormatText(data.szContent, 41, 255, 255, 255), 300, rect)
	end
end

function D.InsertDungeonMenu(menu, fnAction)
	local dwMapID = X.GetMapID()
	local aDungeon =  X.GetTypeGroupMap()
	local data = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
	table.insert(menu, {
		szOption = g_tStrings.CHANNEL_COMMON
			.. ' (' .. (data[MY_TM_SPECIAL_MAP.COMMON] and #data[MY_TM_SPECIAL_MAP.COMMON] or 0) .. ')',
		fnAction = function()
			if fnAction then
				fnAction(MY_TM_SPECIAL_MAP.COMMON)
			end
		end,
	})
	table.insert(menu, { bDevide = true })
	for k, v in ipairs(aDungeon) do
		local tMenu = { szOption = v.szGroup }
		for _, vv in ipairs(v.aMapInfo) do
			table.insert(tMenu, {
				szOption = Table_GetMapName(vv.dwID) .. ' (' .. (data[vv.dwID] and #data[vv.dwID] or 0) .. ')',
				rgb      = { 255, 128, 0 },
				szIcon   = dwMapID == vv.dwID and 'ui/Image/Minimap/Minimap.uitex',
				szLayer  = dwMapID == vv.dwID and 'ICON_RIGHT',
				nFrame   = dwMapID == vv.dwID and 10,
				fnAction = function()
					if fnAction then
						fnAction(vv.dwID)
					end
				end
			})
		end
		table.insert(menu, tMenu)
	end
end

function D.OpenImportPanel(szDefault, szTitle, fnAction)
	local ui = X.UI.CreateFrame('MY_TeamMon_DataPanel', { w = 720, h = 330, text = _L['Import data'], close = true })
	local nX, nY = ui:Append('Text', { x = 20, y = 50, text = _L['Includes'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = 20
	for k, v in ipairs(MY_TMUI_TYPE) do
		nX = ui:Append('WndCheckBox', { name = v, x = nX + 5, y = nY, checked = true, text = _L[v] }):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nY = 110
	nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['File name'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = ui:Append('WndEditBox', { name = 'FilePtah', x = 25, y = nY, w = 450, h = 25, text = szTitle, enable = not szDefault }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndButton', {
		x = nX + 5, y = nY,
		text = _L['Browse'],
		buttonStyle = 'FLAT',
		enable = not szDefault,
		onClick = function()
			local szFile = GetOpenFileName(
				_L['please select data file.'],
				'JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
				MY_TeamMon.MY_TM_REMOTE_DATA_ROOT
			)
			if not X.IsEmpty(szFile) then
				ui:Children('#FilePtah'):Text(szFile)
			end
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 10
	nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['Import mode'], font = 27 }):Pos('BOTTOMRIGHT')
	local szMode = 'REPLACE'
	nX = ui:Append('WndRadioBox', {
		x = 25, y = nY,
		text = _L['Cover'],
		group = 'type', checked = true,
		onCheck = function()
			szMode = 'REPLACE'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Merge priority new file'], group = 'type',
		onCheck = function()
			szMode = 'MERGE_OVERWRITE'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Merge priority old file'], group = 'type',
		onCheck = function()
			szMode = 'MERGE_SKIP'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = 285, y = nY + 30, text = g_tStrings.STR_HOTKEY_SURE,
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			local szFileName = szDefault or ui:Children('#FilePtah'):Text()
			local aType      = {}
			for k, v in ipairs(MY_TMUI_TYPE) do
				if ui:Children('#' .. v):Check() then
					table.insert(aType, v)
				end
			end
			MY_TeamMon.ImportDataFromFile(
				szFileName,
				aType,
				szMode,
				function(bStatus, ...)
					if bStatus then
						local szFilePath, aType, szMode, tMeta = ...
						X.Sysmsg(_L['MY_TeamMon'], _L('Load config success: %s', tostring(szFilePath)), X.CONSTANT.MSG_THEME.SUCCESS)
						-- local function fnAlert2()
						-- 	local szAuthor = tMeta and X.ReplaceSensitiveWord(tostring(tMeta.szAuthor)) or _L['Unknown author']
						-- 	X.Alert(
						-- 		_L('Plugin is plugin, data is data, plugin author is plugin author, data author is data author..\nYou just loaded data\'s author is %s, it works on mingyi plugin team monitor addon.\n%s is data author, do not response for plugin problems. MingYi is plugin author, do not response for data problems.\n\nIf there is some strange headtop, focus, buff or talk, please try to use other author\'s data, and response to current author %s, plugin author MingYi does not response for this.', szAuthor, szAuthor, szAuthor),
						-- 		nil,
						-- 		nil,
						-- 		'FORBIDDEN',
						-- 		2)
						-- end
						-- X.Alert(_L('Import success: %s', szTitle or szFilePath), fnAlert2, nil, fnAlert2)
						X.Alert(_L('Import success: %s', szTitle or szFilePath))
						ui:Remove()
						if MY_LifeBar and not MY_LifeBar.bEnabled then
							MY_LifeBar.bEnabled = true
						end
						if MY_TeamMon and not MY_TeamMon.bEnable then
							MY_TeamMon.bEnable = true
						end
						if MY_Focus and not MY_Focus.bEnable then
							MY_Focus.bEnable = true
						end
						X.SafeCall(fnAction, bStatus, szFilePath, aType, szMode, tMeta)
					else
						-- bStatus, szMsg
						local szMsg = ...
						X.Sysmsg(_L['MY_TeamMon'], _L('Load config failed: %s', _L[szMsg]), X.CONSTANT.MSG_THEME.ERROR)
						X.Alert(_L('Import failed: %s', szTitle or _L[szMsg]))
						X.SafeCall(fnAction, bStatus, szMsg)
					end
				end)
		end,
	})
end

function D.OpenExportPanel()
	local ui = X.UI.CreateFrame('MY_TeamMon_DataPanel', { w = 720, h = 410, text = _L['Export data'], close = true })
	local nX, nY = ui:Append('Text', { x = 20, y = 50, text = _L['Includes'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = 20
	for k, v in ipairs(MY_TMUI_TYPE) do
		nX = ui:Append('WndCheckBox', { name = v, x = nX + 5, y = nY, checked = true, text = _L[v] }):AutoWidth():Pos('BOTTOMRIGHT')
	end
	nY = 110
	local szAuthor = GetUserRoleName()
	nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['Author name'], font = 27 }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndEditBox', {
		x = 25, y = nY, w = 500, h = 25,
		text = szAuthor,
		limit = 6,
		onChange = function(szText)
			szAuthor = X.TrimString(szText)
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 10
	local szFileName = 'TM-' .. X.ENVIRONMENT.GAME_EDITION .. FormatTime('-%Y%m%d_%H.%M', GetCurrentTime())
	nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['File name'], font = 27 }):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndEditBox', {
		x = 25, y = nY, w = 500, h = 25,
		text = szFileName,
		onChange = function(szText)
			szFileName = szText
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 10
	nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['File format'], font = 27 }):Pos('BOTTOMRIGHT')
	local szFormat = 'LUA_ENCRYPTED'
	nX = ui:Append('WndRadioBox', {
		x = 25, y = nY,
		text = _L['Lua encrypted'], group = 'type',
		checked = true,
		onCheck = function()
			szFormat = 'LUA_ENCRYPTED'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Lua plain'], group = 'type',
		checked = false,
		onCheck = function()
			szFormat = 'LUA'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['Lua formated'], group = 'type',
		checked = false,
		onCheck = function()
			szFormat = 'LUA_FORMATED'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['JSON'], group = 'type',
		checked = false,
		onCheck = function()
			szFormat = 'JSON'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndRadioBox', {
		x = nX + 5, y = nY,
		text = _L['JSON formated'], group = 'type',
		checked = false,
		onCheck = function()
			szFormat = 'JSON_FORMATED'
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = 285, y = nY + 30, text = g_tStrings.STR_HOTKEY_SURE,
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			local aType = {}
			for _, v in ipairs(MY_TMUI_TYPE) do
				if ui:Children('#' .. v):Check() then
					table.insert(aType, v)
				end
			end
			MY_TeamMon.ExportDataToFile(
				szFileName,
				aType,
				szFormat,
				szAuthor,
				function(szPath)
					local szMsg = _L('Export success: %s', szPath)
					X.Alert(szMsg)
					X.Sysmsg(szMsg)
					ui:Remove()
				end)
		end,
	})
end

function D.MoveData( ... )
	MY_TeamMon.MoveData(MY_TMUI_SELECT_TYPE, ... )
end

function D.Exchange( ... )
	MY_TeamMon.Exchange(MY_TMUI_SELECT_TYPE, ...)
end

function D.RemoveData(dwMapID, nIndex, szMsg)
	local function fnAction()
		MY_TeamMon.RemoveData(MY_TMUI_SELECT_TYPE, dwMapID, nIndex)
	end
	if not nIndex then
		X.Confirm(FormatString(g_tStrings.MSG_DELETE_NAME, szMsg), fnAction)
	else
		fnAction()
	end
end

function D.GetSearchCache(data)
	if not MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE] then
		MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE] = {}
	end
	local cache = MY_TMUI_SEARCH_CACHE[MY_TMUI_SELECT_TYPE]
	local szString, tParsedData
	if data.dwMapID and data.nIndex then
		if cache[data.dwMapID] and cache[data.dwMapID][data.nIndex] then
			szString = cache[data.dwMapID][data.nIndex]
		else
			if not cache[data.dwMapID] then
				cache[data.dwMapID] = {}
			end
			tParsedData = {}
			for k, v in pairs(data) do
				tParsedData[k] = v
			end
			if tParsedData.szName then
				tParsedData.szName = ParseCustomText(tParsedData.szName)
			end
			szString = X.EncodeLUAData(data) .. X.EncodeLUAData(tParsedData)
			cache[data.dwMapID][data.nIndex] = szString
		end
	else -- ��ʱ��¼ ��ʱ���������洦��
		szString = X.EncodeLUAData(data)
	end
	return szString
end

function D.CheckSearch(szType, data)
	if MY_TMUI_GLOBAL_SEARCH then
		if D.GetSearchCache(data):find(MY_TMUI_SEARCH, nil, true) then
			return true
		end
	else
		local szName = D.GetDataName(szType, data)
		if tostring(szName):find(MY_TMUI_SEARCH, nil, true)
			or (data.szNote   and tostring(data.szNote):find(MY_TMUI_SEARCH, nil, true))
			or (data.key      and tostring(data.key):find(MY_TMUI_SEARCH, nil, true)) -- ��ȦȦ
			or (data.dwID     and tostring(data.dwID):find(MY_TMUI_SEARCH, nil, true))
			or (data.dwMapID  and MY_TeamMon.GetMapName(data.dwMapID):find(MY_TMUI_SEARCH, nil, true))
			or (data.szTarget and tostring(data.szTarget):find(MY_TMUI_SEARCH, nil, true))
		then
			return true
		end
	end
	return false
end

function D.GetDataName(szType, data)
	local szName, nIcon
	if szType == 'CASTING' then
		szName, nIcon = X.GetSkillName(data.dwID, data.nLevel)
	elseif szType == 'NPC' then
		if data.dwID then
			szName = X.GetTemplateName(TARGET.NPC, data.dwID) or data.dwID
			nIcon = data.nFrame
		end
	elseif szType == 'DOODAD' then
		local doodad = GetDoodadTemplate(data.dwID)
		szName = X.GetTemplateName(TARGET.DOODAD, data.dwID) or data.dwID
		nIcon  = doodad and MY_TMUI_DOODAD_ICON[doodad.nKind] or 13
	elseif szType == 'TALK' or szType == 'CHAT' then
		szName = data.szContent
	else
		szName, nIcon = X.GetBuffName(data.dwID, data.nLevel)
	end
	if data.nIcon then
		nIcon = data.nIcon
	end
	if data.szName then
		szName = ParseCustomText(data.szName)
	end
	return szName, nIcon
end

function D.SetBuffItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('BUFF', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local nSec = select(3, GetBuffTime(dat.dwID, dat.nLevel))
	if not nSec then
		h:Lookup('Text_R'):SetText('N/A')
	elseif nSec > 24 * 60 * 60 / X.ENVIRONMENT.GAME_FPS then
		h:Lookup('Text_R'):SetText(_L['INFINITE'])
	else
		nSec = nSec / X.ENVIRONMENT.GAME_FPS
		h:Lookup('Text_R'):SetText(X.FormatDuration(nSec, 'PRIME'))
	end
	h:Lookup('Image_RBg'):Show()
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	if dat.nCount then
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		box:SetOverText(0, dat.nCount)
	end
	h.bDraw = true
end

function D.SetCastingItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('CASTING', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local hSkill = GetSkillInfo({ skill_id = dat.dwID, skill_level = dat.nLevel })
	if not hSkill or hSkill.AreaRadius == 0 then
		h:Lookup('Text_R'):SetText('N/A')
	else
		h:Lookup('Text_R'):SetText(hSkill.AreaRadius / 64 .. g_tStrings.STR_METER)
	end
	h:Lookup('Image_RBg'):Show()
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	h.bDraw = true
end

function D.SetNpcItemAction(h)
	local dat = h.dat
	local szName = D.GetDataName('NPC', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local box = h:Lookup('Box')
	box:ClearObjectIcon()
	box:SetExtentImage('ui/Image/TargetPanel/Target.UITex', dat.nFrame)
	h.bDraw = true
end

function D.SetDoodadItemAction(h)
	local dat = h.dat
	local szName, nIcon = D.GetDataName('DOODAD', dat)
	h:Lookup('Text'):SetText(szName)
	if dat.col then
		h:Lookup('Text'):SetFontColor(unpack(dat.col))
	end
	local box = h:Lookup('Box')
	box:SetObjectIcon(nIcon)
	h.bDraw = true
end

function D.SetTalkItemAction(h)
	local dat = h.dat
	h:Lookup('Text_Name'):SetText(dat.szTarget or _L['Warning box'])
	if not dat.szTarget or dat.szTarget == '%' then -- system and %%
		h:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	end
	h:Lookup('Text_Content'):SetText(dat.szContent)
	if dat.col then
		h:Lookup('Text_Content'):SetFontColor(unpack(dat.col))
	end
	h.bDraw = true
end

function D.SetChatItemAction(h)
	local dat = h.dat
	h:Lookup('Text_Name'):SetText(_L['CHAT'])
	h:Lookup('Text_Name'):SetFontColor(255, 255, 0)
	h:Lookup('Text_Content'):SetText(dat.szContent)
	if dat.col then
		h:Lookup('Text_Content'):SetFontColor(unpack(dat.col))
	end
	h.bDraw = true
end

-- ���¼������
function D.UpdateLList()
	local tab = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
	if tab then
		local dat, dat2 = tab[MY_TMUI_SELECT_MAP] or {}, {}
		if MY_TMUI_SEARCH then
			for k, v in ipairs(dat) do
				if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
					table.insert(dat2, v)
				end
			end
		else
			dat2 = dat
		end
		D.DrawTableL(dat2)
	end
end

function D.DrawTableL(data)
	local frame = D.GetFrame()
	local page = frame.hPageSet:GetActivePage()
	local handle = page:Lookup('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_L', 'Handle_' .. MY_TMUI_SELECT_TYPE .. '_List_L')
	local hItemData = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and frame.hTalkL or frame.hItemL
	handle:Clear()
	if #data > 0 then
		for k, v in X.ipairs_r(data) do
			local h = handle:AppendItemFromData(hItemData, 'Handle_L')
			h.dat = v
		end
	end
	handle:FormatAllItemPos()
	D.RefreshScroll('L')
end

-- ������ʱ����
function D.UpdateRList(data)
	if data then
		D.DrawTableR(data, true)
	else
		local tab, tab2 = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE, true), {}
		if tab then
			if MY_TMUI_SEARCH then
				for k, v in ipairs(tab) do
					if D.CheckSearch(MY_TMUI_SELECT_TYPE, v) then
						table.insert(tab2, v)
					end
				end
			else
				tab2 = tab
			end
			D.DrawTableR(tab2)
		end
	end
end

function D.DrawTableR(data, bInsert)
	local frame = D.GetFrame()
	local page = frame.hPageSet:GetActivePage()
	local handle = page:Lookup('WndScroll_' .. MY_TMUI_SELECT_TYPE .. '_R', 'Handle_' .. MY_TMUI_SELECT_TYPE .. '_List_R')
	if not bInsert then
		handle:Clear()
		local hItemData = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and frame.hTalkR or frame.hItemR
		if #data > 0 then
			for k, v in X.ipairs_r(data) do
				local h = handle:AppendItemFromData(hItemData, 'Handle_R')
				h.dat = v
			end
		end
	else
		-- ��һ�� InsertItemFromData
		local szIniFile = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and MY_TMUI_TALK_R or MY_TMUI_ITEM_R
		local szSectionName = (MY_TMUI_SELECT_TYPE == 'TALK' or MY_TMUI_SELECT_TYPE == 'CHAT') and 'Handle_TALK_R' or 'Handle_R'
		if not MY_TMUI_SEARCH or D.CheckSearch(MY_TMUI_SELECT_TYPE, data) then
			handle:InsertItemFromIni(0, false, szIniFile, szSectionName, 'Handle_R')
			local h = handle:Lookup(0)
			h.dat = data
		end
	end
	handle:FormatAllItemPos()
	D.RefreshScroll('R')
end

function D.ScrollMapIntoView(frame)
	local hList, hNode, hItem = frame.hTreeH
	for i = 0, hList:GetItemCount() - 1 do
		hItem = hList:Lookup(i)
		if hItem:GetName() == 'Handle_TreeNode' then
			hNode = hItem
		elseif hItem.dwMapID == MY_TMUI_SELECT_MAP then
			break
		end
		hItem = nil
	end
	if not hItem then
		return
	end
	if hNode and not MY_TMUI_TREE_EXPAND[hNode.szKey] then
		X.ExecuteWithThis(hNode, D.OnItemLButtonClick)
	end
	X.UI.ScrollIntoView(hItem, frame.hTreeS)
end

-- ������
function D.OpenAddPanel(szType, data)
	local szName, nIcon = _L[szType], 340
	if szType ~= 'TALK' and szType ~= 'CHAT' then
		szName, nIcon = D.GetDataName(szType, data)
	end
	local ui = X.UI.CreateFrame('MY_TeamMon_NewData', { w = 380, h = 250, text = szName, focus = true, close = true })
	local nX, nY = 0, 0
	ui:Event('MY_TMUI_SWITCH_PAGE', function() ui:Remove() end)
	ui:Event('MY_TMUI_TEMP_RELOAD', function() ui:Remove() end)
	if szType ~= 'NPC' then
		nX, nY = ui:Append('Box', { name = 'Box_Icon', w = 48, h = 48, x = 166, y = 40, icon = nIcon }):Pos('BOTTOMRIGHT')
	else
		nX, nY = ui:Append('Box', {
			name = 'Box_Icon', w = 48, h = 48, x = 166, y = 40, icon = nIcon,
			image = 'ui/Image/TargetPanel/Target.uitex', imageFrame = data.nFrame,
		}):Pos('BOTTOMRIGHT')
	end
	ui:Children('#Box_Icon'):Hover(function(bHover)
		this:SetObjectMouseOver(bHover)
		if bHover then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			D.OutputTip(szType, data, { x, y, w, h })
		else
			HideTip()
		end
	end)
	nX, nY = ui:Append('WndEditBox', {
		name = 'map', x = 100, y = nY + 15, w = 200, h = 30,
		text = MY_TMUI_SELECT_MAP ~= _L['All data']
			and MY_TeamMon.GetMapName(MY_TMUI_SELECT_MAP)
			or MY_TeamMon.GetMapName(data.dwMapID),
		autocomplete = {{'option', 'source', X.GetMapNameList()}},
		onChange = function()
			local el = this
			local ui = X.UI(el)
			if ui:Text() == '' then
				local menu = {}
				D.InsertDungeonMenu(menu, function(dwMapID)
					ui:Text(MY_TeamMon.GetMapName(dwMapID))
				end)
				local nX, nY = this:GetAbsPos()
				local nW, nH = this:GetSize()
				menu.nMiniWidth = nW
				menu.x = nX
				menu.y = nY + nH
				menu.fnAutoClose = function() return not el or not el:IsValid() end
				menu.bShowKillFocus = true
				menu.bDisableSound = true
				PopupMenu(menu)
			end
		end,
	}):Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = 120, y = nY + 40, text = _L['Add'],
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			local txt = ui:Children('#map'):Text()
			local map = MY_TeamMon.GetMapInfo(txt)
			if not map then
				return X.Alert(_L['The map does not exist'])
			end
			local tab = select(2, MY_TeamMon.CheckSameData(szType, map.dwID, data.dwID or data.szContent, data.nLevel or data.szTarget))
			if tab then
				return X.Confirm(_L['Data exists, editor?'], function()
					FireUIEvent('MY_TMUI_SELECT_MAP', map.dwID)
					D.OpenSettingPanel(tab, szType)
					ui:Remove()
				end)
			end
			local dat = {
				dwID      = data.dwID,
				nLevel    = data.nLevel,
				nFrame    = data.nFrame,
				szContent = data.szContent,
				szTarget  = data.szTarget
			}
			FireUIEvent('MY_TMUI_SELECT_MAP', map.dwID)
			D.OpenSettingPanel(MY_TeamMon.AddData(szType, map.dwID, dat), szType)
			ui:Remove()
		end,
	})
end
-- ���ݵ������
function D.OpenJsonPanel(data, fnAction)
	local ui = X.UI.CreateFrame('MY_TeamMon_JsonPanel', { w = 720,h = 500, text = _L['MY_TeamMon DEBUG Panel'], close = true })
	ui:Event('MY_TMUI_DATA_RELOAD', function() ui:Remove() end)
	ui:Event('MY_TMUI_SWITCH_PAGE', function() ui:Remove() end)
	ui:Append('WndEditBox', {
		name = 'CODE', w = 660, h = 350, x = 30, y = 60,
		color = { 255, 255, 0 },
		text = X.EncodeLUAData(data, '\t'),
		multiline = true, limit = 999999,
		onChange = function()
			local code = ui:Children('#CODE')
			local dat  = X.DecodeLUAData(code:Text())
			if dat then
				code:Color(255, 255, 0)
				else
				code:Color(255, 0, 0)
			end
		end,
	})
	ui:Append('WndButton',{
		x = 30, y = 440,
		text = g_tStrings.STR_HOTKEY_SURE,
		buttonStyle = 'FLAT_LACE_BORDER',
		onClick = function()
			X.Confirm(_L['Confirm?'], function()
				local dat = X.DecodeLUAData(ui:Children('#CODE'):Text())
				if fnAction and dat then
					ui:Remove()
					return fnAction(dat)
				end
			end)
		end,
	})
end

-- �������
function D.OpenSettingPanel(data, szType)
	local function GetPatternName()
		if szType == 'BUFF' or szType == 'DEBUFF' then
			return '{$B' .. data.dwID .. '}'
		end
		if szType == 'CASTING' then
			return '{$S' .. data.dwID .. '}'
		end
		if szType == 'NPC' then
			return '{$N' .. data.dwID .. '}'
		end
		if szType == 'DOODAD' then
			return '{$D' .. data.dwID .. '}'
		end
	end
	local function GetScrutinyTypeMenu()
		local menu = {
			{
				szOption = g_tStrings.STR_GUILD_ALL,
				bMCheck = true,
				bChecked = type(data.nScrutinyType) == 'nil',
				fnAction = function()
					data.nScrutinyType = nil
				end,
			},
			-- { bDevide = true },
			{
				szOption = g_tStrings.MENTOR_SELF,
				bMCheck = true,
				bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.SELF,
				fnAction = function()
					data.nScrutinyType = MY_TM_SCRUTINY_TYPE.SELF
				end,
			},
			{
				szOption = _L['Team'],
				bMCheck = true,
				bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.TEAM,
				fnAction = function()
					data.nScrutinyType = MY_TM_SCRUTINY_TYPE.TEAM
				end,
			},
			{
				szOption = _L['Enemy'],
				bMCheck = true,
				bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.ENEMY,
				fnAction = function()
					data.nScrutinyType = MY_TM_SCRUTINY_TYPE.ENEMY
				end,
			},
			{
				szOption = g_tStrings.STR_RAID_TIP_TARGET,
				bMCheck = true,
				bChecked = data.nScrutinyType == MY_TM_SCRUTINY_TYPE.TARGET,
				fnAction = function()
					data.nScrutinyType = MY_TM_SCRUTINY_TYPE.TARGET
				end,
			},
		}
		return menu
	end
	local function GetKungFuMenu()
		local menu = {}
		if data.tKungFu then
			table.insert(menu, { szOption = _L['No request'], bCheck = true, bChecked = type(data.tKungFu) == 'nil', fnAction = function()
				data.tKungFu = nil
				X.UI.ClosePopupMenu()
			end })
		end
		for k, v in ipairs(X.CONSTANT.KUNGFU_LIST) do
			table.insert(menu, {
				szOption = X.GetSkillName(v.dwID, 1),
				bCheck   = true,
				bChecked = data.tKungFu and data.tKungFu['SKILL#' .. v.dwID],
				szIcon   = v.szUITex,
				nFrame   = v.nFrame,
				szLayer  = 'ICON_RIGHTMOST',
				fnAction = function()
					data.tKungFu = data.tKungFu or {}
					if not data.tKungFu['SKILL#' .. v.dwID] then
						data.tKungFu['SKILL#' .. v.dwID] = true
					else
						data.tKungFu['SKILL#' .. v.dwID] = nil
						if X.IsEmpty(data.tKungFu) then
							data.tKungFu = nil
						end
					end
				end
			})
		end
		return menu
	end
	local function GetMarkMenu(nClass)
		local menu = {}
		for k, v in X.ipairs_c(PARTY_MARK_ICON_FRAME_LIST) do
			table.insert(menu, {
				szOption = X.CONSTANT.TEAM_MARK_NAME[k] or '?',
				szIcon = PARTY_MARK_ICON_PATH,
				nFrame = v, szLayer = 'ICON_RIGHT',
				bCheck = true, bChecked = data[nClass] and data[nClass].tMark and data[nClass].tMark[k],
				fnAction = function(_, bCheck)
					if bCheck then
						data[nClass] = data[nClass] or {}
						if not data[nClass].tMark then
							data[nClass].tMark = {}
							for kk, vv in X.ipairs_c(PARTY_MARK_ICON_FRAME_LIST) do
								data[nClass].tMark[kk] = false
							end
						end
						data[nClass].tMark[k] = true
					else
						data[nClass].tMark[k] = false
						local bDelete = true
						for k, v in ipairs(data[nClass].tMark) do
							if v then
								bDelete = false
								break
							end
						end
						if bDelete then
							data[nClass].tMark = nil
						end
						if X.IsEmpty(data[nClass]) then data[nClass] = nil end
					end
				end,
			})
		end
		return menu
	end
	local function SetDataClass(nClass, key, value)
		if value then
			data[nClass] = data[nClass] or {}
			data[nClass][key] = value
		else
			data[nClass][key] = nil
			if X.IsEmpty(data[nClass]) then
				data[nClass] = nil
			end
		end
	end

	local function IsSimpleCountdown(dat)
		if dat.nClass == MY_TM_TYPE.NPC_LIFE or dat.nClass == MY_TM_TYPE.NPC_MANA then
			return false
		end
		if X.IsEmpty(dat.nTime) or tonumber(dat.nTime) then
			return true
		end
		return false
	end

	local function FormatElPosByCountdownType(dat, ui, i)
		local bSimple = IsSimpleCountdown(dat)
		ui:Children('#CountdownTime' .. i):Width(bSimple and 100 or 400)
		ui:Children('#CountdownName' .. i):Visible(bSimple)
	end

	local function SetCountdownType(dat, val, ui, i)
		dat.nClass = val
		FormatElPosByCountdownType(dat, ui, i)
		ui:Children('#Countdown' .. i):Text(_L['Countdown TYPE ' ..  dat.nClass])
		X.UI.ClosePopupMenu()
	end

	local function ParseCountdown(szCountdown, nClass)
		local aCountdown, bError, bTrigger
		if nClass == MY_TM_TYPE.NPC_LIFE or nClass == MY_TM_TYPE.NPC_MANA then
			bTrigger = true
			aCountdown, bError = MY_TeamMon.ParseHPCountdown(szCountdown)
		else
			bTrigger = false
			aCountdown, bError = MY_TeamMon.ParseCountdown(szCountdown)
		end
		return aCountdown, bError, bTrigger
	end
	-- local tSkillInfo
	local file = 'ui/Image/UICommon/Feedanimials.uitex'
	local szName, nIcon = _L[szType], 340
	if szType ~= 'TALK' and szType ~= 'CHAT' then
		szName, nIcon = D.GetDataName(szType, data)
	elseif szType == 'CHAT' then
		nIcon = 439
	end
	local ui = X.UI.CreateFrame('MY_TeamMon_SettingPanel', { w = 770, h = 450, text = szName, close = true, focus = true })
	local frame = Station.Lookup('Normal/MY_TeamMon_SettingPanel')
	ui:Event('MY_TMUI_DATA_RELOAD', function() ui:Remove() end)
	ui:Event('MY_TMUI_SWITCH_PAGE', function() ui:Remove() end)
	frame.OnFrameDragEnd = function()
		MY_TMUI_PANEL_ANCHOR = GetFrameAnchor(frame, 'CENTER')
	end
	local nX, nY, _ = 0, 0, 0
	local nW, nH = ui:Size()
	local function fnClickBox()
		local menu, box = {}, this
		if szType ~= 'TALK' and szType ~= 'CHAT' then
			table.insert(menu, { szOption = _L['Edit name'], fnAction = function()
				local szKey = X.Alert(_L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called'])
				local function CloseHelp()
					X.DoMessageBox(szKey)
				end
				local szDefault = data.szName or GetPatternName() or szName
				GetUserInput(_L['Edit name'], function(szText)
					szText = X.TrimString(szText)
					if szText == '' or szText == szName or szText == GetPatternName() then
						data.szName = nil
						ui:Text(szName)
					else
						data.szName = szText
						ui:Text(ParseCustomText(szText))
					end
					CloseHelp()
				end, CloseHelp, function() return not frame or not frame:IsValid() end, nil, szDefault)
			end})
			table.insert(menu, { bDevide = true })
		end
		if szType ~= 'NPC' and szType ~= 'TALK' and szType ~= 'CHAT' then
			table.insert(menu, { szOption = _L['Edit icon'], fnAction = function()
				X.UI.OpenIconPicker(function(nNewIcon)
					nIcon = nNewIcon
					data.nIcon = nNewIcon
					box:SetObjectIcon(nNewIcon)
				end)
			end})
			table.insert(menu, { bDevide = true })
		end
		table.insert(menu, {
			szOption = _L['Edit color'],
			szLayer = 'ICON_RIGHT',
			szIcon = 'ui/Image/UICommon/Feedanimials.uitex',
			nFrame = 86,
			nMouseOverFrame = 87,
			fnClickIcon = function()
				data.col = nil
				ui:Children('#Shadow_Color'):Alpha(0)
			end,
			fnAction = function()
				X.UI.OpenColorPicker(function(r, g, b)
					data.col = { r, g, b }
					ui:Children('#Shadow_Color'):Color(r, g, b):Alpha(255)
				end)
			end
		})
		table.insert(menu, { bDevide = true })
		table.insert(menu, { szOption = _L['Raw data, please be careful'], color = { 255, 255, 0 }, fnAction = function()
			D.OpenJsonPanel(data, function(dat)
				local file = MY_TeamMon.GetTable(MY_TMUI_SELECT_TYPE)
				if file and file[MY_TMUI_SELECT_MAP] and file[data.dwMapID][data.nIndex] then
					file[data.dwMapID][data.nIndex] = dat
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
				FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
				FireUIEvent('MY_TMUI_DATA_RELOAD')
				D.OpenSettingPanel(file[data.dwMapID][data.nIndex], szType)
			end)
		end })
		PopupMenu(menu)
	end

	ui:Append('Shadow', { name = 'Shadow_Color', w = 52, h = 52, x = 359, y = 38, color = data.col, alpha = data.col and 255 or 0 })
	if szType ~= 'NPC' then
		nX, nY = ui:Append('Box', { name = 'Box_Icon', w = 48, h = 48, x = 361, y = 40, icon = nIcon }):Pos('BOTTOMRIGHT')
	else
		nX, nY = ui:Append('Box', {
			name = 'Box_Icon', w = 48, h = 48, x = 361, y = 40, icon = nIcon,
			image = 'ui/Image/TargetPanel/Target.uitex', imageFrame = data.nFrame,
		}):Pos('BOTTOMRIGHT')
	end
	ui:Children('#Box_Icon'):Hover(function(bHover)
		this:SetObjectMouseOver(bHover)
		if bHover then
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			D.OutputTip(szType, data, { x, y, w, h })
		else
			HideTip()
		end
	end):Click(fnClickBox)

	if szType == 'BUFF' or szType == 'DEBUFF' then
		nX, nY = ui:Append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = 30, y = nY, w = 200, text = _L['Scrutiny type'],
			menu = function()
				return GetScrutinyTypeMenu(data)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = nX + 5, y = nY + 2, w = 200, text = _L['Self kungfu requirement'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = nX + 5, y = nY, text = _L['Buffcount achieve'] }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26,
			text = data.nCount or 1, editType = X.UI.EDIT_TYPE.NUMBER,
			onChange = function(nNum)
				data.nCount = tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bCheckLevel, text = _L['Check level'],
			onCheck = function(bCheck)
				data.bCheckLevel = bCheck and true or nil
				FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		-- get buff
		local cfg = data[MY_TM_TYPE.BUFF_GET] or {}
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Get buff'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 60, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.BUFF_GET)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
			tip = {
				render = _L['Requires MY_LifeBar loaded.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bScreenHead', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_FS') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT

		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bPartyBuffList, text = _L['Party buff list'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bPartyBuffList', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bBuffList, text = _L['Buff list'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bBuffList', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bTeamPanel, text = _L['Team panel'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bTeamPanel', bCheck)
				ui:Children('#bOnlySelfSrc'):Enable(bCheck)
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			name = 'bOnlySelfSrc',
			x = nX + 5, y = nY, checked = cfg.bOnlySelfSrc, text = _L['Only source self'], enable = cfg.bTeamPanel == true,
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_GET, 'bOnlySelfSrc', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nY = nY + CHECKBOX_HEIGHT

		if not X.IsRestricted('MY_TeamMon.AutoSelect') then
			local _ui = ui:Append('WndCheckBox', {
				x = 30, y = nY, checked = cfg.bSelect, text = _L['Auto Select'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_GET, 'bSelect', bCheck)
				end,
			}):AutoWidth()
			nX = _ui:Pos('BOTTOMRIGHT')
			if szType == 'BUFF' then
				nX, nY = ui:Append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bAutoCancel, text = _L['Auto Cancel Buff'],
					onCheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.BUFF_GET, 'bAutoCancel', bCheck)
					end,
				}):AutoWidth():Pos('BOTTOMRIGHT')
			else
				nX, nY = _ui:Pos('BOTTOMRIGHT')
			end
		end
		-- ʧȥbuff
		local cfg = data[MY_TM_TYPE.BUFF_LOSE] or {}
		nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Lose buff'], font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.BUFF_LOSE, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'CASTING' then
		nX, nY = ui:Append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Scrutiny type'],
			menu = function()
				return GetScrutinyTypeMenu(data)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = nX + 5, y = nY + 2, text = _L['Self kungfu requirement'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bCheckLevel, text = _L['Check level'],
			onCheck = function(bCheck)
				data.bCheckLevel = bCheck and true or nil
				FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bMonTarget, text = _L['Show target name'],
			onCheck = function(bCheck)
				data.bMonTarget = bCheck and true or nil
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')

		local cfg = data[MY_TM_TYPE.SKILL_END] or {}
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Skills cast succeed'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.SKILL_END)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.SKILL_END, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_END, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_END, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		-- local tRecipeKey = me.GetSkillRecipeKey(data.dwID, data.nLevel)
		-- tSkillInfo = GetSkillInfo(tRecipeKey)
		-- if tSkillInfo and tSkillInfo.CastTime ~= 0 then
			local cfg = data[MY_TM_TYPE.SKILL_BEGIN] or {}
			nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Skills began to cast'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
			nX, nY = ui:Append('WndComboBox', {
				x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
				menu = function()
					return GetMarkMenu(MY_TM_TYPE.SKILL_BEGIN)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			nX = ui:Append('WndCheckBox', {
				x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bTeamChannel', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bWhisperChannel', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bCenterAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			if not X.IsRestricted('MY_TeamMon_LT') then
				nX = ui:Append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
					onCheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bBigFontAlarm', bCheck)
					end,
				}):AutoWidth():Pos('BOTTOMRIGHT')
			end
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
				tip = {
					render = _L['Requires MY_LifeBar loaded.\nDue to official logic, only target is visible.'],
					position = X.UI.TIP_POSITION.BOTTOM_TOP,
				},
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bScreenHead', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			if not X.IsRestricted('MY_TeamMon_FS') then
				nX = ui:Append('WndCheckBox', {
					x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
					onCheck = function(bCheck)
						SetDataClass(MY_TM_TYPE.SKILL_BEGIN, 'bFullScreen', bCheck)
					end,
				}):AutoWidth():Pos('BOTTOMRIGHT')
			end
			nY = nY + CHECKBOX_HEIGHT
		-- end
	elseif szType == 'NPC' then
		-- ͨ��
		nX, nY = ui:Append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Self kungfu requirement'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = nX + 5, y = nY, text = _L['Count achieve'] }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26,
			text = data.nCount or 1, editType = X.UI.EDIT_TYPE.NUMBER,
			onChange = function(nNum)
				data.nCount = tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}):Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bAllLeave, text = _L['Must all leave scene'],
			onCheck = function(bCheck)
				data.bAllLeave = bCheck and true or nil
				if bCheck then
					ui:Children('#NPC_LEAVE_TEXT'):Text(_L['All leave scene'])
				else
					ui:Children('#NPC_LEAVE_TEXT'):Text(_L['Leave scene'])
				end
			end,
		}):Pos('BOTTOMRIGHT')
		-- ���볡��
		local cfg = data[MY_TM_TYPE.NPC_ENTER] or {}
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Enter scene'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndComboBox', {
			x = nX + 5, y = nY + 8, w = 160, h = 25, text = _L['Mark'],
			menu = function()
				return GetMarkMenu(MY_TM_TYPE.NPC_ENTER)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
			tip = {
				render = _L['Requires MY_LifeBar loaded.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bScreenHead', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_FS') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_ENTER, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		nX, nY = ui:Append('Text', {
			name = 'NPC_LEAVE_TEXT', x = 20, y = nY + 5,
			text = data.bAllLeave and _L['All leave scene'] or _L['Leave scene'], font = 27,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.NPC_LEAVE] or {}
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.NPC_LEAVE, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'DOODAD' then
		nX, nY = ui:Append('Text', { x = 20, y = nY, text = g_tStrings.CHANNEL_COMMON, font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndComboBox', {
			x = 30, y = nY + 2, text = _L['Self kungfu requirement'],
			menu = function()
				return GetKungFuMenu(data)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = nX + 5, y = nY, text = _L['Count achieve'] }):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndEditBox', {
			x = nX + 2, y = nY + 2, w = 30, h = 26, text = data.nCount or 1, editType = X.UI.EDIT_TYPE.NUMBER,
			onChange = function(nNum)
				data.nCount = tonumber(nNum)
				if data.nCount == 1 then
					data.nCount = nil
				end
			end,
		}):Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = data.bAllLeave, text = _L['Must all leave scene'],
			onCheck = function(bCheck)
				data.bAllLeave = bCheck and true or nil
				if bCheck then
					ui:Children('#DOODAD_LEAVE_TEXT'):Text(_L['All leave scene'])
				else
					ui:Children('#DOODAD_LEAVE_TEXT'):Text(_L['Leave scene'])
				end
			end,
		}):Pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.DOODAD_ENTER] or {}
		nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Enter scene'], font = 27 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
			-- nX = ui:Append('WndCheckBox', {
			-- 	x = nX + 5, y = nY, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
			-- 	tip = {
			-- 	render = _L['Requires MY_LifeBar loaded.'],
			-- 	position = X.UI.TIP_POSITION.BOTTOM_TOP,
			-- },
			-- 	onCheck = function(bCheck)
			-- 		SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bScreenHead', bCheck)
			-- 	end,
			-- }):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_FS') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_ENTER, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
		nX, nY = ui:Append('Text', {
			name = 'DOODAD_LEAVE_TEXT', x = 20, y = nY + 5,
			text = data.bAllLeave and _L['All leave scene'] or _L['Leave scene'], font = 27,
		}):Pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.DOODAD_LEAVE] or {}
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.DOODAD_LEAVE, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'TALK' then
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Alert content'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szNote, w = 650, h = 25,
			onChange = function(text)
				local szText = X.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
			tip = {
				render = _L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Speaker'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szTarget or _L['Warning box'], w = 650, h = 25,
			onChange = function(text)
				local szText = X.TrimString(text)
				if szText == '' or szText == _L['Warning box'] then
					data.szTarget = nil
				else
					data.szTarget = szText
				end
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Content'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		_, nY = ui:Append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szContent, w = 650, h = 55, multiline = true,
			onChange = function(text)
				data.szContent = X.TrimString(text)
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = nX, y = nY, text = _L['Tips: {$me} behalf of self, {$team} behalf of team.'], alpha = 200 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 540, y = nY + 3, w = 50,
			text = _L['Partical search'],
			tip = {
				render = _L['Supports match partical.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			checked = data.bSearch,
			onCheck = function(bCheck)
				data.bSearch = bCheck
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = 640, y = nY + 3, w = 50,
			text = _L['Regexp match'],
			tip = {
				render = _L['Supports backreference in note string, format: {$index}.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			checked = data.bReg,
			onCheck = function(bCheck)
				data.bReg = bCheck
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Trigger talk'], font = 27 }):Pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.TALK_MONITOR] or {}
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY + 10, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
			tip = {
				render = _L['Requires MY_LifeBar loaded.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bScreenHead', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_FS') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.TALK_MONITOR, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	elseif szType == 'CHAT' then
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Alert content'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szNote, w = 650, h = 25,
			onChange = function(text)
				local szText = X.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
			tip = {
				render = _L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Chat content'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		_, nY = ui:Append('WndEditBox', {
			x = nX + 5, y = nY + 8, text = data.szContent, w = 650, h = 85, multiline = true,
			onChange = function(text)
				data.szContent = text:gsub('\r', '')
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):Pos('BOTTOMRIGHT')
		nX = ui:Append('Text', { x = nX, y = nY, text = _L['Tips: {$me} behalf of self, {$team} behalf of team.'], alpha = 200 }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = 540, y = nY + 3, w = 50,
			text = _L['Partical search'],
			tip = {
				render = _L['Supports match partical.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			checked = data.bSearch,
			onCheck = function(bCheck)
				data.bSearch = bCheck
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndCheckBox', {
			x = 640, y = nY + 3, w = 50,
			text = _L['Regexp match'],
			tip = {
				render = _L['Supports backreference in note string, format: {$index}.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			checked = data.bReg,
			onCheck = function(bCheck)
				data.bReg = bCheck
				FireUIEvent('MY_TM_CREATE_CACHE')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Trigger chat'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		local cfg = data[MY_TM_TYPE.CHAT_MONITOR] or {}
		nX = ui:Append('WndCheckBox', {
			x = 30, y = nY + 10, checked = cfg.bTeamChannel, text = _L['Team channel alarm'], color = GetMsgFontColor('MSG_TEAM', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bTeamChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bWhisperChannel, text = _L['Whisper channel alarm'], color = GetMsgFontColor('MSG_WHISPER', true),
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bWhisperChannel', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bCenterAlarm, text = _L['Center alarm'],
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bCenterAlarm', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_LT') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bBigFontAlarm, text = _L['Large text alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bBigFontAlarm', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY + 10, checked = cfg.bScreenHead, text = _L['Lifebar alarm'],
			tip = {
				render = _L['Requires MY_LifeBar loaded.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			onCheck = function(bCheck)
				SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bScreenHead', bCheck)
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		if not X.IsRestricted('MY_TeamMon_FS') then
			nX = ui:Append('WndCheckBox', {
				x = nX + 5, y = nY + 10, checked = cfg.bFullScreen, text = _L['Fullscreen alarm'],
				onCheck = function(bCheck)
					SetDataClass(MY_TM_TYPE.CHAT_MONITOR, 'bFullScreen', bCheck)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
		end
		nY = nY + CHECKBOX_HEIGHT
	end
	-- ���䱨������
	if szType ~= 'TALK' and szType ~= 'CHAT' then
		nX, nY = ui:Append('Text', { x = 20, y = nY, text = _L['Add content'], font = 27 }):Pos('BOTTOMRIGHT')
		nX, nY = ui:Append('WndEditBox', {
			x = 30, y = nY, text = data.szNote, w = 650, h = 25, limit = 10,
			onChange = function(text)
				local szText = X.TrimString(text)
				if szText == '' then
					data.szNote = nil
				else
					data.szNote = szText
				end
			end,
		}):Pos('BOTTOMRIGHT')
	end
	-- ����ʱ
	nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Countdown'], font = 27 }):Pos('BOTTOMRIGHT')
	for k, v in ipairs(data.tCountdown or {}) do
		-- ����
		nX = ui:Append('WndComboBox', {
			name = 'Countdown' .. k, x = 30, w = 155, h = 25, y = nY,
			color = v.key and { 255, 255, 0 },
			text = v.nClass == -1 and _L['Please select type'] or _L['Countdown TYPE ' ..  v.nClass],
			menu = function()
				local menu = {}
				if IsCtrlKeyDown() then
					table.insert(menu, {
						szOption = _L['Set countdown key'],
						rgb = { 255, 255, 0 },
						fnMouseEnter = function()
							local nX, nY = this:GetAbsX(), this:GetAbsY()
							local nW, nH = this:GetW(), this:GetH()
							OutputTip(GetFormatText(_L['Key supports template render: {$sender}, {$receiver}, {$1}'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.RIGHT_LEFT)
						end,
						fnMouseLeave = function()
							HideTip()
						end,
						fnAction = function()
							GetUserInput(_L['Countdown key'], function(szKey)
								if X.TrimString(szKey) == '' then
									v.key = nil
								else
									v.key = X.TrimString(szKey)
								end
								D.OpenSettingPanel(data, szType)
							end, nil, nil, nil, v.key)
						end,
					})
					table.insert(menu, { bDevide = true })
					table.insert(menu, { szOption = _L['Hold countdown when crossmap'], bCheck = true, bChecked = v.bHold, fnAction = function()
						v.bHold = not v.bHold
					end })
					if v.nClass == MY_TM_TYPE.NPC_FIGHT then
						table.insert(menu, { szOption = _L['Hold countdown when unfight'], bCheck = true, bChecked = v.bFightHold, fnAction = function()
							v.bFightHold = not v.bFightHold
						end })
					end

					table.insert(menu, { bDevide = true })
					table.insert(menu, { szOption = _L['Color Picker'], bDisable = true })
					-- Color Picker
					for i = 0, 8 do
						table.insert(menu, {
							bMCheck = true,
							bChecked = v.nFrame == i,
							fnAction = function()
								v.nFrame = i
								X.UI.ClosePopupMenu()
							end,
							szIcon = PLUGIN_ROOT .. '/img/ST.UITex',
							nFrame = i,
							szLayer = 'ICON_FILL',
						})
					end
				else
					table.insert(menu, { szOption = _L['Please select type'], bDisable = true, bChecked = v.nClass == -1 })
					table.insert(menu, { bDevide = true })
					if szType == 'BUFF' or szType == 'DEBUFF' then
						for kk, vv in ipairs({ MY_TM_TYPE.BUFF_GET, MY_TM_TYPE.BUFF_LOSE }) do
							table.insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui, k)
							end })
						end
					elseif szType == 'CASTING' then
						table.insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.SKILL_END], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.SKILL_END, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.SKILL_END, ui, k)
						end })
						-- if tSkillInfo and tSkillInfo.CastTime ~= 0 then
							table.insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.SKILL_BEGIN], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.SKILL_BEGIN, fnAction = function()
								SetCountdownType(v, MY_TM_TYPE.SKILL_BEGIN, ui, k)
							end })
						-- end
					elseif szType == 'NPC' then
						for kk, vv in ipairs({ MY_TM_TYPE.NPC_ENTER, MY_TM_TYPE.NPC_LEAVE, MY_TM_TYPE.NPC_ALLLEAVE, MY_TM_TYPE.NPC_FIGHT, MY_TM_TYPE.NPC_DEATH, MY_TM_TYPE.NPC_ALLDEATH, MY_TM_TYPE.NPC_LIFE, MY_TM_TYPE.NPC_MANA }) do
							table.insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui, k)
							end })
						end
					elseif szType == 'DOODAD' then
						for kk, vv in ipairs({ MY_TM_TYPE.DOODAD_ENTER, MY_TM_TYPE.DOODAD_LEAVE, MY_TM_TYPE.DOODAD_ALLLEAVE }) do
							table.insert(menu, { szOption = _L['Countdown TYPE ' .. vv], bMCheck = true, bChecked = v.nClass == vv, fnAction = function()
								SetCountdownType(v, vv, ui, k)
							end })
						end
					elseif szType == 'TALK' then
						table.insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.TALK_MONITOR], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.TALK_MONITOR, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.TALK_MONITOR, ui, k)
						end })
					elseif szType == 'CHAT' then
						table.insert(menu, { szOption = _L['Countdown TYPE ' .. MY_TM_TYPE.CHAT_MONITOR], bMCheck = true, bChecked = v.nClass == MY_TM_TYPE.CHAT_MONITOR, fnAction = function()
							SetCountdownType(v, MY_TM_TYPE.CHAT_MONITOR, ui, k)
						end })
					end
				end
				return menu
			end,
			tip = {
				render = function()
					local szTip = GetFormatText(_L['Press CTRL click for advance menu'], 136)
					if X.IsString(v.key) then
						szTip = szTip .. GetFormatText('\n\nKEY: ' .. tostring(v.key), 136, 255, 255, 255)
					end
					return szTip, true
				end,
				position = X.UI.TIP_POSITION.LEFT_RIGHT,
			},
		}):Pos('BOTTOMRIGHT')
		-- ͼ��
		nX = ui:Append('Box', {
			x = nX + 5, y = nY, w = 24, h = 24, icon = v.nIcon or nIcon,
			onHover = function(bHover) this:SetObjectMouseOver(bHover) end,
			onClick = function()
				local box = this
				X.UI.OpenIconPicker(function(nIcon)
					v.nIcon = nIcon
					box:SetObjectIcon(nIcon)
				end)
			end,
		}):Pos('BOTTOMRIGHT')
		-- ����Ƶ������
		nX = ui:Append('WndCheckBox', {
			x = nX + 5, y = nY - 2, text = _L['TC'], color = GetMsgFontColor('MSG_TEAM', true), checked = v.bTeamChannel,
			onCheck = function(bCheck)
				v.bTeamChannel = bCheck and true or nil
			end,
			tip = {
				render = _L['Raid talk warning'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		}):AutoWidth():Pos('BOTTOMRIGHT')
		-- ��ͨ����ʱʱ��/�ֶε���ʱ
		ui:Append('WndEditBox', {
			name = 'CountdownTime' .. k,
			x = nX + 5, y = nY, w = 100, h = 25,
			text = v.nTime,
			color = (IsSimpleCountdown(v) or not select(2, ParseCountdown(v.nTime, v.nClass)))
				and { 255, 255, 255 }
				or { 255, 0, 0 },
			onChange = function(szNum)
				v.nTime = tonumber(szNum) or szNum
				local edit = ui:Children('#CountdownTime' .. k)
				if szNum == '' then
					return
				end
				if IsSimpleCountdown(v) then
					if this:GetW() > 200 then
						edit:Size(100, 25):Color(255, 255, 255)
						ui:Children('#CountdownName' .. k):Visible(true):Text(v.szName or g_tStrings.CHAT_NAME)
					end
				else
					local aCountdown, bError, bTrigger = ParseCountdown(szNum, v.nClass)
					if aCountdown then
						local tOperatorDesc = {
							['+'] = _L['(OPERATOR +)'],
							['-'] = _L['(OPERATOR -)'],
						}
						local xml = { GetFormatText(_L[bTrigger and 'Trigger preview' or 'Countdown preview'] .. '\n', 0, 255, 255, 0) }
						for kk, vv in ipairs(aCountdown) do
							table.insert(xml, GetFormatText(
								(
									bTrigger
										and ((vv.nValue * 100) .. '%')
										or X.FormatDuration(vv.nTime, 'SYMBAL', { mode = 'fixed-except-leading', maxunit = 'minute', keepunit = 'minute' })
								)
									.. (tOperatorDesc[vv.szOperator or ''] or '')
									.. ' - '
									.. FilterCustomText(vv.szContent, '{$sender}', '{$receiver}')
									.. (bTrigger and vv.nTime and (' (' .. vv.nTime .. 's)') or '')
									.. '\n'
							))
						end
						X.OutputTip(this, table.concat(xml), true)
					else
						HideTip()
					end
					if aCountdown and not bError then
						edit:Color(255, 255, 255)
					else
						edit:Color(255, 0, 0)
					end
					if this:GetW() < 200 then
						edit:Size(400, 25)
						ui:Children('#CountdownName' .. k):Visible(false)
					end
				end
			end,
			tip = {
				render = function()
					if v.nClass == MY_TM_TYPE.NPC_LIFE or v.nClass == MY_TM_TYPE.NPC_MANA then
						return _L['Life/mana statement.\n\nExample: 0.7-,Remain 70%;0.5-,Remain Half,2;0.01-,Almost empty,5'] .. '\n\n' .. _L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called']
					end
					return _L['Simple countdown time or multi countdown statement. Input pure number for simple countdown time, otherwise for multi countdown statement.\n\nMulti countdown example: 10,Countdown1;25,Countdown2;55,Countdown3\nExplain: Countdown1 finished will start Countdown2, so as Countdown3.'] .. '\n\n' .. _L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called']
				end,
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		})
		-- ��ͨ����ʱ�ı�
		nX = ui:Append('WndEditBox', {
			name = 'CountdownName' .. k,
			x = nX + 5 + 100 + 5, y = nY, w = 295, h = 25, text = v.szName,
			onChange = function(szName)
				v.szName = szName
			end,
			tip = {
				render = _L['Simple countdown text'] .. '\n\n' .. _L['Notice: Pattern can be used here in order to skip sensitive word scan. Currently supports:\n1. {$B188} Buff name which id is 188\n2. {$S188} Skill name which id is 188\n3. {$N188} Npc name which template id is 188\n4. {$D188} Doodad name which template id is 188\n5. {$me} Self name\n6. {$sender} Sender name, likes caller name\n7. {$receiver} Receiver name, likes teammate be called'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
			placeholder = _L['Please input simple countdown text...'],
		}):Pos('BOTTOMRIGHT')
		-- �ظ�����ʱ������
		nX = ui:Append('WndEditBox', {
			x = nX + 5, y = nY, w = 30, h = 25,
			text = v.nRefresh, editType = X.UI.EDIT_TYPE.NUMBER,
			onChange = function(szNum)
				v.nRefresh = tonumber(szNum)
			end,
			tip = {
				render = _L['Max repeat time\n\nWhen countdown get trigger again, the last countdown may get overwritten. This config is to sovle this problem, input time limit here to ensure in this time period, countdown will not be trigger again.'],
				position = X.UI.TIP_POSITION.BOTTOM_TOP,
			},
		}):Pos('BOTTOMRIGHT')
		-- ɾ����ť
		nX, nY = ui:Append('Image', {
			x = nX + 5, y = nY, w = 26, h = 26,
			image = file, imageFrame = 86,
			onHover = function(bIn)
				if bIn then
					this:SetFrame(87)
				else
					this:SetFrame(86)
				end
			end,
			onClick = function()
				if v.nClass ~= -1 then
					local nClass = v.key and MY_TM_TYPE.COMMON or v.nClass
					if data.dwID then
						local szKey = v.key or (k .. '.'  .. data.dwID .. '.' .. (data.nLevel or 0))
						FireUIEvent('MY_TM_ST_DEL', nClass, szKey) -- try kill
					else
						local szKey = v.key or (data.nIndex .. '.' .. k)
						FireUIEvent('MY_TM_ST_DEL', nClass, szKey) -- try kill
					end
				end
				if #data.tCountdown == 1 then
					data.tCountdown = nil
				else
					table.remove(data.tCountdown, k)
				end
				D.OpenSettingPanel(data, szType)
			end,
		}):Pos('BOTTOMRIGHT')
		FormatElPosByCountdownType(v, ui, k)
	end
	nX = ui:Append('WndButton', {
		x = 30, y = nY + 10,
		text = _L['Add countdown'],
		buttonStyle = 'FLAT',
		enable = not (data.tCountdown and #data.tCountdown > 10),
		onClick = function()
			if not data.tCountdown then
				data.tCountdown = {}
			end
			local szCountdown = _L['Countdown']
			local szPattern = GetPatternName()
			if szPattern then
				szCountdown = szCountdown .. ' ' .. szPattern
			end
			table.insert(data.tCountdown, {
				nTime = 10,
				szName = szCountdown,
				nClass = -1,
				nIcon = nIcon or 13,
			})
			D.OpenSettingPanel(data, szType)
		end,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 35
	-- ȦȦ����
	if (szType == 'NPC' or szType == 'DOODAD') and not X.IsRestricted('MY_TeamMon_CC') then
		nX, nY = ui:Append('Text', { x = 20, y = nY + 5, text = _L['Circle and line'], font = 27 }):AutoWidth():Pos('BOTTOMRIGHT')
		nX, nY = 30, nY + 5
		if szType == 'NPC' then
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY, w = 160, h = 25, text = _L['Only my employer'],
				checked = data.bDrawOnlyMyEmployer,
				onCheck = function(bCheck)
					data.bDrawOnlyMyEmployer = bCheck and true or nil
					FireUIEvent('MY_TM_CC_RELOAD')
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 160, h = 25, text = _L['Draw line'],
			checked = data.bDrawLine,
			onCheck = function(bCheck)
				data.bDrawLine = bCheck and true or nil
				FireUIEvent('MY_TM_CC_RELOAD')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		if szType == 'NPC' then
			nX = ui:Append('WndCheckBox', {
				x = nX, y = nY, w = 160, h = 25, text = _L['Only when stare me'],
				checked = data.bDrawLineOnlyStareMe,
				onCheck = function(bCheck)
					data.bDrawLineOnlyStareMe = bCheck and true or nil
					FireUIEvent('MY_TM_CC_RELOAD')
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		end
		nX, nY = ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 160, h = 25, text = _L['Draw name'],
			checked = data.bDrawName,
			onCheck = function(bCheck)
				data.bDrawName = bCheck and true or nil
				FireUIEvent('MY_TM_CC_RELOAD')
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT')
		nY = nY + 10
		-- ȦȦ�б�
		if data.aCircle then
			for k, circle in ipairs(data.aCircle) do
				nX = ui:Append('Shadow', {
					x = 35, y = nY + 3, w = 23, h = 23,
					color = circle.col,
					onClick = function()
						local ui = X.UI(this)
						X.UI.OpenColorPicker(function(r, g, b)
							ui:Color(r, g, b)
							circle.col = { r, g, b }
							FireUIEvent('MY_TM_CC_RELOAD')
						end)
					end,
				}):Pos('BOTTOMRIGHT')
				nX = ui:Append('WndEditBox', {
					x = nX + 5, y = nY + 2, w = 80, h = 26, text = circle.nAngle, editType = X.UI.EDIT_TYPE.NUMBER,
					onChange = function(nNum)
						circle.nAngle = tonumber(nNum) or 80
						FireUIEvent('MY_TM_CC_RELOAD')
					end,
				}):Pos('BOTTOMRIGHT')
				nX = ui:Append('Text', { x = nX, y = nY, text = _L['Degree'] }):AutoWidth():Pos('BOTTOMRIGHT')
				nX = ui:Append('WndEditBox', {
					x = nX + 10, y = nY + 2, w = 80, h = 26, text = circle.nRadius, editType = X.UI.EDIT_TYPE.NUMBER,
					onChange = function(nNum)
						circle.nRadius = tonumber(nNum) or 4
						FireUIEvent('MY_TM_CC_RELOAD')
					end,
				}):Pos('BOTTOMRIGHT')
				nX = ui:Append('Text', { x = nX, y = nY, text = _L['Meter'] }):AutoWidth():Pos('BOTTOMRIGHT')
				nX = ui:Append('WndEditBox', {
					x = nX + 10, y = nY + 2, w = 80, h = 26, text = circle.nAlpha, editType = X.UI.EDIT_TYPE.NUMBER,
					onChange = function(nNum)
						circle.nAlpha = tonumber(nNum)
						FireUIEvent('MY_TM_CC_RELOAD')
					end,
				}):Pos('BOTTOMRIGHT')
				nX = ui:Append('Text', { x = nX, y = nY, text = _L['Alpha'] }):AutoWidth():Pos('BOTTOMRIGHT')
				nX = ui:Append('WndCheckBox', {
					x = nX + 10, y = nY + 1,
					text = _L['Draw Border'],
					checked = circle.bBorder,
					onCheck = function(bChecked)
						circle.bBorder = bChecked
						FireUIEvent('MY_TM_CC_RELOAD')
					end,
				}):AutoWidth():Pos('BOTTOMRIGHT')
				nX = ui:Append('Image', {
					x = nX + 5, y = nY + 1,
					w = 26, h = 26,
					onHover = function(bIn)
						if bIn then
							this:SetFrame(87)
						else
							this:SetFrame(86)
						end
					end,
					onClick = function()
						if #data.aCircle == 1 then
							data.aCircle = nil
						else
							table.remove(data.aCircle, k)
						end
						FireUIEvent('MY_TM_CC_RELOAD')
						D.OpenSettingPanel(data, szType)
					end,
					image = file, imageFrame = 86,
				}):Pos('BOTTOMRIGHT')
				nY = nY + CHECKBOX_HEIGHT
			end
		end
		nX = ui:Append('WndButton', {
			x = 30, y = nY + 10,
			text = _L['Add circle'],
			buttonStyle = 'FLAT',
			enable = not (data.aCircle and #data.aCircle > 10),
			onClick = function()
				if not data.aCircle then
					data.aCircle = {}
				end
				table.insert(data.aCircle, {
					nAngle = 80,
					nRadius = 4,
					col = {0, 255, 0},
					bBorder = true,
				})
				FireUIEvent('MY_TM_CC_RELOAD')
				D.OpenSettingPanel(data, szType)
			end,
		}):Pos('BOTTOMRIGHT')
		nY = nY + 35
	end
	-- �����б�
	if MY_Focus then
		if szType == 'NPC' or szType == 'DOODAD' then
			nX, nY = ui:Append('Text', { x = 20, y = nY + 10, text = _L['Focuslist'], font = 27 }):Pos('BOTTOMRIGHT')
			nX, nY = 30, nY + 10
			for _, p in ipairs(data.aFocus or X.CONSTANT.EMPTY_TABLE) do
				nX = nX + ui:Append('WndButton', {
					x = nX, y = nY, w = 100,
					text = MY_Focus.FormatRuleText(p, true),
					buttonStyle = 'FLAT',
					onClick = function()
						local ui = X.UI(this)
						MY_Focus.OpenRuleEditor(p, function(dat)
							if dat then
								for k, v in pairs(dat) do
									if k ~= 'szPattern' and k ~= 'szMethod' then
										p[k] = v
									end
								end
								ui:Text(MY_Focus.FormatRuleText(dat, true))
							else
								for k, v in ipairs(data.aFocus) do
									if v == p then
										table.remove(data.aFocus, k)
										break
									end
								end
								D.OpenSettingPanel(data, szType)
							end
							FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
						end, true)
					end,
				}):Width() + 5
				if nX + 130 > nW then
					nX = 30
					nY = nY + BUTTON2_HEIGHT
				end
			end
			nX = ui:Append('WndButton', {
				x = nX, y = nY, w = 100,
				text = _L['Add focus'],
				buttonStyle = 'FLAT',
				onClick = function()
					if not data.aFocus then
						data.aFocus = {}
					end
					table.insert(data.aFocus, {})
					D.OpenSettingPanel(data, szType)
					FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
				end,
			}):Width() + 5
			nY = nY + BUTTON2_HEIGHT
		end
	end
	-- �Ŷ�����������
	if MY_Cataclysm then
		if szType == 'BUFF' or szType == 'DEBUFF' then
			nX, nY = ui:Append('Text', { x = 20, y = nY + 10, text = _L['Team panel buff rule list'], font = 27 }):Pos('BOTTOMRIGHT')
			nX, nY = 30, nY + 10
			for _, p in ipairs(data.aCataclysmBuff or X.CONSTANT.EMPTY_TABLE) do
				nX = nX + ui:Append('WndButton', {
					x = nX, y = nY, w = 100,
					text = MY_Cataclysm.EncodeBuffRule(p, true),
					buttonStyle = 'FLAT',
					onClick = function()
						local ui = X.UI(this)
						MY_Cataclysm.OpenBuffRuleEditor(p, function(dat)
							if dat then
								for k, v in pairs(dat) do
									if k ~= 'dwID' and k ~= 'nLevel' then
										p[k] = v
									end
								end
								ui:Text(MY_Cataclysm.EncodeBuffRule(dat, true))
							else
								for k, v in ipairs(data.aCataclysmBuff) do
									if v == p then
										table.remove(data.aCataclysmBuff, k)
										break
									end
								end
								D.OpenSettingPanel(data, szType)
							end
							FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
						end, nil, true)
					end,
				}):Width() + 5
				if nX + 130 > nW then
					nX = 30
					nY = nY + BUTTON2_HEIGHT
				end
			end
			nX = ui:Append('WndButton', {
				x = nX, y = nY, w = 100,
				text = _L['Add buff rule'],
				buttonStyle = 'FLAT',
				onClick = function()
					if not data.aCataclysmBuff then
						data.aCataclysmBuff = {}
					end
					table.insert(data.aCataclysmBuff, {})
					D.OpenSettingPanel(data, szType)
					FireUIEvent('MY_TM_DATA_RELOAD', { [szType] = true })
				end,
			}):Width() + 5
			nY = nY + BUTTON2_HEIGHT
		end
	end
	-- nX = ui:Append('WndButton', {
	-- 	x = 640, y = nY + 10, text = g_tStrings.HELP_PANEL,
	-- 	buttonStyle = 'FLAT',
	-- 	onClick = function()
	-- 		OpenInternetExplorer('https://github.com/luckyyyyy/JH/blob/master/JH_DBM/README.md')
	-- 	end,
	-- }):Pos('BOTTOMRIGHT')
	ui:Append('WndButton', {
		x = 335, y = nY + 10,
		text = g_tStrings.STR_FRIEND_DEL, color = { 255, 0, 0 },
		buttonStyle = 'FLAT',
		onClick = function()
			X.Confirm(_L['Sure to delete?'], function()
				D.RemoveData(data.dwMapID, data.nIndex, szName or _L['This data'])
			end)
		end,
	})
	nY = nY + 40
	ui:Size(nW, nY + 25):Anchor(MY_TMUI_PANEL_ANCHOR)
end

function D.UpdateAnchor(frame)
	local a = MY_TMUI_ANCHOR
	if not X.IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	end
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_TeamMon_UI')
end

D.IsOpened = D.GetFrame

function D.TogglePanel()
	if D.IsOpened() then
		D.ClosePanel()
	else
		D.OpenPanel()
	end
end
function D.OpenPanel(szType)
	if not D.IsOpened() then
		if szType then
			MY_TMUI_SELECT_TYPE = szType
		end
		Wnd.OpenWindow(MY_TMUI_INIFILE, 'MY_TeamMon_UI')
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function D.ClosePanel()
	if D.IsOpened() then
		FireUIEvent('MY_TMUI_FREECACHE')
		Wnd.CloseWindow(D.GetFrame())
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		X.RegisterEsc('MY_TeamMon')
	end
end

X.RegisterEvent('MY_TMUI_FREECACHE', function()
	MY_TMUI_SEARCH_CACHE = {}
end)
X.RegisterAddonMenu({ szOption = _L['MY_TeamMon'], fnAction = D.TogglePanel })
X.RegisterHotKey('MY_TeamMon_UI', _L['Open/close MY_TeamMon'], D.TogglePanel)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_UI',
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				OpenPanel       = D.OpenPanel,
				ClosePanel      = D.ClosePanel,
				IsOpened        = D.GetFrame,
				TogglePanel     = D.TogglePanel,
				OpenImportPanel = D.OpenImportPanel,
				OpenExportPanel = D.OpenExportPanel,
			},
		},
	},
}
MY_TeamMon_UI = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
