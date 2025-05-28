HAS_HELM_DOCS := $(shell command -v helm-docs;)
HAS_MARKDOWNLINT := $(shell command -v markdownlint-cli2;)
HAS_ZIZMOR := $(shell command -v zizmor;)

LATEST_ALLOY_HELM_CHART_VERSION = $(shell helm show chart grafana/alloy | yq -r '.version')
ALLOY_HELM_CHART_VERSION := $(shell yq '.dependencies[].version' charts/alloy-helm-chart/Chart.yaml)
ALLOY_OPERATOR_IMAGE = ghcr.io/grafana/alloy-operator:$(ALLOY_HELM_CHART_VERSION)
ALLOY_OPERATOR_HELM_CHART_VERSION = $(shell yq '.version' charts/alloy-operator/Chart.yaml)

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Dependencies

charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz:
	cd charts/alloy-helm-chart && helm dependency update

.PHONY: update-alloy-to-latest
update-alloy-to-latest: ## Updates the Alloy chart to the latest version in the Helm repository
	@echo "Upgrading Alloy from $(ALLOY_HELM_CHART_VERSION) to $(LATEST_ALLOY_HELM_CHART_VERSION)"
	cd charts/alloy-helm-chart && \
		yq eval '.version = "$(LATEST_ALLOY_HELM_CHART_VERSION)"' -i Chart.yaml && \
		yq eval '.dependencies[0].version = "$(LATEST_ALLOY_HELM_CHART_VERSION)"' -i Chart.yaml && \
		helm dependency update

##@ Build

.PHONY: build
build: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz build-image build-chart build-test-chart

UPSTREAM_ALLOY_HELM_CHART_FILES = $(shell tar -tzf charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz)
UPSTREAM_ALLOY_HELM_CHART_CRDS_FILES = $(filter alloy/charts/%, $(UPSTREAM_ALLOY_HELM_CHART_FILES))
UNMODIFIED_UPSTREAM_ALLOY_HELM_CHART_FILES = $(filter-out alloy/values.yaml alloy/Chart.yaml alloy/Chart.lock $(UPSTREAM_ALLOY_HELM_CHART_CRDS_FILES), $(UPSTREAM_ALLOY_HELM_CHART_FILES))
UNMODIFIED_OPERATOR_ALLOY_HELM_CHART_FILES = $(patsubst %, operator/helm-charts/%, $(UNMODIFIED_UPSTREAM_ALLOY_HELM_CHART_FILES))
OPERATOR_ALLOY_HELM_CHART_FILES = $(UNMODIFIED_OPERATOR_ALLOY_HELM_CHART_FILES) operator/helm-charts/alloy/Chart.yaml operator/helm-charts/alloy/values.yaml
operator/helm-charts/%: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz
	@mkdir -p $(shell dirname $@)
	tar xzf $< -C operator/helm-charts $* && touch $@

operator/helm-charts/alloy/Chart.yaml: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz
	tar xzf $< -C operator/helm-charts alloy/Chart.yaml
	yq 'del(.dependencies[] | select(.name == "crds"))' -i operator/helm-charts/alloy/Chart.yaml

operator/helm-charts/alloy/values.yaml: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz
	tar xzf $< -C operator/helm-charts alloy/values.yaml
	yq 'del(.crds)' -i operator/helm-charts/alloy/values.yaml

operator/manifests/crd.yaml:
	kustomize build operator/config/crd > $@

operator/manifests/operator.yaml: charts/alloy-helm-chart/Chart.yaml
	cd operator/config/manager && kustomize edit set image controller=${ALLOY_OPERATOR_IMAGE}
	kustomize build operator/config/default > $@

.PHONY: build-image
PLATFORMS ?= linux/arm64,linux/amd64
build-image: .temp/image-built-${ALLOY_HELM_CHART_VERSION}
.temp/image-built-${ALLOY_HELM_CHART_VERSION}: operator/Dockerfile operator/watches.yaml $(OPERATOR_ALLOY_HELM_CHART_FILES) charts/alloy-helm-chart/Chart.yaml ## Build docker image with the manager.
	docker buildx build --platform $(PLATFORMS) --tag ${ALLOY_OPERATOR_IMAGE} operator
	mkdir -p .temp && touch .temp/image-built-${ALLOY_HELM_CHART_VERSION}

