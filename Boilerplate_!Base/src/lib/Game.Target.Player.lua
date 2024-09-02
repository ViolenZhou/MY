--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Player')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

---��ȡ������ɫ
---@param dwForce number @Ҫ��ȡ������ID
---@param szType 'background'|'foreground' @��ȡ����ɫ����ǰ��ɫ
---@return number,number,number @��ɫRGB
function X.GetForceColor(dwForce, szType)
	if szType == 'background' then
		return X.Unpack(X.CONSTANT.FORCE_BACKGROUND_COLOR[dwForce])
	end
	return X.Unpack(X.CONSTANT.FORCE_FOREGROUND_COLOR[dwForce])
end

---��ȡ��Ӫ��ɫ
---@param nCamp number @Ҫ��ȡ����Ӫ
---@param szType 'background'|'foreground' @��ȡ����ɫ����ǰ��ɫ
---@return number,number,number @��ɫRGB
function X.GetCampColor(nCamp, szType)
	if szType == 'background' then
		return X.Unpack(X.CONSTANT.CAMP_BACKGROUND_COLOR[nCamp])
	end
	return X.Unpack(X.CONSTANT.CAMP_FOREGROUND_COLOR[nCamp])
end

--------------------------------------------------------------------------------
-- ��ɫ��Ϣ��ؽӿ�
--------------------------------------------------------------------------------

