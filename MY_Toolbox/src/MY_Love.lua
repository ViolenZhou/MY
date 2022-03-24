--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������Ե
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------

local LOVER_DATA = {
	dwID = 0, -- ��Ե ID
	szName = '', -- ��Ե����
	szTitle = '', -- �ҵĽ�Ե�ƺ�
	nSendItem = '', -- ��Եʱ�ͶԷ��Ķ���
	nReceiveItem = '', -- ��Եʱ�Է��͵Ķ���
	dwAvatar = 0, -- ��Եͷ��
	dwForceID = 0, -- ����
	nRoleType = 0, -- ��Ե���ͣ�0������Ե��
	nLoverType = 0, -- ��Ե���ͣ�����0��˫��1��
	nLoverTime = 0, -- ��Ե��ʼʱ�䣨��λ���룩
	szLoverTitle = '', -- �Է���Ե�ƺ�
	dwMapID = 0, -- ���ڵ�ͼ
	bOnline = false, -- �Ƿ�����
}

local O = X.CreateUserSettingsModule('MY_Love', _L['Target'], {
	bQuiet = { -- ����ţ��ܾ������˵Ĳ鿴����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szNone = { -- û��Եʱ��ʾ����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = _L['Singleton'],
	},
	szJabber = { -- ��ڨ����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = _L['Hi, I seem to meet you somewhere ago'],
	},
	szSign = { -- ��Ե���ԣ�����ǩ����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	bAutoFocus = { -- �Զ�����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bHookPlayerView = { -- �ڲ鿴װ����������ʾ��Ե
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoReplyLover = { -- ����ȷ�ϼ��ɲ鿴�ҵ���Ե
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Love'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {
	-- ��������
	nLoveAttraction = 200,
	nDoubleLoveAttraction = 800,
	-- ���ر���
	aAutoSay = { -- ���ر�����������ף�˫����ȡ������֪ͨ��
		_L['Some people fancy you.'],
		_L['Other side terminate love you.'],
		_L['Some people fall in love with you.'],
		_L['Other side gave up love you.'],
	},
	lover = X.Clone(LOVER_DATA),
	tOtherLover = {}, -- �鿴����Ե����
	tViewer = {}, -- �Ⱥ�鿴��������б�
	aLoverItem = { -- �����ڽ�Ե���̻���Ϣ
		{ nItem = 1, szTitle = _L['FIREWORK_TITLE_67291'], aUIID = {67291, 151179, 160465, 163486} }, -- ���֮��
		{ nItem = 2, szTitle = _L['FIREWORK_TITLE_151303'], aUIID = {151303, 160961, 161078} }, -- �޼䳤�� ������
		{ nItem = 3, szTitle = _L['FIREWORK_TITLE_151743'], aUIID = {151743, 160964, 161079} }, -- ǧ�Բ���
		{ nItem = 4, szTitle = _L['FIREWORK_TITLE_152844'], aUIID = {152844, 160962} }, -- �Ĳ�����
		{ nItem = 5, szTitle = _L['FIREWORK_TITLE_154319'], aUIID = {154319, 160965} }, -- �踣���� ϧ����
		{ nItem = 6, szTitle = _L['FIREWORK_TITLE_154320'], aUIID = {154320, 160968} }, -- ������ һ����
		{ nItem = 7, szTitle = _L['FIREWORK_TITLE_153641'], aUIID = {153641, 156447, 160963} }, -- ��������
		{ nItem = 8, szTitle = _L['FIREWORK_TITLE_153642'], aUIID = {153642, 160966} }, -- ��ҵƻ�
		{ nItem = 9, szTitle = _L['FIREWORK_TITLE_156413'], aUIID = {156413, 160970} }, -- ���ɷ괺 �и���
		{ nItem = 10, szTitle = _L['FIREWORK_TITLE_156446'], aUIID = {154313, 156446, 160967} }, -- �ɶ���� ͬ����
		{ nItem = 11, szTitle = _L['FIREWORK_TITLE_157096'], aUIID = {157096, 160969} }, -- ���Ĳ��� ������
		{ nItem = 12, szTitle = _L['FIREWORK_TITLE_157378'], aUIID = {157378, 160971} }, -- �������� ֪����
		{ nItem = 13, szTitle = _L['FIREWORK_TITLE_158339'], aUIID = {158339, 160972} }, -- ������� ������
		{ nItem = 14, szTitle = _L['FIREWORK_TITLE_159250'], aUIID = {159250, 160974} }, -- �������� ������
		{ nItem = 15, szTitle = _L['FIREWORK_TITLE_160982'], aUIID = {68338, 160982} }, -- ����ɽ��
		{ nItem = 16, szTitle = _L['FIREWORK_TITLE_160993'], aUIID = {160993, 163339} }, -- ȵ������ ��˼��
		{ nItem = 17, szTitle = _L['FIREWORK_TITLE_161367'], aUIID = {161367, 163340} }, -- �������� ������
		{ nItem = 18, szTitle = _L['FIREWORK_TITLE_161887'], aUIID = {161887, 163341} }, -- ���μ��� ������
		{ nItem = 19, szTitle = _L['FIREWORK_TITLE_162307'], aUIID = {162307, 163435} }, -- ������˼ ��Ը��
		{ nItem = 20, szTitle = _L['FIREWORK_TITLE_162308'], aUIID = {162308, 163427} }, -- ����
		{ nItem = 21, szTitle = _L['FIREWORK_TITLE_158577'], aUIID = {158577, 160973} }, -- ������� ������
		-- { nItem = 63, szTitle = X.GetItemNameByUIID(65625), aUIID = {65625} }, -- ������ ����
	},
	tLoverItem = {},
	nPendingItem = 0, -- �����Ե�̻�nItem��Ż���
	aStorageData = nil, -- ��ֹ���ָ��������ô۸�
}
for _, p in ipairs(D.aLoverItem) do
	assert(not D.tLoverItem[p.nItem], 'MY_Love item index conflict: ' .. p.nItem)
	D.tLoverItem[p.nItem] = p
end

X.RegisterRemoteStorage(
	'MY_Love', 32, 88,
	function(aBit)
		local dwID, nTime, nType, nSendItem, nReceiveItem, nCrc = 0, 0, 0, 0, 0, 6
		local aByte = {}
		for i = 1, #aBit, 8 do
			local nByte = 0
			for j = 1, 8 do
				nByte = nByte * 2 + aBit[(i - 1) + j]
			end
			table.insert(aByte, nByte)
		end
		-- 1 crc
		for i = 1, #aByte do
			nCrc = X.NumberBitXor(nCrc, aByte[i])
		end
		if nCrc == 0 then
			-- 2 - 5 dwID
			for i = 5, 2, -1 do
				dwID = X.NumberBitShl(dwID, 8)
				dwID = X.NumberBitOr(dwID, aByte[i])
			end
			-- 6 - 9 nTime
			for i = 9, 6, -1 do
				nTime = X.NumberBitShl(nTime, 8)
				nTime = X.NumberBitOr(nTime, aByte[i])
			end
			-- 10 (nType << 4) | ((nSendItem >> 2) & 0xf)
			nType = X.NumberBitShr(aByte[10], 4)
			nSendItem = X.NumberBitShl(X.NumberBitAnd(aByte[10], 0xf), 2)
			-- 11 (nSendItem & 0x3) << 6 | (nReceiveItem & 0x3f)
			nSendItem = X.NumberBitOr(nSendItem, X.NumberBitShr(aByte[11], 6))
			nReceiveItem = X.NumberBitAnd(aByte[11], 0x3f)
			return dwID, nTime, nType, nSendItem, nReceiveItem
		end
		return 0, 0, 0, 0, 0
	end,
	function(...)
		local dwID, nTime, nType, nSendItem, nReceiveItem = ...
		assert(dwID >= 0 and dwID <= 0xffffffff, 'Value of dwID out of 32bit unsigned int range!')
		assert(nTime >= 0 and nTime <= 0xffffffff, 'Value of nTime out of 32bit unsigned int range!')
		assert(nType >= 0 and nType <= 0xf, 'Value of nType out of range 4bit unsigned int range!')
		assert(nSendItem >= 0 and nSendItem <= 0x3f, 'Value of nSendItem out of 6bit unsigned int range!')
		assert(nReceiveItem >= 0 and nReceiveItem <= 0x3f, 'Value of nReceiveItem out of 6bit unsigned int range!')
		local aByte, nCrc = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 6
		-- 2 - 5 dwID
		for i = 2, 5 do
			aByte[i] = X.NumberBitAnd(dwID, 0xff)
			dwID = X.NumberBitShr(dwID, 8)
		end
		-- 6 - 9 nTime
		for i = 6, 9 do
			aByte[i] = X.NumberBitAnd(nTime, 0xff)
			nTime = X.NumberBitShr(nTime, 8)
		end
		-- 10 (nType << 4) | ((nSendItem >> 2) & 0xf)
		aByte[10] = X.NumberBitOr(X.NumberBitShl(nType, 4), X.NumberBitAnd(X.NumberBitShr(nSendItem, 2), 0xf))
		-- 11 (nSendItem & 0x3) << 6 | (nReceiveItem & 0x3f)
		aByte[11] = X.NumberBitOr(X.NumberBitShl(X.NumberBitAnd(nSendItem, 0x3), 6), X.NumberBitAnd(nReceiveItem, 0x3f))
		-- 1 crc
		for i = 2, #aByte do
			nCrc = X.NumberBitXor(nCrc, aByte[i])
		end
		aByte[1] = nCrc

		local aBit = {}
		for _, nByte in ipairs(aByte) do
			local aByteBit = { 0, 0, 0, 0, 0, 0, 0, 0 }
			for i = 8, 1, -1 do
				aByteBit[i] = math.mod(nByte, 2)
				nByte = math.floor(nByte / 2)
			end
			for _, v in ipairs(aByteBit) do
				table.insert(aBit, v)
			end
		end
		return aBit
	end)

--[[
������Ե
========
1. ÿ����ɫֻ������һ����Ե����Ե�����Ǻ���
2. ��Ҫ̹��������Ե��Ϣ�޷����أ����ѿ�ֱ�Ӳ鿴�������������ȷ�ϣ�
3. ����˫����Ե��Ҫ�����غ�����Ӳ���5���ڣ�������Ҫ�����֮�ģ���ѡ��ΪĿ�꣬�ٵ���ȷ��
4. ������Ե������ѡ��һ�� 3�غø����ϵ����ߺ��ѣ��Է����յ�����֪ͨ
5. ��Ե������ʱ����������������֪ͨ�Է���������Ե����������֪ͨ��
6. ��ɾ����Ե�������Զ������Ե��ϵ


�Ķ���Ե��
	XXXXXXXXX (198����� ...) [ն��˿]
	���ͣ�����/˫��  ʱ����X��XСʱX����X��

	�����ض��ѽ�����[___________] ������4���ڣ���һ�����֮�ģ�
	����ĳ�����غ��ѣ�[___________] ��Ҫ�����ߣ�����֪ͨ�Է���
	û��Եʱ��ʾʲô��[___________]  [**] ���������ģʽ

	��Ե���ԣ� [________________________________________________________]
	��ڨ��� [________________________________________________________]

С��ʾ��
	1. ����װ���������Ҳ����໥��������
	2. ��Ե���Ե�����ɾ����˫����Ե��ͨ�����ĸ�֪�Է�
	3. �Ƕ��Ѳ鿴��ԵʱĿ�ᵯ��ȷ�Ͽ򣨿ɿ�����������Σ�
--]]

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------

local Schema = X.Schema
local BACKUP_DATA_SCHEMA = X.Schema.Record({
	szName = X.Schema.String,
	szUUID = X.Schema.String,
	szLoverName = X.Schema.String,
	szLoverUUID = X.Schema.String,
	nLoverType = X.Schema.Number,
	nLoverTime = X.Schema.Number,
	nSendItem = X.Schema.Number,
	nReceiveItem = X.Schema.Number,
})

-- ��������
function D.IsShielded()
	return ENVIRONMENT.GAME_BRANCH == 'classic'
end

-- ��ȡ����ָ��ID��Ʒ�б�
function D.GetBagItemPos(aUIID)
	local me = GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() do
		for dwX = 0, me.GetBoxSize(dwBox) - 1 do
			local it = me.GetItem(dwBox, dwX)
			if it then
				for _, nUIID in ipairs(aUIID) do
					if it.nUiId == nUIID then
						return dwBox, dwX
					end
				end
			end
		end
	end
end

-- ���ݱ��������ȡ��Ʒ������
function D.GetBagItemNum(dwBox, dwX)
	local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
	if not item then
		return 0
	elseif not item.bCanStack then
		return 1
	else
		return item.nStackNum
	end
end

-- �Ƿ�ɽ�˫����ѣ����������֮�ĵ�λ��
function D.GetDoubleLoveItem(aInfo, aUIID)
	if aInfo then
		local tar = GetPlayer(aInfo.id)
		if aInfo.attraction >= D.nDoubleLoveAttraction and tar and X.IsParty(tar.dwID) and X.GetDistance(tar) <= 4 then
			return D.GetBagItemPos(aUIID)
		end
	end
end

function D.UseDoubleLoveItem(aInfo, aUIID, callback)
	local dwBox, dwX = D.GetDoubleLoveItem(aInfo, aUIID)
	if dwBox then
		local nNum = D.GetBagItemNum(dwBox, dwX)
		SetTarget(TARGET.PLAYER, aInfo.id)
		OnUseItem(dwBox, dwX)
		local nFinishTime = GetTime() + 500
		X.BreatheCall(function()
			local me = GetClientPlayer()
			if not me then
				return 0
			end
			local nType = X.GetOTActionState(me)
			if nType == CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_ITEM_SKILL
			or nType == CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE then -- otActionItemSkill
				nFinishTime = GetTime() + 500
			elseif GetTime() > nFinishTime then
				callback(D.GetBagItemNum(dwBox, dwX) ~= nNum)
				return 0
			end
		end)
	end
end

function D.CreateFireworkSelect(callback)
	local nCol = 3 -- ��ť����
	local nMargin = 30 -- ���ұ߾�
	local nLineHeight = 40 -- �и�
	local nItemWidth = 100 -- ��ť���
	local nItemHeight = 30 -- ��ť�߶�
	local nItemPadding = 10 -- ��ť���
	local ui = UI.CreateFrame('MY_Love_SetLover', {
		w = nItemWidth * nCol + nMargin * 2 + nItemPadding * (nCol - 1),
		h = 50 + math.ceil(#D.aLoverItem / nCol) * nLineHeight + 30,
		text = _L['Select a firework'],
	})
	local nX, nY = nMargin, 50
	for i, p in ipairs(D.aLoverItem) do
		ui:Append('WndButton', {
			x = nX, y = nY + (nLineHeight - nItemHeight) / 2, w = nItemWidth, h = nItemHeight,
			text = X.GetItemNameByUIID(p.aUIID[1]),
			enable = not not D.GetBagItemPos(p.aUIID),
			onclick = function() callback(p) end,
			tip = p.szTitle,
			tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		})
		if i % nCol == 0 then
			nX = nMargin
			nY = nY + nLineHeight
		else
			nX = nX + nItemWidth + nItemPadding
		end
	end
end

-- ����У���ȷ�����ݲ����۸ģ�0-255��
function D.EncodeString(szData)
	local nCrc = 0
	for i = 1, string.len(szData) do
		nCrc = (nCrc + string.byte(szData, i)) % 255
	end
	return string.format('%02x', nCrc) .. szData
end

-- �޳�У�����ȡԭʼ����
function D.DecodeHMString(szData)
	if not X.IsEmpty(szData) and X.IsString(szData) and string.len(szData) > 2 then
		local nCrc = 0
		for i = 3, string.len(szData) do
			nCrc = (nCrc + string.byte(szData, i)) % 255
		end
		if nCrc == tonumber(string.sub(szData, 1, 2), 16) then
			return string.sub(szData, 3)
		end
	end
end

-- ��ȡ��Ե��Ϣ���ɹ��������� + rawInfo��ʧ�� nil��
function D.GetLover()
	if MY_Love.IsShielded() then
		return
	end
	local szKey, me = '#HM#LOVER#', GetClientPlayer()
	if not me or not X.CanUseOnlineRemoteStorage() then
		return
	end
	local dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem = X.GetRemoteStorage('MY_Love')
	local aGroup = me.GetFellowshipGroupInfo() or {}
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for i = #aFriend, 1, -1 do
			local info = aFriend[i]
			if nLoverTime == 0 then -- ʱ��Ϊ��0��ʾ���ǵ�һ���� �ܾ����غ�������
				local bMatch = string.sub(info.remark, 1, string.len(szKey)) == szKey
				-- fetch data
				-- ���ݺ�������Ե��Ϣ�Ӻ��ѱ�ע����ȡ����
				if bMatch then
					local szData = D.DecodeHMString(string.sub(info.remark, string.len(szKey) + 1))
					if not X.IsEmpty(szData) then
						local data = X.SplitString(szData, '#')
						local nType = data[1] and tonumber(data[1])
						local nTime = data[2] and tonumber(data[2])
						if nType and nTime and (nType == 0 or nType == 1) and (nTime > 0 and nTime < GetCurrentTime()) then
							dwLoverID = info.id
							nLoverType = nType
							nLoverTime = nTime
							nSendItem = 0
							nReceiveItem = 0
							X.SetRemoteStorage('MY_Love', dwLoverID, nLoverTime, nLoverType, nSendItem, nReceiveItem)
							D.UpdateProtectData()
						end
					end
					me.SetFellowshipRemark(info.id, '')
				end
			end
			-- ��������Ե����ȡ������Ϣ������
			if info.id == dwLoverID and info.istwoway then
				local fellowClient = GetFellowshipCardClient()
				if fellowClient then
					local card = fellowClient.GetFellowshipCardInfo(info.id)
					if not card or (card.dwMapID == 0 and info.isonline) then
						fellowClient.ApplyFellowshipCard(255, {info.id})
					else
						return {
							dwID = dwLoverID,
							szName = info.name,
							szTitle = D.tLoverItem[D.lover.nSendItem] and D.tLoverItem[D.lover.nSendItem].szTitle or '',
							nSendItem = nSendItem,
							nReceiveItem = nReceiveItem,
							nLoverType = nLoverType,
							nLoverTime = nLoverTime,
							szLoverTitle = D.tLoverItem[D.lover.nReceiveItem] and D.tLoverItem[D.lover.nReceiveItem].szTitle or '',
							dwAvatar = card.dwMiniAvatarID,
							dwForceID = card.dwForceID,
							nRoleType = card.nRoleType,
							dwMapID = card.dwMapID,
							bOnline = info.isonline,
						}
					end
				end
			end
		end
	end
end

-- ת��������ϢΪ��Ե��Ϣ
function D.UpdateLocalLover()
	if MY_Love.IsShielded() then
		return
	end
	local lover = D.GetLover()
	if not lover then
		lover = LOVER_DATA
	end
	local bDiff = false
	for k, _ in pairs(LOVER_DATA) do
		if D.lover[k] ~= lover[k] then
			D.lover[k] = lover[k]
			bDiff = true
		end
	end
	if bDiff then
		FireUIEvent('MY_LOVE_UPDATE')
	end
end

function D.FormatTimeCounter(nSec)
	if nSec <= 60 then
		return nSec .. _L['sec']
	elseif nSec < 3600 then -- X����X��
		return _L('%d min %d sec', nSec / 60, nSec % 60)
	elseif nSec < 86400 then -- XСʱX����
		return _L('%d hour %d min', nSec / 3600, (nSec % 3600) / 60)
	elseif nSec < 31536000 then -- X��XСʱ
		return _L('%d day %d hour', nSec / 86400, (nSec % 86400) / 3600)
	else -- X��X��
		return _L('%d year %d day', nSec / 31536000, (nSec % 31536000) / 86400)
	end
end

-- ��ȡ��Ե�ַ���
function D.FormatLoverString(szPatt, lover)
	if wstring.find(szPatt, '{$type}') then
		if lover.nLoverType == 1 then
			szPatt = wstring.gsub(szPatt, '{$type}', _L['Mutual love'])
		else
			szPatt = wstring.gsub(szPatt, '{$type}', _L['Blind love'])
		end
	end
	if wstring.find(szPatt, '{$time}') then
		szPatt = wstring.gsub(szPatt, '{$time}', D.FormatTimeCounter(GetCurrentTime() - lover.nLoverTime))
	end
	if wstring.find(szPatt, '{$name}') then
		szPatt = wstring.gsub(szPatt, '{$name}', lover.szName)
	end
	if wstring.find(szPatt, '{$map}') then
		szPatt = wstring.gsub(szPatt, '{$map}', Table_GetMapName(lover.dwMapID))
	end
	return szPatt
end

-- ������Ե
function D.SaveLover(nTime, dwID, nType, nSendItem, nReceiveItem)
	-- ��Ϊ����Եʱ��dwID��������Ϊ1��������δ����
	if dwID == 0 then
		nTime, nType, nSendItem, nReceiveItem = 1, 1, 1, 1
	end
	X.SetRemoteStorage('MY_Love', dwID, nTime, nType, nSendItem, nReceiveItem)
	D.UpdateProtectData()
	D.UpdateLocalLover()
end

-- ������Ե
function D.SetLover(dwID, nType)
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	local aInfo = X.GetFriend(dwID)
	if not aInfo or not aInfo.isonline then
		if nType == -1 then
			return X.Alert(_L['Lover must online'])
		end
		return X.Alert(_L['Lover must be a online friend'])
	end
	if nType == -1 then
		-- �ظ����̻�ˢ�³ƺ�
		if dwID == D.lover.dwID then
			D.CreateFireworkSelect(function(p)
				if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
					return X.Systopmsg(_L['Light firework is a sensitive action, please unlock to continue.'])
				end
				D.UseDoubleLoveItem(aInfo, p.aUIID, function(bSuccess)
					if bSuccess then
						D.SaveLover(D.lover.nLoverTime, D.lover.dwID, D.lover.nLoverType, p.nItem, D.lover.nReceiveItem)
						X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_FIREWORK', p.nItem})
						Wnd.CloseWindow('MY_Love_SetLover')
					else
						X.Systopmsg(_L['Failed to light firework.'])
					end
				end)
			end)
		end
	elseif nType == 0 then
		-- ���ó�Ϊ��Ե�����ߺ��ѣ�
		-- ������Ե���򵥣�
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			return X.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
		end
		X.Confirm(_L('Do you want to blind love with [%s]?', aInfo.name), function()
			local aInfo = X.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return X.Alert(_L['Lover must be a online friend'])
			end
			if aInfo.attraction < MY_Love.nLoveAttraction then
				return X.Alert(_L['Inadequate conditions, requiring Lv2 friend'])
			end
			D.SaveLover(GetCurrentTime(), dwID, nType, 0, 0)
			X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE0'})
		end)
	else
		-- ���ó�Ϊ��Ե�����ߺ��ѣ�
		-- ˫����Ե�����ߣ����һ�𣬲�����4���ڣ����𷽴���һ��ָ���̻���
		D.CreateFireworkSelect(function(p)
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
				return X.Systopmsg(_L['Set lover is a sensitive action, please unlock to continue.'])
			end
			local aInfo = X.GetFriend(dwID)
			if not aInfo or not aInfo.isonline then
				return X.Alert(_L['Lover must be a online friend'])
			end
			X.Confirm(_L('Do you want to mutual love with [%s]?', aInfo.name), function()
				if not D.GetDoubleLoveItem(aInfo, p.aUIID) then
					return X.Alert(_L('Inadequate conditions, requiring Lv6 friend/party/4-feet distance/%s', p.szName))
				end
				D.nPendingItem = p.nItem
				X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_ASK'})
				X.Systopmsg(_L('Love request has been sent to [%s], wait please', aInfo.name))
			end)
		end)
	end
end

-- ɾ����Ե
function D.RemoveLover()
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Systopmsg(_L['Remove lover is a sensitive action, please unlock to continue.'])
	end
	local lover = X.Clone(D.lover)
	if lover.dwID ~= 0 then
		local nTime = GetCurrentTime() - lover.nLoverTime
		if nTime < 3600 then
			return X.Alert(_L('Love can not run a red-light, wait for %s left.', D.FormatTimeCounter(3600 - nTime)))
		end
		-- ȡ����Ե
		if lover.nLoverType == 0 then -- ����
			X.Confirm(_L('Are you sure to cut blind love with [%s]?', lover.szName), function()
				-- ����ֻ֪ͨ���ߵ�
				local aInfo = X.GetFriend(lover.dwID)
				if aInfo and aInfo.isonline then
					X.SendBgMsg(lover.szName, 'MY_LOVE', {'REMOVE0'})
				end
				D.SaveLover(0, 0, 0, 0, 0)
				X.Sysmsg(_L['Congratulations, cut blind love finish.'])
			end)
		elseif lover.nLoverType == 1 then -- ˫��
			X.Confirm(_L('Are you sure to cut mutual love with [%s]?', lover.szName), function()
				X.DelayCall(50, function()
					X.Confirm(_L['Past five hundred times looking back only in exchange for a chance encounter this life, you really decided?'], function()
						X.DelayCall(50, function()
							X.Confirm(_L['You do not really want to cut off love it, really sure?'], function()
								-- ˫������������
								X.SendChat(lover.szName, _L['Sorry, I decided to just a swordman, bye my plugin lover'])
								D.SaveLover(0, 0, 0, 0, 0)
								-- X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('A blade and cut, no longer meet with [%s].', lover.szName))
								X.Sysmsg(_L['Congratulations, do not repeat the same mistakes ah.'])
							end)
						end)
					end)
				end)
			end)
		end
	end
end

-- �޸�˫����Ե
function D.FixLover()
	if D.lover.nLoverType ~= 1 then
		return X.Alert(_L['Repair feature only supports mutual love!'])
	end
	if not X.IsParty(D.lover.dwID) then
		return X.Alert(_L['Both sides must in a team to be repaired!'])
	end
	X.SendBgMsg(D.lover.szName, 'MY_LOVE', {'FIX1', {
		D.lover.nLoverTime,
		D.lover.nSendItem,
		D.lover.nReceiveItem,
	}})
	X.Systopmsg(_L['Repair request has been sent, wait please.'])
end

-- ��ȡ�鿴Ŀ��
function D.GetPlayerInfo(dwID)
	local tar = GetPlayer(dwID)
	if not tar then
		local aCard = GetFellowshipCardClient().GetFellowshipCardInfo(dwID)
		if aCard and aCard.bExist then
			tar = { dwID = dwID, szName = aCard.szName, nGender = 1 }
			if aCard.nRoleType == 2 or aCard.nRoleType == 4 or aCard.nRoleType == 6 then
				tar.nGender = 2
			end
		end
	end
	return tar
end

-- ��̨������˵���Ե����
function D.RequestOtherLover(dwID, nX, nY, fnAutoClose)
	local tar = D.GetPlayerInfo(dwID)
	if not tar then
		return
	end
	if nX == true or X.IsParty(dwID) then
		if not D.tOtherLover[dwID] then
			D.tOtherLover[dwID] = {}
		end
		FireUIEvent('MY_LOVE_OTHER_UPDATE', dwID)
		if tar.bFightState and not X.IsParty(tar.dwID) then
			FireUIEvent('MY_LOVE_PV_ACTIVE_CHANGE', tar.dwID, false)
			return X.Systopmsg(_L('[%s] is in fighting, no time for you.', tar.szName))
		end
		local me = GetClientPlayer()
		X.SendBgMsg(tar.szName, 'MY_LOVE', {'VIEW', X.PACKET_INFO.AUTHOR_ROLES[me.dwID] == me.szName and 'Author' or 'Player'})
	else
		local tMsg = {
			x = nX, y = nY,
			szName = 'MY_Love_Confirm',
			szMessage = _L('[%s] is not in your party, do you want to send a request for accessing data?', tar.szName),
			szAlignment = 'CENTER',
			fnAutoClose = fnAutoClose,
			{
				szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					D.RequestOtherLover(dwID, true)
				end,
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		}
		MessageBox(tMsg)
	end
end

function D.GetOtherLover(dwID)
	return D.tOtherLover[dwID]
end

local BACKUP_PASS_PHRASE = '78ed108e-cedd-40ef-8dcc-1529db94b3c9'
function D.BackupLover(...)
	local szLoverName, szLoverUUID = ...
	if not X.CanUseOnlineRemoteStorage() then
		return X.Alert(_L['Please enable sync common ui config first'])
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		return X.Systopmsg(_L['Backup lover is a sensitive action, please unlock to continue.'])
	end
	local lover = X.Clone(D.lover)
	if select('#', ...) == 2 then
		if szLoverName == lover.szName and szLoverUUID then
			local szPath = X.FormatPath(
				{
					'export/lover_backup/'
						.. X.GetUserRoleName() .. '_' .. X.GetClientUUID() .. '-'
						.. szLoverName .. '_' .. szLoverUUID .. '-'
						.. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss')
						.. '.lover.jx3dat',
					X.PATH_TYPE.ROLE
				})
			X.SaveLUAData(
				szPath,
				{
					szName = X.GetUserRoleName(),
					szUUID = X.GetClientUUID(),
					szLoverName = szLoverName,
					szLoverUUID = szLoverUUID,
					nLoverType = lover.nLoverType,
					nLoverTime = lover.nLoverTime,
					nSendItem = lover.nSendItem,
					nReceiveItem = lover.nReceiveItem,
				},
				{ passphrase = BACKUP_PASS_PHRASE }
			)
			local szFullPath = X.GetAbsolutePath(szPath)
			X.Alert(_L('Backup lover successed, file located at: %s.', szFullPath))
			X.Sysmsg(_L('Backup lover successed, file located at: %s.', szFullPath))
		end
	else
		if lover.nLoverType == 1 then -- ˫��
			local info = GetClientTeam().GetMemberInfo(lover.dwID)
			if not info or not info.bIsOnLine then
				X.Systopmsg(_L['Lover must in your team and online to do backup.'])
			else
				X.SendBgMsg(lover.szName, 'MY_LOVE', {'BACKUP'})
				X.Systopmsg(_L['Backup request has been sent, wait please.'])
			end
		else
			X.Systopmsg(_L['Backup feature only supports mutual love!'])
		end
	end
end

function D.RestoreLover(szFilePath)
	local data = X.LoadLUAData(szFilePath, { passphrase = BACKUP_PASS_PHRASE })
	local errs = X.Schema.CheckSchema(data, BACKUP_DATA_SCHEMA)
	if errs then
		return X.Alert(_L['Error: file is not a valid lover backup!'])
	end
	if data.szUUID == X.GetClientUUID() then
		GetUserInput(_L['Please input your lover\'s current name:'], function(szLoverName)
			szLoverName = wstring.gsub(wstring.gsub(X.TrimString(szLoverName), '[', ''), ']', '')
			X.Confirm(
				_L('Send restore lover request to [%s]?', szLoverName),
				function()
					X.SendBgMsg(szLoverName, 'MY_LOVE', {'RESTORE', data})
				end
			)
		end, nil, nil, nil, data.szLoverName)
	else
		X.Alert(_L['This file is not your lover backup, please check!'])
	end
end

-------------------------------------
-- �¼�����
-------------------------------------
-- �������ݸ��£���ʱ�����Ե�仯��ɾ�����Ѹı�ע�ȣ�
do
local function OnFellowshipUpdate()
	if MY_Love.IsShielded() then
		return
	end
	-- ������ʾ
	local lover = D.GetLover()
	if lover and lover.bOnline and lover.dwMapID ~= 0
	and (D.lover.dwID ~= lover.dwID or D.lover.bOnline ~= lover.bOnline) then
		D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] is happy in [{$map}].'), lover))
	end
	-- ������Ե
	D.UpdateLocalLover()
end
X.RegisterEvent('PLAYER_FELLOWSHIP_UPDATE', 'MY_Love', OnFellowshipUpdate)
X.RegisterEvent('FELLOWSHIP_CARD_CHANGE', 'MY_Love', OnFellowshipUpdate)
X.RegisterEvent('UPDATE_FELLOWSHIP_CARD', 'MY_Love', OnFellowshipUpdate)
end

-- �ظ���Ե��Ϣ
function D.ReplyLove(bCancel)
	local szName = D.lover.szName
	if D.lover.dwID == 0 then
		szName = '<' .. O.szNone .. '>'
	elseif bCancel then
		szName = _L['<Not tell you>']
	end
	for k, v in pairs(D.tViewer) do
		X.SendBgMsg(v, 'MY_LOVE', {'REPLY', {
			D.lover.dwID,
			szName,
			D.lover.dwAvatar or 0,
			O.szSign,
			D.lover.dwForceID or 0,
			D.lover.nRoleType or 0,
			D.lover.nLoverType,
			D.lover.nLoverTime,
			D.lover.szLoverTitle,
		}})
	end
	D.tViewer = {}
end

-- ��̨ͬ��
do
local function OnBgTalk(_, aData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if MY_Love.IsShielded() then
		return
	end
	if not bSelf then
		if not X.CanUseOnlineRemoteStorage() then
			X.SendBgMsg(szTalkerName, 'MY_LOVE', {'DATA_NOT_SYNC'})
			return
		end
		local szKey, data = aData[1], aData[2]
		if szKey == 'VIEW' then
			if X.IsParty(dwTalkerID) or data == 'Author' or O.bAutoReplyLover then
				D.tViewer[dwTalkerID] = szTalkerName
				D.ReplyLove()
			elseif not GetClientPlayer().bFightState and not O.bQuiet then
				D.tViewer[dwTalkerID] = szTalkerName
				X.Confirm(
					_L('[%s] want to see your lover info, OK?', szTalkerName),
					function() D.ReplyLove() end,
					function() D.ReplyLove(true) end
				)
			end
		elseif szKey == 'LOVE0' or szKey == 'REMOVE0' then
			local i = math.random(1, math.floor(table.getn(D.aAutoSay)/2)) * 2
			if szKey == 'LOVE0' then
				i = i - 1
			end
			OutputMessage('MSG_WHISPER', _L['[Mystery] quietly said:'] .. D.aAutoSay[i] .. '\n')
			PlaySound(SOUND.UI_SOUND,g_sound.Whisper)
		elseif szKey == 'LOVE_ASK' then
			if D.lover.dwID == dwTalkerID and D.lover.nLoverType == 1 then
				-- ������Ե�����޸�
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'FIX2', {
					D.lover.nLoverTime,
					D.lover.nSendItem,
					D.lover.nReceiveItem,
				}})
			elseif D.lover.dwID ~= 0 and (D.lover.dwID ~= dwTalkerID or D.lover.nLoverType == 1) then
				-- ������Եֱ�Ӿܾ�
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_EXISTS'})
			else
				-- ѯ�����
				X.Confirm(_L('[%s] want to mutual love with you, OK?', szTalkerName), function()
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_YES'})
				end, function()
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_NO'})
				end)
			end
		elseif szKey == 'FIX1' or szKey == 'FIX2' then
			if D.lover.dwID == 0 or (D.lover.dwID == dwTalkerID and D.lover.nLoverType ~= 1) then
				local aInfo = X.GetFriend(dwTalkerID)
				if aInfo then
					local szText = szKey == 'FIX1'
						and _L('[%s] want to repair love relation with you, OK?', szTalkerName)
						or _L('[%s] is already your lover, fix it now?', szTalkerName)
					X.Confirm(szText, function()
						if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
							X.Systopmsg(_L['Fix lover is a sensitive action, please unlock to continue.'])
							return false
						end
						Wnd.CloseWindow('MY_Love_SetLover')
						D.SaveLover(tonumber(data[1]), dwTalkerID, 1, data[3], data[2])
						X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
						X.Systopmsg(_L('Congratulations, love relation with [%s] has been fixed!', szTalkerName))
					end)
				end
			elseif szKey == 'FIX1' then
				if D.lover.dwID == dwTalkerID then
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_ALREADY'})
				else
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'LOVE_ANS_EXISTS'})
				end
			end
		elseif szKey == 'LOVE_ANS_EXISTS' then
			local szMsg = _L['Unfortunately the other has lover, but you can still blind love him!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_ALREADY' then
			local szMsg = _L['The other is already your lover!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_NO' then
			local szMsg = _L['The other refused you without reason, but you can still blind love him!']
			X.Sysmsg(szMsg)
			X.Alert(szMsg)
		elseif szKey == 'LOVE_ANS_YES' then
			local nItem = D.nPendingItem
			local aUIID = nItem and D.tLoverItem[nItem] and D.tLoverItem[nItem].aUIID
			if X.IsEmpty(aUIID) then
				return
			end
			local aInfo = X.GetFriend(dwTalkerID)
			D.UseDoubleLoveItem(aInfo, aUIID, function(bSuccess)
				if bSuccess then
					D.SaveLover(GetCurrentTime(), dwTalkerID, 1, nItem, 0)
					X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
					X.SendBgMsg(aInfo.name, 'MY_LOVE', {'LOVE_ANS_CONF', nItem})
					X.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
					Wnd.CloseWindow('MY_Love_SetLover')
				else
					X.Systopmsg(_L['Failed to attach love, light firework failed.'])
				end
			end)
		elseif szKey == 'LOVE_ANS_CONF' then
			local aInfo = X.GetFriend(dwTalkerID)
			if aInfo then
				D.SaveLover(GetCurrentTime(), dwTalkerID, 1, 0, data)
				X.SendChat(PLAYER_TALK_CHANNEL.TONG, _L('From now on, my heart lover is [%s]', szTalkerName))
				X.Systopmsg(_L('Congratulations, success to attach love with [%s]!', aInfo.name))
			end
		elseif szKey == 'LOVE_FIREWORK' then
			local aInfo = X.GetFriend(dwTalkerID)
			if aInfo and D.lover.dwID == dwTalkerID then
				D.SaveLover(D.lover.nLoverTime, dwTalkerID, D.lover.nLoverType, D.lover.nSendItem, data)
			end
		elseif szKey == 'REPLY' then
			D.tOtherLover[dwTalkerID] = {
				dwID = data[1] or 0,
				szName = data[2] or '',
				dwAvatar = tonumber(data[3]) or 0,
				szSign = data[4] or '',
				dwForceID = tonumber(data[5]),
				nRoleType = tonumber(data[6]) or 1,
				nLoverType = tonumber(data[7]) or 0,
				nLoverTime = tonumber(data[8]) or 0,
				szLoverTitle = data[9] or '',
			}
			FireUIEvent('MY_LOVE_OTHER_UPDATE', dwTalkerID)
		elseif szKey == 'BACKUP' then
			if D.lover.dwID == dwTalkerID then
				X.Confirm(_L('[%s] want to backup lover relation with you, do you agree?', szTalkerName), function()
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						X.Systopmsg(_L['Backup lover is a sensitive action, please unlock to continue.'])
						return false
					end
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'BACKUP_ANS', X.GetClientUUID()})
				end)
			else
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'BACKUP_ANS_NOT_LOVER'})
			end
		elseif szKey == 'BACKUP_ANS' then
			D.BackupLover(szTalkerName, data)
		elseif szKey == 'BACKUP_ANS_NOT_LOVER' then
			X.Alert(_L['Peer is not your lover, please check, or do fix lover first.'])
		elseif szKey == 'RESTORE' then
			if data.szLoverUUID == X.GetClientUUID() then
				X.Confirm(_L('[%s] want to restore lover relation with you, do you agree?', szTalkerName), function()
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						X.Systopmsg(_L['Restore lover is a sensitive action, please unlock to continue.'])
						return false
					end
					X.SendBgMsg(szTalkerName, 'MY_LOVE', {'RESTORE_AGREE', data})
				end)
			else
				X.SendBgMsg(szTalkerName, 'MY_LOVE', {'RESTORE_NOT_ME', data})
			end
		elseif szKey == 'RESTORE_AGREE' then
			if X.GetClientUUID() == data.szUUID and not X.Schema.CheckSchema(data, BACKUP_DATA_SCHEMA) then
				D.SaveLover(data.nLoverTime, dwTalkerID, data.nLoverType, data.nSendItem, data.nReceiveItem)
				X.Alert(_L['Restore lover succeed!'])
			end
		elseif szKey == 'RESTORE_NOT_ME' then
			X.Alert(_L['Peer is not your lover in this backup, please check.'])
		elseif szKey == 'DATA_NOT_SYNC' then
			X.Alert(_L('[%s] disabled ui config sync, unable to read data.', szTalkerName))
		end
	end
end
X.RegisterBgMsg('MY_LOVE', OnBgTalk)
end

-- ��Ե��������֪ͨ
function D.OutputLoverMsg(szMsg)
	X.SendChat(PLAYER_TALK_CHANNEL.LOCAL_SYS, szMsg)
end

-- ���ߣ�����֪ͨ��bOnLine, szName, bFoe
do
local function OnPlayerFellowshipLogin()
	if MY_Love.IsShielded() then
		return
	end
	if not arg2 and arg1 == D.lover.szName and D.lover.szName ~= '' then
		if arg0 then
			FireUIEvent('MY_COMBATTEXT_MSG', _L('Love tip: %s onlines now', D.lover.szName), true, { 255, 0, 255 })
			PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] online, hurry doing needy doing.'), D.lover))
		else
			D.OutputLoverMsg(D.FormatLoverString(_L('Warm tip: Your {$type} lover [{$name}] offline, hurry doing like doing.'), D.lover))
		end
		if not Station.Lookup('Normal/SocialPanel') then
			Wnd.OpenWindow('SocialPanel')
			Wnd.CloseWindow('SocialPanel')
		end
	end
