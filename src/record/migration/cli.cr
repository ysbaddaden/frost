require "../migration"
require "../schema"

at_exit do
  ARGV.reject! do |arg|
    if arg =~ /([a-zA-Z0-9_]+)=(.+)/
      ENV[$1] = $2
    end
  end

  filename = File.join("db", "structure.sql")

  case action = ARGV[0]?
  when "migrate"
    Trail::Record::Migration.all.each(&.execute("up"))
    Trail::Record::Schema.dump_structure(filename)

  when "up", "down"
    unless version = ENV["VERSION"]?
      STDERR.puts "ERROR: you must specify a VERSION"
      exit
    end
    Trail::Record::Migration.find(version).execute(action)
    Trail::Record::Schema.dump_structure(filename)

  when "redo"
    step = ENV.fetch("STEP", "1").to_i

    Trail::Record::Migration.all[-step .. -1].tap do |migrations|
      migrations.reverse_each(&.execute("down"))
      migrations.each(&.execute("up"))
    end
    Trail::Record::Schema.dump_structure(filename)

  when "load"
    Trail::Record::Schema.load_structure(filename)

  when "dump"
    Trail::Record::Schema.dump_structure(filename)

  else
    STDERR.puts "Available commands:"
    STDERR.puts "  migrate        — runs all pending migrations"
    STDERR.puts "  up VERSION=X   — runs the migration versioned X"
    STDERR.puts "  down VERSION=X — reverts the migration versioned X"
    STDERR.puts "  redo STEP=N    — migrates down then up the N last migrations"
    STDERR.puts "  dump           — dumps the current schema as db/structure.sql"
    STDERR.puts "  load           — loads previously dumped db/structure.sql schema"
    exit
  end
end
