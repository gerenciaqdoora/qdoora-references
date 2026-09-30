# Plantillas del SGCN

Encabezado de control documental en todas:

```
Código: [XX-YYY-NN]   Versión: [N]   Fecha: [AAAA-MM-DD]   Clasificación: [Uso interno / Confidencial]
Elaborado por: [cargo]   Revisado por: [cargo]   Aprobado por: [cargo]   Próxima revisión: [fecha]
Distribución: [lista de copias y ubicaciones, incluidas copias fuera de línea]
Historial: | Versión | Fecha | Cambio | Aprobó |
```

No inventes nombres, teléfonos, tiempos ni resultados: usa `[…]`.

---

## 1. Política de continuidad del negocio (§5.2)

```markdown
# Política de Continuidad del Negocio — [Organización]

## Propósito
Asegurar que [Organización] pueda proteger a las personas y continuar entregando sus productos y
servicios prioritarios [lista] en plazos y capacidades aceptables ante disrupciones.

## Alcance
[Referencia al documento de alcance del SGCN].

## Compromisos
La dirección se compromete a:
1. Priorizar la seguridad de las personas en toda respuesta.
2. Identificar las actividades prioritarias mediante el análisis de impacto en el negocio y
   evaluar los riesgos de disrupción.
3. Establecer objetivos de continuidad y hacer seguimiento de su cumplimiento.
4. Implementar estrategias, soluciones y planes proporcionales, y validarlos con ejercicios.
5. Cumplir los requisitos legales, regulatorios y contractuales aplicables.
6. Proveer los recursos y la formación necesarios.
7. Mejorar continuamente el sistema de gestión de continuidad del negocio.

## Roles
[Responsable del SGCN, comité de crisis, dueños de planes].

## Revisión
Al menos anualmente o ante cambios significativos.

[Cargo de la alta dirección] — [Fecha]
```

## 2. Alcance (§4.3)

| Campo | Contenido |
|-------|-----------|
| Productos y servicios incluidos | |
| Partes de la organización y sedes incluidas | |
| Requisitos legales/regulatorios/contractuales considerados (§4.2.2) | |
| Partes interesadas pertinentes | |
| Cuestiones de contexto (incl. cambio climático) | |
| Exclusiones y explicación (sin afectar actividades prioritarias) | |

## 3. Objetivos de continuidad (§6.2)

| Objetivo | Indicador | Línea base | Meta | Frecuencia | Responsable | Estado |
|----------|-----------|-----------|------|-----------|-------------|--------|
| Validar capacidades de recuperación | % de actividades prioritarias con ejercicio en los últimos 12 meses | [..] | 100% | Trimestral | [cargo] | [..] |

## 4. Formulario de entrevista BIA

Ver campos en `bia-evaluacion-riesgos.md` §2 y tabla de salida.

## 5. Plan de continuidad (estructura)

Ver `planes-procedimientos.md` §3. Lista de verificación de primera hora:

```markdown
## Primera hora — [Plan de área X]
- [ ] Confirmar que todas las personas están a salvo (lista de asistencia / punto de encuentro).
- [ ] Notificar al coordinador de continuidad: [canal principal] / [alternativo].
- [ ] Evaluar: ¿qué recursos se perdieron? (personas / sitio / TIC / proveedor / información)
- [ ] Comparar con umbrales de activación → ¿activar el plan? (quién decide: [rol])
- [ ] Abrir la bitácora del incidente (hora, hechos, decisiones).
- [ ] Comunicar al equipo el mensaje inicial preaprobado.
```

## 6. Directorio de contactos (anexo de cada plan)

| Rol | Titular | Suplente | Canal principal | Canal alternativo | Verificado el |
|-----|---------|----------|-----------------|-------------------|---------------|

## 7. Bitácora del incidente (§8.4.3)

| Hora | Información recibida / hecho | Decisión | Quién decidió | Acción asignada a | Comunicación emitida |
|------|-----------------------------|----------|---------------|-------------------|----------------------|

## 8. Informe post-ejercicio (§8.5)

```markdown
# Informe de Ejercicio N.º [..] — [nombre]
Fecha: | Tipo: tabletop / simulación / prueba técnica / integral | Escenario:
Participantes (roles): | Evaluadores:

## Objetivos y resultados
| Objetivo | Criterio | Resultado (Cumplido / Parcial / No) | Evidencia |

## Tiempos medidos
| Actividad / sistema | RTO | Tiempo real | RPO | Pérdida real | MBCO alcanzado |

## Fortalezas
## Brechas
## Recomendaciones y acciones
| Acción | Responsable | Fecha | Documento a actualizar |
```

## 9. Acta de revisión por la dirección (§9.3)

```markdown
# Revisión por la Dirección del SGCN — [período]

## Entradas (§9.3.2)
a) Estado de acciones previas:
b) Cambios en cuestiones externas e internas (incl. clima, regulación):
c) Desempeño: NC y acciones correctivas; seguimiento y medición; auditorías:
d) Retroalimentación de partes interesadas:
e) Necesidad de cambios al SGCN (política, objetivos):
f) Procedimientos y recursos para mejorar:
g) Información del BIA y la evaluación de riesgos:
h) Resultados de la evaluación de documentación y capacidades (§8.6), incluidos proveedores:
i) Riesgos no abordados adecuadamente:
j) Lecciones de cuasi-incidentes y disrupciones; resultados de ejercicios:
k) Oportunidades de mejora:

## Conclusión sobre la conveniencia, adecuación y eficacia del SGCN

## Salidas (§9.3.3)
| Decisión | Tipo (alcance / BIA / riesgos / estrategias / planes / controles / recursos) | Responsable | Fecha |
```

## 10. Evaluación de continuidad de proveedores críticos (§8.6)

| Proveedor | Servicio | Actividades que soporta | Nuestro RTO | RTO declarado del proveedor | ¿Plan probado? (evidencia) | Certificación (22301/27001/SOC 2) | Alternativa calificada | Cláusulas contractuales | Resultado | Próxima evaluación |
|-----------|----------|-------------|-----|-----|-----|-----|-----|-----|-----|-----|
