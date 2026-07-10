# Alloy Operator

The Alloy Operator is a Kubernetes Operator that manages the lifecycle of
[Grafana Alloy](https://grafana.com/docs/alloy/latest/) instances. It is built with the
[Operator SDK](https://sdk.operatorframework.io/) using the
[Alloy Helm chart](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) as its base.

## Current version

[//]: # (Version table start)

| Component        | Version |
|------------------|---------|
| Alloy Operator   | 0.5.11 |
| Alloy Helm chart | 1.10.1 |
| Alloy binary     | v1.17.1 |

[//]: # (Version table end)

## Usage

To use the Alloy Operator, there are two steps to follow:

1. Deploy the Alloy Operator.
1. Deploy an Alloy instance.

### Deploy the Alloy Operator

```shell
$ helm install alloy-operator grafana/alloy-operator
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

For some examples, see the tests that are used within this repository:

* [Basic Alloy instance](tests/integration/basic/alloy.yaml)
* [DaemonSet with HostPath volume mounts](tests/integration/daemonset-with-volumes/alloy.yaml)
* [StatefulSet with WAL](tests/integration/statefulset-with-wal/alloy.yaml)
* [Remote Configuration](tests/platform/remote-config/alloy.yaml)

NOTE: The Alloy instances *do not* deploy the PodLogs CRD, nor does it support the `crds` field in the `spec`.

## Contributing

We welcome contributions to the Grafana Alloy Operator! Please see our [Contributing Guide](./CONTRIBUTING.md) for more
information.

### Security scanning

The operator image is scanned for known vulnerabilities (CVEs) by the **CVE Scan** GitHub Action. It is
**advisory** — it reports findings but does not fail the build or block PRs, because the operator image is a
thin layer over a pinned upstream base image whose CVEs accumulate faster than the base image can be bumped;
gating on them would keep PRs permanently red. It runs on pull requests that touch `operator/**`, the workflow,
or the [VEX ledger](.vex/); on pushes to `main`; weekly; and on demand from the **Actions** tab (or `gh
workflow run trivy.yaml`). The scan uses two complementary scanners:

* **[Trivy](https://trivy.dev/)** matches package versions across the whole image (UBI RPMs and the bundled Go
  binary). Findings justified in the VEX ledger are suppressed, so what surfaces is the set still needing
  attention.
* **[govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)** (binary mode) adds symbol-level
  *reachability* for the bundled `helm-operator` Go binary — it reports which CVEs are actually linked into the
  binary, which Trivy cannot tell. This is the signal that warns when a newly disclosed CVE becomes reachable.

Results go to the repository's **Security → Code scanning** tab and the run's job summary. Scan locally with
`make scan` (Trivy) and `make reachability` (govulncheck); both fall back to a container image if the tool is
not installed. To turn this back into a gate later (fail PRs on un-triaged HIGH/CRITICAL CVEs), drop the
`continue-on-error` lines and restore an `exit-code: '1'` Trivy step.

Because the operator image is a thin layer over the upstream
[`operator-framework/helm-operator`](https://quay.io/repository/operator-framework/helm-operator) base image,
essentially all findings originate from that base image. To resolve a CVE:

1. **Bump the base image** digest in [`operator/Dockerfile`](operator/Dockerfile) to a newer `helm-operator`
   release that ships the fix. This is the real fix, and Renovate opens these digest-bump PRs automatically.
2. **Triage it** in the [VEX ledger](.vex/) if the finding does not affect this operator — add an OpenVEX
   `not_affected` statement with a written justification (see [`.vex/README.md`](.vex/README.md)). This keeps an
   auditable rationale for each accepted finding (rather than a bare ignore list) and removes it from the set
   the scan surfaces as still needing attention.

The genuine fixes live upstream in
[`operator-framework/operator-sdk`](https://github.com/operator-framework/operator-sdk), which builds the
`helm-operator` image from `images/helm-operator/Dockerfile` (Go-binary CVEs are fixed by bumping `go.mod` /
the Go toolchain; UBI RPM CVEs by bumping the `ubi9/ubi-minimal` base tag). Contributions there benefit every
downstream operator — see that repo's `CONTRIBUTING.MD`.

### Updating the Alloy version

The Alloy Operator embeds a specific version of Alloy by default. The Alloy Operator Helm chart's `appVersion` matches
the Alloy Helm chart's version. See [current version](#current-version) for the specifics. To update the embedded Alloy
version, run the script: `./scripts/update-alloy.sh`. Make sure to bump the Alloy Operator version and `make clean build test`

### Releasing Alloy Operator

1. Set a new Alloy Operator chart version
2. Remake generated files with `make clean build test`
3. Make sure all changes are represented in the CHANGELOG.md.
4. Commit, create PR, merge to main
5. Run the "Release Alloy Operator Helm chart" GitHub action.
