lib LibC
  fun realpath(path : UInt8*, resolved_path : UInt8*) : UInt8*
end

class File
  # FIXME: do we have to free the ptr or will GC take care of it?
  def self.realpath(path)
    ptr = LibC.realpath(path, Pointer(UInt8).null)
    raise Errno.new("realpath") if ptr.null?
    String.new(ptr)
  end
end
