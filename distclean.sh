#!/bin/bash

set -euo pipefail

echo "Starting full cleanup..."

echo "Cleaning Python caches & environments..."
find . -type d -name ".venv" -prune -exec rm -rf {} +
find . -type d -name "__pycache__" -prune -exec rm -rf {} +
find . -type d -name "*.egg-info" -prune -exec rm -rf {} +
find . -type d -name ".pytest_cache" -prune -exec rm -rf {} +
find . -type d -name ".mypy_cache" -prune -exec rm -rf {} +
find . -type d -name ".ruff_cache" -prune -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete
find . -type f -name "*.coverage" -delete
find . -type f -name ".coverage.*" -delete

echo "Cleaning dbt artifacts..."
find . -type d -name "dbt_modules" -prune -exec rm -rf {} +
find . -type d -name "target" -prune -exec rm -rf {} +
find . -type d -name "logs" -prune -exec rm -rf {} +
find . -type f -name "manifest.json" -delete
find . -type f -name "run_results.json" -delete
