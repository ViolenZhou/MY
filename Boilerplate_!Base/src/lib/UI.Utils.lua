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
		ui = X.UI.CreateFrame(X.NSFormatString('{$NS}#TempElement'), { empty = true }):Hide()
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

X.UI.UpdateItemInfoBoxObject = _G.UpdateItemInfoBoxObject or UpdataItemInfoBoxObject

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
