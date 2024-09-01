--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Name')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local CACHE = {}

local function StandardizeOption(tOption)
	if not tOption then
		tOption = {}
	end
	if not tOption.eShowID then
		tOption.eShowID = 'auto'
	end
	return tOption
end

local function FormatShowName(szName, szID, eShowID)
	if szName == '' then
		szName = nil
	end
	if eShowID == 'never' then
		return szName
	end
	if not szName then
		return szID
	end
	if eShowID == 'auto' then
		return szName
	end
	if eShowID == 'always' then
		return szName .. '(' .. szID .. ')'
	end
end

local function CacheSet(szCacheID, xKey, szName)
	if not CACHE[szCacheID] then
		CACHE[szCacheID] = X.CreateCache('LIB#NameCache#' .. szCacheID, 'v')
	end
	CACHE[szCacheID][xKey] = {szName}
end

local function CacheGet(szCacheID, xKey)
	return CACHE[szCacheID]
		and CACHE[szCacheID][xKey]
		and CACHE[szCacheID][xKey][1]
		or nil
end

-- ��ȡָ���������
---@param dwID number @Ҫ��ȡ����ҽ�ɫID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetPlayerName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'PLAYER.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kPlayer = X.GetPlayer(dwID)
		if kPlayer then
			szName = kPlayer and kPlayer.szName
			bCache = szName ~= ''
		end
		szName = FormatShowName(szName, 'P' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ��ȡָ��ϵͳ��ɫ����
---@param dwID number @Ҫ��ȡ��ϵͳ��ɫID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetNpcName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'NPC.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey, szCacheID)
	if not szName then
		local bCache = false
		local kNpc = X.GetNpc(dwID)
		if kNpc then
			szName = kNpc.szName
			if X.IsEmpty(szName) then
				szName = X.GetNpcTemplateName(kNpc.dwTemplateID)
			end
			if kNpc.dwEmployer and kNpc.dwEmployer ~= 0 then
				if X.Table.IsSimplePlayer(kNpc.dwTemplateID) then -- ����Ӱ��
					szName = X.GetPlayerName(kNpc.dwEmployer, tOption)
				elseif not X.IsEmpty(szName) then
					local szEmpName
					if X.IsPlayer(kNpc.dwEmployer) then
						szEmpName = X.GetPlayerName(kNpc.dwEmployer, { eShowID = 'never' })
					else
						szEmpName = X.GetNpcName(kNpc.dwEmployer, { eShowID = 'never' })
					end
					if szEmpName then
						bCache = true
					else
						szEmpName = g_tStrings.STR_SOME_BODY
					end
					local szBaseName, szSuffixName, szServerName = X.DisassemblePlayerName(szEmpName)
					szName = X.AssemblePlayerName(szBaseName .. g_tStrings.STR_PET_SKILL_LOG .. szName, szSuffixName, szServerName)
				end
			else
				bCache = true
			end
		end
		local szID = 'N' .. X.ConvertNpcID(dwID)
		if kNpc then
			szID = szID .. '@' .. kNpc.dwTemplateID
		end
		szName = FormatShowName(szName, szID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ����ģ��ID��ȡϵͳ��ɫ����
---@param dwTemplateID number @Ҫ��ȡ��ϵͳ��ɫģ��ID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetNpcTemplateName(dwTemplateID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'NPC_TEMPLATE.' .. tOption.eShowID
	local xKey = dwTemplateID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		szName = X.CONSTANT.NPC_NAME[dwTemplateID]
			and X.RenderTemplateString(X.CONSTANT.NPC_NAME[dwTemplateID])
			or Table_GetNpcTemplateName(dwTemplateID)
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		bCache = true
		szName = FormatShowName(szName, 'NT' .. dwTemplateID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ����ģ��ID��ȡ�����������
---@param dwTemplateID number @Ҫ��ȡ�Ľ������ģ��ID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetDoodadTemplateName(dwTemplateID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'DOODAD_TEMPLATE.' .. tOption.eShowID
	local xKey = dwTemplateID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		szName = X.CONSTANT.DOODAD_NAME[dwTemplateID]
			and X.RenderTemplateString(X.CONSTANT.DOODAD_NAME[dwTemplateID])
			or Table_GetDoodadTemplateName(dwTemplateID)
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		bCache = true
		szName = FormatShowName(szName, 'DT' .. dwTemplateID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ��ȡָ�������������
---@param dwID number @Ҫ��ȡ�Ľ������ID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetDoodadName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'DOODAD.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kDoodad = X.GetDoodad(dwID)
		if kDoodad then
			szName = X.Table.GetDoodadTemplateName(kDoodad.dwTemplateID)
			if szName then
				szName = szName:gsub('^%s*(.-)%s*$', '%1')
			end
			bCache = true
		end
		szName = FormatShowName(szName, 'D' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ��ȡָ����Ʒ����
---@param dwID number @Ҫ��ȡ����ƷID
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetItemName(dwID, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'ITEM.' .. tOption.eShowID
	local xKey = dwID
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kItem = X.GetItem(dwID)
		if kItem then
			szName = X.GetItemNameByItem(kItem)
			bCache = true
		end
		szName = FormatShowName(szName, 'I' .. dwID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

-- ��ȡָ����Ʒ��Ϣ����
---@param dwTabType number @Ҫ��ȡ����Ʒ��Ϣ������
---@param dwTabIndex number @Ҫ��ȡ����Ʒ��Ϣ���±�
---@param nBookInfo? number @Ҫ��ȡ����Ʒ��Ϣ�鼮��Ϣ
---@param tOption? table @��ȡ����
---@return string | nil @��ȡ�ɹ��������ƣ�ʧ�ܷ��ؿ�
function X.GetItemInfoName(dwTabType, dwTabIndex, nBookInfo, tOption)
	local tOption = StandardizeOption(tOption)
	local szCacheID = 'ITEM_INFO.' .. tOption.eShowID
	local xKey = dwTabType .. ':' .. dwTabIndex .. ':' .. (nBookInfo or 0)
	local szName = CacheGet(szCacheID, xKey)
	if not szName then
		local bCache = false
		local kItemInfo = X.GetItemInfo(dwTabType, dwTabIndex)
		if kItemInfo then
			szName = X.GetItemNameByItemInfo(kItemInfo)
			bCache = true
		end
		local szID = dwTabType .. ':' .. dwTabIndex
		if nBookInfo then
			szID = szID .. ':' .. nBookInfo
		end
		szName = FormatShowName(szName, 'II' .. szID, tOption.eShowID)
		if bCache then
			CacheSet(szCacheID, xKey, szName)
		end
	end
	return szName
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
