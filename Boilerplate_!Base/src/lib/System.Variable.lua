--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤ȫ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Variable')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- Format data's structure as struct descripted.
do
local defaultParams = { keepNewChild = false }
local function FormatDataStructure(data, struct, assign, metaSymbol)
	if metaSymbol == nil then
		metaSymbol = '__META__'
	end
	-- ��׼������
	local params = setmetatable({}, defaultParams)
	local structTypes, defaultData, defaultDataType
	local keyTemplate, childTemplate, arrayTemplate, dictionaryTemplate
	if type(struct) == 'table' and struct[1] == metaSymbol then
		-- ������META��ǵ�������
		-- �������ͺ�Ĭ��ֵ
		structTypes = struct[2] or { type(struct.__VALUE__) }
		defaultData = struct[3] or struct.__VALUE__
		defaultDataType = type(defaultData)
		-- ��ģ����ز���
		if defaultDataType == 'table' then
			keyTemplate = struct.__KEY_TEMPLATE__
			childTemplate = struct.__CHILD_TEMPLATE__
			arrayTemplate = struct.__ARRAY_TEMPLATE__
			dictionaryTemplate = struct.__DICTIONARY_TEMPLATE__
		end
		-- ���Ӳ���
		if struct.__PARAMS__ then
			for k, v in pairs(struct.__PARAMS__) do
				params[k] = v
			end
		end
	else
		-- ������ͨ������
		structTypes = { type(struct) }
		defaultData = struct
		defaultDataType = type(defaultData)
	end
	-- ����ṹ�����ݵ�����
	local dataType = type(data)
	local dataTypeExists = false
	if not dataTypeExists then
		for _, v in ipairs(structTypes) do
			if dataType == v then
				dataTypeExists = true
				break
			end
		end
	end
	-- �ֱ�������ƥ���벻ƥ������
	if dataTypeExists then
		if not assign then
			data = X.Clone(data, true)
		end
		local keys, skipKeys = {}, {}
		-- ���������Ǳ���Ĭ������Ҳ�Ǳ� ��ݹ�����Ԫ����Ĭ����Ԫ��
		if dataType == 'table' and defaultDataType == 'table' then
			for k, v in pairs(defaultData) do
				keys[k], skipKeys[k] = true, true
				data[k] = FormatDataStructure(data[k], defaultData[k], true, metaSymbol)
			end
		end
		-- ���������Ǳ���META��Ϣ�ж�������Ԫ��KEYģ�� ��ݹ�����Ԫ��KEY����Ԫ��KEYģ��
		if dataType == 'table' and keyTemplate then
			for k, v in pairs(data) do
				if not skipKeys[k] then
					local k1 = FormatDataStructure(k, keyTemplate, true, metaSymbol)
					if k1 ~= k then
						if k1 ~= nil then
							data[k1] = data[k]
						end
						data[k] = nil
					end
				end
			end
		end
		-- ���������Ǳ���META��Ϣ�ж�������Ԫ��ģ�� ��ݹ�����Ԫ������Ԫ��ģ��
		if dataType == 'table' and childTemplate then
			for k, v in pairs(data) do
				if not skipKeys[k] then
					keys[k] = true
					data[k] = FormatDataStructure(data[k], childTemplate, true, metaSymbol)
				end
			end
		end
		-- ���������Ǳ���META��Ϣ�ж������б���Ԫ��ģ�� ��ݹ�����Ԫ�����б���Ԫ��ģ��
		if dataType == 'table' and arrayTemplate then
			for i, v in pairs(data) do
				if type(i) == 'number' then
					if not skipKeys[i] then
						keys[i] = true
						data[i] = FormatDataStructure(data[i], arrayTemplate, true, metaSymbol)
					end
				end
			end
		end
		-- ���������Ǳ���META��Ϣ�ж����˹�ϣ��Ԫ��ģ�� ��ݹ�����Ԫ�����ϣ��Ԫ��ģ��
		if dataType == 'table' and dictionaryTemplate then
			for k, v in pairs(data) do
				if type(k) ~= 'number' then
					if not skipKeys[k] then
						keys[k] = true
						data[k] = FormatDataStructure(data[k], dictionaryTemplate, true, metaSymbol)
					end
				end
			end
		end
		-- ���������Ǳ���Ĭ������Ҳ�Ǳ� ��ݹ�����Ԫ���Ƿ���Ҫ����
		if dataType == 'table' and defaultDataType == 'table' then
			if not params.keepNewChild then
				for k, v in pairs(data) do
					if defaultData[k] == nil and not keys[k] then -- Ĭ����û����û��ͨ����������������ɾ��
						data[k] = nil
					end
				end
			end
		end
	else -- ���Ͳ�ƥ������
		if type(defaultData) == 'table' then
			-- Ĭ��ֵΪ�� ��Ҫ�ݹ�����Ԫ��
			data = {}
			for k, v in pairs(defaultData) do
				data[k] = FormatDataStructure(nil, v, true, metaSymbol)
			end
		else -- Ĭ��ֵ���Ǳ� ֱ�ӿ�¡����
			data = X.Clone(defaultData, true)
		end
	end
	return data
end
X.FormatDataStructure = FormatDataStructure
end

function X.SetGlobalValue(szVarPath, Val)
	local t = X.SplitString(szVarPath, '.')
	local tab = _G
	for k, v in ipairs(t) do
		if not X.IsTable(tab) then
			return false
		end
		if type(tab[v]) == 'nil' then
			tab[v] = {}
		end
		if k == #t then
			tab[v] = Val
		end
		tab = tab[v]
	end
	return true
end

function X.GetGlobalValue(szVarPath)
	local tVariable = _G
	for szIndex in string.gmatch(szVarPath, '[^%.]+') do
		if tVariable and type(tVariable) == 'table' then
			tVariable = tVariable[szIndex]
		else
			tVariable = nil
			break
		end
	end
	return tVariable
end

-- ����ע������
X.RegisterInit(X.NSFormatString('{$NS}#INITDATA'), function()
	local t = LoadLUAData(X.GetLUADataPath({'config/initial.jx3dat', X.PATH_TYPE.GLOBAL}))
	if t then
		for v_name, v_data in pairs(t) do
			X.SetGlobalValue(v_name, v_data)
		end
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
