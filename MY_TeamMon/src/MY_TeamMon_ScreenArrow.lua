--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ͷ����ͷ
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_ScreenArrow'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_ScreenArrow'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TeamMon_ScreenArrow', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_TeamMon_PartyBuffList', _L['Raid'], {
	bAlert = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlySelf = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	fLifePer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0.3,
	},
	fManaPer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 0.1,
	},
	nFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 186,
	},
	bDrawColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	tCache = {
		['Life'] = {},
		['Mana'] = {},
	}
}

local HANDLE
local CACHE = {
	[TARGET.DOODAD] = {},
	[TARGET.PLAYER] = {},
	[TARGET.NPC]    = {},
}
local SA = {}
SA.__index = SA

local SA_COLOR = {
	FONT = {
		['BUFF'   ] = { 255, 128, 0   },
		['DEBUFF' ] = { 255, 0,   255 },
		['Life'   ] = { 130, 255, 130 },
		['Mana'   ] = { 255, 255, 128 },
		['NPC'    ] = { 0,   255, 255 },
		['CASTING'] = { 150, 200, 255 },
		['DOODAD' ] = { 200, 200, 255 },
		['TIME'   ] = { 128, 255, 255 },
	},
	ARROW = {
		['BUFF'   ] = { 0,   255, 0   },
		['DEBUFF' ] = { 255, 0,   0   },
		['Life'   ] = { 255, 0,   0   },
		['Mana'   ] = { 0,   0,   255 },
		['NPC'    ] = { 0,   128, 255 },
		['CASTING'] = { 255, 128, 0   },
		['DOODAD' ] = { 200, 200, 255 },
		['TIME'   ] = { 255, 0,   0   },
	}
}
do
	local mt = { __index = function() return { 255, 128, 0 } end }
	setmetatable(SA_COLOR.FONT,  mt)
	setmetatable(SA_COLOR.ARROW, mt)
end

local BASE_SA_POINT_C = { 25, 25, 180 }
local BASE_SA_POINT = {
	{ 15, 0,  100 },
	{ 35, 0,  100 },
	{ 35, 25, 180 },
	{ 43, 25, 255 },
	{ 25, 50, 180 },
	{ 7,  25, 255 },
	{ 15, 25, 180 },
}

local BASE_WIDTH
local BASE_HEIGHT
local BASE_PEAK
local BASE_EDGE
local SA_POINT_C = {}
local SA_POINT = {}
local BASE_POINT_START
local function setUIScale()
	local dpi = Station.GetMaxUIScale()
	BASE_PEAK = -60 * dpi * 0.5
	BASE_WIDTH = 100 * dpi
	BASE_HEIGHT = 12 * dpi
	BASE_EDGE = dpi * 1.2
	BASE_POINT_START = 15 * dpi
	SA_POINT_C = {}
	SA_POINT = {}
	for k, v in ipairs(BASE_SA_POINT_C) do
		if k ~= 3 then
			SA_POINT_C[k] = v * dpi
		else
			SA_POINT_C[k] = v
		end
	end
	for k, v in ipairs(BASE_SA_POINT) do
		SA_POINT[k] = {}
		for kk, vv in ipairs(v) do
			if kk ~= 3 then
				SA_POINT[k][kk] = vv * dpi
			else
				SA_POINT[k][kk] = vv
			end
		end
	end
end


-- for i=1, 2 do FireUIEvent('MY_TEAM_MON__SCREEN_ARROW__CREATE', 'TIME', GetClientPlayer().dwID, { col = { 255, 255, 255 }, txt = 'test' })end
local function CreateScreenArrow(szClass, dwID, tArgs)
	tArgs = tArgs or {}
	SA:ctor(szClass, dwID, tArgs)
end

function D.IsEnabled()
	return D.bReady and O.bAlert and not X.IsRestricted('MY_TeamMon_ScreenArrow')
end

function D.OnSort()
	local t = {}
	for k, v in pairs(HANDLE:GetAllItem(true)) do
		PostThreadCall(function(v, xScreen, yScreen)
			v.nIndex = yScreen or 0
		end, v, 'Scene_GetCharacterTopScreenPos', v.dwID)
		table.insert(t, { handle = v, index = v.nIndex or 0 })
	end
	table.sort(t, function(a, b) return a.index < b.index end)
	for i = #t, 1, -1 do
		if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
		t[i].handle:ExchangeIndex(i - 1)
		end
	end
end

