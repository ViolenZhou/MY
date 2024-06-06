--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ����ʱ��
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_SpellTimer'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_SpellTimer'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^22.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_TeamMon_SpellTimer', { ['*'] = false })
--------------------------------------------------------------------------

local MY_FormatDuration = X.FormatDuration
local FilterCustomText = MY_TeamMon.FilterCustomText

local O = X.CreateUserSettingsModule('MY_TeamMon_SpellTimer', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'TOPRIGHT', r = 'CENTER', x = -250, y = -300 },
	},
	nBelowDecimal = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamMon'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
})
local D = {}

-- ST class
local ST = {}
ST.__index = ST

local MY_TEAM_MON_TYPE = MY_TeamMon.MY_TEAM_MON_TYPE
local ST_INI_FILE = X.PACKET_INFO.ROOT .. 'MY_TeamMon/ui/MY_TeamMon_SpellTimer.ini'
local ST_UI_NORMAL = 5
local ST_UI_WARNING = 2
local ST_UI_ALPHA = 180
local ST_TIME_EXPIRE = {}
local ST_CACHE = {}
do
	for k, v in pairs(MY_TEAM_MON_TYPE) do
		ST_CACHE[v] = setmetatable({}, { __mode = 'v' })
		ST_TIME_EXPIRE[v] = {}
	end
end

-- �����ֶε���ʱ
local function ParseCountdown(szCountdown, szSender, szReceiver)
	local aCountdown = MY_TeamMon.ParseCountdown(szCountdown)
	if X.IsTable(aCountdown) then
		for _, v in ipairs(aCountdown) do
			v.szContent = FilterCustomText(v.szContent, szSender, szReceiver)
		end
	end
	return aCountdown
end

-- ����ʱģ�� �¼����� MY_TEAM_MON__SPELL_TIMER__CREATE
-- nType ����ʱ���� MY_TEAM_MON_TYPE
-- szKey ͬһ������Ψһ��ʶ��
-- tParam {
--      szName   -- ����ʱ���� ����ǷֶξͲ���Ҫ������
--      nTime    -- ʱ��  �� 10,����;25,����2; �� 30
--      nRefresh -- ����ʱ���ڽ�ֹ�ظ�ˢ��
--      nIcon    -- ����ʱͼ��ID
--      bTalk    -- �Ƿ񷢲�����ʱ 5�����������ʾ ��szName�� ʣ�� n �롣
-- }
-- ���ӣ�FireUIEvent('MY_TEAM_MON__SPELL_TIMER__CREATE', 0, 'test', { nTime = '5,test;15,����;25,c', szName = 'demo' })
-- ���ܲ��ԣ�for i = 1, 200 do FireUIEvent('MY_TEAM_MON__SPELL_TIMER__CREATE', 0, i, { nTime = Random(5, 15), nIcon = i }) end
local function CreateCountdown(nType, szKey, tParam, szSender, szReceiver)
	assert(type(tParam) == 'table', 'CreateCountdown failed!')
	local tTime = {}
	local nTime = GetTime()
	if X.IsNumber(tParam.nTime) then
		tTime = {
			nTime = tParam.nTime,
			szContent = tParam.szContent,
		}
	elseif X.IsString(tParam.nTime) then
		local aCountdown = ParseCountdown(tParam.nTime, szSender, szReceiver)
		if aCountdown then
			tTime = aCountdown[1]
			tParam.nTime = aCountdown
			tParam.nRefresh = tParam.nRefresh or aCountdown[#aCountdown].nTime - 3 -- ���ʱ���ڷ�ֹ�ظ�ˢ�� ��������ս����NPC��Ҫ�ֶ�ɾ��
		else
			return X.OutputSystemMessage(
				_L['MY_TeamMon'],
				_L['Countdown format error']
					.. ' TYPE: ' .. _L['Countdown TYPE ' .. nType]
					.. ' KEY:' .. szKey .. ' Content:' .. tParam.nTime,
				X.CONSTANT.MSG_THEME.ERROR)
		end
	else
		return X.OutputSystemMessage(
			_L['MY_TeamMon'],
			_L['Countdown format error']
				.. ' TYPE: ' .. _L['Countdown TYPE ' .. nType]
				.. ' KEY:' .. szKey .. ' Content:' .. X.EncodeLUAData(tParam.nTime),
			X.CONSTANT.MSG_THEME.ERROR)
	end
	if tTime.nTime == 0 then
		local ui = ST_CACHE[nType][szKey]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
		ST_TIME_EXPIRE[nType][szKey] = nil
	elseif tTime.nTime == -1 then
		local ui = ST_CACHE[nType][szKey]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
	elseif tTime.nTime == -2 then
		ST_TIME_EXPIRE[nType][szKey] = nil
	else
		local nExpire = ST_TIME_EXPIRE[nType][szKey]
		if nExpire and nExpire > nTime then
			return
		end
		ST_TIME_EXPIRE[nType][szKey] = nTime + (tParam.nRefresh or 0) * 1000
		ST:ctor(nType, szKey, tParam):SetInfo(tTime, tParam.nIcon or 13):Switch(false)
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('MY_TEAM_MON__SPELL_TIMER__CREATE')
	this:RegisterEvent('MY_TEAM_MON__SPELL_TIMER__DEL')
	this:RegisterEvent('MY_TEAM_MON__SPELL_TIMER__CLEAR')
	D.hItem = this:CreateItemData(ST_INI_FILE, 'Handle_Item')
	D.UpdateAnchor(this)
	D.handle = this:Lookup('', 'Handle_List')
end

function D.OnEvent(szEvent)
	if szEvent == 'MY_TEAM_MON__SPELL_TIMER__CREATE' then
		CreateCountdown(arg0, arg1, arg2, arg3, arg4)
	elseif szEvent == 'MY_TEAM_MON__SPELL_TIMER__DEL' then
		local ui = ST_CACHE[arg0][arg1]
		if ui and ui:IsValid() then
			ui.obj:RemoveItem()
		end
		ST_TIME_EXPIRE[arg0][arg1] = nil
	elseif szEvent == 'MY_TEAM_MON__SPELL_TIMER__CLEAR' then
		D.handle:Clear()
		for k, v in pairs(ST_TIME_EXPIRE) do
			ST_TIME_EXPIRE[k] = {}
		end
	elseif szEvent == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif szEvent == 'ON_ENTER_CUSTOM_UI_MODE' or szEvent == 'ON_LEAVE_CUSTOM_UI_MODE' then
		this:BringToTop()
		UpdateCustomModeWindow(this, _L['Countdown'])
	elseif szEvent == 'LOADING_END' then
		for k, v in pairs(ST_CACHE) do
			for kk, vv in pairs(v) do
				if vv and vv:IsValid() and not vv.bHold then
					vv.obj:RemoveItem()
				end
			end
		end
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.tAnchor = GetFrameAnchor(this, 'TOPLEFT')
end

local function SetSTAction(ui, nLeft, nPer)
	local me = X.GetClientPlayer()
	local obj = ui.obj
	if nLeft < 5 then
		local nTimeLeft = nLeft * 1000 % 1000
		local nAlpha = 255 * nTimeLeft / 1000
		if math.floor(nLeft / 1) % 2 == 1 then
			nAlpha = 255 - nAlpha
		end
		obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):Switch(true):SetAlpha(100 + nAlpha)
		if ui.bTalk and me.IsInParty() then
			if not ui.szTalk or ui.szTalk ~= math.floor(nLeft) then
				ui.szTalk = math.floor(nLeft)
				MY_TeamMon.SendChat(PLAYER_TALK_CHANNEL.RAID, _L('[%s] remaining %ds.', obj:GetName(), math.floor(nLeft)))
			end
		end
	else
		if ui.nAlpha < ST_UI_ALPHA then
			ui.nAlpha = math.min(ST_UI_ALPHA, ui.nAlpha + 15)
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer):SetAlpha(ui.nAlpha)
		else
			obj:SetInfo({ nTime = nLeft }):SetPercentage(nPer)
		end
	end
