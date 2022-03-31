--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ƽѪ�� - �ٷ��й�
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
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end

if ENVIRONMENT.GAME_EDITION ~= 'zhcn_exp' and not IsLocalFileExist(X.FormatPath({'config/lifebar-official.jx3dat', X.PATH_TYPE.GLOBAL})) then
	return
end
--------------------------------------------------------------------------

local D = {}
local COUNTDOWN_CACHE = {}

local CACHE_ON_TOP, nTop = {}
local function SetCaptionOnTop(dwID, bTop)
	nTop = bTop and 1 or 0
	if CACHE_ON_TOP[dwID] == nTop then
		return
	end
	CACHE_ON_TOP[dwID] = nTop
	rlcmd('set caption on top ' .. dwID .. ' ' .. nTop)
end
local function ApplyCaptionOnTop(dwID)
	nTop = CACHE_ON_TOP[dwID]
	if not nTop then
		return
	end
	rlcmd('set caption on top ' .. dwID .. ' ' .. nTop)
end

local CACHE_ZOOM_IN, nZoomIn = {}
local function SetCaptionZoomIn(dwID, bZoomIn)
	nZoomIn = bZoomIn and 1 or 0
	if CACHE_ZOOM_IN[dwID] == nZoomIn then
		return
	end
	CACHE_ZOOM_IN[dwID] = nZoomIn
	rlcmd('set caption zoom in ' .. dwID .. ' ' .. nZoomIn)
end
local function ApplyCaptionZoomIn(dwID)
	nZoomIn = CACHE_ZOOM_IN[dwID]
	if not nZoomIn then
		return
	end
	rlcmd('set caption zoom in ' .. dwID .. ' ' .. nZoomIn)
end

local CACHE_EXTRA_TEXT, szExtraText = {}
local function SetCaptionExtraText(dwID, szExtraText)
	if CACHE_EXTRA_TEXT[dwID] == szExtraText then
		return
	end
	CACHE_EXTRA_TEXT[dwID] = szExtraText
	rlcmd('set caption extra text ' .. dwID .. ' ' .. szExtraText)
end
local function ApplyCaptionExtraText(dwID)
	szExtraText = CACHE_EXTRA_TEXT[dwID]
	if not szExtraText then
		return
	end
	rlcmd('set caption extra text ' .. dwID .. ' ' .. szExtraText)
end

local CACHE_CAPTION_COLOR, tColor = {}
local function SetCaptionColor(dwID, nR, nG, nB)
	tColor = CACHE_CAPTION_COLOR[dwID]
	if tColor and tColor.nR == nR and tColor.nG == nG and tColor.nB == nB then
		return
	end
	tColor = { nR = nR, nG = nG, nB = nB, dwColor = 255 * 16777216 + nR * 65536 + nG * 256 + nB }
	CACHE_CAPTION_COLOR[dwID] = tColor
	Output('set plugin caption color ' .. dwID .. ' 1 ' .. tColor.dwColor, tColor)
	rlcmd('set plugin caption color ' .. dwID .. ' 1 ' .. tColor.dwColor)
end
local function ApplyCaptionColor(dwID)
	tColor = CACHE_CAPTION_COLOR[dwID]
	if not tColor then
		return
	end
	rlcmd('set plugin caption color ' .. dwID .. ' 1 ' .. tColor.dwColor)
end

local function ApplyCaption(dwID)
	ApplyCaptionOnTop(dwID)
	ApplyCaptionZoomIn(dwID)
	ApplyCaptionExtraText(dwID)
	ApplyCaptionColor(dwID)
end

local function ResetCaption(dwID)
	CACHE_ON_TOP[dwID] = nil
	CACHE_ZOOM_IN[dwID] = nil
	CACHE_EXTRA_TEXT[dwID] = nil
	CACHE_CAPTION_COLOR[dwID] = nil
	rlcmd('reset caption ' .. dwID)
end

function D.PrioritySorter(a, b)
	if not b.nPriority then
		return true
	end
	if not a.nPriority then
		return false
	end
	return a.nPriority < b.nPriority
end

