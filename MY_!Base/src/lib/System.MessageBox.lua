--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤����
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.MessageBox')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do -- ���η�װ MessageBox ����¼�
local function OnMessageBoxOpen()
	local szName, frame, aMsg = arg0, arg1, {}
	if not frame then
		return
	end
	local wndAll = frame:Lookup('Wnd_All')
	if not wndAll then
		return
	end
	for i = 1, 5 do
		local btn = wndAll:Lookup('Btn_Option' .. i)
		if btn and btn.IsVisible and btn:IsVisible() then
			local nIndex, szOption = btn.nIndex, btn.szOption
			if btn.fnAction then
				HookTableFunc(btn, 'fnAction', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			if btn.fnCountDownEnd then
				HookTableFunc(btn, 'fnCountDownEnd', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'TIME_OUT', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			aMsg[i] = { nIndex = nIndex, szOption = szOption }
		end
	end

	HookTableFunc(frame, 'fnAction', function(i)
		local msg = aMsg[i]
		if not msg then
			return
		end
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', msg.szOption, msg.nIndex)
	end, { bAfterOrigin = true })

	HookTableFunc(frame, 'fnCancelAction', function()
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'CANCEL')
	end, { bAfterOrigin = true })

	if frame.fnAutoClose then
		HookTableFunc(frame, 'fnAutoClose', function()
			FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'AUTO_CLOSE')
		end, { bAfterOrigin = true })
	end

	FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_OPEN'), arg0, arg1)
end
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', OnMessageBoxOpen)
end

-- �����Ի���
-- X.MessageBox([szKey, ]tMsg)
-- X.MessageBox([szKey, ]tMsg)
-- 	@param szKey {string} Ψһ��ʶ���������Զ�����
-- 	@param tMsg {object} ����μ��ٷ� MessageBox �ĵ�
-- 	@param tMsg.fnCancelAction {function} ESC �رջص����ɴ��롰FORBIDDEN����ֹ�ֶ��ر�
-- 	@return {string} Ψһ��ʶ��
function X.MessageBox(szKey, tMsg)
	if X.IsTable(szKey) then
		szKey, tMsg = nil, szKey
	end
	if not szKey then
		szKey = X.GetUUID():gsub('-', '')
	end
	tMsg.szName = X.NSFormatString('{$NS}_MessageBox#') .. GetStringCRC(szKey)
	if not tMsg.x or not tMsg.y then
		local nW, nH = Station.GetClientSize()
		tMsg.x = nW / 2
		tMsg.y = nH / 3
	end
	if not tMsg.szAlignment then
		tMsg.szAlignment = 'CENTER'
	end
	if tMsg.fnCancelAction == 'FORBIDDEN' then
		tMsg.fnCancelAction = function()
			X.DelayCall(function()
				X.MessageBox(szKey, tMsg)
			end)
		end
	end
	MessageBox(tMsg)
	return szKey
end

