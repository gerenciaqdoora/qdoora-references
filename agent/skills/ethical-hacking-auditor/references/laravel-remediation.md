# Laravel 11 — Snippets de Remediación de Seguridad

> Usa este archivo al proponer correcciones backend para hallazgos del catastro Qdoora.
> Stack: Laravel 11 · PHP 8.3 · PostgreSQL · estructura moderna sin Kernel.php

---

## 1. Error Handler Seguro (`bootstrap/app.php`)
**Remedia**: QD-10 (APP_DEBUG), fugas de stack traces.

```php
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->render(function (Throwable $e, Request $request) {
        if ($request->expectsJson()) {
            $status = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 500;
            return response()->json([
                'message' => $status === 404 ? 'Resource not found.'
                           : ($status === 403 ? 'Forbidden.'
                           : 'An error occurred. Please try again.'),
                // ❌ NUNCA: 'trace', 'file', 'line', 'exception'
            ], $status);
        }
    });
})
```

---

## 2. Middleware de Autorización Server-Side
**Remedia**: QD-01 (client-side authz), QD-04 (BFLA).

```php
// app/Http/Middleware/EnforceServerSidePermissions.php
namespace App\Http\Middleware;

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
                return response()->json(['message' => 'Forbidden.'], 403);
            }
        }
        return $next($request);
    }
}

// bootstrap/app.php — registrar alias
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'can.do'       => \App\Http\Middleware\EnforceServerSidePermissions::class,
        'throttle.api' => \App\Http\Middleware\ApiThrottle::class,
        'portal.scope' => \App\Http\Middleware\EnforcePortalScope::class,
    ]);
})

// User::hasPermission() — valida contra DB, nunca contra request
public function hasPermission(string $permission): bool
{
    return \Cache::remember("user_{$this->id}_perm_{$permission}", 300, fn() =>
        $this->roles()
            ->whereHas('permissions', fn($q) => $q->where('slug', $permission))
            ->exists()
    );
}

// En cada controller action — doble capa obligatoria
public function approve(ApproveRequest $request, Liquidacion $liquidacion): JsonResponse
{
    Gate::authorize('approve-liquidacion', $liquidacion); // ← NUNCA omitir
    // ...
}
```

---

## 3. Rate Limiting en Autenticación
**Remedia**: QD-03 (ATO brute force), QD-08 (ausencia de throttle).

```php
// app/Http/Middleware/ApiThrottle.php
class ApiThrottle
{
    public function __construct(private RateLimiter $limiter) {}

    public function handle(Request $request, Closure $next, string $key, int $max, int $decay): Response
    {
        $id = $key . ':' . $request->ip();
        if ($this->limiter->tooManyAttempts($id, $max)) {
            return response()->json([
                'message'     => 'Too many attempts.',
                'retry_after' => $this->limiter->availableIn($id),
            ], 429);
        }
        $this->limiter->hit($id, $decay * 60);
        return $next($request);
    }
}

// routes/api.php
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle.api:login,5,15');           // 5 intentos → bloqueo 15 min

Route::post('/password/email', [ForgotPasswordController::class, 'sendResetLink'])
    ->middleware('throttle.api:password-reset,3,60');  // 3 intentos → bloqueo 60 min

Route::post('/liquidaciones/{id}/pdf', [PdfController::class, 'generate'])
    ->middleware('throttle.api:pdf-gen,10,1');         // 10 PDFs por minuto por IP
```

---

## 4. Protección de Cambio de Email
**Remedia**: QD-03 (ATO via email takeover).

