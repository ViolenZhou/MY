--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��սû��
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_BigWarChecker', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

local function IsBigWarFinishable(me)
	for _, aQuestInfo in ipairs(X.CONSTANT.QUEST_INFO.BIG_WARS) do
		local info = me.GetQuestTraceInfo(aQuestInfo[1])
		if info then
			local finished = false
			if info.finish then
				finished = true
			elseif not X.IsEmpty(info.quest_state) then
				finished = true
				for _, state in ipairs(info.quest_state) do
					if state.need ~= state.have then
						finished = false
					end
				end
			end
			if finished then
				return true
			end
		end
	end
end

-- ��սû��
X.RegisterFrameCreate('ExitPanel', 'BIG_WAR_CHECK', function(name, frame)
	local me = GetClientPlayer()
	if me then
		local ui = X.UI(frame)
		if IsBigWarFinishable(me) then
			OutputWarningMessage(
				'MSG_WARNING_RED',
				X.ENVIRONMENT.GAME_BRANCH == 'classic'
					and _L['Warning: Bounty has been finished but not handed yet!']
					or _L['Warning: Bigwar has been finished but not handed yet!']
			)
			PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			if ui:Children('#Text_MY_Tip'):Count() == 0 then
				ui:Append('Text', { name = 'Text_MY_Tip', y = ui:Height(), w = ui:Width(), color = {255, 255, 0}, font = 199, alignHorizontal = 1})
			end
			ui:Children('#Text_MY_Tip'):Text(
				X.ENVIRONMENT.GAME_BRANCH == 'classic'
					and _L['Warning: Bounty has been finished but not handed yet!']
					or _L['Warning: Bigwar has been finished but not handed yet!']
			)
			local nTick = GetTime()
			local el = ui:Children('#Text_MY_Tip')[1]
			local SCALE_ANIMATE_TIME, SHAKE_ANIMATE_TIME = 200, 200
			X.RenderCall(function()
				if not X.IsElement(el) then
					return 0
				end
				local nTime = GetTime() - nTick
				if nTime >= SCALE_ANIMATE_TIME then
					el:SetFontScale(1)
					ui:Children('#Text_MY_Tip'):Shake(10, 10, 10, SHAKE_ANIMATE_TIME)
					return 0
				end
				el:SetFontScale((1 - nTime / SCALE_ANIMATE_TIME) * 6 + 1)
			end)
		else
			ui:Children('#Text_MY_Tip'):Remove()
		end
	end
end)
X.RegisterFrameCreate('OptionPanel', 'BIG_WAR_CHECK', function(name, frame)
	local me = GetClientPlayer()
	if me then
		local ui = X.UI(frame)
		if IsBigWarFinishable(me) then
			if ui:Children('#Text_MY_Tip'):Count() == 0 then
				ui:Append('Text', { name = 'Text_MY_Tip', y = -20, w = ui:Width(), color = {255, 255, 0}, font = 199, alignHorizontal = 1})
			end
			ui:Children('#Text_MY_Tip')
				:Text(
					X.ENVIRONMENT.GAME_BRANCH == 'classic'
						and _L['Warning: Bounty has been finished but not handed yet!']
						or _L['Warning: Bigwar has been finished but not handed yet!']
					)
				:Shake(10, 10, 10, 1000)
		else
			ui:Children('#Text_MY_Tip'):Remove()
		end
	end
end)

local TASK_STATE = {
	ACCEPTABLE = 1,
	ACCEPTED = 2,
	FINISHABLE = 3,
	FINISHED = 4,
	UNACCEPTABLE = 5,
	UNKNOWN = 6,
}
local function GetTaskState(me, dwQuestID, dwNpcTemplateID)
	-- ��ȡ��������״̬ -1: ����id�Ƿ� 0: ���񲻴��� 1: �������ڽ����� 2: ������ɵ���û�н� 3: ���������
	local nState = me.GetQuestPhase(dwQuestID)
	if nState == 1 then
		return TASK_STATE.ACCEPTED
	end
	if nState == 2 then
		return TASK_STATE.FINISHABLE
	end
	if nState == 3 then
		return TASK_STATE.FINISHED
	end
	-- ��ȡ����״̬
	if me.GetQuestState(dwQuestID) == QUEST_STATE.FINISHED then
		return TASK_STATE.FINISHED
	end
	-- ��ȡ�Ƿ�ɽ�
	local eCanAccept = me.CanAcceptQuest(dwQuestID, dwNpcTemplateID)
	if eCanAccept == QUEST_RESULT.SUCCESS then
		return TASK_STATE.ACCEPTABLE
	end
	if eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED then
		return TASK_STATE.ACCEPTED
	end
	if eCanAccept == QUEST_RESULT.FINISHED_MAX_COUNT then
		return TASK_STATE.FINISHED
	end
	-- local KQuestInfo = GetQuestInfo(dwQuestID)
	-- if KQuestInfo.bRepeat then -- ���ظ�����û��������һ���ɽӣ���ʱ���ͼ���Ի����в��ɽ��ܣ�
	-- 	return TASK_STATE.ACCEPTABLE
	-- end
	-- if eCanAccept == QUEST_RESULT.FAILED then
	-- 	return TASK_STATE.UNACCEPTABLE
	-- end
	return TASK_STATE.UNKNOWN
end

X.RegisterEvent('LOADING_END', 'MY_BigWarChecker', function()
	local me = GetClientPlayer()
	local dwMapID = me.GetMapID()
	-- ������ս��״̬����
	local aQuestInfo = {}
	for _, v in ipairs(X.CONSTANT.QUEST_INFO.BIG_WARS) do
		local szPos = Table_GetQuestPosInfo(v[1], 'quest_state', 1)
		local szMap = szPos and szPos:match('N (%d+),')
		local dwMap = szMap and tonumber(szMap)
		table.insert(aQuestInfo, {
			dwQuestID = v[1],
			dwNpcTemplateID = v[2],
			dwMapID = dwMap,
			eState = GetTaskState(me, v[1], v[2]),
		})
	end
	-- ����һЩ����Ҫ��ʾ�����
	for _, v in ipairs(aQuestInfo) do
		-- �������˴�սֱ�ӷ���
		if v.eState == TASK_STATE.FINISHED or v.eState == TASK_STATE.FINISHABLE then
			return
		end
		-- ����пɽӵĴ�ս���ǲ��������ͼ�򷵻�
		if v.eState == TASK_STATE.ACCEPTABLE and v.dwMapID ~= dwMapID then
			return
		end
	end
	-- �������û�ӵ�ǰ��ͼ��ս�ͱ���
	for _, v in ipairs(aQuestInfo) do
		if v.dwMapID == dwMapID and v.eState ~= TASK_STATE.ACCEPTED and v.eState ~= TASK_STATE.FINISHED then
			local function fnAction()
				OutputWarningMessage('MSG_WARNING_RED', _L['This map is big war map and you did not accepted the quest, is that correct?'])
				PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
			end
			X.DelayCall(10000, fnAction)
			fnAction()
			return
		end
	end
end)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_BigWarChecker',
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
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_BigWarChecker = X.CreateModule(settings)
end
