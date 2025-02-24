--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Item')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do local CACHE = {}
-- ��ȡָ����Ʒ��Ψһ��
-- X.GetItemKey(dwTabType, dwIndex, nBookID)
-- X.GetItemKey(KItem)
-- X.GetItemKey(KItemInfo, nBookID)
---@param dwTabType number @��Ʒ������
---@param dwIndex number @��Ʒ���±�
---@param nBookID number @��ƷΪ�鼮ʱ���鼮ID
---@param KItem usedata @��Ʒ����
---@param KItemInfo usedata @��Ʒģ�����
function X.GetItemKey(dwTabType, dwIndex, nBookID)
	local it, nGenre
	if X.IsUserdata(dwTabType) then
		it, nBookID = dwTabType, dwIndex
		nGenre = it.nGenre
		if not nBookID and nGenre == ITEM_GENRE.BOOK then
			nBookID = it.nBookID or -1
		end
		dwTabType, dwIndex = it.dwTabType, it.dwIndex
	else
		local KItemInfo = GetItemInfo(dwTabType, dwIndex)
		nGenre = KItemInfo and KItemInfo.nGenre
	end
	if not CACHE[dwTabType] then
		CACHE[dwTabType] = {}
	end
	if nGenre == ITEM_GENRE.BOOK then
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = {}
		end
		if not CACHE[dwTabType][dwIndex][nBookID] then
			CACHE[dwTabType][dwIndex][nBookID] = dwTabType .. ',' .. dwIndex .. ',' .. nBookID
		end
		return CACHE[dwTabType][dwIndex][nBookID]
	else
		if not CACHE[dwTabType][dwIndex] then
			CACHE[dwTabType][dwIndex] = dwTabType .. ',' .. dwIndex
		end
		return CACHE[dwTabType][dwIndex]
	end
end
end

-- * ��ǰ�����Ƿ�����װ��Ҫ�󣺰����������ͣ����ɣ��Ա𣬵ȼ������ǣ�����������
function X.DoesEquipmentSuit(kItem, bIsItem, kPlayer)
	if not kPlayer then
		kPlayer = X.GetClientPlayer()
	end
	local requireAttrib = kItem.GetRequireAttrib()
	for k, v in pairs(requireAttrib) do
		if bIsItem and not kPlayer.SatisfyRequire(v.nID, v.nValue1, v.nValue2) then
			return false
		elseif not bIsItem and not kPlayer.SatisfyRequire(v.nID, v.nValue) then
			return false
		end
	end
	return true
end

-- * ��ǰװ���Ƿ��ʺϵ�ǰ�ڹ�
do
local CACHE = {}
local m_MountTypeToWeapon = X.KvpToObject({
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TIAN_CE  , WEAPON_DETAIL.SPEAR        }, -- ����ڹ�=������
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WAN_HUA  , WEAPON_DETAIL.PEN          }, -- ���ڹ�=����
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHUN_YANG, WEAPON_DETAIL.SWORD        }, -- �����ڹ�=�̱���
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.QI_XIU   , WEAPON_DETAIL.DOUBLE_WEAPON}, -- �����ڹ� = ˫����
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.SHAO_LIN , WEAPON_DETAIL.WAND         }, -- �����ڹ�=����
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_JIAN, WEAPON_DETAIL.SWORD        }, -- �ؽ��ڹ�=�̱���,�ر��� WEAPON_DETAIL.BIG_SWORD
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.GAI_BANG , WEAPON_DETAIL.STICK        }, -- ؤ���ڹ�=�̰�
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.MING_JIAO, WEAPON_DETAIL.KNIFE        }, -- �����ڹ�=�䵶
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.WU_DU    , WEAPON_DETAIL.FLUTE        }, -- �嶾�ڹ�=����
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.TANG_MEN , WEAPON_DETAIL.BOW          }, -- �����ڹ�=ǧ��ϻ
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CANG_YUN , WEAPON_DETAIL.BLADE_SHIELD }, -- �����ڹ�=����
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.CHANG_GE , WEAPON_DETAIL.HEPTA_CHORD  }, -- �����ڹ�=��
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.BA_DAO   , WEAPON_DETAIL.BROAD_SWORD  }, -- �Ե��ڹ�=��ϵ�
	{X.CONSTANT.KUNGFU_MOUNT_TYPE.PENG_LAI , WEAPON_DETAIL.UMBRELLA     }, -- �����ڹ�=ɡ
	--WEAPON_DETAIL.FIST = ȭ��
	--WEAPON_DETAIL.DART = ����
	--WEAPON_DETAIL.MACH_DART = ���ذ���
	--WEAPON_DETAIL.SLING_SHOT = Ͷ��
})
function X.IsItemInfoFitKungfu(kItemInfo, dwKungfuID)
	local me = X.GetClientPlayer()
	local kungfu = GetSkill(dwKungfuID, me.GetSkillLevel(dwKungfuID) or 1)
	if kItemInfo.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if not kungfu then
			return false
		end
		if kItemInfo.nDetail == WEAPON_DETAIL.BIG_SWORD and kungfu.dwMountType == 6 then
			return true
		end

		if (m_MountTypeToWeapon[kungfu.dwMountType] ~= kItemInfo.nDetail) then
			return false
		end

		if not kItemInfo.nRecommendID or kItemInfo.nRecommendID == 0 then
			return true
		end
	end

	if not kItemInfo.nRecommendID then
		return
	end
	local aRecommendKungfuID = CACHE[kItemInfo.nRecommendID]
	if not aRecommendKungfuID then
		local EquipRecommend = X.GetGameTable('EquipRecommend', true)
		if EquipRecommend then
			local res = EquipRecommend:Search(kItemInfo.nRecommendID)
			aRecommendKungfuID = {}
			for i, v in ipairs(X.SplitString(res.kungfu_ids, '|')) do
				table.insert(aRecommendKungfuID, tonumber(v))
			end
		end
		CACHE[kItemInfo.nRecommendID] = aRecommendKungfuID
	end

	if not aRecommendKungfuID or not aRecommendKungfuID[1] then
		return
	end

	if aRecommendKungfuID[1] == 0 then
		return true
	end

	if not kungfu then
		return false
	end
	for _, v in ipairs(aRecommendKungfuID) do
		if v == kungfu.dwSkillID then
			return true
		end
	end
