local luautf8 = require 'lua-utf8'
local BinaryReader = require 'binarylib.binaryreader'
local BinaryWriter = require 'binarylib.binarywriter'
local utils = require 'binarylib.utils'
local stdio = require 'binarylib.stdio'

local function read_file(filename)
	local file = io.open(filename, 'rb')
	assert(file, string.format('File "%s" not found', filename))
	local data = file:read('*a')
	file:close()
	return data
end

local commands_length = {
	[0x08] = 2,
	[0x0E] = 2,
	[0x0F] = 2,
	[0x11] = 1,
	[0x19] = 4
}

local commands = {
	[0x08] = true, [0x0E] = true, [0x0F] = true, [0x11] = true, [0x19] = true,
}

local function parse_bytes_string(bytes)
	local br = BinaryReader.new(bytes)
	local result = {}

	while not br:is_eof() do
		local c1 = br:read_ubyte()
		if c1 == 0x7f then
			if br.position % 2 ~= 0 then br.position = br.position + 1 end

			local r1 = br:read_uint16()
			if r1 == 0x0 then
				break
			elseif r1 == 0x01 then
				table.insert(result, '<br>')
			elseif r1 == 0x02 then
				table.insert(result, '<hr>')
			elseif commands[r1] then
				if r1 ~= 0x11 then
					br.position = utils.position_alignment(br.position, 4)
				end

				table.insert(result, '[')
				local codes = {}
				table.insert(codes, string.format("0x%x", r1))

				for _ = 1, commands_length[r1] do
					local short = br:read_uint16()
					if short ~= 0x0 then
						table.insert(codes, string.format("0x%x", short))
					end
				end

				table.insert(result, table.concat(codes, ", "))
				table.insert(result, ']')
			elseif r1 == 0x15 then
				br.position = utils.position_alignment(br.position, 4)

				local short = br:read_uint16()
				if short == 0xffff then
					if br:read_uint16() == 0xffff then
						table.insert(result, '</span>')
					end
				elseif short ~= 0x0 then
					table.insert(result, string.format('<span class="color-%i">', short))
				end
			else
				table.insert(result, r1)
			end
		elseif c1 ~= 0x0 then
			table.insert(result, string.char(c1))
		end
	end
	return result
end

local function export_gmsg(inputgmsg_name, output_name)
	local data = read_file(inputgmsg_name)
	local binreader = BinaryReader.new(data)
	binreader.position = 0x0C
	local entry_count = binreader:read_int32()
	local pos = binreader:read_int32()

	local msg_array = {}
	binreader.position = pos
	for i = 1, entry_count do
		local id = binreader:read_int32()
		binreader:read_int32()
		local offset = binreader:read_int32()
		local length = binreader:read_int32()
		print(id, offset, length)

		local prev_position = binreader.position
		binreader.position = offset

		local bytes = binreader:read_bytes(length)
		table.insert(msg_array, {
			id = id,
			length = length,
			bytes = bytes,
		})

		binreader.position = prev_position
	end

	local output_file = io.open(output_name, 'wb')
	for i, v in ipairs(msg_array) do
		local result = parse_bytes_string(v.bytes)
		output_file:write(v.id, "|", table.concat(result), "|\n")
	end
	output_file:close()
end

local function table_find(t, i, value)
	for j = i, #t do
		if t[j] == value then return j end
	end
	assert('index not found with value: ', value)
end

local function write_align2_codepoint(bw, code)
	if bw.position % 2 == 1 then
		bw:write_ubyte(code)
	else
		bw:write_int16(code)
	end
end

local function write_align4_codepoint(bw, code)
	if (bw.position / 2) % 2 == 1 then
		bw:write_int16(code)
		return 0
	else
		bw:write_int32(code)
		return 2
	end
end

