# FormRequest completo — plantilla de referencia (Portal Cliente)

```php
<?php

namespace App\Http\Requests\Module;

use App\Enums\UserOperationSubmodule;
use App\Models\Empresa\Company;
use App\Traits\AuthorizesClientRequests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ActionRequest extends FormRequest
{
    use AuthorizesClientRequests;

    /**
     * ✅ REGLA: Autorización centralizada en el trait. NUNCA duplicar el switch/case de roles
     * ni inventar métodos de User que no existen (`hasPermission()` no existe).
     */
    public function authorize(): bool
    {
        return $this->authorizeSubmodule(
            (int) $this->route('company_id'),
            'NOMBRE_SUBMODULO',
            UserOperationSubmodule::CREATE
        );
    }

    /**
     * ✅ REGLA: Validación estricta y unicidad con scope multitenant.
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'code' => [
                'required',
                'string',
                'max:50',
                // Unicidad SIEMPRE acotada a la empresa, nunca global
                Rule::unique('module_table')->where('company_id', $this->route('company_id')),
            ],
            // Ojo: la tabla real de empresas es core_companies, no companies
            'company_id' => ['required', 'integer', 'exists:core_companies,id'],
        ];
    }

    /**
     * ✅ REGLA: Mensajes SIEMPRE en ESPAÑOL.
     */
    public function messages(): array
    {
        return [
            'name.required' => 'El nombre es obligatorio.',
            'code.unique' => 'Este código ya está registrado para la empresa.',
            'company_id.exists' => 'La empresa seleccionada no es válida.',
        ];
    }

    /**
     * ✅ REGLA: Pre-condiciones de negocio y propiedad del recurso (anti-IDOR).
     *
     * El trait autoriza el TIPO de operación; acá se autoriza el RECURSO CONCRETO.
     * Usa find() + error controlado en español, nunca findOrFail().
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $empresa = Company::find($this->route('company_id'));

            if (!$empresa || !$empresa->accountPlan) {
                $validator->errors()->add('company_id', 'La empresa debe tener un plan de cuentas asociado.');
            }

            // Anti-IDOR en EDIT/DELETE: el recurso debe pertenecer a la empresa de la ruta
            if ($this->route('resource_id')) {
                $existe = \App\Models\Module\Resource::where('id', $this->route('resource_id'))
                    ->where('company_id', $this->route('company_id'))
                    ->exists();

                if (!$existe) {
                    $validator->errors()->add('resource_id', 'El registro no está disponible.');
                }
            }
        });
    }
}
```

## Checklist antes de dar por terminado un FormRequest

- [ ] `authorize()` usa el trait del portal correcto, sin `switch` de roles duplicado.
- [ ] Ningún `return true;` incondicional.
- [ ] EDIT/DELETE valida propiedad del recurso contra `company_id` en `withValidator()`.
- [ ] `unique()` acotado por `company_id`.
- [ ] Foreign keys con `exists:` apuntando a nombres de tabla **reales** (`core_companies`, no `companies`).
- [ ] Todos los mensajes en español.
- [ ] Sin llamadas a Services ni persistencia.
- [ ] Sin `findOrFail()` — usar `find()` + error controlado.
