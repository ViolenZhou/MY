--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����˵�
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------

local PLUGIN_NAME = X.NSFormatString('{$NS}_PopupMenu')
local COLOR_TABLE_NAME = X.NSFormatString('{$NS}_ColorTable')
local COLOR_PICKER_NAME = X.NSFormatString('{$NS}_ColorPickerEx')

local D = {}
local SZ_INI = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/PopupMenu.ini'
local SZ_TPL_INI = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/PopupMenu.tpl.ini'
local LAYER_LIST = {'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2'}
local ENABLE_FONT = 162
local DISABLE_FONT = 161
local PADDING_H = 8 -- ����ͼ���ұ߿���
local PADDING_V = 8 -- ����ͼ���±߿���
local DIFF_KEYS = { -- �����Զ�ɨ��˵������Ƿ��и��µļ�
	'szImagePath',
	'nBgFrame',
	'nBgAlpha',
	'szOverImgPath',
	'nOverFrame',
	'szOption',
	'bRichText',
	'fnAction',
	'bInline',
	'bDivide',
	'bDevide',
	'r',
	'g',
	'b',
	'rgb',
	'bCheck',
	'bMCheck',
	'bChecked',
	'aCustomIcon',
	'szIcon',
	'nFrame',
	'nMouseOverFrame',
	'nIconWidth',
	'nIconHeight',
	'fnClickIcon',
	'szLayer',
	'bDisable',
	'fnAction',
}

--[[
	menu = {
		nWidth = 200,
		nMinWidth = 100,
		nMaxWidth = 300,
		{
			szOption = 'Option 0',
			bDisable = true,
			bAlwaysShowSub = true,
		},
		{
			bInline = true,
			nMaxHeight = 200,
			{
				szOption = 'Option 1',
				fnAction = function()
					Output('1')
				end,
			},
		},
	}
]]

function D.Open(menu)
	local frame = D.GetFrame()
	if not frame then
		if not menu.bDisableSound then
			PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
		end
		frame = Wnd.OpenWindow(SZ_INI, PLUGIN_NAME)
	end
	if not menu.bShowKillFocus then
		Station.SetFocusWindow(frame)
	end
	frame.nCurX, frame.nCurY = Cursor.GetPos()
	frame:SetDS(menu)
end

function D.Close()
	local frame = D.GetFrame()
	if frame then
		Wnd.CloseWindow(frame)
	end
	Wnd.CloseWindow('PopupMenuPanel')
end

function D.GetFrame()
	for _, v in ipairs(LAYER_LIST) do
		local frame = Station.Lookup(v .. '/' .. PLUGIN_NAME)
		if frame then
			return frame
		end
	end
end

function D.SetDS(frame, menu)
	frame.aMenu = {menu}
	frame.aMenuY = {0}
	frame.aInvalid = {true}
	if menu.szLayer then
		frame:ChangeRelation(menu.szLayer)
	end
	if not Station.IsVisible() then
		frame:ShowWhenUIHide()
	end
	D.CalcDisable(menu)
	D.UpdateUI(frame)
end

function D.AppendContentFromIni(parentWnd, szIni, szPath, szName)
	local frameTemp = Wnd.OpenWindow(szIni, PLUGIN_NAME .. '__TempWnd')
	local wnd = frameTemp:Lookup(szPath)
	if wnd then
		if szName then
			wnd:SetName(szName)
		end
		wnd:ChangeRelation(parentWnd, true, true)
	end
	Wnd.CloseWindow(frameTemp)
	return wnd
end

