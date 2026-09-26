terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.62" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.38" }
    helm = { source = "hashicorp/helm", version = "~> 3.0" }
    http = { source = "hashicorp/http", version = "~> 3.5" }
  }
  backend "s3" {}
}
