module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"
  name = var.cluster_name
  kubernetes_version = var.kubernetes_version
  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa = true
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    workers = {
      name = "workers-spot"
      instance_types = [var.node_instance_type]
      desired_size = var.node_desired_size
      min_size = var.node_min_size
      max_size = var.node_max_size
      disk_size = var.node_volume_size
      disk_type = "gp3"
      capacity_type = "ON_DEMAND"
      iam_role_additional_policies = {
        autoscaling = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
        ebs = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      labels = { workload = "lab" }
      tags = { Name = "${var.cluster_name}-workers" }
    }
  }

  cluster_addons = {
    vpc-cni = {
      configuration_values = jsonencode({ enableNetworkPolicy = "true" })
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }
  tags = { Name = var.cluster_name }
}
