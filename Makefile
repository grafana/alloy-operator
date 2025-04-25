IMG ?= ghcr.io/grafana/alloy-operator:$(VERSION)
HAS_HELM_DOCS := $(shell command -v helm-docs;)
HAS_MARKDOWNLINT := $(shell command -v markdownlint-cli2;)

ALLOY_HELM_CHART_VERSION := $(shell yq '.dependencies[].version' charts/alloy-helm-chart/Chart.yaml)
LATEST_ALLOY_HELM_CHART_VERSION = $(shell helm search repo alloy --output json | jq -r '.[].version')
VERSION ?= $(shell yq eval '.version' operator/helm-charts/alloy/Chart.yaml)

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
		yq eval '.version = "$(LATEST_ALLOY_HELM_CHART_VERSION)"' Chart.yaml > Chart_new.yaml && mv Chart_new.yaml Chart.yaml && \
		yq eval '.dependencies[0].version = "$(LATEST_ALLOY_HELM_CHART_VERSION)"' Chart.yaml > Chart_new.yaml && mv Chart_new.yaml Chart.yaml && \
		helm dependency update

##@ Build

.PHONY: build
build: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz build-image build-chart

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

operator/manifests/operator.yaml:
	cd operator/config/manager && kustomize edit set image controller=${IMG}
	kustomize build operator/config/default > $@

.PHONY: build-image
PLATFORMS ?= linux/arm64,linux/amd64
build-image: .temp/image-built
.temp/image-built: operator/Dockerfile operator/watches.yaml $(OPERATOR_ALLOY_HELM_CHART_FILES) ## Build docker image with the manager.
	docker buildx build --platform $(PLATFORMS) --tag ${IMG} operator
	mkdir -p .temp && touch .temp/image-built

.PHONY: push-image
push-image: ## Push docker image with the manager.
	docker push ${IMG}

# Alloy Operator Helm chart files
charts/alloy-operator/Chart.yaml: operator/helm-charts/alloy/Chart.yaml
	yq ".appVersion = \"$(VERSION)\"" -i charts/alloy-operator/Chart.yaml

charts/alloy-operator/README.md: charts/alloy-operator/values.yaml charts/alloy-operator/Chart.yaml
ifdef HAS_HELM_DOCS
	helm-docs --chart-search-root charts/alloy-operator
else
	docker run --rm --volume "$(shell pwd):/helm-docs" -u $(shell id -u) jnorwood/helm-docs:latest --chart-search-root charts/alloy-operator
endif

charts/alloy-operator/templates/crds/monitoring.grafana.com_podlogs.yaml: charts/alloy-helm-chart/charts/alloy-$(ALLOY_HELM_CHART_VERSION).tgz
	echo "{{- if .Values.crds.deployPodLogsCRD }}" > $@
	tar xvf $< --to-stdout alloy/charts/crds/crds/monitoring.grafana.com_podlogs.yaml >> $@
	echo "{{- end }}" >> $@

charts/alloy-operator/templates/crds/collectors.grafana.com_alloy.yaml:
	echo "{{- if .Values.crds.deployAlloyCRD }}" > $@
	kustomize build operator/config/crd >> $@
	echo "{{- end }}" >> $@

charts/alloy-operator/alloy-values.yaml: operator/helm-charts/alloy/values.yaml
	cp $< $@

.PHONY: build-chart-crds
build-chart-crds: charts/alloy-operator/templates/crds/collectors.grafana.com_alloy.yaml charts/alloy-operator/templates/crds/monitoring.grafana.com_podlogs.yaml

.PHONY: build-chart
build-chart: charts/alloy-operator/README.md charts/alloy-operator/Chart.yaml charts/alloy-operator/alloy-values.yaml build-chart-crds  ## Build the Helm chart.
	make -C charts/alloy-operator build

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
lint: lint-yaml lint-markdown ## Runs all linters.

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
	docker run -v $(shell pwd):/workdir davidanson/markdownlint-cli2 $(MARKDOWN_FILES)
endif

##@ Release

release: ## Release the Alloy Operator Helm chart
	gh workflow run release.yaml
