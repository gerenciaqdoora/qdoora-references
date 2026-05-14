# Estándar de FormRequests QdoorA

## Estructura de Archivo Recomendada

```php
<?php

namespace App\Http\Requests\NombreModulo;

use App\Enums\UserOperationSubmodule;
use App\Models\Company;
use Illuminate\Support\Facades\Auth;
use Illuminate\Foundation\Http\FormRequest;

class MiRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Lógica de roles SUBSCRIBER vs USER
    }

    public function rules(): array
    {
        // Reglas de validación técnica
    }

    public function messages(): array
    {
        // Mensajes en ESPAÑOL
    }

    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            // Lógica de negocio
            
            // Ejemplo: Validación de Propiedad (Multi-tenant)
            if ($this->isMethod('PUT') || $this->isMethod('PATCH') || $this->isMethod('DELETE')) {
                $resourceId = $this->route('id');
                $companyId = $this->route('company_id');
                
                $exists = MiModelo::where('id', $resourceId)
                    ->where('company_id', $companyId)
                    ->exists();
                    
                if (!$exists) {
                    $validator->errors()->add('id', 'El recurso no pertenece a la empresa actual o no existe.');
                }
            }
        });
    }
}
```

## Checklist de Seguridad
1. ¿Valida que el recurso pertenezca a la empresa actual? (Obligatorio en EDIT/DELETE)
2. ¿Los mensajes son amigables y no exponen detalles internos?
3. ¿Se valida el permiso específico del submódulo para `USER_ROLE`?
4. ¿Se usa `exists` para todas las FK?
