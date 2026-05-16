# Tailwind CSS v4 (@theme)

> Configuración CSS-first para el Portal de Soporte.

## 🎨 Configuración en `styles.css`

En Tailwind v4, la configuración se realiza directamente en el archivo CSS principal mediante la directiva `@theme`.

```css
@import "tailwindcss";

@theme {
  /* Colores QdoorA Admin */
  --color-admin-primary: oklch(0.623 0.214 259.815);
  --color-admin-secondary: oklch(0.446 0.03 256.802);

  /* Tipografía */
  --font-display: "Space Grotesk", ui-sans-serif, system-ui;
  --font-body: "Outfit", ui-sans-serif, system-ui;

  /* Espaciado Custom */
  --spacing-18: 4.5rem;
}

/* Clases de utilidad custom */
@utility admin-card {
  @apply rounded-2xl border border-white/10 bg-black/50 backdrop-blur-xl p-6;
}
```

## 🚨 Reglas de Uso
- NO crear archivo `tailwind.config.js`.
- Usar variables CSS nativas para el tipado de colores.
- Renombrar `styles.scss` a `styles.css` para evitar warnings de Sass con el compilador de Vite.
