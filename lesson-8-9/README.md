# Lesson 8-9 — Jenkins + Argo CD + GitOps

## Описание проекта

Этот проект реализует полный CI/CD процесс с использованием Jenkins + Helm + Terraform + Argo CD:

1. **Jenkins** автоматически собирает Docker-образ для Django-приложения
2. **ECR** хранит собранные образы
3. **GitOps репозиторий** обновляется с правильным тегом образа
4. **Argo CD** автоматически синхронизирует приложение в кластере при изменениях в Git

### Компоненты:
- **Jenkins** для CI (Continuous Integration) с поддержкой Kaniko для сборки Docker образов
- **Argo CD** для CD (Continuous Delivery) с GitOps подходом
- **EBS CSI Driver** для работы PersistentVolumeClaim в EKS
- **EKS кластер** для развертывания приложений

### Дополнительные файлы:
- `Jenkinsfile.example` - пример Jenkinsfile для вашего Repo A
- `SETUP.md` - детальная инструкция по настройке
- `QUICK_START.md` - быстрый старт

## Структура проекта

```
lesson-8-9/
├── main.tf                  # Главный файл с модулями и провайдерами
├── backend.tf               # Настройка бекенда для state
├── outputs.tf               # Общие выводы ресурсов
│
├── modules/
│   ├── eks/                 # Модуль EKS кластера
│   │   ├── eks.tf
│   │   ├── iam.tf
│   │   ├── aws_ebs_csi_driver.tf  # EBS CSI Driver для PVC
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/             # Модуль Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf
│   │   ├── values.yaml      # Конфигурация Jenkins
│   │   └── outputs.tf
│   │
│   └── argo_cd/             # Модуль Argo CD
│       ├── argo_cd.tf       # Helm release и Application
│       ├── variables.tf
│       ├── values.yaml      # Конфигурация Argo CD
│       ├── outputs.tf
│       └── charts/          # Helm charts для Applications
```

## Требования

- **Terraform** >= 1.0
- **AWS CLI** настроен с профилем (например: `--profile study`)
- **kubectl** для работы с Kubernetes
- **Helm** для развертывания приложений
- **Git** для работы с репозиториями

## Развертывание инфраструктуры

### 1. Подготовка

**Перед применением Terraform:**

1. Обновите `main.tf` - укажите URL вашего GitOps репозитория:
   ```hcl
   module "argo_cd" {
     source = "./modules/argo_cd"
     gitops_repo_url = "https://github.com/your-username/your-gitops-repo.git"
     # ...
   }
   ```

2. Убедитесь, что у вас есть:
   - GitHub Personal Access Token (для push в GitOps репозиторий)
   - AWS credentials с правами на ECR

### 2. Применение Terraform

```bash
cd lesson-8-9
terraform init
terraform plan
terraform apply
```

**Важно:** Terraform автоматически установит:
- EKS кластер с EBS CSI Driver
- Jenkins через Helm chart
- Argo CD через Helm chart
- Argo CD Application (если указан gitops_repo_url)

**Время развертывания:** 10-15 минут

**После apply получите outputs:**
```bash
terraform output
```

### 2. Ожидание готовности кластера

После `terraform apply` подождите 10-15 минут, пока:
- EKS кластер станет активным
- Ноды станут Ready
- EBS CSI Driver установится
- Jenkins и Argo CD развернутся

Проверка:
```bash
# Проверка нод
kubectl get nodes

# Проверка Jenkins
kubectl get pods -n jenkins
kubectl get svc -n jenkins

# Проверка Argo CD
kubectl get pods -n argocd
kubectl get svc -n argocd

# Проверка EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi
```

## Работа с Jenkins

### Получение пароля администратора

```bash
# Получить пароль из секрета
kubectl get secret -n jenkins jenkins-admin-password -o jsonpath='{.data.password}' | base64 -d && echo
```

