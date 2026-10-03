#!/usr/bin/env python3
"""Despliega el Lab 06 en la base indicada por un archivo .env."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import pymysql
from pymysql.constants import CLIENT


LAB_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SQL_FILES = (
    LAB_ROOT / "sql/02_create_tables.sql",
    LAB_ROOT / "sql/03_seed_catalogs.sql",
    LAB_ROOT / "sql/04_generate_two_year_history.sql",
)


def load_env(path: Path) -> None:
    if not path.is_file():
        raise FileNotFoundError(f"No existe el archivo de configuración: {path}")

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip("\"'"))


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Falta la variable requerida {name}")
    return value


def execute_script(connection: pymysql.Connection, path: Path) -> None:
    statement = path.read_text(encoding="utf-8")
    with connection.cursor() as cursor:
        cursor.execute(statement)
        while cursor.nextset():
            pass


def execute_claims_only(connection: pymysql.Connection) -> None:
    history_path = LAB_ROOT / "sql/04_generate_two_year_history.sql"
    history_sql = history_path.read_text(encoding="utf-8")
    marker = "-- 4 mil siniestros sintéticos"
    start = history_sql.index("INSERT INTO aseguradora_siniestro", history_sql.index(marker))
    end = history_sql.index("\n\nCOMMIT;", start)
    claims_statement = history_sql[start:end]

    digits = " UNION ALL ".join(f"SELECT {number} AS d" for number in range(10))
    sequence_statement = f"""
        INSERT INTO lab06_sequence (n)
        SELECT 1 + u.d + t.d * 10 + h.d * 100 + th.d * 1000
        FROM ({digits}) u
        CROSS JOIN ({digits}) t
        CROSS JOIN ({digits}) h
        CROSS JOIN ({digits}) th
        WHERE 1 + u.d + t.d * 10 + h.d * 100 + th.d * 1000 <= 4000
    """

    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM aseguradora_siniestro")
        if cursor.fetchone()[0] != 0:
            raise RuntimeError("La tabla aseguradora_siniestro ya contiene datos")
        cursor.execute(
            "CREATE TEMPORARY TABLE lab06_sequence "
            "(n INT UNSIGNED NOT NULL PRIMARY KEY) ENGINE=InnoDB"
        )
        cursor.execute(sequence_statement)
        cursor.execute(claims_statement)
        cursor.execute("DROP TEMPORARY TABLE lab06_sequence")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--env-file",
        type=Path,
        default=LAB_ROOT / "lab06-mysql.env",
        help="Archivo con MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD y MYSQL_DATABASE",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--history-only",
        action="store_true",
        help="Ejecuta solamente el generador histórico después de un despliegue parcial",
    )
    mode.add_argument(
        "--claims-only",
        action="store_true",
        help="Recupera únicamente siniestros si una carga parcial no los insertó",
    )
    mode.add_argument(
        "--queries-only",
        action="store_true",
        help="Comprueba que las validaciones y soluciones SQL puedan ejecutarse",
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
        autocommit=True,
        connect_timeout=20,
        read_timeout=180,
        write_timeout=180,
        client_flag=CLIENT.MULTI_STATEMENTS,
        ssl={"check_hostname": False} if ssl_enabled else None,
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]
        print(f"Conexión establecida con MySQL/MariaDB {version}")

        if args.claims_only:
            print("Ejecutando recuperación de siniestros...")
            execute_claims_only(connection)
            print("Completado: 4000 siniestros")
            return

        if args.queries_only:
            query_files = (
                LAB_ROOT / "sql/05_validate_data.sql",
                LAB_ROOT / "sql/06_solutions.sql",
            )
            for sql_file in query_files:
                print(f"Comprobando {sql_file.relative_to(LAB_ROOT)}...")
                execute_script(connection, sql_file)
                print(f"Completado: {sql_file.name}")
            return

        sql_files = DEFAULT_SQL_FILES[-1:] if args.history_only else DEFAULT_SQL_FILES
        for sql_file in sql_files:
            print(f"Ejecutando {sql_file.relative_to(LAB_ROOT)}...")
            execute_script(connection, sql_file)
            print(f"Completado: {sql_file.name}")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
