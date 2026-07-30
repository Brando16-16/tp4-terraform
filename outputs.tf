output "bastion_public_ip" {
  description = "IP publique du Bastion Host (pour s'y connecter en SSH)"
  value       = aws_instance.ec2_bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.ec2_bastion.private_ip
}

output "reverse_proxy_public_ip" {
  description = "IP publique du Reverse Proxy (pour l'ouvrir dans un navigateur)"
  value       = aws_instance.ec2_proxy.public_ip
}

output "reverse_proxy_private_ip" {
  value = aws_instance.ec2_proxy.private_ip
}

output "web_server_private_ip" {
  description = "IP privée du Serveur Web (utilisée dans la config nginx du proxy)"
  value       = aws_instance.ec2_web.private_ip
}

output "vpc_id" {
  value = aws_vpc.vpc_admin.id
}
