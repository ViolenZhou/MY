--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����������ɴ���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local PROXY = {}
if IsDebugClient() then
function PROXY.DebugSetVal(szKey, oVal)
	PROXY[szKey] = oVal
end
end

for k, v in pairs(X) do
	PROXY[k] = v
	X[k] = nil
end
setmetatable(X, {
	__metatable = true,
	__index = PROXY,
	__newindex = function() assert(false, X.NSFormatString('DO NOT modify {$NS} after initialized!!!')) end,
	__tostring = function(t) return X.NSFormatString('{$NS} (base library)') end,
})
FireUIEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'))

X.RegisterInit(X.NSFormatString('{$NS}#AUTHOR_TIP'), function()
	local Farbnamen = _G.MY_Farbnamen
	if Farbnamen and Farbnamen.RegisterHeader then
		for dwID, szName in X.pairs_c(X.PACKET_INFO.AUTHOR_ROLES) do
			Farbnamen.RegisterHeader(szName, dwID, X.PACKET_INFO.AUTHOR_HEADER)
		end
		for szName, _ in X.pairs_c(X.PACKET_INFO.AUTHOR_PROTECT_NAMES) do
			Farbnamen.RegisterHeader(szName, '*', X.PACKET_INFO.AUTHOR_FAKE_HEADER)
		end
	end
end)

do
local function OnKeyPanelBtnLButtonUp()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	local szText = X.DecryptString('2,' .. edit:GetText())
	if not szText then
		return
	end
	local aParam = X.DecodeLUAData(szText)
	if not X.IsTable(aParam) then
		return
	end
	if aParam[1] ~= X.PACKET_INFO.NAME_SPACE then
		return
	end
	local aCRC = X.SplitString(aParam[2], ',')
	local szCorrect = tostring(MD5(X.GetUserRoleName() .. '65e33433-d13c-4269-adac-f091d4a57d4b')):sub(-6)
	if not lodash.includes(aCRC, szCorrect) then
		return
	end
	local nExpire = tonumber(aParam[3] or '')
	if not nExpire or (nExpire ~= 0 and nExpire < GetCurrentTime()) then
		return
	end
	local szCmd = aParam[4]
	if szCmd == 'R' then
		for _, szKey in ipairs(aParam[5]) do
			X.IsRestricted(szKey, false)
		end
	end
	frame:Destroy()
	PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
end
local function HookKeyPanel()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	edit:SetLimit(-1)
	HookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
local function UnhookPanel()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	UnhookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
X.RegisterFrameCreate('KeyPanel', 'LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterInit('LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterReload('LIB.KeyPanel_Restriction', UnhookPanel)
end
