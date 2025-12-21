#!/bin/bash

minikube stop
minikube delete

mkdir -p ~/.minikube/files/etc/ssl/certs
cp -f ./audit-policy.yaml ~/.minikube/files/etc/ssl/certs/audit-policy.yaml

minikube start \
  --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml \
  --extra-config=apiserver.audit-log-path=-
