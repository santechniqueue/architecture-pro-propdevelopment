#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NS="${NS:-audit-zone}"

echo "  verify-admission.sh"
echo "  ROOT_DIR=$ROOT_DIR"
echo "  NS=$NS"
echo

fail() { echo " ❌ $*" >&2; exit 1; }
ok()   { echo " ✅ $*"; }
checking() { echo "📋️ Проверка: $*"; }

# чтобы гарантированно вернуть PSA-лейбл обратно
ORIG_ENFORCE=""
restore_psa() {
  if [[ -n "${ORIG_ENFORCE}" ]]; then
    kubectl label ns "$NS" "pod-security.kubernetes.io/enforce=${ORIG_ENFORCE}" --overwrite >/dev/null 2>&1 || true
  fi
}
trap restore_psa EXIT

checking "Предварительные проверки"
kubectl get ns "$NS" >/dev/null 2>&1 || fail "namespace '$NS' не существует"
kubectl -n gatekeeper-system get pods >/dev/null 2>&1 || fail "Gatekeeper не установлен/не доступен"
echo

checking "Политики работают, небезопасные поды отклоняются (PSA restricted)"
set +e
OUT1="$(kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/insecure-manifests/01-privileged-pod.yaml" 2>&1)"
RC1=$?
OUT2="$(kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/insecure-manifests/02-hostpath-pod.yaml" 2>&1)"
RC2=$?
OUT3="$(kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/insecure-manifests/03-root-user-pod.yaml" 2>&1)"
RC3=$?
set -e

for i in 1 2 3; do
  eval "rc=\$RC$i"
  eval "out=\$OUT$i"
  if [[ "$rc" -eq 0 ]]; then
    echo "$out"
    fail "insecure-manifests/$i НЕ были отклонены (dry-run=server прошёл)"
  fi
  echo "$out" | grep -Eqi "forbidden|denied|violates|violate" \
    || fail "insecure-manifests/$i отклонён, но без ожидаемого текста (forbidden/denied/violates)"
done
ok "insecure-manifests отклоняются (как минимум PSA)"
echo

checking "Безопасные поды проходят валидацию (server-side dry-run)"
kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/secure-manifests/" >/dev/null \
  || fail "secure-manifests НЕ проходят server-side dry-run"
ok "secure-manifests проходят server-side dry-run"
echo

checking "Gatekeeper активно применяет ограничения"
ORIG_ENFORCE="$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
[[ -n "$ORIG_ENFORCE" ]] || ORIG_ENFORCE="restricted"

kubectl label ns "$NS" "pod-security.kubernetes.io/enforce=privileged" --overwrite >/dev/null
echo "  ℹ️  временно установили PSA enforce=privileged для проверки Gatekeeper (потом вернём '${ORIG_ENFORCE}')"
sleep 1

set +e
GK_OUT="$(kubectl apply -n "$NS" --dry-run=server -f "$ROOT_DIR/insecure-manifests/01-privileged-pod.yaml" 2>&1)"
GK_RC=$?
set -e

# возвращаем PSA обратно сразу (на случай падения дальше тоже есть trap)
kubectl label ns "$NS" "pod-security.kubernetes.io/enforce=${ORIG_ENFORCE}" --overwrite >/dev/null

if [[ "$GK_RC" -eq 0 ]]; then
  echo "$GK_OUT"
  fail "при PSA baseline privileged pod прошёл — Gatekeeper не отклонил (или constraints не матчат namespace)"
fi

# В идеале увидим что-то вроде:
# "admission webhook \"validation.gatekeeper.sh\" denied the request: ..."
echo "$GK_OUT" | grep -Eqi "gatekeeper|validation\.gatekeeper\.sh|denied the request|constraints\.gatekeeper\.sh|K8sPrivilegedContainer|deny-privileged" \
  || fail "ожидали отказ именно от Gatekeeper, но в тексте ошибки не видно Gatekeeper/webhook/constraint. Вывод:\n$GK_OUT"

ok "Gatekeeper отклоняет (видно по сообщению admission/webhook/constraint)"
echo

checking "PodSecurity Admission включён и действует (проверка enforce=restricted)"
ENFORCE="$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
if [[ "$ENFORCE" != "restricted" && "$ENFORCE" != "restricted:latest" ]]; then
  fail "PSA enforce не restricted (сейчас: '${ENFORCE:-<empty>}')"
fi
ok "PSA enforce=$ENFORCE"
echo

ok "verify-admission.sh завершён успешно"