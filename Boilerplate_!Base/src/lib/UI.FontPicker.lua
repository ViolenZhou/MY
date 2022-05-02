--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : FontPicker
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ������ѡ��
function X.UI.OpenFontPicker(callback, t)
	local ui, i = X.UI.CreateFrame(X.NSFormatString('{$NS}_Font_Picker'), { simple = true, close = true, esc = true, text = _L['Font Picker'] }), 0
	while 1 do
		local font = i
		local txt = ui:Append('Text', {
			w = 70, x = i % 10 * 80 + 20, y = math.floor(i / 10) * 25,
			font = font, alpha = 200,
			text = _L('Font %d', font),
			onClick = function()
				if callback then
					callback(font)
				end
				if not IsCtrlKeyDown() then
					ui:Remove()
				end
			end,
			onHover = function(bIn)
				X.UI(this):Alpha(bIn and 255 or 200)
			end,
		})
		-- remove unexist font
		if txt:Font() ~= font then
			txt:Remove()
			break
		end
		i = i + 1
	end
	return ui:Size(820, 70 + math.floor(i / 10) * 25):Anchor({ s = 'CENTER', r = 'CENTER', x = 0, y = 0 }):Focus()
end
