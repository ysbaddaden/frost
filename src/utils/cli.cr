require "../support/inflections"
require "../view/ecr_processor"

case ARGV[0]?
when "ecr"
  filename = ARGV[1]? || abort "fatal: please specify ECR template"
  puts Frost::View.ecr_processor(filename, ARGV[2]?)
when "ls"
  glob = ARGV[1]? || abort "fatal: missing glob"
  print Dir[glob].join('\n')
when "singularize"
  word = ARGV[1]? || abort "fatal: missing word"
  print Frost::Inflections.singularize(word)
when "pluralize"
  word = ARGV[1]? || abort "fatal: missing word"
  print Frost::Inflections.pluralize(word)
when nil
  abort "fatal: missing command"
else
  abort "fatal: unknown command '#{ARGV[0]}'"
end
