#!/usr/bin/env bash

# ####################################################################
# anon-service.sh
# version 2.4
# 
# Transparent proxy through Tor and optionally DNSCrypt with  
# Anonymized-DNS feature enabled.
#
# Copyright (C) 2020-2024 Bit4mind
#
# GNU GENERAL PUBLIC LICENSE
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# #####################################################################

export root=/home/anon-service
owner=anon-service
version="2.4"
repo=/etc/apt/sources.list.d/tor.list
## DNSCrypt-proxy release
dnscrel="2.1.5"
## If necessary, change the path according to your system
export netman=/etc/NetworkManager/NetworkManager.conf
tor=/etc/tor/torrc
unbound=/etc/unbound/unbound.conf

##
##  Interactive menu
##
_menu(){
clear
printf '%s\n' "              ▄▄▄      ███▄    █ ▒█████   ███▄    █          "
printf '%s\n' "             ▒████▄    ██ ▀█   █▒██▒  ██▒ ██ ▀█   █          "
printf '%s\n' "             ▒██  ▀█▄ ▓██  ▀█ ██▒██░  ██▒▓██  ▀█ ██▒         "
printf '%s\n' "             ░██▄▄▄▄██▓██▒  ▐▌██▒██   ██░▓██▒  ▐▌██▒         "
printf '%s\n' "              ▓█   ▓██▒██░   ▓██░ ████▓▒░▒██░   ▓██░         "
printf '%s\n' "          ██████ ▓█████  ██▀███░  ██▒ ░ █▓ ██▓ ▄████▄ ▓█████ "
printf '%s\n' "        ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓██▒▒██▀ ▀█ ▓█   ▀ "
printf '%s\n' "        ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██▒▒▓█    ▄▒███   "
printf '%s\n' "          ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░░██░▒▓▓▄ ▄██▒▓█  ▄ "
printf '%s\n' "        ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░██░▒ ▓███▀ ░▒████▒"
printf '%s\n' "              ░           ░           ░       ░ by bit4mind  "
echo "";
printf '%s\n' "   0.  Check and download dependencies"
printf '%s\n' "   1.  Choose and configure transparent proxy type"
printf '%s\n' "   2.  Start/Restart service (restart will change your IP address)"
printf '%s\n' "   3.  Execute all tasks above"
printf '%s\n' "   4.  Exit this menu"
printf '%s\n' "   5.  Display status service"
printf '%s\n' "   6.  Enable service to start automatically at boot"
printf '%s\n' "   7.  Stop service without removing files and setting"
printf '%s\n' "   8.  Exit removing service files and settings from system"
printf '%s\n' "   9.  Edit configuration files"
printf '%s\n' "   10. Install this script"
echo -en      "   11. View log                                          \033[1;34mChoose:\033[0m ";
read -r task
case "$task" in  
	0)
		_checkX
		_download
		_menu
		;;
	1)
		_checkX
		_configure
		_menu
		;;
	2)
		start_service
		_menu
		;;
	3)
		_download
		_configure
		start_service
		_menu
		;;
	4)
		if (hash wmctrl) 2>/dev/null; then
			wmctrl -c :ACTIVE:
			exit 0
		else
			echo "";
			exit 0
		fi
		;;
	5)
		checking_service
		sleep 7
		_menu
		;;
	6)
		permanent_service
		exit 0
		;;
	7)
		if [ -f "cpath" ]; then
			mv cpath $root/ > /dev/null 2>&1
		fi
		shutdown_service
		_menu
		;;
	8)
		_cleanall
		;;
	9)
		_checkX
		_editor
		_menu
		;;
	10)	
		install_service
		sleep 7
		_menu
		;;
	11)
		_checkX
		_vlog
		_menu
		;;
	*)
		echo "";
		echo "==> Are you serious?"
		sleep 3
		_menu
esac
}
##
##  Checking dependencies and downloading upgraded services
##
_download(){
if [ -e "menu" ]; then
	clear 
fi
echo "   #######################################################";
echo "   #                  ANON-SERVICE SETUP                 #";
echo "   #######################################################";
if [ -s "$root" ]; then
	echo "";
	echo "==> Please, firstly remove all files and settings via dedicated option!";
	sleep 7
	if [ -e "menu" ]; then
	_menu
	return 1
	else 
	echo "";
	exit 1
	fi
fi
### Checking for network connection
echo "";
echo "==> Checking for internet connection"
rm conn.txt > /dev/null 2>&1
ping -c1 opendns.com > conn.txt 2>&1
if ( ! grep -q "icmp_seq=1" conn.txt ); then
	rm conn.txt > /dev/null 2>&1
	echo "==> Please connect to a network!";
	sleep 5
	if [ -e "menu" ]; then
		_menu
		return 1
	else
		echo ""; 
		exit 1
	fi   
fi
echo "==> Checking dependencies and preparing the system"
rm -rf $root > /dev/null 2>&1
adduser -q --disabled-password --gecos "" $owner > /dev/null 2>&1
usermod -u 888 $owner > /dev/null 2>&1
mv cpath $root > /dev/null 2>&1
mkdir -p $root/temp
chmod -R 777 $root/temp
apt-get update > $root/temp/apt.log
#
if [[ ! -e "menu" ]] || [[ ! -e "$(cat $root/cpath)/temp/menu" ]]; then
	apt-get install -y curl wget psmisc nano apt-transport-https unbound net-tools ifupdown > /dev/null
else
	apt-get install -y curl wget xterm psmisc wmctrl apt-transport-https net-tools unbound > /dev/null
fi
sleep 1
if [ -e tor_option1 ]; then
	install_tor_project
elif [ -e tor_option2 ]; then
	rm $repo  > /dev/null 2>&1
	apt-get update > /dev/null
	echo "==> Installing Tor";
	apt-get install -y tor > /dev/null 2>&1
elif [ -e tor_option3 ]; then
	echo "==> Tor already installed...";
	sleep 2
	if hash tor 2>/dev/null; then
	touch $root/installed
	else
	echo "==> Sorry! The script cannot recognize your Tor package.";
	echo "";
	exit 1
	fi
else
	echo "==> Which version of Tor do you prefer to use?";
	echo " ";
	echo "      1.Tor Project repository";
	echo "      2.Official repository";
	echo "      3.I already have tor installed";
	echo " "
	echo -n  " Choose: ";
	read -r choose
	echo "";
	case "$choose" in
		1)
			install_tor_project
			;;
		2)
			rm $repo  > /dev/null 2>&1
			apt-get update > /dev/null
			echo "==> Installing Tor";
			apt-get install -y tor > /dev/null 2>&1
			;;
		3)
			echo "==> OK!";
			sleep 2
			if hash tor 2>/dev/null; then
				touch $root/installed
			else
				echo "==> Sorry! The script cannot recognize your Tor package.";
				sleep 3
				_cquit
			fi
			;;
		*)
			echo "==> Are you serious?";
			sleep 5
			_cquit
	esac
fi
#
touch $root/temp/arch.txt > /dev/null
uname -a > $root/temp/arch.txt
if ( grep -Fq "x86_64" $root/temp/arch.txt ); then
	cd $root/temp/
	echo "==> Downloading dnscrypt-proxy";
   	wget -q https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/$dnscrel/dnscrypt-proxy-linux_x86_64-$dnscrel.tar.gz
else
   	cd $root/temp/
	echo "==> Downloading dnscrypt-proxy";
  	wget -q https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/$dnscrel/dnscrypt-proxy-linux_i386-$dnscrel.tar.gz
