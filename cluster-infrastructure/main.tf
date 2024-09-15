terraform {
  backend "s3" {
    bucket         = "5907-terraform-epam-cora"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "epam-cora-terraform"
  }
  required_version = "1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host = module.cluster-infra.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster-infra.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.cluster-infra.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host = module.cluster-infra.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster-infra.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.cluster-infra.cluster_name]
    }
  }
}

provider "postgresql" {
  host      = module.cluster-infra.rds_address
  port      = module.cluster-infra.rds_port
  username  = module.cluster-infra.rds_root_username
  password  = module.cluster-infra.rds_root_pass_secret
  superuser = false
}

module "cluster-infra" {
  source                            = "git::https://github.com/epam/cloud-pipeline//deploy/infra/aws/terraform/cloud-native/cluster-infra?ref=f_aws_native_infra""
  deployment_name                   = "epamcora-terraform"
  deployment_env                    = "epamcora-terraform"
  vpc_id                            = "vpc-05deec794c0d4e0c1"
  external_access_security_group_ids = ["sg-05fcc2187b2dfe967"]
  subnet_ids = ["subnet-0a16832c67515239b", "subnet-04243c22075f1627f", "subnet-003d978a107ffa704"]
  iam_role_permissions_boundary_arn = "arn:aws:iam::590788709872:policy/CP-Service-Policy"
  eks_system_node_group_subnet_ids = ["subnet-003d978a107ffa704"]
  cp_edge_elb_schema                = "internet-facing"
  cp_edge_elb_subnet                = "subnet-04243c22075f1627f"
  cp_edge_elb_ip                    = "52.73.71.164"
  cp_api_srv_host                   = "epam.fascmari.people.aws.dev"
  cp_docker_host                    = "docker.epam.fascmari.people.aws.dev"
  cp_edge_host                      = "edge.epam.fascmari.people.aws.dev"
  cp_gitlab_host                    = "git.epam.fascmari.people.aws.dev"
  eks_additional_role_mapping = [
    {
      iam_role_arn  = "arn:aws:iam::590788709872:role/epamcora-terraform-epamcora-terraform-BastionExecutionRole"
      eks_role_name = "system:node:{{EC2PrivateDNSName}}"
      eks_groups = ["system:bootstrappers", "system:nodes"]
    }
  ]
}  