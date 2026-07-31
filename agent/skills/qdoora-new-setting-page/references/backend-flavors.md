# Sabores de Backend para Páginas de Configuración

Una página de "Configuración/Ajustes/Parámetros" en QdoorA no tiene un único patrón de backend obligatorio (a diferencia de los listados paginados, que siempre usan `PaginatesResults`). Existen dos sabores reales, según la naturaleza del dominio.

## Sabor 1 — Registro de features toggleables (ej. Nómina)

Úsalo cuando el dominio tiene **muchas** configuraciones booleanas/JSON que se activan o desactivan independientemente, y ese catálogo de "features" puede crecer con el tiempo sin tocar código (nuevas filas en una tabla global).

### Modelo de datos
- Una tabla **global** de catálogo (`global_nomina_features`: `feature_key`, `name`, `is_mandatory`, `default_config`).
- Una tabla **por empresa** (`nomina_company_settings`: `company_id`, `feature_key`, `is_active`, `config` JSON, opcionalmente `global_earn_discount_id` si la feature está vinculada a un concepto contable).

### Backend (`app/Services/Nomina/NominaSettingsService.php`)
```php
public function getSettings(int $companyId): array
{
    $features = GlobalNominaFeature::getActiveCached();
    // Lazy init: si la empresa no tiene filas para todas las features, se provisionan con defaults
    if (NominaCompanySettings::porEmpresa($companyId)->count() < $features->count()) {
        $this->provisionDefaultSettings($companyId);
    }
    // Combina catálogo global + fila de empresa + opciones de selects (ej. instituciones CCAF/MUTUAL)
    // Retorna: feature_key, label, is_active, is_mandatory, config, options
}

public function toggleFeature(int $companyId, string $featureKey, bool $isActive): NominaCompanySettings
{
    // Rechaza desactivar una feature is_mandatory
    // Sincroniza el HaberDescuento de empresa vinculado si corresponde
}

public function updateConfig(int $companyId, string $featureKey, array $config): NominaCompanySettings
{
    // Validaciones de negocio específicas por feature (ej. mínimo legal de Horas Extras)
}
```

### Controller (delgado, 3 endpoints)
```php
public function index(int $companyId): JsonResponse           // GET  /nomina/{company}/settings
public function toggle(ToggleNominaFeature $r, int $c): JsonResponse       // PATCH /nomina/{company}/settings/toggle
public function updateConfig(UpdateNominaFeatureConfig $r, int $c, string $featureKey): JsonResponse // PATCH /nomina/{company}/settings/{featureKey}
```

### Angular Service (`nomina/settings/settings.service.ts`)
- `BehaviorSubject<NominaFeatureSetting[]>` + `settings$` expuesto.
- `getSettings()` — carga inicial (normalmente vía **resolver de ruta**, no `ngOnInit`, porque toda la página depende de esta lista antes de renderizar).
- `toggleFeature(featureKey, isActive)` y `updateConfig(featureKey, config)` — ambos hacen `tap()` para mutar el item correspondiente dentro del array del `BehaviorSubject` (evita recargar toda la lista tras cada cambio).
- `buildFeatureForm(setting)` — arma un `FormGroup` **distinto por `feature_key`** (un `switch` local), ya que cada feature tiene su propio shape de `config`.

### Ruta con resolver
```ts
export default [
    {
        path: '',
        component: NominaSettingsComponent,
        resolve: { settingsBase: () => inject(NominaSettingsService).getSettings() },
    },
] as Routes;
```

## Sabor 2 — Agregación de sub-recursos independientes (ej. Facturación SII)

Úsalo cuando la página de Configuración agrupa **2-3 conceptos que ya son independientes entre sí** (cada uno con su propio modelo, sus propios endpoints, sin necesidad de una tabla de catálogo dinámica). No hay concepto de "feature_key" ni de activar/desactivar — cada sub-recurso tiene su propio ciclo de vida (crear, reemplazar, eliminar).

### Ejemplo real (`billing/setting` — Certificado + CAF)
- **Certificado**: `GET /sii/{company}/certificate`, `POST /sii/{company}/certificate` (upload), `DELETE /sii/{company}/certificate/{id}`, `POST /sii/{company}/test-connection`.
- **CAF**: `GET /sii/{company}/caf`, `POST /sii/{company}/caf` (upload XML).

### Angular Service (`billing/billing.service.ts`)
- **No** usa un `BehaviorSubject` compartido para "todas las configuraciones" — cada sub-recurso tiene sus propios métodos simples que devuelven `Observable` directo (`getCertificate()`, `listCafs()`, etc.), sin estado intermedio, porque cada uno se carga independientemente en `ngOnInit()` (no vía resolver único).
- El componente llama a `loadCertificate()` y `loadCafs()` por separado, cada uno con su propio `loadingCert`/`loadingCafs`.

### Cuándo elegir cada sabor

| Señal | Sabor |
|---|---|
| El catálogo de "cosas configurables" puede crecer sin tocar código (nueva fila en tabla global) | 1 — Registro de features toggleables |
| Cada área tiene su propio modelo de datos ya establecido, sin necesidad de una tabla de catálogo | 2 — Agregación de sub-recursos |
| Necesitas activar/desactivar la configuración como un todo (`is_active`) | 1 |
| Cada área se guarda/reemplaza como una operación independiente (subir un archivo, probar una conexión) | 2 |
| Quieres una sola carga inicial (resolver) que traiga todo antes de renderizar | 1 |
| Prefieres cargar cada área de forma independiente y mostrar su propio loader | 2 |

No fuerces el Sabor 1 (tabla de catálogo global + `feature_key`) para un dominio de 2 conceptos fijos que nunca va a crecer — es sobre-ingeniería. Tampoco uses el Sabor 2 si el dominio realmente va a tener nuevas "features" con el tiempo — terminarás repitiendo controladores para cada una en vez de un registro genérico.
