# 🔐 Catastro de Seguridad Qdoora
## Transposición de Hallazgos — Informes Agunsa (Gemini + Perfiles)

> **Fuente**: Informes Inside Security — Portal Gemini (07/04/2026) y Perfiles (16/04/2026)  
> **Stack objetivo**: Laravel 11 · Angular 18/21 · AWS ECS Fargate · PostgreSQL

---

## A. Tabla de Catastro de Hallazgos

| # | Hallazgo Original (Agunsa) | Sistema | Riesgo en Qdoora | Nivel | Solución Propuesta |
|---|---|---|---|---|---|
| 1 | **C01-G**: Escalamiento de privilegios vía manipulación de respuesta de login (`admGlobal`, `privilegios` modificables client-side con Burp) | Gemini | El frontend Angular 18 confía en claims del JWT o en datos de la respuesta `/api/login` para mostrar rutas/menús. Si los Guards o el `authService` leen roles desde `localStorage` sin revalidar en backend, cualquier usuario puede modificar su rol en memoria o interceptar la respuesta. | 🔴 **CRÍTICO** | Guards Angular + Middleware Laravel que valide permisos en CADA request desde claims del token firmado, nunca desde body |
| 2 | **C02-G**: Credenciales AWS IAM en texto claro en endpoint de parámetros API | Gemini | En Qdoora, si algún endpoint expone configuración del sistema, secrets de `.env`, o credenciales S3/SES, un atacante con token válido puede exfiltrar AWS keys con Read+Write a buckets | 🔴 **CRÍTICO** | Nunca serializar configuración de infraestructura. Usar AWS Secrets Manager + IAM Roles en ECS Task Definition |
| 3 | **C03-G / C02-P**: ATO completo — listado de usuarios + fuerza bruta + modificación de email sin verificación | Gemini + Perfiles | `/api/users` expuesto a roles no-admin, ausencia de rate limiting en `/login` y `/password/reset`, sin confirmación de contraseña actual al cambiar email — idéntico riesgo en AuthController de Qdoora | 🔴 **CRÍTICO** | Rate limiting por IP en auth endpoints, verificar password actual antes de cambiar email, notificación al email anterior |
| 4 | **A01-G**: BFLA — funciones privilegiadas ejecutables por usuarios sin ese permiso (endpoints no protegidos server-side) | Gemini | Qdoora puede tener endpoints que solo ocultan botones en Angular pero no validan el permiso en Laravel. Ej: `POST /api/liquidaciones/aprobar` accesible por rol OPERADOR si no hay `authorize()` | 🔴 **CRÍTICO** | `Gate::authorize()` / `Policy` en CADA controller action. Middleware RBAC centralizado. |
| 5 | **A02-G**: IDOR/BOLA en descarga de archivos (`/api/v1/file/{id}` secuencial sin verificar propiedad) | Gemini | Qdoora usa S3 para documentos (DINs, manifiestos, comprobantes). Si los endpoints devuelven presigned URLs sin validar que el `company_id` del token coincide con el del recurso, exposición masiva | 🔴 **CRÍTICO** | Scope de Eloquent por `company_id`. UUIDs en vez de IDs secuenciales. Validar propiedad antes de generar presigned URL |
| 6 | **A03-G**: APIs de gestión de seguridad consumibles desde otro sistema sin revalidar origen ni permisos | Gemini | Si Qdoora expone endpoints de gestión de usuarios/roles en la misma API consumida por el portal cliente (Angular 18) sin distinguir que esos endpoints solo deben ser consumidos por el Portal Admin (Angular 21), riesgo de cross-app privilege escalation | 🟠 **ALTO** | Separar rutas por prefijo y middleware. Portal Admin usa scope `admin:*`, Portal Cliente usa scope `client:*`. Validar en cada request |
| 7 | **A01-P**: Stored XSS en CRUD — backend almacena HTML sin sanitizar, frontend renderiza con innerHTML | Perfiles | Si componentes Angular usan `[innerHTML]` con datos de la API (nombres, comentarios, campos de texto libre), y Laravel no sanitiza inputs, XSS almacenado ejecutable para todos los usuarios | 🟠 **ALTO** | Sanitizar con `strip_tags()` / HTMLPurifier en Laravel. Prohibir `[innerHTML]` en Angular. Usar `DomSanitizer` solo donde sea imprescindible |
| 8 | **A02-P**: Rate Limiting ausente en operaciones CRUD y autenticación | Perfiles | Sin throttle en `/api/login`, `/api/password/reset`, generación de PDFs, envío de emails — Qdoora es vulnerable a fuerza bruta, DoS económico en SII/SES y credential stuffing | 🟠 **ALTO** | `ThrottleRequests` middleware de Laravel 11. Límites diferenciados por endpoint. Backoff exponencial |
| 9 | **C01-P**: Credenciales SMTP + AWS IAM en respuesta de API de parámetros | Perfiles | Si existe un endpoint de configuración del sistema (parámetros globales, GlobalVariable) que devuelve secrets sin filtrar, exposición directa | 🟠 **ALTO** | API Resources de Laravel con `$hidden` estricto. Nunca exponer campos de configuración de infraestructura |
| 10 | **B01-G/P**: Stack traces y rutas internas expuestas en errores | Ambos | `APP_DEBUG=true` en QA/Prod expone rutas del servidor, versión de Laravel, queries SQL y estructura de directorios | 🟡 **MEDIO** | `APP_DEBUG=false` en QA/Prod. Handler personalizado en `bootstrap/app.php`. Respuestas de error genéricas |
| 11 | **M01-G**: Inyección HTML en generación de PDFs | Gemini | Si Qdoora genera PDFs (liquidaciones, DINs, comprobantes) con datos del usuario sin sanitizar usando DomPDF/Snappy, inyección de HTML arbitrario en documentos oficiales | 🟡 **MEDIO** | Sanitizar todos los campos antes de pasar a templates Blade de PDF. Usar `htmlspecialchars()` explícito |

