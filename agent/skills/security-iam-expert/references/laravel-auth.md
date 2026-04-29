# Laravel 11 — Autenticación JWT y Protección de API

> Usa este archivo al trabajar en AuthController, bootstrap/app.php, rutas de api.php,
> configuración de JWTAuth, middleware, o cualquier lógica de autenticación del backend.

---

## 1. Configuración JWTAuth para ECS Fargate

```php
// config/jwt.php — valores críticos para ECS stateless
return [
    'ttl'              => env('JWT_TTL', 60),         // 60 minutos — access token
    'refresh_ttl'      => env('JWT_REFRESH_TTL', 20160), // 14 días — refresh token
    'algo'             => env('JWT_ALGO', 'HS256'),
    'required_claims'  => ['iss', 'iat', 'exp', 'nbf', 'sub', 'jti', 'company_id', 'portal'],
    'blacklist_enabled'=> env('JWT_BLACKLIST_ENABLED', true), // para logout real
    'blacklist_grace_period' => env('JWT_BLACKLIST_GRACE_PERIOD', 0),
];

// .env
JWT_SECRET=<generado_con_php_artisan_jwt:secret>
JWT_TTL=60
JWT_REFRESH_TTL=20160
JWT_BLACKLIST_ENABLED=true
```

---

## 2. AuthController — Delgado y Seguro

```php
// app/Http/Controllers/Auth/AuthController.php
namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Resources\Auth\AuthResource;
use App\Services\Auth\AuthService;
use Illuminate\Http\JsonResponse;

class AuthController extends Controller
{
    public function __construct(private readonly AuthService $authService) {}

    public function login(LoginRequest $request): JsonResponse
    {
        // Toda la lógica vive en el Service, no aquí
        $result = $this->authService->login($request->validated());
        return (new AuthResource($result))->response()->setStatusCode(200);
    }

    public function logout(): JsonResponse
    {
        $this->authService->logout();
        return response()->json(['message' => 'Sesión cerrada correctamente.']);
    }

    public function refresh(): JsonResponse
    {
        $result = $this->authService->refresh();
        return (new AuthResource($result))->response();
    }

    public function me(): JsonResponse
    {
        return response()->json(['data' => auth()->user()]);
    }
}
```

```php
// app/Services/Auth/AuthService.php
namespace App\Services\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthService
{
    public function login(array $credentials): array
    {
        if (!$token = Auth::guard('api')->attempt($credentials)) {
            throw new \App\Exceptions\InvalidCredentialsException();
        }

        $user = Auth::guard('api')->user();

        // Añadir claims personalizados al token
        $customClaims = [
            'company_id' => $user->company_id,
            'portal'     => $this->resolvePortalScope($user),
        ];

        $token = JWTAuth::claims($customClaims)->fromUser($user);

        return ['token' => $token, 'user' => $user];
    }

    public function logout(): void
    {
        Auth::guard('api')->logout(); // invalida el token en la blacklist
    }

    public function refresh(): array
    {
        // Rotation: el token viejo queda inválido, se emite uno nuevo
        $newToken = Auth::guard('api')->refresh(true, true);
        return ['token' => $newToken, 'user' => Auth::guard('api')->user()];
    }

    private function resolvePortalScope(User $user): string
    {
        return match(true) {
            $user->hasRole('SUPER_ADMIN')    => 'admin',
            $user->hasRole('SUPPORT_AGENT')  => 'support',
            default                          => 'client',
        };
    }
}
```

---

## 3. AuthResource — Respuesta Mínima (Anti QD-09)

```php
// app/Http/Resources/Auth/AuthResource.php
public function toArray(Request $request): array
{
    return [
        'token'      => $this->token,
        'token_type' => 'Bearer',
        'expires_in' => config('jwt.ttl') * 60,
        'user' => [
            'id'     => $this->user->id,
            'name'   => $this->user->name,
            'email'  => $this->user->email,
            'portal' => $this->user->portal_scope, // solo el scope, no el objeto de permisos
            // ❌ NUNCA exponer: permissions[], is_admin, roles[], privileges
        ],
    ];
}
```