.PHONY: push-image
push-image: .temp/image-built-${ALLOY_HELM_CHART_VERSION} charts/alloy-helm-chart/Chart.yaml ## Push docker image with the manager.
	docker push ${ALLOY_OPERATOR_IMAGE}

# Alloy Operator Helm chart files
charts/alloy-operator/Chart.yaml: charts/alloy-helm-chart/Chart.yaml
	yq ".appVersion = \"$(ALLOY_HELM_CHART_VERSION)\"" -i charts/alloy-operator/Chart.yaml

charts/alloy-operator/README.md: charts/alloy-operator/values.yaml charts/alloy-operator/Chart.yaml
ifdef HAS_HELM_DOCS
	helm-docs --chart-search-root charts/alloy-operator
else
	docker run --rm --volume "$(shell pwd):/helm-docs" -u $(shell id -u) jnorwood/helm-docs:latest --chart-search-root charts/alloy-operator
endif

charts/alloy-operator/charts/podlogs-crd/crds/monitoring.grafana.com_podlogs.yaml: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz
	tar xvf $< --to-stdout alloy/charts/crds/crds/monitoring.grafana.com_podlogs.yaml > $@

charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml:
	kustomize build operator/config/crd > $@

charts/alloy-operator/alloy-values.yaml: operator/helm-charts/alloy/values.yaml
	cp $< $@

.PHONY: build-chart-crds
build-chart-crds: charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml charts/alloy-operator/charts/podlogs-crd/crds/monitoring.grafana.com_podlogs.yaml

.PHONY: build-charts
build-charts: charts/alloy-operator/README.md charts/alloy-operator/Chart.yaml charts/alloy-operator/alloy-values.yaml build-chart-crds  ## Build the Helm chart.
	make -C charts/alloy-operator build

charts/sample-parent-chart/Chart.yaml: charts/alloy-operator/Chart.yaml
	cd charts/sample-parent-chart && \
		yq eval '.dependencies[0].version = "$(ALLOY_OPERATOR_HELM_CHART_VERSION)"' Chart.yaml > Chart.new.yaml && mv Chart.new.yaml Chart.yaml && \
		helm dependency update

.PHONY: build-test-chart
build-test-chart: charts/sample-parent-chart/Chart.yaml   ## Build the test Helm chart.

.PHONY: clean
clean: ## Clean up build artifacts.
	rm -rf .temp
	rm -f operator/manifests/crd.yaml
	rm -f operator/manifests/operator.yaml
	rm -rf charts/alloy-helm-chart/charts
	rm -f charts/alloy-helm-chart/Chart.lock

##@ Test

#test: ## Run all tests.
#	make -C charts/alloy-operator test

.PHONY: lint
lint: lint-yaml lint-markdown lint-zizmor ## Runs all linters.

YAML_FILES ?= $(shell find . -name "*.yaml" -not -path "./operator/*")
.PHONY: lint-yaml
lint-yaml: $(YAML_FILES) ## Lint yaml files.
	@yamllint $(YAML_FILES)

MARKDOWN_FILES ?= $(shell find . -name "*.md" -not -path "./operator/helm-charts/*")
.PHONY: lint-markdown
lint-markdown: $(MARKDOWN_FILES)  ## Lint markdown files.
ifdef HAS_MARKDOWNLINT
	markdownlint-cli2 $(MARKDOWN_FILES)
else
	docker run --rm --volume $(shell pwd):/workdir davidanson/markdownlint-cli2 $(MARKDOWN_FILES)
endif

.PHONY: lint-zizmor
lint-zizmor: ## Statically analyze GitHub Action workflows
ifdef HAS_ZIZMOR
	zizmor .
else
	docker run --rm --volume $(shell pwd):/src ghcr.io/woodruffw/zizmor@sha256:ebb58dabdf1cd44db1c260a81b555e94ea6dba798cd1bfde378cbfed8f493dde /src  # v1.6.0
endif

##@ Release

release: ## Release the Alloy Operator Helm chart
	gh workflow run release.yaml
