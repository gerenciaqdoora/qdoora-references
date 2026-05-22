# Laravel 11 — Snippets de Remediación de Seguridad

> Usa este archivo al proponer correcciones backend para hallazgos del catastro QdoorA.
> Stack: Laravel 11 · PHP 8.3 · PostgreSQL · estructura moderna sin Kernel.php

---

## 1. Error Handler Seguro (`bootstrap/app.php`)
**Remedia**: QD-10 (APP_DEBUG), fugas de stack traces.

```php
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->render(function (Throwable $e, Request $request) {
        if ($request->expectsJson()) {
            $status = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 500;
            
            // Si es un error de validación HTTP, retornar los mensajes habituales
            if ($e instanceof \Illuminate\Validation\ValidationException) {
                return response()->json([
                    'message' => 'The given data was invalid.',
                    'errors'  => $e->errors(),
                ], 422);
            }

            // Para cualquier otro error en producción, ocultar el stack trace y detalles
            return response()->json([
                'message' => $status === 404 ? 'Resource not found.'
                           : ($status === 403 ? 'Forbidden.'
                           : ($status === 429 ? 'Too many attempts.'
                           : 'An error occurred. Please try again.')),
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

use Closure;
use Illuminate\Http\Request;

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

// User.php (Model) — valida contra DB con caché atómica
public function hasPermission(string $permission): bool
{
    return \Cache::remember("user_{$this->id}_perm_{$permission}", 300, fn() =>
        $this->roles()
            ->whereHas('permissions', fn($q) => $q->where('slug', $permission))
            ->exists()
    );
}

// En cada controller action — aplicar la validación robusta server-side
public function approve(ApproveRequest $request, Liquidacion $liquidacion): JsonResponse
{
    Gate::authorize('approve-liquidacion', $liquidacion); // ← NUNCA omitir control multitenant
    // ...
}
```

---

## 3. Rate Limiting en Autenticación y Operaciones Costosas
**Remedia**: QD-03 (ATO brute force), QD-08 (ausencia de throttle).

```php
// app/Http/Middleware/ApiThrottle.php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Cache\RateLimiter;

class ApiThrottle
{
    public function __construct(private RateLimiter $limiter) {}

    public function handle(Request $request, Closure $next, string $key, int $max, int $decay): mixed
    {
        $id = $key . ':' . $request->ip();
        if ($this->limiter->tooManyAttempts($id, $max)) {
            return response()->json([
                'message'     => 'Too many attempts.',
                'retry_after' => $this->limiter->availableIn($id),
            ], 429)->header('Retry-After', $this->limiter->availableIn($id));
        }
        
        $this->limiter->hit($id, $decay * 60);
        return $next($request);
    }
}

// routes/api.php
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle.api:login,5,15');           // 5 intentos fallidos → bloqueo 15 min

Route::post('/password/email', [ForgotPasswordController::class, 'sendResetLink'])
    ->middleware('throttle.api:password-reset,3,60');  // 3 intentos → bloqueo 60 min

Route::post('/liquidaciones/{id}/pdf', [PdfController::class, 'generate'])
    ->middleware('throttle.api:pdf-gen,10,1');         // Máximo 10 PDFs por minuto
```

---

## 4. Protección de Cambio de Email (Evitar Secuestro de Cuenta)
**Remedia**: QD-03 (ATO via email takeover).

```php
// app/Http/Requests/UpdateEmailRequest.php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;

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
    $user = $request->user();
    $oldEmail = $user->email;
    
    // Actualizar correo
    $user->update(['email' => $request->email]);
    
    // Notificar al correo anterior de forma segura e inmediata
    Mail::to($oldEmail)->queue(new EmailChangedNotification($user, $oldEmail));
    
    return response()->json(['message' => 'Email actualizado exitosamente.']);
}
```

---

## 5. Respuesta de Login Mínima Segura
**Remedia**: QD-09 (objeto de permisos manipulable).

```php
// app/Http/Resources/AuthResource.php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuthResource extends JsonResource
{
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
                // ❌ NUNCA exponer: permissions, is_admin, privileges
            ],
        ];
    }
}
```

---

## 6. Global Scope + UUID para Aislamiento por Empresa
**Remedia**: QD-05 (IDOR/BOLA en documentos S3).

```php
// app/Models/Document.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Builder;

class Document extends Model
{
    use HasUuids; // Auto-generar UUID v4 seguro e impredecible

    protected static function booted(): void
    {
        static::addGlobalScope('company', function (Builder $builder) {
            if (auth()->check()) {
                // Forzar multitenancy: sólo ver registros del company_id del token
                $builder->where('company_id', auth()->user()->company_id);
            }
        });
    }
}

// app/Http/Controllers/DocumentController.php
public function download(string $id): JsonResponse
{
    // findOrFail lanzará 404 si el documento no pertenece al company_id del token
    $doc = Document::findOrFail($id); 
    
    // Presigned URL de corta duración (máximo 5-10 minutos)
    $url = Storage::disk('s3')->temporaryUrl($doc->s3_path, now()->addMinutes(5));
    
    return response()->json(['url' => $url]);
}
```

