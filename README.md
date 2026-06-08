

# DataTel Telecom Data Pipeline

An automated ELT pipeline that pulls raw, messy telecom data out of PostgreSQL,
cleans and stages it, rolls it up into per-customer analytics, and publishes the
result to BigQuery. Orchestrated with Apache Airflow on a daily schedule.


See [DISCUSSION.md](DISCUSSION.md) for answers to the project discussion questions.


## What it does

Three source tables (billing, network sessions, customers) come in dirty:
duplicates, nulls, bad rows. The pipeline quarantines the junk, stages clean data
incrementally, aggregates it per customer, and loads one wide table,
dw_user_analytics, into BigQuery with a MERGE so reruns never duplicate.

## Architecture

Source (Postgres) -> quality gates -> staging (incremental) -> transform
(aggregates) -> warehouse table (Postgres) -> BigQuery (MERGE upsert)

All the logic lives in .sql files. The Airflow DAG only orchestrates. It holds no
business logic of its own.

## Stack

- PostgreSQL for source, staging and transform
- Apache Airflow 3 for orchestration
- Google BigQuery as the final warehouse
- Python for the BigQuery publish step

## Layout

- dags/ the Airflow DAG
- sql/quality/ quarantine and the two gates
- sql/staging_incremental/ the windowed staging loads
- sql/transform/ the aggregates
- sql/warehouse/ the warehouse build and the BigQuery merge
- sql/analytics/ the business queries
- scripts/ the standalone BigQuery loader

## Running it

Part A, build and verify the warehouse in Postgres, then publish once to BigQuery:

    python scripts/generate_data.py
    psql -d datatel -f sql/quality/create_quarantine.sql
    psql -d datatel -f sql/quality/quarantine_bad_rows.sql
    psql -d datatel -f sql/staging/stg_billing.sql
    psql -d datatel -f sql/staging/stg_sessions.sql
    psql -d datatel -f sql/staging/stg_customers.sql
    for f in sql/transform/*.sql; do psql -d datatel -f "$f"; done
    psql -d datatel -f sql/warehouse/dw_user_analytics.sql
    python scripts/load_to_bigquery.py

Part B, hand it to Airflow:

1. Set the two connections (datatel_postgres, google_cloud_default) and the two
   variables (gcp_project, bq_dataset).
2. Put the service account key in keys/.
3. Start Airflow, unpause datatel_pipeline, and trigger it. The first run uses a
   wide date window to backfill all history. After that it runs daily and only
   touches the new window.

## Design notes

Staging is incremental with a delete-insert per window, so reruns are idempotent.
Aggregates recompute from clean staging on every run, which keeps history-spanning
numbers like total revenue and ARPU correct. Customers load as a full refresh
because there is no reliable update column to slice on. The BigQuery write is a
MERGE on customer_id, so it is safe to rerun without duplicating or wiping rows.