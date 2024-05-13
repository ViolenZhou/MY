--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��ѧ��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Math')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

do
local metatable = { __index = function() return 0 end }
-- ��һ����ֵת����һ��Bit����λ��ǰ ��λ�ں�
---@param nNumber number @Ҫת������ֵ
---@return table @��ֵ�ı��ر�
function X.Number2Bitmap(nNumber)
	local tBit = {}
	if nNumber == 0 then
		table.insert(tBit, 0)
	else
		while nNumber > 0 do
			local nValue = nNumber % 2
			table.insert(tBit, nValue)
			nNumber = math.floor(nNumber / 2)
		end
	end
	return setmetatable(tBit, metatable)
end

-- ��һ���ַ�����ֵת����һ��Bit����λ��ǰ ��λ�ں�
---@param szNumber string @Ҫת������ֵ�ַ���
---@return table @��ֵ�ı��ر�
function X.NumericString2Bitmap(szNumber)
	local tBit = {}
	local szResult = ''
	local nCarry = 0
	while #szNumber > 1 or tonumber(szNumber) > 0 do
		szResult = ''
		nCarry = 0
		for i = 1, #szNumber do
			local nNum = tonumber(szNumber:sub(i, i)) + nCarry * 10
			nCarry = nNum % 2
			szResult = szResult .. tostring(math.floor(nNum / 2))
		end
		if string.sub(szResult, 1, 1) == '0' and #szResult > 1 then
			szResult = string.sub(szResult, 2)
		end
		table.insert(tBit, nCarry)
		szNumber = szResult
	end
	return setmetatable(tBit, metatable)
end
end

-- ��һ��Bit����λ��ǰ ��λ�ں�ת����һ����ֵ
---@param tBit table @��ֵ�ı��ر�
---@return number @Ҫת������ֵ
function X.Bitmap2Number(tBit)
	local nNumber = 0
	for i, v in pairs(tBit) do
		if type(i) == 'number' and v and v ~= 0 then
			nNumber = nNumber + 2 ^ (i - 1)
		end
	end
	return nNumber
end

-- ��һ��Bit����λ��ǰ ��λ�ں�ת����һ����ֵ�ַ���
---@param tBit table @��ֵ�ı��ر�
---@return string @Ҫת������ֵ
function X.Bitmap2NumericString(tBit)
	local szNumber = '0'
	for i = #tBit, 1, -1 do
		-- �ַ�����ʾ��������2
		local szDoubled = ''
		local nCarry = 0
		for j = #szNumber, 1, -1 do
			local nNum = tonumber(szNumber:sub(j, j)) * 2 + nCarry
			nCarry = math.floor(nNum / 10)
			szDoubled = tostring(nNum % 10) .. szDoubled
		end
		if nCarry > 0 then
			szDoubled = tostring(nCarry) .. szDoubled
		end
		-- �����ǰλ��1��������1
		if tBit[i] == 1 then
			local szSum = ''
			nCarry = 1  -- ��1��ʼ�ӣ���Ϊ����Ҫ�ӵ���1
			for j = #szDoubled, 1, -1 do
				local nNum = tonumber(szDoubled:sub(j, j)) + nCarry
				nCarry = math.floor(nNum / 10)
				szSum = tostring(nNum % 10) .. szSum
			end
			if nCarry > 0 then
				szSum = tostring(nCarry) .. szSum
			end
			szNumber = szSum
		else
			szNumber = szDoubled
		end
	end
	return szNumber
end

-- ����һ����ֵ��ָ������λ
---@param nNumber number @��ֵ
---@param nIndex number @Ҫ���õ�λ
---@param xBit boolean|'0'|'1' @Ҫ���õ�λ��ֵ
---@return number @���ú����ֵ
function X.SetNumberBit(nNumber, nIndex, xBit)
	nNumber = nNumber or 0
	local tBit = X.Number2Bitmap(nNumber)
	if xBit and xBit ~= 0 then
		tBit[nIndex] = 1
	else
		tBit[nIndex] = 0
	end
	return X.Bitmap2Number(tBit)
end

-- ��ȡһ����ֵ��ָ������λ
---@param nNumber number @��ֵ
---@param nIndex number @Ҫ��ȡ��λ
---@return '0'|'1' @��λ��ֵ
function X.GetNumberBit(nNumber, nIndex)
	return X.Number2Bitmap(nNumber)[nIndex] or 0
end

