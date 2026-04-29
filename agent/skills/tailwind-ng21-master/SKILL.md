---
name: tailwind-ng21-master
description: Experto en la implementación y optimización de Tailwind CSS v4 en proyectos Angular 21 (Vite-based). Domina la configuración CSS-first, el sistema de variables @theme y el escaneo de fuentes optimizado.
---

# Tailwind CSS v4 + Angular 21 Master

Este skill proporciona las directrices y estándares para integrar Tailwind CSS v4 en el ecosistema de Angular 21, aprovechando el nuevo motor de compilación basado en Vite y la arquitectura CSS-first.

## 🛠️ Configuración Core (v4)

Tailwind v4 elimina el archivo `tailwind.config.js` por defecto a favor de una configuración basada íntegramente en CSS.

### 1. PostCSS Bridge
Para Angular 21, se recomienda el uso del plugin `@tailwindcss/postcss`.

**postcss.config.json:**
```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

### 2. Directivas CSS
Importa Tailwind directamente en el punto de entrada global.

**styles.scss:**
```css
@import "tailwindcss";
```

## 🎨 Sistema de Temas (@theme)

Utiliza el bloque `@theme` para extender o modificar el sistema de diseño.

```css
@theme {
  --color-primary: #1a2b48;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #38bdf8;
  
  /* Animaciones Custom */
  --animate-wiggle: wiggle 1s ease-in-out infinite;

  @keyframes wiggle {
    0%, 100% { transform: rotate(-3deg); }
    50% { transform: rotate(3deg); }
  }
}
```

## 🚀 Optimización Angular 21

1.  **Vite Scanning**: Tailwind v4 detecta automáticamente las plantillas `.html` y componentes `.ts`.
2.  **Zoneless Compatibility**: Los estilos de Tailwind no dependen de Zone.js, lo que garantiza un renderizado fluido en el modo experimental Zoneless de Angular 21.
3.  **Signals Integration**: Usa clases dinámicas de Tailwind vinculadas a Angular Signals para una reactividad máxima sin sobrecarga de CSS.

## 🚨 Reglas de Oro

- **No usar tailwind.config.js**: A menos que sea estrictamente necesario para plugins legacy. Prefiere `@theme`.
- **Variables CSS**: Todas las personalizaciones de color deben exponerse como variables CSS estándar.
- **Dark Mode**: Tailwind v4 usa por defecto `media` strategy, pero se recomienda configurar `class` strategy mediante variables CSS si se requiere un toggle manual.
