{{- define "traefik.values" -}}
{{- with .Values.traefik }}
api:
  insecure: true
deployment:
  kind: Deployment
  replicas: 2
  additionalVolumes:
    - name: ca-bundle
      configMap:
        name: trust-bundle
        defaultMode: 0644
        optional: false
        items:
        - key: ca-bundle.crt
          path: ca-bundle.crt
podDisruptionBudget:
  enabled: true
  minAvailable: 1
additionalVolumeMounts:
  - mountPath: /etc/ssl/certs/
    name: ca-bundle
    readOnly: true
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
    expose:
      default: false
  postgres:
    expose:
      default: true
    port: 5432
    protocol: TCP
  websecure:  
    forwardedHeaders:      
      trustedIPs:
        # Cloudflare
        - 103.21.244.0/22
        - 103.22.200.0/22
        - 103.31.4.0/22
        - 104.16.0.0/13
        - 104.24.0.0/14
        - 108.162.192.0/18
        - 131.0.72.0/22
        - 141.101.64.0/18
        - 162.158.0.0/15
        - 172.64.0.0/13
        - 173.245.48.0/20
        - 188.114.96.0/20
        - 190.93.240.0/20
        - 197.234.240.0/22
        - 198.41.128.0/17
tlsOptions:
  default:
    minVersion: VersionTLS13
    clientAuth:
      secretNames:
        - cloudflare-client-cert
      clientAuthType: RequireAndVerifyClientCert
tlsStore:
  default:
    defaultCertificate:
      secretName: cloudflare-origin-cert
providers:
  kubernetesGateway:
    enabled: false
  kubernetesIngress:
    publishedService:
      enabled: true
service:
  spec:
    externalTrafficPolicy: Cluster
  # Cloudflare IP ranges: https://www.cloudflare.com/ips/
  loadBalancerSourceRanges:
    - 103.21.244.0/22
    - 103.22.200.0/22
    - 103.31.4.0/22
    - 104.16.0.0/13
    - 104.24.0.0/14
    - 108.162.192.0/18
    - 131.0.72.0/22
    - 141.101.64.0/18
    - 162.158.0.0/15
    - 172.64.0.0/13
    - 173.245.48.0/20
    - 188.114.96.0/20
    - 190.93.240.0/20
    - 197.234.240.0/22
    - 198.41.128.0/17
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
metrics:
  prometheus: null
tracing:
  otlp:
    enabled: true
    http:
      enabled: true
      endpoint: http://$(HOST_IP):4318
env:
  # work around trace setup error "error detecting resource: user: Current requires cgo or $USER set in environment"
  # See: https://github.com/traefik/traefik/issues/11992
  - name: USER
    value: "nobody"
  - name: HOST_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
{{- end }}
{{- end -}}
