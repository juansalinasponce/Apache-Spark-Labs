# Nomenclatura del laboratorio

Se usan minúsculas, palabras descriptivas y guion bajo. No se utilizan espacios,
tildes ni caracteres especiales en nombres técnicos.

## Artefactos de Fabric

```text
<tipo>_<dominio>_<ambiente>_<proposito>
```

| Tipo | Abreviatura | Ejemplo |
|---|---|---|
| Workspace | `wk` | `wk_banca_dev` |
| Warehouse | `wh` | `wh_banca_dev_comercial` |
| Pipeline | `pl` | `pl_banca_dev_clientes_prestamos` |
| Semantic model | `sm` | `sm_banca_dev_clientes_prestamos` |
| Reporte | `rpt` | `rpt_banca_dev_clientes_prestamos` |

El ambiente de este laboratorio es `dev`. En un proyecto posterior puede
cambiarse por `tst` o `prd`.

## Capas dentro del Warehouse

| Schema | Significado | Contenido |
|---|---|---|
| `brz` | Bronze | Copia sin transformación del origen |
| `slv` | Silver | Datos limpios y tipificados |
| `gld` | Gold | Modelo dimensional para Power BI |

Como el schema ya identifica la capa, no repetimos `brz`, `slv` o `gld` dentro
del nombre de la tabla.

## Tablas Gold

- `dim_`: dimensión descriptiva, por ejemplo `gld.dim_cliente`.
- `fct_`: hecho medible, por ejemplo `gld.fct_prestamo`.

## Actividades del pipeline

```text
act_<orden>_<verbo>_<objeto>
```

Ejemplos:

```text
act_01_limpiar_bronze
act_02_copiar_cliente
act_03_copiar_prestamo
act_04_cargar_silver
act_05_cargar_gold
```
