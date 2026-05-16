```php
<?php

namespace App\Http\Controllers\Module;

use App\Http\Controllers\Controller;
use App\Http\Requests\Module\ActionRequest;
use App\Services\Module\ModuleService;
use App\Services\Logger\LoggerService;
use App\Enums\Logger\LoggerOperation;
use App\Enums\Logger\LoggerEvent;
use App\Traits\HandlesControllerLogs;
use Illuminate\Http\JsonResponse;

class ModuleController extends Controller
{
    use HandlesControllerLogs;

    public function __construct(
        private ModuleService $moduleService,
        private LoggerService $loggerService
    ) {}

    /**
     * ✅ REGLA: Los controladores deben ser "delgados" y orquestar vía Try-Catch.
     */
    public function store(ActionRequest $request): JsonResponse
    {
        try {
            // 1. LOGGING DE OPERACIÓN (Consultar si reusar o crear enums)
            $this->loggerService->log(
                operation: LoggerOperation::CREATE_RESOURCE,
                event: LoggerEvent::RESOURCE_CREATION,
                description: 'Descripción legible de la operación',
                data: $request->validated()
            );

            // 2. DELEGACIÓN AL SERVICIO
            $result = $this->moduleService->createResource($request->validated());

            // 3. RESPUESTA EXITOSA ESTÁNDAR
            return response()->json([
                'success' => true,
                'message' => 'Operación completada con éxito',
                'data' => $result
            ], 201);

        } catch (\Exception $e) {
            // 4. MANEJO CENTRALIZADO DE ERRORES (HandlesControllerLogs)
            return $this->handleError->logAndResponse(
                exception: $e,
                operation: LoggerOperation::CREATE_RESOURCE,
                defaultMessage: 'Ocurrió un error inesperado al procesar la solicitud'
            );
        }
    }
}
```