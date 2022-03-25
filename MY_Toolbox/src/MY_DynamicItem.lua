--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��սû��
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_DynamicItem'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
--------------------------------------------------------------------------

local SZ_INI = PLUGIN_ROOT .. '/ui/MY_DynamicItem.ini'

local O = X.CreateUserSettingsModule('MY_DynamicItem', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowBg = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nNum = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 16,
	},
	nCol = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 16,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'BOTTOMCENTER', r = 'BOTTOMCENTER', x = 26, y = -226 },
	},
})
local D = {
	aList = {},
}

local MAP_MERGE = setmetatable({
	[296] = 297, -- ���ž���
	[410] = 297, -- �������
	[421] = 421, -- �˿��С������ѹ�
	[422] = 421, -- �˿��С�ɣ���ԭ
	[423] = 421, -- �˿��С���ˮկ
	[424] = 421, -- �˿��С�����Ϫ
	[425] = 421, -- �˿��С��Ļ���
	[433] = 421, -- �˿��С��м��ջ
	[434] = 421, -- �˿��С�����ɽ
	[435] = 421, -- �˿��С����幬
	[436] = 421, -- �˿��С�������
	[437] = 421, -- �˿��С���ѩ·
	[438] = 421, -- �˿��С��ż�̳
	[439] = 421, -- �˿��С���ӫ��
	[440] = 421, -- �˿��С�����Ͽ
	[441] = 421, -- �˿��С��������
	[442] = 421, -- �˿��С������ֵ�
	[443] = 421, -- �˿��С�������
	[461] = 421, -- �˿��С���ӣ��
}, {__index = CONSTANT.MAP_MERGE})

function D.GetMapID()
	local dwMapID = GetClientPlayer().GetMapID()
	return MAP_MERGE[dwMapID] or dwMapID
end

function D.SaveMapConfig()
	X.SaveLUAData(
		{'userdata/dynamic_item/' .. D.GetMapID() .. '.jx3dat', X.PATH_TYPE.GLOBAL},
		D.aList,
		{ passphrase = false, crc = false })
end

function D.LoadMapConfig()
	D.aList = X.LoadLUAData(
		{'userdata/dynamic_item/' .. D.GetMapID() .. '.jx3dat', X.PATH_TYPE.GLOBAL},
		{ passphrase = false })
		or X.LoadLUAData(PLUGIN_ROOT .. '/data/dynamic_item/{$branch}/' .. D.GetMapID() .. '.jx3dat')
		or {}
end

function D.GetFrame()
	return Station.Lookup('Lowest/' .. MODULE_NAME)
end

function D.CheckEnable()
	if not GetClientPlayer() then
		return
	end
	if D.bReady and O.bEnable then
		Wnd.OpenWindow(SZ_INI, MODULE_NAME)
	else
		Wnd.CloseWindow(MODULE_NAME)
	end
end

function D.Reinit()
	Wnd.CloseWindow(MODULE_NAME)
	D.CheckEnable()
end

function D.UpdateAnchor(frame)
	local an = O.anchor
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

function D.InitList(frame)
	local nItemW = 0
	local hTotal = frame:Lookup('', '')
	-- �б�
	local hList = hTotal:Lookup('Handle_List')
	hList:Clear()
	for i = 1, O.nNum do
		local hItem = hList:AppendItemFromIni(SZ_INI, 'Handle_Item')
		local box = hItem:Lookup('Box_Item')
		box.nIndex = i
		box.__bDrag = true
		box.__tType = { [UI_OBJECT.ITEM] = true, [UI_OBJECT.ITEM_INFO] = true }
		box.__szTypeErrorMsg = _L['Only item can be draged in']
		-- bind events
		UpdateBoxObject(box, UI_OBJECT.MONEY, 0)
		box.__OnItemLButtonDragEnd = box.OnItemLButtonDragEnd
		nItemW = hItem:GetW()
	end
	hList:SetW(nItemW * O.nCol)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	local nListW, nListH = hList:GetSize()
	-- ���ҷָ���
	local hSplits = hTotal:Lookup('Handle_Splits')
	hSplits:Clear()
	for _ = 1, math.ceil(O.nNum / O.nCol) do
		local hSplit = hSplits:AppendItemFromIni(SZ_INI, 'Handle_Split')
		hSplit:SetW(nListW + hList:GetRelX() * 2)
		hSplit:Lookup('Image_SplitR'):SetRelX(nListW + hList:GetRelX())
		hSplit:FormatAllItemPos()
	end
	hSplits:FormatAllItemPos()
	hSplits:SetSizeByAllItemSize()
	local nSplitsW, nSplitsH = hSplits:GetSize()
	-- �����С
	hTotal:SetSize(nSplitsW, nSplitsH)
	frame:SetSize(nSplitsW, nSplitsH)
