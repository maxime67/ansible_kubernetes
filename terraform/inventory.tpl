all:
  vars:
    ansible_user: debian
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
  children:
    control_plane:
      hosts:
        k8s-cp-01:
          ansible_host: ${control_plane_ip}
    workers:
      hosts:
%{ for i, ip in worker_ips ~}
        k8s-worker-0${i + 1}:
          ansible_host: ${ip}
%{ endfor ~}
