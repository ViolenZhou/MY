--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����֮�ؾŹ�����
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_LockFrame'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LockFrame'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_LockFrame', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {
			['JX_TargetList'] = true,
			['MY_FocusUI'] = true,
			['WhoSeeMe'] = true,
			['HatredPanel'] = true,
			['FightingStatistic'] = true,
			['MY_ThreatRank'] = true,
			['MY_Recount_UI'] = true,
			['LR_AS_FP'] = true,
			['QuestTraceList'] = true,
			['ChatPanel'] = true,
			['DynamicActionBar'] = true,
			['ExteriorAction'] = true,
			['MentorMessage'] = true,
			['JX_TeamCD'] = true,
			['JX_HeightMeter'] = true,
			['Matrix'] = true,
		},
	},
})
local D = {
	bTempDisable = false,
	tLockList = {
		'WhoSeeMe',
		'HatredPanel',
		'FightingStatistic',
		'QuestTraceList',
		'ChatPanel',
		'Matrix',
		'ExteriorAction',
		'MentorMessage',
		'DynamicActionBar',
		'JX_TeamCD',
		'JX_HeightMeter',
		'JX_TargetList',
		'MY_FocusUI',
		'MY_ThreatRank',
		'MY_Recount_UI',
	},
	tLockID = {
		['JX_TargetList'] = 'JX_TargetList', -- ���ġ������б� [Normal/JX_TargetList]
		['MY_FocusUI'] = 'MY_FocusUI', -- �����������б� [Normal/MY_FocusUI]
		['WhoSeeMe'] = 'WhoSeeMe', -- ˭�ڿ��� [Normal/WhoSeeMe]
		['HatredPanel'] = 'HatredPanel', -- ����б� [Normal/HatredPanel]
		['FightingStatistic'] = 'FightingStatistic', -- �˺�ͳ�� [Normal/FightingStatistic]
		['MY_ThreatRank'] = 'MY_ThreatRank', -- ���������ͳ�� [Normal/MY_ThreatRank]
		['MY_Recount_UI'] = 'MY_Recount_UI', -- �������˺�ͳ�� [Normal/MY_Recount_UI]
		['QuestTraceList'] = 'QuestTraceList', -- ����׷�� [Normal/QuestTraceList]
		['Matrix'] = 'Matrix', -- �󷨽��� [Normal/Matrix]
		['ChatPanel1'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel1]
		['ChatPanel2'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel2]
		['ChatPanel3'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel3]
		['ChatPanel4'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel4]
		['ChatPanel5'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel5]
		['ChatPanel6'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel6]
		['ChatPanel7'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel7]
		['ChatPanel8'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel8]
		['ChatPanel9'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel9]
		['ChatPanel10'] = 'ChatPanel', -- ������� [Lowest2/ChatPanel10]
		['DynamicActionBar'] = 'DynamicActionBar', -- ��̬������ [Lowest1/DynamicActionBar]
		['ExteriorAction'] = 'ExteriorAction', -- ��װ���� [Normal/ExteriorAction]
		['MentorMessage'] = 'MentorMessage', -- ʦͽ��ʾ [Normal/MentorMessage]
		['JX_TeamCD'] = 'JX_TeamCD', -- ���ġ��ŶӼ��ܼ�� [Normal/JX_TeamCD]
		['JX_HeightMeter'] = 'JX_HeightMeter', -- ���ġ��߶ȱ��� [Normal/JX_HeightMeter]
	},
}

local HOOKED_UI = setmetatable({}, { __mode = 'k' })
local UI_DRAGABLE = setmetatable({}, { __mode = 'k' })
local function EnableDrag(frame, bEnable)
	UI_DRAGABLE[frame] = bEnable
end
local function IsDragable(frame)
	return UI_DRAGABLE[frame] or false
