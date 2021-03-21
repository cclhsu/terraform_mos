# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu_image" {
  name   = "${var.stack_name}-${basename(var.ubuntu_image_uri)}"
  source = var.ubuntu_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "ubuntu_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-ubuntu/commands.tpl")
}

data "template_file" "ubuntu_cloud-init" {
  count    = var.ubuntus
  template = file("${path.module}/cloud-init-ubuntu/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-ubuntu-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.ubuntu_commands.*.rendered)
  }
}

resource "libvirt_volume" "ubuntu" {
  count          = var.ubuntus
  name           = "${var.stack_name}-ubuntu-volume-${count.index}"
  pool           = var.pool
  size           = var.ubuntu_disk_size
  base_volume_id = libvirt_volume.ubuntu_image.id
}

resource "libvirt_cloudinit_disk" "ubuntu" {
  # needed when 0 ubuntu nodes are defined
  count     = var.ubuntus
  name      = "${var.stack_name}-ubuntu-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.ubuntu_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "ubuntu" {
  count  = var.ubuntus
  name   = "${var.stack_name}-ubuntu-domain-${count.index}"
  memory = var.ubuntu_memory
  vcpu   = var.ubuntu_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.ubuntu.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-ubuntu-${count.index}"
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
      libvirt_volume.ubuntu.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "ubuntu_wait_cloudinit" {
#   count      = var.ubuntus
#   depends_on = [libvirt_domain.ubuntu,]

#   connection {
#     host = element(
#       libvirt_domain.ubuntu.*.network_interface.0.addresses.0,
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

resource "null_resource" "ubuntu_wait_set_hostname" {
  count      = var.ubuntus
  depends_on = [libvirt_domain.ubuntu, ]

  connection {
    host = element(
      libvirt_domain.ubuntu.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.stack_name}-ubuntu-${count.index}",
    ]
  }
}

# resource "null_resource" "ubuntu_reboot" {
#   count      = var.ubuntus
#   depends_on = [null_resource.ubuntu_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.ubuntu.*.network_interface.0.addresses.0,
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