fi
tar -xf dnscrypt-proxy-linux_*.tar.gz
cp linux-*/dnscrypt-proxy $root
cp linux-*/example-dnscrypt-proxy.toml $root/dnscrypt-proxy.toml.bak
cp linux-*/localhost.pem $root
rm -rf $root/temp > /dev/null 2>&1
cd $root
rm *.md > /dev/null 2>&1
rm *.md* > /dev/null 2>&1
echo "==> Downloading public DNS resolvers list";
sleep 1
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/public-resolvers.md > /dev/null 2>&1
echo "==> Downloading anonymized DNS relays list";
sleep 1
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/relays.md > /dev/null 2>&1
### Backup nm and resolv.conf (if exist)
if [ ! -s "$netman.bak" ]; then
	if [ -s "$netman" ]; then
		cp $netman $netman.bak
	fi
fi
if [ ! -s "/etc/resolv.conf.bak" ]; then
	if [ -s "etc/resolv.conf" ]; then
		cp etc/resolv.conf etc/resolv.conf.bak > /dev/null 2>&1
	fi
fi
cd $(cat $root/cpath)
}
##
## INSTALLING TOR PROJECT
##
install_tor_project(){
touch $root/temp/distribution.txt
### Tor Project supported distro
cd $root/temp/
curl -L -O https://deb.torproject.org/torproject.org/dists > /dev/null 2>&1
cat dists | sed -e 's/\(^.*\/">\)\(.*\)\(\/<\/a>.*$\)/\2/; /^stable/d; /^oldstable/d; /^oldoldstable/d; /^unstable/d; /^testing/d; /^proposed-updates/d; /^tor-/d' | awk '!/</' > distribution.txt
touch $root/temp/os.txt
for target in $(cat $root/temp/distribution.txt); do
	if ( grep -Fq "$target" $root/temp/apt.log ); then
	echo $target > $root/temp/os.txt
	fi
done
os=$(cat $root/temp/os.txt | sed -e 's/^[ \t]*//')
if [[ "$os" == " " ]]; then
	echo "";
	echo "==> Sorry! The script can't find the correct repository.";
	echo "==> Please, re-run the script and choose another option.";
	echo "";
	exit 1
fi
if curl --head --silent --fail https://deb.torproject.org/torproject.org/dists/$os/main/binary-i386/ > /dev/null 2>&1;
	then
	echo "==> Enabling $os repository";
	sleep 1
	rm $repo > /dev/null 2>&1
	rm $repo* > /dev/null 2>&1
	touch $repo
	echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
	echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
else
	echo "==> Enabling $os repository"
	rm $repo > /dev/null 2>&1
	rm $repo* > /dev/null 2>&1
	touch $repo
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
	echo "deb-src [arch=amd64 signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
fi
echo "==> Downloading and importing signing key";
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor 2>/dev/null | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null 2>&1
sleep 1
### Fixing gnupg ownership 
gpgconf --kill dirmngr
chown -R $USER ~/.gnupg > /dev/null 2>&1
cd
echo "==> Checking repository"; 
apt-get update > $root/temp/apt.log 
sleep 1
if ( grep "torproject.org $os Release" $root/temp/apt.log > /dev/null 2>&1 ); then
	echo "";
   	echo "==> Sorry! The script can't find the correct repository.";
  	echo "==> Please, try to enter the correct codename of your OS.";
	echo "";
   	echo -n "==> Codename (for example: buster): ";
   	read -r codename
	echo ""; 
   	rm $repo
   	touch $repo
   	echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   	echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   	apt-get update > /dev/null
   	apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
   	echo "";
else
   	echo "==> Installing Tor";
   	apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
fi
}
##
## CONFIGURING SERVICES
##
_configure(){
if [ -e "menu" ]; then
	clear 
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
	clear 
	fi
fi
echo "   #######################################################";
echo "   #              ANON-SERVICE CONFIGURATION             #";
echo "   #######################################################";
if [ -f "cpath" ]; then
	mv cpath $root/ > /dev/null 2>&1
fi
if [ ! -s "$root/dnscrypt-proxy.toml.bak" ]; then
	echo "";
	echo "==> Sorry! Your system is not ready to complete this action.";
	echo "==> Please, check if you have installed the necessary files.";
	sleep 7
	if [ -e "menu" ]; then
	_menu
	return 1
	else 
	echo "";
	exit 1
	fi
fi
### Disable tor and unbound starting at boot time
systemctl disable unbound > /dev/null 2>&1
systemctl disable tor > /dev/null 2>&1
#####
if [ -e "configure_option1" ]; then 
	rm $root/stp-service > /dev/null 2>&1
	touch $root/stp-service
	echo "1" > $root/stp-service
	echo "";
elif [ -e "configure_option2" ]; then 
	rm $root/stp-service > /dev/null 2>&1
	touch $root/stp-service
	echo "0" > $root/stp-service
	_dnscryptconf
elif [ -e "$(cat $root/cpath)/temp/menu" ] || [ -e "$(cat $root/cpath)/temp/configure" ]; then
	echo " ";
	echo "==> Which type of transparent proxy do you prefer to use?";
	echo " ";
	echo "      1. Standard transparent proxy";
	echo "      2. Trasparent proxy with DNSCrypt";
	echo " ";
	echo -n  " Choose: ";
	read -r choose
	case "$choose" in 
	1)
		rm $root/stp-service > /dev/null 2>&1
		touch $root/stp-service
		echo "1" > $root/stp-service
		echo "";
		;;
	2)
		rm $root/stp-service > /dev/null 2>&1
		touch $root/stp-service
		echo "0" > $root/stp-service
		echo ""; 
		_dnscryptconf
		;;
	*)
		echo "";
		echo "==> Are you serious?"
		sleep 5
		_cconfig
		echo "";

	esac
else
	echo "";
	echo "==> Sorry! Something went wrong...Please, report this issue to the project";
	echo "";
	exit 1
fi
netiface
echo "==> Configuring Tor";
sleep 1
### Configuring Tor
cp $tor $root/torrc
echo "Log notice file $root/notices.log" >> $root/torrc
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> $root/torrc
echo "AutomapHostsOnResolve 1" >> $root/torrc
echo "TransPort 9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort" >> $root/torrc
echo "DNSPort 5353" >> $root/torrc
### Disabling unwanted services and configure Network-Manager (if exists)
echo "==> Configuring system";
echo "";
sleep 1
if [ -s $netman ]; then
	rm $root/NetworkManager.conf.temp > /dev/null 2>&1
	cp $netman.bak $root/NetworkManager.conf.temp
	cd $root
	chown $USER:$USER NetworkManager.conf.temp
	sed -i 's/^dns=dnsmasq/#&/' NetworkManager.conf.temp
	sed -i '/\[main\]/a dns=none' NetworkManager.conf.temp
	sed '/dns=none/a rc-manager=unmanaged' NetworkManager.conf.temp > NetworkManager.conf 
fi
rm $root/iptables_rules.sh > /dev/null 2>&1
touch $root/iptables_rules.sh
### Configuring basic iptables rules
### Reference: https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy
echo "#################################################################" > $root/iptables_rules.sh
echo "#                        IPTABLES RULES                         #" >> $root/iptables_rules.sh
echo "#################################################################" >> $root/iptables_rules.sh
echo "#!/bin/bash" >> $root/iptables_rules.sh
# Destinations you don't want routed through Tor
echo "_non_tor=\"127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16\"" >> $root/iptables_rules.sh
echo "_user_uid=\"888\" ## Tor is the only process that runs as this user" >> $root/iptables_rules.sh
# Tor's VirtualAddrNetworkIPv4
echo "_virt_addr=\"10.192.0.0/10\"" >> $root/iptables_rules.sh
# Tor's TransPort
echo "_trans_port=\"9040\"" >> $root/iptables_rules.sh
# Other IANA reserved blocks (These are not processed by tor and dropped by default)
echo "_resv_iana=\"0.0.0.0/8 100.64.0.0/10 169.254.0.0/16 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255/32\"" >> $root/iptables_rules.sh
echo "_iface=\$(cat \$root/netiface.txt)" >> $root/iptables_rules.sh
echo "iptables -F" >> $root/iptables_rules.sh
echo "iptables -t nat -F" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -d \$_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
if ( grep -Fq "1" $root/stp-service ); then
	echo "iptables -t nat -A OUTPUT -d 127.0.0.1/32 -p udp -m udp --dport 53 -j REDIRECT --to-ports 5353" >> $root/iptables_rules.sh
