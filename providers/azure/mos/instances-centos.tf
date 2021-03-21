# https://www.terraform.io/docs/providers/azurerm/d/image.html
# https://www.terraform.io/docs/providers/azurerm/d/platform_image.html
data "azurerm_platform_image" "centos" {
  location  = "West Europe"
  publisher = "OpenLogic"
  offer     = "Centos"
  sku       = "7.5"
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
