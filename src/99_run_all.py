# Databricks notebook source
# MAGIC %md
# MAGIC # Run all medallion layers
# MAGIC
# MAGIC Configure the widgets once, then run this notebook to execute setup, Bronze, Silver and Gold.

# COMMAND ----------

# MAGIC %run ./00_setup

# COMMAND ----------

# MAGIC %run ./01_bronze_load

# COMMAND ----------

# MAGIC %run ./02_silver_load

# COMMAND ----------

# MAGIC %run ./03_gold_load

