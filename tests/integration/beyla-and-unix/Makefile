CLUSTER_NAME ?= beyla-and-unix-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@minikube start

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
	@helm upgrade --install alloy-operator -n operator --create-namespace ../../../charts/alloy-operator --wait

	@echo "Deploying Alloy object..."
	@kubectl apply -f alloy.yaml --wait

test:
	@echo "Running tests..."
	@helm test k8s-monitoring-test --logs

delete-cluster:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	@minikube delete
	@rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
