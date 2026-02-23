variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Ubuntu AMI ID for ap-south-1"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8" # Ubuntu 22.04 LTS
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "EC2 instance name tag"
  type        = string
  default     = "syook-encryption-app-instance"
}

variable "key_name" {
  description = "SSH key pair name in AWS"
  type        = string
  default     = "syook-encryption-app-key"
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/syook_encryption_app_key.pub"
}

variable "private_key_path" {
  description = "Path to your SSH private key file (for ssh command output)"
  type        = string
  default     = "~/.ssh/syook_encryption_app_key"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH. Replace with your IP e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}