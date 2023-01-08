#!/bin/bash

_step_counter=0
function step() {
        _step_counter=$(( _step_counter + 1 ))
        printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step "Getting all the infos needed..."
echo "  - Get latest Talos version"
TALOS_VERSION=$(curl --silent -qI https://github.com/siderolabs/talos/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')

echo "  - Get latest Kubernetes version"
KUBERNETES_VERSION=$(curl --silent -qI https://github.com/siderolabs/kubelet/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/v//g')

echo "  - Get cluster members count"
MEMBERS=$(talosctl get members | grep Member | wc -l)

step "Backup ETCD db"
talosctl etcd snapshot talos-etcd-$(date +%Y%m%d-%H%M%S).snapshot

step "Clean up old ETCD db backups"
ls -t talos-etcd-* | tail -n +4 | xargs rm --

step "Upgrade Talos OS for all nodes"
for NODE in $(grep -A${MEMBERS} endpoints ~/.talos/config | tail -${MEMBERS} | awk '{ print $2 }')
do
    talosctl upgrade -n ${NODE} --image ghcr.io/siderolabs/installer:$TALOS_VERSION
done

step "Upgrade talosctl"
sudo curl --silent -qLo /usr/local/bin/talosctl https://github.com/siderolabs/talos/releases/download/$TALOS_VERSION/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-arm64
sudo chmod +x /usr/local/bin/talosctl

step "Upgrade kubectl"
sudo curl --silent -qLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x /usr/local/bin/kubectl

step "Upgrade k9s"
K9S_VERSION=$(curl --silent -qI https://github.com/derailed/k9s/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')
curl --silent -qLo /tmp/k9s_Linux_arm64.tar.gz https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_arm64.tar.gz
sudo tar -xzf /tmp/k9s_Linux_arm64.tar.gz -C /usr/local/bin/ k9s
sudo chmod +x /usr/local/bin/k9s
sudo rm /tmp/k9s_Linux_arm64.tar.gz

step "Upgrade Kubernetes version"
talosctl upgrade-k8s --to ${KUBERNETES_VERSION}
