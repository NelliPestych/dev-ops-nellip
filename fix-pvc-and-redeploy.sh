#!/bin/bash
# Скрипт для виправлення PVC та перевстановлення компонентів

set -e

echo "=== Крок 1: Видалення завислих PVC ==="
kubectl delete pvc -n jenkins jenkins || echo "PVC jenkins не знайдено або вже видалено"
kubectl delete pvc -n monitoring kube-prometheus-stack-grafana || echo "PVC grafana не знайдено або вже видалено"

echo ""
echo "=== Крок 2: Перевірка PVC та Storage Classes ==="
echo "--- PVC в усіх namespaces ---"
kubectl get pvc -A
echo ""
echo "--- Storage Classes ---"
kubectl get sc

echo ""
echo "=== Крок 3: Видалення namespace argocd ==="
kubectl delete ns argocd --wait=false || echo "Namespace argocd не знайдено або вже видаляється"

echo ""
echo "=== Крок 4: Застосування Terraform для helm-модулів ==="
terraform apply -target=module.jenkins -target=module.argo_cd -target=module.monitoring

echo ""
echo "=== Крок 5: Перевірка стану pods ==="
echo "--- Jenkins ---"
kubectl get pods -n jenkins
echo ""
echo "--- Monitoring ---"
kubectl get pods -n monitoring
echo ""
echo "--- Argo CD ---"
kubectl get pods -n argocd

echo ""
echo "=== Крок 6: Перевірка events ==="
echo "--- Jenkins events (останні 30) ---"
kubectl get events -n jenkins --sort-by=.lastTimestamp | tail -30
echo ""
echo "--- Monitoring events (останні 30) ---"
kubectl get events -n monitoring --sort-by=.lastTimestamp | tail -30
echo ""
echo "--- Argo CD events (останні 30) ---"
kubectl get events -n argocd --sort-by=.lastTimestamp | tail -30

echo ""
echo "=== Додаткова діагностика (якщо потрібно) ==="
echo "--- Всі PVC ---"
kubectl get pvc -A
echo ""
echo "--- Опис Jenkins pod (якщо є проблеми) ---"
kubectl get pods -n jenkins -o name | head -1 | xargs -I {} kubectl describe {} -n jenkins || echo "Jenkins pod не знайдено"

