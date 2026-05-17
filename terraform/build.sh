#!/usr/bin/env bash
# Build Lambda deployment package with Gemini SDK bundled in.
#
# Why Docker: google-generativeai pulls grpcio which has C extensions —
# building on macOS arm64 produces wheels that crash on Lambda's manylinux x86_64.
# Using the AWS-provided python3.12 image guarantees the right ABI.

set -euo pipefail

cd "$(dirname "$0")/lambda"

BUILD_DIR="build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "[build] Installing dependencies in Lambda-compatible container..."
docker run --rm \
  --platform linux/amd64 \
  --entrypoint /bin/sh \
  -v "$PWD":/var/task \
  -w /var/task \
  public.ecr.aws/lambda/python:3.12 \
  -c "pip install --quiet -r requirements.txt -t $BUILD_DIR"

echo "[build] Copying handler..."
cp handler.py "$BUILD_DIR/"

echo "[build] Done. Files in $BUILD_DIR:"
ls -lah "$BUILD_DIR" | head -10
echo "[build] Next: terraform apply"
