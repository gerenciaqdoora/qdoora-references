# Matriz de Roles, Permisos y Scopes — Qdoora ERP

> Usa este archivo al definir roles, permisos, separación de portales, middleware de scope,
> o al validar si un usuario puede ejecutar una acción específica en el ERP.

---

## 1. Roles y Scopes del Sistema

| Rol               | Scope JWT | Portal de Acceso | Descripción                                                      |
| ----------------- | --------- | ---------------- | ---------------------------------------------------------------- |
| `ADMIN_ROLE`      | `admin`   | Portal Admin     | Gestiona empresas, usuarios, roles globales del ERP              |
| `SUPPORT_ROLE`    | `support` | Portal Soporte   | Gestiona tickets, investigación forense, suscriptores            |
| `SUBSCRIBER_ROLE` | `client`  | Portal Cliente   | Dueño/Admin de una empresa. Acceso completo dentro de su empresa |
| `USER_ROLE`       | `client`  | Portal Cliente   | Empleado con permisos granulares definidos por el SUBSCRIBER     |

**Regla crítica**: El scope del JWT determina qué prefijo de rutas puede consumir. Un token
`client` no puede acceder a `/api/support/*` ni `/api/admin/*` aunque el endpoint exista.

---

## 2. Permisos Granulares por Módulo

### Módulo Contabilidad

```
view-vouchers          → Ver comprobantes
create-vouchers        → Crear comprobantes
approve-vouchers       → Aprobar comprobantes (cierre de periodo)
view-reports           → Ver reportes contables
export-books           → Exportar libros de compra/venta
```

### Módulo Remuneraciones

```
view-liquidaciones     → Ver liquidaciones de la empresa
create-liquidaciones   → Generar liquidaciones
approve-liquidaciones  → Aprobar y pagar liquidaciones
export-previred        → Exportar archivo Previred
view-employees         → Ver empleados
manage-employees       → Crear/editar empleados
```

### Módulo Aduana

```
view-din               → Ver declaraciones de importación
create-din             → Crear nuevas DINs
upload-documents       → Adjuntar documentos a despachos
approve-dispatch       → Aprobar y cerrar despachos
view-manifest          → Consultar manifiestos
```

### Portal Soporte/Admin

```
manage-tickets         → Gestionar tickets (agentes de soporte)
view-all-companies     → Ver todas las empresas (solo admin)
manage-companies       → Crear/editar/suspender empresas (solo admin)
manage-users           → Gestionar usuarios globales (solo admin)
view-audit-logs        → Ver logs de auditoría (solo admin)
```

---

## 3. Implementación de Roles en Laravel 11

```php
// database/migrations/xxxx_create_roles_permissions_tables.php
Schema::create('roles', function (Blueprint $table) {
    $table->id();
    $table->string('name')->unique();    // SUPER_ADMIN, SUBSCRIBER_ROLE, etc.
    $table->string('scope');            // admin, support, client
    $table->timestamps();
});

Schema::create('permissions', function (Blueprint $table) {
    $table->id();
    $table->string('slug')->unique();   // view-liquidaciones, approve-vouchers, etc.
    $table->string('module');           // accounting, payroll, customs, support
    $table->timestamps();
});

Schema::create('role_permission', function (Blueprint $table) {
    $table->foreignId('role_id')->constrained()->onDelete('cascade');
    $table->foreignId('permission_id')->constrained()->onDelete('cascade');
    $table->primary(['role_id', 'permission_id']);
});

Schema::create('role_user', function (Blueprint $table) {
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->foreignId('role_id')->constrained()->onDelete('cascade');
    $table->primary(['user_id', 'role_id']);
});
```

```php
// app/Models/User.php
public function roles(): BelongsToMany
{
    return $this->belongsToMany(Role::class);
}

public function hasRole(string $role): bool
{
    return $this->roles()->where('name', $role)->exists();
}

public function hasPermission(string $permission): bool
{
    return \Cache::remember("perm_{$this->id}_{$permission}", 300, fn() =>
        $this->roles()
             ->whereHas('permissions', fn($q) => $q->where('slug', $permission))
             ->exists()
    );
}

public function getPortalScope(): string
{
    if ($this->hasRole('SUPER_ADMIN'))   return 'admin';
    if ($this->hasRole('SUPPORT_AGENT')) return 'support';
    return 'client';
}
```