-- ��ȡ���������Ϣ�����棩
do
local CLIENT_PLAYER_INFO
local function GeneClientPlayerInfo(bForce)
	if not bForce and CLIENT_PLAYER_INFO and CLIENT_PLAYER_INFO.dwID then
		return
	end
	local me = X.GetClientPlayer()
	if me then -- ȷ����ȡ�����
		if not CLIENT_PLAYER_INFO then
			CLIENT_PLAYER_INFO = {}
		end
		if not IsRemotePlayer(me.dwID) then -- ȷ������ս��
			CLIENT_PLAYER_INFO.dwID   = me.dwID
			CLIENT_PLAYER_INFO.szName = me.szName
		end
		CLIENT_PLAYER_INFO.nX                = me.nX
		CLIENT_PLAYER_INFO.nY                = me.nY
		CLIENT_PLAYER_INFO.nZ                = me.nZ
		CLIENT_PLAYER_INFO.nFaceDirection    = me.nFaceDirection
		CLIENT_PLAYER_INFO.szTitle           = me.szTitle
		CLIENT_PLAYER_INFO.dwForceID         = me.dwForceID
		CLIENT_PLAYER_INFO.nLevel            = me.nLevel
		CLIENT_PLAYER_INFO.nExperience       = me.nExperience
		CLIENT_PLAYER_INFO.nCurrentStamina   = me.nCurrentStamina
		CLIENT_PLAYER_INFO.nCurrentThew      = me.nCurrentThew
		CLIENT_PLAYER_INFO.nMaxStamina       = me.nMaxStamina
		CLIENT_PLAYER_INFO.nMaxThew          = me.nMaxThew
		CLIENT_PLAYER_INFO.nBattleFieldSide  = me.nBattleFieldSide
		CLIENT_PLAYER_INFO.dwSchoolID        = me.dwSchoolID
		CLIENT_PLAYER_INFO.nCurrentTrainValue= me.nCurrentTrainValue
		CLIENT_PLAYER_INFO.nMaxTrainValue    = me.nMaxTrainValue
		CLIENT_PLAYER_INFO.nUsedTrainValue   = me.nUsedTrainValue
		CLIENT_PLAYER_INFO.nDirectionXY      = me.nDirectionXY
		CLIENT_PLAYER_INFO.nCurrentLife      = me.nCurrentLife
		CLIENT_PLAYER_INFO.nMaxLife          = me.nMaxLife
		CLIENT_PLAYER_INFO.fCurrentLife64,
		CLIENT_PLAYER_INFO.fMaxLife64        = X.GetTargetLife(me)
		CLIENT_PLAYER_INFO.nMaxLifeBase      = me.nMaxLifeBase
		CLIENT_PLAYER_INFO.nCurrentMana      = me.nCurrentMana
		CLIENT_PLAYER_INFO.nMaxMana          = me.nMaxMana
		CLIENT_PLAYER_INFO.nMaxManaBase      = me.nMaxManaBase
		CLIENT_PLAYER_INFO.nCurrentEnergy    = me.nCurrentEnergy
		CLIENT_PLAYER_INFO.nMaxEnergy        = me.nMaxEnergy
		CLIENT_PLAYER_INFO.nEnergyReplenish  = me.nEnergyReplenish
		CLIENT_PLAYER_INFO.bCanUseBigSword   = me.bCanUseBigSword
		CLIENT_PLAYER_INFO.nAccumulateValue  = me.nAccumulateValue
		CLIENT_PLAYER_INFO.nCamp             = me.nCamp
		CLIENT_PLAYER_INFO.bCampFlag         = me.bCampFlag
		CLIENT_PLAYER_INFO.bOnHorse          = me.bOnHorse
		CLIENT_PLAYER_INFO.nMoveState        = me.nMoveState
		CLIENT_PLAYER_INFO.dwTongID          = me.dwTongID
		CLIENT_PLAYER_INFO.nGender           = me.nGender
		CLIENT_PLAYER_INFO.nCurrentRage      = me.nCurrentRage
		CLIENT_PLAYER_INFO.nMaxRage          = me.nMaxRage
		CLIENT_PLAYER_INFO.nCurrentPrestige  = me.nCurrentPrestige
		CLIENT_PLAYER_INFO.bFightState       = me.bFightState
		CLIENT_PLAYER_INFO.nRunSpeed         = me.nRunSpeed
		CLIENT_PLAYER_INFO.nRunSpeedBase     = me.nRunSpeedBase
		CLIENT_PLAYER_INFO.dwTeamID          = me.dwTeamID
		CLIENT_PLAYER_INFO.nRoleType         = me.nRoleType
		CLIENT_PLAYER_INFO.nContribution     = me.nContribution
		CLIENT_PLAYER_INFO.nCoin             = me.nCoin
		CLIENT_PLAYER_INFO.nJustice          = me.nJustice
		CLIENT_PLAYER_INFO.nExamPrint        = me.nExamPrint
		CLIENT_PLAYER_INFO.nArenaAward       = me.nArenaAward
		CLIENT_PLAYER_INFO.nActivityAward    = me.nActivityAward
		CLIENT_PLAYER_INFO.bHideHat          = me.bHideHat
		CLIENT_PLAYER_INFO.bRedName          = me.bRedName
		CLIENT_PLAYER_INFO.dwKillCount       = me.dwKillCount
		CLIENT_PLAYER_INFO.nRankPoint        = me.nRankPoint
		CLIENT_PLAYER_INFO.nTitle            = me.nTitle
		CLIENT_PLAYER_INFO.nTitlePoint       = me.nTitlePoint
		CLIENT_PLAYER_INFO.dwPetID           = me.dwPetID
		CLIENT_PLAYER_INFO.dwMapID           = me.GetMapID()
		CLIENT_PLAYER_INFO.szMapName         = Table_GetMapName(me.GetMapID())
	end
end
X.RegisterEvent('LOADING_ENDING', function()
	GeneClientPlayerInfo(true)
end)
---��ȡ���������Ϣ�����棩
---@param bForce boolean @�Ƿ�ǿ��ˢ�»���
---@return unknown @��ҵ�������Ϣ����������Ϣ���ֶ�����
function X.GetClientPlayerInfo(bForce)
	GeneClientPlayerInfo(bForce)
	if not CLIENT_PLAYER_INFO then
		return X.CONSTANT.EMPTY_TABLE
	end
	return CLIENT_PLAYER_INFO
