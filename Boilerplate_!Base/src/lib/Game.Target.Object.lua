--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Object')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ��ȡĿ��Ѫ�������Ѫ��
function X.GetObjectLife(obj)
	if not obj then
		return
	end
	return X.IS_REMAKE and obj.fCurrentLife64 or obj.nCurrentLife,
		X.IS_REMAKE and obj.fMaxLife64 or obj.nMaxLife
end

-- ��ȡĿ���������������
function X.GetObjectMana(obj)
	if not obj then
		return
	end
	return obj.nCurrentMana, obj.nMaxMana
end

do
local CACHE = {}
local function GetObjectSceneIndex(dwID)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	if not X.IsMonsterMap(me.GetMapID()) then
		return
	end
	local scene = me.GetScene()
	if not scene then
		return
	end
	local nType = X.IsPlayer(dwID) and 0 or 1
	local nIndex = CACHE[dwID]
	if not nIndex or scene.GetTempCustomUnsigned4(1, nIndex * 20 + 1) ~= dwID then
		for i = 0, 9 do
			local nOffset = i * 20 + 1
			if scene.GetTempCustomUnsigned4(nType, nOffset) == dwID then
				CACHE[dwID] = i
				nIndex = i
				break
			end
		end
	end
	return scene, nType, nIndex
end

-- ��ȡĿ�꾫���������
---@param obj userdata | string @Ŀ������Ŀ��ID
---@return number @Ŀ�꾫���������
function X.GetObjectSpirit(obj)
	local scene, nType, nIndex = GetObjectSceneIndex(X.IsUserdata(obj) and obj.dwID or obj)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 4),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 8)
	end
end

-- ��ȡĿ���������������
---@param obj userdata | string @Ŀ������Ŀ��ID
---@return number @Ŀ���������������
function X.GetObjectEndurance(obj)
	local scene, nType, nIndex = GetObjectSceneIndex(X.IsUserdata(obj) and obj.dwID or obj)
	if scene and nType and nIndex then
		return scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 12),
			scene.GetTempCustomUnsigned4(nType, nIndex * 20 + 1 + 16)
	end
end
end

-- ����ģ��ID��ȡNPC��ʵ����
local NPC_NAME_CACHE, DOODAD_NAME_CACHE = {}, {}
function X.GetTemplateName(dwType, dwTemplateID)
	local CACHE = dwType == TARGET.NPC and NPC_NAME_CACHE or DOODAD_NAME_CACHE
	local szName
	if CACHE[dwTemplateID] then
		szName = CACHE[dwTemplateID]
	end
	if not szName then
		if dwType == TARGET.NPC then
			szName = X.CONSTANT.NPC_NAME[dwTemplateID]
				and X.RenderTemplateString(X.CONSTANT.NPC_NAME[dwTemplateID])
				or Table_GetNpcTemplateName(dwTemplateID)
		else
			szName = X.CONSTANT.DOODAD_NAME[dwTemplateID]
				and X.RenderTemplateString(X.CONSTANT.DOODAD_NAME[dwTemplateID])
				or Table_GetDoodadTemplateName(dwTemplateID)
		end
		if szName then
			szName = szName:gsub('^%s*(.-)%s*$', '%1')
		end
		CACHE[dwTemplateID] = szName or ''
	end
	if X.IsEmpty(szName) then
		szName = nil
	end
	return szName
end

