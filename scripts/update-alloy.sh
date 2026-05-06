#!/usr/bin/env bash
set -euo pipefail

CHART_YAML="charts/alloy-helm-chart/Chart.yaml"

echo "Fetching latest Alloy chart version from grafana/alloy..."
latest=$(helm show chart alloy --repo https://grafana.github.io/helm-charts | yq -r '.version')
current=$(yq '.dependencies[].version' "$CHART_YAML")

echo "Current version: $current"
echo "Latest version:  $latest"

if [ "$latest" = "$current" ]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating $CHART_YAML to $latest..."
yq ".version = \"$latest\"" -i "$CHART_YAML"
yq ".dependencies[].version = \"$latest\"" -i "$CHART_YAML"

make fetch-alloy-chart
make clean build test
