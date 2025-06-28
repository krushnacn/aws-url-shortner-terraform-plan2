provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ----------------------
# VPC
# ----------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "url-shortener-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = terraform.workspace
    Project     = "url-shortener"
  }
}

# ----------------------
# EKS
# ----------------------
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.5"

  cluster_name    = "eks-${terraform.workspace}"
  cluster_version = "1.29"

  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  enable_irsa     = true

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = terraform.workspace
    Project     = "url-shortener"
  }
}

# ----------------------
# RDS (MySQL)
# ----------------------
resource "random_password" "db_password" {
  length  = 16
  special = false
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier = "mysql-${terraform.workspace}"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  name     = "urls"
  username = "urladmin"
  password = random_password.db_password.result

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  skip_final_snapshot = true

  tags = {
    Environment = terraform.workspace
    Project     = "url-shortener"
  }
}

# ----------------------
# Application Load Balancer + WAF
# ----------------------
resource "aws_wafv2_web_acl" "url_waf" {
  name  = "url-shortener-waf-${terraform.workspace}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "urlShortenerACL"
    sampled_requests_enabled   = true
  }
}

# ALB Ingress Controller IAM Role for ServiceAccount (IRSA)
module "alb_ingress_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-serviceaccounts-eks"
  version = "~> 5.30.0"

  role_name = "alb-ingress-controller-${terraform.workspace}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:alb-ingress-controller"]
    }
  }

  tags = {
    Environment = terraform.workspace
  }
}

# Outputs
output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_username" {
  value = module.rds.username
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
