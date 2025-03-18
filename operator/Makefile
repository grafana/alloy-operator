VERSION ?= $(shell yq eval '.version' helm-charts/alloy/Chart.yaml)
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

vendir.lock.yml: vendir.yml
	vendir sync
	rm -rf helm-charts/alloy/charts helm-charts/alloy/Chart.lock
	yq 'del(.dependencies[] | select(.name == "crds"))' -i helm-charts/alloy/Chart.yaml
	yq 'del(.crds)' -i helm-charts/alloy/values.yaml
	cd helm-charts/alloy && helm dependency build

helm-charts/alloy/Chart.yaml: vendir.lock.yml
	vendir sync --locked
	rm -rf helm-charts/alloy/charts helm-charts/alloy/Chart.lock
	yq 'del(.dependencies[] | select(.name == "crds"))' -i helm-charts/alloy/Chart.yaml
	yq 'del(.crds)' -i helm-charts/alloy/values.yaml
	cd helm-charts/alloy && helm dependency build

ALLOY_HELM_FILES ?= $(shell find helm-charts/alloy -type f)

.PHONY: build
build: build-alloy build-crd build-manifest build-image

.PHONY: build-alloy
build-alloy: helm-charts/alloy/Chart.yaml## Build Alloy helm chart.

.PHONY: build-image
PLATFORMS ?= linux/arm64,linux/amd64
build-image: .temp/build-image
.temp/build-image: Dockerfile watches.yaml $(ALLOY_HELM_FILES) ## Build docker image with the manager.
	docker buildx build --platform $(PLATFORMS) --tag ${IMG} .
	touch .temp/build-image

.PHONY: push-image
push-image: ## Push docker image with the manager.
	docker push ${IMG}

.PHONY: docker-build
build-crd: manifests/crd.yaml ## Build CRD manifest.
manifests/crd.yaml:
	kustomize build config/crd > $@

.PHONY: docker-build
build-manifest: manifests/operator.yaml ## Build operator manifest.
manifests/operator.yaml:
	cd config/manager && kustomize edit set image controller=${IMG}
	kustomize build config/default > $@

.PHONY: clean
clean:
	rm -rf .temp
	rm -f manifests/crd.yaml
	rm -f manifests/operator.yaml

##@ Deployment

.PHONY: install
install: manifests/crd.yaml ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	kubectl apply -f manifests/crd.yaml

.PHONY: uninstall
uninstall: manifests/crd.yaml ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	kubectl delete -f manifests/crd.yaml

.PHONY: deploy
deploy: manifests/operator.yaml ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	kubectl apply -f manifests/operator.yaml

.PHONY: undeploy
undeploy: manifests/operator.yaml ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	kubectl delete -f manifests/operator.yaml
