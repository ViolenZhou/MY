--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Ŀ�����������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------

local PLUGIN_NAME = 'MY_TargetMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TargetMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^10.0.0') then
	return
end
X.RegisterRestriction('MY_TargetMon', { ['*'] = false, classic = true })
X.RegisterRestriction('MY_TargetMon.ShieldedUUID', { ['*'] = true })
--------------------------------------------------------------------------
local LANG = ENVIRONMENT.GAME_LANG
local INIT_STATE = 'NONE'
local C, D = { PASSPHRASE = {213, 166, 13}, PASSPHRASE_EMBEDDED = {211, 98, 5} }, {}
local ROLE_CONFIG_FILE = {'config/my_targetmon.jx3dat', X.PATH_TYPE.ROLE}
local EMBEDDED_ENCRYPTED = false
local CUSTOM_EMBEDDED_CONFIG_ROOT = X.FormatPath({'userdata/TargetMon/', X.PATH_TYPE.GLOBAL})
local CUSTOM_DEFAULT_CONFIG_FILE = {'config/my_targetmon.jx3dat', X.PATH_TYPE.GLOBAL}
local TARGET_TYPE_LIST = {
	'CLIENT_PLAYER'  ,
	'CONTROL_PLAYER' ,
	'TARGET'         ,
	'TTARGET'        ,
	'TEAM_MARK_CLOUD',
	'TEAM_MARK_SWORD',
	'TEAM_MARK_AX'   ,
	'TEAM_MARK_HOOK' ,
	'TEAM_MARK_DRUM' ,
	'TEAM_MARK_SHEAR',
	'TEAM_MARK_STICK',
	'TEAM_MARK_JADE' ,
	'TEAM_MARK_DART' ,
	'TEAM_MARK_FAN'  ,
}
local CONFIG, CONFIG_CHANGED, CONFIG_BUFF_TARGET_LIST, CONFIG_SKILL_TARGET_LIST
local CONFIG_TEMPLATE = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_TargetMon/data/template/{$lang}.jx3dat')
local MON_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__
local MONID_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__
local MONLEVEL_TEMPLATE = CONFIG_TEMPLATE.monitors.__CHILD_TEMPLATE__.__VALUE__.ids.__CHILD_TEMPLATE__.levels.__CHILD_TEMPLATE__
local EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = {}, {}, {}

function D.GetTargetTypeList(szType)
	if szType == 'BUFF' then
		return CONFIG_BUFF_TARGET_LIST
	end
	if szType == 'SKILL' then
		return CONFIG_SKILL_TARGET_LIST
	end
	return TARGET_TYPE_LIST
end

function D.GeneUUID()
	return X.GetUUID():gsub('-', '')
end

function D.GetConfigCaption(config)
	local szCaption = config.caption
	if config.group ~= '' then
		szCaption = g_tStrings.STR_BRACKET_LEFT .. config.group .. g_tStrings.STR_BRACKET_RIGHT .. szCaption
	end
	return szCaption
end

-- ��ʽ�����������
function D.FormatConfig(config, bCoroutine)
	return X.FormatDataStructure(config, CONFIG_TEMPLATE, nil, nil, bCoroutine)
end

