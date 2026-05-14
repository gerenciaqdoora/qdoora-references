# Patrones de Diseño UI: Portal de Soporte

Estructuras de componentes y layouts reales extraídos del portal de administración.

### Shell Layout (Estructura Principal)
```html
<div class="flex h-screen overflow-hidden bg-[#f8fafc] font-sans">
    <!-- Sidebar Navy (w-64) -->
    <aside class="w-64 bg-[#172B4D] text-white hidden lg:flex flex-col z-20 shadow-[8px_0_24px_rgba(0,0,0,0.1)]">
        <!-- Logo y Navegación -->
    </aside>

    <div class="flex-1 flex flex-col min-w-0 relative">
        <!-- Header White (h-16) -->
        <header class="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-8 shadow-sm">
            <!-- Breadcrumbs y Logout -->
        </header>

        <!-- Main Content con Pattern Background -->
        <main class="flex-1 relative bg-[#f4f7fa]">
            <div class="absolute inset-0 z-0 opacity-[0.03] pointer-events-none" 
                 style="background-image: radial-gradient(#172B4D 1px, transparent 1px); background-size: 40px 40px;">
            </div>
            <div class="relative z-10 h-full overflow-y-auto">
                <router-outlet></router-outlet>
            </div>
        </main>
    </div>
</div>
```

### Botones Enterprise (Premium)
```html
<!-- Botón Dark Action -->
<button class="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-red-600 text-white rounded-lg text-[10px] font-black uppercase tracking-widest transition-all shadow-md active:scale-95">
    <span>Salir del Sistema</span>
</button>

<!-- Ítem de Navegación Activo -->
<a class="bg-blue-600 shadow-lg shadow-blue-900/40 text-white font-bold flex items-center gap-3 px-4 py-3 rounded-xl">
    <span>📊</span>
    <span>Tablero</span>
</a>
```

### Micro-interacciones
- **Hover Scale**: `transition-transform duration-200 hover:scale-[1.02] active:scale-[0.98]`
- **Glass Card**: `bg-white/70 backdrop-blur-xl border border-white/20 shadow-xl`

### Scrollbar Personalizado
```css
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { 
    background: #cbd5e1; 
    border-radius: 10px; 
}
```
