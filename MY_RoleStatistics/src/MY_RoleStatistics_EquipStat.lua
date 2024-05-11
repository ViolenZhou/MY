--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : װ��ͳ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_RoleStatistics/MY_RoleStatistics_EquipStat'
local PLUGIN_NAME = 'MY_RoleStatistics'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_RoleStatistics_EquipStat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^20.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

CPath.MakeDir(X.FormatPath({'userdata/role_statistics', X.PATH_TYPE.GLOBAL}))

local DB = X.SQLiteConnect(_L['MY_RoleStatistics_EquipStat'], {'userdata/role_statistics/equip_stat.v3.db', X.PATH_TYPE.GLOBAL})
if not DB then
	return X.Sysmsg(_L['MY_RoleStatistics_EquipStat'], _L['Cannot connect to database!!!'], X.CONSTANT.MSG_THEME.ERROR)
end
local SZ_INI = X.PACKET_INFO.ROOT .. 'MY_RoleStatistics/ui/MY_RoleStatistics_EquipStat.ini'

DB:Execute([[
	CREATE TABLE IF NOT EXISTS EquipItems (
		ownerkey NVARCHAR(20) NOT NULL,
		suitindex INTEGER NOT NULL,
		boxtype INTEGER NOT NULL,
		boxindex INTEGER NOT NULL,
		itemid INTEGER NOT NULL,
		tabtype INTEGER NOT NULL,
		tabindex INTEGER NOT NULL,
		tabsubindex INTEGER NOT NULL,
		stacknum INTEGER NOT NULL,
		uiid INTEGER NOT NULL,
		strength INTEGER NOT NULL,
		durability INTEGER NOT NULL,
		diamond_enchant NVARCHAR(100) NOT NULL,
		fea_enchant INTEGER NOT NULL,
		permanent_enchant INTEGER NOT NULL,
		desc NVARCHAR(4000) NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(ownerkey, boxtype, boxindex)
	)
]])
DB:Execute('CREATE INDEX IF NOT EXISTS EquipItems_tab_idx ON EquipItems(tabtype, tabindex, tabsubindex)')
local DB_ItemsW = DB:Prepare([[
	REPLACE INTO
	EquipItems (ownerkey, suitindex, boxtype, boxindex, itemid, tabtype, tabindex, tabsubindex, stacknum, uiid, strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc, extra, time, extra)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]])
local DB_ItemsR = DB:Prepare('SELECT * FROM EquipItems WHERE ownerkey = ? and suitindex = ?')
local DB_ItemsDL = DB:Prepare('DELETE FROM EquipItems WHERE ownerkey = ? AND boxtype = ? AND boxindex >= ?')
local DB_ItemsDA = DB:Prepare('DELETE FROM EquipItems WHERE ownerkey = ?')

