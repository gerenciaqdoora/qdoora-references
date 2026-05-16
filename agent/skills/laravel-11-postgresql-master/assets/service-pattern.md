```php
<?php

namespace App\Services\Module;

use App\Models\Model;
use App\Services\Other\OtherService;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use App\Exceptions\GenericException;

class ServiceName
{
    public function __construct(
        private OtherService $otherService
    ) {}

    /**
     * ✅ REGLA: Los métodos de listado deben usar el prefijo get...List
     */
    public function getResourceList(array $filters = []): Collection
    {
        return Model::query()
            ->when($filters['status'] ?? null, fn($q, $status) => $q->where('status', $status))
            ->with(['relation']) // ✅ Eager Loading obligatorio para evitar N+1
            ->get();
    }

    /**
     * ✅ REGLA: Service Ownership. Si manipulas otro dominio, usa su servicio.
     */
    public function createResource(array $data): Model
    {
        return DB::transaction(function () use ($data) {
            // 1. Crear en mi dominio
            $model = Model::create($data);

            // 2. Delegar a otro dominio usando su servicio (INYECTADO)
            $this->otherService->performAction($model->id, $data['other_data']);

            return $model;
        });
    }

    /**
     * ✅ REGLA: No usar findOrFail. Lanzar excepción genérica.
     */
    public function findResource(int $id): Model
    {
        $model = Model::find($id);
        if (!$model) {
            throw new GenericException('El recurso solicitado no existe o no está disponible.');
        }
        return $model;
    }
}
```