# Examen final — Analítica bancaria con Fabric Warehouse

Construye una solución que responda: ¿cuántas cuentas existen?, ¿qué saldos tienen por moneda?, ¿qué canales procesan más operaciones?, ¿cómo evoluciona la actividad y qué proporción se aprueba?

## Alcance y reglas

Usar banco_cuenta, banco_canal y banco_transaccion del MySQL del curso. Cuenta y canal no se relacionan directamente; transacción contiene ambas claves. No modificar el origen ni asignar canales ficticios a cuentas.

Arquitectura obligatoria: MySQL → Copy Data → Bronze → T-SQL → Silver → T-SQL → Gold → modelo semántico → reporte y dashboard. Las tres capas viven en un único Fabric Warehouse. No se usan notebooks, PySpark, Lakehouse ni Dataflows. DAX se usa solamente para las medidas del modelo; la ingesta se configura mediante Copy Data.

La entrega es un examen práctico guiado con código de apoyo: el estudiante crea los artefactos, ejecuta y explica los scripts, configura las conexiones y demuestra el resultado. Tiempo sugerido: 5 horas, ajustable por el docente.

## Entregables

1. Warehouse exclusivo con schemas brz, slv y gld y tablas pobladas.
2. Pipeline completo con dependencias por éxito y ejecución programada.
3. Modelo semántico con dos dimensiones de negocio, calendario y un hecho.
4. Reporte de dos páginas y dashboard del servicio con al menos cuatro mosaicos.
5. Scripts entregados y evidencia de conciliación SQL contra Power BI.
6. Dos ejecuciones completas exitosas sin duplicados, una ejecución programada y una prueba de error controlada.
7. Informe breve: grano, relaciones, monedas, estrategia de carga, limitaciones y tres conclusiones comerciales basadas en datos.

No entregar credenciales. Los conteos dependen del MySQL que entregue el docente; no se califican contra cifras inventadas.

## Evaluación sobre 100 puntos

- Bronze y mapping completo: 15 puntos.
- Silver, tipos y controles de calidad: 20 puntos.
- Gold, grano, calendario y conciliación: 20 puntos.
- Pipeline, dependencias, actualización semántica y programación: 20 puntos.
- Modelo, medidas, reporte y dashboard: 20 puntos.
- Evidencias y explicación: 5 puntos.

Sumar PEN y USD como un único monto, relacionar directamente cuenta con canal o repetir saldos por transacción invalida el indicador afectado. El docente evalúa comprensión mediante una modificación de filtro y una explicación SQL del mismo resultado.
