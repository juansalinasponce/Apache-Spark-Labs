# Diccionario de datos

## Archivo 01: hoja Tramites → consulta Tramites

Una fila por solicitud después de eliminar duplicados por TramiteID. Las fechas de origen son texto ISO `yyyy-MM-dd` para practicar su conversión; los vacíos de FechaEntrega son intencionales.

| Campo | Tipo final | Uso |
|---|---|---|
| TramiteID | Texto | Identificador sintético único; quitar duplicados por esta columna |
| FechaSolicitud | Fecha | Eje de análisis y relación con DimFecha |
| FechaEntrega | Fecha, admite nulos | Solo presente en ENTREGADO; nunca anterior a solicitud ni posterior al corte |
| SedeID | Texto | Clave hacia Sedes; conservar como texto |
| TipoTramite | Texto | PRIMERA EMISIÓN / RENOVACIÓN |
| Canal | Texto | WEB / PRESENCIAL; origen con algunos espacios y minúsculas |
| Estado | Texto | ENTREGADO / EN PROCESO / OBSERVADO / CANCELADO; limpiar espacios y mayúsculas |
| EdadSolicitante | Entero | Edad ficticia, 18–79 años |
| ImporteReferencial | Decimal fijo | S/ 120 por solicitud; monto didáctico, no tarifa oficial ni recaudación real |

## Archivo 02: hoja Sedes → consulta Sedes

| Campo | Tipo final | Uso |
|---|---|---|
| SedeID | Texto | Clave única, S01–S12 |
| Sede | Texto | Nombre explícitamente simulado |
| Departamento | Texto | Filtro y agrupación geográfica |
| Provincia | Texto | Nivel geográfico intermedio |
| Distrito | Texto | Nivel local |
| RegionNatural | Texto | Costa / Sierra / Selva, clasificación didáctica |
| Latitud | Decimal | Coordenada aproximada de la ciudad, categoría Latitud |
| Longitud | Decimal | Coordenada aproximada de la ciudad, categoría Longitud |

## Calidad y definiciones

24 filas duplicadas exactas; no son solicitudes distintas. No eliminar los nulos de FechaEntrega: representan solicitudes no entregadas. Limpiar Canal y Estado antes de crear medidas. No combinar las tablas con una unión; relacionarlas en el modelo.

La tasa de entrega es entregados / total de solicitudes, incluyendo cancelados y observados. Los días de atención son días calendario entre solicitud y entrega, solo para entregados. Las métricas son al corte fijo; no usar TODAY() para este laboratorio. No se modelan cambios históricos de estado.

Sin filtros: 9.600 solicitudes, 7.657 entregados, 79,76 % de entrega y 9,85 días promedio. Estados: 1.078 en proceso, 588 observados, 277 cancelados. DimFecha tiene 365 fechas sin duplicados ni huecos.
