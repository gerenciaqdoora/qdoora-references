---
name: qdoora-laravel-controllers
description: >
  Especialista en la capa de Controladores de Laravel 11. Genera controladores
  delgados que orquestan vía try-catch, inyectan Services y LoggerService,
  implementan el trait HandlesControllerLogs y retornan respuestas JSON estándar.
  Prohibición absoluta de lógica de negocio o queries directas. Activar cuando
  el usuario cree un nuevo endpoint, refactorice un controlador existente o pida
  generar la capa HTTP de un módulo.
---

# 🎛️ Laravel Controllers (Capa HTTP)

Tu responsabilidad es generar controladores que sean **estrictamente orquestadores**. No posees lógica de negocio, no consultas la base de datos y no validas datos.

## ⚙️ Anatomía Obligatoria de un Método

```
try {
    1. LoggerService → registrar la operación (Enum de operación + evento)
    2. Service → delegar la lógica completa
    3. return response()->json() con estructura estándar
} catch (\Exception $e) {
    4. $this->handleError->logAndResponse($e, $request, LoggerOperation::..., LoggerEvent::..., "Mensaje")
}
```

## 🏗️ Reglas Inquebrantables

1. **Inyección por Constructor**: Todos los `Service`, `LoggerService` y `HandlesControllerLogs` se inyectan en el `__construct()` y sus propiedades deben estar **fuertemente tipadas** (ej. `protected LoggerService $loggerService;`).
2. **Clase `HandlesControllerLogs`**: Obligatorio inyectarla en cada controlador. Es la que provee `$this->handleError->logAndResponse($e, $request, ...)`.
3. **Tipado de Retorno**: Todo método público retorna `JsonResponse`.
4. **FormRequest**: Todo endpoint recibe un `FormRequest` tipado, nunca `Request $request` genérico.
5. **Cero Queries**: Si necesitas un `where()`, `find()` o `create()`, pertenece al Service.
6. **Respuesta Estándar**:
   ```json
   { "success": true, "message": "...", "data": {} }
   ```
   - `201` para creaciones, `200` para lecturas/actualizaciones, `204` para eliminaciones.
7. **Resources**: Para respuestas complejas, envolver `$data` en un `JsonResource` o `ResourceCollection`.

## 📝 Plantilla de Código

Usa siempre el asset `assets/controller-pattern.md` como base para generar un controlador nuevo.

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Contenga `Model::where()`, `DB::table()` o `->save()` dentro del controlador.
- No use `HandlesControllerLogs` ni `LoggerService`.
- Retorne vistas Blade o respuestas que no sean JSON.
- Use `Request` genérico en lugar de un `FormRequest` dedicado.
- Retorne modelos Eloquent crudos sin pasar por un `Resource`.
