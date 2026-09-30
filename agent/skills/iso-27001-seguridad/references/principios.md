# Principios y conceptos fundamentales

Fuente conceptual: ISO/IEC 27000 (visión general y vocabulario, edición 2026) e ISO/IEC 27001.

## La tríada CID

| Propiedad | Significado | Amenaza típica | Controles típicos |
|-----------|-------------|----------------|-------------------|
| **Confidencialidad** | La información no se pone a disposición ni se revela a personas, entidades o procesos no autorizados. | Filtración, acceso indebido, robo de credenciales. | Control de acceso, cifrado, clasificación, DLP, enmascaramiento. |
| **Integridad** | Exactitud y completitud de la información. | Modificación no autorizada, errores, manipulación. | Control de cambios, firmas/hashes, validación de entradas, registros. |
| **Disponibilidad** | Accesible y utilizable cuando lo requiere una entidad autorizada. | Caídas, ransomware, DDoS, desastres. | Respaldos, redundancia, continuidad TIC, gestión de capacidad. |

Propiedades complementarias habituales: autenticidad, responsabilidad (trazabilidad),
no repudio, fiabilidad. **Privacidad** (datos personales) se trata en el control 5.34 y, como
sistema propio, en ISO/IEC 27701:2025.

## Ciclo PHVA en el SGSI

```
      Contexto (4) + Partes interesadas + Requisitos legales/contractuales
                                 │
    ┌──── PLANIFICAR (6: riesgos, SoA, objetivos) ◄── Liderazgo (5) ──► ACTUAR (10) ────┐
    ▼                                                                                  │
  HACER (7 Apoyo, 8 Operación: controles, apreciación y tratamiento) ─► VERIFICAR (9) ─┘
                                 │
              Riesgos de información gestionados a nivel aceptable
```

## Enfoque basado en riesgos (el núcleo de 27001)

A diferencia de ISO 9001, en 27001 la gestión de riesgos es **el motor del sistema**:
1. Se definen criterios de riesgo (aceptación y evaluación).
2. Se identifican riesgos a la CID de la información dentro del alcance.
3. Se analizan (consecuencia × probabilidad) y evalúan contra los criterios.
4. Se elige opción de tratamiento y se determinan los controles **necesarios**.
5. Se comparan contra el Anexo A para no omitir controles necesarios.
6. Se documenta la SoA, se aprueba el plan y los dueños aceptan el riesgo residual.

## Defensa en profundidad y otros principios de diseño

- **Mínimo privilegio** y **necesidad de conocer**.
- **Segregación de funciones** (control 5.3).
- **Defensa en profundidad:** varias capas independientes (física, red, host, aplicación, datos, personas).
- **Seguridad por diseño y por defecto** (controles 8.25–8.27).
- **Falla segura:** ante error, el sistema queda en estado seguro.
- **Confianza cero:** no confiar por ubicación de red; verificar identidad y contexto en cada acceso.
- **Responsabilidad compartida** con proveedores de nube (control 5.23).

## Vocabulario clave

| Término | Significado operativo |
|---------|----------------------|
| **Activo** | Algo que tiene valor para la organización: información, software, hardware, servicios, personas, reputación. |
| **Amenaza** | Causa potencial de un incidente no deseado. |
| **Vulnerabilidad** | Debilidad de un activo o control que puede ser explotada por una amenaza. |
| **Riesgo** | Efecto de la incertidumbre sobre los objetivos; en seguridad, combinación de consecuencia y probabilidad de un evento. |
| **Dueño del riesgo** | Persona con responsabilidad y autoridad para gestionar un riesgo (aprueba tratamiento y acepta residual). |
| **Riesgo residual** | Riesgo que permanece después del tratamiento. |
| **Control** | Medida que mantiene o modifica el riesgo. |
| **Evento de seguridad** | Ocurrencia que indica una posible violación de seguridad o falla de controles. |
| **Incidente de seguridad** | Uno o varios eventos con probabilidad significativa de comprometer operaciones o amenazar la seguridad. |
| **SoA (Declaración de Aplicabilidad)** | Documento con los controles necesarios, justificación de inclusión/exclusión y estado de implementación. |
| **Información documentada** | Mantener = documento; conservar = registro/evidencia. |
| **No conformidad** | Incumplimiento de un requisito (de la norma, del propio SGSI, legal o contractual). |
