# 📚 QdoorA References

Bienvenido al repositorio central de conocimiento y estándares del ecosistema **QdoorA**. Este proyecto actúa como la "Fuente de Verdad" (Source of Truth) tanto para los desarrolladores humanos como para los agentes de IA (Antigravity).

## 🏗️ Estructura del Proyecto

### 🔴 Rules (Crítico)
La carpeta [/Rules](file:///Users/francoalvaradotello/QdoorAChile/qdoora-references/Rules) contiene los estándares arquitectónicos, patrones de diseño y reglas de negocio innegociables del proyecto. Es el corazón del conocimiento técnico de QdoorA.

- **Backend.md**: Estándares para Laravel 11, FormRequests, y lógica de servicios.
- **Frontend.md**: Guías para Angular 18 (Cliente), Signals, y componentes Standalone.
- **Support.md**: Reglas específicas para el Portal de Soporte y Admin (Angular 21).
- **GLOBAL_RULES.md**: Principios transversales de seguridad, multitenancy y arquitectura global.

> [!IMPORTANT]
> Estas reglas son referenciadas imperativamente por todas las **Skills** de los agentes. Cualquier cambio aquí afecta directamente cómo el agente analiza y genera código.

### 🤖 Configuración del Agente (agent-*)
Las carpetas con el prefijo `agent-` definen el cerebro y los procesos de **Antigravity**:
- **agent-rules**: Directrices de comportamiento y restricciones éticas/técnicas para el agente.
- **agent-skills**: Habilidades especializadas (Contabilidad, Remuneraciones, Aduana, etc.).
- **agent-workflows**: Protocolos de pasos obligatorios para tareas complejas (Commits, Deploys, Auditorías).

### 📁 Directorios Adicionales
- **Planes**: Estrategias de implementación y roadmaps técnicos.
- **Otros**: Documentación de apoyo y recursos complementarios.

---

> [!TIP]
> Mantener esta base de conocimientos actualizada es vital. Si descubres un nuevo patrón o corriges una deuda técnica, documéntalo en `Rules/` para que todo el equipo (humano y artificial) trabaje en sincronía.

---
*QdoorA Chile - Sistema de Referencias Técnicas*
