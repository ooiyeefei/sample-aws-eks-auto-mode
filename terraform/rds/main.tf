# Create a random password for PostgreSQL
resource "random_password" "postgres" {
  length           = 16
  special          = true
  override_special = "!*-_"
}

# Create AWS Secrets Manager secret for PostgreSQL credentials
resource "aws_secretsmanager_secret" "postgres_credentials" {
  name_prefix = "${var.name}-postgres-credentials-"
  description = "PostgreSQL credentials for OpenWebUI"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-postgres-credentials"
  }
}

# Store the credentials in the secret
resource "aws_secretsmanager_secret_version" "postgres_credentials" {
  secret_id = aws_secretsmanager_secret.postgres_credentials.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.postgres.result
    dbname   = "vectordb"
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    connectionString = "postgresql://postgres:${random_password.postgres.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/vectordb"
  })

  depends_on = [aws_db_instance.postgres]
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds" {
  name       = "${var.name}-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.name}-rds-subnet-group"
  }
}

# DB Parameter Group for PostgreSQL with enhanced logging
resource "aws_db_parameter_group" "postgres_vector" {
  name        = "${var.name}-postgres-vector"
  family      = "postgres15"
  description = "Parameter group for PostgreSQL with pg_vector extension"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
  
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1"
  }

  tags = {
    Name = "${var.name}-postgres-vector"
  }
}

# IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.name}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS PostgreSQL Instance with improved settings
resource "aws_db_instance" "postgres" {
  identifier             = "${var.name}-postgres"
  engine                 = "postgres"
  engine_version         = "15.13"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true
  
  db_name                = "vectordb"
  username               = "postgres"
  password               = random_password.postgres.result
  
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  parameter_group_name   = aws_db_parameter_group.postgres_vector.name
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  skip_final_snapshot     = true
  deletion_protection     = false
  
  performance_insights_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
  
  apply_immediately       = true
  
  tags = {
    Name = "${var.name}-postgres"
  }
}

# IAM policy for Secrets Manager access
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.name}-secrets-access"
  description = "Policy for accessing PostgreSQL credentials in Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.postgres_credentials.arn
      }
    ]
  })
}

# NOTE: The policy attachment that links this policy to an IAM role
# has been moved to the `apps` module to decouple RDS from other services.
# This module now only creates the policy and outputs its ARN.

# Create a separate connection string secret for easier management and rotation
resource "aws_secretsmanager_secret" "db_connection_string" {
  name_prefix = "${var.name}-db-connection-"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-db-connection"
  }
}

resource "aws_secretsmanager_secret_version" "db_connection_string_version" {
  secret_id = aws_secretsmanager_secret.db_connection_string.id
  secret_string = jsonencode({
    connectionString = "postgresql://postgres:${random_password.postgres.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/vectordb"
  })
  
  depends_on = [aws_db_instance.postgres]
} 