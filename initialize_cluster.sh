#!/bin/bash

if [ -z "$1" ]; then echo "\nprovide hcloud api token"; fi
if [ -z "$2" ]; then echo "\nprovide hcloud floating ip"; fi

hcloud_api_token=$1
hcloud_floating_ip=$2
ops_namespace=ops
gcloud_secret_dir="$HOME/Dropbox/dev/gcloud/633301885736-compute@developer.gserviceaccount.com-key.json"

function install_base() {
  kubectl create namespace $ops_namespace \
    --dry-run -o yaml | kubectl apply -f -
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo update
}

function install_imageregistry_secret() {
  kubectl create secret docker-registry gcr-secret \
  --namespace=default \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat $gcloud_secret_dir)" \
  --docker-email=bajo09@gmail.com \
  --dry-run -o yaml | kubectl apply -f -

  kubectl patch serviceaccounts default -p '{"imagePullSecrets": [{"name": "gcr-secret"}]}'
}

function install_ingress() {
  helm upgrade \
    --install nginx-ingress \
    --namespace $ops_namespace \
    -f nginx-ingress/nginx-ingress-overrides.yaml \
    stable/nginx-ingress
}

function install_certmanager() {
  kubectl apply \
    -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.1/deploy/manifests/00-crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm upgrade \
    --install cert-manager \
    --namespace $ops_namespace \
    -f cert-manager/cert-manager-overrides.yaml \
    jetstack/cert-manager \
    --wait
  kubectl apply -f cert-manager/prod-clusterissuer.yaml
}

function install_metallb() {
  helm upgrade --install metallb stable/metallb \
    --namespace ops \
    -f metallb/metallb-overrides.yaml
}

function install_metrics_server() {
  helm upgrade --install metrics-server stable/metrics-server \
    --namespace $ops_namespace \
    -f metrics-server/metrics-server-overrides.yaml
}

function configure_hcloud_floatingip_failover() {
kubectl apply -f - << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fip-controller
  namespace: $ops_namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fip-controller
rules:
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
      - list
  - apiGroups:
      - "coordination.k8s.io"
    resources:
      - "leases"
    verbs:
      - "get"
      - "list"
      - "update"
      - "create"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fip-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fip-controller
subjects:
  - kind: ServiceAccount
    name: fip-controller
    namespace: $ops_namespace
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fip-controller
  namespace: $ops_namespace
spec:
  selector:
    matchLabels:
      app: fip-controller
  template:
    metadata:
      labels:
        app: fip-controller
    spec:
      containers:
        - name: fip-controller
          image: cbeneke/hcloud-fip-controller:v0.3.1
          imagePullPolicy: IfNotPresent
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          envFrom:
            - secretRef:
                name:  fip-controller-secrets
          volumeMounts:
            - name: config
              mountPath: /app/config
      serviceAccountName: fip-controller
      volumes:
        - name: config
          configMap:
            name: fip-controller-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fip-controller-config
  namespace: $ops_namespace
data:
  config.json: |
    {
      "hcloud_floating_ips": ["${hcloud_floating_ip}"],
      "node_address_type": "external"
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: fip-controller-secrets
  namespace: $ops_namespace
stringData:
  HCLOUD_API_TOKEN: $hcloud_api_token
---
EOF
}

function configure_cicd() {
kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: ops-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: $ops_namespace
EOF
}

install_base
install_imageregistry_secret
install_ingress
install_certmanager
install_metallb
install_metrics_server
configure_hcloud_floatingip_failover
configure_cicd