end
X.RegisterEvent('PLAYER_FELLOWSHIP_LOGIN', 'MY_Love', OnPlayerFellowshipLogin)
end

-- player enter
do
local function OnPlayerEnterScene()
	if D.bReady and O.bAutoFocus and arg0 == D.lover.dwID
	and MY_Focus and MY_Focus.SetFocusID and not X.IsInArena() then
		MY_Focus.SetFocusID(TARGET.PLAYER, arg0)
	end
end
X.RegisterEvent('PLAYER_ENTER_SCENE', 'MY_Love', OnPlayerEnterScene)
end

-- on init
do
local function OnInit()
	D.bReady = true
	D.UpdateLocalLover()
end
X.RegisterInit('MY_Love', OnInit)
end

-- protect data
do
function D.UpdateProtectData()
	D.aStorageData = {X.GetRemoteStorage('MY_Love')}
end
local function onSyncUserPreferencesEnd()
	if D.aStorageData then
		X.SetRemoteStorage('MY_Love', unpack(D.aStorageData))
	else
		D.UpdateProtectData()
	end
end
X.RegisterEvent('SYNC_USER_PREFERENCES_END', 'MY_Love', onSyncUserPreferencesEnd)
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	name = 'MY_Love',
	exports = {
		{
			fields = {
				'nLoveAttraction',
				'nDoubleLoveAttraction',
				'IsShielded',
				'GetLover',
				'SetLover',
				'FixLover',
				'BackupLover',
				'RestoreLover',
				'RemoveLover',
				'FormatLoverString',
				'GetPlayerInfo',
				'RequestOtherLover',
				'GetOtherLover',
			},
			root = D,
		},
		{
			fields = {
				'bQuiet',
				'szNone',
				'szJabber',
				'szSign',
				'bAutoFocus',
				'bHookPlayerView',
				'bAutoReplyLover',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bQuiet',
				'szNone',
				'szJabber',
				'szSign',
				'bAutoFocus',
				'bHookPlayerView',
				'bAutoReplyLover',
			},
			triggers = {
				bAutoFocus = function(_, bAutoFocus)
					if bAutoFocus and D.lover.dwID ~= 0 and MY_Focus and MY_Focus.SetFocusID then
						MY_Focus.SetFocusID(TARGET.PLAYER, D.lover.dwID)
					elseif not bAutoFocus and D.lover.dwID ~= 0 and MY_Focus and MY_Focus.RemoveFocusID then
						MY_Focus.RemoveFocusID(TARGET.PLAYER, D.lover.dwID)
					end
				end,
				bHookPlayerView = function(_, bHookPlayerView)
					FireUIEvent('MY_LOVE_PV_HOOK', bHookPlayerView)
				end,
			},
			root = O,
		},
	},
}
MY_Love = X.CreateModule(settings)
end
