--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����������غ���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT ..'ui/PS.ini'
local IMG_PATH = X.PACKET_INFO.FRAMEWORK_ROOT ..'img/PS.UITex'
local FRAME_NAME = X.NSFormatString('{$NS}_PS')

local D = {}
---------------------------------------------------------------------------------------------
-- ���濪��
---------------------------------------------------------------------------------------------
function X.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function X.OpenPanel()
	if not X.AssertVersion('', '', '*') then
		return
	end
	if not X.IsInitialized() then
		return
	end
	local frame = X.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, FRAME_NAME)
		frame:Hide()
		frame.bVisible = false
		X.CheckTutorial()
	end
	return frame
end

function X.ClosePanel()
	local frame = X.GetFrame()
	if not frame then
		return
	end
	X.SwitchTab('Welcome')
	X.HidePanel(false, true)
	Wnd.CloseWindow(frame)
end

function X.ReopenPanel()
	if not X.IsPanelOpened() then
		return
	end
	local bVisible = X.IsPanelVisible()
	local szCurrentTabID = X.GetCurrentTabID()
	X.ClosePanel()
	X.OpenPanel()
	if szCurrentTabID then
		X.SwitchTab(szCurrentTabID)
	end
	X.TogglePanel(bVisible, true, true)
end

function X.ShowPanel(bMute, bNoAnimate)
	local frame = X.OpenPanel()
	if not frame then
		return
	end
	if not frame:IsVisible() then
		frame:Show()
		frame.bVisible = true
		if not bNoAnimate then
			frame.bToggling = true
			tweenlite.from(300, frame, {
				relY = frame:GetRelY() - 10,
				alpha = 0,
				complete = function()
					frame.bToggling = false
				end,
			})
		end
		if not bMute then
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end
	end
	frame:BringToTop()
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE, X.IsPanelVisible, function() X.HidePanel() end)
end

function X.HidePanel(bMute, bNoAnimate)
	local frame = X.GetFrame()
	if not frame then
		return
	end
	if not frame.bToggling then
		if bNoAnimate then
			frame:Hide()
		else
			local nY = frame:GetRelY()
			local nAlpha = frame:GetAlpha()
			tweenlite.to(300, frame, {relY = nY + 10, alpha = 0, complete = function()
				frame:SetRelY(nY)
				frame:SetAlpha(nAlpha)
				frame:Hide()
				frame.bToggling = false
			end})
			frame.bToggling = true
		end
		frame.bVisible = false
	end
	if not bMute then
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	X.RegisterEsc(X.PACKET_INFO.NAME_SPACE)
	UI.ClosePopupMenu()
end

function X.TogglePanel(bVisible, ...)
	if bVisible == nil then
		if X.IsPanelVisible() then
			X.HidePanel()
		else
			X.ShowPanel()
			X.FocusPanel()
		end
	elseif bVisible then
		X.ShowPanel(...)
		X.FocusPanel()
	else
		X.HidePanel(...)
	end
end

function X.FocusPanel(bForce)
	local frame = X.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function X.IsPanelVisible()
	local frame = X.GetFrame()
	return frame and frame:IsVisible()
end

function X.IsPanelOpened()
	return not not X.GetFrame()
end

---------------------------------------------------------------------------------------------
-- ѡ�
---------------------------------------------------------------------------------------------
local PANEL_CATEGORY_LIST = {
	{ szName = _L['General'] },
	{ szName = _L['Target' ] },
	{ szName = _L['Chat'   ] },
	{ szName = _L['Battle' ] },
	{ szName = _L['Raid'   ] },
	{ szName = _L['System' ] },
	{ szName = _L['Search' ] },
	{ szName = _L['Others' ] },
}
local PANEL_TAB_LIST = {}

function X.GetPanelCategoryList()
	return X.Clone(PANEL_CATEGORY_LIST)
end

