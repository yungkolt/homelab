# Homelab

A Kubernetes platform on a single Proxmox mini PC, built as code from the VMs up. Terraform creates the cluster's virtual machines today; kubeadm, Ansible, GitOps and monitoring are the next phases.

**Status: in progress.** Phase 1 (VM provisioning) is in this repo. Everything under [Roadmap](#roadmap) is planned, not built.

## Hardware

| Part | Spec |
| --- | --- |
| Host | Mini PC, Intel N100, 16 GB RAM |
| Hypervisor | Proxmox VE 9 |
| Network | Flat home LAN, static IPs outside the router's DHCP range |

## What Terraform builds

Three Kubernetes nodes, cloned from a cloud-init VM template:

| Node | Role | vCPU | RAM | Disk | IP |
| --- | --- | --- | --- | --- | --- |
| `k8s-cp-01` | control plane | 2 | 3 GB | 20 GB | 192.168.0.100 |
| `k8s-wk-01` | worker | 2 | 5 GB | 30 GB | 192.168.0.101 |
| `k8s-wk-02` | worker | 2 | 5 GB | 30 GB | 192.168.0.102 |

Together they use 13 of the host's 16 GB, leaving room for Proxmox itself.

For each node, Terraform:

- renders a cloud-init file from `cloud-init/user-data.yaml.tftpl` and uploads it to Proxmox as a snippet
- full-clones the template, then sets CPU, memory, disk, a static IP and DNS
- creates one user, `kolton`, that logs in with an SSH key only (password login locked)
- installs and starts the QEMU guest agent, so Proxmox can report the VM's IP and shut it down cleanly

Nodes are defined once as a map in `terraform.tfvars`, and every resource uses `for_each` over it. Adding a node is one line.

## Layout

```
terraform/
  versions.tf                    Terraform and bpg/proxmox provider versions
  provider.tf                    Proxmox API endpoint and SSH settings
  variables.tf                   node map, gateway, template ID, SSH key path
  main.tf                        cloud-init snippets and the VMs
  cloud-init/
    user-data.yaml.tftpl         per-node cloud-init template
  terraform.tfvars.example       node definitions to copy
```

## Running it

Prerequisites:

- Proxmox VE with snippets enabled on the `local` datastore
- a cloud-init-ready VM template (ID `9000` by default; set `template_id` to change it)
- an SSH key at `~/.ssh/id_ed25519.pub` (or set `ssh_public_key_path`)
- a Proxmox API token, exported for the provider:

```bash
export PROXMOX_VE_API_TOKEN='terraform@pve!homelab=<secret>'
```

Then:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # adjust IPs for your network
terraform init
terraform plan
terraform apply
```

`terraform destroy` removes the VMs and snippets. State and `terraform.tfvars` stay local and are git-ignored.

## Decisions

- **bpg/proxmox provider.** It is actively maintained and supports cloud-init snippets, full clones and the guest agent in one resource.
- **Cloud-init over a golden image.** The template stays generic; hostnames, users and keys are applied per node at first boot.
- **kubeadm over k3s.** k3s is quicker to stand up, but kubeadm shows each piece of a standard cluster (certificates, the control plane components, CNI), which is the point of building it.
- **Known shortcuts for a lab:** the provider skips TLS verification because Proxmox uses a self-signed certificate, and the provider's SSH connection uses the host's root account for snippet uploads. Both would change outside a homelab.

## Roadmap

- [x] Provision node VMs with Terraform and cloud-init
- [ ] Configure nodes with Ansible (container runtime, kernel modules, sysctl, packages)
- [ ] Bootstrap the cluster with kubeadm and a CNI
- [ ] GitOps with Flux: this repo becomes the cluster's source of truth
- [ ] Monitoring with Prometheus and Grafana
- [ ] Remote access with Tailscale
- [ ] Connect to Azure with Azure Arc, managed from the same GitOps repo as an AKS cluster
