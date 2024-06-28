--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ��ƽѪ������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar_Config'
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
if not IsLocalFileExist(X.FormatPath({'config/restriction/lifebar.jx3dat', X.PATH_TYPE.GLOBAL})) then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local function SchemaRelationForce(itemschema)
	return X.Schema.Map(
		X.Schema.OneOf('Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe'),
		function(obj, path)
			if not X.IsTable(obj) then
				return X.Schema.Error('Invalid value: '..path..' must be table', path)
			end
			for k, v in pairs(obj) do
				path:push(k)
				if k == 'DifferentiateForce' then
					if not X.IsBoolean(v) then
						return X.Schema.Error('Invalid value: ' .. path .. ' must be boolean', path)
					end
				else
					local err = itemschema(v, path)
					if err then
						return err
					end
				end
				path:pop()
			end
			return nil
		end
	)
end
local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	eCss = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	fDesignUIScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nDesignFontOffset = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},

	nCamp = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = -1,
	},
	bOnlyInArena = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlyInDungeon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlyInBattleField = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},

	nTextOffsetY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 38,
	},
	nTextLineHeight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 20,
	},
	fTextScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 1.2,
	},
	fTextSpacing = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},

	bShowSpecialNpc = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowSpecialNpcOnlyEnemy = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowObjectID = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowObjectIDOnlyUnnamed = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowKungfu = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowDistanceOnlyTarget = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nDistanceDecimal = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},

	nLifeWidth = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 52,
	},
	nLifeHeight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	nLifePadding = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nLifeOffsetX = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nLifeOffsetY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 12,
	},
	nLifeBorder = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	nLifeBorderR = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nLifeBorderG = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nLifeBorderB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	szLifeDirection = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.String,
		xDefaultValue = 'LEFT_RIGHT',
	},

	nLifePerOffsetX = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nLifePerOffsetY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 8,
	},

	fTitleEffectScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0.7,
	},
	nTitleEffectOffsetY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nBalloonOffsetY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = -20,
	},

	nAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 255,
	},
	nFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 7,
	},
	nDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 80 * 80 * 64 * 64,
	},
	nVerticalDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 50 * 8 * 64,
	},

	bHideLifePercentageWhenFight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bHideLifePercentageDecimal = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},

	fGlobalUIScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	bSystemUIScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowWhenUIHide = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bMineOnTop = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bTargetOnTop = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bScreenPosSort = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},

	Color = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {
			Self = X.KvpToObject({ -- �Լ�
				{'DifferentiateForce', false},
				{'Player', { 26, 156, 227 }},
				{'Npc', { 26, 156, 227 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
			Party = X.KvpToObject({ -- �Ŷ�
				{'DifferentiateForce', false},
				{'Player', { 23, 133, 194 }},
				{'Npc', { 23, 133, 194 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
			Enemy = X.KvpToObject({ -- �ж�
				{'DifferentiateForce', false},
				{'Player', { 203, 53, 9 }},
				{'Npc', { 203, 53, 9 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
			Neutrality = X.KvpToObject({ -- ����
				{'DifferentiateForce', false},
				{'Player', { 238, 238, 15 }},
				{'Npc', { 238, 238, 15 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
			Ally = X.KvpToObject({ -- ��ͬ��Ӫ
				{'DifferentiateForce', false},
				{'Player', { 63 , 210, 94 }},
				{'Npc', { 63 , 210, 94 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
			Foe = X.KvpToObject({ -- ����
				{'DifferentiateForce', false},
				{'Player', { 197, 26, 201 }},
				{FORCE_TYPE.JIANG_HU , { 255, 255, 255 }}, -- ����
				{FORCE_TYPE.SHAO_LIN , { 255, 178, 95  }}, -- ����
				{FORCE_TYPE.WAN_HUA  , { 196, 152, 255 }}, -- ��
				{FORCE_TYPE.TIAN_CE  , { 255, 111, 83  }}, -- ���
				{FORCE_TYPE.CHUN_YANG, { 22 , 216, 216 }}, -- ���� 56,175,255
				{FORCE_TYPE.QI_XIU   , { 255, 129, 176 }}, -- ����
				{FORCE_TYPE.WU_DU    , { 55 , 147, 255 }}, -- �嶾
				{FORCE_TYPE.TANG_MEN , { 121, 183, 54  }}, -- ����
				{FORCE_TYPE.CANG_JIAN, { 214, 249, 93  }}, -- �ؽ�
				{FORCE_TYPE.GAI_BANG , { 205, 133, 63  }}, -- ؤ��
				{FORCE_TYPE.MING_JIAO, { 240, 70 , 96  }}, -- ����
				{FORCE_TYPE.CANG_YUN , { 180, 60 , 0   }}, -- ����
				{FORCE_TYPE.CHANG_GE , { 100, 250, 180 }}, -- ����
				{FORCE_TYPE.BA_DAO   , { 106, 108, 189 }}, -- �Ե�
			}),
		},
	},
	ShowName = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
			bOnlyFighting = X.Schema.Boolean,
			bHideInDungeon = X.Schema.Optional(X.Schema.Boolean),
			bHideFullLife = X.Schema.Optional(X.Schema.Boolean),
			bOnlyTarget = X.Schema.Optional(X.Schema.Boolean),
			bHidePets = X.Schema.Optional(X.Schema.Boolean),
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false },
			},
			Party = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false },
			},
			Enemy = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false },
			},
			Neutrality = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false },
			},
			Ally = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false },
			},
			Foe = { Player = { bEnable = true, bOnlyFighting = false } },
		},
	},
	ShowTong = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
			bOnlyFighting = X.Schema.Boolean,
			bHideInDungeon = X.Schema.Optional(X.Schema.Boolean),
			bHideFullLife = X.Schema.Optional(X.Schema.Boolean),
			bOnlyTarget = X.Schema.Optional(X.Schema.Boolean),
			bHidePets = X.Schema.Optional(X.Schema.Boolean),
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = false, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Party = { Player = { bEnable = false, bOnlyFighting = false } },
			Enemy = { Player = { bEnable = false, bOnlyFighting = false } },
			Neutrality = { Player = { bEnable = false, bOnlyFighting = false } },
			Ally = { Player = { bEnable = false, bOnlyFighting = false } },
			Foe = { Player = { bEnable = true, bOnlyFighting = false } },
		},
	},
	ShowTitle = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
			bOnlyFighting = X.Schema.Boolean,
			bHideInDungeon = X.Schema.Optional(X.Schema.Boolean),
			bHideFullLife = X.Schema.Optional(X.Schema.Boolean),
			bOnlyTarget = X.Schema.Optional(X.Schema.Boolean),
			bHidePets = X.Schema.Optional(X.Schema.Boolean),
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = false, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Party = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Enemy = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Neutrality = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Ally = {
				Npc = { bEnable = true, bOnlyFighting = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false },
			},
			Foe = { Player = { bEnable = false, bOnlyFighting = false } },
		},
	},
	ShowLife = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
			bOnlyFighting = X.Schema.Boolean,
			bHideInDungeon = X.Schema.Optional(X.Schema.Boolean),
			bHideFullLife = X.Schema.Optional(X.Schema.Boolean),
			bOnlyTarget = X.Schema.Optional(X.Schema.Boolean),
			bHidePets = X.Schema.Optional(X.Schema.Boolean),
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = true, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = true, bOnlyFighting = false, bHideFullLife = false },
			},
			Party = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Enemy = {
				Npc = { bEnable = true, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Neutrality = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Ally = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Foe = { Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false } },
		},
	},
	ShowLifePer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
			bOnlyFighting = X.Schema.Boolean,
			bHideInDungeon = X.Schema.Optional(X.Schema.Boolean),
			bHideFullLife = X.Schema.Optional(X.Schema.Boolean),
			bOnlyTarget = X.Schema.Optional(X.Schema.Boolean),
			bHidePets = X.Schema.Optional(X.Schema.Boolean),
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Party = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Enemy = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Neutrality = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Ally = {
				Npc = { bEnable = false, bOnlyFighting = false, bHideFullLife = false, bHidePets = false },
				Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false },
			},
			Foe = { Player = { bEnable = false, bOnlyFighting = false, bHideFullLife = false } },
		},
	},
	ShowBalloon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = SchemaRelationForce(X.Schema.Record({
			bEnable = X.Schema.Boolean,
		})),
		xDefaultValue = {
			Self = {
				Npc = { bEnable = true },
				Player = { bEnable = true },
			},
			Party = {
				Npc = { bEnable = true },
				Player = { bEnable = true },
			},
			Enemy = {
				Npc = { bEnable = true },
				Player = { bEnable = true },
			},
			Neutrality = {
				Npc = { bEnable = true },
				Player = { bEnable = true },
			},
			Ally = {
				Npc = { bEnable = true },
				Player = { bEnable = true },
			},
			Foe = { Player = { bEnable = true } },
		},
	},
	BalloonChannel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L[PLUGIN_NAME],
		xSchema = X.Schema.Map(
			X.Schema.String,
			X.Schema.Record({
				bEnable = X.Schema.Boolean,
				nDuring = X.Schema.Number,
			})
		),
		xDefaultValue = {
			['MSG_NORMAL'           ] = { bEnable = true, nDuring = 5000 },
			['MSG_TEAM'             ] = { bEnable = true, nDuring = 5000 },
			['MSG_PARTY'            ] = { bEnable = true, nDuring = 5000 },
			['MSG_GUILD'            ] = { bEnable = true, nDuring = 9000 },
			['MSG_MAP'              ] = { bEnable = true, nDuring = 9000 },
			['MSG_BATTLE_FILED'     ] = { bEnable = true, nDuring = 9000 },
			['MSG_NPC_NEARBY'       ] = { bEnable = true, nDuring = 9000 },
			['MSG_NPC_PARTY'        ] = { bEnable = true, nDuring = 9000 },
			['MSG_NPC_YELL'         ] = { bEnable = true, nDuring = 9000 },
			['MSG_NPC_WHISPER'      ] = { bEnable = true, nDuring = 9000 },
			['MSG_STORY_NPC'        ] = { bEnable = true, nDuring = 9000 },
			['MSG_STORY_PLAYER'     ] = { bEnable = true, nDuring = 9000 },
			['MSG_BATTLE_FIELD_SIDE'] = { bEnable = true, nDuring = 5000 },
		},
	},
})
local D = {}

