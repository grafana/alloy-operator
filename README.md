# Alloy Operator

The Alloy Operator is a Kubernetes Operator that manages the lifecycle of [Grafana Alloy](https://grafana.com/docs/alloy/latest/)
instances. It is built with the [Operator SDK](https://sdk.operatorframework.io/) using the [Alloy Helm chart](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy)
as its base.

## Usage

To use the Alloy Operator, there are three steps to follow:

1. Deploy the Alloy CustomResourceDefinition (CRD).
2. Deploy the Alloy Operator.
3. Deploy an Alloy instance.

### Install the CRD

```shell
$ kubectl apply -f https://raw.githubusercontent.com/grafana/alloy-operator/refs/heads/main/operator/manifests/crd.yaml
```

### Install the Operator

```shell
$ kubectl apply -f https://raw.githubusercontent.com/grafana/alloy-operator/refs/heads/main/operator/manifests/operator.yaml
```

### Deploy an Alloy instance

Create a file for your Alloy instance:

```yaml
---
apiVersion: collectors.grafana.com/v1alpha1
kind: Alloy
metadata:
  name: alloy-test
spec:
  alloy:
    configMap:
      content: |-
        prometheus.exporter.self "default" {}

        prometheus.scrape "default" {
          targets    = prometheus.exporter.self.default.targets
          forward_to = [prometheus.remote_write.local_prom.receiver]
        }

        prometheus.remote_write "local_prom" {
          endpoint {
            url = "http://prometheus-server.prometheus.svc:9090/api/v1/write"
          }
        }
```

The `spec` section supports all fields in the
[Alloy Helm chart](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy)'s values file.

For some examples, see the integration tests that are used within this repository:

*   [Basic Alloy instance](tests/integration/basic/alloy.yaml)
*   [DaemonSet with HostPath volume mounts](tests/integration/daemonset-with-volumes/alloy.yaml)
*   [StatefulSet with WAL](tests/integration/statefulset-with-wal/alloy.yaml)

NOTE: The Alloy instances *do not* deploy the PodLogs CRD, nor does it support the `crds` field in the `spec`.

## Contributing

We welcome contributions to the Grafana Alloy Operator! Please see our [Contributing Guide](./CONTRIBUTING.md) for more information.
