# Guía de Autoría de Pasos — Tours Guiados QdoorA

Cómo pasar de "esta pantalla necesita un tour" a una propuesta de secciones que el usuario apruebe en la primera o segunda iteración.

## 1. Derivar las secciones del HTML, no de la imaginación

Las secciones de un tour **son los bloques conceptuales que ya existen** en la vista. Orden de preferencia para elegir el ancla:

1. `<app-section-card>` — ya representan una agrupación semántica y tienen título propio (caso `company-tour`).
2. Tarjetas contenedoras `bg-card ... rounded-2xl|3xl` — el patrón de las vistas de permisos (`role-create-tour`, `user-update-tour`).
3. Sidebars / `mat-drawer` — el panel de filtros o navegación lateral suele merecer su propio paso porque no es obvio que sea un filtro.
4. `<div>` agrupador de campos relacionados (ej. `#tour-user-personal` envolviendo RUT + nombre + apellido).

**Nunca** ancles sobre un `<app-input-form>` individual, un `<button>` suelto o una celda de tabla: el popover queda descuadrado y el usuario pierde el contexto del bloque.

### Nomenclatura de anclas

`id="tour-<dominio>-<bloque>"`, en inglés kebab-case, único en todo el DOM de la vista:

```
#tour-info-basica        #tour-user-avatar       #tour-role-name
#tour-info-tributaria    #tour-user-personal     #tour-role-modules
#tour-info-geografica    #tour-user-email        #tour-role-permissions
```

(El repo mezcla español e inglés en el sufijo por historia; mantén la coherencia con las anclas ya presentes en la misma vista.)

## 2. Cuántos pasos

**3 a 6.** Es el rango de los tours en producción (avatar/datos/correo = 3; empresa = 5).

- **< 3**: no justifica un tour; probablemente basta el `description` de un `app-section-card`.
- **> 6**: el usuario abandona, y como `onDestroyStarted` marca el tour como completado, **no habrá segunda oportunidad automática**. Si la pantalla realmente necesita más, propón al usuario partirlo en dos tours (ej. "Crear rol" y "Matriz de permisos avanzada").

## 3. Orden = flujo real de llenado

Recorre la pantalla como la recorre el usuario: arriba→abajo, izquierda→derecha, respetando la columna principal antes que la lateral. Si el formulario tiene una dependencia (elegir empresa antes de ver sus permisos), el tour debe seguir esa misma dependencia.

Regla práctica: si el paso N+1 no se entiende sin haber hecho lo del paso N, el orden es correcto.

## 4. Redacción del copy (español, usuario final)

**`title`** — 1 a 3 palabras, sustantivo, capitalización de título: `Información Básica`, `Datos Personales`, `Matriz de Permisos`.

**`description`** — 1 a 3 frases. La regla es explicar el **por qué / la consecuencia**, no describir lo que ya se ve:

| ❌ Describe lo evidente | ✅ Explica la consecuencia |
|---|---|
| "Aquí se ingresa el correo electrónico." | "Ingresa la dirección de correo. Es un requisito fundamental del aplicativo, ya que debe ser único por usuario del sistema y servirá para el acceso y notificaciones." |
| "Selecciona un rol." | "Puedes seleccionar un rol para que herede automáticamente su matriz de permisos. Ten en cuenta que dentro de la barra de navegación se pueden crear roles para facilitar la asignación de permisos de los módulos contratados." |
| "Este es el panel lateral." | "En esta barra lateral aparecen las empresas y los módulos contratados. Al seleccionarlos, funcionarán como filtro para gestionar la matriz de permisos en el panel central." |

Otras reglas de copy:
- Tutea al usuario (`Ingresa`, `Configura`, `Ten en cuenta`) — es el registro ya usado en todo el repo.
- Menciona explícitamente lo **condicional**: "solo aparecerá si los módulos correspondientes están activos" (caso Certificado Digital de `company-tour`).
- Advierte los **efectos colaterales**: "los cambios aquí solo afectarán la matriz de permisos de los roles asignados".
- Sin jerga técnica de implementación (nada de "endpoint", "payload", "FormRequest").
- Sin HTML en `description` — es texto plano interpolado por driver.js.

## 5. Elegir `side` y `align`

`side` indica dónde se dibuja el popover **respecto del elemento resaltado**. Elígelo según la posición del bloque en el layout:

