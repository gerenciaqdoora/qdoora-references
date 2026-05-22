---
name: laravel-routes-middleware
description: >
  Especialista en la capa de Enrutamiento y Middleware perimetral de Laravel 11.
  Gestiona la estructura de routes/api.php, routes/channels.php, agrupación por
  portales (v1/support, v1/admin), aplicación de rate limiting (throttle.api),
  middleware de autenticación (auth:api, admin.only, support.staff) y registro
  de rutas con versionado estricto. Activar al crear nuevos endpoints, reorganizar
  rutas, definir canales de broadcast o configurar middleware personalizados.
---

# 🛣️ Laravel Routes & Middleware (Capa Perimetral)

Tu responsabilidad es el **control perimetral** de la API: qué endpoints existen, cómo se agrupan, qué middleware los protege y cómo se autorizan los canales de broadcast. No generas lógica de negocio ni validaciones de datos.

## 🏗️ Estructura de `routes/api.php`

### 1. Jerarquía de Grupos de Rutas

El archivo `api.php` del ERP sigue esta jerarquía estricta:

```
1. Rutas Públicas (sin auth)
   ├── POST /v1/login          → throttle.api:login,5,5
   ├── POST /v1/login/admin    → throttle.api:admin-login,3,10
   ├── POST /v1/login/support  → throttle.api:support-login,5,10
   ├── POST /v1/create/subscriber → throttle.api:subscriber-create,3,60
   └── GET  /v1/health         → Sin auth (Docker Engine)

2. Rutas Admin Internas (API Key)
   └── middleware: admin.apikey

3. Rutas Autenticadas (auth:api)
   ├── Grupo v1/parameter      → Parámetros globales
   ├── Grupo v1/global-parameters → Parámetros de nómina
   ├── Grupo v1/company/{company_id}/... → CRUD por empresa
   ├── Grupo v1/{company_id}/aduana/... → Módulo Aduana
   └── Grupo v1/support        → Portal Soporte/Admin
       ├── Rutas compartidas (Staff + Clientes)
       ├── middleware: support.staff → Solo personal
       └── middleware: admin.only  → Solo administradores
```

### 2. Convenciones de URL

| Elemento | Convención | Ejemplo |
|:---|:---|:---|
| Versión | Prefijo `v1/` obligatorio | `v1/company` |
| Recurso | Sustantivo en inglés, singular o plural consistente | `v1/company/{id}/voucher` |
| Empresa | `{company_id}` como segmento de ruta | `v1/company/{company_id}/product` |
| Acción especial | Verbo como último segmento | `v1/company/{id}/select` |

### 3. Rate Limiting

Todo endpoint sensible DEBE tener throttle configurado:

```php
->middleware('throttle.api:login,5,5')        // 5 intentos, 5 min de bloqueo
->middleware('throttle.api:admin-login,3,10')  // 3 intentos, 10 min de bloqueo
```

- **Login endpoints**: Rate limiting obligatorio e individual por tipo de portal.
- **Creación de suscriptores**: `3,60` (3 intentos, 60 min).
- **Grupo general de soporte**: `60,1` (60 req/min).

---

## 📡 Estructura de `routes/channels.php`

Los canales de broadcast siguen el patrón de autorización del ERP:

```php
// Canal privado por empresa → Valida propiedad del suscriptor
Broadcast::channel('channelName.{companyId}', function ($user, $companyId) {
    return Company::where('id', $companyId)
        ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
        ->exists();
});

// Canal privado por usuario → Valida identidad directa
Broadcast::channel('userChannel.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});
```

- **Por empresa**: Validar `company_id ↔ suscriptor_id` (ej: `accountPlanChannel`, `payrollMassCalculationChannel`).
- **Por usuario**: Validar `user_id` directo (ej: `rcvChannel`).
- **Multinivel**: Si `USER_ROLE`, validar `userHasCompanyPermission()`.

---

## 🛡️ Middleware Disponibles

| Middleware | Uso | Contexto |
|:---|:---|:---|
| `auth:api` | Autenticación JWT obligatoria | Todos los endpoints protegidos |
| `admin.apikey` | Autenticación por API Key interna | Endpoints de creación automática de suscriptores |
| `admin.only` | Restringe a `ADMIN_ROLE` | Operaciones de administración del sistema |
| `support.staff` | Restringe a `ADMIN_ROLE` + `SUPPORT_ROLE` | Operaciones del portal de soporte |
| `throttle.api:{key},{max},{decay}` | Rate limiting configurable | Endpoints públicos y sensibles |

---

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Registre un endpoint sin prefijo de versión (`v1/`).
- No proteja con `auth:api` un endpoint que accede a datos de negocio.
- Registre endpoints de soporte/admin fuera del grupo `v1/support`.
- No aplique rate limiting a endpoints de login, registro o generación masiva.
- Defina canales de broadcast sin validar `company_id` o `user_id`.
