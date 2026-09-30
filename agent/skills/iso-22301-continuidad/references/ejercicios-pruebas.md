# Programa de ejercicios y evaluación de capacidades (§8.5, §8.6)

Guía de apoyo: ISO 22313 y la norma de la familia sobre ejercicios (históricamente ISO 22398;
verifica la edición o sucesora vigente).

## Tipos de ejercicio (de menor a mayor realismo y riesgo)

| Tipo | Descripción | Valida | Riesgo de disrupción |
|------|-------------|--------|----------------------|
| **Revisión documental / recorrido** | Leer el plan con sus dueños, detectar errores. | Contenido, contactos, coherencia. | Nulo |
| **Prueba de comunicaciones** | Activar el árbol de llamadas/alertas. | Contactos y tiempos de respuesta. | Nulo |
| **Ejercicio de escritorio (tabletop)** | Discusión guiada de un escenario con inyecciones. | Toma de decisiones, roles, coordinación. | Nulo |
| **Simulación** | Escenario en tiempo casi real, equipos en sus roles, sin afectar operaciones. | Coordinación, comunicación, flujo de información. | Bajo |
| **Prueba técnica / funcional** | Activar una solución: restaurar un respaldo, conmutar a DR, operar desde el sitio alterno. | Capacidad real vs RTO/RPO/MBCO. | Medio (planificar) |
| **Ejercicio integral** | Toda la organización, activación real de soluciones. | El conjunto de disposiciones. | Alto (planificar y controlar) |

## Programa (§8.5)

- Plurianual y cíclico: **en conjunto** debe validar todas las disposiciones (cada actividad prioritaria, cada solución, cada equipo, cada plan) a lo largo del tiempo.
- Frecuencia según criticidad y cambios; típico: comunicaciones semestral, tabletop anual por equipo, prueba técnica de DR anual por sistema crítico.
- Ejercicios adicionales **ante cambios significativos** (nueva sede, migración cloud, nuevo proveedor crítico).
- **Escenarios variados**, incluidos los más probables (TIC, proveedores, clima) y alguno severo pero plausible (pérdida del sitio + personal clave).

| Ejercicio | Tipo | Planes / soluciones que valida | Participantes | Fecha | Objetivos | Estado | Informe |
|-----------|------|-------------------------------|---------------|-------|-----------|--------|---------|

## Diseño de un ejercicio

1. **Objetivos medibles** (p. ej., "el comité de crisis se constituye en ≤ 60 min"; "restaurar el ERP en ≤ 4 h con pérdida ≤ 1 h de datos").
2. **Alcance** y participantes; observadores/evaluadores independientes.
3. **Escenario** realista y **línea de tiempo con inyecciones** (novedades que se entregan durante el ejercicio).
4. **Controles de seguridad**: cómo evitar causar una disrupción real (palabra clave de "no es ejercicio", criterio de aborto, ventanas, respaldo previo).
5. Logística, materiales, comunicación previa (anunciado o no anunciado, según madurez).
6. Hoja de evaluación por objetivo.

## Durante y después

- Registrar tiempos reales, decisiones, problemas.
- **Debrief inmediato** ("en caliente") con participantes.
- **Informe formal [C]** (§8.5): objetivos, escenario, participantes, resultados vs objetivos (cumplido/parcial/no), **tiempos reales vs RTO/RPO**, fortalezas, brechas, recomendaciones, **acciones con responsable y fecha**.
- Acciones gestionadas hasta su cierre; brechas significativas como NC (§10.1).
- Actualizar planes, BIA, estrategias según lo aprendido.

## Evaluación de documentación y capacidades (§8.6)

Revisión periódica (al menos anual), **tras cada incidente o activación real**, y ante cambios:

| Elemento | Pregunta de evaluación | Fuente de evidencia |
|----------|------------------------|---------------------|
| BIA | ¿Refleja productos, procesos y volúmenes actuales? | Comparar con organigrama, catálogo de servicios, cambios |
| Evaluación de riesgos | ¿Incluye nuevas amenazas (clima, ciber, geopolítica)? | Inteligencia de amenazas, incidentes del sector |
| Estrategias y soluciones | ¿Siguen cumpliendo RTO/RPO? | Resultados de pruebas técnicas |
| Planes | ¿Contactos, procedimientos y recursos vigentes? | Revisión documental, prueba de comunicaciones |
| **Proveedores y socios** | ¿Tienen capacidad de continuidad acorde a nuestros RTO? | Cuestionarios, certificados 22301, participación en ejercicios conjuntos, informes de sus pruebas |
| Cumplimiento | ¿Cumple requisitos legales, regulatorios, contractuales y buenas prácticas? | Matriz legal (§4.2.2) |

Conserva los resultados y lleva las conclusiones a la revisión por la dirección (§9.3.2).
