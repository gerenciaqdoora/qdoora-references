# AWS Hardening — ECS Fargate, WAF, S3, Nginx

> Usa este archivo al revisar infraestructura de Qdoora en AWS o al proponer remediaciones
> de configuración de producción. Stack: ECS Fargate · ALB · S3 · Secrets Manager · nginx.

---

## 1. Checklist Rápido de Infraestructura

Ejecutar antes de cualquier revisión de configuración AWS:

```bash
# Verificar que APP_DEBUG no está en true en la task definition
aws ecs describe-task-definition --task-definition qdoora-api --region us-east-1 | \
  jq '.taskDefinition.containerDefinitions[0].environment[] | select(.name=="APP_DEBUG")'

# Verificar que los secrets sensibles vienen de Secrets Manager (no environment)
aws ecs describe-task-definition --task-definition qdoora-api --region us-east-1 | \
  jq '.taskDefinition.containerDefinitions[0].secrets[] | .name'

# Verificar Block Public Access en bucket de documentos
aws s3api get-public-access-block --bucket qdoora-documents-prod

# Verificar WAF asociado al ALB
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 | jq '.WebACLs[] | {Name, Id}'
```

---

## 2. ECS Task Definition — Secrets Manager
**Remedia**: QD-02 (credentials en texto claro).

```json
{
  "family": "qdoora-api",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/qdoora-api-task-role",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/qdoora-ecs-execution-role",
  "containerDefinitions": [
    {
      "name": "qdoora-api",
      "image": "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/qdoora-api:latest",
      "environment": [
        { "name": "APP_ENV",   "value": "production" },
        { "name": "APP_DEBUG", "value": "false" },
        { "name": "LOG_LEVEL", "value": "error" }
      ],
      "secrets": [
        { "name": "APP_KEY",     "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/app-key" },
        { "name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/db-password" },
        { "name": "JWT_SECRET",  "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/jwt-secret" },
        { "name": "MAIL_PASSWORD","valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/smtp-password" },
        { "name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/aws-secret" }
      ]
    }
  ]
}
```

**Regla**: Ningún secret (APP_KEY, DB_PASSWORD, JWT_SECRET, credenciales SMTP, AWS keys) debe
aparecer en el bloque `environment`. Solo en `secrets` referenciando Secrets Manager.

---

## 3. IAM Task Role — Mínimo Privilegio
**Remedia**: QD-02 (IAM con permisos excesivos), QD-05 (acceso S3 masivo).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3DocumentsBucketOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::qdoora-documents-prod/*"
      ]
    },
    {
      "Sid": "S3ListBucketOnly",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::qdoora-documents-prod"
    },
    {
      "Sid": "SecretsManagerRead",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/*"
    }
  ]
}
```

**Anti-patrón a detectar**: `"Action": "s3:*"` o `"Resource": "*"` → reporte como hallazgo Alto.

---

## 4. WAF Web ACL en ALB
**Remedia**: QD-08 (rate limiting ausente), QD-03 (brute force en login).

```json
{
  "Name": "qdoora-waf-prod",
  "Scope": "REGIONAL",
  "Rules": [
    {
      "Name": "RateLimitAuthEndpoints",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 100,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": { "UriPath": {} },
              "PositionalConstraint": "STARTS_WITH",
              "SearchString": "/api/auth",
              "TextTransformations": [{ "Priority": 0, "Type": "LOWERCASE" }]
            }
          }
        }
      },
      "Action": { "Block": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitAuth"
      }
    },
    {
      "Name": "RateLimitPasswordReset",
      "Priority": 2,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 30,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": { "UriPath": {} },
              "PositionalConstraint": "STARTS_WITH",
              "SearchString": "/api/password",
              "TextTransformations": [{ "Priority": 0, "Type": "LOWERCASE" }]
            }
          }
        }
      },
      "Action": { "Block": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitPasswordReset"
      }
    },
    {
      "Name": "AWSManagedRulesCommonRuleSet",
      "Priority": 10,
      "OverrideAction": { "None": {} },
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "CommonRuleSet"
      }
    },
    {
      "Name": "AWSManagedRulesSQLiRuleSet",
      "Priority": 11,
      "OverrideAction": { "None": {} },
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesSQLiRuleSet"
        }
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "SQLiRuleSet"
      }
    }
  ]
}
```

---

## 5. nginx.conf — Security Headers y Fingerprinting
**Remedia**: QD-10 (fuga de versiones), headers de seguridad faltantes.

```nginx
# /etc/nginx/conf.d/qdoora-api.conf

server {
    listen 80;
    server_name api.qdoora.cl;

    # Ocultar fingerprinting
    server_tokens off;
    more_clear_headers 'X-Powered-By';
    more_clear_headers 'Server';

    # Security Headers
    add_header Strict-Transport-Security  "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options            "DENY" always;
    add_header X-Content-Type-Options     "nosniff" always;
    add_header Referrer-Policy            "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy         "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy    "default-src 'none'; connect-src 'self'; frame-ancestors 'none';" always;

    # CORS — solo orígenes autorizados
    set $cors_origin "";
    if ($http_origin ~* "^https://(app|admin)\.qdoora\.cl$") {
        set $cors_origin $http_origin;
    }
    add_header Access-Control-Allow-Origin  $cors_origin always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept" always;
    add_header Vary                         "Origin" always;

    if ($request_method = 'OPTIONS') {
        return 204;
    }

    location / {
        proxy_pass         http://localhost:9000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
```

---

## 6. S3 Bucket — Configuración Segura
**Remedia**: QD-05 (acceso público a bucket de documentos).

```bash
# Bloquear acceso público al bucket de documentos
aws s3api put-public-access-block \
  --bucket qdoora-documents-prod \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Habilitar server-side encryption
aws s3api put-bucket-encryption \
  --bucket qdoora-documents-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Verificar configuración
aws s3api get-public-access-block --bucket qdoora-documents-prod
aws s3api get-bucket-encryption --bucket qdoora-documents-prod
```

**Expiración de presigned URLs** — verificar en Laravel:
```php
// ✅ CORRECTO: expiración corta (5 minutos)
Storage::disk('s3')->temporaryUrl($path, now()->addMinutes(5));

// ❌ INCORRECTO: expiración excesiva
// Storage::disk('s3')->temporaryUrl($path, now()->addHours(24));
```
