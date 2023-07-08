#!/bin/bash
# Openstack lab network configuration

create_net() {
    if [ -z $(which virsh) ]; then
        echo "virsh not found. Please install libvirt first."
        exit 1
    fi
    cat <<EOF >${DATAPATH}/network/ens3.xml
    <network>
        <name>net-${CIDR}.${INTERFACE3}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE3}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE3}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens4.xml
    <network>
        <name>net-${CIDR}.${INTERFACE4}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE4}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE4}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens5.xml
    <network>
        <name>net-${CIDR}.${INTERFACE5}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE5}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE5}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens6.xml
    <network>
        <name>net-${CIDR}.${INTERFACE6}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE6}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE6}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens7.xml
    <network>
        <name>net-${CIDR}.${INTERFACE7}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE7}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE7}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens8.xml
    <network>
        <name>net-${CIDR}.${INTERFACE8}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE8}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE8}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    cat <<EOF >${DATAPATH}/network/ens9.xml
    <network>
        <name>net-${CIDR}.${INTERFACE9}</name>
        <forward mode='route'/>
        <bridge name='bridge-${BRIDGE}${INTERFACE9}' stp='on' delay='0'/>
        <domain name='network'/>
        <ip address='${CIDR}.${INTERFACE9}.1' netmask='255.255.255.0'>
        </ip>
    </network>
EOF
    for i in {3..9}; do
        virsh net-define ${DATAPATH}/network/ens${i}.xml
    done
}

