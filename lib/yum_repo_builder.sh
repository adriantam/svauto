#! /bin/bash

yum_repo_builder()
{

	#
	# PTS stuff
	#

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svpts --version=7.30.0202 --latest
	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svpts --version=7.30.0035 --latest

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svprotocols --version=16.03.2121 --latest
	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svprotocols --version=16.03.2121 --latest

	# Usage Management

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svusagemanagementpts --version=5.20.0050 --latest
	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svusagemanagementpts --version=5.20.0050 --latest

	# Experimental

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svpts --version=7.40.0019 --latest-of-serie
	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svpts --version=7.40.0019 --latest-of-serie


	#
	# SDE stuff
	#

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsde --version=7.45.0087 --latest

	# Usage Management

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svusagemanagement --version=5.20.0050 --latest

	# Subscriber Mapping

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsubscribermapping --version=7.45.0003 --latest


	# Experimental

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svsde --version=7.45.0087 --latest
	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svsde --version=7.50.0019 --latest-of-serie

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsde --version=7.45.0087 --latest-of-serie
	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsde --version=7.50.0019 --latest-of-serie

	# Usage Management

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=svusagemanagement --version=5.20.0050 --latest

	# Subscriber Mapping

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsubscribermapping --version=7.45.0003 --latest-of-serie
#	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svsubscribermapping --version=7.45.0003 --latest-of-serie

	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=subscriber_mapping --version=7.45-0003 --latest
#	./yum-repo-builder.sh --release=dev --base-os=centos72 --product=subscriber_mapping --version=7.45-0003 --latest-of-serie


	#
	# SPB stuff
	#

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svspb --version=6.60.0530 --latest

	# NDS

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svreports --version=6.65.0005 --latest


	# Experimental

	./yum-repo-builder.sh --release=dev --base-os=centos68 --product=svspb --version=7.00.0032 --latest-of-serie


}
