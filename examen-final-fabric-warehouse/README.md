# Examen final — Fabric Warehouse: cuentas, canales y transacciones

Paquete de examen práctico guiado que sigue el patrón del Lab07. Toda la transformación Bronze → Silver → Gold ocurre en T-SQL en un único Warehouse. Se ingieren tres tablas reales de MySQL: banco_cuenta, banco_canal y banco_transaccion.

Leer EXAMEN_FINAL_PASO_A_PASO.pdf: incluye enunciado, guía, pipeline, modelo/dashboard y todos los scripts SQL/DAX como anexos. Los mismos contenidos están disponibles en archivos editables.

- ENUNCIADO.md: alcance, entregables y rúbrica sobre 100.
- GUIA_PASO_A_PASO.md: construcción y validación de principio a fin.
- sql/mysql/: inspección del origen.
- sql/fabric/: nueve scripts de estructura, cargas y controles.
- pipeline/CONFIGURACION_PIPELINE.md: tres copias, scripts, refresh y programación.
- powerbi/MODELO_Y_DASHBOARD.md y medidas.dax: relaciones, visuales y medidas.
- scripts/generar_pdf.py: reconstruye el PDF desde los archivos del paquete.

Flujo: MySQL → Bronze (tres tablas) → Silver (tres tablas) → Gold (dim_cuenta, dim_canal, dim_fecha, fct_transaccion) → modelo Direct Lake → reporte → dashboard.

Cuenta y canal se relacionan mediante transacción, sin inventar un id_canal en cuenta. El saldo es una foto actual y se presenta por moneda. El pipeline usa full refresh sin ejecuciones simultáneas.

El material no incluye credenciales ni recursos ya desplegados en Fabric: los estudiantes los construyen como parte del examen. La guía PDF se genera con Python y ReportLab: instalar reportlab y ejecutar python scripts/generar_pdf.py desde cualquier directorio. La generación PDF es una utilidad editorial; el laboratorio no ejecuta notebooks Python ni PySpark.
