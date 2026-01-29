# Инструкция по настройке CI/CD

## Шаг 1: Подготовка репозиториев

### Repo A (App Repository)

Создайте репозиторий с Django приложением:

```bash
# Структура:
app-repo/
├── Dockerfile
├── Jenkinsfile          # Скопируйте из lesson-8-9/Jenkinsfile.example
├── requirements.txt
├── src/
│   └── ...
└── README.md
```

**Важно:** 
- `Jenkinsfile` должен быть в корне репозитория
- `Dockerfile` должен собирать образ для `linux/amd64`

### Repo B (GitOps Repository)

Создайте репозиторий с Helm chart:

```bash
# Структура:
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml      # image.tag будет обновляться Jenkins
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

**Важно:**
- Используйте Helm chart из `lesson-8-9/charts/django-app/` как основу
- В `values.yaml` должен быть параметр `image.tag`

## Шаг 2: Настройка Terraform

### Обновите main.tf

В `lesson-8-9/main.tf` укажите URL вашего GitOps репозитория:

```hcl
module "argo_cd" {
  source = "./modules/argo_cd"
  
  gitops_repo_url = "https://github.com/your-username/your-gitops-repo.git"
  app_name        = "django-app"
  app_path        = "charts/django-app"
  target_revision = "main"
  
  depends_on = [
    module.eks
  ]
}
```

## Шаг 3: Применение Terraform

```bash
cd lesson-8-9
terraform init
terraform plan
terraform apply
```

**Время ожидания:** 10-15 минут

## Шаг 4: Настройка Jenkins

### 4.1. Получение пароля администратора

```bash
kubectl get secret -n jenkins jenkins-admin-password -o jsonpath='{.data.password}' | base64 -d && echo
```

### 4.2. Доступ к Jenkins UI

```bash
# Port-forward
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Или через LoadBalancer
kubectl get svc -n jenkins jenkins
```

Откройте: http://localhost:8080

### 4.3. Добавление Credentials

1. **GitHub PAT:**
   - Jenkins → Manage Jenkins → Credentials → Add Credentials
   - Kind: "Secret text"
   - Secret: ваш GitHub Personal Access Token
   - ID: `github-pat`
   - Scope: Global

2. **GitOps Repository URL:**
   - Kind: "Secret text"
   - Secret: `github.com/your-username/your-gitops-repo.git` (без https://)
   - ID: `gitops-repo-url`

3. **AWS Credentials (если не используется IRSA):**
   - Kind: "AWS Credentials"
   - Access Key ID и Secret Access Key
   - ID: `aws-ecr-creds`

### 4.4. Создание Pipeline Job

1. New Item → Pipeline
2. Имя: `django-app-pipeline`
3. Pipeline → Definition: "Pipeline script from SCM"
4. Repository URL: URL вашего Repo A
5. Branch: `*/main`
6. Script Path: `Jenkinsfile`
7. Save

### 4.5. Обновление Jenkinsfile

В вашем Repo A обновите `Jenkinsfile`:
- Замените `ECR_REPO` на ваш ECR URL (из `terraform output`)
- Убедитесь, что credentials ID правильные

## Шаг 5: Настройка Argo CD

### 5.1. Получение пароля администратора

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

### 5.2. Доступ к Argo CD UI

```bash
# Port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Или через LoadBalancer
kubectl get svc -n argocd argocd-server
```

Откройте: https://localhost:8080

**Логин:** `admin`  
**Пароль:** (из секрета выше)

### 5.3. Проверка Application

Если Application создан через Terraform:
```bash
kubectl get application -n argocd django-app
```

Если нужно создать вручную:
1. В Argo CD UI → New App
2. Application Name: `django-app`
3. Repository URL: URL вашего GitOps репозитория
4. Path: `charts/django-app`
5. Cluster: `https://kubernetes.default.svc`
6. Namespace: `django`
7. Sync Policy: Automatic (prune, self-heal)

## Шаг 6: Тестирование CI/CD

### 6.1. Запуск Pipeline

1. В Jenkins UI нажмите "Build Now" на вашем pipeline
2. Следите за выполнением в Console Output

### 6.2. Проверка результатов

```bash
# Проверка образа в ECR
aws ecr list-images --repository-name lesson-8-9-django-ecr --region us-west-2 --profile study

# Проверка изменений в GitOps репозитории
# (должен быть новый коммит)

# Проверка синхронизации в Argo CD
kubectl get application -n argocd django-app
kubectl get pods -n django
```

### 6.3. Проверка в Argo CD UI

1. Application должен быть **Synced** и **Healthy**
2. Все ресурсы должны быть развернуты
3. При изменении в GitOps репозитории - автоматическая синхронизация

## Troubleshooting

### Jenkins не может пушить в ECR

**Решение:**
1. Проверьте AWS credentials в Jenkins
2. Или настройте IRSA для Jenkins service account

### Jenkins не может пушить в Git

**Решение:**
1. Проверьте GitHub PAT - должен иметь права на push
2. Проверьте URL репозитория в credentials

### Argo CD не синхронизирует

**Решение:**
1. Проверьте доступ к GitOps репозиторию
2. Проверьте путь к Helm chart
3. Проверьте логи: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

