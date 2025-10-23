FROM quay.io/operator-framework/helm-operator:v1.41.1@sha256:289903c9eab9d28afa76c20ef6367e6f98e08c9bae73b309e37520f02b6175ee

LABEL org.opencontainers.image.source=https://github.com/grafana/alloy-operator
LABEL org.opencontainers.image.description="Alloy Operator container image"
LABEL org.opencontainers.image.licenses=Apache-2.0

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
