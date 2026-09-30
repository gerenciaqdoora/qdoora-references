# Contratos en NestJS (code-first)

## Plugin de Swagger

En `nest-cli.json`, el plugin infiere `@ApiProperty` desde los tipos de TypeScript y los decoradores
de `class-validator`, y lee los comentarios JSDoc:

```json
"plugins": [
  { "name": "@nestjs/swagger", "options": { "introspectComments": true, "classValidatorShim": true } }
]
```

Aun con el plugin, declarar explícitamente lo que no se puede inferir: respuestas de error, enums
con nombre, genéricos y uniones.

## DTOs

```ts
/** Datos para crear una tarea. */
export class CrearTareaDto {
  /** Título visible de la tarea. */
  @IsString() @MaxLength(200)
  titulo!: string;

  @IsOptional() @IsISO8601({ strict: true })
  fechaVencimiento?: string;

  @IsEnum(Prioridad)
  @ApiProperty({ enum: Prioridad, enumName: 'Prioridad' }) // enumName evita un enum anónimo por DTO
  prioridad!: Prioridad;
}

export class TareaSalidaDto {
  id!: string;
  titulo!: string;
  fechaVencimiento!: string | null;
  prioridad!: Prioridad;
}
```

- Entrada y salida son clases distintas. La salida nunca es la entidad.
- Para `PATCH`: `export class ActualizarTareaDto extends PartialType(CrearTareaDto) {}` (de `@nestjs/swagger`).
- `ValidationPipe` global con `whitelist`, `forbidNonWhitelisted` y `transform`.

## Respuestas documentadas

```ts
@ApiTags('tareas')
@Controller('tareas')
export class TareasController {
  @Post()
  @ApiCreatedResponse({ type: TareaSalidaDto })
  @ApiUnprocessableEntityResponse({ type: ProblemaDto })
  @ApiNotFoundResponse({ type: ProblemaDto, description: 'El proyecto no existe o no es tuyo' })
  crear(@Body() dto: CrearTareaDto): Promise<TareaSalidaDto> { ... }
}
```

Para no repetir los errores en cada endpoint, crear un decorador compuesto con `applyDecorators`
(ej. `@RespuestasDeError(422, 404)`).

## Problem Details (RFC 9457)

```ts
export class ErrorCampoDto {
  campo!: string;
  mensaje!: string;
}

export class ProblemaDto {
  type!: string;
  title!: string;
  status!: number;
  detail?: string;
  instance?: string;
  errores?: ErrorCampoDto[];
}
```

En el filtro global de excepciones:

```ts
httpAdapter.setHeader(respuesta, 'content-type', 'application/problem+json');
httpAdapter.reply(respuesta, problema, problema.status);
```

- Los `HttpException` conocidos se traducen a su `type`/`title`.
- Los errores de validación los arma la `exceptionFactory` del `ValidationPipe` en `errores[]`.
- Lo desconocido responde un `500` genérico y registra el detalle con el identificador de petición.

## Colecciones paginadas (genérico)

```ts
export class PaginaCursorDto {
  limite!: number;
  siguienteCursor!: string | null;
  hayMas!: boolean;
}

export class ColeccionDto<T> {
  elementos!: T[];
  pagina!: PaginaCursorDto;
}

export const ApiColeccion = <M extends Type<unknown>>(modelo: M) =>
  applyDecorators(
    ApiExtraModels(ColeccionDto, modelo),
    ApiOkResponse({
      schema: {
        allOf: [
          { $ref: getSchemaPath(ColeccionDto) },
          { properties: { elementos: { type: 'array', items: { $ref: getSchemaPath(modelo) } } } },
        ],
      },
    }),
  );
```

Y el DTO de consulta con límite por defecto y máximo:

```ts
export class ConsultaCursorDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100)
  limite = 25;

  @IsOptional() @IsString()
  cursor?: string;
}
```

## Exportar la especificación al repositorio

Un script que arma la aplicación sin escuchar el puerto y escribe el archivo:

```ts
// scripts/exportar-openapi.ts
const app = await NestFactory.create<NestFastifyApplication>(AppModule, new FastifyAdapter(), { logger: false });
configurarApp(app);                       // la misma configuración que main.ts
const documento = SwaggerModule.createDocument(app, configuracionSwagger);
writeFileSync('openapi.json', JSON.stringify(documento, null, 2) + '\n');
await app.close();
```

- Se ejecuta en cada cambio de contrato y en CI; CI falla si el archivo generado difiere del commiteado.
- Si armar la aplicación exige base de datos u otros servicios, usar un módulo de prueba o
  sobrescribir esos proveedores: el script no debe depender de infraestructura.
- Detectar cambios incompatibles: `oasdiff breaking openapi.base.json openapi.json` contra la
  versión de la rama principal.
