--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ·����ز���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Storage.Path')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

if IsLocalFileExist(X.PACKET_INFO.ROOT .. '@DATA/') then
	CPath.Move(X.PACKET_INFO.ROOT .. '@DATA/', X.PACKET_INFO.DATA_ROOT)
end

-- ��ʽ�������ļ�·�����滻{$uid}��{$lang}��{$server}�Լ���ȫ���·����
-- (string) X.GetLUADataPath(oFilePath)
--   ��·��Ϊ����·��ʱ(��б�ܿ�ͷ)��������
--   ��·��Ϊ���·��ʱ ����ڲ��`{NS}#DATA`Ŀ¼
--   ���Դ����{szPath, ePathType}
local PATH_TYPE_MOVE_STATE = {
	[X.PATH_TYPE.GLOBAL] = 'PENDING',
	[X.PATH_TYPE.ROLE] = 'PENDING',
	[X.PATH_TYPE.SERVER] = 'PENDING',
}
function X.FormatPath(oFilePath, tParams)
	if not tParams then
		tParams = {}
	end
	local szFilePath, ePathType
	if type(oFilePath) == 'table' then
		szFilePath, ePathType = X.Unpack(oFilePath)
	else
		szFilePath, ePathType = oFilePath, X.PATH_TYPE.NORMAL
	end
	-- ���ݾɰ�����λ��
	if PATH_TYPE_MOVE_STATE[ePathType] == 'PENDING' then
		PATH_TYPE_MOVE_STATE[ePathType] = nil
		local szPath = X.FormatPath({'', ePathType})
		if not IsLocalFileExist(szPath) then
			local szOriginPath
			if ePathType == X.PATH_TYPE.GLOBAL then
				szOriginPath = X.FormatPath({'!all-users@{$lang}/', X.PATH_TYPE.DATA})
			elseif ePathType == X.PATH_TYPE.ROLE then
				szOriginPath = X.FormatPath({'{$uid}@{$lang}/', X.PATH_TYPE.DATA})
			elseif ePathType == X.PATH_TYPE.SERVER then
				szOriginPath = X.FormatPath({'#{$server_origin}@{$lang}/', X.PATH_TYPE.DATA})
			end
			if IsLocalFileExist(szOriginPath) then
				CPath.Move(szOriginPath, szPath)
			end
		end
	end
	-- Unified the directory separator
	szFilePath = string.gsub(szFilePath, '\\', '/')
	-- if it's relative path then complete path with '/{NS}#DATA/'
	if szFilePath:sub(2, 3) ~= ':/' then
		if ePathType == X.PATH_TYPE.DATA then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. szFilePath
		elseif ePathType == X.PATH_TYPE.GLOBAL then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '!all-users@{$edition}/' .. szFilePath
		elseif ePathType == X.PATH_TYPE.ROLE then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '{$uid}@{$edition}/' .. szFilePath
		elseif ePathType == X.PATH_TYPE.SERVER then
			szFilePath = X.PACKET_INFO.DATA_ROOT .. '#{$server_origin}@{$edition}/' .. szFilePath
		end
	end
	-- if exist {$uid} then add user role identity
	if string.find(szFilePath, '{$uid}', nil, true) then
		szFilePath = szFilePath:gsub('{%$uid}', tParams['uid'] or X.GetClientPlayerGlobalID())
	end
	-- if exist {$name} then add user role identity
	if string.find(szFilePath, '{$name}', nil, true) then
		szFilePath = szFilePath:gsub('{%$name}', tParams['name'] or X.GetClientPlayerInfo().szName)
	end
	-- if exist {$lang} then add language identity
	if string.find(szFilePath, '{$lang}', nil, true) then
		szFilePath = szFilePath:gsub('{%$lang}', tParams['lang'] or X.ENVIRONMENT.GAME_LANG)
	end
	-- if exist {$edition} then add edition identity
	if string.find(szFilePath, '{$edition}', nil, true) then
		szFilePath = szFilePath:gsub('{%$edition}', tParams['edition'] or X.ENVIRONMENT.GAME_EDITION)
	end
	-- if exist {$branch} then add branch identity
	if string.find(szFilePath, '{$branch}', nil, true) then
		szFilePath = szFilePath:gsub('{%$branch}', tParams['branch'] or X.ENVIRONMENT.GAME_BRANCH)
	end
	-- if exist {$version} then add version identity
	if string.find(szFilePath, '{$version}', nil, true) then
		szFilePath = szFilePath:gsub('{%$version}', tParams['version'] or X.ENVIRONMENT.GAME_VERSION)
	end
	-- if exist {$date} then add date identity
	if string.find(szFilePath, '{$date}', nil, true) then
		szFilePath = szFilePath:gsub('{%$date}', tParams['date'] or X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd'))
	end
	-- if exist {$server} then add server identity
	if string.find(szFilePath, '{$server}', nil, true) then
		szFilePath = szFilePath:gsub('{%$server}', tParams['server'] or ((X.GetRegionName() .. '_' .. X.GetServerName()):gsub('[/\\|:%*%?"<>]', '')))
	end
	-- if exist {$server_origin} then add server_origin identity
	if string.find(szFilePath, '{$server_origin}', nil, true) then
		szFilePath = szFilePath:gsub('{%$server_origin}', tParams['server_origin'] or ((X.GetRegionOriginName() .. '_' .. X.GetServerOriginName()):gsub('[/\\|:%*%?"<>]', '')))
	end
	local rootPath = GetRootPath():gsub('\\', '/')
	if szFilePath:find(rootPath) == 1 then
		szFilePath = szFilePath:gsub(rootPath, '.')
	end
	return szFilePath
end

function X.GetRelativePath(oPath, oRoot)
	local szPath = X.FormatPath(oPath):gsub('^%./', '')
	local szRoot = X.FormatPath(oRoot):gsub('^%./', '')
	local szRootPath = GetRootPath():gsub('\\', '/')
	if szPath:sub(2, 2) ~= ':' then
		szPath = X.ConcatPath(szRootPath, szPath)
	end
	if szRoot:sub(2, 2) ~= ':' then
		szRoot = X.ConcatPath(szRootPath, szRoot)
	end
	szRoot = szRoot:gsub('/$', '') .. '/'
	if X.StringFindW(szPath:lower(), szRoot:lower()) ~= 1 then
		return
	end
	return szPath:sub(#szRoot + 1)
end

function X.GetAbsolutePath(oPath)
	local szPath = X.FormatPath(oPath)
	if szPath:sub(2, 2) == ':' then
		return szPath
	end
	return X.NormalizePath(GetRootPath():gsub('\\', '/') .. '/' .. X.GetRelativePath(szPath, {'', X.PATH_TYPE.NORMAL}):gsub('^[./\\]*', ''))
end

function X.GetLUADataPath(oFilePath)
	local szFilePath = X.FormatPath(oFilePath)
	-- ensure has file name
	if string.sub(szFilePath, -1) == '/' then
		szFilePath = szFilePath .. 'data'
	end
	-- ensure file ext name
	if string.sub(szFilePath, -7):lower() ~= '.jx3dat' then
		szFilePath = szFilePath .. '.jx3dat'
	end
	return szFilePath
end

-- ƴ��·���ַ���
---@vararg string @��Ҫƴ�ӵ�·���ַ�������
---@return string @ƴ�Ӻ��·���ַ���
function X.ConcatPath(...)
	local aPath = {...}
	local szPath = ''
	for _, s in ipairs(aPath) do
		s = tostring(s):gsub('^[\\/]+', '')
		if s ~= '' then
			szPath = szPath:gsub('[\\/]+$', '')
			if szPath ~= '' then
				szPath = szPath .. '/'
			end
			szPath = szPath .. s
		end
	end
	return szPath
end

-- ��׼��·���ַ���Ŀ¼�ָ���Ϊ��б�ܣ�����ɾ��Ŀ¼�е�\.\��\..\
---@param szPath string @Ҫ�����Ŀ¼�ַ���
---@return string @��׼�����·���ַ���
function X.NormalizePath(szPath)
	szPath = szPath:gsub('/', '\\')
	szPath = szPath:gsub('\\%.\\', '\\')
	local nPos1, nPos2
	while true do
		nPos1, nPos2 = szPath:find('[^\\]*\\%.%.\\')
		if not nPos1 then
			break
		end
		szPath = szPath:sub(1, nPos1 - 1) .. szPath:sub(nPos2 + 1)
	end
	return szPath
end

-- ��ȡ����Ŀ¼ ע���ļ����ļ��л�ȡ���������
---@param szPath string @��Ҫ��ȡ����Ŀ¼��·��
---@return string @����Ŀ¼��������βĿ¼�ָ���
function X.GetParentPath(szPath)
	local szPath = X.NormalizePath(szPath)
	if not szPath:find('\\') then
		return '.'
	end
	local szParent = szPath:gsub('\\[^\\]+\\*$', '')
	if #szParent == 2 and szParent:sub(2, 2) == ':' then
		szParent = szParent .. '\\'
	end
	return szParent
end

do local CREATED = {}
function X.CreateDataRoot(ePathType)
	if CREATED[ePathType] then
		return
	end
	CREATED[ePathType] = true
	-- ����Ŀ¼
	if ePathType == X.PATH_TYPE.ROLE then
		X.SaveLUAData(
			{'info.jx3dat', X.PATH_TYPE.ROLE},
			{
				id = X.GetClientPlayerInfo().dwID,
				uid = X.GetClientPlayerGlobalID(),
				name = X.GetClientPlayerInfo().szName,
				lang = X.ENVIRONMENT.GAME_LANG,
				edition = X.ENVIRONMENT.GAME_EDITION,
				branch = X.ENVIRONMENT.GAME_BRANCH,
				version = X.ENVIRONMENT.GAME_VERSION,
				region = X.GetRegionName(),
				server = X.GetServerName(),
				region_origin = X.GetServerOriginName(),
				server_origin = X.GetRegionOriginName(),
				time = GetCurrentTime(),
				time_str = X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'),
			},
			{ encoder = 'luatext', crc = false, passphrase = false })
		local szPlayerName = X.GetClientPlayerName()
		if szPlayerName then
			CPath.MakeDir(X.FormatPath({szPlayerName .. '/', X.PATH_TYPE.ROLE}))
		end
	end
	-- �汾����ʱɾ���ɵ���ʱĿ¼
	if IsLocalFileExist(X.FormatPath({'temporary/', ePathType}))
	and not IsLocalFileExist(X.FormatPath({'temporary/{$version}', ePathType})) then
		CPath.DelDir(X.FormatPath({'temporary/', ePathType}))
	end
	CPath.MakeDir(X.FormatPath({'temporary/{$version}/', ePathType}))
	CPath.MakeDir(X.FormatPath({'audio/', ePathType}))
	CPath.MakeDir(X.FormatPath({'cache/', ePathType}))
	CPath.MakeDir(X.FormatPath({'config/', ePathType}))
	CPath.MakeDir(X.FormatPath({'export/', ePathType}))
	CPath.MakeDir(X.FormatPath({'logs/', ePathType}))
	CPath.MakeDir(X.FormatPath({'font/', ePathType}))
	CPath.MakeDir(X.FormatPath({'userdata/', ePathType}))
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