function D.OnBreathe()
	if not D.bReady then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local team = GetClientTeam()
	local tTeamMark = team.dwTeamID > 0 and team.GetTeamMark() or EMPTY_TABLE
	for dwType, tab in pairs(CACHE) do
		for dwID, v in pairs(tab) do
			local object, tInfo = select(2, D.GetObject(dwType, dwID))
			if object then
				local obj = D.GetAction(dwType, dwID)
				local fLifePer = obj.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentLife / math.max(tInfo.nMaxLife, tInfo.nCurrentLife, 1)
				local fManaPer = obj.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentMana / math.max(tInfo.nMaxMana, tInfo.nCurrentMana, 1)
				local szName
				if dwType == TARGET.DOODAD then
					szName = tInfo.szName
				elseif dwType == TARGET.NPC then
					szName = X.GetTemplateName(TARGET.NPC, object.dwTemplateID)
				else
					szName = X.GetObjectName(object)
				end
				szName = obj.szName or szName
				if tTeamMark[dwID] then
					szName = szName .. _L('[%s]', X.CONSTANT.TEAM_MARK_NAME[tTeamMark[dwID]])
				end
				local txt = ''
				if obj.szClass == 'BUFF' or obj.szClass == 'DEBUFF' then
					-- local KBuff = GetBuff(obj.dwBuffID, object) -- ֻ�ж�dwID ����������ͬʱ��ò�ͬlv
					local KBuff = object.GetBuff(obj.dwBuffID, 0) -- ֻ�ж�dwID ����������ͬʱ��ò�ͬlv
					if KBuff then
						local nSec = X.GetEndTime(KBuff.GetEndTime())
						local szDuration = X.FormatDuration(math.min(nSec, 5999), 'PRIME')
						if KBuff.nStackNum > 1 then
							txt = string.format('%s(%d)_%s', obj.txt or X.GetBuffName(KBuff.dwID, KBuff.nLevel), KBuff.nStackNum, szDuration)
						else
							txt = string.format('%s_%s', obj.txt or X.GetBuffName(KBuff.dwID, KBuff.nLevel), szDuration)
						end
					else
						return obj:Free()
					end
				elseif obj.szClass == 'Life' or obj.szClass == 'Mana' then
					if object.nMoveState == MOVE_STATE.ON_DEATH then
						return obj:Free()
					end
					if obj.szClass == 'Life' then
						if fLifePer > O.fLifePer then
							return obj:Free()
						end
						txt = g_tStrings.STR_SKILL_H_LIFE_COST .. string.format('%d/%d', tInfo.nCurrentLife, tInfo.nMaxLife)
					elseif obj.szClass == 'Mana' then
						if fManaPer > O.fManaPer then
							return obj:Free()
						end
						txt = g_tStrings.STR_SKILL_H_MANA_COST .. string.format('%d/%d', tInfo.nCurrentMana, tInfo.nMaxMana)
					end
				elseif obj.szClass == 'CASTING' then
					local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetOTActionState(object)
					if nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE then
						txt = obj.txt or X.GetSkillName(dwSkillID, dwSkillLevel)
						fManaPer = fCastPercent
					else
						return obj:Free()
					end
				elseif obj.szClass == 'NPC' or obj.szClass == 'DOODAD' then
					txt = obj.txt or txt
				elseif obj.szClass == 'TIME' then
					if (GetTime() - obj.nNow) / 1000 > 5 then
						return obj:Free()
					end
					txt = obj.txt or _L['Call Alert']
				end
				if not obj.init then
					obj:DrawBackGround()
				end
				obj:DrawLifeBar(fLifePer, fManaPer):DrawText(txt, szName):DrowArrow()
			else
				for _, vv in pairs(v) do
					vv:Free()
				end
			end
		end
	end
end

