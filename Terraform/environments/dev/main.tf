provider "aws" {
  region = "us-east-1"
  profile = "franklynux"
}


locals {
  hub_cluster_name   = "fleetform-hub-${random_string.suffix.result}"
  spoke_cluster_name = "fleetform-spoke-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

# --- HUB ---
module "hub_vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "hub"
}

module "hub_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                                     = local.hub_cluster_name
  kubernetes_version                       = "1.30"
  enable_cluster_creator_admin_permissions = true

  # EKS Addons
  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.hub_vpc.vpc_id
  subnet_ids = module.hub_vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

#--- SPOKE ---
module "spoke_vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.1.0.0/16"
  vpc_name   = "spoke"
}

module "spoke_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                                     = local.spoke_cluster_name
  kubernetes_version                       = "1.30"
  enable_cluster_creator_admin_permissions = true

  # EKS Addons
  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.spoke_vpc.vpc_id
  subnet_ids = module.spoke_vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}