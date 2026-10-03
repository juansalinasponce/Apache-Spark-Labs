# Guía paso a paso — 90 minutos

## 1. Conocer el caso e importar (0–15 min)

Responder: ¿qué sede entrega más pasaportes?, ¿cómo cambian las solicitudes por mes?, ¿qué departamentos concentran la atención?, ¿cuánto tarda una entrega?

1. Abrir Power BI Desktop → Informe en blanco.
2. Inicio → Obtener datos → Libro de Excel → `datos/01_tramites_pasaportes.xlsx`.
3. En Navegador seleccionar **Tramites**, luego **Transformar datos**.
4. En Power Query: Inicio → Nuevo origen → Excel → `02_sedes.xlsx`; seleccionar **Sedes**.
5. Renombrar las consultas exactamente `Tramites` y `Sedes`. Si aparecen Column1, Column2… elegir **Usar la primera fila como encabezados**. No hacerlo dos veces.

## 2. Limpiar con Power Query (15–35 min)

En **Tramites**:

1. Si el paso automático **Tipo cambiado** genera errores en fechas, eliminar ese paso y aplicar los tipos manualmente.
2. Seleccionar `Canal` y `Estado` → Transformar → Formato → **Limpiar**, **Recortar**, **MAYÚSCULAS**. Comprobar que WEB y ENTREGADO ya no tienen variantes.
3. Seleccionar `FechaSolicitud` y `FechaEntrega` → tipo de datos → **Usar configuración regional** → Fecha → Español (Perú). El origen usa `yyyy-MM-dd`; los vacíos de entrega deben permanecer `null`. Si el equipo no reconoce ISO, usar la consulta M de solución, que especifica el formato explícito.
4. Tipos: `TramiteID`, `SedeID`, `TipoTramite`, `Canal`, `Estado` como Texto; `EdadSolicitante` como Número entero; `ImporteReferencial` como Número decimal fijo.
5. Seleccionar **solo TramiteID** → Inicio → Quitar filas → Quitar duplicados. De 9.624 pasar a **9.600** filas. No quitar las solicitudes sin entrega.
6. Vista → Calidad de columna. Para revisar todo el archivo, cambiar el perfil de las primeras 1.000 filas a **conjunto de datos completo** en la barra inferior.

En **Sedes**, dejar las seis primeras columnas como Texto y Latitud/Longitud como Número decimal. Debe haber **12** claves SedeID únicas.

**Cerrar y aplicar**. La preparación ocurre antes de cargar el modelo. No usar Combinar ni Anexar: los archivos permanecerán como dos tablas relacionadas.

**Solución de rescate:** seleccionar una consulta → Editor avanzado y pegar el contenido del `.m` correspondiente en `powerquery/`. Cambiar `C:\Lab09\datos\...` por la ruta real. En M las barras invertidas son literales: usar una sola barra. Estas consultas sustituyen los pasos completos; no se pegan en el cuadro de columna personalizada.

## 3. Relacionar y crear el calendario (35–50 min)

1. Vista Modelo → arrastrar `Sedes[SedeID]` a `Tramites[SedeID]`.
2. Revisar cardinalidad **Uno a varios (1:*)**, relación activa, dirección de filtro **Única**, de Sedes a Tramites. No usar varios a varios.
3. Modelado → **Nueva tabla** → pegar únicamente el bloque `DimFecha` de [formulas.dax](dax/formulas.dax).
4. Esa fórmula usa MIN y MAX de `FechaSolicitud` del Excel; crea cada día del 01/10/2025 al 30/09/2026, incluidos días sin solicitudes. No requiere un tercer Excel.
5. Confirmar que `DimFecha[Fecha]` tiene tipo Fecha. Ordenar `Mes` por `MesNumero` y `AnioMes` por `AnioMesOrden`: seleccionar columna → Herramientas de columna → Ordenar por columna.
6. Relacionar `DimFecha[Fecha]` (1) con `Tramites[FechaSolicitud]` (*), activa y con filtro único hacia Tramites.
7. Usar `DimFecha[AnioMes]` en el eje temporal, sin la jerarquía automática de fecha. La tabla tiene fechas continuas, únicas y sin nulos. Si la versión muestra **Marcar como tabla de fechas**, se puede seleccionar `Fecha`; este lab no utiliza inteligencia temporal clásica ni necesita activar funciones en vista previa.

**Alternativa opcional para el instructor:** crear una consulta en blanco llamada DimFecha y pegar `powerquery/DimFecha_opcional.m`. No crear simultáneamente las versiones M y DAX. La ruta principal de 90 minutos utiliza DAX.

## 4. Campos calculados y medidas (50–65 min)

Seleccionar **Tramites** → Nueva columna → pegar `DiasAtencion`; repetir para `GrupoEdad`. Explicar que cada columna se calcula para cada solicitud: 05/01 a 10/01 equivale a 5 días calendario; una solicitud pendiente queda vacía, no en cero.

Luego **Nueva medida**, una por una:

