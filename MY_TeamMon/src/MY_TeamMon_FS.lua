--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ȫ������
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
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
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
X.RegisterRestriction('MY_TeamMon_FS', { ['*'] = true })
--------------------------------------------------------------------------

local GetBuff = X.GetBuff

local D = {}
local FS = {}
FS.__index = FS

local FS_HANDLE, FS_FRAME
local FS_CACHE   = setmetatable({}, { __mode = 'v' })
local FS_INIFILE = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_FS.ini'

-- FireUIEvent('MY_TM_FS_CREATE', Random(50, 255), { col = { Random(50, 255), Random(50, 255), Random(50, 255) }, bFlash = true})
local function CreateFullScreen(szKey, tArgs)
	if X.IsRestricted('MY_TeamMon_FS') then
		return
	end
	assert(type(tArgs) == 'table', 'CreateFullScreen failed!')
	tArgs.nTime = tArgs.nTime or 3
	if tArgs.tBindBuff then
		FS:ctor(szKey, tArgs):DrawEdge()
	else
		FS:ctor(szKey, tArgs)
	end
end

function D.Init()
	Wnd.CloseWindow('MY_TeamMon_FS')
	Wnd.OpenWindow(FS_INIFILE, 'MY_TeamMon_FS'):Hide()
end

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('MY_TM_FS_CREATE')

	this.hItem = this:CreateItemData(FS_INIFILE, 'Handle_Item')
	FS_FRAME   = this
	FS_HANDLE  = this:Lookup('', '')
	FS_HANDLE:Clear()
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TM_FS_CREATE' then
		CreateFullScreen(arg0, arg1)
	elseif szEvent == 'UI_SCALED' then
		for k, v in pairs(FS_CACHE) do
			if v.tBindBuff then
				v.obj:DrawEdge()
			end
		end
	elseif szEvent == 'LOADING_END' then
		FS_HANDLE:Clear()
	end
end

function D.OnFrameRender()
	local nNow = GetTime()
	for k, v in pairs(FS_CACHE) do
		if v:IsValid() then
			local nTime = ((nNow - v.nCreate) / 1000)
			local nLeft  = v.nTime - nTime
			if nLeft > 0 then
				if v.bFlash then
					local nTimeLeft = nTime * 1000 % 750
					local nAlpha = 150 * nTimeLeft / 750
					if math.floor(nTime / 0.75) % 2 == 1 then
						nAlpha = 150 - nAlpha
					end
					v.obj:DrawFullScreen(math.floor(nAlpha))
				else
					local nAlpha = 150 - 150 * nTime / v.nTime
					v.obj:DrawFullScreen(nAlpha)
				end
			else
				if v.sha1:IsValid() then
					if v.tBindBuff then
						v.obj:RemoveFullScreen()
					else
						v.obj:RemoveItem()
					end
				end
			end
			if v.tBindBuff then
				local dwID, nLevel = unpack(v.tBindBuff)
				local buff = GetBuff(GetClientPlayer(), dwID)
				if not buff then
					v.obj:RemoveItem()
				end
			end
		end
	end
end

function FS:ctor(szKey, tArgs)
	local el = FS_CACHE[szKey]
	local nTime = GetTime()
	local oo = {}
	setmetatable(oo, self)
	oo.key = szKey
	if not el or el and not el:IsValid() then
		el = FS_HANDLE:AppendItemFromData(FS_FRAME.hItem)
	end
	if el.sha1 and el.sha1:IsValid() then
		el.sha1 = el.sha1
	else
		el.sha1 = el:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini', 'Shadow')
		el.sha1:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		el.sha1:SetD3DPT(D3DPT.TRIANGLESTRIP)
	end
	el.bFlash  = tArgs.bFlash
	el.nTime   = tArgs.nTime
	el.nCreate = nTime
	el.col     = tArgs.col or { 255, 128, 0 }
	if tArgs.tBindBuff then
		if el.sha2 and el.sha2:IsValid() then
			el.sha2 = el.sha2
		else
			el.sha2 = el:AppendItemFromIni(X.PACKET_INFO.UICOMPONENT_ROOT .. 'Shadow.ini', 'Shadow')
			el.sha2:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
			el.sha2:SetD3DPT(D3DPT.TRIANGLESTRIP)
		end
		el.tBindBuff = tArgs.tBindBuff
	end
	oo.el = el
	oo.el.obj = oo
	FS_CACHE[szKey] = oo.el
	FS_FRAME:Show()
	return oo
end

function FS:DrawFullScreen( ... )
	self:DrawShadow(self.el.sha1, ...)
	return self
end

function FS:DrawEdge()
	self:DrawShadow(self.el.sha2, 220, 15, 15)
	return self
end

function FS:DrawShadow(sha, nAlpha, fScreenX, fScreenY)
	local r, g, b = unpack(self.el.col)
	local w, h = Station.GetClientSize()
	local bW, bH = fScreenX or w * 0.10, fScreenY or h * 0.10
	if sha:IsValid() then
		sha:ClearTriangleFanPoint()
		sha:AppendTriangleFanPoint(0, 0, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(0, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, h - bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(bW, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(w - bW, h - bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(w, h, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(w - bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(w, 0, r, g, b, nAlpha)
		sha:AppendTriangleFanPoint(bW, bH, r, g, b, 0)
		sha:AppendTriangleFanPoint(0, 0, r, g, b, nAlpha)
	end
	return self
end

function FS:RemoveFullScreen()
	self.el:RemoveItem(self.el.sha1)
	return self
end

function FS:RemoveItem()
	FS_HANDLE:RemoveItem(self.el)
	if FS_HANDLE:GetItemCount() == 0 then
		FS_FRAME:Hide()
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_TeamMon_FS', D.Init)

-- Global exports
do
local settings = {
	name = 'MY_TeamMon_FS',
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_TeamMon_FS = X.CreateModule(settings)
end
