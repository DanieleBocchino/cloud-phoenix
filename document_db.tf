# __________________________________ Document DB __________________________________

resource "aws_docdb_cluster" "db_phoenix_cluster" {
  cluster_identifier      = "db-phoenix-cluster"
  engine                  = "docdb"
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_docdb_subnet_group.phoenix_subnet_group.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.documentdb_sg.id]
  backup_retention_period = 7
    port                    = 27017

}

resource "aws_docdb_cluster_instance" "phoenix_cluster_instance" {
  identifier         = "phoenix-cluster-instance"
  cluster_identifier = aws_docdb_cluster.db_phoenix_cluster.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_subnet_group" "phoenix_subnet_group" {
  name       = "phoenix-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "My phoenix db subnet group"
  }
}

output "DB_CONNECTION_STRING" {
  value = "mongodb://${var.db_username}:${var.db_password}@${aws_docdb_cluster.db_phoenix_cluster.endpoint}:${aws_docdb_cluster.db_phoenix_cluster.port}/phoenix-mongo-db"
}

output "DB_HOST" {
  value = aws_docdb_cluster.db_phoenix_cluster.endpoint
}

output "DB_PORT" {
  value = aws_docdb_cluster.db_phoenix_cluster.port
}


# Security Group for Document DB
resource "aws_security_group" "documentdb_sg" {
  name        = "documentdb-sg"
  description = "Security group for MongoDB cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.name]
    description = "Allow MongoDB traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "allow_mongodb_traffic"
    Environment = "prod"
  }
}
