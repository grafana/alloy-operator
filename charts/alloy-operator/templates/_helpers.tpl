{{/* Expand the name of the chart. */}}
{{- define "alloy-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "alloy-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "alloy-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "alloy-operator.labels" -}}
helm.sh/chart: {{ include "alloy-operator.chart" . }}
{{ include "alloy-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels */}}
{{- define "alloy-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alloy-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* The name of the service account to use */}}
{{- define "alloy-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- .Values.serviceAccount.name | default (include "alloy-operator.fullname" .)  }}
{{- else }}
{{- .Values.serviceAccount.name | default "default" }}
{{- end }}
{{- end }}

{{/* Calculate the image identifier to use */}}
{{- define "alloy-operator.imageIdentifier" -}}
{{- if .Values.image.digest }}
  {{- $digest := .Values.image.digest }}
  {{- if not (hasPrefix "sha256:" $digest) }}
    {{- $digest = printf "sha256:%s" $digest }}
  {{- end }}
  {{- printf "@%s" $digest }}
{{- else if .Values.image.tag }}
  {{- printf ":%s" .Values.image.tag }}
{{- else }}
  {{- printf ":%s" .Chart.AppVersion }}
{{- end }}
{{- end }}
