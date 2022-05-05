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

ffi.cdef[[
uint16_t _byteswap_ushort ( uint16_t val );
uint32_t _byteswap_ulong  ( uint32_t val );
uint64_t _byteswap_uint64 ( uint64_t val );
]]

local binaryreader = {}
binaryreader.__index = binaryreader

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

local function new(data, size)
      local stream
      if type(data) == 'table' and data.class_name == 'STDIOFILE' then
            stream = Stream.f_stream(data)
      else
            stream = Stream.m_stream(data, size)
      end
      local object = { is_little_endian = true, _init_pos = 0, position = 0, stream = stream }
      return setmetatable(object, binaryreader)
end

function binaryreader:new_from_position(new_position)
      local object = {
            is_little_endian = self.is_little_endian,
            _init_pos = self._init_pos + (new_position or self.position),
            position = 0,
            stream = self.stream,
      }
      return setmetatable(object, binaryreader)
end

function binaryreader:alignment(align)
      self.position = self.position + utils.alignment(self._init_pos + self.position, align)
end

function binaryreader:relative_position()
      return self._init_pos + self.position
end

function binaryreader:read_ubyte()
      local t = types.ubyte
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 1
      return ptr[0]
end

function binaryreader:read_int64()
      local t = types.int64
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 8
      if not self.is_little_endian then
            return byteswap.int64(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_int32()
      local t = types.int32
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 4
      if not self.is_little_endian then
            return byteswap.int32(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_int16()
      local t = types.int16
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 2
      if not self.is_little_endian then
            return byteswap.int16(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_uint64()
      local t = types.uint64
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 8
      if not self.is_little_endian then
            return byteswap.uint64(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_uint32()
      local t = types.uint32
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 4
      if not self.is_little_endian then
            return byteswap.uint32(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_uint16()
      local t = types.uint16
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 2
      if not self.is_little_endian then
            return byteswap.uint16(ptr, t)
      end
      return ptr[0]
end

function binaryreader:read_float()
      local t = types.float
      local ptr = self.stream:get_data_ptr(self:relative_position(), t)
      self.position = self.position + 4
      --[[if not self.is_little_endian then
            return byteswap.int16(ptr, t)
      end]]
      return ptr[0]
end

function binaryreader:read_int32_array(count)
      local array = {}
      for i = 1, count do
            array[i] = self:read_int32()
      end
      return array
end

function binaryreader:read_bytes(count)
      assert(self.position + count <= self:size(), 'read_bytes out of range')
      local bytes = {}
      for i = 1, count do
            table.insert(bytes, self:read_ubyte())
      end
      return bytes
end

function binaryreader:read_string(count)
      if count then
            assert(self.position + count < self:size(), 'read_ascii_string out of range')
            local s = self.stream:read_data(self:relative_position(), count)
            self.position = self.position + count
            return ffi.string(s, count)
      else
            local bytes = {}
            while not self:is_eof() do
                  local value = self:read_ubyte()
                  if value == 0 then
                        break
                  end
                  table.insert(bytes, value)
            end
            local count = #bytes
            local s = ffi.new("uint8_t[?]", count)
            for i, v in ipairs(bytes) do
                  s[i - 1] = v
            end
            return ffi.string(s, count)
      end
end

function binaryreader:read_raw_bytes(offset, size)
      return self.stream:read_data(self._init_pos + offset, size)
end

function binaryreader:search_bytes(bytes, i, j)
      i = i or 0
      j = j or (self.size - 1)
      local t = {}
      for pos = i, j do
            self.position = pos
            local find = true
            for _, v in ipairs(bytes) do
                  if v ~= self:read_ubyte() then
                        find = false
                        break
                  end
            end
            if find then
                  table.insert(t, pos)
            end
      end
      return t
end

function binaryreader:size()
      return self.stream.size - self._init_pos
end

function binaryreader:is_eof()
      return self.position >= self:size()
end

return {
      new = new,
}