-- ��λ������
---@param nNumber1 number @��ֵ1
---@param nNumber2 number @��ֵ2
---@return number @��λ��������ֵ
function X.NumberBitAnd(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == 1 and tBit2[i] == 1 and 1 or 0
	end
	return X.Bitmap2Number(tBit)
end

-- ��λ������
---@param nNumber1 number @��ֵ1
---@param nNumber2 number @��ֵ2
---@return number @��λ��������ֵ
function X.NumberBitOr(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == 0 and tBit2[i] == 0 and 0 or 1
	end
	return X.Bitmap2Number(tBit)
end

-- ��λ�������
---@param nNumber1 number @��ֵ1
---@param nNumber2 number @��ֵ2
---@return number @��λ���������ֵ
function X.NumberBitXor(nNumber1, nNumber2)
	local tBit1 = X.Number2Bitmap(nNumber1)
	local tBit2 = X.Number2Bitmap(nNumber2)
	local tBit = {}
	for i = 1, math.max(#tBit1, #tBit2) do
		tBit[i] = tBit1[i] == tBit2[i] and 0 or 1
	end
	return X.Bitmap2Number(tBit)
end

-- ��������
---@param nNumber number @��ֵ
---@param nShift number @��������
---@param nNumberBit number @��ֵ��Bitλ����Ĭ��32λ
---@return number @����������ֵ
function X.NumberBitShl(nNumber, nShift, nNumberBit)
	local tBit = X.Number2Bitmap(nNumber)
	if not nNumberBit then
		nNumberBit = 32
	end
	for i = 1, nShift do
		table.insert(tBit, 1, 0)
	end
	while #tBit > nNumberBit do
		table.remove(tBit)
	end
	return X.Bitmap2Number(tBit)
end

-- ��������
---@param nNumber number @��ֵ
---@param nShift number @��������
---@return number @����������ֵ
function X.NumberBitShr(nNumber, nShift)
	local tBit = X.Number2Bitmap(nNumber)
	for i = 1, nShift do
		table.remove(tBit, 1)
	end
	return X.Bitmap2Number(tBit)
end

-- ��ʽ������Ϊָ�������µ��ַ�����ʾ
---@param nNumber number @��ֵ
---@param nBase number @����ֵ
---@param szDigits string @����λ��ʾ��Ĭ��Ϊ 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ
---@return string @ת�����ƺ����ֵ�ַ���
function X.NumberBaseN(nNumber, nBase, szDigits)
	if not X.IsNumber(nNumber) or X.IsHugeNumber(nNumber) then
		assert(false, 'Input must be a number value except `math.huge`.')
	end
	nNumber = math.floor(nNumber)
	if not nBase or nBase == 10 then
		return tostring(nNumber)
	end
	if not szDigits then
		szDigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	end
	if nBase > #szDigits then
		assert(false, 'Number base can not be larger than digits length.')
	end
	local t = {}
	local szSign = ''
	if nNumber < 0 then
		szSign = '-'
		nNumber = -nNumber
	end
	repeat
		local d = (nNumber % nBase) + 1
		nNumber = math.floor(nNumber / nBase)
		table.insert(t, 1, szDigits:sub(d, d))
	until nNumber == 0
	return szSign .. table.concat(t, '')
end

-- ��ֵת���������ַ => �ε�ַ + ����ƫ��
---@param nNumber number @�����ַ��ֵ
---@param nSegmentSize number @�γ���
---@return number,number @ת����Ķε�ַ,����ƫ��
function X.NumberToSegment(nNumber, nSegmentSize)
	-- (!(n & (n - 1)))
	if not X.IsNumber(nSegmentSize) or nSegmentSize <= 0 or X.NumberBitAnd(nSegmentSize, nSegmentSize - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if nSegmentSize == 0x20 and GlobelRecipeID2BookID then
		local n, o = GlobelRecipeID2BookID(nNumber)
		if n and o then
			return n - 1, o - 1
		end
	end
	return nNumber / nSegmentSize, nNumber % nSegmentSize
end

-- ��ֵת�����ε�ַ + ����ƫ�� => �����ַ
---@param nSegment number @�ε�ַ
---@param nOffset number @����ƫ��
---@param nSegmentSize number @�γ���
---@return number @ת����������ַ��ֵ
function X.SegmentToNumber(nSegment, nOffset, nSegmentSize)
	-- (!(n & (n - 1)))
	if not X.IsNumber(nSegmentSize) or nSegmentSize <= 0 or X.NumberBitAnd(nSegmentSize, nSegmentSize - 1) ~= 0 then
		assert(false, 'segment size must be a positive number and be power of 2')
	end
	if nSegmentSize == 0x20 and BookID2GlobelRecipeID then
		local n = BookID2GlobelRecipeID(nSegment + 1, nOffset + 1)
		if n then
			return n
		end
	end
	return nSegment * nSegmentSize + nOffset
end

-- ��Ϸͨ�� ��Recipe�±�(����ַ0)�� ת �����±�(����ַ1)�� + �������±�(����ַ1)��
---@param dwRecipeID number @Recipe�±�(����ַ0)
---@return number,number @���±�(����ַ1),�����±�(����ַ1)
function X.RecipeToSegmentID(dwRecipeID)
	local dwSegmentID, dwOffset = X.NumberToSegment(dwRecipeID, 0x20)
	return dwSegmentID + 1, dwOffset + 1
end

-- ��Ϸͨ�� �����±�(����ַ1)�� + �������±�(����ַ1)�� ת ��Recipe�±�(����ַ0)��
---@param dwSegmentID number @���±�(����ַ1)
---@param dwOffset number @�����±�(����ַ1)
---@return number @Recipe�±�(����ַ0)
function X.SegmentToRecipeID(dwSegmentID, dwOffset)
	return X.SegmentToNumber(dwSegmentID - 1, dwOffset - 1, 0x20)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
