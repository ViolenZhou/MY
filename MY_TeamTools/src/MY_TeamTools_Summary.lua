--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Ŷӹ��� - �ŶӸſ�
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamTools_Summary'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_Summary'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^23.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {
	tAnchor = {},
	tDamage = {},
	tDeath  = {},
}
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_Summary.ini'
local MY_IsParty, MY_GetSkillName, MY_GetBuffName = X.IsParty, X.GetSkillName, X.GetBuffName

local RT_EQUIP_TOTAL = {
	'MELEE_WEAPON', -- �ὣ �ؽ�ȡ BIG_SWORD �ؽ�
	'RANGE_WEAPON', -- Զ������
	'CHEST',        -- �·�
	'HELM',         -- ñ��
	'AMULET',       -- ����
	'LEFT_RING',    -- ��ָ
	'RIGHT_RING',   -- ��ָ
	'WAIST',        -- ����
	'PENDANT',      -- ��׹
	'PANTS',        -- ����
	'BOOTS',        -- Ь��
	'BANGLE',       -- ����
}

local RT_SKILL_TYPE = {
	[0]  = 'PHYSICS_DAMAGE',
	[1]  = 'SOLAR_MAGIC_DAMAGE',
	[2]  = 'NEUTRAL_MAGIC_DAMAGE',
	[3]  = 'LUNAR_MAGIC_DAMAGE',
	[4]  = 'POISON_DAMAGE',
	[5]  = 'REFLECTIED_DAMAGE',
	[6]  = 'THERAPY',
	[7]  = 'STEAL_LIFE',
	[8]  = 'ABSORB_THERAPY',
	[9]  = 'ABSORB_DAMAGE',
	[10] = 'SHIELD_DAMAGE',
	[11] = 'PARRY_DAMAGE',
	[12] = 'INSIGHT_DAMAGE',
	[13] = 'EFFECTIVE_DAMAGE',
	[14] = 'EFFECTIVE_THERAPY',
	[15] = 'TRANSFER_LIFE',
	[16] = 'TRANSFER_MANA',
}
-- �ؾ����� ���������
-- local RT_DUNGEON_TOTAL = {}
local RT_SCORE = {
	Equip   = _L['Equip score'],
	Buff    = _L['Buff score'],
	Food    = _L['Food score'],
	Enchant = _L['Enchant score'],
	Special = _L['Special equip score'],
}

local RT_EQUIP_SPECIAL = {
	MELEE_WEAPON = true,
	BIG_SWORD    = true,
	AMULET       = true,
	PENDANT      = true
}

local RT_FOOD_TYPE = {
	[24] = true,
	[17] = true,
	[18] = true,
	[19] = true,
	[20] = true
}
-- ��Ҫ��ص�BUFF
local RT_BUFF_ID = {
	-- ����ְҵBUFF
	[362]  = true,
	[673]  = true,
	[112]  = true,
	[382]  = true,
	[2837] = true,
	-- ������
	[6329] = true,
	[6330] = true,
	-- ������
	[2564] = true,
	[2563] = true,
	-- ��������
	[3098] = true,
	-- ���� / ��˹�
	[2313] = true,
	[5970] = true,
}
local RT_GZ_BUFF_ID = 3219 -- ��ս����
-- default sort
local RT_SORT_MODE = 'DESC'
local RT_SORT_FIELD = 'nEquipScore'
local RT_MAP_ID = 0
local RT_PLAYER_MAP_COPY_ID = {}
local RT_MAP_CD_PROGRESS = {}
local RT_SELECT_PAGE = 0
local RT_SELECT_KUNGFU
local RT_SELECT_DEATH
--
local RT_SCORE_FULL = 30000

function D.UpdateDungeonInfo(hDungeon)
	local me = X.GetClientPlayer()
	local szText = Table_GetMapName(RT_MAP_ID)
	if me.GetMapID() == RT_MAP_ID and X.IsDungeonMap(RT_MAP_ID) then
		szText = szText .. '\n' .. 'ID:(' .. me.GetScene().nCopyIndex  ..')'
	else
		local tCD = X.GetMapSaveCopy()
		if tCD and tCD[RT_MAP_ID] then
			szText = szText .. '\n' .. 'ID:(' .. tCD[RT_MAP_ID][1]  ..')'
		end
	end
	hDungeon:Lookup('Text_Dungeon'):SetText(szText)
end

function D.GetPlayerView()
	return Station.Lookup('Normal/PlayerView')
end

function D.ViewInviteToPlayer(page, dwID)
	local me = X.GetClientPlayer()
	if dwID ~= me.dwID then
		page.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID)
	end
end
-- ��������
function D.CountScore(tab, tScore)
	tScore.Food = tScore.Food + #tab.tFood * 100
	tScore.Buff = tScore.Buff + #tab.tBuff * 20
	if tab.nEquipScore then
		tScore.Equip = tScore.Equip + tab.nEquipScore
	end
	if tab.tTemporaryEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tTemporaryEnchant * 300
	end
	if tab.tPermanentEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tPermanentEnchant * 100
	end
	if tab.tEquip then
		for k, v in ipairs(tab.tEquip) do
			tScore.Special = tScore.Special + v.nLevel * 0.15 *  v.nQuality
		end
	end
end
-- �������
function D.CalculateSort(tInfo)
	local nCount = -2
	if RT_SORT_FIELD == 'tBossKill' then
		if X.IsCDProgressMap(RT_MAP_ID) then
			nCount = 0
			for _, p in ipairs(tInfo[RT_SORT_FIELD]) do
				if p then
					nCount = nCount + 100
				else
					nCount = nCount + 1
				end
			end
		else
			nCount = tInfo.nCopyID or math.huge
		end
	elseif tInfo[RT_SORT_FIELD] then
		if type(tInfo[RT_SORT_FIELD]) == 'table' then
			nCount = #tInfo[RT_SORT_FIELD]
		else
			nCount = tInfo[RT_SORT_FIELD]
		end
	end
	if nCount == 0 and not tInfo.bIsOnLine then
		nCount = -2
	end
	return nCount
end
function D.Sorter(a, b)
	local nCountA = D.CalculateSort(a)
	local nCountB = D.CalculateSort(b)

	if RT_SORT_MODE == 'ASC' then -- ����
		return nCountA < nCountB
	else
		return nCountA > nCountB
	end
