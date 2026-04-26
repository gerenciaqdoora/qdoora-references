## Plan Liquidaciones — Seguimiento de Ejecución

### Fase 0: Pre-Liquidaciones (Refinamiento)
#### Backend
- [ ] Enum `OvertimeSubtype`
- [ ] Enum `AbsenceSubtype`
- [ ] Modificar `NominaFeatureKey` — agregar AUSENCIAS y PSGS
- [ ] Migración: schema HORAS_EXTRAS + seed AUSENCIA_LABORAL + PSGS + propagación
- [ ] Modificar `UpdateNominaFeatureConfig` — validar nuevos schemas

#### Frontend
- [ ] Settings — expandir bloque Horas Extras (6 tasas)
- [ ] Settings — card PSGS
- [ ] Settings — card Ausencias (5 subtipos)

---

### Fase 1: Backend Principal
- [ ] Migración `liquidaciones`
- [ ] Migración `liquidacion_novedades` (+ subtype + hours decimal)
- [ ] Modelo `Liquidacion`
- [ ] Modelo `LiquidacionNovedad`
- [ ] Enum `EstadoLiquidacion`
- [ ] Enum `TipoNovedad`
- [ ] Actualizar `LoggerEvent` — agregar LIQUIDACION
- [ ] `LiquidacionService`
- [ ] FormRequests (4)
- [ ] Resources (3)
- [ ] `LiquidacionController`
- [ ] Rutas API

### Fase 2: Frontend Principal
- [ ] `liquidacion.api.ts`
- [ ] `liquidaciones.service.ts`
- [ ] `liquidaciones.routes.ts`
- [ ] `list.component.ts` + `.html`
- [ ] Dialog: `horas-extras-novedad-dialog`
- [ ] Dialog: `ausencia-novedad-dialog`
- [ ] Dialog: `psgs-novedad-dialog`
- [ ] Dialog: `email-liquidacion-dialog`
- [ ] `app.routes.ts` — registrar ruta
