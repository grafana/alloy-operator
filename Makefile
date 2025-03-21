VERSION ?= $(shell yq eval '.version' operator/helm-charts/alloy/Chart.yaml)
IMG ?= ghcr.io/grafana/alloy-operator:$(VERSION)

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

##@ Build

.PHONY: build
build: build-alloy build-image

.PHONY: build-alloy
build-alloy: operator/helm-charts/alloy/Chart.yaml ## Build Alloy helm chart.

vendir.lock.yml: vendir.yml
	vendir sync

operator/helm-charts/alloy/Chart.yaml: vendir.lock.yml
	vendir sync --locked
	yq 'del(.dependencies[] | select(.name == "crds"))' -i operator/helm-charts/alloy/Chart.yaml
	yq 'del(.crds)' -i operator/helm-charts/alloy/values.yaml

operator/manifests/crd.yaml:
	kustomize build operator/config/crd > $@

operator/manifests/operator.yaml:
	cd operator/config/manager && kustomize edit set image controller=${IMG}
	kustomize build operator/config/default > $@


.PHONY: build-image
PLATFORMS ?= linux/arm64,linux/amd64
build-image: .temp/image-built
ALLOY_HELM_FILES ?= $(shell find operator/helm-charts/alloy -type f)
.temp/image-built: operator/Dockerfile operator/watches.yaml operator/helm-charts/alloy/Chart.yaml $(ALLOY_HELM_FILES) ## Build docker image with the manager.
	docker buildx build --platform $(PLATFORMS) --tag ${IMG} operator
	mkdir -p .temp && touch .temp/image-built

.PHONY: push-image
push-image: ## Push docker image with the manager.
	docker push ${IMG}

.PHONY: clean
clean: ## Clean up build artifacts.
	rm -rf .temp
	rm -f operator/manifests/crd.yaml
	rm -f operator/manifests/operator.yaml

# Alloy Operator Helm chart files
charts/alloy-operator/Chart.yaml: operator/helm-charts/alloy/Chart.yaml
	yq ".appVersion = \"$(VERSION)\"" -i charts/alloy-operator/Chart.yaml

charts/alloy-operator/charts/pod-logs-crd/crds/monitoring.grafana.com_podlogs.yaml: vendir.lock.yml
	vendir sync --locked

charts/alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml : operator/manifests/crd.yaml
	cp $< $@

build-chart: charts/alloy-operator/Chart.yaml charts/alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml charts/alloy-operator/charts/pod-logs-crd/crds/monitoring.grafana.com_podlogs.yaml

##@ Test

.PHONY: install-alloy-crd
install-alloy-crd: operator/manifests/crd.yaml	## Installs the Alloy CRD into the current K8s cluster.
	kubectl apply -f operator/manifests/crd.yaml

.PHONY: uninstall-alloy-crd
uninstall-alloy-crd: operator/manifests/crd.yaml ## Uninstall CRDs from the current K8s cluster.
	kubectl delete -f operator/manifests/crd.yaml

.PHONY: deploy-operator
deploy-operator: operator/manifests/operator.yaml ## Deploy controller to the current K8s cluster.
	kubectl apply -f operator/manifests/operator.yaml

.PHONY: undeploy-operator
undeploy-operator: operator/manifests/operator.yaml ## Undeploy controller from the current K8s cluster.
	kubectl delete -f operator/manifests/operator.yaml

.PHONY: lint
lint: lint-yaml ## Runs all linters.
	yamllint
	kubectl apply -f manifests/crd.yaml

YAML_FILES ?= $(shell find . -name "*.yaml" -not -path "./operator/helm-charts/*")
.PHONY: lint-yaml
lint-yaml: $(YAML_FILES) ## Lint yaml files.
	@yamllint $(YAML_FILES)
