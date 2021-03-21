# https://www.terraform.io/docs/providers/azurerm/d/image.html
# https://www.terraform.io/docs/providers/azurerm/d/platform_image.html
data "azurerm_platform_image" "centos" {
  location  = "West Europe"
  publisher = "SUSE"
  offer     = "openSUSE-Leap"
  sku       = "42.3"
}


data "template_file" "opensuse_leap_repositories" {
  template = file("${path.module}/cloud-init-opensuse-leap/repository.tpl")
  count    = length(var.repositories)

  vars = {
    repository_url = element(
      values(var.repositories),
      count.index
    )
    repository_name = element(
      keys(var.repositories),
      count.index
    )
  }
}

data "template_file" "opensuse_leap_commands" {
  template = file("${path.module}/cloud-init-opensuse-leap/commands.tpl")
}

data "template_file" "opensuse_leap_cloud-init" {
  template = file("${path.module}/cloud-init-opensuse-leap/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories    = join("\n", data.template_file.opensuse_leap_repositories.*.rendered)
    packages        = join("\n", formatlist("  - %s", var.packages))
    commands        = join("\n", data.template_file.opensuse_leap_commands.*.rendered)
  }
}
