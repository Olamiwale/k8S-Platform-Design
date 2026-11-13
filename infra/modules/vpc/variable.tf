
variable "project_name" {
  type        = string
  description = "Name of the project"
}


variable "environment" {
  type        = string
  description = "Deployment environment"
}


variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}


variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnet deployment"

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required."
  }
}


variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnets are required."
  }
}


variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnets are required."
  }
}
