require "../support/core_ext/string"

class LoadFixtures
  def initialize(@path)
  end

  def models
    @models ||= Dir[File.join(@path, "*.yml")].map do |path|
      file_name = File.basename(path)
      table_name = file_name[0 ... -4]
      class_name = table_name.singularize.camelcase
      {class_name, table_name, path}
    end
  end

  def each
    models.each { |a| yield a[0], a[1], a[2] }
  end

  def to_crystal_s(io : IO)
    io << "\n"

    io << "def preload_fixtures\n"
    each do |class_name, _, path|
      io << "  load_fixtures " << class_name << ", " << path.inspect << "\n"
    end
    io << "end\n\n"

    each do |class_name, table_name, _|
      io << "def " << table_name << "(name)\n"
      io << "  cache = @" << table_name << "_fixtures_cache ||= {} of String => " << class_name << "\n"
      io << "  cache[name.to_s] ||= " << class_name << ".find(fixture_id(" << table_name.inspect << ", name))\n"
      io << "end\n\n"
    end

    io << "def clear_fixtures_cache\n"
    each do |class_name, table_name, _|
      io << "  if cache = @" << table_name << "_fixtures_cache\n"
      io << "    cache.clear\n"
      io << "  end\n"
    end
    io << "end\n"
  end
end

LoadFixtures.new(ARGV[0]).to_crystal_s(STDOUT)
