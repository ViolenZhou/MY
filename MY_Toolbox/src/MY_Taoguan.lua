--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : �Զ��������չ�
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Toolbox/MY_Taoguan'
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Taoguan'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^15.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
-- �������� -- ��һ����һ���屶�������������չ�
-- ���˽��� -- ��һ���������չ�ʧ������������ɻ���
-- �������� -- ��һ���������屶�������������չ�
-- ������� -- ��һ���������չ�ʧ������һ�����
-- ���ǹ� -- ��һ�����屶�������������չ�
-- ���� -- ��һ���������չ�ʧ������ʧ����

local FILTER_ITEM = {}
do
	local data = X.LoadLUAData(PLUGIN_ROOT .. '/data/taoguan/{$lang}.jx3dat')
	if X.IsTable(data.FILTER_ITEM) then
		FILTER_ITEM = data.FILTER_ITEM
	end
end
local FILTER_ITEM_DEFAULT = {}
for _, p in ipairs(FILTER_ITEM) do
	FILTER_ITEM_DEFAULT[p.szName] = p.bFilter
end

local O = X.CreateUserSettingsModule('MY_Taoguan', _L['Target'], {
	nPausePoint = { -- ͣ�ҷ�����
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 327680,
	},
	bUseTaoguan = { -- ��Ҫʱʹ�ñ������չ�
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bNoYinchuiUseJinchui = { -- ûС����ʱʹ��С��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nUseXiaojinchui = { -- ����ʹ��С�𴸵ķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 320,
	},
	bPauseNoXiaojinchui = { -- ȱ��С��ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nUseXingyunXiangnang = { -- ��ʼ���������ҵķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	bPauseNoXingyunXiangnang = { -- ȱ����������ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nUseXingyunJinnang = { -- ��ʼ�����˽��ҵķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	bPauseNoXingyunJinnang = { -- ȱ�����˽���ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nUseRuyiXiangnang = { -- ��ʼ���������ҵķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	bPauseNoRuyiXiangnang = { -- ȱ����������ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nUseRuyiJinnang = { -- ��ʼ��������ҵķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	bPauseNoRuyiJinnang = { -- ȱ���������ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nUseJiyougu = { -- ��ʼ�Լ��ǹȵķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1280,
	},
	bPauseNoJiyougu = { -- ȱ�ټ��ǹ�ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nUseZuisheng = { -- ��ʼ�������ķ���
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1280,
	},
	bPauseNoZuisheng = { -- ȱ������ʱͣ��
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	tFilterItem = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Taoguan'],
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = FILTER_ITEM_DEFAULT,
	},
})

---------------------------------------------------------------------
-- ���غ����ͱ���
---------------------------------------------------------------------
local TAOGUAN = X.GetItemNameByUIID(74224) -- �����չ�
local XIAOJINCHUI = X.GetItemNameByUIID(65611) -- С��
local XIAOYINCHUI = X.GetItemNameByUIID(65609) -- С����
local MEILIANGYUQIAN = X.GetItemNameByUIID(65589) -- ÷����ǩ
local XINGYUNXIANGNANG = X.GetItemNameByUIID(65578) -- ��������
local XINGYUNJINNANG = X.GetItemNameByUIID(65581) -- ���˽���
local RUYIXIANGNANG = X.GetItemNameByUIID(65579) -- ��������
local RUYIJINNANG = X.GetItemNameByUIID(65582) -- �������
local JIYOUGU = X.GetItemNameByUIID(65580) -- ���ǹ�
local ZUISHENG = X.GetItemNameByUIID(65583) -- ����
local ITEM_CD = 1 * X.ENVIRONMENT.GAME_FPS + 8 -- ��ҩCD
local HAMMER_CD = 5 * X.ENVIRONMENT.GAME_FPS + 8 -- ����CD
local MAX_POINT_POW = 16 -- ������߱�����2^n��

local D = {
	bEnable = false, -- ����״̬
	bWaitPoint = false, -- �ȴ�����ˢ�� ��ֹ���ҩƷ
	nPoint = 0, -- ��ǰ�ܷ���
	nUseItemLFC = 0, -- �ϴγ�ҩ���߼�֡
	nUseHammerLFC = 0, -- �ϴ��ô��ӵ��߼�֡
	dwDoodadID = 0, -- �Զ�ʰȡ���˵Ľ������ID
	aUseItemPS = { -- ���ý������Ʒʹ������
		{ szName = XIAOJINCHUI, szID = 'Xiaojinchui' },
		{ szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang' },
		{ szName = XINGYUNJINNANG, szID = 'XingyunJinnang' },
		{ szName = RUYIXIANGNANG, szID = 'RuyiXiangnang' },
		{ szName = RUYIJINNANG, szID = 'RuyiJinnang' },
		{ szName = JIYOUGU, szID = 'Jiyougu' },
		{ szName = ZUISHENG, szID = 'Zuisheng' },
	},
	aUseItemOrder = { -- ״̬ת�ƺ�������Ʒ��BUFF�ж��߼�
		{
			{ szName = JIYOUGU, szID = 'Jiyougu', dwBuffID = 1660, nBuffLevel = 3 },
			{ szName = RUYIXIANGNANG, szID = 'RuyiXiangnang', dwBuffID = 1660, nBuffLevel = 2 },
			{ szName = XINGYUNXIANGNANG, szID = 'XingyunXiangnang', dwBuffID = 1660, nBuffLevel = 1 },
		},
		{
			{ szName = ZUISHENG, szID = 'Zuisheng', dwBuffID = 1661, nBuffLevel = 3 },
			{ szName = RUYIJINNANG, szID = 'RuyiJinnang', dwBuffID = 1661, nBuffLevel = 2 },
			{ szName = XINGYUNJINNANG, szID = 'XingyunJinnang', dwBuffID = 1661, nBuffLevel = 1 },
		},
	},
}

-- ʹ�ñ�����Ʒ
function D.UseBagItem(szName, bWarn)
	local me = X.GetClientPlayer()
	for i = 1, 6 do
		for j = 0, me.GetBoxSize(i) - 1 do
		local it = GetPlayerItem(me, i, j)
			if it and it.szName == szName then
				--[[#DEBUG BEGIN]]
				X.Debug('MY_Taoguan', 'UseItem: ' .. i .. ',' .. j .. ' ' .. szName, X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				OnUseItem(i, j)
				return true
			end
		end
	end
	if bWarn then
		X.Systopmsg(_L('Auto taoguan: missing [%s]!', szName))
	end
end

-- �ҹ���״̬��ת�ƺ���
function D.BreakCanStateTransfer()
	local me = X.GetClientPlayer()
	if not me or not D.bEnable then
		return
	end
	local nLFC = GetLogicFrameCount()
	-- ȷ�ϵ��ҽ�ȷ�Ͽ�
	X.DoMessageBox('PlayerMessageBoxCommon')
	-- ��ҩ����CD��ȴ�
	if nLFC - D.nUseItemLFC < ITEM_CD then
		return
	end
	-- ����ҩBUFF�������
	for _, aItem in ipairs(D.aUseItemOrder) do
		-- ÿ���������ȼ�˳����
		for _, item in ipairs(aItem) do
			-- ���ϳ�ҩ��������
			if D.nPoint >= O['nUse' .. item.szID] then
				-- ����Ѿ���BUFF�����Թ�ҩ�ˣ�������ѭ��
				if X.GetBuff(me, item.dwBuffID, item.nBuffLevel) then
					break
				end
				-- �����Գ�ҩ
				if D.UseBagItem(item.szName, O['bPauseNo' .. item.szID]) then
					D.nUseItemLFC = nLFC
					-- �Գɹ��ˣ��ȴ��´�״̬��ת�ƺ�������
					return
				end
				if O['bPauseNo' .. item.szID] then
					-- ��ʧ���ˣ���ͣ�ҹ���
					D.Stop()
					return
				end
			end
		end
	end
	-- ���ӻ���CD��ȴ�
	if nLFC - D.nUseHammerLFC < HAMMER_CD then
		return
	end
	-- Ѱ�����ҵ��չ�
	local npcTaoguan
	for _, npc in ipairs(X.GetNearNpc()) do
		if npc and npc.dwTemplateID == 6820 then
			if X.GetDistance(npc) < 4 then
				npcTaoguan = npc
				break
			end
		end
	end
	-- û�����ҵ��չ޿����Լ���һ��
	if not npcTaoguan and O.bUseTaoguan then
		if D.UseBagItem(TAOGUAN) then
			D.nUseItemLFC = nLFC
		end
	end
	-- ����û���ҵ�������ȴ�
	if not npcTaoguan then
		return
	end
	-- �ҵ������ˣ���ΪĿ��
	X.SetTarget(TARGET.NPC, npcTaoguan.dwID)
	-- ��Ҫ��С�𴸣�����Ѿ��
	if D.nPoint >= O.nUseXiaojinchui then
		if D.UseBagItem(XIAOJINCHUI, O.bPauseNoXiaojinchui) then
			-- �ҳɹ��ˣ��ȴ���CD
			D.nUseHammerLFC = nLFC
			D.bWaitPoint = true
			return
		end
		if O.bPauseNoXiaojinchui then
			-- ��ʧ���ˣ���ͣ�ҹ���
			D.Stop()
			return
		end
	end
	-- ��Ҫ��С����������Ѿ��
	if D.UseBagItem(XIAOYINCHUI) then
		-- �ҳɹ��ˣ��ȴ���CD
		D.nUseHammerLFC = nLFC
		D.bWaitPoint = true
		return
	end
	-- û��С����ʱʹ��С�𴸣�
	if O.bNoYinchuiUseJinchui and D.UseBagItem(XIAOJINCHUI) then
		-- �ҳɹ��ˣ��ȴ���CD
		D.nUseHammerLFC = nLFC
		return
	end
	-- û�н�Ҳû������������ѽ
	D.UseBagItem(XIAOYINCHUI, true)
	D.Stop()
end

-------------------------------------
-- �¼�����
-------------------------------------
function D.MonitorZP(szChannel, szMsg)
	local _, _, nP = string.find(szMsg, _L['Current total score:(%d+)'])
	if nP then
		D.nPoint = tonumber(nP)
		if D.nPoint >= O.nPausePoint then
			D.Stop()
			D.bReachLimit = true
			X.Systopmsg(_L['Auto taoguan: reach limit!'])
		end
		D.bWaitPoint = false
		D.nUseHammerLFC = GetLogicFrameCount()
	end
end

function D.OnLootItem()
	if arg0 == X.GetClientPlayer().dwID and arg2 > 2 and GetItem(arg1).szName == MEILIANGYUQIAN then
		D.nPoint = 0
		D.bWaitPoint = false
		X.Systopmsg(_L['Auto taoguan: score clear!'])
	end
end

function D.OnDoodadEnter()
	if D.bEnable or D.bReachLimit then
		local d = X.GetDoodad(arg0)
		if d and d.szName == TAOGUAN and d.CanDialog(X.GetClientPlayer())
			and X.GetDistance(d) < 4.1
		then
			D.dwDoodadID = arg0
			X.DelayCall(520, function()
				X.InteractDoodad(D.dwDoodadID)
			end)
		end
	end
end

function D.OnOpenDoodad()
	if D.bEnable or D.bReachLimit then
		local d = X.GetDoodad(D.dwDoodadID)
		if d and d.szName == TAOGUAN then
			local nQ, nM, me = 1, d.GetLootMoney(), X.GetClientPlayer()
			if nM > 0 then
				LootMoney(d.dwID)
			end
			for i = 0, 31 do
				local it, bRoll, bDist = d.GetLootItem(i, me)
				if not it then
					break
				end
				local szName = GetItemNameByItem(it)
				if it.nQuality >= nQ and not bRoll and not bDist
					and not O.tFilterItem[szName]
				then
					LootItem(d.dwID, it.dwID)
				else
					X.Systopmsg(_L('Auto taoguan: filter item [%s].', szName))
				end
			end
			local hL = Station.Lookup('Normal/LootList', 'Handle_LootList')
			if hL then
				hL:Clear()
			end
		end
		D.bReachLimit = nil
	end
end

-- �ҹ��ӿ�ʼ��ע���¼���
function D.Start()
	if D.bEnable then
		return
	end
	D.bEnable = true
	D.bWaitPoint = false
	X.RegisterMsgMonitor('MSG_SYS', 'MY_Taoguan', D.MonitorZP)
	X.BreatheCall('MY_Taoguan', D.BreakCanStateTransfer)
	X.RegisterEvent('LOOT_ITEM', 'MY_Taoguan', D.OnLootItem)
	X.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Taoguan', D.OnDoodadEnter)
	X.RegisterEvent('HELP_EVENT', 'MY_Taoguan', function()
		if arg0 == 'OnOpenpanel' and arg1 == 'LOOT'
			and D.bEnable and D.dwDoodadID ~= 0
		then
			D.OnOpenDoodad()
			D.dwDoodadID = 0
		end
	end)
	X.Systopmsg(_L['Auto taoguan: on.'])
end

-- �ҹ��ӹرգ�ע���¼���
function D.Stop()
	if not D.bEnable then
		return
	end
	D.bEnable = false
	X.RegisterMsgMonitor('MSG_SYS', 'MY_Taoguan', false)
	X.BreatheCall('MY_Taoguan', false)
	X.RegisterEvent('NPC_ENTER_SCENE', 'MY_Taoguan', false)
	-- X.RegisterEvent('LOOT_ITEM', 'MY_Taoguan', false) -- ���������������ע���������´�����������ж�
	X.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_Taoguan', false)
	X.RegisterEvent('HELP_EVENT', 'MY_Taoguan', false)
	X.Systopmsg(_L['Auto taoguan: off.'])
end

-- �ҹ��ӿ���
function D.Switch()
	if D.bEnable then
		D.Stop()
	else
		D.Start()
	end
end

-------------------------------------
-- ���ý���
-------------------------------------
local PS = {}

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 20, 20
	local nX, nY = nPaddingX, nPaddingY

	ui:Append('Text', { text = _L['Feature setting'], x = nX, y = nY, font = 27 })

	-- �����ﵽ����ͣ��
	nX = nPaddingX + 10
	nY = nY + 28
	nX = ui:Append('Text', { text = _L['Stop simple broken can when score reaches'], x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = O.nPausePoint,
		menu = function()
			local ui = X.UI(this)
			local m0 = {}
			for i = 2, MAX_POINT_POW do
				local v = 10 * 2 ^ i
				table.insert(m0, { szOption = tostring(v), fnAction = function()
					O.nPausePoint = v
					ui:Text(tostring(v))
				end })
			end
			return m0
		end,
	}):Pos('BOTTOMRIGHT') + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Put can if needed?'],
		checked = O.bUseTaoguan,
		onCheck = function(bChecked) O.bUseTaoguan = bChecked end,
	}):AutoWidth()

	-- û��С����ʱʹ��С��
	-- nX = X + 10
	nY = nY + 28
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L('When no %s use %s?', XIAOYINCHUI, XIAOJINCHUI),
		checked = O.bNoYinchuiUseJinchui,
		onCheck = function(bChecked) O.bNoYinchuiUseJinchui = bChecked end,
	}):AutoWidth()

	-- ���ֶ���ʹ�÷�����ȱ��ͣ��
	local nMaxItemNameLen = 0
	for _, p in ipairs(D.aUseItemPS) do
		nMaxItemNameLen = math.max(nMaxItemNameLen, X.StringLenW(p.szName))
	end
	for _, p in ipairs(D.aUseItemPS) do
		nX = nPaddingX + 10
		nY = nY + 28
		nX = ui:Append('Text', {
			x = nX, y = nY,
			text = _L('Use %s when score reaches', p.szName .. string.rep(g_tStrings.STR_ONE_CHINESE_SPACE, nMaxItemNameLen - X.StringLenW(p.szName))),
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		nX = ui:Append('WndComboBox', {
			x = nX, y = nY, w = 100, h = 25,
			text = O['nUse' .. p.szID],
			menu = function()
				local ui = X.UI(this)
				local m0 = {}
				for i = 2, MAX_POINT_POW - 1 do
					local v = 10 * 2 ^ i
					table.insert(m0, { szOption = tostring(v), fnAction = function()
						O['nUse' .. p.szID] = v
						ui:Text(tostring(v))
					end })
				end
				return m0
			end,
		}):Pos('BOTTOMRIGHT') + 10
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			text = _L['Stop break when no item'],
			checked = O['bPauseNo' .. p.szID],
			onCheck = function(bChecked)
				O['bPauseNo' .. p.szID] = bChecked
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	end

	-- ʰȡ����
	nX = nPaddingX + 10
	nY = nY + 38
	nX = ui:Append('WndComboBox', {
		x = nX, y = nY, w = 150,
		text = _L['Pickup filters'],
		menu = function()
			local m0 = {}
			for _, p in ipairs(FILTER_ITEM) do
				table.insert(m0, {
					szOption = p.szName,
					bCheck = true, bChecked = O.tFilterItem[p.szName],
					fnAction = function(d, b)
						O.tFilterItem[p.szName] = b
						O.tFilterItem = O.tFilterItem
					end,
				})
			end
			for k, v in pairs(O.tFilterItem) do
				if FILTER_ITEM_DEFAULT[k] == nil then
					table.insert(m0, {
						szOption = k,
						bCheck = true, bChecked = v,
						fnAction = function(d, b)
							O.tFilterItem[k] = b
							O.tFilterItem = O.tFilterItem
						end,
						szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
						nFrame = 49,
						nMouseOverFrame = 51,
						nIconWidth = 17,
						nIconHeight = 17,
						szLayer = 'ICON_RIGHTMOST',
						fnClickIcon = function()
							O.tFilterItem[k] = nil
							O.tFilterItem = O.tFilterItem
							X.UI.ClosePopupMenu()
						end,
					})
				end
			end
			if #m0 > 0 then
				table.insert(m0, X.CONSTANT.MENU_DIVIDER)
			end
			table.insert(m0, {
				szOption = _L['Custom add'],
				fnAction = function()
					local function fnConfirm(szText)
						O.tFilterItem[szText] = true
						O.tFilterItem = O.tFilterItem
					end
					GetUserInput(_L['Please input custom name'], fnConfirm, nil, nil, nil, '', 20)
				end,
			})
			return m0
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	ui:Append('Text', { x = nX, y = nY, text = _L['(Checked will not be picked up, if still pick please check system auto pick config)'] })

	-- ���ư�ť
	nX = nPaddingX + 10
	nY = nY + 36
	nX = ui:Append('WndButton', {
		x = nX, y = nY, w = 130, h = 30,
		text = _L['Start/stop break can'],
		onClick = D.Switch,
	}):Pos('BOTTOMRIGHT') + 5
	nX = ui:Append('WndButton', {
		x = nX, y = nY, w = 130, h = 30,
		text = _L['Restore default config'],
		onClick = function()
			O('reset')
			X.SwitchTab('MY_Taoguan', true)
		end,
	}):Pos('BOTTOMRIGHT')
end
X.RegisterPanel(_L['Target'], 'MY_Taoguan', _L[MODULE_NAME], 119, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
