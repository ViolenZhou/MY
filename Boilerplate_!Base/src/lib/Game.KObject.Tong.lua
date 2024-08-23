--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.KObject.Tong')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ����Ա��ؽӿ�
--------------------------------------------------------------------------------

-- ��ȡ����Ա�б�
---@param bShowOffLine boolean @�Ƿ���ʾ���߳�Ա
---@param szSorter string @�����ֶ�
---@param bAsc boolean @�Ƿ���������
---@return table @����Ա�б�
function X.GetTongMemberInfoList(bShowOffLine, szSorter, bAsc)
	if bShowOffLine == nil then bShowOffLine = false  end
	if szSorter     == nil then szSorter     = 'name' end
	if bAsc         == nil then bAsc         = true   end
	local aSorter = {
		['name'  ] = 'name'                    ,
		['level' ] = 'group'                   ,
		['school'] = 'development_contribution',
		['score' ] = 'score'                   ,
		['map'   ] = 'join_time'               ,
		['remark'] = 'last_offline_time'       ,
	}
	szSorter = aSorter[szSorter]
	-- GetMemberList(bShowOffLine, szSorter, bAsc, nGroupFilter, -1) -- ��������������֪��ʲô��
	return GetTongClient().GetMemberList(bShowOffLine, szSorter or 'name', bAsc, -1, -1)
end

-- ��ȡ�������
---@param dwTongID number @���ID
---@param nGetType? number @0 ��ʾ�߼�ֱ������һ����ˢ��player����ͷ����ʾ, -1�����ϲ�����������¼�
---@return string @�������
function X.GetTongName(dwTongID, nGetType)
	local szTongName
	if X.IsNumber(dwTongID) and dwTongID > 0 then
		szTongName = GetTongClient().ApplyGetTongName(dwTongID, nGetType or 253)
	end
	return szTongName
end

-- ��ȡ����������
---@param nGetType? number @0 ��ʾ�߼�ֱ������һ����ˢ��player����ͷ����ʾ, -1�����ϲ�����������¼�
---@return string @�������
function X.GetClientPlayerTongName(nGetType)
	local dwTongID = (X.GetClientPlayer() or X.CONSTANT.EMPTY_TABLE).dwTongID
	return X.GetTongName(dwTongID, nGetType)
end

-- ��ȡ����Ա
---@param arg0 string | number @����ԱID������
---@return table @����Ա��Ϣ
function X.GetTongMemberInfo(arg0)
	if not arg0 then
		return
	end
	return GetTongClient().GetMemberInfo(arg0)
end

-- �ж��Ƿ��ǰ���Ա
---@param arg0 string | number @����ԱID������
---@return boolean @�Ƿ��ǰ���Ա
function X.IsTongMember(arg0)
	return X.GetTongMemberInfo(arg0) and true or false
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
