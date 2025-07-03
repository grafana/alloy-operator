HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

EXAMPLE_RELEASE_NAME := test
EXAMPLE_VALUES_FILES := $(shell find docs/examples -name values.yaml)
EXAMPLE_OUTPUT_FILES := $(EXAMPLE_VALUES_FILES:values.yaml=output.yaml)

docs/examples/%/output.yaml: docs/examples/%/values.yaml values.yaml Chart.yaml
	helm template --namespace operator $(EXAMPLE_RELEASE_NAME) . -f $< > $@

README.md: README.md.gotmpl values.yaml Chart.yaml
	docker run --rm --volume $(shell pwd):/chart ghcr.io/grafana/hackathon-13-helm-chart-toolbox-doc-generator:0.1.0 --chart /chart > $@

.SECONDEXPANSION:
values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --volume $(shell pwd):/chart ghcr.io/grafana/hackathon-13-helm-chart-toolbox-schema-generator:0.1.0 --chart /chart > $@

.PHONY: build
build: README.md values.schema.json $(EXAMPLE_OUTPUT_FILES)  ## Builds documentation and examples

.PHONY: clean
clean:  ## Deletes generated files
	rm -f README.md $(EXAMPLE_OUTPUT_FILES)

.PHONY: test
test:  ## Runs tests
ifdef HAS_HELM_UNITTEST
	helm unittest --failfast .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.17.0-0.7.1 --failfast .
endif
