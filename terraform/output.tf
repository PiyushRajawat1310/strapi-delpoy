output "public_ip" {
  value = aws_instance.strapi_ec2.public_ip
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
