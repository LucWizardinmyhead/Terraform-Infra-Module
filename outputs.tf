output "instance_public_ip" {
    description = "Public IP of ec2 instance"
    value = aws_instance.prod.public_ip    
}

output "ami_4prod" {
  description = "ID of AMI used for prod instance"
  value = data.aws_ami.amazon_linux.id
}

output "my_public_ip" {
  description = "Your current public IP for SSH access"
  value       = local.my_ip
  sensitive = true
}

output "my_dynamic_ip" {
  description = "Your dynamically fetched public IP for SSH"
  value       = local.my_ip
  sensitive =  true
}

output "my_public_ipv4" {
  description = "Your dynamically fetched IPv4 address"
  value       = local.my_ip
  sensitive = true
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}