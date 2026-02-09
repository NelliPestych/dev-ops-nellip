# Команди для виправлення PVC та перевстановлення компонентів

## Крок 1: Видалення завислих PVC

```bash
kubectl delete pvc -n jenkins jenkins
kubectl delete pvc -n monitoring kube-prometheus-stack-grafana
```

## Крок 2: Перевірка PVC та Storage Classes

```bash
kubectl get pvc -A
kubectl get sc
```

**Очікування**: У PVC має бути STORAGECLASS `gp2` і статус `Bound` (з VOLUME).

## Крок 3: Видалення namespace argocd

```bash
kubectl delete ns argocd --wait=false
```

## Крок 4: Застосування Terraform для helm-модулів

```bash
terraform apply -target=module.jenkins -target=module.argo_cd -target=module.monitoring
```

## Крок 5: Перевірка стану

```bash
kubectl get pods -n jenkins
kubectl get pods -n monitoring
kubectl get pods -n argocd
```

## Крок 6: Перевірка events

```bash
kubectl get events -n jenkins --sort-by=.lastTimestamp | tail -30
kubectl get events -n monitoring --sort-by=.lastTimestamp | tail -30
kubectl get events -n argocd --sort-by=.lastTimestamp | tail -30
```

## Додаткова діагностика (якщо є проблеми)

Якщо після кроку 4 знову буде `context deadline exceeded` або інші помилки:

```bash
kubectl get pvc -A
kubectl describe pod -n jenkins jenkins-0
# або для Grafana:
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
```

## Альтернатива: Використання скрипта

Можна виконати всі команди одразу:

```bash
./fix-pvc-and-redeploy.sh
```

