---
name: laravel-form-requests
description: >
  Especialista en la capa de validación y autorización de Laravel 11. Genera
  FormRequests con autorización multinivel (RBAC + IDOR), reglas de validación
  estrictas con scope multitenant, mensajes en español y validaciones complejas
  vía withValidator(). Diferencia los patrones de autorización entre Portal
  Cliente y Portal Soporte/Admin. Activar al crear endpoints, modificar reglas
  de validación, auditar contratos API o refactorizar Requests existentes.
---

# 🛡️ Laravel FormRequests (Capa de Validación)

Tu responsabilidad es ser el **guardián de la entrada**. Ningún dato llega al Service sin pasar por tu validación y autorización. No posees lógica de negocio ni interactúas con servicios externos.

## 🔐 Método `authorize()`: Autorización Multinivel

Antes de generar el código, identifica el portal:

- **Portal de Clientes** → Usa el patrón de `assets/authorize-client.md`
  - `SUBSCRIBER_ROLE`: Valida propiedad de la empresa (`company_id ↔ suscriptor_id`).
  - `USER_ROLE`: Valida permisos de submódulo + pertenencia a empresa.
- **Portal de Soporte/Admin** → Usa el patrón de `assets/authorize-support.md`
  - Discrimina entre endpoints exclusivos `ADMIN_ROLE` y compartidos `SUPPORT_ROLE`.

> [!IMPORTANT]
> Nunca mezcles las lógicas de autorización de ambos portales en un mismo FormRequest.

### Validación de Propiedad (EDIT/DELETE — Anti-IDOR)

En operaciones de edición o eliminación, el `withValidator()` DEBE validar que el recurso a manipular pertenezca a la `company_id` de la ruta. Esto bloquea vectores IDOR (QD-05).

## ✅ Método `rules()`: Validación Estricta

1. **Foreign Keys**: Siempre `'exists:table,id'`.
2. **Unicidad Multitenant**: `Rule::unique('table')->where('company_id', $this->route('company_id'))`.
3. **Enums**: Validar con `Rule::in(EnumClass::values())`.
4. **Archivos S3**: `'nullable|file|mimes:pdf,png,jpg|max:10240'`.

## 💬 Método `messages()`: Español Obligatorio

- Todo mensaje en **español**, claro y descriptivo para el usuario final.
- Formato: `'campo.regla' => 'Mensaje descriptivo.'`

## 🔧 Método `withValidator()`: Reglas Complejas

Úsalo para validaciones que dependan de múltiples campos, estados de BD o lógica condicional:
- Validar prefijos jerárquicos (ej: código hijo comienza con código padre).
- Validar exclusividad mutua entre campos.
- Validar propiedad IDOR del recurso contra `company_id`.

## 📝 Plantillas de Código

| Patrón | Asset |
|:---|:---|
| FormRequest completo | `assets/form-request-pattern.md` |
| Autorización Cliente | `assets/authorize-client.md` |
| Autorización Soporte | `assets/authorize-support.md` |

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Tenga `authorize()` que retorne `true` sin validación.
- No filtre unicidades por `company_id`.
- Contenga mensajes de validación en inglés.
- Invoque Services o realice operaciones de persistencia.
- Mezcle lógica de autorización de Cliente con Soporte/Admin.
