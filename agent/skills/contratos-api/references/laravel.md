# Contratos en Laravel

## Entrada: FormRequest

```php
class CrearTareaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', [Tarea::class, $this->route('proyecto')]);
    }

    public function rules(): array
    {
        return [
            'titulo' => ['required', 'string', 'max:200'],
            'fecha_vencimiento' => ['nullable', 'date_format:Y-m-d'],
            'prioridad' => ['required', Rule::enum(Prioridad::class)],
        ];
    }
}
```

- Usar `$request->validated()`, nunca `$request->all()`: es la lista blanca contra mass assignment.
- `$fillable` estricto en el modelo como segunda barrera.

## Salida: API Resources

```php
class TareaResource extends JsonResource
{
    public static $wrap = null; // sin sobre { data } en recursos individuales

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'titulo' => $this->titulo,
            'fecha_vencimiento' => $this->fecha_vencimiento?->toDateString(),
            'prioridad' => $this->prioridad->value,
        ];
    }
}
```

- Nunca devolver el modelo Eloquent directo: expone columnas nuevas sin querer.
- Colecciones: por defecto Laravel envuelve en `{ data, links, meta }`. Si el proyecto adopta
  `{ elementos, pagina }`, crear una `ResourceCollection` propia con `paginationInformation()` o un
  helper; si ya usa el formato de Laravel, mantenerlo (la regla es no mezclar).
- Paginación por cursor: `->cursorPaginate($limite)` (keyset nativo). Tope: `min($request->integer('limite', 25), 100)`.

## Errores RFC 9457

En `bootstrap/app.php` (Laravel 11+):

```php
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->render(function (ValidationException $e, Request $request) {
        if (! $request->expectsJson()) return null;
        return response()->json([
            'type' => 'about:blank',
            'title' => 'La solicitud tiene datos inválidos',
            'status' => 422,
            'detail' => 'Revisa los campos marcados.',
            'instance' => '/'.$request->path(),
            'errores' => collect($e->errors())->flatMap(
                fn ($mensajes, $campo) => collect($mensajes)->map(fn ($m) => ['campo' => $campo, 'mensaje' => $m])
            )->values(),
        ], 422, ['Content-Type' => 'application/problem+json']);
    });
})
```

Repetir el patrón para `NotFoundHttpException`, `AuthorizationException` y un caso genérico
para lo inesperado (500 sin detalle, con `APP_DEBUG=false` fuera de local).

## Especificación

- **Scramble** (`dedoc/scramble`) genera OpenAPI desde FormRequests y Resources sin anotaciones;
  **L5-Swagger** usa anotaciones. Exportar a un archivo commiteado (ej. `php artisan scramble:export`)
  y compararlo en CI.
- Sin especificación: tests de contrato con `assertJsonStructure` y `assertExactJson` sobre los
  endpoints, incluidos los errores.

## Concurrencia e idempotencia

- ETag: middleware que calcula el `ETag` (desde `updated_at` o una columna `version`) y compara
  `If-Match`; responde 412 si no coincide.
- `Idempotency-Key`: middleware que guarda clave + respuesta en caché o tabla por 24 h.
