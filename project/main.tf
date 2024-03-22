# configure aws provider
provider "aws" {
  region = var.region
}

# create vpc
module "vpc" {
  source                  = "../modules/vpc"
  region                  = var.region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
}

# Create Security Group
module "security_group" {
  source       = "../modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  my_public_ip = var.my_public_ip
}

# Create EKS cluster
module "eks" {
  source                = "../modules/eks"
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  private_subnet_az1_id = module.vpc.private_subnet_az1_id
  private_subnet_az2_id = module.vpc.private_subnet_az2_id
}

# # Create Application Load Balancer
# module "alb" {
#   source                = "../modules/alb"
#   project_name          = module.vpc.project_name
#   alb_security_group_id = module.security_group.alb_security_group_id
#   public_subnet_az1_id  = module.vpc.public_subnet_az1_id
#   public_subnet_az2_id  = module.vpc.public_subnet_az2_id
#   vpc_id                = module.vpc.vpc_id
# }

# # Create Auto Scaling groups
# module "asg" {
#   source                     = "../modules/asg"
#   project_name               = module.vpc.project_name
#   region                     = var.region
#   instance_type              = var.instance_type
#   asg_min_size               = var.asg_min_size
#   asg_desired_capacity       = var.asg_desired_capacity
#   asg_max_size               = var.asg_max_size
#   amis                       = var.amis
#   public_subnet_az1_id       = module.vpc.public_subnet_az1_id
#   public_subnet_az2_id       = module.vpc.public_subnet_az2_id
#   alb_target_group_arn       = module.alb.alb_target_group_arn
#   inctance_security_group_id = module.security_group.inctance_security_group_id
# }