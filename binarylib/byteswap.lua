local ffi = require 'ffi'

ffi.cdef[[
uint16_t _byteswap_ushort ( uint16_t val );
uint32_t _byteswap_ulong  ( uint32_t val );
uint64_t _byteswap_uint64 ( uint64_t val );
]]

local union_type = ffi.typeof [[
union {
uint8_t u8[4];
int16_t i16; uint16_t u16;
int32_t i32; uint32_t u32;
int64_t i64; uint64_t u64;
}
]]
local union = union_type { u64 = 0 }

return {
      union = union,
      uint16 = function(ptr, t)
            union.u16 = ffi.cast(t, ptr)[0]
            return ffi.C._byteswap_ushort(union.u16)
      end,
      uint32 = function(ptr, t)
            union.u32 = ffi.cast(t, ptr)[0]
            return ffi.C._byteswap_ulong (union.u32)
      end,
      uint64 = function(ptr, t)
            union.u64 = ffi.cast(t, ptr)[0]
            return ffi.C._byteswap_uint64(union.u64)
      end,

      int16 = function(ptr, t)
            union.u16 = ffi.C._byteswap_ushort(ffi.cast(t, ptr)[0])
            return union.i16
      end,
      int32 = function(ptr, t)
            union.u32 = ffi.C._byteswap_ulong (ffi.cast(t, ptr)[0])
            return union.i32
      end,
      int64 = function(ptr, t)
            union.u64 = ffi.C._byteswap_uint64(ffi.cast(t, ptr)[0])
            return union.i64
      end
}