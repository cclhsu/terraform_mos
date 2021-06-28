# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest release image from their mirrors
resource "libvirt_volume" "rancher_os_image" {
  count  = var.rancher_oss == 0 ? 0 : 1
  name   = "${var.stack_name}-${basename(var.rancher_os_image_uri)}"
  source = var.rancher_os_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "rancher_os_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init-rancher-os/commands.tpl")
}

data "template_file" "rancher_os_cloud-init" {
  count    = var.rancher_oss
  template = file("${path.module}/cloud-init-rancher-os/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = "rancher"
    password           = var.password
    hostname           = "${var.stack_name}-rancher-os-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.rancher_os_commands.*.rendered)
  }
}

resource "libvirt_volume" "rancher-os" {
  count          = var.rancher_oss
  name           = "${var.stack_name}-rancher-os-volume-${count.index}"
  pool           = var.pool
  size           = var.rancher_os_disk_size
  base_volume_id = libvirt_volume.rancher_os_image[0].id
}

resource "libvirt_cloudinit_disk" "rancher-os" {
  # needed when 0 rancher-os nodes are defined
  count = var.rancher_oss
  name  = "${var.stack_name}-rancher-os-cloudinit-disk-${count.index}"
  pool  = var.pool
  # user_data = data.template_file.rancher_os_cloud-init[count.index].rendered

  user_data = <<CLOUDINIT
#cloud-config
ssh_authorized_keys:
- ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVlEA1t6QnGR5+8TDZDKKQ1F4ExBCHCYuIWlZ+IQAqod+t9CSrkPlLYAlrYTxTKbxsPCqU77CyEz9T3LB711q5rx3pfUoccBz+zQMv5SVPPZGkFN7FcDU/71j7EulbpBOTYHornZHObovfObTPa1ixDl9rR/txI8Jtv7viHh8qX/YY9woNsdhsH09/owjdiAGobBhplYdSIToZlGYN/aEQGPGXDeaejURyaxVOuZWovvRNkkfx5MRAzxJXnv3v3XQhjMXMLJmSr0RUrgw+M/fK5XMxJ+0U1KhrT7OtCbdrWJXR7O7CLwmYekBvq8YfnQqtOWDairfkjDjnsPIzmtlVS2bYlFyO4Yz1GQZlF7yGLG9YDvdNo77oAzMdMSIBzYyTKUlJFO51vTza36GbDhv21C9/H8birZ0FaltsRysWnQwCBBaqF0EnUgIRlStD8lAdkG1ChWbpCWtfgS7iGzYICSS7yeH7Y4u2exm8HghHRXR4ISyF47c8QBG7hpZND34qoqBpuy0oxu1vOLKenyPyHCeENwT/Dpj8wbvsOu3xpEfZPzx/qXMNVSX5zUTfsSyaQ4UZHTNZpnMkDEo5kIBi2KkD18e5xVJwIs4CiPajvXEmItj/7/pUA5W6npFb4uU1bz0ZZ14YlSGPblEDYXmQCMSHDS+y6bItvna9TjWaFQ== clark.hsu@suse.com
- "github:cclhsu"
rancher:
  network:
    dns:
      search:
        - mos.local
      nameservers:
        - 10.17.0.1
CLOUDINIT
}

# Create the machine
resource "libvirt_domain" "rancher-os" {
  count  = var.rancher_oss
  name   = "${var.stack_name}-rancher-os-domain-${count.index}"
  memory = var.rancher_os_memory
  vcpu   = var.rancher_os_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.rancher-os.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-rancher-os-${count.index}"
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
      libvirt_volume.rancher-os.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "rancher_os_wait_cloudinit" {
#   count      = var.rancher_oss
#   depends_on = [libvirt_domain.rancher-os,]

#   connection {
#     host = element(
#       libvirt_domain.rancher-os.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = "rancher"
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo cloud-init status --wait > /dev/null",
#     ]
#   }
# }

# resource "null_resource" "rancher_os_wait_set_hostname" {
#   depends_on = [libvirt_domain.rancher-os,]

#   connection {
#     host = element(
#       libvirt_domain.rancher-os.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = "rancher"
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname ${var.stack_name}-rancher-os-${count.index}",
#     ]
#   }
# }

# resource "null_resource" "rancher_os_reboot" {
#   count      = var.rancher_oss
#   depends_on = [null_resource.rancher_os_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = "rancher"
#       host = element(
#         libvirt_domain.rancher-os.*.network_interface.0.addresses.0,
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
