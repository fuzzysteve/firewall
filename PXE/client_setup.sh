#!/bin/bash


usage () {
        echo
        echo "Usage: client_setup.sh <hostname> <MAC Address>"
        echo "Examples: "
        echo "          > client_setup.sh fw45-customer-ny4  00:50:56:aa:62:21"
        echo
}

IPASERVER=10.70.70.254

LOCATION=$(echo $1 | awk -F "-" '{print $3}')
ME=$(hostname -a | awk -F "-" '{print $3}')
if [ $ME != $LOCATION ];
then
  echo "hostname incorrect for this site: NY4 "
  echo
  usage
  exit
fi

CCOUNT=$(echo $2 | wc -m)
WCOUNT=$(echo $2 | tr : " " | wc -w)
if [ $CCOUNT -ne 18 -o $WCOUNT -ne 6]
then
  echo "MAC Address in incorrect format"
  echo
  usage
  exit
fi

MAC=$2
PXEMAC=$(echo $MAC | tr : -)
cat > /var/lib/tftpboot/pxelinux.cfg/$PXEMAC <<END
default 1
prompt 0
timeout 300
ONTIMEOUT local

menu title ########## PXE Boot Menu ##########

label 1
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=ftp://$IPASERVER/pub ks=ftp://$IPASERVER/pub/$MAC.cfg devfs=nomount
END

cat > /var/ftp/pub/$MAC.cfg <<END
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use FTP installation media
url --url="ftp://$IPASERVER/pub/"
# Root password
rootpw --plaintext VDIware123
# System authorization information
auth useshadow passalgo=sha512
# Use graphical install
graphical
firstboot disable
# System keyboard
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US
# SELinux configuration
selinux enable
# Installation logging level
logging level=info
# System timezone
timezone America/Chicago
# System bootloader configuration
bootloader location=mbr
clearpart --all --initlabel
autopart --type lvm --fstype xfs --nohome
reboot
%packages
@^minimal
@core
%end

%post --log=/root/post.log

wget ftp://$IPASERVER/pub/VMwareTools-10.2.5-8068406.tar.gz
tar zxf VMwareTools-10.2.5-8068406.tar.gz
cd vmware-tools-distrib
./vmware-install.pl -d -f

yum install git
git clone -b beeks https://github.com/bulax41/firewall
cd firewall
./setup $1

%end


%addon com_redhat_kdump --disable --reserve-mb='auto'
%end
END