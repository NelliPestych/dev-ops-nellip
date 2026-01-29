# Quick Start Guide

## Быстрый старт

### 1. Применение Terraform

```bash
cd lesson-8-9

# Обновите gitops_repo_url в main.tf
# Затем:
terraform init
terraform plan
terraform apply
```

### 2. Получение паролей и URL

```bash
# Jenkins пароль
kubectl get secret -n jenkins jenkins-admin-password -o jsonpath='{.data.password}' | base64 -d && echo

# Argo CD пароль
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

# Jenkins URL
terraform output jenkins_loadbalancer_url

# Argo CD URL
terraform output argocd_loadbalancer_url
```

### 3. Настройка Jenkins

1. Откройте Jenkins UI (port-forward или LoadBalancer)
2. Добавьте credentials:
   - `github-pat` (Secret text) - GitHub Personal Access Token
   - `gitops-repo-url` (Secret text) - `github.com/username/repo.git`
3. Создайте Pipeline job из вашего Repo A

### 4. Настройка Argo CD

1. Откройте Argo CD UI (port-forward или LoadBalancer)
2. Application должен быть создан автоматически (если указан gitops_repo_url)
3. Или создайте вручную через UI

### 5. Тестирование

1. Запустите Pipeline в Jenkins
2. Проверьте образ в ECR
3. Проверьте синхронизацию в Argo CD

## Полезные команды

```bash
# Проверка статуса
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get application -n argocd

# Логи
kubectl logs -n jenkins -l app.kubernetes.io/name=jenkins
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Port-forward
kubectl port-forward -n jenkins svc/jenkins 8080:8080
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

