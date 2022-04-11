--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��ӭҳ
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
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/ps/')

local PS = { bWelcome = true, bHide = true }

local function GetMemoryText()
	return string.format('Memory:%.1fMB', collectgarbage('count') / 1024)
end

local function GetAdvText()
	local me = GetClientPlayer()
	if not me then
		return ''
	end
	return _L('%s, welcome to use %s!', me.szName, X.PACKET_INFO.NAME)
end

local function GetSvrText()
	local nFeeTime = X.GetTimeOfFee() - GetCurrentTime()
	local szFeeTime = nFeeTime > 0
		and _L('Fee left %s', X.FormatDuration(nFeeTime, 'CHINESE', { accuracyunit = ENVIRONMENT.GAME_BRANCH == 'classic' and 'hour' or nil }))
		or _L['Fee left unknown']
	return X.GetServer() .. ' (' .. X.GetRealServer() .. ')'
		.. g_tStrings.STR_CONNECT
		.. szFeeTime
end

function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	ui:Append('Shadow', { name = 'Shadow_Adv', x = 0, y = 0, color = { 140, 140, 140 } })
	ui:Append('Image', { name = 'Image_Adv', x = 0, y = 0, image = X.PACKET_INFO.POSTER_UITEX, imageFrame = GetTime() % X.PACKET_INFO.POSTER_FRAME_COUNT })
	ui:Append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200, text = GetAdvText() })
	ui:Append('Text', { name = 'Text_Memory', x = 10, y = 300, w = 150, alpha = 150, font = 162, text = GetMemoryText(), alignHorizontal = 2 })
	ui:Append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = GetSvrText(), alpha = 220 })
	local x = 7
	-- ��������
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotify',
		text = _L['Show share notify.'],
		checked = MY_Serendipity.bEnable,
		oncheck = function(bChecked)
			if bChecked then
				local ui = UI(this)
				X.Confirm(_L['Check this will monitor system message for serendipity and share it, are you sure?'], function()
					MY_Serendipity.bEnable = bChecked
					ui:Check(true, WNDEVENT_FIRETYPE.PREVENT)
				end)
				ui:Check(false, WNDEVENT_FIRETYPE.PREVENT)
			else
				MY_Serendipity.bEnable = bChecked
			end
		end,
		tip = _L['Monitor serendipity and show share notify.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
	}):AutoWidth():Width()
	local xS0 = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityAutoShare',
		text = _L['Auto share.'],
		checked = MY_Serendipity.bAutoShare,
		oncheck = function()
			MY_Serendipity.bAutoShare = not MY_Serendipity.bAutoShare
		end,
		autoenable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	-- �Զ���������
	x = xS0
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipitySilentMode',
		text = _L['Silent mode.'],
		checked = MY_Serendipity.bSilentMode,
		oncheck = function()
			MY_Serendipity.bSilentMode = not MY_Serendipity.bSilentMode
		end,
		autovisible = function() return MY_Serendipity.bAutoShare end,
		autoenable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	x = x + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = 375, w = 105, h = 25,
		name = 'WndEditBox_SerendipitySilentMode',
		placeholder = _L['Realname, leave blank for anonymous.'],
		tip = _L['Realname, leave blank for anonymous.'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		limit = 6,
		text = X.LoadLUAData({'config/realname.jx3dat', X.PATH_TYPE.ROLE}) or GetClientPlayer().szName:gsub('@.-$', ''),
		onchange = function(szText)
			X.SaveLUAData({'config/realname.jx3dat', X.PATH_TYPE.ROLE}, szText)
		end,
		autovisible = function() return MY_Serendipity.bAutoShare end,
		autoenable = function() return MY_Serendipity.bEnable end,
	}):Width()
	-- �ֶ���������
	x = xS0
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotifyTip',
		text = _L['Show notify tip.'],
		checked = MY_Serendipity.bPreview,
		oncheck = function()
			MY_Serendipity.bPreview = not MY_Serendipity.bPreview
		end,
		autovisible = function() return not MY_Serendipity.bAutoShare end,
		autoenable = function() return MY_Serendipity.bEnable end,
	}):AutoWidth():Width()
	x = x + ui:Append('WndCheckBox', {
		x = x, y = 375,
		name = 'WndCheckBox_SerendipityNotifySound',
		text = _L['Play notify sound.'],
		checked = MY_Serendipity.bSound,
		oncheck = function()
			MY_Serendipity.bSound = not MY_Serendipity.bSound
		end,
		autoenable = function() return MY_Serendipity.bEnable and not MY_Serendipity.bAutoShare end,
		autovisible = function() return not MY_Serendipity.bAutoShare end,
	}):AutoWidth():Width()
	x = x + ui:Append('WndButton', {
		x = x, y = 375,
		name = 'WndButton_SerendipitySearch',
		text = _L['serendipity'],
		onclick = function()
			local szNameU = AnsiToUTF8(X.GetClientInfo().szName)
			local szNameCRC = ('%x%x%x'):format(szNameU:byte(), GetStringCRC(szNameU), szNameU:byte(-1))
			UI.OpenBrowser(
				'https://j3cx.com/serendipity/?'
					.. X.EncodeQuerystring(X.SignPostData(X.ConvertToUTF8(
						{
							l = ENVIRONMENT.GAME_LANG,
							L = ENVIRONMENT.GAME_EDITION,
							S = X.GetRealServer(1),
							s = X.GetRealServer(2),
							n = X.GetClientInfo().szName,
							N = szNameCRC,
						}),
						X.SECRET['J3CX::SERENDIPITY']
					)),
				{ openurl = 'https://j3cx.com/serendipity', controls = false })
		end,
	}):AutoWidth():Width() + 5
	-- ����λ��
	x = x + ui:Append('WndButton', {
		x = x, y = 405,
		name = 'WndButton_UserPreference',
		text = _L['User preference storage'],
		menu = function()
			return {
				{
					szOption = _L['User preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['User preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.ROLE}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Server preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Server preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.SERVER}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Global preference'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Global preference'] .. _L['Storage location'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						local szRoot = X.GetAbsolutePath({'', X.PATH_TYPE.GLOBAL}):gsub('/', '\\')
						X.OpenFolder(szRoot)
						UI.OpenTextEditor(szRoot)
						UI.ClosePopupMenu()
					end,
				},
				CONSTANT.MENU_DIVIDER,
				{
					szOption = _L['Flush data'],
					fnMouseEnter = function()
						local nX, nY = this:GetAbsX(), this:GetAbsY()
						local nW, nH = this:GetW(), this:GetH()
						OutputTip(GetFormatText(_L['Config and data will be saved when exit game, click to save immediately'], nil, 255, 255, 0), 600, {nX, nY, nW, nH}, ALW.BOTTOM_TOP)
					end,
					fnMouseLeave = function()
						HideTip()
					end,
					fnAction = function()
						X.FireFlush()
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Export data'],
					fnAction = function()
						X.OpenUserSettingsExportPanel()
						UI.ClosePopupMenu()
					end,
				},
				{
					szOption = _L['Import data'],
					fnAction = function()
						X.OpenUserSettingsImportPanel()
						UI.ClosePopupMenu()
					end,
				},
			}
		end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndButton', {
		name = 'WndButton_AddonErrorMessage',
		x = x, y = 405,
		text = _L['Error message'],
		tip = _L['Show error message'],
		tipPosType = UI.TIP_POSITION.BOTTOM_TOP,
		onClick = function()
			if IsCtrlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then
				X.IsDebugClient('Dev_LuaWatcher', true, true)
				X.IsDebugClient('Dev_UIEditor', true, true)
				X.IsDebugClient('Dev_UIManager', true, true)
				X.IsDebugClient('Dev_UIFindStation', true, true)
				X.Systopmsg(_L['Debug tools has been enabled...'])
				X.ReopenPanel()
				return
			end
			local szErrmsg = X.GetAddonErrorMessage()
			local nErrmsgLen, nMaxLen = #szErrmsg, 1024
			if nErrmsgLen == 0 then
				X.Alert(_L['No error message found.'])
				return
			end
			if nErrmsgLen > 300 then
				szErrmsg = szErrmsg:sub(0, nMaxLen)
					.. '\n========================================'
					.. '\n' .. '... ' .. (nErrmsgLen - nMaxLen) .. ' char(s) omitted.'
					.. '\n========================================'
					.. '\n# Full error logs:'
					.. '\n> ' .. X.GetAbsolutePath(X.GetAddonErrorMessageFilePath())
					.. '\n========================================'
			end
			UI.OpenTextEditor(szErrmsg, { w = 800, h = 600, title = _L['Error message'] })
		end,
	}):AutoWidth():Width() + 5
	PS.OnPanelResize(wnd)
