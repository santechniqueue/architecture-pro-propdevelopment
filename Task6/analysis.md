# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
   - Кто: `minikube-user (impersonate: system:serviceaccount:secure-ops:monitoring)`, client: `kubectl/v1.30.5 (darwin/arm64) kubernetes/74e84a9`, IP: `192.168.49.1`, время: `2025-12-17T01:09:36.600279Z`
   - Где: namespace `kube-system`, `resource secrets (list)`, requestURI: `/api/v1/namespaces/kube-system/secrets?limit=500`
   - Почему подозрительно: попытка перечислить секреты в `kube-system` от имени `serviceaccount` `secure-ops/monitoring` (получен `403 Forbidden`). 
   Это похоже на разведку или попытку получить токены/конфигурации.

2. Привилегированные поды:
   - Кто: `minikube-user`, client: `kubectl/v1.30.5 (darwin/arm64) kubernetes/74e84a9`, IP: `192.168.49.1`, время: `2025-12-17T01:09:36.672765Z`
   - Комментарий: создан Pod `secure-ops/privileged-pod` с `securityContext.privileged: true`. 
   Привилегированный контейнер может получить расширенный доступ к хосту/ноде и использовать это для эскалации вплоть до компрометации ноды и последующего доступа к кластеру.

3. Использование kubectl exec в чужом поде:
   - Кто: `minikube-user`, client: `kubectl/v1.30.5 (darwin/arm64) kubernetes/74e84a9`, IP: `192.168.49.1`, время: `2025-12-17T01:09:36.745502Z`
   - Что делал: exec в системный Pod `kube-system/coredns-66bc5c9577-gkstw` (container: `coredns`), команда: `cat /etc/resolv.conf`.

4. Создание RoleBinding с правами cluster-admin:
   - Кто: `minikube-user`, client: `kubectl/v1.30.5 (darwin/arm64) kubernetes/74e84a9`, IP: `192.168.49.1`, время: `2025-12-17T01:09:36.855353Z`
   - К чему привело: создан RoleBinding `secure-ops/escalate-binding`, который привязывает ServiceAccount `secure-ops/monitoring` к ClusterRole `cluster-admin`. 
   Это даёт максимально широкие права в namespace `secure-ops` и позволяет выполнять любые действия с ресурсами в этом пространстве имён (включая создание/изменение подов, чтение секретов в namespace и т.д.).

5. Удаление audit-policy.yaml:
   - Кто: не зафиксировано. 
   - Возможные последствия: при реальном удалении, подмене audit-policy или отключении audit-логирования атакующий снижает возможность обнаружения, усложняет расследование и уменьшает качество доказательной базы.
   - Комментарий: если судить по запросу симуляции, то можно увидеть, что была попытка удалить audit-policy по пути `/etc/kubernetes/audit-policy.yaml`, однако путь не был найден, так как audit-policy лежит в другой директории.

## Вывод

В логе фиксируется цепочка действий, характерная для инцидента: попытка доступа к секретам от имени сервис-аккаунта, создание привилегированного пода, exec в системный pod и выдача прав `cluster-admin` сервис-аккаунту через RoleBinding. 

Компрометацией кластера можно считать создание `privileged-pod` и выдачу `cluster-admin` (как минимум - компрометация namespace `secure-ops`, с высоким риском выхода на ноду и дальнейшего захвата всего кластера).

Риски/ошибки RBAC и контроля безопасности:
- опасно иметь возможность создавать RoleBinding/ClusterRoleBinding без строгих ограничений;
- важно ограничивать операции `bind/escalate/impersonate` и не выдавать широкие права по умолчанию сервис-аккаунтам;
- необходимо запрещать `privileged` и другие опасные настройки контейнеров политиками Pod Security (baseline/restricted) или аналогичными контроллерами;
- доступ к namespace `kube-system` должен быть максимально ограничен, а попытки перечислять secrets - подлежать алертингу, даже если запрос был отклонён.