-- �����Ի��� - ����ťȷ��
-- X.Alert([szKey, ]szMsg[, fnResolve])
-- X.Alert([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} Ψһ��ʶ���������Զ�����
-- 	@param szMsg {string} ����
-- 	@param tOpt.x {number} ����λ��x����
-- 	@param tOpt.y {number} ����λ��y����
-- 	@param tOpt.szResolve {string} ��ť�İ�
-- 	@param tOpt.fnResolve {function} ��ť�ص�
-- 	@param tOpt.nResolveCountDown {number} ȷ����ť����ʱ
-- 	@param tOpt.fnCancel {function} ESC �رջص����ɴ��롰FORBIDDEN����ֹ�ֶ��ر�
-- 	@return {string} Ψһ��ʶ��
function X.Alert(szKey, szMsg, fnResolve)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve = nil, szKey, szMsg
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = { fnResolve = fnResolve }
	end
	return X.MessageBox(szKey, {
		x = tOpt.x, y = tOpt.y,
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		fnAutoClose = tOpt.fnAutoClose,
		{
			szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE,
			fnAction = tOpt.fnResolve,
			bDelayCountDown = tOpt.nResolveCountDown and true or false,
			nCountDownTime = tOpt.nResolveCountDown,
		},
	})
end

-- �����Ի��� - ˫��ť����ȷ��
-- X.Confirm([szKey, ]szMsg[, fnResolve[, fnReject[, fnCancel]]])
-- X.Confirm([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} Ψһ��ʶ���������Զ�����
-- 	@param szMsg {string} ����
-- 	@param tOpt.x {number} ����λ��x����
-- 	@param tOpt.y {number} ����λ��y����
-- 	@param tOpt.szResolve {string} ȷ����ť�İ�
-- 	@param tOpt.fnResolve {function} ȷ���ص�
-- 	@param tOpt.szReject {string} ȡ����ť�İ�
-- 	@param tOpt.fnReject {function} ȡ���ص�
-- 	@param tOpt.fnCancel {function} ESC �رջص����ɴ��롰FORBIDDEN����ֹ�ֶ��ر�
-- 	@return {string} Ψһ��ʶ��
function X.Confirm(szKey, szMsg, fnResolve, fnReject, fnCancel)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve, fnReject = nil, szKey, szMsg, fnResolve
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = {
			fnResolve = fnResolve,
			fnReject = fnReject,
			fnCancel = fnCancel,
		}
	end
	return X.MessageBox(szKey, {
		x = tOpt.x, y = tOpt.y,
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		fnAutoClose = tOpt.fnAutoClose,
		{ szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE, fnAction = tOpt.fnResolve },
		{ szOption = tOpt.szReject or g_tStrings.STR_HOTKEY_CANCEL, fnAction = tOpt.fnReject },
	})
end

-- �����Ի��� - �Զ��尴ť
-- X.Dialog([szKey, ]szMsg[, aOptions[, fnCancelAction]])
-- X.Dialog([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} Ψһ��ʶ���������Զ�����
-- 	@param szMsg {string} ����
-- 	@param tOpt.aOptions {array} ��ť�б��μ� MessageBox �÷�
-- 	@param tOpt.fnCancelAction {function} ESC �رջص����ɴ��롰FORBIDDEN����ֹ�ֶ��ر�
-- 	@return {string} Ψһ��ʶ��
function X.Dialog(szKey, szMsg, aOptions, fnCancelAction)
	if not X.IsString(szMsg) then
		szKey, szMsg, aOptions, fnCancelAction = nil, szKey, szMsg, aOptions
	end
	local tMsg = {
		szMessage = szMsg,
		fnCancelAction = fnCancelAction,
	}
	for i, p in ipairs(aOptions) do
		local tOption = {
			szOption = p.szOption,
			fnAction = p.fnAction,
		}
		if not tOption.szOption then
			if i == 1 then
				tOption.szOption = g_tStrings.STR_HOTKEY_SURE
			elseif i == #aOptions then
				tOption.szOption = g_tStrings.STR_HOTKEY_CANCEL
			end
		end
		table.insert(tMsg, tOption)
	end
	return X.MessageBox(szKey, tMsg)
end

function X.DoMessageBox(szName, i)
	local frame = Station.Lookup('Topmost2/MB_' .. szName) or Station.Lookup('Topmost/MB_' .. szName)
	if frame then
		i = i or 1
		local btn = frame:Lookup('Wnd_All/Btn_Option' .. i)
		if btn and btn:IsEnabled() then
			if btn.fnAction then
				if frame.args then
					btn.fnAction(X.Unpack(frame.args))
				else
					btn.fnAction()
				end
			elseif frame.fnAction then
				if frame.args then
					frame.fnAction(i, X.Unpack(frame.args))
				else
					frame.fnAction(i)
				end
			end
			frame.OnFrameDestroy = nil
			CloseMessageBox(szName)
		end
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
