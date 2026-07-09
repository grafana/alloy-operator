# VEX ledger

[`alloy-operator.openvex.json`](./alloy-operator.openvex.json) is an
[OpenVEX](https://openvex.dev/) document: the triage ledger for CVEs that the
**CVE Scan** workflow finds in the operator image but that **do not affect this
operator**. It replaces the old blanket `.trivyignore`: instead of a bare list
of CVE IDs, every entry is a `not_affected` statement carrying a machine-readable
`justification` and a human-readable `impact_statement`.

Trivy consumes it (`--vex` / `TRIVY_VEX`) and suppresses only the exact
`(CVE, package)` pairs that have a written justification. Any HIGH/CRITICAL
finding **not** covered here is surfaced by the scan (Security tab + job
summary) as still needing attention. The scan is advisory — it runs on PRs but
never fails them — see the repository README.

## Why these CVEs do not affect us

The operator image is a thin layer over
`quay.io/operator-framework/helm-operator`: `operator/Dockerfile` copies Helm
charts onto the upstream base image and changes nothing else. So every finding
lives in the base image — its UBI 9.x RPMs or the bundled `helm-operator` Go
binary — and falls into one of three buckets:

1. **UBI RPMs (gnutls, openssl-libs, libnghttp2, libarchive, libcap).** The only
   process in the image is the statically linked, `CGO_ENABLED=0` Go
   `helm-operator` binary (verified with `go version -m`). It does not
   dynamically link or invoke any of these libraries — it uses Go's own
   `crypto/tls`, `net/http`, and `archive/tar`. The RPMs sit unused in the base
   filesystem (`vulnerable_code_not_in_execute_path`).

2. **Go binary, reachable but not attacker-controllable.** `govulncheck`
   confirms the vulnerable symbols are linked, but the operator's only network
   peers are the trusted in-cluster Kubernetes API server and CoreDNS. The
   vulnerable paths (TLS/x509 against a malicious peer, HTTP/2 against a
   malicious server, email/MIME/SPDY parsing of untrusted input, HTML rendered
   to a browser) have no attacker-controlled input in this deployment
   (`vulnerable_code_cannot_be_controlled_by_adversary`). A couple are
   OS-specific (Windows/BSD panics) and cannot execute on this `linux/amd64`
   image (`vulnerable_code_not_in_execute_path`).

3. **Go binary, not in the execute path.** `govulncheck` reports the vulnerable
   symbols are not reachable from this binary
   (`vulnerable_code_not_in_execute_path`).

The per-CVE rationale lives in each statement's `impact_statement`.

## How reachability is assessed

The Go-binary justifications are backed by **`govulncheck` in binary mode**,
which the **CVE Scan** workflow runs against the extracted `helm-operator`
binary on every scan (and uploads to the Security tab). It reports, at the
symbol level, which CVEs are actually linked into the binary versus merely
present as a dependency. Reproduce locally with `make reachability`.

`govulncheck` itself cannot judge OS-package (RPM) CVEs — those rest on the
threat-model reasoning in bucket 1.

## Maintaining this file

- **The real fix is bumping the base image.** When `operator/Dockerfile`'s base
  image is bumped (org-level Renovate opens these PRs), re-run `make scan`. The
  RPM/module versions in the new image change, so version-pinned VEX statements
  for fixed CVEs stop matching and Trivy reports them as resolved — delete those
  statements. Anything still flagged needs its statement's package version
  updated and its justification re-checked.
- **Adding a finding.** Run `make scan` to get the CVE ID and the exact package
  PURL (the `pkg:...` string Trivy reports). Add a `not_affected` statement
  whose `products[].@id` is that PURL and whose `vulnerability.name` is the CVE
  ID, with a `justification` (one of the OpenVEX
  [justification](https://github.com/openvex/spec) enums) and a concrete
  `impact_statement`. Never suppress without a written reason.
- **Reachability changed.** If `govulncheck` starts reporting a previously
  not-called CVE as reachable, its `vulnerable_code_not_in_execute_path`
  justification is no longer valid — re-triage it.
