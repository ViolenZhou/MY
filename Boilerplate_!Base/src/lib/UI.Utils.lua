--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ���湤�߿�
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.Utils')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

function X.UI.GetFreeTempFrameName()
	local nTempFrame = 0
	local szTempFrame
	repeat
		szTempFrame = X.NSFormatString('{$NS}_TempWnd#') .. nTempFrame
		nTempFrame = nTempFrame + 1
	until not Station.SearchFrame(szTempFrame)
	return szTempFrame
end

function X.UI.RecursiveLookup(hEl, szName)
	if hEl:GetName() == szName then
		return hEl
	end
	if hEl:GetBaseType() == 'Wnd' then
		local hChild = hEl:GetFirstChild()
		while hChild do
			local hFind = X.UI.RecursiveLookup(hChild, szName)
			if hFind then
				return hFind
			end
			hChild = hChild:GetNext()
		end
		local hHandle = hEl:Lookup('', '')
		if hHandle then
			local hFind = X.UI.RecursiveLookup(hHandle, szName)
			if hFind then
				return hFind
			end
		end
	elseif hEl:GetType() == 'Handle' then
		for i = 0, hEl:GetItemCount() - 1 do
			local hFind = X.UI.RecursiveLookup(hEl:Lookup(i), szName)
			if hFind then
				return hFind
			end
		end
	end
end

function X.UI.AppendFromIni(hParent, szIni, szName, bOnlyChild)
	local szParentBaseType = hParent:GetBaseType()
	if szParentBaseType ~= 'Wnd' then
		return
	end
	local hFrame = X.UI.OpenFrame(szIni, X.UI.GetFreeTempFrameName())
	local hEl = X.UI.RecursiveLookup(hFrame, szName)
	local aEl = {}
	if hEl and hEl:GetBaseType() == szParentBaseType then
		if bOnlyChild then
			while true do
				local hChild = hEl:GetFirstChild()
				if not hChild then
					break
				end
				hChild:ChangeRelation(hParent, true, true)
				table.insert(aEl, hChild)
			end
		else
			hEl:ChangeRelation(hParent, true, true)
			table.insert(aEl, hEl)
		end
	end
	Wnd.CloseWindow(hFrame)
	return aEl
end

function X.UI.GetFrameAnchor(...)
	return GetFrameAnchor(...)
end

function X.UI.SetFrameAnchor(frame, anchor)
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
end

function X.UI.GetTreePath(raw)
	local tTreePath = {}
	if X.IsTable(raw) and raw.GetTreePath then
		table.insert(tTreePath, (raw:GetTreePath()):sub(1, -2))
		while(raw and raw:GetType():sub(1, 3) ~= 'Wnd') do
			local szName = raw:GetName()
			if not szName or szName == '' then
				table.insert(tTreePath, 2, raw:GetIndex())
			else
				table.insert(tTreePath, 2, szName)
			end
			raw = raw:GetParent()
		end
	else
		table.insert(tTreePath, tostring(raw))
	end
	return table.concat(tTreePath, '/')
end

do
local ui, cache
function X.UI.GetTempElement(szType, szKey)
	if not X.IsString(szType) then
		return
	end
	if not X.IsString(szKey) then
		szKey = 'Default'
	end
	if not cache or not ui or ui:Count() == 0 then
		cache = {}
		ui = X.UI.CreateFrame(X.NSFormatString('{$NS}#TempElement'), { theme = X.UI.FRAME_THEME.EMPTY }):Hide()
	end
	local szName = szType .. '_' .. szKey
	local raw = cache[szName]
	if not raw then
		raw = ui:Append(szType, {
			name = szName,
		})[1]
		cache[szName] = raw
	end
	return raw
end
end

function X.UI.ScrollIntoView(el, scrollY, nOffsetY, scrollX, nOffsetX)
	local elParent, nParentW, nParentH = el:GetParent()
	local nX, nY = el:GetAbsX() - elParent:GetAbsX(), el:GetAbsY() - elParent:GetAbsY()
	if elParent:GetType() == 'WndContainer' then
		nParentW, nParentH = elParent:GetAllContentSize()
	else
		nParentW, nParentH = elParent:GetAllItemSize()
	end
	if nOffsetY then
		nY = nY + nOffsetY
	end
	if scrollY then
		scrollY:SetScrollPos(nY / nParentH * scrollY:GetStepCount())
	end
	if nOffsetX then
		nX = nX + nOffsetX
	end
	if scrollX then
		scrollX:SetScrollPos(nX / nParentW * scrollX:GetStepCount())
	end
