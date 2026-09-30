# BIA y evaluación de riesgos de disrupción (§8.2)

Guías: **ISO/TS 22317** (BIA), **ISO 22313** (guía del SGCN), **ISO 31000** (riesgo).

## Orden correcto

```
Productos/servicios en alcance → Procesos → Actividades → BIA (impacto en el tiempo)
→ MTPD → RTO / MBCO / RPO → Actividades prioritarias → Recursos y dependencias
→ Evaluación de riesgos de disrupción → Estrategias (8.3)
```

## 1. Preparar el BIA (§8.2.2 a)

Define y aprueba con la dirección:

**Tipos de impacto** (ejemplo): financiero · clientes/servicio · legal/regulatorio/contractual ·
reputacional · seguridad y salud de las personas · operacional · ambiental.

**Criterios por nivel** (ajustar a la organización):

| Nivel | Financiero | Clientes | Legal / regulatorio | Reputación |
|-------|-----------|----------|---------------------|------------|
| 1 Insignificante | < [X] | Sin efecto perceptible | Ninguno | Sin cobertura |
| 2 Menor | [X–Y] | Retrasos puntuales | Observación menor | Quejas aisladas |
| 3 Moderado | [Y–Z] | Varios clientes afectados | Incumplimiento notificable | Prensa local / redes |
| 4 Mayor | [Z–W] | Clientes clave afectados, penalidades SLA | Sanción probable | Prensa nacional |
| 5 Crítico | > [W] | Pérdida de clientes, incumplimiento masivo | Pérdida de licencia, sanción grave | Daño duradero |

**Nivel de impacto inaceptable** (define el MTPD): p. ej., el primer momento en que cualquier
tipo de impacto alcanza el nivel 4.

## 2. Recopilar (entrevistas o talleres con dueños de proceso)

Por cada actividad:
1. Descripción y producto/servicio que soporta.
2. **Impacto en el tiempo** por tipo: 1 h, 4 h, 1 día, 3 días, 1 semana, 2 semanas, 1 mes (escala adaptable).
3. **Picos y estacionalidad** (cierre de mes, temporada alta): el BIA se hace para el peor momento razonable.
4. **MTPD:** primer intervalo con impacto inaceptable.
5. **RTO** (< MTPD con margen) y **MBCO** (capacidad mínima: volumen, clientes, horario).
6. **RPO** de la información que usa.
7. **Recursos mínimos** para operar a MBCO, en el tiempo: personas (cantidad y competencias críticas), sitio/espacio, equipos, aplicaciones TIC, información (física y digital), proveedores, finanzas.
8. **Dependencias**: actividades internas previas y posteriores, proveedores y socios (incluidos servicios en la nube y SaaS).
9. Soluciones provisorias existentes (manuales, trabajo remoto) y su límite en el tiempo.
10. Registros vitales que no pueden perderse.

## 3. Analizar y validar

- Consolida y **normaliza** entre áreas (todos se creen críticos; los criterios arbitran).
- Verifica **coherencia de interdependencias:** si A depende de B, `RTO(B) ≤ RTO(A)`.
- Agrega por recurso: RTO y RPO exigidos a cada sistema TIC = el más exigente de las actividades que lo usan.
- **Valida con la alta dirección** y obtén aprobación formal de actividades prioritarias y tiempos.

## Tabla de salida del BIA

| Actividad | Producto/servicio | Dueño | Impacto 4 h | 1 d | 3 d | 1 sem | MTPD | RTO | MBCO | RPO | Personas mín. | Sitio | TIC | Proveedores | Dependencias | ¿Prioritaria? |
|-----------|-------------------|-------|-------------|-----|-----|-------|------|-----|------|-----|---------------|-------|-----|-------------|--------------|---------------|

Tabla derivada **por recurso TIC** (entrada al DRP):

| Sistema | Actividades que soporta | RTO exigido | RPO exigido | Capacidad actual (probada) | Brecha |
|---------|------------------------|-------------|-------------|----------------------------|--------|

## 4. Evaluación de riesgos de disrupción (§8.2.3)

Foco: riesgos de **disrupción a las actividades prioritarias y a sus recursos** (no todos los
riesgos del negocio).

1. **Identificar** amenazas por recurso:
   - Personas: pandemia, huelga, pérdida de personal clave, imposibilidad de desplazamiento.
   - Instalaciones: incendio, inundación, sismo, corte de energía o agua, acceso bloqueado, **eventos climáticos extremos**.
   - TIC: caída de data center o región cloud, ransomware, falla de telecomunicaciones, error de cambio.
   - Información: corrupción, pérdida, borrado.
   - Proveedores: quiebra, disrupción del proveedor, dependencia de proveedor único, conflicto geopolítico.
   - Entorno: disturbios, restricciones sanitarias, fallas de servicios públicos.
2. **Analizar** probabilidad y consecuencia (considerando controles existentes). Escala 1–5 compatible con la de riesgos corporativos si existe.
3. **Evaluar** qué riesgos requieren tratamiento según el apetito de riesgo.
4. **Tratar** mediante medidas de protección/mitigación (reducir probabilidad) y estrategias de continuidad (reducir impacto y duración) → §8.3.

| ID | Recurso / actividad | Amenaza | Vulnerabilidad | Controles existentes | P | C | Nivel | Tratamiento | Responsable | Plazo |
|----|--------------------|---------|----------------|---------------------|---|---|-------|-------------|-------------|-------|

**Punto único de falla:** marca explícitamente todo recurso sin alternativa (persona única con
conocimiento, proveedor único, sistema sin réplica, sede única). Son los hallazgos más valiosos.

## 5. Mantener

Repetir a intervalos planificados (típicamente anual) y ante cambios significativos: nuevos
productos, reorganizaciones, migraciones tecnológicas, cambio de proveedor crítico, incidentes,
fusiones, nuevas regulaciones.
