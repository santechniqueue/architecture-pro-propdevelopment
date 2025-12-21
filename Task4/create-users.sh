#!/bin/bash

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: pd-sales

apiVersion: v1
kind: Namespace
metadata:
  name: pd-tenant

apiVersion: v1
kind: Namespace
metadata:
  name: pd-finance

apiVersion: v1
kind: Namespace
metadata:
  name: pd-data

apiVersion: v1
kind: Namespace
metadata:
  name: pd-security

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grp-ops
  namespace: pd-security

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grp-dev
  namespace: pd-security

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grp-security
  namespace: pd-security

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grp-platform
  namespace: kube-system
EOF
