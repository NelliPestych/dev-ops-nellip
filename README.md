# DevOps Final Project

Проєкт для розгортання Django додатку на AWS з використанням Terraform, EKS, Jenkins, Argo CD та моніторингу.

## Структура проєкту

```
Project/
├── main.tf              # Головний файл для підключення модулів
├── backend.tf           # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf           # Загальні виводи ресурсів
├── variables.tf         # Змінні
├── terraform.tfvars     # Значення змінних
│
├── modules/             # Каталог з усіма модулями
│  ├── s3-backend/       # Модуль для S3 та DynamoDB
│  ├── vpc/              # Модуль для VPC
│  ├── ecr/              # Модуль для ECR
│  ├── eks/              # Модуль для Kubernetes кластера
│  ├── rds/              # Модуль для RDS
│  ├── jenkins/          # Модуль для Helm-установки Jenkins
│  ├── argo_cd/          # Модуль для Helm-установки Argo CD
│  └── monitoring/       # Модуль для Prometheus та Grafana
│
├── charts/              # Helm чарти
│  └── django-app/       # Helm чарт для Django додатку
│
└── Django/              # Django додаток
   ├── app/
   ├── Dockerfile
   ├── Jenkinsfile
   └── docker-compose.yaml
```

## Передумови

1. AWS CLI налаштований з коректними credentials
2. Terraform >= 1.0
3. kubectl встановлений
4. Helm 3.x встановлений
5. Docker встановлений

## Встановлення

### 1. Підготовка S3 Backend

**ВАЖЛИВО**: Перед використанням Terraform backend, потрібно створити S3 bucket та DynamoDB таблицю вручну або через окремий скрипт.

```bash
# Створіть S3 bucket
aws s3 mb s3://devops-nellip-terraform-state --region us-east-1

# Створіть DynamoDB таблицю
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Налаштування змінних

Відредагуйте `terraform.tfvars` та встановіть необхідні значення:

```hcl
aws_region            = "us-east-1"
rds_password          = "YourSecurePassword123!"  # Змініть на безпечний пароль
```

### 3. Ініціалізація Terraform

```bash
terraform init
```

### 4. Розгортання інфраструктури

```bash
terraform plan
terraform apply
```

## Використання

### Доступ до Jenkins

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Відкрийте браузер: http://localhost:8080

Отримати пароль адміністратора:
```bash
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
```

### Доступ до Argo CD

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

Відкрийте браузер: https://localhost:8081

Отримати пароль адміністратора:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### Доступ до Grafana

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Відкрийте браузер: http://localhost:3000

Логін: `admin` / Пароль: `admin` (за замовчуванням)

### Доступ до Prometheus

```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```

Відкрийте браузер: http://localhost:9090

## Перевірка стану

```bash
# Перевірка Jenkins
kubectl get all -n jenkins

# Перевірка Argo CD
kubectl get all -n argocd

# Перевірка моніторингу
kubectl get all -n monitoring

# Перевірка Django app
kubectl get all -n default
```

## Видалення інфраструктури

⚠️ **УВАГА**: При видаленні всієї інфраструктури за допомогою `terraform destroy` ви також видаляєте S3-бакет і DynamoDB-таблицю, які використовуються для збереження Terraform стейту.

Якщо потрібно зберегти стейт, видаліть ресурси вручну або використайте `terraform destroy -target` для селективного видалення.

```bash
terraform destroy
```

## CI/CD Pipeline

Jenkins pipeline автоматично:
1. Білдить Docker образ Django додатку
2. Запускає тести
3. Пушить образ в ECR
4. Деплоїть в EKS

## Моніторинг

- **Prometheus**: Збір метрик
- **Grafana**: Візуалізація метрик та дашборди
- **Alertmanager**: Налаштування алертів

## Автомасштабування

Django app налаштований з HPA (Horizontal Pod Autoscaler) для автоматичного масштабування на основі CPU та Memory використання.

## Безпека

- VPC з приватними та публічними підмережами
- Security Groups для контролю доступу
- IAM ролі з мінімальними необхідними правами
- Шифрування даних в RDS та S3

## Підтримка

При виникненні проблем звертайтеся до ментора у Slack.
