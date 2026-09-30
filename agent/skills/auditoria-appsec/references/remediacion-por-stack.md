# Remediación por stack

Patrones de referencia. Antes de proponer uno, verificar qué existe ya en el proyecto y adaptarlo a
sus nombres, idioma y convenciones.

## NestJS

**Cerrado por defecto con guard global y rutas públicas explícitas**
```ts
// módulo de auth
providers: [{ provide: APP_GUARD, useClass: AccesoGuard }]

// decorador
export const CLAVE_PUBLICO = 'publico';
export const Publico = () => SetMetadata(CLAVE_PUBLICO, true);
```

**Rol en el servidor (BFLA)**
```ts
export const Roles = (...roles: Rol[]) => SetMetadata(CLAVE_ROLES, roles);

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}
  canActivate(ctx: ExecutionContext): boolean {
    const requeridos = this.reflector.getAllAndOverride<Rol[]>(CLAVE_ROLES, [ctx.getHandler(), ctx.getClass()]);
    if (!requeridos?.length) return true;
    const { persona } = ctx.switchToHttp().getRequest<{ persona?: { rol: Rol } }>();
    return persona !== undefined && requeridos.includes(persona.rol);
  }
}
```

**Pertenencia del recurso (BOLA/IDOR):** filtrar en la consulta, no después de traer el registro.
```ts
const nota = await this.repo.findOne({ where: { id, duenoId: persona.id } });
if (!nota) throw new NotFoundException(); // 404 y no 403: no confirmar que existe
```

**Lista blanca de entrada:** `ValidationPipe` global con `whitelist: true`,
`forbidNonWhitelisted: true` y `transform: true`. Los campos sensibles (`rol`, `duenoId`) no
existen en el DTO de entrada.

**Salida explícita:** DTO de respuesta construido a mano o con `plainToInstance` +
`excludeExtraneousValues`; nunca devolver la entidad.

**Errores saneados:** filtro global `@Catch()` que registra el detalle internamente y responde un
cuerpo uniforme sin mensaje interno en los 500.

**Límite de uso:** `@nestjs/throttler` con límites más estrictos en login, envío de correo,
exportaciones y rutas que llaman a un LLM.

**Cabeceras en Fastify:** `@fastify/helmet`; CORS con `origin` explícito y `credentials: true` solo
para el origen del frontend.

**SQL:** parámetros siempre (`where('x = :x', { x })`); nunca interpolar en `query()`.

## Angular

- **Sin `innerHTML` con datos del servidor.** Si es inevitable, sanitizar y nunca usar
  `bypassSecurityTrustHtml` con contenido de usuarios.
- **Cookies de sesión:** `withCredentials: true` en un interceptor, solo hacia el origen de la API.
  No guardar tokens en `localStorage`.
- **Guards de ruta y directiva de rol:** solo mejoran la experiencia; el control real está en el
  servidor.
- **Errores:** traducir a mensajes amigables; nunca mostrar el cuerpo crudo del servidor.
- **CSP:** sin `unsafe-inline` para scripts; Angular es compatible con CSP estricta usando `nonce`.

## Python (FastAPI)

- Dependencias de seguridad (`Depends`) en el router, no en cada función; rutas públicas explícitas.
- Modelos Pydantic de entrada con `extra='forbid'`; modelos de respuesta con `response_model`.
- Consultas filtradas por dueño en SQLAlchemy; nunca `text()` con f-strings.

## Laravel

- `Gate`/`Policy` en cada acción; `authorizeResource` en controladores de recursos.
- `$fillable` estricto; `FormRequest` para validar.
- Scope global de tenant (`addGlobalScope`) y verificación en descargas de archivos.
- `APP_DEBUG=false` fuera de local; middleware `throttle` en rutas sensibles.

## Infraestructura

- Base de datos y servicios internos sin puertos publicados al host en producción.
- Contenedores sin root y con sistema de archivos de solo lectura cuando sea posible.
- Secretos por variables de entorno inyectadas o un gestor de secretos; nunca en la imagen.
- Buckets u objetos de almacenamiento privados; URLs firmadas de corta duración.
