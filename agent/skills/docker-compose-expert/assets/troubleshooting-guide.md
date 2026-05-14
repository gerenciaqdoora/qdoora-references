# Guía de Diagnóstico Docker (QdoorA)

Resolución de problemas comunes en el entorno de desarrollo y QA.

### 1. Variables de Entorno no Detectadas
**Síntoma**: La API devuelve errores de conexión a DB o `null` en variables críticas.
- **Causa**: El contenedor no montó el `.env` o la caché de configuración está desactualizada.
- **Solución**:
  1. Verificar volumen en `docker-compose.yml`: `- "./.env:/var/www/html/.env"`.
  2. Ejecutar `php artisan config:clear` dentro del contenedor.
  3. Verificar `env_file` en la definición del servicio.

### 2. Fallos de Networking entre Servicios
**Síntoma**: Un frontend no puede conectar con `qdoora-api` dentro de la red Docker.
- **Causa**: El servicio no está en la misma red `sail` o el nombre del host es incorrecto.
- **Solución**:
  - Asegurar que ambos tengan `networks: - sail`.
  - Usar el nombre del servicio (`http://qdoora-api`) en lugar de `localhost`.

### 3. Errores de Permisos en Volúmenes
**Síntoma**: "Permission denied" al escribir en `storage/` o `bootstrap/cache`.
- **Causa**: Desajuste de UID entre el host y el contenedor.
- **Solución**:
  - Usar la variable `WWWUSER` y `WWWGROUP` en el `docker-compose.yml`.
  - Ejecutar `chown -R sail:sail storage` si es necesario (asumiendo usuario sail en la imagen).

### 4. Hot-Reload no Funciona (Angular)
**Síntoma**: Cambias el código pero el navegador no se refresca.
- **Causa**: El sistema de archivos del contenedor no detecta eventos del host (común en Docker Desktop).
- **Solución**:
  - En el script de inicio de Angular, usar el flag `--poll 2000`.
  - Ejemplo: `ng serve --host 0.0.0.0 --poll 2000`.
