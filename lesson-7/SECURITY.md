# Рекомендации по безопасности для production

## Управление секретами

### Текущая реализация

В текущей конфигурации чувствительные данные (SECRET_KEY, DB_PASSWORD) хранятся в Kubernetes Secret, что является улучшением по сравнению с ConfigMap, но все еще не идеально для production.

### Рекомендации для production

#### 1. Использование AWS Secrets Manager

Для EKS кластера рекомендуется использовать AWS Secrets Manager через External Secrets Operator:

```yaml
# Установка External Secrets Operator
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/charts/external-secrets/templates/crds/crd-secretstore.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/charts/external-secrets/templates/crds/crd-externalsecret.yaml

# Создание SecretStore для AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
```

#### 2. Использование HashiCorp Vault

Для более сложных сценариев можно использовать HashiCorp Vault:

```yaml
# Пример ExternalSecret для Vault
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: django-secrets
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: django-secret
    creationPolicy: Owner
  data:
    - secretKey: SECRET_KEY
      remoteRef:
        key: secret/django
        property: secret_key
    - secretKey: DB_PASSWORD
      remoteRef:
        key: secret/django
        property: db_password
```

#### 3. Использование Sealed Secrets

Для GitOps подходов можно использовать Sealed Secrets:

```bash
# Установка kubeseal
brew install kubeseal

# Создание SealedSecret
kubectl create secret generic django-secret \
  --from-literal=SECRET_KEY='your-secret-key' \
  --from-literal=DB_PASSWORD='your-db-password' \
  --dry-run=client -o yaml | kubeseal -o yaml > sealed-secret.yaml
```

#### 4. Ротация секретов

Для production важно настроить автоматическую ротацию секретов:

- AWS Secrets Manager поддерживает автоматическую ротацию
- Используйте разные секреты для разных окружений (dev, staging, production)
- Настройте мониторинг и алерты на утечки секретов

### Текущая структура

```
lesson-7/charts/django-app/
├── templates/
│   ├── configmap.yaml    # Нечувствительные данные
│   ├── secret.yaml       # Чувствительные данные (SECRET_KEY, DB_PASSWORD)
│   └── deployment.yaml   # Использует оба источника
└── values.yaml           # Разделено на config и secrets
```

### Миграция на production

1. **Создайте секреты в AWS Secrets Manager:**
   ```bash
   aws secretsmanager create-secret \
     --name django/secret-key \
     --secret-string "your-production-secret-key" \
     --region us-west-2
   
   aws secretsmanager create-secret \
     --name django/db-password \
     --secret-string "your-production-db-password" \
     --region us-west-2
   ```

2. **Установите External Secrets Operator:**
   ```bash
   helm repo add external-secrets https://charts.external-secrets.io
   helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace
   ```

3. **Создайте SecretStore и ExternalSecret:**
   - См. примеры выше

4. **Обновите values.yaml:**
   - Удалите секреты из values.yaml
   - Используйте ExternalSecret для автоматической синхронизации

### Best Practices

1. ✅ **Никогда не коммитьте секреты в Git**
2. ✅ **Используйте разные секреты для разных окружений**
3. ✅ **Настройте автоматическую ротацию секретов**
4. ✅ **Используйте минимальные права доступа (principle of least privilege)**
5. ✅ **Логируйте доступ к секретам**
6. ✅ **Регулярно аудитируйте использование секретов**

### Дополнительные ресурсы

- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [External Secrets Operator](https://external-secrets.io/)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Kubernetes Secrets Best Practices](https://kubernetes.io/docs/concepts/configuration/secret/#best-practices)

