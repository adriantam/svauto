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


source lib/include-tools.inc


for i in "$@"
do
case $i in

        --base-os=*)

                BASE_OS="${i#*=}"
                shift
                ;;

	--base-os-upgrade)

		BASE_OS_UPGRADE="yes"
		shift
		;;

	--operation=*)

		OPERATION="${i#*=}"
		shift
		;;

	--bootstrap-svauto)

		BOOTSTRAP_SVAUTO="yes"
		shift
		;;

	--svauto-deployments)

		SVAUTO_DEPLOYMENTS="yes"
		shift
		;;

	# Options starting with --ansible-* are passed to Ansible itself,
	# or being used by dynamic stuff.
	--ansible-roles=*)

		ALL_ANSIBLE_ROLES="${i#*=}"
		ANSIBLE_ROLES="$( echo $ALL_ANSIBLE_ROLES | sed s/,/\ /g )"
		shift
		;;

	--ansible-extra-vars=*)

		ALL_ANSIBLE_EXTRA_VARS="${i#*=}"
		ANSIBLE_EXTRA_VARS="$( echo $ALL_ANSIBLE_EXTRA_VARS | sed s/,/\ /g )"
		shift
		;;

	# Options starting with --os-* are OpenStack related
	--os-project=*)

		OS_PROJECT="${i#*=}"
		shift
		;;

	--os-stack=*)

		OS_STACK="${i#*=}"
		shift
		;;

	--os-aio)

		OS_AIO="yes"
		shift
		;;

        --os-release=*)

	        OS_RELEASE="${i#*=}"
		shift
		;;

        --os-bridge-mode=*)

	        OS_BRIDGE_MODE="${i#*=}"
		shift
		;;

        --os-hybrid-firewall)

		OS_HYBRID_FW="yes"
		shift
		;;

        --os-no-security-groups)

		OS_NO_SEC="yes"
		shift
		;;

	--os-open-provider-nets-to-regular-users)

		OS_OPEN_PROVIDER_NETS_TO_REGULAR_USERS="yes"
		shift
		;;

	--freebsd-pts)

		FREEBSD_PTS="yes"
		shift
		;;

	--labify)

		LABIFY="yes"
		shift
		;;

	--packer-build-sandvine)

		PACKER_BUILD_SANDVINE="yes"
		shift
		;;

	--packer-build-official)

		PACKER_BUILD_OFFICIAL="yes"
		shift
		;;

	--packer-build-cs)

		PACKER_BUILD_CS="yes"
		shift
		;;

	--move2webroot)

		MOVE2WEBROOT="yes"
		shift
		;;

	--heat-templates)

		HEAT_TEMPLATES="yes"
		shift
		;;

	--heat-templates-cs)

		HEAT_TEMPLATES_CS="yes"
		shift
		;;

	--deployment-mode)

		DEPLOYMENT_MODE="yes"
		shift
		;;

	--config-only-mode)

		CONFIG_ONLY_MODE="yes"
		shift
		;;

	--cloud-services-mode=*)

		CLOUD_SERVICES_MODE="${i#*=}"
		shift
		;;

	--libvirt-files)

		LIBVIRT_FILES="yes"
		shift
		;;

	--installation-helper)

		INSTALLATION_HELPER="yes"
		HEAT_TEMPLATES_CS="yes"
		LIBVIRT_FILES="yes"
		shift
		;;

	--release)

		RELEASE="yes"
		shift
		;;

	--build-yum-repo)

		BUILD_YUM_REPO="yes"
		shift
		;;

	# Options starting with --ubuntu-* are Ubuntu related
        --ubuntu-network-setup)

	        UBUNTU_NETWORK_SETUP="yes"
		shift
		;;

        --ubuntu-network-detect-default-nic)

	        UBUNTU_NETWORK_DETECT_DEFAULT_NIC="yes"
		shift
		;;

	--ubuntu-network-mode=*)

		UBUNTU_NETWORK_MODE="${i#*=}"
		shift
		;;

	--ubuntu-network-ip=*)

		# Syntax: "ip/mask,gateway"
		UBUNTU_NETWORK_IP_RAW_DATA="${i#*=}"

		UBUNTU_STATIC_IP_MASK=`echo $UBUNTU_NETWORK_IP_RAW_DATA | cut -d , -f 1`
		UBUNTU_STATIC_IP_GATEWAY=`echo $UBUNTU_NETWORK_IP_RAW_DATA | cut -d , -f 2`

		shift
		;;

	--ubuntu-name-servers=*)

		UBUNTU_NS_SETUP="yes"

		# Syntax: "dns1,dns2"
		UBUNTU_NAME_SERVERS_RAW="${i#*=}"

		UBUNTU_NAME_SERVER_1=`echo $UBUNTU_NAME_SERVERS_RAW | cut -d , -f 1`
		UBUNTU_NAME_SERVER_2=`echo $UBUNTU_NAME_SERVERS_RAW | cut -d , -f 2`

		shift
		;;

	--ubuntu-dummies)

		UBUNTU_DUMMIES="yes"
		shift
		;;

	--ubuntu-iptables-rc-local)

		UBUNTU_IPTABLES_RC_LOCAL="yes"
		shift
		;;

        --download-iso-images)

	        DOWNLOAD_ISO_IMAGES="yes"
		shift
		;;

	--clean-all)

		CLEAN_ALL="yes"
		shift
		;;

	--dry-run)

		DRY_RUN="yes"
		shift
		;;

