local ffi = require 'ffi'

ffi.cdef[[
void *malloc(size_t size);
void *realloc(void *ptr, size_t size);
void free(void *ptr);
]]

return {
      malloc = ffi.C.malloc,
      realloc = ffi.C.realloc,
      free = ffi.C.free
}