# https://www.terraform.io/docs/providers/azurerm/d/image.html
# https://www.terraform.io/docs/providers/azurerm/d/platform_image.html
data "azurerm_platform_image" "ubuntu" {
  location  = "West Europe"
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
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