esac
done


#
# Operation System setup on playbook vars
#

if [ ! -z "$BASE_OS" ];
then
	sed -i -e 's/base_os:.*/base_os: "'$BASE_OS'"/' ansible/group_vars/all
fi

if [ "$BASE_OS_UPGRADE" == "yes" ]
then
	sed -i -e 's/base_os_upgrade:.*/base_os_upgrade: "yes"/' ansible/group_vars/all
fi


#
# Ubuntu Settings
#

# Network setup?
if [ "$UBUNTU_NETWORK_SETUP" == "yes" ]
then

	echo
	echo "Ubuntu Network Setup requested:"

	sed -i -e 's/ubuntu_network_setup:.*/ubuntu_network_setup: "yes"/' ansible/group_vars/all

fi

if [ "$UBUNTU_NETWORK_DETECT_DEFAULT_NIC" == "yes" ]
then

	# Configuring the default interface
	unset UBUNTU_PRIMARY_INTERFACE
	UBUNTU_PRIMARY_INTERFACE=$(ip r | grep default | awk '{print $5}')


	if [ -z "$UBUNTU_PRIMARY_INTERFACE" ]
	then
		echo
		echo "ABORTING! Ubuntu's primary network interface not detected!"
		echo "Are you sure that your Ubuntu have a default gateway configured?"

		exit 1
	fi


	echo
	echo "Your primary network interface is:"
	echo "dafault route via:" $UBUNTU_PRIMARY_INTERFACE

	echo
	echo "* Enabling Network Setup, preparing Ansible variables based on detected default interface..."

	sed -i -e 's/ubuntu_primary_interface:.*/ubuntu_primary_interface: "'$UBUNTU_PRIMARY_INTERFACE'"/g' ansible/group_vars/all


	if [ "$OPERATION" == "openstack" ]
	then

		echo
		echo "* Configuring OpenStack's Management Interface based on: '$UBUNTU_PRIMARY_INTERFACE'..."

		sed -i -e 's/{{OS_MGMT_NIC}}/'$UBUNTU_PRIMARY_INTERFACE'/' ansible/hosts

	fi

fi

