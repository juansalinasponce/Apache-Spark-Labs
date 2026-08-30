# Databricks notebook source
# MAGIC %run ./lab_config

# COMMAND ----------

use_catalog()

for schema_name in [SCHEMA_BRONZE, SCHEMA_SILVER, SCHEMA_GOLD]:
    ensure_schema(schema_name)

print("Schemas ready:")
print(f"- {fqtn(SCHEMA_BRONZE, '<tables>')}")
print(f"- {fqtn(SCHEMA_SILVER, '<tables>')}")
print(f"- {fqtn(SCHEMA_GOLD, '<tables>')}")
print("")
print("Landing expected in S3:")
for item in SOURCE_TABLES:
    print(f"- {item['landing_path']}")

