# 🚀 QdoorA Agentic ERP - Manual de Orquestación

Bienvenido al centro de mando de QdoorA. Este documento guía la interacción con los Agentes de IA especializados para mantener el rigor arquitectónico y la seguridad del proyecto.

## 🎭 Activación Natural de Expertos
No necesitas recordar los nombres técnicos de los "Skills". Simplemente menciona el contexto de tu tarea y el agente adecuado se activará automáticamente.

| Skill (Auto) | Comando ( / ) | Propósito |
| :--- | :--- | :--- |
| **Lógica de Negocio (ERP)** | | |
| `erp-payroll-expert` | `/erp-payroll` | Cálculos de sueldos, leyes sociales Chile, finiquitos. |
| `erp-accounting-expert` | `/erp-accounting` | Partida doble, planes de cuenta, centralización contable. |
| `erp-customs-expert` | `/erp-customs` | Documentación masiva, costeo, logística internacional. |
| `erp-electronic-invoicing-expert` | `/erp-invoicing` | Generación de XML, firmas digitales, comunicación SII. |
| `erp-global-parameters-expert` | `/erp-parameters` | Clonación de periodos, indicadores económicos. |
| **Frontend & UI** | | |
| `angular-18-ui-ux-master` | `/angular-ui` | Estándares de UI premium, RxJS, formularios y temas. |
| `angular-migration-architect` | `/angular-migration` | Transición v18 a v21, Vitest y arquitectura zoneless. |
| **Backend & Arquitectura** | | |
| `laravel-11-postgresql-master` | `/laravel-backend` | Controladores, modelos Eloquent, optimización SQL. |
| `full-stack-architect` | `/architect` | Guardián de estándares, seguridad y flujos de trabajo. |
| `api-contract-aligner` | `/api-contract` | Sincronización entre Laravel FormRequest y Angular UI. |
| `bi-reporting-exports-master` | `/bi-reporting` | Dashboards, reportes masivos Excel/PDF y SQL BI. |
| **DevOps & Despliegue** | | |
| `cloud-devops-engineer` | `/devops` | ECS Fargate, S3, Dockerización y mantenimiento dev. |
| `qa-versioned-deployer` | `/qa-deploy` | Empaquetado de imágenes Docker y despliegue en AWS ECR. |
| `committer` | `/commit` | Automatiza el ciclo de Commit y actualización de log. |
| `changelog-manager` | `/changelog` | Administración automática de cambios en repos QdoorA. |
| **Seguridad & Calidad (QA)** | | |
| `ethical-hacking-auditor` | `/security-hacking` | Revisión OWASP, IDOR, SQLi, XSS y hacking ético. |
| `security-iam-expert` | `/security-iam` | JWTAuth, Autorización (RBAC) y protección de rutas. |
| `qa-automation-data-auditor` | `/qa-audit` | Pruebas Pest/Angular, integridad de datos PostgreSQL. |
| **Mantenimiento & Evolución** | | |
| `lifecycle-tech-debt-guardian` | `/maintenance` | Estratega de mantenimiento y prevencion de obsolescencia. |
| `safe-garbage-collector` | `/garbage-collector` | Eliminación segura de deuda técnica y código muerto. |
| `technical-scribe-documentarian` | `/scribe` | Documentación técnica viva y actualización de GLOBAL_RULES. |
| `skill-creator` | `/skill-creator` | Creación, edición y optimización de skills de agentes. |
| `find-skills` | `/find-skills` | Descubrimiento e instalación de nuevas capacidades. |

## 🛠️ Comandos de Flujo (Workflows)
Usa estos comandos para cargar contextos predefinidos al inicio de la conversación:

- `/backend`: Activa el modo experto en **Laravel 11**.
- `/frontend`: Activa el modo experto en **Angular 18**.
- `/new-submodule`: Inicia el flujo de creación de un nuevo submódulo en el ERP.
- `/sync-module`: Sincroniza cambios entre componentes de un submódulo existente.

## 🛡️ Protocolo de Rigor Arquitectónico (EXTREMO)
Este proyecto se rige por las reglas en la carpeta `.qdoora/Rules/`. El agente `full-stack-architect` actuará como auditor senior:
1. **Refutación**: Si una propuesta técnica viola las reglas, será rechazada inmediatamente con una explicación.
2. **Sin Atajos**: No se permiten soluciones rápidas que comprometan la integridad de la base de código.
3. **Documentación Viva**: Tras cada tarea, el `technical-scribe-documentarian` actualizará las reglas del proyecto si se detectan nuevos patrones o mejoras.

---
*Para ver la lista técnica de skills instalados, utiliza: `npx skills list`*
