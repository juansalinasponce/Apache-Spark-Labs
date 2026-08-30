# Lab 02 - Spark Streaming with Kafka / Redpanda

## 1. Objetivo del laboratorio

Este laboratorio tiene como objetivo implementar un flujo de procesamiento en tiempo real utilizando:

- **Python** como publicador de eventos.
- **Redpanda Cloud** como broker compatible con Apache Kafka.
- **Apache Spark Structured Streaming** en Databricks Free Edition como consumidor.
- **Amazon S3** como almacenamiento final mediante una tabla Delta externa.

El caso de uso simula operaciones financieras que se publican en tiempo real hacia un tópico Kafka llamado `operaciones`.

---

## 2. Arquitectura del laboratorio

```text
Python Publisher
     |
     v
Redpanda Cloud / Kafka Topic: operaciones
     |
     v
Apache Spark Structured Streaming - Databricks
     |
     v
Delta Lake Table
     |
     v
Amazon S3
s3://dmc-storage-jmsp/lakehouse/silver/transacciones/