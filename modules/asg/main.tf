resource "aws_launch_template" "node_lt" {
  name                   = "${terraform.workspace}-${var.project_name}-LT"
  image_id               = var.amis["${var.region}"]
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.inctance_security_group_id, ]
  key_name               = aws_key_pair.vm_key.id
  iam_instance_profile {
    name = "ECRPolicy"
  }

  user_data = (base64encode(<<EOF
#!/bin/bash
sudo apt-get remove needrestart -y
sudo apt update -y
sudo apt install awscli  docker.io -y
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 111085330655.dkr.ecr.eu-central-1.amazonaws.com
docker run -p 3000:3000 111085330655.dkr.ecr.eu-central-1.amazonaws.com/brainscale:latest
EOF
  ))

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "web" {
  name                      = "${terraform.workspace}-${var.project_name}-asg"
  wait_for_capacity_timeout = "5m"
  health_check_grace_period = "300"
  health_check_type         = "EC2"
  force_delete              = true
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size

  target_group_arns = [var.alb_target_group_arn]

  launch_template {
    id      = aws_launch_template.node_lt.id
    version = "$Latest"
  }

  # launch_configuration = aws_launch_configuration.web.name
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 70
    }
    triggers = [/*"launch_template",*/ "desired_capacity"]
  }

  vpc_zone_identifier = [
    "${var.public_subnet_az1_id}",
    "${var.public_subnet_az2_id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${terraform.workspace}-instance"
    propagate_at_launch = true
  }
}

# Using my local public key
resource "aws_key_pair" "vm_key" {
  key_name   = "${terraform.workspace}-id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwE3DgPBFChc0cXIBa6prLPe4wuOaeUXgcG2TgEMOOEQr3jjPbmma3iDzUKsZ4fkQzNrLRu9xdq3LU4qKdiJfEUKBGY9Bg3W5oVzN9OGkgo7zueEL4BcWHkSBkd5vUztMD9kLtoS0/G0+VJ3JWoi2cdpC3qRdp6qJUAgxCQSzEXkpu+HgEDR/h5B0gPdNiDIz5MzZ+MCF0Y4ZnTAQXtw86e9RtpDJ+T7LRtGp6xsYn4PEaHwiD0++kFtPyF8u2NgPyX65Bu8ClB6LINADt6tUz63BG9B/PPsX/PefwV5t6f73/geENj7WAi0zWTXa3DTA+xEhbmz1jPJAxiNGGP6rZnSmPDktDajIYLZ6KOyl8HX78V2fWkQxUtHi3QIsKrdCDkMhLBUXWzE/YancRm3/lJ7DvYwApiTjE6QJW8Quuxz5oDoXb3ySFPSxORraO+t7AKGUKbr35Z6x/VM1kRYuBPaXRL0wKAsxH/9j9nkZKjLPRfKcSko9jzc3Aem7S2gk= art@art"
}
