# 📘 Development Guidelines

> Guía completa de estándares y mejores prácticas para el desarrollo del proyecto.

---

## 📑 Índice

1. [Reglas Generales de Interacción](#-reglas-generales-de-interacción)
2. [Backend - Laravel](#-backend---laravel)

- [Arquitectura](#arquitectura)
- [Patrones de Implementación](#patrones-de-implementación)
- [Convenciones de Nombres](#convenciones-de-nombres)
- [QA & Pruebas Automatizadas](#-qa--pruebas-automatizadas)

---

## 🤝 Reglas Generales de Interacción

### Ejecución de Comandos

> ⚠️ **IMPORTANTE**: El asistente NO debe ejecutar comandos que requieran instalación de dependencias o modificaciones de base de datos.

**Comandos que deben ser entregados al usuario:**

- Instalación de librerías: `npm install`, `composer install/require`
- Comandos de base de datos: migraciones, seeds, etc.
- Comandos de framework: `php artisan ...`, `ng generate ...`

**Responsabilidad del asistente:**

- ✅ Listar claramente estos comandos al finalizar la respuesta
- ✅ Agruparlos en una sección "Comandos a ejecutar"
- ✅ Proporcionar el orden correcto de ejecución
- ✅ Explicar brevemente el propósito de cada comando

**Ejemplo de formato de entrega:**

```bash

# 📦 Comandos a ejecutar (en orden):


# 1. Instalar dependencias del backend

composerrequirevendor/package


# 2. Ejecutar migraciones

phpartisanmigrate


```

---

## ⚙️ Backend - Laravel

### Resumen Ejecutivo

- 🏗️ **Arquitectura por capas**: Services → Requests → Controllers
- 📝 **FormRequest obligatorio**: Todo método debe tener su Request
- 🔐 **Autorización estricta**: Validar roles y propiedad de recursos
- 📊 **Logging exhaustivo**: Documentar todas las operaciones
- 🎯 **Delegación inteligente**: Usar servicios especializados

---

### Arquitectura

#### 1. Business Layer (Services)

> 📂 **Ubicación**: `app/Services` (organizado en subdirectorios por módulo)

**🔴 REGLA OBLIGATORIA**: Toda la lógica de negocio DEBE residir en la capa de servicios.

**Consulta obligatoria:**

- ❓ Preguntar al usuario por la carpeta/namespace específico antes de crear servicios nuevos

---

##### Service Ownership (Propiedad del Negocio)

**Principio fundamental:**

> Cada servicio es el dueño exclusivo de su dominio. Si necesitas manipular un recurso de otro dominio, invoca al servicio correspondiente.

**✅ Patrón correcto:**

```php

// UserService.php

classUserService

{

publicfunction__construct(

privateCompanyService$companyService,

privateRoleService$roleService

    ) {}


publicfunctioncreateUser(array$data):User

    {

// ✅ Crear el usuario (mi dominio)

$user=User::create($data);


// ✅ Asignar empresa usando CompanyService (su dominio)

$this->companyService->assignUserToCompany(

$user->id, 

$data['company_id']

        );


// ✅ Asignar rol usando RoleService (su dominio)

$this->roleService->assignRole(

$user->id, 

$data['role_id']

        );


return$user;

    }

}

```

**❌ Patrón incorrecto:**

```php

// ❌ UserService manipulando directamente modelos de otros dominios

publicfunctioncreateUser(array$data):User

{

$user=User::create($data);


// ❌ Acceso directo al modelo Company (viola ownership)

Company::where('id', $data['company_id'])

->update(['user_id'=>$user->id]);


// ❌ Manipulación directa del modelo Role

Role::attach($user->id, $data['role_id']);


return$user;

}

```

---

##### Delegación de Servicios Especializados

**S3FileService** - Gestión de archivos

```php

// 📂 Ubicación: /app/Services/Util/S3FileService.php


// ✅ Uso correcto

classDocumentService

{

publicfunction__construct(

privateS3FileService$s3FileService

    ) {}


publicfunctionuploadDocument(UploadedFile$file, int$userId):Document

    {

// ✅ Delegar subida a S3FileService

$fileData=$this->s3FileService->uploadFile(

$file,

'documents/'.$userId

        );


returnDocument::create([

'user_id'=>$userId,

'file_path'=>$fileData['path'],

'file_name'=>$fileData['name'],

'file_size'=>$fileData['size']

        ]);

    }

}

```

**EmailService** - Gestión de correos

```php

// 📂 Ubicación: /app/Services/Util/EmailService.php


// ✅ Uso correcto

classNotificationService

{

publicfunction__construct(

privateEmailService$emailService

    ) {}


publicfunctionnotifyUserCreation(User$user):void

    {

// ✅ Delegar envío a EmailService

$this->emailService->sendEmail(

            to: $user->email,

            subject: 'Bienvenido a la plataforma',

            view: 'emails.welcome',

            data: ['user'=>$user]

        );

    }

}

```

---

##### Manejo de Enums

> 📂 **Ubicación**: `/app/Enums` (con subdirectorios temáticos)

**Regla obligatoria:**

- Al crear migraciones con tipos `Enum`, las clases correspondientes DEBEN crearse en `/app/Enums`

**Estructura de ejemplo:**

```

app/Enums/

├── User/

│   ├── UserStatus.php

│   └── UserRole.php

├── Invoice/

│   ├── InvoiceStatus.php

│   └── PaymentMethod.php

└── Logger/

    ├── LoggerOperation.php

    └── LoggerEvent.php

```

**Ejemplo de implementación:**

```php

// app/Enums/User/UserStatus.php

namespaceApp\Enums\User;


enumUserStatus:string

{

case ACTIVE ='active';

case INACTIVE ='inactive';

case SUSPENDED ='suspended';


publicfunctionlabel():string

    {

returnmatch($this) {

self::ACTIVE=>'Activo',

self::INACTIVE=>'Inactivo',

self::SUSPENDED=>'Suspendido',

        };

    }

}

```

**Uso en migración:**

```php

// database/migrations/xxxx_create_users_table.php

Schema::create('users', function (Blueprint$table) {

$table->id();

$table->string('name');

$table->enum('status', ['active', 'inactive', 'suspended'])

->default('active');

$table->timestamps();

});

```

---

#### 2. Request Layer (FormRequests)

> 📂 **Ubicación**: `app/Http/Requests` (organizado en subdirectorios por módulo)

**🔴 OBLIGATORIO**: Todo método de controlador que reciba datos o requiera autorización DEBE tener un `FormRequest`.

##### Validación de Propiedad (IDOR) en authorize()

**Regla Estricta**: La validación de que un recurso pertenece a la empresa (`company_id`) o al usuario DEBE realizarse en el método `authorize()` del `FormRequest`. NUNCA realices esta validación manualmente dentro del controlador si existe un ID de recurso en la ruta.

**Ejemplo Correcto:**
```php
public function authorize(): bool
{
    $companyId = $this->route('company_id');
    $id = $this->route('id');

    // Validar propiedad del recurso mediante query directa
    return Liquidacion::where('id', $id)
        ->where('company_id', $companyId)
        ->exists();
}
```

---

##### Unicidad de Correos y Traducción de Mensajes (Localización)

**Regla Estricta**: TODO `FormRequest` encargado de la creación, registro o actualización de usuarios (independiente de si es Admin, Soporte o Cliente) DEBE:
1. Incluir la regla de validación de unicidad en base de datos explícitamente: `'email' => 'required|email|unique:users,email'`. NUNCA dependas únicamente del Constraint de Base de Datos para evitar excepciones 500.
2. Incluir imperativamente el método `messages()` retornando todas las traducciones personalizadas de las reglas en **español** para garantizar una experiencia de usuario (UX) correcta en el ERP Chileno.

**Ejemplo Correcto:**
```php
public function rules(): array {
    return [ 'email' => 'required|email|unique:users,email' ];
}

public function messages(): array {
    return [
        'email.required' => 'El correo electrónico es obligatorio.',
        'email.unique' => 'Este correo electrónico ya está registrado en el sistema.'
    ];
}
```

---

##### Endpoints Administrativos y de Roles Internos

**Regla Estricta**: La creación de roles internos de la plataforma (ej. `SUPPORT_ROLE`, `SUBSCRIBER_ROLE`) no debe quedar expuesta a endpoints públicos. Deben estar encapsulados bajo el grupo de rutas protegido por el middleware `admin.apikey` u otro mecanismo de API Key para integraciones seguras.

---

##### Organización de Rutas de Soporte TI

**Regla Estricta**: TODO endpoint destinado exclusivamente al Portal de Soporte (Gestión de Tickets, Logs TI, Analítica de Soporte, Directorio de Suscriptores, etc.) DEBE quedar agrupado bajo el prefijo `v1/support` dentro del archivo `routes/api.php`, encapsulado imperativamente dentro del middleware `auth:api` para garantizar la trazabilidad del agente.

**Ejemplo de Estructura Correcta en `routes/api.php`:**
```php
Route::middleware(['auth:api'])->group(function () {
    // Soporte TI - Gestión de Tickets e Interacciones
    Route::group(['prefix' => 'v1/support'], function () {
        Route::get('tickets', [SupportController::class, 'index']);
        Route::get('logs', [SystemLogController::class, 'index']);
        Route::get('analytics', [AnalyticsController::class, 'getDashboard']);
        // ... otros endpoints exclusivos del portal de soporte
    });
});
```

---

##### Estructura Completa de FormRequest

```php

<?php


namespaceApp\Http\Requests\User;


use Illuminate\Foundation\Http\FormRequest;

use App\Models\Company;


classCreateUserRequestextendsFormRequest

{

/**

     * ===================================

     * AUTORIZACIÓN

     * ===================================

     */

publicfunctionauthorize():bool

    {

$user=$this->user();


// ┌──────────────────────────────────────┐

// │ USER_ROLE (Permisos de módulo)       │

// └──────────────────────────────────────┘

// ❓ Consultar al usuario: permiso y submódulo

if ($user->hasRole('USER_ROLE')) {

return$user->hasPermission('NOMINA.EMPLOYEES', 'CREATE');

// Ejemplos: 'NOMINA.EMPLOYEES', 'ACCOUNTING.INVOICES', 'REVIEW'

        }


// ┌──────────────────────────────────────┐

// │ SUBSCRIBER_ROLE (Propiedad empresa)  │

// └──────────────────────────────────────┘

// ✅ Validar que la empresa pertenezca al suscriptor

if ($user->hasRole('SUBSCRIBER_ROLE')) {

returnCompany::where('id', $this->route('company_id'))

->where('suscriptor_id', $user->getSuscriptorByRole()?->id)

->exists();

        }


returnfalse;

    }


/**

     * ===================================

     * REGLAS DE VALIDACIÓN

     * ===================================

     */

publicfunctionrules():array

    {

return [

// ┌─────────────────┐

// │ BODY PARAMS     │

// └─────────────────┘

'name'=> ['required', 'string', 'max:255'],

'email'=> ['required', 'email', 'unique:users,email'],

'role_id'=> ['required', 'exists:roles,id'],


// ┌─────────────────┐

// │ QUERY PARAMS    │

// └─────────────────┘

'per_page'=> ['nullable', 'integer', 'min:1', 'max:100'],

'sort_by'=> ['nullable', 'string', 'in:name,created_at'],


// ┌─────────────────┐

// │ ROUTE PARAMS    │

// └─────────────────┘

'company_id'=> ['required', 'integer', 'exists:companies,id'],

        ];

    }


/**

     * ===================================

     * MENSAJES DE VALIDACIÓN (ESPAÑOL)

     * ===================================

     */

publicfunctionmessages():array

    {

return [

'name.required'=>'El nombre es obligatorio',

'name.max'=>'El nombre no puede superar los 255 caracteres',

'email.required'=>'El correo electrónico es obligatorio',

'email.email'=>'El correo electrónico debe ser válido',

'email.unique'=>'Este correo electrónico ya está registrado',

'role_id.required'=>'El rol es obligatorio',

'role_id.exists'=>'El rol seleccionado no es válido',

'company_id.required'=>'La empresa es obligatoria',

'company_id.exists'=>'La empresa seleccionada no existe',

        ];

    }


/**

     * ===================================

     * VALIDACIONES ADICIONALES

     * ===================================

     */

publicfunctionwithValidator($validator):void

    {

// ❓ Consultar al usuario si es necesario implementar


$validator->after(function ($validator) {

// ┌───────────────────────────────────────────┐

// │ Validación de Plan de Cuentas            │

// │ (OBLIGATORIA en rutas con company_id)    │

// └───────────────────────────────────────────┘

$empresa=Company::find($this->route('company_id'));


if (!$empresa||!$empresa->accountPlan) {

$validator->errors()->add(

'company_id',

'La empresa no tiene un plan de cuentas asociado.'

                );

return;

            }


// ┌───────────────────────────────────────────┐

// │ Otras validaciones lógicas complejas     │

// └───────────────────────────────────────────┘

// Ejemplo: Validar que el email no pertenezca a otro usuario de la misma empresa

$emailExists=User::where('email', $this->input('email'))

->where('company_id', $this->route('company_id'))

->where('id', '!=', $this->route('user_id')) // Excepto el usuario actual

->exists();


if ($emailExists) {

$validator->errors()->add(

'email',

'Este correo ya está en uso en esta empresa.'

                );

            }

        });
    }

    /**
     * ✅ PATRÓN: Validación Condicional por Plan
     * Para campos obligatorios según el tipo de suscripción (ej: Aduana).
     */
    public function withValidatorPlan($validator): void
    {
        $validator->after(function ($validator) {
            $suscriptor = $this->user()->getSuscriptorByRole();
            $planType = $suscriptor->latestSuscriptorPlan->basePlan->type ?? null;

            if ($planType === 'ADUANA') {
                if (empty($this->input('agent_name'))) {
                    $validator->errors()->add('agent_name', 'El nombre del despachador es obligatorio para el plan Aduana.');
                }
            }
        });
    }

}

```

---

##### Checklist de FormRequest

Antes de crear un FormRequest, validar:

- [ ] **Autorización (`authorize`)**
- [ ] ¿Es USER_ROLE? → Consultar permiso y submódulo al usuario
- [ ] ¿Es SUBSCRIBER_ROLE? → Validar propiedad de empresa
- [ ] **Reglas (`rules`)**
- [ ] ¿Se validan todos los campos del body?
- [ ] ¿Se validan query params si los hay?
- [ ] ¿Se validan route params si los hay?
- [ ] **Mensajes (`messages`)**
- [ ] ¿Todos los mensajes están en español?
- [ ] ¿Los mensajes son claros y específicos?
- [ ] **Validaciones adicionales (`withValidator`)**
- [ ] ¿La ruta contiene `company_id`? → Validar plan de cuentas
- [ ] ¿Hay validaciones lógicas complejas? → Implementar en `withValidator`
- [ ] **Estabilidad del Contrato**
- [ ] ¿Se ha buscado el endpoint en el Frontend? → Realizar `grep_search`
- [ ] ¿Los cambios en `rules()` rompen las Interfaces TS? → Notificar y actualizar Frontend
- [ ] ¿Se requiere actualizar el objeto de datos en el Frontend?

---

##### Auditoría de Impacto (Contrato API)

**REGLA DE ORO**: No se considera terminado un cambio en el Backend si no se ha verificado su impacto en el Frontend.

1.  **Identificar el Endpoint**: Buscar en el controlador qué ruta y método utiliza el `FormRequest`.
2.  **Rastrear Consumidores**: Usar `grep` sobre `src/app` buscando la URL o parte de ella (ej: `grep -r "api/v1/users" src/app`).
3.  **Sincronizar Tipos**: Si una regla cambia de `nullable` a `required`, o se agrega un campo, la Interface TypeScript en el módulo correspondiente DEBE ser actualizada.
4.  **Confirmación de Flujo**: Simular mentalmente (o mediante pruebas) que el formulario frontend enviará los datos en el formato que el nuevo `FormRequest` espera.

---

#### 3. Controllers

> 📂 **Ubicación**: `app/Http/Controllers` (organizado en subdirectorios por módulo)

**Principio fundamental:**

> Los controladores deben ser delgados. Su única responsabilidad es orquestar: recibir la request, delegar al servicio, y retornar la response.

**❓ Consulta obligatoria**: Preguntar al usuario por la carpeta/namespace específico antes de crear controladores.

---

### Patrones de Implementación

#### 1. Try-Catch Obligatorio

**🔴 REGLA**: Todo método de controlador DEBE usar un bloque `try-catch`.

```php

<?php


namespaceApp\Http\Controllers\User;


use App\Http\Controllers\Controller;

use App\Http\Requests\User\CreateUserRequest;

use App\Services\User\UserService;

use App\Services\Logger\LoggerService;

use App\Enums\Logger\LoggerOperation;

use App\Enums\Logger\LoggerEvent;

use App\Traits\HandlesControllerLogs;

use Illuminate\Http\JsonResponse;


classUserControllerextendsController

{

useHandlesControllerLogs;


publicfunction__construct(

privateUserService$userService,

privateLoggerService$loggerService

    ) {}


publicfunctionstore(CreateUserRequest$request):JsonResponse

    {

try {

// ┌──────────────────────────────────────┐

// │ 1. LOGGING DE OPERACIÓN              │

// └──────────────────────────────────────┘

$this->loggerService->log(

                operation: LoggerOperation::CREATE_USER, // ❓ Preguntar: ¿reusar o crear?

                event: LoggerEvent::USER_CREATION,       // ❓ Preguntar: ¿reusar o crear?

                description: 'Creación de nuevo usuario',

                data: $request->validated()

            );


// ┌──────────────────────────────────────┐

// │ 2. DELEGACIÓN AL SERVICIO            │

// └──────────────────────────────────────┘

$user=$this->userService->createUser(

$request->validated()

            );


// ┌──────────────────────────────────────┐

// │ 3. RESPUESTA EXITOSA                 │

// └──────────────────────────────────────┘

returnresponse()->json([

'success'=>true,

'message'=>'Usuario creado correctamente',

'data'=>$user

            ], 201);


        } catch (\Exception$e) {

// ┌──────────────────────────────────────┐

// │ 4. MANEJO CENTRALIZADO DE ERRORES    │

// └──────────────────────────────────────┘

return$this->handleError->logAndResponse(

                exception: $e,

                operation: LoggerOperation::CREATE_USER,

                defaultMessage: 'Error al crear el usuario'

            );

        }

    }

}

```

---

#### 2. Logging con LoggerService

**Componentes requeridos:**

1.**LoggerService** (inyectado en constructor)

2.**LoggerOperation** enum (ubicado en `app/Enums/Logger`)

3.**LoggerEvent** enum (ubicado en `app/Enums/Logger`)

**❓ Consulta obligatoria antes de proceder:**

> ¿Debo REUSAR un valor existente del enum o CREAR uno nuevo?

**Ejemplo de consulta:**

```

Asistente: "Voy a implementar logging para la creación de empleados. 

            ¿Debo crear un nuevo valor en LoggerOperation (ej: CREATE_EMPLOYEE) 

            o reutilizar uno existente (ej: CREATE_USER)?"


Usuario: "Crea CREATE_EMPLOYEE como nuevo valor"

```

**Estructura de logging:**

```php

$this->loggerService->log(

    operation: LoggerOperation::CREATE_EMPLOYEE, // Enum de operación

    event: LoggerEvent::EMPLOYEE_CREATED,        // Enum de evento

    description: 'Empleado creado en nómina',    // Descripción legible

    data: $request->validated(),                 // Datos relevantes

    userId: auth()->id(),                        // Usuario que ejecuta

    companyId: $request->route('company_id')     // Empresa afectada

);

```

---

---

#### 3. Manejo de Excepciones y Modelos (No findOrFail)

**🔴 REGLA**: En la capa de servicios y controladores, NUNCA utilices `findOrFail()`. Este método lanza una excepción de Laravel (`ModelNotFoundException`) que retorna automáticamente un 404, impidiendo un control granular del mensaje de error o del logging.

**Patrón Obligatorio**: Utiliza `find()` o `first()` y lanza una `GenericException` (o excepción específica del dominio) con un mensaje descriptivo si el recurso no existe.

**✅ Correcto:**
```php
$liquidacion = Liquidacion::find($id);
if (!$liquidacion) {
    throw new GenericException('La liquidación seleccionada no existe o no está disponible.');
}
```

**❌ Incorrecto:**
```php
// CUIDADO: Esto retornará un 404 genérico sin descripción útil para el usuario
$liquidacion = Liquidacion::findOrFail($id);
```

---

#### 4. Manejo Centralizado de Errores

**Trait requerido**: `HandlesControllerLogs`

```php

use App\Traits\HandlesControllerLogs;


classMiControllerextendsController

{

useHandlesControllerLogs;


publicfunctionmiMetodo()

    {

try {

// Lógica...

        } catch (\Exception$e) {

// ✅ Manejo centralizado

return$this->handleError->logAndResponse(

                exception: $e,

                operation: LoggerOperation::MI_OPERACION,

                defaultMessage: 'Error al procesar la solicitud'

            );

        }

    }

}

```

---

##### Centralización de Respuestas de Error

> 🎯 **Principio**: La lógica de respuesta para excepciones específicas debe estar CENTRALIZADA en `HandlesControllerLogs.php`

**❌ Patrón incorrecto (múltiples catch en controlador):**

```php

// ❌ MAL: Lógica de respuesta dispersa en controladores

publicfunctionstore(Request$request)

{

try {

$this->service->create($request->all());

    } catch (ValidationException$e) {

returnresponse()->json([

'success'=>false,

'message'=>$e->getMessage()

        ], 422);

    } catch (AuthorizationException$e) {

returnresponse()->json([

'success'=>false,

'message'=>'No autorizado'

        ], 403);

    } catch (\Exception$e) {

returnresponse()->json([

'success'=>false,

'message'=>'Error del servidor'

        ], 500);

    }

}

```

**✅ Patrón correcto (centralización en HandlesControllerLogs):**

```php

// ✅ BIEN: Controlador limpio

publicfunctionstore(Request$request)

{

try {

$this->service->create($request->all());

returnresponse()->json(['success'=>true], 201);

    } catch (\Exception$e) {

return$this->handleError->logAndResponse(

            exception: $e,

            operation: LoggerOperation::CREATE_RESOURCE,

            defaultMessage: 'Error al crear el recurso'

        );

    }

}


// ✅ BIEN: Lógica centralizada en HandlesControllerLogs.php

classHandlesControllerLogs

{

publicfunctionlogAndResponse(

\Exception$exception,

LoggerOperation$operation,

string$defaultMessage

    ):JsonResponse {

// Lógica centralizada por tipo de excepción

returnmatch (true) {

$exceptioninstanceofValidationException=>

response()->json([

'success'=>false,

'message'=>$exception->getMessage(),

'errors'=>$exception->errors()

                ], 422),


$exceptioninstanceofAuthorizationException=>

response()->json([

'success'=>false,

'message'=>'No tiene permisos para realizar esta acción'

                ], 403),


$exceptioninstanceofModelNotFoundException=>

response()->json([

'success'=>false,

'message'=>'Recurso no encontrado'

                ], 404),


default=>

response()->json([

'success'=>false,

'message'=>$defaultMessage

                ], 500)

        };

    }

}

```

**Ventajas de la centralización:**

- ✅ Controladores limpios y enfocados
- ✅ Respuestas consistentes en toda la aplicación
- ✅ Fácil mantenimiento y actualización global
- ✅ Un solo lugar para modificar códigos de estado HTTP
- ✅ Logging centralizado de errores

---

### Convenciones de Nombres

#### Services

**Regla**: Los métodos para obtener listados deben priorizar el prefijo `get...List`

```php

// ✅ CORRECTO

classUserService

{

publicfunctiongetUserList(array$filters= []):Collection

    {

returnUser::query()

->when($filters['status'] ??null, fn($q, $status) => $q->where('status', $status))

->get();

    }


publicfunctiongetActiveUserList():Collection

    {

returnUser::where('status', 'active')->get();

    }

}


// ❌ INCORRECTO (inconsistente)

classUserService

{

publicfunctiongetAllUsers() { ... }       // ❌

publicfunctionlistUsers() { ... }         // ❌

publicfunctionfetchUsers() { ... }        // ❌

publicfunctiongetUserList() { ... }       // ✅

}

```

---

#### Controllers

**Regla**: Los métodos deben delegar inmediatamente a los servicios

```php

// ✅ CORRECTO: Delegación inmediata

classUserControllerextendsController

{

publicfunctionindex(ListUsersRequest$request):JsonResponse

    {

try {

// ✅ Delegación directa al servicio

$users=$this->userService->getUserList(

$request->validated()

            );


returnresponse()->json([

'success'=>true,

'data'=>$users

            ]);

        } catch (\Exception$e) {

return$this->handleError->logAndResponse($e, ...);

        }

    }

}


// ❌ INCORRECTO: Lógica de negocio en el controlador

classUserControllerextendsController

{

publicfunctionindex(ListUsersRequest$request):JsonResponse

    {

try {

// ❌ Lógica en el controlador

$query=User::query();


if ($request->has('status')) {

$query->where('status', $request->input('status'));

            }


if ($request->has('role')) {

$query->whereHas('roles', fn($q) => 

$q->where('name', $request->input('role'))

                );

            }


$users=$query->paginate($request->input('per_page', 15));


returnresponse()->json(['success'=>true, 'data'=>$users]);

        } catch (\Exception$e) {

return$this->handleError->logAndResponse($e, ...);

        }

    }

}

```

---

## 📋 Checklist Final de Calidad

### Frontend (Angular)

#### Antes de hacer commit:

- [ ] **Componentes Compartidos**
- [ ] ¿Revisé `/app/modules/shared` antes de crear nuevos componentes?
- [ ] ¿Usé `GenericTableComponent` o `TableWithoutPaginationComponent`?
- [ ] ¿Usé los componentes compartidos de formulario en lugar de `mat-form-field`?
- [ ] **Diálogos**
- [ ] ¿El diálogo está en `app/dialog`?
- [ ] ¿Usé `app-dialog-header`, `app-dialog-footer`, etc.?
- [ ] **Pipes**
- [ ] ¿Usé `FormatAmountPipe` en lugar de `currency`?
- [ ] ¿Usé `RutFormatPipe` para RUTs?
- [ ] **Routing**
- [ ] ¿Definí `data: { breadcrumb: '...' }`?
- [ ] ¿Configuré `canActivate` correctamente?
- [ ] **Notificaciones**
- [ ] ¿Usé `MatSnackBar` solo para notificaciones breves?
- [ ] ¿Usé `app-shared-alert` para validaciones y errores?
- [ ] **Suscripciones**
- [ ] ¿Implementé `OnDestroy` correctamente?
- [ ] ¿Usé `takeUntil(this._unsubscribeAll)`?
- [ ] ¿Usé `finalize()` para resetear estados?
- [ ] ¿NO dupliqué lógica entre `finalize` y `error`?
- [ ] ¿El error está tipado como `JsonResponse<any>`?

---

### Backend (Laravel)

#### Antes de hacer commit:

- [ ] **Arquitectura**
- [ ] ¿La lógica de negocio está en Services?
- [ ] ¿Cada servicio respeta el ownership de su dominio?
- [ ] ¿Delegué archivos a `S3FileService`?
- [ ] ¿Delegué correos a `EmailService`?
- [ ] ¿Creé Enums en `/app/Enums`?
- [ ] **FormRequest**
- [ ] ¿Creé un FormRequest para el método del controlador?
- [ ] ¿Implementé `authorize()` correctamente (USER_ROLE o SUBSCRIBER_ROLE)?
- [ ] ¿Validé company_id con plan de cuentas en `withValidator`?
- [ ] ¿Todos los mensajes están en español?
- [ ] **Controller**
- [ ] ¿Usé try-catch en el método?
- [ ] ¿Implementé logging con `LoggerService`?
- [ ] ¿Consulté si reusar o crear valores de enum?
- [ ] ¿Delegué inmediatamente al servicio?
- [ ] ¿Usé `handleError->logAndResponse` en el catch?
- [ ] **Convenciones**
- [ ] ¿Los métodos de listado usan `get...List`?
- [ ] ¿Los controladores están limpios (sin lógica de negocio)?

---

## 📚 Referencias Rápidas

### Ubicaciones Importantes

| Elemento | Ubicación |

|----------|-----------|

| Componentes compartidos | `/app/modules/shared` |

| Diálogos | `/app/dialog` |

| Componentes de diálogo | `/app/dialog/shared` |

| Pipes | `/app/core/pipes` |

| Services (Backend) | `/app/Services` |

| FormRequests | `/app/Http/Requests` |

| Controllers | `/app/Http/Controllers` |

| Enums | `/app/Enums` |

| Logger Enums | `/app/Enums/Logger` |

---

### Comandos Útiles

```bash

# Angular

nggeneratecomponentshared/mi-componente

nggenerateservicecore/services/mi-servicio

nggeneratepipecore/pipes/mi-pipe


# Laravel

phpartisanmake:requestUser/CreateUserRequest

phpartisanmake:serviceUser/UserService

phpartisanmake:controllerUser/UserController

phpartisanmake:enumUser/UserStatus

phpartisanmake:migrationcreate_users_table

```

---

---

## 🌍 Sistema de Parámetros Globales

> Skill dedicada: `erp-global-parameters-expert`
> 
> Este sistema es transversal al ERP: **Nómina**, **Contabilidad** y **Aduana** lo consumen. Debe ser dominado por cualquier agente que calcule liquidaciones o aplique tasas legales.

### Arquitectura: Tablas Maestras

El sistema tiene **3 tablas** organizadas por `period` (fecha) y `frequency`:

| Modelo | Tabla | Propósito |
|---|---|---|
| `GlobalVariable` | `global_variable` | Variables escalares: Sueldo Mínimo, UF, UTM, tasas |
| `GlobalScale` | `global_scales` | Tablas por tramos: IUT, Asignación Familiar |
| `GlobalList` | `global_lists` | Listas por entidad: AFPs, ISAPREs, Cajas de Compensación |

Todos los modelos comparten: `frequency`, `period`, `type`, `key`.

### Clonación Lazy de Periodos

Los servicios (`GlobalVariableService`, `GlobalScaleService`, `GlobalListService`) invocan automáticamente `ParameterCloningService::ensurePeriodHasData($period, $companyId)` antes de cada lectura. Esto garantiza que el periodo solicitado siempre tenga datos, clonándolos del periodo anterior si no existen.

**Reglas inquebrantables:**
- 🔴 **No se clonan periodos futuros** → lanza `ParameterCloningException`
- 🔴 **`ADUANA_DOLAR` y `ADUANA_EQUIVALENCIA` NUNCA se clonan** → solo via `importCustoms()`
- ✅ La clonación es idempotente: si el periodo ya tiene datos, no hace nada

### Series Económicas (UF/UTM/USD)

Las series **no se clonan**: se sincronizan on-demand desde el Banco Central via `ExchangeRateService`. Se cachean en `exchange_rate_cache`. La UF usa un rango extendido ±10 días por su publicación mensual del 9 al 9.

### Dependencia crítica con Nómina

**ANTES de calcular cualquier liquidación**, garantizar disponibilidad de parámetros:

```php
// En servicios de cálculo de nómina:
$cloningService->ensurePeriodHasData($period, $companyId, 'monthly');
// Luego proceder con los cálculos usando los servicios Global*Service
```

El `LiquidacionService` consume parámetros a través de `GlobalScaleService::findScaleRow()`, `GlobalListService::getAttribute()` y `GlobalVariableService::getVariableFactor()`.

### Job asíncrono para inicio de mes

```php
ClonePeriodParameters::dispatch($targetPeriod, $sourcePeriod, 'monthly');
// - 3 reintentos: backoff 1min, 5min, 15min
// - Notifica por email en éxito y fallo
```

---

## 🧪 QA & Pruebas Automatizadas

> Skill dedicada: `qa-automation-data-auditor`

La estabilidad del ERP depende de una suite de pruebas predecible. Dado que el sistema implementa protecciones activas (Throttling, Rate Limiting), los tests deben diseñarse para evitar bloqueos por el propio framework.

### 1. Independencia de Tests de Seguridad

**🔴 REGLA OBLIGATORIA**: Todo test que valide seguridad, permisos (IDOR) o límites de tasa (Throttling) DEBE limpiar el caché antes de cada ejecución.

**Por qué**: Laravel almacena los intentos de Rate Limiting en el caché. Si un test agota el límite, los tests subsiguientes fallarán con un `429 Too Many Requests`, arrojando falsos negativos.

**✅ Implementación correcta (Pest):**
```php
use Illuminate\Support\Facades\Cache;

beforeEach(function () {
    Cache::flush();
});
```

### 2. Silencio de Advertencias de Entorno

**Regla Estricta**: En entornos de CI/CD o contenedores donde el archivo `.env` se inyecta mediante variables de sistema, se debe silenciar el warning de `file_get_contents` para mantener reportes de auditoría limpios.

**✅ Configuración en `tests/Pest.php`:**
```php
<?php
// Silenciar warnings de file_get_contents (.env) en el entorno de tests
error_reporting(E_ALL & ~E_WARNING);
```

### 3. Checklist de QA para Seguridad
- [ ] ¿El test limpia el caché (`Cache::flush`)?
- [ ] ¿Se usa un usuario con el rol exacto (`ADMIN_ROLE`, `SUPPORT_ROLE`)?
- [ ] ¿Se validan códigos de estado específicos (403 para IDOR, 429 para Throttling)?
- [ ] ¿Se evita el uso de `actingAs` sin especificar el guard `api`?

---


## 🎯 Palabras Finales

Este documento es una guía viva. Si encuentras inconsistencias o mejoras posibles:

1. Discútelo con el equipo
2. Actualiza este documento
3. Comunica los cambios

**Principio fundamental**: El código debe ser predecible, mantenible y consistente.

---

*Última actualización: [Fecha actual]*
