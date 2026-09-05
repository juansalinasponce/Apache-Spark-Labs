# Dashboard básico

Nombre del reporte:

```text
rpt_banca_dev_clientes_prestamos
```

Usa una sola página llamada **Resumen comercial**.

## Fila superior — Indicadores

Crea cinco tarjetas:

1. `Clientes con préstamo`.
2. `Total préstamos`.
3. `Monto desembolsado`.
4. `Saldo pendiente`.
5. `Porcentaje pagado`.

## Visual 1 — Evolución mensual

Tipo: gráfico de columnas.

| Campo | Valor |
|---|---|
| Eje X | `fct_prestamo[fecha_desembolso]` por mes |
| Valores | `Monto desembolsado` |

## Visual 2 — Colocaciones por tipo

Tipo: barras horizontales.

| Campo | Valor |
|---|---|
| Eje Y | `fct_prestamo[tipo_prestamo]` |
| Eje X | `Monto desembolsado` |

## Visual 3 — Clientes por segmento

Tipo: columnas.

| Campo | Valor |
|---|---|
| Eje X | `dim_cliente[segmento]` |
| Valores | `Clientes con préstamo` |

## Visual 4 — Estado de préstamos

Tipo: gráfico de dona.

| Campo | Valor |
|---|---|
| Leyenda | `fct_prestamo[estado_prestamo]` |
| Valores | `Total préstamos` |

## Visual 5 — Detalle por cliente

Tipo: matriz.

| Campo | Valor |
|---|---|
| Filas | `dim_cliente[nombre_completo]` |
| Valores | `Total préstamos`, `Monto desembolsado`, `Saldo pendiente` |

## Segmentadores

Agrega dos filtros:

- `dim_cliente[segmento]`;
- `fct_prestamo[tipo_prestamo]`.

No agregues más páginas ni visuales en esta primera versión. El objetivo es que
un estudiante complete el flujo completo rápidamente y entienda la relación
entre dimensión, hecho y medida.