end
end

function X.IsItemFitKungfu(kItem, dwKungfuID)
	local kItemInfo = GetItemInfo(kItem.dwTabType, kItem.dwIndex)
	return X.IsItemInfoFitKungfu(kItemInfo, dwKungfuID)
end

-- ��ȡ��Ʒ�����ȼ�
---@param kItem userdata @��Ʒ����
---@param kPlayer userdata @��Ʒ������ɫ
---@return number, number, number @[��Ч�����ȼ�, ��Ʒ�����ȼ�, װ���������ȼ�]
function X.GetItemStrengthLevel(kItem, kPlayer)
	if X.IS_REMAKE then
		if not kPlayer then
			kPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(kItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and kPlayer.GetEquipBoxStrength then
			local KItemInfo = GetItemInfo(kItem.dwTabType, kItem.dwIndex)
			local nMaxStrengthLevel = KItemInfo.nMaxStrengthLevel
			local nBoxStrengthLevel = kPlayer.GetEquipBoxStrength(dwBox)
			local nItemStrengthLevel = kItem.nStrengthLevel
			local nStrengthLevel = math.min(math.max(nItemStrengthLevel, nBoxStrengthLevel), nMaxStrengthLevel)
			return nStrengthLevel, nItemStrengthLevel, nBoxStrengthLevel
		end
	end
	return kItem.nStrengthLevel, kItem.nStrengthLevel, 0
end

-- ��ȡ��Ʒ��Ƕ����Ƕ��Ϣ
---@param kItem userdata @��Ʒ����
---@param nSlotIndex string @��Ƕ���±�
---@param kPlayer userdata @��Ʒ������ɫ
---@return number, number, number @[��Ч��Ƕ������ʯID, ��Ʒ��Ƕ������ʯID, װ������Ƕ������ʯID]
function X.GetItemMountDiamondEnchantID(kItem, nSlotIndex, kPlayer)
	if X.IS_REMAKE then
		if not kPlayer then
			kPlayer = X.GetClientPlayer()
		end
		local dwPackage, dwBox = X.GetItemEquipPos(kItem)
		if dwPackage == INVENTORY_INDEX.EQUIP and kPlayer.GetEquipBoxMountDiamondEnchantID then
			local dwBoxEnchantID, nBoxQuality = kPlayer.GetEquipBoxMountDiamondEnchantID(dwBox, nSlotIndex)
            local dwItemEnchantID = kItem.GetMountDiamondEnchantID(nSlotIndex)
            local dwEnchantID = kItem.GetAdaptedDiamondEnchantID(nSlotIndex, kItem.nLevel, dwBoxEnchantID)
			return dwEnchantID, dwItemEnchantID, dwBoxEnchantID
		end
	end
	local dwItemEnchantID = kItem.GetMountDiamondEnchantID(nSlotIndex)
	return dwItemEnchantID, dwItemEnchantID, 0
end

-- ��ȡ��Ʒ���ʯ����Ƕ��Ϣ
---@param kItem userdata @��Ʒ����
---@return number @��Ч��Ƕ�����ʯID
function X.GetItemMountFEAEnchantID(kItem)
	if X.IS_REMAKE then
		return GetFEAEnchantID(kItem)
	end
	local dwItemFEAEnchantID = kItem.GetMountFEAEnchantID() or 0
	return dwItemFEAEnchantID
end

-- * ��ȡ��Ʒ��Ӧ����װ����λ��
function X.GetItemEquipPos(kItem, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local dwPackage, dwBox, nCount = INVENTORY_INDEX.EQUIP, 0, 1
	if kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		if kItem.nDetail == WEAPON_DETAIL.BIG_SWORD then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON
		end
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.ARROW then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.ARROW
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.CHEST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.CHEST
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.HELM then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.HELM
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.AMULET then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.AMULET
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.RING then
		if nIndex == 1 then
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING
		else
			dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING
		end
		nCount = 2
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PENDANT then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PENDANT
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PANTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.PANTS
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BOOTS then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BOOTS
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BANGLE then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BANGLE
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_INVENTORY.BACK_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND then
		dwBox = X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	elseif kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE then
		dwPackage, dwBox = X.GetClientPlayer().GetEquippedHorsePos()
	end
	return dwPackage, dwBox, nIndex, nCount
end

-- * ��ǰװ���Ƿ��Ǳ������Ѿ�װ���ĸ���
function X.IsBetterEquipment(kItem, dwPackage, dwBox)
	if kItem.nGenre ~= ITEM_GENRE.EQUIPMENT
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.BULLET
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.MINI_AVATAR
	or kItem.nSub == X.CONSTANT.EQUIPMENT_SUB.PET then
		return false
	end

	if not dwPackage or not dwBox then
		local nIndex, nCount = 0, 1
		while nIndex < nCount do
			dwPackage, dwBox, nIndex, nCount = X.GetItemEquipPos(kItem, nIndex + 1)
			if X.IsBetterEquipment(kItem, dwPackage, dwBox) then
				return true
			end
		end
		return false
	end

	local me = X.GetClientPlayer()
	local equipedItem = GetPlayerItem(me, dwPackage, dwBox)
	if not equipedItem then
		return false
	end
	if me.nLevel < me.nMaxLevel then
		return kItem.nEquipScore > equipedItem.nEquipScore
	end
	return (kItem.nEquipScore > equipedItem.nEquipScore) or (kItem.nLevel > equipedItem.nLevel and kItem.nQuality >= equipedItem.nQuality)
end

do local ITEM_CACHE = {}
function X.GetItemNameByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local szName = Table_GetItemName(nUiId)
		if szName == '' then
			szName = 'ITEM#' .. nUiId
		end
		ITEM_CACHE[nUiId] = szName
	end
	return ITEM_CACHE[nUiId]
end
end

function X.GetItemNameByItem(kItem)
	if kItem.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = X.RecipeToSegmentID(kItem.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(kItem.nUiId)
end

function X.GetItemNameByItemInfo(kItemInfo, nBookInfo)
	if kItemInfo.nGenre == ITEM_GENRE.BOOK and nBookInfo then
		local nBookID, nSegID = X.RecipeToSegmentID(nBookInfo)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	end
	return X.GetItemNameByUIID(kItemInfo.nUiId)
end

do local ITEM_CACHE = {}
function X.GetItemIconByUIID(nUiId)
	if not ITEM_CACHE[nUiId] then
		local nIcon = Table_GetItemIconID(nUiId)
		if nIcon == -1 then
			nIcon = 1435
		end
		ITEM_CACHE[nUiId] = nIcon
	end
	return ITEM_CACHE[nUiId]
end
end

function X.UpdateItemBoxExtend(hBox, nQuality)
	local szImage = 'ui/Image/Common/Box.UITex'
	local nFrame
	if nQuality == 2 then
		nFrame = 13
	elseif nQuality == 3 then
		nFrame = 12
	elseif nQuality == 4 then
		nFrame = 14
	elseif nQuality == 5 then
		nFrame = 17
	end
	hBox:ClearExtentImage()
	hBox:ClearExtentAnimate()
	if nFrame and nQuality < 5 then
		hBox:SetExtentImage(szImage, nFrame)
	elseif nQuality == 5 then
		hBox:SetExtentAnimate(szImage, nFrame, -1)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
