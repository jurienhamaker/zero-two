{{- define "traefik.values" -}}
{{- with .Values.traefik }}
podDisruptionBudget:
  enabled: true
  minAvailable: 1
certificatesResolvers:
  letsencrypt:
    acme:
      email: "{{ .email }}"
      caServer: https://acme-v02.api.letsencrypt.org/directory # Production server
      #caServer: https://acme-staging-v02.api.letsencrypt.org/directory # Staging server
      dnsChallenge:
        provider: cloudflare
      storage: /data/acme.json
persistence:
  enabled: true
  name: data
  accessMode: ReadWriteMany
  storageClass: nfs-k8s
  size: 128Mi
  path: /data
deployment:
  initContainers:
    - name: volume-permissions
      image: busybox:latest
      command: ["sh", "-c", "ls -la /; touch /data/acme.json; chmod -v 600 /data/acme.json"]
      volumeMounts:
      - mountPath: /data
        name: data
podSecurityContext: null
resources:
  requests:
    cpu: 50m
    memory: 100Mi
  limits:
    cpu: 500m
    memory: 250Mi
log:
  level: DEBUG
accessLog:
    enabled: true
ports:
  web:
    port: 80
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
    observability:
      accessLogs: false
      metrics: false
      tracing: false
  websecure:
    http:
      tls:
        certResolver: letsencrypt
        domains:
          - main: {{ .domain | quote }}
            sans:
            - "*.{{ .domain }}"
  postgres:
    expose:
      default: true
    port: 5432
    protocol: TCP
tlsOptions:
  default:
    minVersion: VersionTLS13
providers:
  kubernetesGateway:
    enabled: false
  kubernetesIngress:
    publishedService:
      enabled: true
ingressRoute:
  {{- $clusterHostname := .clusterHostname }}
  {{- with .dashboard }}
  dashboard:
    enabled: {{ .enabled }}
    matchRule: Host(`{{ .hostname }}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
    entryPoints:
      - websecure
  {{- end }}
env:
  # work around trace setup error "error detecting resource: user: Current requires cgo or $USER set in environment"
  # See: https://github.com/traefik/traefik/issues/11992
  - name: USER
    value: "nobody"
  - name: HOST_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: CF_API_EMAIL
    valueFrom:
      secretKeyRef:
        key: email
        name: cloudflare-api-credentials
  - name: CF_API_KEY
    valueFrom:
      secretKeyRef:
        key: apiKey
        name: cloudflare-api-credentials
{{- end }}
{{- end -}}
