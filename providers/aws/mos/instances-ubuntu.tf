# https://www.terraform.io/docs/providers/aws/r/instance.html
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "template_file" "ubuntu_commands" {
  template = file("${path.module}/cloud-init-ubuntu/commands.tpl")
}

data "template_file" "ubuntu_cloud-init" {
  template = file("${path.module}/cloud-init-ubuntu/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages        = join("\n", formatlist("  - %s", var.packages))
    commands        = join("\n", data.template_file.ubuntu_commands.*.rendered)
  }
}
