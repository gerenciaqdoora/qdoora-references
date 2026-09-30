```php
<?php

namespace App\Http\Controllers\Module;

use App\Http\Controllers\Controller;
use App\Http\Requests\Module\ActionRequest;
use App\Services\Module\ModuleService;
use App\Services\Util\LoggerService;
use App\Enums\Logger\LoggerOperation;
use App\Enums\Logger\LoggerEvent;
use App\Helpers\HandlesControllerLogs;
use Illuminate\Http\JsonResponse;

class ModuleController extends Controller
{
    protected ModuleService $moduleService;
    protected LoggerService $loggerService;
    protected HandlesControllerLogs $handleError;

    public function __construct(
        ModuleService $moduleService,
        LoggerService $loggerService,
        HandlesControllerLogs $handleError
    ) {
        $this->moduleService = $moduleService;
        $this->loggerService = $loggerService;
        $this->handleError = $handleError;
    }

    /**
     * ✅ REGLA: Los controladores deben ser "delgados" y orquestar vía Try-Catch.
     */
    public function store(ActionRequest $request): JsonResponse
    {
        try {
            $user = $request->user();

            // 1. LOGGING DE OPERACIÓN (Consultar si reusar o crear enums)
            $this->loggerService->debug(
                $user, 
                LoggerOperation::CREAR, 
                LoggerEvent::SISTEMA, 
                $request->fullUrl(), 
                'Descripción legible de la operación', 
                $request->all()
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
                $e, 
                $request, 
                LoggerOperation::CREAR, 
                LoggerEvent::SISTEMA,
                'Ocurrió un error inesperado al procesar la solicitud'
            );
        }
    }
}
```
