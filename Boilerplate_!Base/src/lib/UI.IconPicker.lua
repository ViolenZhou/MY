--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : IconPicker
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
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local ICON_PAGE, MAX_ICON
-- iconѡ����
function UI.OpenIconPicker(fnAction)
	if not MAX_ICON then
		local szPath = 'ui\\Scheme\\Case\\icon.txt'
		local tTitle = {
			{ f = 'i', t = 'dwID'       },
			{ f = 's', t = 'szFileName' },
			{ f = 'i', t = 'nFrame'     },
			{ f = 's', t = 'szKind'     },
			{ f = 's', t = 'szSubKind'  },
			{ f = 's', t = 'szTag1'     },
			{ f = 's', t = 'szTag2'     },
		}
		local tInfo = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL)
		if tInfo then
			local nRowCount = tInfo:GetRowCount()
			local nMaxL = nRowCount - 256     -- �۰���������ֵ
			local nMaxR = nRowCount + 256     -- �۰�����Ҷ���ֵ
			local bMaxL = tInfo:Search(nMaxL) -- �۰������˽��
			local bMaxR = tInfo:Search(nMaxR) -- �۰�����Ҷ˽��
			local nCount, nMaxCount = 0, 1000 -- �۰����ͳ�� 1000���۰���һ�û�ҵ������BUG�� �ж����޷�ֹ��ѭ��
			while true do
				if nMaxL < 1 then
					break
				elseif bMaxL and bMaxR then
					nMaxR = nMaxR * 2
					bMaxR = tInfo:Search(nMaxR)
				elseif not bMaxL and not bMaxR then
					nMaxL = math.floor(nMaxL / 2)
					bMaxL = tInfo:Search(nMaxL)
				else
					if bMaxL and not bMaxR then
						if nMaxL + 1 == nMaxR then
							MAX_ICON = nMaxL
							break
						else
							local nCur = math.floor(nMaxR - (nMaxR - nMaxL) / 2)
							local bCur = tInfo:Search(nCur)
							if bCur then
								nMaxL = nCur
							else
								nMaxR = nCur
							end
						end
					elseif not bMaxL and bMaxR then
						--[[#DEBUG BEGIN]]
						X.Debug('ERROR CALC MAX_ICON!', X.DEBUG_LEVEL.ERROR)
						--[[#DEBUG END]]
						break
					end
				end
				if nCount >= nMaxCount then
					break
				end
				nCount = nCount + 1
			end
		end
		MAX_ICON = MAX_ICON or 10000
	end
	local nMaxIcon, boxs, txts = MAX_ICON, {}, {}
	local ui = UI.CreateFrame(X.NSFormatString('{$NS}_IconPanel'), { w = 920, h = 650, text = _L['Icon Picker'], simple = true, close = true, esc = true })
	local function GetPage(nPage, bInit)
		if nPage == ICON_PAGE and not bInit then
			return
		end
		ICON_PAGE = nPage
		local nStart = (nPage - 1) * 144
		for i = 1, 144 do
			local x = ((i - 1) % 18) * 50 + 10
			local y = math.floor((i - 1) / 18) * 70 + 10
			if boxs[i] then
				local nIcon = nStart + i
				if nIcon > nMaxIcon then
					boxs[i]:Toggle(false)
					txts[i]:Toggle(false)
				else
					boxs[i]:Icon(-1)
					txts[i]:Text(nIcon):Toggle(true)
					X.DelayCall(function()
						if math.ceil(nIcon / 144) == ICON_PAGE and boxs[i] then
							boxs[i]:Icon(nIcon):Toggle(true)
						end
					end)
				end
			else
				boxs[i] = ui:Append('Box', {
					w = 48, h = 48, x = x, y = y, icon = nStart + i,
					onhover = function(bHover)
						this:SetObjectMouseOver(bHover)
					end,
					onclick = function()
						if fnAction then
							fnAction(this:GetObjectIcon())
						end
						ui:Remove()
					end,
				})
				txts[i] = ui:Append('Text', { w = 48, h = 20, x = x, y = y + 48, text = nStart + i, align = 1 })
			end
		end
	end
	ui:Append('WndEditBox', { name = 'Icon', x = 730, y = 580, w = 50, h = 25, edittype = 0 })
	ui:Append('WndButton', {
		x = 800, y = 580,
		text = g_tStrings.STR_HOTKEY_SURE,
		buttonstyle = 'FLAT',
		onclick = function()
			local nIcon = tonumber(ui:Children('#Icon'):Text())
			if nIcon then
				if fnAction then
					fnAction(nIcon)
				end
				ui:Remove()
			end
		end,
	})
	ui:Append('WndTrackbar', {
		x = 10, y = 580, h = 25, w = 500, textfmt = ' Page: %d',
		range = {1, math.ceil(nMaxIcon / 144)}, value = ICON_PAGE or 21,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		onchange = function(nVal)
			X.DelayCall(function() GetPage(nVal) end)
		end,
	})
	GetPage(ICON_PAGE or 21, true)
end
