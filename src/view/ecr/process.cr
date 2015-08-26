require "./ecr"
puts Trail::View::ECR.process_file(ARGV[0], ARGV[1])