end

function D.OnFrameBreathe()
	local me = X.GetClientPlayer()
	if not me then return end
	local nNow = GetTime()
	for k, v in pairs(ST_CACHE) do
		for kk, vv in pairs(v) do
			if vv:IsValid() then
				if type(vv.countdown) == 'number' then
					local nLeft  = vv.countdown - ((nNow - vv.nLeft) / 1000)
					if nLeft >= 0 then
						SetSTAction(vv, nLeft, nLeft / vv.countdown)
					else
						vv.obj:RemoveItem()
					end
				else
					local time = vv.countdown[1]
					local nLeft = time.nTime - (nNow - vv.nLeft) / 1000
					if nLeft >= 0 then
						SetSTAction(vv, nLeft, nLeft / time.nTime)
					else
						if #vv.countdown == 1 then
							vv.obj:RemoveItem()
						else
							local nATime = (nNow - vv.nCreate) / 1000
							vv.nLeft = nNow
							table.remove(vv.countdown, 1)
							local time = vv.countdown[1]
							time.nTime = time.nTime - nATime
							vv.obj:SetInfo(time):Switch(false)
						end
					end
				end
			end
		end
	end
	D.handle:Sort()
	D.handle:FormatAllItemPos()
end

function D.UpdateAnchor(frame)
	local a = O.tAnchor
	frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	frame:CorrectPos()
end