DB:Execute([[
	CREATE TABLE IF NOT EXISTS OwnerInfo (
		ownerkey NVARCHAR(20) NOT NULL,
		ownername NVARCHAR(20) NOT NULL,
		servername NVARCHAR(20) NOT NULL,
		ownerforce INTEGER NOT NULL,
		ownerrole INTEGER NOT NULL,
		ownerlevel INTEGER NOT NULL,
		ownerscore NVARCHAR(100) NOT NULL,
		ownersuitindex INTEGER NOT NULL,
		time INTEGER NOT NULL,
		extra TEXT NOT NULL,
		PRIMARY KEY(ownerkey)
	)
]])
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_ownername_idx ON OwnerInfo(ownername)')
DB:Execute('CREATE INDEX IF NOT EXISTS OwnerInfo_servername_idx ON OwnerInfo(servername)')
local DB_OwnerInfoW = DB:Prepare('REPLACE INTO OwnerInfo (ownerkey, ownername, servername, ownerforce, ownerrole, ownerlevel, ownerscore, ownersuitindex, time, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
local DB_OwnerInfoR = DB:Prepare('SELECT * FROM OwnerInfo WHERE ownername LIKE ? OR servername LIKE ? ORDER BY time DESC')
local DB_OwnerInfoG = DB:Prepare('SELECT * FROM OwnerInfo WHERE ownerkey = ?')
local DB_OwnerInfoD = DB:Prepare('DELETE FROM OwnerInfo WHERE ownerkey = ?')

local EQUIPMENT_ITEM_LIST = {
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.HELM or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.HELM,
		box = 'Handle_Equip/Box_Helm',
		durability = 'Handle_Equip/Text_Helm',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.CHEST or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.CHEST,
		box = 'Handle_Equip/Box_Chest',
		durability = 'Handle_Equip/Text_Chest',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.BANGLE or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.BANGLE,
		box = 'Handle_Equip/Box_Bangle',
		durability = 'Handle_Equip/Text_Bangle',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.WAIST or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.WAIST,
		box = 'Handle_Equip/Box_Waist',
		durability = 'Handle_Equip/Text_Waist',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.PANTS or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.PANTS,
		box = 'Handle_Equip/Box_Pants',
		durability = 'Handle_Equip/Text_Pants',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.BOOTS or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.BOOTS,
		box = 'Handle_Equip/Box_Boots',
		durability = 'Handle_Equip/Text_Boots',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.AMULET or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.AMULET,
		box = 'Handle_Equip/Box_Amulet'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.PENDANT or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.PENDANT,
		box = 'Handle_Equip/Box_Pendant'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.RING or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.LEFT_RING,
		box = 'Handle_Equip/Box_LeftRing'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.RING or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.RIGHT_RING,
		box = 'Handle_Equip/Box_RightRing'
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON,
		box = 'Handle_Weapon/Box_LightSword',
		durability = 'Handle_Weapon/Text_LightSword',
	},
	{
		label = g_tStrings.WeapenDetail[WEAPON_DETAIL.BIG_SWORD or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.BIG_SWORD,
		box = 'Handle_Weapon/Box_HeavySword',
		durability = 'Handle_Weapon/Text_HeavySword',
		background = 'Handle_Weapon/Image_HeavySword',
		force = X.CONSTANT.FORCE_TYPE.CANG_JIAN or -1,
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.RANGE_WEAPON,
		box = 'Handle_Weapon/Box_RangeWeapon',
		durability = 'Handle_Weapon/Text_RangeWeapon',
	},
	{
		label = g_tStrings.tEquipTypeNameTable[X.CONSTANT.EQUIPMENT_SUB.ARROW or 'NULL'],
		pos = X.CONSTANT.EQUIPMENT_INVENTORY.ARROW,
		box = 'Handle_Weapon/Box_AmmoPouch'
	},
}
local EQUIPMENT_EXTRA_ITEM_LIST = {
	{ key = 'waist'    , box = 'Handle_Equip/Box_Waist_Extend'     }, -- EQUIPMENT_SUB.WAIST_EXTEND
	{ key = 'back'     , box = 'Handle_Equip/Box_Back_Extend'      }, -- EQUIPMENT_SUB.BACK_EXTEND
	{ key = 'face'     , box = 'Handle_Equip/Box_Helm_Extend'      }, -- EQUIPMENT_SUB.FACE_EXTEND
	{ key = 'lshoulder', box = 'Handle_Equip/Box_LShoulder_Extend' }, -- EQUIPMENT_SUB.L_SHOULDER_EXTEND
	{ key = 'rshoulder', box = 'Handle_Equip/Box_RShoulder_Extend' }, -- EQUIPMENT_SUB.R_SHOULDER_EXTEND
	{ key = 'backcloak', box = 'Handle_Equip/Box_BackCloak_Extend' }, -- EQUIPMENT_SUB.BACK_CLOAK_EXTEND
	{ key = 'bag'      , box = 'Handle_Equip/Box_Bag'              }, -- EQUIPMENT_SUB.BAG_EXTEND
	{ key = 'glasses'  , box = 'Handle_Equip/Box_Glasses'          }, -- EQUIPMENT_SUB.GLASSES_EXTEND
	{ key = 'lglove'   , box = 'Handle_Equip/Box_LHand_Extend'     }, -- EQUIPMENT_SUB.L_GLOVE_EXTEND
	{ key = 'rglove'   , box = 'Handle_Equip/Box_RHand_Extend'     }, -- EQUIPMENT_SUB.R_GLOVE_EXTEND
	{ key = 'penpet'   , box = 'Handle_Equip/Box_PendantPet'       }, --
}

local O = X.CreateUserSettingsModule('MY_RoleStatistics_EquipStat', _L['General'], {
	bCompactMode = {
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceFloatEntry = {
		ePathType = X.PATH_TYPE.ROLE,
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAdviceSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_RoleStatistics'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	szCurrentOwnerKey = nil,
	dwCurrentSuitIndex = 1,
}

local function GetEquipRecipeDesc(Value1, Value2)
	local szText = ''
	local EquipmentRecipe = X.GetGameTable('EquipmentRecipe', true)
	if EquipmentRecipe then
		local tRecipeSkillAtrri = EquipmentRecipe:Search(Value1, Value2)
		if tRecipeSkillAtrri then
			szText = tRecipeSkillAtrri.szDesc
		end
	end
	return szText
end

function D.FormatEnchantAttribText(v)
	if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
		local SkillEvent = X.GetGameTable('SkillEvent', true)
		if SkillEvent then
			local skillEvent = SkillEvent:Search(v.nValue1)
			if skillEvent then
				return FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
			end
		end
		return '<text>text="unknown skill event id:' .. v.nValue1 .. '"</text>'
	elseif v.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then
		return GetEquipRecipeDesc(v.nValue1, v.nValue2)
	else
		FormatAttributeValue(v)
		return FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
	end
end

function D.Migration()
	local DB_V2_PATH = X.FormatPath({'userdata/role_statistics/equip_stat.v2.db', X.PATH_TYPE.GLOBAL})
	if not IsLocalFileExist(DB_V2_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- ת��V2�ɰ�����
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					DB:Execute('BEGIN TRANSACTION')
					local aEquipItems = DB_V2:Execute('SELECT * FROM EquipItems WHERE ownerkey IS NOT NULL AND suitindex IS NOT NULL AND boxtype IS NOT NULL')
					if aEquipItems then
						for _, rec in ipairs(aEquipItems) do
							DB_ItemsW:ClearBindings()
							DB_ItemsW:BindAll(
								rec.ownerkey,
								rec.suitindex,
								rec.boxtype,
								rec.boxindex,
								rec.itemid,
								rec.tabtype,
								rec.tabindex,
								rec.tabsubindex,
								rec.stacknum,
								rec.uiid,
								rec.strength,
								rec.durability,
								rec.diamond_enchant,
								rec.fea_enchant,
								rec.permanent_enchant,
								rec.desc,
								rec.extra,
								rec.time,
								''
							)
							DB_ItemsW:Execute()
						end
						DB_ItemsW:Reset()
					end
					local aOwnerInfo = DB_V2:Execute('SELECT * FROM OwnerInfo WHERE ownerkey IS NOT NULL AND ownername IS NOT NULL AND servername IS NOT NULL')
					if aOwnerInfo then
						for _, rec in ipairs(aOwnerInfo) do
							DB_OwnerInfoW:ClearBindings()
							DB_OwnerInfoW:BindAll(
								rec.ownerkey,
								rec.ownername,
								rec.servername,
								rec.ownerforce,
								rec.ownerrole,
								rec.ownerlevel,
								'',
								rec.ownersuitindex,
								rec.time,
								''
							)
							DB_OwnerInfoW:Execute()
						end
						DB_OwnerInfoW:Reset()
					end
					DB:Execute('END TRANSACTION')
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			FireUIEvent('MY_ROLE_STAT_EQUIP_UPDATE')
			X.Alert(_L['Migrate succeed!'])
		end)
end

local REC_CACHE
X.RegisterEvent({'EQUIP_CHANGE', 'EQUIP_ITEM_UPDATE'}, 'MY_RoleStatistics_EquipStat', function()
	X.DelayCall('MY_RoleStatistics_EquipStat_GetScore', 100, function()
		if not REC_CACHE then
			return
		end
		local me = X.GetClientPlayer()
		local ownersuitindex = me.GetEquipIDArray(0) + 1
		REC_CACHE.ownerscore[ownersuitindex] = me.GetTotalEquipScore() or 0
	end)
end)

function D.FlushDB()
	if not O.bSaveDB then
		return
	end
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local me = X.GetClientPlayer()
	local time = GetCurrentTime()
	local ownerkey = AnsiToUTF8(X.GetPlayerGUID())
	local ownername = AnsiToUTF8(me.szName)
	local servername = AnsiToUTF8(X.GetServerOriginName())
	local rec = REC_CACHE
	if not rec then
		rec = {
			ownerscore = {},
		}
		DB_OwnerInfoG:ClearBindings()
		DB_OwnerInfoG:BindAll(ownerkey)
		local result = DB_OwnerInfoG:GetAll()
		DB_OwnerInfoG:Reset()
		if result and result[1] and result[1].ownerscore then
			local d = X.DecodeLUAData(result[1].ownerscore)
			if X.IsTable(d) then
				rec.ownerscore = d
			end
		end
		REC_CACHE = rec
	end
	local ownerforce = 0
	local ownerrole = 0
	local ownerlevel = 0
	local ownerscore = rec.ownerscore
	local ownersuitindex = 0
	local ownerextra = ''
	DB:Execute('BEGIN TRANSACTION')

	-- ����
	local tSuitIndexToBoxType = {}
	for suitindex, boxtype in ipairs(X.CONSTANT.INVENTORY_EQUIP_LIST) do
		tSuitIndexToBoxType[me.GetEquipIDArray(suitindex - 1) + 1] = boxtype
	end
	for suitindex, _ in ipairs(X.CONSTANT.INVENTORY_EQUIP_LIST) do
		local boxtype = tSuitIndexToBoxType[suitindex]
		if boxtype then
			local count = X.GetInventoryBoxSize(boxtype)
			for boxindex = 0, count - 1 do
				local KItem = X.GetInventoryItem(me, boxtype, boxindex)
				DB_ItemsW:ClearBindings()
				local itemid, tabtype, tabindex, tabsubindex = -1, -1, -1, -1
				local stacknum, uiid, strength, durability = 0, 0, 0, 0
				local diamond_enchant, fea_enchant, permanent_enchant, desc, extra = 0, 0, 0, '', ''
				if KItem then
					local aDiamondEnchant = {}
					for i = 1, KItem.GetSlotCount() do
						aDiamondEnchant[i] = X.GetItemMountDiamondEnchantID(KItem, i - 1)
					end
					itemid = KItem.dwID
					tabtype = KItem.dwTabType
					tabindex = KItem.dwIndex
					tabsubindex = KItem.nGenre == ITEM_GENRE.BOOK and KItem.nBookID or -1
					stacknum = KItem.bCanStack and KItem.nStackNum or 1
					uiid = KItem.nUiId
					strength = X.GetItemStrengthLevel(KItem, me)
					durability = KItem.nCurrentDurability
					diamond_enchant = AnsiToUTF8(X.EncodeJSON(aDiamondEnchant)) -- ����ʯ
					fea_enchant = KItem.nSub == EQUIPMENT_SUB.MELEE_WEAPON and KItem.GetMountFEAEnchantID() or 0 -- ���ʯ
					permanent_enchant = KItem.dwPermanentEnchantID -- ��ħ
					desc = AnsiToUTF8(X.GetItemTip(KItem) or '')
				end
				DB_ItemsW:BindAll(
					ownerkey, suitindex, boxtype, boxindex, itemid,
					tabtype, tabindex, tabsubindex, stacknum, uiid,
					strength, durability, diamond_enchant, fea_enchant, permanent_enchant, desc, extra, time, '')
				DB_ItemsW:Execute()
			end
			DB_ItemsDL:ClearBindings()
			DB_ItemsDL:BindAll(ownerkey, boxtype, count)
			DB_ItemsDL:Execute()
		end
	end
	DB_ItemsW:Reset()
	DB_ItemsDL:Reset()

	-- ���Ρ�����
	ownerforce = me.dwForceID
	ownerrole = me.nRoleType
	ownerlevel = me.nLevel
	ownersuitindex = me.GetEquipIDArray(0) + 1
	ownerscore[ownersuitindex] = me.GetTotalEquipScore() or 0
	ownerextra = AnsiToUTF8(X.EncodeJSON({
		waist = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwWaistItemIndex) },
		back = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwBackItemIndex) },
		face = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwFaceItemIndex) },
		lshoulder = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwLShoulderItemIndex) },
		rshoulder = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwRShoulderItemIndex) },
		backcloak = { ITEM_TABLE_TYPE.CUST_TRINKET, (me.dwBackCloakItemIndex) },
		bag = { ITEM_TABLE_TYPE.CUST_TRINKET, X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.dwBagItemIndex or 0 },
		glasses = { ITEM_TABLE_TYPE.CUST_TRINKET, X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.dwGlassesItemIndex or 0 },
		lglove = { ITEM_TABLE_TYPE.CUST_TRINKET, X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.GetSelectPendent(KPENDENT_TYPE.LGLOVE) or 0 },
		rglove = { ITEM_TABLE_TYPE.CUST_TRINKET, X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.GetSelectPendent(KPENDENT_TYPE.RGLOVE) or 0 },
		penpet = { ITEM_TABLE_TYPE.CUST_TRINKET, X.ENVIRONMENT.GAME_BRANCH ~= 'classic' and me.GetEquippedPendentPet() or 0 },
	}))

	DB_OwnerInfoW:ClearBindings()
	DB_OwnerInfoW:BindAll(ownerkey, ownername, servername, ownerforce, ownerrole, ownerlevel, X.EncodeLUAData(ownerscore), ownersuitindex, time, ownerextra)
	DB_OwnerInfoW:Execute()
	DB_OwnerInfoW:Reset()

	DB:Execute('END TRANSACTION')
	--[[#DEBUG BEGIN]]
	nTickCount = GetTickCount() - nTickCount
	X.Debug('MY_RoleStatistics_EquipStat', _L('Flushing to database costs %dms...', nTickCount), X.DEBUG_LEVEL.PM_LOG)
	--[[#DEBUG END]]
end

function D.UpdateSaveDB()
	if not D.bReady then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not O.bSaveDB then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_EquipStat', 'Remove from database...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local guid = AnsiToUTF8(X.GetPlayerGUID())
		DB_ItemsDA:ClearBindings()
		DB_ItemsDA:BindAll(guid)
		DB_ItemsDA:Execute()
		DB_ItemsDA:Reset()
		DB_OwnerInfoD:ClearBindings()
		DB_OwnerInfoD:BindAll(guid)
		DB_OwnerInfoD:Execute()
		DB_OwnerInfoD:Reset()
		--[[#DEBUG BEGIN]]
		X.Debug('MY_RoleStatistics_EquipStat', 'Remove from database finished...', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	FireUIEvent('MY_ROLE_STAT_EQUIP_UPDATE')
end

function D.UpdateNames(page)
	local searchname = page:Lookup('Wnd_Total/Wnd_SearchName/Edit_SearchName'):GetText()
	DB_OwnerInfoR:ClearBindings()
	DB_OwnerInfoR:BindAll(AnsiToUTF8('%' .. searchname .. '%'), AnsiToUTF8('%' .. searchname .. '%'))
	local result = DB_OwnerInfoR:GetAll()
	DB_OwnerInfoR:Reset()

	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	container:Clear()
	for _, rec in ipairs(result) do
		for k, v in pairs(rec) do
			if X.IsString(v) then
				rec[k] = UTF8ToAnsi(v)
			end
		end
		rec.ownerextra = X.DecodeJSON(rec.extra or '') or {}
	end
	if result[1] and not X.lodash.some(result, function(r) return r.ownerkey == D.szCurrentOwnerKey end) then
		D.szCurrentOwnerKey = result[1].ownerkey
	end
	for _, rec in ipairs(result) do
		local wnd = container:AppendContentFromIni(SZ_INI, 'Wnd_Name')
		local ownername = rec.ownername
		if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
			ownername = MY_ChatMosaics.MosaicsString(ownername)
		end
		wnd:Lookup('', 'Text_Name'):SetText(ownername .. ' (' .. rec.servername .. ')')
		wnd:Lookup('', 'Image_NameBg_Selected'):SetVisible(rec.ownerkey == D.szCurrentOwnerKey)
		wnd.ownerinfo = rec
	end
	container:FormatAllContentPos()
	D.UpdateItems(page)
end

function D.UpdateItems(page)
	D.FlushDB()

	-- ˢ��װ������ѡ��
	local container = page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_PageNum/WndContainer_PageNum')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		wnd:Lookup('CheckBox_PageNum'):Check(wnd.nSuitIndex == D.dwCurrentSuitIndex, WNDEVENT_FIRETYPE.PREVENT)
	end

	-- ��ȡ��ɫ����
	local ownername = ''
	local ownerforce = -1
	local ownerrole = 0
	local ownerlevel = 0
	local ownerscore = {}
	local ownersuitindex = 0
	local ownerextra = {}
	local container = page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name')
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		if wnd.ownerinfo.ownerkey == D.szCurrentOwnerKey then
			ownername = wnd.ownerinfo.ownername
			ownerforce = wnd.ownerinfo.ownerforce
			ownerrole = wnd.ownerinfo.ownerrole
			ownerlevel = wnd.ownerinfo.ownerlevel
			ownerscore = X.DecodeLUAData(wnd.ownerinfo.ownerscore)
			if not X.IsTable(ownerscore) then
				ownerscore = {}
			end
			ownersuitindex = wnd.ownerinfo.ownersuitindex
			ownerextra = wnd.ownerinfo.ownerextra
		end
	end
	if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
		ownername = MY_ChatMosaics.MosaicsString(ownername)
	end

	-- �����Ҳ�����
	local aXml = {}

	-- ����װ��
	DB_ItemsR:ClearBindings()
	DB_ItemsR:BindAll(AnsiToUTF8(D.szCurrentOwnerKey), D.dwCurrentSuitIndex)
	local tResult = {}
	local aRes = DB_ItemsR:GetAll()
	DB_ItemsR:Reset()
	for _, rec in ipairs(aRes) do
		for k, v in pairs(rec) do
			if X.IsString(v) then
				rec[k] = UTF8ToAnsi(v)
			end
			rec.diamond_enchant = X.DecodeJSON(rec.diamond_enchant) or {}
		end
		tResult[rec.boxindex] = rec
	end
	local handle = page:Lookup('Wnd_Total/Wnd_ItemPage', '')
	-- local nTitleLen = 0
	-- for _, info in ipairs(EQUIPMENT_ITEM_LIST) do
	-- 	nTitleLen = math.max(X.StringLenW(info.label or '') + 1, nTitleLen)
	-- end
	for _, info in ipairs(EQUIPMENT_ITEM_LIST) do
		local visible = info.label and (not info.force or info.force == ownerforce) and true or false
		local rec = visible and info.pos and tResult[info.pos]
		local box = info.box and handle:Lookup(info.box)
		local txtDurability = info.durability and handle:Lookup(info.durability)
		local imgBackground = info.background and handle:Lookup(info.background)
		if visible then
			local szPos = info.label or ''
			szPos = szPos .. g_tStrings.STR_COLON
			-- szPos = szPos .. string.rep(g_tStrings.STR_ONE_CHINESE_SPACE, nTitleLen - X.StringLenW(szPos))
			table.insert(aXml, GetFormatText(szPos, 162))
		end
		if box then
			box:SetVisible(visible)
		end
		if txtDurability then
			txtDurability:SetVisible(visible)
		end
		if imgBackground then
			imgBackground:SetVisible(visible)
		end
		if rec and rec.tabtype >= 0 then
			local KItemInfo = GetItemInfo(rec.tabtype, rec.tabindex)
			if KItemInfo then
				local bMaxStrength = KItemInfo.nMaxStrengthLevel > 0 and rec.strength == KItemInfo.nMaxStrengthLevel
				if box then
					X.UI.UpdateItemInfoBoxObject(box, nil, rec.tabtype, rec.tabindex, rec.stacknum, rec.tabsubindex)
					UpdateItemBoxExtend(box, KItemInfo.nGenre, KItemInfo.nQuality, bMaxStrength)
					box.OnItemMouseEnter = nil
					box.OnItemRefreshTip = nil
					box.tip = rec.desc
				end
				if txtDurability then
					local nDurability = math.floor(rec.durability / KItemInfo.nMaxDurability * 100)
					local nFont = 167
					if nDurability < 30 then
						nFont = 159
					elseif nDurability <= 70 then
						nFont = 16
					end
					txtDurability:SetFontScheme(nFont)
					txtDurability:SetText(nDurability .. '%')
				end
				table.insert(aXml, GetFormatText('[' .. KItemInfo.szName .. ']', 162, GetItemFontColorByQuality(KItemInfo.nQuality)))
				-- ǿ���ȼ�
				for _ = 1, rec.strength do
					table.insert(aXml, '<image>w=16 h=16 path="ui/Image/UICommon/FEPanel.UITex" frame=39 </image>')
				end
				-- ����ʯ
				for _, nEnchantID in ipairs(rec.diamond_enchant) do
					local nType, nTabIndex = GetDiamondInfoFromEnchantID(nEnchantID)
					local diamon = nType and nTabIndex and GetItemInfo(nType, nTabIndex)
					if diamon then
						table.insert(aXml, '<image>w=24 h=24 path="fromiconid" frame=' .. Table_GetItemIconID(diamon.nUiId) .. '</image>')
					else
						table.insert(aXml, '<image>w=24 h=24 path="ui/Image/UICommon/FEPanel.UITex" frame=5 </image>')
					end
				end
				-- ��ħ
				if rec.permanent_enchant ~= 0 then
					local szImagePath = 'ui/Image/UICommon/FEPanel.UITex'
					local nFrame = 41
					local szText = Table_GetCommonEnchantDesc(rec.permanent_enchant)
					if szText then
						szText = string.gsub(szText, 'font=%d+', 'font=113')
						table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
						table.insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 113))
						table.insert(aXml, GetFormatImage(szImagePath, nFrame, 20, 20))
						table.insert(aXml, GetFormatText(' ', 113))
						table.insert(aXml, szText)
					else
						local enchantAttrib = GetItemEnchantAttrib(rec.permanent_enchant);
						if enchantAttrib then
							for k, v in pairs(enchantAttrib) do
								szText = D.FormatEnchantAttribText(v)
								if szText ~= '' then
									szText = string.gsub(szText, 'font=%d+', 'font=113')
									table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
									table.insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 113))
									table.insert(aXml, GetFormatImage(szImagePath, nFrame, 20, 20))
									table.insert(aXml, GetFormatText(' ', 113))
									table.insert(aXml, szText)
								end
							end
						end
					end
				end
				-- ���ʯ
				if KItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
					table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
					-- table.insert(aXml, GetFormatText(string.rep(g_tStrings.STR_ONE_CHINESE_SPACE, nTitleLen) .. ' ', 162))
					-- table.insert(aXml, GetFormatText(g_tStrings.STR_ONE_CHINESE_SPACE, 162))
					table.insert(aXml, GetFormatText(g_tStrings.STR_COLOR_DIAMOND .. g_tStrings.STR_COLON, 162))
					if rec.fea_enchant == 0 then
						table.insert(aXml, '<image>w=20 h=20 path="ui/Image/UICommon/FEPanel.UITex" frame=5 </image>')
						table.insert(aXml, '<text>text=' .. EncodeComponentsString(' ' .. g_tStrings.STR_ITEM_H_COLOR_DIAMOND) .. ' font=161 valign=1 h=24 richtext=0 </text>')
					else
						local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(rec.fea_enchant)
						local diamon = GetItemInfo(dwTabType, dwIndex)
						table.insert(aXml, '<image>w=20 h=20 path="fromiconid" frame=' .. Table_GetItemIconID(diamon.nUiId) .. '</image>')
						table.insert(aXml, GetFormatText(' [' .. diamon.szName .. ']', 162, GetItemFontColorByQuality(diamon.nQuality)))
					end
				end
			--[[#DEBUG BEGIN]]
			else
				X.Debug('MY_RoleStatistics_EquipStat', 'KItemInfo not found: ' .. rec.tabtype .. ', ' .. rec.tabindex, X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			end
		else
			if box then
				box:ClearObject()
			end
			if txtDurability then
				txtDurability:SetText('')
			end
			if visible then
				table.insert(aXml, GetFormatText(_L['None'], 162))
			end
		end
		if visible then
			table.insert(aXml, X.CONSTANT.XML_LINE_BREAKER)
		end
	end

	-- ���ƹ��Ρ�����
	for _, info in ipairs(EQUIPMENT_EXTRA_ITEM_LIST) do
		local aItemData = ownerextra[info.key] or {}
		local dwTabType, dwTabIndex = aItemData[1], aItemData[2]
		local KItemInfo = not X.IsEmpty(dwTabIndex) and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwTabIndex)
		local box = info.box and handle:Lookup(info.box)
		if KItemInfo then
			if box then
				box:SetObjectIcon(Table_GetItemIconID(KItemInfo.nUiId))
				box.bItemInfo = true
				box.dwTabType = dwTabType
				box.dwTabIndex = dwTabIndex
				UpdateItemBoxExtend(box, KItemInfo.nGenre, KItemInfo.nQuality)
			end
		else
			if box then
				box:ClearObject()
			end
		end
	end

	-- ��������
	local txtName = page:Lookup('Wnd_Total/Wnd_ItemPage', 'Text_RoleName')
	txtName:SetText(_L('%s (Lv%d)', ownername, ownerlevel))
	txtName:SetFontColor(X.GetForceColor(ownerforce, 'foreground'))
	local txtRoleInfo = page:Lookup('Wnd_Total/Wnd_ItemPage', 'Text_RoleInfo')
	txtRoleInfo:SetText(_L('%s * %s', X.CONSTANT.FORCE_TYPE_LABEL[ownerforce] or '', X.CONSTANT.ROLE_TYPE_LABEL[ownerrole] or ''))
	local txtEquipScore = page:Lookup('Wnd_Total/Wnd_ItemPage', 'Text_EquipScore')
	-- txtEquipScore:SetVisible(ownersuitindex == D.dwCurrentSuitIndex)
	txtEquipScore:SetText(_L('Equip score: %s', ownerscore[D.dwCurrentSuitIndex] or _L['Unknown']))
	local hBoard = page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', 'Handle_EquipInfo')
	hBoard:Clear()
	hBoard:AppendItemFromString(table.concat(aXml))
	hBoard:FormatAllItemPos()
end

function D.OnInitPage()
	local frameTemp = X.UI.OpenFrame(SZ_INI, 'MY_RoleStatistics_EquipStat')
	local wnd = frameTemp:Lookup('Wnd_Total')
	wnd:ChangeRelation(this, true, true)
	X.UI.CloseFrame(frameTemp)

	local container = wnd:Lookup('Wnd_ItemPage/WndScroll_PageNum/WndContainer_PageNum')
	container:Clear()
	for nIndex, _ in ipairs(X.CONSTANT.INVENTORY_EQUIP_LIST) do
		local wndPage = container:AppendContentFromIni(SZ_INI, 'Wnd_PageNum')
		wndPage:Lookup('CheckBox_PageNum', 'Text_PageNum'):SetText(nIndex)
		wndPage.nSuitIndex = nIndex
	end
	container:FormatAllContentPos()

	local frame = this:GetRoot()
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	frame:RegisterEvent('MY_ROLE_STAT_EQUIP_UPDATE')

	D.OnResizePage()
end

function D.OnResizePage()
	local page = this
	local ui = X.UI(page)
	local nW, nH = ui:Size()

	page:Lookup('Wnd_Total'):SetSize(nW, nH)
	page:Lookup('Wnd_Total/WndScroll_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/WndScroll_Name', 'Image_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/WndScroll_Name/WndContainer_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/WndScroll_Name/Scroll_Name'):SetH(nH - 78)
	page:Lookup('Wnd_Total/Wnd_ItemPage'):SetSize(nW - 235, nH - 54)
	page:Lookup('Wnd_Total/Wnd_ItemPage', ''):SetSize(nW - 235, nH - 54)
	page:Lookup('Wnd_Total/Wnd_ItemPage', 'Image_ItemPageBg'):SetSize(nW - 235, nH - 54)
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo'):SetSize(nW - 563, nH - 78)
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', ''):SetSize(nW - 579, nH - 78)
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', 'Image_EquipInfo'):SetSize(nW - 579, nH - 78)
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', 'Handle_EquipInfo'):SetSize(nW - 602, nH - 90)
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo', 'Handle_EquipInfo'):FormatAllItemPos()
	page:Lookup('Wnd_Total/Wnd_ItemPage/WndScroll_EquipInfo/Scroll_EquipInfo'):SetH(78)
end

function D.OnActivePage()
	D.Migration()
	if not O.bAdviceSaveDB and not O.bSaveDB then
		X.Confirm(_L('%s stat has not been enabled, this character\'s data will not be saved, are you willing to save this character?\nYou can change this config by click option button on the top-right conner.', _L[MODULE_NAME]), function()
			MY_RoleStatistics_EquipStat.bSaveDB = true
			MY_RoleStatistics_EquipStat.bAdviceSaveDB = true
		end, function()
			MY_RoleStatistics_EquipStat.bAdviceSaveDB = true
		end)
	end
	D.UpdateNames(this)
end

function D.OnEvent(event)
	if event == 'ON_MY_MOSAICS_RESET' then
		D.UpdateNames(this)
	elseif event == 'MY_ROLE_STAT_EQUIP_UPDATE' then
		D.FlushDB()
		D.UpdateNames(this)
	end
end

function D.OnEditSpecialKeyDown()
	local name = this:GetName()
	local szKey = GetKeyName(Station.GetMessageKey())
	if szKey == 'Enter' then
		if name == 'Edit_SearchName' then
			local page = this:GetParent():GetParent():GetParent()
			D.UpdateNames(page)
		end
		return 1
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_PageNum' then
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent()
		D.dwCurrentSuitIndex = this:GetParent().nSuitIndex
		D.UpdateNames(page)
	end
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Wnd_Name' then
		local wnd = this
		local page = this:GetParent():GetParent():GetParent():GetParent()
		D.szCurrentOwnerKey = wnd.ownerinfo.ownerkey
		D.UpdateNames(page)
	elseif name == 'Btn_Delete' then
		local wnd = this:GetParent()
		local page = this:GetParent():GetParent():GetParent():GetParent():GetParent()
		X.Confirm(_L('Are you sure to delete item record of %s?', wnd.ownerinfo.ownername), function()
			DB_ItemsDA:ClearBindings()
			DB_ItemsDA:BindAll(wnd.ownerinfo.ownerkey)
			DB_ItemsDA:Execute()
			DB_ItemsDA:Reset()
			DB_OwnerInfoD:ClearBindings()
			DB_OwnerInfoD:BindAll(wnd.ownerinfo.ownerkey)
			DB_OwnerInfoD:Execute()
			DB_OwnerInfoD:Reset()
			D.UpdateNames(page)
		end)
	end
end

function D.OnItemMouseEnter()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(true)
	end
	if this.tip then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(this.tip, 400, {x, y, w, h, false}, nil, false)
	elseif this.bItemInfo then
		X.OutputItemInfoTip(this, this.dwTabType, this.dwTabIndex)
	end
end
D.OnItemRefreshTip = D.OnItemMouseEnter

function D.OnItemMouseLeave()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(false)
	end
	HideTip()
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Wnd_Name' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(GetFormatText(_L(
			this.ownerinfo.ownername:sub(1, 1) == '['
				and 'Tong: %s\nServer: %s\nSnapshot Time: %s'
				or 'Character: %s\nServer: %s\nSnapshot Time: %s',
			this.ownerinfo.ownername,
			this.ownerinfo.servername,
			X.FormatTime(this.ownerinfo.time, '%yyyy-%MM-%dd %hh:%mm:%ss')), nil, 255, 255, 0), 400, {x, y, w, h, false}, ALW.RIGHT_LEFT_AND_BOTTOM_TOP, false)
	end
end

-- ������
function D.ApplyFloatEntry(bFloatEntry)
	local frame = Station.Lookup('Normal/CharacterPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_MY_RoleStatistics_EquipEntry')
	if bFloatEntry then
		if btn then
			return
		end
		local frameTemp = X.UI.OpenFrame(PLUGIN_ROOT .. '/ui/MY_RoleStatistics_EquipEntry.ini', 'MY_RoleStatistics_EquipEntry')
		btn = frameTemp:Lookup('Btn_MY_RoleStatistics_EquipEntry')
		btn:ChangeRelation(frame, true, true)
		btn:SetRelPos(40, 8)
		X.UI.CloseFrame(frameTemp)
		btn.OnLButtonClick = function()
			MY_RoleStatistics.Open('EquipStat')
		end
	else
		if not btn then
			return
		end
		btn:Destroy()
	end
end

function D.UpdateFloatEntry()
	if not D.bReady then
		return
	end
	D.ApplyFloatEntry(O.bFloatEntry)
end

--------------------------------------------------------------------------------
-- Module exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_EquipStat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnResizePage',
				szSaveDB = 'MY_RoleStatistics_EquipStat.bSaveDB',
				szFloatEntry = 'MY_RoleStatistics_EquipStat.bFloatEntry',
			},
			root = D,
		},
	},
}
MY_RoleStatistics.RegisterModule('EquipStat', _L['MY_RoleStatistics_EquipStat'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_RoleStatistics_EquipStat',
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				'bSaveDB',
				'bAdviceSaveDB',
				'bFloatEntry',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bSaveDB',
				'bAdviceSaveDB',
				'bFloatEntry',
			},
			triggers = {
				bSaveDB = D.UpdateSaveDB,
				bFloatEntry = D.UpdateFloatEntry,
			},
			root = O,
		},
	},
}
MY_RoleStatistics_EquipStat = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_RoleStatistics_EquipStat', function()
	D.bReady = true
	D.UpdateFloatEntry()
end)

X.RegisterFlush('MY_RoleStatistics_EquipStat', function()
	D.FlushDB()
end)

X.RegisterExit('MY_RoleStatistics_EquipStat', function()
	if not X.ENVIRONMENT.RUNTIME_OPTIMIZE then
		D.UpdateSaveDB()
		D.FlushDB()
	end
end)

X.RegisterReload('MY_RoleStatistics_EquipStat', function()
	D.ApplyFloatEntry(false)
end)

X.RegisterFrameCreate('CharacterPanel', 'MY_RoleStatistics_EquipStat', function()
	D.UpdateFloatEntry()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
