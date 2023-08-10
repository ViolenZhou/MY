--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Զ��۳���Ʒ
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_AutoSell'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^16.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_AutoSell', _L['General'], {
	bEnable = { -- ���̵���Զ��۳��ܿ���,
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSellGray = { -- �Զ����ۻ�ɫ��Ʒ,
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSellWhiteBook = { -- �Զ������Ѷ�����,
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSellGreenBook = { -- �Զ������Ѷ�����,
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSellBlueBook = { -- �Զ������Ѷ�����,
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tSellItem = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {
			[X.GetObjectName('ITEM_INFO', 5, 2863)] = true, -- ��Ҷ��
			[X.GetObjectName('ITEM_INFO', 5, 2864)] = true, -- ����Ҷ��
			[X.GetObjectName('ITEM_INFO', 5, 2865)] = true, -- ��Ƭ����Ҷ��
			[X.GetObjectName('ITEM_INFO', 5, 2866)] = true, -- ���ĩ
			[X.GetObjectName('ITEM_INFO', 5, 2867)] = true, -- ��Ҷ��
			[X.GetObjectName('ITEM_INFO', 5, 2868)] = true, -- ��Ƭ��Ҷ��
			[X.GetObjectName('ITEM_INFO', 5, 11682)] = true, -- ����
			[X.GetObjectName('ITEM_INFO', 5, 11683)] = true, -- ���
			[X.GetObjectName('ITEM_INFO', 5, 11640)] = true, -- ��ש
			[X.GetObjectName('ITEM_INFO', 5, 17130)] = true, -- ��Ҷ�ӡ�����֮��
			[X.GetObjectName('ITEM_INFO', 5, 22974)] = true, -- ����Ľ�����
		},
	},
	tProtectItem = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {
			[X.GetObjectName('ITEM_INFO', 5, 789)] = true, -- ��˿�Ƕ�
			[X.GetObjectName('ITEM_INFO', 5, 797)] = true, -- ����ͼ��
		},
	},
})
local D = {}

RegisterCustomData('MY_AutoSell.tSellItem')
RegisterCustomData('MY_AutoSell.tProtectItem')

function D.SellItem(nNpcID, nShopID, dwBox, dwX, nCount, szReason, szName, nUiId)
	local me = X.GetClientPlayer()
	local item = me.GetItem(dwBox, dwX)
	if not item or item.nUiId ~= nUiId then
		return
	end
	SellItem(nNpcID, nShopID, dwBox, dwX, nCount)
	X.Sysmsg(_L('Auto sell %s item: %s.', szReason, szName))
end

-- �Զ��۳���Ʒ
function D.AutoSellItem(nNpcID, nShopID, bIgnoreGray)
	if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
		return
	end
	local me = X.GetClientPlayer()
	local nIndex = X.GetBagPackageIndex()
	local aSell = {}
	for dwBox = nIndex, nIndex + X.GetBagPackageCount() do
		local dwSize = me.GetBoxSize(dwBox) - 1
		for dwX = 0, dwSize do
			local item = me.GetItem(dwBox, dwX)
			if item and item.bCanTrade then
				local bSell, szReason = false, ''
				local szName = X.GetObjectName(item)
				if not O.tProtectItem[szName] then
					if item.nQuality == 0 and O.bSellGray and not bIgnoreGray then
						bSell = true
						szReason = _L['Gray item']
					end
					if not bSell and O.tSellItem[szName] then
						bSell = true
						szReason = _L['Specified']
					end
					if not bSell and item.nGenre == ITEM_GENRE.BOOK and me.IsBookMemorized(X.RecipeToSegmentID(item.nBookID)) then
						if O.bSellWhiteBook and item.nQuality == 1 then
							bSell = true
							szReason = _L['Read white book']
						elseif O.bSellGreenBook and item.nQuality == 2 then
							bSell = true
							szReason = _L['Read green book']
						elseif O.bSellBlueBook and item.nQuality == 3 then
							bSell = true
							szReason = _L['Read blue book']
						end
					end
				end
				if bSell then
					local nCount = 1
					if item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.ARROW then --Զ������
						nCount = item.nCurrentDurability
					elseif item.bCanStack then
						nCount = item.nStackNum
					end
					local r, g, b = GetItemFontColorByQuality(item.nQuality)
					local sell = {
						nNpcID = nNpcID, nShopID = nShopID, dwBox = dwBox, dwX = dwX, nCount = nCount,
						szReason = szReason, szName = szName, nUiId = item.nUiId, r = r, g = g, b = b,
					}
					table.insert(aSell, sell)
				end
			end
		end
	end
	table.sort(aSell, function(a, b)
		if a.szReason == b.szReason then
			return a.nUiId > b.nUiId
		end
		return a.szReason > b.szReason
	end)
	if #aSell > 0 then
		local aXML, szReason = {}
		table.insert(aXML, GetFormatText(_L['Confirm auto sell?']))
		table.insert(aXML, X.CONSTANT.XML_LINE_BREAKER)
		for _, v in ipairs(aSell) do
			if v.szReason ~= szReason then
				table.insert(aXML, X.CONSTANT.XML_LINE_BREAKER)
				table.insert(aXML, GetFormatText(v.szReason .. g_tStrings.STR_CHINESE_MAOHAO))
				szReason = v.szReason
			end
			table.insert(aXML, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(aXML, GetFormatText(g_tStrings.STR_TWO_CHINESE_SPACE .. '['.. v.szName ..']', 166, v.r, v.g, v.b))
			table.insert(aXML, GetFormatText(' x' .. v.nCount))
		end
		table.insert(aXML, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(aXML, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(aXML, GetFormatText(_L['Some items may not be able to buy back once you sell it, and there is also a limit number rule by official, change auto sell rules in plugin if you want.']))
		local nW, nH = Station.GetClientSize()
		local tMsg = {
			x = nW / 2, y = nH / 3,
			szName = 'MY_AutoSell__Confirm',
			szMessage = table.concat(aXML),
			bRichText = true,
			szAlignment = 'CENTER',
			{
				szOption = g_tStrings.STR_HOTKEY_SURE,
				fnAction = function()
					for _, v in ipairs(aSell) do
						D.SellItem(v.nNpcID, v.nShopID, v.dwBox, v.dwX, v.nCount, v.szReason, v.szName, v.nUiId)
					end
				end,
			}, { szOption = g_tStrings.STR_HOTKEY_CANCEL },
		}
		MessageBox(tMsg)
	end
end

function D.CheckEnable()
	if O.bEnable then
		X.RegisterEvent('SHOP_OPENSHOP', 'MY_AutoSell', function()
			local chk = Station.Lookup('Normal/ShopPanel/CheckBox_AutoSell')
			local bIgnoreGray = chk and chk:IsCheckBoxChecked() or false
			D.AutoSellItem(arg4, arg0, bIgnoreGray)
		end)
	else
		X.RegisterEvent('SHOP_OPENSHOP', 'MY_AutoSell', false)
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto sell items'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
			D.CheckEnable()
		end,
		tip = {
			render = _L['Auto sell when open shop'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
	}):Width() + 5

	-- �����ͳ���
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto sell by type'],
		menu = function()
			local m0 = {
				{
					szOption = _L['Sell grey items'],
					bCheck = true, bChecked = O.bSellGray,
					fnAction = function(d, b) O.bSellGray = b end,
				},
				{
					szOption = _L['Sell read white books'],
					bCheck = true, bChecked = O.bSellWhiteBook,
					fnAction = function(d, b) O.bSellWhiteBook = b end,
				},
				{
					szOption = _L['Sell read green books'], bCheck = true, bChecked = O.bSellGreenBook,
					fnAction = function(d, b) O.bSellGreenBook = b end,
				},
				{
					szOption = _L['Sell read blue books'], bCheck = true, bChecked = O.bSellBlueBook,
					fnAction = function(d, b) O.bSellBlueBook = b end,
				},
			}
			return m0
		end,
		autoEnable = function() return O.bEnable end,
	}):Width() + 5

	-- �����Ƴ���
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Auto sell by name'],
		menu = function()
			local m1 = {
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = string.gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								O.tSellItem[szText] = true
								O.tSellItem = O.tSellItem
							end
						end)
					end
				},
				{ bDevide = true },
			}
			local m2 = { bInline = true, nMaxHeight = 550 }
			for k, v in pairs(O.tSellItem) do
				table.insert(m2, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) O.tSellItem[k] = b end,
					{
						szOption = _L['Remove'],
						fnAction = function()
							O.tSellItem[k] = nil
							O.tSellItem = O.tSellItem
							for i, v in ipairs(m2) do
								if v.szOption == k then
									table.remove(m2, i)
									break
								end
							end
							return 0
						end,
					},
				})
			end
			table.insert(m1, m2)
			return m1
		end,
		autoEnable = function() return O.bEnable end,
	}):Width() + 5

	-- �����������۵���Ʒ
	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Protect specified items'],
		menu = function()
			local m1 = {
				{
					szOption = _L['* New *'],
					fnAction = function()
						GetUserInput(_L['Name of item'], function(szText)
							local szText = string.gsub(szText, '^%s*%[?(.-)%]?%s*$', '%1')
							if szText ~= '' then
								O.tProtectItem[szText] = true
								O.tProtectItem = O.tProtectItem
							end
						end)
					end
				},
				{ bDevide = true },
			}
			local m2 = { bInline = true, nMaxHeight = 550 }
			for k, v in pairs(O.tProtectItem) do
				table.insert(m2, {
					szOption = k, bCheck = true, bChecked = v, fnAction = function(d, b) O.tProtectItem[k] = b end,
					{
						szOption = _L['Remove'],
						fnAction = function()
							O.tProtectItem[k] = nil
							O.tProtectItem = O.tProtectItem
							for i, v in ipairs(m2) do
								if v.szOption == k then
									table.remove(m2, i)
									break
								end
							end
							return 0
						end,
					},
				})
			end
			table.insert(m1, m2)
			return m1
		end,
		autoEnable = function() return O.bEnable end,
	}):Width() + 5

	return nX, nY
end

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_AutoSell',
	exports = {
		{
			fields = {
				'tSellItem',
				'tProtectItem',
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
	imports = {
		{
			fields = {
				'tSellItem',
				'tProtectItem',
			},
			root = D,
		},
	},
}
MY_AutoSell = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_AutoSell', function()
	for _, k in ipairs({'tSellItem', 'tProtectItem'}) do
		if D[k] then
			X.SafeCall(X.Set, O, k, D[k])
			D[k] = nil
		end
	end
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
