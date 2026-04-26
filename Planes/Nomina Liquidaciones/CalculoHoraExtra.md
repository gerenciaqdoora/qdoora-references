Exactamente, eso es lo correcto. Te lo explico de forma ordenada para que lo puedas trasladar directo al desarrollador:

---

## En la Ficha del Trabajador

Necesitas dos campos nuevos que trabajan juntos:

*Campo 1: Tipo de remuneración*

Un campo tipo lista desplegable (ENUM) con estas opciones:

•⁠  ⁠⁠ mensual ⁠ → sueldo fijo al mes

•⁠  ⁠⁠ semanal ⁠ → sueldo fijo por semana

•⁠  ⁠⁠ diario ⁠ → sueldo por día trabajado

•⁠  ⁠⁠ por_hora ⁠ → se paga por cada hora trabajada

*Campo 2: Jornada semanal pactada (en horas)*

Un número decimal. Ejemplos: ⁠ 44 ⁠, ⁠ 40 ⁠, ⁠ 30 ⁠. Este valor es el divisor clave en todas las fórmulas. No debe ser un ENUM fijo porque la Ley 40 Horas está reduciendo gradualmente la jornada, y distintas empresas ya van en tramos diferentes (44h, 42h, 40h).

*Campo 3 (solo para trabajadores ⁠ diario ⁠):* Días de trabajo por semana. Generalmente 5, pero puede ser 6 en algunos rubros.

---

## En los Parámetros del Sistema

Agrega una tabla de *Factores de Cálculo de Hora Extra* que el sistema use automáticamente según la jornada. Así no hardcodeas el factor en el código:

| Jornada semanal | Horas al mes (×4 sem) | Factor mensual (ya con 50%) |

|---|---|---|

| 44 horas | 176 | 0.0079545 |

| 42 horas | 168 | 0.0083333 |

| 40 horas | 160 | 0.0087500 |

| 45 horas (histórico) | 180 | 0.0077778 |

El factor se calcula así: ⁠ (28/30) / horas_mensuales × 1.5 ⁠. El sistema debería *calcularlo automáticamente* desde la jornada, no requerir que el usuario lo ingrese.

---

## En el Ingreso de Variables del Mes

En la pantalla donde se ingresan los movimientos del período, agrega:

| Variable | Tipo | Regla |

|---|---|---|

| Horas extras al 50% | Decimal | Recargo estándar (domingos, festivos y nocturno incluidos) |

| Horas extras al 100% | Decimal | Solo si hay pacto especial escrito |

| Semana corrida (monto) | Número CLP | Solo aplica para trabajadores ⁠ diario ⁠ y ⁠ por_hora ⁠ |

---

## La Lógica de Cálculo (para el desarrollador)

El sistema debe detectar el ⁠ tipo_remuneracion ⁠ del trabajador y aplicar la fórmula correspondiente:

Si tipo = "mensual":

valor_hora_extra = (sueldo_base / 30 × 28 / horas_semanales × 4) × 1.5

Si tipo = "semanal":

valor_hora_extra = (sueldo_semanal / jornada_semanal) × 1.5

Si tipo = "diario":

valor_hora_extra = ((sueldo_diario × dias_semana + semana_corrida) / jornada_semanal) × 1.5

Si tipo = "por_hora":

  Si NO hay semana corrida:

valor_hora_extra = valor_hora × 1.5

  Si HAY semana corrida:

valor_hora_extra = (valor_hora + semana_corrida / horas_trabajadas_semana) × 1.5

Total horas extras mes = valor_hora_extra × cantidad_horas_extras_50

---

## Un detalle importante sobre la base de cálculo

El artículo que compartiste lo confirma: *las horas extras se calculan solo sobre el sueldo base pactado*. Los bonos, comisiones y gratificaciones no entran en la base. Por eso en la ficha del concepto "horas extras" debes marcar explícitamente qué componente del sueldo es la base, y el sistema no debe incluir los otros haberes en ese cálculo.

---

## Resumen de campos a agregar

TABLA TRABAJADORES — campos nuevos:

  tipo_remuneracion     ENUM('mensual','semanal','diario','por_hora')

  jornada_horas_semana  DECIMAL(5,2)   -- ej: 44.00

  dias_trabajo_semana   INT DEFAULT 5  -- para tipo 'diario'

  valor_hora            DECIMAL(10,2)  -- solo si tipo = 'por_hora'

  sueldo_semanal        DECIMAL(12,2)  -- solo si tipo = 'semanal'

TABLA VARIABLES_MES — campos nuevos:

  horas_extras_50       DECIMAL(6,2)

  horas_extras_100      DECIMAL(6,2)

  semana_corrida        DECIMAL(12,2)  -- para diario y por_hora

Con esta estructura, el módulo puede calcular correctamente las horas extras para cualquier tipo de trabajador, y está preparado para adaptarse a los cambios de jornada que vienen con la Ley 40 Horas sin necesidad de modificar el código.




## Configuración Salarial Base

Sacar checkbox Aplica Semana Corrida -> posible derivacion a concepto global haber -> imponible

## Modal -> Contrato de Trabajo

Incluir como sera la `forma de pago`: Mensual, Semanal, dia o por Hora.
