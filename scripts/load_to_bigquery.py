import os
import pandas as pd
from sqlalchemy import create_engine
from google.cloud import bigquery
from dotenv import load_dotenv

load_dotenv()

PG_URL = (
    f"postgresql+psycopg2://{os.environ['PGUSER']}:{os.environ['PGPASSWORD']}"
    f"@{os.environ['PGHOST']}:{os.environ['PGPORT']}/{os.environ['PGDATABASE']}"
)
PROJECT = os.environ["GCP_PROJECT"]
DATASET = os.environ["BQ_DATASET"]

MERGE_SQL = f"""
CREATE TABLE IF NOT EXISTS `{PROJECT}.{DATASET}.dw_user_analytics` (
  customer_id STRING, customer_name STRING, email STRING, country STRING,
  customer_since TIMESTAMP, total_revenue FLOAT64, total_transactions INT64,
  total_data_used_mb FLOAT64, avg_session_duration_sec FLOAT64, total_sessions INT64,
  arpu FLOAT64, short_sessions INT64, medium_sessions INT64, long_sessions INT64,
  avg_data_per_session_mb FLOAT64
);

MERGE `{PROJECT}.{DATASET}.dw_user_analytics` T
USING `{PROJECT}.{DATASET}.dw_user_analytics_staging` S
ON T.customer_id = S.customer_id
WHEN MATCHED THEN UPDATE SET
  customer_name = S.customer_name, email = S.email, country = S.country,
  customer_since = S.customer_since, total_revenue = S.total_revenue,
  total_transactions = S.total_transactions, total_data_used_mb = S.total_data_used_mb,
  avg_session_duration_sec = S.avg_session_duration_sec, total_sessions = S.total_sessions,
  arpu = S.arpu, short_sessions = S.short_sessions, medium_sessions = S.medium_sessions,
  long_sessions = S.long_sessions, avg_data_per_session_mb = S.avg_data_per_session_mb
WHEN NOT MATCHED THEN INSERT ROW;
"""

def main():
    engine = create_engine(PG_URL)
    df = pd.read_sql("SELECT * FROM dw_user_analytics", engine)

    client = bigquery.Client(project=PROJECT)
    staging = f"{PROJECT}.{DATASET}.dw_user_analytics_staging"

    client.load_table_from_dataframe(
        df, staging,
        job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE"),
    ).result()

    client.query(MERGE_SQL).result()
    print(f"Published {len(df)} rows to {PROJECT}.{DATASET}.dw_user_analytics")

if __name__ == "__main__":
    main()