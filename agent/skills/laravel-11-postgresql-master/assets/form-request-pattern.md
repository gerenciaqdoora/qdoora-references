```php
<?php

namespace App\Http\Requests\Module;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\Company;

class ActionRequest extends FormRequest
{
    /**
     * ✅ REGLA: Validación de Propiedad (IDOR) y Roles.
     */
    public function authorize(): bool
    {
        $user = $this->user();
        
        // USER_ROLE: Basado en permisos de submódulo
        if ($user->hasRole('USER_ROLE')) {
            return $user->hasPermission('MODULE.SUBMODULE', 'ACTION');
        }

        // SUBSCRIBER_ROLE: Basado en pertenencia a empresa
        if ($user->hasRole('SUBSCRIBER_ROLE')) {
            return Company::where('id', $this->route('company_id'))
                ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
                ->exists();
        }

        return false;
    }

    /**
     * ✅ REGLA: Validación estricta y Unicidad.
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'], // Unicidad explícita
            'company_id' => ['required', 'integer', 'exists:companies,id'],
        ];
    }

    /**
     * ✅ REGLA: Mensajes SIEMPRE en ESPAÑOL.
     */
    public function messages(): array
    {
        return [
            'email.required' => 'El correo electrónico es obligatorio.',
            'email.unique' => 'Este correo electrónico ya está registrado.',
            'company_id.exists' => 'La empresa seleccionada no es válida.',
        ];
    }

    /**
     * ✅ REGLA: Pre-condiciones de negocio (ej. Plan de Cuentas).
     */
    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $empresa = Company::find($this->route('company_id'));
            if (!$empresa || !$empresa->accountPlan) {
                $validator->errors()->add('company_id', 'La empresa debe tener un plan de cuentas asociado.');
            }
        });
    }
}
```