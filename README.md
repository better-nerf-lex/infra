# paragrafic Infrastructure as Code

Terraform-based AWS infrastructure for deploying the paragrafic application using ECS Fargate, RDS PostgreSQL, and Application Load Balancer.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │ Route53 │
                    │  + ACM  │
                    └────┬────┘
                         │
                    ┌────▼────────────────────────────────┐
                    │   Application Load Balancer (ALB)   │
                    │   (Public Subnets - 2 AZs)          │
                    └────┬────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
   ┌────▼────────┐                  ┌─────▼───────┐
   │ ECS Fargate │                  │ ECS Fargate │
   │  Gateway    │                  │  Gateway    │
   │  (Private)  │                  │  (Private)  │
   └────┬────────┘                  └─────┬───────┘
        │                                 │
        └────────────────┬────────────────┘
                         │
                    ┌────▼────────────────┐
                    │  RDS PostgreSQL     │
                    │  (Private Subnets)  │
                    └─────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.9.0 ([Install](https://www.terraform.io/downloads))
3. **AWS CLI** configured ([Install](https://aws.amazon.com/cli/))
4. **GitHub Repository** with OIDC configured
5. **Domain Name** - either managed in Route 53 or with an external DNS provider

## Authentication & Troubleshooting

If you encounter the error `Error: No valid credential sources found` during `terraform init`, it means Terraform cannot find your AWS credentials.

### Quick Fix Options

**Option A: Edit `backend.tf` directly (Recommended for single profile)**
1. Open `envs/dev/backend.tf` (or `envs/prod/backend.tf`)
2. Uncomment and edit the `profile` line in the `backend "s3"` block:
   ```hcl
   backend "s3" {
     bucket         = "paragrafic-terraform-state-dev"
     key            = "dev/terraform.tfstate"
     region         = "eu-north-1"
     encrypt        = true
     dynamodb_table = "paragrafic-terraform-locks-dev"
     profile        = "your-aws-profile"  # <-- uncomment and set this
   }
   ```
3. Also set `aws_profile = "your-aws-profile"` in your `terraform.tfvars`
4. Run `terraform init`

**Option B: Pass profile during init (No file changes)**
```bash
terraform init -backend-config="profile=your-aws-profile"
```
Then set `aws_profile = "your-aws-profile"` in your `terraform.tfvars` for subsequent commands.

**Option C: Use environment variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-north-1"
terraform init
```

**Option D: Configure default AWS CLI credentials**
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, and region when prompted
terraform init
```

### Verifying Your Credentials

Before running `terraform init`, verify your AWS credentials work:
```bash
aws sts get-caller-identity --profile your-aws-profile
# Or without profile if using default/env vars:
aws sts get-caller-identity
```

### S3 Backend Initialization

Note that the S3 backend is used for state storage. You must have permissions to the state bucket before running `terraform init`. If you are setting this up for the first time, you might need to comment out the `backend "s3"` block in `backend.tf`, run `terraform apply` to create the bucket/table (if they don't exist yet), and then uncomment and run `terraform init` again.

## Quick Start (Using Existing ACM Certificates)

If you already have SSL/TLS certificates in AWS Certificate Manager (ACM) and want to enable HTTPS-only communication:

1. **Obtain your certificate ARNs** from the AWS Certificate Manager console:
   - API certificate (must be in the same region as your ALB, e.g., `eu-north-1`)
   - Frontend certificate (must be in `us-east-1` for CloudFront)

2. **Configure your `terraform.tfvars`**:
   ```hcl
   use_route53 = false              # Set to false if domain is managed externally (OVH, GoDaddy, etc.)
   enable_ssl_certificates = true   # Enable HTTPS with your existing certificates
   domain_name = "yourdomain.com"
   frontend_domain = "app.yourdomain.com"
   api_domain = "app.yourdomain.com"  # Same domain for path-based routing
   ```

3. **Run `terraform apply`** - This will create infrastructure with HTTPS-only communication:
   - ALB will redirect all HTTP (port 80) traffic to HTTPS (port 443)
   - CloudFront will enforce HTTPS for all viewer requests
   - All communication between CloudFront and ALB will use HTTPS

4. **Add CNAME records** in your DNS provider to point your domain to AWS:
   - Frontend: `app.yourdomain.com` → CloudFront domain (from `terraform output cloudfront_domain_name`)
   - API: Handled via CloudFront path-based routing (`/api/*`)

> **Note:** The infrastructure enforces HTTPS-only communication. HTTP requests are automatically redirected to HTTPS with a 301 permanent redirect.

## Quick Start (External DNS - OVH, GoDaddy, Cloudflare, etc.)

If you own a domain managed outside AWS (e.g., **OVH**, GoDaddy, Namecheap, Cloudflare), follow these steps:

### Step 1: Initial Infrastructure Deployment (without SSL certificates)

1. **Configure your `terraform.tfvars`**:
   ```hcl
   use_route53 = false              # Use external DNS
   enable_ssl_certificates = false  # Skip SSL on first apply
   domain_name = "yourdomain.com"
   frontend_domain = "app.yourdomain.com"
   api_domain = "app.yourdomain.com"  # Same domain for path-based routing
   ```

2. **Run `terraform apply`** - This will create all infrastructure including ACM certificates, but without HTTPS listeners on ALB/CloudFront

3. **Get DNS validation records**:
   ```bash
   terraform output api_dns_validation_records
   terraform output frontend_dns_validation_records
   ```

4. **Add DNS validation records** to your external DNS provider (OVH, GoDaddy, etc.)

5. **Wait 5-30 minutes** for certificate validation (check AWS ACM console)

### Step 2: Enable SSL Certificates

6. **Update `terraform.tfvars`**:
   ```hcl
   enable_ssl_certificates = true  # Enable SSL after validation
   ```

7. **Run `terraform apply` again** - This will add HTTPS listeners to ALB and CloudFront

8. **Add CNAME records** to point your domain to AWS:
   - Frontend: `app.yourdomain.com` → CloudFront domain (from `terraform output cloudfront_domain_name`)
   - API: Handled via CloudFront path-based routing (`/api/*`)

> **Note:** OpenSearch is disabled by default as it takes 10+ minutes to create. Enable it in `terraform.tfvars` only if needed.

## DNS Configuration

This infrastructure supports two DNS management options:

### Option 1: External DNS Provider (Recommended - OVH, GoDaddy, Namecheap, Cloudflare)

If your domain is managed outside of AWS, you **do not need Route 53**.

**Configuration:**

1. Set `use_route53 = false` and `enable_ssl_certificates = false` in your `terraform.tfvars`
2. Run `terraform apply` - This will create all infrastructure including ACM certificates, but without HTTPS listeners
3. Terraform will output the DNS validation records you need to add to your external DNS provider
4. Add the DNS validation records to your domain's DNS settings:
   - Check the Terraform outputs: `terraform output api_dns_validation_records` and `terraform output frontend_dns_validation_records`
   - Create CNAME records in your DNS provider with the name and value from the output
5. **Wait for certificate validation** (can take 5-30 minutes). You can check the status in the AWS ACM console
6. Set `enable_ssl_certificates = true` in your `terraform.tfvars`
7. Run `terraform apply` again to enable HTTPS on ALB and CloudFront
8. Add the following DNS records to point your domain to AWS resources:
   - **Frontend (CloudFront)**: Create a CNAME record for your frontend domain (e.g., `test-0.paragraphic.pl`) pointing to the CloudFront distribution domain (check `terraform output cloudfront_domain_name`)
   - **API (ALB)**: If using a separate API domain, create a CNAME record pointing to the ALB DNS name (check `terraform output alb_dns_name`). If using path-based routing (e.g., `test-0.paragraphic.pl/api`), no separate record is needed.

> **⚠️ Important:** When using external DNS, set `enable_ssl_certificates = false` on the first apply to avoid certificate validation errors. After adding DNS validation records and waiting for validation, set `enable_ssl_certificates = true` and run `terraform apply` again.

**Example DNS Records (for external DNS provider):**

```
# Certificate Validation (from Terraform outputs)
_abc123.test-0.paragraphic.pl  CNAME  _xyz789.acm-validations.aws.

# Frontend (points to CloudFront)
test-0.paragraphic.pl          CNAME  d1234567890.cloudfront.net
```

### Option 2: AWS Route 53

If you want AWS to manage your DNS:

1. Create a Route 53 Hosted Zone for your domain in the AWS Console
2. Update your domain registrar's nameservers to point to the Route 53 nameservers
3. Set `use_route53 = true` in your `terraform.tfvars`
4. Run `terraform apply`

Terraform will automatically:
- Create DNS validation records for ACM certificates
- Create A records pointing to CloudFront and ALB

## Project Structure

```
infra/
├── modules/              # Reusable Terraform modules
│   ├── vpc/             # VPC with public/private subnets
│   ├── alb/             # Application Load Balancer
│   ├── ecs-cluster/     # ECS cluster with Fargate
│   ├── ecs-service/     # ECS service definition
│   ├── ecr/             # ECR repositories
│   ├── rds/             # RDS PostgreSQL
│   ├── iam/             # IAM roles and OIDC provider
│   └── acm/             # ACM certificate and Route53
└── envs/                # Environment configurations
    ├── dev/             # Development environment
    ├── prod/            # Production environment
    └── local/           # LocalStack development environment
```

## Local Development (LocalStack)

To test the infrastructure locally, you can use [LocalStack](https://localstack.cloud/).

The local environment is a **simplified configuration** that tests only the following services:
- **S3** - Frontend bucket for static assets
- **Cognito** - User pool for authentication
- **CloudFront** - CDN distribution (without custom domain/ACM)
- **ECR** - Container registry
- **ECS** - Cluster (without services that require VPC/ALB)

This configuration avoids dependencies on Route53, EC2, and other services that may require additional LocalStack setup.

### 1. Prerequisites

- [LocalStack CLI](https://docs.localstack.cloud/getting-started/installation/)
- [Docker](https://www.docker.com/get-started/)
- [AWS CLI](https://aws.amazon.com/cli/)

### 2. Configure AWS Profile

Add a `localstack` profile to your `~/.aws/credentials` and `~/.aws/config`:

`~/.aws/credentials`:
```ini
[localstack]
aws_access_key_id=test
aws_secret_access_key=test
```

`~/.aws/config`:
```ini
[profile localstack]
region=eu-north-1
output=json
endpoint_url = http://localhost:4566
```

### 3. Start LocalStack

Start LocalStack with the necessary services enabled:

```bash
SERVICES=cloudfront,cognito,ecr,ecs,iam,s3,sts,logs,cloudwatch localstack start -d
```

Or using Docker Compose:

```yaml
services:
  localstack:
    image: localstack/localstack
    ports:
      - "127.0.0.1:4566:4566"
    environment:
      - SERVICES=cloudfront,cognito,ecr,ecs,iam,s3,sts,logs,cloudwatch
      - DEBUG=1
```

### 4. Initialize and Apply

The `local` environment uses a local backend for Terraform state, so no S3 bucket is needed for the state itself.

```bash
cd envs/local
terraform init
terraform apply
```

### 5. Verify Resources

After applying, you can verify the created resources:

```bash
# List S3 buckets
aws --profile localstack s3 ls

# List Cognito User Pools
aws --profile localstack cognito-idp list-user-pools --max-results 10

# List ECR repositories
aws --profile localstack ecr describe-repositories

# List ECS clusters
aws --profile localstack ecs list-clusters
```

### 6. Troubleshooting

If you see errors like `Service 'X' is not enabled` or `connection refused`, verify:
1. **LocalStack is running**: `localstack status`
2. **Endpoint is reachable**: `curl http://localhost:4566/_localstack/health`
3. **Correct Services**: Ensure all services are listed in the `SERVICES` environment variable.
4. **Profile Configuration**: Ensure `~/.aws/config` has `endpoint_url = http://localhost:4566` for the `localstack` profile.

Note: Some services like CloudFront might have limited functionality in the LocalStack Community version, but the Terraform resources can still be created for testing purposes.

## Initial Setup

### 1. Create S3 Backend and DynamoDB Table

Before running Terraform, create the S3 bucket and DynamoDB table for state management:

```bash
# For dev environment
aws s3api create-bucket \
  --bucket paragrafic-terraform-state-dev \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

aws s3api put-bucket-versioning \
  --bucket paragrafic-terraform-state-dev \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name paragrafic-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-north-1

# For prod environment
aws s3api create-bucket \
  --bucket paragrafic-terraform-state-prod \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

aws s3api put-bucket-versioning \
  --bucket paragrafic-terraform-state-prod \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name paragrafic-terraform-locks-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-north-1
```

### 2. Configure Environment Variables

Copy the example tfvars file and update with your values:

```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
github_org        = "your-github-org"
github_repo       = "paragrafic"
gateway_image_uri = "ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/gateway:latest"
```

### 3. Deploy Infrastructure

```bash
cd infra/envs/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

After the first apply, you'll get outputs including:
- ECR repository URL
- GitHub Actions role ARN
- Application URL

### 4. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `AWS_ROLE_ARN_DEV`: The GitHub Actions role ARN from Terraform output
- `AWS_ROLE_ARN_PROD`: The GitHub Actions role ARN for prod (when ready)

### 5. Build and Push Initial Image

```bash
# Get ECR login
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com

# Build and push
cd gateway
docker build -t ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/gateway:latest .
docker push ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/paragrafic/gateway:latest
```

### 6. Update ECS Service

After pushing the initial image, update the task definition image URI in `terraform.tfvars` and run:

```bash
terraform apply
```

## CI/CD Workflows

### Continuous Integration (CI)

Triggered on pull requests to `develop` or `main`:
- Builds the application with Maven
- Runs tests
- Builds Docker image
- Runs Trivy security scan

### Continuous Deployment (CD)

**Dev Environment:**
- Triggered on push to `develop` branch
- Automatically deploys to dev environment
- Uses GitHub OIDC for AWS authentication

**Prod Environment:**
- Triggered on push to `main` branch or manual dispatch
- Requires manual approval (GitHub environment protection)
- Deploys to production with enhanced monitoring

## Module Documentation

### VPC Module

Creates a VPC with:
- Public subnets (2 AZs) for ALB
- Private subnets (2 AZs) for ECS and RDS
- NAT Gateways for private subnet internet access
- Internet Gateway for public access

### ALB Module

Creates:
- Application Load Balancer in public subnets
- Target groups with health checks
- HTTPS listener with SSL certificate
- HTTP to HTTPS redirect

### ECS Cluster Module

Creates:
- ECS cluster with Fargate capacity providers
- CloudWatch log groups
- Container Insights (optional)

### ECS Service Module

Creates:
- Task definition with container configuration
- ECS service with auto-scaling
- Security groups
- IAM roles for task execution and task

### RDS Module

Creates:
- PostgreSQL 16 instance
- Automated backups
- Multi-AZ deployment (prod)
- Secrets Manager for credentials
- Security groups

### IAM Module

Creates:
- GitHub OIDC provider
- GitHub Actions deployment role
- Policies for ECR and ECS access

### ACM Module

Creates:
- ACM certificate for domain
- DNS validation records
- Route53 A record pointing to ALB

## Environment Differences

| Feature | Dev | Prod           |
|---------|-----|----------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16    |
| Domain | test-0.paragrafic.pl | paragrafic.pl  |
| RDS Instance | db.t4g.micro | db.t4g.small   |
| RDS Multi-AZ | No | Yes            |
| ECS CPU | 256 (0.25 vCPU) | 512 (0.5 vCPU) |
| ECS Memory | 512 MB | 1024 MB        |
| Desired Tasks | 1 | 2              |
| Max Tasks | 3 | 6              |
| Log Retention | 7 days | 30 days        |
| ECR Retention | 10 images | 20 images      |

## Accessing the Application

After deployment:
- **Frontend**: https://test-0.paragraphic.pl
- **API**: https://test-0.paragraphic.pl/api

Health check endpoint: `/actuator/health`

## Database Access

Database credentials are stored in AWS Secrets Manager. To retrieve:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev-gateway-db-password \
  --region eu-north-1 \
  --query SecretString \
  --output text | jq .
```

## Monitoring and Logs

### CloudWatch Logs

```bash
aws logs tail /ecs/dev --follow --region eu-north-1
```

### ECS Service Status

```bash
aws ecs describe-services \
  --cluster dev-cluster \
  --services dev-gateway \
  --region eu-north-1
```

## Cost Estimation

### Dev Environment (~$100-150/month)
- NAT Gateway: ~$32/month (2 AZs)
- ALB: ~$20/month
- ECS Fargate: ~$15/month (0.25 vCPU, 512MB)
- RDS db.t4g.micro: ~$15/month
- Data transfer: ~$10-20/month

### Prod Environment (~$200-300/month)
- NAT Gateway: ~$32/month (2 AZs)
- ALB: ~$20/month
- ECS Fargate: ~$60/month (0.5 vCPU, 1GB, 2 tasks)
- RDS db.t4g.small Multi-AZ: ~$60/month
- Data transfer: ~$20-40/month

## Troubleshooting

### ECS Tasks Not Starting

Check CloudWatch logs:
```bash
aws logs tail /ecs/dev --follow
```

Check task definition:
```bash
aws ecs describe-task-definition --task-definition dev-gateway
```

### Database Connection Issues

Verify security group allows ECS tasks:
```bash
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

### SSL Certificate Issues

Check certificate validation status:
```bash
aws acm describe-certificate --certificate-arn <cert-arn>
```

## Cleanup

To destroy the infrastructure:

```bash
cd infra/envs/dev
terraform destroy
```

**Warning**: This will delete all resources including the database. Make sure to backup any important data first.

## Security Best Practices

1. **Secrets Management**: All sensitive data stored in AWS Secrets Manager
2. **Network Isolation**: ECS tasks and RDS in private subnets
3. **Encryption**: RDS encryption at rest, HTTPS in transit
4. **IAM**: Least privilege access with GitHub OIDC
5. **Security Scanning**: Trivy scans in CI pipeline
6. **Backup**: Automated RDS backups with 7-30 day retention

## Support

For issues or questions, please open an issue in the GitHub repository.
