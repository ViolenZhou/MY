--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤���溯��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.UI')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ע��ȫ�� ESC ��ť�¼�
---@param szKey string @Ψһ��ʶ�ַ������������ͬ��ʶ�ɵĻᱻ���ǣ�
---@param fnCondition function | false @�жϺ������������ʾִ�� fnAction������ false ��ʾȡ��ע��
---@param fnAction function? @�¼�ִ�к���
---@param bTopmost boolean? @�� ESC ע��Ϊ�����ȼ�
function X.RegisterEsc(szKey, fnCondition, fnAction, bTopmost)
	if fnCondition and fnAction then
		if RegisterGlobalEsc then
			RegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szKey, fnCondition, fnAction, bTopmost)
		end
	elseif fnCondition == false then
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szKey, bTopmost)
		end
	end
end

do
local bCustomMode = false
function X.IsInCustomUIMode()
	return bCustomMode
end
X.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE', function() bCustomMode = true  end)
X.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE', function() bCustomMode = false end)
end

function X.GetUIScale()
	return Station.GetUIScale()
end

function X.GetOriginUIScale()
	-- ������ϳ����Ĺ�ʽ -- ��֪����ͬ�����᲻�᲻һ��
	-- Դ����
	-- 0.63, 0.7
	-- 0.666, 0.75
	-- 0.711, 0.8
	-- 0.756, 0.85
	-- 0.846, 0.95
	-- 0.89, 1
	-- return math.floor((1.13726 * Station.GetUIScale() / Station.GetMaxUIScale() - 0.011) * 100 + 0.5) / 100 -- +0.5Ϊ����������
	-- ��ͬ��ʾ��GetMaxUIScale����һ�� ̫�鷳�� ���� ֱ�Ӷ�������
	return GetUserPreferences(3775, 'c') / 100 -- TODO: ��ͬ�����þ�GG�� Ҫͨ��ʵʱ��ֵ������� ȱ��API
end

function X.OpenFolder(szPath)
	local OpenFolder = X.GetGameAPI('OpenFolder')
	if X.IsFunction(OpenFolder) then
		OpenFolder(szPath)
	else
		X.SafeCall(SetDataToClip, szPath)
		X.UI.OpenTextEditor(szPath)
	end
end

-- X.OpenBrowser(szAddr, 'auto')
-- X.OpenBrowser(szAddr, 'outer')
-- X.OpenBrowser(szAddr, 'inner')
function X.OpenBrowser(szAddr, szMode)
	if not szMode then
		szMode = 'auto'
	end
	if szMode == 'auto' or szMode == 'outer' then
		local OpenBrowser = X.GetGameAPI('OpenBrowser')
		if OpenBrowser then
			OpenBrowser(szAddr)
			return
		end
		if szMode == 'outer' then
			X.UI.OpenTextEditor(szAddr)
			return
		end
	end
	X.UI.OpenBrowser(szAddr)
end

-- ���¼�����
---@param szLinkInfo string @��Ҫ�򿪵��¼���������
function X.OpenEventLink(szLinkInfo)
	if IsCtrlKeyDown() then
		X.BreatheCall(function()
			if IsCtrlKeyDown() then
				return
			end
			X.OpenEventLink(szLinkInfo)
			return 0
		end)
		return
	end
	local h = X.UI.GetTempElement('Handle', 'LIB#OpenEventLink')
	if not h then
		return
	end
	h:Clear()
	h:AppendItemFromString(GetFormatText(
		'',
		10, 255, 255, 255, nil,
		'this.szLinkInfo=' .. X.EncodeLUAData(szLinkInfo),
		'eventlink',
		nil,
		szLinkInfo
	))
	local hItem = h:Lookup(0)
	if not hItem then
		return
	end
	OnItemLinkDown(hItem)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
