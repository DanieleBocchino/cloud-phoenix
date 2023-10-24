# __________________________________________________ Security Group __________________________________________________

module "phoenix_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "phoenix-sg"
  description = "Security group for Phoenix app"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
}
