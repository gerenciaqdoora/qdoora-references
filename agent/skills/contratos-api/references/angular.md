# Contratos en Angular (tipos generados + adaptador)

> Sin especificación OpenAPI en el proyecto: los tipos `*Api` se escriben a mano en un solo archivo
> por funcionalidad, junto a su adaptador, y los tests del adaptador fijan la forma esperada.

## Generar solo los tipos

Se generan **tipos**, no servicios. Los servicios HTTP se escriben a mano porque en ellos vive el
adaptador y la integración con el estado (signals, `resource`, RxJS).

```bash
npx openapi-typescript ../<backend>/openapi.json -o src/app/core/api/esquema.generado.ts
```

- Guardar el comando como script de `package.json` (ej. `"api:tipos"`).
- El archivo generado se commitea, no se edita a mano y lleva un comentario que lo indica.
- CI regenera y falla si hay diferencias: así un cambio del backend que rompe el frontend aparece
  como error de compilación y no en producción.

## Alias legibles

```ts
// core/api/tipos.ts
import type { components } from './esquema.generado';

type Esquemas = components['schemas'];
export type TareaApi = Esquemas['TareaSalidaDto'];
export type CrearTareaApi = Esquemas['CrearTareaDto'];
export type ProblemaApi = Esquemas['ProblemaDto'];
```

## Servicio de la funcionalidad con adaptador

```ts
// features/tareas/tareas.modelo.ts: el modelo que usa la UI
export interface Tarea {
  id: string;
  titulo: string;
  vence: Date | null;
  prioridad: Prioridad;
  vencida: boolean;
}

// features/tareas/tareas.adaptador.ts
export function aTarea(api: TareaApi, ahora = new Date()): Tarea {
  const vence = api.fechaVencimiento ? new Date(api.fechaVencimiento) : null;
  return { id: api.id, titulo: api.titulo, vence, prioridad: api.prioridad, vencida: !!vence && vence < ahora };
}

// features/tareas/tareas.service.ts
@Injectable({ providedIn: 'root' })
export class TareasService {
  private readonly http = inject(HttpClient);

  listar(consulta: { limite?: number; cursor?: string }): Observable<Pagina<Tarea>> {
    return this.http
      .get<ColeccionApi<TareaApi>>(`${API}/tareas`, { params: consulta })
      .pipe(map((c) => ({ elementos: c.elementos.map((t) => aTarea(t)), siguienteCursor: c.pagina.siguienteCursor })));
  }
}
```

- Los componentes consumen el servicio y el modelo de UI; nunca `HttpClient` ni los tipos `*Api`.
- El adaptador es una función pura con su propio test: es donde se detecta un cambio de forma.
- Conversiones típicas del adaptador: fechas a `Date`, decimales en string a número o a un tipo
  monetario, campos derivados para la vista, valores de enum desconocidos a un valor por defecto.

## Errores

```ts
export function esProblema(cuerpo: unknown): cuerpo is ProblemaApi {
  return typeof cuerpo === 'object' && cuerpo !== null && 'status' in cuerpo && 'title' in cuerpo;
}

export function mensajeDeError(error: HttpErrorResponse): string {
  if (error.status === 0) return 'No hay conexión con el servidor';
  if (esProblema(error.error)) return error.error.detail ?? error.error.title;
  return 'Ocurrió un error inesperado';
}
```

- Los errores de validación (`errores[]`) se mapean a los controles del formulario por `campo`.
- Durante una migración de formato, `mensajeDeError` acepta el formato antiguo y el nuevo.
- Nunca mostrar el cuerpo crudo del servidor.

## Concurrencia (ETag)

Pedir la respuesta completa (`observe: 'response'`) para leer `ETag`, guardarlo junto al recurso y
enviarlo en `If-Match` al modificar. Ante un `412`, recargar el recurso y avisar que otra persona lo
cambió.
