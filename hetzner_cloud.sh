#!/bin/bash

if [ -z "$1" ]; then echo "\nprovide hetzner cloud api token"; fi

hcloud_api_token=$1
kubectl create namespace fip-controller \
  --dry-run -o yaml | kubectl apply -f -

install_rbac() {
kubectl apply -f - << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fip-controller
  namespace: fip-controller
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
    namespace: fip-controller
---
EOF
}

install_daemonset() {
kubectl apply -f - << EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fip-controller
  namespace: fip-controller
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
EOF
}

install_configs() {
kubectl apply -f - << EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fip-controller-config
  namespace: fip-controller
data:
  config.json: |
    {
      "hcloud_floating_ips": ["95.216.181.0"],
      "node_address_type": "external"
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: fip-controller-secrets
  namespace: fip-controller
stringData:
  HCLOUD_API_TOKEN: $hcloud_api_token
---
EOF
}

install_rbac
install_daemonset
install_configs
