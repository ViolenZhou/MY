--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ������
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Distance')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local O = X.CreateUserSettingsModule('LIB', _L['System'], {
	szDistanceType = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.OneOf('gwwean', 'euclidean','plane'),
		xDefaultValue = 'gwwean',
	},
})
function X.GetGlobalDistanceType()
	return O.szDistanceType
end

function X.SetGlobalDistanceType(szType)
	O.szDistanceType = szType
end

function X.GetDistanceTypeList(bGlobal)
	local t = {
		{ szType = 'gwwean', szText = _L.DISTANCE_TYPE['gwwean'] },
		{ szType = 'euclidean', szText = _L.DISTANCE_TYPE['euclidean'] },
		{ szType = 'plane', szText = _L.DISTANCE_TYPE['plane'] },
	}
	if (bGlobal) then
		table.insert(t, { szType = 'global', szText = _L.DISTANCE_TYPE['global'] })
	end
	return t
end

function X.GetDistanceTypeMenu(bGlobal, eValue, fnAction)
	local t = {}
	for _, p in ipairs(X.GetDistanceTypeList(true)) do
		local t1 = {
			szOption = p.szText,
			bCheck = true, bMCheck = true,
			bChecked = p.szType == eValue,
			UserData = p,
			fnAction = fnAction,
		}
		if p.szType == 'global' then
			t1.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t1.nFrame = 105
			t1.nMouseOverFrame = 106
			t1.szLayer = 'ICON_RIGHTMOST'
			t1.fnClickIcon = function()
				X.ShowPanel()
				X.SwitchTab('GlobalConfig')
				X.UI.ClosePopupMenu()
			end
		end
		table.insert(t, t1)
	end
	return t
end
end

-- ��ȡ����3D�����֮��ľ���
---@param nX1 userdata @��1��X����
---@param nY1 userdata @��1��Y����
---@param nZ1 userdata @��1��Z����
---@param nX2 userdata @��2��X����
---@param nY2 userdata @��2��Y����
---@param nZ2 userdata @��2��Z����
---@param szType? string @������㷽ʽ��'euclidean': ŷ�Ͼ��� (default)�� 'plane': ƽ����룻 'gwwean': ���Ͼ��룻 'global': ʹ��ȫ�����ã�
---@return number @���������
function X.Get3DPointDistance(nX1, nY1, nZ1, nX2, nY2, nZ2, szType)
	if not szType or szType == 'global' then
		szType = X.GetGlobalDistanceType()
	end
	if szType == 'plane' then
		return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64
	end
	if szType == 'gwwean' then
		return math.max(math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2) ^ 0.5) / 64, math.floor(math.abs(nZ1 / 8 - nZ2 / 8)) / 64)
	end
	return math.floor(((nX1 - nX2) ^ 2 + (nY1 - nY2) ^ 2 + (nZ1 / 8 - nZ2 / 8) ^ 2) ^ 0.5) / 64
end

-- ��ȡ����2D�����֮��ľ���
---@param nX1 userdata @��1��X����
---@param nY1 userdata @��1��Y����
---@param nX2 userdata @��2��X����
---@param nY2 userdata @��2��Y����
---@param szType? string @������㷽ʽ��'euclidean': ŷ�Ͼ��� (default)�� 'plane': ƽ����룻 'gwwean': ���Ͼ��룻 'global': ʹ��ȫ�����ã�
---@return number @���������
function X.Get2DPointDistance(nX1, nY1, nX2, nY2, szType)
	return X.Get3DPointDistance(nX1, nY1, 0, nX2, nY2, 0, szType)
end

-- ��ȡ����Ŀ��֮��ľ���
---@param kTar1 userdata @Ŀ��1
---@param kTar2 userdata @Ŀ��2
---@param szType? string @������㷽ʽ��'euclidean': ŷ�Ͼ��� (default)�� 'plane': ƽ����룻 'gwwean': ���Ͼ��룻 'global': ʹ��ȫ�����ã�
---@return number @���������
function X.GetCharacterDistance(kTar1, kTar2, szType)
	return X.Get3DPointDistance(kTar1.nX, kTar1.nY, kTar1.nZ, kTar2.nX, kTar2.nY, kTar2.nZ, szType)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
