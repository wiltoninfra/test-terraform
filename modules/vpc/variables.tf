variable "name" {}
variable "cidr" {}
variable "azs" {type = "list" } 

variable "enable_nat_gateway" {} 
variable "enable_vpn_gateway" {} 
variable "tags" {type = "list" } 
  

variable subnet-private {
  description = "Create both private frontend and public subnets"
  type        = "string"
  default     = "true"
}

variable subnet-public {
  description = "Create both private backend and public subnets"
  type        = "string"
  default     = "true"
}