else
	echo "iptables -t nat -A OUTPUT -d 127.0.0.1/32 -p udp -m udp --dport 53 -j REDIRECT --to-ports 53" >> $root/iptables_rules.sh
fi
echo "iptables -t nat -A OUTPUT -m owner --uid-owner \$_user_uid -j RETURN" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -o lo -j RETURN" >> $root/iptables_rules.sh
echo "for _lan in \$_non_tor; do" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -d \$_lan -j RETURN" >> $root/iptables_rules.sh
echo "done" >> $root/iptables_rules.sh
echo "sleep 5" >> $root/iptables_rules.sh
echo "for _iana in \$_resv_iana; do" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -d \$_iana -j RETURN" >> $root/iptables_rules.sh
echo "done" >> $root/iptables_rules.sh
echo "sleep 7" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> $root/iptables_rules.sh
echo "## Uncomment the next line to grant yourself ssh access from remote machines before the DROP." >> $root/iptables_rules.sh
echo "#iptables -A INPUT -i \$_iface -p tcp --dport 22 -m state --state NEW -j ACCEPT" >> $root/iptables_rules.sh
echo "iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT" >> $root/iptables_rules.sh
echo "iptables -A INPUT -i lo -j ACCEPT" >> $root/iptables_rules.sh
echo "# Allow INPUT from lan hosts in \$_non_tor" >> $root/iptables_rules.sh
echo "## Uncomment the next 4 lines to enable" >> $root/iptables_rules.sh
echo "#for _lan in \$_non_tor; do" >> $root/iptables_rules.sh
echo "# iptables -A INPUT -s \$_lan -j ACCEPT" >> $root/iptables_rules.sh
echo "#done" >> $root/iptables_rules.sh
echo "#sleep 2" >> $root/iptables_rules.sh
echo "## Uncomment the next line to enable logging" >> $root/iptables_rules.sh
echo "#iptables -A INPUT -j LOG --log-prefix "Dropped INPUT packet: " --log-level 7 --log-uid" >> $root/iptables_rules.sh
echo "iptables -A INPUT -j DROP" >> $root/iptables_rules.sh
echo "iptables -A FORWARD -j DROP" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -m state --state INVALID -j DROP" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -o \$_iface -m owner --uid-owner \$_user_uid -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j ACCEPT" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -d 127.0.0.1/32 -o lo -j ACCEPT" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -d 127.0.0.1/32 -p tcp -m tcp --dport \$_trans_port --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "## Uncomment the next 4 lines to Allow OUTPUT to lan hosts" >> $root/iptables_rules.sh
echo "#for _lan in \$_non_tor; do" >> $root/iptables_rules.sh
echo "#iptables -A INPUT -s \$_lan -j ACCEPT" >> $root/iptables_rules.sh
echo "#done" >> $root/iptables_rules.sh
echo "#sleep 5" >> $root/iptables_rules.sh
echo "## Uncomment the next line to enable logging" >> $root/iptables_rules.sh
echo "#iptables -A OUTPUT -j LOG --log-prefix "Dropped OUTPUT packet: " --log-level 7 --log-uid" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -j DROP" >> $root/iptables_rules.sh
echo "iptables -P FORWARD DROP" >> $root/iptables_rules.sh
echo "iptables -P INPUT DROP" >> $root/iptables_rules.sh
echo "iptables -P OUTPUT DROP" >> $root/iptables_rules.sh
echo "ip6tables -P INPUT DROP"  >> $root/iptables_rules.sh
echo "ip6tables -P FORWARD DROP" >> $root/iptables_rules.sh
echo "ip6tables -P OUTPUT DROP" >> $root/iptables_rules.sh
chmod +x $root/iptables_rules.sh
cd $(cat $root/cpath)
}
##
## CONFIGURING DNSCRYPT
##
_dnscryptconf(){
### Configuring dnscrypt_proxy
rm $root/dnscrypt-proxy.toml > /dev/null 2>&1
cp $root/dnscrypt-proxy.toml.bak $root/dnscrypt-proxy.toml
if [ -e "configure_option2" ]; then
	server1="$(cat server1)"
else	
	clear
	echo "==> Opening file contain public resolvers";
	sleep 2
	if [ -e "configure" ]; then
		echo "==> Type "q" to quit";
		sleep 3
		more $root/public-resolvers.md
	else
		xterm -ls -xrm 'XTerm*selectToClipboard: true' -T "Resolvers" -e "more $root/public-resolvers.md" &
		sleep 1
		clear
	fi
	echo "";
	echo "==> Please enter the name of the first resolver to use, only ipv4!";
	echo "";
	echo -n "    First server: ";
	read -r server1
fi
if ( ! grep "\<$server1\>" $root/public-resolvers.md > /dev/null ); then
	echo "";
	echo "==> First server not found! Please retry";
	killall xterm > /dev/null 2>&1
	sleep 3
	echo "";
	_dnscryptconf
	return 1
fi
if [ -e "configure_option2" ]; then
	server2="$(cat server2)"
else
	if [ -e "configure" ]; then
		clear
		echo "==> Type "q" to quit";
		sleep 3
		more $root/public-resolvers.md
	fi
	echo "";
	echo "==> Please enter the name of the second resolver to use, only ipv4!";
	echo "";	
	echo -n "    Second server: ";	
	read -r server2
	if ( ! grep "\<$server2\>" $root/public-resolvers.md > /dev/null ); then
		echo "";
		echo "==> Second server not found! Please retry";
		killall xterm > /dev/null 2>&1
		sleep 3
		echo "";
		_dnscryptconf
		return 1
	fi
fi
if [ -e "configure_option2" ]; then
	relay1="$(cat relay1)"
else
	clear
	echo "==> Opening file contain relays";
	sleep 2
	killall xterm > /dev/null 2>&1
	sleep 2
	echo "";
	echo "    ***************************************************************************";
	echo "==> Carefully choose relays/servers so that they are run by different entities!";
	echo "    ***************************************************************************";
	sleep 2
	echo "";
	if [ -e "configure" ]; then
		echo "==> Type "q" to quit";
		sleep 3
		more $root/relays.md
		else
		xterm -ls -xrm 'XTerm*selectToClipboard: true' -T "Relays" -e "more $root/relays.md" &
		sleep 1
		clear
	fi
	echo "";
	echo "==> Please enter the name of the first realy to use!";
	echo "";
	echo -n "    First relay for the first server: ";
	read -r relay1
	if ! grep "\<$relay1\>" $root/relays.md > /dev/null; then
		echo "";
		echo "==> First relay for the first server not found! Please retry";
		killall xterm > /dev/null 2>&1
		sleep 3
		echo "";
		_dnscryptconf
		return 1
	fi
fi
if [ -e "configure_option2" ]; then
	relay2="$(cat relay2)"
else
	if [ -e "configure" ]; then
		clear
		echo "==> Type "q" to quit";
		sleep 3
		more $root/relays.md
	fi
	echo "";
	echo "==> Please enter the name of the second relay to use!";
	echo "";
	echo -n "    Second relay for the first server: ";
	read -r relay2
	echo "";
	if ( ! grep "\<$relay2\>" $root/relays.md > /dev/null ); then
		echo "";
		echo "==> Second relay for the first server not found! Please retry";
		killall xterm > /dev/null 2>&1
		sleep 3
		echo "";
		_dnscryptconf
		return 1
	fi
fi
if [ -e "configure_option2" ]; then
	relay3="$(cat relay3)"
else
	if [ -e "configure" ]; then
		clear
		echo "==> Type "q" to quit";
		sleep 3
		more $root/relays.md
	fi
	echo "";
	echo "==> Please enter the name of the third resolver to use!";
	echo "";
	echo -n "    First relay for the second server: ";
	read -r relay3
	if ( ! grep "\<$relay3\>" $root/relays.md > /dev/null; ) then
		echo "";
		echo "==> First relay for the second server not found! Please retry";
		killall xterm > /dev/null 2>&1
		sleep 3
		echo "";
		_dnscryptconf
		return 1
	fi
fi
if [ -e "configure_option2" ]; then
	relay4="$(cat relay4)"
else
	if [ -e "configure" ]; then
		clear
		echo "==> Type "q" to quit";
		sleep 3
		more $root/relays.md
	fi
	echo "";
	echo "==> Please enter the name of the fourth resolver to use!";
	echo "";
	echo -n "    Second relay for the second server: ";
	read -r relay4
	if ( ! grep "\<$relay4\>" $root/relays.md > /dev/null ); then
		echo "";
		echo "==> Second relay for the second server not found! Please retry";
		killall xterm > /dev/null 2>&1
		sleep 3
		echo "";
		_dnscryptconf
		return 1
	fi
	clear
	echo "   #######################################################";
	echo "   #              ANON-SERVICE CONFIGURATION             #";
	echo "   #######################################################";
fi
killall xterm > /dev/null 2>&1
echo "";
echo "==> Configuring DNSCrypt";
sleep 1
sed -i "1iforce_tcp = true" $root/dnscrypt-proxy.toml
sed -i "2iserver_names = ['$server1', '$server2']" $root/dnscrypt-proxy.toml
#sed -i "3iproxy = 'socks5://127.0.0.1:9050'" $root/dnscrypt-proxy.toml
sed -i "s/127.0.0.1:53/127.0.0.1:10000/g; s/9.9.9.9/208.67.222.222/g; s/8.8.8.8/208.67.220.220/g; s/require_dnssec = false/require_dnssec = true/g; s/force_tcp = false/#force_tcp = false/g; s/\[anonymized_dns\]/\[anonymized_dns\]\nroutes = \[\n{ server_name='$server1', via=\[\'$relay1\', \'$relay2\'\] },\n{ server_name=\'$server2\', via=[\'$relay3\', \'$relay4\'] }\n\]/g; s/skip_incompatible = false/skip_incompatible = true/g" $root/dnscrypt-proxy.toml
### Configuring unbound
echo "==> Configuring Unbound";
sleep 1
unbound-anchor > /dev/null 2>&1
sleep 1
echo "server:" > $unbound
echo "tcp-upstream: yes" >> $unbound
echo "domain-insecure: \"onion\"" >> $unbound
echo "private-domain: \"onion\"" >> $unbound
echo "do-not-query-localhost: no" >> $unbound
echo "do-ip6: no " >> $unbound
echo "interface: 127.0.0.1@53" >> $unbound
echo "local-zone: \"onion.\" transparent" >> $unbound
echo "forward-zone:" >> $unbound
echo "    name: \"onion\"" >> $unbound
echo "    forward-addr: 127.0.0.1@5353" >> $unbound
echo "forward-zone:" >> $unbound
echo "   name: \".\"" >> $unbound
echo "   forward-addr: 127.0.0.1@10000" >> $unbound
sleep 1
}
##
## Starting services and configuring iptables
##
start_service(){
### Checking for required files
if [ -e "menu" ]; then
	clear 
fi
	if [[ -e $root/cpath ]]; then
		if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
			clear 
		fi
	fi
echo "   #######################################################";
echo "   #                ANON-SERVICE STARTER                 #";
echo "   #######################################################";
echo "";
if [ ! -s "$root/stp-service" ]; then
	echo "==> Sorry! Your system is not ready to start the service...";
	echo "==> Please, check if you have installed the necessary files.";
	sleep 7
	if [ -e "menu" ]; then
		_menu
		return 1
	else 
		echo "";
		exit 1
	fi
fi
if [ -f "cpath" ]; then
	mv cpath $root/
fi
if [ -s "/etc/network/if-up.d/anon-service" ]; then
	echo "==> Sorry! This menu option is not usable in permanent mode. Use";
	echo "==> command-line option or simply restart your connection instead!";
	sleep 7
	_cquit
fi
rm $root/running > /dev/null 2>&1
### Firewall flush
iptables -F
iptables -t nat -F
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain 
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
netiface
### Configure Network-Manager
cd $root
if [ -s $netman ]; then
	cp NetworkManager.conf $netman
	chown root:root $netman
fi
service resolvconf stop > /dev/null 2>&1
service dnsmasq stop > /dev/null 2>&1
service bind stop > /dev/null 2>&1
service systemd-resolved stop > /dev/null 2>&1
killall dnsmasq bind > /dev/null 2>&1
sleep 1
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
echo "==> Forcing nameserver to 127.0.0.1 in resolv.conf";
rm /etc/resolv.conf > /dev/null 2>&1
echo $'inameserver 127.0.0.1\E:x\n' | vi /etc/resolv.conf > /dev/null 2>&1
chattr +i /etc/resolv.conf > /dev/null 2>&1
sleep 1
cat /etc/resolv.conf | sed -e '/^$/d; /^#/d' > $root/dnsread
if [[ $(cat $root/dnsread) != "nameserver 127.0.0.1" ]]; then 
	echo "";
	echo "==> There is a problem with your DNS setting! Fix your /etc/resolv.conf";
	echo "==> by setting 127.0.0.1 as nameserver and try again."
	_cquit
fi
rm $root/dnsread > /dev/null 2>&1
echo "==> Restarting networking";
service network-manager restart > /dev/null 2>&1
service networking restart > /dev/null 2>&1
sleep 3
### Disable ipv6 
ipv6_status=$(cat /proc/sys/net/ipv6/conf/default/disable_ipv6)
if [ "$ipv6_status" == "0" ]; then
	echo "==> Disabling IPV6 protocol";
	sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
	sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null 2>&1
fi
sleep 2
chown -R $owner:$owner $root
## Restore original files automatically at shutdown
if ( ! pgrep -f "restoring_orig.sh " )  > /dev/null; then
	rm restoring_orig.sh > /dev/null 2>&1 
	touch restoring_orig.sh
	echo "#!/bin/bash" > restoring_orig.sh
	echo "restoring_script() {" >> restoring_orig.sh 
	echo "if [ ! -f /etc/network/if-up.d/anon-service ]; then" >> restoring_orig.sh
	echo "cp $netman.bak $netman > /dev/null 2>&1" >> restoring_orig.sh
	echo "chattr -i /etc/resolv.conf > /dev/null 2>&1" >> restoring_orig.sh
	echo "rm /etc/resolv.conf > /dev/null 2>&1" >> restoring_orig.sh
	echo "echo $'inameserver 1.1.1.1\E:x\n' | vi /etc/resolv.conf > /dev/null 2>&1" >> restoring_orig.sh
    echo "fi" >> restoring_orig.sh
	echo "rm $root/running > /dev/null 2>&1" >> restoring_orig.sh
	echo "exit" >> restoring_orig.sh
	echo "}" >> restoring_orig.sh
	echo "while :" >> restoring_orig.sh
	echo "do" >> restoring_orig.sh
	echo "trap restoring_script SIGINT SIGTERM" >> restoring_orig.sh
	echo "sleep 7" >> restoring_orig.sh
	echo "done" >> restoring_orig.sh
	chmod +x restoring_orig.sh
	if [[ ! -e "menu" ]] || [[ ! -e "$(cat $root/cpath)/temp/menu" ]]; then
		nohup ./restoring_orig.sh > /dev/null 2>&1 &
		echo "==> Automatic restore started"
		sleep 1
	else
		xterm -e nohup ./restoring_orig.sh
		echo "==> Automatic restore started"
		sleep 1
	fi
fi
echo "==> Starting anon-service";
sleep 1
## Start selected transparent proxy
active_service=$(cat $root/stp-service)
case $active_service in
	"0")
		nohup ./dnscrypt-proxy > /dev/null 2>&1 &
		sleep 1
		rm $root/notices.log > /dev/null 2>&1
		touch $root/notices.log
		chown anon-service:anon-service $root/notices.log
		nohup su - $owner -c "tor -f $root/torrc" > /dev/null 2>&1 &
		echo "==> Checking connection to Tor";
		SECONDS=0
		secs=30
		while (( SECONDS < secs )); do
			if ( grep -Fq "100%" $root/notices.log ); then 
				break
			fi
			sleep 1
		done
		cd $root
		./iptables_rules.sh
		sleep 2
		unbound &
		### Checking services
		if ( ! pgrep -x "tor" ) > /dev/null; then
			echo "==> Sorry! No connection to TOR...Please, report this issue to the project";
			sleep 7
			shutdown_service 
			exit 1
		fi
		if ( ! pgrep -x "dnscrypt-proxy" ) > /dev/null; then
			echo "==> Sorry! Dnscrypt-proxy isn't running...Please, report this issue to the project";
			sleep 7
			shutdown_service
			exit 1
		fi
		if ( ! pgrep -x "unbound" ) > /dev/null; then
			echo "==> Sorry! Unbound isn't running...Please, report this issue to the project";
			sleep 7
			shutdown_service
			exit 1
		else
			echo "==> Service started using Tor and DNSCrypt";
			echo "";
			touch $root/running
			sleep 5
		fi
		;;
	"1")
		rm $root/notices.log > /dev/null 2>&1
		touch $root/notices.log
		chown anon-service:anon-service $root/notices.log
		nohup su - $owner -c "tor -f $root/torrc" > /dev/null 2>&1 &
		echo "==> Checking connection to Tor";
		SECONDS=0
		secs=30
		while (( SECONDS < secs )); do
			if ( grep -Fq "100%" $root/notices.log ); then 
				break
			fi
			sleep 1
		done
		cd $root
		./iptables_rules.sh
		### Checking services
		if ( ! pgrep -x "tor" > /dev/null ); then
			echo "==> Sorry! No connection to TOR...Please, report this issue to the project";
			echo "";
			sleep 7
			shutdown_service
			exit 1
		else
			echo "==> Service started using Tor network";
			echo "";
			touch $root/running
			sleep 5
		fi
