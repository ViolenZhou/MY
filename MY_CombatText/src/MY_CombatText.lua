--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ս����������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_CombatText/MY_CombatText'
local PLUGIN_NAME = 'MY_CombatText'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_CombatText'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE
local GetSkill, Random = GetSkill, Random
local Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible = Table_GetBuffName, Table_GetSkillName, Table_BuffIsVisible

-- ս�������������˼·
--[[
	ͣ��ʱ�䣺ʹ�ã���֡�� * ÿ֡ʱ�䣩��������ͣ��ʱ�䣬
	alpha��   ʹ��֡��������fadein��fadeout��
	����    ����ʹ�ü��׼�����룬������й켣�����̶��ϱ�֤���ܺ͸�����ֵ������
	����켣��ʹ�ùؼ�֡��ʽ��һ��32�ؼ�֡�������������ӳ�֡��
	���֣�    �Գ�����1֡���ӳٴ�����1֡����5���˺����5֡���γ��֡�
	-------------------------------------------------------------------------------
	��ʼ�������ͣ���Ϊ ���� �� �� ���� ���� ����
	������
		Y��켣�� �� math.floor(3.5 / UI����) ���������ʼY��߶Ȳ�ͬ��
		�ڹ켣ȫ����ռ�ú�������̯����Ļ�����������ߡ�
	�������ͣ�ʹ�ù켣�ϲ�16-32֡���������ı��ᶥ��ǰ����ı����Ӷ������ⲿ��ͣ����֡����
]]

local COMBAT_TEXT_INIFILE          = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText_Render.ini'
local COMBAT_TEXT_CONFIG           = X.FormatPath({'config/CombatText.jx3dat', X.PATH_TYPE.GLOBAL})
local COMBAT_TEXT_PLAYERID         = 0
local COMBAT_TEXT_IN_ROGUELIKE_MAP = false
local COMBAT_TEXT_TOTAL            = 32
local COMBAT_TEXT_UI_SCALE         = 1
local COMBAT_TEXT_TRAJECTORY       = 4   -- ����Y��켣���� �������Ŵ�С�仯 0.8����5���� ��ĻС����

local COMBAT_TEXT_TYPE = {
	DAMAGE               = 'DAMAGE'              ,

	THERAPY              = 'THERAPY'             ,
	EFFECTIVE_THERAPY    = 'EFFECTIVE_THERAPY'   ,
	STEAL_LIFE           = 'STEAL_LIFE'          ,

	PHYSICS_DAMAGE       = 'PHYSICS_DAMAGE'      ,
	SOLAR_MAGIC_DAMAGE   = 'SOLAR_MAGIC_DAMAGE'  ,
	NEUTRAL_MAGIC_DAMAGE = 'NEUTRAL_MAGIC_DAMAGE',
	LUNAR_MAGIC_DAMAGE   = 'LUNAR_MAGIC_DAMAGE'  ,
	POISON_DAMAGE        = 'POISON_DAMAGE'       ,
	REFLECTED_DAMAGE     = 'REFLECTED_DAMAGE'    ,
	SPIRIT               = 'SPIRIT'              ,
	STAYING_POWER        = 'STAYING_POWER'       ,

	SHIELD_DAMAGE        = 'SHIELD_DAMAGE'       ,
	ABSORB_DAMAGE        = 'ABSORB_DAMAGE'       ,
	PARRY_DAMAGE         = 'PARRY_DAMAGE'        ,
	INSIGHT_DAMAGE       = 'INSIGHT_DAMAGE'      ,

	SKILL_BUFF           = 'SKILL_BUFF'          ,
	SKILL_DEBUFF         = 'SKILL_DEBUFF'        ,
	SKILL_MISS           = 'SKILL_MISS'          ,
	BUFF_IMMUNITY        = 'BUFF_IMMUNITY'       ,
	SKILL_DODGE          = 'SKILL_DODGE'         ,
	EXP                  = 'EXP'                 ,
	MSG                  = 'MSG'                 ,
	CRITICAL_MSG         = 'CRITICAL_MSG'        ,
}

local COMBAT_TEXT_CRITICAL = { -- ��Ҫ������֡����������
	[COMBAT_TEXT_TYPE.THERAPY             ] = true,
	[COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY   ] = true,
	[COMBAT_TEXT_TYPE.STEAL_LIFE          ] = true,
	[COMBAT_TEXT_TYPE.PHYSICS_DAMAGE      ] = true,
	[COMBAT_TEXT_TYPE.SOLAR_MAGIC_DAMAGE  ] = true,
	[COMBAT_TEXT_TYPE.NEUTRAL_MAGIC_DAMAGE] = true,
	[COMBAT_TEXT_TYPE.LUNAR_MAGIC_DAMAGE  ] = true,
	[COMBAT_TEXT_TYPE.POISON_DAMAGE       ] = true,
	[COMBAT_TEXT_TYPE.REFLECTED_DAMAGE    ] = true,
	[COMBAT_TEXT_TYPE.EXP                 ] = true,
	[COMBAT_TEXT_TYPE.CRITICAL_MSG        ] = true,
}
local COMBAT_TEXT_EVENT  = { 'COMMON_HEALTH_TEXT', 'SKILL_EFFECT_TEXT', 'SKILL_MISS', 'SKILL_DODGE', 'SKILL_BUFF', 'BUFF_IMMUNITY' }
local COMBAT_TEXT_OFFICIAL_EVENT = { 'SKILL_EFFECT_TEXT', 'COMMON_HEALTH_TEXT', 'SKILL_MISS', 'SKILL_DODGE', 'SKILL_BUFF', 'BUFF_IMMUNITY', 'ON_EXP_LOG', 'SYS_MSG', 'FIGHT_HINT' }
local COMBAT_TEXT_SKILL_IGNORE = {}
local COMBAT_TEXT_SKILL_TYPE_IGNORE = {}
local COMBAT_TEXT_SKILL_STATIC_STRING = X.KvpToObject({ -- ��Ҫ����ض��ַ������˺�����
	{SKILL_RESULT_TYPE.SHIELD_DAMAGE , g_tStrings.STR_MSG_ABSORB    },
	{SKILL_RESULT_TYPE.ABSORB_DAMAGE , g_tStrings.STR_MSG_ABSORB    },
	{SKILL_RESULT_TYPE.PARRY_DAMAGE  , g_tStrings.STR_MSG_COUNTERACT},
	{SKILL_RESULT_TYPE.INSIGHT_DAMAGE, g_tStrings.STR_MSG_INSIGHT   },
})

