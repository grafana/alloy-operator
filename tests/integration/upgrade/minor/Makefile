CLUSTER_NAME ?= minor-upgrade-test-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml
ALLOY_OPERATOR_VERSION ?= $(shell yq .version ../../../../charts/alloy-operator/Chart.yaml)
PREVIOUS_ALLOY_OPERATOR_MINOR_VERSION ?= $(shell echo $(ALLOY_OPERATOR_VERSION) | awk -F. '{printf "%d.%d", $$1, $$2-1}')
TEST_SHOULD_RUN ?= $(shell echo "$${ALLOY_OPERATOR_VERSION}" | grep -q "[[:digit:]]\+\.0\.[[:digit:]]\+" && echo "false" || echo "true")

check:
	echo $(PREVIOUS_ALLOY_OPERATOR_MINOR_VERSION)

ifeq ($(TEST_SHOULD_RUN), "false")
create-cluster: ;
deploy-dependencies: ;
deploy: ;
test: ;
delete-cluster: ;

else

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@kind create cluster --name $(CLUSTER_NAME) --kubeconfig $(KUBECONFIG)

deploy-dependencies: $(KUBECONFIG)
	# TODO: Add a configmap with the Alloy Operator version
	# TODO: Attach that configmap to the Alloy instance and use that to add a `version` label
	# TODO: Update queries to look for the version

	@echo "Deploying flux..."
	@flux install --components=source-controller,helm-controller

	@echo "Deploying dependencies..."
	@kubectl apply -f dependencies --wait
	@HELM_RELEASE_COUNT=$$(flux get helmreleases --all-namespaces | wc -l); \
	while [ $$(flux get helmreleases --all-namespaces --status-selector ready=true | wc -l) -lt $${HELM_RELEASE_COUNT} ]; do \
		sleep 5; \
	done

deploy: $(KUBECONFIG)
	@echo "Deploying Alloy Operator..."
	@helm upgrade --install alloy-operator -n operator --create-namespace --version $(PREVIOUS_ALLOY_OPERATOR_MINOR_VERSION) grafana/alloy-operator --wait

	@echo "Deploying Alloy object..."
	@kubectl apply -f alloy.yaml --wait

	@echo "Upgrading Alloy Operator..."
	@helm upgrade --install alloy-operator -n operator --create-namespace ../../../charts/alloy-operator --wait

test:
	@echo "Running tests..."
	@helm test k8s-monitoring-test --logs

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@kind delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG)

endif
run-test: create-cluster deploy-dependencies deploy test
