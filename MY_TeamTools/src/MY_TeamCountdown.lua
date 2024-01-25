--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Ŷӵ���ʱ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamCountdown'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamCountdown'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_TeamCountdown', _L['Raid'], {
	nCountdown = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		xSchema = X.Schema.Number,
		xDefaultValue = 5,
	},
})
local D = {}

function D.Open()
	if not X.IsLeader() then
		X.Topmsg(_L['You are not leader!'])
		return
	end
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
		X.Topmsg(_L['Please unlock safety talk lock first!'])
		return
	end
	GetUserInput(_L['Team countdown seconds'], function(text)
		local nCountdown = tonumber(text)
		if not nCountdown then
			X.Topmsg(_L['Invalid countdown time input.'])
			return
		end
		if nCountdown > 10 then
			X.Topmsg(_L('Countdown time cannot be more than %ds.', 10))
			return
		end
		if nCountdown < 1 then
			X.Topmsg(_L('Countdown time cannot be less than %ds.', 1))
			return
		end
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_TeamCountdown', {nCountdown}, true)
		O.nCountdown = nCountdown
	end, nil, nil, nil, tostring(O.nCountdown), 50)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nX, y = nY + 15, text = _L['MY_TeamCountdown'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = nPaddingX + 10
	nY = nY + 5
	nX = ui:Append('WndButton', {
		x = nX + 5, y = nY, w = 200,
		text = _L['Send team countdown'],
		buttonStyle = 'FLAT',
		onClick = D.Open,
	}):Pos('BOTTOMRIGHT')
	nY = nY + 28

	return nX, nY
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamCountdown',
	exports = {
		{
			fields = {
				Open = D.Open,
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_TeamCountdown = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------
X.RegisterBgMsg('MY_TeamCountdown', function(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not X.IsLeader(dwTalkerID) then
		return
	end
	local nCountdown = data[1]
	if X.IsNumber(nCountdown) and nCountdown >= 1 and nCountdown <= 10 then
		if X.IsLeader() then
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['[TeamCountdown] Fight Countdown Begin!'])
		end
		X.BreatheCall('MY_TeamCountdown', 1000, function()
			local szText = nCountdown == 0 and _L['Fight Begin'] or tostring(nCountdown)
			X.UI.CreateFloatText(szText, 1000, {
				nFont = 230,
				fScale = 10,
				nR = 255,
				nG = 255,
				nB = 0,
				szAnimation = 'ZOOM_IN_FADE_IN_OUT',
			})
			if X.IsLeader() then
				X.SendChat(
					PLAYER_TALK_CHANNEL.RAID,
					nCountdown == 0
						and _L['[TeamCountdown] Fight Begin!']
						or _L('[TeamCountdown] %ds!', nCountdown)
				)
			end
			-- ����
			if nCountdown <= 0 then
				return 0
			end
			nCountdown = nCountdown - 1
		end)
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
