resource "aws_vpc" "vpc_admin" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-admin"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id            = aws_vpc.vpc_admin.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = var.az

  tags = {
    Name = "${var.project_name}-subnet-public"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id            = aws_vpc.vpc_admin.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = var.az

  tags = {
    Name = "${var.project_name}-subnet-private"
  }
}

resource "aws_internet_gateway" "internet_gateway_main" {
  vpc_id = aws_vpc.vpc_admin.id

  tags = {
    Name = "${var.project_name}-igw-main"
  }
}

resource "aws_route_table" "route_table_main" {
  vpc_id = aws_vpc.vpc_admin.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_main.id
  }

  tags = {
    Name = "${var.project_name}-rt-main"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_main.id
}

resource "aws_route_table_association" "route_table_association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_main.id
}

resource "aws_security_group" "sg_bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "SG pour le Bastion Host"
  vpc_id      = aws_vpc.vpc_admin.id

  ingress {
    description = "SSH depuis mon poste de travail uniquement"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-bastion"
  }
}

resource "aws_security_group" "sg_web" {
  name        = "${var.project_name}-sg-web"
  description = "SG pour le Serveur Web"
  vpc_id      = aws_vpc.vpc_admin.id

  tags = {
    Name = "${var.project_name}-sg-web"
  }
}

resource "aws_security_group" "sg_proxy" {
  name        = "${var.project_name}-sg-proxy"
  description = "SG pour le Reverse Proxy"
  vpc_id      = aws_vpc.vpc_admin.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS depuis Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH uniquement depuis le Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    description     = "HTTP applicatif uniquement vers le Serveur Web"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  tags = {
    Name = "${var.project_name}-sg-proxy"
  }
}

resource "aws_security_group_rule" "sgrule_web_from_proxy" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_web.id
  source_security_group_id = aws_security_group.sg_proxy.id
}

resource "aws_security_group_rule" "sgrule_web_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_web.id
  source_security_group_id = aws_security_group.sg_bastion.id
}

data "aws_ami" "ami_bastion" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2_bastion" {
  ami                         = data.aws_ami.ami_bastion.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }
}

data "aws_ami" "ami_proxy" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2_proxy" {
  ami                         = data.aws_ami.ami_proxy.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_proxy.id]
  associate_public_ip_address = true

  tags = {
    Name = "proxy"
  }
}

data "aws_ami" "ami_web" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2_web" {
  ami                         = data.aws_ami.ami_web.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.subnet_private.id
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  associate_public_ip_address = false

  tags = {
    Name = "web"
  }
}

# Règle egress TEMPORAIRE pour permettre apt/docker/nginx de sortir vers
# Internet pendant la configuration initiale (Terraform supprime la règle
# "allow all outbound" par défaut d'AWS dès qu'un security group n'a aucun
# bloc egress complet). À retirer du infra.csv une fois les logiciels
# installés, pour revenir à une sortie strictement limitée.
resource "aws_security_group_rule" "sgrule_egress_temp_web" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_web.id
}

# Règle egress TEMPORAIRE pour permettre apt/docker/nginx de sortir vers
# Internet pendant la configuration initiale (Terraform supprime la règle
# "allow all outbound" par défaut d'AWS dès qu'un security group n'a aucun
# bloc egress complet). À retirer du infra.csv une fois les logiciels
# installés, pour revenir à une sortie strictement limitée.
resource "aws_security_group_rule" "sgrule_egress_temp_proxy" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_proxy.id
}

