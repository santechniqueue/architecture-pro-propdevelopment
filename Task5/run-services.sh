#!/bin/bash

# (опционально) очистка предыдущих запусков
kubectl delete svc front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app isolated-app --ignore-not-found
kubectl delete pod front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app isolated-app --ignore-not-found

kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80
kubectl run isolated-app --image=nginx --labels role=isolated --expose --port 80
