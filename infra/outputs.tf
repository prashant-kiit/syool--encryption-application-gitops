output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ec2_instance.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.ec2_instance.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.ec2_instance.public_ip}"
}