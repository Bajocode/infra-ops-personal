#!/bin/bash

if [ -z "$1" ]; then printf "\nprovide hcloud api token"; fi
if [ -z "$2" ]; then printf "\nprovide hcloud floating ip"; fi
if [ -z "$3" ]; then printf "\nprovide gcloud secret dir"; fi

hcloud_api_token=$1
hcloud_floating_ip=$2
gcloud_secret_dir=$3

function install_metrics_server() {
  kubectl apply \
    -n kube-system \
    -f metrics-server/metrics-server.yaml
}

function configure_hcloud_floatingip_failover() {
kubectl apply -f - << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fip-controller
  namespace: kube-system
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
      - pods
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
    namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fip-controller-config
  namespace: kube-system
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
  namespace: kube-system
stringData:
  HCLOUD_API_TOKEN: ${hcloud_api_token}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fip-controller
  namespace: kube-system
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
          image: cbeneke/hcloud-fip-controller:v0.4.0
          imagePullPolicy: Always
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
EOF
}

function add_helmrepos() {
  helm repo add metallb https://metallb.github.io/metallb
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
}

function install_metallb() {
  helm upgrade --install metallb metallb/metallb \
    --namespace kube-system \
    -f metallb/metallb-overrides.yaml
}

function install_ingress() {
  helm upgrade \
    --install nginx-ingress \
    --namespace kube-system \
    -f nginx-ingress/nginx-ingress-overrides.yaml \
    ingress-nginx/ingress-nginx
}

function install_certmanager() {
  helm upgrade \
    --install cert-manager \
    --namespace kube-system \
    -f cert-manager/cert-manager-overrides.yaml \
    jetstack/cert-manager \
    --wait
  kubectl apply -f cert-manager/prod-clusterissuer.yaml
}

function install_imageregistry_secret() {
  kubectl create secret docker-registry gcr-secret \
  --namespace=default \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat "$gcloud_secret_dir")" \
  --docker-email=bajo09@gmail.com \
  --dry-run -o yaml | kubectl apply -f -

  kubectl patch serviceaccounts default -p '{"imagePullSecrets": [{"name": "gcr-secret"}]}'
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
  namespace: kube-system
EOF
}

install_metrics_server
configure_hcloud_floatingip_failover
add_helmrepos
install_metallb
install_ingress
install_certmanager
install_imageregistry_secret
# configure_cicd
