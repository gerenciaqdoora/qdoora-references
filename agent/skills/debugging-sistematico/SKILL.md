---
name: debugging-sistematico
description: >
  Proceso de depuración en 4 fases (causa raíz → patrones → hipótesis → arreglo con test) para
  cualquier stack. USAR antes de proponer cualquier arreglo.
  Activar AUTOMÁTICAMENTE ante: bug reportado, test fallando, error 500 o respuesta inesperada de
  una API, excepción no controlada, comportamiento inesperado del frontend, consulta SQL incorrecta
  o lenta, migración fallida, contenedor que no levanta, o cuando el usuario diga "no funciona",
  "está fallando", "error en producción", "¿por qué hace esto?". Activar ESPECIALMENTE bajo presión
  de tiempo.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Depuración sistemática

**Ley de hierro:** `NINGÚN ARREGLO SIN INVESTIGAR LA CAUSA RAÍZ PRIMERO`

Los parches rápidos esconden el problema real. Si no completaste la fase 1, no puedes proponer código.

## Fase 1: Causa raíz

1. **Leer el error completo:** el stack trace entero, el archivo y la línea. Nada de saltarse líneas.
2. **Reproducir de forma determinista.** Si no se reproduce, reunir más datos antes de actuar.
3. **Revisar cambios recientes:** `git diff`, últimos commits, dependencias, variables de entorno,
   migraciones aplicadas.
4. **Instrumentar cada frontera** en sistemas de varias capas (UI → cliente HTTP → controlador →
   servicio → base de datos): registrar qué entra y qué sale en cada una hasta encontrar dónde se
   corrompe el valor. Nunca registrar secretos ni datos personales en claro.
5. **Trazar hacia atrás** desde el síntoma hasta el origen.

## Fase 2: Patrones

1. Buscar en el código algo equivalente que **sí funcione**.
2. Leerlo completo y listar **todas** las diferencias, aunque parezcan irrelevantes.
3. Revisar el contexto implícito: sesión y permisos, configuración por entorno, caché, zona
   horaria, orden de ejecución, estado de la base.

## Fase 3: Hipótesis

1. Escribir **una** hipótesis: "Creo que X es la causa porque Y".
2. Probarla con el **cambio mínimo**, una variable a la vez.
3. Si no se confirma, formular una nueva desde cero; no apilar cambios.
4. Si no entiendes algo, dilo: "Todavía no entiendo X".

## Fase 4: Arreglo

1. **Test que reproduce el bug y falla** (ver `desarrollo-guiado-por-pruebas`).
2. **Arreglo en el origen**, no en el síntoma. Un solo cambio.
3. **Verificar:** el test pasa, el resto de la suite sigue en verde y el comportamiento real es el esperado.
4. **Si el arreglo no funciona:**
   - 1.er intento fallido → volver a la fase 1 con la información nueva;
   - 2.º → cuestionar los supuestos;
   - 3.º o más → **cuestionar la arquitectura** y consultar al usuario antes de seguir parchando.

## Señales para detenerse y volver a la fase 1

| Pensamiento | Realidad |
|---|---|
| "Arreglo rápido y después investigo" | El después nunca llega |
| "Pruebo este cambio a ver qué pasa" | Probar al azar es más lento que investigar |
| "Cambio varias cosas a la vez" | No sabrás cuál funcionó y crearás bugs nuevos |
| "Es simple, no necesita proceso" | Lo simple también tiene causa raíz |
| "Un intento más" (tras 2 fallidos) | 3 fallos seguidos = problema de diseño |

## Guías por tipo de falla

- **Error 500 en una API:** log real del servidor → ¿falló la validación de entrada? → ¿qué filtro
  o manejador global interceptó la excepción? → ¿transacción abierta o conexión agotada? →
  ¿operación bloqueante en el event loop?
- **401/403 inesperado:** ¿llega la credencial (cookie, cabecera)? → ¿atributos de cookie
  (`SameSite`, `Secure`, dominio) y CORS con credenciales? → ¿el guard marca la ruta como pública o
  protegida? → ¿el rol o la regla por recurso es la esperada?
- **Frontend no muestra datos:** la red (estado, cuerpo) → el adaptador → el estado (signal,
  observable) → la plantilla. ¿Suscripción no disparada o detección de cambios?
- **Test que falla de forma intermitente:** orden de ejecución, estado compartido, reloj real,
  promesas sin esperar, datos que no se limpian entre tests.
- **Base de datos:** `EXPLAIN (ANALYZE, BUFFERS)`, restricciones violadas, migración parcial,
  diferencia entre el esquema y las entidades.

Si el perfil del proyecto documenta incidentes o trampas conocidas, revísalas en la fase 2.

> **Relacionadas:** `desarrollo-guiado-por-pruebas` (test del bug) · `auditoria-appsec` (si el bug tiene implicancias de
> seguridad) · `planificador` (si el arreglo requiere un cambio de diseño mayor)
