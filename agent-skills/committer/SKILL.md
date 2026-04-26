---
name: committer
description: Automatiza el ciclo de Commit y Changelog en los proyectos de QdoorA (fuse-starter, qdoora-api, support-portal, fuse-demo, qdoora-references).
---

# 📦 Herramienta de Committer y Changelog Unificada

Esta skill es la herramienta principal para realizar commits y gestionar el historial de cambios en todos los proyectos del workspace. Garantiza que cada cambio sea registrado automáticamente tanto en Git como en el archivo `CHANGELOG.md` del proyecto correspondiente de forma atómica.

## 🚀 Proyectos Soportados

- `fuse-starter` (Frontend Cliente)
- `qdoora-api` (Backend)
- `support-portal` (Frontend Soporte/Admin)
- `fuse-demo` (Frontend Demo)
- `qdoora-references` (Reglas y Estándares)

## 🛠️ Herramienta de Ejecución

Para realizar un commit, **DEBES** utilizar el script unificado:

```bash
/Users/francoalvaradotello/QdoorAChile/.agents/skills/committer/scripts/commit.sh <proyecto> "<mensaje>"
```

### Parámetros:
- `<proyecto>`: El nombre de la carpeta del proyecto (ej: `fuse-starter`, `qdoora-api`, etc.).
- `"<mensaje>"`: Mensaje siguiendo la convención de **Conventional Commits**. **IMPORTANTE: Todo mensaje DEBE estar en ESPAÑOL.**

---

## 📐 Convención de Commits

Todo mensaje debe seguir esta estructura: `<tipo>[alcance]: <descripción>`

| Tipo | Descripción |
| :--- | :--- |
| **feat** | Nueva funcionalidad |
| **fix** | Corrección de error |
| **docs** | Documentación |
| **style** | Formato y estilo |
| **refactor** | Mejora de código sin cambios funcionales |
| **perf** | Mejora de rendimiento |
| **chore** | Tareas de mantenimiento |

---

## 🔄 Flujo de Trabajo (Agente)

1. **Análisis**: Verifica qué archivos han cambiado.
2. **Ejecución**: Invoca el script `commit.sh`. Este realizará de forma atómica:
   - Actualización del `CHANGELOG.md` local del proyecto con la fecha y el mensaje en **ESPAÑOL**.
   - `git add .` en el directorio del proyecto (incluyendo el cambio del changelog).
   - `git commit -m "..."`.

---

> [!IMPORTANT]
> Esta skill es la **única** forma autorizada de realizar commits. No realices `git commit` manuales, ya que esto rompería la trazabilidad del `CHANGELOG.md`. Todos los mensajes deben escribirse en **ESPAÑOL**.
