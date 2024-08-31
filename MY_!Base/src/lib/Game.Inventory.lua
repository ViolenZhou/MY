--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Inventory')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ��Ʒ����Ʒ�洢�����ϡ��������ֿ⡢���ֿ�
--------------------------------------------------------------------------------

-- �����Ʒ�洢λ��ת��Ϊ�ٷ���Ʒ�洢λ��
---@param dwBox number @��Ʒ�洢��
---@param dwX number @�洢����ָ����Ʒ�±�
---@return number,number @�ٷ��洢��λ��(dwBox),�ٷ��洢����ָ����Ʒ���±�(dwX)
local function GetOfficialInventoryBoxPos(dwBox, dwX)
	-- ���ֿ��Ϊ����λ�ã����⴦��
	if dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE1
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE2
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE3
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE4
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE5
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE6
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE7
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE8
	then
		local nPage = dwBox - X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
		local nPageSize = INVENTORY_GUILD_PAGE_SIZE or 100
		return INVENTORY_GUILD_BANK or INVENTORY_INDEX.TOTAL + 1, nPage * nPageSize + dwX
	end
	return dwBox, dwX
end

-- ��ȡָ��������Ʒ�洢��λ���б�
---@param eType number @��Ʒ�洢��ָ������
---@return number[] @�洢��λ���б�
function X.GetInventoryBoxList(eType)
	-- ����װ����
	if eType == X.CONSTANT.INVENTORY_TYPE.EQUIP then
		return X.Clone(X.CONSTANT.INVENTORY_EQUIP_LIST)
	end
	-- ������
	if eType == X.CONSTANT.INVENTORY_TYPE.PACKAGE then
		if X.IsInInventoryPackageLimitedMap() then
			return X.Clone(X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST)
		end
		return X.Clone(X.CONSTANT.INVENTORY_PACKAGE_LIST)
	end
	-- �ֿ��
	if eType == X.CONSTANT.INVENTORY_TYPE.BANK then
		local me, aList = X.GetClientPlayer(), {}
		for i = 1, me.GetBankPackageCount() + 1 do
			aList[i] = X.CONSTANT.INVENTORY_BANK_LIST[i]
		end
		return aList
	end
	-- ���ֿ������λ�ò����������ߴ洢��
	if eType == X.CONSTANT.INVENTORY_TYPE.GUILD_BANK then
		return X.Clone(X.CONSTANT.INVENTORY_GUILD_BANK_LIST)
	end
	-- ԭʼ������
	if eType == X.CONSTANT.INVENTORY_TYPE.ORIGIN_PACKAGE then
		return X.Clone(X.CONSTANT.INVENTORY_PACKAGE_LIST)
	end
	-- ���ⱳ����
	if eType == X.CONSTANT.INVENTORY_TYPE.LIMITED_PACKAGE then
		return X.Clone(X.CONSTANT.INVENTORY_LIMITED_PACKAGE_LIST)
	end
end

-- ��ȡָ����Ʒ�洢��ɴ����Ʒ������ָ��λ��װ�����Ĵ�С��
---@param dwBox number @��Ʒ�洢��λ��
---@return number @�洢��ɴ����Ʒ����
function X.GetInventoryBoxSize(dwBox)
	-- ���ֿ��Ϊ����λ�ã����⴦��
	if dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE1
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE2
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE3
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE4
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE5
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE6
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE7
	or dwBox == X.CONSTANT.INVENTORY_INDEX.GUILD_BANK_PACKAGE8
	then
		return 98
	end
	-- �������߽ӿڻ�ȡ
	local me = X.GetClientPlayer()
	return me.GetBoxSize(dwBox)
end

-- ��ȡָ����Ʒ�洢��λ�õ���Ʒ����
---@param me userdata @��Ҷ���
---@param dwBox number @��Ʒ�洢��
---@param dwX number @�洢����ָ����Ʒ�±�
---@return userdata|nil @ָ��λ�õ���Ʒ���������򷵻ؿ�
function X.GetInventoryItem(me, dwBox, dwX)
	dwBox, dwX = GetOfficialInventoryBoxPos(dwBox, dwX)
	return GetPlayerItem(me, dwBox, dwX)
end

-- ���Q������Ʒ�洢��λ�õ���Ʒ����
---@param dwBox1 number @��Ʒ�洢��1
---@param dwX1 number @�洢����ָ����Ʒ1�±�
---@param dwBox2 number @��Ʒ�洢��2
---@param dwX2 number @�洢����ָ����Ʒ2�±�
function X.ExchangeInventoryItem(dwBox1, dwX1, dwBox2, dwX2)
	dwBox1, dwX1 = GetOfficialInventoryBoxPos(dwBox1, dwX1)
	dwBox2, dwX2 = GetOfficialInventoryBoxPos(dwBox2, dwX2)
	if (
		dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE1
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE2
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE3
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE4
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.PACKAGE_MIBAO
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.LIMITED_PACKAGE
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE1
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE2
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE3
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE4
		or dwBox1 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE5
	) and (
		dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE1
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE2
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE3
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE4
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.PACKAGE_MIBAO
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.LIMITED_PACKAGE
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE1
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE2
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE3
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE4
		or dwBox2 == X.CONSTANT.INVENTORY_INDEX.BANK_PACKAGE5
	) then
		local me = X.GetClientPlayer()
		if me then
			me.ExchangeItem(dwBox1, dwX1, dwBox2, dwX2)
			return
		end
	end
	OnExchangeItem(dwBox1, dwX1, dwBox2, dwX2)
end