end
end

do
local PLAYER_NAME
---��ȡ��������ɫ��
---@return string @��ҵ������ɫ��
function X.GetClientPlayerName()
	if X.IsFunction(GetUserRoleName) then
		return GetUserRoleName()
	end
	local me = X.GetClientPlayer()
	if me and not IsRemotePlayer(me.dwID) then
		PLAYER_NAME = me.szName
	end
	return PLAYER_NAME
end
end

---��ȡ��������ɫ����
function X.GetClientPlayerCharInfo()
	local me = X.GetClientPlayer()
	local kungfu = X.GetClientPlayer().GetKungfuMount()
	local data = {
		dwID = me.dwID,
		szName = me.szName,
		dwForceID = me.dwForceID,
		nEquipScore = me.GetTotalEquipScore() or 0,
		dwMountKungfuID = kungfu and kungfu.dwSkillID or 0,
	}
	if CharInfoMore_GetShowValue then
		local aCategory, aContent, tTip = CharInfoMore_GetShowValue()
		local nCategoryIndex, nSubLen, nSubIndex = 0, -1, 0
		for _, content in ipairs(aContent) do
			if nSubIndex > nSubLen then
				nCategoryIndex = nCategoryIndex + 1
				local category = aCategory[nCategoryIndex]
				if category then
					table.insert(data, {
						category = true,
						label = category[1],
					})
					nSubLen, nSubIndex = category[2], 1
				end
			end
			table.insert(data, {
				label = content[1],
				value = content[2],
				tip = tTip[content[3]],
			})
			nSubIndex = nSubIndex + 1
		end
	else
		local frame = Station.Lookup('Normal/CharInfo')
		if not frame or not frame:IsVisible() then
			if frame then
				X.UI.CloseFrame('CharInfo') -- ǿ��kill
			end
			X.UI.OpenFrame('CharInfo'):Hide()
		end
		local hCharInfo = Station.Lookup('Normal/CharInfo')
		local handle = hCharInfo:Lookup('WndScroll_Property', '')
		for i = 0, handle:GetVisibleItemCount() -1 do
			local h = handle:Lookup(i)
			table.insert(data, {
				szTip = h.szTip,
				label = h:Lookup(0):GetText(),
				value = h:Lookup(1):GetText(),
			})
		end
	end
	return data
end

do
local REQUEST_TIME = {}
local PLAYER_GLOBAL_ID = {}
local function RequestTeammateGlobalID()
	local me = X.GetClientPlayer()
	local team = GetClientTeam()
	if not me or IsRemotePlayer(me.dwID) or not team or not me.IsInParty() then
		return
	end
	local nTime = GetTime()
	local aRequestGlobalID = {}
	for _, dwTarID in ipairs(team.GetTeamMemberList()) do
		local info = team.GetMemberInfo(dwTarID)
		if not PLAYER_GLOBAL_ID[dwTarID]
		and (info and info.bIsOnLine)
		and (not REQUEST_TIME[dwTarID] or nTime - REQUEST_TIME[dwTarID] > 2000) then
			table.insert(aRequestGlobalID, dwTarID)
			REQUEST_TIME[dwTarID] = nTime
		end
	end
	if not X.IsEmpty(aRequestGlobalID) then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, X.NSFormatString('{$NS}_GLOBAL_ID_REQUEST'), {aRequestGlobalID}, true)
	end
