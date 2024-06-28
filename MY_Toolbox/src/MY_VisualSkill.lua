--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ������ʾ - ս�����ӻ�
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_VisualSkill'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local INI_PATH = X.PACKET_INFO.ROOT .. 'MY_Toolbox/ui/MY_VisualSkill.ini'
local DEFAULT_ANCHOR = { x = 0, y = -220, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' }
local O = X.CreateUserSettingsModule('MY_VisualSkill', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bPenetrable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nVisualSkillBoxCount = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Number,
		xDefaultValue = 5,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = X.Clone(DEFAULT_ANCHOR),
	},
})
local D = {}

local BOX_WIDTH = 46
local BOX_ANIMATION_TIME = 300
local BOX_SLIDEOUT_DISTANCE = 200

-- local FORMATION_SKILL = {
-- 	[230  ] = true, -- (230)  ���˺���ʩ��  �߾���ң��
-- 	[347  ] = true, -- (347)  ����������ʩ��  �Ź�������
-- 	[526  ] = true, -- (526)  ����������ʩ��  ���������
-- 	[662  ] = true, -- (662)  ��߷������ͷ�  ���������
-- 	[740  ] = true, -- (740)  ���ַ�����ʩ��  ��շ�ħ��
-- 	[745  ] = true, -- (745)  ���ֹ�����ʩ��  ���������
-- 	[754  ] = true, -- (754)  ��߹������ͷ�  �����۳���
-- 	[778  ] = true, -- (778)  ����������ʩ��  ����������
-- 	[781  ] = true, -- (781)  �����˺���ʩ��  ����������
-- 	[1020 ] = true, -- (1020) ��������ʩ��  ���Ǿ�����
-- 	[1866 ] = true, -- (1866) �ؽ����ͷ�      ��ɽ������
-- 	[2481 ] = true, -- (2481) �嶾������ʩ��  ����֯����
-- 	[2487 ] = true, -- (2487) �嶾������ʩ��  ���������
-- 	[3216 ] = true, -- (3216) �����⹦��ʩ��  ���Ǹ�����
-- 	[3217 ] = true, -- (3217) �����ڹ���ʩ��  ǧ���ٱ���
-- 	[4674 ] = true, -- (4674) ���̹�����ʩ��  ������ħ��
-- 	[4687 ] = true, -- (4687) ���̷�����ʩ��  ����������
-- 	[5311 ] = true, -- (5311) ؤ�﹥�����ͷ�  ����������
-- 	[13228] = true, -- (13228)  �ٴ���ɽ���ͷ�  �ٴ���ɽ��
-- 	[13275] = true, -- (13275)  ��������ʩ��  ��������
-- }
local COMMON_SKILL = {
	[10   ] = true, -- (10)    ��ɨǧ��           ��ɨǧ��
	[11   ] = true, -- (11)    ��ͨ����-������     ���Ϲ�
	[12   ] = true, -- (12)    ��ͨ����-ǹ����     ÷��ǹ��
	[13   ] = true, -- (13)    ��ͨ����-������     ���񽣷�
	[14   ] = true, -- (14)    ��ͨ����-ȭ�׹���   ��ȭ
	[15   ] = true, -- (15)    ��ͨ����-˫������   ����˫��
	[16   ] = true, -- (16)    ��ͨ����-�ʹ���     �йٱʷ�
	[1795 ] = true, -- (1795)  ��ͨ����-�ؽ�����   �ļ�����
	[2183 ] = true, -- (2183)  ��ͨ����-��ѹ���   ��ĵѷ�
	[3121 ] = true, -- (3121)  ��ͨ����-������     ��ڷ�
	[4326 ] = true, -- (4326)  ��ͨ����-˫������   ��Į����
	[13039] = true, -- (13039) ��ͨ����_�ܵ�����   ��ѩ��
	[14063] = true, -- (14063) ��ͨ����_�ٹ���     ��������
	[16010] = true, -- (16010) ��ͨ����_��˪������  ˪�絶��
	[19712] = true, -- (19712) ��ͨ����_����ɡ����  Ʈңɡ��
	[31636] = true, -- (31636) ��ͨ����-�Ƶ�       �Ƶ�
	[17   ] = true, -- (17)    ����-��������-����  ����
	[18   ] = true, -- (18)    ̤��               ̤��
}