---

## B. Implementación Técnica — 3 Hallazgos Críticos

---

### 🔴 CRÍTICO #1 — Privilege Escalation via Client-Side Authorization

**Problema**: El frontend decide los permisos basándose en datos del response de login que pueden ser manipulados con un proxy MITM.

#### Backend — Laravel 11 (`bootstrap/app.php` + Middleware)

```php
// app/Http/Middleware/EnforceServerSidePermissions.php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class EnforceServerSidePermissions
{
    public function handle(Request $request, Closure $next, string ...$permissions): mixed
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        foreach ($permissions as $permission) {
            if (!$user->hasPermission($permission)) {
                return response()->json([
                    'message' => 'Forbidden. Insufficient permissions.',
                    'required' => $permission,
                ], 403);
            }
        }

        return $next($request);
    }
}

// bootstrap/app.php — registrar middleware
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'can.do'  => \App\Http\Middleware\EnforceServerSidePermissions::class,
        'throttle.api' => \App\Http\Middleware\ApiThrottle::class,
    ]);
})
```

```php
// app/Models/User.php
public function hasPermission(string $permission): bool
{
    // Valida contra DB/cache — NUNCA contra datos del request
    return $this->roles()
        ->whereHas('permissions', fn($q) => $q->where('slug', $permission))
        ->exists();
}

// En el controller:
public function approve(LiquidacionApproveRequest $request, Liquidacion $liquidacion): JsonResponse
{
    // El middleware ya valida, pero Gate es una segunda capa
    Gate::authorize('approve-liquidacion', $liquidacion);
    // ...
}
```

```php
// CRÍTICO: La respuesta de login NO debe exponer el objeto completo de permisos
// app/Http/Resources/AuthResource.php
public function toArray(Request $request): array
{
    return [
        'token'      => $this->token,
        'token_type' => 'Bearer',
        'expires_in' => config('jwt.ttl') * 60,
        'user' => [
            'id'    => $this->user->id,
            'name'  => $this->user->name,
            'email' => $this->user->email,
            'role'  => $this->user->role->slug, // solo el slug del rol, NUNCA el objeto completo de permisos
        ],
        // ❌ NUNCA: 'permissions' => $this->user->permissions->pluck('slug'),
        // ❌ NUNCA: 'is_admin' => $this->user->is_admin,
    ];
}
```

#### Frontend — Angular 18 (Guard + Interceptor)

