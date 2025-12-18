# Задание 1

- [Чеклист](Task1/README.md)
- [Mindmap исходник](Task1/mindmap.drawio)

![Mindmap](Task1/mindmap.png)

# Задание 2

- [Чеклист](Task2/checklist.md)

# Задание 3

- [Диаграмма контекста C4](Task3/C4_Context.puml)

![C4_Context](Task3/C4_Context.svg)

- [Доработанная диаграмма контейнеров C4](Task3/C4_Containers_With_Integration.drawio)

![C4_Containers](Task3/C4_Containers_With_Integration.png)

# Задание 4

## Как запустить

```bash
bash create-users.sh
bash create-roles.sh
bash bind.sh
```

# Задание 5

## Как запустить

```bash
bash run-services.sh
kubectl apply -f non-admin-api-allow.yaml
```

## Как проверить

```bash
kubectl run test-ok1-$RANDOM --rm -i -t --restart=Never --image=alpine --labels role=front-end -- sh
/ # wget -qO- --timeout=2 http://back-end-api-app | head
/ # exit

kubectl run test-ok2-$RANDOM --rm -i -t --restart=Never --image=alpine --labels role=admin-front-end -- sh
/ # wget -qO- --timeout=2 http://admin-back-end-api-app | head
/ # exit

kubectl run test-x1-$RANDOM --rm -i -t --restart=Never --image=alpine --labels role=front-end -- sh
/ # wget -qO- --timeout=2 http://admin-back-end-api-app || echo "BLOCKED_OK"
/ # exit
```

Результат проверок:

![Результат проверок](Task5/task5_network_test.png)

# Задание 6

## Как запустить

```bash
bash run-minikube.sh
```
Дождаться запуска миникуба

```bash
bash simulate-incident.sh
```

```bash
kubectl logs kube-apiserver-minikube -n  kube-system | grep audit.k8s.io/v1 > audit.log
```

```bash
bash extract.sh
```

# Задание 7 

## Как проверить

Для начала, необходимо создать namespace:

```bash
kubectl apply -f 01-create-namespace.yaml
kubectl get ns audit-zone --show-labels
```

### insecure

Необходимо выполнить команду:

```bash
kubectl -n audit-zone apply -f ./insecure-manifests/
```

После выполнения команды должны получить ошибки:

```
Error from server (Forbidden): error when creating "insecure-manifests/01-privileged-pod.yaml": pods "pod-privileged" is forbidden: violates PodSecurity "restricted:latest": privileged (container "nginx" must not set securityContext.privileged=true), allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
Error from server (Forbidden): error when creating "insecure-manifests/02-hostpath-pod.yaml": pods "pod-hostpath" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), restricted volume types (volume "host-etc" uses restricted volume type "hostPath"), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
Error from server (Forbidden): error when creating "insecure-manifests/03-root-user-pod.yaml": pods "pod-root" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "nginx" must not set runAsUser=0), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

Так же, после выполнения команды `kubectl -n audit-zone get pods` мы не должны видеть поды в audit-zone
