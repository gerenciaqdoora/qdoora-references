### Configuración Core (PostCSS Bridge)
Para Angular 21, se recomienda el uso del plugin `@tailwindcss/postcss`.

**postcss.config.json:**
```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

### Directivas CSS (styles.scss)
```css
@import "tailwindcss";

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

### Reglas de Oro (Vanguardia)
- **No usar tailwind.config.js**: Prefiere el bloque `@theme` dentro de los archivos CSS.
- **Variables CSS**: Todas las personalizaciones de color deben exponerse como variables CSS estándar.
- **Dark Mode**: Configurar `class` strategy mediante variables CSS si se requiere un toggle manual.