end
-- ����UI ûʲô������� ��Ҫclear
function D.UpdateList(page)
	local me = X.GetClientPlayer()
	if not me then return end
	local aTeam, tKungfu = D.GetTeamData(page), {}
	local tScore = {
		Equip   = 0,
		Buff    = 0,
		Food    = 0,
		Enchant = 0,
		Special = 0,
	}
	table.sort(aTeam, D.Sorter)

	for k, v in ipairs(aTeam) do
		-- �ķ�ͳ��
		tKungfu[v.dwMountKungfuID] = tKungfu[v.dwMountKungfuID] or {}
		table.insert(tKungfu[v.dwMountKungfuID], v)
		D.CountScore(v, tScore)
		if not RT_SELECT_KUNGFU or (RT_SELECT_KUNGFU and v.dwMountKungfuID == RT_SELECT_KUNGFU) then
			local szName = 'P' .. (v.szGlobalID or v.dwID)
			local h = page.hPlayerList:Lookup(szName)
			if not h then
				h = page.hPlayerList:AppendItemFromData(page.hItemDataPlayer)
			end
			h:SetUserData(k)
			h:SetName(szName)
			h.dwID       = v.dwID
			h.szGlobalID = v.szGlobalID
			h.szName     = v.szName
			-- �ķ�����
			if v.dwMountKungfuID and v.dwMountKungfuID ~= 0 then
				local nIcon = select(2, MY_GetSkillName(v.dwMountKungfuID, 1))
				h:Lookup('Image_Icon'):FromIconID(nIcon)
			else
				h:Lookup('Image_Icon'):FromUITex(GetForceImage(v.dwForceID))
			end
			h:Lookup('Text_Name'):SetText(v.szName)
			h:Lookup('Text_Name'):SetFontColor(X.GetForceColor(v.dwForceID))
			-- ҩƷ��BUFF
			if not h['hHandle_Food'] then
				h['hHandle_Food'] = {
					self = h:Lookup('Handle_Food'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_Food'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			if not h['hHandle_Equip'] then
				h['hHandle_Equip'] = {
					self = h:Lookup('Handle_Equip'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_Equip'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			local hBuff = h:Lookup('Box_Buff')
			local hBox = h:Lookup('Box_Grandpa')
			if not v.bIsOnLine then
				h.hHandle_Equip.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				h:Lookup('Text_Toofar1'):SetText(g_tStrings.STR_GUILD_OFFLINE)
			end
			if not v.KPlayer then
				h.hHandle_Food.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				if MY_TeamTools.szStatRange == 'ROOM' then
					h:Lookup('Text_Toofar1'):SetText('-')
				elseif v.bIsOnLine then
					h:Lookup('Text_Toofar1'):SetText(_L['Too far'])
				end
				hBuff:Hide()
				hBox:Hide()
			else
				hBuff:Show()
				hBox:Show()
				h:Lookup('Text_Toofar1'):Hide()
				-- СҩUI����
				local handle_food = h.hHandle_Food.self
				for kk, vv in ipairs(v.tFood) do
					local szName = vv.dwID .. '_' .. vv.nLevel
					local nIcon = select(2, MY_GetBuffName(vv.dwID, vv.nLevel))
					local box = handle_food:Lookup(szName)
					if not box then
						box = h.hHandle_Food.Pool:New()
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, vv.dwID, vv.nLevel, vv.nEndFrame)
					box:SetObjectIcon(nIcon)
					box.OnItemRefreshTip = function()
						local dwID, nLevel, nEndFrame = select(2, this:GetObject())
						local nTime = (nEndFrame - GetLogicFrameCount()) / 16
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						X.OutputBuffTip({ x, y, w, h }, dwID, nLevel, nTime)
					end
					local nTime = (vv.nEndFrame - GetLogicFrameCount()) / 16
					if nTime < 480 then
						box:SetAlpha(80)
					else
						box:SetAlpha(255)
					end
					box:Show()
				end
				for i = 0, handle_food:GetItemCount() - 1, 1 do
					local item = handle_food:Lookup(i)
					if item and not item.bFree then
						local dwID, nLevel, nEndFrame = select(2, item:GetObject())
						if dwID and nLevel then
							if not X.GetBuff(v.KPlayer, dwID, nLevel) then
								h.hHandle_Food.Pool:Remove(item)
							end
						end
					end
				end
				handle_food:FormatAllItemPos()
				-- BUFF UI����
				if v.tBuff and #v.tBuff > 0 then
					hBuff:EnableObject(true)
					hBuff:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
					hBuff:SetOverTextFontScheme(1, 197)
					hBuff:SetOverText(1, #v.tBuff)
					hBuff.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local xml = {}
						for k, v in ipairs(v.tBuff) do
							local nIcon = select(2, MY_GetBuffName(v.dwID, v.nLevel))
							local nTime = (v.nEndFrame - GetLogicFrameCount()) / 16
							local nAlpha = nTime < 600 and 80 or 255
							table.insert(xml, '<image> path="fromiconid" frame=' .. nIcon ..' alpha=' .. nAlpha ..  ' w=30 h=30 </image>')
						end
						OutputTip(table.concat(xml), 250, { x, y, w, h })
					end
				else
					hBuff:SetOverText(1, '')
					hBuff:EnableObject(false)
				end
				if v.bGrandpa then
					hBox:EnableObject(true)
					hBox.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local kBuff = X.GetBuff(v.KPlayer, RT_GZ_BUFF_ID)
						if kBuff then
							X.OutputBuffTip({ x, y, w, h }, kBuff.dwID, kBuff.nLevel)
						end
					end
				end
				hBox:EnableObject(v.bGrandpa)
			end
			-- ҩƷ����ħ
			if v.tTemporaryEnchant and #v.tTemporaryEnchant > 0 then
				local vv = v.tTemporaryEnchant[1]
				local box = h:Lookup('Box_Enchant')
				box:Show()
				if vv.CommonEnchant then
					box:SetObjectIcon(6216)
				else
					box:SetObjectIcon(7577)
				end
				box.OnItemRefreshTip = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local desc = ''
					if vv.CommonEnchant then
						desc = X.Table.GetCommonEnchantDesc(vv.dwTemporaryEnchantID)
					else
						-- ... �ٷ����̫�鷳��
						local tEnchant = GetItemEnchantAttrib(vv.dwTemporaryEnchantID)
						if tEnchant then
							for kkk, vvv in pairs(tEnchant) do
								if vvv.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then -- ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER
									local SkillEvent = X.GetGameTable('SkillEvent', true)
									local skillEvent = SkillEvent and SkillEvent:Search(vvv.nValue1)
									if skillEvent then
										desc = desc .. FormatString(skillEvent.szDesc, vvv.nValue1, vvv.nValue2)
									else
										desc = desc .. '<text>text="unknown skill event id:'.. vvv.nValue1..'"</text>'
									end
								elseif vvv.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then -- ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE
									local EquipmentRecipe = X.GetGameTable('EquipmentRecipe', true)
									if EquipmentRecipe then
										local tRecipeSkillAtrri = EquipmentRecipe:Search(vvv.nValue1, vvv.nValue2)
										if tRecipeSkillAtrri then
											desc = desc .. tRecipeSkillAtrri.szDesc
										end
									end
								else
									if Table_GetMagicAttributeInfo then
										desc = desc .. FormatString(Table_GetMagicAttributeInfo(vvv.nID, true), vvv.nValue1, vvv.nValue2, 0, 0)
									else
										desc = GetFormatText('Enchant Attrib value ' .. vvv.nValue1 .. ' ', 113)
									end
								end

							end
						end
					end
					if desc and #desc > 0 then
						OutputTip(desc:gsub('font=%d+', 'font=113') .. GetFormatText(FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME ..'\n', GetTimeText(vv.nTemporaryEnchantLeftSeconds)), 102), 400, { x, y, w, h })
					end
				end
				if vv.nTemporaryEnchantLeftSeconds < 480 then
					box:SetAlpha(80)
				else
					box:SetAlpha(255)
				end
			else
				h:Lookup('Box_Enchant'):Hide()
			end
			-- װ��
			if v.tEquip and #v.tEquip > 0 then
				local handle_equip = h.hHandle_Equip.self
				for kk, vv in ipairs(v.tEquip) do

					local szName = tostring(vv.nUiId)
					local box = handle_equip:Lookup(szName)
					if not box then
						box = h.hHandle_Equip.Pool:New()
						X.UpdateItemBoxExtend(box, vv.nQuality)
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_OTER_PLAYER_ITEM, vv.nUiId, vv.dwBox, vv.dwX, v.dwID)
					box:SetObjectIcon(vv.nIcon)
					local item = GetItem(vv.dwID)
					if item then
						UpdataItemBoxObject(box, vv.dwBox, vv.dwX, item, nil, nil, v.dwID)
					end
					box.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						if not GetItem(vv.dwID) then
							D.ApplyRemotePlayerView(page, v.dwID)
							OutputItemTip(UI_OBJECT_ITEM_INFO, X.ENVIRONMENT.CURRENT_ITEM_VERSION, vv.dwTabType, vv.dwIndex, {x, y, w, h})
						else
							OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, vv.dwID, nil, nil, { x, y, w, h }, nil, nil, nil, nil, nil, v.dwID)
						end
					end
					box:Show()
				end
				for i = 0, handle_equip:GetItemCount() - 1, 1 do
					local item = handle_equip:Lookup(i)
					if item and not item.bFree then
						local nUiId, bDelete = item:GetName(), true
						for kk ,vv in ipairs(v.tEquip) do
							if tostring(vv.nUiId) == nUiId then
								bDelete = false
								break
							end
						end
						if bDelete then
							h.hHandle_Equip.Pool:Remove(item)
						end
					end
				end
				handle_equip:FormatAllItemPos()
			end
			-- װ����
			local hScore = h:Lookup('Text_Score')
			if v.nEquipScore then
				hScore:SetText(v.nEquipScore)
			else
				if MY_TeamTools.szStatRange == 'ROOM' then
					hScore:SetText('-')
				elseif v.bIsOnLine then
					hScore:SetText(_L['Loading'])
				else
					hScore:SetText(g_tStrings.STR_GUILD_OFFLINE)
				end
			end
			-- �ؾ�CD
			if not h.hHandle_BossKills then
				h.hHandle_BossKills = {
					self = h:Lookup('Handle_BossKills'),
					Pool = X.UI.HandlePool(h:Lookup('Handle_BossKills'), '<handle>postype=8 eventid=784 w=16 h=14 <image>name="Image_BossKilled" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=20</image><image>name="Image_BossAlive" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=21</image></handle>')
				}
			end
			local hCopyID = h:Lookup('Text_CopyID')
			local hBossKills = h:Lookup('Handle_BossKills')
			if X.IsCDProgressMap(RT_MAP_ID) then
				for nIndex, bKill in ipairs(v.tBossKill) do
					local szName = tostring(nIndex)
					local hBossKill = hBossKills:Lookup(szName)
					if not hBossKill then
						hBossKill = h.hHandle_BossKills.Pool:New()
						hBossKill:SetName(szName)
					end
					hBossKill:Lookup('Image_BossAlive'):SetVisible(not bKill)
					hBossKill:Lookup('Image_BossKilled'):SetVisible(bKill)
					hBossKill.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local texts = {}
						for i, boss in ipairs(X.GetMapCDProgressInfo(RT_MAP_ID)) do
							table.insert(texts, boss.szName .. '\t' .. _L[v.tBossKill[i] and 'x' or 'r'])
						end
						OutputTip(GetFormatText(table.concat(texts, '\n')), 400, { x, y, w, h })
					end
					hBossKill:Show()
				end
				for i = 0, hBossKills:GetItemCount() - 1, 1 do
					local item = hBossKills:Lookup(i)
					if item and not item.bFree then
						if tonumber(item:GetName()) > #v.tBossKill then
							h.hHandle_BossKills.Pool:Remove(item)
						end
					end
				end
				hBossKills:FormatAllItemPos()
				hCopyID:Hide()
				hBossKills:Show()
			else
				hCopyID:SetText(v.nCopyID == -1 and _L['None'] or v.nCopyID or _L['Unknown'])
				hCopyID:Show()
				hBossKills:Hide()
			end
			-- ս��״̬
			if v.nFightState == 1 then
				h:Lookup('Image_Fight'):Show()
			else
				h:Lookup('Image_Fight'):Hide()
			end
		end
	end
	page.hPlayerList:FormatAllItemPos()
	for i = page.hPlayerList:GetItemCount() - 1, 0, -1 do
		local item = page.hPlayerList:Lookup(i)
		if item and item:IsValid() then
			if MY_TeamTools.szStatRange == 'RAID' then
				if not MY.IsParty(item.dwID) then
					page.hPlayerList:RemoveItem(item)
					page.hPlayerList:FormatAllItemPos()
				end
			elseif MY_TeamTools.szStatRange == 'ROOM' then
				if not MY.IsRoommate(item.szGlobalID) then
					page.hPlayerList:RemoveItem(item)
					page.hPlayerList:FormatAllItemPos()
				end
			end
		end
	end
	-- ����
	page.tScore = tScore
	local nScore = 0
	for k, v in pairs(tScore) do
		nScore = nScore + v
	end
	page.hTotalScore:SetText(math.floor(nScore))
	local nNum      = #D.GetMemberList(true)
	local nAvgScore = nScore / nNum
	page.hProgress:Lookup('Image_Progress'):SetPercentage(nAvgScore / RT_SCORE_FULL)
	page.hProgress:Lookup('Text_Progress'):SetText(_L('Team strength(%d/%d)', math.floor(nAvgScore), RT_SCORE_FULL))
	-- �ķ�ͳ��
	for k, kungfu in pairs(X.CONSTANT.KUNGFU_LIST) do
		local h = page.hKungfuList:Lookup(k - 1)
		local img = h:Lookup('Image_Force')
		local nCount = 0
		if tKungfu[kungfu.dwID] then
			nCount = #tKungfu[kungfu.dwID]
		end
		local szName, nIcon = MY_GetSkillName(kungfu.dwID)
		img:FromIconID(nIcon)
		h:Lookup('Text_Num'):SetText(nCount)
		if not tKungfu[kungfu.dwID] then
			h:SetAlpha(60)
			h.OnItemMouseEnter = nil
		else
			h:SetAlpha(255)
			h.OnItemMouseEnter = function()
				this:Lookup('Text_Num'):SetFontScheme(101)
				local xml = {}
				table.insert(xml, GetFormatText(szName .. g_tStrings.STR_COLON .. nCount .. g_tStrings.STR_PERSON ..'\n', 157))
				table.sort(tKungfu[kungfu.dwID], function(a, b)
					local nCountA = a.nEquipScore or -1
					local nCountB = b.nEquipScore or -1
					return nCountA > nCountB
				end)
				for k, v in ipairs(tKungfu[kungfu.dwID]) do
					if v.nEquipScore then
						table.insert(xml, GetFormatText(v.szName .. g_tStrings.STR_COLON ..  v.nEquipScore  ..'\n', 106))
					else
						table.insert(xml, GetFormatText(v.szName ..'\n', 106))
					end
				end
				local x, y = img:GetAbsPos()
				local w, h = img:GetSize()
				OutputTip(table.concat(xml), 400, { x, y, w, h })
			end
		end
	end
end

local function CreateItemTable(item, dwBox, dwX)
	return {
		nIcon     = X.GetItemIconByUIID(item.nUiId),
		dwID      = item.dwID,
		nLevel    = item.nLevel,
		szName    = X.GetItemNameByUIID(item.nUiId),
		nUiId     = item.nUiId,
		nVersion  = item.nVersion,
		dwTabType = item.dwTabType,
		dwIndex   = item.dwIndex,
		nQuality  = item.nQuality,
		dwBox     = dwBox,
		dwX       = dwX
	}
end

function D.GetEquipCache(page, KPlayer)
	if not KPlayer then
		return
	end
	local me = X.GetClientPlayer()
	local tInfo = {
		tEquip            = {},
		tPermanentEnchant = {},
		tTemporaryEnchant = {}
	}
	-- װ�� Output(X.GetInventoryItem(X.GetClientPlayer(),0,0).GetMagicAttrib())
	for _, equip in ipairs(RT_EQUIP_TOTAL) do
		-- if #tInfo.tEquip >= 3 then break end
		-- �ؽ�ֻ���ؽ�
		if KPlayer.dwForceID == 8 and X.CONSTANT.EQUIPMENT_INVENTORY[equip] == X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON then
			equip = 'BIG_SWORD'
		end
		local dwBox, dwX = INVENTORY_INDEX.EQUIP, X.CONSTANT.EQUIPMENT_INVENTORY[equip]
		local item = X.GetInventoryItem(KPlayer, dwBox, dwX)
		if item then
			if RT_EQUIP_SPECIAL[equip] then
				if item.dwSkillID ~= 0 then
					table.insert(tInfo.tEquip, CreateItemTable(item, dwBox, dwX))
				elseif equip == 'PENDANT' then
					local desc = Table_GetItemDesc(item.nUiId)
					if desc and (desc:find(_L['Use:']) or desc:find(_L['Use: ']) or desc:find('15 seconds')) then
						table.insert(tInfo.tEquip, CreateItemTable(item, dwBox, dwX))
					end
				-- elseif item.nQuality == 5 then -- ��ɫװ��
				-- 	table.insert(tInfo.tEquip, CreateItemTable(item))
				else
					-- ����װ��
					local aMagicAttrib = item.GetMagicAttrib()
					for _, tAttrib in ipairs(aMagicAttrib) do
						if tAttrib.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
							table.insert(tInfo.tEquip, CreateItemTable(item, dwBox, dwX))
							break
						end
					end
				end
			end
			-- ���õĸ�ħ ��������
			if item.dwPermanentEnchantID and item.dwPermanentEnchantID ~= 0 then
				table.insert(tInfo.tPermanentEnchant, {
					dwPermanentEnchantID = item.dwPermanentEnchantID,
				})
			end
			-- ��ħ / ��ʱ��ħ ��������
			if item.dwTemporaryEnchantID and item.dwTemporaryEnchantID ~= 0 then
				local dat = {
					dwTemporaryEnchantID         = item.dwTemporaryEnchantID,
					nTemporaryEnchantLeftSeconds = item.GetTemporaryEnchantLeftSeconds()
				}
				if X.Table.GetCommonEnchantDesc(item.dwTemporaryEnchantID) then
					dat.CommonEnchant = true
				end
				table.insert(tInfo.tTemporaryEnchant, dat)
			end
		end
	end
	-- ��Щ����һ���ԵĻ�������
	page.tDataCache[KPlayer.dwID] = {
		tEquip            = tInfo.tEquip,
		tPermanentEnchant = tInfo.tPermanentEnchant,
		tTemporaryEnchant = tInfo.tTemporaryEnchant,
		nEquipScore       = KPlayer.GetTotalEquipScore()
	}
	page.tViewInvite[KPlayer.dwID] = nil
	if X.IsEmpty(page.tViewInvite) then
		if KPlayer.dwID ~= me.dwID then
			FireUIEvent('MY_TEAM_TOOLS__SUMMARY__SUCCESS') -- װ���������
		end
	else
		ViewInviteToPlayer(next(page.tViewInvite), true)
	end
end

function D.ApplyRemotePlayerView(page, dwID)
	if not page.tViewInvite[dwID] then
		page.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID, true)
	end
