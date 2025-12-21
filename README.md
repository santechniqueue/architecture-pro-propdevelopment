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

### Подготовка окружения - чистый кластер, политики, secure pods

```bash
bash ./verify/init.sh
```

### Security-проверки

```bash
bash ./verify/validate-security.sh
```

В результате должен быть успешный статус проверки: `✅ validate-security.sh завершён успешно`

### Admission-проверки

```bash
bash ./verify/verify-admission.sh
```

В результате должен быть успешный статус проверки: `✅ verify-admission.sh завершён успешно`