function D.UpdateAnchor(frame)
	local anchor = O.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	frame:CorrectPos()
end

function D.UpdateAnimation(frame, fPercentage)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nCount = hList:GetItemCount()
	local nSlideLRelX = 0 - BOX_SLIDEOUT_DISTANCE
	local nSlideRRelX = hList:GetW() + BOX_SLIDEOUT_DISTANCE
	-- [0, O.nVisualSkillBoxCount] ������ʾ��BOX
	-- [O.nVisualSkillBoxCount - 1, nCount - 1] ���������Ľ���BOX
	for i = 0, nCount - 1 do
		local hItem = hList:LogicLookup(i)
		if not hItem.nStartX then
			hItem.nStartX = hItem:GetRelX()
		end
		local nDstRelX = i < O.nVisualSkillBoxCount
			and hList:GetW() - BOX_WIDTH * (i + 1) -- �б�BOX��������λ��
			or ((fPercentage == 1 or hItem.nStartX > hList:GetW() - BOX_WIDTH)
				and (nSlideRRelX + BOX_WIDTH * (nCount - i + 1)) -- δ���붯���򶯻�������BOX�յ�Ϊ�Ҳ�
				or (nSlideLRelX - BOX_WIDTH * (i - O.nVisualSkillBoxCount))) -- ���붯����BOX�յ�Ϊ���
		local nRelX = hItem.nStartX + (nDstRelX - hItem.nStartX) * (
			hItem.nStartX > hList:GetW() - BOX_WIDTH
				and math.min(fPercentage / 0.4, 1) -- ����BOX�����˶�������ײ
				or math.max((fPercentage - 0.4) / 0.6, 0) -- �б�BOX�ӳ���ײ
		)
		if hItem.nStartX > hList:GetW() - BOX_WIDTH then -- �Ҳ����BOX������ײ����
			if fPercentage < 0.7 and (not hItem.nHitTime or GetTime() - hItem.nHitTime > BOX_ANIMATION_TIME) then
				hItem:Lookup('Animate_Hit'):Replay()
				hItem.nHitTime = GetTime()
			end
		end
		local nAlpha = (nRelX >= 0 and nRelX <= hList:GetW() - BOX_WIDTH)
			and 255
			or (1 - math.min(math.abs(nRelX < 0 and nRelX or (hList:GetW() - BOX_WIDTH - nRelX)) / BOX_SLIDEOUT_DISTANCE, 1)) * 255
		hItem:SetRelX(nRelX)
		hItem:SetAlpha(nAlpha)
	end
	hList:FormatAllItemPos()
end

function D.StartAnimation(frame, nStep)
	local hList = frame:Lookup('', 'Handle_Boxes')
	if nStep then
		hList.nIndexBase = (hList.nIndexBase - nStep) % hList:GetItemCount()
	end
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1 do
		local hItem = hList:Lookup(i)
		hItem.nStartX = hItem:GetRelX()
	end
	frame.nTickStart = GetTickCount()
end

-- ������ȷ�������б�
function D.CorrectBoxCount(frame)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nBoxCount = O.nVisualSkillBoxCount * 2
	local nBoxCountOffset = nBoxCount - hList:GetItemCount()
	if nBoxCountOffset == 0 then
		return
	end
	if nBoxCountOffset > 0 then
		for i = 1, nBoxCountOffset do
			hList:AppendItemFromIni(INI_PATH, 'Handle_Box'):Lookup('Box_Skill'):Hide()
			for i = hList:GetItemCount() - 1, hList.nIndexBase + 1 do
				hList:ExchangeItemIndex(i, i - 1)
			end
		end
	elseif nBoxCountOffset < 0 then
		for i = nBoxCountOffset, -1 do
			hList:LogicRemoveItem(0)
			hList.nIndexBase = hList.nIndexBase % hList:GetItemCount()
		end
	end
	local nBoxesW = BOX_WIDTH * O.nVisualSkillBoxCount
	frame:Lookup('', 'Handle_Bg/Image_Bg_11'):SetW(nBoxesW)
	frame:Lookup('', 'Handle_Bg'):FormatAllItemPos()
	frame:Lookup('', ''):FormatAllItemPos()
	frame:SetW(nBoxesW + 169)
	hList:SetW(nBoxesW)
	hList.nCount = nBoxCount
	D.UpdateAnimation(frame, 1)