local function write_string(id, s, bw)
	local t = {}
	for _, code in luautf8.next, s do
		table.insert(t, luautf8.char(code))
	end

	local i = 1
	while i <= #t do
		local c = t[i]
		if c == '[' then
			local j = table_find(t, i, ']')
			assert(j, string.format('Error in line %i = %s', id, s))
			local temp = table.concat(t, nil, i + 1, j - 1)

			write_align2_codepoint(bw, 0x7f)

			local codes = {}
			for code in temp:gmatch("[^, ]+") do
				table.insert(codes, tonumber(code, 16))
			end
			local first_code = codes[1]
			table.remove(codes, 1)
			if commands[first_code] then
				if first_code ~= 0x11 then
					write_align4_codepoint(bw, first_code)
				else
					bw:write_int16(first_code)
				end
				for k = 0, commands_length[first_code] - 1 do
					if k % 2 == 0 then
						local code = codes[(k / 2) + 1]
						if code then
							bw:write_int16(code)
						else
							bw:write_int16(0x0)
						end
					else
						bw:write_int16(0x0)
					end
				end
			else
				bw:write_bytes(codes)
			end
			i = j
		elseif c == '<' then
			local j = table_find(t, i, '>')
			assert(j, string.format('Error in line %i = %s', id, s))
			local tag = table.concat(t, nil, i + 1, j - 1)

			write_align2_codepoint(bw, 0x7f)

			if tag == 'br' then
				bw:write_int16(0x01)
			elseif tag == 'hr' then
				bw:write_int16(0x02)
			elseif tag:find('span ') then
				local color_value = tag:match('span class="color%-([%d]+)"')
				write_align4_codepoint(bw, 0x15)
				bw:write_int16(tonumber(color_value))
				bw:write_int16(0x0)
			elseif tag:find('/span') then
				write_align4_codepoint(bw, 0x15)
				bw:write_int16(0xffff)
				bw:write_int16(0xffff)
			else
				error(string.format('Invalid tag on %i = %s', id, s))
			end
			i = j
		else
			bw:write_string(c)
		end
		i = i + 1
	end
	write_align2_codepoint(bw, 0x7f)
	return write_align4_codepoint(bw, 0x00)
end

local function import_gmsg(inputgmsg_name, inputmd_name, outputgmsg_name)
	local lines = {}
	for line in io.lines(inputmd_name) do
		if #line > 0 then
			local id, str = line:match('([^|]+)|([^|]*)|')
			assert(id, 'Error in: ' .. line)
			lines[tonumber(id)] = str
		end
	end

	local data = read_file(inputgmsg_name)

	local binreader = BinaryReader.new(data)
	binreader.position = 0x0C
	local entry_count = binreader:read_int32()
	local pos = binreader:read_int32()

	local size = entry_count * 4 * 4 + pos

	local output_file = stdio.open(outputgmsg_name, 'wb')
	local bw = BinaryWriter.from_file(output_file)
	bw:write_raw_bytes(binreader:read_raw_bytes(0, size), size)

	binreader.position = pos
	for i = 1, entry_count do
		local table_pos = binreader.position
		local id = binreader:read_int32()
		local unknown = binreader:read_int32()
		binreader:read_int32()
		binreader:read_int32()

		assert(lines[id], 'Not found: ' .. id)
		local offset = bw.position
		local align = write_string(id, lines[id], bw)
		local prev_position = bw.position
		bw.position = table_pos
		bw:write_int32(id)
		bw:write_int32(unknown)
		bw:write_int32(offset)
		bw:write_int32(prev_position - offset - align)
		bw.position = prev_position
	end
end

local first_arg = arg[1]
if first_arg == 'import' then
	assert(arg[2], 'Error: inputgmsg_name arg not found.')
	assert(arg[3], 'Error: inputmd_name arg not found.')
	assert(arg[4], 'Error: outputgmsg_name arg not found.')
	import_gmsg(select(2, unpack(arg)))
elseif first_arg == 'export' then
	assert(arg[2], 'Error: inputgmsg_name arg not found.')
	assert(arg[3], 'Error: output_name arg not found.')
	export_gmsg(select(2, unpack(arg)))
end