-- ���캯��
function ST:ctor(nType, szKey, tParam)
	if not ST_CACHE[nType] then
		return
	end
	if not tParam.szName then
		tParam.szName = nType .. '#' .. szKey
	end
	local ui = ST_CACHE[nType][szKey]
	local nTime = GetTime()
	local oo
	if ui and ui:IsValid() then
		oo = ui.obj
		oo.ui.nCreate   = nTime
		oo.ui.nLeft     = nTime
		oo.ui.countdown = tParam.nTime
		oo.ui.nRefresh  = tParam.nRefresh or 1
		oo.ui.bTalk     = tParam.bTalk
		oo.ui.nFrame    = tParam.nFrame
	else -- û��ui������� ����
		oo = {}
		setmetatable(oo, self)
		oo.ui                = D.handle:AppendItemFromData(D.hItem)
		-- ����
		oo.ui.nCreate        = nTime
		oo.ui.nLeft          = nTime
		oo.ui.countdown      = tParam.nTime
		oo.ui.nRefresh       = tParam.nRefresh or 1
		oo.ui.bTalk          = tParam.bTalk
		oo.ui.nFrame         = tParam.nFrame
		oo.ui.bHold          = tParam.bHold
		-- ����
		oo.ui.nAlpha         = 30
		-- ui
		oo.ui.time           = oo.ui:Lookup('TimeLeft')
		oo.ui.txt            = oo.ui:Lookup('SkillName')
		oo.ui.img            = oo.ui:Lookup('Image')
		oo.ui.sha            = oo.ui:Lookup('shadow')
		oo.ui.sfx            = oo.ui:Lookup('SFX')
		oo.ui.obj            = oo
		ST_CACHE[nType][szKey] = oo.ui
		oo.ui:Show()
		oo.ui.sfx:Set2DRotation(math.pi / 2)
		D.handle:FormatAllItemPos()
	end
	return oo
end

-- ���õ���ʱ�����ƺ�ʱ�� ���ڶ�̬�ı�ֶε���ʱ
function ST:SetInfo(tTime, nIcon)
	if tTime.szContent then
		self.ui.txt:SetText(tTime.szContent)
	end
	if tTime.nTime then
		self.ui.time:SetText(
			(
				tTime.nTime >= 60
					and MY_FormatDuration(tTime.nTime - tTime.nTime % 60, 'ENGLISH_ABBR', { accuracyUnit = 'minute' })
					or ''
			)
			.. (
				(D.bReady and O.nBelowDecimal ~= 0 and (O.nBelowDecimal == 3601 or (tTime.nTime < O.nBelowDecimal and tTime.nTime >= 0.1)))
					and ('%.1fs'):format(tTime.nTime % 60)
					or ('%ds'):format(tTime.nTime % 60)
			)
		)
		self.ui:SetUserData(math.floor(tTime.nTime))
	end
	if nIcon then
		local box = self.ui:Lookup('Box')
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN)
		box:SetObjectIcon(nIcon)
	end
	if MY_TeamMon.bPushVoiceAlarm and tTime.szVoice then
		FireUIEvent('MY_TEAM_MON__VOICE_ALARM', tTime.szVoice)
	end
	return self
end

-- ���ý�����
function ST:SetPercentage(fPercentage)
	self.ui.img:SetPercentage(fPercentage)
	self.ui.sfx:SetRelX(32 + 300 * fPercentage)
	self.ui.sha:SetW(300 - 300 * fPercentage)
	self.ui.sha:SetRelX(32 + 300 * fPercentage)
	self.ui:FormatAllItemPos()
	return self
end

-- �ı���ʽ ���true�����Ϊ�ڶ���ʽ ����ʱ��С��5���ʱ��
function ST:Switch(bSwitch)
	if bSwitch then
		self.ui.txt:SetFontColor(255, 255, 255)
		-- self.ui.time:SetFontColor(255, 255, 255)
		self.ui.img:SetFrame(ST_UI_WARNING)
		-- self.ui.sha:SetColorRGB(30, 0, 0)
	else
		self.ui.txt:SetFontColor(255, 255, 0)
		self.ui.time:SetFontColor(255, 255, 255)
		self.ui.img:SetFrame(self.ui.nFrame or ST_UI_NORMAL)
		self.ui.img:SetAlpha(self.ui.nAlpha)
		-- self.ui.sha:SetAlpha(100)
		self.ui.sha:SetColorRGB(0, 0, 0)
	end
	return self
end

function ST:SetAlpha(nAlpha)
	self.ui.img:SetAlpha(nAlpha)
	-- self.ui.sha:SetAlpha(100 * (nAlpha / 255))
	return self
end

function ST:GetName()
	return self.ui.txt:GetText()
end

-- ɾ������ʱ
function ST:RemoveItem()
	D.handle:RemoveItem(self.ui)
	D.handle:FormatAllItemPos()
end

function D.CheckEnable()
	X.UI.CloseFrame('MY_TeamMon_SpellTimer')
	if X.IsRestricted('MY_TeamMon_SpellTimer') then
		return
	end
	X.UI.OpenFrame(ST_INI_FILE, 'MY_TeamMon_SpellTimer')
end

function D.Init()
	D.CheckEnable()
end

--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_SpellTimer',
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				'nBelowDecimal',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'nBelowDecimal',
			},
			root = O,
		},
	},
}
MY_TeamMon_SpellTimer = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_TeamMon_SpellTimer', function()
	if arg0 and arg0 ~= 'MY_TeamMon_SpellTimer' then
		return
	end
	D.CheckEnable()
end)

X.RegisterUserSettingsInit('MY_TeamMon_SpellTimer', function()
	D.bReady = true
	D.Init()
end)

X.RegisterUserSettingsRelease('MY_TeamMon_SpellTimer', function()
	D.bReady = false
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
