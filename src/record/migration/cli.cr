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
    Frost::Record::Migration.all.each(&.execute("up"))
    Frost::Record::Schema.dump_structure(filename)

  when "up", "down"
    unless version = ENV["VERSION"]?
      STDERR.puts "ERROR: you must specify a VERSION"
      exit
    end
    Frost::Record::Migration.find(version).execute(action)
    Frost::Record::Schema.dump_structure(filename)

  when "redo"
    step = ENV.fetch("STEP", "1").to_i

    Frost::Record::Migration.all[-step .. -1].tap do |migrations|
      migrations.reverse_each(&.execute("down"))
      migrations.each(&.execute("up"))
    end
    Frost::Record::Schema.dump_structure(filename)

  when "load"
    Frost::Record::Schema.load_structure(filename)

  when "dump"
    Frost::Record::Schema.dump_structure(filename)

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
