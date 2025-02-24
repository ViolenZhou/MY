--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Doodad')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- �������
--------------------------------------------------------------------------------

-- ��һ��ʰȡ�����������ǰ֡�ظ����ý���һ�η�ֹ�Ҷ���
function X.OpenDoodad(me, doodad)
	X.Throttle(X.NSFormatString('{$NS}#OpenDoodad') .. doodad.dwID, 375, function()
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('Open Doodad ' .. doodad.dwID .. ' [' .. doodad.szName .. '] at ' .. GetLogicFrameCount() .. '.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		OpenDoodad(me, doodad)
	end)
end

-- ����һ��ʰȡ�����������ǰ֡�ظ����ý�����һ�η�ֹ�Ҷ���
function X.InteractDoodad(dwID)
	X.Throttle(X.NSFormatString('{$NS}#InteractDoodad') .. dwID, 375, function()
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('Open Doodad ' .. dwID .. ' at ' .. GetLogicFrameCount() .. '.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		InteractDoodad(dwID)
	end)
end

-- ��ȡ����ʰȡ��Ǯ����
---@param dwDoodadID number @����ʰȡID
---@return number @����ʰȡ��Ǯ����
function X.GetDoodadLootMoney(dwDoodadID)
	if X.IS_REMAKE then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		return scene and scene.GetLootMoney(dwDoodadID)
	else
		local doodad = X.GetDoodad(dwDoodadID)
		return doodad and doodad.GetLootMoney()
	end
end

-- ��ȡ����ʰȡ��Ʒ����
---@param dwDoodadID number @����ʰȡID
---@return number @����ʰȡ��Ʒ����
function X.GetDoodadLootItemCount(dwDoodadID)
	if X.IS_REMAKE then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		local tLoot = scene and scene.GetLootList(dwDoodadID)
		return tLoot and tLoot.nItemCount or nil
	else
		local doodad = X.GetDoodad(dwDoodadID)
		return doodad and doodad.GetItemListCount()
	end
end

-- ��ȡ����ʰȡ��Ʒ
---@param dwDoodadID number @����ʰȡID
---@return KItem,boolean,boolean,boolean @����ʰȡ��Ʒ,�Ƿ���ҪRoll��,�Ƿ���Ҫ����,�Ƿ���Ҫ����
function X.GetDoodadLootItem(dwDoodadID, nIndex)
	if X.IS_REMAKE then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		local tLoot = scene and scene.GetLootList(dwDoodadID)
		local it = tLoot and tLoot[nIndex - 1]
		if it then
			local bNeedRoll = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_ROLL
			local bDist = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_DISTRIBUTE
			local bBidding = it.LootType == X.CONSTANT.LOOT_ITEM_TYPE.NEED_BIDDING
			return it.Item, bNeedRoll, bDist, bBidding
		end
	else
		local me = X.GetClientPlayer()
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			return doodad.GetLootItem(nIndex - 1, me)
		end
	end
end

-- �������ʰȡ��Ʒ
---@param dwDoodadID number @����ʰȡID
---@param dwItemID number @������ƷID
---@param dwTargetPlayerID number @��������ID
function X.DistributeDoodadItem(dwDoodadID, dwItemID, dwTargetPlayerID)
	if X.IS_REMAKE then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		if scene then
			scene.DistributeItem(dwDoodadID, dwItemID, dwTargetPlayerID)
		end
	else
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			doodad.DistributeItem(dwItemID, dwTargetPlayerID)
		end
	end
end

-- ��ȡ�����ʰȡ����б�
---@param dwDoodadID number @����ʰȡID
---@return number[] @��ʰȡ����б�
function X.GetDoodadLooterList(dwDoodadID)
	if X.IS_REMAKE then
		local me = X.GetClientPlayer()
		local scene = me and me.GetScene()
		if scene then
			return scene.GetLooterList(dwDoodadID)
		end
	else
		local doodad = X.GetDoodad(dwDoodadID)
		if doodad then
			return doodad.GetLooterList()
		end
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