# Network mode:
if [ ! -z "$UBUNTU_NETWORK_MODE" ];
then

	echo
	echo "* Configuring Ubuntu's network mode to: \"$UBUNTU_NETWORK_MODE\"."

	case "$UBUNTU_NETWORK_MODE" in

		dhcp)

			sed -i -e 's/ubuntu_network_mode:.*/ubuntu_network_mode: "dhcp"/' ansible/group_vars/all
			;;

		static)

			if [ -z $UBUNTU_STATIC_IP_MASK ]
			then
				echo
				echo "Error! Static network mode requires IP address, mask and gateway. ABORTING!"
				echo

				exit 1
			else

				echo
				echo " - Static IP/MASK: \"$UBUNTU_STATIC_IP_MASK\"."
				echo " - Static gateway: \"$UBUNTU_STATIC_IP_GATEWAY\"."

				UBUNTU_IP_MASK_SANITIZED=$(echo $UBUNTU_STATIC_IP_MASK | sed -e 's/\//\\\//g')

				sed -i -e 's/ubuntu_network_mode:.*/ubuntu_network_mode: "static"/' ansible/group_vars/all
				sed -i -e 's/ubuntu_static_ip_mask:.*/ubuntu_static_ip_mask: "'$UBUNTU_IP_MASK_SANITIZED'"/' ansible/group_vars/all
				sed -i -e 's/ubuntu_static_ip_gateway:.*/ubuntu_static_ip_gateway: "'$UBUNTU_STATIC_IP_GATEWAY'"/' ansible/group_vars/all

			fi
			;;

	esac

fi

# Name Server setup?
if [ "$UBUNTU_NS_SETUP" == "yes" ]
then
	sed -i -e 's/ubuntu_name_server_1:.*/ubuntu_name_server_1: "'$UBUNTU_NAME_SERVER_1'"/' ansible/group_vars/all
	sed -i -e 's/ubuntu_name_server_2:.*/ubuntu_name_server_2: "'$UBUNTU_NAME_SERVER_2'"/' ansible/group_vars/all
fi

# Enable dummies?
if [ "$UBUNTU_DUMMIES" == "yes" ]
then
	sed -i -e 's/ubuntu_setup_dummy_nics:.*/ubuntu_setup_dummy_nics: "yes"/' ansible/group_vars/all
fi

# Enable iptalbes via /etc/rc.local?
if [ "$UBUNTU_IPTABLES_RC_LOCAL" == "yes" ]
then
	sed -i -e 's/ubuntu_setup_iptables_rc_local:.*/ubuntu_setup_iptables_rc_local: "yes"/' ansible/group_vars/all
fi


#
# SVAuto Deployments - "Curl | Bash" lovers
#

if [ "$SVAUTO_DEPLOYMENTS" == "yes" ]
then

	svauto_deployments

	exit 0

fi


#
# SVAuto Functions
#