function D.GetAction(dwType, dwID)
	local tab = CACHE[dwType][dwID]
	if #tab > 1 then
		for k, v in ipairs(CACHE[dwType][dwID]) do
			v:Hide()
		end
	end
	local obj = CACHE[dwType][dwID][#CACHE[dwType][dwID]]
	return obj:Show()
end

function D.GetObject(szClass, dwID)
	local dwType, object, tInfo
	if szClass == 'DOODAD' or szClass == TARGET.DOODAD then
		dwType = TARGET.DOODAD
		object = GetDoodad(dwID)
	elseif IsPlayer(dwID) then
		dwType = TARGET.PLAYER
		local me = GetClientPlayer()
		if dwID == me.dwID then
			object = me
		elseif X.IsParty(dwID) then
			object = GetPlayer(dwID)
			tInfo  = GetClientTeam().GetMemberInfo(dwID)
		else
			object = GetPlayer(dwID)
		end
	else
		dwType = TARGET.NPC
		object = GetNpc(dwID)
	end
	tInfo = tInfo and tInfo or object
	return dwType, object, tInfo
end

function D.RegisterFight()
	if arg0 and O.bAlert then
		X.BreatheCall('ScreenArrow_Fight', D.OnBreatheFight)
	else
		D.KillBreathe()
	end
end

function D.KillBreathe()
	X.BreatheCall('ScreenArrow_Fight', false)
	D.tCache['Mana'] = {}
	D.tCache['Life'] = {}
end

function D.OnBreatheFight()
	local me = GetClientPlayer()
	if not me then return end
	if not me.bFightState then -- kill fix bug
		return D.KillBreathe()
	end
	local team = GetClientTeam()
	local list = {}
	if me.IsInParty() and not O.bOnlySelf then
		list = team.GetTeamMemberList()
	else
		list[1] = me.dwID
	end
	for k, v in ipairs(list) do
		local p, info = select(2, D.GetObject(TARGET.PLAYER, v))
		if p and info then
			if p.nMoveState == MOVE_STATE.ON_DEATH then
				D.tCache['Mana'][v] = nil
				D.tCache['Life'][v] = nil
			else
				local fLifePer = info.nCurrentLife / math.max(info.nMaxLife, info.nCurrentLife, 1)
				local fManaPer = info.nCurrentMana / math.max(info.nMaxMana, info.nCurrentMana, 1)
				if fLifePer < O.fLifePer then
					if not D.tCache['Life'][v] then
						D.tCache['Life'][v] = true
						CreateScreenArrow('Life', v)
					end
				else
					D.tCache['Life'][v] = nil
				end
				if fManaPer < O.fManaPer and (p.dwForceID < 7 or p.dwForceID == 22) then
					if not D.tCache['Mana'][v] then
						D.tCache['Mana'][v] = true
						CreateScreenArrow('Mana', v)
					end
				else
					D.tCache['Mana'][v] = nil
				end
			end
		end
	end
end

function SA:ctor(szClass, dwID, tArgs)
	local dwType, object = D.GetObject(szClass, dwID)
	if not X.IsDebugClient(true) and not X.IsInDungeonMap(true) then
		if dwType == TARGET.NPC and object.bDialogFlag then
			return
		end
	end
	local oo = {}
	setmetatable(oo, self)
	local ui      = HANDLE:New()
	oo.szName   = tArgs.szName
	oo.txt      = tArgs.txt
	oo.col      = tArgs.col or SA_COLOR.ARROW[szClass]
	oo.dwBuffID = tArgs.dwID
	oo.szClass  = szClass

	oo.Arrow    = ui:Lookup(0)
	oo.Text     = ui:Lookup(1)
	oo.BGB      = ui:Lookup(2)
	oo.BGI      = ui:Lookup(3)
	oo.Life     = ui:Lookup(4)
	oo.Mana     = ui:Lookup(5)

	oo.ui       = ui
	oo.ui.dwID  = dwID
	oo.init     = false
	oo.bUp      = false
	oo.nTop     = 10
	oo.dwID     = dwID
	oo.dwType   = dwType
	if szClass == 'TIME' then
		oo.nNow = GetTime()
	end
	oo.Text:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	for k, v in pairs({ oo.BGB, oo.BGI, oo.Life, oo.Mana, oo.Arrow }) do
		v:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		v:SetD3DPT(D3DPT.TRIANGLEFAN)
	end
	CACHE[dwType][dwID] = CACHE[dwType][dwID] or {}
	table.insert(CACHE[dwType][dwID], oo)
	return oo
end

-- �������� ���λ���
function SA:DrawText( ... )
	self.Text:ClearTriangleFanPoint()
	local nTop = BASE_PEAK - (BASE_EDGE * 2)
	local r, g, b = unpack(SA_COLOR.FONT[self.szClass])
	local i = 1
	for k, v in ipairs({ ... }) do
		if v and v ~= '' then
			local top = nTop + i * -45
			if self.dwType == TARGET.DOODAD then
				self.Text:AppendDoodadID(self.dwID, r, g, b, 240, { 0, 0, 0, 0, top }, O.nFont, v, 1, 1.8)
			else
				if O.bDrawColor and self.dwType == TARGET.PLAYER and k ~= 1 then
					local p = select(2, D.GetObject(self.szClass, self.dwID))
					if p then
						r, g, b = X.GetForceColor(p.dwForceID, 'foreground')
					end
				end
				self.Text:AppendCharacterID(self.dwID, true, r, g, b, 240, { 0, 0, 0, 0, top }, O.nFont, v, 1, 1.8)
			end
			i = i + 1
		end
	end
	return self
end

function SA:DrawBackGround()
	for k, v in pairs({ self.BGB, self.BGI }) do
		v:ClearTriangleFanPoint()
	end
	local bcX, bcY = -BASE_WIDTH / 2, BASE_PEAK
	local doubleEdge = BASE_EDGE * 2
	if self.dwType == TARGET.DOODAD then
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY + BASE_HEIGHT })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + BASE_HEIGHT })
		bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY + BASE_HEIGHT - doubleEdge })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + BASE_HEIGHT - doubleEdge})
	else
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY + BASE_HEIGHT })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + BASE_HEIGHT })
		bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY + BASE_HEIGHT - doubleEdge })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + BASE_HEIGHT - doubleEdge})
	end
	self.init = true
	return self
