--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ������Ⱦ��Ӱ
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = Boilerplate
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------

local D = {}
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Shadows.ini'
local FRAME_NAME = X.NSFormatString('{$NS}_Shadows')

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	this:RegisterEvent('ON_FRAME_CREATE')
	UI(this):BringToBottom()
end

do
local VISIBLE = true
function D.OnFrameBreathe()
	if Station.IsVisible() then
		if not VISIBLE then
			local h = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				h:Lookup(i):SetVisible(true)
			end
			VISIBLE = true
		end
	else
		if VISIBLE then
			local h, hh = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				hh = h:Lookup(i)
				hh:SetVisible(hh.bShowWhenUIHide or false)
			end
			VISIBLE = false
		end
	end
end
end

function D.OnEvent(event)
	if event == 'LOADING_END' then
		this:Show()
	elseif event == 'COINSHOP_ON_OPEN' or event == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif event == 'COINSHOP_ON_CLOSE' or event == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	elseif event == 'ON_FRAME_CREATE' then
		UI(this):BringToBottom()
	end
end

function UI.GetShadowHandle(szName)
	local frame = Station.SearchFrame(FRAME_NAME)
	if frame and not X.IsElement(frame) then -- �ر���Ч�� frame ���
		Wnd.CloseWindow(FRAME_NAME)
		frame = nil
	end
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, FRAME_NAME)
	end
	local sh = frame:Lookup('', szName)
	if sh and not X.IsElement(sh) then -- �ر���Ч�� sh ���
		frame:Lookup('', ''):Remove(sh)
		sh = nil
	end
	if not sh then
		frame:Lookup('', ''):AppendItemFromString(string.format('<handle> name="%s" </handle>', szName))
		--[[#DEBUG BEGIN]]
		X.Debug('UI', 'Create sh # ' .. szName, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		sh = frame:Lookup('', szName)
	end
	return sh
end

function UI.SetShadowHandleParam(szName, tParam)
	local sh = UI.GetShadowHandle(szName)
	for k, v in pairs(tParam) do
		sh[k] = v
	end
end

do local VISIBLES = {}
function UI.TempSetShadowHandleVisible(bVisible)
	local frame = Station.SearchFrame(FRAME_NAME)
	if not frame then
		return table.insert(VISIBLES, true)
	end
	table.insert(VISIBLES, frame:IsVisible() or false)
	frame:SetVisible(bVisible)
end

function UI.RevertShadowHandleVisible()
	if #VISIBLES == 0 then
		return
	end
	local bVisible = table.remove(VISIBLES)
	local frame = Station.SearchFrame(FRAME_NAME)
	if frame then
		frame:SetVisible(bVisible)
	end
end
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end
