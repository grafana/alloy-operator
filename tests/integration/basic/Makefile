CLUSTER_NAME ?= basic-test-cluster
KUBECONFIG ?= $(shell pwd)/kubeconfig.yaml

create-cluster: $(KUBECONFIG)
$(KUBECONFIG):
	kind create cluster --name $(CLUSTER_NAME) --kubeconfig $(KUBECONFIG)

deploy-dependencies: $(KUBECONFIG)
	flux install
	kubectl apply -f dependencies --wait
	HELM_RELEASE_COUNT=$$(flux get helmreleases --all-namespaces | wc -l); \
	while [ $$(flux get helmreleases --all-namespaces --status-selector ready=true | wc -l) -lt $${HELM_RELEASE_COUNT} ]; do \
		sleep 5; \
	done

deploy: $(KUBECONFIG)
	make -C ../../.. install
	make -C ../../.. deploy
	kubectl apply -f alloy.yaml --wait

test:
	helm test k8s-monitoring-test

delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)
	rm -f $(KUBECONFIG)

run-test: $(KUBECONFIG) deploy-dependencies deploy test
