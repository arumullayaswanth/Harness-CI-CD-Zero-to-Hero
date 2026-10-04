# Bastion Server IAM Role (Admin Access)
resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach AdministratorAccess to bastion role
resource "aws_iam_role_policy_attachment" "bastion_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.bastion.name
}

# Instance Profile (to attach role to EC2)
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name_prefix = "${var.cluster_name}-bastion-"
  vpc_id      = aws_vpc.main.id

  # Allow ALL inbound traffic (for SonarQube, apps, testing)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All TCP inbound"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name = "${var.cluster_name}-bastion-sg"
  }
}

# AMI is hardcoded: ami-02b64aa047cb5edf5 (Amazon Linux 2023, us-east-1)

# Bastion EC2 Instance (fixed AMI, SSM access, no key pair)
resource "aws_instance" "bastion" {
  ami                    = "ami-02b64aa047cb5edf5"
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # Don't recreate EC2 when user_data changes (keeps data safe)
  user_data_replace_on_change = false

  # Runs tools.sh on first boot only
  user_data = file("${path.module}/tools.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.cluster_name}-bastion"
  }

  depends_on = [aws_eks_cluster.main]
}

# EKS Access Entry - Allow bastion role to access cluster
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.bastion.arn
  type          = "STANDARD"

  lifecycle {
    ignore_changes = [principal_arn]
  }
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.bastion.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  # Must wait for the access entry to exist first — otherwise AWS returns
  # ResourceNotFoundException (the entry isn't registered yet).
  depends_on = [aws_eks_access_entry.bastion]
}
