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
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^23.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

function D.Operate(bRandom, bExportBlueprint, aBlueprint)
	local hFrame = Station.Lookup('Normal/BigBagPanel')
	if not hFrame then
		return
	end
	local szState = 'Idle'
	-- ���ظ����б�
	local me, aItemDesc, nItemCount, aBoxPos = X.GetClientPlayer(), {}, 0, {}
	for _, dwBox in ipairs(X.GetInventoryBoxList(X.CONSTANT.INVENTORY_TYPE.PACKAGE)) do
		local dwGenre = me.GetContainType(dwBox)
		if dwGenre == ITEM_GENRE.BOOK then
			X.OutputSystemAnnounceMessage(_L['Bag contains book only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		if dwGenre == ITEM_GENRE.MATERIAL then
			X.OutputSystemAnnounceMessage(_L['Bag contains material only, use official sort please!'], X.CONSTANT.MSG_THEME.ERROR)
			return
		end
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			local kItem = X.GetInventoryItem(me, dwBox, dwX)
			local tDesc = MY_BagEx.GetItemDesc(kItem)
			if not X.IsEmpty(tDesc) then
				nItemCount = nItemCount + 1
			end
			table.insert(aItemDesc, tDesc)
			table.insert(aBoxPos, { dwBox = dwBox, dwX = dwX })
		end
	end
	-- ��������
	if bExportBlueprint then
		X.UI.OpenTextEditor(MY_BagEx.EncodeItemDescList(aItemDesc))
		return
	end
	-- û��Ʒ����Ҫ����
	if nItemCount == 0 then
		return
	end
	-- ���벼��
	if aBlueprint then
		for nIndex, tDesc in ipairs(aItemDesc) do
			aItemDesc[nIndex] = aBlueprint[nIndex] or MY_BagEx.GetItemDesc()
		end
	else
		-- �ܿ���������
		local aMovableItemDesc = {}
		for nIndex, tDesc in ipairs(aItemDesc) do
			local tPos = aBoxPos[nIndex]
			if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
				table.insert(aMovableItemDesc, tDesc)
			end
		end
		-- ��������б�
		if bRandom then
			for nIndex = 1, #aMovableItemDesc do
				local nExcIndex = X.Random(1, #aMovableItemDesc)
				if nIndex ~= nExcIndex then
					aMovableItemDesc[nIndex], aMovableItemDesc[nExcIndex] = aMovableItemDesc[nExcIndex], aMovableItemDesc[nIndex]
				end
			end
		else
			table.sort(aMovableItemDesc, MY_BagEx.ItemDescSorter)
		end
		-- �ϳɱܿ��������Ӻ��������
		for nIndex, _ in X.ipairs_r(aItemDesc) do
			local tPos = aBoxPos[nIndex]
			if not MY_BagEx_Bag.IsItemBoxLocked(tPos.dwBox, tPos.dwX) then
				aItemDesc[nIndex] = table.remove(aMovableItemDesc)
			end
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
	local nIndex, bChanged = 1, false
	local function fnNext()
		if not hFrame then
			X.OutputSystemAnnounceMessage(_L['Bag panel closed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' then
			return
		end
		while nIndex <= #aItemDesc do
			local tDesc = aItemDesc[nIndex]
			local tBoxPos = aBoxPos[nIndex]
			local dwBox, dwX = tBoxPos.dwBox, tBoxPos.dwX
			local kCurItem = X.GetInventoryItem(me, dwBox, dwX)
			local tCurDesc = MY_BagEx.GetItemDesc(kCurItem)
			if MY_BagEx.IsSameItemDesc(tDesc, tCurDesc) then
				if not MY_BagEx_Bag.IsItemBoxLocked(dwBox, dwX) then
					MY_BagEx_Bag.HideItemShadow(hFrame, dwBox, dwX)
				end
				nIndex = nIndex + 1
			else -- ��ǰ���Ӻ�Ԥ�ڲ��� ��Ҫ����
				local tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc
				-- Ѱ��Ԥ����Ʒ����λ��
				if not dwExcBox then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- ƥ�䵽Ԥ����Ʒ����λ��
						if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and MY_BagEx.IsSameItemDesc(tDesc, tExcDesc) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						bChanged = true
					end
				end
				-- Ѱ�Ҷѵ�����ͬ��Ԥ����Ʒ����λ��
				if not dwExcBox then
					for nExcIndex = nIndex, #aBoxPos do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- ƥ�䵽Ԥ����Ʒ����λ��
						if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and MY_BagEx.IsSameItemDesc(tDesc, tExcDesc, true) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
				end
				-- ����Ҫ���ý��Q
				if dwBox == dwExcBox and dwX == dwExcX then
					nIndex = nIndex + 1
					X.DelayCall(fnNext)
					return
				end
				-- ��ǰ���Ӻ�Ԥ����Ʒ�ɶѵ� ���ø���Ķ����滻��������ᵼ����Ʒ�ϲ�
				if dwExcBox and MY_BagEx.CanItemDescStack(tCurDesc, tDesc) then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- ƥ�䵽���ڽ����ĸ���
						if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and not MY_BagEx.CanItemDescStack(tCurDesc, tExcDesc) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Bag item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, bag is full, sort exited!']
						X.OutputSystemAnnounceMessage(szMsg, X.CONSTANT.MSG_THEME.ERROR)
						return fnFinish()
					end
				end
				-- ����û��ƥ�䵽 ����ǰ��Ʒ�Ҹ��ո�������
				if not dwExcBox then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						-- ƥ�䵽���ڽ����ĸ���
						if not MY_BagEx_Bag.IsItemBoxLocked(dwExcBox, dwExcX) and not kExcItem then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Bag item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, bag is full, sort exited!']
						X.OutputSystemAnnounceMessage(szMsg, X.CONSTANT.MSG_THEME.ERROR)
						return fnFinish()
					end
				end
				-- ִ����Ʒ����
				szState = 'Exchanging'
				if kCurItem then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_BagSort', 'ExchangeItem: ' .. dwBox .. ',' .. dwX .. ' <-> ' ..dwExcBox .. ',' .. dwExcX .. ' <T1>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwBox, dwX, dwExcBox, dwExcX)
				else
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_BagSort', 'ExchangeItem: ' .. dwExcBox .. ',' .. dwExcX .. ' <-> ' ..dwBox .. ',' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwExcBox, dwExcX, dwBox, dwX)
				end
				return
			end
		end
		fnFinish()
	end
	X.RegisterEvent('BAG_ITEM_UPDATE', 'MY_BagEx_BagSort__Sort', function()
		local dwBox, dwX, bNewAdd = arg0, arg1, arg2
		if bNewAdd then
			X.OutputSystemAnnounceMessage(_L['Put new item in bag detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
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
		local hFrame = Station.Lookup('Normal/BigBagPanel')
		if not hFrame then
			return
		end
		local hBtnRef = hFrame:Lookup('Btn_CU')
		local hBtnNew = hFrame:Lookup('Btn_MY_Sort')
		if not hBtnRef then
			return
		end
		local nX = hBtnRef:GetRelX()
		local nY = hBtnRef:GetRelY()
		local nH = hBtnRef:GetH()
		if not hBtnNew then
			hBtnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Sort',
					w = 'auto', h = nH,
					text = _L['Sort'],
					tip = {
						render = _L['Press shift for random, right click to import and export'],
						position = X.UI.TIP_POSITION.BOTTOM_TOP,
					},
					onLClick = function()
						local bRandom = IsShiftKeyDown()
						MY_BagEx_Bag.ShowAllItemShadow()
						if MY_BagEx_Bag.bConfirm then
							X.Confirm('MY_BagEx_BagSort', _L['Sure to start bag sort?'], {
								x = hFrame:GetAbsX() + hFrame:GetW() / 2,
								y = hFrame:GetAbsY() + hFrame:GetH() / 2,
								fnResolve = function() D.Operate(bRandom) end,
								fnReject = MY_BagEx_Bag.HideAllItemShadow,
								fnCancel = MY_BagEx_Bag.HideAllItemShadow,
								fnAutoClose = function() return not hFrame or not hFrame:IsVisible() end,
							})
						else
							D.Operate(bRandom)
						end
					end,
					menuRClick = function()
						return {
							{
								szOption = _L['Export blueprint'],
								fnAction = function()
									D.Operate(false, true)
									X.UI.ClosePopupMenu()
								end,
							},
							{
								szOption = _L['Import blueprint'],
								fnAction = function()
									GetUserInput(_L['Please input blueprint'], function(szBlueprint)
										local aBlueprint = MY_BagEx.DecodeItemDescList(szBlueprint)
										if aBlueprint then
											MY_BagEx_Bag.ShowAllItemShadow()
											D.Operate(false, false, aBlueprint)
										else
											X.OutputSystemAnnounceMessage(_L['Invalid blueprint data'])
										end
									end, nil, nil, nil, '')
								end,
							},
						}
					end,
				})
				:Raw()
		end
		if not hBtnNew then
			return
		end
		hBtnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ�����Ŧ
		X.UI('Normal/BigBagPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagSort__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
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