local COMBAT_TEXT_STYLES = {
	[0] = {
		2, 4.5, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[1] = {
		2, 4.5, 4, 3, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[2] = {
		1, 2, 3, 4.5, 3, 3, 3, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	[3] = {
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	}
}

local COMBAT_TEXT_SCALE = { -- �����˺�������֡�� һ��32֡
	CRITICAL = { -- ����
		2, 4.5, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
		2, 2, 2, 2, 2, 2, 2, 2,
	},
	NORMAL = { -- ��ͨ�˺�
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
		1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	},
}

local COMBAT_TEXT_POINT = {
	TOP = { -- �˺� ���ϵ� ������ ��ͨ �� �� ��~~
		0,   6,   12,  18,  24,  30,  36,  42,
		45,  48,  51,  54,  57,  60,  63,  66,
		69,  72,  75,  78,  81,  84,  87,  90,
		100, 110, 120, 130, 140, 150, 160, 170,
	},
	RIGHT = { -- �������ҵ�
		8,   16,  24,  32,  40,  48,  56,  64,
		72,  80,  88,  96,  104, 112, 120, 128,
		136, 136, 136, 136, 136, 136, 136, 136,
		136, 136, 136, 136, 136, 136, 136, 136,
		139, 142, 145, 148, 151, 154, 157, 160,
		163, 166, 169, 172, 175, 178, 181, 184,
	},
	LEFT = { -- ���ҵ���
		8,   16,  24,  32,  40,  48,  56,  64,
		72,  80,  88,  96,  104, 112, 120, 128,
		136, 136, 136, 136, 136, 136, 136, 136,
		136, 136, 136, 136, 136, 136, 136, 136,
		139, 142, 145, 148, 151, 154, 157, 160,
		163, 166, 169, 172, 175, 178, 181, 184,
	},
	BOTTOM_LEFT = { -- ���½�
		5,   10,  15,  20,  25,  30,  35,  40,
		45,  50,  55,  60,  65,  70,  75,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		82,  84,  86,  88,  90,  92,  94,  96,
		98,  100, 102, 104, 106, 108, 110, 112,
	},
	BOTTOM_RIGHT = {
		5,   10,  15,  20,  25,  30,  35,  40,
		45,  50,  55,  60,  65,  70,  75,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		80,  80,  80,  80,  80,  80,  80,  80,
		82,  84,  86,  88,  90,  92,  94,  96,
		98,  100, 102, 104, 106, 108, 110, 112,
	},
}

local COMBAT_TEXT_COLOR = {
	-- ����
	[COMBAT_TEXT_TYPE.DAMAGE              ] = X.ENVIRONMENT.GAME_PROVIDER == 'remote' and { 253, 86, 86 } or { 255, 0, 0 }, -- ���� �Լ��ܵ����˺�
	-- ����
	[COMBAT_TEXT_TYPE.THERAPY             ] = {   0, 255,   0 }, -- ����
	[COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY   ] = {   0, 255,   0 }, -- ��Ч����
	[COMBAT_TEXT_TYPE.STEAL_LIFE          ] = {   0, 255,   0 }, -- ͵ȡ��Ѫ
	-- ��ʽ
	[COMBAT_TEXT_TYPE.PHYSICS_DAMAGE      ] = { 255, 255, 255 }, -- �⹦����
	[COMBAT_TEXT_TYPE.SOLAR_MAGIC_DAMAGE  ] = { 255, 128, 128 }, -- ���Թ���
	[COMBAT_TEXT_TYPE.NEUTRAL_MAGIC_DAMAGE] = { 255, 255,   0 }, -- ��Ԫ����
	[COMBAT_TEXT_TYPE.LUNAR_MAGIC_DAMAGE  ] = {  12, 242, 255 }, -- ���Թ���
	[COMBAT_TEXT_TYPE.POISON_DAMAGE       ] = { 128, 255, 128 }, -- ���Թ���
	[COMBAT_TEXT_TYPE.REFLECTED_DAMAGE    ] = { 255, 128, 128 }, -- �����˺�
	[COMBAT_TEXT_TYPE.SPIRIT              ] = { 160,   0, 160 }, -- ����
	[COMBAT_TEXT_TYPE.STAYING_POWER       ] = { 255, 169,   0 }, -- ����

	[COMBAT_TEXT_TYPE.SHIELD_DAMAGE       ] = { 255, 255,   0 },
	[COMBAT_TEXT_TYPE.ABSORB_DAMAGE       ] = { 255, 255,   0 },
	[COMBAT_TEXT_TYPE.PARRY_DAMAGE        ] = { 255, 255,   0 },
	[COMBAT_TEXT_TYPE.INSIGHT_DAMAGE      ] = { 255, 255,   0 },

	[COMBAT_TEXT_TYPE.SKILL_BUFF          ] = { 255, 255,   0 },
	[COMBAT_TEXT_TYPE.SKILL_DEBUFF        ] = { 255,   0,   0 },
	[COMBAT_TEXT_TYPE.SKILL_MISS          ] = { 255, 255, 255 },
	[COMBAT_TEXT_TYPE.BUFF_IMMUNITY       ] = { 255, 255, 255 },
	[COMBAT_TEXT_TYPE.SKILL_DODGE         ] = { 255,   0,   0 },

	[COMBAT_TEXT_TYPE.EXP                 ] = { 255,   0, 255 },
	[COMBAT_TEXT_TYPE.MSG                 ] = { 255, 255,   0 },
	[COMBAT_TEXT_TYPE.CRITICAL_MSG        ] = { 255,   0,   0 },
}
local COMBAT_TEXT_CRITICAL_COLOR = {}

local COMBAT_TEXT_TYPE_CLASS = {
	[COMBAT_TEXT_TYPE.STEAL_LIFE       ] = 'THERAPY',
	[COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY] = 'THERAPY',
	[COMBAT_TEXT_TYPE.THERAPY          ] = 'THERAPY',
}

local COMBAT_TEXT_LEAVE  = {}
local COMBAT_TEXT_FREE   = {}
--  �ϲ��˺� cache ��¼��ʽ�� dwTargetID + _ + szPoint = nValue
local COMBAT_TEXT_COMBINE = {}
local COMBAT_TEXT_SHADOW = {}
local COMBAT_TEXT_QUEUE  = {}
local COMBAT_TEXT_CACHE  = { -- buff������cache
	BUFF   = {},
	DEBUFF = {},
}

local COMBAT_TEXT_TYPE_NAME = setmetatable(_L.COMBAT_TEXT_TYPE_NAME or {}, { __index = function(_, k) return k end })

local O = X.CreateUserSettingsModule('MY_CombatText', _L['System'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bRender = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nStyle = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nMaxAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 240,
	},
	nMaxCount = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 300,
	},
	nTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 40,
	},
	nFadeIn = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 4,
	},
	nFadeOut = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 8,
	},
	nFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Number,
		xDefaultValue = 19,
	},
	bImmunity = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOtherCharacter = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bCritical = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOptimizeRoguelike = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	-- ��ʾ�ϲ��ı�������һ����
	bEnableCombineText = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	-- $name ���� $sn   ������ $crit ���� $val  ��ֵ
	szSkill = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit $val',
	},
	szTherapy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit +$val',
	},
	szDamage = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.String,
		xDefaultValue = '$sn' .. g_tStrings.STR_COLON .. '$crit -$val',
	},
	bCasterNotI = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bSnShorten2 = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTherapyEffectiveOnly = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tColor = { -- ����������ɫ
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Map(X.Schema.OneOf(X.Schema.String, X.Schema.Number), X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {},
	},
	tCriticalColor = { -- ��������������ɫ
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_CombatText'],
		xSchema = X.Schema.Map(X.Schema.OneOf(X.Schema.String, X.Schema.Number), X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {},
	},
})
local D = {}

local function IsEnabled()
	return D.bReady and O.bEnable
end

local function IsCombatTextPlayerID(...)
	if O.bOtherCharacter then
		return true
	end
	for i = 1, select('#', ...) do
		if select(i, ...) == COMBAT_TEXT_PLAYERID then
			return true
		end
	end
	return false
end

function D.GetColor(eType, bCritical)
	return (bCritical and O.bCritical)
		and O.tCriticalColor[eType]
		or O.tColor[eType]
		or COMBAT_TEXT_COLOR[eType]
		or { 255, 255, 255 }
end

function D.HideOfficialCombat()
	local frame = Station.Lookup('Lowest/CombatText')
	if frame then
		for _, v in ipairs(COMBAT_TEXT_OFFICIAL_EVENT) do
			frame:UnRegisterEvent(v)
		end
	end
end

function D.ShowOfficialCombat()
	local frame = Station.Lookup('Lowest/CombatText')
	if frame then
		for _, v in ipairs(COMBAT_TEXT_OFFICIAL_EVENT) do
			frame:UnRegisterEvent(v)
			frame:RegisterEvent(v)
		end
	end
end

