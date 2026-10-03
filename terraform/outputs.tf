output "cluster_name" { 
	value = module.eks.cluster_name 
}
output "cluster_endpoint" { 
	value = module.eks.cluster_endpoint 
}
output "region" { 
	value = var.aws_region 
}
output "vpc_id" { 
	value = module.vpc.vpc_id 
}
output "private_subnets" { 
	value = module.vpc.private_subnets
}
output "public_subnets" { 
	value = module.vpc.public_subnets
}
output "oidc_provider_arn" { 
	value = module.eks.oidc_provider_arn 
}
output "alb_controller_role_arn" { 
	value = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null 
}
