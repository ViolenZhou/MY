--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_BagLock'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_BagLock'
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
	if not bRemoveInjection and MY_BagEx_Bag.bEnable then
		-- ֲ��ѵ���Ŧ
		local frame = Station.Lookup('Normal/BigBagPanel')
		if not frame then
			return
		end
		local hBtnRef = frame:Lookup('Btn_MY_Stack')
		local btnNew = frame:Lookup('Btn_MY_Lock')
		if not hBtnRef then
			return
		end
		local nX = hBtnRef:GetRelX() + hBtnRef:GetW() + 3
		local nY = hBtnRef:GetRelY()
		local nH = hBtnRef:GetH()
		if not btnNew then
			local bEdit = false
			btnNew = X.UI('Normal/BigBagPanel')
				:Append('WndButton', {
					name = 'Btn_MY_Lock',
					w = 'auto', h = nH,
					text = _L['Lock'],
					onClick = function()
						bEdit = not bEdit
						if bEdit then
							MY_BagEx_Bag.ShowAllItemShadow(true)
						else
							MY_BagEx_Bag.HideAllItemShadow()
						end
					end,
				})
				:Raw()
		end
		if not btnNew then
			return
		end
		btnNew:SetRelPos(nX, nY)
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagLock__Injection', function()
			if not btnNew then
				return
			end
			btnNew:Enable(not arg0)
		end)
	else
		-- �Ƴ��ѵ���Ŧ
		X.UI('Normal/BigBagPanel/Btn_MY_Lock'):Remove()
		X.RegisterEvent('MY_BAG_EX__SORT_STACK_PROGRESSING', 'MY_BagEx_BagLock__Injection', false)
	end
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_BagLock',
	exports = {
		{
			fields = {
				CheckInjection = D.CheckInjection,
			},
		},
	},
}
MY_BagEx_BagLock = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterEvent('SCROLL_UPDATE_LIST', 'MY_BagEx_BagLock', function()
	if (arg0 == 'Handle_Bag_Compact' or arg0 == 'Handle_Bag_Normal')
	and arg1 == 'BigBagPanel' then
		D.CheckInjection()
	end
end)
X.RegisterUserSettingsInit('MY_BagEx_BagLock', function() D.CheckInjection() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_BagLock', function() D.CheckInjection() end)
X.RegisterReload('MY_BagEx_BagLock', function() D.CheckInjection(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
