#!/bin/bash

set -e

uv run /app/src/health_data/main.py

cd /app/src/analytics && uv run dbt build