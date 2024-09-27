--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Macro')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local MACRO_ACTION_DATATYPE = {
	['cast'] = 'SKILL',
	['fcast'] = 'SKILL',
}
local MACRO_CONDITION_DATATYPE = {
	['buff'] = 'BUFF',
	['nobuff'] = 'BUFF',
	['bufftime'] = 'BUFF',
	['life'] = 'VOID',
	['mana'] = 'VOID',
	['rage'] = 'VOID',
	['qidian'] = 'VOID',
	['energy'] = 'VOID',
	['sun'] = 'VOID',
	['moon'] = 'VOID',
	['sun_power'] = 'VOID',
	['moon_power'] = 'VOID',
	['skill_energy'] = 'SKILL',
	['skill'] = 'SKILL',
	['noskill'] = 'SKILL',
	['npclevel'] = 'VOID',
	['nearby_enemy'] = 'VOID',
	['yaoxing'] = 'VOID',
	['skill_notin_cd'] = 'SKILL',
	['tbuff'] = 'BUFF',
	['tnobuff'] = 'BUFF',
	['tbufftime'] = 'BUFF',
}
function X.IsMacroValid(szMacro)
	-- /cast [nobuff:̫��] ̫���޼�
	local bDebug = X.IsDebugging(X.NSFormatString('{$NS}_Macro'))
	for nLine, szLine in ipairs(X.SplitString(szMacro, '\n')) do
		szLine = X.TrimString(szLine)
		if not X.IsEmpty(szLine) then
			-- ��� /����ָ�� [����] ����ָ�����
			local szAction, szCondition, szActionData = szLine:match('^/([a-zA-Z_]+)%s*%[([^%]]+)%]%s*(.-)%s*$')
			if not szAction then
				szAction, szActionData = szLine:match('^/([a-zA-Z_]+)%s+(.-)%s*$')
				szCondition = ''
			end
			-- У�鶯��ָ��
			if not szAction then
				local szErrMsg = _L('Syntax error at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szLine .. '}'
				end
				return false, 'SYNTAX_ERROR', nLine, szErrMsg
			end
			local szActionType = MACRO_ACTION_DATATYPE[szAction]
			if not szActionType then
				local szErrMsg = _L('Unknown action at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szAction .. '}'
				end
				return false, 'UNKNOWN_ACTION', nLine, szErrMsg
			end
			-- У�鶯��ָ�����
			if szActionType == 'SKILL' and not tonumber(szActionData) and not X.GetSkillByName(szActionData) then
				local szErrMsg = _L('Unknown action skill at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_SKILL', nLine, szErrMsg
			elseif szActionType == 'BUFF' and not tonumber(szActionData) and not X.GetBuffByName(szActionData) then
				local szErrMsg = _L('Unknown action buff at line %d', nLine)
				if bDebug then
					szErrMsg = szErrMsg .. '{' .. szActionData .. '}'
				end
				return false, 'UNKNOWN_ACTION_BUFF', nLine, szErrMsg
			end
			-- У������
			for _, szSubCondition in ipairs(X.SplitString(szCondition, {'|', '&'}, true)) do
				-- last_skill~=����ع��
				-- moon>sun
				-- sun<10
				-- life<0.3
				-- bufftime:̫��<4.1
				-- tbuff:��Ѫ
				-- У�顾����ָ��:����ָ�����(��ѡ��ֵ�Ƚ�)������
				local szJudge, szJudgeData = szSubCondition:match('^([a-zA-Z_]+)%s*%:%s*([^<>~=]+)%s*[<>~=]*%s*[0-9.]*$')
				if not szJudge then
					szJudge, szJudgeData = szSubCondition:match('^([a-zA-Z_]+)%s*[<>~=]*%s*[0-9.%s]*$'), ''
				end
				if szJudge and szJudge ~= 'last_skill' then
					local szJudgeType = MACRO_CONDITION_DATATYPE[szJudge]
					if not szJudgeType then
						local szErrMsg = _L('Unknown condition at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudge .. '}'
						end
						return false, 'UNKNOWN_CONDITION', nLine, szErrMsg
					end
					if szJudgeType == 'SKILL' and not tonumber(szJudgeData) and not X.GetSkillByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition skill at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_CONDITION_SKILL', nLine, szErrMsg
					elseif szJudgeType == 'BUFF' and not tonumber(szJudgeData) and not X.GetBuffByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition buff at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_CONDITION_BUFF', nLine, szErrMsg
					end
				elseif not szSubCondition:match('moon[<>=%s]+sun') and not szSubCondition:match('sun[<>=%s]+moon') then
					szJudge, szJudgeData = szSubCondition:match('^(last_skill)[=~%s]+([^<>=~]+)$')
					if not szJudge then
						local szErrMsg = _L('Unknown condition at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szSubCondition .. '}'
						end
						return false, 'UNKNOWN_CONDITION', nLine, szErrMsg
					end
					if szJudge and not tonumber(szJudgeData) and not X.GetSkillByName(szJudgeData) then
						local szErrMsg = _L('Unknown condition skill at line %d', nLine)
						if bDebug then
							szErrMsg = szErrMsg .. '{' .. szJudgeData .. '}'
						end
						return false, 'UNKNOWN_ACTION_SKILL', nLine, szErrMsg
					end
				end
			end
		end
	end
	return true
end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
