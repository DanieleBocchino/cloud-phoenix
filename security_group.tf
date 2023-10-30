# Security Group for Document DB
resource "aws_security_group" "documentdb_sg" {
  name        = "documentdb-sg"
  description = "Security group for MongoDB cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
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

# ____ Security Group ____

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all internal traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }


  tags = {
    Name        = "ecs_sg"
    Environment = "prod"
  }
}
