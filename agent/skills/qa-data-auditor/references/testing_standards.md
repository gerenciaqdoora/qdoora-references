## 🧪 Estándares de Testing Backend (Laravel 11 / Pest PHP)

1. **Pruebas de Capa de Servicio (Unitarias):** 
   - La lógica de negocio (`app/Services`) DEBE probarse exhaustivamente y de forma aislada.
   - **Mocking Obligatorio:** Servicios externos o de infraestructura como `S3FileService`, `EmailService` o llamadas a APIs (como el SII) DEBEN ser "mockeados" (simulados). JAMÁS permitas que una prueba unitaria interactúe con AWS S3 o envíe correos reales.
2. **Pruebas de API y Autorización (Feature) - REGLA DE ORO:** 
   - Cada endpoint del sistema ERP protegido DEBE tener pruebas de seguridad multi-tenant. 
   - Debes proveer e imponer tests en Pest que afirmen (`assert`) obligatoriamente el bloqueo de usuarios sin permisos correctos o de otras empresas.

### Ejemplo de Auditoría de Endpoint Seguro en Pest:

Todo endpoint creado por otras skills (Contabilidad, Nómina, etc.) DEBE ser verificado por un test similar a este:

```php
test('un usuario sin permiso de submódulo no puede acceder al recurso', function () {
    // 1. Arrange: Usuario autenticado sin permiso de "COMPRA" en su rol
    $user = User::factory()->create(['role' => 'USER_ROLE']);
    // Asignar empresa pero NO el submódulo
    // ...

    // 2. Act: Intentar consumir la ruta protegida
    $response = $this->actingAs($user, 'api')
                     ->getJson("/api/companies/{$company->id}/purchases");

    // 3. Assert: DEBE ser bloqueado por el FormRequest
    $response->assertStatus(403);
});

test('un usuario no puede acceder a los datos de otra empresa', function () {
    // 1. Arrange: Usuario de la Empresa A con permisos completos
    // Trata de leer datos de la Empresa B
    // ...

    // 2. Act
    $response = $this->actingAs($userA, 'api')
                     ->getJson("/api/companies/{$companyB->id}/purchases");

    // 3. Assert: Aislamiento multitenant
    $response->assertStatus(403);
});
```

## 📐 Estándares de Testing Frontend (Angular 18)

1. **Validación de UI/UX:** 
   - Asegúrate de que las pruebas verifiquen la presencia de los componentes compartidos obligatorios (ej. esperar que se renderice `app-shared-alert` cuando el backend retorna un error, uso estricto de `app-select-with-filter`).
2. **Pruebas de Fugas de Memoria (RxJS):** 
   - En pruebas de componentes complejos, verifica que el flujo pase por el bloque `finalize()` para limpiar el estado de carga (`isLoading = false`), asegurando que no queden suscripciones colgadas (memory leaks).
