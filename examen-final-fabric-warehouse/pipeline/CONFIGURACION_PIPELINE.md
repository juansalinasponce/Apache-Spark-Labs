# Pipeline automatizado

Nombre: pl_banca_final_cuentas_canales_<apellido>. Destino: wh_banca_final_<apellido>. Seleccionar ese Warehouse en todas las actividades Script; usar tipo NonQuery para carga y Query para consultas de resultados. El archivo 08 contiene controles y SELECT: usar un bloque Query compatible con múltiples sentencias o dividir sus SELECT en un segundo bloque Query.

## Orden y dependencias

act_01_limpiar_bronze → tres Copy Data en paralelo → act_05_cargar_silver → act_06_cargar_gold → act_07_validar → act_08_refrescar_modelo.

Cada flecha es On success. Silver debe tener tres dependencias, una por cada copia. Una copia fallida debe impedir Silver, Gold y la actualización del modelo. No basta conectar solo una de las ramas.

## Actividades

1. Script act_01_limpiar_bronze: sql/fabric/05_limpiar_bronze.sql.
2. Copy Data act_02_copiar_cuenta: banco_cuenta → brz.banco_cuenta.
3. Copy Data act_03_copiar_canal: banco_canal → brz.banco_canal.
4. Copy Data act_04_copiar_transaccion: banco_transaccion → brz.banco_transaccion.
5. Script act_05_cargar_silver: sql/fabric/06_cargar_silver.sql completo, en una sola sesión/bloque. Las tablas temporales necesitan esa sesión.
6. Script act_06_cargar_gold: sql/fabric/07_cargar_gold.sql completo en una sola sesión/bloque.
7. Script act_07_validar: sql/fabric/08_validar_capas.sql.
8. Semantic model refresh act_08_refrescar_modelo: seleccionar workspace y sm_banca_final_<apellido>; esperar su finalización. Crear esta actividad después de crear el modelo. En Direct Lake actualiza el framing; en Import actualizaría los datos importados.

## Configurar cada copia

Source: conexión MySQL del curso, base de datos correcta, Table y tabla indicada. Destination: Fabric Warehouse existente, schema brz y tabla precreada. Acción Append, sin crear ni reemplazar tablas. En Mapping → Import schemas, mapear todas las columnas por nombre; los destinos Bronze son VARCHAR(250). Revisar conversión de enteros, decimales y fechas a texto. Verificar que fecha_transaccion conserva milisegundos, que decimal usa punto y que las fechas son ISO. No seleccionar solo las columnas del dashboard.

Si el conector no entrega fechas ISO, usar una consulta MySQL SELECT con DATE_FORMAT(fecha_apertura, '%Y-%m-%d') para cuenta y DATE_FORMAT(fecha_transaccion, '%Y-%m-%d %H:%i:%s.%f') para transacción, conservando los alias originales y las demás columnas. No colocar contraseñas en consultas.

Retry: 0 en las tres Copy Data para evitar duplicar filas con Append tras una copia parcial. Ante fallo, ejecutar TODO el pipeline desde la limpieza Bronze. No ejecutar instancias solapadas ni lanzar una ejecución manual mientras corre la programada. Si la UI ofrece límite de concurrencia, fijarlo en 1; de lo contrario, controlar el horario y esperar la finalización.

## Programación

Guardar, ejecutar manualmente y comprobar el historial. Agregar Schedule: diariamente a las 07:00, zona America/Lima (UTC-05:00; la interfaz puede mostrar Lima/Bogotá), con inicio y fin dentro del periodo del examen. Para demostrar automatización, programar una ejecución cercana, esperar su finalización y capturar historial, hora y tipo de ejecución. Luego mantener el horario diario solicitado. Si una ejecución dura más que el intervalo, ampliar el intervalo.

## Prueba de error

En una copia del pipeline, cambiar temporalmente la tabla de origen a un nombre inexistente. Ejecutar y demostrar que Silver/Gold/refresh no se ejecutan. Restaurar y correr el pipeline completo. No alterar MySQL ni los datos compartidos. La limpieza afecta solo al Warehouse propio.

Esta carga es full refresh, no incremental. Las copias paralelas no constituyen un snapshot transaccional conjunto de MySQL: usar un origen estable durante el examen. Silver y Gold se publican cada una dentro de una transacción. Bronze puede quedar parcial si falla una copia, por eso se exige reiniciar desde el inicio.
