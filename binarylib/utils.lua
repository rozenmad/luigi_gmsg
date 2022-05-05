local utils = {}

function utils.alignment(size, align)
      return math.floor((size + (align - 1)) / align) * align - size
end

function utils.position_alignment(position, align)
      return position + math.floor((position + (align - 1)) / align) * align - position
end

function utils.find(list, fn)
      for _, v in ipairs(list) do
            if fn(v) then
                  return v
            end
      end
end

function utils.find_all(list, fn)
      local t = {}
      for i, v in ipairs(list) do
            if fn(i, v) then
                  table.insert(t, v)
            end
      end
      return t
end

function utils.sequence_equal(a, b)
      for i = 1, #b do
            if not a[i] or a[i] ~= b[i] then
                  return false
            end
      end
      return true
end

function utils.subarray(a, index, length)
      local t = {}
      for i = index, index + length do
            table.insert(t, a[i])
      end
      return t
end

local ffi = require 'ffi'
function utils.bytearray_to_string(bytes)
	local c_str = ffi.new("char[?]", #bytes, 0)
	for i, v in ipairs(bytes) do
		c_str[i-1] = v
	end
	return ffi.string(c_str, #bytes)
end

return utils