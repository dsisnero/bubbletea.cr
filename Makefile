.PHONY: install update format lint test clean build-examples check-go-port-inventory check-go-source-parity check-go-test-parity parity-specs parity-shell

CACHE_ROOT := $(abspath ./temp/cache)
PARITY_SPECS := $(wildcard spec/*_parity_spec.cr) $(wildcard spec/parity)
EXAMPLE_SRC_DIR := bubbletea-examples/src
EXAMPLE_OUT := $(abspath ./temp/examples)
EXAMPLE_CRYSTAL_PATH := $(abspath lib):$(abspath src):$(shell crystal env CRYSTAL_PATH)
EXAMPLE_SRCS := $(filter-out $(EXAMPLE_SRC_DIR)/bubbletea-examples.cr,$(wildcard $(EXAMPLE_SRC_DIR)/*.cr))
# Shards not present in ./lib: examples requiring them are skipped, not failed.
# `bubbles` is a separate port and is not a dependency of this shard.
EXAMPLE_MISSING_SHARDS := bubbles
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
	mkdir -p "$(EXAMPLE_OUT)"
	set -e; \
	for file in $(EXAMPLE_SRCS); do \
		name=$$(basename "$$file" .cr); \
		skip=; \
		for shard in $(EXAMPLE_MISSING_SHARDS); do \
			if [ ! -d "lib/$$shard" ] && grep -q "^require \"$$shard\"" "$$file"; then \
				skip="$$shard"; \
				break; \
			fi; \
		done; \
		if [ -n "$$skip" ]; then \
			echo "[build-examples] $$name (skip, needs $$skip)"; \
			continue; \
		fi; \
		out="$(EXAMPLE_OUT)/$$name"; \
		if [ -f "$$out" ] && [ "$$file" -ot "$$out" ]; then \
			echo "[build-examples] $$name (skip, up-to-date)"; \
		else \
			echo "[build-examples] $$name (build)"; \
			CRYSTAL_PATH="$(EXAMPLE_CRYSTAL_PATH)" \
				crystal build "$$file" -o "$$out"; \
		fi; \
	done

clean:
	if [ -d ./temp ]; then find ./temp -mindepth 1 -delete; fi

check-go-port-inventory:
	./bin/check_go_port_inventory.sh . docs/go_port_inventory.tsv vendor/bubbletea

check-go-source-parity:
	./bin/check_go_source_parity.sh . docs/go_source_parity.tsv vendor/bubbletea

check-go-test-parity:
	./bin/check_go_test_parity.sh . docs/go_test_parity.tsv vendor/bubbletea

parity-specs:
	./scripts/parity_env.sh crystal spec $(PARITY_SPECS)

parity-shell:
	@echo "Run: source ./scripts/parity_env.sh"