Или через Terraform output:
```bash
# Получить имя секрета
terraform output jenkins_admin_password_secret

# Получить пароль
kubectl get secret -n jenkins $(terraform output -raw jenkins_admin_password_secret) -o jsonpath='{.data.password}' | base64 -d && echo
```

**Логин:** `admin`  
**Пароль:** (из секрета выше)

**Примечание:** Если секрет `jenkins-admin-password` не существует, используйте:
```bash
kubectl get secret -n jenkins -l app.kubernetes.io/instance=jenkins -o jsonpath='{.items[0].data.jenkins-admin-password}' | base64 -d && echo
```

### Доступ к Jenkins UI

#### Вариант 1: LoadBalancer (если включен)

```bash
# Получить EXTERNAL-IP
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Открыть в браузере
open http://$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

#### Вариант 2: Port-forward

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

Откройте в браузере: http://localhost:8080

**Логин:** `admin`  
**Пароль:** (из секрета выше)

### Настройка Jenkins Pipeline

#### 1. Создание Pipeline Job

1. Войдите в Jenkins UI (используя пароль из секрета)
2. Нажмите "New Item"
3. Выберите "Pipeline" или "Multibranch Pipeline"
4. Укажите имя (например: `django-app-pipeline`)

#### 2. Добавление Credentials

**GitHub PAT (Personal Access Token) - обязательно для push в GitOps репозиторий:**
1. Jenkins → Manage Jenkins → Credentials → Add Credentials
2. Kind: "Secret text"
3. Secret: ваш GitHub PAT (с правами на push в репозиторий)
4. ID: `github-pat`
5. Description: "GitHub Personal Access Token"

**AWS/ECR Credentials (если не используется IRSA):**
1. Jenkins → Manage Jenkins → Credentials → Add Credentials
2. Kind: "AWS Credentials"
3. Access Key ID и Secret Access Key (с правами на ECR)
4. ID: `aws-ecr-creds`
5. Description: "AWS ECR Credentials"

#### 3. Настройка Pipeline

В конфигурации Pipeline укажите:

**Pipeline script from SCM:**
- Repository URL: URL вашего Repo A (app repo с Dockerfile и Jenkinsfile)
- Branch: `*/main` или `*/master`
- Script Path: `Jenkinsfile`
- Credentials: (если репозиторий приватный)

### Пример Jenkinsfile

Полный пример Jenkinsfile находится в `Jenkinsfile.example`. Скопируйте его в ваш Repo A и обновите:

1. **ECR_REPO** - URL вашего ECR репозитория (из `terraform output ecr_repository_url`)
2. **Credentials ID** - должны совпадать с ID в Jenkins

**Основные моменты:**
- Kaniko собирает образ без Docker daemon
- Образ пушится в ECR с тегом GIT_SHA
- GitOps репозиторий обновляется автоматически
- Используются credentials из Jenkins

**См. также:** `SETUP.md` для детальных инструкций по настройке

## Работа с Argo CD

### Получение пароля администратора

```bash
# Получить пароль из секрета
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

Или через Terraform output:
```bash
# Получить имя секрета
terraform output argocd_admin_password_secret

# Получить пароль
kubectl get secret -n argocd $(terraform output -raw argocd_admin_password_secret) -o jsonpath='{.data.password}' | base64 -d && echo
```

**Логин:** `admin`  
**Пароль:** (из секрета выше)

### Доступ к Argo CD UI

#### Вариант 1: LoadBalancer (если включен)

```bash
# Получить EXTERNAL-IP
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Открыть в браузере
open https://$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

#### Вариант 2: Port-forward

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Откройте в браузере: https://localhost:8080

**Логин:** `admin`  
**Пароль:** (из секрета выше)

### Настройка Argo CD Application

#### Через Terraform

В `main.tf` укажите URL вашего GitOps репозитория:

```hcl
module "argo_cd" {
  source = "./modules/argo_cd"
  