```typescript
// auth.guard.ts — Guard que valida contra el backend, no contra localStorage
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { map, catchError, of } from 'rxjs';

export const permissionGuard = (requiredPermission: string): CanActivateFn => {
  return () => {
    const auth   = inject(AuthService);
    const router = inject(Router);

    // Valida contra el backend en cada navegación crítica
    return auth.validatePermission(requiredPermission).pipe(
      map(hasPermission => {
        if (!hasPermission) {
          router.navigate(['/unauthorized']);
          return false;
        }
        return true;
      }),
      catchError(() => {
        router.navigate(['/login']);
        return of(false);
      })
    );
  };
};

// routes con guards server-validated
export const ADMIN_ROUTES: Routes = [
  {
    path: 'liquidaciones/aprobar',
    loadComponent: () => import('./approve.component'),
    canActivate: [permissionGuard('approve-liquidacion')],
  },
];
```

```typescript
// auth.service.ts — los permisos se obtienen del backend, no del token local
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly _permissions = signal<string[]>([]);

  validatePermission(permission: string): Observable<boolean> {
    // Endpoint dedicado que valida server-side con el token actual
    return this.http.get<{ allowed: boolean }>(
      `/api/auth/check-permission/${permission}`
    ).pipe(map(r => r.allowed));
  }

  // ❌ NUNCA hacer esto:
  // hasPermission(p: string): boolean { return this.decodedToken().permissions.includes(p); }
}
```

---

### 🔴 CRÍTICO #2 — ATO: Rate Limiting + Email Change Protection

**Problema**: Sin throttle en auth endpoints + sin verificación de password al cambiar email = Account Takeover completo.

#### Backend — Laravel 11

```php
// app/Http/Middleware/ApiThrottle.php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cache\RateLimiter;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiThrottle
{
    public function __construct(private RateLimiter $limiter) {}

    public function handle(Request $request, Closure $next, string $key, int $maxAttempts, int $decayMinutes): Response
    {
        $identifier = $key . ':' . $request->ip();

        if ($this->limiter->tooManyAttempts($identifier, $maxAttempts)) {
            $seconds = $this->limiter->availableIn($identifier);
            return response()->json([
                'message'     => 'Too many attempts. Please try again later.',
                'retry_after' => $seconds,
            ], 429);
        }

        $this->limiter->hit($identifier, $decayMinutes * 60);

        return $next($request);
    }
}

// bootstrap/app.php — throttle por endpoint
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle.api:login,5,15'); // 5 intentos, bloqueo 15 min

Route::post('/password/email', [PasswordController::class, 'sendResetLink'])
    ->middleware('throttle.api:password-reset,3,60'); // 3 intentos, bloqueo 60 min
```

```php
// app/Http/Requests/UpdateEmailRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;

class UpdateEmailRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'email'            => ['required', 'email', 'unique:users,email,' . $this->user()->id],
            'current_password' => ['required', 'string'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            // CRÍTICO: verificar password actual antes de permitir cambio de email
            if (!Hash::check($this->current_password, $this->user()->password)) {
                $validator->errors()->add('current_password', 'La contraseña actual es incorrecta.');
            }
        });
    }
}

// app/Http/Controllers/ProfileController.php
public function updateEmail(UpdateEmailRequest $request): JsonResponse
{
    $user     = $request->user();
    $oldEmail = $user->email;

    $user->update(['email' => $request->email]);

    // Notificar al email ANTERIOR con enlace de reversión
    Mail::to($oldEmail)->send(new EmailChangedNotification($user, $oldEmail));

    return response()->json(['message' => 'Email actualizado correctamente.']);
}
```

#### Frontend — Angular 18

```typescript
// email-change.component.ts
import { Component, signal } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';

@Component({ /* ... */ })
export class EmailChangeComponent {
  readonly isLoading = signal(false);
  readonly error     = signal<string | null>(null);

  form = this.fb.group({
    email:            ['', [Validators.required, Validators.email]],
    current_password: ['', [Validators.required]],  // obligatorio
  });

  constructor(private fb: FormBuilder, private profileService: ProfileService) {}

  submit(): void {
    if (this.form.invalid) return;
    this.isLoading.set(true);
    this.profileService.updateEmail(this.form.value).subscribe({
      next: () => { /* éxito */ },
      error: (err) => this.error.set(err.error?.message ?? 'Error al actualizar email'),
      complete: () => this.isLoading.set(false),
    });
  }
}
```

---

### 🔴 CRÍTICO #3 — IDOR/BOLA en Recursos con IDs Secuenciales

**Problema**: IDs numéricos predecibles en rutas de descarga sin validar `company_id` del usuario autenticado.

#### Backend — Laravel 11

