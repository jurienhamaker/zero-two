{{- define "infra-repository-values" -}}
repoURL: {{ .Values.repoURL | quote }}
targetRevision: {{ .Values.targetRevision | quote }}
{{- end -}}