end

function SA:DrawLifeBar(fLifePer, fManaPer)
	local height = BASE_HEIGHT / 2 - BASE_EDGE
	local width = BASE_WIDTH - (BASE_EDGE * 2)
	if fLifePer ~= self.fLifePer then
		self.Life:ClearTriangleFanPoint()
		if fLifePer > 0 then
			local bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
			local r, g ,b = 220, 40, 0
			if self.dwType == TARGET.DOODAD then
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY + height })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			else
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY + height })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			end
		end
		self.fLifePer = fLifePer
	end
	if fManaPer ~= self.fManaPer then
		self.Mana:ClearTriangleFanPoint()
		if fManaPer > 0 then
			local bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + height + BASE_EDGE
			local r, g ,b = 50, 100, 255
			if self.szClass == 'CASTING' then
				r, g ,b = 255, 128, 0
			end
			if self.dwType == TARGET.DOODAD then
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY + height })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			else
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY + height })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			end
		end
		self.fManaPer = fManaPer
	end
	return self
end

function SA:DrowArrow()
	local cX, cY, cA = unpack(SA_POINT_C)
	cX, cY = cX * 0.7, cY * 0.7
	local fX, fY = BASE_POINT_START, -BASE_PEAK - BASE_HEIGHT
	if self.bUp then
		self.nTop = self.nTop + 2
		if self.nTop >= 10 then
			self.bUp = false
		end
	else
		self.nTop = self.nTop - 2
		if self.nTop <= 0 then
			self.bUp = true
		end
	end
	fY = fY - self.nTop

	self.Arrow:ClearTriangleFanPoint()
	local r, g, b = unpack(self.col)
	if self.dwType == TARGET.DOODAD then
		self.Arrow:AppendDoodadID(self.dwID, r, g, b, cA, { 0, 0, 0, cX - fX, cY - fY })
		for k, v in ipairs(SA_POINT) do
			local x, y, a = unpack(v)
			x, y = x * 0.7, y * 0.7
			self.Arrow:AppendDoodadID(self.dwID, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
		end
		local x, y, a = unpack(SA_POINT[1])
		self.Arrow:AppendDoodadID(self.dwID, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
	else
		self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, cA, { 0, 0, 0, cX - fX, cY - fY })
		for k, v in ipairs(SA_POINT) do
			local x, y, a = unpack(v)
			x, y = x * 0.7, y * 0.7
			self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
		end
		local x, y, a = unpack(SA_POINT[1])
		self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, x- fX, y - fY })
	end
	return self
end

function SA:Show()
	self.ui:Show()
	return self
end

function SA:Hide()
	self.ui:Hide()
	return self
end

function SA:Free()
	local tab = CACHE[self.dwType][self.dwID]
	if #tab == 1 then
		CACHE[self.dwType][self.dwID] = nil
	else
		for k, v in pairs(tab) do
			if v.ui == self.ui then
				table.remove(tab, k)
				break
			end
		end
	end
	HANDLE:Free(self.ui)
end

