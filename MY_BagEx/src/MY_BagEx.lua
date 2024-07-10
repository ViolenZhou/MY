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
local MODULE_PATH = 'MY_BagEx/MY_BagEx'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {
	-- ��Ʒ����˳��
	aGenre = {
		[ITEM_GENRE.TASK_ITEM] = 1,
		[ITEM_GENRE.EQUIPMENT] = 2,
		[ITEM_GENRE.BOOK] = 3,
		[ITEM_GENRE.POTION] = 4,
		[ITEM_GENRE.MATERIAL] = 5,
	},
	aSub = {
		[EQUIPMENT_SUB.HORSE] = 1,
		[EQUIPMENT_SUB.PACKAGE] = 2,
		[EQUIPMENT_SUB.MELEE_WEAPON] = 3,
		[EQUIPMENT_SUB.RANGE_WEAPON] = 4,
	},
}

local ITEM_DESC_LIST_SCHEMA = X.Schema.Collection(X.Schema.OneOf(
	X.Schema.Record({
		dwTabType = X.Schema.Number,
		dwTabIndex = X.Schema.Number,
		nBookID = X.Schema.Number,
		nStackNum = X.Schema.Number,
		nCurrentDurability = X.Schema.Number,
		bBind = X.Schema.Boolean,
	}, false),
	X.Schema.Record({}, false)
))

function D.GetItemDesc(kItem)
	if not kItem then
		return X.CONSTANT.EMPTY_TABLE
	end
	return {
		dwTabType = kItem.dwTabType,
		dwTabIndex = kItem.dwIndex,
		nBookID = kItem.nBookID,
		nGenre = kItem.nGenre,
		nSub = kItem.nSub,
		nDetail = kItem.nDetail,
		nQuality = kItem.nQuality,
		bCanStack = kItem.bCanStack,
		nStackNum = kItem.nStackNum,
		nCurrentDurability = kItem.nCurrentDurability,
		bBind = kItem.bBind,
	}
end

function D.IsSameItemDesc(a, b, bIgnoreStackNum)
	if X.IsEmpty(a) and X.IsEmpty(b) then
		return true
	end
	if X.IsEmpty(a) or X.IsEmpty(b) then
		return false
	end
	if a.dwTabType ~= b.dwTabType or a.dwTabIndex ~= b.dwTabIndex then
		return false
	end
	if a.nGenre == ITEM_GENRE.BOOK and a.nBookID ~= b.nBookID then
		return false
	end
	if not bIgnoreStackNum and a.bCanStack and a.nStackNum ~= b.nStackNum then
		return false
	end
	if a.bBind ~= b.bBind then
		return false
	end
	return true
end

function D.CanItemDescStack(a, b)
	if X.IsEmpty(a) or X.IsEmpty(b) then
		return false
	end
	if a.dwTabType ~= b.dwTabType or a.dwTabIndex ~= b.dwTabIndex then
		return false
	end
	if a.nGenre == ITEM_GENRE.BOOK and a.nBookID ~= b.nBookID then
		return false
	end
	return a.bCanStack
end

-- �����������������
function D.ItemDescSorter(a, b)
	-- �հ׸��ӿ���
	if X.IsEmpty(a) then
		return false
	end
	if X.IsEmpty(b) then
		return true
	end
	-- ���Ͳ�ͬ����������
	local nGenreA = D.aGenre[a.nGenre] or (100 + a.nGenre)
	local nGenreB = D.aGenre[b.nGenre] or (100 + b.nGenre)
	if nGenreA ~= nGenreB then
		return nGenreA < nGenreB
	end
	-- װ����Ƚ�
	if a.nGenre == ITEM_GENRE.EQUIPMENT then
		local nSubA = D.aSub[a.nSub] or (100 + a.nSub)
		local nSubB = D.aSub[b.nSub] or (100 + b.nSub)
		-- ��װ����������
		if nSubA ~= nSubB then
			return nSubA > nSubB
		end
		-- ����������������
		if a.nSub == EQUIPMENT_SUB.MELEE_WEAPON or a.nSub == EQUIPMENT_SUB.RANGE_WEAPON then
			if a.nDetail ~= b.nDetail then
				return a.nDetail < b.nDetail
			end
		end
		-- ���������������ǰ��
		if b.nSub == EQUIPMENT_SUB.PACKAGE then
			if a.nCurrentDurability ~= b.nCurrentDurability then
				return a.nCurrentDurability > b.nCurrentDurability
			end
		end
	end
	-- ����Ʒ�ʱȽ�
	if a.nQuality ~= b.nQuality then
		return a.nQuality > b.nQuality
	end
	-- ������Ʒ���±�����
	if a.dwTabType ~= b.dwTabType then
		return a.dwTabType < b.dwTabType
	end
	if a.dwTabIndex ~= b.dwTabIndex then
		return a.dwTabIndex < b.dwTabIndex
	end
	if a.nGenre == ITEM_GENRE.BOOK and a.nBookID ~= b.nBookID then
		return a.nBookID < b.nBookID
	end
	-- ���ѵ���������
	if b.bCanStack then
		return a.nStackNum > b.nStackNum
	end
	return false
end

function D.EncodeItemDescList(aItemDesc)
	local aList = {}
	for nIndex, tDesc in ipairs(aItemDesc) do
		-- �������Զ�������
		aList[nIndex] = {
			dwTabType = tDesc.dwTabType,
			dwTabIndex = tDesc.dwTabIndex,
			nBookID = tDesc.nBookID,
			nStackNum = tDesc.nStackNum,
			nCurrentDurability = tDesc.nCurrentDurability,
			bBind = tDesc.bBind,
		}
	end
	return X.CompressLUAData(aList)
end

function D.DecodeItemDescList(szBin)
	local aList = X.DecompressLUAData(szBin)
	local errs = X.Schema.CheckSchema(aList, ITEM_DESC_LIST_SCHEMA)
	if not errs then
		local aItemDesc = {}
		for nIndex, tItem in ipairs(aList) do
			local kItemInfo = GetItemInfo(tItem.dwTabType, tItem.dwTabIndex)
			if kItemInfo then
				aItemDesc[nIndex] = {
					dwTabType = tItem.dwTabType,
					dwTabIndex = tItem.dwTabIndex,
					nBookID = tItem.nBookID,
					nStackNum = tItem.nStackNum,
					nCurrentDurability = tItem.nCurrentDurability,
					bBind = tItem.bBind,
					-- �� ItemInfo �лָ���������
					nGenre = kItemInfo.nGenre,
					nSub = kItemInfo.nSub,
					nDetail = kItemInfo.nDetail,
					nQuality = kItemInfo.nQuality,
					bCanStack = kItemInfo.bCanStack,
				}
			else
				aItemDesc[nIndex] = {}
			end
		end
		return aItemDesc
	end
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx',
	exports = {
		{
			fields = {
				GetItemDesc = D.GetItemDesc,
				IsSameItemDesc = D.IsSameItemDesc,
				CanItemDescStack = D.CanItemDescStack,
				ItemDescSorter = D.ItemDescSorter,
				EncodeItemDescList = D.EncodeItemDescList,
				DecodeItemDescList = D.DecodeItemDescList,
			},
		},
	},
}
MY_BagEx = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