---

## 4. FormRequest con authorize() — Validación RBAC por Recurso

```php
// app/Http/Requests/Payroll/ApproveLiquidacionRequest.php
class ApproveLiquidacionRequest extends FormRequest
{
    public function authorize(): bool
    {
        // ✅ Validación en dos capas:
        // 1. ¿El usuario tiene el permiso funcional?
        // 2. ¿La liquidación pertenece a su empresa?
        $liquidacion = $this->route('liquidacion');

        return $this->user()->hasPermission('approve-liquidaciones')
            && $liquidacion->company_id === $this->user()->company_id;
    }

    public function rules(): array
    {
        return [
            'observations' => ['nullable', 'string', 'max:500'],
        ];
    }

    // ❌ NUNCA dejar authorize() en true sin validación:
    // public function authorize(): bool { return true; } ← BFLA vulnerability (QD-04)
}
```

---

## 5. Seeder de Roles y Permisos

```php
// database/seeders/RolesAndPermissionsSeeder.php
class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Roles
        $admin   = Role::firstOrCreate(['name' => 'SUPER_ADMIN',    'scope' => 'admin']);
        $support = Role::firstOrCreate(['name' => 'SUPPORT_AGENT',  'scope' => 'support']);
        $owner   = Role::firstOrCreate(['name' => 'SUBSCRIBER_ROLE','scope' => 'client']);
        $user    = Role::firstOrCreate(['name' => 'USER_ROLE',       'scope' => 'client']);

        // Permisos por módulo
        $allPerms = [
            // Contabilidad
            ['slug' => 'view-vouchers',    'module' => 'accounting'],
            ['slug' => 'create-vouchers',  'module' => 'accounting'],
            ['slug' => 'approve-vouchers', 'module' => 'accounting'],
            // Nómina
            ['slug' => 'view-liquidaciones',    'module' => 'payroll'],
            ['slug' => 'create-liquidaciones',  'module' => 'payroll'],
            ['slug' => 'approve-liquidaciones', 'module' => 'payroll'],
            // Aduana
            ['slug' => 'view-din',      'module' => 'customs'],
            ['slug' => 'create-din',    'module' => 'customs'],
            ['slug' => 'approve-dispatch', 'module' => 'customs'],
            // Admin
            ['slug' => 'manage-companies', 'module' => 'admin'],
            ['slug' => 'manage-users',     'module' => 'admin'],
            ['slug' => 'view-audit-logs',  'module' => 'admin'],
        ];

        foreach ($allPerms as $perm) {
            Permission::firstOrCreate($perm);
        }

        // SUPER_ADMIN tiene todos los permisos
        $admin->permissions()->sync(Permission::pluck('id'));

        // SUBSCRIBER_ROLE tiene todos los permisos de cliente
        $clientPerms = Permission::whereNotIn('module', ['admin'])->pluck('id');
        $owner->permissions()->sync($clientPerms);
    }
}
```

---

## 6. Tabla de Decisión — ¿Qué middleware aplicar?

| Escenario                         | Middleware / Validación             |
| --------------------------------- | ----------------------------------- |
| Ruta pública (login, registro)    | Sin middleware                      |
| Ruta autenticada cualquier portal | `auth.jwt`                          |
| Ruta exclusiva del portal cliente | `auth.jwt` + `portal.scope:client`  |
| Ruta exclusiva del portal soporte | `auth.jwt` + `portal.scope:support` |
| Ruta exclusiva del portal admin   | `auth.jwt` + `portal.scope:admin`   |
| Acción sobre recurso específico   | `authorize()` en `FormRequest`      |
| Endpoint de alta criticidad       | `auth.jwt` + `throttle.api:X,Y`     |