if [ "$CLEAN_ALL" == "yes" ]
then

	echo
	echo "Cleaning it up..."

	git checkout ansible/hosts ansible/group_vars/all

	rm -rf build-date.txt packer/build* tmp/cs-rel/* tmp/cs/* tmp/sv/* ansible/tmp/*

	# Also need to clean ~/svauto.conf.  Otherwise, cannot overwrite things like 
	# DNS_DOMAIN etc.
	rm -rf ~/svauto.conf

	echo

	exit 0

fi


if [ "$DOWNLOAD_ISO_IMAGES" == "yes" ]
then

	echo
	echo "Download ISO images into Libvirt subdir:"

	sudo mkdir /var/lib/libvirt/ISO -p

	cd /var/lib/libvirt/ISO

	sudo wget -c $ubuntu16_iso_image
	sudo wget -c $ubuntu14_iso_image
	sudo wget -c $centos7_iso_image
	sudo wget -c $centos6_iso_image

	exit 0

fi


if [ "$BOOTSTRAP_SVAUTO" == "yes" ]
then

	echo
	echo "Installing SVAuto dependencies via APT:"
	echo

	sudo ~/svauto/scripts/bootstrap-svauto-server.sh

	exit 0

fi


if [ "$BUILD_YUM_REPO" == "yes" ]
then

#       build_yum_repo_agawa
#       build_yum_repo_niagara
	build_yum_repo_yukon

	exit 0

fi


if [ -z "$OPERATION" ]
then

	echo
	echo "No operation mode was specified, use one of the following options:"

	echo
	echo "--operation=sandvine, or --operation=cloud-services, or --operation=openstack, to \"~/svauto.sh\""

	echo
	exit 1

fi


if [ "$OPERATION" == "openstack" ]
then

	echo
	echo "Installing OpenStack with SVAuto:"

	# NOTE: all the OS_* variables are being used by "os_deploy" below:
	os_deploy

	exit 0

fi


if [ "$MOVE2WEBROOT" == "yes" ]
then

	move2webroot

fi


if [ "$PACKER_BUILD_CS" == "yes" ] && [ "$RELEASE" == "yes" ]
then

	packer_build_cs_release

	exit 0

fi


if [ "$PACKER_BUILD_CS" == "yes" ]
then

	packer_build_cs_lab
	packer_build_cs

	exit 0

fi


if [ "$PACKER_BUILD_OFFICIAL" == "yes" ]
then

	packer_build_official

	exit 0

fi


if [ "$PACKER_BUILD_SANDVINE" == "yes" ]
then

	packer_build_sandvine_lab
	packer_build_sandvine

	exit 0

fi


if [ ! "$LABIFY" == "yes" ]
then


	if [ -z $OS_PROJECT ]
	then
		echo
		echo "You did not specified the OpenStack Project name, by passing:"
		echo
		echo "--os-project=\"demo\" to \"~/svauto.sh\""

		exit 1
	fi


	if [ ! -f ~/$OS_PROJECT-openrc.sh ]
	then
		echo
		echo "OpenStack Credentials for "$OS_PROJECT" account not found, aborting!"

		exit 1
	else
		echo
		echo "Loading OpenStack credentials for "$OS_PROJECT" account..."

		source ~/$OS_PROJECT-openrc.sh
	fi


	if [ -z $OS_STACK ]
	then
		echo
		echo "You did not specified the destination Stack to deploy Sandvine's RPM Packages."
		echo "However, the following Stack(s) was detected under your account:"
		echo

		heat stack-list

		echo
		echo "Run this script with the following arguments:"
		echo
		echo "cd ~/svauto"
		echo "./svauto.sh --os-project=\"demo\" --stack=demo"
		echo
		echo
		echo "If you don't have a Sandvine compatible Stack up and running."
		echo "To launch one, run:"
		echo
		echo "heat stack-create demo -f ~/svauto/misc/os-heat-templates/sandvine-stack-0.1-centos.yaml"
		echo
		echo "Aborting!"

		exit 1
	fi


	if heat stack-show $OS_STACK 2>&1 > /dev/null
	then
		echo
		echo "Stack found, proceeding..."
	else
		echo
		echo "Stack not found! Aborting..."
		exit 1
	fi


#	TODO: Auto detected all instances automatically:
	PTS_FLOAT=$(nova floating-ip-list | grep `nova list | grep $OS_STACK-pts | awk $'{print $2}'` | awk $'{print $4}')
	SDE_FLOAT=$(nova floating-ip-list | grep `nova list | grep $OS_STACK-sde | awk $'{print $2}'` | awk $'{print $4}')
	SPB_FLOAT=$(nova floating-ip-list | grep `nova list | grep $OS_STACK-spb | awk $'{print $2}'` | awk $'{print $4}')
#	CSD_FLOAT=$(nova floating-ip-list | grep `nova list | grep $OS_STACK-csd | awk $'{print $2}'` | awk $'{print $4}')


	if [ -z $PTS_FLOAT ] || [ -z $SDE_FLOAT ] || [ -z $SPB_FLOAT ] #|| [ -z $CSD_FLOAT ]
	then
		echo
		echo "Warning! No compatible Instances was detected on your \"$OS_STACK\" Stack!"
		echo "Possible causes are:"
		echo
		echo " * Missing Floating IP for one or more Sandvine's Instances."
		echo " * You're running a Stack that is not compatbile with Sandvine's rquirements."
		echo
		exit 1
	fi


	echo
	echo "The following Sandvine-compatible Instances (their Floating IPs) was detected on"
	echo "your \"$OS_STACK\" Stack:"
	echo
	echo Floating IPs of:
	echo
	echo PTS: $PTS_FLOAT
	echo SDE: $SDE_FLOAT
	echo SPB: $SPB_FLOAT
#	echo CSD: $CSD_FLOAT

fi


echo
echo "Preparing the Ansible Playbooks to deploy/configure Sandvine Platform..."


if [ ! "$LABIFY" == "yes" ]
then

	git checkout ansible/hosts

	if [ "$FREEBSD_PTS" == "yes" ]
	then
		sed -i -e 's/^#FREEBSD_PTS_IP/'$PTS_FLOAT'/g' ansible/hosts
	else
		sed -i -e 's/^#PTS_IP/'$PTS_FLOAT'/g' ansible/hosts
	fi
	sed -i -e 's/^#SDE_IP/'$SDE_FLOAT'/g' ansible/hosts
	sed -i -e 's/^#SPB_IP/'$SPB_FLOAT'/g' ansible/hosts
#	sed -i -e 's/^#CSD_IP/'$CSD_FLOAT'/g' ansible/hosts

	sed -i -e 's/packages_server:.*/packages_server: \"'$SVAUTO_MAIN_HOST'\"/g' ansible/group_vars/all

	sed -i -e 's/license_server:.*/license_server: \"'$LICENSE_SERVER'\"/g' ansible/group_vars/all

