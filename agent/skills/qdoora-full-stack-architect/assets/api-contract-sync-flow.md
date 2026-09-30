# Flujo de Sincronización de Contratos API

> El estándar innegociable para asegurar la integridad Full-Stack.

## 🔄 Secuencia de Ejecución

1.  **Definición en Backend**:
    - Crear/Modificar el `FormRequest` en Laravel.
    - Definir reglas (`required`, `nullable`, `exists`).
2.  **Alineación del contrato** (principios generales en la skill `contratos-api`):
    - Identificar la ruta y el método HTTP del controlador asociado.
    - Buscar los consumidores con `grep` de la URL del endpoint en `fuse-starter/src/app` (y en `support-portal/src/app` si aplica).
    - Comparar el `FormRequest` con la interface de Angular en `core/models/request` o `core/models/data`.
    - Toda modificación en un extremo exige revisar el otro: no existe el cambio "aislado".
3.  **Mapeo de Tipos**:
    | Laravel | TypeScript |
    | :--- | :--- |
    | `required` | `field: type;` |
    | `nullable` | `field?: type;` |
    | `string` / `email` | `string` |
    | `integer` / `numeric` | `number` |
    | `boolean` | `boolean` |
    | `exists` / `in` | Evaluar un `enum` o un tipo de unión literal (ej. `'active' \| 'inactive'`) |
4.  **Validación de Consumo**:
    - Verificar que los componentes que consumen la interface no tengan errores de tipado (TS2322).
5.  **Prueba de Integridad**:
    - Realizar un test de integración o validación manual del flujo completo.

---

> [!IMPORTANT]
> Un cambio en el Backend sin sincronizar el Frontend se considera una deuda técnica inmediata.