end
X.RegisterEvent('LOADING_END', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_UPDATE_BASE_INFO', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_LEVEL_UP_RAID', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_ADD_MEMBER', RequestTeammateGlobalID)
X.RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG', RequestTeammateGlobalID)
X.RegisterBgMsg(X.NSFormatString('{$NS}_GLOBAL_ID'), function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	PLAYER_GLOBAL_ID[dwTalkerID] = data
end)
-- ��ȡΨһ��ʶ��
function X.GetPlayerGlobalID(dwID)
	if dwID == X.GetClientPlayerID() then
		return X.GetClientPlayerGlobalID()
	end
	local szGlobalID = PLAYER_GLOBAL_ID[dwID]
	if not szGlobalID then
		local kTarget = X.GetPlayer(dwID)
		if kTarget then
			szGlobalID = kTarget.GetGlobalID()
		end
		if szGlobalID == '0' then
			szGlobalID = nil
		end
		PLAYER_GLOBAL_ID[dwID] = szGlobalID
	end
	return szGlobalID
end
end

-- ƴ�ӽ�ɫ�����
---@param szName string @��ɫԭʼ��
---@param szServerName string @��ɫ��������
---@return string @��ɫ�����
function X.AssemblePlayerGlobalName(szName, szServerName)
	return szName .. g_tStrings.STR_CONNECT .. szServerName
end

-- ��ֽ�ɫ�����ɫ������
---@param szGlobalName string @��ɫ������������ɲ��Ӻ�׺
---@param bFallbackServerName boolean @��ɫ��������������ʱ�Ƿ���Ϊ��ǰ����������ɫ
---@return string, string | nil @ȥ�������������׺�Ľ�ɫ��, ��ɫ���ڷ�������
function X.DisassemblePlayerGlobalName(szGlobalName, bFallbackServerName)
	local nPos, szServerName = X.StringFindW(szGlobalName, g_tStrings.STR_CONNECT), nil
	if nPos then
		szServerName = szGlobalName:sub(nPos + #g_tStrings.STR_CONNECT)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	if bFallbackServerName and not szServerName then
		szServerName = X.GetServerOriginName()
	end
	return szGlobalName, szServerName
end

-- ��ʽ��ԭʼ��ɫ��
---@param szName string @��ɫ��
---@return string @ȥ�������������׺�Ľ�ɫ��
function X.ExtractPlayerOriginName(szName)
	return (X.DisassemblePlayerGlobalName(szName))
end

-- ƴ�ӽ�ɫ������
---@param szName string @��ɫԭʼ��
---@param szSuffix? string @��ɫ��׺��
---@param szServerName? string @��ɫ��������
---@return string @��ɫ������
function X.AssemblePlayerName(szName, szSuffix, szServerName)
	if szSuffix then
		szName = szName .. szSuffix
	end
	if szServerName then
		szName = szName .. g_tStrings.STR_CONNECT .. szServerName
	end
	return szName
end

-- ��ֽ�ɫ������׺����ɫ������
---@param szGlobalName string @��ɫ������������ɲ��Ӻ�׺
---@param bFallbackServerName boolean @��ɫ��������������ʱ�Ƿ���Ϊ��ǰ����������ɫ
---@return string, string, string | nil @��ɫԭʼ��, ��ɫ��׺��, ��ɫ���ڷ�������
function X.DisassemblePlayerName(szGlobalName, bFallbackServerName)
	local nPos, szServerName = X.StringFindW(szGlobalName, g_tStrings.STR_CONNECT), nil
	if nPos then
		szServerName = szGlobalName:sub(nPos + #g_tStrings.STR_CONNECT)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	if bFallbackServerName and not szServerName then
		szServerName = X.GetServerOriginName()
	end
	local nPos, szSuffix = X.StringFindW(szGlobalName, '@'), ''
	if nPos then
		szSuffix = szGlobalName:sub(nPos)
		szGlobalName = szGlobalName:sub(1, nPos - 1)
	end
	return szGlobalName, szSuffix, szServerName
end

-- ��ʽ��������ɫ��
---@param szName string @��ɫ��
---@return string @ȥ�������������׺��ת����׺�Ľ�ɫ��
function X.ExtractPlayerBaseName(szName)
	return (X.DisassemblePlayerName(szName))
end

--------------------------------------------------------------------------------
-- ������ɫװ����Ϣ���
--------------------------------------------------------------------------------

-- �鿴��ɫװ�����λ
local PEEK_PLAYER_ACTION = {}
local function OnPeekOtherPlayerResult(xKey, eState)
	local dwID = X.IsNumber(xKey) and xKey or nil
	local kPlayer = dwID and X.GetPlayer(dwID)
	local szGlobalID = kPlayer and kPlayer.GetGlobalID()
	if not X.IsGlobalID(szGlobalID) then
		szGlobalID = X.IsGlobalID(xKey)
			and xKey
			or nil
	end
	if dwID then
		for _, fnAction in ipairs(PEEK_PLAYER_ACTION[dwID] or X.CONSTANT.EMPTY_TABLE) do
			X.SafeCall(fnAction, dwID, eState, kPlayer)
		end
		PEEK_PLAYER_ACTION[dwID] = nil
		X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, false)
	end
	if szGlobalID then
		for _, fnAction in ipairs(PEEK_PLAYER_ACTION[szGlobalID] or X.CONSTANT.EMPTY_TABLE) do
			X.SafeCall(fnAction, szGlobalID, eState, kPlayer)
		end
		PEEK_PLAYER_ACTION[szGlobalID] = nil
		X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, false)
	end
end
X.RegisterEvent('PEEK_OTHER_PLAYER', function()
	OnPeekOtherPlayerResult(arg1, arg0)
end)

-- ��ȡ������ɫ����
---@param dwID number @Ҫ��ȡ�Ľ�ɫID
---@param fnAction? fun(dwID: number, eState: number, kPlayer: userdata?): void @�ص�����
function X.PeekOtherPlayerByID(dwID, fnAction)
	if not PEEK_PLAYER_ACTION[dwID] then
		PEEK_PLAYER_ACTION[dwID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[dwID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, 1000, function()
		OnPeekOtherPlayerResult(dwID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(dwID, true)
end

-- ��ȡ������ɫ����
---@param szGlobalID string @Ҫ��ȡ�Ľ�ɫΨһID
---@param fnAction? fun(szGlobalID: string, eState: number, kPlayer: userdata?): void @�ص�����
function X.PeekOtherPlayerByGlobalID(dwServerID, szGlobalID, fnAction)
	if not PEEK_PLAYER_ACTION[szGlobalID] then
		PEEK_PLAYER_ACTION[szGlobalID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[szGlobalID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, 1000, function()
		OnPeekOtherPlayerResult(szGlobalID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(nil, true, dwServerID, szGlobalID)
end

-- �鿴������ɫװ��
---@param dwID number @Ҫ�鿴�Ľ�ɫID
---@param fnAction? fun(dwID: number, eState: number, kPlayer: userdata?): void @�ص�����
function X.ViewOtherPlayerByID(dwID, fnAction)
	if not PEEK_PLAYER_ACTION[dwID] then
		PEEK_PLAYER_ACTION[dwID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[dwID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. dwID, 1000, function()
		OnPeekOtherPlayerResult(dwID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(dwID, false)
end

-- �鿴������ɫװ��
---@param szGlobalID string @Ҫ�鿴�Ľ�ɫΨһID
---@param fnAction? fun(szGlobalID: string, eState: number, kPlayer: userdata?): void @�ص�����
function X.ViewOtherPlayerByGlobalID(dwServerID, szGlobalID, fnAction)
	if not PEEK_PLAYER_ACTION[szGlobalID] then
		PEEK_PLAYER_ACTION[szGlobalID] = {}
	end
	table.insert(PEEK_PLAYER_ACTION[szGlobalID], fnAction)
	X.DelayCall('LIB#PeekOtherPlayer#' .. szGlobalID, 1000, function()
		OnPeekOtherPlayerResult(szGlobalID, X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.FAILED)
	end)
	ViewInviteToPlayer(nil, false, dwServerID, szGlobalID)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
