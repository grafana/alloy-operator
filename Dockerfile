# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.39.1

LABEL org.opencontainers.image.source=https://github.com/gafana/alloy-operator
LABEL org.opencontainers.image.description="Alloy Operator container image"
LABEL org.opencontainers.image.licenses=Apache-2.0

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