  gitops_repo_url = "https://github.com/your-username/your-gitops-repo.git"
  app_name        = "django-app"
  app_path        = "charts/django-app"
  target_revision = "main"
}
```

Затем:
```bash
terraform apply
```

#### Вручную через UI

1. Войдите в Argo CD UI
2. Нажмите "New App"
3. Заполните:
   - **Application Name:** `django-app`
   - **Project Name:** `default`
   - **Repository URL:** URL вашего GitOps репозитория (Repo B)
   - **Path:** `charts/django-app`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `django`
4. Нажмите "Create"

### Проверка статуса Application

```bash
# Проверить статус Application
kubectl get application -n argocd django-app

# Детальная информация
kubectl describe application -n argocd django-app

# Проверить синхронизацию
kubectl get pods -n django
kubectl get svc -n django
```

В UI Argo CD:
- Application должен быть в статусе **Synced** и **Healthy**
- Все ресурсы должны быть развернуты
- При изменении в GitOps репозитории - автоматическая синхронизация

### Как увидеть результат в Argo CD

#### 1. Доступ к Argo CD UI

```bash
# Получить пароль администратора
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

# Port-forward для доступа к UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Откройте в браузере: https://localhost:8080  
**Логин:** `admin`  
**Пароль:** (из команды выше)

#### 2. Проверка Application

1. **В Argo CD UI:**
   - Application `django-app` должен быть виден
   - Статус: **Synced** (зеленый) ✅
   - Health: **Healthy** (зеленый) ✅
   - Sync Policy: **Automated** (автоматическая синхронизация)

2. **Проверка ресурсов:**
   ```bash
   kubectl get application -n argocd django-app
   kubectl get pods -n django
   kubectl get svc -n django
   ```

3. **Детальная информация:**
   ```bash
   kubectl describe application -n argocd django-app
   ```

#### 3. Тест автоматической синхронизации

1. **Обновите `image.tag` в GitOps репозитории:**
   ```bash
   # В GitOps репозитории (Repo B)
   sed -i 's/tag:.*/tag: new-tag-123/' charts/django-app/values.yaml
   git add charts/django-app/values.yaml
   git commit -m "Test: Update image tag"
   git push origin main
   ```

2. **Argo CD автоматически:**
   - Обнаружит изменение (через 3 минуты polling)
   - Начнет автоматическую синхронизацию
   - Развернет новые поды с новым образом
   - Удалит старые поды (prune: true)

3. **Проверка в UI:**
   - В Argo CD UI увидите статус "Syncing" → "Synced"
   - Новые поды появятся в кластере

## GitOps Workflow

### Схема CI/CD процесса

```
┌─────────────┐
│  Repo A     │  (App Repository)
│  - Dockerfile│  - Jenkinsfile
│  - src/      │
└──────┬──────┘
       │ Push code
       ▼
┌─────────────┐
│  Jenkins    │
│  Pipeline   │
│  1. Build   │  (Kaniko)
│  2. Push    │  (ECR)
│  3. Update  │  (Repo B)
└──────┬──────┘
       │ Update values.yaml
       ▼
┌─────────────┐
│  Repo B     │  (GitOps Repository)
│  - charts/  │  - values.yaml
└──────┬──────┘
       │ Git push
       ▼
┌─────────────┐
│  Argo CD    │
│  - Detect   │  (Git changes)
│  - Sync     │  (Auto sync)
│  - Deploy   │  (Kubernetes)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  EKS        │
│  Cluster    │
│  - Pods     │
│  - Service  │
└─────────────┘
```

### Структура репозиториев

**Repo A (App Repo):**
```
app-repo/
├── Dockerfile
├── Jenkinsfile
├── src/
└── requirements.txt
```

**Repo B (GitOps Repo):**
```
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml      # image.tag обновляется Jenkins
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            └── ...
```

### Процесс CI/CD (детальный flow)

#### Шаг 1: Разработчик пушит код
```bash
git push origin main  # В Repo A (App Repository)
```

#### Шаг 2: Jenkins Pipeline (автоматически запускается)

**Stage 1: Checkout**
- Jenkins клонирует Repo A с кодом приложения

