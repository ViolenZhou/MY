--------------------------------------------------------------------------------
-- v is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �ŶӼ�ؿ��ٺϲ��������ݵ���
-- @author   : ���� @˫���� @׷����Ӱ
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_Subscribe_MergeDataSlice'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {}

function D.OpenPanel(szModule)
	GetUserInput(
		_L['Please input data slice id:'],
		function(szText)
			if X.IsEmpty(szText) then
				return
			end
			X.Ajax({
				url = MY_RSS.PULL_BASE_URL .. '/api/addon/team-monitor/slice',
				data = {
					l = X.ENVIRONMENT.GAME_LANG,
					L = X.ENVIRONMENT.GAME_EDITION,
					uuid = szText,
				},
				success = function(szHTML)
					local res = X.DecodeJSON(szHTML)
					if not X.IsTable(res) then
						X.Systopmsg(_L['Invalid data slice data response.'])
						return
					end
					if not res.code == 0 then
						X.Systopmsg(X.ReplaceSensitiveWord(res.msg) or _L['Invalid data slice data response.'])
						return
					end
					if not X.IsTable(res.data)
					or not X.IsString(res.data.title)
					or not X.IsString(res.data.desc)
					or not X.IsString(res.data.type)
					or not X.IsString(res.data.szName)
					or not X.IsString(res.data.created_at)
					or not X.IsString(res.data.updated_at)
					or not X.IsString(res.data.lua) then
						X.Systopmsg(_L['Invalid data slice data response.'])
						return
					end
					local data = X.DecodeLUAData(res.data.lua)
					if not data then
						X.Systopmsg(_L['Invalid data slice data response payload.'])
						return
					end
					X.Confirm(
						_L(
							'Sure to merge this data? conflict item will be overwritten.\n\nTitle: %s\nDesc: %s\nType: %s\nRecord Name: %s\nCreate at: %s\nUpdate at: %s',
							res.data.title,
							res.data.desc,
							_L[res.data.type],
							res.data.szName,
							res.data.created_at,
							res.data.updated_at
						),
						function()
							MY_TeamMon.ImportData(
								data,
								nil,
								'MERGE_OVERWRITE',
								function(bSuccess)
									if bSuccess then
										X.Systopmsg(_L['Load data slice success.'])
										X.Sysmsg(_L('Load data slice [%s] success.', res.data.title))
									else
										X.Systopmsg(_L['Load data slice failed.'])
									end
								end
							)
						end
					)
				end,
			})
		end,
		nil, nil, nil, '')
end

--------------------------------------------------------
-- Global exports
--------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_Subscribe_MergeDataSlice',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenPanel',
			},
			root = D,
		},
	},
}
MY_TeamMon_Subscribe_MergeDataSlice = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