end

function D.UpdateCDText(txt, nTime)
	if txt.nTime == nTime then
		return
	end
	local nSec, szTime, nR, nG, nB = math.floor(nTime / ENVIRONMENT.GAME_FPS)
	if nSec == 0 then
		szTime, nR, nG, nB = '', 255, 255, 255
	else
		local nH = math.floor(nSec / 3600)
		local nM = math.floor(nSec / 60) % 60
		local nS = nSec % 60
		if nH > 0 then
			if nM > 0 or nS > 0 then
				nH = nH + 1
			end
			szTime = nH ..'h'
			nR, nG, nB = 255, 255, 255
		elseif nM  > 0 then
			if nS > 0 then
				nM = nM + 1
			end
			szTime = nM ..'m'
			nR, nG, nB = 255, 255, 0
		elseif nS >= 0 then
			if nS < 5 then
				if not txt.nSpark or txt.nSpark >= 7 then
					txt.nSpark = 0
					txt.bSpark = not txt.bSpark
				end
				if txt.bSpark then
					nR, nG, nB = 255, 255, 255
				else
					nR, nG, nB = 255, 0, 0
				end
				txt.nSpark = txt.nSpark + 1
			else
				nR, nG, nB = 255, 255, 0
			end
			szTime = nS
		end
	end
	txt:SetText(szTime)
	txt:SetFontColor(nR, nG, nB)
	txt.nTime = nTime
end

function D.UpdateListCD(frame)
	local me = GetClientPlayer()
	if not me then
		return
	end
	local bShowCD = X.GetNumberBit(GetUserPreferences(4380, 'c'), 2) == 1
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		local box = hItem:Lookup('Box_Item')
		local data, nTime = D.aList[i], 0
		if data then
			if data[1] == UI_OBJECT.ITEM_INFO then
				nTime = UpdataItemCDProgress(me, box, 0, data[2], data[3]) or 0
			elseif data[1] == UI_OBJECT.ITEM then
				nTime = UpdataItemCDProgress(me, box, data[2], data[3]) or 0
			end
		end
		D.UpdateCDText(hItem:Lookup('Text_CD'), bShowCD and nTime or 0)
	end
end

function D.UpdateList(frame)
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		local box = hItem:Lookup('Box_Item')
		local data = D.aList[i]
		if data then
			if data[1] == UI_OBJECT.ITEM_INFO then
				local nAmount = X.GetItemAmount(data[2], data[3], data[4])
				UpdateBoxObject(box, UI_OBJECT.ITEM_INFO, nil, data[2], data[3], data[4] or nAmount)
				box:EnableObject(nAmount > 0)
			elseif data[1] == UI_OBJECT.ITEM then
				UpdateBoxObject(box, UI_OBJECT.ITEM, data[2], data[3])
			else
				UpdateBoxObject(box, UI_OBJECT.NONE)
			end
		else
			UpdateBoxObject(box, UI_OBJECT.NONE)
		end
		box.OnItemLButtonClick = nil
		box.OnItemRButtonClick = nil
		box.OnItemLButtonDrag = nil
		box.OnItemLButtonDragEnd = nil
	end
	D.UpdateListCD(frame)
	D.UpdateItemVisible(frame)
end

function D.ParseBoxItem(box)
	local me = GetClientPlayer()
	local data, tItem = {box:GetObject()}
	if data[1] == UI_OBJECT.ITEM then
		local KItem = GetPlayerItem(me, data[3], data[4])
		if KItem then
			if data[3] == 0 then -- ������ϵ�װ��
				tItem = {UI_OBJECT.ITEM, data[3], data[4]}
			else
				if KItem.nGenre == ITEM_GENRE.BOOK then
					tItem = {UI_OBJECT.ITEM_INFO, KItem.dwTabType, KItem.dwIndex, KItem.nBookID}
				else
					tItem = {UI_OBJECT.ITEM_INFO, KItem.dwTabType, KItem.dwIndex}
				end
			end
		end
	elseif data[1] == UI_OBJECT.ITEM_INFO then
		local KItemInfo = GetItemInfo(data[4], data[5])
		if KItemInfo then
			if KItemInfo.nGenre == ITEM_GENRE.BOOK then
				tItem = {UI_OBJECT.ITEM_INFO, data[4], data[5], data[7]}
			else
				tItem = {UI_OBJECT.ITEM_INFO, data[4], data[5]}
			end
		end
	end
	D.aList[box.nIndex] = tItem or {}
