--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Fellowship')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ������ؽӿ�
--------------------------------------------------------------------------------

---��ȡ���ѷ���
---@return table @���ѷ����б�
function X.GetFellowshipGroupInfoList()
	local aList
	local smc = X.GetSocialManagerClient()
	if smc then
		aList = smc.GetFellowshipGroupInfo()
	else
		local me = X.GetClientPlayer()
		if me then
			aList = me.GetFellowshipGroupInfo()
		end
	end
	if not aList then
		return
	end
	-- Ĭ�Ϸ���
	local aRes = {{ nID = 0, szName = g_tStrings.STR_FRIEND_GOOF_FRIEND or '' }}
	for _, tGroup in ipairs(aList) do
		table.insert(aRes, {
			nID = tGroup.id,
			szName = tGroup.name,
		})
	end
	return aRes
end

---��ȡָ�����ѷ���ĺ����б�
---@param nGroupID number @Ҫ��ȡ�ĺ��ѷ���ID
---@return table @�÷����µ������Ϣ�б�
function X.GetFellowshipInfoList(nGroupID)
	local aList
	local smc = X.GetSocialManagerClient()
	if smc then
		aList = smc.GetFellowshipInfo(nGroupID)
	else
		local me = X.GetClientPlayer()
		if me then
			aList = me.GetFellowshipInfo(nGroupID)
		end
	end
	if not aList then
		return
	end
	local aRes = {}
	for _, info in ipairs(aList) do
		table.insert(aRes, {
			xID = info.id, -- ���ư�Ϊ szGlobalID��Ե��Ϊ dwID
			szName = info.name, -- ���ư�Ϊ nil
			nAttraction = info.attraction,
			bTwoWay = info.istwoway == 1 or info.istwoway == true,
			szRemark = info.remark,
			nGroupID = info.groupid,
			bOnline = info.isonline, -- ���ư�Ϊ nil
		})
	end
	return aRes
end

do
local FELLOWSHIP_CACHE
local function OnFellowshipUpdate()
	FELLOWSHIP_CACHE = nil
end
X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE'     , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FELLOWSHIP_CHANGE'     , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN'      , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_FOE_UPDATE'            , OnFellowshipUpdate)
X.RegisterEvent('PLAYER_BLACK_LIST_UPDATE'     , OnFellowshipUpdate)
X.RegisterEvent('DELETE_FELLOWSHIP'            , OnFellowshipUpdate)
X.RegisterEvent('FELLOWSHIP_TWOWAY_FLAG_CHANGE', OnFellowshipUpdate)

-- ��ȡ����
---@param xPlayerID number | string @Ҫ��ȡ��������ƻ�ID
---@return table @ƥ��������Ϣ
function X.GetFellowshipInfo(xPlayerID)
	if not FELLOWSHIP_CACHE then
		local me = X.GetClientPlayer()
		if me then
			local aGroupInfo = X.GetFellowshipGroupInfoList()
			if aGroupInfo then
				FELLOWSHIP_CACHE = {}
				for _, tGroup in ipairs(aGroupInfo) do
					for _, tFellowship in ipairs(X.GetFellowshipInfoList(tGroup.nID) or {}) do
						FELLOWSHIP_CACHE[tFellowship.xID] = tFellowship
						if tFellowship.szName then
							FELLOWSHIP_CACHE[tFellowship.szName] = tFellowship
						else
							local tPei = X.GetPlayerEntryInfo(tFellowship.xID)
							if tPei then
								FELLOWSHIP_CACHE[tPei.dwID] = tFellowship
								FELLOWSHIP_CACHE[tPei.szName] = tFellowship
							end
						end
					end
				end
			end
		end
	end
	return FELLOWSHIP_CACHE and X.Clone(FELLOWSHIP_CACHE[xPlayerID])
end

-- �ж��Ƿ��Ǻ���
---@param xPlayerID number | string @Ҫ�жϵ�������ƻ�ID
---@return boolean @�Ƿ��Ǻ���
function X.IsFellowship(xPlayerID)
	return X.GetFellowshipInfo(xPlayerID) and true or false
end

-- ��������
---@param fnIter function @������������0ʱֹͣ����
function X.IterFellowshipInfo(fnIter)
	local aGroup = X.GetFellowshipGroupInfoList() or {}
	for _, tGroup in ipairs(aGroup) do
		local aFellowshipInfo = X.GetFellowshipInfoList(tGroup.nID) or {}
		for _, tFellowship in ipairs(aFellowshipInfo) do
			if fnIter(tFellowship, tGroup) == 0 then
				return
			end
		end
	end
end
end

