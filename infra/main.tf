provider "aws" {
  region = var.region
}

resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh_and_app"
  description = "Allow SSH and frontend port inbound"

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Dashboard Frontend"
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Dashboard Backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  # Increase root volume to comfortably hold Docker images
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # ── System update ────────────────────────────────────────────────
    apt-get update -y
    apt-get upgrade -y

    # ── Docker prerequisites ─────────────────────────────────────────
    apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      git

    # ── Add Docker's official GPG key & repo ─────────────────────────
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # ── Install Docker Engine + Compose plugin ────────────────────────
    apt-get update -y
    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    # ── Enable & start Docker ─────────────────────────────────────────
    systemctl enable docker
    systemctl start docker

    # ── Allow ubuntu user to run Docker without sudo ──────────────────
    usermod -aG docker ubuntu

    # ── Verify installations (logged to /var/log/user-data.log) ───────
    docker --version
    docker compose version
  EOF

  tags = {
    Name = var.instance_name
  }
}