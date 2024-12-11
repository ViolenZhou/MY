--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : IconPicker
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.PageSetModule')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/PageSetModule.ini'

-- ����һ�� PageSet ģ��
---@param NS table | userdata @��Ҫ���� PageSet �������ռ�������
---@param szPageSetPath string @�Ӵ�����ڵ㵽 WndPageSet �����·��
---@return table @����һ��ģ�鵼������
function X.UI.CreatePageSetModule(NS, szPageSetPath)
	local Exports = {
		tModuleAPI = {},
	}
	local Modules = {}
	local PageSetEvent = {}

	local function GetPageSet(frame)
		return frame:Lookup(szPageSetPath)
	end

	-- ע����ģ��
	function Exports.RegisterModule(szKey, szName, tModule)
		for i, v in X.ipairs_r(Modules) do
			if v.szKey == szKey then
				table.remove(Modules, i)
			end
		end
		if szName and tModule then
			table.insert(Modules, {
				szKey = szKey,
				szName = szName,
				szNameTip = tModule.szNameTip,
				tModule = tModule,
			})
			if tModule.tAPI then
				for k, v in pairs(tModule.tAPI) do
					Exports.tModuleAPI[k] = v
				end
			end
		end
	end

	-- ��ʼ��������
	function Exports.DrawUI(frame)
		local ps = GetPageSet(frame)
		if not ps then
			return
		end
		ps.bInitPageSet = true
		for i, m in ipairs(Modules) do
			local frameTemp = X.UI.OpenFrame(INI_PATH, X.NSFormatString('{$NS}#PageSetModuleTemp'))
			local checkbox = frameTemp and frameTemp:Lookup('PageSet_Total/WndCheck_Default')
			local page = frameTemp and frameTemp:Lookup('PageSet_Total/Page_Default')
			if checkbox and page then
				X.UI.AdaptComponentAppearance(checkbox, 'WndTab')
				checkbox:ChangeRelation(ps, true, true)
				page:ChangeRelation(ps, true, true)
				X.UI.CloseFrame(frameTemp)
				checkbox:SetName('WndCheck_Default')
				page:SetName('Page_Default')
				ps:AddPage(page, checkbox)
				checkbox:Show()
				checkbox:SetRelX(checkbox:GetRelX() + checkbox:GetW() * (i - 1))
				page:SetRelPos(0, checkbox:GetH() + 4)
				page:SetSize(ps:GetW(), ps:GetH() - checkbox:GetH() - 4)
				checkbox:Lookup('', 'Text_CheckDefault'):SetText(m.szName)
				checkbox.nIndex = i
				if m.szNameTip then
					checkbox.OnMouseEnter = function()
						X.OutputTip(this, m.szNameTip, true, X.UI.TIP_POSITION.TOP_BOTTOM)
					end
					checkbox.OnMouseLeave = function()
						X.HideTip()
					end
				end
				page.nIndex = i
			else
				X.UI.CloseFrame(frameTemp)
			end
		end
		ps.bInitPageSet = nil
	end

	function Exports.ActivePage(frame, szModule, bFirst)
		local ps = GetPageSet(frame)
		if not ps then
			return
		end
		local pageActive = ps:GetActivePage()
		local nActiveIndex, nToIndex = pageActive.nIndex, nil
		for i, m in ipairs(Modules) do
			if m.szKey == szModule or i == szModule then
				nToIndex = i
			end
		end
		if bFirst and not nToIndex then
			nToIndex = 1
		end
		if nToIndex then
			if nToIndex == nActiveIndex then
				X.SafeCallWithThis(ps, PageSetEvent.OnActivePage)
			else
				ps:ActivePage(nToIndex - 1)
			end
		end
	end

	function PageSetEvent.OnFrameCreate()
		Exports.DrawUI(this)
	end

	-- �㲥����ģ��
	function Exports.BroadcastPageEvent(frame, szEvent, ...)
		local ps = frame:Lookup(szPageSetPath)
		if ps then
			local page = ps:GetFirstChild()
			while page do
				if page:GetName() == 'Page_Default' and page.bInit then
					local m = Modules[page.nIndex]
					if m and m.tModule[szEvent] then
						X.SafeCallWithThis(page, m.tModule[szEvent], ...)
					end
				end
				page = page:GetNext()
			end
		end
	end

	-- ȫ�ֹ㲥ģ���¼�
	for _, szEvent in ipairs({
		'OnFrameCreate',
		'OnFrameDestroy',
		'OnFrameBreathe',
		'OnFrameRender',
		'OnFrameDragEnd',
		'OnFrameDragSetPosEnd',
		'OnEvent',
	}) do
		local fnOriginAction = NS[szEvent]
		NS[szEvent] = function(...)
			-- �㲥����ģ��
			local ps = this:Lookup(szPageSetPath)
			if ps then
				local page = ps:GetFirstChild()
				while page do
					if page:GetName() == 'Page_Default' and page.bInit then
						local m = Modules[page.nIndex]
						if m and m.tModule[szEvent] then
							X.SafeCallWithThis(page, m.tModule[szEvent], ...)
						end
					end
					page = page:GetNext()
				end
			end
			-- �㲥�� PageSet ����
			if PageSetEvent[szEvent] then
				PageSetEvent[szEvent](...)
			end
			-- �㲥��ԭʼ�¼�
			if fnOriginAction then
				fnOriginAction(...)
			end
		end
	end

	function PageSetEvent.OnActivePage()
		if this:GetRoot():Lookup(szPageSetPath) == this then
			local ps = this
			if ps.bInitPageSet then
				return
			end
			local page = ps:GetActivePage()
			if page.nIndex then
				local m = Modules[page.nIndex]
				if not page.bInit then
					if m and m.tModule.OnInitPage then
						X.SafeCallWithThis(page, m.tModule.OnInitPage)
					end
					page.bInit = true
				end
				if m and m.tModule.OnActivePage then
					X.SafeCallWithThis(page, m.tModule.OnActivePage)
				end
			end
		end
	end

	-- ����Ԫ��λ��ת����Ӧģ���¼�
	for _, szEvent in ipairs({
		'OnSetFocus',
		'OnKillFocus',
		'OnItemLButtonDown',
		'OnItemMButtonDown',
		'OnItemRButtonDown',
		'OnItemLButtonUp',
		'OnItemMButtonUp',
		'OnItemRButtonUp',
		'OnItemLButtonClick',
		'OnItemMButtonClick',
		'OnItemRButtonClick',
		'OnItemMouseEnter',
		'OnItemMouseLeave',
		'OnItemRefreshTip',
		'OnItemMouseWheel',
		'OnItemLButtonDrag',
		'OnItemLButtonDragEnd',
		'OnLButtonDown',
		'OnLButtonUp',
		'OnLButtonClick',
		'OnLButtonHold',
		'OnMButtonDown',
		'OnMButtonUp',
		'OnMButtonClick',
		'OnMButtonHold',
		'OnRButtonDown',
		'OnRButtonUp',
		'OnRButtonClick',
		'OnRButtonHold',
		'OnMouseEnter',
		'OnMouseLeave',
		'OnScrollBarPosChanged',
		'OnEditChanged',
		'OnEditSpecialKeyDown',
		'OnCheckBoxCheck',
		'OnCheckBoxUncheck',
		'OnActivePage',
	}) do
		local fnOriginAction = NS[szEvent]
		NS[szEvent] = function(...)
			-- ת������ģ��
			local ps = this:GetRoot():Lookup(szPageSetPath)
			if ps then
				local page = this
				while page and page:GetParent() ~= ps do
					page = page:GetParent()
				end
				if page and this ~= page then
					local m = Modules[page.nIndex]
					if m and m.tModule[szEvent] then
						return m.tModule[szEvent](...)
					end
					return
				end
			end
			-- ת���� PageSet ����
			if PageSetEvent[szEvent] and this == ps then
				return PageSetEvent[szEvent](...)
			end
			-- ת����ԭʼ�¼�
			if fnOriginAction then
				return fnOriginAction(...)
			end
		end
	end

	return Exports
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
