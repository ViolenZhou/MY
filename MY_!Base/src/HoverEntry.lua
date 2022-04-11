--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����������
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
local PLUGIN_NAME = X.NSFormatString('{$NS}_HoverEntry')
local PLUGIN_ROOT = X.PACKET_INFO.FRAMEWORK_ROOT
local MODULE_NAME = X.NSFormatString('{$NS}_HoverEntry')
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/hoverentry/')
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule(MODULE_NAME, _L['System'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Number,
		xDefaultValue = 30,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = -362, y = -78, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' },
	},
	bHoverMenu = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}
local FRAME_NAME = MODULE_NAME

function D.Popup()
	local addonmenu = X.GetTraceButtonAddonMenu()[1]
	local menu = {
		bDisableSound = true,
		{
			szOption = addonmenu.szOption,
			rgb = addonmenu.rgb,
		},
		CONSTANT.MENU_DIVIDER,
	}
	for i, v in ipairs(addonmenu) do
		table.insert(menu, v)
	end
	UI.PopupMenu(menu)
end

function D.CheckEnable()
	Wnd.CloseWindow(FRAME_NAME)
	if O.bEnable then
		local frame = UI.CreateFrame(FRAME_NAME, {
			empty = true,
			w = O.nSize, h = O.nSize,
			anchor = O.anchor,
		})
		UI(frame):Append('Image', {
			w = O.nSize, h = O.nSize,
			image = X.PACKET_INFO.LOGO_UITEX,
			imageFrame = X.PACKET_INFO.LOGO_MAIN_FRAME,
			onHover = function(bIn)
				if bIn and O.bHoverMenu then
					D.Popup()
				end
			end,
			onClick = D.Popup,
		})
	end
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'HoverEntry', D.CheckEnable)

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		UI(this):Anchor(O.anchor)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['HoverEntry'])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L['HoverEntry'])
	end
end

function D.OnFrameDragEnd()
	O.anchor = GetFrameAnchor(this)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX = nPaddingX
	nY = nLFY
	ui:Append('Text', {
		x = nPaddingX - 10, y = nY,
		text = _L['HoverEntry'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Enable'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
			D.CheckEnable()
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Hover popup'],
		checked = O.bHoverMenu,
		onCheck = function(bChecked)
			O.bHoverMenu = bChecked
			D.CheckEnable()
		end,
		autoEnable = function() return O.bEnable end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 100, h = 25,
		value = O.nSize,
		range = {1, 300},
		trackbarStyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		textFormatter = function(v) return _L('Size: %d', v) end,
		onChange = function(val)
			O.nSize = val
			D.CheckEnable()
		end,
		autoEnable = function() return O.bEnable end,
	}):AutoWidth():Width() + 5
	nX, nY = nPaddingX, nY + 30

	nLFY = nY + nLH
	return nX, nY, nLFY
end

-- Global exports
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end
