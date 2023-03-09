struct Frost::Params::UploadedFiles
  include Enumerable({String, UploadedFile})

  def initialize(@uploads = {} of String => Array(UploadedFile))
  end

  def has_key?(name : String) : Bool
    @uploads.has_key?(name)
  end

  def [](name : String) : UploadedFile
    fetch(name) { raise KeyError.new "Missing param name: #{name.inspect}" }
  end

  def []?(name : String) : UploadedFile?
    fetch(name) { nil }
  end

  def fetch(name : String, default) : UploadedFile
    fetch(name) { default }
  end

  def fetch(name : String, &) : UploadedFile
    if @uploads.has_key?(name)
      @uploads[name].first
    else
      yield
    end
  end

  def fetch_all(name : String) : Array(UploadedFile)
    @uploads.fetch(name)
  end

  def fetch_all?(name : String) : Array(UploadedFile)?
    @uploads.fetch?(name)
  end

  def each(& : {String, UploadedFile} ->) : Nil
    @uploads.each do |name, values|
      values.each do |value|
        yield({name, value})
      end
    end
  end

  def add(name : String, value : UploadedFile) : Nil
    (@uploads[name] ||= [] of UploadedFile) << value
  end

  def size : Int32
    @uploads.reduce(0) { |a, (_, values)| a + values.size }
  end
end
