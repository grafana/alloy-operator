CLUSTER_NAME ?= remote-config-cluster-$(RANDOM_NUMBER)
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	@echo "Creating cluster $(CLUSTER_NAME)..."
	@kind create cluster --name $(CLUSTER_NAME) --kubeconfig $(KUBECONFIG)

dependencies/test-variables.yaml:
	echo "---" > $@
	kubectl create configmap test-variables \
		--from-literal=CLUSTER="$(CLUSTER_NAME)" \
		--from-literal=RANDOM_NUMBER="$$RANDOM_NUMBER" \
		-o yaml --dry-run=client >> $@

dependencies/grafana-cloud-credentials.yaml:
	echo "---" > $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
  		--from-literal=GRAFANA_CLOUD_FLEET_MGMT_USER="$$GRAFANA_CLOUD_FLEET_MGMT_USER" \
  		--from-literal=GRAFANA_CLOUD_FLEET_MGMT_TOKEN="$$GRAFANA_CLOUD_FLEET_MGMT_TOKEN" \
  		--from-literal=PROMETHEUS_USER="$$GRAFANA_CLOUD_METRICS_USERNAME" \
  		--from-literal=PROMETHEUS_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@

deploy-dependencies: $(KUBECONFIG) dependencies/test-variables.yaml dependencies/grafana-cloud-credentials.yaml
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