local PS = { szRestriction = 'DELTA' }
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 30, 30
	local nX, nY = nPaddingX, nPaddingY

	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['Screen Head Alarm'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	nX, nY = ui:Append('WndCheckBox', {
		x = nX, y = nY + 10,
		text = _L['Draw School Color'],
		checked = O.bDrawColor,
		onCheck = function(bChecked)
			O.bDrawColor = bChecked
		end,
	}):Pos('BOTTOMRIGHT')

	nX = nPaddingX
	nY = nY + 10
	nX, nY = ui:Append('Text', { x = nX, y = nY + 5, text = _L['less life/mana HeadAlert'], font = 27 }):Pos('BOTTOMRIGHT')
	nX = nPaddingX + 10
	nX = ui:Append('WndCheckBox',{
		x = nX, y = nY + 10,
		text = _L['Enable'],
		checked = O.bAlert,
		onCheck = function(bChecked)
			O.bAlert = bChecked
			local me = GetClientPlayer()
			if bChecked and me.bFightState then
				X.BreatheCall('ScreenArrow_Fight', D.OnBreatheFight)
			else
				D.KillBreathe()
			end
		end
	}):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('WndCheckBox', {
		x = nX + 10, y = nY + 10,
		text = _L['only Monitor self'],
		checked = O.bOnlySelf,
		onCheck = function(bChecked)
			O.bOnlySelf = bChecked
		end,
		autoEnable = function() return O.bAlert end,
	}):Pos('BOTTOMRIGHT')

	nX = nPaddingX
	nY = nY + 10
	nX = ui:Append('Text', { text = _L['While HP less than'], x = nX, y = nY }):Pos('BOTTOMRIGHT')
	nX = nX + 10
	nX, nY = ui:Append('WndSlider', {
		x = nX, y = nY + 3,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {0, 100},
		value = O.fLifePer * 100,
		onChange = function(nVal) O.fLifePer = nVal / 100 end,
		autoEnable = function() return O.bAlert end,
	}):Pos('BOTTOMRIGHT')

	nX = nPaddingX
	nX = ui:Append('Text', { text = _L['While MP less than'], x = nX, y = nY }):Pos('BOTTOMRIGHT')
	nX = nX + 10
	nX, nY = ui:Append('WndSlider', {
		x = nX, y = nY + 3,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {0, 100},
		value = O.fManaPer * 100,
		onChange = function(nVal) O.fManaPer = nVal / 100 end,
		autoEnable = function() return O.bAlert end,
	}):Pos('BOTTOMRIGHT')

	nX = nPaddingX
	nY = nY + 10
	nX = ui:Append('WndButton', {
		x = nX, y = nY + 5,
		text = g_tStrings.FONT,
		onClick =  function()
			X.UI.OpenFontPicker(function(nFont)
				O.nFont = nFont
			end)
		end,
	}):Pos('BOTTOMRIGHT')
	nX = nX + 10
	ui:Append('WndButton', {
		x = nX, y = nY + 5,
		text = _L['preview'],
		onClick = function()
			CreateScreenArrow('TIME', GetClientPlayer().dwID, { text = _L('%s are welcome to use JH plug-in', GetUserRoleName()) })
		end,
	})
end
X.RegisterPanel(_L['Raid'], 'MY_TeamMon_ScreenArrow', _L['MY_TeamMon_ScreenArrow'], 431, PS)

function D.Init()
	HANDLE = X.UI.HandlePool(X.UI.GetShadowHandle('ScreenArrow'), FormatHandle(string.rep('<shadow></shadow>', 6)))
	X.BreatheCall('ScreenArrow_Sort', 500, D.OnSort)
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_ScreenArrow',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'IsEnabled',
			},
			root = D,
		},
	},
}
MY_TeamMon_ScreenArrow = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.BreatheCall('MY_TeamMon_ScreenArrow', D.OnBreathe)
X.RegisterEvent('FIGHT_HINT', 'MY_TeamMon_ScreenArrow', D.RegisterFight)
X.RegisterEvent('LOGIN_GAME', 'MY_TeamMon_ScreenArrow', D.Init)
X.RegisterEvent('UI_SCALED' , 'MY_TeamMon_ScreenArrow', setUIScale)
X.RegisterEvent('MY_TEAM_MON__SCREEN_ARROW__CREATE', 'MY_TeamMon_ScreenArrow', function()
	CreateScreenArrow(arg0, arg1, arg2)
end)

X.RegisterUserSettingsInit('MY_TeamMon_ScreenArrow', function()
	D.bReady = true
end)
X.RegisterUserSettingsRelease('MY_TeamMon_ScreenArrow', function()
	D.bReady = false
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
