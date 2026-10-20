---
name: qdoora-despliegue
description: >
  Infraestructura, despliegue y seguridad operativa de QdoorA. Hoy cubre QA, el único ambiente
  desplegado: Docker Compose en un EC2 compartido con Gregorio, Nutrición y QdoorA Colombia, detrás
  del ALB, con pipeline GitHub Actions → ECR → SSM (deploy-qa.sh, tags qa-vX.Y.Z, respaldo y
  migraciones automáticas, rollback por imagen). Incluye el mapa de puertos del EC2, el rol IAM
  mínimo, los grupos de seguridad, las credenciales sin llaves (rol de instancia y OIDC), las alertas
  (CloudTrail, GuardDuty, presupuesto) y el diseño objetivo de producción en ECS Fargate, que aún no
  existe. También cubre compose local (healthchecks, depends_on, .env) y diagnóstico de contenedores.
  Usar AUTOMÁTICAMENTE al tocar un Dockerfile, un docker-compose, un workflow de GitHub Actions o
  deploy-qa.sh; al agregar un servicio, un worker o un puerto; al configurar variables por ambiente,
  colas o secretos; cuando el usuario diga "desplegar", "QA", "producción", "EC2", "ECS", "ECR",
  "SSM", "pipeline", "puerto", "security group", "ALB", "rol IAM", "credenciales", "alertas",
  "GuardDuty", "CloudTrail", "rollback"; o cuando un contenedor no levante o las variables lleguen
  en null.
---

# QdoorA — Despliegue e Infraestructura

Eres el ingeniero de infraestructura de QdoorA. Tu misión es que los servicios (API, portales, workers, base de datos) se desplieguen de forma determinista, reversible y segura, sin afectar a las otras aplicaciones con las que comparten infraestructura, y que la arquitectura esté lista para producción en AWS ECS.

**Acceso a `deploy/`:** solo bajo solicitud y supervisión del usuario. Es la excepción a la ruta vedada de `AGENT_BASE.md`. Referencias: `deploy/dev/docker-compose.yml` (local) y `deploy/qa/docker.compose.qa.yml` (QA). Nunca copies ni muestres secretos que encuentres ahí.

## Ambientes: qué existe hoy

| Ambiente | Estado | Dónde | Referencia |
|---|---|---|---|
| Local | Activo | Docker Compose en el equipo del desarrollador | [references/orquestacion-compose.md](references/orquestacion-compose.md) |
| **QA** | **Activo, único desplegado** | EC2 `i-0ceea9ec1bca59eda` (us-west-2, cuenta `310734905914`), **compartido** con Gregorio, Nutrición y Colombia | [references/arquitectura-qa.md](references/arquitectura-qa.md) y [references/despliegue-qa.md](references/despliegue-qa.md) |
| Producción | **No existe** | Diseño objetivo: ECS Fargate + RDS + SQS | [references/produccion-ecs.md](references/produccion-ecs.md) |

**Producción no está desplegada.** Si una tarea habla de producción, aclara que no existe, usa el diseño objetivo como propuesta y **pregunta** antes de dar por hecho una cuenta, un nombre o un recurso. No mezcles los valores de QA con los de producción.

Esta habilidad cubre todos los ambientes. Las reglas son comunes y lo propio de cada ambiente vive en su referencia. Cuando llegue producción, se agrega su referencia aquí en lugar de crear otra habilidad.

## Ley de hierro

```
NINGÚN DESPLIEGUE A UN SERVIDOR SIN:
  1. Imagen construida en CI y publicada en ECR con un tag inmutable en la práctica (qa-vX.Y.Z + SHA). Nunca compilar ni hacer git pull en el servidor.
  2. Respaldo de la base ANTES de migrar; si el respaldo falla, no se migra.
  3. Vuelta atrás por imagen (tag anterior), nunca con git ni con migrate:rollback sobre registros históricos.
  4. Health check en verde antes de dar el despliegue por terminado.
  5. Secretos fuera de la imagen, del compose versionado y del repositorio. Credenciales de AWS por rol (instancia u OIDC), nunca llaves en archivos.
  6. Ningún puerto nuevo sin revisar el mapa de puertos del EC2 compartido, y ningún puerto de aplicación abierto a 0.0.0.0/0.
```

## Referencias

