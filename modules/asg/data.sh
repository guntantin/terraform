#!/bin/bash
sudo apt-get remove needrestart -y
sudo apt update -y
sudo apt install awscli  docker.io -y
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 111085330655.dkr.ecr.eu-central-1.amazonaws.com
docker run -p 3000:3000 111085330655.dkr.ecr.eu-central-1.amazonaws.com/brainscale:latest