---
name: laravel-form-requests
description: >
  Especialista en la capa de validación y autorización de Laravel 11. Genera
  FormRequests con autorización multinivel (RBAC + IDOR) usando los traits
  centralizados AuthorizesClientRequests/AuthorizesSupportRequests, habilidades
  especiales de submódulo (abilities), reglas de validación estrictas con scope
  multitenant, mensajes en español y validaciones complejas vía withValidator().
  Diferencia los patrones de autorización entre Portal Cliente y Portal
  Soporte/Admin. Activar al crear endpoints, modificar reglas de validación,
  auditar contratos API o refactorizar Requests existentes.
---

# 🛡️ Laravel FormRequests (Capa de Validación)

Tu responsabilidad es ser el **guardián de la entrada**. Ningún dato llega al Service sin pasar por tu validación y autorización. No posees lógica de negocio ni interactúas con servicios externos.

## 🔐 Método `authorize()`: Autorización Multinivel

> [!IMPORTANT]
> **FormRequests NUEVOS: usa siempre los traits de `app/Traits/`.** No copies el `switch/case` de `$user->role` de un FormRequest viejo. Los ~150 Requests de Cliente y ~43 de Soporte que aún lo duplican **no fueron migrados a propósito** (deuda consciente, ago-2026) — son referencia histórica, no el estándar a replicar.

| Caso | Trait | Llamada |
|:---|:---|:---|
| Operación CRUD sobre un submódulo (Cliente) | `AuthorizesClientRequests` | `$this->authorizeSubmodule($companyId, 'SUBMODULO', UserOperationSubmodule::CREATE)` |
| Habilidad especial / no-CRUD (Cliente) | `AuthorizesClientRequests` | `$this->authorizeSubmodule($companyId, 'SUBMODULO', UserOperationSubmodule::CREATE, 'CODIGO_ABILITY')` |
| Solo pertenencia de empresa, sin submódulo | `AuthorizesClientRequests` | `$this->authorizeCompany($companyId)` |
| Endpoint de Soporte/Admin | `AuthorizesSupportRequests` | `$this->authorizeAdmin()` |
| Endpoint exclusivo para dueño (Suscriptor) | `AuthorizesSubscriberRequests` | `$this->authorizeSubscriber()` |
| Catálogo compartido entre módulos (solo lectura) | — | Reutiliza `App\Http\Requests\CompanyAccessRequest`, no crees un Request nuevo |

Detalle y plantillas completas:
- **Portal de Clientes** → `assets/authorize-client.md`
- **Portal de Soporte/Admin** → `assets/authorize-support.md`
- **Gestión Suscriptor** → Usa directamente `$this->authorizeSubscriber()`

> [!IMPORTANT]
> Nunca mezcles las lógicas de autorización de ambos portales en un mismo FormRequest. Los traits están separados justamente para que esa mezcla sea visible en el `use` del archivo.

### Reglas duras de autorización

1. **Nada de `Gate::define()`/`Gate::check()`.** Este proyecto no los usa en ningún FormRequest real. La autorización siempre es un método del modelo `User`, invocado por un trait. No introduzcas Gates aunque alguna referencia externa los sugiera.
2. **Fail-closed obligatorio.** Todo `match($user->role)` lleva `default => false`. Un rol no contemplado (`ADMIN_ROLE` llegando a un endpoint de Cliente) debe quedar **denegado**, nunca autorizado por omisión. Es el vector QD-04 (BFLA).
3. **`authorizeSupportStaff()` es la excepción, no la regla.** Solo 1 de 43 FormRequests reales de Soporte acepta `SUPPORT_ROLE`. Por defecto se usa `authorizeAdmin()`.
4. **`transaction` es el permiso de empresa por defecto**, no `show`. `SHOW`/`UPDATE` quedan reservados a la ficha de empresa (`/general/company`).

### Validación de Propiedad (EDIT/DELETE — Anti-IDOR)

En operaciones de edición o eliminación, el `withValidator()` DEBE validar que el recurso a manipular pertenezca a la `company_id` de la ruta. El trait autoriza el *tipo* de operación; el `withValidator()` autoriza el *recurso concreto*. Ambas capas son obligatorias — omitir la segunda abre IDOR (QD-05).

## ✅ Método `rules()`: Validación Estricta

1. **Foreign Keys**: Siempre `'exists:tabla,id'`. Ojo con los nombres reales: la tabla de empresas es **`core_companies`**, no `companies`.
2. **Unicidad Multitenant**: `Rule::unique('table')->where('company_id', $this->route('company_id'))`.
3. **Enums**: Validar con `Rule::in(EnumClass::values())`.
4. **Archivos S3**: `'nullable|file|mimes:pdf,png,jpg|max:10240'`.

## 💬 Método `messages()`: Obligatorio y Opaco ante Atacantes

- **Inclusión obligatoria:** Si el FormRequest define reglas en `rules()` (es decir, recibe parámetros o body), DEBE incluir la función `messages()`.
- **Textos en español:** Todo mensaje debe ser claro para el usuario final. Formato: `'campo.regla' => 'Mensaje descriptivo.'`
- **Cero fugas de información (Opacidad):** Los textos NO deben dar indicios de restricciones técnicas, estructurales o sensibles. No reveles límites exactos.
  - ❌ Incorrecto: *"El nombre del rol no puede superar los 255 caracteres."* (Revela el límite exacto de la base de datos).
  - ✅ Correcto: *"El nombre del rol excede el largo permitido."*
  - ❌ Incorrecto: *"El RUT debe coincidir con el formato XX.XXX.XXX-X."*
  - ✅ Correcto: *"El RUT ingresado no tiene un formato válido."*

## 🔧 Método `withValidator()`: Reglas Complejas

Úsalo para validaciones que dependan de múltiples campos, estados de BD o lógica condicional:
- Validar prefijos jerárquicos (ej: código hijo comienza con código padre).
- Validar exclusividad mutua entre campos.
- Validar propiedad IDOR del recurso contra `company_id`.

## 📝 Plantillas de Código

| Patrón | Asset |
|:---|:---|
| FormRequest completo | `assets/form-request-pattern.md` |
| Autorización Cliente (traits + abilities) | `assets/authorize-client.md` |
| Autorización Soporte/Admin | `assets/authorize-support.md` |

## ⚠️ Gotcha de PHP: enums como valor por defecto

Un enum backed **no puede usarse con `->value` como default de un parámetro** — es un error fatal (`Constant expression contains invalid operations`), incluso en PHP 8.2/8.3, porque `->value` no es expresión constante:

```php
// ❌ Fatal error
function f(string $ability = CompanyPermissionAbility::TRANSACTION->value) {}

// ✅ Tipar con el enum y extraer ->value dentro
function f(CompanyPermissionAbility $ability = CompanyPermissionAbility::TRANSACTION) {
    $valor = $ability->value;
}
```

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Tenga `authorize()` que retorne `true` sin validación.
- Duplique el `switch/case` de `$user->role` en un FormRequest **nuevo** en vez de usar los traits.
- Use un `if`/`match` de roles **sin rama `default`/`else` que deniegue** (fail-open).
- Invente métodos inexistentes en `User` — solo existen los documentados en `assets/authorize-client.md`. **`hasPermission()` no existe.**
- Use `Gate::define()`/`Gate::check()`.
- No filtre unicidades por `company_id`.
- Contenga mensajes de validación en inglés.
- Invoque Services o realice operaciones de persistencia.
- Mezcle lógica de autorización de Cliente con Soporte/Admin.