function D.OnFrameCreate()
	for k, v in ipairs(COMBAT_TEXT_EVENT) do
		this:RegisterEvent(v)
	end
	this:ShowWhenUIHide()
	this:RegisterEvent('SYS_MSG')
	this:RegisterEvent('FIGHT_HINT')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('NPC_ENTER_SCENE')
	this:RegisterEvent('ON_EXP_LOG')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	D.handle = this:Lookup('', '')
	D.FreeQueue()
	D.UpdateTrajectoryCount()
	X.BreatheCall('COMBAT_TEXT_CACHE', 1000 * 60 * 5, function()
		local count = 0
		for k, v in pairs(COMBAT_TEXT_LEAVE) do
			count = count + 1
		end
		if count > 10000 then
			COMBAT_TEXT_LEAVE = {}
			Log('[MY] CombatText cache beyond 10000 !!!')
		end
	end)
	X.BreatheCall('COMBAT_TEXT_COMBINE', 200, function()
		if not O.bEnableCombineText then
			return
		end
		for k, v in pairs(COMBAT_TEXT_COMBINE) do
			if v.nCount >= 3 then
				local object = X.IsPlayer(v.dwTargetID) and X.GetPlayer(v.dwTargetID) or X.GetNpc(v.dwTargetID)
				local _, fMaxLife = X.GetObjectLife(object)
				if v.nValue > fMaxLife * 0.3 then
					local shadow = D.GetFreeShadow(true)
					if shadow then
						D.CreateText(shadow, v.dwTargetID, _L['Critical Strike'] .. ' ' .. v.nValue, v.szPoint, COMBAT_TEXT_TYPE.CRITICAL_MSG, true, true)
					end
				end
			end
			COMBAT_TEXT_COMBINE[k] = nil
		end
	end)
