# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest centos release image from their mirrors
resource "libvirt_volume" "sles_image" {
  name   = "${var.stack_name}-${basename(var.sles_image_uri)}"
  source = var.sles_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "sles_repositories" {
  count    = length(var.repositories)
  template = file("${path.module}/cloud-init-sles/repository.tpl")

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
  count    = var.caasp_registry_code == "" ? 0 : 1
  template = file("${path.module}/cloud-init-sles/register-scc.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code

    # no need to enable the SLE HA product on this kind of nodes
    ha_registry_code = ""
  }
}

data "template_file" "sles_register_rmt" {
  count    = var.rmt_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init-sles/register-rmt.tpl")

  vars = {
    rmt_server_name = var.rmt_server_name
  }
}

data "template_file" "sles_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-sles/commands.tpl")

  vars = {
    packages = join(" ", var.packages)
  }
}

data "template_file" "sles_cloud-init" {
  count    = var.sless
  template = file("${path.module}/cloud-init-sles/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-sles-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories       = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.sles_repositories.*.rendered)
    register_scc       = var.caasp_registry_code != "" && var.rmt_server_name == "" ? join("\n", data.template_file.sles_register_scc.*.rendered) : ""
    register_rmt       = var.rmt_server_name == "" ? join("\n", data.template_file.sles_register_rmt.*.rendered) : ""
    commands           = join("\n", data.template_file.sles_commands.*.rendered)
    # packages           = join("\n", formatlist("  - %s", var.packages))
  }
}

resource "libvirt_volume" "sles" {
  count          = var.sless
  name           = "${var.stack_name}-sles-volume-${count.index}"
  pool           = var.pool
  size           = var.sles_disk_size
  base_volume_id = libvirt_volume.sles_image.id
}

# for more info about parameter check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/sles/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "sles" {
  # needed when 0 sles nodes are defined
  count     = var.sless
  name      = "${var.stack_name}-sles-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.sles_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "sles" {
  count  = var.sless
  name   = "${var.stack_name}-sles-domain-${count.index}"
  memory = var.sles_memory
  vcpu   = var.sles_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.sles.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-sles-${count.index}"
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(
      libvirt_volume.sles.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

resource "null_resource" "sles_wait_cloudinit" {
  depends_on = [libvirt_domain.sles, ]
  count      = var.sless

  connection {
    host = element(
      libvirt_domain.sles.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "sles_reboot" {
  depends_on = [null_resource.sles_wait_cloudinit, ]
  count      = var.sless

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.sles.*.network_interface.0.addresses.0,
        count.index
      )
    }

    command = <<EOT
export sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60"
if ! ssh $sshopts $user@$host 'sudo needs-restarting -r'; then
    ssh $sshopts $user@$host sudo reboot || :
    export delay=5
    # wait for node reboot completed
    while ! ssh $sshopts $user@$host 'sudo needs-restarting -r'; do
        sleep $delay
        delay=$((delay+1))
        [ $delay -gt 30 ] && exit 1
    done
fi
EOT

  }
}
