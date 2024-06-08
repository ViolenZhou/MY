--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ֿ�����
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_GuildBankSort'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_GuildBankSort'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^22.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

function D.Operate(bRandom, bExportBlueprint, aBlueprint)
	local hFrame = Station.Lookup('Normal/GuildBankPanel')
	if not hFrame then
		return
	end
	local nPage, szState = hFrame.nPage or 0, 'Idle'
	local dwBox = X.CONSTANT.INVENTORY_GUILD_BANK_LIST[nPage + 1]
	-- ���ظ����б�
	local me, aItemDesc, nItemCount, aBoxPos = X.GetClientPlayer(), {}, 0, {}
	for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
		local kItem = X.GetInventoryItem(me, dwBox, dwX)
		local tDesc = MY_BagEx.GetItemDesc(kItem)
		if not X.IsEmpty(tDesc) then
			nItemCount = nItemCount + 1
		end
		table.insert(aItemDesc, tDesc)
		table.insert(aBoxPos, { dwBox = dwBox, dwX = dwX })
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
		-- ��������б�
		if bRandom then
			for nIndex = 1, #aItemDesc do
				local nExcIndex = X.Random(1, #aItemDesc)
				if nIndex ~= nExcIndex then
					aItemDesc[nIndex], aItemDesc[nExcIndex] = aItemDesc[nExcIndex], aItemDesc[nIndex]
				end
			end
		else
			table.sort(aItemDesc, MY_BagEx.ItemDescSorter)
		end
	end
	-- �������������ָ��ؼ�״̬
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankSort__Sort', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankSort__Sort', false)
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- �����������뵱ǰ״̬������Ʒ
	local nIndex, bChanged = 1, false
	local function fnNext()
		if not hFrame or (hFrame.nPage or 0) ~= nPage then
			X.OutputSystemAnnounceMessage(_L['Guild box closed or page changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' or szState == 'Refreshing' then
			return
		end
		while nIndex <= #aItemDesc do
			local tDesc = aItemDesc[nIndex]
			local tBoxPos = aBoxPos[nIndex]
			local dwBox, dwX = tBoxPos.dwBox, tBoxPos.dwX
			local kCurItem = X.GetInventoryItem(me, dwBox, dwX)
			local tCurDesc = MY_BagEx.GetItemDesc(kCurItem)
			-- ��ǰ���Ӻ�Ԥ�ڲ��� ��Ҫ����
			if MY_BagEx.IsSameItemDesc(tDesc, tCurDesc) then
				nIndex = nIndex + 1
			else
				local tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc
				-- Ѱ��Ԥ����Ʒ����λ��
				if not dwExcBox then
					for nExcIndex = #aBoxPos, nIndex + 1, -1 do
						tExcBoxPos = aBoxPos[nExcIndex]
						dwExcBox, dwExcX = tExcBoxPos.dwBox, tExcBoxPos.dwX
						kExcItem = X.GetInventoryItem(me, dwExcBox, dwExcX)
						tExcDesc = MY_BagEx.GetItemDesc(kExcItem)
						-- ƥ�䵽Ԥ����Ʒ����λ��
						if MY_BagEx.IsSameItemDesc(tDesc, tExcDesc) then
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
						if MY_BagEx.IsSameItemDesc(tDesc, tExcDesc, true) then
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
						if not MY_BagEx.CanItemDescStack(tCurDesc, tExcDesc) then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Guild bank item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, guild bank is full, sort exited!']
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
						if not kExcItem then
							break
						end
						tExcBoxPos, dwExcBox, dwExcX, kExcItem, tExcDesc = nil, nil, nil, nil, nil
					end
					if not dwExcBox then
						local szMsg = bChanged
							and _L['Guild bank item changed, sort finished, result may not be perfect!']
							or _L['Cannot find item temp position, guild bank is full, sort exited!']
						X.OutputSystemAnnounceMessage(szMsg, X.CONSTANT.MSG_THEME.ERROR)
						return fnFinish()
					end
				end
				szState = 'Exchanging'
				if kCurItem then
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_GuildBankSort', 'ExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwExcX .. ' <T1>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwBox, dwX, dwExcBox, dwExcX)
				else
					--[[#DEBUG BEGIN]]
					X.OutputDebugMessage('MY_BagEx_GuildBankSort', 'ExchangeItem: GUILD,' .. dwExcX .. ' <-> ' .. 'GUILD,' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
					--[[#DEBUG END]]
					X.ExchangeInventoryItem(dwExcBox, dwExcX, dwBox, dwX)
				end
				return
			end
		end
		fnFinish()
	end
	X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankSort__Sort', function()
		if szState == 'Refreshing' then
			szState = 'Idle'
			fnNext()
		end
	end)
	X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankSort__Sort', function()
		-- TONG_EVENT_CODE.TAKE_REPERTORY_ITEM_PERMISSION_DENY_ERROR
		if arg0 == TONG_EVENT_CODE.EXCHANGE_REPERTORY_ITEM_SUCCESS then
			szState = 'Refreshing'
		elseif arg0 == TONG_EVENT_CODE.PUT_ITEM_IN_REPERTORY_SUCCESS then
			X.OutputSystemAnnounceMessage(_L['Put item in guild detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		else
			X.OutputSystemAnnounceMessage(_L['Unknown exception occurred, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('MY_BagEx_GuildBankSort', 'TONG_EVENT_NOTIFY: ' .. arg0, X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
		end
	end)
	FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', true)
	fnNext()
end

-- ������Ӱ�Ŧ
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_GuildBank.bEnable then
		-- ֲ������Ŧ
		local hFrame = Station.Lookup('Normal/GuildBankPanel')
		if not hFrame then
			return
		end
		local hBtnRef = hFrame:Lookup('Btn_Refresh')
		local hBtnNew = hFrame:Lookup('Btn_MY_Sort')
		if hBtnRef then
			if not hBtnNew then
				local nX, nY = hBtnRef:GetRelPos()
				local nW, nH = hBtnRef:GetSize()
				hBtnNew = X.UI('Normal/GuildBankPanel')
					:Append('WndButton', {
						name = 'Btn_MY_Sort',
						x = nX - nW, y = nY, w = nW, h = nH,
						text = _L['Sort'],
						tip = {
							render = _L['Press shift for random, right click to import and export'],
							position = X.UI.TIP_POSITION.BOTTOM_TOP,
						},
						onLClick = function()
							if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
								X.OutputSystemAnnounceMessage(_L['Please unlock mibao first.'])
								return
							end
							local bRandom = IsShiftKeyDown()
							if MY_BagEx_GuildBank.bConfirm then
								X.Confirm('MY_BagEx_GuildBankSort', _L['Sure to start guild bank sort?'], {
									x = hFrame:GetAbsX() + hFrame:GetW() / 2,
									y = hFrame:GetAbsY() + hFrame:GetH() / 2,
									fnResolve = function() D.Operate(bRandom) end,
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
		end
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', function()
			if not hBtnNew then
				return
			end
			hBtnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ�����Ŧ
		X.UI('Normal/GuildBankPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_GuildBankSort',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_GuildBankSort = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagEx_GuildBankSort', function() D.CheckInjection() end)
X.RegisterFrameCreate('GuildBankPanel', 'MY_BagEx_GuildBankSort', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_GuildBankSort', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
