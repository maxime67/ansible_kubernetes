# kubernetes-on-proxmox

Déploiement d'un cluster Kubernetes sur Proxmox via Terraform et Ansible.

## Stack

| Couche | Composant | Version |
|--------|-----------|---------|
| Hyperviseur | Proxmox VE | 9.1 |
| OS VMs | Debian | 13 (Trixie) |
| Provisioning infra | Terraform | >= 1.6 |
| Provider Proxmox | bpg/proxmox | ~> 0.66 |
| Configuration | Ansible | >= 2.14 |
| Orchestration | k3s | latest stable |

## Topologie

```
1x control-plane   k8s-cp-01       2 CPU  2 GB RAM  20 GB
2x worker          k8s-worker-01   1 CPU  1 GB RAM  20 GB
                   k8s-worker-02   1 CPU  1 GB RAM  20 GB
```

Réseau pods : `10.42.0.0/16` (défaut k3s)

## Prérequis

Sur Proxmox (une seule fois, depuis le shell web) :

```bash
# Activer le content type images sur le storage local
pvesm set local --content backup,iso,vztmpl,images

# Télécharger l'image Debian 13 et créer le template VM (id 9000)
curl -L -o /var/lib/vz/template/iso/debian-13.qcow2 https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
qm create 9000 --name debian-13-template --memory 1024 --cores 1 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm importdisk 9000 /var/lib/vz/template/iso/debian-13.qcow2 local
qm set 9000 --scsi0 local:9000/vm-9000-disk-0.qcow2,discard=on --ide2 local:cloudinit --boot order=scsi0 --serial0 socket --vga serial0
qm template 9000

```

Clé SSH disponible localement (`~/.ssh/id_ed25519`).

## Utilisation

### 1. Terraform — créer les VMs

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# remplir terraform.tfvars
terraform init
terraform apply
```

### 2. Renseigner l'inventaire Ansible

Récupérer les IPs des VMs depuis l'interface Proxmox et mettre à jour `ansible/inventory.yml`.

### 3. Ansible — déployer Kubernetes

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

### 4. Ansible — déployer ArgoCD et les addons

```bash
ansible-playbook addons.yml
```

ArgoCD se synchronise ensuite automatiquement depuis `gitops/apps/` et déploie Vault, Prometheus, etc.

## Structure

```
.
├── terraform/
│   ├── main.tf            # VMs Proxmox
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
└── ansible/
    ├── site.yml
    ├── inventory.yml
    ├── group_vars/all.yml
    ├── roles/
    │   ├── common/        # swap, modules kernel, sysctl
    │   ├── k3s_server/    # installation k3s control-plane
    │   ├── k3s_agent/     # installation k3s workers
    │   └── argocd/        # installation ArgoCD + App of Apps
    └── requirements.yml   # collections Ansible
└── gitops/
    └── apps/              # Applications ArgoCD (Vault, Prometheus...)
```
