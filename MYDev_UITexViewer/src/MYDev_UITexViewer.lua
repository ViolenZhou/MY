--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �����߹���
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MYDev_UITexViewer/MYDev_UITexViewer'
local PLUGIN_NAME = 'MYDev_UITexViewer'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MYDev_UITexViewer'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^27.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MYDev_UITexViewer', {
	szUITexPath = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MYDev_UITexViewer'],
		szDescription = X.MakeCaption({
			_L['UITexPath'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
})
local D = {}

local PS = {}

function PS.IsRestricted()
	return not X.IsDebugging('Dev_UITexViewer')
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local w, h = ui:Size()
	local x, y = 20, 20

	D.tUITexList = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MYDev_UITexViewer/data/data.jx3dat') or {}

	local uiBoard = ui:Append('WndScrollHandleBox', {
		name = 'WndScrollHandleBox_ImageList',
		x = x, y = y + 25, w = w - 21, h = h - 70,
		handleStyle = 3,
	})

	local uiEdit = ui:Append('WndEditBox', {
		name = 'WndEdit_Copy',
		x = x, y = h - 30, w = w - 20, h = 25,
		multiline = true,
	})

	local function DrawBoard()
		local szPath = O.szUITexPath:gsub('/', '\\'):gsub('\\\\', '\\'):gsub('%.UITex$', ''):gsub('%.uitex$', '')

		local tInfo = KG_Table.Load(szPath .. '.txt', {
		-- ͼƬ�ļ�֡��Ϣ��ı�ͷ����
			{f = 'i', t = 'nFrame' },             -- ͼƬ֡ ID
			{f = 'i', t = 'nLeft'  },             -- ֡λ��: �����������(Xλ��)
			{f = 'i', t = 'nTop'   },             -- ֡λ��: ���붥������(Yλ��)
			{f = 'i', t = 'nWidth' },             -- ֡���
			{f = 'i', t = 'nHeight'},             -- ֡�߶�
			{f = 's', t = 'szFile' },             -- ֡��Դ�ļ�(������)
		}, FILE_OPEN_MODE.NORMAL)
		if not tInfo then
			return
		end

		uiBoard:Clear()
		for i = 0, 256 do
			local tLine = tInfo:Search(i)
			if not tLine then
				break
			end

			if tLine.nWidth ~= 0 and tLine.nHeight ~= 0 then
				uiBoard:Append('Image', {
					name = 'Image_' .. i,
					w = tLine.nWidth, h = tLine.nHeight,
					alpha = 220,
					image = szPath .. '.UITex', imageFrame = tLine.nFrame,
					tip = {
						render = szPath .. '.UITex#' .. i .. '\n' .. tLine.nWidth .. 'x' .. tLine.nHeight .. '\n' .. _L['(left click to generate xml)'],
						position = X.UI.TIP_POSITION.TOP_BOTTOM,
					},
					onHover = function(bIn)
						X.UI(this):Alpha((bIn and 255) or 220)
					end,
					onClick = function()
						uiEdit:Text('<image>w='..tLine.nWidth..' h='..tLine.nHeight..' path="' .. szPath .. '.UITex" frame=' .. i ..'</image>')
					end,
				})
			end
		end
	end

	ui:Append('WndAutocomplete', {
		name = 'WndAutocomplete_UITexPath',
		x = x, y = y, w = w - 20, h = 25,
		text = O.szUITexPath,
		onChange = function(szText)
			O.szUITexPath = szText
			DrawBoard()
		end,
		onClick = function(nButton)
			if IsPopupMenuOpened() then
				X.UI(this):Autocomplete('close')
			else
				X.UI(this):Autocomplete('search', '')
			end
		end,
		autocomplete = {
			{'option', 'maxOption', 20},
			{'option', 'source', D.tUITexList},
		},
	})

	DrawBoard()
end

function PS.OnPanelDeactive(wnd)
	D.tUITexList = nil
	collectgarbage('collect')
end

X.Panel.Register(_L['Development'], 'Dev_UITexViewer', _L['UITexViewer'], 'ui/Image/UICommon/BattleFiled.UITex|7', PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
