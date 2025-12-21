#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NS="${NS:-audit-zone}"

echo "  validate-security.sh"
echo "  ROOT_DIR=$ROOT_DIR"
echo "  NS=$NS"
echo

fail()    { echo " ❌ $*" >&2; exit 1; }
ok()      { echo " ✅ $*"; }
checking() { echo " 📋 Проверка: $*"; }

checking "Контекст kubectl"
kubectl version --client >/dev/null 2>&1 || fail "kubectl не доступен"
kubectl cluster-info >/dev/null 2>&1 || fail "кластер недоступен (kubectl cluster-info падает)"
ok "Кластер доступен"
echo

checking "PodSecurity Admission включён и действует (namespace '$NS')"
kubectl get ns "$NS" >/dev/null 2>&1 || fail "namespace '$NS' не существует"
ENFORCE="$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
if [[ "$ENFORCE" != "restricted" && "$ENFORCE" != "restricted:latest" ]]; then
  fail "PSA enforce не restricted (сейчас: '${ENFORCE:-<empty>}')"
fi
ok "PSA enforce=$ENFORCE"
echo

checking "Gatekeeper установлен и готов"
kubectl get ns gatekeeper-system >/dev/null 2>&1 || fail "namespace gatekeeper-system не найден (Gatekeeper не установлен?)"

kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager --timeout=180s >/dev/null 2>&1 \
  || fail "gatekeeper-controller-manager не Ready"
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-audit --timeout=180s >/dev/null 2>&1 \
  || fail "gatekeeper-audit не Ready"
ok "Gatekeeper deployments Ready"

kubectl -n gatekeeper-system get svc gatekeeper-webhook-service >/dev/null 2>&1 \
  || fail "service gatekeeper-webhook-service не найден"
ok "gatekeeper-webhook-service существует"

kubectl get validatingwebhookconfiguration gatekeeper-validating-webhook-configuration >/dev/null 2>&1 \
  || fail "validatingwebhookconfiguration gatekeeper-validating-webhook-configuration не найден"
ok "validating webhook configuration присутствует"
echo

checking "ConstraintTemplates и Constraints присутствуют"
kubectl get constrainttemplates >/dev/null 2>&1 || fail "constrainttemplates недоступны"

kubectl get constrainttemplate k8sprivilegedcontainer >/dev/null 2>&1 \
  || fail "нет constrainttemplate: k8sprivilegedcontainer"
kubectl get constrainttemplate k8sdisallowhostpath >/dev/null 2>&1 \
  || fail "нет constrainttemplate: k8sdisallowhostpath"
kubectl get constrainttemplate k8srunasnonroot >/dev/null 2>&1 \
  || fail "нет constrainttemplate: k8srunasnonroot"
ok "ConstraintTemplates на месте"

kubectl get k8sprivilegedcontainer deny-privileged >/dev/null 2>&1 \
  || fail "нет constraint: deny-privileged (K8sPrivilegedContainer)"
kubectl get k8sdisallowhostpath deny-hostpath >/dev/null 2>&1 \
  || fail "нет constraint: deny-hostpath (K8sDisallowHostPath)"
kubectl get k8srunasnonroot require-nonroot-and-readonlyfs >/dev/null 2>&1 \
  || fail "нет constraint: require-nonroot-and-readonlyfs (K8sRunAsNonRoot)"
ok "Constraints на месте"

for c in \
  "k8sprivilegedcontainer/deny-privileged" \
  "k8sdisallowhostpath/deny-hostpath" \
  "k8srunasnonroot/require-nonroot-and-readonlyfs"
do
  ea="$(kubectl get "$c" -o jsonpath='{.spec.enforcementAction}' 2>/dev/null || true)"
  ea="${ea:-deny}"
  [[ "$ea" == "deny" ]] || fail "у $c enforcementAction не deny (сейчас: '$ea')"
done
ok "enforcementAction=deny (или по умолчанию deny) у всех constraints"
echo

checking "Безопасные манифесты проходят server-side валидацию (dry-run)"
kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/secure-manifests/" >/dev/null \
  || fail "secure-manifests НЕ проходят server dry-run"
ok "secure-manifests проходят server dry-run"
echo

ok "validate-security.sh завершён успешно"