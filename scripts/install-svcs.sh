#! /bin/bash

curl -L https://raw.githubusercontent.com/sandvine-eng/svauto/dev/scripts/svauto-deployments.sh | bash -s -- --base-os=centos6 --roles=bootstrap,grub-conf,svcs,post-cleanup
