# Guía Universal de Hardening de Infraestructura y Nube (Cloud Hardening)

> Directrices de configuración y blindaje para infraestructura de contenedores, servidores y nubes públicas.
> Aplicable a AWS, GCP, Azure, Kubernetes y despliegues con Nginx/WAF.

---

## 1. Gestión Inalterable y Stateless de Secretos
**Vectores Asociados**: QD-02 (Secrets exposure).

**Regla de Oro**: Ningún archivo `.env` o de configuración cruda de producción debe subirse al contenedor o persistir en sistemas de archivos locales. Los secretos se inyectan en tiempo de ejecución desde bóvedas criptográficas seguras.

### Patrón de Inyección Segura:
*   **AWS**: Inyectar secretos en la definición de tareas (Task Definition) de **ECS Fargate** referenciando de forma directa a **AWS Secrets Manager** o **Parameter Store**.
*   **Kubernetes**: Consumir secretos utilizando `Kubernetes Secrets` inyectados como variables de entorno o volúmenes montados, preferiblemente integrados con **HashiCorp Vault** o administrados por **External Secrets Operator**.
*   **Docker Compose / On-Premise**: Utilizar archivos `.env` restringidos con privilegios de lectura únicamente para el sistema de ejecución de Docker (chmod 600) y excluir del build de imágenes.

---

## 2. Acceso Basado en Roles de Identidad (IAM Stateless Roles)
**Vectores Asociados**: QD-02 (IAM keys leak).

**Regla de Oro**: Prohibido usar llaves estáticas (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` o archivos JSON de cuentas de servicio) dentro de los contenedores de producción. El acceso a recursos en la nube debe delegarse a **roles asimilados** de forma dinámica.

### Patrones de Autorización Stateless:
*   **AWS ECS**: Asignar un **IAM Task Role** exclusivo al contenedor. El SDK de AWS detectará automáticamente la firma de identidad sin requerir llaves hardcodeadas.
*   **Kubernetes (EKS)**: Emplear **IRSA (IAM Roles for Service Accounts)** para asociar cuentas de servicio de Kubernetes con políticas IAM de AWS de forma granular.
*   **GCP**: Usar identidades asociadas a recursos mediante **Workload Identity Federation** o perfiles de computación asignados de forma nativa a la máquina/contenedor.

---

## 3. Aislamiento Físico y Multi-Entorno de Almacenamiento
**Vectores Asociados**: QD-05 (Aislamiento S3 / Multi-tenant).

**Regla de Oro**: Cada entorno de ejecución (Desarrollo, Staging/QA, Producción) debe poseer buckets de almacenamiento y recursos completamente independientes y aislados en diferentes cuentas o capas físicas.

### Checklist de Seguridad de Almacenamiento en la Nube (ej. S3, GCS):
1. **Bloqueo de Acceso Público**: Activar siempre Block Public Access a nivel de bucket de almacenamiento.
2. **Encriptación por Defecto**: Habilitar encriptación en reposo forzada utilizando llaves gestionadas por el proveedor (SSE-S3) o llaves de cliente (SSE-KMS).
3. **Mínimo Privilegio IAM**: Las políticas de acceso a almacenamiento deben restringirse a acciones específicas (`GetObject`, `PutObject`, `DeleteObject`) y dirigirse únicamente a rutas acotadas del bucket. Prohibido el uso de `"Action": "s3:*"` o wildcard `"Resource": "*"`.

---

## 4. Rate Limiting y Protección DoS en el Borde (Edge WAF / ALB)
**Vectores Asociados**: QD-03 (Brute force), QD-08 (Rate Limiting).

**Regla de Oro**: El primer filtro de mitigación DoS y limitación de frecuencia de peticiones debe aplicarse en el balanceador o CDN en el borde de la red, disminuyendo la carga sobre los servidores de aplicación.

### Buenas Prácticas de Configuración WAF:
*   **Límites por IP en Login**: Configurar reglas en WAF (ej. AWS WAFv2, Cloudflare) que bloqueen temporalmente direcciones IP que realicen más de 100 peticiones en 5 minutos a endpoints del tipo `/api/auth/login`.
*   **Filtros de Inspección Común (CRS)**: Habilitar conjuntos de reglas administradas (Common Rule Sets) para inspección de SQLi, XSS y escaneo automatizado.

---

## 5. Servidor Web Nginx — Cabeceras y Fingerprinting
**Vectores Asociados**: QD-10 (Information leak).

**Regla de Oro**: Configurar el servidor web o Ingress Controller para eliminar cualquier firma de software y forzar cabeceras HTTP de seguridad obligatorias.

### Parámetros Esenciales para Nginx (`nginx.conf`):

```nginx
# 1. Desactivar la exposición de la versión de Nginx en cabeceras y páginas de error
server_tokens off;

# 2. Remover cabeceras de compilación de lenguajes
more_clear_headers 'X-Powered-By';
more_clear_headers 'Server';

# 3. Cabeceras de Seguridad Obligatorias
add_header Strict-Transport-Security  "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options            "DENY" always;
add_header X-Content-Type-Options     "nosniff" always;
add_header Referrer-Policy            "strict-origin-when-cross-origin" always;
add_header Permissions-Policy         "geolocation=(), microphone=(), camera=()" always;
add_header Content-Security-Policy    "default-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;
```
