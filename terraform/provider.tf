provider "proxmox" {
  endpoint = "https://192.168.0.50:8006/"
  insecure = true # Proxmox uses a self-signed cert

  ssh {
    agent    = true
    username = "root"
  }
}