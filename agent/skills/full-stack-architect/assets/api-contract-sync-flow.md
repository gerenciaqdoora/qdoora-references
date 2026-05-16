# Flujo de Sincronización de Contratos API

> El estándar innegociable para asegurar la integridad Full-Stack.

## 🔄 Secuencia de Ejecución

1.  **Definición en Backend**:
    - Crear/Modificar el `FormRequest` en Laravel.
    - Definir reglas (`required`, `nullable`, `exists`).
2.  **Activación de Aligner**:
    - Invocar `api-contract-aligner/SKILL.md`.
    - Comparar el `FormRequest` con la interface de Angular en `core/models`.
3.  **Mapeo de Tipos**:
    | Laravel | TypeScript |
    | :--- | :--- |
    | `required` | `field: type;` |
    | `nullable` | `field?: type;` |
    | `string` / `email` | `string` |
    | `integer` / `numeric` | `number` |
    | `boolean` | `boolean` |
4.  **Validación de Consumo**:
    - Verificar que los componentes que consumen la interface no tengan errores de tipado (TS2322).
5.  **Prueba de Integridad**:
    - Realizar un test de integración o validación manual del flujo completo.

---

> [!IMPORTANT]
> Un cambio en el Backend sin sincronizar el Frontend se considera una deuda técnica inmediata.
