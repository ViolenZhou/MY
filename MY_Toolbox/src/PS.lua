--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ���ù���
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/PS'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

do
local TARGET_TYPE, TARGET_ID
local function onHotKey()
	if TARGET_TYPE then
		X.SetTarget(TARGET_TYPE, TARGET_ID)
		TARGET_TYPE, TARGET_ID = nil
	else
		TARGET_TYPE, TARGET_ID = X.GetTarget()
		X.SetTarget(TARGET.PLAYER, X.GetClientPlayerID())
	end
end
X.RegisterHotKey('MY_AutoLoopMeAndTarget', _L['Loop target between me and target'], onHotKey)
end

local PS = { nPriority = 0 }
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 25, 25
	local nW, nH = ui:Size()
	local nX, nY = nPaddingX, nPaddingY
	local nLH = 28

	-- Ŀ��
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Target'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_FooterTip.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	-- ս��
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Battle'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_VisualSkill.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_DynamicActionBarPos.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ArenaHelper.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_ShenxingHelper.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	-- ����
	nX = nPaddingX
	nY = nY + ui:Append('Text', { x = nX, y = nY, h = 'auto', text = _L['Others'], color = {255, 255, 0} }):Height() + 5
	nX = nX + 10
	nX, nY = MY_AchievementWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_PetWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_QuestWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_RideWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ItemWiki.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_ItemPrice.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_YunMacro.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_AutoDiamond.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_HideAnnounceBg.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = MY_FriendTipLocation.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_Domesticate.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = MY_Memo.OnPanelActivePartial(ui, nPaddingX + 10, nPaddingY, nW, nH, nX, nY, nLH)

	nX, nY = MY_AutoSell.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX, nY = nPaddingX + 10, nY + nLH
	nX, nY = MY_DynamicItem.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)

	-- �Ҳม��
	MY_GongzhanCheck.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	MY_LockFrame.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
end
X.RegisterPanel(_L['General'], 'MY_Toolbox', _L['MY_Toolbox'], 134, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
