---
name: qdoora-laravel-services
description: >
  Especialista en la capa de Servicios de Laravel 11. Implementa toda la lógica
  de negocio del ERP siguiendo Service Ownership, transacciones atómicas con
  DB::transaction(), excepciones controladas (sin findOrFail), Eager Loading
  preventivo y nomenclatura estándar. Activar al crear lógica de negocio nueva,
  refactorizar lógica que esté en controladores o coordinar operaciones entre
  múltiples dominios.
---

# ⚙️ Laravel Services (Capa de Negocio)

Tu responsabilidad es contener **toda la lógica de negocio** del ERP. Eres el dueño exclusivo de tu dominio y ningún otro componente (Controller, Request, Seeder) puede manipular tus modelos directamente.

## 🏗️ Principios de Operación

### 1. Service Ownership (Propiedad del Dominio)

- Cada servicio es dueño de su modelo/tabla.
- Si necesitas afectar otro dominio, **inyecta su servicio** en tu constructor.
- Prohibido: `OtherModel::create(...)` desde tu servicio. Correcto: `$this->otherService->create(...)`.

### 2. Nomenclatura Estándar

| Operación | Prefijo del método |
|:---|:---|
| Listados | `get...List()` |
| Búsqueda unitaria | `find...()` o `get...ById()` |
| Creación | `create...()` o `store...()` |
| Actualización | `update...()` |
| Eliminación | `delete...()` o `destroy...()` |

### 3. Transacciones Atómicas

```php
return DB::transaction(function () use ($data) {
    $model = Model::create($data);
    $this->otherService->performAction($model->id);
    return $model;
});
```

- **Obligatorio** si la operación afecta más de una tabla.
- El `return` dentro del closure garantiza que el controlador reciba el resultado.

### 4. Excepciones Controladas (Anti-findOrFail)

```php
$model = Model::find($id);
if (!$model) {
    throw new GenericException('El recurso solicitado no existe o no está disponible.');
}
```

- Mensajes en **español**, descriptivos para el usuario final.
- Excepciones custom en `app/Exceptions`:
  - `GenericException` (400) → errores de negocio genéricos.
  - `NotFound404Exception` (404) → recurso no encontrado.
  - `AuthException` (401/403) → fallos de autenticación/autorización.
  - `ParameterCloningException` → fallo específico de clonación de períodos.

### 5. Optimización de Consultas

- **Eager Loading** preventivo: `->with(['relation'])` para evitar N+1.
- **Filtros dinámicos**: `->when($filter, fn($q) => ...)` para consultas condicionales.
- **Selección de columnas**: `->select([...])` cuando no necesitas el modelo completo.

### 6. Comunicaciones (MailerSend)

Los correos de alta prioridad usan plantillas premium. El patrón se encuentra en `assets/mailersend-pattern.md`.

## 📝 Plantillas de Código

| Patrón | Asset |
|:---|:---|
| Servicio estándar | `assets/service-pattern.md` |
| Correo premium (MailerSend) | `assets/mailersend-pattern.md` |

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Coloque lógica de negocio en un Controller o FormRequest.
- Use `findOrFail()` en lugar de `find()` + excepción controlada.
- No envuelva operaciones multi-tabla en `DB::transaction()`.
- Manipule modelos de otro dominio sin usar su servicio inyectado.
- Tenga consultas sin Eager Loading que generen N+1 detectables.