fi


if [ ! "$LABIFY" == "yes" ]
then

	if [ "$FREEBSD_PTS" == "yes" ]
	then

		if [ "$DRY_RUN" == "yes" ]
		then
			echo
			echo "Not preparing FreeBSD! Skipping this step..."
		else
			echo
			echo "FreeBSD PTS detected, preparing it, by installing Python 2.7 sane version..."
			ssh -oStrictHostKeyChecking=no cloud@$PTS_FLOAT 'sudo pkg_add http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/amd64/8.2-RELEASE/packages/python/python27-2.7.1_1.tbz'
			sed -i -e 's/base_os:.*/base_os: freebsd8/g' ansible/group_vars/all
			sed -i -e 's/deploy_pts_freebsd_pkgs:.*/deploy_pts_freebsd_pkgs: yes/g' ansible/group_vars/all
			echo "done."
		fi

	fi

fi

if [ "$LABIFY" == "yes" ]
then

	echo
	echo "Labifying the playbook, so it can work against lab's Instances..."

	echo
	echo "You'll need to copy and paste each hostname here, after running profilemgr..."

	echo
	echo -n "Type the PTS hostname: "
	read PTS_HOSTNAME
	echo -n "Type the PTS Service IP: "
	read PTS_SRVC_IP

	echo
	echo -n "Type the SDE hostname: "
	read SDE_HOSTNAME
	echo -n "Type the SDE Service IP: "
	read SDE_SRVC_IP

	echo
	echo -n "Type the SPB hostname: "
	read SPB_HOSTNAME
	echo -n "Type the SPB Service IP: "
	read SPB_SRVC_IP

#	echo
#	echo -n "Type the Subscriber IPv4 Subnet/Mask (for subnets.txt on the PTS): "
#	read INT_SUBNET

	echo
	echo -n "Type the username with password-less SSH access to the lab's Instances: "
	read REGULAR_SYSTEM_USER


	PTS_FQDN_TMP=$PTS_HOSTNAME.$DNS_DOMAIN
	SDE_FQDN_TMP=$SDE_HOSTNAME.$DNS_DOMAIN
	SPB_FQDN_TMP=$SPB_HOSTNAME.$DNS_DOMAIN

	PTS_FQDN=`echo $PTS_FQDN_TMP | awk '{print tolower($0)}'`
	SDE_FQDN=`echo $SDE_FQDN_TMP | awk '{print tolower($0)}'`
	SPB_FQDN=`echo $SPB_FQDN_TMP | awk '{print tolower($0)}'`

	PTS_CTRL_IP=`host $PTS_FQDN_TMP | awk $'{print $4}'`
	SDE_CTRL_IP=`host $SDE_FQDN_TMP | awk $'{print $4}'`
	SPB_CTRL_IP=`host $SPB_FQDN_TMP | awk $'{print $4}'`
