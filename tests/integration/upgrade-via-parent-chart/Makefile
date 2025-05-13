CLUSTER_NAME ?= upgrade-test-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@kind create cluster --name $(CLUSTER_NAME) --kubeconfig $(KUBECONFIG)

deploy-dependencies: $(KUBECONFIG)
	@echo "Deploying flux..."
	@flux --kubeconfig $(KUBECONFIG) install --components=source-controller,helm-controller

	@echo "Deploying dependencies..."
	@kubectl --kubeconfig $(KUBECONFIG) apply -f dependencies --wait
	@HELM_RELEASE_COUNT=$$(flux --kubeconfig $(KUBECONFIG) get helmreleases --all-namespaces | wc -l); \
	while [ $$(flux --kubeconfig $(KUBECONFIG) get helmreleases --all-namespaces --status-selector ready=true | wc -l) -lt $${HELM_RELEASE_COUNT} ]; do \
		sleep 5; \
	done

deploy: $(KUBECONFIG)
	@echo "Deploying the test chart without CRDs..."
	@helm --kubeconfig $(KUBECONFIG) upgrade --install sample-parent-chart ../../../charts/sample-parent-chart -f values-first.yaml --wait

	@echo "Deploying the Alloy CRD..."
	@kubectl --kubeconfig $(KUBECONFIG) apply -f ../../../charts/alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml

	@echo "Upgrading the test chart..."
	@helm --kubeconfig $(KUBECONFIG) upgrade sample-parent-chart ../../../charts/sample-parent-chart -f values-second.yaml --wait

test:
	@echo "Running tests..."
	@helm --kubeconfig $(KUBECONFIG) list -a
	@helm --kubeconfig $(KUBECONFIG) test sample-parent-chart --logs

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@kind --kubeconfig $(KUBECONFIG) delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
