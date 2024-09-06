--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Chat/PS'
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Chat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nLineH = 29

	if MY_Farbnamen and MY_Farbnamen.OnPanelActivePartial then
		nX, nY = MY_Farbnamen.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	end
	nX, nY = MY_ChatSwitch.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	nX, nY = MY_TeamBalloon.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	nX, nY = MY_ChatCopy.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	nX, nY = MY_AutoHideChat.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	nX, nY = MY_WhisperMention.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
	nX, nY = MY_ChatEmotion.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLineH)
end
X.PS.RegisterPanel(_L['Chat'], 'MY_ChatSwitch', _L['chat helper'], 'UI/Image/UICommon/ActivePopularize2.UITex|20', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
