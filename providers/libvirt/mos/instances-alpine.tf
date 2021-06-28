# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest release image from their mirrors
resource "libvirt_volume" "alpine_image" {
  count  = var.alpines == 0 ? 0 : 1
  name   = "${var.stack_name}-${basename(var.alpine_image_uri)}"
  source = var.alpine_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "alpine_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-alpine/commands.tpl")
}

data "template_file" "alpine_cloud-init" {
  count    = var.alpines
  template = file("${path.module}/cloud-init-alpine/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-alpine-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.alpine_commands.*.rendered)
  }
}

resource "libvirt_volume" "alpine" {
  count          = var.alpines
  name           = "${var.stack_name}-alpine-volume-${count.index}"
  pool           = var.pool
  size           = var.alpine_disk_size
  base_volume_id = libvirt_volume.alpine_image[0].id
}

resource "libvirt_cloudinit_disk" "alpine" {
  # needed when 0 alpine nodes are defined
  count     = var.alpines
  name      = "${var.stack_name}-alpine-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.alpine_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "alpine" {
  count  = var.alpines
  name   = "${var.stack_name}-alpine-domain-${count.index}"
  memory = var.alpine_memory
  vcpu   = var.alpine_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.alpine.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-alpine-${count.index}"
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
      libvirt_volume.alpine.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "alpine_wait_cloudinit" {
#   count      = var.alpines
#   depends_on = [libvirt_domain.alpine]

#   connection {
#     host = element(
#       libvirt_domain.alpine.*.network_interface.0.addresses.0,
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

resource "null_resource" "alpine_wait_set_hostname" {
  count      = var.alpines
  depends_on = [libvirt_domain.alpine, ]

  connection {
    host = element(
      libvirt_domain.alpine.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.stack_name}-alpine-${count.index}",
    ]
  }
}

# resource "null_resource" "alpine_reboot" {
#   count      = var.alpines
#   depends_on = [null_resource.alpine_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.alpine.*.network_interface.0.addresses.0,
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
