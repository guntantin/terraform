# configure aws provider
provider "aws" {
  region = var.region
}

# create vpc
module "vpc" {
  source                 = "../modules/vpc"
  region                 = var.region
  project_name           = var.project_name
  vpc_cidr               = var.vpc_cidr
  public_subnet_az1_cidr = var.public_subnet_az1_cidr
  public_subnet_az2_cidr = var.public_subnet_az2_cidr
}

# Create Security Group
module "security_group" {
  source       = "../modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  my_public_ip = var.my_public_ip
}

# Create Application Load Balancer
module "alb" {
  source                = "../modules/alb"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
}

# Create Auto Scaling groups
module "asg" {
  source                     = "../modules/asg"
  project_name               = module.vpc.project_name
  region                     = var.region
  instance_type              = var.instance_type
  asg_min_size               = var.asg_min_size
  asg_desired_capacity       = var.asg_desired_capacity
  asg_max_size               = var.asg_max_size
  amis                       = var.amis
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  alb_target_group_arn       = module.alb.alb_target_group_arn
  inctance_security_group_id = module.security_group.inctance_security_group_id
}

resource "aws_iam_role" "ecr_role" {
  name = "ECRRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecr.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRPolicy"
  description = "IAM policy for ECR"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_attachment" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.ecr_role.name
}