---���������Ƭ
---@param xPlayerID string | string[] @Ҫ��������ΨһID����ΨһID�б�Ե��Ϊ dwID��
function X.ApplyFellowshipCard(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.ApplyFellowshipCard(xPlayerID)
	end
	local fcc = X.GetFellowshipCardClient()
	if fcc then
		return fcc.ApplyFellowshipCard(255, xPlayerID)
	end
end

---��ȡ�����Ƭ��Ϣ
---@param xPlayerID number @Ҫ��ȡ�����ΨһID��Ե��Ϊ dwID��
---@return table @��ҵ���Ƭ��Ϣ
function X.GetFellowshipCardInfo(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		local tCard = smc.GetFellowshipCardInfo(xPlayerID)
		if tCard then
			tCard = {
				bTwoWay = tCard.bIsTwoWayFriend == 1,
				-- dwLandMapID = v.dwLandMapID,
				-- nLandIndex = v.nLandIndex,
				-- Praiseinfo = v.Praiseinfo,
				-- nPHomeCopyIndex = v.nPHomeCopyIndex,
				-- nLandCopyIndex = v.nLandCopyIndex,
				-- dwPHomeSkin = v.dwPHomeSkin,
				-- dwPHomeMapID = v.dwPHomeMapID,
			}
		end
		return tCard
	end
	local tFellowship = X.GetFellowshipInfo(xPlayerID)
	local fcc = X.GetFellowshipCardClient()
	local tCard = tFellowship and fcc and fcc.GetFellowshipCardInfo(tFellowship.id)
	if tCard then
		return {
			bTwoWay = tFellowship.istwoway,
			-- dwLandMapID = tCard.dwLandMapID,
			-- nLandIndex = tCard.nLandIndex,
			-- Praiseinfo = tCard.Praiseinfo,
			-- nPHomeCopyIndex = tCard.nPHomeCopyIndex,
			-- nLandCopyIndex = tCard.nLandCopyIndex,
			-- dwPHomeSkin = tCard.dwPHomeSkin,
			-- dwPHomeMapID = tCard.dwPHomeMapID,
		}
	end
end

---��ȡ������ڵ�ͼ
---@param xPlayerID number @Ҫ��ȡ�����ΨһID��Ե��Ϊ dwID��
---@return boolean @������ڵ�ͼ
function X.GetFellowshipMapID(xPlayerID)
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.GetFellowshipMapID(xPlayerID)
	end
	local tFellowship = X.GetFellowshipInfo(xPlayerID)
	local fcc = X.GetFellowshipCardClient()
	local tCard = tFellowship and fcc and fcc.GetFellowshipCardInfo(tFellowship.id)
	if tCard then
		return tCard.dwMapID
	end
end

--------------------------------------------------------------------------------
-- ������ؽӿ�
--------------------------------------------------------------------------------
do
local FOE_LIST, FOE_CACHE
local function GetFoeInfo()
	local smc = X.GetSocialManagerClient()
	if smc then
		return smc.GetFoeInfo()
	end
	local me = X.GetClientPlayer()
	if me and me.GetFoeInfo then
		return me.GetFoeInfo()
	end
end
local function GeneFoeCache()
	if not FOE_LIST then
		local aInfo = GetFoeInfo()
		if aInfo then
			FOE_LIST = {}
			FOE_CACHE = {}
			for i, p in ipairs(aInfo) do
				FOE_CACHE[p.id] = p
				if p.name then
					FOE_CACHE[p.name] = p
				else
					local tPei = X.GetPlayerEntryInfo(p.id)
					if tPei then
						FOE_CACHE[tPei.dwID] = p
						FOE_CACHE[tPei.szName] = p
					end
				end
				table.insert(FOE_LIST, p)
			end
			return true
		end
		return false
	end
	return true
end
local function OnFoeUpdate()
	FOE_LIST = nil
	FOE_CACHE = nil
end
X.RegisterEvent('PLAYER_FOE_UPDATE', OnFoeUpdate)

-- ��ȡ�����б�
---@return table @�����б�
function X.GetFoeInfoList()
	if GeneFoeCache() then
		return X.Clone(FOE_LIST)
	end
end

-- ��ȡ����
---@param xPlayerID number | string @�������ƻ����ID
---@return userdata @���˶���
function X.GetFoeInfo(xPlayerID)
	if xPlayerID and GeneFoeCache() then
		return FOE_CACHE[xPlayerID]
	end
end
end

-- �ж��Ƿ��ǳ���
---@param xPlayerID number | string @Ҫ�жϵ�������ƻ�ID
---@return boolean @�Ƿ��ǳ���
function X.IsFoe(xPlayerID)
	return X.GetFoeInfo(xPlayerID) and true or false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
