#!/bin/bash

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-ops-viewer
  namespace: pd-sales
subjects:
  - kind: ServiceAccount
    name: grp-ops
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-viewer
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-dev-editor
  namespace: pd-sales
subjects:
  - kind: ServiceAccount
    name: grp-dev
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-editor
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-ops-viewer
  namespace: pd-tenant
subjects:
  - kind: ServiceAccount
    name: grp-ops
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-viewer
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-dev-editor
  namespace: pd-tenant
subjects:
  - kind: ServiceAccount
    name: grp-dev
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-editor
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-ops-viewer
  namespace: pd-finance
subjects:
  - kind: ServiceAccount
    name: grp-ops
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-viewer
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-dev-editor
  namespace: pd-finance
subjects:
  - kind: ServiceAccount
    name: grp-dev
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-editor
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-ops-viewer
  namespace: pd-data
subjects:
  - kind: ServiceAccount
    name: grp-ops
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-viewer
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grp-dev-editor
  namespace: pd-data
subjects:
  - kind: ServiceAccount
    name: grp-dev
    namespace: pd-security
roleRef:
  kind: Role
  name: pd-ns-editor
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grp-security-secret-reader
subjects:
  - kind: ServiceAccount
    name: grp-security
    namespace: pd-security
roleRef:
  kind: ClusterRole
  name: pd-secret-reader
  apiGroup: rbac.authorization.k8s.io

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grp-platform-cluster-operator
subjects:
  - kind: ServiceAccount
    name: grp-platform
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: pd-cluster-operator
  apiGroup: rbac.authorization.k8s.io
EOF
