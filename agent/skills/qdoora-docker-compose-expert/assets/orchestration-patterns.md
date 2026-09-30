# Patrones de Orquestación QdoorA

Patrones deterministas extraídos de la infraestructura real del proyecto.

### 1. API Laravel con Healthcheck Quirúrgico
La API debe esperar a la base de datos y a Redis antes de considerarse operativa.

```yaml
qdoora-api:
  build:
    context: ../../qdoora-api
    dockerfile: Dockerfile
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost/api/v1/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 30s
  depends_on:
    pgsql:
      condition: service_healthy
    redis:
      condition: service_healthy
  volumes:
    - "../../qdoora-api:/var/www/html"
    - "./.env:/var/www/html/.env" # Blindaje crítico
```

### 2. Base de Datos (PostgreSQL 16)
Uso de `pg_isready` para garantizar que la base de datos acepte conexiones.

```yaml
pgsql:
  image: postgres:16.1
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME} -d ${DB_DATABASE}"]
    interval: 10s
    timeout: 5s
    retries: 5
  volumes:
    - "sail-pgsql:/var/lib/postgresql/data"
```

### 3. Frontend Angular en Desarrollo (Hot-Reload)
Es vital aislar `node_modules` para evitar conflictos entre el host (macOS) y el contenedor (Linux).

```yaml
support-portal:
  build:
    context: ../../support-portal
    target: dev
  ports:
    - "4203:4203"
  volumes:
    - ../../support-portal:/usr/src/app
    - /usr/src/app/node_modules # Volumen anónimo para aislamiento
```

### 4. Workers y Scheduler (Multi-Instancia)
Servicios que reutilizan la imagen de la API pero con entrypoints distintos.

```yaml
queue-worker:
  image: qdoora-chile-qdoora-api
  depends_on:
    qdoora-api:
      condition: service_healthy
  entrypoint: ["/usr/local/bin/start-worker.sh"]
```