local function LoadDefaultTemplate(szStyle)
	local template = X.LoadLUAData(X.PACKET_INFO.ROOT .. 'MY_LifeBar/config/' .. szStyle .. '/{$lang}.jx3dat')
	if not template then
		return
	end
	for _, szRelation in ipairs({ 'Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe' }) do
		local tVal = X.KvpToObject(template[1].Color[szRelation].__VALUE__)
		for _, dwForceID in X.pairs_c(X.CONSTANT.FORCE_TYPE) do
			if not tVal[dwForceID] then
				tVal[dwForceID] = { X.GetForceColor(dwForceID, 'foreground') }
			end
		end
		template[1].Color[szRelation].__VALUE__ = tVal
	end
	if X.ENVIRONMENT.GAME_PROVIDER == 'remote' then -- �ƶ�΢��������ɫ��ֹѹ��ģ��
		for _, szType in ipairs({ 'Player', 'Npc' }) do
			template[1].Color.Enemy.__VALUE__[szType] = { 253, 86, 86 }
		end
		template[1].Color.Foe.__VALUE__.Player = { 202, 126, 255 }
	end
	return template
end

local CONFIG_DEFAULTS = setmetatable({}, {
	__index = function(t, k)
		assert(k ~= 'DEFAULT', 'Default config not exist!!!')
		return t.DEFAULT
	end,
})

