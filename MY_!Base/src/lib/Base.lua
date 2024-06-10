--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��������ռ��ʼ��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------

-- ��Ϸ���ԡ���Ϸ��Ӫ��֧���롢��Ϸ���а���롢��Ϸ�汾�š���Ϸ���з�ʽ
local szVersion, szVersionLineName, szVersionEx = select(2, GetVersion())
-- ��Ϸ����
local _GAME_LANG_ = string.lower(szVersionLineName)
if _GAME_LANG_ == 'classic' then
	_GAME_LANG_ = 'zhcn'
end
-- ��Ϸ��Ӫ��֧����
local _GAME_BRANCH_ = string.lower(szVersionLineName)
if _GAME_BRANCH_ == 'zhcn' then
	_GAME_BRANCH_ = 'remake'
elseif _GAME_BRANCH_ == 'zhtw' then
	_GAME_BRANCH_ = 'intl'
end
-- ��Ϸ���а����
local _GAME_EDITION_ = string.lower(szVersionLineName .. '_' .. szVersionEx)
-- ��Ϸ�汾��
local _GAME_VERSION_ = string.lower(szVersion)
-- ��Ϸ���з�ʽ�����ء��ƶ�
local _GAME_PROVIDER_ = 'local'
if SM_IsEnable then
	local status, res = pcall(SM_IsEnable)
	if status and res then
		_GAME_PROVIDER_ = 'remote'
	end
end

local DEBUG_LEVEL = {
	PM_LOG  = 0,
	LOG     = 1,
	WARNING = 2,
	ERROR   = 3,
	DEBUG   = 3,
	NONE    = 4,
}

local CODE_PAGE = {
	UTF8 = 65001,
	GBK = 936,
}

local _NAME_SPACE_            = 'MY'
local _BUILD_                 = '20240610'
local _VERSION_               = '22.0.3'
local _MENU_COLOR_            = {255, 165, 79}
local _INTERFACE_ROOT_        = 'Interface/'
local _ADDON_ROOT_            = _INTERFACE_ROOT_ .. _NAME_SPACE_ .. '/'
local _DATA_ROOT_             = (_GAME_PROVIDER_ == 'remote' and (GetUserDataFolder() .. '/' .. GetUserAccount() .. '/interface/') or _INTERFACE_ROOT_) .. _NAME_SPACE_ .. '#DATA/'
local _FRAMEWORK_ROOT_        = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_!Base/'
local _UI_COMPONENT_ROOT_     = _FRAMEWORK_ROOT_ .. 'ui/components/'
local _LOGO_UITEX_            = _FRAMEWORK_ROOT_ .. 'img/Logo.UITex'
local _LOGO_MAIN_FRAME_       = 0
local _LOGO_MENU_FRAME_       = 1
local _LOGO_MENU_HOVER_FRAME_ = 2
local _POSTER_UITEX_          = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_Resource/img/Poster.UITex'
local _POSTER_FRAME_COUNT_    = 2
local _DEBUG_LEVEL_           = DEBUG_LEVEL[LoadLUAData(_DATA_ROOT_ .. 'debug.level.jx3dat') or 'NONE'] or DEBUG_LEVEL.NONE
local _LOG_LEVEL_             = math.min(DEBUG_LEVEL[LoadLUAData(_DATA_ROOT_ .. 'log.level.jx3dat') or 'ERROR'] or DEBUG_LEVEL.ERROR, _DEBUG_LEVEL_)