end

function D.OnSkillCast(frame, dwSkillID, dwSkillLevel)
	-- ��ȡ������Ϣ
	local szSkillName, dwIconID = X.GetSkillName(dwSkillID, dwSkillLevel)
	if dwSkillID == 4097 then -- ���
		dwIconID = 1899
	end
	-- ������������
	if not szSkillName or szSkillName == '' then
		return
	end
	-- �չ�����
	if COMMON_SKILL[dwSkillID] then
		return
	end
	-- ����ͼ�꼼������
	if dwIconID == 1817 --[[����]] or dwIconID == 533 --[[����]] or dwIconID == 0 --[[�Ӽ���]] or dwIconID == 13 --[[�Ӽ���]] then
		return
	end
	-- ���ͷż�������
	if Table_IsSkillFormation(dwSkillID, dwSkillLevel) or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel) then
		return
	end
	-- ��Ⱦ���津������
	local box = frame:Lookup('', 'Handle_Boxes')
		:LogicLookup(-1):Lookup('Box_Skill')
	box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
	box:SetObjectIcon(dwIconID)
	box:Show()
	D.StartAnimation(frame, 1)
end

function D.OnFrameCreate()
	local hList = this:Lookup('', 'Handle_Boxes')
	hList.LogicLookup = function(el, i)
		return el:Lookup((i + el.nIndexBase) % el.nCount)
	end
	hList.LogicRemoveItem = function(el, i)
		return el:RemoveItem((i + el.nIndexBase) % el.nCount)
	end
	hList.nIndexBase = 0
	hList.nCount = 0
	D.CorrectBoxCount(this)
	this:RegisterEvent('RENDER_FRAME_UPDATE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('DO_SKILL_CAST')
	this:RegisterEvent('DO_SKILL_CHANNEL_PROGRESS')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT')
	D.OnEvent('UI_SCALED')
end

function D.OnEvent(event)
	if event == 'RENDER_FRAME_UPDATE' then
		if not this.nTickStart then
			return
		end
		local nTickDuring = GetTickCount() - this.nTickStart
		if nTickDuring > 600 then
			this.nTickStart = nil
		end
		D.UpdateAnimation(this, math.min(math.max(nTickDuring / BOX_ANIMATION_TIME, 0), 1))
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'DO_SKILL_CAST' then
		local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
		if dwID == X.GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'DO_SKILL_CHANNEL_PROGRESS' then
		local dwID, dwSkillID, dwSkillLevel = arg3, arg1, arg2
		if dwID == X.GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
		MY_VisualSkill.anchor = GetFrameAnchor(this)
	elseif event == 'CUSTOM_UI_MODE_SET_DEFAULT' then
		MY_VisualSkill.anchor = X.Clone(DEFAULT_ANCHOR)
		D.UpdateAnchor(this)
	end
end

function D.Open()
	X.UI.OpenFrame(INI_PATH, 'MY_VisualSkill')
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_VisualSkill')
end

function D.Close()
	X.UI.CloseFrame('MY_VisualSkill')
end

function D.Reload()
	if D.bReady and O.bEnable then
		local frame = D.GetFrame()
		if frame then
			D.CorrectBoxCount(frame)
		else
			D.Open()
		end
	else
		D.Close()
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Visual skill'],
		checked = MY_VisualSkill.bEnable,
		onCheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
		end,
	}):Width() + 5

	ui:Append('WndSlider', {
		x = nX, y = nY,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L('Display %d skills.', MY_VisualSkill.nVisualSkillBoxCount),
		textFormatter = function(val) return _L('Display %d skills.', val) end,
		onChange = function(val)
			MY_VisualSkill.nVisualSkillBoxCount = val
		end,
	})
	nX = nPaddingX
	nY = nY + nLH
	return nX, nY
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_VisualSkill',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'bPenetrable',
				'nVisualSkillBoxCount',
				'anchor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bPenetrable',
				'nVisualSkillBoxCount',
				'anchor',
			},
			triggers = {
				bEnable              = D.Reload,
				nVisualSkillBoxCount = D.Reload,
			},
			root = O,
		},
	},
}
MY_VisualSkill = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_VisualSkill', function()
	D.bReady = true
	D.Reload()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