| Posición del bloque | `side` recomendado | Razón |
|---|---|---|
| Columna izquierda / principal | `right` | El popover cae sobre el espacio libre de la derecha |
| Columna derecha / sidebar | `left` | Simétrico al anterior |
| Bloque ancho al inicio de la vista | `bottom` | Deja ver el encabezado |
| Bloque ancho al final / tabla larga | `top` | Evita que el popover quede fuera del viewport |

`align` (`start`/`center`/`end`) es opcional; los tours actuales no lo usan. Úsalo solo si el bloque es muy alto y el popover queda visualmente perdido.

Si el bloque ocupa el ancho completo, prefiere `top`/`bottom` — `left`/`right` no tendrán espacio y driver.js reposicionará por su cuenta.

## 6. Bloques condicionales (`@if`)

driver.js resuelve el selector **en el instante del paso**. Si el bloque está detrás de estado del componente, tienes tres opciones, en este orden de preferencia:

**A. Excluirlo del tour.** Lo más simple y robusto si el bloque es accesorio.

**B. Mencionarlo desde un paso vecino.** Es lo que hace `company-tour` con el Certificado Digital: se ancla al bloque y el copy aclara que "solo aparecerá si los módulos correspondientes están activos".

**C. Revelarlo programáticamente** con `actionBeforeNext` + `delayBeforeNext` (patrón real de `user-update-tour`):

```typescript
{
    element: '#tour-user-company-permissions',
    popover: { title: 'Permisos de Empresa', description: '...', side: 'top' },
    actionBeforeNext: () => {
        const moduleListContainer = document.querySelector('#tour-module-list');
        if (moduleListContainer) {
            const firstBtn = moduleListContainer.querySelector('button') as HTMLElement;
            if (firstBtn) firstBtn.click();
        }
    },
    delayBeforeNext: 250 // Dar tiempo suficiente a Angular para renderizar
},
{
    element: '#tour-user-module-permissions',
    popover: { title: 'Permisos de Submódulos', description: '...', side: 'top' },
    actionBeforePrev: () => {
        // Si el usuario regresa al paso anterior, restauramos el estado
        const sidebarCards = document.querySelectorAll('#tour-user-sidebar button');
        if (sidebarCards.length > 0) { (sidebarCards[0] as HTMLElement).click(); }
    },
    delayBeforePrev: 250
}
```

Reglas de la opción C:
- Siempre implementa **también** el par `actionBeforePrev`/`delayBeforePrev`: sin él, retroceder deja la pantalla en un estado donde el paso anterior ya no existe y el tour se rompe.
- Usa guardas (`if (el)`) — el DOM puede no estar listo.
- `delay` de 200-250 ms es lo probado; no bajes de 200.
- Ancla el contenedor que **sí** existe siempre (`#tour-module-list`, `#tour-user-sidebar`) para buscar dentro de él, en vez de hacer `querySelector` global.

## 7. Plantilla de la propuesta al usuario (paso 2 del flujo)

```markdown
## Tour propuesto: "<Título>" (`<key>`)
Ruta: `/general/...`  ·  Sección del Centro de Ayuda: `tours-...`  ·  Modo: crear | refinar

| # | Sección | Ancla | side | Qué explica |
|---|---------|-------|------|-------------|
| 1 | Datos Personales | `#tour-x-personal` (div existente, línea 55) | right | Que el RUT valida dígito verificador y no se puede cambiar después |
| 2 | ... | ... | ... | ... |

**Decisiones abiertas**
- El bloque "Certificado Digital" solo se renderiza si el módulo está activo. ¿Lo incluimos con `actionBeforeNext`, lo mencionamos desde el paso 3, o lo dejamos fuera?
- ¿El tour debe dispararse automáticamente al entrar, o solo desde el Centro de Ayuda?
```

Después de esta tabla: **DETENTE**. No edites archivos hasta la aprobación.

## 8. Refinar un tour existente

- **Parte del array actual**, paso por paso; no lo reescribas de cero (pierdes copy que ya fue aprobado por el negocio).
- Cambiar `title`/`description`/`order` en el seeder es seguro (`updateOrCreate` por `key`).
- **Nunca cambies la `key`**: las filas de `user_tours` quedan huérfanas y el tour reaparece automáticamente para todos los usuarios que ya lo vieron.
- Si agregas pasos a un tour que la mayoría ya completó, avisa al usuario: solo lo verán quienes lo relancen desde el Centro de Ayuda.
- Al eliminar un paso, borra también su `id="tour-*"` del HTML si nadie más lo usa.
- Verifica que cada `element` del registry siga existiendo en el HTML después de cualquier refactor de la vista — es el modo más común de que un tour se degrade en silencio.
