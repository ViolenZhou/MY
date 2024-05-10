--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagSort'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ���ֿ�����
function D.SortBag()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if not frame then
		return
	end
	local szState = 'Idle'
	-- ���ظ����б�
	local me, aInfo, nItemCount = X.GetClientPlayer(), {}, 0
	local aBagPos = {}
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() - 1 do
		local dwGenre = me.GetContainType(dwBox)
		if dwGenre == ITEM_GENRE.BOOK then
			X.Systopmsg(_L['Bag contains book only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		if dwGenre == ITEM_GENRE.MATERIAL then
			X.Systopmsg(_L['Bag contains material only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local KItem = GetPlayerItem(me, dwBox, dwX)
			local info = KItem
				and MY_BagEx.GetItemDescription(KItem)
				or X.CONSTANT.EMPTY_TABLE
			if info ~= X.CONSTANT.EMPTY_TABLE then
				nItemCount = nItemCount + 1
			end
			table.insert(aInfo, info)
			table.insert(aBagPos, { dwBox = dwBox, dwX = dwX })
		end
	end
	if nItemCount == 0 then
		return
	end
	-- �ܿ���������
	local aMovableInfo = {}
	for i, info in ipairs(aInfo) do
		local tPos = aBagPos[i]
		if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
			table.insert(aMovableInfo, info)
		end
	end
	-- ��������б�
	if IsShiftKeyDown() then
		for i = 1, #aMovableInfo do
			local j = X.Random(1, #aMovableInfo)
			if i ~= j then
				aMovableInfo[i], aMovableInfo[j] = aMovableInfo[j], aMovableInfo[i]
			end
		end
	else
		table.sort(aMovableInfo, MY_BagEx.ItemSorter)
	end
	-- �ϳɱܿ��������Ӻ��������
	for i, _ in X.ipairs_r(aInfo) do
		local tPos = aBagPos[i]
		if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
			aInfo[i] = table.remove(aMovableInfo)
		end
	end
	-- �������������ָ��ؼ�״̬
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagSort__Sort', false)
		MY_BagEx_Bag.HideAllItemShadow()
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- �����������뵱ǰ״̬������Ʒ
	local function fnNext()
		if not frame then
			X.Systopmsg(_L['Bag panel closed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' then
			return
		end
		for i, info in ipairs(aInfo) do
			local tBagPos = aBagPos[i]
			local dwBox, dwX = tBagPos.dwBox, tBagPos.dwX
			local item = GetPlayerItem(me, dwBox, dwX)
			if MY_BagEx.IsSameItem(item, info) then
				if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bag.HideItemShadow(frame, dwBox, dwX)
				end
			else -- ��ǰ���Ӻ�Ԥ�ڲ��� ��Ҫ����
				-- ��ǰ���Ӻ�Ԥ����Ʒ�ɶѵ� ���ø���Ķ����滻��������ᵼ����Ʒ�ϲ�
				if item and info.dwID and item.nUiId == info.nUiId and item.bCanStack and item.nStackNum ~= info.nStackNum then
					for j = #aBagPos, i + 1, -1 do
						local tBagPos1 = aBagPos[j]
						local dwBox1, dwX1 = tBagPos1.dwBox, tBagPos1.dwX
						local item1 = GetPlayerItem(me, dwBox1, dwX1)
						-- ƥ�䵽���ڽ����ĸ���
						if not MY_BagEx_Bag.IsItemBoxLocked(dwBox1, dwX1) and (not item1 or item1.nUiId ~= item.nUiId) then
							szState = 'Exchanging'
							if item then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwBox, dwX, dwBox1, dwX1)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox1 .. ',' .. dwX1 .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwBox1, dwX1, dwBox, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return fnFinish()
				end
				-- Ѱ��Ԥ����Ʒ����λ��
				for j = #aBagPos, i + 1, -1 do
					local tBagPos1 = aBagPos[j]
					local dwBox1, dwX1 = tBagPos1.dwBox, tBagPos1.dwX
					local item1 = GetPlayerItem(me, dwBox1, dwX1)
					-- ƥ�䵽Ԥ����Ʒ����λ��
					if not MY_BagEx_Bag.IsItemBoxLocked(dwBox1, dwX1) and MY_BagEx.IsSameItem(item1, info) then
						szState = 'Exchanging'
						if item then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox .. ',' .. dwX .. ' <-> ' ..dwBox1 .. ',' .. dwX1 .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwBox, dwX, dwBox1, dwX1)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_BagSort', 'OnExchangeItem: ' ..dwBox1 .. ',' .. dwX1 .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <N2>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwBox1, dwX1, dwBox, dwX)
						end
						return
					end
				end
				X.Systopmsg(_L['Exchange item match failed, bag may changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				return fnFinish()
			end
		end
		fnFinish()
	end
	X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagSort__Sort', function()
		local dwBox, dwX, bNewAdd = arg0, arg1, arg2
		if bNewAdd then
			X.Systopmsg(_L['Put new item in bag detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		elseif szState == 'Exchanging' then
			szState = 'Idle'
			X.DelayCall('MY_BagEx_BagSort__Sort', fnNext)
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
end

-- ������Ӱ�Ŧ
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bag.bEnable then
		-- ֲ������Ŧ
		local frame = Station.Lookup('Normal/BigBagPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_CU')
		local btnNew = frame:Lookup('Btn_MY_Sort')
		if not btnRef then
			return
		end
		local nX, nY = btnRef:GetRelPos()
		local nW, nH = btnRef:GetSize()
		if not btnNew then
			btnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Sort',
					w = nW, h = nH - 3,
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onClick = function()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm('MY_BagEx_BagSort', _L['Sure to start bag sort?'], {
								x = frame:GetAbsX() + frame:GetW() / 2,
								y = frame:GetAbsY() + frame:GetH() / 2,
								fnResolve = D.SortBag,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
							})
						else
							D.SortBag()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ�����Ŧ
		X.UI('Normal/BigBagPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagSort',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagSort', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagSort', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagSort', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagSort', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
