# Laravel 11 — Autenticación JWT y Protección de API

> Patrones de implementación para AuthController, AuthService, JWT config, middleware de scope
> y rate limiting. Para la arquitectura de permisos (Submódulo/Empresa), consulta `rbac-matrix.md`.

---

## 1. Configuración JWTAuth (ECS Fargate)

```php
// config/jwt.php
return [
    'ttl'              => env('JWT_TTL', 60),           // 60 min — access token
    'refresh_ttl'      => env('JWT_REFRESH_TTL', 20160),// 14 días — refresh token
    'algo'             => env('JWT_ALGO', 'HS256'),
    'required_claims'  => ['iss', 'iat', 'exp', 'nbf', 'sub', 'jti', 'company_id', 'portal'],
    'blacklist_enabled'=> env('JWT_BLACKLIST_ENABLED', true),
    'blacklist_grace_period' => env('JWT_BLACKLIST_GRACE_PERIOD', 0),
];
```

---

## 2. AuthController (Delgado)

```php
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

    public function checkPermission(string $permission): JsonResponse
    {
        $allowed = auth('api')->user()->hasPermission($permission);
        return response()->json(['allowed' => $allowed]);
    }
}
```

---

## 3. AuthService

```php
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

        $customClaims = [
            'company_id' => $user->company_id,
            'portal'     => $this->resolvePortalScope($user),
        ];

        $token = JWTAuth::claims($customClaims)->fromUser($user);
        return ['token' => $token, 'user' => $user];
    }

    public function logout(): void
    {
        Auth::guard('api')->logout();
    }

    public function refresh(): array
    {
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

## 4. AuthResource (Respuesta Mínima)

```php
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
            'portal' => $this->user->portal_scope,
        ],
    ];
}
```

---

## 5. Rutas por Portal y Middleware de Scope

```php
// bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'auth.jwt'     => \App\Http\Middleware\JwtAuthenticate::class,
        'portal.scope' => \App\Http\Middleware\EnforcePortalScope::class,
        'throttle.api' => \App\Http\Middleware\ApiThrottle::class,
    ]);
})

// routes/api.php
Route::prefix('auth')->group(function () {
    Route::post('login',   [AuthController::class, 'login'])->middleware('throttle.api:login,5,15');
    Route::post('logout',  [AuthController::class, 'logout'])->middleware('auth.jwt');
    Route::post('refresh', [AuthController::class, 'refresh'])->middleware('auth.jwt');
    Route::get('me',       [AuthController::class, 'me'])->middleware('auth.jwt');
    Route::get('check-permission/{permission}', [AuthController::class, 'checkPermission'])->middleware('auth.jwt');
});

Route::prefix('client')->middleware(['auth.jwt', 'portal.scope:client'])->group(function () { /* ... */ });
Route::prefix('support')->middleware(['auth.jwt', 'portal.scope:support'])->group(function () { /* ... */ });
Route::prefix('admin')->middleware(['auth.jwt', 'portal.scope:admin'])->group(function () { /* ... */ });
```

---

## 6. EnforcePortalScope Middleware

```php
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

## 7. Rate Limiting para Auth

```php
namespace App\Http\Middleware;

class ApiThrottle
{
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
}
```
