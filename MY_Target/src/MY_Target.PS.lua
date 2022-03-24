--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Ŀ��������ʾ�ȹ����������
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
local PLUGIN_NAME = 'MY_Target'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Target'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
X.RegisterRestriction('MY_Target', { ['*'] = false, classic = true })
--------------------------------------------------------------------------

local PS = { szRestriction = 'MY_Target' }

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY
	local nLH = 26
	ui:Append('Text', { x = nX, y = nY, text = _L['Options'], font = 27 })

	-- target direction
	nX, nY = nPaddingX + 10, nY + nLH
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show target direction'],
		checked = MY_TargetDirection.bEnable,
		oncheck = function(bChecked)
			MY_TargetDirection.bEnable = bChecked
		end,
	}):AutoWidth():Width()

	ui:Append('WndComboBox', {
		x = nX, y = nY, w = 200, text = _L['Distance type'],
		menu = function()
			return X.GetDistanceTypeMenu(true, MY_TargetDirection.eDistanceType, function(p)
				MY_TargetDirection.eDistanceType = p.szType
			end)
		end,
	}):AutoWidth()

	if not X.IsRestricted('MY_TargetLine') then
		-- target line
		nX, nY = nPaddingX + 10, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the line from self to target'],
			checked = MY_TargetLine.bTarget,
			oncheck = function(bChecked)
				MY_TargetLine.bTarget = bChecked
			end,
		}):AutoWidth():Width()

		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['New style'],
			checked = MY_TargetLine.bTargetRL,
			oncheck = function(bChecked)
				MY_TargetLine.bTargetRL = bChecked
			end,
		}):AutoWidth():Width() + 10

		nX = nX + ui:Append('Shadow', {
			x = nX + 2, y = nY + 4, w = 18, h = 18,
			color = MY_TargetLine.tTargetColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetLine.tTargetColor = { r, g, b }
				end)
			end,
			autoenable = function() return not MY_TargetLine.bTargetRL end,
		}):Width() + 5

		nX = nX + ui:Append('Text', {
			x = nX, y = nY - 2,
			text = _L['Change color'],
			autoenable = function() return not MY_TargetLine.bTargetRL end,
		}):AutoWidth():Width()

		nX, nY = nPaddingX + 10, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the line target self to target target'],
			checked = MY_TargetLine.bTTarget,
			oncheck = function(bChecked)
				MY_TargetLine.bTTarget = bChecked
			end,
		}):AutoWidth():Width()

		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['New style'],
			checked = MY_TargetLine.bTTargetRL,
			oncheck = function(bChecked)
				MY_TargetLine.bTTargetRL = bChecked
			end,
		}):AutoWidth():Width() + 10

		nX = nX + ui:Append('Shadow', {
			x = nX + 2, y = nY + 4, w = 18, h = 18,
			color = MY_TargetLine.tTTargetColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetLine.tTTargetColor = { r, g, b }
				end)
			end,
			autoenable = function() return not MY_TargetLine.bTTargetRL end,
		}):Width() + 5

		nX = nX + ui:Append('Text', {
			x = nX, y = nY - 2,
			text = _L['Change color'],
			autoenable = function() return not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', {
			text = _L['Line width'], x = nX, y = nY,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = MY_TargetLine.nLineWidth,
			range = {1, 5},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d px', val) end,
			onchange = function(val) MY_TargetLine.nLineWidth = val end,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		})
		nX = nX + 180
		nX = nX + ui:Append('WndRadioBox', {
			x = nX, y = nY, w = 100, h = 25, group = 'line postype',
			text = _L['From head to head'],
			checked = MY_TargetLine.bAtHead,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				MY_TargetLine.bAtHead = true
			end,
		}):AutoWidth():Width() + 10


		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', {
			text = _L['Line alpha'], x = nX, y = nY,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		}):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = MY_TargetLine.nLineAlpha,
			range = {1, 255},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			onchange = function(val) MY_TargetLine.nLineAlpha = val end,
			autoenable = function() return not MY_TargetLine.bTargetRL or not MY_TargetLine.bTTargetRL end,
		})
		nX = nX + 180
		nX = nX + ui:Append('WndRadioBox', {
			x = nX, y = nY, w = 100, h = 25, group = 'line postype',
			text = _L['From foot to foot'],
			checked = not MY_TargetLine.bAtHead,
			oncheck = function(bChecked)
				if not bChecked then
					return
				end
				MY_TargetLine.bAtHead = false
			end,
		}):AutoWidth():Width() + 10
	end

	if not X.IsRestricted('MY_TargetFace') then
		-- target face
		nX, nY = nPaddingX + 10, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the sector of target facing, change color'],
			checked = MY_TargetFace.bTargetFace,
			oncheck = function(bChecked)
				MY_TargetFace.bTargetFace = bChecked
			end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = nX + 2, y = nY + 2, w = 18, h = 18,
			color = MY_TargetFace.tTargetFaceColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTargetFaceColor = { r, g, b }
				end)
			end,
		})

		-- target target face
		nX, nY = nPaddingX + 10, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the sector of target target facing, change color'],
			checked = MY_TargetFace.bTTargetFace,
			oncheck = function(bChecked)
				MY_TargetFace.bTTargetFace = bChecked
			end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = nX + 2, y = nY + 2, w = 18, h = 18,
			color = MY_TargetFace.tTTargetFaceColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTTargetFaceColor = { r, g, b }
				end)
			end,
		})

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', { text = _L['The sector angle'], x = nX, y = nY }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = MY_TargetFace.nSectorDegree,
			range = {30, 180},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d degree', val) end,
			onchange = function(val) MY_TargetFace.nSectorDegree = val end,
		})

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', { text = _L['The sector radius'], x = nX, y = nY }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = MY_TargetFace.nSectorRadius,
			range = {1, 26},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d feet', val) end,
			onchange = function(val) MY_TargetFace.nSectorRadius = val end,
		})

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', { text = _L['The sector transparency'], x = nX, y = nY }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = math.ceil((200 - MY_TargetFace.nSectorAlpha) / 2),
			range = {0, 100},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d %%', val) end,
			onchange = function(val) MY_TargetFace.nSectorAlpha = (100 - val) * 2 end,
		})

		-- foot shape
		nX, nY = nPaddingX, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the foot shape of target, change color'],
			checked = MY_TargetFace.bTargetShape,
			oncheck = function(bChecked) MY_TargetFace.bTargetShape = bChecked end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = nX + 2, y = nY + 2, w = 18, h = 18,
			color = MY_TargetFace.tTargetShapeColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTargetShapeColor = { r, g, b }
				end)
			end,
		})

		nX, nY = nPaddingX, nY + nLH
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Display the foot shape of target target, change color'],
			checked = MY_TargetFace.bTTargetShape,
			oncheck = function(bChecked) MY_TargetFace.bTTargetShape = bChecked end,
		}):AutoWidth():Width()

		ui:Append('Shadow', {
			x = nX + 2, y = nY + 2, w = 18, h = 18,
			color = MY_TargetFace.tTTargetShapeColor,
			onclick = function()
				local ui = UI(this)
				UI.OpenColorPicker(function(r, g, b)
					ui:Color(r, g, b)
					MY_TargetFace.tTTargetShapeColor = { r, g, b }
				end)
			end,
		})

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', { text = _L['The foot shape radius'], x = nX, y = nY }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = MY_TargetFace.nShapeRadius,
			range = {1, 26},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%.1f feet', val / 2) end,
			onchange = function(val) MY_TargetFace.nShapeRadius = val end,
		})

		nX, nY = nPaddingX + 37, nY + nLH
		nX = nX + ui:Append('Text', { text = _L['The foot shape transparency'], x = nX, y = nY }):AutoWidth():Width()

		ui:Append('WndTrackbar', {
			x = nX + 2, y = nY + 2,
			value = math.ceil((200 - MY_TargetFace.nShapeAlpha) / 2),
			range = {0, 100},
			trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			textfmt = function(val) return _L('%d %%', val) end,
			onchange = function(val) MY_TargetFace.nShapeAlpha = (100 - val) * 2 end,
		})
	end
end
X.RegisterPanel(_L['Target'], 'MY_Target', _L['MY_Target'], 2136, PS)
