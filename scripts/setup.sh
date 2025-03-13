#!/usr/bin/env bash

PARENT_DIR=$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd))
pushd $PARENT_DIR || exit

# Cleaning artifacts
rm -rf alloy config helm-charts .gitignore Dockerfile Makefile PROJECT watches.yaml

# Fetch Alloy and remove CRD dependencies
helm pull grafana/alloy --untar
pushd alloy || exit
rm -rf charts Chart.lock
yq 'del(.dependencies[] | select(.name == "crds"))' -i Chart.yaml
yq 'del(.crds)' -i values.yaml
helm dependency build
popd || exit

# Initialize the Operator
operator-sdk init \
  --plugins helm \
  --project-name alloy-operator \
  --domain grafana.com \
  --group collectors \
  --helm-chart ./alloy

# Clean up the temporary Alloy
rm -rf alloy

# Update Makefile to change:
sed -i .orig -e 's/IMAGE_TAG_BASE ?= grafana.com\/alloy-operator/IMAGE_TAG_BASE ?= ghcr.io\/grafana\/alloy-operator/' Makefile
sed -i .orig -e 's/IMG ?= controller:latest/IMG ?= $(IMAGE_TAG_BASE):$(VERSION)/' Makefile
rm Makefile.orig

# Update Dockerfile to add labels:
