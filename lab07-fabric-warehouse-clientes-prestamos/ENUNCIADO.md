# Enunciado para el estudiante

El banco necesita un reporte sencillo que describa a sus clientes y las
colocaciones de préstamos realizadas. La información se encuentra en MySQL y
debe llegar a un Warehouse de Microsoft Fabric organizado en Bronze, Silver y
Gold.

## Objetivo

Construir un pipeline de carga completa para responder:

1. ¿Cuántos clientes contrataron préstamos?
2. ¿Cuántos préstamos fueron desembolsados?
3. ¿Cuál es el monto desembolsado y el saldo pendiente?
4. ¿Qué tipo de préstamo concentra más colocaciones?
5. ¿Qué segmentos de clientes concentran más préstamos?
6. ¿Cómo evolucionaron los desembolsos por mes?

## Restricciones

- Utilizar únicamente `banco_cliente` y `banco_prestamo` como fuentes.
- Crear un solo Warehouse.
- Separar las capas mediante schemas `brz`, `slv` y `gld`.
- Usar Copy Data para la ingesta.
- Usar T-SQL básico para Silver y Gold.
- Crear solamente `gld.dim_cliente` y `gld.fct_prestamo`.
- Crear una sola página de reporte.

## Criterios de finalización

- El pipeline termina sin errores.
- Los conteos se conservan entre capas.
- No existen préstamos sin cliente en Gold.
- El modelo semántico tiene una relación activa `1:*`.
- El reporte contiene indicadores, tendencia, distribución y detalle.