```php
// app/Models/Document.php — Global Scope para aislar por empresa
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Document extends Model
{
    // Usar UUID en lugar de ID autoincremental
    public $incrementing = false;
    protected $keyType   = 'string';

    protected static function boot(): void
    {
        parent::boot();
        static::creating(fn($model) => $model->id = (string) Str::uuid());
    }

    // Scope global — SIEMPRE filtra por company del usuario autenticado
    protected static function booted(): void
    {
        static::addGlobalScope('company', function (Builder $builder) {
            if (auth()->check()) {
                $builder->where('company_id', auth()->user()->company_id);
            }
        });
    }
}

// app/Http/Controllers/DocumentController.php
public function download(string $id): JsonResponse
{
    // El Global Scope garantiza que el documento pertenece a la company del usuario
    // Si no existe en su scope, lanza 404 (no 403, para no revelar que existe)
    $document = Document::findOrFail($id);

    // Presigned URL con expiración corta (5 minutos)
    $url = Storage::disk('s3')->temporaryUrl(
        $document->s3_path,
        now()->addMinutes(5)
    );

    return response()->json(['url' => $url]);
}
```

```php
// Migration — usar UUID en tablas de documentos
Schema::create('documents', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->foreignUuid('company_id')->constrained();
    $table->foreignId('uploaded_by')->constrained('users');
    $table->string('s3_path');
    $table->string('original_name');
    $table->timestamps();

    // Índice compuesto para queries rápidas con scope
    $table->index(['company_id', 'id']);
});
```

---

## C. Configuración de Infraestructura AWS

### WAF Rules (ALB — producción ECS Fargate)

```json
{
  "Rules": [
    {
      "Name": "RateLimitAuthEndpoints",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 100,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": { "UriPath": {} },
              "PositionalConstraint": "STARTS_WITH",
              "SearchString": "/api/auth",
              "TextTransformations": [{ "Priority": 0, "Type": "LOWERCASE" }]
            }
          }
        }
      },
      "Action": { "Block": {} },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitAuth"
      }
    },
    {
      "Name": "AWSManagedRulesCommonRuleSet",
      "Priority": 2,
      "OverrideAction": { "None": {} },
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      }
    }
  ]
}
```

### ECS Task Definition — IAM Role mínimo (no hardcodear credenciales)

```json
{
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/qdoora-api-task-role",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/qdoora-ecs-execution-role",
  "secrets": [
    {
      "name": "APP_KEY",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/app-key"
    },
    {
      "name": "DB_PASSWORD",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:qdoora/prod/db-password"
    }
  ]
}
```

### Security Headers — Nginx / ALB Response Headers Policy

```nginx
# nginx.conf para contenedor Laravel
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://api.qdoora.cl;" always;

# Ocultar fingerprinting
server_tokens off;
fastcgi_hide_header X-Powered-By;
```

---

## D. Plan de Remediación Priorizado

| Prioridad | Hallazgo | Esfuerzo | Sprint |
|---|---|---|---|
| 1 | ✅ Server-side authorization en TODOS los endpoints (Gate/Policy) | Alto | S1 |
| 2 | ✅ Rate limiting en `/login`, `/password/reset`, `/password/email` | Bajo | S1 |
| 3 | ✅ UUID en tablas de documentos + Global Scope por `company_id` | Medio | S1 |
| 4 | ✅ Verificar `current_password` antes de cambiar email | Bajo | S1 |
| 5 | ✅ Eliminar objeto de permisos del response de login | Bajo | S1 |
| 6 | ✅ Guards Angular con validación server-side | Medio | S2 |
| 7 | ✅ Sanitización de inputs en backend + prohibir `[innerHTML]` en Angular | Medio | S2 |
| 8 | ✅ `APP_DEBUG=false` en todos los entornos no-local | Bajo | S2 |
| 9 | ✅ Secrets en AWS Secrets Manager — eliminar del `.env` en ECS | Medio | S2 |
| 10 | ✅ WAF Rules en ALB + Security Headers en Nginx | Medio | S3 |
| 11 | ✅ Separación de scopes API: Admin vs Cliente | Alto | S3 |
| 12 | ✅ Notificación por email ante cambio de credenciales sensibles | Bajo | S3 |

---

> **Nota de Seguridad**: Este documento es de uso interno restringido. Los snippets de código son referencias de implementación — deben ser adaptados y revisados por el equipo antes de merge a producción.
