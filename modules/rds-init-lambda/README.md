# RDS Schema Initialization Lambda

This Lambda function initializes the RDS database schema using SQL files stored in S3.

## Quick Start

### 1. Build the psycopg2 Layer

```bash
cd infra/modules/rds-init-lambda
./build-layer.sh
```

This creates `psycopg2-layer.zip` (required for Lambda to connect to PostgreSQL).

### 2. Apply Terraform

```bash
cd infra/envs/dev
terraform init
terraform apply
```

Terraform will:
1. Create S3 bucket and upload SQL files
2. Deploy Lambda function in VPC
3. **Automatically invoke** the Lambda to initialize schema
4. Lambda will create all tables and insert seed data (dev only)

### 3. Verify

Check Lambda execution logs:
```bash
aws logs tail /aws/lambda/dev-rds-schema-init --follow
```

Expected output:
```
Starting RDS schema initialization
Retrieving database credentials
Connecting to database...
Database connection established
Executing init schema
SQL executed successfully
Environment is dev, executing seed data
Schema initialization completed successfully
```

## How It Works

**No AWS Trigger Required**: The Lambda doesn't have an EventBridge/S3 trigger visible in the AWS console. Instead, Terraform invokes it once via `null_resource` after deployment.

1. Terraform uploads `init-schema.sql` and `seed-data.sql` to S3
2. Lambda is deployed with VPC access
3. Terraform runs `aws lambda invoke` via `null_resource.invoke_lambda`
4. Lambda:
   - Retrieves DB credentials from Secrets Manager
   - Downloads SQL from S3
   - Connects to RDS with psycopg2 (SSL enabled)
   - Executes schema DDL
   - Executes seed data (dev environment only)

## Re-running Schema

If tables are missing or you update SQL files:

```bash
cd infra/envs/dev
terraform taint 'module.rds_init.null_resource.invoke_lambda'
terraform apply
```

This forces Terraform to re-invoke the Lambda.

## Troubleshooting

### Tables Still Missing

1. **Check if Lambda was invoked:**
   ```bash
   aws lambda get-function --function-name dev-rds-schema-init
   ```

2. **Check CloudWatch logs:**
   ```bash
   aws logs tail /aws/lambda/dev-rds-schema-init --since 2h
   ```

3. **Manually invoke Lambda:**
   ```bash
   aws lambda invoke \
     --function-name dev-rds-schema-init \
     --payload '{}' \
     /tmp/response.json
   cat /tmp/response.json
   ```

### VPC Issues

Lambda needs to reach:
- RDS (port 5432) - check security group rules
- Secrets Manager - check VPC endpoints or NAT gateway
- S3 - check VPC endpoint or NAT gateway

### Check Security Groups

```bash
# Lambda should be able to connect to RDS
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=<RDS_SG_ID>" \
  | grep -A5 "5432"
```