delete_net() {
    virsh net-destroy net-${CIDR}.${INTERFACE3}
    virsh net-destroy net-${CIDR}.${INTERFACE4}
    virsh net-destroy net-${CIDR}.${INTERFACE5}
    virsh net-destroy net-${CIDR}.${INTERFACE6}
    virsh net-destroy net-${CIDR}.${INTERFACE7}
    virsh net-destroy net-${CIDR}.${INTERFACE8}
    virsh net-destroy net-${CIDR}.${INTERFACE9}
    virsh net-undefine net-${CIDR}.${INTERFACE3}
    virsh net-undefine net-${CIDR}.${INTERFACE4}
    virsh net-undefine net-${CIDR}.${INTERFACE5}
    virsh net-undefine net-${CIDR}.${INTERFACE6}
    virsh net-undefine net-${CIDR}.${INTERFACE7}
    virsh net-undefine net-${CIDR}.${INTERFACE8}
    virsh net-undefine net-${CIDR}.${INTERFACE9}
    sudo iptables -t nat -D POSTROUTING -s ${CIDR}.${INTERFACE3}.0/24 -j MASQUERADE
    rm ${DATAPATH}/network/*.xml
}

start_net() {
    virsh net-start net-${CIDR}.${INTERFACE3}
    virsh net-start net-${CIDR}.${INTERFACE4}
    virsh net-start net-${CIDR}.${INTERFACE5}
    virsh net-start net-${CIDR}.${INTERFACE6}
    virsh net-start net-${CIDR}.${INTERFACE7}
    virsh net-start net-${CIDR}.${INTERFACE8}
    virsh net-start net-${CIDR}.${INTERFACE9}
    virsh net-autostart net-${CIDR}.${INTERFACE3}
    virsh net-autostart net-${CIDR}.${INTERFACE4}
    virsh net-autostart net-${CIDR}.${INTERFACE5}
    virsh net-autostart net-${CIDR}.${INTERFACE6}
    virsh net-autostart net-${CIDR}.${INTERFACE7}
    virsh net-autostart net-${CIDR}.${INTERFACE8}
    virsh net-autostart net-${CIDR}.${INTERFACE9}
    sudo iptables -t nat -A POSTROUTING -s ${CIDR}.${INTERFACE3}.0/24 -j MASQUERADE
}

# Openstack pool configuration

create_pool() {
    if [ ! -d ${DATAPATH}/${POOLISOPATH} ] || [ ! -d ${DATAPATH}/${POOLVMSPATH}];then
        mkdir -p ${DATAPATH}/${POOLISOPATH}
        mkdir -p ${DATAPATH}/${POOLVMSPATH}
    fi
    # virsh pool-define-as --name images --type dir --target /var/lib/libvirt/images
    virsh pool-define-as --name ${POOLISONAME} --type dir --target $(pwd)/${DATAPATH}/${POOLISOPATH}
    virsh pool-define-as --name ${POOLVMSNAME} --type dir --target $(pwd)/${DATAPATH}/${POOLVMSPATH}
    # echo "If you using ubuntu based distro, please add this line to /etc/apparmor.d/libvirt/TEMPLATE.qemu"
    # echo "  $(pwd)/${DATAPATH}/${POOLISOPATH}/ rwk,"
    # echo "  $(pwd)/${DATAPATH}/${POOLVMSPATH}/ rwk,"
    # echo "Then restart apparmor service."
}

delete_pool() {
    # virsh pool-undefine images
    virsh pool-undefine ${POOLISONAME}
    virsh pool-undefine ${POOLVMSNAME}
    rm -rf ${DATAPATH}/${POOLISOPATH}
    rm -rf ${DATAPATH}/${POOLVMSPATH}
}

start_pool() {
    # virsh pool-start images
    virsh pool-start ${POOLISONAME}
    virsh pool-start ${POOLVMSNAME}
    # virsh pool-autostart images
    virsh pool-autostart ${POOLISONAME}
    virsh pool-autostart ${POOLVMSNAME}
}

stop_pool() {
    # virsh pool-destroy images
    virsh pool-destroy ${POOLISONAME}
    virsh pool-destroy ${POOLVMSNAME}
}

# Openstack lab configuration

create_lab() {
    if [ -z $(which aria2c) ]; then
        echo "aria2 not found. Please install aria2 first."
        exit 1
    fi
    if [[ ! -e ${DATAPATH}/${POOLISOPATH}/${VMOS} ]]; then
        if [[ ${VMOS} == "ubuntu-bionic.img" ]]; then
            aria2c https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -o ${DATAPATH}/${POOLISOPATH}/ubuntu-bionic.img
        elif [[ ${VMOS} == "ubuntu-focal.img" ]]; then
            aria2c https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -o ${DATAPATH}/${POOLISOPATH}/ubuntu-focal.img
        elif [[ ${VMOS} == "ubuntu-jammy.img" ]]; then
            aria2c https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -o ${DATAPATH}/${POOLISOPATH}/ubuntu-jammy.img
        else 
            echo "OS not supported."
            exit 1
        fi
        virsh pool-refresh ${POOLISONAME}
    fi
    cat <<EOF >${DATAPATH}/${TEMPLATEDIR}/${TFGENNAME1}
[LAB]
PUBKEY1: ${PUBKEY1}
EOF
    for i in {1..3}
    do
    cat <<EOF >>${DATAPATH}/${TEMPLATEDIR}/${TFGENNAME1}

[VM${i}]
NAME: ${VMCTRL}${i}
OS: ${VMOS}
NESTED: ${VMCTRL_NESTED}
VCPUS: ${VMCTRL_VCPUS}
MEMORY: ${VMCTRL_MEMORY}
DISK1: ${VMCTRL_DISK1}
IFACE_NETWORK1: ${CIDR}.${INTERFACE3}.0
IFACE_IP1: ${CIDR}.${INTERFACE3}.1${i}
IFACE_NETWORK2: ${CIDR}.${INTERFACE4}.0
IFACE_IP2: ${CIDR}.${INTERFACE4}.1${i}
IFACE_NETWORK3: ${CIDR}.${INTERFACE5}.0
IFACE_IP3: ${CIDR}.${INTERFACE5}.1${i}
IFACE_NETWORK4: ${CIDR}.${INTERFACE6}.0
IFACE_IP4: none
IFACE_NETWORK5: ${CIDR}.${INTERFACE7}.0
IFACE_IP5: none
IFACE_NETWORK6: ${CIDR}.${INTERFACE8}.0
IFACE_IP6: ${CIDR}.${INTERFACE8}.1${i}
IFACE_NETWORK7: ${CIDR}.${INTERFACE9}.0
IFACE_IP7: ${CIDR}.${INTERFACE9}.1${i}
CONSOLE: vnc
EOF
    done
    
    cat <<EOF >${DATAPATH}/${TEMPLATEDIR}/${TFGENNAME2}
[LAB]
PUBKEY1: ${PUBKEY1}
EOF
    for i in {1..3}
    do
    cat <<EOF >>${DATAPATH}/${TEMPLATEDIR}/${TFGENNAME2}

[VM${i}]
NAME: ${VMCMPT}${i}
OS: ${VMOS}
NESTED: ${VMCMPT_NESTED}
VCPUS: ${VMCMPT_VCPUS}
MEMORY: ${VMCMPT_MEMORY}
DISK1: ${VMCMPT_DISK1}
DISK2: ${VMCMPT_DISK2}
DISK3: ${VMCMPT_DISK3}
IFACE_NETWORK1: ${CIDR}.${INTERFACE3}.0
IFACE_IP1: ${CIDR}.${INTERFACE3}.2${i}
IFACE_NETWORK2: ${CIDR}.${INTERFACE4}.0
IFACE_IP2: ${CIDR}.${INTERFACE4}.2${i}
IFACE_NETWORK3: ${CIDR}.${INTERFACE5}.0
IFACE_IP3: ${CIDR}.${INTERFACE5}.2${i}
IFACE_NETWORK4: ${CIDR}.${INTERFACE6}.0
IFACE_IP4: ${CIDR}.${INTERFACE6}.2${i}
IFACE_NETWORK5: ${CIDR}.${INTERFACE7}.0
IFACE_IP5: ${CIDR}.${INTERFACE7}.2${i}
IFACE_NETWORK6: ${CIDR}.${INTERFACE8}.0
IFACE_IP6: ${CIDR}.${INTERFACE8}.2${i}
IFACE_NETWORK7: ${CIDR}.${INTERFACE9}.0
IFACE_IP7: ${CIDR}.${INTERFACE9}.2${i}
CONSOLE: vnc
EOF
    done
    if [[ -e ${DATAPATH}/${TEMPLATEDIR}/${TFGENDIR1} ]]; then
        echo "Lab control directory already exist. Please delete it or rename it."
    elif [[ -e ${DATAPATH}/${TEMPLATEDIR}/${TFGENDIR2} ]]; then
        echo "Lab compute directory already exist. Please delete it or rename it."
    fi
    cd ${DATAPATH}/${TEMPLATEDIR}
    ./tfgen.sh ${TFGENDIR1} ${TFGENNAME1}
    ./tfgen.sh ${TFGENDIR2} ${TFGENNAME2}
}

deploy_lab() {
    if [[ -z $(which terraform) ]]; then
        echo "terraform not found. Please install terraform first."
        exit 1
    fi
    if [[ ! -e ${LIBVIRTPROVIDER} ]]; then
        echo "terraform libvirt provider not found, copying..."
        mkdir -p ${LIBVIRTPROVIDER}
        cp ${DATAPATH}/provider/terraform-provider-libvirt ${LIBVIRTPROVIDER}
    fi
    cd ${DATAPATH}/${TEMPLATEDIR}/${TFGENDIR1}
    terraform init
    terraform apply -auto-approve
    cd ../${TFGENDIR2}
    terraform init
    terraform apply -auto-approve
}

delete_lab() {
    cd ${DATAPATH}/${TEMPLATEDIR}/${TFGENDIR1}
    terraform destroy -auto-approve
    cd ../${TFGENDIR2}
    terraform destroy -auto-approve
    cd ..
    rm -rf ${TFGENDIR1} ${TFGENDIR2} ${TFGENNAME1} ${TFGENNAME2}
}

stop_lab() {
    for i in {1..3}
    do
        virsh destroy ${VMCTRL}${i}
        virsh destroy ${VMCMPT}${i}
    done
}

start_lab() {
    for i in {1..3}
    do
        virsh start ${VMCTRL}${i}
        virsh start ${VMCMPT}${i}
    done
}

snapshot_lab() {
    for i in {1..3}
    do
        virsh snapshot-create-as ${VMCTRL}${i} snap-${snapver}
        virsh snapshot-create-as ${VMCMPT}${i} snap-${snapver}
    done
}

snapshot_lab_delete() {
    for i in {1..3}
    do
        virsh snapshot-delete ${VMCTRL}${i} snap-${snapver}
        virsh snapshot-delete ${VMCMPT}${i} snap-${snapver}
    done
}

restore_lab() {
    for i in {1..3}
    do
        virsh snapshot-revert ${VMCTRL}${i} snap-${snapver}
        virsh snapshot-revert ${VMCMPT}${i} snap-${snapver}
    done
}

snapshot_lab_list() {
    for i in {1..3}
    do
        virsh snapshot-list ${VMCTRL}${i}
        virsh snapshot-list ${VMCMPT}${i}
    done
}

deploy_ceph_cluster() {
    cd ${DATAPATH}/ansible-iac
    tar -cf ceph-cluster.tar Ceph-iac
    scp ceph-cluster.tar root@${CIDR}.${INTERFACE3}.11:/root
    ssh -l root ${CIDR}.${INTERFACE3}.11 tar -xf /root/ceph-cluster.tar
    ssh -l root ${CIDR}.${INTERFACE3}.11 rm /root/ceph-cluster.tar
    rm ceph-cluster.tar
    cat <<EOF | ssh -l root ${CIDR}.${INTERFACE3}.11 tee -a /root/Ceph-iac/group_vars/all.yml
public_network: ${CIDR}.${INTERFACE3}.0/24
cluster_network: ${CIDR}.${INTERFACE4}.0/24
EOF
    ansible_check=$(ssh -l root ${CIDR}.${INTERFACE3}.11 which ansible)
    if [[ -z ${ansible_check} ]]; then
        echo "ansible not found. Installing..."
        ssh -l root ${CIDR}.${INTERFACE3}.11 pip3 install ansible && python3 -m pip install jinja2==3.0.3
    else
        echo "ansible found."
    fi
    ssh -l root ${CIDR}.${INTERFACE3}.11 ansible -i /root/Ceph-iac/inventory/hosts all -m ping
    if [[ $? -eq 0 ]]; then
        ssh -l root ${CIDR}.${INTERFACE3}.11 ansible-playbook -i /root/Ceph-iac/inventory/hosts /root/Ceph-iac/bootstrap-server.yml
        ssh -l root ${CIDR}.${INTERFACE3}.11 ansible-playbook -i /root/Ceph-iac/inventory/hosts /root/Ceph-iac/deploy-cluster.yml
        ssh -l root ${CIDR}.${INTERFACE3}.11 /root/Ceph-iac/keyring-copy.sh
    else
        echo "ansible ping failed."
        exit 1
    fi
}

prepare_lab() {
    rm $HOME/.ssh/known_hosts
    if [[ -e "${DATAPATH}/${PUBKEYNODE}" ]]; then
        rm ${DATAPATH}/${PUBKEYNODE}
    else
        echo "file not found."
    fi
    for i in {1..3}
    do
        ssh -l root ${CIDR}.${INTERFACE3}.1${i} ssh-keygen -q -t ed25519 <<< $'\ny'
        ssh -l root ${CIDR}.${INTERFACE3}.2${i} ssh-keygen -q -t ed25519 <<< $'\ny'
        ssh -l root ${CIDR}.${INTERFACE3}.1${i} cat .ssh/id_ed25519.pub >> ${DATAPATH}/${PUBKEYNODE}
        ssh -l root ${CIDR}.${INTERFACE3}.2${i} cat .ssh/id_ed25519.pub >> ${DATAPATH}/${PUBKEYNODE}
    done
    for j in {1..3}
    do
        cat ${DATAPATH}/${PUBKEYNODE} | ssh -l root ${CIDR}.${INTERFACE3}.1${j} tee -a .ssh/authorized_keys
        cat ${DATAPATH}/${PUBKEYNODE} | ssh -l root ${CIDR}.${INTERFACE3}.2${j} tee -a .ssh/authorized_keys
    done
    for k in {1..3}
    do
        cat <<EOF | ssh -l root ${CIDR}.${INTERFACE3}.1${k} tee  /etc/hosts
${CIDR}.${INTERFACE3}.11 control-01
${CIDR}.${INTERFACE3}.12 control-02
${CIDR}.${INTERFACE3}.13 control-03
${CIDR}.${INTERFACE3}.21 compute-01
${CIDR}.${INTERFACE3}.22 compute-02
${CIDR}.${INTERFACE3}.23 compute-03
EOF
        cat <<EOF | ssh -l root ${CIDR}.${INTERFACE3}.2${k} tee  /etc/hosts
${CIDR}.${INTERFACE3}.11 control-01
${CIDR}.${INTERFACE3}.12 control-02
${CIDR}.${INTERFACE3}.13 control-03
${CIDR}.${INTERFACE3}.21 compute-01
${CIDR}.${INTERFACE3}.22 compute-02
${CIDR}.${INTERFACE3}.23 compute-03
EOF
    done
    for l in {1..3}
    do
        cat <<EOF | ssh -l root ${CIDR}.${INTERFACE3}.1${l} tee .ssh/config
Host *
        StrictHostKeyChecking=accept-new
EOF
        cat <<EOF | ssh -l root ${CIDR}.${INTERFACE3}.2${l} tee .ssh/config
Host *
        StrictHostKeyChecking=accept-new
EOF
    done
    prepare(){
        timedatectl set-timezone Asia/Jakarta
        timedatectl set-ntp true
        apt update
        apt upgrade -y
        apt install -y chrony git wget unzip vim bash-completion python3 python3-pip
        wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
        chmod +x /usr/local/bin/oh-my-posh
        rm -rf simple-dotfiles
        git clone https://github.com/Script47ph/simple-dotfiles.git
        cp -r simple-dotfiles/poshthemes ~/.poshthemes
        cp simple-dotfiles/vimrc ~/.vimrc
        cp -r simple-dotfiles/vim ~/.vim
        cp simple-dotfiles/inputrc ~/.inputrc
        echo -e 'eval "$(oh-my-posh init bash --config ~/.poshthemes/huvix.omp.json)" \nalias cl="clear"' >> ~/.bashrc
        reboot
    }
    for m in {1..3}
    do
        ssh -l root ${CIDR}.${INTERFACE3}.1${m} "$(typeset -f prepare); prepare"
        ssh -l root ${CIDR}.${INTERFACE3}.2${m} "$(typeset -f prepare); prepare"
    done
}

# Main

usage () {
    echo
    echo "Usage: Openstack.sh [OPTION] arg"
    echo "--net (Valid values: create, delete, start)"
    echo "--lab (Valid values: create, delete, deploy, stop, start, snapshot take, restore, snapshot list, prepare, deploy ceph)"
    echo "--pool (Valid values: create, delete, start, stop)"
    echo
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

if [[ $1 == "--net" ]]; then
    if [[ $2 == "create" ]]; then
        if [[ ! -d ${DATAPATH}/network ]]; then
            mkdir -p ${DATAPATH}/network
        fi
        create_net
    elif [[ $2 == "delete" ]]; then
        delete_net
    elif [[ $2 == "start" ]]; then
        start_net
    else
        usage
        exit 1
    fi
elif [[ $1 == "--lab" ]]; then
    if [[ $2 == "create" ]]; then
        create_lab
    elif [[ $2 == "delete" ]]; then
        delete_lab
    elif [[ $2 == "deploy" ]]; then
        if [[ $3 == "ceph" ]]; then
            deploy_ceph_cluster
        else
            deploy_lab
        fi
    elif [[ $2 == "stop" ]]; then
        stop_lab
    elif [[ $2 == "start" ]]; then
        start_lab
    elif [[ $2 == "snapshot" ]]; then
        if [[ $3 == "list" ]]; then
            snapshot_lab_list
        elif [[ $3 == "take" ]]; then
            if [[ -z $4 ]]; then
                echo "Please specify snapshot version."
                exit 1
            else
                snapver=$4
                snapshot_lab
            fi
        elif [[ $3 == "delete" ]]; then
            if [[ -z $4 ]]; then
                echo "Please specify snapshot version."
                exit 1
            else
                snapver=$4
                snapshot_lab_delete
            fi
        else 
            usage
            exit 1
        fi
    elif [[ $2 == "restore" ]]; then
        if [[ -z $3 ]]; then
            echo "Please specify snapshot version."
            exit 1
        else
            snapver=$3
            restore_lab
        fi
    elif [[ $2 == "prepare" ]]; then
        prepare_lab
    else
        usage
        exit 1
    fi
elif [[ $1 == "--pool" ]]; then
    if [[ $2 == "create" ]]; then
        create_pool
    elif [[ $2 == "delete" ]]; then
        delete_pool
    elif [[ $2 == "start" ]]; then
        start_pool
    elif [[ $2 == "stop" ]]; then
        stop_pool
    else
        usage
        exit 1
    fi
else
    usage
    exit 1
fi
