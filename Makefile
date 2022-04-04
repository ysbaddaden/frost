.POSIX:

CRYSTAL = crystal
CRFLAGS =
TESTS = test/*_test.cr test/**/*_test.cr
OPTS =

all: bin/utils

bin/utils: src/utils/cli.cr
	$(CRYSTAL) build -Dgc_none $(CRFLAGS) -o $@ $<

bin: .phony
	@mkdir -p bin

test: .phony
	$(CRYSTAL) run $(CRFLAGS) $(TESTS) -- $(OPTS)

clean: .phony
	rm -f bin/utils

.phony:
