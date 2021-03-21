# https://www.terraform.io/docs/providers/aws/r/instance.html
data "aws_ami" "centos" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

data "template_file" "centos_commands" {
  template = file("${path.module}/cloud-init-centos/commands.tpl")
}

data "template_file" "centos_cloud-init" {
  template = file("${path.module}/cloud-init-centos/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages        = join("\n", formatlist("  - %s", var.packages))
    commands        = join("\n", data.template_file.centos_commands.*.rendered)
  }
}
