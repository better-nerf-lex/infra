import json
import boto3
import psycopg2
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')
s3_client = boto3.client('s3')


def get_db_credentials(secret_arn):
    """Retrieve database credentials from Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(response['SecretString'])
        return secret
    except Exception as e:
        logger.error(f"Error retrieving secret: {e}")
        raise


def get_sql_from_s3(bucket, key):
    """Download SQL file from S3"""
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        sql_content = response['Body'].read().decode('utf-8')
        return sql_content
    except Exception as e:
        logger.error(f"Error downloading SQL from S3: {e}")
        raise


def execute_sql(connection, sql_content):
    """Execute SQL script"""
    try:
        cursor = connection.cursor()
        cursor.execute(sql_content)
        connection.commit()
        cursor.close()
        logger.info("SQL executed successfully")
        return True
    except Exception as e:
        logger.error(f"Error executing SQL: {e}")
        connection.rollback()
        raise


def migrate_cognito_columns(connection):
    """Add Cognito columns if they don't exist"""
    try:
        cursor = connection.cursor()
        
        # Check if cognito_sub column exists
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'cognito_sub'
        """)
        
        if not cursor.fetchone():
            logger.info("Adding cognito_sub column to users table")
            cursor.execute("ALTER TABLE users ADD COLUMN cognito_sub VARCHAR(255) UNIQUE")
            connection.commit()
        
        # Check if email_verified column exists
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'email_verified'
        """)
        
        if not cursor.fetchone():
            logger.info("Adding email_verified column to users table")
            cursor.execute("ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE")
            connection.commit()
        
        # Make password nullable
        cursor.execute("""
            SELECT is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'password'
        """)
        result = cursor.fetchone()
        if result and result[0] == 'NO':
            logger.info("Making password column nullable")
            cursor.execute("ALTER TABLE users ALTER COLUMN password DROP NOT NULL")
            connection.commit()
        
        cursor.close()
        logger.info("Cognito columns migration completed")
        return True
    except Exception as e:
        logger.error(f"Error migrating Cognito columns: {e}")
        connection.rollback()
        raise


def lambda_handler(event, context):
    """
    Lambda handler for RDS schema initialization
    
    Expected environment variables:
    - DB_HOST: RDS hostname
    - DB_PORT: RDS port (default: 5432)
    - DB_NAME: Database name
    - DB_SECRET_ARN: ARN of the Secrets Manager secret containing credentials
    - SCHEMA_BUCKET: S3 bucket containing schema files
    - INIT_SCHEMA_KEY: S3 key for init-schema.sql
    - SEED_DATA_KEY: S3 key for seed-data.sql (optional)
    - ENVIRONMENT: Environment name (dev/prod)
    """
    
    logger.info("Starting RDS schema initialization")
    
    # Get configuration from environment
    db_host = os.environ['DB_HOST']
    db_port = os.environ.get('DB_PORT', '5432')
    db_name = os.environ['DB_NAME']
    db_secret_arn = os.environ['DB_SECRET_ARN']
    schema_bucket = os.environ['SCHEMA_BUCKET']
    init_schema_key = os.environ['INIT_SCHEMA_KEY']
    seed_data_key = os.environ.get('SEED_DATA_KEY', '')
    environment = os.environ.get('ENVIRONMENT', 'dev')
    
    connection = None
    
    try:
        # Get database credentials
        logger.info("Retrieving database credentials")
        credentials = get_db_credentials(db_secret_arn)
        db_username = credentials.get('username')
        db_password = credentials.get('password')
        
        # Connect to database
        logger.info(f"Connecting to database at {db_host}:{db_port}/{db_name}")
        connection = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_username,
            password=db_password,
            sslmode='require',
            connect_timeout=10
        )
        
        logger.info("Database connection established")
        
        # Execute init schema
        logger.info(f"Downloading init schema from s3://{schema_bucket}/{init_schema_key}")
        init_schema_sql = get_sql_from_s3(schema_bucket, init_schema_key)
        
        logger.info("Executing init schema")
        execute_sql(connection, init_schema_sql)
        
        # Run Cognito columns migration
        logger.info("Running Cognito columns migration")
        migrate_cognito_columns(connection)
        
        # Execute seed data only in dev environment
        if environment == 'dev' and seed_data_key:
            logger.info(f"Environment is {environment}, executing seed data")
            logger.info(f"Downloading seed data from s3://{schema_bucket}/{seed_data_key}")
            seed_data_sql = get_sql_from_s3(schema_bucket, seed_data_key)
            
            logger.info("Executing seed data")
            execute_sql(connection, seed_data_sql)
        else:
            logger.info(f"Skipping seed data (environment={environment})")
        
        
        logger.info("Schema initialization completed successfully")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Schema initialization completed successfully',
                'environment': environment,
                'database': db_name
            })
        }
        
    except Exception as e:
        logger.error(f"Schema initialization failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Schema initialization failed: {str(e)}',
                'environment': environment,
                'database': db_name
            })
        }
        
    finally:
        if connection:
            connection.close()
            logger.info("Database connection closed")