local function FormatConfigData(szStyle, d)
	local template = CONFIG_DEFAULTS[szStyle]
	return X.FormatDataStructure(d, template[1], true, template[2])
end

local Config = O
local ConfigLoaded = false

function D.Init()
	for _, p in ipairs({
		{ key = 'DEFAULT' , name = 'default'  },
		{ key = 'OFFICIAL', name = 'official' },
		{ key = 'CLEAR'   , name = 'clear'    },
		{ key = 'XLIFEBAR', name = 'xlifebar' },
	}) do
		local config = LoadDefaultTemplate(p.name)
		if not config then
			X.OutputDebugMessage(_L['MY_LifeBar'], _L['Default config cannot be loaded, please reinstall!!!'] .. ' (' .. p.name .. ')', X.DEBUG_LEVEL.ERROR)
		end
		CONFIG_DEFAULTS[p.key] = config
	end
end

-- ��������Զ�������������÷������� ʵ��Ĭ�����ò����û�����Ӱ��
function D.AutoAdjustScale()
	Config('reload', {'fDesignUIScale', 'fGlobalUIScale'})
	local fUIScale = X.GetUIScale()
	if Config.fDesignUIScale ~= fUIScale then
		Config.fGlobalUIScale = Config.fGlobalUIScale * Config.fDesignUIScale / fUIScale
		Config.fDesignUIScale = fUIScale
	end
	Config('reload', {'nDesignFontOffset', 'fTextScale'})
	local nFontOffset = Font.GetOffset()
	if Config.nDesignFontOffset ~= nFontOffset then
		Config.fTextScale = Config.fTextScale * X.GetFontScale(Config.nDesignFontOffset) / X.GetFontScale()
		Config.nDesignFontOffset = nFontOffset
	end
