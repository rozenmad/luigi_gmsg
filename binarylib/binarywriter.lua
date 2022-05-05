--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

local ffi = require 'ffi'
local byteswap = require 'binarylib.byteswap'
local utils = require 'binarylib.utils'
local Stream = require 'binarylib.stream'

local binarywriter = {}
binarywriter.__index = binarywriter

local types = {
      ubyte = 'uint8_t*',
      int16 = 'int16_t*',
      int32 = 'int32_t*',
      int64 = 'int64_t*',
      uint16 = 'uint16_t*',
      uint32 = 'uint32_t*',
      uint64 = 'uint64_t*',
      float = 'float*',
}

local function from_file(file)
      local stream
      if type(file) == 'table' and file.class_name == 'STDIOFILE' then
            stream = Stream.f_stream(file)
      end
      local object = { is_little_endian = true, _init_pos = 0, position = 0, stream = stream }
      return setmetatable(object, binarywriter)
end

local function from_data(data)
      local stream
      if data then
            stream = Stream.m_stream(data, #data)
      else
            stream = Stream.m_stream('')
      end
      local object = { is_little_endian = true, _init_pos = 0, position = 0, stream = stream }
      return setmetatable(object, binarywriter)
end

function binarywriter:new_from_position(new_position)
      local object = {
            is_little_endian = self.is_little_endian,
            _init_pos = self._init_pos + (new_position or self.position),
            position = 0,
            stream = self.stream,
      }
      return setmetatable(object, binarywriter)
end

function binarywriter:alignment(align)
      local offset = utils.alignment(self._init_pos + self.position, align)
      if offset > 0 then
            self:fill(offset, 0)
      end
end

function binarywriter:relative_position()
      return self._init_pos + self.position
end

function binarywriter:write_ubyte(value)
      local t = types.ubyte
      self.stream:pack(self:relative_position(), 1, value, t)
      self.position = self.position + 1
end

function binarywriter:write_int16(value)
      local t = types.int16
      if not self.is_little_endian then
            byteswap.union.i16 = value
            value = byteswap.int16(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 2, value, t)
      self.position = self.position + 2
end

function binarywriter:write_int32(value)
      local t = types.int32
      if not self.is_little_endian then
            byteswap.union.i32 = value
            value = byteswap.int32(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 4, value, t)
      self.position = self.position + 4
end

function binarywriter:write_int64(value)
      local t = types.int64
      if not self.is_little_endian then
            byteswap.union.i64 = value
            value = byteswap.int64(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 8, value, t)
      self.position = self.position + 8
end

function binarywriter:write_uint16(value)
      local t = types.uint16
      if not self.is_little_endian then
            byteswap.union.u16 = value
            value = byteswap.uint16(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 2, value, t)
      self.position = self.position + 2
end

function binarywriter:write_uint32(value)
      local t = types.uint32
      if not self.is_little_endian then
            byteswap.union.u32 = value
            value = byteswap.uint32(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 4, value, t)
      self.position = self.position + 4
end

function binarywriter:write_uint64(value)
      local t = types.uint64
      if not self.is_little_endian then
            byteswap.union.u64 = value
            value = byteswap.uint64(byteswap.union, t)
      end
      self.stream:pack(self:relative_position(), 8, value, t)
      self.position = self.position + 8
end

function binarywriter:write_float(value)
      local t = types.float
      --[[if not self.is_little_endian then
            byteswap.union.i64 = value
            value = byteswap.int64(byteswap.union, t)
      end]]
      self.stream:pack(self:relative_position(), 4, value, t)
      self.position = self.position + 4
end

function binarywriter:write_int32_array(array)
      for i, v in ipairs(array) do
            self:write_int32(v)
      end
end

function binarywriter:write_bytes(bytearray)
      for i, v in ipairs(bytearray) do
            self:write_ubyte(v)
      end
end

function binarywriter:write_raw_bytes(ptr, size)
      self.stream:write_data(self:relative_position(), size, ptr)
      self.position = self.position + size
end

function binarywriter:fill(size, value)
      for i = 1, size do
            self:write_ubyte(value)
      end
end

function binarywriter:write_string(s)
      local size = #s
      local c_str = ffi.new("uint8_t[?]", size)
      ffi.copy(c_str, s, size)
      self.stream:write_data(self:relative_position(), size, c_str)
      self.position = self.position + size
end

return {
      from_file = from_file,
      from_data = from_data,
}