---

## 4. Rutas — Separación por Portal (bootstrap/app.php + api.php)

```php
// bootstrap/app.php — registro de middlewares
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'auth.jwt'     => \App\Http\Middleware\JwtAuthenticate::class,
        'portal.scope' => \App\Http\Middleware\EnforcePortalScope::class,
        'can.do'       => \App\Http\Middleware\EnforceServerSidePermissions::class,
        'throttle.api' => \App\Http\Middleware\ApiThrottle::class,
    ]);
})

// routes/api.php — grupos por portal con scope enforcement
Route::prefix('auth')->group(function () {
    Route::post('login',   [AuthController::class, 'login'])
         ->middleware('throttle.api:login,5,15');
    Route::post('logout',  [AuthController::class, 'logout'])->middleware('auth.jwt');
    Route::post('refresh', [AuthController::class, 'refresh'])->middleware('auth.jwt');
    Route::get('me',       [AuthController::class, 'me'])->middleware('auth.jwt');

    // Endpoint de validación server-side para Guards de Angular (anti QD-01)
    Route::get('check-permission/{permission}', [AuthController::class, 'checkPermission'])
         ->middleware('auth.jwt');
});

// Rutas del Portal Cliente
Route::prefix('client')->middleware(['auth.jwt', 'portal.scope:client'])->group(function () {
    Route::apiResource('vouchers',     \App\Http\Controllers\Client\VoucherController::class);
    Route::apiResource('liquidaciones',\App\Http\Controllers\Client\LiquidacionController::class);
    // ...
});

// Rutas del Portal Soporte
Route::prefix('support')->middleware(['auth.jwt', 'portal.scope:support'])->group(function () {
    Route::apiResource('tickets', \App\Http\Controllers\Support\TicketController::class);
    // ...
});

// Rutas del Portal Admin
Route::prefix('admin')->middleware(['auth.jwt', 'portal.scope:admin'])->group(function () {
    Route::apiResource('users',     \App\Http\Controllers\Admin\UserController::class);
    Route::apiResource('companies', \App\Http\Controllers\Admin\CompanyController::class);
    // ...
});
```

---

## 5. Middleware de Scope por Portal

```php
// app/Http/Middleware/EnforcePortalScope.php
namespace App\Http\Middleware;

class EnforcePortalScope
{
    public function handle(Request $request, Closure $next, string $requiredScope): mixed
    {
        $payload = auth('api')->payload();

        if (!$payload || $payload->get('portal') !== $requiredScope) {
            return response()->json([
                'message' => 'Forbidden. This token does not have access to this portal.',
            ], 403);
        }

        return $next($request);
    }
}
```

---

## 6. Validación de Permiso Server-Side (Anti QD-01)

```php
// app/Http/Controllers/Auth/AuthController.php
public function checkPermission(string $permission): JsonResponse
{
    $user    = auth('api')->user();
    $allowed = $user->hasPermission($permission);

    return response()->json(['allowed' => $allowed]);
}

// app/Models/User.php
public function hasPermission(string $permission): bool
{
    return \Cache::remember("user_{$this->id}_perm_{$permission}", 300, fn() =>
        $this->roles()
             ->whereHas('permissions', fn($q) => $q->where('slug', $permission))
             ->exists()
    );
}
```

---

## 7. Rate Limiting en Auth Endpoints

```php
// app/Http/Middleware/ApiThrottle.php
public function handle(Request $request, Closure $next, string $key, int $max, int $decay): Response
{
    $id = $key . ':' . ($request->user()?->id ?? $request->ip());

    if ($this->limiter->tooManyAttempts($id, $max)) {
        return response()->json([
            'message'     => 'Too many attempts.',
            'retry_after' => $this->limiter->availableIn($id),
        ], 429);
    }

    $this->limiter->hit($id, $decay * 60);
    return $next($request);
}
```