-- ��ȡָ��������Ʒ�洢���λ����
---@param eType number @��Ʒ�洢��ָ������
---@return number @�洢���λ����
function X.GetInventoryEmptyItemCount(eType)
	local me, nCount = X.GetClientPlayer(), 0
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not X.GetInventoryItem(me, dwBox, dwX) then
				nCount = nCount + 1
			end
		end
	end
	return nCount
end

-- ��ȡָ��������Ʒ�洢���һ����λλ��
---@param eType number @��Ʒ�洢��ָ������
---@return number,number @�洢���һ����λλ�ã��������ؿ�
function X.GetInventoryEmptyItemPos(eType)
	local me = X.GetClientPlayer()
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			if not X.GetInventoryItem(me, dwBox, dwX) then
				return dwBox, dwX
			end
		end
	end
end

-- ����ָ��������Ʒ�洢��������Ʒ
---@param eType number @��Ʒ�洢��ָ������
---@param fnIter function @����������������0ֹͣ����
function X.IterInventoryItem(eType, fnIter)
	local me = X.GetClientPlayer()
	for _, dwBox in ipairs(X.GetInventoryBoxList(eType)) do
		for dwX = 0, X.GetInventoryBoxSize(dwBox) - 1 do
			local kItem = X.GetInventoryItem(me, dwBox, dwX)
			if kItem and fnIter(kItem, dwBox, dwX) == 0 then
				return
			end
		end
	end
end

do local CACHE = {}
-- ��ȡָ����Ʒ��ָ�����͵���Ʒ�洢���е�������
---@param eType number @��Ʒ�洢��ָ������
---@param dwTabType number @ָ����Ʒ�ı�����
---@param dwIndex number @ָ����Ʒ�ı��±�
---@param nBookID number @ָ����ƷΪ�鼮����µ��鼮ID
---@return number @ָ����Ʒ��������
function X.GetInventoryItemAmount(eType, dwTabType, dwIndex, nBookID)
	if not CACHE[eType] then
		CACHE[eType] = {}
	end
	local szKey = X.GetItemKey(dwTabType, dwIndex, nBookID)
	if not CACHE[eType][szKey] then
		local nAmount = 0
		X.IterInventoryItem(eType, function(kItem)
			if szKey == X.GetItemKey(kItem) then
				nAmount = nAmount + (kItem.bCanStack and kItem.nStackNum or 1)
			end
		end)
		CACHE[eType][szKey] = nAmount
	end
	return CACHE[eType][szKey]
end
X.RegisterEvent({'BAG_ITEM_UPDATE', 'BANK_ITEM_UPDATE', 'LOADING_ENDING'}, 'LIB#GetInventoryItemAmount', function() CACHE = {} end)
end

-- Ѱ����Ʒλ��
-- X.GetInventoryItemPos(eType, szName)
-- X.GetInventoryItemPos(eType, dwTabType, dwIndex, nBookID)
---@param eType number @��Ʒ�洢��ָ������
---@param szName string @Ҫʹ�õ���Ʒ����
---@param dwTabType number @Ҫʹ�õ���Ʒ������
---@param dwIndex number @Ҫʹ�õ���Ʒ���±�
---@param nBookID number @Ҫʹ�õ���ƷΪ�鼮ʱ���鼮ID
---@return number,number @��Ʒ���꣬�Ҳ������ؿ�
function X.GetInventoryItemPos(eType, dwTabType, dwIndex, nBookID)
	local dwRetBox, dwRetX = nil, nil
	if X.IsString(dwTabType) then
		X.IterInventoryItem(eType, function(kItem, dwBox, dwX)
			if X.GetItemName(kItem.dwID) == dwTabType then
				dwRetBox, dwRetX = dwBox, dwX
				return 0
			end
		end)
	else
		X.IterInventoryItem(eType, function(kItem, dwBox, dwX)
			if kItem.dwTabType == dwTabType and kItem.dwIndex == dwIndex then
				if kItem.nGenre == ITEM_GENRE.BOOK and kItem.nBookID ~= nBookID then
					return
				end
				dwRetBox, dwRetX = dwBox, dwX
				return 0
			end
		end)
	end
	return dwRetBox, dwRetX
end

-- װ��ָ���洢���װ��
---@param dwBox number @��Ʒ�洢��
---@param dwX number @�洢����ָ����Ʒ�±�
function X.EquipInventoryItem(dwBox, dwX)
	local me = X.GetClientPlayer()
	local kItem = X.GetInventoryItem(me, dwBox, dwX)
	local szName = X.GetItemNameByUIID(kItem.nUiId)
	if szName == g_tStrings.tBulletDetail[BULLET_DETAIL.SNARE]
	or szName == g_tStrings.tBulletDetail[BULLET_DETAIL.BOLT] then
		for dwBulletX = 0, 15 do
			if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, dwBulletX) == nil then
				X.ExchangeInventoryItem(dwBox, dwX, INVENTORY_INDEX.BULLET_PACKAGE, dwBulletX)
				break
			end
		end
	else
		local dwEquipX = select(2, me.GetEquipPos(GetOfficialInventoryBoxPos(dwBox, dwX)))
		X.ExchangeInventoryItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, dwEquipX)
	end
end

-- ʹ����Ʒ
---@param dwBox number @��Ʒ�洢��
---@param dwX number @�洢����ָ����Ʒ�±�
function X.UseInventoryItem(dwBox, dwX)
	dwBox, dwX = GetOfficialInventoryBoxPos(dwBox, dwX)
	OnUseItem(dwBox, dwX)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