-- ��ȡָ�����������
-- X.GetObjectName(obj, eRetID)
-- X.GetObjectName(dwType, dwID, eRetID)
-- (KObject) obj    Ҫ��ȡ���ֵĶ���
-- (string)  eRetID �Ƿ񷵻ض���ID��Ϣ
--    'auto'   ����Ϊ��ʱ���� -- Ĭ��ֵ
--    'always' ���Ƿ���
--    'never'  ���ǲ�����
local OBJECT_NAME = {
	['PLAYER'   ] = X.CreateCache('LIB#GetObjectName#PLAYER.v'   ),
	['NPC'      ] = X.CreateCache('LIB#GetObjectName#NPC.v'      ),
	['DOODAD'   ] = X.CreateCache('LIB#GetObjectName#DOODAD.v'   ),
	['ITEM'     ] = X.CreateCache('LIB#GetObjectName#ITEM.v'     ),
	['ITEM_INFO'] = X.CreateCache('LIB#GetObjectName#ITEM_INFO.v'),
	['UNKNOWN'  ] = X.CreateCache('LIB#GetObjectName#UNKNOWN.v'  ),
}
function X.GetObjectName(arg0, arg1, arg2, arg3, arg4)
	local KObject, szType, dwID, nExtraID, eRetID
	if X.IsNumber(arg0) then
		local dwType = arg0
		dwID, eRetID = arg1, arg2
		KObject = X.GetObject(dwType, dwID)
		if dwType == TARGET.PLAYER then
			szType = 'PLAYER'
		elseif dwType == TARGET.NPC then
			szType = 'NPC'
		elseif dwType == TARGET.DOODAD then
			szType = 'DOODAD'
		else
			szType = 'UNKNOWN'
		end
	elseif X.IsString(arg0) then
		if arg0 == 'PLAYER' or arg0 == 'NPC' or arg0 == 'DOODAD' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			else
				local dwType = TARGET[arg0]
				dwID, eRetID = arg1, arg2
				KObject = X.GetObject(dwType, dwID)
				szType = arg0
			end
		elseif arg0 == 'ITEM' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				local p = X.GetPlayer(arg1)
				if p then
					KObject = p.GetItem(arg2, arg3)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg4
				end
			elseif X.IsNumber(arg2) then
				local p = X.GetClientPlayer()
				if p then
					KObject = p.GetItem(arg1, arg2)
					if KObject then
						dwID = KObject.dwID
					end
					eRetID = arg3
				end
			else
				dwID, eRetID = arg1, arg2
				KObject = GetItem(dwID)
			end
			szType = 'ITEM'
		elseif arg0 == 'ITEM_INFO' then
			if X.IsUserdata(arg1) then
				KObject = arg1
				dwID, eRetID = KObject.dwID, arg2
			elseif X.IsNumber(arg3) then
				dwID = arg1 .. ':' .. arg2 .. ':' .. arg3
				nExtraID = arg3
				eRetID = arg4
			else
				dwID = arg1 .. ':' .. arg2
				eRetID = arg3
			end
			KObject = GetItemInfo(arg1, arg2)
			szType = 'ITEM_INFO'
		else
			szType = 'UNKNOWN'
		end
	else
		KObject, eRetID = arg0, arg1
		if KObject then
			szType = X.GetObjectType(KObject)
			if szType == 'ITEM_INFO' then
				dwID = KObject.nGenre .. ':' .. KObject.dwID
			else
				dwID = KObject.dwID
			end
		end
	end
	if not dwID then
		return
	end
	if not eRetID then
		eRetID = 'auto'
	end
	local cache = OBJECT_NAME[szType][dwID]
	if not cache or (KObject and not cache.bFull) then -- �����ȡ���ƻ���
		local szDispType, szDispID, szName = '?', '', ''
		if KObject then
			szName = KObject.szName
		end
		if not cache then
			cache = { bFull = false }
		end
		if szType == 'PLAYER' then
			szDispType = 'P'
			cache.bFull = not X.IsEmpty(szName)
		elseif szType == 'NPC' then
			szDispType = 'N'
			if KObject then
				if X.IsEmpty(szName) then
					szName = X.GetTemplateName(TARGET.NPC, KObject.dwTemplateID)
				end
				if KObject.dwEmployer and KObject.dwEmployer ~= 0 then
					if X.Table.IsSimplePlayer(KObject.dwTemplateID) then -- ����Ӱ��
						szName = X.GetObjectName(X.GetPlayer(KObject.dwEmployer), eRetID)
					elseif not X.IsEmpty(szName) then
						local szEmpName = X.GetObjectName(
							(X.IsPlayer(KObject.dwEmployer) and X.GetPlayer(KObject.dwEmployer)) or X.GetNpc(KObject.dwEmployer),
							'never'
						)
						if szEmpName then
							cache.bFull = true
						else
							szEmpName = g_tStrings.STR_SOME_BODY
						end
						local szBaseName, szSuffixName, szServerName = X.DisassemblePlayerName(szEmpName)
						szName = X.AssemblePlayerName(szBaseName .. g_tStrings.STR_PET_SKILL_LOG .. szName, szSuffixName, szServerName)
					end
				else
					cache.bFull = true
				end
			end
		elseif szType == 'DOODAD' then
			szDispType = 'D'
			if KObject and X.IsEmpty(szName) then
				szName = X.Table.GetDoodadTemplateName(KObject.dwTemplateID)
				if szName then
					szName = szName:gsub('^%s*(.-)%s*$', '%1')
				end
			end
			cache.bFull = true
		elseif szType == 'ITEM' then
			szDispType = 'I'
			if KObject then
				szName = X.GetItemNameByItem(KObject)
			end
			cache.bFull = true
		elseif szType == 'ITEM_INFO' then
			szDispType = 'II'
			if KObject then
				szName = X.GetItemNameByItemInfo(KObject, nExtraID)
			end
			cache.bFull = true
		else
			szDispType = '?'
			cache.bFull = false
		end
		if szType == 'NPC' then
			szDispID = X.ConvertNpcID(dwID)
			if KObject then
				szDispID = szDispID .. '@' .. KObject.dwTemplateID
			end
		else
			szDispID = dwID
		end
		if X.IsEmpty(szName) then
			szName = nil
		end
		cache['never'] = szName
		if szName then
			cache['auto'] = szName
			cache['always'] = szName .. '(' .. szDispType .. szDispID .. ')'
		else
			cache['auto'] = szDispType .. szDispID
			cache['always'] = szDispType .. szDispID
		end
		OBJECT_NAME[szType][dwID] = cache
	end
	return cache and cache[eRetID] or nil
end