-- ���������ռ�
local X = {
	UI = {},
	DEBUG_LEVEL = DEBUG_LEVEL,
	CODE_PAGE = CODE_PAGE,
	PATH_TYPE = {
		NORMAL = 0,
		DATA   = 1,
		ROLE   = 2,
		GLOBAL = 3,
		SERVER = 4,
	},
	PACKET_INFO = {
		NAME_SPACE            = _NAME_SPACE_           ,
		VERSION               = _VERSION_              ,
		BUILD                 = _BUILD_                ,
		MENU_COLOR            = _MENU_COLOR_           ,
		INTERFACE_ROOT        = _INTERFACE_ROOT_       ,
		ROOT                  = _ADDON_ROOT_           ,
		DATA_ROOT             = _DATA_ROOT_            ,
		FRAMEWORK_ROOT        = _FRAMEWORK_ROOT_       ,
		UI_COMPONENT_ROOT     = _UI_COMPONENT_ROOT_    ,
		LOGO_UITEX            = _LOGO_UITEX_           ,
		LOGO_MAIN_FRAME       = _LOGO_MAIN_FRAME_      ,
		LOGO_MENU_FRAME       = _LOGO_MENU_FRAME_      ,
		LOGO_MENU_HOVER_FRAME = _LOGO_MENU_HOVER_FRAME_,
		POSTER_UITEX          = _POSTER_UITEX_         ,
		POSTER_FRAME_COUNT    = _POSTER_FRAME_COUNT_   ,
		DEBUG_LEVEL           = _DEBUG_LEVEL_          ,
		LOG_LEVEL             = _LOG_LEVEL_            ,
	},
	ENVIRONMENT = setmetatable({}, {
		__index = setmetatable({
			GAME_LANG = _GAME_LANG_,
			GAME_BRANCH = _GAME_BRANCH_,
			GAME_EDITION = _GAME_EDITION_,
			GAME_VERSION = _GAME_VERSION_,
			GAME_PROVIDER = _GAME_PROVIDER_,
			SERVER_ADDRESS = select(7, GetUserServer()),
			SOUND_DRIVER = IsFileExist('bin64\\KG3DWwiseSoundX64.dll')
				and 'WWISE'
				or 'FMOD',
			CODE_PAGE = _GAME_BRANCH_ == 'intl'
				and CODE_PAGE.UTF8
				or CODE_PAGE.GBK,
			RUNTIME_OPTIMIZE = --[[#DEBUG BEGIN]](
				(IsDebugClient() or debug.traceback ~= nil)
					and _DEBUG_LEVEL_ == DEBUG_LEVEL.NONE
					and _LOG_LEVEL_ == DEBUG_LEVEL.NONE
					and not IsLocalFileExist(_ADDON_ROOT_ .. 'secret.jx3dat')
				) and not IsLocalFileExist(_DATA_ROOT_ .. 'no.runtime.optimize.jx3dat')
					and true
					or --[[#DEBUG END]]false,
		}, { __index = GLOBAL }),
		__newindex = function() end,
	}),
	SECRET = setmetatable({}, {
		__index = LoadLUAData(_ADDON_ROOT_ .. 'secret.jx3dat') or {},
		__newindex = function() end,
	}),
	SHARED_MEMORY = PLUGIN_SHARED_MEMORY,
}

X.IS_REMAKE = X.ENVIRONMENT.GAME_BRANCH == 'remake'
X.IS_CLASSIC = X.ENVIRONMENT.GAME_BRANCH == 'classic'
X.IS_LOCAL = X.ENVIRONMENT.GAME_PROVIDER == 'local'
X.IS_REMOTE = X.ENVIRONMENT.GAME_PROVIDER == 'remote'
X.IS_WWISE = X.ENVIRONMENT.SOUND_DRIVER == 'WWISE'
X.IS_FMOD = X.ENVIRONMENT.SOUND_DRIVER == 'FMOD'
X.IS_UTF8 = X.ENVIRONMENT.CODE_PAGE == CODE_PAGE.UTF8
X.IS_GBK = X.ENVIRONMENT.CODE_PAGE == CODE_PAGE.GBK
X.IS_RUNTIME_OPTIMIZE = X.ENVIRONMENT.RUNTIME_OPTIMIZE

-- �����ڴ�
if type(X.SHARED_MEMORY) ~= 'table' then
	X.SHARED_MEMORY = {}
	PLUGIN_SHARED_MEMORY = X.SHARED_MEMORY
end

local NS_FORMAT_STRING_CACHE = {}

-- ��ʽ�������ռ�ģ���ַ���
---@param s string @��Ҫ��ʽ�����ַ���
---@return string @��ʽ������ַ���
function X.NSFormatString(s)
	if not NS_FORMAT_STRING_CACHE[s] then
		NS_FORMAT_STRING_CACHE[s] = StringReplaceW(s, '{$NS}', _NAME_SPACE_)
	end
	return NS_FORMAT_STRING_CACHE[s]
end

-- ���������ռ�
---@param ns table @��Ҫ�����������ռ�
---@param szNSString string @��Ҫ�����������ռ���ַ���������
---@param mt table @����������ռ�Ԫ��
---@return table @�����ռ��������д�������
function X.NSLock(ns, szNSString, mt)
	local PROXY = {}
	for k, v in pairs(ns) do
		PROXY[k] = v
		ns[k] = nil
	end
	local t = {
		__metatable = true,
		__index = PROXY,
		__newindex = function() assert(false, 'DO NOT modify ' .. szNSString .. ' after initialized!!!') end,
		__tostring = function(t) return szNSString end,
	}
	if mt then
		for k, v in pairs(mt) do
			t[k] = v
		end
	end
	setmetatable(ns, t)
	return PROXY
end

-- �������԰�
---@param szLangFolder string @���԰��ļ���
---@return table<string, any> @���԰�
function X.LoadLangPack(szLangFolder)
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_ .. 'lang/default') or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_ .. 'lang/' .. _GAME_LANG_) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder) == 'string' then
		szLangFolder = string.gsub(szLangFolder,'[/\\]+$','')
		local t2 = LoadLUAData(szLangFolder..'/default') or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		local t3 = LoadLUAData(szLangFolder..'/' .. _GAME_LANG_) or {}
		for k, v in pairs(t3) do
			t0[k] = v
		end
	end
	setmetatable(t0, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t0
end

local _L = X.LoadLangPack(_FRAMEWORK_ROOT_ .. 'lang/lib/')

X.PACKET_INFO.NAME                  = _L.PLUGIN_NAME
X.PACKET_INFO.SHORT_NAME            = _L.PLUGIN_SHORT_NAME
X.PACKET_INFO.AUTHOR                = _L.PLUGIN_AUTHOR
X.PACKET_INFO.AUTHOR_FEEDBACK       = _L.PLUGIN_AUTHOR_FEEDBACK
X.PACKET_INFO.AUTHOR_FEEDBACK_URL   = _L.PLUGIN_AUTHOR_FEEDBACK_URL
X.PACKET_INFO.AUTHOR_SIGNATURE      = _L.PLUGIN_AUTHOR_SIGNATURE
X.PACKET_INFO.AUTHOR_HEADER         = GetFormatText(_L.PLUGIN_NAME .. ' ' .. _L['[Author]'], 8, 89, 224, 232)
X.PACKET_INFO.AUTHOR_FAKE_HEADER    = GetFormatText(_L['[Fake author]'], 8, 255, 95, 159)
X.PACKET_INFO.AUTHOR_ROLES          = {
	[ 3007396] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� �ν���
	[28564812] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ �ν���
	[ 1600498] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ׷����Ӱ
	[ 4664780] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ��������
	[17796954] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0x40, 0xB0, 0xD7, 0xB5, 0xDB, 0xB3, 0xC7), -- ����@�׵۳� �ν���
	[     601] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ���˸�Լ
	[    2202] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ ���˸�Լ
	[     690] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ɽ�����
	[    1848] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ ɽ�����
	[     417] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� �Ե���
	[     974] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ �Ե���
	[      43] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ���󳤰�
	[     125] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ ���󳤰�
	[    3848] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ü��ѩ
	[    6060] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ ü��ѩ
	[     350] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ������
	[     518] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- ������ ������
	[  385183] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A), -- ����1@�[�� ��Ѫ����
	[ 8568269] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A), -- ���� ��Ѫ����
	[ 1452025] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A), -- ������ �p������
	[    1028] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� Ե����@Ե��һ��
	[     660] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� �λس���@Ե��һ��
	[     280] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ��������@Ե��һ��
	[     143] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� ������@Ե��һ��
	[    1259] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- ���� �챦ʢ��@Ե��һ��
}
X.PACKET_INFO.AUTHOR_GLOBAL_IDS     = {
	['4647714815446365644'] = true, -- Ǭ��һ�� ����
	['4647714815446365650'] = true, -- Ǭ��һ�� ������
	['2900318160027211566'] = true, -- Ψ�Ҷ��� ����
	['342273571684493800' ] = true, -- Ψ�Ҷ��� ������
	['2990390152574185432'] = true, -- ���ƺ ����
	['252201579145213206' ] = true, -- ���ƺ ������
	['3945153273576625046'] = true, -- ������ ����
	['3945153273576625053'] = true, -- ������ ������
	['4431542033332598576'] = true, -- ��ת���� ����
	['270215977662693730' ] = true, -- ��ת���� ������
	['432345564230575012' ] = true, -- �ν��� ����
	['432345564256132428' ] = true, -- �ν��� ������
	['288230376168682411' ] = true, -- ������ ����
	['288230376154983398' ] = true, -- ������ ������
	['810647932948971397' ] = true, -- �����콾 ����
	['810647932954621200' ] = true, -- �����콾 ������
	['216172782136999278' ] = true, -- ������ ����
	['216172782126564848' ] = true, -- ������ ������
	['396316767212724712' ] = true, -- ������ ����
	['396316767221969620' ] = true, -- ������ ������
	['3963167672086075586'] = true, -- ��÷��� ����
	['3728980491462810295'] = true, -- ��÷��� ������
	['234187180631190792' ] = true, -- �������� ����
	['234187180639172085' ] = true, -- �������� ������
	['378302368729578857' ] = true, -- �������� ����
	['378302368704986888' ] = true, -- �������� ������
	['972777519522485610' ] = true, -- �������� ����
	['972777519512290625' ] = true, -- �������� ������
}
X.PACKET_INFO.AUTHOR_PROTECT_NAMES  = {
	[string.char(0xDC, 0xF8, 0xD2, 0xC1)] = true, -- ����
	[string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1)] = true, -- ����
	[string.char(0XE8, 0X8C, 0X97, 0XE4, 0XBC, 0X8A)] = true, -- ����
	[string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A)] = true, -- ����
}

-- ���������ռ�
MY = X
