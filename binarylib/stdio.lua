local ffi = require 'ffi'
local stdlib = require 'binarylib.stdlib'

ffi.cdef[[
enum {
      SEEK_SET = 0,
      SEEK_CUR = 1,
      SEEK_END = 2,
};
typedef struct {
      char *fpos;
      void *base;
      unsigned short handle;
      short flags;
      short unget;
      unsigned long alloc;
      unsigned short buffincrement;
} FILE;

FILE *fopen(const char *filename, const char *mode);
size_t fread(void *buffer, size_t size, size_t count, FILE *stream);
size_t fwrite(const void *buffer, size_t size, size_t count, FILE *stream);
int fseek(FILE *stream, long offset, int origin);
long ftell(FILE *stream);
void rewind(FILE *stream);
int fclose(FILE *stream);
]]

local uint8_t_size = ffi.sizeof('uint8_t')

local file = {}
file.__index = file
file.class_name = 'STDIOFILE'

function file:read()
      local size = self:size()
      local buffer = stdlib.malloc(size)
      local res = ffi.C.fread(buffer, uint8_t_size, size, self.f)
      return buffer
end

function file:read_to_buffer(buffer, count)
      local res = ffi.C.fread(buffer, uint8_t_size, count, self.f)
      return buffer
end

function file:write(data, size)
      return ffi.C.fwrite(data, uint8_t_size, size, self.f)
end

function file:seek(whence, offset)
      local origin = ffi.C.SEEK_SET
      if whence == 'cur' then origin = ffi.C.SEEK_CUR end
      if whence == 'end' then origin = ffi.C.SEEK_END end
      return ffi.C.fseek(self.f, offset, origin)
end

function file:tell()
      return ffi.C.ftell(self.f)
end

function file:size()
      local prev_position = self:tell()
      self:seek('end', 0)
      local size = self:tell()
	self:seek('set', prev_position)
      return size
end

function file:rewind()
      ffi.C.rewind(self.f)
end

function file:close()
      ffi.C.fclose(self.f)
end

return {
      open = function (filename, mode)
            mode = mode or 'r'
            local f = ffi.C.fopen(filename, mode)
            if f then
                  return setmetatable({ f = f }, file)
            end
      end
}