local KTarget, aCountDown, nR, nG, nB
local tCountDownItem, szCountDownText, nCountDownSecond, fCountDownPercent
function D.DrawLifeBar(dwID)
	KTarget = (IsPlayer(dwID) and GetPlayer or GetNpc)(dwID)
	if not KTarget then
		return
	end
	aCountDown = COUNTDOWN_CACHE[dwID]
	nR, nG, nB = nil, nil, nil
	while aCountDown and #aCountDown > 0 do
		tCountDownItem, szCountDownText, nCountDownSecond, fCountDownPercent = aCountDown[1], nil, nil, nil
		-- ���ݲ�ͬ���͵���ʱ���㵹��ʱʱ�䡢����
		if tCountDownItem.szType == 'BUFF' or tCountDownItem.szType == 'DEBUFF' then
			local KBuff = KTarget.GetBuff(tCountDownItem.dwBuffID, 0)
			if KBuff then
				nCountDownSecond = (KBuff.GetEndTime() - GetLogicFrameCount()) / ENVIRONMENT.GAME_FPS
				szCountDownText = tCountDownItem.szText or X.GetBuffName(KBuff.dwID, KBuff.nLevel)
				if KBuff.nStackNum > 1 then
					szCountDownText = szCountDownText .. 'x' .. KBuff.nStackNum
				end
			end
		elseif tCountDownItem.szType == 'CASTING' then
			local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetOTActionState(KTarget)
			if dwSkillID == tCountDownItem.dwSkillID
			and (
				nType == CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
				or nType == CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE
			) then
				fCountDownPercent = fCastPercent
				szCountDownText = tCountDownItem.szText or X.GetSkillName(dwSkillID, dwSkillLevel)
			end
		elseif tCountDownItem.szType == 'NPC' or tCountDownItem.szType == 'DOODAD' then
			szCountDownText = tCountDownItem.szText or ''
		else --if tData.szType == 'TIME' then
			if tCountDownItem.nLogicFrame then
				nCountDownSecond = (tCountDownItem.nLogicFrame - GetLogicFrameCount()) / ENVIRONMENT.GAME_FPS
			elseif tCountDownItem.nTime then
				nCountDownSecond = (tCountDownItem.nTime - GetTime()) / 1000
			end
			if nCountDownSecond > 0 then
				szCountDownText = tCountDownItem.szText or ''
			end
		end
		-- ʣ��ʱ�䲻�����㲻��Ҫ��ʾ
		if nCountDownSecond and nCountDownSecond <= 0 then
			nCountDownSecond = nil
		end
		-- �ٷֱȲ������㲻��Ҫ��ʾ
		if fCountDownPercent and fCountDownPercent <= 0 then
			fCountDownPercent = nil
		end
		-- ����ǿ��õ���ʱ��ʾ���ж�ʣ����ж�
		if szCountDownText then
			if tCountDownItem.tColor then
				nR, nG, nB = unpack(tCountDownItem.tColor)
			end
			if not X.IsEmpty(szCountDownText) and not tCountDownItem.bHideProgress then
				if nCountDownSecond then
					szCountDownText = szCountDownText .. '_' .. X.FormatDuration(math.min(nCountDownSecond, 5999), 'PRIME')
				elseif fCountDownPercent then
					szCountDownText = szCountDownText .. '_' .. math.floor(fCountDownPercent * 100) .. '%'
				end
			end
			break
		end
		-- ���û���ҵ����õ���ʱ�����Ƴ��õ���ʱ
		table.remove(aCountDown, 1)
	end
	if szCountDownText then
		SetCaptionOnTop(dwID, true)
		SetCaptionZoomIn(dwID, true)
		SetCaptionExtraText(dwID, szCountDownText)
		if nR and nG and nB then
			SetCaptionColor(dwID, nR, nG, nB)
		end
	elseif #aCountDown == 0 then
		COUNTDOWN_CACHE[dwID] = nil
		ResetCaption(dwID)
	end
end

X.BreatheCall('MY_LifeBar', function()
	for dwID, _ in pairs(COUNTDOWN_CACHE) do
		D.DrawLifeBar(dwID)
	end
end)

X.RegisterEvent('MY_LIFEBAR_COUNTDOWN', function()
	local dwID, szType, szKey, tData = arg0, arg1, arg2, arg3
	if not COUNTDOWN_CACHE[dwID] then
		COUNTDOWN_CACHE[dwID] = {}
	end
	for i, p in X.ipairs_r(COUNTDOWN_CACHE[dwID]) do
		if p.szType == szType and p.szKey == szKey then
			table.remove(COUNTDOWN_CACHE[dwID], i)
		end
	end
	if tData then
		local tData = X.Clone(tData)
		if tData.col then
			local r, g, b = X.HumanColor2RGB(tData.col)
			if r and g and b then
				tData.tColor = {r, g, b}
			end
			tData.col = nil
		end
		tData.szType = szType
		tData.szKey = szKey
		table.insert(COUNTDOWN_CACHE[dwID], 1, tData)
		table.sort(COUNTDOWN_CACHE[dwID], D.PrioritySorter)
	elseif #COUNTDOWN_CACHE[dwID] == 0 then
		COUNTDOWN_CACHE[dwID] = nil
		ResetCaption(dwID)
	end
end)

X.RegisterEvent({'PLAYER_ENTER_SCENE', 'NPC_ENTER_SCENE'}, 'MY_LifeBar', function()
	local dwID = arg0
	X.DelayCall(function() ApplyCaption(dwID) end)
	X.DelayCall(200, function() ApplyCaption(dwID) end)
	X.DelayCall(500, function() ApplyCaption(dwID) end)
end)
