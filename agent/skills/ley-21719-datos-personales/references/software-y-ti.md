# Privacidad desde el diseño en software, datos e IA

Aplica los arts. 3 (principios), 14 quáter (diseño y por defecto), 14 quinquies (seguridad),
8 bis (decisiones automatizadas) y 10–11 (derechos) a sistemas concretos.

## Mapeo obligación → práctica de ingeniería

| Obligación | Práctica | Evidencia |
|------------|----------|-----------|
| Finalidad y proporcionalidad (3 b, c) | Cada campo del modelo de datos tiene una finalidad documentada; no recolectar "por si acaso" | Diccionario de datos con finalidad y base por campo |
| Por defecto (14 quáter) | Configuración más restrictiva por defecto; campos opcionales realmente opcionales; visibilidad mínima | Revisión de formularios y valores por defecto |
| Conservación (3 c) | Jobs de **retención y borrado/anonimización** automáticos; TTL; borrado en respaldos según su ciclo | Código del job, logs de ejecución |
| Seudonimización y cifrado (14 quinquies a) | Cifrado en reposo y tránsito; identificadores seudónimos en analítica; tokenización | Configuración, ADRs |
| Acceso mínimo | Roles, autorización por recurso, auditoría de accesos a datos personales | Matriz de roles, logs de auditoría |
| Datos de prueba (3 b, c; 14 quinquies) | **Nunca datos reales** en desarrollo/QA; datos sintéticos o anonimizados | Scripts de semillas, política |
| Logs (3 c; 14 quinquies) | No registrar datos personales innecesarios (RUT, correos, tokens, payloads completos) en logs; enmascarar | Revisión de logging, pruebas |
| Derechos (10, 11) | Funciones para **buscar, exportar (JSON/CSV), rectificar, suprimir y bloquear** los datos de un titular en todos los sistemas | Endpoints/backoffice, pruebas |
| Bloqueo (8 ter, 11) | Marca de bloqueo que impida el tratamiento sin borrar | Campo de estado + controles en servicios |
| Portabilidad (9) | Exportación estructurada de lo que el titular aportó | Función de exportación |
| Consentimiento (12) | Registro de consentimientos: titular, versión del texto, finalidades, fecha, canal; revocación en un clic | Tabla de consentimientos, UI |
| Decisiones automatizadas (8 bis) | Identificar modelos que deciden sobre personas; explicación, **revisión humana**, canal de impugnación | Documentación del modelo, flujo de revisión |
| Transparencia (14 ter) | Aviso en capas en cada punto de recolección; enlace a política | UI |
| NNA (16 quáter) | Verificación de edad proporcional, consentimiento parental < 14 | Flujo de registro |
| Encargados y transferencias (15 bis, 27) | Inventario de servicios externos que reciben datos (cloud, correo, analítica, **APIs de IA**, errores/APM) | Lista de subprocesadores con país y contrato |
| Brechas (14 sexies) | Monitoreo, alertas, capacidad de determinar **qué datos y cuántos titulares** afectó un incidente | Logs, inventario de datos por sistema |

## IA y modelos de lenguaje

- Enviar datos personales a una API de IA es **tratamiento**, normalmente vía **encargado** y, si el proveedor está fuera de Chile, **transferencia internacional**.
- Minimizar y **seudonimizar** antes de enviar; nunca enviar datos sensibles sin base y análisis.
- Verificar retención y **no uso para entrenamiento** por el proveedor.
- Si el sistema **decide o recomienda** sobre personas (scoring, selección de postulantes, priorización), aplicar art. 8 bis y evaluar **EIPD** (art. 15 ter a).
- Registrar prompts/respuestas con datos personales solo si es necesario, con retención corta y acceso restringido.

## Cookies, analítica y seguimiento

La ley no regula las cookies específicamente, pero:
- Identificadores de dispositivo, IP y perfiles de navegación pueden ser **datos personales** (art. 2 f).
- El **monitoreo del comportamiento** de personas en Chile activa la aplicación territorial (art. 1° bis c) y la definición de **perfilamiento** (art. 2 w).
- Marketing y perfilamiento dan **derecho de oposición** (art. 8 b).
- Recomendación: analítica sin identificación directa cuando sea posible; consentimiento para seguimiento publicitario; informar en la política.

## Checklist rápido para un repositorio o feature

- [ ] ¿Hay datos personales reales en el repositorio (semillas, fixtures, dumps, CSV, capturas)? — historial incluido.
- [ ] ¿Cada nueva columna/campo con datos personales tiene finalidad, base y plazo definidos?
- [ ] ¿Existe job de retención que borre o anonimice al vencer el plazo?
- [ ] ¿Los logs y errores (APM) excluyen o enmascaran datos personales?
- [ ] ¿Cifrado en tránsito y reposo; secretos fuera del código?
- [ ] ¿Autorización por recurso que impida ver datos de otros titulares (IDOR)?
- [ ] ¿Se puede buscar, exportar, rectificar, bloquear y suprimir todo lo de un titular?
- [ ] ¿Los formularios muestran aviso de privacidad y no tienen casillas premarcadas?
- [ ] ¿Qué servicios externos reciben datos? ¿Están en el inventario de encargados y transferencias?
- [ ] ¿Hay decisiones automatizadas sobre personas? ¿Revisión humana?
- [ ] ¿Se trata algún dato sensible (salud, biométrico, socioeconómico) o de menores?
- [ ] ¿Ambientes de desarrollo y pruebas sin datos reales?
- [ ] ¿Se puede determinar qué datos y cuántos titulares afecta un incidente en este sistema?
