.PHONY: install update format lint test clean build-examples check-go-port-inventory check-go-source-parity check-go-test-parity

CACHE_ROOT := $(abspath ./temp/cache)
export CRYSTAL_CACHE_DIR := $(CACHE_ROOT)/crystal
export SHARDS_CACHE_PATH := $(CACHE_ROOT)/shards
export GOCACHE := $(CACHE_ROOT)/go-build
export GOMODCACHE := $(CACHE_ROOT)/go-mod
export GOFLAGS := -modcacherw

install:
	mkdir -p "$(CACHE_ROOT)"
	BEADS_DIR=$$(pwd)/.beads shards install

update:
	mkdir -p "$(CACHE_ROOT)"
	BEADS_DIR=$$(pwd)/.beads shards update

format:
	crystal tool format --check

lint:
	ameba --fix
	ameba

test:
	crystal spec

build-examples:
	mkdir -p ./temp/examples
	set -e; \
	for file in ./examples/*.cr; do \
		name=$$(basename "$$file" .cr); \
		out="./temp/examples/$$name"; \
		if [ -f "$$out" ] && [ "$$file" -ot "$$out" ]; then \
			echo "[build-examples] $$name (skip, up-to-date)"; \
		else \
			echo "[build-examples] $$name (build)"; \
			crystal build "$$file" -o "$$out"; \
		fi; \
	done

clean:
	if [ -d ./temp ]; then find ./temp -mindepth 1 -delete; fi
	for file in ./examples/*.cr; do \
		name=$$(basename "$$file" .cr); \
		rm -f "./examples/$$name"; \
	done

check-go-port-inventory:
	./bin/check_go_port_inventory.sh . docs/go_port_inventory.tsv vendor/bubbletea

check-go-source-parity:
	./bin/check_go_source_parity.sh . docs/go_source_parity.tsv vendor/bubbletea

check-go-test-parity:
	./bin/check_go_test_parity.sh . docs/go_test_parity.tsv vendor/bubbletea
