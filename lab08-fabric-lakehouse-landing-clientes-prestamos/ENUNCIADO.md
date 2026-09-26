# Enunciado — Fabric 02: arquitectura híbrida con SCD Tipo 2

## Situación

El banco necesita analizar clientes y colocaciones de préstamos. La información
se origina en las tablas MySQL `banco_cliente` y `banco_prestamo`.

El equipo de Data Engineering ha decidido usar una arquitectura híbrida de
Microsoft Fabric:

- Bronze y Silver estarán en un Lakehouse con tablas Delta;
- Gold estará en un Warehouse orientado al consumo analítico;
- los cambios de atributos del cliente deben conservarse mediante SCD Tipo 2.

## Objetivo

Construir un pipeline completo que permita responder:

1. ¿Cuántos clientes tienen préstamos?
2. ¿Cuántos préstamos fueron desembolsados?
3. ¿Cuál es el monto desembolsado, pagado y pendiente?
4. ¿Qué segmentos concentran más colocaciones?
5. ¿Cómo evolucionan los desembolsos por mes?
6. ¿Qué atributos tenía un cliente antes y después de una modificación?

## Arquitectura obligatoria

```text
MySQL
  │
  ├── banco_cliente
  └── banco_prestamo
          │
          ▼
Lakehouse: lh_banca_dev_medallion
  ├── brz.banco_cliente       (todas las columnas STRING)
  ├── brz.banco_prestamo      (todas las columnas STRING)
  ├── slv.cliente             (tipificada e histórica)
  └── slv.prestamo            (tipificada, último estado)
          │
          ▼
Warehouse: wh_banca_dev_gold
  ├── stg.cliente
  ├── stg.prestamo
  ├── gld.dim_cliente
  └── gld.fct_prestamo
```

## Requerimientos de Bronze

1. Usa un Lakehouse con schemas habilitados.
2. Crea `brz.banco_cliente` y `brz.banco_prestamo` como tablas Delta.
3. Declara todas las columnas de Bronze como `STRING`.
4. Usa carga completa: limpia Bronze y copia el snapshot actual de MySQL.
5. No agregues PK, FK, índices ni reglas de calidad en Bronze.

## Requerimientos de Silver

1. Crea `slv.cliente` y `slv.prestamo` como tablas Delta tipificadas.
2. Usa `TRY_CAST` para convertir identificadores, fechas, montos y tasas.
3. Normaliza texto con `TRIM`, `UPPER` o `LOWER` según corresponda.
4. Deduplica por la clave de negocio antes de ejecutar un `MERGE`.
5. Usa `id_cliente` como clave de negocio de la dimensión.
6. Detecta cambios del cliente mediante un hash de atributos.
7. Implementa SCD Tipo 2 con estas columnas de control:
   `cliente_sk`, `vigente_desde`, `vigente_hasta`, `es_actual`,
   `hash_atributos` y `fecha_proceso`.
8. Una modificación debe cerrar la versión actual e insertar una nueva.
9. Una ejecución sin cambios no debe insertar otra versión.
10. Procesa `slv.prestamo` mediante upsert Tipo 1 por `id_prestamo`.

El ejercicio no exige detectar eliminaciones físicas del origen. Para representar
una baja, modifica el atributo `estado`; ese cambio sí debe generar una nueva
versión SCD2.

## Requerimientos de Gold

1. Crea un Warehouse independiente llamado `wh_banca_dev_gold`.
2. Usa `stg` como zona de transferencia desde el Lakehouse.
3. Usa `gld` para el modelo dimensional.
4. Crea únicamente `gld.dim_cliente` y `gld.fct_prestamo` como tablas finales.
5. Conserva en `gld.dim_cliente` todas las versiones procedentes de Silver.
6. Relaciona `gld.fct_prestamo.cliente_sk` con
   `gld.dim_cliente.cliente_sk`.
7. Calcula en Gold el monto pagado y el año y mes del desembolso.
8. Usa `MERGE` para que la carga Gold sea repetible.

## Prueba obligatoria de SCD Tipo 2

1. Ejecuta el pipeline con el snapshot inicial.
2. Elige un cliente que tenga préstamo y registra su `id_cliente`.
3. Modifica en MySQL uno de estos atributos: `segmento`, `estado`, `email` o
   `telefono`.
4. Ejecuta nuevamente el pipeline.
5. Comprueba en `slv.cliente` y `gld.dim_cliente` que:
   - existen dos versiones del cliente;
   - la versión anterior tiene `es_actual = false`;
   - la versión nueva tiene `es_actual = true`;
   - las vigencias no quedan abiertas simultáneamente;
   - cada versión tiene un `cliente_sk` diferente.
6. Ejecuta por tercera vez sin modificar el origen y comprueba que no aparece
   una tercera versión.

## Entregables

- DDL Spark SQL de Bronze y Silver.
- Transformación Silver con `MERGE` SCD Tipo 2.
- DDL y carga T-SQL de staging y Gold.
- Pipeline ejecutado correctamente.
- Evidencia del cliente antes y después del cambio.
- Resultados de las consultas de validación.
- Diagrama del modelo semántico con relación `dim_cliente 1:* fct_prestamo`.

## Criterios de finalización

- Bronze contiene dos tablas Delta y todas sus columnas son `STRING`.
- Silver contiene tipos de datos de negocio válidos.
- Cada cliente tiene exactamente una versión actual.
- La segunda ejecución conserva la versión anterior del cliente modificado.
- Una ejecución sin cambios es idempotente.
- Gold conserva el mismo historial que Silver.
- No existen préstamos Gold sin dimensión de cliente.
- El pipeline finaliza sin errores.
