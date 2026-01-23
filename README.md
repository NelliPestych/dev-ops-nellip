# Lesson 7 — Helm + EKS + ECR (Terraform)

## Описание проекта

Этот проект создает инфраструктуру AWS с помощью Terraform и разворачивает Django-приложение в кластере EKS с использованием Helm chart.

### Компоненты инфраструктуры:
- **VPC** с публичными и приватными подсетями, Internet Gateway и NAT Gateway
- **S3 Backend** для хранения Terraform state
- **DynamoDB** для блокировки state файлов
- **ECR** репозиторий для Docker образов
- **EKS** кластер Kubernetes с managed node group (2-6 нод)
- **Helm Chart** для развертывания Django-приложения:
  - Deployment с образом из ECR
  - Service типа LoadBalancer для внешнего доступа
  - ConfigMap с переменными окружения из темы 4
  - HPA (Horizontal Pod Autoscaler) для автоматического масштабирования (2-6 реплик, CPU > 70%)

## Структура проекта

```
lesson-7/
├── main.tf                  # Главный файл для подключения модулей
├── backend.tf               # Настройка бекенда для state (S3 + DynamoDB)
├── outputs.tf               # Общие выводы ресурсов
│
├── modules/                 # Каталог со всеми модулями
│   ├── s3-backend/          # Модуль для S3 и DynamoDB
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── eks/                 # Модуль для Kubernetes кластера
│       ├── eks.tf
│       ├── iam.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml       # ConfigMap с переменными окружения
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

## Требования

- **Terraform** >= 1.0
- **AWS CLI** настроен с профилем (например: `--profile study`)
- **kubectl** для работы с Kubernetes
- **Helm** для развертывания приложений
- **Docker** для сборки и push образов

## Установка CLI инструментов (Mac)

### kubectl
```bash
brew install kubectl
kubectl version --client
```

### AWS CLI
```bash
brew install awscli
aws --version
```

### Helm
```bash
brew install helm
helm version
```

## Работа с Terraform

### Стратегия Backend

Для первого запуска backend настроен как локальный (`terraform {}`), чтобы сначала создать S3 bucket и DynamoDB таблицу. После первого apply нужно раскомментировать backend "s3" в `backend.tf` и выполнить миграцию state.

### Первый запуск (локальный backend)

1. Перейдите в директорию проекта:
```bash
cd lesson-7
```

2. Инициализируйте Terraform:
```bash
terraform init
```

3. Проверьте план:
```bash
terraform plan
```

4. Примените изменения:
```bash
terraform apply
```

5. Получите outputs (важно для следующих шагов):
```bash
terraform output
```

**Outputs:**
- `ecr_repository_url` - URL репозитория ECR
- `eks_cluster_name` - Имя EKS кластера
- `state_bucket_name` - Имя S3 bucket для state
- `dynamodb_table_name` - Имя DynamoDB таблицы

### Второй запуск (миграция на S3 backend)

1. Раскомментируйте блок `backend "s3"` в `backend.tf`

2. Выполните миграцию state:
```bash
terraform init -migrate-state -reconfigure
```

3. Проверьте, что state успешно мигрирован:
```bash
terraform plan
```

## Подключение kubectl к EKS

После создания кластера подключите kubectl:

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks --profile study
```

Проверьте подключение:
```bash
kubectl config current-context
kubectl get nodes -o wide
```

Ожидайте 1-3 минуты, пока ноды станут Ready.

## Работа с ECR

### Логин в ECR

```bash
aws ecr get-login-password --region us-west-2 --profile study \
  | docker login --username AWS --password-stdin 053414411835.dkr.ecr.us-west-2.amazonaws.com
```

### Получение URL репозитория

```bash
cd lesson-7
terraform output -raw ecr_repository_url
```

### Сборка и Push Docker образа

**Важно:** Образ должен быть собран для платформы `linux/amd64`, так как ноды EKS работают на amd64.

1. Получите исходный код Django-приложения из ветки `lesson-4`:
```bash
git checkout lesson-4
# или скопируйте файлы из lesson-4
```

2. Соберите образ для правильной платформы:
```bash
ECR_URL=$(terraform output -raw ecr_repository_url)

docker buildx build --platform linux/amd64 \
  -t $ECR_URL:latest \
  --push .
```

3. Проверьте, что образ запушен:
```bash
aws ecr list-images --repository-name lesson-7-django-ecr --region us-west-2 --profile study
```

## Развертывание с Helm

### Обновление values.yaml

Убедитесь, что в `charts/django-app/values.yaml` указан правильный URL ECR репозитория:

```yaml
image:
  repository: "053414411835.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-ecr"
  tag: "latest"
```

### Установка Helm chart

1. Перейдите в директорию chart:
```bash
cd lesson-7/charts/django-app
```

2. Проверьте chart:
```bash
helm lint .
```

3. Установите release:
```bash
helm install django-app . --namespace django --create-namespace
```

4. Или обновите существующий:
```bash
helm upgrade django-app . --namespace django
```

### Проверка развертывания

```bash
# Проверка подов
kubectl get pods -n django

# Проверка сервисов
kubectl get svc -n django -o wide

# Проверка HPA
kubectl get hpa -n django
kubectl describe hpa django-app -n django

# Проверка ConfigMap
kubectl get configmap -n django
kubectl get configmap django-app-config -n django -o yaml

# Проверка всех ресурсов
kubectl get all -n django
```

### Получение внешнего IP

```bash
kubectl get svc django-app -n django -o wide
```

EXTERNAL-IP будет доступен через несколько минут после создания LoadBalancer.

## Переменные окружения (ConfigMap)

В `values.yaml` настроены переменные окружения из темы 4:

- `DJANGO_SETTINGS_MODULE`: "config.settings"
- `DEBUG`: "0"
- `ALLOWED_HOSTS`: "*"
- `DB_HOST`: "db"
- `DB_NAME`: "postgres"
- `DB_USER`: "postgres"
- `DB_PASSWORD`: "postgres"
- `DB_PORT`: "5432"
- `SECRET_KEY`: (из темы 4)

Эти переменные автоматически создаются в ConfigMap и подключаются к подам через `envFrom`.

## Очистка ресурсов

**Внимание:** Удаление всех ресурсов также удалит S3 bucket и DynamoDB таблицу, используемые для remote state.

```bash
cd lesson-7

# Удаление Helm release
helm uninstall django-app -n django

# Удаление инфраструктуры
terraform destroy
```

## Troubleshooting

### Проблема: ImagePullBackOff

**Причина:** Образ собран для неправильной платформы (arm64 вместо amd64).

**Решение:** Пересоберите образ для `linux/amd64`:
```bash
docker buildx build --platform linux/amd64 -t <ECR_URL>:latest --push .
```

### Проблема: HPA не может получить метрики

**Причина:** В EKS по умолчанию не установлен metrics-server.

**Решение:** Это нормально для базовой настройки. HPA создан и настроен правильно, метрики появятся после установки metrics-server (не требуется для ДЗ).

### Проблема: Ноды не становятся Ready

**Решение:** Подождите 2-5 минут и проверьте снова:
```bash
kubectl get nodes -o wide
```

## Критерии выполнения ДЗ

✅ Кластер Kubernetes создан через Terraform и работает  
✅ ECR создан и содержит загруженный Docker образ  
✅ Deployment, Service и HPA созданы и работают в кластере через helm  
✅ ConfigMap создан и используется приложением  
✅ Проект запушен в GitHub-репозиторий в ветку lesson-7 с документацией в README.md

## Автор

Nellipestych

## Лицензия

Educational project for GoIT Neoversity
