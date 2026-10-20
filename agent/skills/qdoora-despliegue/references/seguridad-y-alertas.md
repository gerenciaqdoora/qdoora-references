# Seguridad, accesos y alertas

Estado al 2026-10-20, después del endurecimiento del EC2 compartido. Lo que queda abierto está en `qdoora-references/agent/rules/PENDIENTE.md`, §21 (rotación de secretos) y §22 (cierre del endurecimiento).

## Dónde llegan las alertas

```mermaid
flowchart LR
  subgraph Registro
    CT[CloudTrail qdoora-trail<br/>multirregión, validación de integridad] --> B[(S3 qdoora-cloudtrail-310734905914<br/>privado, expira a los 365 días)]
  end
  subgraph Detección
    GD[GuardDuty<br/>detector 76d0accd7dc78fbe29b291cd35fe7ce3] -->|hallazgo severidad ≥ 4| EB[EventBridge<br/>regla guardduty-a-correo]
    EB --> SNS[SNS qdoora-alertas-seguridad]
  end
  BUD[AWS Budgets 'mensual'<br/>USD 200, aviso al 80% = USD 160] --> M
  SNS --> M[francoalvaradot@gmail.com]
  ECR[ECR scanOnPush<br/>7 repositorios] --> C[Consola ECR<br/>vulnerabilidades por imagen<br/>sin aviso por correo]
```

| Señal | Qué detecta | Dónde se ve |
|---|---|---|
| CloudTrail `qdoora-trail` | Toda llamada a la API de AWS (quién, qué y desde dónde) en todas las regiones | Bucket `qdoora-cloudtrail-310734905914` (365 días). Los últimos 90 días también en CloudTrail → Event history |
| GuardDuty | Credenciales usadas desde fuera, minería, escaneos de puertos, accesos anómalos | Correo a `francoalvaradot@gmail.com` (severidad ≥ 4) y consola de GuardDuty (todos) |
| AWS Budgets `mensual` | Gasto sobre USD 160 (80% de USD 200). Un gasto anómalo suele ser la primera señal de una cuenta comprometida | Correo a `francoalvaradot@gmail.com` |
| ECR `scanOnPush` | CVE en las imágenes nuevas | Consola de ECR. **No envía correo**: revisar en cada versión importante |

- Los hallazgos `[SAMPLE]` en GuardDuty son de prueba y se pueden archivar.
- La prueba gratis de GuardDuty termina alrededor del 2026-11-19: revisa el costo estimado en su consola.

## Quién administra y desde dónde

| Tarea | Desde | Identidad |
|---|---|---|
| IAM, SG, ALB, Route 53, GuardDuty, presupuesto | **CloudShell** (consola, us-west-2) | Root con MFA (pendiente: crear un usuario administrador con MFA) |
| Comandos dentro del EC2 | Consola → Connect → EC2 Instance Connect o Session Manager | `ubuntu` (Session Manager entra como `ssm-user`: `sudo su - ubuntu`) |
| Build y push manual | Equipo del desarrollador | IAM `codecommit-franco` (solo ECR) con `AWS_PROFILE=qdoora-chile` |
| Despliegue automático | GitHub Actions | Rol OIDC `github-qdoora-chile-qa-deploy` |

**El EC2 ya no administra la cuenta.** Su rol no tiene permisos de IAM ni de EC2: un comando de administración desde el EC2 responde `AccessDenied`.

CloudShell tiene dos trampas:
- Pega los comandos de a uno y sin variables: la primera línea de un pegado múltiple se puede perder.
- Pon entre comillas simples todo texto que tenga `!`.

## Rol de la instancia `qdoora-role-node`

| Política | Para qué | Quién la usa |
|---|---|---|
| `AmazonSSMManagedInstanceCore` | Agente SSM: Run Command (pipeline) y Session Manager | Sistema |
| `AmazonEC2ContainerRegistryReadOnly` | Pull de imágenes | `deploy-qa.sh`, Gregorio, Nutrición |
| `QdooraQAS3Policy` | Bucket `qdoora-chile-qa` y `GetSecretValue` sobre `qdoora/chile/qa/api*` | Chile QA |
| `S3AccessLaravelApi` | Bucket `faat-iozean-contabilidad-develop` | Colombia (`/var/www/html/qdoora-server`) |

- **Todos los contenedores del EC2 comparten este rol**, porque IMDS tiene hop limit 2. Cada permiso que agregues lo reciben también Gregorio, Nutrición y Colombia. Por eso solo se permiten buckets y secretos con nombre propio, nunca `s3:*` sobre `*`, y nunca `AdministratorAccess`.
- **Buckets que NO van en el rol:** `qdoora-latam-disk` (desarrollo, con credenciales propias de cada desarrollador) y `co-qdoora-production-disk` (producción de Colombia, hoy detenida; al volver, con una política propia). `gregorio-disk` se agrega con `GregorioS3Policy` solo cuando `agente-gregorio` entre en funcionamiento.
- El secreto usa la llave KMS por defecto (`aws/secretsmanager`), así que no hace falta `kms:Decrypt`.
- **Para saber qué usa el rol:** `aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=i-0ceea9ec1bca59eda`. Access Advisor llega con horas de retraso, y las lecturas de S3 no aparecen en ninguno de los dos.

## Credenciales: reglas

1. **Nunca llaves de AWS en un EC2, un `.env`, un repositorio ni un chat.** En el EC2, el rol de la instancia; en GitHub, OIDC.
2. **Un secreto que apareció en git o en un chat se considera expuesto**: se rota, no basta con borrarlo del historial.
3. **Para saber si un valor actual quedó expuesto sin mostrarlo**, compara su SHA-256 con el de los valores del historial (método documentado en PENDIENTE §21).
4. **Usuarios IAM vigentes:**
   - `codecommit-franco`: solo ECR, llave …24KY. La …RBOX se borra hacia el 2026-10-27.
   - `qdoora-chile-dev`: S3 de desarrollo.

   `qdoora-chile-qa` fue eliminado.
5. **Rotación cada 60 días** de los secretos de QA (salvo `APP_KEY`), según PENDIENTE §21.

## Red

- **Ningún puerto de aplicación abierto a `0.0.0.0/0`.** Solo se acepta tráfico desde el SG del ALB (`sg-0480b37b4e6611eca`). El mapa completo está en `arquitectura-qa.md`.
- **SSH solo desde EC2 Instance Connect** (`18.237.140.160/29`), con `PermitRootLogin no`.
- **Las bases de datos nunca se publican:** el acceso desde fuera es por túnel de SSM.
- **Docker ignora `ufw`** con los puertos publicados (`ufw` está inactivo). El control real es el SG; para que un puerto no salga de la máquina, publícalo en `127.0.0.1:`.
- **Revocar una regla `0.0.0.0/0` corta al instante las conexiones abiertas**: AWS no las mantiene. Si es la regla de SSH, se corta tu sesión.

## Auditoría periódica

`qdoora-api/ops/security-inventory.sh` es un inventario de solo lectura que no imprime secretos. Se ejecuta en el EC2 con `sudo bash security-inventory.sh 2>&1 | tee ~/inventario.txt` y revisa:
- SG, ALB y puertos;
- contenedores y SSH;
- el rol y las llaves IAM con su último uso;
- Secrets Manager, ECR, CloudTrail y GuardDuty;
- archivos sensibles en disco.

Desde la Fase 4 hay que ejecutarlo desde CloudShell para las partes de IAM y EC2, porque el rol del EC2 ya no tiene esos permisos.
