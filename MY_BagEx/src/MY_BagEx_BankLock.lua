--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ֿ�����
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BankLock'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BankLock'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^26.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {})
local D = {}

-- ���ѵ���Ŧ
function D.CheckInjection(bRemoveInjection)
	if not bRemoveInjection and MY_BagEx_Bank.bEnable then
		-- ֲ��ѵ���Ŧ
		local frame = Station.Lookup('Normal/BigBankPanel')
		if not frame then
			return
		end
		local btnRef = frame:Lookup('Btn_MY_Stack')
		local btnNew = frame:Lookup('Btn_MY_Lock')
		if not btnRef then
			return
		end
		local nX = btnRef:GetRelX() + btnRef:GetW() + 5
		local nY = btnRef:GetRelY()
		if not btnNew then
			local bEdit = false
			btnNew = X.UI('Normal/BigBankPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Lock',
					w = 'auto', h = 'auto',
					text = _L['Lock'],
					onClick = function()
						bEdit = not bEdit
						if bEdit then
							MY_BagEx_Bank.ShowAllItemShadow(true)
						else
							MY_BagEx_Bank.HideAllItemShadow()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankLock__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ��ѵ���Ŧ
		X.UI('Normal/BigBankPanel/Btn_MY_Lock'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BankLock__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BankLock',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BankLock = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
