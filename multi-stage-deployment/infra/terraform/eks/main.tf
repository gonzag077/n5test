provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "demo-eks"
  cluster_version = "1.27"
  subnet_ids      = ["subnet-123", "subnet-456"]
  vpc_id          = "vpc-xxx"

  node_groups = {
    demo = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }
}

output "kubeconfig" {
  value = module.eks.kubeconfig
  sensitive = true
}