end

do
local function onUIScaled()
	if not ConfigLoaded then
		return
	end
	D.AutoAdjustScale()
	FireUIEvent('MY_LIFEBAR_CONFIG_UPDATE')
end
X.RegisterEvent('UI_SCALED', 'MY_LifeBar_Config', onUIScaled)
end

function D.LoadConfig(szConfig)
	local tConfig
	if X.IsTable(szConfig) then
		tConfig = szConfig
	elseif X.IsString(szConfig) then
		tConfig = X.LoadLUAData({ 'config/xlifebar/' .. szConfig .. '.jx3dat', X.PATH_TYPE.GLOBAL })
	end
	if tConfig then
		if not tConfig.fDesignUIScale then -- ����������
			for _, key in ipairs({'ShowName', 'ShowTong', 'ShowTitle', 'ShowLife', 'ShowLifePer'}) do
				for _, relation in ipairs({'Self', 'Party', 'Enemy', 'Neutrality', 'Ally', 'Foe'}) do
					for _, tartype in ipairs({'Npc', 'Player'}) do
						if tConfig[key] and X.IsTable(tConfig[key][relation]) and X.IsBoolean(tConfig[key][relation][tartype]) then
							tConfig[key][relation][tartype] = { bEnable = tConfig[key][relation][tartype] }
						end
					end
				end
			end
			tConfig.fDesignUIScale = X.GetUIScale()
			tConfig.fMatchedFontOffset = Font.GetOffset()
		end
		tConfig = FormatConfigData(tConfig.eCss or 'DEFAULT', tConfig)
		for k, v in pairs(tConfig) do
			X.Call(X.Set, Config, {k}, v)
		end
	end
	ConfigLoaded = true
	FireUIEvent('MY_LIFEBAR_CONFIG_LOADED')
end

MY_LifeBar_Config = setmetatable({}, {
	__call = function(t, op, ...)
		local argc = select('#', ...)
		local argv = {...}
		if op == 'get' then
			local config = Config
			for i = 1, argc do
				if not X.IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			return config
		elseif op == 'set' then
			local config = Config
			for i = 1, argc - 2 do
				if not X.IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			if not X.IsTable(config) then
				return
			end
			config[argv[argc - 1]] = argv[argc]
		elseif op == 'reset' then
			if not argv[1] then
				MessageBox({
					szName = 'MY_LifeBar_Restore_Default',
					szAlignment = 'CENTER',
					szMessage = _L['Please choose your favorite lifebar style.\nYou can rechoose in setting panel.'],
					{
						szOption = _L['Official default style'],
						fnAction = function()
							D.LoadConfig(FormatConfigData('OFFICIAL'))
						end,
					},
					{
						szOption = _L['Official clear style'],
						fnAction = function()
							D.LoadConfig(FormatConfigData('CLEAR'))
						end,
					},
					{
						szOption = _L['XLifeBar style'],
						fnAction = function()
							D.LoadConfig(FormatConfigData('XLIFEBAR'))
						end,
					},
					{
						szOption = _L['Keep current'],
						fnAction = function()
							if Config.eCss == '' then
								Config.eCss = 'DEFAULT'
							end
						end,
					},
				})
			else
				D.LoadConfig(FormatConfigData(argv[1]))
			end
		elseif op == 'load' then
			return D.LoadConfig(...)
		elseif op == 'loaded' then
			return ConfigLoaded
		end
	end,
	__index = function(t, k) return Config[k] end,
	__newindex = function(t, k, v) Config[k] = v end,
})

--------------------------------------------------------------------------------
-- �¼�ע��
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_LifeBar_Config', function()
	D.Init()
	D.LoadConfig()
end)

X.RegisterInit('MY_LifeBar_Config', function()
	D.AutoAdjustScale()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
