# kubernetes-on-proxmox

Cluster Kubernetes homelab déployé sur Proxmox via Terraform et Ansible. Aucune exposition internet — certificats TLS signés par une CA privée locale.

## Stack

| Couche | Outil | Rôle |
|--------|-------|------|
| Hyperviseur | Proxmox VE | Hébergement des VMs |
| OS VMs | Debian 13 (Trixie) | Image cloud + qemu-guest-agent |
| Infra | Terraform + bpg/proxmox | Création des VMs |
| Configuration | Ansible | Installation et configuration du cluster |
| Kubernetes | kubeadm 1.35 | Bootstrap du cluster |
| CNI | Cilium + Hubble | Réseau pods + observabilité |
| Ingress | Traefik | Reverse proxy (DaemonSet, hostPort 80/443) |
| LoadBalancer | MetalLB | IP flottante pour Traefik (L2) |
| Stockage | Longhorn | CSI — volumes persistants distribués |
| TLS | cert-manager + CA privée | Certificats valides sur le réseau local |
| GitOps | ArgoCD | Synchronisation des apps depuis ce repo |
| Monitoring | Prometheus + Grafana | Métriques cluster |

## Topologie

```
Nœud Proxmox   VM              Rôle            CPU   RAM     Disque
pve1           k8s-cp-01       control-plane    3     7 GB    20 GB
pve2           k8s-worker-01   worker           2     6 GB    20 GB
pve3           k8s-worker-02   worker           2     6 GB    20 GB
```

- Réseau pods : `10.244.0.0/16` (Cilium)
- IP LoadBalancer Traefik : `192.168.1.200` (MetalLB, configurable dans `ansible/group_vars/all.yml`)
- Domaine local : `homelab.local` (configurable dans `ansible/group_vars/all.yml`)

---

## Prérequis

### 1. Clé SSH

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

### 2. Token API Proxmox

Depuis l'interface Proxmox : **Datacenter → Permissions → API Tokens → Add**

```
User : root@pam  |  Token : terraform  |  Privilege Separation : décoché
```

```bash
export TF_VAR_proxmox_credentials='root@pam!terraform=<uuid>'
```

### 3. Template Proxmox (une seule fois, sur le shell de pve1)

```bash
apt install -y libguestfs-tools
wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2

virt-customize -a debian-13-genericcloud-amd64.qcow2 \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent'

qm create 9004 --name debian-13-template --memory 1024 --net0 virtio,bridge=vmbr0 --ostype l26
qm importdisk 9004 debian-13-genericcloud-amd64.qcow2 local-lvm
qm set 9004 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9004-disk-0,discard=on
qm set 9004 --ide2 local-lvm:cloudinit
qm set 9004 --boot order=scsi0
qm set 9004 --serial0 socket --vga serial0
qm set 9004 --agent enabled=1
qm template 9004
```

### 4. Outils locaux

- Terraform >= 1.14
- Ansible >= 2.20

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

---

## Déploiement

### 1. Terraform — Création des VMs

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Remplir proxmox_endpoint, proxmox_credentials, ssh_public_key
terraform init && terraform apply
```

Terraform crée les 3 VMs (1 par nœud Proxmox) et génère `ansible/inventory.yml`.

### 2. Ansible — Cluster complet

```bash
cd ansible
ansible-playbook site.yml
```

Le playbook installe dans l'ordre :

| Phase | Rôles |
|-------|-------|
| Nœuds | swap, kernel, storage, containerd, kubernetes_packages |
| Control plane | k8s_control_plane, helm, cilium |
| Workers | k8s_worker |
| Addons | metrics_server, longhorn, metallb, cert_manager, traefik, argocd, monitoring |

En fin de playbook, les URLs et mots de passe d'accès sont affichés.

### 3. Certificat CA — import Windows (une seule fois)

Le playbook génère `ca.crt` à la racine du projet. L'importer dans Windows pour que les certificats `*.homelab.local` soient reconnus comme valides :

```powershell
# PowerShell en Admin
Import-Certificate -FilePath "ca.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### 4. DNS local

Ajouter dans `C:\Windows\System32\drivers\etc\hosts` (en Admin) :

```
192.168.1.200  argocd.homelab.local grafana.homelab.local hubble.homelab.local traefik.homelab.local
```

> Remplacer `192.168.1.200` par la première IP du range MetalLB si modifié.

---

## Accès

| Service | URL |
|---------|-----|
| ArgoCD | https://argocd.homelab.local |
| Grafana | https://grafana.homelab.local |
| Hubble | https://hubble.homelab.local |
| Traefik | https://traefik.homelab.local/dashboard/ |

Les identifiants sont affichés à la fin du playbook Ansible.

---

## Structure du repo

```
├── terraform/          # Création des VMs Proxmox
├── ansible/
│   ├── site.yml        # Point d'entrée unique
│   ├── inventory.yml   # Généré par Terraform
│   ├── group_vars/     # Variables globales (domaine, IP range, versions)
│   └── roles/          # Un rôle par composant
└── gitops/
    ├── apps/           # Applications ArgoCD (app-of-apps)
    └── cert-manager/   # Values Helm
```

## Reset

```bash
cd terraform && terraform destroy
# Supprimer le template depuis pve1 si nécessaire :
qm destroy 9004 --purge
```
