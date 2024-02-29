resource "aws_launch_template" "node_lt" {
  name          = "${terraform.workspace}-${var.project_name}-LT"
  image_id      = var.amis["${var.aws_region}"]
  instance_type = var.instance_type
  vpc_security_group_ids = [var.inctance_security_group_id,]
  key_name      = aws_key_pair.vm_key.id
  iam_instance_profile {
    name = "ECR"
  }

  user_data = "${base64encode(<<EOF
#!/bin/bash
sudo apt-get remove needrestart -y
sudo apt update -y
sudo apt install awscli  docker.io -y
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 111085330655.dkr.ecr.eu-central-1.amazonaws.com
docker run -p 3000:3000 111085330655.dkr.ecr.eu-central-1.amazonaws.com/brainscale:latest
EOF
)}"

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
    "${var.subnet_az_a_id}",
    "${var.subnet_az_b_id}"
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4XrMLieHYyrhXakJhudyfIp9rgFRZDeYKrlPfBB2t+9Yq4favh+e7AVszU2R3fwP5RDrShm9IHp6WJSeDtAGFfHGuIiJqKFtr5kG24EqALM0/5uk6pC1Lzh2mKVSTg6wIHZcHcdgqO83c3LtySAw8hiStQHeFlW2ZvbU3MikBg45J2Wi4g0oWoICKDga+TH/r/iQQXG19nzWg9fsafDKg51nZH8Fnkuca5M8u0eV6uC7YXFHT76dw/TF6lFw2r5Rzq93m6SRMwzufr96y7b0QgZiqeWWHklwaahwUNx5Q0qmdG37N9aj5F3+e7WlIw9Db0z9f1i7qtfGWd+/hewkN1YrXWW7pfNwbfJQvSDRoTY+b7bPjAjDW26ivsAN2FzYYOnMLGIlxJo2wissyjD1fZLnnua6LnGiR8SBp6qmN1ZHUVB4ap/Uoc/Em0U5Ebks5WJxHw7tctYN4h7nzwbsKtztUQLehz4MM99BNYIUddiO/xDk9gA0fXv1gLC1QNF0= Lenovo@LAPTOP-ATQHB6OO"
}
