#! /bin/bash

# Copyright 2016, Sandvine Incorporated.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Get options, both Linux Bridges and Open vSwitch (default) are supported.
# You can also use --dry-run to NOT run Ansible in the end, just prepare the
# configuration files.
for i in "$@"
do
case $i in

        --br-mode=*)

	        BR_MODE="${i#*=}"
        	shift
		;;


        --base-os=*)

                BASE_OS="${i#*=}"
                shift
                ;;


	--base-os-upgrade)

		BASE_OS_UPGRADE="yes"
		shift
		;;


        --use-dummies)

	        USE_DUMMIES="yes"
		shift
        	;;


        --dry-run)

	        DRYRUN="yes"
		shift
        	;;

esac
done

# Open vSwitch is the default.
if [ -z $BR_MODE ]
then
	BR_MODE=OVS
fi

# Validade the BR_MODE variable.
if ! [[ "$BR_MODE" = "OVS" || "$BR_MODE" = "LBR" ]]
then
	echo
	echo "Aborting!!!"
	echo "You need to correctly specify the Bridge Mode for your OpenStack."
	echo
	echo "Try:"
	echo "./os-deploy.sh --br-mode=OVS --base-os=ubuntu16 --base-os-upgrade=yey  # For Open vSwitch."
	echo "./os-deploy.sh --br-mode=LBR --base-os=ubuntu16 --base-os-upgrade=yes  # For Linux Bridges."
	exit 1
fi


# Doing CPU checks
if [ "$DRYRUN" == "yes" ]
then

        echo
	echo "WARNING!!!"
        echo "Not running CPU checks..."

else
 
	# Verifying if you have enough CPU Cores.
	echo
	echo "Verifying if you have enough CPU Cores..."
	
	CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
	
	if [ $CPU_CORES -lt 4 ]
	then
		echo
	        echo "WARNING!!!"
		echo "You do not have enough CPU Cores to run this system!"
		echo "ABORTING!!!"
	
		exit 1
	else
	        echo
		echo "Okay, good, you have enough CPU Cores, proceeding..."
	fi


	# Verifying if host have Virtualization enabled, abort it if doesn't have.
	echo
	echo "Verifying if your CPU supports Virtualization..."
	
	sudo apt -y install cpu-checker 2>&1 > /dev/null
	
	if /usr/sbin/kvm-ok 2>&1 > /dev/null
	then
		echo
	        echo "OK, Virtualization supported, proceeding..."
	else
	        echo "WARNING!!!"
		echo "Virtualization NOT supported on this CPU or it is not enabled on your BIOS"
		echo "ABORTING!!!"
	
		exit 1
	fi

fi


# Detect some of the local settings:
WHOAMI=$(whoami)
HOSTNAME=$(hostname)
FQDN=$(hostname -f)
DOMAIN=$(hostname -d)


# If the hostname and hosts file aren't configured according, abort.
if [ -z $HOSTNAME ]; then
        echo "Hostname not found... Configure the file /etc/hostname with your hostname. ABORTING!"

        exit 1
fi

if [ -z $DOMAIN ]; then
        echo "Domain not found... Configure the file /etc/hosts with your \"IP + FQDN + HOSTNAME\". ABORTING!"

        exit 1
fi

if [ -z $FQDN ]; then
        echo "FQDN not found... Configure your /etc/hosts according. ABORTING!"

        exit 1
fi


# Display local configuration
echo
echo "The detected local configuration are:"
echo
echo "You are:" $WHOAMI
echo "Hostname:" $HOSTNAME
echo "FQDN:" $FQDN
echo "Domain:" $DOMAIN


# Configuring Bridge Mode on group_vars/all
echo
echo "Configuring Bridge Mode to "$BR_MODE" on ansible/group_vars/all file..."

# http://docs.openstack.org/networking-guide/scenario_legacy_lb.html
if [ "$BR_MODE" = "LBR" ]
then
	sed -i -e 's/br_mode:.*/br_mode: "LBR"/' ansible/group_vars/all
	sed -i -e 's/linuxnet_interface_driver:.*/linuxnet_interface_driver: "nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver"/' ansible/group_vars/all
	sed -i -e 's/neutron_interface_driver:.*/neutron_interface_driver: "linuxbridge"/' ansible/group_vars/all
	sed -i -e 's/mechanism_drivers:.*/mechanism_drivers: "linuxbridge"/' ansible/group_vars/all
	sed -i -e 's/firewall_driver:.*/firewall_driver: "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver"/' ansible/group_vars/all
fi

