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

output "ec2_elastic_ip" {
  description = "Elastic IP associated with the EC2 instance"
  value = aws_eip.ec2_eip.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value = "ssh -i ~/.ssh/${var.private_key_path} ubuntu@${aws_eip.ec2_eip.public_ip}"
}