esac
cd $(cat $root/cpath)
}
##
## Edit configuration files
##
_editor(){
if [ -e "menu" ]; then
	clear 
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #              ANON-SERVICE CUSTOMIZATION             #";
echo "   #######################################################";
echo "";
if [ -f "cpath" ]; then
	mv cpath $root/ > /dev/null 2>&1
fi
if [ ! -s "$root/torrc" ]; then
	echo "==> Sorry! Your system is not ready to complete this action.";
	echo "==> Please, check if you have installed the necessary files.";
	sleep 7
	_menu
	return 1
else
	echo "";
fi
echo "==> What do you want to edit?";
echo "      1.torrc";
echo "      2.iptables rules";
echo " "
echo -n  " Choose: ";
read -r answer
echo "";
case "$answer" in 
	1)
		if  [[ ! -e "menu" ]] || [[ ! -e "$(cat $root/cpath)/temp/menu" ]]; then
			nano $root/torrc
			echo "==> Please restart the service to apply changes";
			echo "";
			exit 0
		else
			xterm -T "Torrc" -e "nano $root/torrc" > /dev/null 2>&1
			echo "==> Please restart the service to apply changes";
			sleep 7
			_menu
		fi
		;;
	2)
		if [ -s "/etc/network/if-up.d/anon-service" ]; then
			if  [[ ! -e "menu" ]] || [[ ! -e "$(cat $root/cpath)/temp/menu" ]]; then
				nano /etc/network/if-up.d/anon-service
				echo "==> Please restart via command-line option to apply changes!"; 
				echo "==> Otherwise simply restart your network connection.";
				echo "";
				exit 0
			else
				xterm -T "Editor" -e "nano /etc/network/if-up.d/anon-service" > /dev/null 2>&1
				echo "==> Please restart via command-line option to apply changes!"; 
				echo "==> Otherwise simply restart your network connection.";
				sleep 7
				_menu
			fi
		else 
			if  [[ ! -e "menu" ]] || [[ ! -e "$(cat $root/cpath)/temp/menu" ]]; then
				nano $root/iptables_rules.sh
				echo "==> Please restart the service to apply changes";
				echo "";
				exit 0
			else
				xterm -T "Editor" -e "nano $root/iptables_rules.sh" > /dev/null 2>&1
				echo "==> Please restart the service to apply changes";
				sleep 7
				_menu
			fi
		fi
		;;
	*)
		echo "==> Are you serious?"
		sleep 5
		_cquit
		;;
