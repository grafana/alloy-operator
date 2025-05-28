CLUSTER_NAME ?= daemonset-test-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@kind create cluster --name $(CLUSTER_NAME) --config kind-cluster-config.yaml --kubeconfig $(KUBECONFIG)

deploy-dependencies: $(KUBECONFIG)
	@echo "Deploying dependencies..."
	@flux --kubeconfig $(KUBECONFIG) install --components=source-controller,helm-controller
	@kubectl --kubeconfig $(KUBECONFIG) apply -f dependencies --wait
	@HELM_RELEASE_COUNT=$$(flux --kubeconfig $(KUBECONFIG) get helmreleases --all-namespaces | wc -l); \
	while [ $$(flux --kubeconfig $(KUBECONFIG) get helmreleases --all-namespaces --status-selector ready=true | wc -l) -lt $${HELM_RELEASE_COUNT} ]; do \
		sleep 5; \
	done

deploy: $(KUBECONFIG)
	@echo "Deploying Alloy Operator..."
	@helm --kubeconfig $(KUBECONFIG) upgrade --install alloy-operator -n operator --create-namespace ../../../charts/alloy-operator --wait

	@echo "Deploying Alloy object..."
	@kubectl --kubeconfig $(KUBECONFIG) apply -f alloy.yaml --wait

test:
	@echo "Running tests..."
	@helm --kubeconfig $(KUBECONFIG) list -a
	@helm --kubeconfig $(KUBECONFIG) test alloy-logs --logs

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@kind --kubeconfig $(KUBECONFIG) delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
