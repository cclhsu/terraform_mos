# instance the provider
provider "libvirt" {
  uri = var.libvirt_keyfile == "" ? var.libvirt_uri : "${var.libvirt_uri}?keyfile=${var.libvirt_keyfile}"
}
