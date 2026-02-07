#!/bin/bash
set -e

if [ $1 == "--full-refresh" ]; then
    PIPELINE_CMD="uv run /app/src/health_data/main.py --full-refresh"
    DBT_CMD="uv run dbt build --full-refresh"
else
    PIPELINE_CMD="uv run /app/src/health_data/main.py"
    DBT_CMD="uv run dbt build"
fi

# Run the health data pipeline to load
# data from GCS to BigQuery
$PIPELINE_CMD

# Run the dbt build to transform the data in BigQuery
cd /app/src/analytics && $DBT_CMD