**Stage 2: Build and Push to ECR**
- Kaniko собирает Docker образ из Dockerfile
- Образ тегируется с GIT_SHA (например: `abc1234`)
- Образ пушится в ECR:
  - `${ECR_REPO}:${GIT_SHA}` (например: `053414411835.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-django-ecr:abc1234`)
  - `${ECR_REPO}:latest`

**Stage 3: Update GitOps Repository**
- Jenkins клонирует Repo B (GitOps Repository)
- Обновляет `charts/django-app/values.yaml`:
  ```yaml
  image:
    repository: 053414411835.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-django-ecr
    tag: abc1234  # ← Обновлено Jenkins
  ```
- Коммитит и пушит изменения в Repo B

#### Шаг 3: Argo CD (автоматически синхронизирует)

1. **Обнаружение изменений:**
   - Argo CD опрашивает Repo B (polling каждые 3 минуты)
   - Обнаруживает новый коммит с обновленным `values.yaml`

2. **Автоматическая синхронизация:**
   - Argo CD применяет изменения из Helm chart
   - Обновляет Deployment с новым образом
   - Разворачивает новые поды с образом `${ECR_REPO}:abc1234`

3. **Результат:**
   - Новые поды запускаются с обновленным образом
   - Старые поды удаляются (prune: true)
   - Приложение обновлено до новой версии

#### Время выполнения
- Jenkins Pipeline: ~5-10 минут
- Argo CD Sync: ~1-2 минуты после push в Repo B
- **Общее время:** ~6-12 минут от push до деплоя

## Как проверить Jenkins job

### 1. Доступ к Jenkins UI

```bash
# Получить пароль администратора
kubectl get secret -n jenkins jenkins-admin-password -o jsonpath='{.data.password}' | base64 -d && echo

# Port-forward для доступа к UI
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

Откройте в браузере: http://localhost:8080  
**Логин:** `admin`  
**Пароль:** (из команды выше)

### 2. Запуск Pipeline

1. Войдите в Jenkins UI
2. Найдите ваш Pipeline job (например: `django-app-pipeline`)
3. Нажмите "Build Now" или дождитесь автоматического запуска (если настроен webhook)

### 2. Мониторинг выполнения

1. **В Jenkins UI:**
   - Нажмите на номер build (например: #1)
   - Просмотрите "Console Output" для логов
   - Проверьте каждый stage:
     - Build and Push (Kaniko должен собрать образ)
     - Update GitOps (должен обновить values.yaml и запушить)

2. **Проверка результатов:**
   ```bash
   # Проверить образ в ECR
   aws ecr list-images --repository-name lesson-8-9-django-ecr --region us-west-2 --profile study
   
   # Проверить изменения в GitOps репозитории
   # (должен быть новый коммит с обновленным image.tag)
   ```

### 3. Типичные проблемы

**Pipeline падает на этапе Build:**
- Проверьте, что Kaniko pod запустился: `kubectl get pods -n jenkins`
- Проверьте логи Kaniko в Jenkins Console Output

**Pipeline падает на этапе Update GitOps:**
- Проверьте, что GitHub PAT правильный и имеет права на push
- Проверьте, что URL GitOps репозитория правильный
- Проверьте, что путь к values.yaml правильный

**Образ не пушится в ECR:**
- Проверьте AWS credentials в Jenkins
- Проверьте права доступа к ECR
- Проверьте логи Kaniko

## Troubleshooting

### Jenkins не может собрать образ

**Проблема:** Kaniko не может пушить в ECR

**Решение:**
1. Убедитесь, что Jenkins service account имеет права на ECR (IRSA)
2. Или добавьте AWS credentials в Jenkins secrets

### Argo CD не синхронизирует

**Проблема:** Application в статусе Unknown или OutOfSync

**Решение:**
1. Проверьте доступ к GitOps репозиторию
2. Убедитесь, что путь к Helm chart правильный
3. Проверьте логи Argo CD:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### PVC не создается

**Проблема:** PersistentVolumeClaim в статусе Pending

**Решение:**
1. Убедитесь, что EBS CSI Driver установлен:
```bash
kubectl get pods -n kube-system | grep ebs-csi
```
2. Проверьте StorageClass:
```bash
kubectl get storageclass
```

## Очистка ресурсов

```bash
cd lesson-8-9