```php
// app/Http/Requests/UpdateEmailRequest.php
class UpdateEmailRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'email'            => ['required', 'email', 'unique:users,email,' . $this->user()->id],
            'current_password' => ['required', 'string'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            if (!Hash::check($this->current_password, $this->user()->password)) {
                $v->errors()->add('current_password', 'La contraseña actual es incorrecta.');
            }
        });
    }
}

// app/Http/Controllers/ProfileController.php
public function updateEmail(UpdateEmailRequest $request): JsonResponse
{
    $oldEmail = $request->user()->email;
    $request->user()->update(['email' => $request->email]);
    Mail::to($oldEmail)->queue(new EmailChangedNotification($request->user(), $oldEmail));
    return response()->json(['message' => 'Email actualizado.']);
}
```

---

## 5. Respuesta de Login Mínima
**Remedia**: QD-09 (objeto de permisos manipulable).

```php
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
            'role'  => $this->user->role->slug,
            // ❌ NUNCA exponer: permissions, is_admin, privileges, roles[]
        ],
    ];
}
```

---

## 6. Global Scope + UUID para Aislamiento por Empresa
**Remedia**: QD-05 (IDOR/BOLA en documentos S3).

```php
// app/Models/Document.php
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Document extends Model
{
    use HasUuids; // UUID automático en creación

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
    $doc = Document::findOrFail($id); // 404 si no pertenece a la company del token
    $url = Storage::disk('s3')->temporaryUrl($doc->s3_path, now()->addMinutes(5));
    return response()->json(['url' => $url]);
}
```

---

## 7. Sanitización de Inputs
**Remedia**: QD-07 (Stored XSS), QD-11 (HTML injection en PDFs).

```php
// En FormRequest — siempre sanitizar antes de validar
protected function prepareForValidation(): void
{
    $sanitized = [];
    foreach (['name', 'description', 'comment', 'title'] as $field) {
        if ($this->has($field)) {
            $sanitized[$field] = strip_tags($this->input($field));
        }
    }
    $this->merge($sanitized);
}

// Para campos que permiten HTML controlado (ej: editores de texto)
// Usar HTMLPurifier con configuración estricta:
$purifier = new \HTMLPurifier();
$config   = \HTMLPurifier_Config::createDefault();
$config->set('HTML.Allowed', 'p,br,strong,em,ul,li,ol');
$clean = $purifier->purify($this->input('body'), $config);
```

---

## 8. Separación de Scopes por Portal
**Remedia**: QD-06 (cross-portal privilege escalation).

```php
// app/Http/Middleware/EnforcePortalScope.php
class EnforcePortalScope
{
    public function handle(Request $request, Closure $next, string $requiredScope): mixed
    {
        $user = $request->user();
        // El JWT debe incluir un claim 'portal' firmado server-side
        $portalClaim = auth()->payload()->get('portal');

        if ($portalClaim !== $requiredScope) {
            return response()->json(['message' => 'Forbidden. Wrong portal scope.'], 403);
        }
        return $next($request);
    }
}

// routes/api.php — separar rutas por portal
Route::prefix('admin')->middleware(['auth:api', 'portal.scope:admin'])->group(function () {
    Route::apiResource('users', AdminUserController::class);
    Route::apiResource('companies', AdminCompanyController::class);
});

Route::prefix('support')->middleware(['auth:api', 'portal.scope:support'])->group(function () {
    Route::apiResource('tickets', SupportTicketController::class);
});

Route::prefix('client')->middleware(['auth:api', 'portal.scope:client'])->group(function () {
    Route::get('dashboard', [ClientDashboardController::class, 'index']);
});
```

---

## 9. Prevenir Mass Assignment
**Remedia**: QD-09 (campos sensibles en PATCH de perfil).

```php
// app/Models/User.php
protected $fillable = [
    'name', 'email', 'phone',  // ← solo campos seguros
    // ❌ NUNCA en $fillable: role, is_admin, company_id, permissions, password (usar Hash)
];

// En controllers: nunca usar $request->all() — usar solo campos explícitos
public function update(UpdateProfileRequest $request): JsonResponse
{
    $request->user()->update($request->only(['name', 'phone']));
    return response()->json(['message' => 'Perfil actualizado.']);
}
```
