# Reto de pipeline — Seguros comerciales

Construye un pipeline desde MySQL/MariaDB hacia Microsoft Fabric sin ejecutar
consultas analíticas directamente contra el OLTP.

## Bronze

Copia completa para catálogos y maestros:

- `aseguradora_ubicacion`
- `aseguradora_producto`
- `aseguradora_broker`
- `aseguradora_canal_venta`
- `aseguradora_medio_pago`
- `aseguradora_tipo_siniestro`
- `aseguradora_cliente`

Para tablas transaccionales utiliza cursores compuestos:

| Tabla | Cursor incremental recomendado |
|---|---|
| `aseguradora_cotizacion` | `(fecha_cotizacion, id_cotizacion)` |
| `aseguradora_poliza` | `(fecha_emision, id_poliza)` |
| `aseguradora_pago` | `(fecha_pago, id_pago)` |
| `aseguradora_siniestro` | `(fecha_reporte, id_siniestro)` |

`aseguradora_cuota` contiene estado y saldo mutable. Cárgala completa en este
laboratorio o impleméntale una columna `actualizado_en` para practicar CDC por
marca de tiempo.

## Silver

- normaliza texto y estados;
- valida importes no negativos y fechas coherentes;
- conserva pagos rechazados, pero no los sumes como cobranza;
- crea `monto_incorrido = monto_pagado + monto_reserva`;
- identifica cuotas vencidas y días de mora;
- evita mezclar cotizaciones con ventas emitidas;
- anonimiza documento, correo y teléfono del cliente.

## Gold

Propón estas tablas analíticas:

```text
gold_ventas_mensuales
gold_embudo_comercial
gold_desempeno_broker
gold_cobranza_mensual
gold_siniestralidad_producto
gold_geografia_comercial
gold_cliente_360
```

El tablero final debe incluir prima emitida, prima cobrada, conversión, deuda
vencida, frecuencia de siniestros, severidad, siniestralidad simplificada y
ranking de brokers.

