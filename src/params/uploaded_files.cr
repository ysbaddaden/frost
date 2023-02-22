struct Frost::Params::UploadedFiles
  def initialize(@uploads = {} of String => Array(Params::UploadedFile))
  end

  def has_key?(name : String) : Bool
    @uploads.has_key?(name)
  end

  def [](name : String) : Params::UploadedFile
    fetch(name) { raise KeyError.new "Missing param name: #{name.inspect}" }
  end

  def []?(name : String) : Params::UploadedFile?
    fetch(name) { nil }
  end

  def fetch(name : String, default) : Params::UploadedFile
    fetch(name) { default }
  end

  def fetch(name : String, &) : Params::UploadedFile
    if @uploads.has_key?(name)
      @uploads[name].first
    else
      yield
    end
  end

  def fetch_all(name : String) : Array(Params::UploadedFile)
    @uploads.fetch(name)
  end

  def fetch_all?(name : String) : Array(Params::UploadedFile)?
    @uploads.fetch?(name)
  end

  def each(& : {String, Params::UploadedFile} ->) : Nil
    @uploads.each do |name, values|
      values.each do |value|
        yield({name, value})
      end
    end
  end

  def add(name : String, value : Params::UploadedFile) : Nil
    (@uploads[name] ||= [] of Params::UploadedFile) << value
  end
end
