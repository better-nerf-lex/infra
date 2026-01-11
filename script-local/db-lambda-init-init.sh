#!/bin/bash
cd ~/work/lexai/infra/modules/rds-init-lambda
LAYER_ARN=$(aws lambda publish-layer-version \
  --layer-name dev-psycopg2 \
  --zip-file fileb://psycopg2-layer.zip \
  --compatible-runtimes python3.12 \
  --description "psycopg2 for Amazon Linux" \
  --query 'LayerVersionArn' \
  --output text)
echo "Layer ARN: $LAYER_ARN"
aws lambda update-function-configuration \
  --function-name dev-rds-schema-init \
  --layers "$LAYER_ARN"

sleep 30

