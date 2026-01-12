import json
import boto3
import psycopg2
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')


def get_db_credentials(secret_arn):
    """Retrieve database credentials from Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(response['SecretString'])
        return secret
    except Exception as e:
        logger.error(f"Error retrieving secret: {e}")
        raise


def handler(event, context):
    """
    Post-authentication trigger for Cognito
    Creates or updates user record in database when user authenticates
    
    Event structure:
    {
        "request": {
            "userAttributes": {
                "sub": "cognito-user-id",
                "email": "user@example.com",
                "email_verified": "true"
            }
        }
    }
    """
    
    logger.info("Post-authentication trigger invoked")
    
    # Extract user attributes
    user_attributes = event['request']['userAttributes']
    cognito_sub = user_attributes['sub']
    email = user_attributes['email']
    email_verified = user_attributes.get('email_verified', 'false') == 'true'
    
    logger.info(f"Processing authentication for cognito_sub: {cognito_sub}, email: {email}")
    
    # Get database configuration
    db_host = os.environ['DB_HOST']
    db_port = os.environ.get('DB_PORT', '5432')
    db_name = os.environ['DB_NAME']
    db_secret_arn = os.environ['DB_SECRET_ARN']
    
    connection = None
    
    try:
        # Get database credentials
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
        
        cursor = connection.cursor()
        
        # Check if user exists by cognito_sub
        cursor.execute(
            "SELECT id, email, email_verified FROM users WHERE cognito_sub = %s",
            (cognito_sub,)
        )
        result = cursor.fetchone()
        
        if result:
            # User exists - update email and verification status if changed
            user_id, existing_email, existing_verified = result
            
            if existing_email != email or existing_verified != email_verified:
                cursor.execute("""
                    UPDATE users 
                    SET email = %s, 
                        email_verified = %s, 
                        updated_at = CURRENT_TIMESTAMP
                    WHERE cognito_sub = %s
                """, (email, email_verified, cognito_sub))
                
                connection.commit()
                logger.info(f"Updated user {user_id} - email: {email}, verified: {email_verified}")
            else:
                logger.info(f"User {user_id} already up-to-date")
        else:
            # New user - create record
            cursor.execute("""
                INSERT INTO users (username, email, cognito_sub, email_verified, enabled, created_at, updated_at, version)
                VALUES (%s, %s, %s, %s, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                RETURNING id
            """, (email, email, cognito_sub, email_verified))
            
            user_id = cursor.fetchone()[0]
            connection.commit()
            
            logger.info(f"Created new user {user_id} for cognito_sub: {cognito_sub}")
            
            # Assign default USER role
            cursor.execute("""
                INSERT INTO user_roles (user_id, role, created_at)
                VALUES (%s, %s, CURRENT_TIMESTAMP)
            """, (user_id, 'USER'))
            
            connection.commit()
            logger.info(f"Assigned USER role to user {user_id}")
        
        cursor.close()
        
    except Exception as e:
        logger.error(f"Error processing post-authentication: {str(e)}")
        if connection:
            connection.rollback()
        raise
        
    finally:
        if connection:
            connection.close()
    
    # Return event unchanged (required by Cognito)
    return event
