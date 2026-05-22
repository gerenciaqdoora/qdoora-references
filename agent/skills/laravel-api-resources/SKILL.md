---
name: laravel-api-resources
description: >
  Especialista en la capa de presentación de datos de Laravel 11. Genera
  JsonResource y ResourceCollection para transformar modelos Eloquent en
  respuestas JSON seguras y consistentes. Maneja relaciones anidadas, campos
  nullables, colecciones embebidas y previene la exposición accidental de datos
  sensibles. Activar al crear nuevos endpoints de lectura, refactorizar
  respuestas que retornan modelos crudos, o cuando se necesite estandarizar la
  forma de los datos devueltos al frontend.
---

# 📦 Laravel API Resources (Capa de Presentación)

Tu responsabilidad es **transformar y blindar** los datos que salen de la API. Eres la última frontera antes del frontend. Ningún modelo Eloquent debe salir crudo; siempre se transforma a través de un `JsonResource`.

## 🏗️ Ubicación y Organización

```
app/Http/Resources/
├── GlobalParameter/         → Recursos de parámetros globales
├── Nomina/                  → Recursos de nómina
├── VoucherResource.php      → Recurso de comprobante
├── VoucherAccountResource.php
├── PurchaseResource.php
├── SaleResource.php
└── ...
```

- **Organización por dominio**: Los recursos se organizan en subdirectorios que reflejan los módulos del ERP.
- **Nomenclatura**: `{ModelName}Resource.php` para recursos individuales, `{ModelName}Collection.php` para colecciones personalizadas.

## ⚙️ Reglas de Implementación

### 1. Estructura Estándar de un Resource

```php
class VoucherResource extends JsonResource
{
    public function toArray(Request $request)
    {
        return [
            'id' => $this->id,
            'date' => $this->date,
            'type' => $this->type,

            // ✅ Relaciones nullables con operador null-safe
            'origen' => $this->origen?->name,

            // ✅ Relaciones anidadas con sub-Resource
            'company' => [
                'id' => $this->company_id,
                'social_reason' => $this->company?->social_reason,
            ],

            // ✅ Colecciones embebidas con ::collection()
            'voucher_accounts' => VoucherAccountResource::collection(
                $this->voucher_accounts
            ),
        ];
    }
}
```

### 2. Reglas Inquebrantables

| Regla | Detalle |
|:---|:---|
| **Null-safe** | Toda relación nullable usa `?->` (ej: `$this->company?->name`) |
| **Sub-resources** | Relaciones hasMany se envuelven en `::collection()` del Resource hijo |
| **Sin datos sensibles** | Nunca exponer `password`, `remember_token`, `suscriptor_id` interno |
| **Sin URLs firmadas en Resource** | Las URLs de S3 se firman en el Controller o Service, no en el Resource |
| **Enums como valor** | Los enums se retornan como `$this->status->value` o `$this->status` si ya es string-backed |

### 3. Relaciones Condicionales

```php
// Solo incluir la relación si fue cargada (evita N+1 accidental)
'accounts' => VoucherAccountResource::collection(
    $this->whenLoaded('voucher_accounts')
),

// Incluir un campo solo cuando se cumple una condición
'bank_details' => $this->when($this->type === 'EGRESO', [
    'bank' => $this->bank_name,
    'account' => $this->bank_account,
]),
```

### 4. Wrapping de Respuesta

- **Recurso individual**: `return new VoucherResource($voucher);` → `{ "data": { ... } }`
- **Colección**: `return VoucherResource::collection($vouchers);` → `{ "data": [ ... ] }`
- **Paginación**: `return VoucherResource::collection($vouchers->paginate(15));` → incluye `meta` y `links`

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Retorne `response()->json($model)` sin pasar por un Resource.
- Exponga campos internos como `suscriptor_id`, `password_hash` o `api_key`.
- Acceda a relaciones sin `?->` pudiendo causar errores en registros con nullable.
- No use `whenLoaded()` en relaciones opcionales, arriesgando N+1.
- Coloque lógica de negocio o mutaciones dentro del `toArray()`.
