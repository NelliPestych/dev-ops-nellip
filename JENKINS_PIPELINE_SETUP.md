# Інструкції для запуску Jenkins Pipeline

## Jenkins Admin Credentials

**URL**: http://localhost:8080 (після port-forward)
**Логін**: admin
**Пароль**: Отримайте командою:
```bash
kubectl exec -n jenkins jenkins-0 -c jenkins -- cat /run/secrets/additional/chart-admin-password
```

## Крок 1: Port-forward до Jenkins

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

## Крок 2: Відкрийте Jenkins UI

Відкрийте в браузері: http://localhost:8080

## Крок 3: Створіть Pipeline Job

1. Натисніть **"New Item"** (або "Створити новий проект")
2. Введіть назву: **django-app**
3. Виберіть **"Pipeline"** і натисніть **OK**
4. У розділі **"Pipeline"**:
   - Виберіть **"Pipeline script from SCM"**
   - **SCM**: Git
   - **Repository URL**: `https://github.com/NelliPestych/dev-ops-nellip.git`
   - **Branch**: `*/final_project`
   - **Script Path**: `Django/Jenkinsfile`
5. Натисніть **"Save"** (Зберегти)

## Крок 4: Налаштуйте Jenkins Credentials

Перед запуском pipeline переконайтеся, що створені credentials:

1. **github_pat** (Secret text):
   - GitHub Personal Access Token з правами `repo`
   - Jenkins → Manage Jenkins → Credentials → Add Credentials
   - Kind: Secret text
   - ID: `github_pat`

2. **aws-credentials** (AWS Credentials):
   - AWS Access Key ID та Secret Access Key
   - Jenkins → Manage Jenkins → Credentials → Add Credentials
   - Kind: AWS Credentials
   - ID: `aws-credentials`

3. **eks-credentials** (Kubernetes config):
   - Kubernetes config для доступу до EKS
   - Jenkins → Manage Jenkins → Credentials → Add Credentials
   - Kind: Kubernetes configuration
   - ID: `eks-credentials`

## Крок 5: Запустіть Pipeline

1. На головній сторінці Jenkins знайдіть **django-app**
2. Натисніть **"Build Now"** (або "Запустити збірку")
3. Pipeline почне виконуватися автоматично

## Крок 6: Перевірте прогрес

1. Натисніть на номер build (наприклад, #1)
2. Перегляньте **"Console Output"** для деталей виконання

## Що робить Pipeline

1. **Checkout**: Клонує код з репозиторію
2. **Setup Python dependencies**: Встановлює pyyaml
3. **Build**: Білдить Docker образ Django додатку
4. **Test**: Запускає тести (якщо є)
5. **Push to ECR**: Пушить образ в ECR з тегом BUILD_NUMBER
6. **Update Helm values**: Оновлює `charts/django-app/values.yaml` з новим image.repository та image.tag
7. **Commit & Push**: Комітить зміни в гілку `final_project` та пушить в репозиторій

## Після успішного Pipeline

- Docker образ буде створений і запушений в ECR
- `charts/django-app/values.yaml` буде оновлено з новим образом
- Argo CD автоматично синхронізує зміни (auto-sync enabled)
- Django app буде задеплоєний з новим образом

## Перевірка результату

```bash
# Перевірте Argo CD Application
kubectl get application django-app -n argocd

# Перевірте Django app pods
kubectl get pods -l app.kubernetes.io/name=django-app

# Перевірте логи
kubectl logs -l app.kubernetes.io/name=django-app --tail=50
```

