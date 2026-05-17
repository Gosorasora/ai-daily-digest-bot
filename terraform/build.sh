#!/usr/bin/env bash
# Build Lambda deployment package.
#
# No external dependencies — handler uses only Python stdlib + boto3
# (boto3 is preinstalled in Lambda Python runtime). So we just stage
# handler.py into build/ and let Terraform's archive_file zip it.

set -euo pipefail

cd "$(dirname "$0")/lambda"

BUILD_DIR="build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp handler.py "$BUILD_DIR/"

echo "[build] Done. Files in $BUILD_DIR:"
ls -lah "$BUILD_DIR"
echo "[build] Next: terraform apply"