-- ��N2��N1�������  --  ����+2
-- (number) X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
-- (number) X.GetFaceAngel(oN1, oN2, bAbs)
-- @param nX    N1��X����
-- @param nY    N1��Y����
-- @param nFace N1������[0, 255]
-- @param nTX   N2��X����
-- @param nTY   N2��Y����
-- @param bAbs  ���ؽǶ��Ƿ�ֻ��������
-- @param oN1   N1����
-- @param oN2   N2����
-- @return nil    ��������
-- @return number �����(-180, 180]
function X.GetFaceAngel(nX, nY, nFace, nTX, nTY, bAbs)
	if type(nY) == 'userdata' and type(nX) == 'userdata' then
		nX, nY, nFace, nTX, nTY, bAbs = nX.nX, nX.nY, nX.nFaceDirection, nY.nX, nY.nY, nFace
	end
	if type(nX) == 'number' and type(nY) == 'number' and type(nFace) == 'number'
	and type(nTX) == 'number' and type(nTY) == 'number' then
		local nFace = (nFace * 2 * math.pi / 255) - math.pi
		local nSight = (nX == nTX and ((nY > nTY and math.pi / 2) or - math.pi / 2)) or math.atan((nTY - nY) / (nTX - nX))
		local nAngel = ((nSight - nFace) % (math.pi * 2) - math.pi) / math.pi * 180
		if bAbs then
			nAngel = math.abs(nAngel)
		end
		return nAngel
	end
end

--------------------------------------------------------------------------------
-- ��ɫ״̬
--------------------------------------------------------------------------------

-- ��ȡ�����Ƿ��޵�
-- (mixed) X.IsInvincible([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object invincible state
function X.IsInvincible(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return nil
	elseif X.GetBuff(KObject, 961) then
		return true
	else
		return false
	end
end

-- ��ȡ�����Ƿ񱻸���
-- (mixed) X.IsIsolated([object KObject])
-- @return <nil >: invalid KObject
-- @return <bool>: object isolated state
function X.IsIsolated(...)
	local KObject = ...
	if select('#', ...) == 0 then
		KObject = X.GetClientPlayer()
	end
	if not KObject then
		return false
	end
	if X.IS_CLASSIC then
		return false
	end
	return KObject.bIsolated
end

--------------------------------------------------------------------------------
-- ��ɫģ������״̬
--------------------------------------------------------------------------------

do
local CURRENT_NPC_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_ALL = true
local CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
X.RegisterEvent('ON_REPRESENT_CMD', 'LIB#PLAYER_DISPLAY_MODE', function()
	if arg0 == 'show npc' then
		CURRENT_NPC_SHOW_ALL = true
	elseif arg0 == 'hide npc' then
		CURRENT_NPC_SHOW_ALL = false
	elseif arg0 == 'show player' then
		CURRENT_PLAYER_SHOW_ALL = true
	elseif arg0 == 'hide player' then
		CURRENT_PLAYER_SHOW_ALL = false
	elseif arg0 == 'show or hide party player 1' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = true
	elseif arg0 == 'show or hide party player 0' then
		CURRENT_PLAYER_SHOW_PARTY_OVERRIDE = false
	end
end)

--- ��ȡ NPC ��ʾ״̬
---@return boolean @NPC �Ƿ���ʾ
function X.GetNpcVisibility()
	return CURRENT_NPC_SHOW_ALL
end

--- ���� NPC ��ʾ״̬
---@param bShow boolean @NPC �Ƿ���ʾ
function X.SetNpcVisibility(bShow)
	if bShow then
		rlcmd('show npc')
	else
		rlcmd('hide npc')
	end
end

--- ��ȡ�����ʾ״̬
---@return boolean, boolean @����Ƿ���ʾ @�����Ƿ�ǿ����ʾ
function X.GetPlayerVisibility()
	if UIGetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		local eMode = UIGetPlayerDisplayMode()
		if eMode == PLAYER_DISPLAY_MODE.ALL then
			return true, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_PARTY then
			return false, true
		end
		if eMode == PLAYER_DISPLAY_MODE.ONLY_SELF then
			return false, false
		end
		return true, false
	end
	return CURRENT_PLAYER_SHOW_ALL, CURRENT_PLAYER_SHOW_PARTY_OVERRIDE
end

--- ���������ʾ״̬
---@param bShowAll boolean @����Ƿ���ʾ
---@param bShowPartyOverride boolean @�����Ƿ�ǿ����ʾ
function X.SetPlayerVisibility(bShowAll, bShowPartyOverride)
	if UISetPlayerDisplayMode and PLAYER_DISPLAY_MODE then
		if bShowAll then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ALL)
		end
		if bShowPartyOverride then
			return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_PARTY)
		end
		return UISetPlayerDisplayMode(PLAYER_DISPLAY_MODE.ONLY_SELF)
	end
	if bShowAll then
		rlcmd('show player')
	else
		rlcmd('hide player')
	end
	if bShowPartyOverride then
		rlcmd('show or hide party player 1')
	else
		rlcmd('show or hide party player 0')
	end
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
