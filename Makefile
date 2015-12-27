CRYSTAL_BIN ?= $(shell which crystal)
PWD = $(pwd)

.PHONY: doc

doc:
	mkdir -p doc
	cd .. && make doc
	cp -r ../doc/* doc/
