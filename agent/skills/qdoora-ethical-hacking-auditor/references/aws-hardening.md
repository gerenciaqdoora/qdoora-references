# AWS Hardening — ECS Fargate, S3 Multi-Environment, Secrets Manager

> Usa este archivo al revisar la infraestructura de QdoorA en AWS o al proponer remediaciones
> de configuración de producción. Stack: ECS Fargate · ALB · S3 · Secrets Manager · KMS.

---

## 1. Checklist Rápido de Infraestructura (Detección Activa)

Ejecutar antes de cualquier revisión de configuración AWS:

```bash
# 1. Verificar que APP_DEBUG no está en true en la Task Definition de ECS
aws ecs describe-task-definition --task-definition qdoora-api --region us-east-1 | \
  jq '.taskDefinition.containerDefinitions[0].environment[] | select(.name=="APP_DEBUG")'

# 2. Verificar que los secrets sensibles vienen de Secrets Manager (no environment crudo)
aws ecs describe-task-definition --task-definition qdoora-api --region us-east-1 | \
  jq '.taskDefinition.containerDefinitions[0].secrets[] | .name'

# 3. Verificar Block Public Access en buckets S3 por ambiente (dev, qa, prod)
for bucket in qdoora-chile-dev qdoora-chile-qa qdoora-chile-prod; do
  echo "=== Bucket: $bucket ==="
  aws s3api get-public-access-block --bucket "$bucket"
done

# 4. Verificar WAF asociado al ALB
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 | jq '.WebACLs[] | {Name, Id}'
```

---

## 2. ECS Task Definition — Secrets Manager Integrado (Stateless)
**Remedia**: QD-02 (secrets expuestos en texto plano en la app o base de datos).

Para evitar guardar secretos críticos en variables de entorno crudas en la Task Definition o en tablas de configuración de base de datos en texto claro, los inyectamos en tiempo de ejecución de forma **stateless** utilizando **AWS Secrets Manager** referenciado en la definición del contenedor de ECS.

```json
{
  "family": "qdoora-api",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/qdoora-ecs-task-role",
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
        { "name": "APP_KEY",      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/secrets:APP_KEY::" },
        { "name": "DB_PASSWORD",  "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/secrets:DB_PASSWORD::" },
        { "name": "JWT_SECRET",   "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/secrets:JWT_SECRET::" },
        { "name": "MAIL_PASSWORD","valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/secrets:MAIL_PASSWORD::" }
      ]
    }
  ]
 Segregación de secretos por ambiente:
  - Desarrollo/Local: `.env` local.
  - QA/VPS: `.env.qa` inyectado mediante Secrets Manager local o variables de Docker Compose.
  - Producción: AWS Secrets Manager inyectado dinámicamente en el ECS Task Definition sin almacenamiento en disco (Stateless).
}
```

---

## 3. IAM Task Role & Task Execution Role (Mínimo Privilegio)
**Remedia**: QD-02 (IAM con permisos excesivos), QD-05 (acceso S3 masivo y fuga entre ambientes).