end
-- for i=1,5 do FireUIEvent('SKILL_EFFECT_TEXT',1073745690,MY.GetClientPlayerID(),true,5,1111,111,1)end
-- for i=1,5 do FireUIEvent('SKILL_EFFECT_TEXT',MY.GetClientPlayerID(),1073745690,true,5,1111,111,1)end
-- for i=1,5 do FireUIEvent('SKILL_EFFECT_TEXT',X.GetClientPlayerID(),1073741860,false,5,1111,111,1)end
-- for i=1, 5 do FireEvent('SKILL_BUFF', X.GetClientPlayerID(), true, 103, 1) end
-- FireUIEvent('SKILL_MISS', X.GetClientPlayerID(), X.GetClientPlayerID())
-- FireUIEvent('SYS_MSG', 'UI_OME_EXP_LOG', X.GetClientPlayerID(), X.GetClientPlayerID())
function D.OnEvent(szEvent)
	if szEvent == 'FIGHT_HINT' then -- ����ս������
		if arg0 then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.STR_MSG_ENTER_FIGHT)
		else
			OutputMessage('MSG_ANNOUNCE_YELLOW', g_tStrings.STR_MSG_LEAVE_FIGHT)
		end
	elseif szEvent == 'COMMON_HEALTH_TEXT' then
		if arg1 ~= 0 then
			D.OnCommonHealth(arg0, arg1)
		end
	elseif szEvent == 'SKILL_EFFECT_TEXT' then
		-- ����������Чֵ SKILL_EFFECT_TEXT �޷���ʾ��������������Ч������ SYS_MSG -> UI_OME_SKILL_EFFECT_LOG ͨ��
		if arg3 == SKILL_RESULT_TYPE.EFFECTIVE_THERAPY then
			return
		end
		D.OnSkillText(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	elseif szEvent == 'SKILL_BUFF' then
		D.OnSkillBuff(arg0, arg1, arg2, arg3)
	elseif szEvent == 'BUFF_IMMUNITY' then
		if not O.bImmunity and IsCombatTextPlayerID(arg1) then
			D.OnBuffImmunity(arg0)
		end
	elseif szEvent == 'SKILL_MISS' then
		if IsCombatTextPlayerID(arg0, arg1) then
			D.OnSkillMiss(arg1)
		end
	elseif szEvent == 'UI_SCALED' then
		D.UpdateTrajectoryCount()
	elseif szEvent == 'SKILL_DODGE' then
		if IsCombatTextPlayerID(arg0, arg1) then
			D.OnSkillDodge(arg1)
		end
	elseif szEvent == 'NPC_ENTER_SCENE' then
		COMBAT_TEXT_LEAVE[arg0] = nil
	elseif szEvent == 'ON_EXP_LOG' then
		D.OnExpLog(arg0, arg1)
	elseif szEvent == 'SYS_MSG' then
		if arg0 == 'UI_OME_DEATH_NOTIFY' then
			if not X.IsPlayer(arg1) then
				COMBAT_TEXT_LEAVE[arg1] = true
			end
		elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
			-- �������ղ�����Ч��������ֵ�ı仯����
			-- (arg1)dwCaster��ʩ���� (arg2)dwTarget��Ŀ�� (arg3)bReact���Ƿ�Ϊ���� (arg4)nEffectType��Effect���� (arg5)dwID:Effect��ID
			-- (arg6)dwLevel��Effect�ĵȼ� (arg7)bCriticalStrike���Ƿ���� (arg8)nCount��tResultCount���ݱ���Ԫ�ظ��� (arg9)tResultCount����ֵ����
			-- ����������Чֵ SKILL_EFFECT_TEXT �޷���ʾ��������������Ч������ SYS_MSG -> UI_OME_SKILL_EFFECT_LOG ͨ��
			if arg9[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY] then
				D.OnSkillText(arg1, arg2, arg7, SKILL_RESULT_TYPE.EFFECTIVE_THERAPY, arg9[SKILL_RESULT_TYPE.EFFECTIVE_THERAPY], arg5, arg6, arg4)
			end
			-- dwCasterID, dwTargetID, bCriticalStrike, nEffectType, nValue, dwSkillID, dwSkillLevel, nEffectType
		end
	elseif szEvent == 'LOADING_END' then
		this:Show()
		D.FreeQueue()
	elseif szEvent == 'COINSHOP_ON_OPEN' or szEvent == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif szEvent == 'COINSHOP_ON_CLOSE' or szEvent == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	end
end

function D.FreeQueue()
	COMBAT_TEXT_LEAVE  = {}
	COMBAT_TEXT_FREE   = {}
	COMBAT_TEXT_SHADOW = {}
	COMBAT_TEXT_CACHE  = {
		BUFF   = {},
		DEBUFF = {},
	}
	D.handle:Clear()
	COMBAT_TEXT_QUEUE = {
		TOP          = {},
		LEFT         = {},
		RIGHT        = {},
		BOTTOM_LEFT  = {},
		BOTTOM_RIGHT = {},
	}
	setmetatable(COMBAT_TEXT_QUEUE, { __index = function(me) return me['TOP'] end, __newindex = function(me) return me['TOP'] end })
end
function D.OnFrameRender()
	if not D.bReady then
		return
	end
	local nTime     = GetTime()
	local nFadeIn   = O.nFadeIn
	local nFadeOut  = O.nFadeOut
	local nMaxAlpha = O.nMaxAlpha
	local nFont     = O.nFont
	local nDelay    = O.nTime
	local g_fScale  = O.fScale
	for k, v in pairs(COMBAT_TEXT_SHADOW) do
		local nFrame = (nTime - v.nTime) / nDelay + 1 -- ÿһ֡�Ƕ��ٺ��� ����ԽС ����Խ��
		local nBefore = math.floor(nFrame)
		local nAfter  = math.ceil(nFrame)
		local fDiff   = nFrame - nBefore
		local nTotal  = COMBAT_TEXT_POINT[v.szPoint] and #COMBAT_TEXT_POINT[v.szPoint] or COMBAT_TEXT_TOTAL
		k:ClearTriangleFanPoint()
		if nBefore < nTotal then
			local nTop   = 0
			local nLeft  = 0
			local nAlpha = nMaxAlpha
			local fScale = 1
			local bTop   = true
			-- alpha
			if nFrame < nFadeIn then
				nAlpha = nMaxAlpha * nFrame / nFadeIn
			elseif nFrame > nTotal - nFadeOut then
				nAlpha = nMaxAlpha * (nTotal - nFrame) / nFadeOut
			end
			-- ����
			if v.szPoint == 'TOP' or v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				nTop = (-60 * g_fScale) + v.nSort * (-40 * g_fScale) - (tTop[nBefore] + (tTop[nAfter] - tTop[nBefore]) * fDiff)
				if v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
					if v.szPoint == 'TOP_LEFT' then
						nLeft = -250
					elseif v.szPoint == 'TOP_RIGHT' then
						nLeft = 250
					end
					nTop = nTop -50
				end
			elseif v.szPoint == 'LEFT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = -60 - (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.85
			elseif v.szPoint == 'RIGHT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				nLeft = 60 + (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				nAlpha = nAlpha * 0.9
			elseif v.szPoint == 'BOTTOM_LEFT' or v.szPoint == 'BOTTOM_RIGHT' then
				local tLeft = COMBAT_TEXT_POINT[v.szPoint]
				local tTop = COMBAT_TEXT_POINT[v.szPoint]
				if v.szPoint == 'BOTTOM_LEFT' then
					nLeft = -130 - (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				else
					nLeft = 130 + (tLeft[nBefore] + (tLeft[nAfter] - tLeft[nBefore]) * fDiff)
				end
				nTop = 50 + tTop[nBefore] + (tTop[nAfter] - tTop[nBefore]) * fDiff
				fScale = 1.5
			end
			-- ����
			if COMBAT_TEXT_CRITICAL[v.eType] then
				local tScale  = v.bCriticalStrike and COMBAT_TEXT_SCALE.CRITICAL or COMBAT_TEXT_SCALE.NORMAL
				fScale  = tScale[nBefore]
				if tScale[nBefore] > tScale[nAfter] then
					fScale = fScale - ((tScale[nBefore] - tScale[nAfter]) * fDiff)
				elseif tScale[nBefore] < tScale[nAfter] then
					fScale = fScale + ((tScale[nAfter] - tScale[nBefore]) * fDiff)
				end
				if COMBAT_TEXT_TYPE_CLASS[v.eType] == 'THERAPY' then -- ������С
					if v.bCriticalStrike then
						fScale = math.max(fScale * 0.7, COMBAT_TEXT_SCALE.NORMAL[#COMBAT_TEXT_SCALE.NORMAL] + 0.1)
					end
					if v.dwTargetID == COMBAT_TEXT_PLAYERID then
						fScale = fScale * 0.95
					end
				elseif v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then -- ������С
					fScale = fScale * 0.85
				end
				if v.szPoint == 'TOP' or v.szPoint == 'TOP_LEFT' or v.szPoint == 'TOP_RIGHT' then
					fScale = fScale * g_fScale
				end
			end
			-- draw
			local r, g, b = unpack(v.col or {255, 255, 255})
			if not COMBAT_TEXT_LEAVE[v.dwTargetID] or not v.object or not v.tPoint[1] then
				k:AppendCharacterID(v.dwTargetID, bTop, r, g, b, nAlpha, { 0, 0, 0, nLeft * COMBAT_TEXT_UI_SCALE, nTop * COMBAT_TEXT_UI_SCALE}, nFont, v.szText, 1, fScale)
				if v.object and v.object.nX then
					v.tPoint = { v.object.nX, v.object.nY, v.object.nZ }
				else -- DEBUG  JX3Client   [Script index] pointer invalid. call stack: ��������������� ��������ڴ�й¶
					if not COMBAT_TEXT_LEAVE[v.dwTargetID] then
						COMBAT_TEXT_LEAVE[v.dwTargetID] = true
					end
				end
			else
				local x, y, z = unpack(v.tPoint)
				k:AppendTriangleFan3DPoint(x, y, z, r, g, b, nAlpha, { 0, 1.65 * 64, 0, nLeft * COMBAT_TEXT_UI_SCALE, nTop * COMBAT_TEXT_UI_SCALE}, nFont, v.szText, 1, fScale)
			end
			-- �ϲ��˺� ��ǰ
			if not v.bJump and v.szPoint ~= 'TOP' and nFrame >= 16 and nFrame <= 32 then
				for kk, vv in pairs(COMBAT_TEXT_SHADOW) do
					if k ~= kk
						and vv.nFrame <= 32
						and v.szPoint == vv.szPoint
						and not vv.bJump
						and v.nTime > vv.nTime
					then
						vv.bJump = true
					end
				end
			end
			if v.bJump and v.szPoint ~= 'TOP' and nFrame >= 16 and nFrame <= 32 then
				v.nTime = v.nTime - (32 - nFrame) * nDelay
			else
				v.nFrame = nFrame
			end
		else
			if v.szPoint == 'RIGHT' and v.dwTargetID == COMBAT_TEXT_PLAYERID then
				if v.eType == COMBAT_TEXT_TYPE.SKILL_BUFF and COMBAT_TEXT_CACHE.BUFF[v.szText] then
					COMBAT_TEXT_CACHE.BUFF[v.szText] = nil
				elseif v.eType == COMBAT_TEXT_TYPE.SKILL_DEBUFF and COMBAT_TEXT_CACHE.DEBUFF[v.szText] then
					COMBAT_TEXT_CACHE.DEBUFF[v.szText] = nil
				end
			end
			k.free = true
			COMBAT_TEXT_SHADOW[k] = nil
		end
	end
	for k, v in pairs(COMBAT_TEXT_QUEUE) do
		for kk, vv in pairs(v) do
			if #vv > 0 then
				local dat = table.remove(vv, 1)
				if dat.dat.szPoint == 'TOP' then
					local nSort, szPoint = D.GetTrajectory(dat.dat.dwTargetID)
					dat.dat.nSort   = nSort
					dat.dat.szPoint = szPoint
				end
				dat.dat.nTime = GetTime()
				COMBAT_TEXT_SHADOW[dat.shadow] = dat.dat
			else
				COMBAT_TEXT_QUEUE[k][kk] = nil
			end
		end
	end
end

D.OnFrameBreathe = D.OnFrameRender
D.OnFrameRender  = D.OnFrameRender

function D.UpdateTrajectoryCount()
	if D.bReady then
		COMBAT_TEXT_UI_SCALE   = Station.GetUIScale() * 0.6
		COMBAT_TEXT_TRAJECTORY = O.fScale < 1.5
			and math.floor(3.5 / COMBAT_TEXT_UI_SCALE / O.fScale)
			or math.floor(3.5 / COMBAT_TEXT_UI_SCALE)
	end
end


local function TrajectorySort(a, b)
	if a.nCount == b.nCount then
		return a.nSort < b.nSort
	else
		return a.nCount < b.nCount
	end
end

-- ���̶���ʹ�ü������Ч�� ȱ�ٻ��� ������
function D.GetTrajectory(dwTargetID, bCriticalStrike)
	local tSort = {}
	local fRange = 1 / COMBAT_TEXT_TRAJECTORY
	for i = 1, COMBAT_TEXT_TRAJECTORY do
		tSort[i] = { nSort = i, nCount = 0, fRange = i * fRange }
	end
	for k, v in pairs(COMBAT_TEXT_SHADOW) do
		if v.dwTargetID == dwTargetID
			and v.szPoint == 'TOP'
			and v.nFrame < 15
		then
			local fSort = (COMBAT_TEXT_POINT.TOP[math.floor(v.nFrame) + 1] + v.nSort * fRange * COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]) / COMBAT_TEXT_POINT.TOP[COMBAT_TEXT_TOTAL]
			for i = 1, COMBAT_TEXT_TRAJECTORY do
				if fSort < tSort[i].fRange then
					tSort[i].nCount = tSort[i].nCount + 1
					break
				end
			end
		end
	end
	table.sort(tSort, TrajectorySort)
	local nSort = tSort[1].nSort - 1
	local szPoint = 'TOP'
	if tSort[1].nCount == 1 then
		szPoint = Random(2) == 1 and 'TOP_LEFT' or 'TOP_RIGHT'
		nSort = 0
	end
	return nSort, szPoint
end

function D.CreateColorText(shadow, dwTargetID, szText, szPoint, eType, bCriticalStrike, tCol, bIsCombineText)
	local object, tPoint
	local bIsPlayer = X.IsPlayer(dwTargetID)
	if dwTargetID ~= COMBAT_TEXT_PLAYERID then
		object = bIsPlayer and X.GetPlayer(dwTargetID) or X.GetNpc(dwTargetID)
		if object and object.nX then
			tPoint = { object.nX, object.nY, object.nZ }
		end
	end
	local dat = {
		szPoint         = szPoint,
		nSort           = 0,
		dwTargetID      = dwTargetID,
		szText          = szText,
		eType           = eType,
		nFrame          = 0,
		bCriticalStrike = bCriticalStrike,
		col             = tCol or D.GetColor(eType, bCriticalStrike),
		object          = object,
		tPoint          = tPoint,
	}
	if dat.bCriticalStrike or bIsCombineText then
		if szPoint == 'TOP' and not bIsCombineText then
			local nSort, point = D.GetTrajectory(dat.dwTargetID, true)
			dat.nSort = nSort
			dat.szPoint = point
		end
		dat.nTime = GetTime()
		COMBAT_TEXT_SHADOW[shadow] = dat
	else
		COMBAT_TEXT_QUEUE[szPoint][dwTargetID] = COMBAT_TEXT_QUEUE[szPoint][dwTargetID] or {}
		table.insert(COMBAT_TEXT_QUEUE[szPoint][dwTargetID], { shadow = shadow, dat = dat })
	end
end

function D.CreateText(shadow, dwTargetID, szText, szPoint, eType, bCriticalStrike, bIsCombineText)
	return D.CreateColorText(shadow, dwTargetID, szText, szPoint, eType, bCriticalStrike, nil, bIsCombineText)
end

local SKILL_RESULT_TYPE_TO_COMBAT_TEXT_TYPE = X.KvpToObject({
	{SKILL_RESULT_TYPE.THERAPY             , COMBAT_TEXT_TYPE.THERAPY             },
	{SKILL_RESULT_TYPE.EFFECTIVE_THERAPY   , COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY   },
	{SKILL_RESULT_TYPE.STEAL_LIFE          , COMBAT_TEXT_TYPE.STEAL_LIFE          },
	{SKILL_RESULT_TYPE.PHYSICS_DAMAGE      , COMBAT_TEXT_TYPE.PHYSICS_DAMAGE      },
	{SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE  , COMBAT_TEXT_TYPE.SOLAR_MAGIC_DAMAGE  },
	{SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE, COMBAT_TEXT_TYPE.NEUTRAL_MAGIC_DAMAGE},
	{SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE  , COMBAT_TEXT_TYPE.LUNAR_MAGIC_DAMAGE  },
	{SKILL_RESULT_TYPE.POISON_DAMAGE       , COMBAT_TEXT_TYPE.POISON_DAMAGE       },
	{SKILL_RESULT_TYPE.REFLECTIED_DAMAGE   , COMBAT_TEXT_TYPE.REFLECTED_DAMAGE    },
	{SKILL_RESULT_TYPE.SPIRIT              , COMBAT_TEXT_TYPE.SPIRIT              },
	{SKILL_RESULT_TYPE.STAYING_POWER       , COMBAT_TEXT_TYPE.STAYING_POWER       },
	{SKILL_RESULT_TYPE.SHIELD_DAMAGE       , COMBAT_TEXT_TYPE.SHIELD_DAMAGE       },
	{SKILL_RESULT_TYPE.ABSORB_DAMAGE       , COMBAT_TEXT_TYPE.ABSORB_DAMAGE       },
	{SKILL_RESULT_TYPE.PARRY_DAMAGE        , COMBAT_TEXT_TYPE.PARRY_DAMAGE        },
	{SKILL_RESULT_TYPE.INSIGHT_DAMAGE      , COMBAT_TEXT_TYPE.INSIGHT_DAMAGE      },
})

function D.OnSkillText(dwCasterID, dwTargetID, bCriticalStrike, nSkillResultType, nValue, dwSkillID, dwSkillLevel, nEffectType)
	local eType = SKILL_RESULT_TYPE_TO_COMBAT_TEXT_TYPE[nSkillResultType]
	if not eType then
		return
	end
	-- �ض����͵���ʽ����
	if (dwCasterID == COMBAT_TEXT_PLAYERID or nSkillResultType == SKILL_RESULT_TYPE.STEAL_LIFE)
	and COMBAT_TEXT_SKILL_TYPE_IGNORE[nSkillResultType] then
		return
	end
	-- �ض�����ʽ����
	if dwCasterID == COMBAT_TEXT_PLAYERID and COMBAT_TEXT_SKILL_IGNORE[dwSkillID] then
		return
	end
	-- ��Ч���ƹ���
	if (eType == COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY and not O.bTherapyEffectiveOnly)
	or (eType == COMBAT_TEXT_TYPE.THERAPY and O.bTherapyEffectiveOnly) then
		return
	end
	-- ������Ч����
	if COMBAT_TEXT_TYPE_CLASS[eType] == 'THERAPY' and nValue == 0 then
		return
	end
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and (COMBAT_TEXT_TYPE_CLASS[eType] == 'THERAPY' or dwTargetID == COMBAT_TEXT_PLAYERID) and O.bOptimizeRoguelike then
		return
	end
	local bIsPlayer = X.IsPlayer(dwCasterID)
	local KCaster = bIsPlayer and X.GetPlayer(dwCasterID) or X.GetNpc(dwCasterID)
	local KEmployer, dwEmployerID
	if not bIsPlayer and KCaster then
		dwEmployerID = KCaster.dwEmployer
		if dwEmployerID ~= 0 then -- NPCҪ�����Ȧ
			KEmployer = X.GetPlayer(dwEmployerID)
		end
	end
	-- ������������
	if (dwCasterID ~= COMBAT_TEXT_PLAYERID and dwTargetID ~= COMBAT_TEXT_PLAYERID and dwEmployerID ~= COMBAT_TEXT_PLAYERID)
	and not O.bOtherCharacter then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end

	local szSkillName, szText, szReplaceText, bStaticSign
	-- replace text / point / color
	local szPoint = 'TOP'
	-- skill type effect by class and presets
	if COMBAT_TEXT_SKILL_STATIC_STRING[nSkillResultType] then -- ��Ҫ����ض��ַ������˺�����
		szText = COMBAT_TEXT_SKILL_STATIC_STRING[nSkillResultType]
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'LEFT'
		end
	elseif COMBAT_TEXT_TYPE_CLASS[eType] == 'THERAPY' then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		szReplaceText = O.szTherapy
	elseif dwTargetID == COMBAT_TEXT_PLAYERID then
		szPoint = 'BOTTOM_LEFT'
		szReplaceText = O.szDamage
	else
		szReplaceText = O.szSkill
	end
	-- specific skill type overwrite
	if eType == COMBAT_TEXT_TYPE.STEAL_LIFE then -- ��Ѫ����͵ȡ�����ظ���ȡ �˷�����
		szSkillName = g_tStrings.SKILL_STEAL_LIFE
	elseif eType == COMBAT_TEXT_TYPE.SPIRIT then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		szReplaceText = O.szSkill
		szSkillName = g_tStrings.SKILL_SPIRIT
		bStaticSign = true
	elseif eType == COMBAT_TEXT_TYPE.STAYING_POWER then
		if dwTargetID == COMBAT_TEXT_PLAYERID then
			szPoint = 'BOTTOM_RIGHT'
		end
		szReplaceText = O.szSkill
		szSkillName = g_tStrings.SKILL_STAYING_POWER
		bStaticSign = true
	end
	-- skill name fallback
	if not szSkillName then
		szSkillName = nEffectType == SKILL_EFFECT_TYPE.BUFF
			and Table_GetBuffName(dwSkillID, dwSkillLevel)
			or Table_GetSkillName(dwSkillID, dwSkillLevel)
	end
	if szPoint == 'BOTTOM_LEFT' then -- ���½ǿ϶����˺�
		-- ���Ʒ�������������ɫ
		if KCaster and KCaster.dwID ~= COMBAT_TEXT_PLAYERID and  KCaster.dwForceID == 21 and nEffectType ~= SKILL_EFFECT_TYPE.BUFF then
			local hSkill = GetSkill(dwSkillID, dwSkillLevel)
			if hSkill and hSkill.dwBelongSchool ~= 18 and hSkill.dwBelongSchool ~= 0 then
				eType = COMBAT_TEXT_TYPE.REFLECTED_DAMAGE
			end
		end
		if eType ~= COMBAT_TEXT_TYPE.REFLECTED_DAMAGE then
			eType = COMBAT_TEXT_TYPE.DAMAGE
		end
	end
	-- draw text
	if not szText then -- ��δ�������
		local szCasterName = ''
		if KCaster then
			if KEmployer then
				szCasterName = KEmployer.szName
			else
				szCasterName = KCaster.szName
			end
		end
		if O.bCasterNotI and (COMBAT_TEXT_PLAYERID == dwCasterID or COMBAT_TEXT_PLAYERID == dwEmployerID) then
			szCasterName = ''
		end
		if O.bSnShorten2 then
			szSkillName = X.StringSubW(szSkillName, 1, 2) -- wstring�Ǽ���̨���� ̨��utf-8
		end
		szText = szReplaceText
		szText = szText:gsub('(%s?)$crit(%s?)', (bCriticalStrike and '%1'.. g_tStrings.STR_CS_NAME .. '%2' or ''))
		szText = szText:gsub('$name', szCasterName)
		szText = szText:gsub('$sn', szSkillName)
		szText = szText:gsub('$val', (bStaticSign and X.IsNumber(nValue) and nValue > 0 and '+' or '') .. (nValue or ''))
	end
	if O.bEnableCombineText then
		local key = dwTargetID .. '_' .. szPoint
		if not COMBAT_TEXT_COMBINE[key] then
			COMBAT_TEXT_COMBINE[key] = {
				dwTargetID = dwTargetID,
				szPoint = szPoint,
				nValue = 0,
				nCount = 0,
				aList = {}
			}
		end
		COMBAT_TEXT_COMBINE[key].nValue = COMBAT_TEXT_COMBINE[key].nValue + (X.IsNumber(nValue) and nValue or 0)
		COMBAT_TEXT_COMBINE[key].nCount = COMBAT_TEXT_COMBINE[key].nCount + 1
		table.insert(COMBAT_TEXT_COMBINE[key].aList, szText)
	end
	D.CreateText(shadow, dwTargetID, szText, szPoint, eType, bCriticalStrike)
end

function D.OnSkillBuff(dwCharacterID, bCanCancel, dwID, nLevel)
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and O.bOptimizeRoguelike then
		return
	end
	if not Table_BuffIsVisible(dwID, nLevel) then
		return
	end
	local szBuffName = Table_GetBuffName(dwID, nLevel)
	if szBuffName == '' then
		return
	end
	local tCache = bCanCancel and COMBAT_TEXT_CACHE.BUFF or COMBAT_TEXT_CACHE.DEBUFF
	if tCache[szBuffName] then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	tCache[szBuffName] = true
	D.CreateText(shadow, dwCharacterID, szBuffName, 'RIGHT', bCanCancel and COMBAT_TEXT_TYPE.SKILL_BUFF or COMBAT_TEXT_TYPE.SKILL_DEBUFF, false)
end

function D.OnSkillMiss(dwTargetID)
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and O.bOptimizeRoguelike then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	local szPoint = dwTargetID == COMBAT_TEXT_PLAYERID and 'LEFT' or 'TOP'
	D.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_MISS, szPoint, COMBAT_TEXT_TYPE.SKILL_MISS, false)
end

function D.OnBuffImmunity(dwTargetID)
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and O.bOptimizeRoguelike then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	D.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_IMMUNITY, 'LEFT', COMBAT_TEXT_TYPE.BUFF_IMMUNITY, false)
end

-- FireUIEvent('COMMON_HEALTH_TEXT', X.GetClientPlayer().dwID, -8888)
function D.OnCommonHealth(dwCharacterID, nDeltaLife)
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and O.bOptimizeRoguelike then
		return
	end
	if nDeltaLife < 0 and not IsCombatTextPlayerID(dwCharacterID) then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	local szPoint = 'BOTTOM_LEFT'
	if nDeltaLife > 0 then
		if dwCharacterID ~= COMBAT_TEXT_PLAYERID then
			szPoint = 'TOP'
		else
			szPoint = 'BOTTOM_RIGHT'
		end
	end
	local szText = nDeltaLife > 0 and '+' .. nDeltaLife or nDeltaLife
	local eType  = nDeltaLife > 0 and COMBAT_TEXT_TYPE.THERAPY or COMBAT_TEXT_TYPE.DAMAGE
	D.CreateText(shadow, dwCharacterID, szText, szPoint, eType, false)
end

function D.OnSkillDodge(dwTargetID)
	-- �˻ĺ���Ż�����������Լ����˺��������ܵ����˺�������
	if COMBAT_TEXT_IN_ROGUELIKE_MAP and O.bOptimizeRoguelike then
		return
	end
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	D.CreateText(shadow, dwTargetID, g_tStrings.STR_MSG_DODGE, 'LEFT', COMBAT_TEXT_TYPE.SKILL_DODGE, false)
end

function D.OnExpLog(dwCharacterID, nExp)
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	D.CreateText(shadow, dwCharacterID, g_tStrings.STR_COMBATMSG_EXP .. nExp, 'CENTER', COMBAT_TEXT_TYPE.EXP, true)
end

function D.CreateMessage(szText, tOptions)
	local shadow = D.GetFreeShadow()
	if not shadow then -- û�п��е�shadow
		return
	end
	local dwTargetID = tOptions.dwTargetID or COMBAT_TEXT_PLAYERID
	local szPosition = tOptions.szPosition or 'CENTER'
	local bCritical = tOptions.bCritical or false
	local eType = bCritical and COMBAT_TEXT_TYPE.CRITICAL_MSG or COMBAT_TEXT_TYPE.MSG
	local tColor = tOptions.tColor
	D.CreateColorText(shadow, dwTargetID, szText, szPosition, eType, bCritical, tColor)
end

-- ��ȡ���Ƿ��Ǻϲ����˺�
function D.GetFreeShadow(bIsCombineText)
	if not bIsCombineText then
		for k, v in ipairs(COMBAT_TEXT_FREE) do
			if v.free then
				v.free = false
				return v
			end
		end
	end

	if bIsCombineText or (O.nMaxCount > 0 and #COMBAT_TEXT_FREE < O.nMaxCount) then
		local handle = D.handle
		local sha = handle:AppendItemFromIni(COMBAT_TEXT_INIFILE, bIsCombineText and 'Shadow_Content' or 'Shadow_Content_2')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		table.insert(COMBAT_TEXT_FREE, sha)
		return sha
	end
end

function D.LoadConfig()
	local bExist = IsFileExist(COMBAT_TEXT_CONFIG)
	if bExist then
		local data = LoadLUAData(COMBAT_TEXT_CONFIG)
		if data then
			COMBAT_TEXT_CRITICAL          = data.COMBAT_TEXT_CRITICAL            or COMBAT_TEXT_CRITICAL
			COMBAT_TEXT_SCALE             = data.COMBAT_TEXT_SCALE               or COMBAT_TEXT_SCALE
			COMBAT_TEXT_POINT             = data.COMBAT_TEXT_POINT               or COMBAT_TEXT_POINT
			COMBAT_TEXT_EVENT             = data.COMBAT_TEXT_EVENT               or COMBAT_TEXT_EVENT
			COMBAT_TEXT_SKILL_IGNORE      = data.COMBAT_TEXT_SKILL_IGNORE        or {}
			COMBAT_TEXT_SKILL_TYPE_IGNORE = data.COMBAT_TEXT_SKILL_TYPE_IGNORE   or {}
			COMBAT_TEXT_COLOR             = data.COMBAT_TEXT_COLOR               or COMBAT_TEXT_COLOR
			COMBAT_TEXT_CRITICAL_COLOR    = data.COMBAT_TEXT_CRITICAL_COLOR      or COMBAT_TEXT_CRITICAL_COLOR
			X.OutputSystemMessage(_L['Combat text config loaded.'])
		else
			X.OutputSystemMessage(_L['Combat text config failed.'])
		end
	end
end

function D.CheckEnable()
	local ui = Station.Lookup('Lowest/MY_CombatText')
	if IsEnabled() then
		if O.bRender then
			COMBAT_TEXT_INIFILE = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText_Render.ini'
		else
			COMBAT_TEXT_INIFILE = X.PACKET_INFO.ROOT .. 'MY_CombatText/ui/MY_CombatText.ini'
		end
		COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[O.nStyle] and COMBAT_TEXT_STYLES[O.nStyle] or COMBAT_TEXT_STYLES[0]
		D.LoadConfig()
		if ui then
			X.UI.CloseFrame(ui)
		end
		X.UI.OpenFrame(COMBAT_TEXT_INIFILE, 'MY_CombatText')
		D.HideOfficialCombat()
	else
		if ui then
			D.FreeQueue()
			X.UI.CloseFrame(ui)
			X.BreatheCall('COMBAT_TEXT_CACHE', false)
			X.BreatheCall('COMBAT_TEXT_COMBINE', false)
			collectgarbage('collect')
		end
		D.ShowOfficialCombat()
	end
	setmetatable(COMBAT_TEXT_POINT, { __index = function(me, key)
		if key == 'TOP_LEFT' or key == 'TOP_RIGHT' then
			return me['TOP']
		end
	end })
	local mt = { __index = function(me)
		return me[#me]
	end }
	setmetatable(COMBAT_TEXT_SCALE.CRITICAL, mt)
	setmetatable(COMBAT_TEXT_SCALE.NORMAL,   mt)
end


--------------------------------------------------------------------------------
-- ȫ�ֵ���
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_CombatText',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'CreateMessage',
			},
			root = D,
		},
	},
}
MY_CombatText = X.CreateModule(settings)
end


