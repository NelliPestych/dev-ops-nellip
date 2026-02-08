# DevOps Final Project

Проєкт для розгортання Django додатку на AWS з використанням Terraform, EKS, Jenkins, Argo CD та моніторингу.

## Структура проєкту

```
Project/
├── bootstrap/           # Bootstrap проєкт для створення S3/DynamoDB backend
│  ├── main.tf
│  ├── variables.tf
│  ├── outputs.tf
│  └── terraform.tfvars
│
├── main.tf              # Головний файл для підключення модулів
├── backend.tf           # Налаштування remote бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf           # Загальні виводи ресурсів
├── variables.tf          # Змінні
├── terraform.tfvars      # Значення змінних
│
├── modules/              # Каталог з усіма модулями
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
└── Django/               # Django додаток
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

## Порядок запуску

### 1. Bootstrap Backend (S3 + DynamoDB)

**ВАЖЛИВО**: Спочатку потрібно створити S3 bucket та DynamoDB таблицю для збереження Terraform state. Це робиться через окремий bootstrap проєкт з локальним state.

```bash
cd bootstrap

# Відредагуйте terraform.tfvars з вашими значеннями
# Особливо важливо: bucket name має бути globally unique!

terraform init
terraform plan
terraform apply
```

Після успішного створення backend, переконайтеся що значення в `bootstrap/terraform.tfvars` відповідають значенням в `backend.tf` в корені проєкту.

### 2. Налаштування змінних основного проєкту

Відредагуйте `terraform.tfvars` в корені проєкту та встановіть необхідні значення:

```hcl
aws_region            = "us-east-1"
rds_password          = "YourSecurePassword123!"  # Змініть на безпечний пароль
```

### 3. Ініціалізація основного Terraform проєкту

```bash
cd ..
terraform init -reconfigure
```

Флаг `-reconfigure` необхідний для налаштування remote backend після створення S3 bucket.

### 4. Розгортання інфраструктури

```bash
terraform plan
terraform apply
```

Це займе приблизно 20-30 хвилин для створення всієї інфраструктури.

### 5. Налаштування kubectl

Після створення EKS кластера, налаштуйте kubectl:

```bash
aws eks update-kubeconfig --name devops-cluster --region us-east-1
```

Перевірте підключення:

```bash
kubectl get nodes
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

## Port-forward команди

Для доступу до сервісів через port-forward:

```bash
# Jenkins
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

# Argo CD
kubectl port-forward svc/argocd-server 8081:443 -n argocd

# Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring

# Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```

## Видалення інфраструктури

⚠️ **УВАГА**: 

1. **Основна інфраструктура**: При видаленні основної інфраструктури через `terraform destroy` в корені проєкту, S3 bucket та DynamoDB таблиця НЕ будуть видалені (вони створені через bootstrap).

2. **Bootstrap backend**: Якщо потрібно видалити S3 bucket та DynamoDB таблицю, виконайте:
   ```bash
   cd bootstrap
   terraform destroy
   ```
   **УВАГА**: Це видалить backend для Terraform state! Виконайте це тільки якщо ви впевнені, що більше не потрібен state.

Для видалення основної інфраструктури:

```bash
# В корені проєкту
terraform destroy
```

## CI/CD Pipeline (GitOps)

Jenkins pipeline автоматично виконує наступні кроки:

1. **Build**: Білдить Docker образ Django додатку
2. **Test**: Запускає тести
3. **Push to ECR**: Пушить образ в ECR з тегом BUILD_NUMBER
4. **Update Helm values**: Оновлює `charts/django-app/values.yaml` з новим image.repository та image.tag
5. **Commit & Push**: Комітить зміни в гілку `final_project` та пушить в репозиторій

**Деплой через Argo CD (GitOps)**:
- Argo CD з auto-sync відстежує зміни в репозиторії
- При виявленні нового commit з оновленими values.yaml, Argo CD автоматично синхронізує додаток
- Виконується deploy/rollout нового образу в EKS

### Jenkins Credentials

Для роботи pipeline потрібні наступні credentials в Jenkins:

1. **github_pat** (Secret text):
   - GitHub Personal Access Token з правами `repo`
   - Використовується для push змін в репозиторій
   - Створіть токен: GitHub Settings → Developer settings → Personal access tokens

2. **aws-credentials** (AWS credentials):
   - AWS Access Key ID та Secret Access Key
   - Використовується для доступу до ECR та EKS

### CI/CD Demo

**Сценарій роботи:**

1. Розробник пушить код в репозиторій
2. Jenkins запускає pipeline:
   - Build Docker image
   - Push в ECR (tag: BUILD_NUMBER)
   - Оновлює `charts/django-app/values.yaml` (image.repository + image.tag)
   - Commit + push у гілку `final_project`
3. Argo CD (auto-sync) підтягує зміни з репозиторію
4. Argo CD виконує deploy/rollout нового образу в EKS
5. Додаток оновлюється з новим образом

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
