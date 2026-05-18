# Reporte de Hallazgo de Seguridad — [ID-VECT]

---

## 📝 1. Ficha del Hallazgo

| Propiedad | Detalle |
|-----------|---------|
| **Título del Hallazgo** | [Ej. Secuestro de Cuenta mediante Modificación Insegura de Email] |
| **Identificador Vector** | [Ej. QD-03 / ATO] |
| **Dominio Metodología OWASP** | [Ej. OTG-AUTHN (Autenticación)] |
| **Severidad Global** | [🔴 CRÍTICO / 🟠 ALTO / 🟡 MEDIO / 🔵 BAJO] |
| **Impacto Técnico** | [Ej. Escalamiento de Privilegios / Robo de Identidad] |
| **Endpoint / Componente Afectado** | [Ej. PUT /api/v1/profile/email / EmailChangeComponent] |

---

## 🔍 2. Descripción Teórica
[Proporcione una explicación clara y conceptual de la vulnerabilidad, indicando cómo se produce en términos de diseño, lógica de negocio o falta de validaciones en el framework o lenguaje utilizado.]

---

## 🚨 3. Prueba de Concepto (PoC) / Evidencia de Explotación
[Detalle paso a paso cómo reproducir activamente la vulnerabilidad. Incluya códigos de payloads, comandos curl con cabeceras de prueba y la respuesta esperada que confirma el fallo.]

### Petición de Explotación:
```bash
curl -X [METODO] {{BASE_URL}}/api/[ruta] \
  -H "Authorization: Bearer {{TEST_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{
    "[parametro]": "[payload]"
  }'
```

### Respuesta Obtenida (Fallo de Seguridad):
```json
{
  "status": "success",
  "message": "Operación completada sin re-autenticar",
  "sensitive_data": "[Datos expuestos]"
}
```

---

## 💼 4. Impacto de Negocio
[Explique las repercusiones comerciales y operativas para la organización en caso de que un atacante explote esta vulnerabilidad (ej. robo de propiedad intelectual, fuga de información financiera de clientes, penalizaciones regulatorias, daño reputacional, etc.).]

---

## 🛠️ 5. Plan de Remediación Definitivo

### A. Corrección en Backend ([Tecnología/Lenguaje])
[Detalle las correcciones específicas que deben aplicarse a nivel de controladores, middlewares, ORM o base de datos. Proporcione código fuente limpio y listo para su inserción.]

```[lenguaje_backend]
// Código de remediación seguro
```

### B. Corrección en Frontend ([Tecnología/Framework])
[Detalle los cambios a nivel de componentes, guards, interceptores o directivas que aseguren la consistencia visual y de datos en el cliente.]

```[framework_frontend]
// Código de remediación seguro
```

### C. Hardening en Infraestructura / Nube
[Si aplica, describa las modificaciones necesarias a nivel de nginx, balanceador de carga, políticas IAM de roles, o políticas de bucket.]

---

## 🧪 6. Validación de Corrección
[Defina las pruebas necesarias para validar que la remediación mitigue efectivamente la vulnerabilidad, indicando qué respuesta debe retornar ahora la API (ej. HTTP 401, 403, 429 o 404).]