# http://docs.openstack.org/networking-guide/scenario_legacy_ovs.html
if [ "$BR_MODE" = "OVS" ]
then 
         sed -i -e 's/br_mode:.*/br_mode: "OVS"/' ansible/group_vars/all
         sed -i -e 's/linuxnet_interface_driver:.*/linuxnet_interface_driver: "nova.network.linux_net.LinuxOVSInterfaceDriver"/' ansible/group_vars/all
         sed -i -e 's/neutron_interface_driver:.*/neutron_interface_driver: "openvswitch"/' ansible/group_vars/all
         sed -i -e 's/mechanism_drivers:.*/mechanism_drivers: "openvswitch"/' ansible/group_vars/all
         sed -i -e 's/firewall_driver:.*/firewall_driver: "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"/' ansible/group_vars/all
fi


# Configuring FQDN and Domain on group_vars/all
echo
echo "Configuring ansible/group_vars/all & ansible/hosts file based on current environment..."

sed -i -e 's/base_os:.*/base_os: "ubuntu16"/' ansible/group_vars/all
sed -i -e 's/base_os_upgrade:.*/base_os_upgrade: "yes"/' ansible/group_vars/all
sed -i -e 's/use_dummies:.*/use_dummies: "yes"/' ansible/group_vars/all

sed -i -e 's/controller-1.yourdomain.com/'$FQDN'/g' ansible/group_vars/all
sed -i -e 's/yourdomain.com/'$DOMAIN'/g' ansible/group_vars/all

sed -i -e 's/^#localhost/localhost/g' ansible/hosts


# Configuring site.yml and some roles
echo
echo "Configuring ansible/site.yml and OpenStack OpenRC files with your current $WHOAMI user..."

sed -i -e 's/administrative/'$WHOAMI'/g' ansible/site.yml
sed -i -e 's/administrative/'$WHOAMI'/g' ansible/roles/keystone/tasks/openrc-files.yml


# Configuring the default interface
DEFAULT_GW_INT=$(ip r | grep default | awk '{print $5}')

echo 
echo "Your primary network interface is:"
echo "dafault route via:" $DEFAULT_GW_INT

echo
echo "Preparing Ansible templates based on current default gateway interface..."

sed -i -e 's/eth0/'$DEFAULT_GW_INT'/g' ansible/roles/nova_aio/templates/nova.conf
sed -i -e 's/eth0/'$DEFAULT_GW_INT'/g' ansible/roles/cinder/templates/cinder.conf


echo
echo "Running Ansible, deploying OpenStack:"
if [ "$DRYRUN" == "yes" ]
then
        echo
	echo "WARNING!!!"
        echo "Not running Ansible! Just preparing the environment variables..."
else
        echo

	cd ~/svauto/ansible
        ansible-playbook site.yml
fi


# Uploading and/or creating SSH Keypair, only if Nova binary available.
if [ "$DRYRUN" == "yes" ]
then

        echo
	echo "WARNING!!!"
        echo "Not creating / uploading SSH Keypairs on --dry-run..."

else

	if [ -f ~/.ssh/id_rsa.pub ] && [ -f /usr/bin/nova ]
	then

		echo
		echo "Creating and uploding your SSH Keypair into OpenStack..."
		echo
		echo "Safe SSH Key found, uploading it to OpenStack."

		source ~/demo-openrc.sh
		nova keypair-add --pub-key ~/.ssh/id_rsa.pub default

	else

		echo
		echo "Creating and uploding your SSH Keypair into OpenStack..."
		echo
	        echo "Creating a safe SSH Keypair for you and uploading it to OpenStack."
		echo

	        ssh-keygen -b 2048 -t rsa -N "" -f ~/.ssh/id_rsa
	        source ~/demo-openrc.sh
	        nova keypair-add --pub-key ~/.ssh/id_rsa.pub default

	fi

fi


# Tell about iptables required rules and configure it at /etc/rc.local:
if [ "$DRYRUN" == "yes" ]
then

        echo
	echo "WARNING!!!"
        echo "Not telling about iptables neither configuring it at /etc/rc.local."

else
 
	# Displaying information about the need for an iptables MASQUERADE rule.
	echo 
	echo "You'll need an iptables MASQUERADE rule to allow your Instances to reach the"
	echo "Internet, so, lets add the following line to your /etc/rc.local file:"
	echo
	echo "iptables -t nat -I POSTROUTING 1 -o $DEFAULT_GW_INT -j MASQUERADE"
	
	sudo sed -i -e '/exit/d' /etc/rc.local
	
	sudo tee --append /etc/rc.local > /dev/null <<EOF
iptables -t nat -I POSTROUTING 1 -o $DEFAULT_GW_INT -j MASQUERADE
EOF
	
	echo
	echo "Running /etc/rc.local for you..."
	
	sudo /etc/rc.local

fi