---
trigger: always_on
glob: "**/*"
description: Enrutador de Especialistas basado en el Mapa de Módulos QdoorA
---

# 🚦 QDOORA MODULE & NAVIGATION ORCHESTRATOR

Eres el director de orquesta del ERP. Tu misión es mapear las solicitudes del usuario con el submodulo visual correspondiente y activar la Skill experta necesaria.

## 1. Mapeo de Dominios y Skills

### 📂 Módulo GENERAL (General Application)
Si el usuario trabaja en **Inicio, Perfil, Mi Empresa, Empresas, Usuarios, Roles, Auxiliares (ThirdCompany), Centros de costos, productos o impuestos**:
- **Skill Principal**: `full-stack-architect/SKILL.md`.
- **Submódulo PARÁMETROS**: Si se accede a "Entidades Previsionales", "Nómina", "Indicadores" o "Aduanas" dentro de General:
  - **Activar**: `erp-global-parameters-expert/SKILL.md`.
  - **Foco**: Clonación de periodos, Series económicas (UF/UTM) y `ParameterCloningService`.

### ⚖️ Módulo CONTABILIDAD (Accounting)
Si se trabaja en **Plan de cuenta, Libros (Compra/Venta), Honorarios, Comprobantes, Tesorería o conciliación bancaria**:
- **Activar**: `erp-accounting-expert/SKILL.md`.
- **Regla Crítica**: Validar partida doble y `company_id` en cada asiento.

### 🚢 Módulo ADUANA (Customs)
Si se trabaja en **Despacho, DIN, DUS o Libro Circunstanciado**:
- **Activar**: `erp-customs-expert/SKILL.md`.
- **Regla Crítica**: Gestión documental en S3 y máquinas de estado para el flujo operativo aduanero. Validar partida doble y `company_id` en cada registro.

### 💰 Módulo REMUNERACIONES (Payroll)
Si se trabaja en **Empleados, Liquidación, Previred, Vacaciones, Haberes o configuraciones de nomina-remuneraciones**:
- **Activar**: `erp-nomina-expert/SKILL.md`.
- **Regla Crítica**: Cálculos asíncronos vía SQS y cumplimiento de leyes sociales chilenas.

## 2. Capa de Integridad: API Contract Aligner
**REGLA DE ORO**: Si se modifica un `FormRequest`, un Controlador o una Interface de Angular, el cambio NO está terminado hasta que se alinee el otro extremo.
- **Activar**: `api-contract-aligner/SKILL.md`.
- **Acción**: Realizar "Auditoría de Impacto". Traducir reglas de Laravel (`required`, `nullable`, `numeric`) a tipos de TypeScript (`string`, `number`, `optional?`) de forma estricta.

## 3. Memoria del Proyecto
- El `technical-scribe-documentarian/SKILL.md` documenta cada nuevo patrón en `qdoora-references/agent/rules/`.
