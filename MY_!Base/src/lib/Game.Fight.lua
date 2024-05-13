--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Fellowship')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ս��״̬
--------------------------------------------------------------------------------

do
local LAST_FIGHT_UUID  = nil
local FIGHT_UUID       = nil
local FIGHT_BEGIN_TICK = -1
local FIGHT_END_TICK   = -1
local FIGHTING         = false
local function ListenFightStateChange()
	-- �ж�ս���߽�
	if X.IsFighting() then
		-- ����ս���ж�
		if not FIGHTING then
			FIGHTING = true
			-- 5����ս�ж����� ��ֹ������������ж�
			if not FIGHT_UUID
			or GetTickCount() - FIGHT_END_TICK > 5000 then
				-- �µ�һ��ս����ʼ
				FIGHT_BEGIN_TICK = GetTickCount()
				-- ����ս��ȫ��Ψһ��ʾ
				local me = X.GetClientPlayer()
				local team = GetClientTeam()
				local szEdition = X.ENVIRONMENT.GAME_EDITION
				local szServer = X.GetRegionOriginName() .. '_' .. X.GetServerOriginName()
				local dwTime = GetCurrentTime()
				local dwTeamID, nTeamMember, dwTeamXorID = 0, 0, 0
				if team then
					dwTeamID = team.dwTeamID
				end
				if me and team and me.IsInParty() then
					for _, dwTarID in ipairs(team.GetTeamMemberList()) do
						nTeamMember = nTeamMember + 1
						dwTeamXorID = X.NumberBitXor(dwTeamXorID, dwTarID)
					end
				elseif me then
					nTeamMember = 1
					dwTeamXorID = me.dwID
				end
				FIGHT_UUID = szEdition .. '::' .. szServer .. '::' .. dwTime .. '::'
					.. dwTeamID .. '::' .. dwTeamXorID .. '/' .. nTeamMember
					.. '::U' .. me.GetGlobalID() .. '/' .. me.dwID
				FireUIEvent(X.NSFormatString('{$NS}_FIGHT_HINT'), true, FIGHT_UUID, 0)
			end
		end
	else
		-- �˳�ս���ж�
		if FIGHTING then
			FIGHT_END_TICK, FIGHTING = GetTickCount(), false
		elseif FIGHT_UUID and GetTickCount() - FIGHT_END_TICK > 5000 then
			LAST_FIGHT_UUID, FIGHT_UUID = FIGHT_UUID, nil
			FireUIEvent(X.NSFormatString('{$NS}_FIGHT_HINT'), false, LAST_FIGHT_UUID, FIGHT_END_TICK - FIGHT_BEGIN_TICK)
		end
	end
end
X.BreatheCall(X.NSFormatString('{$NS}#ListenFightStateChange'), ListenFightStateChange)

-- ��ȡ��ǰս��ʱ��
function X.GetFightTime(szFormat)
	local nTick = 0
	if FIGHTING then -- ս��״̬
		nTick = GetTickCount() - FIGHT_BEGIN_TICK
	else  -- ��ս״̬
		nTick = FIGHT_END_TICK - FIGHT_BEGIN_TICK
	end

	if szFormat then
		local nSeconds = math.floor(nTick / 1000)
		local nMinutes = math.floor(nSeconds / 60)
		local nHours   = math.floor(nMinutes / 60)
		local nMinute  = nMinutes % 60
		local nSecond  = nSeconds % 60
		szFormat = szFormat:gsub('f', math.floor(nTick / 1000 * X.ENVIRONMENT.GAME_FPS))
		szFormat = szFormat:gsub('H', nHours)
		szFormat = szFormat:gsub('M', nMinutes)
		szFormat = szFormat:gsub('S', nSeconds)
		szFormat = szFormat:gsub('hh', string.format('%02d', nHours ))
		szFormat = szFormat:gsub('mm', string.format('%02d', nMinute))
		szFormat = szFormat:gsub('ss', string.format('%02d', nSecond))
		szFormat = szFormat:gsub('h', nHours)
		szFormat = szFormat:gsub('m', nMinute)
		szFormat = szFormat:gsub('s', nSecond)

		if szFormat:sub(1, 1) ~= '0' and tonumber(szFormat) then
			szFormat = tonumber(szFormat)
		end
	else
		szFormat = nTick
	end
	return szFormat
end

-- ��ȡ��ǰս��Ψһ��ʾ��
function X.GetFightUUID()
	return FIGHT_UUID
end

-- ��ȡ�ϴ�ս��Ψһ��ʾ��
function X.GetLastFightUUID()
	return LAST_FIGHT_UUID
end
end

-- ��ȡ�����Ƿ����߼�ս��״̬
-- (bool) X.IsFighting()
do local ARENA_START = false
function X.IsFighting()
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local bFightState = me.bFightState
	if not bFightState and X.IsInArenaMap() and ARENA_START then
		bFightState = true
	elseif not bFightState and X.IsInDungeonMap() then
		-- ���ؾ��Ҹ������ѽ�ս�Ҹ����ж�NPC��ս���жϴ���ս��״̬
		local bPlayerFighting, bNpcFighting
		for _, p in ipairs(X.GetNearPlayer()) do
			if me.IsPlayerInMyParty(p.dwID) and p.bFightState then
				bPlayerFighting = true
				break
			end
		end
		if bPlayerFighting then
			for _, p in ipairs(X.GetNearNpc()) do
				if IsEnemy(p.dwID, me.dwID) and p.bFightState then
					bNpcFighting = true
					break
				end
			end
		end
		bFightState = bPlayerFighting and bNpcFighting
	end
	return bFightState
end
X.RegisterEvent('LOADING_ENDING', 'LIB#PLAYER', function() ARENA_START = nil end)
X.RegisterEvent('ARENA_START', 'LIB#PLAYER', function() ARENA_START = true end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
