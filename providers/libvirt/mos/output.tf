output "username" {
  value = var.username
}

output "ip_load_balancer" {
  value = var.create_lb ? zipmap(
    libvirt_domain.lb.*.network_interface.0.hostname,
    libvirt_domain.lb.*.network_interface.0.addresses.0,
  ) : {}
}

output "ip_alpines" {
  value = zipmap(
    libvirt_domain.alpine.*.network_interface.0.hostname,
    libvirt_domain.alpine.*.network_interface.0.addresses.0,
  )
}

output "ip_centoss" {
  value = zipmap(
    libvirt_domain.centos.*.network_interface.0.hostname,
    libvirt_domain.centos.*.network_interface.0.addresses.0,
  )
}

output "ip_coreoss" {
  value = zipmap(
    libvirt_domain.coreos.*.network_interface.0.hostname,
    libvirt_domain.coreos.*.network_interface.0.addresses.0,
  )
}

output "ip_debians" {
  value = zipmap(
    libvirt_domain.debian.*.network_interface.0.hostname,
    libvirt_domain.debian.*.network_interface.0.addresses.0,
  )
}

output "ip_fedoras" {
  value = zipmap(
    libvirt_domain.fedora.*.network_interface.0.hostname,
    libvirt_domain.fedora.*.network_interface.0.addresses.0,
  )
}

output "ip_opensuse_leaps" {
  value = zipmap(
    libvirt_domain.opensuse-leap.*.network_interface.0.hostname,
    libvirt_domain.opensuse-leap.*.network_interface.0.addresses.0,
  )
}

output "ip_opensuse_tumbleweeds" {
  value = zipmap(
    libvirt_domain.opensuse-tumbleweed.*.network_interface.0.hostname,
    libvirt_domain.opensuse-tumbleweed.*.network_interface.0.addresses.0,
  )
}

output "ip_oracle_linuxes" {
  value = zipmap(
    libvirt_domain.oracle-linux.*.network_interface.0.hostname,
    libvirt_domain.oracle-linux.*.network_interface.0.addresses.0,
  )
}

output "ip_rancher_k3oss" {
  value = zipmap(
    libvirt_domain.rancher-k3os.*.network_interface.0.hostname,
    libvirt_domain.rancher-k3os.*.network_interface.0.addresses.0,
  )
}

output "ip_rancher_oss" {
  value = zipmap(
    libvirt_domain.rancher-os.*.network_interface.0.hostname,
    libvirt_domain.rancher-os.*.network_interface.0.addresses.0,
  )
}

output "ip_raspioss" {
  value = zipmap(
    libvirt_domain.raspios.*.network_interface.0.hostname,
    libvirt_domain.raspios.*.network_interface.0.addresses.0,
  )
}

output "ip_sless" {
  value = zipmap(
    libvirt_domain.sles.*.network_interface.0.hostname,
    libvirt_domain.sles.*.network_interface.0.addresses.0,
  )
}

output "ip_ubuntus" {
  value = zipmap(
    libvirt_domain.ubuntu.*.network_interface.0.hostname,
    libvirt_domain.ubuntu.*.network_interface.0.addresses.0,
  )
}