#	CSD_CTRL_IP=`host $PTS_FQDN_TMP | awk $'{print $4}'`


	git checkout ansible/group_vars/all


	echo
	echo "Configuring group_vars/all..."

	#sed -i -e 's/int_subnet:.*/int_subnet: '$INT_SUBNET'/g' ansible/group_vars/all

	sed -i -e 's/pts_ctrl_ip:.*/pts_ctrl_ip: '$PTS_CTRL_IP'/g' ansible/group_vars/all
	sed -i -e 's/pts_srvc_ip:.*/pts_srvc_ip: '$PTS_SRVC_IP'/g' ansible/group_vars/all

	sed -i -e 's/sde_ctrl_ip:.*/sde_ctrl_ip: '$SDE_CTRL_IP'/g' ansible/group_vars/all
	sed -i -e 's/sde_srvc_ip:.*/sde_srvc_ip: '$SDE_SRVC_IP'/g' ansible/group_vars/all

	sed -i -e 's/csd_ctrl_ip:.*/csd_ctrl_ip: '$SDE_CTRL_IP'/g' ansible/group_vars/all
	sed -i -e 's/csd_srvc_ip:.*/csd_srvc_ip: '$SDE_SRVC_IP'/g' ansible/group_vars/all

	sed -i -e 's/spb_ctrl_ip:.*/spb_ctrl_ip: '$SPB_CTRL_IP'/g' ansible/group_vars/all
	sed -i -e 's/spb_srvc_ip:.*/spb_srvc_ip: '$SPB_SRVC_IP'/g' ansible/group_vars/all

	sed -i -e 's/ga_srvc_ip:.*/ga_srvc_ip: '$SDE_SRVC_IP'/g' ansible/group_vars/all


	sed -i -e 's/regular_system_user:.*/regular_system_user: '$REGULAR_SYSTEM_USER'/g' ansible/group_vars/all

	sed -i -e 's/lab_stack:.*/lab_stack: "yes"/g' ansible/group_vars/all

	sed -i -e 's/packages_server:.*/packages_server: \"'$SVAUTO_MAIN_HOST'\"/g' ansible/group_vars/all

	sed -i -e 's/license_server:.*/license_server: \"'$LICENSE_SERVER'\"/g' ansible/group_vars/all

	echo "### Adding MDM information ###" >> ansible/group_vars/all
        echo "mdmQMGroup:" >> ansible/group_vars/all
	echo "    - { name: \"NoQuota\", default: \"NoQuota1\" }" >> ansible/group_vars/all
	echo "    - { name: \"Basic\", default: \"Basic1\" }" >> ansible/group_vars/all
        echo "mdmQM:" >> ansible/group_vars/all
        echo "  - wheel:" >> ansible/group_vars/all
        echo "    name: \"Internet\"" >> ansible/group_vars/all
        echo "    sharedQuota: \"100GB\"" >> ansible/group_vars/all
        echo "    reportThreshold: \"25%,50%,75%,100%\"" >> ansible/group_vars/all
        echo "    rollover: \"1\"" >> ansible/group_vars/all
        echo "    plan: " >> ansible/group_vars/all
        echo "    - { name: \"NoQuota1\", limit: \"1B\", event_thresholds: [\"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic1\", limit: \"1GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic2\", limit: \"2GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic3\", limit: \"3GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "  - wheel:" >> ansible/group_vars/all
        echo "    name: \"Intranet\"" >> ansible/group_vars/all
        echo "    sharedQuota: \"1000GB\"" >> ansible/group_vars/all
        echo "    reportThreshold: \"25%,50%,75%,100%\"" >> ansible/group_vars/all
        echo "    rollover: \"1\"" >> ansible/group_vars/all
        echo "    plan: " >> ansible/group_vars/all
        echo "    - { name: \"NoQuota1\", limit: \"1B\", event_thresholds: [\"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic1\", limit: \"10GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic2\", limit: \"20GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic3\", limit: \"30GB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "  - wheel:" >> ansible/group_vars/all
        echo "    name: \"Roaming\"" >> ansible/group_vars/all
        echo "    sharedQuota: \"10GB\"" >> ansible/group_vars/all
        echo "    reportThreshold: \"25%,50%,75%,100%\"" >> ansible/group_vars/all
        echo "    rollover: \"1\"" >> ansible/group_vars/all
        echo "    plan: " >> ansible/group_vars/all
        echo "    - { name: \"NoQuota1\", limit: \"1B\", event_thresholds: [\"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic1\", limit: \"100MB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "    - { name: \"Basic2\", limit: \"200MB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
	echo "    - { name: \"Basic3\", limit: \"300MB\", event_thresholds: [\"25\", \"50\", \"75\", \"100\"]} " >> ansible/group_vars/all
        echo "" >> ansible/group_vars/all


	git checkout ansible/hosts


	echo
	echo "Configuring hosts..."

	if [ "$FREEBSD_PTS" == "yes" ]
	then
		echo
		echo "FreeBSD PTS detected, preparing Ansible's group_vars/all & hosts files..."

		sed -i -e 's/base_os:.*/base_os: freebsd8/g' ansible/group_vars/all
		sed -i -e 's/deploy_pts_freebsd_pkgs:.*/deploy_pts_freebsd_pkgs: yes/g' ansible/group_vars/all
		sed -i -e 's/^#FREEBSD_PTS_IP/'$PTS_FQDN'/g' ansible/hosts
	else
		sed -i -e 's/^#PTS_IP/'$PTS_FQDN'/g' ansible/hosts
	fi
	sed -i -e 's/^#SDE_IP/'$SDE_FQDN'/g' ansible/hosts
	sed -i -e 's/^#SPB_IP/'$SPB_FQDN'/g' ansible/hosts
#	sed -i -e 's/^#CSD_IP/'$CSD_FQDN'/g' ansible/hosts


fi


if [ "$DRY_RUN" == "yes" ]
then

	echo
	echo "Not running Ansible! Just preparing the environment variables..."

else

	BUILD_RAND=$(openssl rand -hex 4)


	if [ "$DEPLOYMENT_MODE" == "yes" ]
	then
		EXTRA_VARS="deployment_mode=yes"
	fi


	case "$CLOUD_SERVICES_MODE" in

		default)
			echo
			echo "Cloud Services mode set to: \"default\"."

			EXTRA_VARS="$EXTRA_VARS setup_sub_option=default"
			;;

		mdm)
			echo
			echo "Cloud Services mode set to: \"mdm\"."

			EXTRA_VARS="$EXTRA_VARS setup_sub_option=mdm"
			;;

	esac


	if [ "$OPERATION" == "sandvine" ]
	then

		EXTRA_VARS="$EXTRA_VARS setup_mode=sandvine"


		cd ansible/


		if [ "$CONFIG_ONLY_MODE" == "yes" ]
		then

			echo
			echo "Configuring Sandvine Platform with Ansible..."


			PLAYBOOK_FILE="tmp/sandvine-auto-config-"$BUILD_RAND".yml"

			echo
			echo "Creating Ansible Playbook: \"$PLAYBOOK_FILE\"."

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
				--roles=sandvine-auto-config > $PLAYBOOK_FILE

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
				--roles=sandvine-auto-config >> $PLAYBOOK_FILE

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
				--roles=sandvine-auto-config >> $PLAYBOOK_FILE


                        echo
                        echo "Running Ansible:"
                        echo
                        echo "ansible-playbook $PLAYBOOK_FILE --extra-vars \"$EXTRA_VARS\""
                        echo

			ansible-playbook $PLAYBOOK_FILE --extra-vars "$EXTRA_VARS"

		else

			echo
			echo "Deploying Sandvine's RPM packages with Ansible..."


			PLAYBOOK_FILE="tmp/site-sandvine-"$BUILD_RAND".yml"

			echo
			echo "Creating Ansible Playbook: \"$PLAYBOOK_FILE\"."

			if [ "$DEPLOYMENT_MODE" == "yes" ]
			then

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
					--roles=bootstrap,svpts,sandvine-auto-config,post-cleanup,power-cycle > $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
					--roles=bootstrap,svsde,sandvine-auto-config,post-cleanup,power-cycle >> $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
					--roles=bootstrap,svspb,sandvine-auto-config,post-cleanup,power-cycle >> $PLAYBOOK_FILE

			else

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
					--roles=bootstrap,svpts,sandvine-auto-config,post-cleanup > $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
					--roles=bootstrap,svsde,sandvine-auto-config,post-cleanup >> $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
					--roles=bootstrap,svspb,sandvine-auto-config,post-cleanup >> $PLAYBOOK_FILE

			fi


                        echo
                        echo "Running Ansible:"
                        echo
                        echo "ansible-playbook $PLAYBOOK_FILE --extra-vars \"$EXTRA_VARS\""
                        echo

			ansible-playbook $PLAYBOOK_FILE --extra-vars "$EXTRA_VARS"

		fi

	fi


	if [ "$OPERATION" == "cloud-services" ]
	then

		EXTRA_VARS="$EXTRA_VARS setup_mode=cloud-services"


		cd ansible/


		if [ "$CONFIG_ONLY_MODE" == "yes" ]
		then

			echo
			echo "Configuring Sandvine Platform and Cloud Services with Ansible..."


			PLAYBOOK_FILE="tmp/sandvine-auto-config-"$BUILD_RAND".yml"

			echo
			echo "Creating Ansible Playbook: \"$PLAYBOOK_FILE\"."

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
				--roles=sandvine-auto-config > $PLAYBOOK_FILE

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
				--roles=sandvine-auto-config >> $PLAYBOOK_FILE

			ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
				--roles=sandvine-auto-config >> $PLAYBOOK_FILE


                        echo
                        echo "Running Ansible:"
                        echo
                        echo "ansible-playbook $PLAYBOOK_FILE --extra-vars \"$EXTRA_VARS\""
                        echo

			ansible-playbook $PLAYBOOK_FILE --extra-vars "$EXTRA_VARS"

		else

			echo
			echo "Deploying Sandvine's RPM Packages plus Cloud Services with Ansible..."


			PLAYBOOK_FILE="tmp/site-cloudservices-"$BUILD_RAND".yml"

			echo
			echo "Creating Ansible Playbook: \"$PLAYBOOK_FILE\"."

			if [ "$DEPLOYMENT_MODE" == "yes" ]
			then

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
					--roles=bootstrap,svpts,svusagemanagementpts,svcs-svpts,sandvine-auto-config,post-cleanup,power-cycle > $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
					--roles=bootstrap,svsde,svusagemanagement,svsubscribermapping,svcs-svsde,svcs,sandvine-auto-config,post-cleanup,power-cycle >> $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
					--roles=bootstrap,svspb,svreports,svcs-svspb,sandvine-auto-config,post-cleanup,power-cycle >> $PLAYBOOK_FILE

			else

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svpts-servers \
					--roles=bootstrap,svpts,svusagemanagementpts,svcs-svpts,sandvine-auto-config,post-cleanup > $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svsde-servers \
					--roles=bootstrap,svsde,svusagemanagement,svsubscribermapping,svcs-svsde,svcs,sandvine-auto-config,post-cleanup >> $PLAYBOOK_FILE

				ansible_playbook_builder --ansible-remote-user=\"{{\ regular_system_user\ }}\" --ansible-hosts=svspb-servers \
					--roles=bootstrap,svspb,svreports,svcs-svspb,sandvine-auto-config,post-cleanup >> $PLAYBOOK_FILE

			fi


			echo
			echo "Running Ansible:"
			echo
			echo "ansible-playbook $PLAYBOOK_FILE --extra-vars \"$EXTRA_VARS\""
			echo

			ansible-playbook $PLAYBOOK_FILE --extra-vars "$EXTRA_VARS"

		fi

	fi

fi


if [ ! "$LABIFY" == "yes" ]
then

	echo
	echo "If no errors reported by Ansible, then, well done!"
	echo
	echo "Your brand new Sandvine's Stack is reachable through SSH:"
	echo
	echo "ssh sandvine@$PTS_FLOAT # PTS"
	echo "ssh sandvine@$SDE_FLOAT # SDE"
	echo "ssh sandvine@$SPB_FLOAT # SPB"
#	echo "ssh sandvine@$CSD_FLOAT # CSD"
	echo

fi