-----------------------------------------------
-- �ж������˵�ѡ�����ϲ�˵��ǲ���һ��
-----------------------------------------------
function D.IsEquals(m1, m2)
	if not m1 or not m2 then
		return false
	end
	if #m1 ~= #m2 then
		return false
	end
	for i = 1, #m1 do
		local ms1, ms2 = m1[i], m2[i]
		for _, k in ipairs(DIFF_KEYS) do
			if not X.IsEquals(ms1[k], ms2[k]) then
				return false
			end
		end
		if (#ms1 == 0) ~= (#ms2 == 0) then
			return false
		end
		if ms1.bInline and not D.IsEquals(ms1, ms2) then
			return false
		end
	end
	return true
end

-- �ж�һ���˵��Ƿ�ɽ���
function D.IsDisable(menu)
	if menu.bDisable or menu.bDevide or menu.bDivide then
		return true
	end
	return false
end

-- ��¡һ���˵������� ���ڽ�������
function D.Clone(menu)
	local m = {}
	for _, k in ipairs(DIFF_KEYS) do
		m[k] = X.Clone(menu[k])
	end
	for i, v in ipairs(menu) do
		m[i] = D.Clone(v)
	end
	return m
end

-- ����������״̬��ֹ��˸ ������ˢ�¿�Ⱥ�ִ��
function D.UpdateMouseOver(scroll, nCurX, nCurY)
	local container = scroll:Lookup('WndContainer_Menu')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:GetName() == 'Wnd_Item' then
			local h = wnd:Lookup('', '')
			local hFooter = h:Lookup('Handle_Item_R')
			for i = 0, hFooter:GetItemCount() - 1 do
				local hItem = hFooter:Lookup(i)
				local szName = hItem:GetName()
				if szName == 'Handle_CustomIcon' then
					hItem:Lookup('Image_CustomIconHover'):SetVisible(hItem:PtInItem(nCurX, nCurY))
				elseif szName == 'Handle_Color' then
					hItem:Lookup('Image_ColorHover'):SetVisible(hItem:PtInItem(nCurX, nCurY))
				end
			end
			h:Lookup('Image_Over'):SetVisible(not D.IsDisable(wnd.menu) and h:PtInItem(nCurX, nCurY))
		elseif wnd:GetName() == 'WndScroll_Menu' then
			D.UpdateMouseOver(wnd, nCurX, nCurY)
		end
	end
end

function D.GetPadding(top)
	return top.nPaddingTop or top.nPaddingVertical or top.nPadding or PADDING_V,
		top.nPaddingBottom or top.nPaddingVertical or top.nPadding or PADDING_V,
		top.nPaddingLeft or top.nPaddingHorizontal or top.nPadding or PADDING_H,
		top.nPaddingRight or top.nPaddingHorizontal or top.nPadding or PADDING_H
end

-- ������Ⱦ�����ݵ���ѡ���ȣ����ڿ����������Ԫ��Ӱ�� ���Զ����ɺ����ڻ��ƽ�����ͳһ���ã�
function D.UpdateScrollContainerWidth(scroll, nHeaderWidth, nContentWidth, nFooterWidth, nPaddingRight, bInlineContainer)
	local nWidth = nHeaderWidth + nContentWidth + nFooterWidth
	local container = scroll:Lookup('WndContainer_Menu')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd:GetName() == 'Wnd_Item' then
			local h = wnd:Lookup('', '')
			local hHeader = h:Lookup('Handle_Item_L')
			local hContent = h:Lookup('Handle_Content')
			local hFooter = h:Lookup('Handle_Item_R')
			local nLineFooterWidth = hFooter:GetAllItemSize()
			hHeader:SetW(nHeaderWidth)
			hContent:SetW(nContentWidth + nFooterWidth - nLineFooterWidth)
			hContent:SetRelX(nHeaderWidth)
			hFooter:SetW(nLineFooterWidth)
			hFooter:SetRelX(nHeaderWidth + nContentWidth + nFooterWidth - nLineFooterWidth)
			h:Lookup('Image_Background'):SetW(nWidth)
			h:Lookup('Image_Over'):SetW(nWidth)
			h:Lookup('Image_Devide'):SetW(nWidth)
			h:SetW(nWidth)
			h:FormatAllItemPos()
			wnd:SetW(nWidth)
		elseif wnd:GetName() == 'WndScroll_Menu' then
			D.UpdateScrollContainerWidth(wnd, nHeaderWidth, nContentWidth, nFooterWidth, nPaddingRight, true)
		end
	end
	container:SetW(nWidth)
	-- ������λ�ô�С
	local nWidth, nHeight = container:GetSize()
	scroll:Lookup('Scroll_Menu'):SetH(nHeight)
	scroll:Lookup('Scroll_Menu'):SetRelX(bInlineContainer and (nWidth - nPaddingRight) or nWidth)
	scroll:Lookup('Scroll_Menu/WndButton_Scroll_Menu'):SetH(math.min(nHeight * 2 / 3, 40))
	scroll:SetW(math.max(nWidth, scroll:Lookup('Scroll_Menu'):GetRelX() + scroll:Lookup('Scroll_Menu'):GetW()))
end

-- ����ѡ���б�
function D.DrawScrollContainer(scroll, top, menu, nLevel, bInlineContainer)
	local nHeaderWidth, nContentWidth, nFooterWidth = 10, 0, 10
	local nPaddingTop, nPaddingBottom, nPaddingLeft, nPaddingRight = D.GetPadding(top)
	local container = scroll:Lookup('WndContainer_Menu')
	container:Clear()
	for _, m in ipairs(menu) do
		if m.bInline then
			local scroll = container:AppendContentFromIni(SZ_TPL_INI, 'WndScroll_Menu')
			local n1, n2, n3 = D.DrawScrollContainer(scroll, top, m, nLevel, true)
			nHeaderWidth = math.max(nHeaderWidth, n1)
			nContentWidth = math.max(nContentWidth, n2)
			nFooterWidth = math.max(nFooterWidth, n3)
		else
			local wnd = container:AppendContentFromIni(SZ_TPL_INI, 'Wnd_Item')
			local h = wnd:Lookup('', '')
			local hHeader = h:Lookup('Handle_Item_L')
			local hContent = h:Lookup('Handle_Content')
			local hFooter = h:Lookup('Handle_Item_R')
			local imgDevide = h:Lookup('Image_Devide')
			local imgBg = h:Lookup('Image_Background')
			if top.szOverImgPath and top.nOverFrame then
				h:Lookup('Image_Over'):FromUITex(top.szOverImgPath, top.nOverFrame)
			end
			if m.bDevide or m.bDivide then
				imgDevide:Show()
				wnd:SetH(imgDevide:GetH())
				hHeader:Hide()
				hContent:Hide()
				hFooter:Hide()
				h:ClearHoverElement()
			else
				imgDevide:Hide()
				-- ����
				local szBgUITex, nBgFrame = m.szBgUITex, m.nBgFrame
				if m.szIcon and m.szLayer == 'ICON_FILL' then
					szBgUITex = m.szIcon
					nBgFrame = m.nFrame
				end
				if szBgUITex then
					if szBgUITex and nBgFrame then
						imgBg:FromUITex(szBgUITex, nBgFrame)
					elseif szBgUITex then
						imgBg:FromTextureFile(szBgUITex)
					end
					imgBg:Show()
				else
					imgBg:Hide()
				end
				-- �Զ���ͼ��
				local aCustomIcon = {}
				if m.aCustomIcon then
					for _, v in ipairs(m.aCustomIcon) do
						table.insert(aCustomIcon, v)
					end
				end
				if m.szIcon and m.szLayer ~= 'ICON_FILL' then
					table.insert(aCustomIcon, {
						szPosType = m.szLayer == 'ICON_LEFT' and 'LEFT' or 'RIGHT',
						szUITex = m.szIcon ~= 'fromiconid' and m.szIcon or nil,
						nFrame = m.szIcon ~= 'fromiconid' and m.nFrame or nil,
						nIconID = m.szIcon == 'fromiconid' and m.nFrame or nil,
						szHoverUITex = m.szIcon,
						nHoverFrame = m.nMouseOverFrame,
						nWidth = m.nIconWidth,
						nHeight = m.nIconHeight,
						fnAction = m.fnClickIcon,
					})
				end
				for _, v in ipairs(aCustomIcon) do
					local hDest = v.szPosType == 'LEFT' and hHeader or hFooter
					local hCustom = hDest:AppendItemFromIni(SZ_TPL_INI, 'Handle_CustomIcon')
					if hDest == hFooter then
						while hCustom:GetIndex() > 1 and hFooter:Lookup(hCustom:GetIndex() - 1):GetName() ~= 'Handle_Color' do
							hCustom:ExchangeIndex(hCustom:GetIndex() - 1)
						end
					end
					-- ͼ��
					local img = hCustom:Lookup('Image_CustomIcon')
					local imgHover = hCustom:Lookup('Image_CustomIconHover')
					if v.szUITex and v.nFrame then
						img:FromUITex(v.szUITex, v.nFrame)
					elseif v.szUITex then
						img:FromTextureFile(v.szUITex)
					elseif v.nIconID then
						img:FromIconID(v.nIconID)
					end
					if v.nWidth then
						img:SetW(v.nWidth)
						imgHover:SetW(v.nWidth)
					end
					if v.nHeight then
						img:SetH(v.nHeight)
						imgHover:SetH(v.nHeight)
					end
					img:SetRelY((hCustom:GetH() - img:GetH()) / 2)
					-- ��껬��
					if v.szHoverUITex and v.nHoverFrame then
						imgHover:FromUITex(v.szHoverUITex, v.nHoverFrame)
					elseif v.szHoverUITex then
						imgHover:FromTextureFile(v.szHoverUITex)
					elseif v.nIconID then
						imgHover:FromIconID(v.nHoverIconID)
					end
					if v.nHoverWidth then
						imgHover:SetW(v.nHoverWidth)
					end
					if v.nHoverHeight then
						imgHover:SetW(v.nHoverHeight)
					end
					imgHover:SetRelY((hCustom:GetH() - imgHover:GetH()) / 2)
					-- ��������
					hCustom:FormatAllItemPos()
					hCustom:SetHoverElement('Image_CustomIconHover')
					hCustom.data = v
					hCustom.menu = m
				end
				-- ���ͼ��
				hHeader:Lookup('Handle_Check'):SetVisible(m.bCheck and not m.bMCheck and m.bChecked)
				hHeader:Lookup('Handle_MCheck'):SetVisible(m.bMCheck and m.bChecked)
				hHeader:SetW(99999)
				hHeader:FormatAllItemPos()
				nHeaderWidth = math.max(nHeaderWidth, (hHeader:GetAllItemSize()))
				-- ����
				local hContentInner = hContent:Lookup('Handle_ContentInner')
				local nFont = D.IsDisable(m) and DISABLE_FONT or ENABLE_FONT
				local rgb = m.rgb or X.CONSTANT.EMPTY_TABLE
				local r, g, b = rgb.r or rgb[1] or m.r, rgb.g or rgb[2] or m.g, rgb.b or rgb[3] or m.b
				if D.IsDisable(m) then
					r, g, b = nil, nil, nil
				end
				hContentInner:AppendItemFromString(m.bRichText and m.szOption or GetFormatText(m.szOption, nFont, r, g, b))
				hContentInner:SetW(99999)
				hContentInner:FormatAllItemPos()
				hContentInner:SetSizeByAllItemSize()
				hContentInner:SetRelY((hContent:GetH() - hContentInner:GetH()) / 2)
				hContent:SetW(hContentInner:GetW())
				hContent:FormatAllItemPos()
				nContentWidth = math.max(nContentWidth, hContent:GetW())
				-- �Ҳ�ͼ��
				if m.nPushCount then
					hFooter:Lookup('Handle_PushInfo/Text_PushInfo'):SetText(m.nPushCount)
					hFooter:Lookup('Handle_PushInfo'):Show()
				else
					hFooter:Lookup('Handle_PushInfo'):Hide()
				end
				hFooter:Lookup('Handle_Color'):SetVisible(m.fnChangeColor and true or false)
				hFooter:Lookup('Handle_Child'):SetVisible(#m > 0)
				hFooter:SetW(99999)
				hFooter:FormatAllItemPos()
				nFooterWidth = math.max(nFooterWidth, hFooter:GetAllItemSize())
			end
			wnd.menu = m
			wnd.nLevel = nLevel + 1
		end
	end
	-- �����������߶�
	container:SetW(1) -- ��ֹ�˵�ͬ������
	container:FormatAllContentPos()
	local nHeight = select(2, container:GetAllContentSize())
	if menu.nMaxHeight then
		nHeight = math.min(nHeight, menu.nMaxHeight)
	end
	nHeight = math.min(nHeight, select(2, Station.GetClientSize()) - nPaddingTop - nPaddingBottom)
	container:SetH(nHeight)
	container:FormatAllContentPos() -- ����KGUI��BUG ��������߶Ⱥ�����Formatһ��Ļ� һ�����������
	scroll:SetH(nHeight)
	-- ��Ƕ�ײ���ʼ�������п��
	if not bInlineContainer then
		if menu.nWidth then
			nContentWidth = math.max(menu.nWidth - nHeaderWidth - nFooterWidth - nPaddingLeft - nPaddingRight, 0)
		else
			local nMinWidth = menu.nMinWidth or menu.nMiniWidth
			if nMinWidth then
				nContentWidth = math.max(nMinWidth - nHeaderWidth - nFooterWidth - nPaddingLeft - nPaddingRight, nContentWidth)
			end
			if menu.nMaxWidth then
				nContentWidth = math.max(math.min(nContentWidth, menu.nMaxWidth - nHeaderWidth - nFooterWidth - nPaddingLeft - nPaddingRight), 0)
			end
		end
		D.UpdateScrollContainerWidth(scroll, nHeaderWidth, nContentWidth, nFooterWidth, nPaddingRight, false)
		D.UpdateMouseOver(scroll, Cursor.GetPos())
	end
	return nHeaderWidth, nContentWidth, nFooterWidth
end

function D.DrawWnd(wnd, top, menu, nLevel)
	--[[#DEBUG BEGIN]]
	X.Debug(PLUGIN_NAME, 'Draw wnd at level ' .. nLevel, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	-- �����б�
	local scroll = wnd:Lookup('WndScroll_Menu')
	local container = scroll:Lookup('WndContainer_Menu')
	D.DrawScrollContainer(scroll, top, menu, nLevel, false)
	-- ���Ʊ���
	local nWidth, nHeight = container:GetSize()
	local nPaddingTop, nPaddingBottom, nPaddingLeft, nPaddingRight = D.GetPadding(top)
	local nWWidth, nWHeight = nWidth + nPaddingLeft + nPaddingRight, nHeight + nPaddingTop + nPaddingBottom
	scroll:SetRelY(nPaddingTop)
	wnd:SetSize(nWWidth, nWHeight)
	wnd:Lookup('', ''):SetSize(nWWidth, nWHeight)
	wnd:Lookup('', 'Image_Bg'):SetSize(nWWidth, nWHeight)
	if top.szImagePath and top.nBgFrame then
		wnd:Lookup('', 'Image_Bg'):FromUITex(top.szImagePath, top.nBgFrame)
	end
	if top.nBgAlpha then
		wnd:Lookup('', 'Image_Bg'):SetAlpha(top.nBgAlpha)
	end
	wnd.nLevel = nLevel
	wnd.menu = menu
end

-- �ж�һ���˵��������ǲ�����һ��������
function D.IsSubMenu(menu, t)
	if X.IsTable(menu) then
		for _, v in ipairs(menu) do
			if v == t then
				return true
			end
			if v.bInline and D.IsSubMenu(v, t) then
				return true
			end
		end
	end
	return false
end

-- �������˵�λ�ü���ˢ�¸��Ӳ˵�λ��
function D.UpdateWndPos(frame)
	local nW, nH = Station.GetClientSize()
	local aMenu = frame.aMenu
	local aMenuY = frame.aMenuY
	-- ���˵�
	local wnd = frame:Lookup('Wnd_Menu1')
	local menu = aMenu[1]
	if menu.x ~= 'keep' then
		local nX0, nX = menu.x or frame.nCurX, nil
		if nX0 + wnd:GetW() <= nW then
			nX = nX0
		elseif nX0 - wnd:GetW() >= 0 then
			nX = nX0 - wnd:GetW()
		else
			nX = nW - wnd:GetW()
		end
		wnd:SetRelX(nX)
	end
	if menu.y ~= 'keep' then
		local nY0, nY = menu.y or frame.nCurY, nil
		if nY0 + wnd:GetH() <= nH then
			nY = nY0
		elseif nY0 - wnd:GetH() >= 0 then
			nY = nY0 - wnd:GetH()
		else
			nY = nH - wnd:GetH()
		end
		wnd:SetRelY(nY)
	end
	-- �Ӳ˵�
	for nLevel = 2, #aMenu do
		local wnd = frame:Lookup('Wnd_Menu' .. nLevel)
		local wndPrev = frame:Lookup('Wnd_Menu' .. (nLevel - 1))
		local nX = wndPrev:GetAbsX() + wndPrev:GetW() + wnd:GetW() > nW
			and wndPrev:GetRelX() - wnd:GetW()
			or wndPrev:GetRelX() + wndPrev:GetW()
		local nY = (frame:GetAbsY() + aMenuY[nLevel] + wnd:GetH() > nH)
			and nH - wnd:GetH()
			or aMenuY[nLevel]
		wnd:SetRelPos(nX, nY)
	end
end

-- ����menu����ˢ����ʾ
function D.UpdateUI(frame)
	-- ����ģ��
	local wnd = frame:Lookup('Wnd_Menu')
	if wnd then
		wnd:Destroy()
	end
	-- ������Ʋ˵�
	local aMenu, nExistLevel, bExist, bDrawed = frame.aMenu, frame.nExistLevel or 0, true, false
	for nLevel = 1, math.max(#aMenu, nExistLevel) do
		local menu = aMenu[nLevel]
		local wnd = frame:Lookup('Wnd_Menu' .. nLevel)
		if nLevel > 1 then
			bExist = menu and D.IsSubMenu(aMenu[nLevel - 1], menu)
		end
		if bExist then -- ȷ�ϻ���
			if not wnd then
				wnd = D.AppendContentFromIni(frame, SZ_TPL_INI, 'Wnd_Menu', 'Wnd_Menu' .. nLevel)
			end
			if frame.aInvalid[nLevel] or not D.IsEquals(wnd.menuSnapshot, menu) then
				D.DrawWnd(wnd, aMenu[1], menu, nLevel)
				bDrawed = true
				frame.aInvalid[nLevel] = false
				wnd.menuSnapshot = D.Clone(menu)
			end
		else -- ��Ҫ����Ĳ˵����Ѳ����ڣ�
			if wnd then
				wnd:Destroy()
			end
			aMenu[nLevel] = nil
		end
	end
	if bDrawed then
		frame.nExistLevel = #aMenu
		D.UpdateWndPos(frame)
	end
end

-- �����Զ����ú���ˢ�½���״̬
function D.CalcDisable(menu)
	for _, v in ipairs(menu) do
		if v.fnDisable then
			v.bDisable = v.fnDisable(v.UserData)
		end
		if #v > 0 then
			D.CalcDisable(v)
		end
	end
end

function D.FireAction(frame, menu, fnAction, ...)
	if fnAction and fnAction(menu.UserData, ...) == 0 then
		Wnd.CloseWindow(frame)
	end
end

function D.OnFrameCreate()
	this:SetRelPos(0, 0)
	this.SetDS = D.SetDS
end

function D.OnFrameDestroy()
	local top = this.aMenu[1]
	if not top.bDisableSound then
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

function D.OnFrameBreathe()
	local top = this.aMenu[1]
	if not top.bShowKillFocus then
		local wnd = Station.GetFocusWindow()
		local frame = wnd and wnd:GetRoot()
		local name = frame and frame:GetName()
		if frame and frame ~= this and name ~= COLOR_TABLE_NAME and name ~= COLOR_PICKER_NAME then
			if top.fnCancel then
				top.fnCancel()
			end
			if this.bColorPicker then
				Wnd.CloseWindow(COLOR_TABLE_NAME)
				Wnd.CloseWindow(COLOR_PICKER_NAME)
			end
			return Wnd.CloseWindow(this)
		end
	end
	if top.fnAutoClose and top.fnAutoClose() then
		return Wnd.CloseWindow(this)
	end
	D.CalcDisable(top)
	D.UpdateUI(this)
end

function D.OnItemMouseEnter()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent() -- 'Wnd_Item'
		local frame = this:GetRoot()
		local menu = wnd.menu
		local nLevel = wnd.nLevel
		if #menu ~= 0 and (not D.IsDisable(menu) or menu.bAlwaysShowSub) then
			X.DelayCall(PLUGIN_NAME .. '__HideSub', false)
			-- �����Ӳ˵�
			for i = nLevel, #frame.aMenu do
				frame.aMenu[i] = nil
			end
			frame.aMenu[nLevel] = menu
			-- ��¼����λ��
			for i = nLevel, #frame.aMenuY do
				frame.aMenuY[i] = nil
			end
			frame.aMenuY[nLevel] = this:GetAbsY() - frame:GetAbsY()
			-- �����Ч����
			frame.aInvalid[nLevel] = true
			-- ����UI
			D.UpdateUI(frame)
		elseif frame.nAutoHideLevel ~= nLevel or not X.DelayCall(PLUGIN_NAME .. '__HideSub') then -- 3000ms��ر�֮ǰչ�����Ӳ˵�
			X.DelayCall(PLUGIN_NAME .. '__HideSub', 1000, function()
				if not X.IsElement(wnd) then
					return
				end
				for i = nLevel, #frame.aMenu do
					frame.aMenu[i] = nil
				end
				frame.nAutoHideLevel = nil
				D.UpdateUI(frame)
			end)
			frame.nAutoHideLevel = nLevel
		end
		if menu.fnMouseEnter then
			menu.fnMouseEnter(menu.UserData)
		end
	elseif name == 'Handle_Color' then
		X.ExecuteWithThis(this:GetParent():GetParent(), D.OnItemMouseEnter)
	elseif name == 'Handle_CustomIcon' then
		X.ExecuteWithThis(this:GetParent():GetParent(), D.OnItemMouseEnter)
	end
end

function D.OnItemMouseLeave()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent() -- 'Wnd_Item'
		local menu = wnd.menu
		if menu.fnMouseLeave then
			menu.fnMouseLeave(menu.UserData)
		end
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Item' then
		local wnd = this:GetParent() -- 'Wnd_Item'
		local frame = this:GetRoot()
		local menu = wnd.menu
		if D.IsDisable(menu) then
			return
		end
		if menu.bMCheck then
			local p = wnd:GetPrev()
			while p do
				if p.menu.bDevide or p.menu.bDivide then
					break
				end
				if p.menu.bMCheck then
					p.menu.bChecked = false
				end
				p = p:GetPrev()
			end
			local p = wnd:GetNext()
			while p do
				if p.menu.bDevide or p.menu.bDivide then
					break
				end
				if p.menu.bMCheck then
					p.menu.bChecked = false
				end
				p = p:GetNext()
			end
			menu.bChecked = not menu.bChecked
			D.FireAction(frame, menu, menu.fnAction, menu.bChecked)
		elseif menu.bCheck then
			menu.bChecked = not menu.bChecked
			D.FireAction(frame, menu, menu.fnAction, menu.bChecked)
		else
			D.FireAction(frame, menu, menu.fnAction)
		end
	elseif name == 'Handle_Color' then
		local wnd = this:GetParent():GetParent():GetParent() -- 'Wnd_Item'
		local frame = this:GetRoot()
		frame.bColorPicker = true
		X.UI.OpenColorPicker(function(r, g, b)
			if not wnd or not wnd:IsValid() then
				return
			end
			if wnd.menu.fnChangeColor(wnd.menu.UserData, r, g, b) ~= 0 then
				wnd.menu.rgb = { r = r, g = g, b = b }
			end
			frame.bColorPicker = nil
		end)
	elseif name == 'Handle_CustomIcon' then
		local data = this.data
		local menu = this.menu
		local frame = this:GetRoot()
		D.FireAction(frame, menu, data.fnAction)
	end
end

-- Global exports
do
local settings = {
	name = PLUGIN_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'Open',
				'Close',
			},
			root = D,
		},
	},
}
_G[PLUGIN_NAME] = X.CreateModule(settings)
end

X.UI.PopupMenu = D.Open
X.UI.ClosePopupMenu = D.Close
