import os
from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.decorators import task
from airflow.providers.common.sql.operators.sql import (
    SQLExecuteQueryOperator,
    SQLCheckOperator,
)
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

PG_CONN = "datatel_postgres"
GCP_CONN = "google_cloud_default"
SQL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "sql"))

with DAG(
    dag_id="datatel_pipeline",
    description="DataTel telecom ELT pipeline",
    start_date=datetime(2026, 5, 1),
    schedule="@daily",
    catchup=False,
    default_args={"owner": "mark-david", "retries": 1},
    template_searchpath=SQL_DIR,
    params={
        "t_start": Param(default=None, type=["null", "string"]),
        "t_end": Param(default=None, type=["null", "string"]),
    },
    tags=["datatel", "capstone"],
) as dag:

    quarantine_ddl = SQLExecuteQueryOperator(
        task_id="quarantine_ddl", conn_id=PG_CONN,
        sql="quality/create_quarantine.sql",
    )
    quarantine_load = SQLExecuteQueryOperator(
        task_id="quarantine_load", conn_id=PG_CONN,
        sql="quality/quarantine_bad_rows.sql",
    )

    gate_billing = SQLCheckOperator(
        task_id="gate_billing", conn_id=PG_CONN,
        sql="quality/gate_billing.sql",
    )
    gate_sessions = SQLCheckOperator(
        task_id="gate_sessions", conn_id=PG_CONN,
        sql="quality/gate_sessions.sql",
    )

    stg_billing_ddl = SQLExecuteQueryOperator(
        task_id="stg_billing_ddl", conn_id=PG_CONN,
        sql="staging_incremental/stg_billing_ddl.sql",
    )
    stg_billing_load = SQLExecuteQueryOperator(
        task_id="stg_billing_load", conn_id=PG_CONN,
        sql="staging_incremental/stg_billing_load.sql",
    )
    stg_sessions_ddl = SQLExecuteQueryOperator(
        task_id="stg_sessions_ddl", conn_id=PG_CONN,
        sql="staging_incremental/stg_sessions_ddl.sql",
    )
    stg_sessions_load = SQLExecuteQueryOperator(
        task_id="stg_sessions_load", conn_id=PG_CONN,
        sql="staging_incremental/stg_sessions_load.sql",
    )
    stg_customers_ddl = SQLExecuteQueryOperator(
        task_id="stg_customers_ddl", conn_id=PG_CONN,
        sql="staging_incremental/stg_customers_ddl.sql",
    )
    stg_customers_load = SQLExecuteQueryOperator(
        task_id="stg_customers_load", conn_id=PG_CONN,
        sql="staging_incremental/stg_customers_load.sql",
    )

    agg_user_revenue = SQLExecuteQueryOperator(
        task_id="agg_user_revenue", conn_id=PG_CONN,
        sql="transform/agg_user_revenue.sql",
    )
    agg_monthly_revenue = SQLExecuteQueryOperator(
        task_id="agg_monthly_revenue", conn_id=PG_CONN,
        sql="transform/agg_monthly_revenue.sql",
    )
    agg_arpu = SQLExecuteQueryOperator(
        task_id="agg_arpu", conn_id=PG_CONN,
        sql="transform/agg_arpu.sql",
    )
    agg_user_usage = SQLExecuteQueryOperator(
        task_id="agg_user_usage", conn_id=PG_CONN,
        sql="transform/agg_user_usage.sql",
    )
    session_buckets = SQLExecuteQueryOperator(
        task_id="session_buckets", conn_id=PG_CONN,
        sql="transform/session_buckets.sql",
    )
    agg_session_distribution = SQLExecuteQueryOperator(
        task_id="agg_session_distribution", conn_id=PG_CONN,
        sql="transform/agg_session_distribution.sql",
    )

    build_dw = SQLExecuteQueryOperator(
        task_id="build_dw_postgres", conn_id=PG_CONN,
        sql="warehouse/dw_user_analytics.sql",
    )

    @task(task_id="publish_to_bigquery")
    def publish_to_bigquery():
        from airflow.providers.postgres.hooks.postgres import PostgresHook
        from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
        from google.cloud import bigquery

        project = Variable.get("gcp_project")
        dataset = Variable.get("bq_dataset")

        df = PostgresHook(postgres_conn_id=PG_CONN).get_pandas_df(
            "SELECT * FROM dw_user_analytics"
        )
        client = BigQueryHook(gcp_conn_id=GCP_CONN, use_legacy_sql=False).get_client(
            project_id=project
        )
        client.load_table_from_dataframe(
            df, f"{project}.{dataset}.dw_user_analytics_staging",
            job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE"),
        ).result()

    merge_warehouse = BigQueryInsertJobOperator(
        task_id="merge_warehouse", gcp_conn_id=GCP_CONN,
        configuration={
            "query": {
                "query": "{% include 'warehouse/dw_merge_bigquery.sql' %}",
                "useLegacySql": False,
            }
        },
    )

    publish = publish_to_bigquery()

    quarantine_ddl >> quarantine_load >> [gate_billing, gate_sessions]
    gate_billing >> stg_billing_ddl >> stg_billing_load
    gate_sessions >> stg_sessions_ddl >> stg_sessions_load
    stg_customers_ddl >> stg_customers_load
    stg_billing_load >> [agg_user_revenue, agg_monthly_revenue, agg_arpu]
    stg_sessions_load >> [agg_user_usage, session_buckets]
    session_buckets >> agg_session_distribution
    [agg_user_revenue, agg_user_usage, agg_arpu,
     agg_session_distribution, stg_customers_load] >> build_dw
    build_dw >> publish >> merge_warehouse