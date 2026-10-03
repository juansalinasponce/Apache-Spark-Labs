#!/usr/bin/env python3
"""Valida volúmenes e integridad del despliegue del Lab 06."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import pymysql

from deploy_mysql import LAB_ROOT, load_env, require_env


TABLES = (
    "aseguradora_ubicacion",
    "aseguradora_producto",
    "aseguradora_broker",
    "aseguradora_canal_venta",
    "aseguradora_medio_pago",
    "aseguradora_cliente",
    "aseguradora_cotizacion",
    "aseguradora_poliza",
    "aseguradora_cuota",
    "aseguradora_pago",
    "aseguradora_tipo_siniestro",
    "aseguradora_siniestro",
)


def scalar(cursor: pymysql.cursors.Cursor, query: str) -> int:
    cursor.execute(query)
    return int(cursor.fetchone()[0])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--env-file",
        type=Path,
        default=LAB_ROOT / "lab06-mysql.env",
    )
    args = parser.parse_args()
    load_env(args.env_file.expanduser().resolve())

    ssl_enabled = os.environ.get("MYSQL_SSL_ENABLED", "true").lower() in {
        "1",
        "true",
        "yes",
        "on",
    }
    connection = pymysql.connect(
        host=require_env("MYSQL_HOST"),
        port=int(os.environ.get("MYSQL_PORT", "3306")),
        user=require_env("MYSQL_USER"),
        password=require_env("MYSQL_PASSWORD"),
        database=require_env("MYSQL_DATABASE"),
        charset="utf8mb4",
        connect_timeout=20,
        read_timeout=120,
        ssl={"check_hostname": False} if ssl_enabled else None,
    )

    try:
        with connection.cursor() as cursor:
            print("CONTEOS")
            for table in TABLES:
                print(f"{table}: {scalar(cursor, f'SELECT COUNT(*) FROM {table}')}")

            cursor.execute(
                """
                SELECT
                  MIN(fecha_cotizacion),
                  MAX(fecha_cotizacion),
                  COUNT(DISTINCT DATE_FORMAT(fecha_cotizacion, '%Y-%m')),
                  COUNT(DISTINCT DATE(fecha_cotizacion))
                FROM aseguradora_cotizacion
                """
            )
            first_date, last_date, months, days = cursor.fetchone()
            print("\nHISTORIA")
            print(f"primera_cotizacion: {first_date}")
            print(f"ultima_cotizacion: {last_date}")
            print(f"meses: {months}")
            print(f"dias: {days}")

            validations = {
                "convertidas_sin_poliza": """
                    SELECT COUNT(*)
                    FROM aseguradora_cotizacion c
                    LEFT JOIN aseguradora_poliza p ON p.id_cotizacion = c.id_cotizacion
                    WHERE c.estado = 'CONVERTIDA' AND p.id_poliza IS NULL
                """,
                "polizas_no_convertidas": """
                    SELECT COUNT(*)
                    FROM aseguradora_poliza p
                    JOIN aseguradora_cotizacion c ON c.id_cotizacion = p.id_cotizacion
                    WHERE c.estado <> 'CONVERTIDA'
                """,
                "cronogramas_desbalanceados": """
                    SELECT COUNT(*) FROM (
                      SELECT p.id_poliza
                      FROM aseguradora_poliza p
                      JOIN aseguradora_cuota c ON c.id_poliza = p.id_poliza
                      GROUP BY p.id_poliza, p.prima_total, p.numero_cuotas
                      HAVING COUNT(*) <> p.numero_cuotas
                         OR ABS(SUM(c.importe_cuota) - p.prima_total) > 0.01
                    ) x
                """,
                "cuotas_pago_inconsistente": """
                    SELECT COUNT(*) FROM (
                      SELECT c.id_cuota
                      FROM aseguradora_cuota c
                      LEFT JOIN aseguradora_pago p ON p.id_cuota = c.id_cuota
                      GROUP BY c.id_cuota, c.importe_cuota, c.saldo_pendiente
                      HAVING ABS(
                        COALESCE(SUM(CASE WHEN p.estado = 'PROCESADO' THEN p.importe_pagado ELSE 0 END), 0)
                        - (c.importe_cuota - c.saldo_pendiente)
                      ) > 0.01
                    ) x
                """,
                "siniestros_tipo_incompatible": """
                    SELECT COUNT(*)
                    FROM aseguradora_siniestro s
                    JOIN aseguradora_poliza p ON p.id_poliza = s.id_poliza
                    JOIN aseguradora_tipo_siniestro t ON t.id_tipo_siniestro = s.id_tipo_siniestro
                    WHERE p.id_producto <> t.id_producto
                """,
                "siniestros_fuera_vigencia": """
                    SELECT COUNT(*)
                    FROM aseguradora_siniestro s
                    JOIN aseguradora_poliza p ON p.id_poliza = s.id_poliza
                    WHERE DATE(s.fecha_ocurrencia) < p.fecha_inicio_vigencia
                       OR DATE(s.fecha_ocurrencia) > p.fecha_fin_vigencia
                """,
            }
            print("\nANOMALIAS")
            for name, query in validations.items():
                print(f"{name}: {scalar(cursor, query)}")

            cursor.execute(
                """
                SELECT
                  ROUND(AVG(cotizaciones), 2), MIN(cotizaciones), MAX(cotizaciones),
                  ROUND(AVG(polizas), 2), MIN(polizas), MAX(polizas)
                FROM (
                  SELECT
                    mes,
                    SUM(tipo = 'C') AS cotizaciones,
                    SUM(tipo = 'P') AS polizas
                  FROM (
                    SELECT DATE_FORMAT(fecha_cotizacion, '%Y-%m') AS mes, 'C' AS tipo
                    FROM aseguradora_cotizacion
                    UNION ALL
                    SELECT DATE_FORMAT(fecha_emision, '%Y-%m'), 'P'
                    FROM aseguradora_poliza
                  ) eventos
                  GROUP BY mes
                ) mensual
                """
            )
            avg_cot, min_cot, max_cot, avg_pol, min_pol, max_pol = cursor.fetchone()
            print("\nVOLUMEN_MENSUAL")
            print(f"cotizaciones promedio/min/max: {avg_cot}/{min_cot}/{max_cot}")
            print(f"polizas promedio/min/max: {avg_pol}/{min_pol}/{max_pol}")
    finally:
        connection.close()


if __name__ == "__main__":
    main()

