CLUSTER_NAME ?= upgrade-test-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@kind create cluster --name $(CLUSTER_NAME) --kubeconfig $(KUBECONFIG)

deploy-dependencies: $(KUBECONFIG)
	@echo "Deploying flux..."
	@flux install --components=source-controller,helm-controller

	@echo "Deploying dependencies..."
	@kubectl apply -f dependencies --wait
	@HELM_RELEASE_COUNT=$$(flux get helmreleases --all-namespaces | wc -l); \
	while [ $$(flux get helmreleases --all-namespaces --status-selector ready=true | wc -l) -lt $${HELM_RELEASE_COUNT} ]; do \
		sleep 5; \
	done

deploy: $(KUBECONFIG)
	@echo "Deploying the test chart without CRDs..."
	@helm upgrade --install sample-parent-chart ../../../charts/sample-parent-chart -f values-first.yaml --wait

	@echo "Deploying the Alloy CRD..."
	@kubectl apply -f ../../../charts/alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml

	@echo "Upgrading the test chart..."
	@helm upgrade sample-parent-chart ../../../charts/sample-parent-chart -f values-second.yaml --wait

test:
	@echo "Running tests..."
	@helm test k8s-monitoring-test --logs

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@kind delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