- `Total Tramites`: contar filas después de limpiar duplicados.
- `Pasaportes Entregados`: contar solicitudes con estado ENTREGADO.
- `Porcentaje Entrega`: entregados / solicitudes del contexto actual.
- `Dias Promedio`: promedio de DiasAtencion; AVERAGE ignora los vacíos.
- `Tramites Pendientes`: medida adicional si queda tiempo.

Todas las fórmulas están en `dax/formulas.dax`. No pegar el archivo completo como una fórmula. Los ejemplos usan comas; si Desktop tiene habilitados separadores DAX regionales y pide punto y coma, cambiar el separador de argumentos o deshabilitar esa opción.

Formatear conteos como enteros, porcentaje con **2 decimales** y días con **2 decimales**. En tarjetas, poner unidades de visualización **Ninguna** para ver 9.600 en lugar de 9,6 mil.

**Columna vs medida:** DiasAtencion conserva un valor por trámite; Dias Promedio se recalcula al elegir otra sede. KEEPFILTERS hace que la medida de entregados respete un filtro de Estado; al elegir EN PROCESO no debe mostrar entregados de otro estado. La tasa en ese filtro será 0 y el promedio de días estará vacío.

## 5. Construir la página (65–85 min)

Formato de página 16:9. Vista → Temas → Examinar temas → `tema_migraciones.json`. Título **Pasaportes por sede**; subtítulo **Datos simulados | Oct 2025 – Sep 2026 | Corte: 30/09/2026**. La imagen es una referencia de diseño.

| Visual | Campos y configuración |
|---|---|
| Cuatro tarjetas superiores | Total Tramites; Pasaportes Entregados; Porcentaje Entrega; Dias Promedio |
| Segmentadores desplegables | DimFecha[AnioMes], Sedes[Departamento], Sedes[Sede], Tramites[Estado] |
| Barras horizontales | Eje Y: Sedes[Sede]; eje X: Pasaportes Entregados; ordenar por medida descendente; título Entregados por sede. Para imitar la imagen, filtro visual Top N = 6 por Pasaportes Entregados y Aplicar filtro |
| Línea | Eje X: DimFecha[AnioMes], categórico y ascendente; eje Y: Pasaportes Entregados; título Entregados por mes de solicitud |
| Dona | Leyenda: Tramites[Estado]; valores: Total Tramites |
| Tabla | Sedes[Departamento], Pasaportes Entregados; mostrar total. Opcional: Total Tramites y Dias Promedio |
| Mapa opcional | Categorizar Sedes[Latitud] como Latitud y Longitud como Longitud; no resumir coordenadas; en Azure Maps agregar ambas, Sede como ubicación/detalle según versión y Pasaportes Entregados como tamaño; Departamento en información sobre herramientas |

Priorizar tarjetas, barras, línea y tabla. Dona y mapa son extensiones si queda tiempo. El mapa requiere conexión y puede estar deshabilitado por el administrador. Si no está disponible, usar barras por Departamento: se conserva el análisis geográfico y la clase sigue adelante.

**Interpretación del tiempo:** la línea cuenta solicitudes realizadas en cada mes que se entregaron al corte. No es una línea por fecha de entrega. Septiembre tiene solicitudes recientes pendientes; no concluir automáticamente que empeoró el desempeño. Para mantener el nivel básico, no crear otra relación con FechaEntrega.

## 6. Validar y guardar (85–90 min)

Limpiar todos los segmentadores y selecciones de los gráficos:

| Control | Resultado |
|---|---:|
| Total Tramites | 9.600 |
| Pasaportes Entregados | 7.657 |
| Porcentaje Entrega | 79,76 % |
| Dias Promedio | 9,85 |
| Tramites Pendientes | 1.078 |
| Filas de Sedes | 12 |
| Fechas de DimFecha | 365 |

Pruebas con filtros:

1. Departamento **Lima** → entregados **2.895**. Quitar filtro.
2. Sede **Lima Centro (simulada)** → entregados **1.692**. Quitar filtro.
3. AnioMes **2026-09** → **690** solicitudes y **378** entregados. Quitar filtro.
4. Estado **EN PROCESO** → **1.078** trámites, 0 entregados y días promedio vacío. Quitar filtro.

Archivo → Guardar como → `lab09_migraciones_pasaportes.pbix`. Cerrar y volver a abrir para comprobar que el informe sigue disponible. Si se comparte para actualizar desde otro equipo, ajustar las rutas en Transformar datos → Configuración de origen de datos → Cambiar origen.

## Problemas frecuentes

- Conteo 9.624: faltó quitar duplicados por TramiteID.
- Medida de entregados incorrecta: revisar limpieza de Estado y filtros activos.
- Misma cantidad repetida en todas las sedes: falta relación activa o se usó un campo de otra tabla sin relación.
- Error al crear relación: SedeID debe ser Texto en ambas tablas y único en Sedes.
- Meses fuera de orden: usar AnioMes y ordenar por AnioMesOrden, no por nombre de Mes.
- Valores vacíos en mapa: comprobar tipos numéricos, categorías y permisos del visual.
