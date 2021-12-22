.POSIX:

CRYSTAL = crystal
CRFLAGS =
TESTS = test/*_test.cr test/**/*_test.cr
OPTS =

all: test

test: .phony
	$(CRYSTAL) run $(CRFLAGS) $(TESTS) -- $(OPTS)

.phony:
