--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ɾ�ͬ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBAchievementSync'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBAchievementSync'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}

function D.EncodeAchievement()
	local me = X.GetClientPlayer()
	local Achievement = X.GetGameTable('Achievement', true)
	local achi = Achievement and Achievement:GetRow(Achievement:GetRowCount())
	local nMaxIndex = achi and achi.dwID
	local aByte = {}
	local aBit = {0, 0, 0, 0, 0, 0, 0, 0}
	local nIndex = 0
	while nIndex <= nMaxIndex do
		for nOffset = 0, 7 do
			aBit[nOffset + 1] = me.IsAchievementAcquired(nIndex + nOffset) or 0
		end
		table.insert(aByte, string.char(X.Bitmap2Number(aBit)))
		nIndex = nIndex + 8
	end
	local szBin = table.concat(aByte)
	local szCompressBin = X.Deflate:CompressZlib(szBin)
	local szCompressBinBase64 = X.Base64Encode(szCompressBin)
	return szCompressBinBase64
end

function D.Sync(resolve, reject)
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/api/achievements',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetPlayerGUID(),
			achievements = D.EncodeAchievement(),
		},
		signature = X.SECRET['J3CX::ACHIEVEMENT_SYNC'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			Output(szHTML)
			if X.Get(res, {'code'}) == 0 then
				X.Alert((X.Get(res, {'msg'}, _L['Sync success.'])))
				X.SafeCall(resolve)
			else
				X.Alert((X.Get(res, {'msg'}, _L['Request failed.'])))
				X.SafeCall(reject)
			end
		end,
	})
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	-- �ɾ�ͬ��
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2, w = 'auto',
		buttonStyle = 'FLAT', text = _L['Sync achievement'],
		onClick = function()
			D.Sync()
		end,
	}):Width()

	nLFY = nY + nLH
	return nX, nY, nLFY
end

-- Global exports
do
local settings = {
	name = 'MY_JBAchievementSync',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_JBAchievementSync = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
