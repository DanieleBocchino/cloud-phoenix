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
    from_port   = 3000
    to_port     = 3000
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


resource "aws_security_group_rule" "ecs_to_docdb" {
  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # Sostituisci con l'effettivo blocco CIDR, se necessario
}


resource "aws_security_group_rule" "docdb_to_ecs" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.documentdb_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id
}

