# Medidas DAX

Crea estas medidas dentro de `fct_prestamo`.

## Clientes

```dax
Total clientes =
DISTINCTCOUNT('dim_cliente'[id_cliente])
```

```dax
Clientes con préstamo =
DISTINCTCOUNT('fct_prestamo'[id_cliente])
```

## Préstamos

```dax
Total préstamos =
COUNTROWS('fct_prestamo')
```

```dax
Préstamos vigentes =
CALCULATE(
    [Total préstamos],
    'fct_prestamo'[estado_prestamo] = "VIGENTE"
)
```

## Importes

```dax
Monto desembolsado =
SUM('fct_prestamo'[monto_desembolso])
```

```dax
Saldo pendiente =
SUM('fct_prestamo'[saldo_pendiente])
```

```dax
Monto pagado =
SUM('fct_prestamo'[monto_pagado])
```

```dax
Porcentaje pagado =
DIVIDE(
    [Monto pagado],
    [Monto desembolsado],
    0
)
```

```dax
Ticket promedio =
AVERAGE('fct_prestamo'[monto_desembolso])
```

```dax
Tasa promedio =
AVERAGE('fct_prestamo'[tasa_interes_anual])
```

Formatea importes como moneda, `Porcentaje pagado` como porcentaje y
`Tasa promedio` con dos decimales. Si tu configuración regional usa punto y
coma en DAX, reemplaza las comas de los argumentos por `;`.