end

function D.UpdateSelfData()
	local dwMapID = RT_MAP_ID
	local dwID = X.GetClientPlayerID()
	local szGlobalID = X.GetClientPlayerGlobalID()
	X.GetMapSaveCopy(function(tMapID)
		local aCopyID = tMapID[dwMapID]
		if not RT_PLAYER_MAP_COPY_ID[dwID] then
			RT_PLAYER_MAP_COPY_ID[dwID] = {}
		end
		if not RT_PLAYER_MAP_COPY_ID[szGlobalID] then
			RT_PLAYER_MAP_COPY_ID[szGlobalID] = {}
		end
		RT_PLAYER_MAP_COPY_ID[dwID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
		RT_PLAYER_MAP_COPY_ID[szGlobalID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
		FireUIEvent('MY_TEAM_TOOLS__SUMMARY__UPDATE')
	end)
	X.GetClientPlayerMapCDProgress(dwMapID, function(tProgress)
		if not RT_MAP_CD_PROGRESS[szGlobalID] then
			RT_MAP_CD_PROGRESS[szGlobalID] = {}
		end
		RT_MAP_CD_PROGRESS[szGlobalID][dwMapID] = tProgress
		FireUIEvent('MY_TEAM_TOOLS__SUMMARY__UPDATE')
	end)
end

function D.RequestTeamData()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local aRequestID, aRefreshID = {}, {}
	local bDungeonMap = X.IsDungeonMap(RT_MAP_ID)
	local bCDProgressMap = X.IsCDProgressMap(RT_MAP_ID)
	--[[#DEBUG BEGIN]]
	if MY_TeamTools.szStatRange == 'RAID' and bCDProgressMap then
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Update team map progress.', X.DEBUG_LEVEL.LOG)
	end
	--[[#DEBUG END]]
	local aMemberList = D.GetMemberList(true)
	if MY_TeamTools.szStatRange == 'RAID' then
		for _, tMember in ipairs(aMemberList) do
			if bCDProgressMap then -- �ؾ�����
				ApplyDungeonRoleProgress(RT_MAP_ID, tMember.dwID) -- �ɹ��ص� UPDATE_DUNGEON_ROLE_PROGRESS(dwMapID, dwPlayerID)
			elseif bDungeonMap then -- �ؾ�CDID
				if not RT_PLAYER_MAP_COPY_ID[tMember.dwID] then
					RT_PLAYER_MAP_COPY_ID[tMember.dwID] = {}
				end
				if RT_PLAYER_MAP_COPY_ID[tMember.dwID][RT_MAP_ID] then
					table.insert(aRefreshID, tMember.dwID)
				else
					table.insert(aRequestID, tMember.dwID)
				end
			end
		end
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		for _, tMember in ipairs(aMemberList) do
			if bDungeonMap then -- �ؾ�CDID
				if not RT_PLAYER_MAP_COPY_ID[tMember.szGlobalID] then
					RT_PLAYER_MAP_COPY_ID[tMember.szGlobalID] = {}
				end
				if not RT_MAP_CD_PROGRESS[tMember.szGlobalID] then
					RT_MAP_CD_PROGRESS[tMember.szGlobalID] = {}
				end
				if RT_PLAYER_MAP_COPY_ID[tMember.szGlobalID][RT_MAP_ID]
				and RT_MAP_CD_PROGRESS[tMember.szGlobalID][RT_MAP_ID] then
					table.insert(aRefreshID, tMember.szGlobalID)
				else
					table.insert(aRequestID, tMember.szGlobalID)
				end
			end
		end
	end
	if not X.IsEmpty(aRequestID) or not X.IsEmpty(aRefreshID) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'Request team map copy id.', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		if #aRequestID == #aMemberList then
			aRequestID = nil
		end
		if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
			X.OutputSystemAnnounceMessage(_L['Fetch teammate\'s data failed, please unlock talk and reopen.'])
		else
			local nChannel = MY_TeamTools.szStatRange == 'RAID'
				and PLAYER_TALK_CHANNEL.RAID
				or PLAYER_TALK_CHANNEL.ROOM
			X.SendBgMsg(nChannel, 'MY_TEAM_TOOLS__MAP_CD_REQ', {RT_MAP_ID, aRequestID, nil})
		end
	end
	-- ˢ���Լ���
	D.UpdateSelfData()
end

-- ��ȡ�ŶӴ󲿷���� �ǻ���
function D.GetTeamData(page)
	local me    = X.GetClientPlayer()
	local team  = GetClientTeam()
	local aList = {}
	local bIsInParty = X.IsInParty()
	local bCDProgressMap = X.IsCDProgressMap(RT_MAP_ID)
	local aProgressMapBoss = bCDProgressMap and X.GetMapCDProgressInfo(RT_MAP_ID)
	local aRequestMapCopyID = {}
	local aMemberList = D.GetMemberList()
	for _, tMember in ipairs(aMemberList) do
		local KPlayer = MY_TeamTools.szStatRange == 'RAID' and X.GetPlayer(tMember.dwID)
		local tInfo = {
			KPlayer           = KPlayer,
			szName            = tMember.szName or _L['Loading...'],
			dwID              = tMember.dwID,  -- ID
			szGlobalID        = tMember.szGlobalID,
			dwForceID         = tMember.dwForceID, -- ����ID
			dwMountKungfuID   = tMember.dwKungfuID, -- �ڹ�
			-- tPermanentEnchant = {}, -- ��ħ
			-- tTemporaryEnchant = {}, -- ��ʱ��ħ
			-- tEquip            = {}, -- ��Чװ��
			tBuff             = {}, -- ����BUFF
			tFood             = {}, -- С�Ժ͸�ħ
			nEquipScore       = tMember.nEquipScore, -- װ���֣��� ROOM ����ֵ
			nCopyID           = nil, -- �ؾ�ID
			tBossKill         = {}, -- �ؾ�����
			nFightState       = KPlayer and KPlayer.bFightState and 1 or 0, -- ս��״̬
			bIsOnLine         = true,
			bGrandpa          = false, -- ��ү
		}
		if tMember.bOnline ~= nil then
			tInfo.bIsOnLine = tMember.bOnline
		end
		if KPlayer then
			-- С�Ժ�buff
			local nType
			for _, buff in X.ipairs_c(X.GetBuffList(KPlayer)) do
				nType = GetBuffInfo(buff.dwID, buff.nLevel, {}).nDetachType or 0
				if RT_FOOD_TYPE[nType] then
					table.insert(tInfo.tFood, buff)
				end
				if RT_BUFF_ID[buff.dwID] then
					table.insert(tInfo.tBuff, buff)
				end
				if buff.dwID == RT_GZ_BUFF_ID then -- grandpa
					tInfo.bGrandpa = true
				end
			end
			if me.dwID == KPlayer.dwID then
				D.GetEquipCache(page, me)
			end
		end
		-- �ؾ�����
		if MY_TeamTools.szStatRange == 'RAID' then
			if tInfo.bIsOnLine and bCDProgressMap then
				for i, boss in ipairs(aProgressMapBoss) do
					tInfo.tBossKill[i] = GetDungeonRoleProgress(RT_MAP_ID, tMember.dwID, boss.dwProgressID)
				end
			end
			tInfo.nCopyID = X.Get(RT_PLAYER_MAP_COPY_ID, {tMember.dwID, RT_MAP_ID})
		elseif MY_TeamTools.szStatRange == 'ROOM' then
			if bCDProgressMap then
				for i, boss in ipairs(aProgressMapBoss) do
					tInfo.tBossKill[i] = X.Get(RT_MAP_CD_PROGRESS, {tMember.szGlobalID, RT_MAP_ID, boss.dwProgressID})
				end
			end
			tInfo.nCopyID = X.Get(RT_PLAYER_MAP_COPY_ID, {tMember.szGlobalID, RT_MAP_ID})
		end
		setmetatable(tInfo, { __index = page.tDataCache[tMember.dwID] })
		table.insert(aList, tInfo)
	end
	return aList
end

function D.ApplyTeamEquip(page)
	if MY_TeamTools.szStatRange == 'RAID' then
		local hView = D.GetPlayerView()
		if hView and hView:IsVisible() then -- �鿴װ����ʱ��ֹͣ����
			return
		end
		local team = GetClientTeam()
		for _, tMember in ipairs(D.GetMemberList()) do
			if tMember.dwID ~= X.GetClientPlayerID() then
				local info = team.GetMemberInfo(tMember.dwID)
				if info.bIsOnLine then
					D.ApplyRemotePlayerView(page, tMember.dwID)
				end
			end
		end
	end
end

-- ��ȡ�Ŷӳ�Ա�б�
function D.GetMemberList(bIsOnLine)
	local aList = {}
	if MY_TeamTools.szStatRange == 'RAID' then
		for _, dwID in ipairs(X.GetTeamMemberList()) do
			local tMember = X.GetTeamMemberInfo(dwID)
			if tMember and (not bIsOnLine or tMember.bOnline) then
				table.insert(aList, {
					dwID = tMember.dwID,
					szGlobalID = tMember.szGlobalID,
					szName = tMember.szName,
					dwForceID = tMember.dwForceID,
					dwKungfuID = tMember.dwKungfuID,
					bOnline = tMember.bOnline,
				})
			end
		end
	elseif MY_TeamTools.szStatRange == 'ROOM' then
		for _, szGlobalID in ipairs(X.GetRoomMemberList()) do
			local tMember = X.GetRoomMemberInfo(szGlobalID)
			local szServerName = tMember and X.GetServerNameByID(tMember.dwServerID)
			if tMember and szServerName then
				table.insert(aList, {
					szGlobalID = tMember.szGlobalID,
					szName = tMember.szName .. g_tStrings.STR_CONNECT .. szServerName,
					dwForceID = tMember.dwForceID,
					dwKungfuID = tMember.dwKungfuID,
					nEquipScore = tMember.nEquipScore,
				})
			end
		end
	end
	return aList
end

function D.SetMapByRoomInfo()
	if MY_TeamTools.szStatRange ~= 'ROOM' then
		return
	end
	local tInfo = X.GetRoomInfo()
	if tInfo then
		D.SetMapID(tInfo.nTargetMapID)
	end
end

function D.SetMapID(dwMapID)
	if RT_MAP_ID == dwMapID then
		return
	end
	RT_MAP_ID = dwMapID
	FireUIEvent('MY_TEAM_TOOLS__SUMMARY__MAP_ID_CHANGE')
end

X.RegisterEvent('LOADING_END', function()
	D.SetMapID(X.GetClientPlayer().GetMapID())
end)

X.RegisterBgMsg('MY_TEAM_TOOLS__MAP_CD_RES', function(_, data, nChannel, dwID, szName, bIsSelf)
	local szGlobalID, dwMapID, aCopyID, tProgress = data[1], data[2], data[3], data[4]
	if not RT_PLAYER_MAP_COPY_ID[dwID] then
		RT_PLAYER_MAP_COPY_ID[dwID] = {}
	end
	RT_PLAYER_MAP_COPY_ID[dwID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
	if not RT_PLAYER_MAP_COPY_ID[szGlobalID] then
		RT_PLAYER_MAP_COPY_ID[szGlobalID] = {}
	end
	RT_PLAYER_MAP_COPY_ID[szGlobalID][dwMapID] = X.IsTable(aCopyID) and aCopyID[1] or -1
	if X.IsCDProgressMap(dwMapID) then
		if not RT_MAP_CD_PROGRESS[szGlobalID] then
			RT_MAP_CD_PROGRESS[szGlobalID] = {}
		end
		RT_MAP_CD_PROGRESS[szGlobalID][dwMapID] = X.IsTable(tProgress) and tProgress or nil
	end
	FireUIEvent('MY_TEAM_TOOLS__SUMMARY__UPDATE')
end)

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(SZ_INI, 'MY_TeamTools_Summary')
	local wnd = frameTemp:Lookup('Wnd_Summary')
	wnd:ChangeRelation(this, true, true)
	X.UI.CloseFrame(frameTemp)

	local page = this
	local frame = page:GetRoot()
	frame:RegisterEvent('PEEK_OTHER_PLAYER')
	frame:RegisterEvent('PARTY_ADD_MEMBER')
	frame:RegisterEvent('PARTY_DISBAND')
	frame:RegisterEvent('PARTY_DELETE_MEMBER')
	frame:RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG')
	frame:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
	frame:RegisterEvent('UPDATE_DUNGEON_ROLE_PROGRESS')
	frame:RegisterEvent('LOADING_END')
	frame:RegisterEvent('GLOBAL_ROOM_DETAIL_INFO')
	-- �ų���� ���������ǩ
	frame:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	-- �Զ����¼�
	frame:RegisterEvent('MY_TEAM_TOOLS__MODE_CHANGE')
	frame:RegisterEvent('MY_TEAM_TOOLS__SUMMARY__UPDATE')
	frame:RegisterEvent('MY_TEAM_TOOLS__SUMMARY__SUCCESS')
	frame:RegisterEvent('MY_TEAM_TOOLS__SUMMARY__MAP_ID_CHANGE')
	-- �����ķ�ѡ��
	RT_SELECT_KUNGFU = nil
	local hPlayerList = page:Lookup('Wnd_Summary/Scroll_Player', '')
	local hSummaryTotal = page:Lookup('Wnd_Summary', '')
	page.hPlayerList = hPlayerList
	page.hItemDataPlayer = frame:CreateItemData(SZ_INI, 'Handle_Item_Player')

	page.tScore = {}
	-- ����
	local hTitle = page:Lookup('Wnd_Summary', 'Handle_Player_BG')
	for k, v in ipairs({'dwForceID', 'tFood', 'tBuff', 'tEquip', 'nEquipScore', 'tBossKill', 'nFightState'}) do
		local txt = hTitle:Lookup('Text_Title_' .. k)
		txt.nFont = txt:GetFontScheme()
		txt.OnItemMouseEnter = function()
			this:SetFontScheme(101)
		end
		txt.OnItemMouseLeave = function()
			this:SetFontScheme(this.nFont)
		end
		txt.OnItemLButtonClick = function()
			if v == RT_SORT_FIELD then
				RT_SORT_MODE = RT_SORT_MODE == 'ASC' and 'DESC' or 'ASC'
			else
				RT_SORT_MODE = 'DESC'
			end
			RT_SORT_FIELD = v
			D.UpdateList(page) -- set userdata
			page.hPlayerList:Sort()
			page.hPlayerList:FormatAllItemPos()
		end
	end
	-- װ����
	page.hTotalScore = page:Lookup('Wnd_Summary', 'Handle_Score/Text_TotalScore')
	page.hProgress   = page:Lookup('Wnd_Summary', 'Handle_Progress')
	-- �ؾ���Ϣ
	local hDungeon = page:Lookup('Wnd_Summary', 'Handle_Dungeon')
	local hKungfu = page:Lookup('Wnd_Summary', 'Handle_Kungfu')
	D.UpdateDungeonInfo(hDungeon)
	local hKungfuList     = page:Lookup('Wnd_Summary', 'Handle_Kungfu/Handle_Kungfu_List')
	local hItemDataKungfu = frame:CreateItemData(SZ_INI, 'Handle_Kungfu_Item')
	hKungfuList:Clear()
	for k, kungfu in pairs(X.CONSTANT.KUNGFU_LIST) do
		local h = hKungfuList:AppendItemFromData(hItemDataKungfu, kungfu.dwID)
		local img = h:Lookup('Image_Force')
		img:FromIconID(select(2, MY_GetSkillName(kungfu.dwID)))
		h:Lookup('Text_Num'):SetText(0)
		h.nFont = h:Lookup('Text_Num'):GetFontScheme()
		h.OnItemMouseLeave = function()
			HideTip()
			if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
				this:Lookup('Text_Num'):SetFontScheme(101)
			else
				this:Lookup('Text_Num'):SetFontScheme(h.nFont)
			end
		end
		h.OnItemLButtonClick = function()
			if this:GetAlpha() ~= 255 then
				return
			end
			page.hPlayerList:Clear()
			if RT_SELECT_KUNGFU then
				if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
					RT_SELECT_KUNGFU = nil
					h:Lookup('Text_Num'):SetFontScheme(101)
					return D.UpdateList(page)
				else
					local h = this:GetParent():Lookup(tostring(RT_SELECT_KUNGFU))
					h:Lookup('Text_Num'):SetFontScheme(h.nFont)
				end
			end
			RT_SELECT_KUNGFU = tonumber(this:GetName())
			this:Lookup('Text_Num'):SetFontScheme(101)
			D.UpdateList(page)
		end
	end
	hKungfuList:FormatAllItemPos()
	local nH = select(2, hKungfuList:GetAllItemSize())
	hKungfuList:SetH(nH)
	hKungfu:SetH(nH + 10)
	hDungeon:SetRelY(hKungfu:GetRelY() + nH + 10)
	hSummaryTotal:FormatAllItemPos()
	page.hKungfuList = hKungfuList
	-- ui ��ʱ����
	page.tViewInvite = {} -- ����װ������
	page.tDataCache  = {} -- ��ʱ����
	-- lang
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_3'):SetText(_L['BUFF'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_4'):SetText(_L['Equip'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_6'):SetText(_L['Dungeon CD'])
	page:Lookup('Wnd_Summary', 'Handle_Player_BG/Text_Title_7'):SetText(_L['Fight'])
end

function D.OnActivePage()
	local hView = D.GetPlayerView()
	if hView and hView:IsVisible() then
		hView:Hide()
	end
	X.BreatheCall('MY_RaidTools_Draw', 1000, D.UpdateList, this)
	X.BreatheCall('MY_RaidTools_RequestMemberEquip', 3000, D.ApplyTeamEquip, this)
	X.BreatheCall('MY_RaidTools_RequestTeamData', 30000, D.RequestTeamData, this)
end

function D.OnDeactivePage()
	X.BreatheCall('MY_RaidTools_Draw', false)
	X.BreatheCall('MY_RaidTools_RequestMemberEquip', false)
	X.BreatheCall('MY_RaidTools_RequestTeamData', false)
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TEAM_TOOLS__SUMMARY__UPDATE' then
		D.UpdateList(this)
	elseif szEvent == 'UPDATE_DUNGEON_ROLE_PROGRESS' then
		D.UpdateList(this)
	elseif szEvent == 'PEEK_OTHER_PLAYER' then
		if arg0 == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			if this.tViewInvite[arg1] then
				D.GetEquipCache(this, X.GetPlayer(arg1)) -- ץȡ��������
			end
		else
			this.tViewInvite[arg1] = nil
		end
	elseif szEvent == 'PARTY_SET_MEMBER_ONLINE_FLAG' then
		if arg2 == 0 then
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'PARTY_DELETE_MEMBER' then
		local me = X.GetClientPlayer()
		if me.dwID == arg1 then
			this.tDataCache = {}
			this.hPlayerList:Clear()
		else
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'LOADING_END' or szEvent == 'PARTY_DISBAND' then
		this.tDataCache = {}
		this.hPlayerList:Clear()
		-- �ؾ���Ϣ
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'MY_TEAM_TOOLS__SUMMARY__MAP_ID_CHANGE' then
		D.RequestTeamData() -- ��ͼ�仯ˢ��
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'ON_APPLY_PLAYER_SAVED_COPY_RESPOND' then
		local hDungeon = this:Lookup('Wnd_Summary', 'Handle_Dungeon')
		D.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'MY_TEAM_TOOLS__SUMMARY__SUCCESS' then
		if RT_SORT_FIELD == 'nEquipScore' then
			D.UpdateList(this)
			this.hPlayerList:Sort()
			this.hPlayerList:FormatAllItemPos()
		end
	elseif szEvent == 'MY_TEAM_TOOLS__MODE_CHANGE' then
		D.SetMapByRoomInfo()
		D.RequestTeamData()
		D.UpdateList(this)
	elseif szEvent == 'GLOBAL_ROOM_DETAIL_INFO' then
		D.SetMapByRoomInfo()
	end
end

function D.OnLButtonClick()
end

function D.OnItemMouseEnter()
	local szName = this:GetName()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(true)
	elseif szName == 'Handle_Score' then
		local img = this:Lookup('Image_Score')
		img:SetFrame(23)
		local nScore = this:Lookup('Text_TotalScore'):GetText()
		local xml = {}
		table.insert(xml, GetFormatText(g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. nScore ..'\n', 65))
		for k, v in pairs(this:GetParent():GetParent():GetParent().tScore) do
			table.insert(xml, GetFormatText(RT_SCORE[k] .. g_tStrings.STR_COLON, 67))
			table.insert(xml, GetFormatText(v ..'\n', 44))
		end
		local x, y = img:GetAbsPos()
		local w, h = img:GetSize()
		OutputTip(table.concat(xml), 400, { x, y, w, h })
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(false)
	elseif szName == 'Handle_Score' then
		this:Lookup('Image_Score'):SetFrame(22)
	end
	HideTip()
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_Dungeon' then
		if MY_TeamTools.szStatRange == 'ROOM' then
			X.OutputAnnounceMessage(_L['Room stat map will follow system room dest, cannot be customized.'])
			return
		end
		local menu = X.GetDungeonMenu({
			fnAction = function(p)
				D.SetMapID(p.dwID)
			end,
		})
		menu.x, menu.y = Cursor.GetPos(true)
		PopupMenu(menu)
	elseif tonumber(szName:find('P(%d+)')) then
		local dwID = tonumber(szName:match('P(%d+)'))
		if IsCtrlKeyDown() then
			X.EditBox_AppendLinkPlayer(this.szName)
		else
			D.ViewInviteToPlayer(this:GetParent():GetParent():GetParent():GetParent(), dwID)
		end
	end
end

function D.OnItemRButtonClick()
	local szName = this:GetName()
	local dwID = tonumber(szName:match('P(%d+)'))
	local me = X.GetClientPlayer()
	if dwID and dwID ~= me.dwID then
		local page = this:GetParent():GetParent():GetParent():GetParent()
		local menu = {
			{ szOption = this.szName, bDisable = true },
			{ bDevide = true }
		}
		InsertPlayerCommonMenu(menu, dwID, this.szName)
		menu[#menu] = {
			szOption = g_tStrings.STR_LOOKUP, fnAction = function()
				D.ViewInviteToPlayer(page, dwID)
			end
		}
		local t = {}
		InsertTargetMenu(t, dwID)
		for _, v in ipairs(t) do
			if v.szOption == g_tStrings.LOOKUP_INFO or v.szOption == g_tStrings.STR_LOOKUP_MORE then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then
						table.insert(menu, vv)
						break
					end
				end
				break
			end
		end
		if MY_CharInfo and MY_CharInfo.ViewCharInfoToPlayer then
			menu[#menu + 1] = {
				szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR, fnAction = function()
					MY_CharInfo.ViewCharInfoToPlayer(dwID)
				end
			}
		end
		PopupMenu(menu)
	end
end

-- Module exports
do
local settings = {
	name = 'MY_TeamTools_Summary_Module',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnDeactivePage',
				bStatRange = true,
			},
			root = D,
		},
	},
}
MY_TeamTools.RegisterModule('Summary', _L['MY_TeamTools_Summary'], X.CreateModule(settings))
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
