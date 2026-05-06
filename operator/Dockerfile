FROM quay.io/operator-framework/helm-operator:v1.42.2@sha256:3791825677f659e93bf8a4728d326cb26668be8456d32312c5d7a30aef27b1c0

LABEL org.opencontainers.image.source=https://github.com/grafana/alloy-operator
LABEL org.opencontainers.image.description="Alloy Operator container image"
LABEL org.opencontainers.image.licenses=Apache-2.0

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
