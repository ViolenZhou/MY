--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Achievement')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- ��ȡ�ɾͻ�����Ϣ
function X.GetAchievement(dwAchieveID)
	local Achievement = X.GetGameTable('Achievement', true)
	if Achievement then
		return Achievement:Search(dwAchieveID)
	end
end

-- ��ȡ�ɾ�������Ϣ
function X.GetAchievementInfo(dwAchieveID)
	local AchievementInfo = X.GetGameTable('AchievementInfo', true)
	if AchievementInfo then
		return AchievementInfo:Search(dwAchieveID)
	end
end

-- ��ȡһ����ͼ�ĳɾ��б������Ƿ������ף�
local MAP_ACHI_NORMAL, MAP_ACHI_ALL
function X.GetMapAchievements(dwMapID, bWujia)
	if not MAP_ACHI_NORMAL then
		local tMapAchiNormal, tMapAchiAll = {}, {}
		local Achievement = not X.ENVIRONMENT.RUNTIME_OPTIMIZE and X.GetGameTable('Achievement', true)
		if Achievement then
			local nCount = Achievement:GetRowCount()
			for i = 2, nCount do
				local tLine = Achievement:GetRow(i)
				if tLine and tLine.nVisible == 1 then
					for _, szID in ipairs(X.SplitString(tLine.szSceneID, '|', true)) do
						local dwID = tonumber(szID)
						if dwID then
							if tLine.dwGeneral == 1 then
								if not tMapAchiNormal[dwID] then
									tMapAchiNormal[dwID] = {}
								end
								table.insert(tMapAchiNormal[dwID], tLine.dwID)
							end
							if not tMapAchiAll[dwID] then
								tMapAchiAll[dwID] = {}
							end
							table.insert(tMapAchiAll[dwID], tLine.dwID)
						end
					end
				end
			end
		end
		MAP_ACHI_NORMAL, MAP_ACHI_ALL = tMapAchiNormal, tMapAchiAll
	end
	if bWujia then
		return X.Clone(MAP_ACHI_ALL[dwMapID])
	end
	return X.Clone(MAP_ACHI_NORMAL[dwMapID])
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
