variable "aws_region" {
  description = "Région AWS utilisée pour le déploiement"
  type        = string
  default     = "us-east-1"
}

variable "az" {
  description = "Zone de disponibilité pour les sous-réseaux et instances"
  type        = string
  default     = "us-east-1a"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 existante (AWS Academy fournit 'vockey')"
  type        = string
  default     = "vockey"
}

variable "my_ip" {
  description = "Ton adresse IP publique, au format CIDR (ex: 90.12.34.56/32), autorisée à SSH sur le Bastion"
  type        = string
  # Pas de valeur par défaut : à renseigner obligatoirement dans terraform.tfvars
}

variable "instance_type" {
  description = "Type d'instance EC2 utilisé pour les 3 machines"
  type        = string
  default     = "t2.micro"
}

variable "app_port" {
  description = "Port sur lequel écoute l'application (user-app, via gunicorn/Docker)"
  type        = number
  default     = 8080
}

variable "project_name" {
  description = "Préfixe utilisé pour nommer toutes les ressources"
  type        = string
  default     = "tp4"
}
