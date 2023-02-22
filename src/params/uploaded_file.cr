struct Frost::Params
  struct UploadedFile
    @original_filename : String
    @headers : HTTP::Headers
    @size : UInt64?
    @tempfile : File

    def initialize(part = HTTP::FormData::Part)
      @original_filename = part.filename.not_nil!
      @headers = part.headers
      @size = part.size

      @tempfile = File.tempfile("frost_upload")

      {% if flag?(:unix) %}
        # remove filesystem entry but keep the file descriptor so only this
        # process can read and write this file (?)
        @tempfile.delete
      {% end %}

      IO.copy(part.body, @tempfile)
      @tempfile.rewind
    end

    def original_filename : String
      @original_filename
    end

    def headers : HTTP::Headers
      @headers
    end

    def content_type? : String?
      @headers["content-type"]?
    end

    def size : UInt64
      @size ||= @tempfile.info.size.to_u64
    end

    def to_io : IO
      @tempfile
    end

    def closed? : Bool
      @tempfile.closed?
    end

    def close : Nil
      @tempfile.close
    end

    def delete : Nil
      @tempfile.delete if File.exists?(@tempfile.path)
    end
  end
end
