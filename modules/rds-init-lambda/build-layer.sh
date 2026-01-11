#!/bin/bash
# Build psycopg2 Lambda layer for Python 3.12

set -e

echo "Building psycopg2 Lambda layer..."

# Create directory structure
mkdir -p python/lib/python3.12/site-packages

# Install psycopg2-binary
pip install psycopg2-binary -t python/lib/python3.12/site-packages/

# Create zip file
cd python
zip -r ../psycopg2-layer.zip .
cd ..

# Clean up
rm -rf python/

echo "Layer created: psycopg2-layer.zip"
echo "Size: $(du -h psycopg2-layer.zip | cut -f1)"
