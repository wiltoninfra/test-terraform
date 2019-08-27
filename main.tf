# Ambiente Test App
# Author: Wilton Guilherme
# IAC



# Module VPC Main
module "vpc" {
  source                = "./modules/vpc"
  name = "my-vpc"
  cidr = "10.10.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = true
  enable_vpn_gateway = true
  tags = {
    Terraform = "true"
    Environment = "dev"

  }
}
module "ecs" {
  source = "./modules/ecs"
  vpcid = "${module.vpc.vpc_id}"
  public = ["${module.vpc.subnet_pub}"]
  private = ["${module.vpc.subnet_priv}"]
  security-group  = "${module.securitygroup.security_group}"      
  security-group_ecs = "${module.securitygroup.security_group_ecs}"

}


module "securitygroup" {
  source                = "./modules/securitygroup"
  vpcid                = "${module.vpc.vpc_id}"

}
