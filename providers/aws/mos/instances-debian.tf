# https://www.terraform.io/docs/providers/aws/r/instance.html
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["379101102735"]

  filter {
    name   = "name"
    values = ["debian-jessie-*"]
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

# We fetch the latest centos release image from their mirrors
resource "libvirt_volume" "debian_image" {
  name   = "${var.stack_name}-${basename(var.debian_image_uri)}"
  source = var.debian_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "debian_commands" {
  template = file("${path.module}/cloud-init-debian/commands.tpl")
}

data "template_file" "debian_cloud-init" {
  template = file("${path.module}/cloud-init-debian/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages        = join("\n", formatlist("  - %s", var.packages))
    commands        = join("\n", data.template_file.debian_commands.*.rendered)
  }
}