esac
}
##
## Install this script
##
install_service(){
if [ -e "menu" ]; then
	clear
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #             ANON-SERVICE MISCELLANEOUS              #";
echo "   #######################################################";
echo "";
if [ -e $root/cpath ]; then
	cd $(cat $root/cpath)
fi
if [ -f "/opt/anon-service/anon-service.sh" ]; then
	echo "==> Nothing to do here!"; 
	sleep 3
	if [ -e "menu" ]; then
		_menu
		return 1
	else
		echo "";
		exit 1
	fi
fi
mkdir -p /opt/anon-service > /dev/null 2>&1
rm /usr/bin/anon-service > /dev/null 2>&1
rm /opt/anon-service/anon-service.sh > /dev/null 2>&1
touch /opt/anon-service/anon-service.sh > /dev/null 2>&1
if [ -e "menu" ]; then
	cp ../$0 /opt/anon-service/anon-service.sh > /dev/null 2>&1
else 
	cp $0 /opt/anon-service/anon-service.sh > /dev/null 2>&1
fi
chmod +x /opt/anon-service/anon-service.sh
ln -s /opt/anon-service/anon-service.sh /usr/bin/anon-service
echo "==> Now you can run it simply typing \"sudo anon-service\"!";
echo "";
if [ -e $root/cpath ]; then
	cd $(cat $root/cpath)
fi
exit 0
}
##
## Discover network device
##
netiface(){
ifconfig | grep "RUNNING" | awk '{ print $1 '} | tr -d : | sed -e '/^lo/d; /^$/d' > $root/netiface.txt
sleep 1 
clines=$(wc -l "$root/netiface.txt" | awk '{ print $1 }')
if [[ "$clines" > "1" ]]; then
	echo " ";
	echo "==> Available network devices:";
	echo "";
	for dev in $(cat $root/netiface.txt); do
		echo "    $dev";
	done
	echo "";
	echo "==> Which network interface do you prefer to use?";
	echo " ";
	echo -n  " Choose: ";
	read -r netdevice
	echo "";
	if ( ! grep -Fq "$netdevice" $root/netiface.txt ); then
		echo "==> The selected device does not match! Please try again.";
		sleep 3
		_cquit
	else
		echo ${netdevice//[[:blank:]]/} > $root/netiface.txt
	fi
fi
}
##
## Detect if X runs
##
_checkX(){
if ( ! timeout 1s xset q &>/dev/null ); then
	echo " ";
	echo "==> No X server detected. Try to use command-line option instead." >&2
	echo "";
	sleep 5
	exit 1
fi
}
##
## Exit if error
##
_cquit(){
if [[ -e "menu" ]] || [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
	_menu
	return 1
else
	echo "";
	exit 1
fi
}
##
## Configure if error
##
_cconfig(){
if [[ -e "menu" ]] || [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
	_configure
	return 1
else 
	exit 1
fi
}
##
## Run at boot
##
permanent_service(){
if [ -e "menu" ]; then
	clear
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #             ANON-SERVICE MISCELLANEOUS              #";
echo "   #######################################################";
echo "";
if [ ! -f "$root/stp-service" ]; then
	echo "==> Sorry! Your system is not ready to start the service...";
	echo "==> Please, check if you have installed the necessary files!";
	sleep 7
	if [ -e "menu" ]; then
		_menu
		return 1
	else
		echo "";
		exit 1
	fi
fi
cd $root
cp NetworkManager.conf $netman > /dev/null 2>&1
chown root:root $netman > /dev/null 2>&1
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
touch /etc/network/if-up.d/anon-service
chattr -i /etc/resolv.conf > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
echo $'inameserver 127.0.0.1\E:x\n' | vi /etc/resolv.conf > /dev/null 2>&1
chattr +i /etc/resolv.conf > /dev/null 2>&1
echo "#!/bin/sh" > /etc/network/if-up.d/anon-service
echo "#################################################################" >> /etc/network/if-up.d/anon-service
echo "#                   DO NOT EDIT THIS SECTION                    #" >> /etc/network/if-up.d/anon-service
echo "#################################################################" >> /etc/network/if-up.d/anon-service
echo "root=/home/anon-service" >> /etc/network/if-up.d/anon-service
echo "owner=anon-service" >> /etc/network/if-up.d/anon-service
echo "rm $root/running > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "iptables -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -F" >> /etc/network/if-up.d/anon-service
echo "iptables --flush" >> /etc/network/if-up.d/anon-service
echo "iptables --table nat --flush" >> /etc/network/if-up.d/anon-service
echo "iptables --delete-chain" >> /etc/network/if-up.d/anon-service
echo "iptables --table nat --delete-chain" >> /etc/network/if-up.d/anon-service 
echo "iptables -P OUTPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -P INPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P FORWARD ACCEPT" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P OUTPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P INPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -P FORWARD ACCEPT" >> /etc/network/if-up.d/anon-service
echo "service dnsmasq stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service bind stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service resolvconf stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service systemd-resolved stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "killall dnsmasq bind > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "cd $root" >> /etc/network/if-up.d/anon-service
echo "service tor stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service dnscrypt-proxy stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service unbound stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "killall unbound tor dnscrypt-proxy > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "chown -R $owner:$owner $root" >> /etc/network/if-up.d/anon-service
echo "rm $root/notices.log > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "touch $root/notices.log" >> /etc/network/if-up.d/anon-service
echo "chown anon-service:anon-service $root/notices.log" >> /etc/network/if-up.d/anon-service
echo "nohup su - $owner -c \"tor -f $root/torrc\" > /dev/null 2>&1 &" >> /etc/network/if-up.d/anon-service
echo "while :" >> /etc/network/if-up.d/anon-service
echo "do" >> /etc/network/if-up.d/anon-service 
echo "if (grep -Fq \"100%\" $root/notices.log ); then" >> /etc/network/if-up.d/anon-service 
echo "break" >> /etc/network/if-up.d/anon-service
echo "else" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "fi" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
if ( grep -Fq "0" $root/stp-service ); then
	echo "nohup ./dnscrypt-proxy > /dev/null 2>&1 &" >> /etc/network/if-up.d/anon-service
	echo "sleep 1s" >> /etc/network/if-up.d/anon-service
fi
echo "#################################################################" >> /etc/network/if-up.d/anon-service
echo "#                        IPTABLES RULES                         #" >> /etc/network/if-up.d/anon-service
echo "#################################################################" >> /etc/network/if-up.d/anon-service
echo "_non_tor=\"127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16\"" >> /etc/network/if-up.d/anon-service
echo "_user_uid=\"888\"" >> /etc/network/if-up.d/anon-service
echo "_virt_addr=\"10.192.0.0/10\"" >> /etc/network/if-up.d/anon-service
echo "_trans_port=\"9040\"" >> /etc/network/if-up.d/anon-service
echo "_resv_iana=\"0.0.0.0/8 100.64.0.0/10 169.254.0.0/16 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255/32\"" >> /etc/network/if-up.d/anon-service
echo "_iface=\$(cat \$root/netiface.txt)" >> /etc/network/if-up.d/anon-service
echo "iptables -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
if ( grep -Fq "0" $root/stp-service ); then
	echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53" >> /etc/network/if-up.d/anon-service
else
	echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353" >> /etc/network/if-up.d/anon-service
fi
echo "iptables -t nat -A OUTPUT -m owner --uid-owner \$_user_uid -j RETURN" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -o lo -j RETURN" >> /etc/network/if-up.d/anon-service
echo "for _lan in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_lan -j RETURN" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 3s" >> /etc/network/if-up.d/anon-service
echo "for _iana in \$_resv_iana; do" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_iana -j RETURN" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 3s" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "## Uncomment the next line to grant yourself ssh access from remote machines before the DROP." >> /etc/network/if-up.d/anon-service
echo "#iptables -A INPUT -i \$_iface -p tcp --dport 22 -m state --state NEW -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -i lo -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "# Allow INPUT from lan hosts in \$_non_tor" >> /etc/network/if-up.d/anon-service
echo "## Uncomment the next 4 lines to enable" >> /etc/network/if-up.d/anon-service
echo "#for _lan in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "# iptables -A INPUT -s \$_lan -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "#done" >> /etc/network/if-up.d/anon-service
echo "#sleep 2s" >> /etc/network/if-up.d/anon-service
echo "## Uncomment the next line to enable logging" >> /etc/network/if-up.d/anon-service
echo "#iptables -A INPUT -j LOG --log-prefix "Dropped INPUT packet: " --log-level 7 --log-uid" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A FORWARD -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state INVALID -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -o \$_iface -m owner --uid-owner \$_user_uid -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -d 127.0.0.1/32 -o lo -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -d 127.0.0.1/32 -p tcp -m tcp --dport \$_trans_port --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "## Uncomment the next 4 lines to Allow OUTPUT to lan hosts" >> /etc/network/if-up.d/anon-service
echo "#for _lan in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "#iptables -A INPUT -s \$_lan -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "#done" >> /etc/network/if-up.d/anon-service
echo "#sleep 3s" >> /etc/network/if-up.d/anon-service
echo "## Uncomment the next line to enable logging" >> /etc/network/if-up.d/anon-service
echo "#iptables -A OUTPUT -j LOG --log-prefix "Dropped OUTPUT packet: " --log-level 7 --log-uid" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P FORWARD DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P INPUT DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P OUTPUT DROP" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P FORWARD DROP" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P INPUT DROP" >> /etc/network/if-up.d/anon-service
echo "ip6tables -P OUTPUT DROP" >> /etc/network/if-up.d/anon-service
if ( grep -Fq "0" $root/stp-service ); then
	echo "unbound" >> /etc/network/if-up.d/anon-service
fi
echo "echo \"+++ anon-service started +++\"" >> /etc/network/if-up.d/anon-service
echo "touch \$root/running > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
chown root:root /etc/network/if-up.d/anon-service
chmod 755 /etc/network/if-up.d/anon-service
chmod +x /etc/network/if-up.d/anon-service
echo "==> Now you are ready to go! Restart your network connection"; 
echo "==> or use the restart command-line option.";
echo "";
if [[ -e $root/cpath ]]; then
	cd $(cat $root/cpath)
fi
}
##
## CHECKING IF RUNNING
##
checking_service(){
if [ -e "menu" ]; then
	clear 
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #                 ANON-SERVICE STATUS                 #";
echo "   #######################################################";
echo "";
sleep 1
rm $root/ip.txt > /dev/null 2>&1
if [ ! -e $root/running ]; then
	echo "==> Service is not running!";
	echo "";
	sleep 3	
else
	echo "==> Service is running!";
	curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 "Your IP address" | sed -e 's/<[^>]*>//g' | xargs > $root/ip.txt
	if ( grep -q "Your" $root/ip.txt ) > /dev/null 2>&1; then
		ipaddr=$(cat $root/ip.txt)
		echo "==> $ipaddr";
		echo "";
	else
		echo "==> But the service can't access internet. Try the restart option!";
		sleep 5
		_cquit
	fi
fi
}
##
## Exit
##
shutdown_service(){
if [ -e "menu" ]; then
	clear
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #               ANON-SERVICE DEACTIVATOR              #";
echo "   #######################################################";
echo "";
if [ -f "cpath" ]; then
	mv cpath $root/ > /dev/null 2>&1
fi
service dnscrypt-proxy stop > /dev/null 2>&1
sleep 3
if ! pgrep -x "tor" > /dev/null; then
	echo "==> Restoring original files"; 
	sleep 1
else
	echo "==> Stopping anon-service";
	sleep 1
	echo "==> Restoring original files";
	sleep 1
fi
rm $root/tor.txt > /dev/null 2>&1
rm $root/running > /dev/null 2>&1
chattr -i /etc/resolv.conf > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
echo $'inameserver 1.1.1.1\E:x\n' | vi /etc/resolv.conf > /dev/null 2>&1
service tor stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall xterm unbound tor dnscrypt-proxy restoring_orig.sh > /dev/null 2>&1
cp $netman.bak $netman > /dev/null 2>&1
echo "==> Restarting neworking";
echo "";
service systemd-resolved restart > /dev/null 2>&1
service network-manager restart > /dev/null 2>&1
service networking restart > /dev/null 2>&1
sleep 3
if [ -s "/etc/network/if-up.d/anon-service" ]; then
	rm /etc/network/if-up.d/anon-service
	echo "==> Now the service is no more enabled at startup!";
	echo "==> You can reactivate it using appropriate option.";
	echo "";
	sleep 7
fi
### Firewall flush
iptables -F
iptables -t nat -F
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain 
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
if [ -e $root/cpath ]; then
	cd $(cat $root/cpath)
fi
}
##
## Cleaning all and exit
##
_cleanall(){
if [ -e "menu" ]; then
	clear
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #               ANON-SERVICE UNINSTALLER              #";
echo "   #######################################################";
echo "";
if [ ! -d $root ]; then
	echo "==> Nothing to do here!"; 
	sleep 3
	if [ -e "menu" ]; then
		_menu
		return 1
	else
		echo "";
		exit 1
	fi
fi
if ! pgrep -x "tor" > /dev/null; then
	echo "==> Restoring original files"; 
	sleep 1
else
	echo "==> Stopping anon-service";
	service tor stop > /dev/null 2>&1
	service unbound stop > /dev/null 2>&1
	killall xterm unbound tor dnscrypt-proxy restoring_orig.sh > /dev/null 2>&1
	sleep 1
fi
echo "==> Removing anon-service files and settings from system";
if [ -s "$netman.bak" ]; then
	cp $netman.bak $netman > /dev/null 2>&1
fi
chattr -i /etc/resolv.conf > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
echo $'inameserver 1.1.1.1\E:x\n' | vi /etc/resolv.conf > /dev/null 2>&1
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
if [ -s "$root/installed" ]; then
	apt-get remove -y unbound > /dev/null 2>&1
else
	apt-get remove -y unbound tor deb.torproject.org-keyring > /dev/null 2>&1
fi
apt-get clean > /dev/null
apt-get -y autoremove > /dev/null 2>&1
apt-get -y autoclean > /dev/null 2>&1
if [ -e $root/cpath ]; then
	rm -rf $(cat $root/cpath)/temp > /dev/null 2>&1
fi
userdel -r $owner > /dev/null 2>&1
rm -rf $root > /dev/null 2>&1
rm cpath > /dev/null 2>&1
echo "==> Restarting neworking";
service systemd-resolved restart > /dev/null 2>&1
rm -rf /opt/anon-service > /dev/null 2>&1
rm /usr/bin/anon-service > /dev/null 2>&1
service network-manager restart > /dev/null 2>&1
service networking restart > /dev/null 2>&1
sleep 3
### Firewall flush
iptables -F
iptables -t nat -F
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain 
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
clear
echo -e "\n\n\n\n\n\n";
echo "    ______________________________________________";
echo " "
echo "    +++ Have a nice day! ;) +++";
echo "    ______________________________________________";
echo -e "\n\n";
exit 0
}
##
## View log
##
_vlog(){
if [ -e "menu" ]; then
	clear 
fi
if [[ -e $root/cpath ]]; then
	if [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		clear 
	fi
fi
echo "   #######################################################";
echo "   #               ANON-SERVICE MAINTENANCE              #";
echo "   #######################################################";
if [ ! -e $root/notices.log ]; then
	echo "";	
	echo "==> Sorry! Log file not exitsts.";
	echo "";
	sleep 3
	_cquit
fi
echo " ";
echo "==> What tor info do you want to view?";
echo " ";
echo "      1.Cached (last session)";
echo "      2.Realtime";
echo " ";
echo -n  " Choose: ";
read -r selected_view
echo "";
if [ $selected_view == 1 ]; then
	if [ -e $root/running ]; then
	echo "==> Service is running! Please view realtime logs instead.";
	echo "";
	sleep 3
	_cquit
	fi
	if [[ -e "menu" ]] || [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		xterm -T "Cached logs" -e "more $root/notices.log"
	else 
		more $root/notices.log
		exit 0
	fi
elif [ $selected_view == 2 ]; then
	if [ ! -e $root/running ]; then
		echo "==> Tor is not running! Please view cached logs instead.";
		sleep 3
		echo "";
		_cquit
	fi
	if [[ -e "menu" ]] || [[ -e "$(cat $root/cpath)/temp/menu" ]]; then
		xterm -T "Tor log file" -e tail -f $root/notices.log &
	else 
		tail -f $root/notices.log
	fi
else 
	echo "";
	echo "==> Are you sure Tor is running?";
	echo "";
	sleep 3
	_cquit
	fi
}
##
## Usage
##
usage(){
printf '%s\n' "Usage:"
printf '%s\n' " ./anon-service.sh [option] <value> <server1> <server2> <relay1> <relay2> <relay3> <relay4>"
echo -e "\n";
printf '%s\n' "Transparent proxy through Tor with optionally DNSCrypt"
printf '%s\n' "and anonymized DNS feature enabled."
echo -e "\n";
printf '%s\n' "Options:"
printf '%s\n' " --download  <value>  check dependencies and download them"
printf '%s\n' "                      <value> Tor from: -1 Tor Project repository"
printf '%s\n' "                      -2 OS repository -3 already installed"
printf '%s\n' " --configure <value>  choose transparent proxy type"
printf '%s\n' "                      <value> -1 standard -2 with DNSCrypt"
printf '%s\n' " --start              start service"
printf '%s\n' " --stop               exit without removing service files and settings"
printf '%s\n' " --restart            restart service"
printf '%s\n' " --status             display status service"
printf '%s\n' " --menu               display interactive menu"
printf '%s\n' " --install            install this script"
printf '%s\n' " --permanent          enable service to start automatically at boot"
printf '%s\n' " --remove             exit removing files and settings from system"
printf '%s\n' " --edit      <value>  edit configuraion files"
printf '%s\n' "                      <value> torrc or iptables"
printf '%s\n' " --restore            restore original files and settings"
echo "";
printf '%s\n' " --help               display this help"
printf '%s\n' " --version            display version"
printf '%s\n' " --log      <value>   view Tor log file"
printf '%s\n' "                      <value> cached or realtime"
echo "";
}
##
## Banner
##
banner(){
printf '%s\n' "           ▄▄▄      ███▄    █ ▒█████   ███▄    █          "
printf '%s\n' "          ▒████▄    ██ ▀█   █▒██▒  ██▒ ██ ▀█   █          "
printf '%s\n' "          ▒██  ▀█▄ ▓██  ▀█ ██▒██░  ██▒▓██  ▀█ ██▒         "
printf '%s\n' "          ░██▄▄▄▄██▓██▒  ▐▌██▒██   ██░▓██▒  ▐▌██▒         "
printf '%s\n' "           ▓█   ▓██▒██░   ▓██░ ████▓▒░▒██░   ▓██░  v$version"
printf '%s\n' "       ██████ ▓█████  ██▀███░  ██▒ ░ █▓ ██▓ ▄████▄ ▓█████ "
printf '%s\n' "     ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓██▒▒██▀ ▀█ ▓█   ▀ "
printf '%s\n' "     ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██▒▒▓█    ▄▒███   "
printf '%s\n' "       ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░░██░▒▓▓▄ ▄██▒▓█  ▄ "
printf '%s\n' "     ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░██░▒ ▓███▀ ░▒████▒"
printf '%s\n' "           ░           ░           ░       ░ by bit4mind  "
echo " ";
}
##
## Main
##
clear
### Checking for administrator privileges 
ifsudo=$(id -u)
if [ $ifsudo != 0 ]; then
	echo "==> Please, run script with administrator privileges!";
	echo "";
	exit 1
fi
pwd > cpath
mkdir -p temp
mv cpath temp/
rm temp/menu > /dev/null 2>&1
rm temp/download > /dev/null 2>&1
rm temp/configure > /dev/null 2>&1
rm temp/server1 > /dev/null 2>&1
rm temp/server2 > /dev/null 2>&1
rm temp/relay1 > /dev/null 2>&1
rm temp/relay2 > /dev/null 2>&1
rm temp/relay3 > /dev/null 2>&1
rm temp/relay4 > /dev/null 2>&1
rm temp/tor_option1 > /dev/null 2>&1
rm temp/tor_option2 > /dev/null 2>&1
rm temp/tor_option3 > /dev/null 2>&1
rm temp/configure_option1 > /dev/null 2>&1
rm temp/configure_option2 > /dev/null 2>&1
### Checking for required files
if [ "$#" -gt 0 ]; then
	case "$1" in
		--download)
			cd temp
			touch download
			if [ ! -z "$2" ]; then
				case "$2" in
					-1)
						if [ -e "download" ]; then
							touch tor_option1
						else
							echo "==> Invalid option '$2'";
							echo "";
							exit 1
						fi
						;;
					-2)
						if [ -e "download" ]; then
							touch tor_option2
						else
							echo "==> Invalid option '$2'";
							echo "";
							exit 1
						fi
						;;
					-3)
						if [ -e "download" ]; then
							touch tor_option3
						else 
							echo "==> Invalid option '$2'";
							echo "";
						fi
						;;
					-- | -* | *)
						echo "Invalid option '$2'";
						echo "";
						exit 1
						;;
				esac
				_download
			else
				_download
			fi
			exit 0
			;;
		--configure)
			cd temp
			touch configure 
			if [ ! -z "$2" ]; then
				case "$2" in
					-1)
						if [ -e "configure" ]; then
							touch configure_option1
						else
							echo "==> Invalid option '$2'";
							echo "";
							exit 1
						fi
						;;
					-2)
						if [ -e "configure" ]; then
							touch configure_option2
						else
							echo "==> Invalid option '$2'";
							echo "";
							exit 1
						fi
						if [ ! -z "$3" ]; then
							echo "$3" > server1
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						if [ ! -z "$4" ]; then
							echo "$4" > server2
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						if [ ! -z "$5" ]; then
							echo "$5" > relay1
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						if [ ! -z "$6" ]; then
							echo "$6" > relay2
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						if [ ! -z "$7" ]; then
							echo "$7" > relay3
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						if [ ! -z "$8" ]; then
							echo "$8" > relay4
						else
							echo "==> Error! DNSCrypt enable option requires more arguments"
							echo "";
							exit 1
						fi
						;;
					-- | -* | *)
						echo "Invalid option '$2'";
						echo "";
						exit 1
						;;
				esac        
				_configure
				exit 0
			else
				_configure
			fi
			;;
		--start)
			if [ -f "cpath" ]; then
				mv cpath $root/ > /dev/null 2>&1
			fi
			start_service
			exit 0
			;;
		--stop)
			if [ -f "cpath" ]; then
				mv cpath $root/ > /dev/null 2>&1
			fi
			shutdown_service
			exit 0
			;;
		--restart)
			echo "Reloading...";
			sleep 1
			clear
			if [ -f "cpath" ]; then
				mv cpath $root/ > /dev/null 2>&1
			fi
			if [ -s "/etc/network/if-up.d/anon-service" ]; then
				service network-manager restart > /dev/null 2>&1
				service networking restart > /dev/null 2>&1
				sleep 3
				exit 0
			else
				start_service
				exit 0
			fi
			;;
		--status)
			checking_service
			exit 0
			;;
		--menu)
			cd temp
			touch menu
			_menu
			;;
		--install)
			install_service
			;;
		--permanent)
			permanent_service
			exit 0
			;;
		--remove)
			_cleanall
			exit 0
			;;
		--restore)
			shutdown_service
			exit 0
			;;
		--version)
			banner
			;;
		--help)
			usage
			exit 0
			;;
		--edit)
			if [ -f "cpath" ]; then
				mv cpath $root/ > /dev/null 2>&1
			fi
			if [ ! -s "$root/torrc" ]; then
				clear
				echo "   #######################################################";
				echo "   #              ANON-SERVICE CUSTOMIZATION             #";
				echo "   #######################################################";
				echo "";
				echo "==> Sorry! Your system is not ready to complete this action.";
				echo "==> Please, check if you have installed the necessary files.";
				echo "";
				sleep 3	
				exit 1
			fi
			if [ ! -z "$2" ]; then
				case "$2" in
					torrc)
						nano $root/torrc
						clear
						echo "   #######################################################";
						echo "   #              ANON-SERVICE CUSTOMIZATION             #";
						echo "   #######################################################";
						echo "";
						echo "==> Please restart the service to apply changes";
						echo "";
						exit 0
						;;
					iptables)
						if [ -s "/etc/network/if-up.d/anon-service" ]; then
							nano /etc/network/if-up.d/anon-service
							clear
							echo "   #######################################################";
							echo "   #              ANON-SERVICE CUSTOMIZATION             #";
							echo "   #######################################################";
							echo "";
							echo "==> Please restart via command-line option to apply changes!"; 	
							echo "==> Otherwise simply restart your network connection.";
							echo "";
							exit 0
						else 
							nano $root/iptables_rules.sh
							clear
							echo "   #######################################################";
							echo "   #              ANON-SERVICE CUSTOMIZATION             #";
							echo "   #######################################################";
							echo "";
							echo "==> Please restart the service to apply changes";
							echo "";
							exit 0
						fi
						;;
					*)
						echo "==> Invalid option '$2'";
						echo "";
						exit 1
						;;
				esac
			else
				_editor
				exit 0
			fi
			;;
		--log)
			if [ -f "cpath" ]; then
				mv cpath $root/ > /dev/null 2>&1
			fi
			if [ ! -s "$root/notices.log" ]; then
				clear
				echo "   #######################################################";
				echo "   #               ANON-SERVICE MAINTENANCE              #";
				echo "   #######################################################";
				echo "";
				echo "==> Sorry! Log file not exitsts.";
				echo "";
				sleep 3
				exit 1
			fi
			if [ ! -z "$2" ]; then
				case "$2" in
					cached)
						more $root/notices.log
						exit 0
						;;
					realtime)
						if [ ! -e $root/running ]; then
							clear
							echo "   #######################################################";
							echo "   #               ANON-SERVICE MAINTENANCE              #";
							echo "   #######################################################";
							echo "";
							echo "==> Service is not running! Please view cached logs instead.";
							echo "";
							exit 0
						fi
						tail -f $root/notices.log
						;;
					*)
						echo "==> Invalid option '$2'";
						echo "";
						exit 1
						;;
					esac
			else
				_vlog
				exit 0
			fi
			;;
		-- | -* | *)
			echo "Invalid option '$1'";
			echo "";			
			exit 1
			;;
	esac
else
	cd temp
	touch menu
	_menu
fi
