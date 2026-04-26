# Plantilla de Reporte de Auditoría de Seguridad — Qdoora

> Usa esta plantilla al generar el reporte final de cualquier auditoría sobre el stack Qdoora.
> Completa todas las secciones. Si un dominio no fue evaluado, indicarlo explícitamente.

---

```markdown
# Reporte de Auditoría de Seguridad — [Componente / Módulo]
**Fecha**: [YYYY-MM-DD]
**Auditor**: [Nombre / Equipo]
**Alcance**: [URLs, módulos o funcionalidades evaluadas]
**Stack evaluado**: Laravel 11 · Angular [18/21] · AWS ECS Fargate · PostgreSQL

---

## Resumen Ejecutivo

[Párrafo de 3-5 oraciones describiendo: nivel general de riesgo encontrado, los hallazgos más
críticos en términos de impacto de negocio para el ERP Qdoora, y la recomendación prioritaria
del sprint inmediato.]

---

## Estadísticas

| Severidad  | Cantidad | Vectores Qdoora |
|------------|----------|-----------------|
| 🔴 Crítico | X        | QD-XX, QD-XX    |
| 🟠 Alto    | X        | QD-XX           |
| 🟡 Medio   | X        | QD-XX           |
| 🟢 Bajo    | X        | —               |
| ℹ️ Info    | X        | —               |
| **Total**  | **X**    |                 |

---

## Hallazgos por Dominio

### Dominio 1 — Recopilación de Información (OTG-INFO)

**Hallazgo**: [Descripción concisa]
**Vector Qdoora**: [QD-XX si aplica, o N/A]
**Evidencia**:
```bash
# Comando ejecutado y respuesta recibida
curl -I https://api.qdoora.cl/api/health
# X-Powered-By: PHP/8.3.x  ← fuga de versión detectada
```
**Severidad**: [Crítico / Alto / Medio / Bajo / Informativo]
**Impacto de negocio**: [Qué puede hacer un atacante con esta información en el contexto del ERP]
**Remediación Laravel 11**:
```php
// snippet de corrección
```
**Remediación Angular / AWS**: [si aplica]
**Esfuerzo estimado**: [Bajo / Medio / Alto]

---

### Dominio 2 — Configuración y Despliegue (OTG-CONFIG)
[Repetir estructura de hallazgo]

---

### Dominio 3 — Gestión de Identidad (OTG-IDENT)
[Repetir estructura de hallazgo]

---

### Dominio 4 — Autenticación (OTG-AUTHN)
[Repetir estructura de hallazgo]

---

### Dominio 5 — Autorización (OTG-AUTHZ)
[Repetir estructura de hallazgo]

---

### Dominio 6 — Gestión de Sesiones (OTG-SESS)
[Repetir estructura de hallazgo]

---

### Dominio 7 — Validación de Entradas (OTG-INPVAL)
[Repetir estructura de hallazgo]

---

### Dominio 8 — Manejo de Errores (OTG-ERR)
[Repetir estructura de hallazgo]

---

### Dominio 9 — Criptografía (OTG-CRYPST)
[Repetir estructura de hallazgo]

---

### Dominio 10 — Lógica de Negocio (OTG-BUSLOGIC)
[Repetir estructura de hallazgo]

---

### Dominio 11 — Lado del Cliente (OTG-CLIENT)
[Repetir estructura de hallazgo]

---

### Dominio 12 — Seguridad de API (OTG-API)
[Repetir estructura de hallazgo]

---

## Checklist de Vectores Qdoora

Estado de los 11 vectores del catastro para este componente:

| ID | Vector | Estado | Hallazgo # |
|----|--------|--------|------------|
| QD-01 | Client-side authorization bypass | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-02 | Credentials en endpoint de parámetros | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-03 | ATO chain (brute force + email change) | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-04 | BFLA (endpoints sin Gate::authorize) | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-05 | IDOR/BOLA en documentos S3 | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-06 | Cross-portal privilege escalation | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-07 | Stored XSS via [innerHTML] | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-08 | Rate limiting ausente | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-09 | Login response expone permisos | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-10 | APP_DEBUG en entornos no-local | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |
| QD-11 | HTML injection en PDFs | ✅ OK / ❌ VULNERABLE / ⬜ No evaluado | H-X |

---

## Plan de Remediación Priorizado

| Prioridad | ID Hallazgo | Vector | Descripción | Esfuerzo | Sprint |
|-----------|-------------|--------|-------------|----------|--------|
| 1 | H-X | QD-XX | [Acción concreta] | Alto | S1 |
| 2 | H-X | QD-XX | [Acción concreta] | Bajo | S1 |
| 3 | H-X | QD-XX | [Acción concreta] | Medio | S2 |
| ... | | | | | |

---

## Notas de Alcance

- Componentes evaluados: [lista]
- Componentes NO evaluados en este alcance: [lista]
- Próxima auditoría recomendada: [fecha o evento trigger]

---

> ⚠️ Documento de uso interno restringido. No distribuir fuera del equipo de desarrollo.
> Los snippets de código son referencias de implementación — revisar y adaptar antes de merge.
```
