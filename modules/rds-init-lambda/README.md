# RDS Schema Initialization Lambda

This Lambda function initializes the RDS database schema using SQL files stored in S3.

## Building the psycopg2 Layer

The Lambda function requires the `psycopg2` library to connect to PostgreSQL. You need to build a Lambda layer containing this dependency.

### Option 1: Build Locally (Recommended)

```bash
cd infra/modules/rds-init-lambda

# Create directory structure
mkdir -p python/lib/python3.12/site-packages

# Install psycopg2-binary into the layer directory  
pip install psycopg2-binary -t python/lib/python3.12/site-packages/

# Zip the layer
zip -r psycopg2-layer.zip python/

# Clean up
rm -rf python/
```

### Option 2: Use Docker (for Amazon Linux compatibility)

```bash
cd infra/modules/rds-init-lambda

docker run --rm -v $(pwd):/var/task public.ecr.aws/lambda/python:3.12 \
  /bin/sh -c "pip install psycopg2-binary -t python/lib/python3.12/site-packages/ && cd python && zip -r ../psycopg2-layer.zip ."

# Clean up
docker run --rm -v $(pwd):/var/task public.ecr.aws/lambda/python:3.12 rm -rf python/
```

### Option 3: Use Public Layer (easiest, region-specific)

Instead of building your own layer, you can use a public psycopg2 layer. Update `main.tf` to use a public ARN:

```hcl
# Replace the aws_lambda_layer_version resource with a data source:
data "aws_lambda_layer_version" "psycopg2" {
  layer_name = "psycopg2"
  # Find public ARN for your region at: https://github.com/jetbridge/psycopg2-lambda-layer
}
```

## How It Works

1. **Schema Files**: `init-schema.sql` and `seed-data.sql` are uploaded to an S3 bucket
2. **Lambda Invocation**: Terraform invokes the Lambda function after RDS is created
3. **Credentials**: Lambda retrieves DB credentials from AWS Secrets Manager
4. **Execution**: Lambda downloads SQL from S3 and executes it against RDS
5. **Idempotent**: SQL uses `CREATE TABLE IF NOT EXISTS` and `ON CONFLICT` - safe to re-run

## Environment Variables

The Lambda function uses these environment variables (configured by Terraform):

- `DB_HOST`: RDS hostname
- `DB_PORT`: Database port (5432)
- `DB_NAME`: Database name
- `DB_SECRET_ARN`: ARN of Secrets Manager secret with credentials
- `SCHEMA_BUCKET`: S3 bucket containing SQL files
- `INIT_SCHEMA_KEY`: S3 key for init-schema.sql
- `SEED_DATA_KEY`: S3 key for seed-data.sql
- `ENVIRONMENT`: Environment name (triggers seed data in dev only)

## CloudWatch Logs

Lambda execution logs are available in CloudWatch:
- Log group: `/aws/lambda/{environment}-rds-schema-init`
- Retention: 7 days (dev) / 30 days (prod)

## Re-running Schema Initialization

The `null_resource.invoke_lambda` will re-run when:
- `init-schema.sql` content changes (filemd5 trigger)
- `seed-data.sql` content changes (filemd5 trigger)
- Lambda function ARN changes

To force a re-run without changing SQL:
```bash
terraform taint 'module.rds_init.null_resource.invoke_lambda'
terraform apply
```
