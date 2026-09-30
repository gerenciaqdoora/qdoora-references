# 📚 QdoorA References

Bienvenido al repositorio central de conocimiento y estándares del ecosistema **QdoorA**. Este proyecto actúa como la "Fuente de Verdad" (Source of Truth) tanto para los desarrolladores humanos como para los agentes de IA (Antigravity).

## 🏗️ Estructura del Proyecto

### 🔴 Rules (Crítico)
La carpeta [./Rules](./Rules) contiene los estándares arquitectónicos, patrones de diseño y reglas de negocio innegociables del proyecto. Es el corazón del conocimiento técnico de QdoorA.

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

## 🕸️ graphify — Grafo de Conocimiento del Código

Claude Code y Codex consultan primero un grafo del código de `qdoora-api`, `fuse-starter` y `support-portal` (`graphify query`) antes de buscar en los archivos. Las reglas están en `agent/rules/AGENT_BASE.md` (sección "graphify").

Los grafos, los git hooks y los hooks de Claude son locales a cada máquina y no viajan por git. Para prepararlos, ejecuta **una vez** desde la raíz del workspace (`QdoorAChile/`):

```bash
git -C qdoora-references pull
qdoora-references/agent/scripts/graphify-setup.sh
```

- Si graphify no está instalado, el script se detiene y muestra el comando para instalarlo (`uv tool install graphifyy` o `pipx install graphifyy`). Instálalo y vuelve a ejecutar el script.
- Es idempotente: se puede volver a ejecutar para reparar la instalación o tras clonar un repo de nuevo.
- Abre siempre las sesiones de Claude y Codex en la raíz del workspace.
- Para rehacer el grafo a mano tras editar código: `qdoora-references/agent/scripts/graphify-sync.sh`.

---

> [!TIP]
> Mantener esta base de conocimientos actualizada es vital. Si descubres un nuevo patrón o corriges una deuda técnica, documéntalo en `Rules/` para que todo el equipo (humano y artificial) trabaje en sincronía.

---
*QdoorA Chile - Sistema de Referencias Técnicas*
