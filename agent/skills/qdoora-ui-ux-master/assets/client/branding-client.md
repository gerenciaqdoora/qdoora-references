# Identidad Visual: Portal de Clientes (Angular 18)

Detalle técnico de la marca y estética aplicada en el portal de clientes basado en Fuse.

### Paleta de Colores (Brand Colors)
- **Primary / Action**: `#3b82f6` (Blue-500, usado en botones primarios y tours).
- **Success**: `#4caf50` (Snackbar) / `#15803d` (Alertas).
- **Error**: `#f44336` (Snackbar) / `#b91c1c` (Alertas).
- **Warning**: `#ff9800` (Snackbar) / `#b45309` (Alertas).
- **Info**: `#2196f3` (Snackbar) / `#1d4ed8` (Alertas).

### Alertas Estandarizadas (`app-shared-alert`)
- **Radio de Borde**: `12px` (interno) / `13px` (contenedor).
- **Apariencia**: Siempre `outline`.
- **Textura de Fondo**: `/images/dialog/back.png` (Sello de agua premium).
- **Sombra Interna**: `inset 7px 0 0 0 currentColor` (Barra lateral de acento).

### Diálogos y Popovers
- **Radio de Borde**: `13px` para diálogos, `16px` para popovers de tour.
- **Sombra Premium**: `0 25px 50px -12px rgba(0, 0, 0, 0.25)`.
- **Z-Index**: Popovers de tour (`100000`), Alertas (`10`).

### Tipografía y Espaciado
- **Fuentes**: Definidas en el tema de Fuse (usualmente Inter o similar).
- **Labels**: Estilo `reduceMarginLabel` para mayor densidad de información.
- **Grids**: Patrón responsivo estándar `grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6`.
