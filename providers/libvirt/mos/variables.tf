variable "libvirt_uri" {
  type        = string
  default     = "qemu:///system"
  description = "URL of libvirt connection - default to localhost"
}

variable "libvirt_keyfile" {
  type        = string
  default     = ""
  description = "The private key file used for libvirt connection - default to none"
}

variable "pool" {
  type        = string
  default     = "default"
  description = "Pool to be used to store all the volumes"
}

variable "lb_image_uri" {
  type        = string
  default     = ""
  description = "URL of the lb image to use"
}

variable "alpine_image_uri" {
  type        = string
  default     = ""
  description = "URL of the alpine image to use"
}

variable "centos_image_uri" {
  type        = string
  default     = ""
  description = "URL of the centos image to use"
}

variable "coreos_image_uri" {
  type        = string
  default     = ""
  description = "URL of the coreos image to use"
}
variable "debian_image_uri" {
  type        = string
  default     = ""
  description = "URL of the debian image to use"
}

variable "fedora_image_uri" {
  type        = string
  default     = ""
  description = "URL of the fedora image to use"
}

variable "opensuse_leap_image_uri" {
  default     = ""
  description = "URL of the opensuse-leap image to use"
}

variable "opensuse_tumbleweed_image_uri" {
  default     = ""
  description = "URL of the opensuse-tumbleweed image to use"
}

variable "oracle_linux_image_uri" {
  default     = ""
  description = "URL of the oracle-linux image to use"
}

variable "rancher_k3os_image_uri" {
  type        = string
  default     = ""
  description = "URL of the rancher-k3os image to use"
}

variable "rancher_os_image_uri" {
  type        = string
  default     = ""
  description = "URL of the rancher-os image to use"
}
variable "sles_image_uri" {
  type        = string
  default     = ""
  description = "URL of the sles image to use"
}

variable "raspios_image_uri" {
  type        = string
  default     = ""
  description = "URL of the raspios image to use"
}

variable "ubuntu_image_uri" {
  type        = string
  default     = ""
  description = "URL of the ubuntu image to use"
}

variable "lb_repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "stack_name" {
  type        = string
  default     = ""
  description = "Identifier to make all your resources unique and avoid clashes with other users of this terraform project"
}

variable "authorized_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into all the nodes"
}

variable "ntp_servers" {
  type        = list(string)
  default     = []
  description = "List of NTP servers to configure"
}

variable "dns_nameservers" {
  type        = list(string)
  default     = []
  description = "List of Name servers to configure"
}

variable "packages" {
  type = list(string)

  default = [
    "openssl",
    "python3",
    "curl",
    "rsync",
    "jq",
  ]

  description = "List of packages to install"
}

variable "username" {
  type        = string
  default     = "mos"
  description = "Username for the cluster nodes"
}

variable "password" {
  type        = string
  default     = "linux"
  description = "Password for the cluster nodes"
}

variable "dns_domain" {
  type        = string
  default     = "mos.local"
  description = "Name of DNS Domain"
}

variable "network_cidr" {
  type        = string
  default     = "10.17.0.0/22"
  description = "Network used by the cluster"
}

variable "network_mode" {
  type        = string
  default     = "nat"
  description = "Network mode used by the cluster"
}

variable "network_name" {
  type        = string
  default     = ""
  description = "The virtual network name to use. If provided just use the given one (not managed by terraform), otherwise terraform creates a new virtual network resource"
}

variable "create_lb" {
  type        = bool
  default     = true
  description = "Create load balancer node exposing master nodes"
}

variable "create_http_server" {
  type        = bool
  default     = true
  description = "Create http server in load balancer node"
}

variable "lb_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a load balancer node"
}

variable "lb_vcpu" {
  type        = number
  default     = 1
  description = "Amount of virtual CPUs for a load balancer node"
}

variable "lb_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "alpines" {
  type        = number
  default     = 1
  description = "Number of alpine nodes"
}

variable "alpine_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a alpine"
}

variable "alpine_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a alpine"
}

variable "alpine_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "centoss" {
  type        = number
  default     = 1
  description = "Number of centos nodes"
}

variable "centos_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a centos"
}

variable "centos_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a centos"
}

variable "centos_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "coreoss" {
  type        = number
  default     = 1
  description = "Number of coreos nodes"
}

variable "coreos_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a coreos"
}

variable "coreos_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a coreos"
}

variable "coreos_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "debians" {
  type        = number
  default     = 1
  description = "Number of debian nodes"
}

variable "debian_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a debian"
}

variable "debian_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a debian"
}

variable "debian_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "fedoras" {
  type        = number
  default     = 1
  description = "Number of fedora nodes"
}

variable "fedora_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a fedora"
}

variable "fedora_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a fedora"
}

variable "fedora_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "opensuse_leaps" {
  type        = number
  default     = 1
  description = "Number of opensuse-leap nodes"
}

variable "opensuse_leap_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a opensuse"
}

variable "opensuse_leap_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a opensuse"
}

variable "opensuse_leap_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "opensuse_tumbleweeds" {
  type        = number
  default     = 1
  description = "Number of opensuse-tumbleweed nodes"
}

variable "opensuse_tumbleweed_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a opensuse"
}

variable "opensuse_tumbleweed_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a opensuse"
}

variable "opensuse_tumbleweed_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "oracle_linuxes" {
  type        = number
  default     = 1
  description = "Number of oracle-linux nodes"
}

variable "oracle_linux_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a opensuse"
}

variable "oracle_linux_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a opensuse"
}

variable "oracle_linux_disk_size" {
  type        = number
  default     = 39728447488
  description = "Disk size (in bytes)"
}
variable "rancher_k3oss" {
  type        = number
  default     = 1
  description = "Number of rancher-k3os nodes"
}

variable "rancher_k3os_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a rancher-k3os"
}

variable "rancher_k3os_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a rancher-k3os"
}

variable "rancher_k3os_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "rancher_oss" {
  type        = number
  default     = 1
  description = "Number of rancheros nodes"
}

variable "rancher_os_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a rancheros"
}

variable "rancher_os_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a rancheros"
}

variable "rancher_os_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "raspioss" {
  type        = number
  default     = 1
  description = "Number of raspios nodes"
}

variable "raspios_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a raspios"
}

variable "raspios_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a raspios"
}

variable "raspios_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "sless" {
  type        = number
  default     = 1
  description = "Number of sles nodes"
}

variable "sles_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a sles"
}

variable "sles_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a sles"
}

variable "sles_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "caasp_registry_code" {
  type        = string
  default     = ""
  description = "SUSE CaaSP Product Registration Code"
}

variable "ha_registry_code" {
  type        = string
  default     = ""
  description = "SUSE Linux Enterprise High Availability Extension Registration Code"
}

variable "rmt_server_name" {
  type        = string
  default     = ""
  description = "SUSE Repository Mirroring Server Name"
}

variable "ubuntus" {
  type        = number
  default     = 1
  description = "Number of ubuntu nodes"
}

variable "ubuntu_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a ubuntu"
}

variable "ubuntu_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a ubuntu"
}

variable "ubuntu_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "hostname_from_dhcp" {
  type        = bool
  default     = true
  description = "Set node's hostname from DHCP server"
}

variable "cpi_enable" {
  type        = bool
  default     = false
  description = "Enable CPI integration with Azure"
}
