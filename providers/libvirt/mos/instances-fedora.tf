# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest fedora release image from their mirrors
resource "libvirt_volume" "fedora_image" {
  name   = "${var.stack_name}-${basename(var.fedora_image_uri)}"
  source = var.fedora_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "fedora_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-fedora/commands.tpl")
}

data "template_file" "fedora_cloud-init" {
  count    = var.fedoras
  template = file("${path.module}/cloud-init-fedora/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-fedora-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.fedora_commands.*.rendered)
  }
}

resource "libvirt_volume" "fedora" {
  count          = var.fedoras
  name           = "${var.stack_name}-fedora-volume-${count.index}"
  pool           = var.pool
  size           = var.fedora_disk_size
  base_volume_id = libvirt_volume.fedora_image.id
}

resource "libvirt_cloudinit_disk" "fedora" {
  # needed when 0 fedora nodes are defined
  count     = var.fedoras
  name      = "${var.stack_name}-fedora-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.fedora_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "fedora" {
  count  = var.fedoras
  name   = "${var.stack_name}-fedora-domain-${count.index}"
  memory = var.fedora_memory
  vcpu   = var.fedora_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.fedora.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-fedora-${count.index}"
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
      libvirt_volume.fedora.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "fedora_wait_cloudinit" {
#   count      = var.fedoras
#   depends_on = [libvirt_domain.fedora,]

#   connection {
#     host = element(
#       libvirt_domain.fedora.*.network_interface.0.addresses.0,
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

resource "null_resource" "fedora_wait_set_hostname" {
  count      = var.fedoras
  depends_on = [libvirt_domain.fedora, ]

  connection {
    host = element(
      libvirt_domain.fedora.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.stack_name}-fedora-${count.index}",
    ]
  }
}

# resource "null_resource" "fedora_reboot" {
#   count      = var.fedoras
#   depends_on = [null_resource.fedora_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.fedora.*.network_interface.0.addresses.0,
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
