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
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^19.0.0-alpha.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ���ֿ�����
function D.SortGuildBank()
	local frame = Station.Lookup('Normal/GuildBankPanel')
	if not frame then
		return
	end
	local nPage, szState = frame.nPage or 0, 'Idle'
	-- ���ظ����б�
	local me, aInfo, nItemCount = X.GetClientPlayer(), {}, 0
	for i = 1, X.GetGuildBankBagSize(nPage) do
		local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
		local item = GetPlayerItem(me, dwPos, dwX)
		if item then
			table.insert(aInfo, {
				dwID = item.dwID,
				nUiId = item.nUiId,
				dwTabType = item.dwTabType,
				dwIndex = item.dwIndex,
				nGenre = item.nGenre,
				nSub = item.nSub,
				nDetail = item.nDetail,
				nQuality = item.nQuality,
				bCanStack = item.bCanStack,
				nStackNum = item.nStackNum,
				nCurrentDurability = item.nCurrentDurability,
				szName = X.GetObjectName('ITEM', item),
			})
			nItemCount = nItemCount + 1
		else
			table.insert(aInfo, X.CONSTANT.EMPTY_TABLE)
		end
	end
	if nItemCount == 0 then
		return
	end
	-- ��������б�
	if IsShiftKeyDown() then
		for i = 1, #aInfo do
			local j = X.Random(1, #aInfo)
			if i ~= j then
				aInfo[i], aInfo[j] = aInfo[j], aInfo[i]
			end
		end
	else
		table.sort(aInfo, MY_BagEx.ItemSorter)
	end
	-- �������������ָ��ؼ�״̬
	local function fnFinish()
		szState = 'Idle'
		X.RegisterEvent('TONG_EVENT_NOTIFY', 'MY_BagEx_GuildBankSort__Sort', false)
		X.RegisterEvent('UPDATE_TONG_REPERTORY_PAGE', 'MY_BagEx_GuildBankSort__Sort', false)
		FireUIEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', false)
	end
	-- �����������뵱ǰ״̬������Ʒ
	local function fnNext()
		if not frame or (frame.nPage or 0) ~= nPage then
			X.Systopmsg(_L['Guild box closed or page changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			return fnFinish()
		end
		if szState == 'Exchanging' or szState == 'Refreshing' then
			return
		end
		for i, info in ipairs(aInfo) do
			local dwPos, dwX = X.GetGuildBankBagPos(nPage, i)
			local item = GetPlayerItem(me, dwPos, dwX)
			-- ��ǰ���Ӻ�Ԥ�ڲ��� ��Ҫ����
			if not MY_BagEx.IsSameItem(item, info) then
				-- ��ǰ���Ӻ�Ԥ����Ʒ�ɶѵ� ���ø���Ķ����滻��������ᵼ����Ʒ�ϲ�
				if item and info.dwID and item.nUiId == info.nUiId and item.bCanStack and item.nStackNum ~= info.nStackNum then
					for j = X.GetGuildBankBagSize(nPage), i + 1, -1 do
						local dwPos1, dwX1 = X.GetGuildBankBagPos(nPage, j)
						local item1 = GetPlayerItem(me, INVENTORY_GUILD_BANK, dwX1)
						-- ƥ�䵽���ڽ����ĸ���
						if not item1 or item1.nUiId ~= item.nUiId then
							szState = 'Exchanging'
							if item then
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <T1>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
							else
								--[[#DEBUG BEGIN]]
								X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <T2>', X.DEBUG_LEVEL.LOG)
								--[[#DEBUG END]]
								OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
							end
							return
						end
					end
					X.Systopmsg(_L['Cannot find item temp position, guild bag is full, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
					return fnFinish()
				end
				-- Ѱ��Ԥ����Ʒ����λ��
				for j = X.GetGuildBankBagSize(nPage), i + 1, -1 do
					local dwPos1, dwX1 = X.GetGuildBankBagPos(nPage, j)
					local item1 = GetPlayerItem(me, dwPos1, dwX1)
					-- ƥ�䵽Ԥ����Ʒ����λ��
					if MY_BagEx.IsSameItem(item1, info) then
						szState = 'Exchanging'
						if item then
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX .. ' <-> ' .. 'GUILD,' .. dwX1 .. ' <N1>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos, dwX, dwPos1, dwX1)
						else
							--[[#DEBUG BEGIN]]
							X.Debug('MY_BagEx_GuildBankSort', 'OnExchangeItem: GUILD,' .. dwX1 .. ' <-> ' .. 'GUILD,' .. dwX .. ' <N2>', X.DEBUG_LEVEL.LOG)
							--[[#DEBUG END]]
							OnExchangeItem(dwPos1, dwX1, dwPos, dwX)
						end
						return
					end
				end
				X.Systopmsg(_L['Exchange item match failed, guild bag may changed, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
				return fnFinish()
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
			X.Systopmsg(_L['Put item in guild detected, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
		else
			X.Systopmsg(_L['Unknown exception occurred, sort exited!'], X.CONSTANT.MSG_THEME.ERROR)
			fnFinish()
			--[[#DEBUG BEGIN]]
			X.Debug('MY_BagEx_GuildBankSort', 'TONG_EVENT_NOTIFY: ' .. arg0, X.DEBUG_LEVEL.LOG)
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
		local frame = Station.Lookup('Normal/GuildBankPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_Refresh')
		local btnNew = frame:Lookup('Btn_MY_Sort')
		if btnRef then
			if not btnNew then
				local nX, nY = btnRef:GetRelPos()
				local nW, nH = btnRef:GetSize()
				btnNew = X.UI('Normal/GuildBankPanel')
					:Append('WndButton', {
						name = 'Btn_MY_Sort',
						x = nX - nW, y = nY, w = nW, h = nH - 2,
						text = _L['Sort'],
						tip = {
							render = _L['Press shift for random'],
							position = X.UI.TIP_POSITION.BOTTOM_TOP,
						},
						onClick = function()
							if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
								X.Systopmsg(_L['Please unlock mibao first.'])
								return
							end
							if MY_BagEx_Bag.bConfirm then
								X.Confirm('MY_BagEx_GuildBankSort', _L['Sure to start guild bank sort?'], {
									x = frame:GetAbsX() + frame:GetW() / 2,
									y = frame:GetAbsY() + frame:GetH() / 2,
									fnResolve = D.SortGuildBank,
								})
							else
								D.SortGuildBank()
							end
						end,
					})
					:Raw()
			end
		end
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ�����Ŧ
		X.UI('Normal/GuildBankPanel/Btn_MY_Sort'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_GuildBankSort__Injection', false)
	end
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
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