# Удаление через Terraform
terraform destroy
```

**Внимание:** Это удалит все ресурсы, включая EKS кластер, Jenkins и Argo CD.

## Критерии выполнения ДЗ

### ✅ Встановлення Jenkins + Terraform + Helm (20 балів)

- ✅ Jenkins установлен через Helm chart
- ✅ Установка автоматизирована через Terraform (`modules/jenkins/jenkins.tf`)
- ✅ Kubernetes Agent настроен для работы с Kaniko
- ✅ ServiceAccount `jenkins-sa` создан
- ✅ LoadBalancer настроен для доступа к UI

**Проверка:**
```bash
kubectl get pods -n jenkins
kubectl get svc -n jenkins
helm list -n jenkins
```

### ✅ Робочий Jenkins pipeline (30 балів)

- ✅ Pipeline собирает Docker образ через Kaniko
- ✅ Образ пушится в ECR с тегом (GIT_SHA)
- ✅ Обновляется `image.tag` в `values.yaml` GitOps репозитория
- ✅ Изменения коммитятся и пушатся в main ветку

**Проверка:**
1. Запустите Pipeline в Jenkins UI
2. Проверьте Console Output - все stages должны быть успешными
3. Проверьте ECR: `aws ecr list-images --repository-name lesson-8-9-django-ecr --region us-west-2 --profile study`
4. Проверьте GitOps репозиторий - должен быть новый коммит

### ✅ Встановлення Argo CD + Terraform + Helm (20 балів)

- ✅ Argo CD установлен через Helm chart
- ✅ Установка автоматизирована через Terraform (`modules/argo_cd/argo_cd.tf`)
- ✅ LoadBalancer настроен для доступа к UI

**Проверка:**
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
helm list -n argocd
```

### ✅ Argo application з повною синхронізацією (20 балів)

- ✅ Application создан через Helm chart (`modules/argo_cd/charts/`)
- ✅ Application настроен на GitOps репозиторий
- ✅ Автоматическая синхронизация включена (`automated: prune: true, selfHeal: true`)
- ✅ Helm chart разворачивается в кластер

**Проверка:**
```bash
kubectl get application -n argocd django-app
kubectl describe application -n argocd django-app
# В UI Argo CD: статус должен быть Synced и Healthy
```

### ✅ README.md з описом, командами та схемою CI/CD (10 балів)

- ✅ Полное описание проекта
- ✅ Инструкции по применению Terraform
- ✅ Инструкции по проверке Jenkins job
- ✅ Инструкции по проверке результата в Argo CD
- ✅ Схема CI/CD процесса (ASCII диаграмма)

### ✅ Безопасность (рекомендация ментора)

- ✅ Чувствительные данные (SECRET_KEY, DB_PASSWORD) вынесены в Kubernetes Secret
- ✅ ConfigMap содержит только нечувствительные данные
- ✅ Создан SECURITY.md с рекомендациями для production
- ✅ Документация по использованию AWS Secrets Manager, Vault и других решений

## Безопасность

Чувствительные данные (SECRET_KEY, DB_PASSWORD) в Helm chart для Django-приложения хранятся в Kubernetes Secret, что является улучшением по сравнению с ConfigMap. Однако для production окружений рекомендуется использовать внешние системы управления секретами.

**См. `SECURITY.md`** для детальных рекомендаций по:
- AWS Secrets Manager
- HashiCorp Vault
- Sealed Secrets
- External Secrets Operator

## Дополнительные ресурсы

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html)

## Автор

Nellipestych

## Лицензия

Educational project for GoIT Neoversity

