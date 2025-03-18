VERSION ?= $(shell yq eval '.version' helm-charts/alloy/Chart.yaml)
IMG ?= ghcr.io/grafana/alloy-operator:$(VERSION)

.PHONY: all
all: docker-build

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

ALLOY_HELM_FILES ?= $(shell find helm-charts/alloy -type f)

.PHONY: build
build: build-crd build-manifest build-image

.PHONY: build-image
build-image: .temp/build-image
.temp/build-image: Dockerfile watches.yaml $(ALLOY_HELM_FILES) ## Build docker image with the manager.
	docker build -t ${IMG} .
	mkdir -p .temp && touch .temp/build-image

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

# PLATFORMS defines the target platforms for  the manager image be build to provide support to multiple
# architectures. (i.e. make docker-buildx IMG=myregistry/mypoperator:0.0.1). To use this option you need to:
# - able to use docker buildx . More info: https://docs.docker.com/build/buildx/
# - have enable BuildKit, More info: https://docs.docker.com/develop/develop-images/build_enhancements/
# - be able to push the image for your registry (i.e. if you do not inform a valid value via IMG=<myregistry/image:<tag>> than the export will fail)
# To properly provided solutions that supports more than one platform you should use this option.
PLATFORMS ?= linux/arm64,linux/amd64
.PHONY: docker-buildx
docker-buildx: ## Build and push docker image for the manager for cross-platform support
	- docker buildx create --name project-v3-builder
	docker buildx use project-v3-builder
	- docker buildx build --push --platform=$(PLATFORMS) --tag ${IMG} -f Dockerfile .
	- docker buildx rm project-v3-builder

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
