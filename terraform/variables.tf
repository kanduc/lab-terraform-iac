variable "aws_region" { 
	type = string 
	default = "us-east-1" 
}
variable "cluster_name" { 
	type = string 
	default = "eks-lab-tec" 
}
variable "kubernetes_version" { 
	type = string 
	default = "1.35" 
}
variable "environment" { 
	type = string 
	default = "lab" 
}
variable "vpc_cidr" { 
	type = string 
	default = "10.0.0.0/16" 
}
variable "azs" { 
	type = list(string) 
	default = ["us-east-1a", "us-east-1b"] 
}
variable "node_instance_type" { 
	type = string 
	default = "t3.medium" 
}
variable "node_desired_size" { 
	type = number 
	default = 2 
}
variable "node_min_size" { 
	type = number 
	default = 2 
}
variable "node_max_size" { 
	type = number 
	default = 4 
}
variable "node_volume_size" { 
	type = number 
	default = 30 
}
variable "manage_namespace_with_terraform" { 
	type = bool 
	default = true 
}
variable "enable_alb_controller" { 
	type = bool 
	default = true 
}
variable "alb_controller_version" { 
	type = string 
	default = "1.14.1" 
}
variable "github_actions_role_arn" { 
	type = string 
	default = "" 
}
