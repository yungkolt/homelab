variable "nodes" {
  description = "Kubernetes nodes to create"
  type = map(object({
    vmid   = number
    cores  = number
    memory = number # MB
    disk   = number # GB
    ip     = string # CIDR, e.g. 192.168.0.100/24
  }))
}

variable "gateway" {
  type    = string
  default = "192.168.0.1"
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}