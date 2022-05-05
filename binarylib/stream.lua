local ffi = require 'ffi'
local stdlib = require 'binarylib.stdlib'

local m_stream = {}
m_stream.__index = m_stream

local f_stream = {}
f_stream.__index = f_stream

local function m_stream_new(data, size)
      local t = setmetatable({}, m_stream)
      local c_str
      if type(data) == 'cdata' and size then
            t.size = size
            c_str = ffi.cast("uint8_t*", data)
      else
            local size = #data
            local memblock = stdlib.malloc(size)
            c_str = ffi.cast("uint8_t*", memblock)
            ffi.fill(c_str, size, 0)

            if type(data) == 'string' then
                  ffi.copy(c_str, data, size)
            else
                  for i, v in ipairs(data) do
                        c_str[i - 1] = v
                  end
            end
            t.size = size
      end
      t.buffer = ffi.gc(c_str, stdlib.free)
      return t
end

function m_stream:check_capacity(position, size)
      if position + size > self.size then
            local old_capacity = self.size
            local new_capacity = position + size
            self.size = new_capacity + (new_capacity / 2)
            ffi.gc(self.buffer, nil)
            local new_buffer = ffi.cast('uint8_t*', stdlib.realloc(self.buffer, self.size))
            assert(new_buffer, 'realloc failed')
            self.buffer = ffi.gc(new_buffer, stdlib.free)
      end
end

function m_stream:pack(position, size, value, t)
      self:check_capacity(position, size)
      local ptr = ffi.cast(t, self.buffer + position)
      ptr[0] = value
end

function m_stream:get_data_ptr(position, t)
      return ffi.cast(t, self.buffer + position)
end

function m_stream:read_data(position, size)
      local data = ffi.new('uint8_t[?]', size)
      ffi.copy(data, self.buffer + position, size)
      return data
end

function m_stream:write_data(position, size, ptr)
      self:check_capacity(position, size)
      ffi.copy(self.buffer + position, ptr, size)
      return ptr
end


local function f_stream_new(file)
      local t = setmetatable({}, f_stream)
      t.file = file
      t.size = t.file:size()

      t.buffer = ffi.new('uint8_t[?]', 8)
      return t
end

function f_stream:pack(position, size, value, t)
      local ptr = ffi.cast(t, self.buffer)
      ptr[0] = value
      self.file:seek('set', position)
      self.file:write(ptr, size)
end

function f_stream:get_data_ptr(position, t)
      self.file:seek('set', position)
      self.file:read_to_buffer(self.buffer, 8)
      return ffi.cast(t, self.buffer)
end

function f_stream:read_data(position, size)
      local ptr = ffi.new('uint8_t[?]', size)
      self.file:seek('set', position)
      self.file:read_to_buffer(ptr, size)
      return ptr
end

function f_stream:write_data(position, size, ptr)
      self.file:seek('set', position)
      self.file:write(ptr, size)
end

return {
      m_stream = m_stream_new,
      f_stream = f_stream_new,
}