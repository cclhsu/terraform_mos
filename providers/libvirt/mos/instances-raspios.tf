# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest release image from their mirrors
resource "libvirt_volume" "raspios_image" {
  count  = var.raspioss == 0 ? 0 : 1
  name   = "${var.stack_name}-${basename(var.raspios_image_uri)}"
  source = var.raspios_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "raspios_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-raspios/commands.tpl")
}

data "template_file" "raspios_cloud-init" {
  count    = var.raspioss
  template = file("${path.module}/cloud-init-raspios/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-raspios-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.raspios_commands.*.rendered)
  }
}

# resource "libvirt_volume" "kernel" {
#   count  = var.raspioss
#   # source = "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-5.4.51-buster"
#   source = "/home/cclhsu/Documents/myImages/kvm/raspios/kernel-qemu-5.4.51-buster"
#   name   = "${var.stack_name}-raspios-kernel-volume-${count.index}"
#   pool   = var.pool
#   format = "raw"
# }

resource "libvirt_volume" "raspios" {
  count          = var.raspioss
  name           = "${var.stack_name}-raspios-volume-${count.index}"
  pool           = var.pool
  size           = var.raspios_disk_size
  base_volume_id = libvirt_volume.raspios_image[0].id
}

resource "libvirt_cloudinit_disk" "raspios" {
  # needed when 0 raspios nodes are defined
  count     = var.raspioss
  name      = "${var.stack_name}-raspios-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.raspios_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "raspios" {
  count  = var.raspioss
  name   = "${var.stack_name}-raspios-domain-${count.index}"
  memory = var.raspios_memory
  vcpu   = var.raspios_vcpu
  # kernel = element(libvirt_volume.kernel.*.id, count.index)
  # emulator = "/usr/bin/qemu-system-aarch64"
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.raspios.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-raspios-${count.index}"
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
      libvirt_volume.raspios.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "raspios_wait_cloudinit" {
#   count      = var.raspioss
#   depends_on = [libvirt_domain.raspios]

#   connection {
#     host = element(
#       libvirt_domain.raspios.*.network_interface.0.addresses.0,
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

resource "null_resource" "raspios_wait_set_hostname" {
  count      = var.raspioss
  depends_on = [libvirt_domain.raspios, ]

  connection {
    host = element(
      libvirt_domain.raspios.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.stack_name}-raspios-${count.index}",
    ]
  }
}

# resource "null_resource" "raspios_reboot" {
#   count      = var.raspioss
#   depends_on = [null_resource.raspios_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.raspios.*.network_interface.0.addresses.0,
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
