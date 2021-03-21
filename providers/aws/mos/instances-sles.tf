data "susepubliccloud_image_ids" "sles15sp2_chost_byos" {
  cloud  = "amazon"
  region = data.aws_region.current.name
  state  = "active"

  # USE SLES 15 SP2 Container host AMI - this is needed to avoid issues like bsc#1146774
  name_regex = "suse-sles-15-sp2-chost-byos.*-hvm-ssd-x86_64"
}

data "aws_region" "current" {}

data "template_file" "sles_repositories" {
  template = file("${path.module}/cloud-init-sles/repository.tpl")
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

data "template_file" "sles_register_scc" {
  template = file("${path.module}/cloud-init-sles/register-scc.tpl")
  count    = var.caasp_registry_code == "" ? 0 : 1

  vars = {
    caasp_registry_code = var.caasp_registry_code
    rmt_server_name     = var.rmt_server_name
  }
}

data "template_file" "sles_register_rmt" {
  template = file("${path.module}/cloud-init-sles/register-rmt.tpl")
  count    = var.rmt_server_name == "" ? 0 : 1

  vars = {
    rmt_server_name = var.rmt_server_name
  }
}

data "template_file" "sles_commands" {
  template = file("${path.module}/cloud-init-sles/commands.tpl")
  count    = join("", var.packages) == "" ? 0 : 1

  vars = {
    packages = join(" ", var.packages)
  }
}

data "template_file" "sles_cloud-init" {
  template = file("${path.module}/cloud-init-sles/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    register_scc    = join("\n", data.template_file.sles_register_scc.*.rendered)
    register_rmt    = join("\n", data.template_file.sles_register_rmt.*.rendered)
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories    = join("\n", data.template_file.sles_repositories.*.rendered)
    # packages        = join("\n", formatlist("  - %s", var.packages))
    commands = join("\n", data.template_file.sles_commands.*.rendered)
  }
}
