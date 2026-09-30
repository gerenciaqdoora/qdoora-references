# Contratos en FastAPI

FastAPI genera OpenAPI desde los modelos Pydantic de forma nativa: la opción natural es code-first.

## Entrada y salida

```python
class CrearTarea(BaseModel):
    model_config = ConfigDict(extra="forbid")  # lista blanca: rechaza campos no declarados

    titulo: str = Field(min_length=1, max_length=200)
    fecha_vencimiento: date | None = None


class TareaSalida(BaseModel):
    id: UUID
    titulo: str
    fecha_vencimiento: date | None


@router.post("/tareas", status_code=201, response_model=TareaSalida,
             responses={422: {"model": Problema}, 404: {"model": Problema}})
async def crear_tarea(datos: CrearTarea, ...) -> TareaSalida: ...
```

- `response_model` filtra lo que no está declarado: nunca devolver el modelo ORM tal cual.
- Dinero: `Decimal` serializado como string (`Annotated[Decimal, PlainSerializer(str)]`).

## Errores RFC 9457

```python
@app.exception_handler(RequestValidationError)
async def validacion(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        media_type="application/problem+json",
        content={
            "type": "about:blank",
            "title": "La solicitud tiene datos inválidos",
            "status": 422,
            "detail": "Revisa los campos marcados.",
            "instance": request.url.path,
            "errores": [{"campo": ".".join(map(str, e["loc"][1:])), "mensaje": e["msg"]} for e in exc.errors()],
        },
    )
```

Handlers equivalentes para `HTTPException` y un `Exception` genérico (500 sin detalle).

Nota: FastAPI responde por defecto `{"detail": ...}` (con un arreglo en validación). Migrar a RFC
9457 es un cambio incompatible para los clientes: coordinarlo (ver `convenciones-http.md`).

## Especificación

- Exportar: `json.dump(app.openapi(), archivo)` en un script; commitear y comparar en CI.
- Paginación: `limite: Annotated[int, Query(ge=1, le=100)] = 25`.
