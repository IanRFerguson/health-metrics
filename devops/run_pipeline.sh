#!/bin/bash
set -e

HOME_DIR="/app"
if [[ $1 == "--full-refresh" ]]; then
    PIPELINE_CMD="uv run $HOME_DIR/src/health_data/main.py --full-refresh"
    DBT_CMD_PRE="uv run dbt build --full-refresh -s +tag:pre_gemini"
    DBT_CMD_POST="uv run dbt build --full-refresh -s tag:post_gemini+"
else
    PIPELINE_CMD="uv run $HOME_DIR/src/health_data/main.py"
    DBT_CMD_PRE="uv run dbt build -s +tag:pre_gemini"
    DBT_CMD_POST="uv run dbt build -s tag:post_gemini+"
fi

# Run the health data pipeline to load
# data from GCS to BigQuery
$PIPELINE_CMD

# Run the dbt build to transform the data in BigQuery
cd $HOME_DIR/src/analytics && $DBT_CMD_PRE

cd $HOME_DIR
uv run $HOME_DIR/src/scores/main.py

cd $HOME_DIR/src/analytics && $DBT_CMD_POST