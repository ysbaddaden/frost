CRYSTAL_BIN ?= $(shell which crystal)
test_files := $(shell find test -iname "*_test.cr")
record_test_files := $(shell find test/record -iname "*_test.cr")

.PHONY: tasks test doc notes stats

tasks:
	@echo "Available tasks:"
	@grep --color=never -e "^[a-z]\+:" Makefile | sed s/://g

test:
	bin/env.sh $(CRYSTAL_BIN) run test/record/schema.cr
	bin/env.sh $(CRYSTAL_BIN) run $(test_files)
	bin/env.sh $(CRYSTAL_BIN) run -D test_dependent_delete $(record_test_files)
	bin/env.sh $(CRYSTAL_BIN) run -D test_dependent_destroy $(record_test_files)
	bin/env.sh $(CRYSTAL_BIN) run -D test_dependent_nullify $(record_test_files)
	bin/env.sh $(CRYSTAL_BIN) run -D test_dependent_exception $(record_test_files)

doc:
	$(CRYSTAL_BIN) docs src/*.cr src/routing/mapper.cr src/support/callbacks.cr src/record.cr

src_files := $(wildcard src/*.cr) $(wildcard src/**/*.cr)
fixtures_files := $(wildcard test/fixtures/*.cr) $(wildcard test/fixtures/**/*.cr)

notes:
	@grep -oT -E '#\s+(NOTE|TODO|OPTIMIZE|FIXME).+' $(src_files) |\
		sed 's/:#\s*//g' |\
		awk -F'\t' '{print $$2" ("$$1")"}' | cut -b 2-

lines := $(shell cat $(src_files) | grep -v "^$$" | wc -l )
tests := $(shell cat $(fixtures_files) $(test_files) | grep -v '^$$' | wc -l )

stats:
	@echo " code: $(lines)"
	@echo "tests: $(tests)"
	@echo -n "ratio: `echo 'scale=6; 1.0 / $(lines) * $(tests)' | bc -q`"
	@echo " (code-to-test)"
