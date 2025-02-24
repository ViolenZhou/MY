--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : �����������ɴ���
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/LoadingEnd')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local PROXY = X.NSLock(X, X.NSFormatString('{$NS} (base library)'))
if IsDebugClient() then
function PROXY.DebugSetVal(szKey, oVal)
	PROXY[szKey] = oVal
end
end
FireUIEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'))

X.RegisterInit(X.NSFormatString('{$NS}#AUTHOR_TIP'), function()
	local Farbnamen = _G.MY_Farbnamen
	if not Farbnamen then
		return
	end
	for _, v in ipairs(X.PACKET_INFO.AUTHOR_ROLE_LIST) do
		if v.szName and v.dwID and v.szHeader and Farbnamen.RegisterNameIDHeader then
			Farbnamen.RegisterNameIDHeader(v.szName, v.dwID, v.szHeader)
		end
		if v.szGlobalID and v.szHeader and Farbnamen.RegisterGlobalIDHeader then
			Farbnamen.RegisterGlobalIDHeader(v.szGlobalID, v.szHeader)
		end
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
