# Enunciado — Fabric 02: landing Delta en un Lakehouse

## Situación

El banco ya dispone en MySQL de información de clientes y préstamos. En el
ejercicio anterior, estas entidades se copiaron a la capa Bronze de un
Warehouse de Microsoft Fabric.

El equipo de Data Engineering quiere evaluar una segunda alternativa: recibir
la información en un Lakehouse y almacenarla como tablas Delta en OneLake. Para
esta demostración, la capa `landing` representará la capa Bronze de la
arquitectura medallion.

## Reto

Construye mediante Spark SQL la estructura inicial de la capa `landing` dentro
de un Lakehouse de Microsoft Fabric con schemas habilitados.

Debes crear exactamente estas dos tablas administradas:

```text
landing.banco_cliente
landing.banco_prestamo
```

Ambas tablas deben usar explícitamente el formato Delta, conservar los nombres
de columnas del origen MySQL y declarar todas sus columnas como `STRING`.

## Estructura requerida

### `landing.banco_cliente`

| Columna | Tipo Spark SQL |
|---|---|
| `id_cliente` | `STRING` |
| `tipo_documento` | `STRING` |
| `nro_documento` | `STRING` |
| `nombre_completo` | `STRING` |
| `tipo_cliente` | `STRING` |
| `segmento` | `STRING` |
| `fecha_registro` | `STRING` |
| `email` | `STRING` |
| `telefono` | `STRING` |
| `estado` | `STRING` |
| `creado_en` | `STRING` |

### `landing.banco_prestamo`

| Columna | Tipo Spark SQL |
|---|---|
| `id_prestamo` | `STRING` |
| `id_cliente` | `STRING` |
| `id_sucursal` | `STRING` |
| `tipo_prestamo` | `STRING` |
| `monto_desembolso` | `STRING` |
| `saldo_pendiente` | `STRING` |
| `tasa_interes_anual` | `STRING` |
| `numero_cuotas` | `STRING` |
| `fecha_desembolso` | `STRING` |
| `estado` | `STRING` |

## Reglas del ejercicio

1. Utiliza un **Lakehouse**, no un Warehouse.
2. Crea el Lakehouse con la opción **Lakehouse schemas** habilitada.
3. Ejecuta el DDL con **Spark SQL**.
4. Crea el schema `landing` solamente si todavía no existe.
5. Usa `CREATE TABLE IF NOT EXISTS` para que el DDL pueda volver a ejecutarse.
6. Declara `USING DELTA` en cada tabla.
7. Declara todas las columnas como `STRING`, incluidos identificadores, fechas
   e importes.
8. No agregues claves primarias, claves foráneas, índices ni reglas de calidad.
9. No construyas capas Silver o Gold en este ejercicio.
10. No incluyas credenciales ni datos de conexión en el script.

Los campos se dejan anulables y en formato texto de forma intencional. La capa
landing debe conservar el valor recibido antes de aplicar conversiones. Los
tipos de negocio, las validaciones y los rechazos corresponden a Silver.

## Validaciones solicitadas

Después de ejecutar el DDL:

1. Lista las tablas del schema `landing`.
2. Describe la estructura de ambas tablas.
3. Verifica en el detalle de cada tabla que el formato sea `delta`.
4. Consulta el historial Delta de al menos una tabla.
5. Confirma que las tablas comienzan con cero registros.

Consultas que pueden utilizarse para comprobar la entrega:

```sql
SHOW TABLES IN landing;

DESCRIBE TABLE landing.banco_cliente;
DESCRIBE TABLE landing.banco_prestamo;

DESCRIBE DETAIL landing.banco_cliente;
DESCRIBE DETAIL landing.banco_prestamo;

DESCRIBE HISTORY landing.banco_cliente;

SELECT COUNT(*) AS filas_cliente
FROM landing.banco_cliente;

SELECT COUNT(*) AS filas_prestamo
FROM landing.banco_prestamo;
```

## Entregables

- Script DDL de Spark SQL.
- Captura del explorador del Lakehouse mostrando el schema y las dos tablas.
- Resultado de `DESCRIBE DETAIL` donde se observe el formato Delta.
- Resultado de los conteos iniciales.
- Explicación breve de dos diferencias entre crear estas tablas en Lakehouse y
  crearlas en Warehouse.

## Criterios de finalización

- Existen únicamente las dos tablas solicitadas dentro de `landing`.
- El DDL puede ejecutarse nuevamente sin error por objetos existentes.
- Todas las columnas están declaradas como `STRING`.
- Las dos tablas se almacenan en formato Delta.
- La solución se ejecutó con Spark SQL sobre el Lakehouse correcto.