end
function D.LockFrame(frame)
	if not HOOKED_UI[frame] then
		HOOKED_UI[frame] = true
		UI_DRAGABLE[frame] = frame:IsDragable()
		frame:EnableDrag(false)
		HookTableFunc(frame, 'EnableDrag', EnableDrag, { bDisableOrigin = true })
		HookTableFunc(frame, 'IsDragable', IsDragable, { bDisableOrigin = true, bHookReturn = true })
	end
end
function D.UnlockFrame(frame)
	if HOOKED_UI[frame] then
		UnhookTableFunc(frame, 'EnableDrag', EnableDrag)
		UnhookTableFunc(frame, 'IsDragable', IsDragable)
		frame:EnableDrag(UI_DRAGABLE[frame])
		HOOKED_UI[frame] = nil
		UI_DRAGABLE[frame] = nil
	end
end

function D.IsFrameLock(frame)
	if not D.bReady or not O.bEnable or D.bTempDisable or not frame then
		return false
	end
	local szLock = D.tLockID[frame:GetName()]
	return szLock and O.tEnable[szLock] ~= false
end

function D.CheckFrame(frame)
	local bLock = D.IsFrameLock(frame)
	if bLock then
		D.LockFrame(frame)
	else
		D.UnlockFrame(frame)
	end
end

function D.CheckAllFrame()
	for _, szLayer in ipairs({'Lowest', 'Lowest1', 'Lowest2', 'Normal', 'Normal1', 'Normal2', 'Topmost', 'Topmost1', 'Topmost2'})do
		local frmIter = Station.Lookup(szLayer)
		if frmIter then
			frmIter = frmIter:GetFirstChild()
		end
		while frmIter do
			local bLock = D.IsFrameLock(frmIter)
			if bLock then
				D.LockFrame(frmIter)
			else
				D.UnlockFrame(frmIter)
			end
			frmIter = frmIter:GetNext()
		end
	end
	if D.bReady and O.bEnable then
		X.RegisterEvent('ON_FRAME_CREATE', 'MY_LockFrame', function()
			D.CheckFrame(arg0)
		end)
		X.RegisterSpecialKeyEvent('*', 'MY_LockFrame', function()
			if IsCtrlKeyDown() and (IsShiftKeyDown() or IsAltKeyDown()) then
				if not D.bTempDisable then
					X.OutputAnnounceMessage(_L['MY_LockFrame has been temporary disabled.'])
					D.bTempDisable = true
					D.CheckAllFrame()
				end
			else
				if D.bTempDisable then
					X.OutputAnnounceMessage(_L['MY_LockFrame has been enabled.'])
					D.bTempDisable = false
					D.CheckAllFrame()
				end
			end
		end)
	else
		X.RegisterEvent('ON_FRAME_CREATE', 'MY_LockFrame', false)
		X.RegisterSpecialKeyEvent('*', 'MY_LockFrame', false)
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	ui:Append('WndComboBox', {
		x = nW - 140, y = 65,
		text = _L['Lock frame position'],
		menu = function()
			local t = {
				{
					szOption = _L['Enable (press ctrl+alt to temp unlock)'],
					bCheck = true, bChecked = MY_LockFrame.bEnable,
					fnAction = function(_, b)
						MY_LockFrame.bEnable = b
						D.CheckAllFrame()
					end,
				}, X.CONSTANT.MENU_DIVIDER,
			}
			for _, k in ipairs(D.tLockList) do
				table.insert(t, {
					szOption = _L['LOCK_FRAME_' .. k],
					bCheck = true, bChecked = MY_LockFrame.tEnable[k] ~= false,
					fnAction = function(_, b)
						MY_LockFrame.tEnable[k] = b
						MY_LockFrame.tEnable = MY_LockFrame.tEnable
					end,
					fnDisable = function()
						return not MY_LockFrame.bEnable
					end,
				})
			end
			return t
		end,
	})
	return nX, nY
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_LockFrame',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'tEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'tEnable',
			},
			triggers = {
				bEnable = D.CheckAllFrame,
				tEnable = D.CheckAllFrame,
			},
			root = O,
		},
	},
}
MY_LockFrame = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_LockFrame', function()
	D.bReady = true
	D.CheckAllFrame()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
