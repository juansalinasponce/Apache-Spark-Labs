# Modelo semántico, reporte y dashboard

## Crear el modelo

Después de validar Gold, abrir el Warehouse → New semantic model. Nombre: sm_banca_final_<apellido>, mismo workspace. Seleccionar solo gld.dim_cuenta, gld.dim_canal, gld.dim_fecha y gld.fct_transaccion. Elegir Direct Lake. No incluir Bronze/Silver ni confiar en la creación automática de un modelo.

Abrir Open data model y renombrar las tablas en el modelo como dim_cuenta, dim_canal, dim_fecha y fct_transaccion; son los nombres usados por medidas.dax. Estos cambios no renombrarán las tablas SQL. Asegurar tipos: identificadores enteros, saldo/monto decimal, fecha tipo Fecha y fecha_transaccion tipo Fecha/hora.

Relaciones activas, 1:* y filtro único hacia el hecho:

- dim_cuenta[id_cuenta] → fct_transaccion[id_cuenta].
- dim_canal[id_canal] → fct_transaccion[id_canal].
- dim_fecha[fecha] → fct_transaccion[fecha].

No crear relaciones cuenta-canal, cuenta-calendario ni relaciones bidireccionales. Marcar dim_fecha como tabla de fechas, columna fecha, cuando la interfaz lo permita. anio_mes está en formato YYYY-MM y se ordena ascendentemente. Ocultar claves técnicas en la lista de campos; no sumar identificadores.

## Medidas

Abrir powerbi/medidas.dax y crear una medida por vez con Nueva medida. El archivo no es un script SQL ni debe pegarse entero como una sola medida. Formato: conteos enteros, porcentajes con dos decimales, importes con dos decimales y moneda explícita en el título.

El saldo_actual es una foto actual en dim_cuenta, no saldo histórico mensual. Un filtro de canal o fecha filtra transacciones, pero no la dimensión cuenta: Total Cuentas y Saldo PEN/USD no cambian con esos filtros. Para contar cuentas bajo filtros de fecha/canal usar Cuentas con Operaciones, basada en el hecho. No usar SUM de saldo después de unir cada cuenta con sus transacciones.

Monto Aprobado representa volumen de operaciones registradas aprobadas; no ingresos, utilidad ni saldo. Puede incluir ambos lados de transferencias. No interpretar naturaleza CREDITO/DEBITO como ingreso/gasto del banco ni aplicar fórmulas de saldo histórico. La moneda se obtiene de la cuenta: se asume que el monto está expresado en esa moneda, confirmar esta regla con el docente.

## Página 1: Cuentas y saldos actuales

Crear rpt_banca_final_<apellido>. Página Cuentas:

- Tarjetas: Total Cuentas, Cuentas Activas, Saldo PEN, Saldo USD.
- Barras: eje dim_cuenta[tipo_cuenta], valores Total Cuentas.
- Dona: leyenda dim_cuenta[estado], valores Total Cuentas.
- Matriz: filas tipo_cuenta y moneda; valores Total Cuentas, Saldo PEN, Saldo USD.
- Segmentadores: dim_cuenta[moneda], dim_cuenta[tipo_cuenta], dim_cuenta[estado].

No poner un saldo histórico por fecha de transacción. No añadir canal como categoría de saldo.

## Página 2: Operaciones por canal

- Tarjetas: Total Transacciones, Transacciones Aprobadas, Porcentaje Aprobacion, Cuentas con Operaciones.
- Barras: eje dim_canal[nombre_canal]; valores Transacciones Aprobadas; ordenar descendente.
- Línea: eje dim_fecha[anio_mes]; valores Transacciones Aprobadas; ordenar por mes ascendente.
- Barras de monto: canal y Monto Aprobado PEN. Segundo gráfico canal y Monto Aprobado USD, con títulos claros.
- Dona: leyenda fct_transaccion[estado]; valores Total Transacciones.
- Matriz: canal y moneda; valores Transacciones Aprobadas, Monto Aprobado PEN, Monto Aprobado USD.
- Segmentadores: dim_fecha[anio_mes], dim_canal[tipo_canal], dim_cuenta[moneda], fct_transaccion[estado].

No sincronizar el segmentador de fecha/canal con la página de saldos. Al seleccionar RECHAZADA, Transacciones Aprobadas debe ser cero o vacío, nunca mostrar aprobadas de otro estado. Si se desea mostrar cero en todos los gráficos, envolver la medida con COALESCE.

## Dashboard en Power BI Service

Guardar el reporte en el workspace. Anclar al menos cuatro visuales a un dashboard nuevo llamado db_banca_final_<apellido>: cuentas, saldo PEN, saldo USD y operaciones por canal. Incluir enlace al reporte para explorar filtros. Un dashboard de mosaicos y un reporte son artefactos distintos; las segmentaciones interactivas se prueban en el reporte.

Volver al pipeline y agregar Semantic model refresh al final. Si Direct Lake permite actualización automática, desactivarla para controlar el momento de publicación durante el examen y refrescar explícitamente al finalizar Gold. Ejecutar el pipeline y volver a abrir/refrescar la vista del reporte; los mosaicos pueden tener caché, verificar el reporte para la evidencia inmediata.

## Comprobación

Ejecutar sql/fabric/09_consultas_dashboard.sql. Sin filtros, cotejar cada canal y moneda con las medidas de aprobadas. Luego elegir un mes y una moneda; repetir SQL con WHERE equivalente. Mostrar diferencias igual a cero. Filtrar un canal y verificar que Cuentas con Operaciones cambia, mientras Total Cuentas conserva la foto de cuentas. Capturar relaciones, dos páginas, dashboard y actualización semántica exitosa.
