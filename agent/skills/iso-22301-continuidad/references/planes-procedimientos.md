# Planes y procedimientos de continuidad (§8.4)

Guías: ISO 22313, **ISO/TS 22332** (planes y procedimientos), **ISO 22361** (gestión de crisis),
**ISO 22320** (gestión de emergencias), **ISO/IEC 27031** (preparación TIC).

## 1. Estructura de respuesta (§8.4.2)

Arquitectura habitual de tres niveles (adaptar al tamaño):

| Nivel | Equipo | Responsabilidad |
|-------|--------|-----------------|
| Estratégico | **Comité de crisis** (alta dirección) | Decisiones mayores, recursos, comunicación externa de alto nivel, reguladores, medios |
| Táctico | Equipo de gestión del incidente / coordinador de continuidad | Evaluar, activar planes, coordinar equipos, reportar |
| Operativo | Equipos de continuidad por área, equipo TIC de recuperación, equipo de emergencias | Ejecutar procedimientos, operar soluciones alternas, restaurar sistemas |

Para cada rol: titular, **al menos un suplente**, autoridad (qué puede decidir y gastar sin
consultar), competencias, formas de contacto (incluidas alternativas).

### Ciclo de respuesta
```
Detección → Alerta → Evaluación (naturaleza, alcance, impacto vs umbrales) → Activación
→ Priorización (vida primero) → Implementación de soluciones → Monitoreo → Comunicación continua
→ Desactivación → Recuperación → Revisión post-incidente
```

### Umbrales de activación (ejemplo)
| Nivel | Criterio | Quién activa |
|-------|----------|--------------|
| 1 — Incidente | Afecta una actividad, recuperable dentro de su RTO con medios normales | Dueño de la actividad |
| 2 — Disrupción mayor | Afecta actividades prioritarias o se proyecta superar el RTO | Coordinador de continuidad |
| 3 — Crisis | Amenaza objetivos estratégicos, vidas, reputación o cumplimiento regulatorio | Comité de crisis |

## 2. Advertencia y comunicación (§8.4.3)

Plan de comunicaciones con:
- **Matriz de partes interesadas:** personal, clientes, proveedores, reguladores, autoridades, servicios de emergencia, medios, accionistas, comunidad.
- Para cada una: qué se comunica, quién es el vocero autorizado, canal principal y alternativo, momento (inicial, actualizaciones, cierre), aprobación.
- **Mensajes preaprobados** por escenario (plantillas con `[…]`).
- **Medios alternativos** si fallan los habituales: árbol de llamadas, SMS, mensajería, radio, página de estado externa, correo en otro proveedor.
- **Bitácora del incidente [C]:** hora, información recibida, decisiones, quién decidió, acciones, comunicaciones emitidas.
- Pruebas periódicas de los sistemas de alerta y del árbol de llamadas.

## 3. Contenido mínimo de los planes (§8.4.4)

Cada plan (o el conjunto) debe incluir:

- [ ] Propósito, alcance y objetivos.
- [ ] **Criterios y procedimiento de activación.**
- [ ] Procedimientos de implementación (listas de verificación paso a paso).
- [ ] Roles, responsabilidades y autoridades (con suplentes).
- [ ] Requisitos y procedimientos de comunicación.
- [ ] Interdependencias internas y externas.
- [ ] Recursos requeridos (y dónde obtenerlos).
- [ ] Requisitos de reporte y flujo de información.
- [ ] **Proceso de desactivación (stand-down).**
- [ ] Contactos (internos, proveedores, autoridades) — con fecha de última verificación.
- [ ] Control documental, versión, dueño, distribución y **ubicación de copias disponibles sin los sistemas afectados** (impresas, dispositivo móvil, repositorio en otro proveedor).

### Estructura sugerida de un plan de continuidad por área
1. Datos de control y distribución.
2. Resumen: actividades prioritarias, RTO/MBCO/RPO.
3. Activación: criterios, quién, cómo.
4. Equipo y contactos.
5. Listas de verificación: primera hora · primeras 24 h · hasta RTO · operación en modo alterno.
6. Soluciones alternas por escenario de pérdida de recurso (personas, sitio, TIC, proveedor).
7. Registros vitales y dónde están.
8. Comunicación.
9. Desactivación y retorno.
10. Anexos: formularios, bitácora, mapas.

**Estilo:** frases imperativas, listas, sin teoría. Debe poder ejecutarlo un suplente bajo estrés
a las 3 de la mañana.

## 4. Recuperación (§8.4.5)

Procedimientos documentados para volver de las medidas temporales a la operación normal:
evaluación de daños · restauración de instalaciones y sistemas · **sincronización/reconciliación
de datos** procesados en modo alterno · retorno gradual de personas · verificación de
funcionamiento · comunicación de normalidad · cierre formal · revisión post-incidente (§8.6).