local PS = {}
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nW, nH = ui:Size()
	local nPaddingX, nPaddingY = 20, 10
	local nX, nY = nPaddingX, nPaddingY
	local nDeltaY = 28
	local nChapterPaddingTop = 5
	local nChapterPaddingBottom = 3

	ui:Append('Text', { x = nX, y = nY, text = _L['Combat text'], font = 27 })
	nX = nX + 10
	nY = nY + nDeltaY + nChapterPaddingBottom

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Enable combat text'],
		color = { 255, 128, 0 },
		checked = O.bEnable,
		onCheck = function(bCheck)
			O.bEnable = bCheck
			D.CheckEnable()
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Enable render'],
		checked = O.bRender,
		onCheck = function(bCheck)
			O.bRender = bCheck
			D.CheckEnable()
		end,
		autoEnable = IsEnabled,
	}):Width() + 5
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Only show my related combat text'],
		checked = not O.bOtherCharacter,
		onCheck = function(bCheck)
			O.bOtherCharacter = not bCheck
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Disable immunity'],
		checked = O.bImmunity,
		onCheck = function(bCheck)
			O.bImmunity = bCheck
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Optimize in roguelike'],
		checked = O.bOptimizeRoguelike,
		onCheck = function(bCheck)
			O.bOptimizeRoguelike = bCheck
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	-- ��ʾ�ϲ��ı�
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Show combine text'],
		checked = O.bEnableCombineText,
		tip = {
			render = _L['Combine the same time combat text'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		onCheck = function(bCheck)
			O.bEnableCombineText = bCheck
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = g_tStrings.STR_QUESTTRACE_CHANGE_ALPHA, color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, text = '',
		range = {1, 255},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nMaxAlpha,
		onChange = function(nVal)
			O.nMaxAlpha = nVal
		end,
		autoEnable = IsEnabled,
	})

	nX = nX + 180
	ui:Append('Text', { x = nX, y = nY, text = _L['Hold time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, textFormatter = function(val) return val .. _L['ms'] end,
		range = {700, 2500},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nTime * COMBAT_TEXT_TOTAL,
		onChange = function(nVal)
			O.nTime = nVal / COMBAT_TEXT_TOTAL
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Fade in time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, textFormatter = function(val) return val .. _L['frame'] end,
		range = {0, 15},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nFadeIn,
		onChange = function(nVal)
			O.nFadeIn = nVal
		end,
		autoEnable = IsEnabled,
	})

	nX = nX + 180
	ui:Append('Text', { x = nX, y = nY, text = _L['Fade out time'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, textFormatter = function(val) return val .. _L['frame'] end,
		rang = {0, 15},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nFadeOut,
		onChange = function(nVal)
			O.nFadeOut = nVal
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Font size'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, textFormatter = function(val) return (val / 100) .. _L['times'] end,
		range = {50, 200},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.fScale * 100,
		onChange = function(nVal)
			O.fScale = nVal / 100
			D.UpdateTrajectoryCount()
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 180

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Max count'],
		tip = {
			render = _L['Max same time combat text count limit'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		color = { 255, 255, 200 },
		autoEnable = IsEnabled,
	})
	nX = nX + 70
	ui:Append('WndSlider', {
		x = nX, y = nY, text = '',
		textFormatter = function(val)
			return val == 0
				and _L['Limitless']
				or _L('Limit to %d', val)
		end,
		range = {0, 500},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = O.nMaxCount,
		onChange = function(nVal)
			O.nMaxCount = nVal
		end,
		autoEnable = IsEnabled,
	})
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Critical style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 70

	nX = nX + ui:Append('WndRadioBox', {
		x = nX, y = nY, text = _L['Hit feel'],
		group = 'style',
		checked = O.nStyle == 0,
		onCheck = function()
			O.nStyle = 0
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[0]
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	nX = nX + ui:Append('WndRadioBox', {
		x = nX, y = nY, text = _L['Low hit feel'],
		group = 'style',
		checked = O.nStyle == 1,
		onCheck = function()
			O.nStyle = 1
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[1]
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	nX = nX + ui:Append('WndRadioBox', {
		x = nX, y = nY, text = _L['Soft'],
		group = 'style',
		checked = O.nStyle == 2,
		onCheck = function()
			O.nStyle = 2
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[2]
		end,
		autoEnable = IsEnabled,
	}):Width() + 5

	ui:Append('WndRadioBox', {
		x = nX, y = nY, text = _L['Scale only'],
		group = 'style',
		checked = O.nStyle == 3,
		onCheck = function()
			O.nStyle = 3
			COMBAT_TEXT_SCALE.CRITICAL = COMBAT_TEXT_STYLES[3]
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 90
	nY = nY + nDeltaY

	nX = nPaddingX
	nY = nY + nChapterPaddingTop
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Text style'], font = 27, autoEnable = IsEnabled }):Width() + 5
	nX = nX + ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Tips: $name means caster\'s name, $sn means skill name, $crit means critical, $val means value.'],
		color = { 196, 196, 196 },
		autoEnable = IsEnabled,
	}):Width() + 5
	nY = nY + nDeltaY + nChapterPaddingBottom

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Skill style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 110
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = 250, h = 25, text = O.szSkill, limit = 30,
		onChange = function(szText)
			O.szSkill = szText
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 250
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Damage style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 110
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = 250, h = 25, text = O.szDamage, limit = 30,
		onChange = function(szText)
			O.szDamage = szText
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 250
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['Therapy style'], color = { 255, 255, 200 }, autoEnable = IsEnabled })
	nX = nX + 110
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = 250, h = 25, text = O.szTherapy, limit = 30,
		onChange = function(szText)
			O.szTherapy = szText
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 250
	nY = nY + nDeltaY

	nX = nPaddingX + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 190, text = _L['$name not me'], checked = O.bCasterNotI,
		onCheck = function(bCheck)
			O.bCasterNotI = bCheck
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 190

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 110, text = _L['$sn shorten(2)'], checked = O.bSnShorten2,
		onCheck = function(bCheck)
			O.bSnShorten2 = bCheck
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 110

	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 140, text = _L['Therapy effective only'], checked = O.bTherapyEffectiveOnly,
		onCheck = function(bCheck)
			O.bTherapyEffectiveOnly = bCheck
		end,
		autoEnable = IsEnabled,
	})
	nX = nX + 140

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, h = 24,
		text = _L['Font edit'],
		buttonStyle = 'FLAT',
		onClick = function()
			X.UI.OpenFontPicker(function(nFont)
				O.nFont = nFont
			end)
		end,
		tip = {
			render = function() return _L('Current font: %d', O.nFont) end,
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		autoEnable = IsEnabled,
	}):Width() + 10
	nY = nY + nDeltaY

	nX = nPaddingX
	nY = nY + nChapterPaddingTop
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Color edit'], font = 27, autoEnable = IsEnabled }):Width() + 10
	nX = nX + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY + 2, w = 'auto',
		text = _L['Distinct critical color'],
		checked = O.bCritical,
		onCheck = function(bCheck)
			O.bCritical = bCheck
			X.ShowPanel()
			X.FocusPanel()
			X.SwitchTab('MY_CombatText', true)
		end,
		autoEnable = IsEnabled,
	}):Width() + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2, w = 'auto', h = 24,
		text = _L['Reset color'],
		buttonStyle = 'FLAT',
		onClick = function()
			O('reset', { 'tColor', 'tCriticalColor' })
			X.ShowPanel()
			X.FocusPanel()
			X.SwitchTab('MY_CombatText', true)
		end,
		autoEnable = IsEnabled,
	}):Width() + 10
	nY = nY + nDeltaY + nChapterPaddingBottom

	nX = nPaddingX + 20
	for _, eType in ipairs({
		COMBAT_TEXT_TYPE.DAMAGE               ,
		COMBAT_TEXT_TYPE.THERAPY              ,
		COMBAT_TEXT_TYPE.EFFECTIVE_THERAPY    ,
		COMBAT_TEXT_TYPE.STEAL_LIFE           ,
		COMBAT_TEXT_TYPE.PHYSICS_DAMAGE       ,
		COMBAT_TEXT_TYPE.SOLAR_MAGIC_DAMAGE   ,
		COMBAT_TEXT_TYPE.NEUTRAL_MAGIC_DAMAGE ,
		COMBAT_TEXT_TYPE.LUNAR_MAGIC_DAMAGE   ,
		COMBAT_TEXT_TYPE.POISON_DAMAGE        ,
		COMBAT_TEXT_TYPE.REFLECTED_DAMAGE     ,
	}) do
		if nX > nW - 100 then
			nX = nPaddingX + 20
			nY = nY + 25
		end
		local uiCritical
		ui:Append('Shadow', {
			x = nX, y = nY + 8, color = D.GetColor(eType, false), w = 15, h = 15,
			onClick = function()
				local this = this
				X.UI.OpenColorPicker(function(r, g, b)
					O.tColor[eType] = { r, g, b }
					O.tColor = O.tColor
					if uiCritical then
						uiCritical:Color(D.GetColor(eType, true))
					end
					X.UI(this):Color(r, g, b)
				end)
			end,
			autoEnable = IsEnabled,
		})
		nX = nX + 20
		if O.bCritical then
			uiCritical = ui:Append('Shadow', {
				x = nX, y = nY + 8, color = D.GetColor(eType, true), w = 15, h = 15,
				tip = {
					render = _L['Critical color'],
					position = X.UI.TIP_POSITION.BOTTOM_TOP,
				},
				onClick = function()
					local this = this
					X.UI.OpenColorPicker(function(r, g, b)
						O.tCriticalColor[eType] = { r, g, b }
						O.tCriticalColor = O.tCriticalColor
						X.UI(this):Color(r, g, b)
					end)
				end,
				autoEnable = IsEnabled,
			})
			nX = nX + 20
		end
		nX = nX + math.max(ui:Append('Text', {
			x = nX, y = nY, w = 'auto',
			text = COMBAT_TEXT_TYPE_NAME[eType],
			autoEnable = IsEnabled,
		}):Width() + 10, 100)
	end
	nY = nY + 30

	nX = nPaddingX + 20
	for _, eType in ipairs({
		COMBAT_TEXT_TYPE.SPIRIT               ,
		COMBAT_TEXT_TYPE.STAYING_POWER        ,
		COMBAT_TEXT_TYPE.SHIELD_DAMAGE        ,
		COMBAT_TEXT_TYPE.ABSORB_DAMAGE        ,
		COMBAT_TEXT_TYPE.PARRY_DAMAGE         ,
		COMBAT_TEXT_TYPE.INSIGHT_DAMAGE       ,
		COMBAT_TEXT_TYPE.SKILL_DODGE          ,
		COMBAT_TEXT_TYPE.SKILL_BUFF           ,
		COMBAT_TEXT_TYPE.SKILL_DEBUFF         ,
		COMBAT_TEXT_TYPE.BUFF_IMMUNITY        ,
		COMBAT_TEXT_TYPE.SKILL_MISS           ,
		COMBAT_TEXT_TYPE.EXP                  ,
		COMBAT_TEXT_TYPE.MSG                  ,
		COMBAT_TEXT_TYPE.CRITICAL_MSG         ,
	}) do
		if nX > nW - 100 then
			nX = nPaddingX + 20
			nY = nY + 25
		end
		ui:Append('Shadow', {
			x = nX, y = nY + 8, color = D.GetColor(eType, false), w = 15, h = 15,
			onClick = function()
				local this = this
				X.UI.OpenColorPicker(function(r, g, b)
					O.tColor[eType] = { r, g, b }
					O.tColor = O.tColor
					X.UI(this):Color(r, g, b)
				end)
			end,
			autoEnable = IsEnabled,
		})
		nX = nX + 20
		nX = nX + math.max(ui:Append('Text', {
			x = nX, y = nY, w = 'auto',
			text = COMBAT_TEXT_TYPE_NAME[eType],
			autoEnable = IsEnabled,
		}):Width() + 10, 100)
	end
	nY = nY + 30

	ui:Append('WndWindow', { x = nX, y = nY + 10, w = nW, h = 0 }) -- �����Ĺ��������⣬����ʹ��һ�� Wnd ���ܴ�����������

	if IsFileExist(COMBAT_TEXT_CONFIG) then
		ui:Append('WndButton', {
			x = nW - 130 - nPaddingX, y = 15, h = 40,
			text = _L['Reload combat text config'],
			buttonStyle = 'SKEUOMORPHISM_LACE_BORDER',
			onClick = D.CheckEnable,
		})
	end
