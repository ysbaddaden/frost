require "./ecr"
puts Frost::View::ECR.process_file(ARGV[0], ARGV[1])
