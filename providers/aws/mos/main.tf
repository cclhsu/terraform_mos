locals {
  basic_tags = merge(
    {
      "Name"        = var.stack_name
      "Environment" = var.stack_name
    },
    var.tags,
  )

  tags = local.basic_tags
  # tags = merge(
  #   local.basic_tags,
  #   {
  #     format("kubernetes.io/cluster/%v", var.stack_name) = "SUSE-terraform"
  #   },
  # )
}

# https://www.terraform.io/docs/providers/aws/index.html
provider "aws" {
  profile = "default"
}

data "aws_region" "current" {}

resource "aws_key_pair" "kube" {
  key_name   = "${var.stack_name}-keypair"
  public_key = element(var.authorized_keys, 0)
}

# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "dedicated"

  tags = {
    Name = "main"
  }
}
