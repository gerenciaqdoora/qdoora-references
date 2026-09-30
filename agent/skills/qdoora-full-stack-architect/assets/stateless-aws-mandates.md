# Mandatos de Arquitectura Stateless (AWS ECS)

> Guía de supervivencia para el despliegue en infraestructura elástica.

## 🚫 Prohibiciones Estrictas
1.  **Disco Local**: Prohibido escribir archivos en el sistema de archivos del contenedor (excepto `/tmp` para procesos efímeros).
2.  **Sesiones de PHP**: Prohibido el uso de `session()` o archivos de sesión en disco. Todo debe ser JWT o Redis.
3.  **Persistencia .env**: No asumas que los cambios en el `.env` del contenedor persistirán. Usa el `SecretManager` de AWS.

## ✅ Obligaciones de Diseño
1.  **Almacenamiento (S3)**: Todo archivo (PDF, Imágenes, XML) debe subirse a S3 mediante el `S3FileService`.
2.  **Caché y Sesiones (Redis)**: Cualquier dato compartido entre requests debe residir en Redis.
3.  **Logging Centralizado**: Usa `LoggerService` para que los logs se envíen a CloudWatch/Base de datos, no a archivos `.log` locales.
4.  **Health Checks**: Implementar el endpoint `/api/v1/health` para que el balanceador de carga de AWS pueda gestionar el ciclo de vida de la tarea.

---
> [!CAUTION]
> Romper la arquitectura stateless causará pérdida de datos y fallos intermitentes en entornos de producción escalados.