end
X.RegisterPanel(_L['System'], 'MY_CombatText', _L['MY_CombatText'], 2041, PS)

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

local function OnLoadingEnding()
	local me = X.GetControlPlayer()
	if not me then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('CombatText get player id failed!!! try again', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		X.DelayCall(1000, OnLoadingEnding)
		return
	end
	COMBAT_TEXT_PLAYERID = me.dwID
	--[[#DEBUG BEGIN]]
	-- X.OutputDebugMessage('CombatText get player id ' .. me.dwID, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	COMBAT_TEXT_IN_ROGUELIKE_MAP = X.IsInRoguelikeMap()
end
X.RegisterUserSettingsInit('MY_CombatText', function()
	D.bReady = true
	D.UpdateTrajectoryCount()
	D.CheckEnable()
end)
X.RegisterEvent('LOADING_ENDING', 'MY_CombatText', OnLoadingEnding) -- ����Ҫ���Ż�
X.RegisterEvent('ON_NEW_PROXY_SKILL_LIST_NOTIFY', 'MY_CombatText', OnLoadingEnding) -- �����������ID�л�
X.RegisterEvent('ON_CLEAR_PROXY_SKILL_LIST_NOTIFY', 'MY_CombatText', OnLoadingEnding) -- �����������ID�л�
X.RegisterEvent('ON_PVP_SHOW_SELECT_PLAYER', 'MY_CombatText', function()
	COMBAT_TEXT_PLAYERID = arg0
end)
X.RegisterEvent('FIRST_LOADING_END', 'MY_CombatText', D.CheckEnable)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
