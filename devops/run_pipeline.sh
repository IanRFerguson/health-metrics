#!/bin/bash
set -e

HOME_DIR="/app"

PIPELINE_CMD="uv run $HOME_DIR/src/health_data/run_health_data.py"
SCORES_CMD="uv run $HOME_DIR/src/scores/run_gemini_health_scores.py"
DBT_CMD_PRE="uv run dbt build -s +tag:pre_gemini"
DBT_CMD_POST="uv run dbt build -s tag:post_gemini+"

if [[ $1 == "--full-refresh" ]]; then
    PIPELINE_CMD="$PIPELINE_CMD --full-refresh"
    DBT_CMD_PRE="$DBT_CMD_PRE --full-refresh"
    DBT_CMD_POST="$DBT_CMD_POST --full-refresh"
    SCORES_CMD="$SCORES_CMD --full-refresh"
fi

# Run the health data pipeline to load
# data from GCS to BigQuery
$PIPELINE_CMD

# Run the dbt build to transform the data in BigQuery
cd $HOME_DIR/src/analytics && $DBT_CMD_PRE

cd $HOME_DIR
$SCORES_CMD

cd $HOME_DIR/src/analytics && $DBT_CMD_POST