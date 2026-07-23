# Contributing to the Alloy Operator

Thanks for your interest in improving the Grafana Alloy Operator! This guide explains how the repository is laid
out, how to set up a development environment, and the workflow for getting a change merged.

## Ways to contribute

* **Report a bug or request a feature** by opening an [issue](https://github.com/grafana/alloy-operator/issues).
* **Fix a bug, add a test, or improve the docs** by opening a pull request.

If you are planning a larger change, please open an issue first so we can discuss the approach before you invest
time in the implementation.

## How this repository is built

The Alloy Operator is a thin layer over two upstream projects, and most of the repository is *generated* rather
than hand-written:

* It is built with the [Operator SDK](https://sdk.operatorframework.io/) and ships the
  [`operator-framework/helm-operator`](https://quay.io/repository/operator-framework/helm-operator) base image.
* It embeds the [Alloy Helm chart](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy),
  which the operator renders to reconcile `Alloy` custom resources.

Because so much is generated, **run `make build` after any change and commit the results** so the generated files
stay in sync with their sources.

### Repository layout

| Path | What lives there |
|------|------------------|
| `operator/` | The operator itself: `Dockerfile`, `watches.yaml`, the embedded `helm-charts/`, and the `config/` used to generate CRDs and manifests. |
| `charts/alloy-operator/` | The Alloy Operator Helm chart that users install. `README.md`, `values.schema.json`, and `docs/examples/*/output.yaml` are generated. |
| `charts/alloy-crd/`, `charts/alloy-helm-chart/`, `charts/sample-parent-chart/` | Supporting charts: the standalone CRD chart, the vendored upstream Alloy chart, and a parent chart used by tests. |
| `tests/integration/` | Integration tests, one directory per scenario, each with a `test-plan.yaml`. |
| `tests/platform/` | Platform-specific tests such as remote configuration. |
| `scripts/` | Helper scripts, including `update-alloy.sh`. |
| `.vex/` | The OpenVEX ledger used to triage CVE-scan findings. |

## Prerequisites

The build and lint targets are written so that each tool is used directly if it is installed, and otherwise falls
back to running it in a Docker container. At a minimum you will want:

* [Docker](https://docs.docker.com/get-docker/) (with `buildx`)
* [Helm](https://helm.sh/docs/intro/install/) and the
  [`helm-unittest`](https://github.com/helm-unittest/helm-unittest) plugin
* [`yq`](https://github.com/mikefarah/yq)
* [`kustomize`](https://kustomize.io/)

Optional tools that speed up the build/lint targets when installed locally (otherwise Docker is used):
`helm-docs`, `markdownlint-cli2`, `yamllint`, `actionlint`, `zizmor`, `trivy`, and `govulncheck`.

## Development workflow

1. Fork the repository and create a branch for your change.
2. Make your change. If it touches anything under `operator/` or `charts/`, regenerate the derived files:

   ```shell
   make clean build test
   ```

3. Run the linters:

   ```shell
   make lint
   ```

4. Add an entry to [`charts/alloy-operator/CHANGELOG.md`](charts/alloy-operator/CHANGELOG.md) under the
   `## Unreleased` heading, ending it with your GitHub handle, e.g. `(@your-handle)`.
5. Commit your changes, including any regenerated files, and open a pull request against `main`.

`make help` lists every available target. The most common ones are:

* `make build` — regenerate the operator manifests, Helm chart docs/schema/examples, and the README version table.
* `make test` — run the Helm chart unit tests.
* `make lint` — run all linters (`lint-yaml`, `lint-markdown`, `lint-actionlint`, `lint-zizmor`).
* `make clean` — remove build artifacts so the next `build` starts fresh.

## Updating the embedded Alloy version

The operator embeds a specific version of Alloy by default, and the Helm chart's `appVersion` matches the Alloy
Helm chart version. To bump it, run:

```shell
./scripts/update-alloy.sh
```

Then bump the Alloy Operator chart version, add a CHANGELOG entry, and run `make clean build test`.

## Adding an integration test

Integration tests live under `tests/integration/`, one directory per scenario. Each directory contains a
`test-plan.yaml` describing the release to install, cluster dependencies, and the assertions to make; supporting
manifests such as `alloy.yaml` sit alongside it. Copy an existing scenario (for example
[`tests/integration/basic/`](tests/integration/basic/)) as a starting point. The **Integration Test** GitHub
Action discovers every `test-plan.yaml` automatically, so a new directory is picked up without further wiring.

## Security scanning

The operator image is scanned for CVEs by the advisory **CVE Scan** GitHub Action. You can reproduce it locally
with `make scan` (Trivy, VEX-gated) and `make reachability` (govulncheck). Because nearly all findings come from
the upstream base image, resolve them by either bumping the base-image digest in
[`operator/Dockerfile`](operator/Dockerfile) or triaging the finding in the [VEX ledger](.vex/). See the
[Security scanning](README.md#security-scanning) section of the README for the full details.

## Releasing

Releases are cut by maintainers. The process is:

1. Set a new Alloy Operator chart version.
2. Remake generated files with `make clean build test`.
3. Make sure all changes are represented in `charts/alloy-operator/CHANGELOG.md`.
4. Commit, open a PR, and merge to `main`.
5. Run the **Release Alloy Operator Helm chart** GitHub Action.

## License

By contributing, you agree that your contributions will be licensed under the repository's
[Apache 2.0 License](LICENSE).
