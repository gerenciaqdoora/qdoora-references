```php
<?php

namespace App\Http\Controllers\Util;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthCheckController extends Controller
{
    /**
     * ✅ REGLA: Endpoint público /api/v1/health sin auth.
     * Valida activamente DB y Redis de forma Stateless.
     */
    public function check(): JsonResponse
    {
        try {
            // 1. Validar Conexión a Base de Datos
            DB::connection()->getPdo();

            // 2. Validar Conexión a Redis
            Redis::connection()->ping();

            return response()->json([
                'status' => 'healthy',
                'timestamp' => now()->toIso8601String(),
                'services' => [
                    'database' => 'ok',
                    'redis' => 'ok'
                ]
            ], 200);

        } catch (\Throwable $e) {
            return response()->json([
                'status' => 'unhealthy',
                'message' => 'Service Unavailable'
            ], 503);
        }
    }
}
```