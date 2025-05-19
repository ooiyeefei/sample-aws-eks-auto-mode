# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = module.vpc.vpc_id

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
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.name}-rds-subnet-group"
  }
}

# DB Parameter Group for pg_vector
resource "aws_db_parameter_group" "postgres_vector" {
  name        = "${var.name}-postgres-vector"
  family      = "postgres15"
  description = "Parameter group for PostgreSQL with pg_vector extension"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pg_vector"
  }

  tags = {
    Name = "${var.name}-postgres-vector"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.name}-postgres"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true
  
  db_name                = "vectordb"
  username               = "postgres"
  password               = "YourStrongPasswordHere" # Consider using AWS Secrets Manager or SSM Parameter Store
  
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  parameter_group_name   = aws_db_parameter_group.postgres_vector.name
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name}-postgres-final-snapshot"
  
  apply_immediately       = true
  
  tags = {
    Name = "${var.name}-postgres"
  }
}

# Output the RDS endpoint
output "rds_endpoint" {
  description = "The connection endpoint for the PostgreSQL instance"
  value       = aws_db_instance.postgres.endpoint
}
