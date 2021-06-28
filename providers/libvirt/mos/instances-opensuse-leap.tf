# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest release image from their mirrors
resource "libvirt_volume" "opensuse_leap_image" {
  count  = var.opensuse_leaps == 0 ? 0 : 1
  name   = "${var.stack_name}-${basename(var.opensuse_leap_image_uri)}"
  source = var.opensuse_leap_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "opensuse_leap_repositories" {
  count    = length(var.repositories)
  template = file("${path.module}/cloud-init-opensuse-leap/repository.tpl")

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
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-opensuse-leap/commands.tpl")

  vars = {
    packages = join(" ", var.packages)
  }
}

data "template_file" "opensuse_leap_cloud-init" {
  count    = var.opensuse_leaps
  template = file("${path.module}/cloud-init-opensuse-leap/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-opensuse-leap-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories       = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.opensuse_leap_repositories.*.rendered)
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.opensuse_leap_commands.*.rendered)
  }
}

resource "libvirt_volume" "opensuse-leap" {
  count          = var.opensuse_leaps
  name           = "${var.stack_name}-opensuse-leap-volume-${count.index}"
  pool           = var.pool
  size           = var.opensuse_leap_disk_size
  base_volume_id = libvirt_volume.opensuse_leap_image[0].id
}

resource "libvirt_cloudinit_disk" "opensuse-leap" {
  # needed when 0 opensuse-leap nodes are defined
  count     = var.opensuse_leaps
  name      = "${var.stack_name}-opensuse-leap-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.opensuse_leap_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "opensuse-leap" {
  count  = var.opensuse_leaps
  name   = "${var.stack_name}-opensuse-leap-domain-${count.index}"
  memory = var.opensuse_leap_memory
  vcpu   = var.opensuse_leap_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.opensuse-leap.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-opensuse-leap-${count.index}"
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
      libvirt_volume.opensuse-leap.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "opensuse_leap_wait_cloudinit" {
#   count      = var.opensuse_leaps
#   depends_on = [libvirt_domain.opensuse-leap,]

#   connection {
#     host = element(
#       libvirt_domain.opensuse-leap.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo cloud-init status --wait > /dev/null",
#     ]
#   }
# }

# resource "null_resource" "opensuse_leap_wait_set_hostname" {
#   depends_on = [libvirt_domain.opensuse-leap,]

#   connection {
#     host = element(
#       libvirt_domain.opensuse-leap.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname ${var.stack_name}-opensuse-leap-${count.index}",
#     ]
#   }
# }

# resource "null_resource" "opensuse_leap_reboot" {
#   count      = var.opensuse_leaps
#   depends_on = [null_resource.opensuse_leap_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.opensuse-leap.*.network_interface.0.addresses.0,
#         count.index
#       )
#     }

#     command = <<EOT
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# # wait for ssh ready after reboot
# until nc -zv $host 22; do sleep 5; done
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60 $user@$host /usr/bin/true
# EOT

#   }
# }
