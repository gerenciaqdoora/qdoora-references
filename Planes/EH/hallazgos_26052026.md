# 🛡️ Reporte de Auditoría de Seguridad de la API (Caja Gris)

Este documento detalla los hallazgos y remediaciones resultantes del análisis estático de seguridad (auditoría de código de caja gris) realizado sobre la API backend de **QdoorA ERP** (Laravel 11 / PHP 8.3 / PostgreSQL).

> [!IMPORTANT]
> **Alcance Acotado del Análisis**:
> Conforme a las instrucciones recibidas, se han excluido las revisiones de infraestructura en vivo de AWS (como configuraciones de SQS y políticas de IAM) y el código frontend de Angular. Este análisis se centra estrictamente en la lógica del código fuente backend.

---

## 📊 Matriz de Hallazgos y Vulnerabilidades

A continuación se presenta el consolidado de vulnerabilidades clasificadas según severidad, mapeadas a los estándares **OWASP WSTG (Web Security Testing Guide)** y el catálogo de vectores de riesgo **QD** del proyecto:

| ID | Vulnerabilidad | Dominio OWASP WSTG | Vector QD | Severidad | Estado | Archivo / Ubicación |
|---|---|---|---|---|---|---|
| **QD-SEC-01** | Cache de Secretos de AWS en Texto Plano en Disco | WSTG-CONF-02 (Config Management) | QD-02 | 🔴 Crítica | Pendiente | [aws-secrets.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/bootstrap/aws-secrets.php#L27-L30) |
| **QD-SEC-02** | Account Takeover vía Bypass de Contraseña en Cambio de Email | WSTG-ATHN-02 (Authentication) | QD-03 | 🟠 Alta | Pendiente | [UpdateProfileRequest.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Requests/Profile/UpdateProfileRequest.php#L32) |
| **QD-SEC-03** | BOLA / IDOR Masivo por Uso de Request Genérico en Nómina | WSTG-ATHZ-02 (Authorization) | QD-04 | 🟠 Alta | Pendiente | [LiquidacionController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/Nomina/LiquidacionController.php#L64) |
| **QD-SEC-04** | Bypass de Autorización Multitenant (BOLA) en ImpuestoEmpresa | WSTG-ATHZ-02 (Authorization) | QD-04 | 🟠 Alta | Pendiente | [ReviewImpuestoEmpresa.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Requests/ImpuestoEmpresa/ReviewImpuestoEmpresa.php#L22-L24) |
| **QD-SEC-05** | Denegación de Servicio Dirigida en Cierre de Sesión (Logout DoS) | WSTG-ATHN-06 (Authentication) | QD-06 | 🟡 Media | Pendiente | [AuthController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/AuthController.php#L266) |
| **QD-SEC-06** | Ausencia de Rate Limiting (Throttling) en Refresh Token | WSTG-ATHN-04 (Authentication) | QD-08 | 🟡 Media | Pendiente | [api.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/routes/api.php#L15) |
| **QD-SEC-07** | Endpoints de Pruebas de Desarrollo Expuestos a Producción | WSTG-CONF-02 (Config Management) | QD-04 | 🟡 Media | Pendiente | [api.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/routes/api.php#L31-L33) |

---

## 🔍 Detalle de Hallazgos y Remediaciones

---

### QD-SEC-01: Cache de Secretos de AWS en Texto Plano en Disco
- **Severidad:** 🔴 Crítica
- **Dominio OWASP:** WSTG-CONF-02 (Information Leakage & Configuration Management)
- **Vector QD:** QD-02

#### Descripción
Cuando la integración con AWS Secrets Manager está activa, la API descarga los secretos sensibles y los escribe en disco en texto plano dentro de la ruta `storage/app/aws_secrets.php` usando la función `var_export`. Cualquier vulnerabilidad secundaria del servidor o del framework, como un Directory Traversal, Local File Inclusion (LFI) o mala configuración en la exposición del directorio `storage/`, permitiría a un atacante leer todas las credenciales maestras de la aplicación, incluyendo contraseñas de bases de datos, claves de encriptación y tokens de APIs de terceros.

#### Evidencia en Código
En el script de arranque [aws-secrets.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/bootstrap/aws-secrets.php#L27-L30):
```php
        file_put_contents(
            $cacheFile,
            '<?php return ' . var_export($secrets, true) . ';'
        );
```

#### Confirmación Propuesta (cURL / Test Manual)
Intentar leer el archivo directamente simulando un LFI o acceso de lectura a través del sistema de archivos local de contenedores vulnerados:
```bash
cat /Users/francoalvaradotello/QdoorAChile/qdoora-api/storage/app/aws_secrets.php
```

#### Propuesta de Remediación
Evitar almacenar en caché en disco los secretos en texto plano en la etapa de bootstrap. En su lugar, se sugiere:
1. Almacenar temporalmente los secretos desencriptados únicamente en memoria caché (por ejemplo, mediante APCu o el mecanismo OPcache) si el entorno lo soporta.
2. Si es mandatorio persistir en disco para mitigar la latencia de las llamadas a AWS Secrets Manager, encriptar el array de secretos utilizando AES-256-CBC con una clave de encriptación que resida exclusivamente en las variables de entorno inyectadas por el contenedor Docker (PHP `getenv`), nunca en disco local.

##### Código Sugerido de Remediación:
```php
// En qdoora-api/bootstrap/aws-secrets.php
// Reemplazar la escritura plana por un almacenamiento cifrado usando openssl_encrypt
$bootstrapKey = getenv('BOOTSTRAP_ENCRYPTION_KEY'); // Clave inyectada por el orquestador
if (!$bootstrapKey) {
    throw new Exception('Clave de bootstrap de secretos ausente en variables de entorno.');
}

// Cifrar los secretos antes de guardarlos en el disco
$serialized = serialize($secrets);
$iv = openssl_random_pseudo_bytes(openssl_cipher_iv_length('aes-256-cbc'));
$encrypted = openssl_encrypt($serialized, 'aes-256-cbc', $bootstrapKey, 0, $iv);
$cacheData = base64_encode($iv . '::' . $encrypted);

file_put_contents($cacheFile, '<?php return ' . var_export($cacheData, true) . ';');

// Para leerlo:
$cachedString = require $cacheFile;
$parts = explode('::', base64_decode($cachedString), 2);
$decrypted = openssl_decrypt($parts[1], 'aes-256-cbc', $bootstrapKey, 0, $parts[0]);
$secrets = unserialize($decrypted);
```

---

### QD-SEC-02: Account Takeover vía Bypass de Contraseña en Cambio de Email
- **Severidad:** 🟠 Alta
- **Dominio OWASP:** WSTG-ATHN-02 (Bypassing Authentication Schema)
- **Vector QD:** QD-03

#### Descripción
El endpoint `PUT /v1/profile` procesa la actualización de los datos del perfil de usuario mediante la validación de `UpdateProfileRequest`. Sin embargo, este request no exige que se proporcione la contraseña actual (`current_password`) para cambiar el correo electrónico (`email`). Si un atacante secuestra una sesión activa del portal de clientes (por ejemplo, mediante XSS o robo de token), puede enviar una petición de actualización cambiando el correo electrónico del usuario por uno bajo su control. Luego, el atacante simplemente solicita un restablecimiento de contraseña en el flujo de `/v1/forgot-password` y el correo con la nueva contraseña llegará a su casilla, logrando un secuestro total de la cuenta.

#### Evidencia en Código
En [UpdateProfileRequest.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Requests/Profile/UpdateProfileRequest.php#L29-L34):
```php
        return [
            'first_name' => 'sometimes|required|string|max:255',
            'last_name'  => 'sometimes|required|string|max:255',
            'email'      => 'sometimes|required|email|max:255|unique:users,email,' . ($user ? $user->id : 'NULL'),
            'avatar'     => 'sometimes|nullable|image|max:5120', // Max 5MB
        ];
```

#### Confirmación Propuesta (cURL / Test Manual)
Enviar una petición PUT al perfil cambiando el email de la sesión sin enviar la contraseña:
```bash
curl -X PUT http://localhost:8000/api/v1/profile \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"email": "atacante@evil.com"}'
```

#### Propuesta de Remediación
Modificar `UpdateProfileRequest` para exigir obligatoriamente el campo `current_password` si se intenta mutar el atributo `email`. Adicionalmente, validar en la capa de negocio que dicha contraseña coincida con el hash de la base de datos antes de proceder con el guardado.

##### Código Sugerido de Remediación:
```php
// En app/Http/Requests/Profile/UpdateProfileRequest.php
public function rules(): array
{
    /** @var \App\Models\User $user */
    $user = Auth::guard('api')->user();

    $rules = [
        'first_name' => 'sometimes|required|string|max:255',
        'last_name'  => 'sometimes|required|string|max:255',
        'avatar'     => 'sometimes|nullable|image|max:5120',
    ];

    // Si viene email en la request y es diferente al actual, exigir contraseña actual
    if ($this->has('email') && $this->input('email') !== $user->email) {
        $rules['email'] = 'required|email|max:255|unique:users,email,' . $user->id;
        $rules['current_password'] = 'required|string';
    }

    return $rules;
}

public function withValidator($validator)
{
    $validator->after(function ($validator) {
        if ($this->has('current_password')) {
            $user = Auth::guard('api')->user();
            if (!\Illuminate\Support\Facades\Hash::check($this->input('current_password'), $user->password)) {
                $validator->errors()->add('current_password', 'La contraseña actual ingresada es incorrecta.');
            }
        }
    });
}
```

---

### QD-SEC-03: BOLA / IDOR Masivo por Uso de Request Genérico en Nómina
- **Severidad:** 🟠 Alta
- **Dominio OWASP:** WSTG-ATHZ-02 (Bypassing Authorization Schema / IDOR)
- **Vector QD:** QD-04

#### Descripción
Múltiples métodos de controladores críticos en el dominio de Nómina (como `LiquidacionController`, `EmployeeController`, `BranchCompanyController` y `EmployeeScheduledMovementController`) inyectan la clase genérica `Illuminate\Http\Request` en lugar de un FormRequest especializado de validación y autorización. Al omitir el FormRequest, **no se ejecuta ninguna validación server-side sobre la pertenencia de la empresa (`company_id`) o del recurso solicitado**. Un usuario autenticado legítimo con rol `SUBSCRIBER_ROLE` o `USER_ROLE` puede consultar, modificar o eliminar liquidaciones de sueldos, contratos de trabajo o sucursales de OTRA empresa simplemente modificando el parámetro `{company_id}` en la URL de la petición.

#### Evidencia en Código
En [LiquidacionController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/Nomina/LiquidacionController.php#L64):
```php
    public function show(Request $request, $company_id, $id)
    {
        // Inyecta Request genérico, omitiendo la capa de validación multinivel
```
En [EmployeeController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/Nomina/EmployeeController.php#L65):
```php
    public function show(Request $request, $company_id, $id)
```
En [BranchCompanyController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/Nomina/BranchCompanyController.php#L32):
```php
    public function index(Request $request, $company_id)
```

#### Confirmación Propuesta (cURL / Test Manual)
Intentar listar sucursales de una empresa ajena (ID 99) usando un token de la empresa (ID 1):
```bash
curl -X GET http://localhost:8000/api/v1/company/99/branches \
  -H "Authorization: Bearer <JWT_TOKEN_EMPRESA_1>"
```

#### Propuesta de Remediación
Estandarizar las firmas de los métodos en los controladores para inyectar obligatoriamente FormRequests que realicen la validación multinivel (RBAC + IDOR de empresa). Se debe crear un request base como `CompanyAccessRequest` o usar FormRequests específicos como `ReviewLiquidaciones` que implementen la lógica de control de propiedad.
Además, para cumplir con el estándar de controladores delgados y no usar `findOrFail()`, las consultas Eloquent deben moverse a la capa de Servicio correspondiente lanzando excepciones controladas.

##### Código Sugerido de Remediación (Ejemplo para Liquidación Detalle):
```php
// 1. Crear / Modificar el Request de validación y autorización
namespace App\Http\Requests\Nomina;

use App\Enums\UserOperationSubmodule;
use App\Models\Empresa\Company;
use App\Models\Nomina\Liquidacion;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class ReviewLiquidacionRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var \App\Models\User|null $user */
        $user = Auth::guard('api')->user();
        if (!$user) return false;

        $companyId = $this->route('company_id');
        $id = $this->route('id');

        // Validar acceso de empresa
        $hasCompanyAccess = match($user->role) {
            'SUBSCRIBER_ROLE' => Company::where('id', $companyId)
                ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
                ->exists(),
            'USER_ROLE' => $user->userHasCompanyPermission($companyId)
                && $user->usersPermissionSubmodules('NOMINA.SLIPS', UserOperationSubmodule::REVIEW->value),
            default => false,
        };

        if (!$hasCompanyAccess) return false;

        // Validar propiedad del recurso (IDOR Protection) si se envía el ID
        if ($id) {
            return Liquidacion::where('id', $id)
                ->where('company_id', $companyId)
                ->exists();
        }

        return true;
    }

    public function rules(): array { return []; }
}
```

```php
// 2. Modificar la firma y llamada en el Controlador
public function show(ReviewLiquidacionRequest $request, $company_id, $id)
{
    try {
        $user = Auth::guard('api')->user();
        $this->loggerService->debug($user, LoggerOperation::REVISAR, LoggerEvent::LIQUIDACION, $request->fullUrl(), 'Ver detalle de liquidación', ['id' => $id]);

        // Delegar la obtención al servicio y evitar consultas Eloquent directas (findOrFail) en el Controller
        $liquidacion = $this->liquidacionService->getLiquidacionDetail((int)$company_id, (int)$id);

        return jsonResponse(new LiquidacionResource($liquidacion), 200, 'Ok');
    } catch (\Throwable $e) {
        return $this->handleError->logAndResponse($e, $request, LoggerOperation::REVISAR, LoggerEvent::LIQUIDACION, Auth::user());
    }
}
```

---

### QD-SEC-04: Bypass de Autorización Multitenant (BOLA) en ImpuestoEmpresa
- **Severidad:** 🟠 Alta
- **Dominio OWASP:** WSTG-ATHZ-02 (Bypassing Authorization Schema / IDOR)
- **Vector QD:** QD-04

#### Descripción
Los FormRequests del módulo de Contabilidad para la gestión de impuestos corporativos (`ReviewImpuestoEmpresa` y `EliminarImpuestoEmpresa`) otorgan autorización inmediata y sin verificar a las peticiones originadas por usuarios con rol `SUBSCRIBER_ROLE`. Esto significa que un suscriptor de la Empresa A puede inyectar el identificador `company_id` de la Empresa B en la ruta y el `id` de un impuesto de la Empresa B en la query string. Dado que la validación de propiedad `withValidator` solo corrobora que el impuesto pertenezca al `company_id` especificado en la ruta (el cual pertenece a la víctima), y `authorize` retorna `true` para cualquier suscriptor, la solicitud procede con éxito. Un atacante puede revisar o eliminar permanentemente cualquier impuesto configurado por cualquier empresa dentro del ERP.

#### Evidencia en Código
En [ReviewImpuestoEmpresa.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Requests/ImpuestoEmpresa/ReviewImpuestoEmpresa.php#L22-L24) (y similar en `EliminarImpuestoEmpresa.php`):
```php
        switch ($user->role) {
            case 'SUBSCRIBER_ROLE':
                return true; // Retorna true incondicionalmente para cualquier suscriptor
```

#### Confirmación Propuesta (cURL / Test Manual)
Intentar consultar un impuesto de la empresa víctima (ID 99) inyectando su ID y `company_id` con un token de suscriptor legítimo de otra empresa (ID 1):
```bash
curl -X GET "http://localhost:8000/api/v1/company/99/impuesto-empresa?id=5" \
  -H "Authorization: Bearer <JWT_TOKEN_SUSCRIPTOR_EMPRESA_1>"
```

#### Propuesta de Remediación
Refactorizar el método `authorize()` para validar la propiedad de la empresa mediante la relación `suscriptor_id` antes de evaluar el resto de las reglas del request.

##### Código Sugerido de Remediación:
```php
// En app/Http/Requests/ImpuestoEmpresa/ReviewImpuestoEmpresa.php y EliminarImpuestoEmpresa.php
public function authorize(): bool
{
    /** @var \App\Models\User|null $user */
    $user = Auth::guard('api')->user();
    if (!$user) return false;

    switch ($user->role) {
        case 'SUBSCRIBER_ROLE':
            // Validar que la empresa de la ruta pertenezca al suscriptor autenticado
            return Company::where('id', $this->route('company_id'))
                ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
                ->exists();

        case 'USER_ROLE':
            return $user->userHasCompanyPermission($this->route('company_id'));

        default:
            return false;
    }
}
```

---

### QD-SEC-05: Denegación de Servicio Dirigida en Cierre de Sesión (Logout DoS)
- **Severidad:** 🟡 Media
- **Dominio OWASP:** WSTG-ATHN-06 (Logout Functionality)
- **Vector QD:** QD-06

#### Descripción
El endpoint de cierre de sesión (`POST /v1/logout/{user_id}`) contiene una validación de seguridad en su bloque `try` para corroborar que el identificador `$user_id` enviado por parámetro coincida con el usuario del JWT. Sin embargo, si la llamada al parser del token (`JWTAuth::parseToken()`) arroja un error debido a que el token está expirado (`TokenExpiredException`) o es inválido (`TokenInvalidException`), la ejecución salta inmediatamente a los bloques `catch`.
Dentro de los bloques `catch`, la API invoca incondicionalmente a `$this->invalidateRefreshToken($user_id)`. Como esta llamada ocurre fuera del bloque `try`, la validación de propiedad del token no se completa. Como consecuencia, **cualquier usuario o atacante externo puede cerrar la sesión de cualquier usuario del sistema (incluidos administradores) simplemente enviando un token JWT mal formado o expirado y modificando el `$user_id` en la URL de la petición**.

#### Evidencia en Código
En [AuthController.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/app/Http/Controllers/AuthController.php#L286-L291):
```php
        } catch (TokenExpiredException $e) {
            $this->invalidateRefreshToken($user_id); // Invalida la sesión del usuario del path directamente
            return jsonResponse([], 401, 'Access token has expired.');
        } catch (TokenInvalidException $e) {
            $this->invalidateRefreshToken($user_id); // Invalida la sesión del usuario del path directamente
            return jsonResponse([], 401, 'Access token is invalid.');
        }
```

#### Confirmación Propuesta (cURL / Test Manual)
Enviar una petición de logout para el usuario administrador (por ejemplo, ID 1) con un token inválido:
```bash
curl -X POST http://localhost:8000/api/v1/logout/1 \
  -H "Authorization: Bearer token_invalido_de_pruebas"
```

#### Propuesta de Remediación
1. En caso de `TokenInvalidException`, no realizar ninguna invalidación de sesión en la base de datos, puesto que no es posible constatar la procedencia del token.
2. En caso de `TokenExpiredException`, se puede decodificar el payload del token expirado (sin verificar la vigencia de expiración) para extraer el claim `sub` (el ID de usuario). Solo si dicho `sub` coincide con el `$user_id` de la ruta, proceder a invalidar el refresh token en base de datos.

##### Código Sugerido de Remediación:
```php
// En app/Http/Controllers/AuthController.php
        } catch (TokenExpiredException $e) {
            try {
                // Decodificar el token expirado de forma segura para validar coincidencia
                $payload = JWTAuth::setToken($token)->check(true); // check(true) permite bypass de expiración para inspección
                $claims = JWTAuth::getPayload($token)->toArray();
                
                if (isset($claims['sub']) && (int)$claims['sub'] === (int)$user_id) {
                    $this->invalidateRefreshToken($user_id);
                }
            } catch (\Throwable $ex) {
                // Si la decodificación falla, no invalidar nada
            }
            return jsonResponse([], 401, 'Access token has expired.');
        } catch (TokenInvalidException $e) {
            // NUNCA invalidar sesiones de BD basándose en tokens inválidos o de firmas corruptas
            return jsonResponse([], 401, 'Access token is invalid.');
        }
```

---

### QD-SEC-06: Ausencia de Rate Limiting (Throttling) en Refresh Token
- **Severidad:** 🟡 Media
- **Dominio OWASP:** WSTG-ATHN-04 (Brute Force Testing)
- **Vector QD:** QD-08

#### Descripción
El endpoint de refresco de tokens JWT (`POST /v1/refresh`) no cuenta con ningún middleware de tasa límite (Rate Limiting). Un atacante podría realizar ataques automatizados de fuerza bruta a alta velocidad para intentar adivinar refresh tokens activos en el sistema o causar una denegación de servicio (DoS) por sobrecarga al forzar consultas repetitivas de verificación sobre la base de datos de usuarios.

#### Evidencia en Código
En el archivo de rutas [api.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/routes/api.php#L15):
```php
Route::post('/v1/refresh', [\App\Http\Controllers\AuthController::class, 'v1_refreshToken']);
```

#### Confirmación Propuesta (cURL / Test Manual)
Ejecutar un ataque de repetición automatizado de peticiones POST hacia `/v1/refresh` y verificar que el servidor responda de forma consecutiva sin bloquear la tasa de llamadas.

#### Propuesta de Remediación
Asociar el middleware de throttling configurado en el sistema (`throttle.api`) restringiendo el endpoint a un máximo prudente de llamadas (por ejemplo, 10 llamadas por minuto).

##### Código Sugerido de Remediación:
```php
// En routes/api.php
Route::post('/v1/refresh', [\App\Http\Controllers\AuthController::class, 'v1_refreshToken'])
    ->middleware('throttle.api:refresh-token,10,1');
```

---

### QD-SEC-07: Endpoints de Pruebas de Desarrollo Expuestos a Producción
- **Severidad:** 🟡 Media
- **Dominio OWASP:** WSTG-CONF-02 (Information Leakage / Exposed Debug Interfaces)
- **Vector QD:** QD-04

#### Descripción
Las rutas protegidas por autenticación exponen tres endpoints controlados por `TestController` (`/v1/test/redis`, `/v1/review/modulos` y `/v1/test/bco/central`). Estos endpoints ejecutan diagnósticos de desarrollo que no debieran estar disponibles para usuarios autenticados comunes en el entorno productivo, ya que pueden filtrar configuraciones de red, estructura de módulos e integraciones con entidades bancarias externas (Banco Central).

#### Evidencia en Código
En el archivo de rutas [api.php](file:///Users/francoalvaradotello/QdoorAChile/qdoora-api/routes/api.php#L31-L33):
```php
    // Pruebas
    Route::get('/v1/test/redis', [\App\Http\Controllers\TestController::class, 'test_redis']);
    Route::get('/v1/review/modulos', [\App\Http\Controllers\TestController::class, 'modulos_suscriptor']);
    Route::get('/v1/test/bco/central', [\App\Http\Controllers\TestController::class, 'test_bco_central']);
```

#### Confirmación Propuesta (cURL / Test Manual)
```bash
curl -X GET http://localhost:8000/api/v1/test/redis \
  -H "Authorization: Bearer <JWT_TOKEN_CLIENTE_COMUN>"
```

#### Propuesta de Remediación
Eliminar las rutas de diagnóstico del archivo principal de enrutamiento o envolverlas en una validación condicional que evalúe si la aplicación corre en entorno local o de pruebas (`local` o `testing`), impidiendo su inicialización en ambientes productivos.

##### Código Sugerido de Remediación:
```php
// En routes/api.php
    if (app()->environment('local', 'testing')) {
        Route::get('/v1/test/redis', [\App\Http\Controllers\TestController::class, 'test_redis']);
        Route::get('/v1/review/modulos', [\App\Http\Controllers\TestController::class, 'modulos_suscriptor']);
        Route::get('/v1/test/bco/central', [\App\Http\Controllers\TestController::class, 'test_bco_central']);
    }
```

---

## 📅 Plan de Remediación Priorizado (Sprints de Seguridad)

Para implementar estas correcciones de forma ordenada, se propone dividir las remediaciones en dos Sprints de desarrollo:

### 🏃‍♂️ Sprint 1: Bloqueo de Vectores Críticos y Autorización (Duración: 1 Semana)
*Objetivo: Mitigar los riesgos de secuestro de cuentas, fugas de secretos y bypasses de autorización multitenant (BOLA).*

1. **QD-SEC-01 (Caché de Secretos AWS en Disco)**: Implementar encriptación en la persistencia local temporal de arranque.
2. **QD-SEC-02 (Bypass de Contraseña en Cambio de Email)**: Modificar `UpdateProfileRequest` para exigir la clave actual.
3. **QD-SEC-03 (BOLA en CRUD de Nómina)**: Refactorizar controladores de nómina para inyectar FormRequests específicos que validen los permisos y la propiedad de la empresa (aplicando también cambios en la capa de servicios para eliminar consultas de Eloquent de los controladores).
4. **QD-SEC-04 (BOLA en Impuestos de Empresa)**: Refactorizar `ReviewImpuestoEmpresa` y `EliminarImpuestoEmpresa` para validar que la empresa corresponda al suscriptor autenticado.

### 🏃‍♂️ Sprint 2: Hardening, Configuración y Estabilidad (Duración: 1 Semana)
*Objetivo: Mejorar las protecciones contra abuso de endpoints, corregir bugs de enrutamiento e invalidar correctamente las sesiones de usuario.*

1. **QD-SEC-05 (Logout DoS)**: Sanitizar los bloques `catch` de excepciones JWT en `AuthController` para evitar el cierre de sesión no autorizado por ID de ruta.
2. **QD-SEC-06 (Rate Limiting en Refresh)**: Agregar el middleware de throttling al endpoint `/v1/refresh`.
3. **QD-SEC-07 (Endpoints de Pruebas Expuestos)**: Encapsular condicionalmente las rutas de pruebas del `TestController` para que solo se carguen en entornos locales y de testing.