local function IsTabRestricted(tTab)
	if tTab.szRestriction and X.IsRestricted(tTab.szRestriction) then
		return true
	end
	if tTab.IsRestricted then
		return tTab.IsRestricted()
	end
	return false
end

-- X.SwitchCategory(szCategory)
function X.SwitchCategory(szCategory)
	local frame = X.GetFrame()
	if not frame then
		return
	end

	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	local chk = container:GetFirstChild()
	while(chk and chk.szCategory ~= szCategory) do
		chk = chk:GetNext()
	end
	if not chk then
		chk = container:GetFirstChild()
	end
	if chk then
		chk:Check(true)
	end
end

function X.SwitchTab(szKey, bForceUpdate)
	local frame = X.GetFrame()
	if not frame then
		return
	end
	local tTab = lodash.find(PANEL_TAB_LIST, function(tTab) return tTab.szKey == szKey end)
	if not tTab then
		--[[#DEBUG BEGIN]]
		if not tTab then
			X.Debug(X.NSFormatString('{$NS}.SwitchTab'), _L('Cannot find tab: %s', szKey), X.DEBUG_LEVEL.WARNING)
		end
		--[[#DEBUG END]]
		return
	end
	-- �ж��������Ƿ���ȷ
	if tTab.szCategory and frame.szCurrentCategoryName ~= tTab.szCategory then
		X.SwitchCategory(tTab.szCategory)
	end
	-- �жϱ�ǩҳ�Ƿ��Ѽ���
	if frame.szCurrentTabKey == tTab.szKey and not bForceUpdate then
		return
	end
	if frame.szCurrentTabKey ~= tTab.szKey then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	-- �����ǩҳ����ѡ��״̬
	local scrollTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	for i = 0, scrollTabs:GetItemCount() - 1 do
		if scrollTabs:Lookup(i).szKey == szKey then
			scrollTabs:Lookup(i):Lookup('Image_Bg_Active'):Show()
		else
			scrollTabs:Lookup(i):Lookup('Image_Bg_Active'):Hide()
		end
	end
	-- �¼������������
	-- get main panel
	local wnd = frame.MAIN_WND
	local scroll = frame.MAIN_SCROLL
	-- fire custom registered on switch event
	if wnd.OnPanelDeactive then
		local res, err, trace = X.XpCall(wnd.OnPanelDeactive, wnd)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelDeactive'), trace)
		end
	end
	-- clear all events
	wnd.OnPanelActive   = nil
	wnd.OnPanelResize   = nil
	wnd.OnPanelScroll   = nil
	wnd.OnPanelBreathe  = nil
	wnd.OnPanelDeactive = nil
	-- reset main panel status
	scroll:SetScrollPos(0)
	wnd:Clear()
	wnd:Lookup('', ''):Clear()
	wnd:SetContainerType(UI.WND_CONTAINER_STYLE.CUSTOM)
	-- ready to draw
	if tTab.OnPanelActive then
		local res, err, trace = X.XpCall(tTab.OnPanelActive, wnd)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelActive'), trace)
		end
		wnd:FormatAllContentPos()
	end
	wnd.OnPanelActive   = tTab.OnPanelActive
	wnd.OnPanelResize   = tTab.OnPanelResize
	wnd.OnPanelScroll   = tTab.OnPanelScroll
	wnd.OnPanelBreathe  = tTab.OnPanelBreathe
	wnd.OnPanelDeactive = tTab.OnPanelDeactive
	frame.szCurrentTabKey = szKey
end

function X.RedrawTab(szKey)
	if X.GetCurrentTabID() == szKey then
		X.SwitchTab(szKey, true)
	end
end

function X.GetCurrentTabID()
	local frame = X.GetFrame()
	if not frame then
		return
	end
	return frame.szCurrentTabKey
end

-- ע��ѡ�
-- (void) X.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
-- szCategory      ѡ����ڷ���
-- szKey           ѡ�Ψһ KEY
-- szName          ѡ���ť����
-- szIconTex       ѡ�ͼ���ļ�|ͼ��֡
-- options         ѡ�������Ӧ���� {
--   options.szRestriction           ѡ��������ƻ�ȡ��ʶ��
--   options.bWelcome                ��ӭҳ��Ĭ��ҳ��ѡ�
--   options.OnPanelActive(wnd)      ѡ�����    wndΪ��ǰMainPanel
--   options.OnPanelDeactive(wnd)    ѡ�ȡ������
-- }
-- Ex�� X.RegisterPanel('����', 'Test', '���Ա�ǩ', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', { OnPanelActive = function(wnd) end })
function X.RegisterPanel(szCategory, szKey, szName, szIconTex, options)
	-- ���಻�����򴴽�
	if not options.bHide and not lodash.find(PANEL_CATEGORY_LIST, function(tCategory) return tCategory.szName == szCategory end) then
		table.insert(PANEL_CATEGORY_LIST, {
			szName = szCategory,
		})
	end
	-- �Ƴ��Ѵ��ڵ�
	for i, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szKey == szKey then
			table.remove(tTab, i)
			break
		end
	end
	-- �жϷ�ע��������
	if szName ~= false then
		-- ��ʽ��ͼ����Ϣ
		if X.IsNumber(szIconTex) then
			szIconTex = 'FromIconID|' .. szIconTex
		elseif not X.IsString(szIconTex) then
			szIconTex = 'UI/Image/Common/Logo.UITex|6'
		end
		local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
		if dwIconFrame then
			dwIconFrame = tonumber(dwIconFrame)
			szIconTex = string.gsub(szIconTex, '%|.*', '')
		end
		local nPriority = options.nPriority or (GetStringCRC(szKey) + 100000)
		-- �������ݽṹ����������
		table.insert(PANEL_TAB_LIST, {
			szKey           = szKey                  ,
			szName          = szName                 ,
			szCategory      = szCategory             ,
			szIconTex       = szIconTex              ,
			dwIconFrame     = dwIconFrame            ,
			nPriority       = nPriority              ,
			bWelcome        = options.bWelcome       ,
			bHide           = options.bHide          ,
			szRestriction   = options.szRestriction  ,
			IsRestricted    = options.IsRestricted   ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelScroll   = options.OnPanelScroll  ,
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelBreathe  = options.OnPanelBreathe ,
			OnPanelDeactive = options.OnPanelDeactive,
		})
		-- ���¸���Ȩ����������
		table.sort(PANEL_TAB_LIST, function(t1, t2)
			if t1.bWelcome then
				return true
			elseif t2.bWelcome then
				return false
			else
				return t1.nPriority < t2.nPriority
			end
		end)
	end
	-- ֪ͨ�ػ�
	FireUIEvent(X.NSFormatString('{$NS}_PANEL_UPDATE'))
end

---------------------------------------------------------------------------------------------
-- ���ں���
---------------------------------------------------------------------------------------------
function D.ResizePanel(frame, nWidth, nHeight)
	UI(frame):Size(nWidth, nHeight)
end

function D.RedrawCategory(frame, szCategory)
	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	container:Clear()
	for _, tCategory in ipairs(PANEL_CATEGORY_LIST) do
		if lodash.some(PANEL_TAB_LIST, function(tTab) return tTab.szCategory == tCategory.szName and not tTab.bHide and not IsTabRestricted(tTab) end) then
			local chkCategory = container:AppendContentFromIni(INI_PATH, 'CheckBox_Category')
			if not szCategory then
				szCategory = tCategory.szName
			end
			chkCategory.szCategory = tCategory.szName
			chkCategory:Lookup('', 'Text_Category'):SetText(tCategory.szName)
		end
	end
	container:FormatAllContentPos()
	X.SwitchCategory(szCategory)
end

function D.RedrawTabs(frame, szCategory)
	local scroll = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	scroll:Clear()
	for _, tTab in ipairs(PANEL_TAB_LIST) do
		if tTab.szCategory == szCategory and not tTab.bHide and not IsTabRestricted(tTab) then
			local hTab = scroll:AppendItemFromIni(INI_PATH, 'Handle_Tab')
			hTab.szKey = tTab.szKey
			hTab:Lookup('Text_Tab'):SetText(tTab.szName)
			if tTab.szIconTex == 'FromIconID' then
				hTab:Lookup('Image_TabIcon'):FromIconID(tTab.dwIconFrame)
			elseif tTab.dwIconFrame then
				hTab:Lookup('Image_TabIcon'):FromUITex(tTab.szIconTex, tTab.dwIconFrame)
			else
				hTab:Lookup('Image_TabIcon'):FromTextureFile(tTab.szIconTex)
			end
			hTab:Lookup('Image_Bg'):FromUITex(IMG_PATH, 0)
			hTab:Lookup('Image_Bg_Active'):FromUITex(IMG_PATH, 1)
			hTab:Lookup('Image_Bg_Hover'):FromUITex(IMG_PATH, 2)
		end
	end
	scroll:FormatAllItemPos()
	local tWelcomeTab = lodash.find(PANEL_TAB_LIST, function(tTab) return tTab.szCategory == szCategory and tTab.bWelcome and not IsTabRestricted(tTab) end)
		or lodash.find(PANEL_TAB_LIST, function(tTab) return not tTab.szCategory and tTab.bWelcome and not IsTabRestricted(tTab) end)
	if tWelcomeTab then
		X.SwitchTab(tWelcomeTab.szKey)
	end
end

function D.OnSizeChanged()
	local frame = this
	if not frame then
		return
	end
	-- fix size
	local nWidth, nHeight = frame:GetSize()
	local hTotal = frame:Lookup('', '')
	hTotal:Lookup('Text_Author'):SetRelY(nHeight - 25 - 30)
	hTotal:FormatAllItemPos()
	local wnd = frame:Lookup('Wnd_Total')
	wnd:Lookup('WndContainer_Category'):SetSize(nWidth - 22, 32)
	wnd:Lookup('WndContainer_Category'):FormatAllContentPos()
	wnd:Lookup('Btn_Weibo'):SetRelPos(nWidth - 135, 55)
	wnd:Lookup('WndScroll_Tabs'):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):FormatAllItemPos()
	wnd:Lookup('WndScroll_Tabs/ScrollBar_Tabs'):SetSize(16, nHeight - 111)

	local hWndTotal = wnd:Lookup('', '')
	wnd:Lookup('', ''):SetSize(nWidth, nHeight)
	hWndTotal:Lookup('Image_Breaker'):SetSize(6, nHeight - 340)
	hWndTotal:Lookup('Image_TabBg'):SetSize(nWidth - 2, 33)
	hWndTotal:Lookup('Handle_DBClick'):SetSize(nWidth, 54)

	local bHideTabs = nWidth < 550
	wnd:Lookup('WndScroll_Tabs'):SetVisible(not bHideTabs)
	hWndTotal:Lookup('Image_Breaker'):SetVisible(not bHideTabs)

	if bHideTabs then
		nWidth = nWidth + 181
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(5)
	else
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(186)
	end

	wnd:Lookup('WndScroll_MainPanel'):SetSize(nWidth - 191, nHeight - 100)
	frame.MAIN_SCROLL:SetSize(20, nHeight - 100)
	frame.MAIN_SCROLL:SetRelPos(nWidth - 209, 0)
	frame.MAIN_WND:SetSize(nWidth - 201, nHeight - 100)
	frame.MAIN_HANDLE:SetSize(nWidth - 201, nHeight - 100)
	local hWndMainPanel = frame.MAIN_WND
	if hWndMainPanel.OnPanelResize then
		local res, err, trace = X.XpCall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize'), trace)
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err, trace = X.XpCall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize->OnPanelDeactive'), trace)
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err, trace = X.XpCall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			X.ErrorLog(err, X.NSFormatString('{$NS}#OnPanelResize->OnPanelActive'), trace)
		end
		hWndMainPanel:FormatAllContentPos()
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function D.OnItemLButtonDBClick()
	local name = this:GetName()
	if name == 'Handle_DBClick' then
		this:GetRoot():Lookup('CheckBox_Maximize'):ToggleCheck()
	end
end

function D.OnMouseWheel()
	local el = this
	while el do
		if el:GetType() == 'WndContainer' then
			return
		end
		el = el:GetParent()
	end
	return true
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		X.ClosePanel()
	elseif name == 'Btn_Weibo' then
		X.OpenBrowser(X.PACKET_INFO.AUTHOR_WEIBO_URL)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Tab' then
		X.SwitchTab(this.szKey)
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Category' then
		local frame = this:GetRoot()
		local container = this:GetParent()
		local el = container:GetFirstChild()
		while el do
			if el ~= this then
				el:Check(false)
			end
			el = el:GetNext()
		end
		frame.szCurrentCategoryName = this.szCategory
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		D.RedrawTabs(frame, this.szCategory)
	elseif name == 'CheckBox_Maximize' then
		local frame = this:GetRoot()
		local ui = UI(frame)
		frame.tMaximizeAnchor = ui:Anchor()
		frame.nMaximizeW, frame.nMaximizeH = ui:Size()
		ui:Pos(0, 0):Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
			ui:Size(Station.GetClientSize())
		end):Drag(false)
		D.ResizePanel(frame, Station.GetClientSize())
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local frame = this:GetRoot()
		D.ResizePanel(frame, frame.nMaximizeW, frame.nMaximizeH)
		UI(this:GetRoot())
			:Event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			:Drag(true)
			:Anchor(frame.tMaximizeAnchor)
	end
end

function D.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = UI(this:GetRoot()):Size()
	end
end

function D.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = math.max(this.fDragW + nDeltaX, 500)
		local nH = math.max(this.fDragH + nDeltaY, 300)
		D.ResizePanel(this:GetRoot(), nW, nH)
	end
end

function D.OnFrameCreate()
	this.MAIN_SCROLL = this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel')
	this.MAIN_WND = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	this.MAIN_HANDLE = this:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel', '')
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(_L('%s v%s Build %s', X.PACKET_INFO.NAME, X.PACKET_INFO.VERSION, X.PACKET_INFO.BUILD))
	this:Lookup('', 'Text_Author'):SetText('-- by ' .. X.PACKET_INFO.AUTHOR_SIGNATURE)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L('Author @%s', X.PACKET_INFO.AUTHOR_WEIBO))
	this:Lookup('Wnd_Total/Btn_Weibo', 'Image_Icon'):FromUITex(X.PACKET_INFO.LOGO_UITEX, X.PACKET_INFO.LOGO_MAIN_FRAME)
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	UI(this):Size(D.OnSizeChanged)
	D.RedrawCategory(this)
	D.ResizePanel(this, 960 * fScale, 630 * fScale)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
end

function D.OnFrameBreathe()
	if this.MAIN_WND and this.MAIN_WND.OnPanelBreathe then
		X.Call(this.MAIN_WND.OnPanelBreathe, this.MAIN_WND)
	end
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		X.ExecuteWithThis(this.MAIN_SCROLL, X.OnScrollBarPosChanged)
		D.OnSizeChanged()
	end
end

function D.OnScrollBarPosChanged()
	local name = this:GetName()
	if name == 'ScrollBar_MainPanel' then
		local wnd = this:GetRoot().MAIN_WND
		if not wnd.OnPanelScroll then
			return
		end
		local scale = Station.GetUIScale()
		local scrollX, scrollY = wnd:GetStartRelPos()
		scrollX = scrollX == 0 and 0 or -scrollX / scale
		scrollY = scrollY == 0 and 0 or -scrollY / scale
		wnd.OnPanelScroll(wnd, scrollX, scrollY)
	end
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end
