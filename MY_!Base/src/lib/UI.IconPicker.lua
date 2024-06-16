--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : IconPicker
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.IconPicker')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local ICON_PAGE, MAX_ICON_ID
local ICON_ROW_COUNT = 10
local ICON_COLUMN_COUNT = 20
local ICON_PAGE_SIZE = ICON_ROW_COUNT * ICON_COLUMN_COUNT
-- iconѡ����
function X.UI.OpenIconPicker(fnAction, nCurrentIconID)
	if not MAX_ICON_ID then
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
							MAX_ICON_ID = nMaxL
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
						X.OutputDebugMessage('ERROR CALC MAX_ICON!', X.DEBUG_LEVEL.ERROR)
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
		MAX_ICON_ID = MAX_ICON_ID or 50000
	end
	if X.IsNumber(nCurrentIconID) and nCurrentIconID > 0 then
		ICON_PAGE = math.floor((nCurrentIconID - 1) / ICON_PAGE_SIZE) + 1
	end
	local nMaxIconID, aBox, aTxt = MAX_ICON_ID, {}, {}
	local ui = X.UI.CreateFrame(X.NSFormatString('{$NS}_IconPanel'), {
		w = ICON_COLUMN_COUNT * 50 + 20,
		h = ICON_ROW_COUNT * 70 + 90,
		text = _L['Icon Picker'],
		simple = true, close = true, esc = true,
	})
	local function OnSelectIcon(nIconID)
		if fnAction then
			fnAction(nIconID)
		end
		ui:Remove()
	end
	for i = 1, ICON_PAGE_SIZE do
		local nX = ((i - 1) % ICON_COLUMN_COUNT) * 50 + 10
		local nY = math.floor((i - 1) / ICON_COLUMN_COUNT) * 70 + 10
		aBox[i] = ui:Append('Box', {
			x = nX, y = nY,
			w = 48, h = 48,
			icon = -1,
			onHover = function(bHover)
				this:SetObjectMouseOver(bHover)
			end,
			onClick = function()
				OnSelectIcon(this:GetObjectIcon())
			end,
		}):Raw()
		aTxt[i] = ui:Append('Text', {
			x = nX, y = nY + 48,
			w = 48, h = 20,
			text = '',
			align = 1,
		}):Raw()
	end
	local function GetPage(nPage, bInit)
		if nPage == ICON_PAGE and not bInit then
			return
		end
		ICON_PAGE = nPage
		local nStart = (nPage - 1) * ICON_PAGE_SIZE
		for i = 1, ICON_PAGE_SIZE do
			local nIconID = nStart + i
			local box = aBox[i]
			local txt = aTxt[i]
			if nIconID > nMaxIconID then
				box:SetVisible(false)
				txt:SetVisible(false)
			else
				box:SetObjectIcon(-1)
				box:SetObjectStaring(nIconID == nCurrentIconID)
			end
		end
		X.DelayCall(X.NSFormatString('{$NS}#UI.IconPicker.DelayRender'), function()
			if nPage ~= ICON_PAGE then
				return
			end
			for i = 1, ICON_PAGE_SIZE do
				local nIconID = nStart + i
				local box = aBox[i]
				local txt = aTxt[i]
				box:SetObjectIcon(nIconID)
				box:SetVisible(true)
				txt:SetText(nIconID)
				txt:SetVisible(true)
			end
		end)
	end
	ui:Append('WndEditBox', { name = 'Icon', x = ICON_COLUMN_COUNT * 50 + 20 - 190, y = ICON_ROW_COUNT * 70 + 90 - 70, w = 50, h = 25, editType = 0 })
	ui:Append('WndButton', {
		x = ICON_COLUMN_COUNT * 50 + 20 - 120,
		y = ICON_ROW_COUNT * 70 + 90 - 70,
		text = g_tStrings.STR_HOTKEY_SURE,
		buttonStyle = 'FLAT',
		onClick = function()
			local nIcon = tonumber(ui:Children('#Icon'):Text())
			if nIcon then
				OnSelectIcon(nIcon)
			end
		end,
	})
	ui:Append('WndSlider', {
		x = 10, y = ICON_ROW_COUNT * 70 + 90 - 70,
		w = 500, h = 25,
		textFormatter = ' Page: %d',
		range = {1, math.ceil(nMaxIconID / ICON_PAGE_SIZE)}, value = ICON_PAGE or 21,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		onChange = function(nVal)
			X.DelayCall(function() GetPage(nVal) end)
		end,
	})
	GetPage(ICON_PAGE or 21, true)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