end

function X.UI.LookupFrame(szName)
	for _, v in ipairs(X.UI.LAYER_LIST) do
		local frame = Station.Lookup(v .. '/' .. szName)
		if frame then
			return frame
		end
	end
end

do
local ITEM_COUNT = {}
local HOOK_BEFORE = setmetatable({}, { __mode = 'v' })
local HOOK_AFTER = setmetatable({}, { __mode = 'v' })

function X.UI.HookHandleAppend(hList, fnOnAppendItem)
	-- ע���ɵ� HOOK ����
	if HOOK_BEFORE[hList] then
		UnhookTableFunc(hList, 'AppendItemFromIni'   , HOOK_BEFORE[hList])
		UnhookTableFunc(hList, 'AppendItemFromData'  , HOOK_BEFORE[hList])
		UnhookTableFunc(hList, 'AppendItemFromString', HOOK_BEFORE[hList])
	end
	if HOOK_AFTER[hList] then
		UnhookTableFunc(hList, 'AppendItemFromIni'   , HOOK_AFTER[hList])
		UnhookTableFunc(hList, 'AppendItemFromData'  , HOOK_AFTER[hList])
		UnhookTableFunc(hList, 'AppendItemFromString', HOOK_AFTER[hList])
	end

	-- �����µ� HOOK ����
	local function BeforeAppendItem(hList)
		ITEM_COUNT[hList] = hList:GetItemCount()
	end
	HOOK_BEFORE[hList] = BeforeAppendItem

	local function AfterAppendItem(hList)
		local nCount = ITEM_COUNT[hList]
		if not nCount then
			return
		end
		ITEM_COUNT[hList] = nil
		for i = nCount, hList:GetItemCount() - 1 do
			local hItem = hList:Lookup(i)
			fnOnAppendItem(hList, hItem)
		end
	end
	HOOK_AFTER[hList] = AfterAppendItem

	-- Ӧ�� HOOK ����
	ITEM_COUNT[hList] = 0
	AfterAppendItem(hList)
	HookTableFunc(hList, 'AppendItemFromIni'   , BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromIni'   , AfterAppendItem , { bAfterOrigin = true  })
	HookTableFunc(hList, 'AppendItemFromData'  , BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromData'  , AfterAppendItem , { bAfterOrigin = true  })
	HookTableFunc(hList, 'AppendItemFromString', BeforeAppendItem, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendItemFromString', AfterAppendItem , { bAfterOrigin = true  })
end
end

do
local ITEM_COUNT = {}
local HOOK_BEFORE = setmetatable({}, { __mode = 'v' })
local HOOK_AFTER = setmetatable({}, { __mode = 'v' })

function X.UI.HookContainerAppend(hList, fnOnAppendContent)
	-- ע���ɵ� HOOK ����
	if HOOK_BEFORE[hList] then
		UnhookTableFunc(hList, 'AppendContentFromIni'   , HOOK_BEFORE[hList])
	end
	if HOOK_AFTER[hList] then
		UnhookTableFunc(hList, 'AppendContentFromIni'   , HOOK_AFTER[hList])
	end

	-- �����µ� HOOK ����
	local function BeforeAppendContent(hList)
		ITEM_COUNT[hList] = hList:GetAllContentCount()
	end
	HOOK_BEFORE[hList] = BeforeAppendContent

	local function AfterAppendContent(hList)
		local nCount = ITEM_COUNT[hList]
		if not nCount then
			return
		end
		ITEM_COUNT[hList] = nil
		for i = nCount, hList:GetAllContentCount() - 1 do
			local hContent = hList:LookupContent(i)
			fnOnAppendContent(hList, hContent)
		end
	end
	HOOK_AFTER[hList] = AfterAppendContent

	-- Ӧ�� HOOK ����
	ITEM_COUNT[hList] = 0
	AfterAppendContent(hList)
	HookTableFunc(hList, 'AppendContentFromIni'   , BeforeAppendContent, { bAfterOrigin = false })
	HookTableFunc(hList, 'AppendContentFromIni'   , AfterAppendContent , { bAfterOrigin = true  })
end
end

-- ��ʽ�������¼��ص�������Ϊ���뷵��ֵ��ͬ�ٷ� FORMAT_WMSG_RET ������δ������
---@param stopPropagation boolean @�¼��Ѵ���ֹͣð��Ѱ�Ҹ���Ԫ��
---@param callFrameBinding boolean @�������ô���󶨵Ľű��ϵ�ͬ���ص�����
---@return number �����¼��ص�������Ϊ����ֵ
function X.UI.FormatUIEventMask(stopPropagation, callFrameBinding)
	local ret = 0
	if stopPropagation then
		ret = ret + 1 --01
	end
	if callFrameBinding then
		ret = ret + 2 --10
	end
	return ret
end

-- ���ð�ť�ؼ�ͼ��
---@param hWndCheckBox userdata @��ť��ؼ����
---@param szImagePath string @ͼ�ص�ַ
---@param nNormal number @����״̬��ͼ��
---@param nMouseOver number @��껮��ʱͼ��
---@param nMouseDown number @��갴��ʱͼ��
---@param nDisable number @����ʱͼ��
function X.UI.SetButtonUITex(
	hButton,
	szImagePath,
	nNormal,
	nMouseOver,
	nMouseDown,
	nDisable
)
	hButton:SetAnimatePath(szImagePath)
	hButton:SetAnimateGroupNormal(nNormal)
	hButton:SetAnimateGroupMouseOver(nMouseOver)
	hButton:SetAnimateGroupMouseDown(nMouseDown)
	hButton:SetAnimateGroupDisable(nDisable)
end

-- ���ø�ѡ��ؼ�ͼ��
-- ��Ϊ����ά�ȣ�(δ��ѡ, ��ѡ) x (����, ����, ����, ����)
---@param hWndCheckBox userdata @��ѡ��ؼ����
---@param szImagePath string @ͼ�ص�ַ
---@param nUnCheckAndEnable number @δѡ�С�����״̬ʱͼ�أ�δ��ѡ+������
---@param nUncheckedAndEnableWhenMouseOver number @δѡ�С�����״̬ʱ�������ʱͼ�أ�δ��ѡ+������
---@param nChecking number @δѡ�С�����ʱͼ�أ�δ��ѡ+���£�
---@param nUnCheckAndDisable number @δѡ�С�����״̬ʱͼ�أ�δ��ѡ+���ã�
---@param nCheckAndEnable number @ѡ�С�����״̬ʱͼ�أ���ѡ+������
---@param nCheckedAndEnableWhenMouseOver number @ѡ�С�����״̬ʱ�������ʱͼ�أ���ѡ+������
---@param nUnChecking number @ѡ�С�����ʱͼ�أ���ѡ+���£�
---@param nCheckAndDisable number @ѡ�С�����״̬ʱͼ�أ���ѡ+���ã�
---@param nUncheckedAndDisableWhenMouseOver? number @δѡ�С�����״̬ʱ�������ʱͼ�أ�Ĭ��ȡδѡ�С�����״̬ʱͼ��
---@param nCheckedAndDisableWhenMouseOver? number @ѡ�С�����״̬ʱ�������ʱͼ�أ�Ĭ��ȡѡ�С�����״̬ʱͼ��
function X.UI.SetCheckBoxUITex(
	hWndCheckBox,
	szImagePath,
	nUnCheckAndEnable,
	nUncheckedAndEnableWhenMouseOver,
	nChecking,
	nUnCheckAndDisable,
	nCheckAndEnable,
	nCheckedAndEnableWhenMouseOver,
	nUnChecking,
	nCheckAndDisable,
	nUncheckedAndDisableWhenMouseOver,
	nCheckedAndDisableWhenMouseOver
)
	if not nUncheckedAndDisableWhenMouseOver then
		nUncheckedAndDisableWhenMouseOver = nUnCheckAndDisable
	end
	if not nCheckedAndDisableWhenMouseOver then
		nCheckedAndDisableWhenMouseOver = nCheckAndDisable
	end
	return hWndCheckBox:SetAnimation(
		szImagePath,
		nUnCheckAndEnable,
		nCheckAndEnable,
		nUnCheckAndDisable,
		nCheckAndDisable,
		nChecking,
		nUnChecking,
		nCheckedAndEnableWhenMouseOver,
		nUncheckedAndEnableWhenMouseOver,
		nCheckedAndDisableWhenMouseOver,
		nUncheckedAndDisableWhenMouseOver
	)
end

-- ���������ʽ������/������
---@param hEl userdata @������
---@param szExtra? string @���������Ϣ
function X.UI.AdaptComponentAppearance(hEl, szExtra)
	local szType = hEl:GetType()
	if X.UI.IS_GLASSMORPHISM then
		if szType == 'WndButton' then
			local szPath = X.StringLowerW(hEl:GetAnimatePath())
			local nFrame = hEl:GetAnimateGroupNormal()
			if (szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 25)
			or (szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 35)
			or (szPath == 'ui\\image\\uicommon\\logincommon.uitex' and nFrame == 54) then
				X.UI.SetButtonUITex(
					hEl,
					'ui\\Image\\denglu\\Sign1.UITex',
					32,
					33,
					34,
					35
				)
			elseif szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 31 then -- �����������ť
				X.UI.SetButtonUITex(
					hEl,
					'ui\\Image\\UItimate\\UICommon\\Button.UITex',
					47,
					48,
					49,
					50
				)
			elseif szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 47 then -- �������ϰ�ť
				X.UI.SetButtonUITex(
					hEl,
					'ui\\Image\\UItimate\\UICommon\\Button.UITex',
					63,
					64,
					65,
					66
				)
			elseif szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 51 then -- �������°�ť��������ť
				X.UI.SetButtonUITex(
					hEl,
					'ui\\Image\\UItimate\\UICommon\\Button.UITex',
					67,
					68,
					69,
					70
				)
			elseif szPath == 'ui\\image\\uicommon\\commonpanel.uitex' and nFrame == 105 then -- �����������ť
				X.UI.SetButtonUITex(
					hEl,
					'ui\\Image\\UItimate\\UICommon\\Button.UITex',
					79,
					80,
					81,
					82
				)
			end
		elseif szType == 'WndCheckBox' then
			if szExtra == 'WndTab' then
				local h = hEl:Lookup('', '')
				for i = 0, h:GetItemCount() - 1 do
					local hChild = h:Lookup(i)
					if hChild:GetType() == 'Image'
					and X.StringLowerW((hChild:GetImagePath())) == 'ui\\image\\uicommon\\activepopularize2.uitex'
					and hChild:GetFrame() == 44 then
						hChild:Hide()
					end
				end
				hEl:SetAnimation('ui\\Image\\UItimate\\UICommon\\Button4.UITex', 14, 20, 14, 14, 20, 20, 20, 19, 14, 14)
			elseif szExtra == 'WndCheckBox' then
				X.UI.SetCheckBoxUITex(
					hEl,
					'ui\\Image\\UItimate\\UICommon\\Button4.UITex',
					4,
					5,
					6,
					7,
					0,
					1,
					2,
					3,
					7,
					3
				)
			end
		elseif szType == 'WndNewScrollBar' then
			X.UI.AdaptComponentAppearance(hEl:GetFirstChild())
			local hSibling = hEl:GetParent():GetFirstChild()
			while hSibling do
				if hSibling:GetType() == 'WndButton' then
					X.UI.AdaptComponentAppearance(hSibling)
				end
				hSibling = hSibling:GetNext()
			end
		elseif szType == 'Image' then
			local szPath = X.StringLowerW((hEl:GetImagePath()))
			local nFrame = hEl:GetFrame()
			if szPath == 'ui\\image\\uicommon\\activepopularize2.uitex' and nFrame == 46 then
				hEl:FromUITex('ui\\Image\\UItimate\\UICommon\\Button4.UITex', 21)
				hEl:SetRelY(hEl:GetRelY() - 3)
				hEl:SetAbsY(hEl:GetAbsY() - 3)
			end
		end
	end
end

X.UI.UpdateItemInfoBoxObject = _G.UpdateItemInfoBoxObject or UpdataItemInfoBoxObject

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