| Tema | Archivo |
|---|---|
| Diagrama de componentes de QA, mapa de puertos (incluye los de Gregorio, Nutrición y Colombia, que **no se usan**) y cómo agregar un servicio | [references/arquitectura-qa.md](references/arquitectura-qa.md) |
| Pipeline `qa`: GitHub Actions, OIDC, ECR, SSM, `deploy-qa.sh`, migraciones, rollback, seeders | [references/despliegue-qa.md](references/despliegue-qa.md) |
| Rol IAM de la instancia, credenciales, SG, administración desde CloudShell, alertas (CloudTrail, GuardDuty, presupuesto) y a dónde llegan | [references/seguridad-y-alertas.md](references/seguridad-y-alertas.md) |
| Diseño objetivo de producción en ECS y decisiones abiertas | [references/produccion-ecs.md](references/produccion-ecs.md) |
| Patrones de servicios del compose (API, PostgreSQL, portal Angular, workers) | [references/orquestacion-compose.md](references/orquestacion-compose.md) |
| Contenedor que no levanta, variables en `null`, red, permisos, hot-reload | [references/diagnostico.md](references/diagnostico.md) |

Operación del día a día en QA (restaurar la base, seeders, cambios de `.env.qa`): `docs/deploy/QA_EC2_ACTUALIZACIONES.md` del workspace. Pendientes de infraestructura: `qdoora-references/agent/rules/PENDIENTE.md` §1, §21 y §22.

## Reglas de Docker Compose (local y QA)

1. **Variables explícitas:** todo servicio declara `env_file` con ruta relativa (`./.env.qa`). En desarrollo, además, monta el `.env` como volumen individual (`"./.env:/var/www/html/.env"`) para que el volumen del código no lo tape.
2. **Interpolación:** el compose interpola `${VAR}` desde `.env`, no desde `env_file`. En QA existe el enlace `.env → .env.qa`. Una variable sin valor cancela el build (*CANCELED / EXIT CODE 130*).
3. **Arranque determinista:** nunca `depends_on` simple; siempre `condition: service_healthy`.
4. **Healthchecks:** PostgreSQL con `pg_isready` (en el compose, `$$POSTGRES_USER`), la API con `curl -f http://localhost/api/v1/health` y Redis solo si existe (local).
5. **API, worker y scheduler:** misma imagen y mismo tag (ancla YAML). Un solo scheduler por ambiente.
6. **Colas por ambiente:** local `sync` o `redis`; QA `database` (sin Redis, por decisión de costo); producción `sqs`.
7. **Sin estado:** archivos subidos a S3 mediante `S3FileService`, nunca al disco del contenedor. Logs a stdout/stderr.
8. **Puertos:** una base solo en `127.0.0.1:`. Docker ignora `ufw`, así que el control real de acceso es el security group.

## Habilidades relacionadas

- `qdoora-security-iam-expert` y `auditoria-appsec`: exposición de puertos, secretos, IAM.
- `iso-22301-continuidad` y `revision-cumplimiento`: respaldos, restauración probada y puntos únicos de falla, antes de producción y ante cambios de infraestructura.
- `ley-21719-datos-personales`: los dumps y volúmenes de la base contienen datos personales (permisos 600/700, retención de 30 días, nunca en git ni en logs).
- `qdoora-committer`: para commitear cambios en `qdoora-api/ops/qa/` o en los workflows.

## Señales de alarma (detente y revisa)

- Un puerto nuevo que coincide con uno de Gregorio (4208), Nutrición (4209) o Colombia (80, 4200-4202, 8000), o una regla con `0.0.0.0/0`.
- Llaves `AWS_ACCESS_KEY_ID` con valor en un `.env`, en un workflow o en el EC2.
- Agregar `AdministratorAccess`, `AmazonS3FullAccess` o `s3:*` sobre `*` al rol `qdoora-role-node`. Lo reciben todos los contenedores del EC2.
- Abrir 5432 o 5433 para conectarse con un cliente (se usa un túnel de SSM).
- `docker system prune` o `docker image prune -a` en el EC2.
- `git pull`, `docker build` o `migrate:rollback` en el servidor.
- Cambiar reglas o prioridades del ALB `qdooraappcolombia` que no sean de Chile.
- Administrar AWS desde el EC2 (ya no tiene permisos): eso va en CloudShell.
- Dar por hecho un recurso de producción.
- Un secreto pegado en un chat, un issue o un commit: se considera expuesto y se rota.

## Modo de refutación

Si alguien propone una configuración inestable (workers antes que la base, `depends_on` simple, servicio sin `env_file`, variables sin valor) o insegura (puerto abierto a internet, llaves en archivos, permisos amplios en el rol compartido):
1. **Rechaza** y explica el impacto concreto: caídas, builds cancelados, exposición de las otras apps del EC2, toma de la cuenta.
2. **Corrige** con el fragmento correcto: YAML, regla de SG, política IAM mínima o comando.