end

function D.UpdateHotKey(frame)
	local hList = frame:Lookup('', 'Handle_List')
	for i = 1, O.nNum do
		local nKey, bShift, bCtrl, bAlt = Hotkey.Get(MODULE_NAME .. '_' .. i)
		hList:Lookup(i - 1):Lookup('Text_HotKey'):SetText(GetKeyShow(nKey, bShift, bCtrl, bAlt, true))
	end
end

function D.UpdateItemVisible(frame)
	local hList = frame:Lookup('', 'Handle_List')
	local bShowItem = O.bShowBg or not Hand_IsEmpty()
	for i = 1, O.nNum do
		local hItem = hList:Lookup(i - 1)
		hItem:SetVisible(bShowItem or not hItem:Lookup('Box_Item'):IsEmpty())
	end
end

function D.UpdateBgVisible(frame)
	local hList = frame:Lookup('', 'Handle_List')
	local bShowBg = O.bShowBg or not Hand_IsEmpty()
	for i = 1, O.nNum do
		hList:Lookup(i - 1):Lookup('Image_ItemBg'):SetVisible(bShowBg)
	end
	frame:Lookup('', 'Handle_Splits'):SetVisible(bShowBg)
	frame:SetDummyWnd(Hand_IsEmpty())
	D.UpdateItemVisible(frame)
end

function D.OnFrameCreate()
	D.LoadMapConfig()
	D.InitList(this)
	D.UpdateList(this)
	D.UpdateHotKey(this)
	D.UpdateAnchor(this)
	D.UpdateBgVisible(this)
	D.UpdateItemVisible(this)

	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('LOADING_ENDING')
	this:RegisterEvent('EQUIP_ITEM_UPDATE')
	this:RegisterEvent('BAG_ITEM_UPDATE')
	this:RegisterEvent('HAND_PICK_OBJECT')
	this:RegisterEvent('HAND_CLEAR_OBJECT')
	this:RegisterEvent('HOT_KEY_RELOADED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
end

function D.OnFrameBreathe()
	D.UpdateListCD(this)
end

function D.OnEvent(event)
	if event == 'LOADING_ENDING' then
		D.LoadMapConfig()
		D.UpdateList(this)
	elseif event == 'EQUIP_ITEM_UPDATE' or event == 'BAG_ITEM_UPDATE' then
		D.UpdateList(this)
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'HAND_PICK_OBJECT' then
		D.UpdateBgVisible(this)
		D.UpdateItemVisible(this)
	elseif event == 'HAND_CLEAR_OBJECT' then
		D.UpdateBgVisible(this)
		D.UpdateItemVisible(this)
	elseif event == 'HOT_KEY_RELOADED' then
		D.UpdateHotKey(this)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L[MODULE_NAME])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L[MODULE_NAME])
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Box_Item' then
		if this.bIgnoreClick or this.bDisableClick then
			return
		end
		if Hand_IsEmpty() then
			local data = {this:GetObject()}
			if data[1] == UI_OBJECT.ITEM_INFO then
				local dwTabType, dwIndex, nBookID = data[4], data[5], data[7]
				X.WalkBagItem(function(item, dwBox, dwX)
					if item.dwTabType == dwTabType and item.dwIndex == dwIndex then
						if item.nGenre == ITEM_GENRE.BOOK and item.nBookID ~= nBookID then
							return
						end
						OnUseItem(dwBox, dwX)
						return 0
					end
				end)
			elseif data[1] == UI_OBJECT.ITEM then
				local dwBox, dwX = data[3], data[4]
				OnUseItem(dwBox, dwX)
			end
		else
			X.ExecuteWithThis(this, D.OnItemLButtonDragEnd)
		end
	end
end

