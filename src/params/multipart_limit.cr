struct Frost::Params
  # Raised when a multipart request has more than `Params#multipart_parts_limit`
  # parts (defaults to 4096) or more than `Params#multipart_files_limit` files,
  # that is parts with a filename (defaults to 128).
  #
  # These limits can be configured with `Params#multipart_parts_limit=` or
  # `Params#multipart_files_limit=` as well as the `FROST_MULTIPART_PARTS_LIMIT`
  # and `FROST_MULTIPART_FILES_LIMIT` environment variables.
  class MultipartLimit < Exception
  end

  def self.multipart_parts_limit : Int32
    @@multipart_parts_limit ||= ENV.fetch("FROST_MULTIPART_PARTS_LIMIT", "4096").to_i
  end

  def self.multipart_parts_limit=(@@multipart_parts_limit : Int32)
  end

  def self.multipart_files_limit : Int32
    @@multipart_files_limit ||= ENV.fetch("FROST_MULTIPART_FILES_LIMIT", "128").to_i
  end

  def self.multipart_files_limit=(@@multipart_files_limit : Int32)
  end

  private def check_multipart_limit(limit : Int32, &)
    return if limit >= 0
    close
    raise MultipartLimit.new(yield)
  end
end
