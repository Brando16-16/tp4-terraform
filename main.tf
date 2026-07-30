############################################
# TP 4 — Génération automatique d'une infrastructure Terraform
# via templates + infra.csv (gen.sh, fourni et non modifié).
# Ce fichier ne contient que le provider : les ressources sont
# toutes dans new_infra.tf, généré par gen.sh.
############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Les identifiants AWS Academy (access key / secret key / session token)
# sont lus automatiquement par le provider depuis les variables
# d'environnement AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY et
# AWS_SESSION_TOKEN. Ne JAMAIS écrire de clés en dur ici.
provider "aws" {
  region = var.aws_region
}
