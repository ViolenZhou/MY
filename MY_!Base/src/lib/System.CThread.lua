--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ϵͳ�����⡤���̶߳�д
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.CThread')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ���߳�ʵʱ��ȡĿ�����λ��
-- ע�᣺X.CThreadCoor(dwType, dwID, szKey, true)
-- ע����X.CThreadCoor(dwType, dwID, szKey, false)
-- ��ȡ��X.CThreadCoor(dwType, dwID) -- ������ע����ܻ�ȡ
-- ע�᣺X.CThreadCoor(dwType, nX, nY, nZ, szKey, true)
-- ע����X.CThreadCoor(dwType, nX, nY, nZ, szKey, false)
-- ��ȡ��X.CThreadCoor(dwType, nX, nY, nZ) -- ������ע����ܻ�ȡ
do
local CACHE = {}
function X.CThreadCoor(arg0, arg1, arg2, arg3, arg4, arg5)
	local dwType, dwID, nX, nY, nZ, szCtcKey, szKey, bReg = arg0, nil, nil, nil, nil, nil, nil, nil
	if dwType == CTCT.CHARACTER_TOP_2_SCREEN_POS or dwType == CTCT.CHARACTER_POS_2_SCREEN_POS or dwType == CTCT.DOODAD_POS_2_SCREEN_POS then
		dwID, szKey, bReg = arg1, arg2, arg3
		szCtcKey = dwType .. '_' .. dwID
	elseif dwType == CTCT.SCENE_2_SCREEN_POS or dwType == CTCT.GAME_WORLD_2_SCREEN_POS then
		nX, nY, nZ, szKey, bReg = arg1, arg2, arg3, arg4, arg5
		szCtcKey = dwType .. '_' .. nX .. '_' .. nY .. '_' .. nZ
	end
	if szKey then
		if bReg then
			if not CACHE[szCtcKey] then
				local cache = { keys = {} }
				if dwID then
					cache.ctcid = CThreadCoor_Register(dwType, dwID)
				else
					cache.ctcid = CThreadCoor_Register(dwType, nX, nY, nZ)
				end
				CACHE[szCtcKey] = cache
			end
			CACHE[szCtcKey].keys[szKey] = true
		else
			local cache = CACHE[szCtcKey]
			if cache then
				cache.keys[szKey] = nil
				if not next(cache.keys) then
					CThreadCoor_Unregister(cache.ctcid)
					CACHE[szCtcKey] = nil
				end
			end
		end
	else
		local cache = CACHE[szCtcKey]
		--[[#DEBUG BEGIN]]
		if not cache then
			X.OutputDebugMessage(X.NSFormatString('{$NS}#SYS'), _L('Error: `%s` has not be registed!', szCtcKey), X.DEBUG_LEVEL.ERROR)
		end
		--[[#DEBUG END]]
		return CThreadCoor_Get(cache.ctcid) -- nX, nY, bFront
	end
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