function D.OnItemRButtonClick()
	local name = this:GetName()
	if name == 'Box_Item' then
		D.OnItemLButtonClick()
	end
end

function D.OnItemLButtonDrag()
	local name = this:GetName()
	if name == 'Box_Item' then
		this.bIgnoreClick = true
		this.bDisableClick = true
		this:SetObjectPressed(0)
		if Hand_IsEmpty() and not this:IsEmpty() then
			if IsCursorInExclusiveMode() then
				OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
			elseif X.GetNumberBit(GetUserPreferences(2145, 'c'), 8) == 1 and not IsShiftKeyDown() then
				OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_LOCK_ACTIONBAR_WHEN_DRAG)
			else
				Hand_Pick(this)
				UpdateBoxObject(this, UI_OBJECT.NONE)
				D.ParseBoxItem(this)
				D.SaveMapConfig()
			end
		end
	end
end

function D.OnItemLButtonDragEnd()
	local name = this:GetName()
	if name == 'Box_Item' then
		local wnd = Station.GetMouseOverWindow()
		if not wnd or wnd:GetRoot() ~= this:GetRoot() then
			return
		end
		if not this:IsEmpty() and X.GetNumberBit(GetUserPreferences(2145, 'c'), 8) == 1 and not IsShiftKeyDown() then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.SRT_ERROR_LOCK_ACTIONBAR_WHEN_DRAG)
		else
			this.__OnItemLButtonDragEnd()
			D.ParseBoxItem(this)
			D.SaveMapConfig()
			D.UpdateList(this:GetRoot())
		end
		this.bIgnoreClick = nil
		this.bDisableClick = nil
	end
end

for i = 1, 32 do
	Hotkey.AddBinding(
		MODULE_NAME .. '_' .. i,
		_L('Dynamic item %d', i),
		i == 1 and _L['MY Dynamic Item'] or '',
		function()
			local frame = D.GetFrame()
			local hItem = frame and frame:Lookup('', 'Handle_List'):Lookup(i - 1)
			if not hItem then
				return
			end
			hItem:Lookup('Box_Item'):SetObjectPressed(1)
		end,
		function()
			local frame = D.GetFrame()
			local hItem = frame and frame:Lookup('', 'Handle_List'):Lookup(i - 1)
			if not hItem then
				return
			end
			hItem:Lookup('Box_Item'):SetObjectPressed(0)
			X.ExecuteWithThis(hItem:Lookup('Box_Item'), D.OnItemLButtonClick)
		end)
end

X.RegisterUserSettingsUpdate('@@INIT@@', MODULE_NAME, function()
	D.bReady = true
	D.CheckEnable()
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L[MODULE_NAME],
		checked = MY_DynamicItem.bEnable,
		oncheck = function(bChecked)
			MY_DynamicItem.bEnable = bChecked
		end,
		tip = _L['Dynamic item bar for different map'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	}):Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Show background'],
		checked = MY_DynamicItem.bShowBg,
		oncheck = function(bChecked)
			MY_DynamicItem.bShowBg = bChecked
		end,
		autoenable = function() return MY_DynamicItem.bEnable end,
	}):Width() + 5

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, h = 25, w = 220,
		range = {1, 32}, value = MY_DynamicItem.nNum,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Box number: %d', v) end,
		onchange = function(nVal)
			X.DelayCall(function() MY_DynamicItem.nNum = nVal end)
		end,
		autoenable = function() return MY_DynamicItem.bEnable end,
	}):Width() + 5

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, h = 25, w = 220,
		range = {1, 32}, value = MY_DynamicItem.nCol,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textfmt = function(v) return _L('Col number: %d', v) end,
		onchange = function(nVal)
			X.DelayCall(function() MY_DynamicItem.nCol = nVal end)
		end,
		autoenable = function() return MY_DynamicItem.bEnable end,
	}):Width() + 5

	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_DynamicItem',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'bShowBg',
				'nNum',
				'nCol',
				'anchor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bShowBg',
				'nNum',
				'nCol',
				'anchor',
			},
			triggers = {
				bEnable = D.CheckEnable,
				bShowBg = D.Reinit,
				nNum = D.Reinit,
				nCol = D.Reinit,
				anchor = D.Reinit,
			},
			root = O,
		},
	},
}
MY_DynamicItem = X.CreateModule(settings)
end