function D.LoadEmbeddedConfig(bCoroutine)
	if not X.IsString(C.PASSPHRASE) or not X.IsString(C.PASSPHRASE_EMBEDDED) then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_TargetMonConfig', 'Passphrase cannot be empty!', X.DEBUG_LEVEL.ERROR)
		--[[#DEBUG END]]
		return
	end
	if not EMBEDDED_ENCRYPTED then
		-- �Զ��������ü�������
		local DAT_ROOT = 'MY_Resource/data/targetmon/'
		local SRC_ROOT = X.PACKET_INFO.ROOT .. '!src-dist/data/' .. DAT_ROOT
		for _, szFile in ipairs(CPath.GetFileList(SRC_ROOT)) do
			X.Sysmsg(_L['Encrypt and compressing: '] .. DAT_ROOT .. szFile)
			local uuid = szFile:sub(1, -13)
			local lang = szFile:sub(-11, -8)
			if lang == 'zhcn' or lang == 'zhtw' then
				local data = LoadDataFromFile(SRC_ROOT .. szFile)
				if IsEncodedData(data) then
					data = DecodeData(data)
				end
				if lang == 'zhcn' then
					data = X.DecodeLUAData(data)
					if X.IsArray(data) then
						for k, p in ipairs(data) do
							data[k] = D.FormatConfig(p, bCoroutine)
						end
					else
						data = D.FormatConfig(data, bCoroutine)
					end
					data = 'return ' .. X.EncodeLUAData(data)
				end
				data = EncodeData(data, true, true)
				SaveDataToFile(data, X.FormatPath({'userdata/TargetMon/' .. uuid .. '.jx3dat', X.PATH_TYPE.GLOBAL}, {lang = lang}), C.PASSPHRASE_EMBEDDED)
			end
		end
		EMBEDDED_ENCRYPTED = true
	end
	-- ������������
	local aConfig = {}
	for _, szFile in ipairs(CPath.GetFileList(CUSTOM_EMBEDDED_CONFIG_ROOT) or {}) do
		local config = X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile, { passphrase = C.PASSPHRASE_EMBEDDED })
			or X.LoadLUAData(CUSTOM_EMBEDDED_CONFIG_ROOT .. szFile)
		if X.IsTable(config) and config.uuid and szFile:sub(1, -#'.jx3dat' - 1) == config.uuid and config.group and config.sort and config.monitors then
			table.insert(aConfig, config)
		end
	end
	table.sort(aConfig, function(a, b)
		if a.group == b.group then
			return b.sort > a.sort
		end
		return b.group > a.group
	end)
	-- ��ʽ����������
	local aEmbedded, tEmbedded, tEmbeddedMon = {}, {}, {}
	for _, config in ipairs(aConfig) do
		if config and config.uuid and config.monitors then
			local embedded = config
			if LANG ~= 'zhcn' then
				embedded = D.FormatConfig(config, bCoroutine)
			end
			if embedded then
				-- Ĭ�Ͻ���
				embedded.enable = false
				-- ������ͼ������ٻ���
				local tMon = {}
				for _, mon in ipairs(embedded.monitors) do
					mon.manually = nil
					tMon[mon.uuid] = mon
				end
				-- ��������
				tEmbedded[embedded.uuid] = embedded
				tEmbeddedMon[embedded.uuid] = tMon
				table.insert(aEmbedded, embedded)
			end
		end
	end
	EMBEDDED_CONFIG_LIST, EMBEDDED_CONFIG_HASH, EMBEDDED_MONITOR_HASH = aEmbedded, tEmbedded, tEmbeddedMon
end

local SHIELDED_UUID = X.ArrayToObject({
	'00000223B5B291D0',
	'00000223B5FD2010',
	'00mu02rong04youMB',
	'00mu02rong04youZS',
	'00mu02rong04youMBC',
	'00mu02rong04youZSC',
	'00mu02rong04youMBMZB',
	'00mu02rong04youZSMZB',
	'00000000D7D31AB0',
	'000000009AB91DB0',
	'000001B68EE82B00',
	'000001B68EE79EB0',
	'000001B5FA8F1880',
	'000001B6A2BCF6F0',
})
-- ͨ����Ƕ���ݽ������תΪPatch
function D.PatchToConfig(patch, bCoroutine)
	-- �����û�ɾ�����ڽ����ݺͲ��Ϸ�������
	if patch.delete or not patch.uuid or (X.IsRestricted('MY_TargetMon.ShieldedUUID') and not IsDebugClient() and SHIELDED_UUID[patch.uuid]) then
		return
	end
	-- �ϲ�δ�޸ĵ���Ƕ����
	local embedded, config = EMBEDDED_CONFIG_HASH[patch.uuid], {}
	if embedded then
		-- ������Ƕ����Ĭ������
		for k, v in pairs(embedded) do
			if k ~= 'monitors' then
				if patch[k] == nil then
					config[k] = X.Clone(v)
				end
			end
		end
		-- ���øı��������
		for k, v in pairs(patch) do
			if k ~= 'monitors' then
				config[k] = X.Clone(v)
			end
		end
		-- ���ü������Ƕ����ɾ������Զ�����
		local monitors = {}
		local existMon = {}
		if patch.monitors then
			for i, mon in ipairs(patch.monitors) do
				if not mon.delete then
					local monEmbedded = EMBEDDED_MONITOR_HASH[patch.uuid][mon.uuid]
					if monEmbedded then -- ������Ƕ����
						if mon.patch then
							table.insert(monitors, X.ApplyPatch(monEmbedded, mon.patch))
						else
							table.insert(monitors, X.Clone(monEmbedded))
						end
					elseif not mon.embedded and not mon.patch and mon.manually ~= false then -- ɾ����ǰ�汾�����ڵ���Ƕ����
						table.insert(monitors, X.Clone(mon))
					end
				end
				existMon[mon.uuid] = true
			end
		end
		-- �����µ���Ƕ����
		for i, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				local prevUuid, nIndex = monitors[i - 1] and monitors[i - 1].uuid, nil
				if prevUuid then
					for j, mon in ipairs(monitors) do
						if mon.uuid == prevUuid then
							nIndex = j + 1
							break
						end
					end
				end
				if nIndex then
					table.insert(monitors, nIndex, X.Clone(monEmbedded))
				else
					table.insert(monitors, X.Clone(monEmbedded))
				end
				existMon[monEmbedded.uuid] = true
			end
		end
		config.monitors = monitors
		config.group = embedded.group
		config.caption = embedded.caption
		config.embedded = true
	else
		-- ���ٴ��ڵ���Ƕ����
		if patch.embedded then
			return
		end
		for k, v in pairs(patch) do
			config[k] = X.Clone(v)
		end
	end
	return D.FormatConfig(config, bCoroutine)
end

-- ͨ����Ƕ���ݽ�PatchתΪ�����
function D.ConfigToPatch(config)
	-- �����Ϸ�������
	if not config.uuid then
		return
	end
	-- �����޸ĵ���Ƕ����
	local embedded, patch = EMBEDDED_CONFIG_HASH[config.uuid], {}
	if embedded then
		-- �����޸ĵ�ȫ������
		for k, v in pairs(config) do
			if k ~= 'monitors' and not X.IsEquals(v, embedded[k]) then
				patch[k] = X.Clone(v)
			end
		end
		-- ������������Լ������޸ĵĲ���
		local monitors = {}
		local existMon = {}
		for i, mon in ipairs(config.monitors) do
			local monEmbedded = EMBEDDED_MONITOR_HASH[embedded.uuid][mon.uuid]
			if monEmbedded then
				-- ��Ƕ�ļ�ؼ���Patch
				table.insert(monitors, {
					embedded = true,
					uuid = monEmbedded.uuid,
					patch = X.GetPatch(monEmbedded, mon),
				})
			else
				-- �Լ���ӵļ��
				table.insert(monitors, X.Clone(mon))
			end
			existMon[mon.uuid] = true
		end
		-- ����ɾ���Ĳ���
		for _, monEmbedded in ipairs(embedded.monitors) do
			if not existMon[monEmbedded.uuid] then
				table.insert(monitors, { uuid = monEmbedded.uuid, delete = true })
			end
			existMon[monEmbedded.uuid] = true
		end
		patch.uuid = config.uuid
		patch.embedded = true
		patch.monitors = monitors
	else
		for k, v in pairs(config) do
			patch[k] = X.Clone(v)
		end
	end
	return patch
end

function D.MarkConfigChanged()
	CONFIG_CHANGED = true
end

function D.HasConfigChanged()
	return CONFIG_CHANGED
end

function D.UpdateTargetList()
	local tBuffTargetExist, tSkillTargetExist = {}, {}
	for _, config in ipairs(CONFIG) do
		if config.enable then
			if config.type == 'BUFF' then
				tBuffTargetExist[config.target] = true
			elseif config.type == 'SKILL' then
				tSkillTargetExist[config.target] = true
			end
		end
	end
	local aBuffTarget, aSkillTarget = {}, {}
	for _, szType in ipairs(TARGET_TYPE_LIST) do
		if tBuffTargetExist[szType] then
			table.insert(aBuffTarget, szType)
		end
		if tSkillTargetExist[szType] then
			table.insert(aSkillTarget, szType)
		end
	end
	CONFIG_BUFF_TARGET_LIST, CONFIG_SKILL_TARGET_LIST = aBuffTarget, aSkillTarget
end

function D.LoadConfig(bDefault, bOriginal, bCoroutine)
	local aPatch
	if not bDefault then
		aPatch = X.LoadLUAData(ROLE_CONFIG_FILE, { passphrase = C.PASSPHRASE }) or X.LoadLUAData(ROLE_CONFIG_FILE)
	end
	if not aPatch and not bOriginal then
		aPatch = X.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE, { passphrase = C.PASSPHRASE }) or X.LoadLUAData(CUSTOM_DEFAULT_CONFIG_FILE)
	end
	if not aPatch then
		aPatch = {}
	end
	local aConfig, tLoaded = {}, {}
	for i, patch in ipairs(aPatch) do
		if patch.uuid and not tLoaded[patch.uuid] then
			local config = D.PatchToConfig(patch)
			if config then
				table.insert(aConfig, config)
			end
			tLoaded[patch.uuid] = true
		end
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if embedded.uuid and not tLoaded[embedded.uuid] then
			local config = X.Clone(embedded)
			if LANG ~= 'zhcn' then
				config = D.FormatConfig(config, bCoroutine)
			end
			if config then
				config.embedded = true
				table.insert(aConfig, config)
			end
			tLoaded[config.uuid] = true
		end
	end
	CONFIG = aConfig
	CONFIG_CHANGED = bDefault and true or false
	D.UpdateTargetList()
	if INIT_STATE == 'DONE' then
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
end

function D.SaveConfig(bDefault)
	local aPatch, tLoaded = {}, {}
	for i, config in ipairs(CONFIG) do
		local patch = D.ConfigToPatch(config)
		if patch then
			table.insert(aPatch, patch)
		end
		tLoaded[config.uuid] = true
	end
	for i, embedded in ipairs(EMBEDDED_CONFIG_LIST) do
		if not tLoaded[embedded.uuid] then
			table.insert(aPatch, {
				uuid = embedded.uuid,
				delete = true,
			})
			tLoaded[embedded.uuid] = true
		end
	end
	if bDefault then
		X.SaveLUAData(CUSTOM_DEFAULT_CONFIG_FILE, aPatch, { passphrase = C.PASSPHRASE })
	else
		X.SaveLUAData(ROLE_CONFIG_FILE, aPatch, { passphrase = C.PASSPHRASE })
		CONFIG_CHANGED = false
	end
end

function D.ImportPatches(aPatch, bAsEmbedded)
	local nImportCount = 0
	local nReplaceCount = 0
	if bAsEmbedded then
		for _, embedded in ipairs(aPatch) do
			if embedded and embedded.uuid then
				local szFile = CUSTOM_EMBEDDED_CONFIG_ROOT .. embedded.uuid .. '.jx3dat'
				if IsLocalFileExist(szFile) then
					nReplaceCount = nReplaceCount + 1
				end
				nImportCount = nImportCount + 1
				X.SaveLUAData(szFile, embedded, { passphrase = C.PASSPHRASE_EMBEDDED })
			end
		end
		if nImportCount > 0 then
			D.SaveConfig()
			D.LoadEmbeddedConfig()
			D.LoadConfig()
		end
	else
		for _, patch in ipairs(aPatch) do
			local config = D.PatchToConfig(patch)
			if config then
				for i, cfg in X.ipairs_r(CONFIG) do
					if config.uuid and config.uuid == cfg.uuid then
						table.remove(CONFIG, i)
						nReplaceCount = nReplaceCount + 1
					end
				end
				nImportCount = nImportCount + 1
				table.insert(CONFIG, config)
			end
		end
		if nImportCount > 0 then
			CONFIG_CHANGED = true
			D.UpdateTargetList()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end
	end
	return nImportCount, nReplaceCount
end

function D.ExportPatches(aUUID, bAsEmbedded)
	local aPatch = {}
	for i, uuid in ipairs(aUUID) do
		for i, config in ipairs(CONFIG) do
			local patch = config.uuid == uuid and D.ConfigToPatch(config)
			if patch and (bAsEmbedded or not patch.embedded) then
				if bAsEmbedded then
					patch.uuid = 'DT' .. patch.uuid
				end
				table.insert(aPatch, patch)
			end
		end
	end
	return aPatch
end

function D.ImportPatchFile(oFilePath)
	local aPatch, bAsEmbedded = X.LoadLUAData(oFilePath, { passphrase = C.PASSPHRASE }) or X.LoadLUAData(oFilePath), false
	if not aPatch then
		aPatch, bAsEmbedded = X.LoadLUAData(oFilePath, { passphrase = C.PASSPHRASE_EMBEDDED }), true
	end
	if not aPatch then
		return
	end
	return D.ImportPatches(aPatch, bAsEmbedded)
end

function D.ExportPatchFile(oFilePath, aUUID, szIndent, bAsEmbedded)
	if bAsEmbedded then
		szIndent = nil
	end
	local szPassphrase
	if bAsEmbedded then
		szPassphrase = C.PASSPHRASE_EMBEDDED
	elseif not szIndent then
		szPassphrase = C.PASSPHRASE
	end
	local aPatch = D.ExportPatches(aUUID, bAsEmbedded)
	X.SaveLUAData(oFilePath, aPatch, { indent = szIndent, crc = not szIndent, passphrase = szPassphrase })
end

function D.Init(bNoCoroutine)
	if INIT_STATE == 'NONE' then
		local k = string.char(80, 65, 83, 83, 80, 72, 82, 65, 83, 69)
		if X.IsTable(C[k]) then
			for i = 0, 50 do
				for j, v in ipairs({ 253, 12, 34, 56 }) do
					table.insert(C[k], (i * j * ((3 * v) % 256)) % 256)
				end
			end
			C[k] = string.char(unpack(C[k]))
		end
		local k = string.char(80, 65, 83, 83, 80, 72, 82, 65, 83, 69, 95, 69, 77, 66, 69, 68, 68, 69, 68)
		if X.IsTable(C[k]) then
			for i = 0, 50 do
				for j, v in ipairs({ 253, 12, 34, 56 }) do
					table.insert(C[k], (i * j * ((15 * v) % 256)) % 256)
				end
			end
			C[k] = string.char(unpack(C[k]))
		end
		INIT_STATE = 'WAIT_CONFIG'
	end
	if INIT_STATE == 'WAIT_CONFIG' then
		X.RegisterCoroutine('MY_TargetMonConfig', function()
			D.LoadEmbeddedConfig(true)
			D.LoadConfig(nil, nil, true)
			INIT_STATE = 'DONE'
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
		end)
		INIT_STATE = 'LOADING_CONFIG'
	end
	if INIT_STATE == 'LOADING_CONFIG' and bNoCoroutine then
		X.FlushCoroutine('MY_TargetMonConfig')
	end
	return INIT_STATE == 'DONE'
end
X.RegisterInit('MY_TargetMonConfig', D.Init)

do
local function Flush()
	if not D.HasConfigChanged() then
		return
	end
	D.SaveConfig()
end
X.RegisterFlush('MY_TargetMonConfig', Flush)
end

function D.GetConfig(nIndex)
	return CONFIG[nIndex]
end

function D.GetConfigList(bNoEmbedded)
	D.Init(true)
	if bNoEmbedded then
		local a = {}
		for _, config in ipairs(CONFIG) do
			if not EMBEDDED_CONFIG_HASH[config.uuid] then
				table.insert(a, config)
			end
		end
		return a
	end
	return CONFIG
end

------------------------------------------------------------------------------------------------------
-- �������������
------------------------------------------------------------------------------------------------------
function D.CreateConfig()
	local config = X.FormatDataStructure({
		uuid = D.GeneUUID(),
	}, CONFIG_TEMPLATE)
	table.insert(CONFIG, config)
	D.UpdateTargetList()
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	return config
end

function D.MoveConfig(config, offset)
	for i, v in ipairs(CONFIG) do
		if v == config then
			local j = math.min(math.max(i + offset, 1), #CONFIG)
			if j ~= i then
				table.remove(CONFIG, i)
				table.insert(CONFIG, j, config)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
end

function D.ModifyConfig(config, szKey, oVal)
	if X.IsString(config) then
		for _, v in ipairs(CONFIG) do
			if v.uuid == config then
				config = v
				break
			end
		end
	end
	if not X.Set(config, szKey, oVal) then
		return
	end
	if szKey == 'enable' or szKey == 'target' or szKey == 'type' then
		D.UpdateTargetList()
	end
	if szKey == 'enable' and oVal then
		FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
	end
	D.MarkConfigChanged()
end

function D.DeleteConfig(config, bAsEmbedded)
	for i, v in X.ipairs_r(CONFIG) do
		if v == config then
			table.remove(CONFIG, i)
			D.UpdateTargetList()
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_CONFIG_INIT')
			break
		end
	end
	if bAsEmbedded then
		CPath.DelFile(CUSTOM_EMBEDDED_CONFIG_ROOT .. config.uuid .. '.jx3dat')
		D.LoadEmbeddedConfig()
		D.SaveConfig()
		D.LoadConfig()
	end
end

------------------------------------------------------------------------------------------------------
-- ����������������
------------------------------------------------------------------------------------------------------
function D.CreateMonitor(config, name)
	local mon = X.FormatDataStructure({
		name = name,
		uuid = D.GeneUUID(),
	}, MON_TEMPLATE)
	table.insert(config.monitors, mon)
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
	return mon
end

function D.MoveMonitor(config, mon, offset)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			local j = math.min(math.max(i + offset, 1), #config.monitors)
			if j ~= i then
				table.remove(config.monitors, i)
				table.insert(config.monitors, j, mon)
			end
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
			break
		end
	end
end

function D.ModifyMonitor(mon, szKey, oVal)
	if not X.Set(mon, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
	FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
end

function D.DeleteMonitor(config, mon)
	for i, v in ipairs(config.monitors) do
		if v == mon then
			table.remove(config.monitors, i)
			D.MarkConfigChanged()
			FireUIEvent('MY_TARGET_MON_MONITOR_CHANGE')
			break
		end
	end
end

------------------------------------------------------------------------------------------------------
-- �������������ID�б�
------------------------------------------------------------------------------------------------------
function D.CreateMonitorId(mon, dwID)
	local monid = X.FormatDataStructure(nil, MONID_TEMPLATE)
	mon.ids[dwID] = monid
	D.MarkConfigChanged()
	return monid
end

function D.ModifyMonitorId(monid, szKey, oVal)
	if not X.Set(monid, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
end

function D.DeleteMonitorId(mon, dwID)
	mon.ids[dwID] = nil
	D.MarkConfigChanged()
end

------------------------------------------------------------------------------------------------------
-- �������������ID�ȼ��б�
------------------------------------------------------------------------------------------------------
function D.CreateMonitorLevel(monid, nLevel)
	local monlevel = X.FormatDataStructure(nil, MONLEVEL_TEMPLATE)
	monid.levels[nLevel] = monlevel
	D.MarkConfigChanged()
	return monlevel
end

function D.ModifyMonitorLevel(monlevel, szKey, oVal)
	if not X.Set(monlevel, szKey, oVal) then
		return
	end
	D.MarkConfigChanged()
end

function D.DeleteMonitorLevel(monid, nLevel)
	monid.levels[nLevel] = nil
	D.MarkConfigChanged()
end

-- Global exports
do
local settings = {
	name = 'MY_TargetMonConfig',
	exports = {
		{
			fields = {
				GetTargetTypeList  = D.GetTargetTypeList ,
				GetConfig          = D.GetConfig         ,
				GetConfigList      = D.GetConfigList     ,
				GetConfigCaption   = D.GetConfigCaption  ,
				LoadConfig         = D.LoadConfig        ,
				SaveConfig         = D.SaveConfig        ,
				ImportPatches      = D.ImportPatches     ,
				ExportPatches      = D.ExportPatches     ,
				ImportPatchFile    = D.ImportPatchFile   ,
				ExportPatchFile    = D.ExportPatchFile   ,
				MarkConfigChanged  = D.MarkConfigChanged ,
				CreateConfig       = D.CreateConfig      ,
				MoveConfig         = D.MoveConfig        ,
				ModifyConfig       = D.ModifyConfig      ,
				DeleteConfig       = D.DeleteConfig      ,
				CreateMonitor      = D.CreateMonitor     ,
				MoveMonitor        = D.MoveMonitor       ,
				ModifyMonitor      = D.ModifyMonitor     ,
				DeleteMonitor      = D.DeleteMonitor     ,
				CreateMonitorId    = D.CreateMonitorId   ,
				ModifyMonitorId    = D.ModifyMonitorId   ,
				DeleteMonitorId    = D.DeleteMonitorId   ,
				CreateMonitorLevel = D.CreateMonitorLevel,
				ModifyMonitorLevel = D.ModifyMonitorLevel,
				DeleteMonitorLevel = D.DeleteMonitorLevel,
			},
		},
	},
}
MY_TargetMonConfig = X.CreateModule(settings)
end