end

function PS.OnPanelResize(wnd)
	local ui = UI(wnd)
	local w, h = ui:Size()
	local scaleH = w / 557 * 278
	local bottomH = 90
	if scaleH > h - bottomH then
		ui:Fetch('Shadow_Adv'):Size((h - bottomH) / 278 * 557, (h - bottomH))
		ui:Fetch('Image_Adv'):Size((h - bottomH) / 278 * 557, (h - bottomH))
		ui:Fetch('Text_Memory'):Pos(w - 150, h - bottomH + 10)
		ui:Fetch('Text_Adv'):Pos(10, h - bottomH + 10)
		ui:Fetch('Text_Svr'):Pos(10, h - bottomH + 35)
	else
		ui:Fetch('Shadow_Adv'):Size(w, scaleH)
		ui:Fetch('Image_Adv'):Size(w, scaleH)
		ui:Fetch('Text_Memory'):Pos(w - 150, scaleH + 10)
		ui:Fetch('Text_Adv'):Pos(10, scaleH + 10)
		ui:Fetch('Text_Svr'):Pos(10, scaleH + 35)
	end
	ui:Fetch('WndCheckBox_SerendipityNotify'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityAutoShare'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipitySilentMode'):Top(scaleH + 65)
	ui:Fetch('WndEditBox_SerendipitySilentMode'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityNotifyTip'):Top(scaleH + 65)
	ui:Fetch('WndCheckBox_SerendipityNotifySound'):Top(scaleH + 65)
	ui:Fetch('WndButton_SerendipitySearch'):Top(scaleH + 65)
	ui:Fetch('WndButton_UserPreference'):Top(scaleH + 65)
	ui:Fetch('WndButton_AddonErrorMessage'):Top(scaleH + 65)
end

function PS.OnPanelBreathe(wnd)
	local ui = UI(wnd)
	ui:Fetch('Text_Adv'):Text(GetAdvText())
	ui:Fetch('Text_Svr'):Text(GetSvrText())
	ui:Fetch('Text_Memory'):Text(GetMemoryText())
end

X.RegisterPanel(nil, 'Welcome', _L['Welcome'], '', PS)
