FROM quay.io/operator-framework/helm-operator:v1.42.0@sha256:102abedc1eb4ece4187eab36107cb3176e672ff6bf17d64396cd903ce13affa0

LABEL org.opencontainers.image.source=https://github.com/grafana/alloy-operator
LABEL org.opencontainers.image.description="Alloy Operator container image"
LABEL org.opencontainers.image.licenses=Apache-2.0

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
