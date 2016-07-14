#! /bin/bash

curl -L https://raw.githubusercontent.com/sandvine-eng/svauto/dev/scripts/svauto-deployments.sh | bash -s -- --base-os=ubuntu16 --roles=bootstrap,grub-conf,post-cleanup --extra-vars="base_os_upgrade=yes ubuntu_install=server"