---

## 7. Sanitización de Inputs y Prevención de XSS
**Remedia**: QD-07 (Stored XSS), QD-11 (HTML injection en PDFs).

```php
// En FormRequests — Sanitizar todas las entradas antes de su validación
protected function prepareForValidation(): void
{
    $sanitized = [];
    foreach ($this->all() as $key => $value) {
        if (is_string($value)) {
            // Sanitizar campos de texto generales
            if (in_array($key, ['name', 'title', 'comment', 'description'])) {
                $sanitized[$key] = strip_tags($value);
            }
        }
    }
    
    if (!empty($sanitized)) {
        $this->merge($sanitized);
    }
}

// Para campos especiales que requieran permitir HTML formateado (editores rich text)
// Utilizar HTMLPurifier con directivas restrictivas
public function sanitizeRichText(string $html): string
{
    $purifier = new \HTMLPurifier();
    $config   = \HTMLPurifier_Config::createDefault();
    $config->set('HTML.Allowed', 'p,br,strong,em,ul,ol,li'); // Solo tags de formato básicos
    return $purifier->purify($html, $config);
}
```

---

## 8. Separación de Scopes por Portal
**Remedia**: QD-06 (cross-portal privilege escalation).

```php
// app/Http/Middleware/EnforcePortalScope.php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnforcePortalScope
{
    public function handle(Request $request, Closure $next, string $requiredScope): mixed
    {
        // El token JWT debe incluir un claim firmado server-side llamado 'portal'
        $portalClaim = auth()->payload()->get('portal');

        if ($portalClaim !== $requiredScope) {
            return response()->json(['message' => 'Forbidden. Wrong portal scope.'], 403);
        }
        
        return $next($request);
    }
}

// routes/api.php — Aislar y enforzar prefijos
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

## 9. Cifrado de Secretos en Base de Datos
**Remedia**: QD-02 (secrets expuestos).

```php
// app/Models/SystemParameter.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

class SystemParameter extends Model
{
    // Mutator para cifrado automático al guardar en PostgreSQL
    public function setValueAttribute(string $value): void
    {
        if ($this->isSensitiveField($this->key)) {
            $this->attributes['value'] = Crypt::encryptString($value);
        } else {
            $this->attributes['value'] = $value;
        }
    }

    // Accessor para descifrar automáticamente
    public function getValueAttribute(string $value): string
    {
        if ($this->isSensitiveField($this->key)) {
            try {
                return Crypt::decryptString($value);
            } catch (\Exception $e) {
                return '[DECRYPT_ERROR]';
            }
        }
        return $value;
    }

    private function isSensitiveField(string $key): bool
    {
        return in_array(strtolower($key), [
            'smtp_password', 'aws_secret_access_key', 'api_key', 'private_key'
        ]);
    }
}
```

---

## 10. Validación de Payloads en Jobs Asíncronos (SQS)
**Remedia**: QD-12 (Message Poisoning, Deserialización Insegura, SSRF).

```php
// app/Jobs/ProcessData.php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class ProcessData implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(private array $payload) {}

    public function handle(): void
    {
        // 1. Validar estrictamente la estructura y tipos del payload
        $validator = Validator::make($this->payload, [
            'url' => ['required', 'url'],
            'id'  => ['required', 'integer', 'min:1'],
        ]);

        if ($validator->fails()) {
            \Log::warning('SQS Poisoning Attempt Detected', ['errors' => $validator->errors()]);
            return;
        }

        $validated = $validator->validated();

        // 2. Prevenir SSRF validando que la URL no apunte a IPs internas de AWS (169.254.x.x) o localhost
        $parsedUrl = parse_url($validated['url'], PHP_URL_HOST);
        $ip = gethostbyname($parsedUrl);
        
        if (preg_match('/^(127\.|169\.254\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)/', $ip)) {
            \Log::critical('SSRF Attempt in Job', ['url' => $validated['url']]);
            return;
        }

        // 3. Procesamiento seguro
        $response = Http::timeout(5)->get($validated['url']);
    }
}
```

---

## 11. Configuración de Content-Disposition en S3
**Remedia**: QD-13 (Stored XSS vía uploads directos).

```php
// app/Http/Controllers/UploadController.php
public function upload(Request $request): JsonResponse
{
    $request->validate([
        'file' => ['required', 'file', 'max:5120']
    ]);

    $file = $request->file('file');
    $path = "companies/".auth()->user()->company_id."/uploads";

    // Forzar Content-Disposition: attachment al subir a S3
    // Esto asegura que el navegador descargue el archivo en lugar de renderizarlo (previniendo XSS de SVG/HTML)
    $storedPath = Storage::disk('s3')->putFileAs(
        $path, 
        $file, 
        $file->hashName(), 
        ['ContentDisposition' => 'attachment; filename="'.$file->getClientOriginalName().'"']
    );

    return response()->json(['path' => $storedPath]);
}
```
