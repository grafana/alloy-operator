CLUSTER_NAME ?= statefulset-with-wal
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
	@echo "Deploying Alloy Operator..."
	@helm install alloy-operator -n operator --create-namespace ../../../charts/alloy-operator --wait

	@echo "Deploying Alloy object..."
	@kubectl apply -f alloy.yaml --wait

test:
	@echo "Running tests..."
	@helm test k8s-monitoring-test --logs || kubectl get pods --all-namespaces

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@kind delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
