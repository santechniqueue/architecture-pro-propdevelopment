#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NS="${NS:-audit-zone}"
GK_VERSION="${GK_VERSION:-v3.15.0}"

fail()    { echo " ❌ $*" >&2; exit 1; }
ok()      { echo " ✅ $*"; }
started() { echo " 🚀 $*"; }

started "Рестарт minikube"
minikube delete || true
minikube start

started "Установка Gatekeeper"
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GK_VERSION}/deploy/gatekeeper.yaml"

started "Ожидание Gatekeeper"

kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager --timeout=180s
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-audit --timeout=180s || true

for i in {1..60}; do
  eps="$(kubectl -n gatekeeper-system get endpoints gatekeeper-webhook-service -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)"
  if [[ -n "${eps}" ]]; then
    ok "gatekeeper-webhook-service endpoints: ${eps}"
    break
  fi
  sleep 2
done

kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io gatekeeper-validating-webhook-configuration >/dev/null

started "Apply namespace + PodSecurity labels"
kubectl apply -f "${ROOT_DIR}/01-create-namespace.yaml"

started "Ожидание namespace '${NS}' в статусе Active"
for i in {1..60}; do
  if kubectl get namespace "${NS}" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

for i in {1..60}; do
  status="$(kubectl get namespace "${NS}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "${status}" == "Active" ]]; then
    ok "Namespace ${NS} в статусе Active"
    break
  fi
  sleep 2
done

started "Ожидание подов Gatekeeper"
kubectl -n gatekeeper-system wait --for=condition=Ready pod -l control-plane=controller-manager --timeout=180s
kubectl -n gatekeeper-system wait --for=condition=Ready pod -l control-plane=audit-controller --timeout=180s
ok "Поды Gatekeeper активны"
echo

started "Применяю ConstraintTemplates"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraint-templates/"

started "Wait CRDs created by templates"

crds=(
  "k8sprivilegedcontainer.constraints.gatekeeper.sh"
  "k8sdisallowhostpath.constraints.gatekeeper.sh"
  "k8srunasnonroot.constraints.gatekeeper.sh"
)

for crd in "${crds[@]}"; do
  for i in {1..60}; do
    if kubectl get crd "${crd}" >/dev/null 2>&1; then
      ok "CRD существует: ${crd}"
      break
    fi
    sleep 2
  done
done
echo

started "Применяю Constraints"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraints/"
ok "Constraints применены"
echo

echo
started "Применяю secure манифесты"
kubectl apply -n "${NS}" -f "${ROOT_DIR}/secure-manifests/"
ok "Secure манифесты применены"

echo
started "Ожидание secure подов"
kubectl -n "${NS}" wait --for=condition=Ready pod -l app=pod-secure --timeout=180s 2>/dev/null || true
kubectl -n "${NS}" wait --for=condition=Ready pod/pod-secure-01 --timeout=180s
kubectl -n "${NS}" wait --for=condition=Ready pod/pod-secure-02 --timeout=180s
kubectl -n "${NS}" wait --for=condition=Ready pod/pod-secure-03 --timeout=180s
ok "Secure поды готовы"