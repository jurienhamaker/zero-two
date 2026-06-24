{{- define "traefik.values" -}}
{{- with .Values.traefik }}
podDisruptionBudget:
  enabled: true
  minAvailable: 1
additionalArguments:
  - --entrypoints.websecure.http.tls.certresolver=cloudflare
  - --entrypoints.websecure.http.tls.domains[0].main={{ .domain }}
  - --entrypoints.websecure.http.tls.domains[0].sans=*.{{ .domain }} 
  - --certificatesresolvers.cloudflare.acme.dnschallenge.provider=cloudflare
  - --certificatesresolvers.cloudflare.acme.email={{ .email }}
  - --certificatesresolvers.cloudflare.acme.dnschallenge.resolvers=1.1.1.1
  - --certificatesresolvers.cloudflare.acme.storage=/certs/acme.json
persistence:
  enabled: true
  name: data
  accessMode: ReadWriteOnce
  size: 64Mi
  path: /data
resources:
  requests:
    cpu: 50m
    memory: 100Mi
  limits:
    cpu: 500m
    memory: 250Mi
log:
  level: INFO
accessLog:
    enabled: true
ports:
  web:
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
    annotations:
      external-dns.alpha.kubernetes.io/target: {{ $clusterHostname }}
    #matchRule: Host(`{{ .hostname }}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
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
