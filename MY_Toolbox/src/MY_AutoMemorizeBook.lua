--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Զ��Ķ��鼮
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_AutoMemorizeBook'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_AutoMemorizeBook'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^20.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_AutoMemorizeBook', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_AutoMemorizeBook', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.Hook()
	local frame = Station.Lookup('Normal/CraftReaderPanel')
	if not frame or frame:Lookup('MY_AutoMemorizeBook') then
		return
	end
	X.UI(frame):Append('WndCheckBox', {
		name = 'MY_AutoMemorizeBook',
		x = 50, y = 482,
		text = _L['Auto memorize book'],
		checked = O.bEnable,
		onCheck = function() O.bEnable = not O.bEnable end,
	})
end

function D.Unhook()
	X.UI('Normal/CraftReaderPanel/MY_AutoMemorizeBook'):Remove()
end

function D.CheckEnable()
	if X.IsRestricted('MY_AutoMemorizeBook') then
		D.Unhook()
		X.RegisterFrameCreate('CraftReaderPanel', 'MY_AutoMemorizeBook', false)
		X.RegisterEvent('OPEN_BOOK', 'MY_AutoMemorizeBook', false)
		X.RegisterEvent('OPEN_BOOK_NOTIFY', 'MY_AutoMemorizeBook', false)
	else
		D.Hook()
		X.RegisterFrameCreate('CraftReaderPanel', 'MY_AutoMemorizeBook', D.Hook)
		if O.bEnable then
			X.RegisterEvent({'OPEN_BOOK', 'OPEN_BOOK_NOTIFY'}, 'MY_AutoMemorizeBook', function(event)
				if IsShiftKeyDown() then
					return X.Systopmsg(_L['Auto memorize book has been disabled due to SHIFT key pressed.'])
				end
				local me = X.GetClientPlayer()
				if not me then
					return
				end
				local nBookID, nSegmentID, nItemID, nRecipeID = arg0, arg1, arg2, arg3
				local dwTargetType = event == 'OPEN_BOOK_NOTIFY' and arg4 or nil
				if me.IsBookMemorized(nBookID, nSegmentID) then
					return
				end
				me.CastProfessionSkill(8, nRecipeID, dwTargetType, nItemID)
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_AutoMemorizeBook', D.CheckEnable)
X.RegisterReload('MY_AutoMemorizeBook', D.Unhook)
X.RegisterEvent('MY_RESTRICTION', 'MY_AutoMemorizeBook', function()
	if arg0 and arg0 ~= 'MY_AutoMemorizeBook' then
		return
	end
	D.CheckEnable()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