### A. Task Execution Role (`qdoora-ecs-execution-role`)
Permite al agente de ECS arrancar los contenedores y descargar las imágenes del ECR y los secretos desde Secrets Manager.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/*"
    },
    {
      "Sid": "KMSDecryptSecrets",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
    }
  ]
}
```

### B. Task Role (`qdoora-ecs-task-role`)
Permite a la aplicación (el contenedor en ejecución) consumir recursos de AWS (como S3) **sin persistir Access/Secret keys** en los archivos de entorno o contenedor.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::qdoora-chile-prod/*"
    },
    {
      "Sid": "S3ListBucketOnly",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::qdoora-chile-prod"
    }
  ]
}
```

---

## 4. WAF Web ACL en ALB (Fuerza Bruta & Rate Limiting)
**Remedia**: QD-08 (rate limiting ausente), QD-03 (brute force en login).

```json
{
  "Name": "qdoora-waf-prod",
  "Scope": "REGIONAL",
  "Rules": [
    {
      "Name": "RateLimitLoginAuth",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 100,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": { "UriPath": {} },
              "PositionalConstraint": "EXACTLY",
              "SearchString": "/api/v1/login",
              "TextTransformations": [{ "Priority": 0, "Type": "LOWERCASE" }]
            }
          }
        }
      },
      "Action": { "Block": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitLogin"
      }
    },
    {
      "Name": "RateLimitPDFAndDTE",
      "Priority": 2,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 50,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": { "UriPath": {} },
              "PositionalConstraint": "CONTAINS",
              "SearchString": "/pdf",
              "TextTransformations": [{ "Priority": 0, "Type": "LOWERCASE" }]
            }
          }
        }
      },
      "Action": { "Block": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitPDF"
      }
    }
  ]
}
```

---

## 5. nginx.conf — Ocultamiento de Fingerprinting y Security Headers
**Remedia**: QD-10 (fuga de versiones), headers de seguridad ausentes.

```nginx
# /etc/nginx/conf.d/qdoora-api.conf

server {
    listen 80;
    server_name api.qdoora.cl;

    # Ocultar firmas y software del servidor
    server_tokens off;
    more_clear_headers 'X-Powered-By';
    more_clear_headers 'Server';

    # Security Headers obligatorios
    add_header Strict-Transport-Security  "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options            "DENY" always;
    add_header X-Content-Type-Options     "nosniff" always;
    add_header Referrer-Policy            "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy         "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy    "default-src 'none'; connect-src 'self'; frame-ancestors 'none';" always;

    # CORS — orígenes estrictamente acotados
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
}
```

---

## 6. S3 Bucket — Configuración Multientorno y Encriptación
**Remedia**: QD-05 (IDOR y presigned URLs sin control).

### A. Aislamiento por Buckets Independientes
- **Desarrollo (Local):** `qdoora-chile-dev`
- **QA (VPS):** `qdoora-chile-qa`
- **Producción (AWS):** `qdoora-chile-prod`

### B. Aplicación del Block Public Access y Encriptación KMS
```bash
# Aplicar bloqueo total de acceso público en el bucket de producción
aws s3api put-public-access-block \
  --bucket qdoora-chile-prod \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Forzar encriptación por defecto usando llaves KMS gestionadas por AWS
aws s3api put-bucket-encryption \
  --bucket qdoora-chile-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      },
      "BucketKeyEnabled": true
    }]
  }'
```

### C. Configuración de Expiración Corta en Presigned URLs (Laravel)
```php
// ✅ CORRECTO: Expiración estrictamente limitada a 5 minutos
Storage::disk('s3')->temporaryUrl($path, now()->addMinutes(5));

// ❌ INCORRECTO: Evitar expiraciones prolongadas o infinitas
// Storage::disk('s3')->temporaryUrl($path, now()->addHours(24));
```

---

## 7. SQS Queues — Mínimo Privilegio y Encriptación
**Remedia**: QD-14 (Falta de encriptación), QD-12 (Exceso de privilegios en colas).

### A. Políticas IAM para Colas (Least Privilege)
Evitar conceder `sqs:*`. Los workers de Laravel solo necesitan recibir y eliminar mensajes procesados, y los publicadores solo enviar.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SQSWorkerPermissions",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:us-east-1:ACCOUNT_ID:qdoora-prod-queue"
    },
    {
      "Sid": "SQSPublisherPermissions",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "arn:aws:sqs:us-east-1:ACCOUNT_ID:qdoora-prod-queue"
    }
  ]
}
```

### B. Encriptación en Reposo (SSE-KMS)
Todas las colas SQS deben crearse con Server-Side Encryption (SSE) configurado para proteger payloads sensibles.

```bash
aws sqs set-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/qdoora-prod-queue \
  --attributes KmsMasterKeyId="alias/aws/sqs",KmsDataKeyReusePeriodSeconds="300"
```
