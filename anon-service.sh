#!/usr/bin/env bash

# ####################################################################
# anon-service.sh
# version 2.1
# 
# Transparent proxy through Tor and optionally DNSCrypt with  
# Anonymized-DNS feature enabled.
#
# Copyright (C) 2020-2023 Bit4mind
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
version="2.0"
repo=/etc/apt/sources.list.d/tor.list
## DNSCrypt-proxy release
dnscrel="2.1.4"
## If necessary, change the path according to your system
export netman=/etc/NetworkManager/NetworkManager.conf
export resolved=/etc/systemd/resolved.conf
tor=/etc/tor/torrc
unbound=/etc/unbound/unbound.conf

menu(){
clear
printf '%s\n' "                    ▄▄▄      ███▄    █ ▒█████   ███▄    █          "
printf '%s\n' "                   ▒████▄    ██ ▀█   █▒██▒  ██▒ ██ ▀█   █          "
printf '%s\n' "                   ▒██  ▀█▄ ▓██  ▀█ ██▒██░  ██▒▓██  ▀█ ██▒         "
printf '%s\n' "                   ░██▄▄▄▄██▓██▒  ▐▌██▒██   ██░▓██▒  ▐▌██▒         "
printf '%s\n' "                    ▓█   ▓██▒██░   ▓██░ ████▓▒░▒██░   ▓██░         "
printf '%s\n' "                ██████ ▓█████  ██▀███░  ██▒ ░ █▓ ██▓ ▄████▄ ▓█████ "
printf '%s\n' "              ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓██▒▒██▀ ▀█ ▓█   ▀ "
printf '%s\n' "              ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██▒▒▓█    ▄▒███   "
printf '%s\n' "                ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░░██░▒▓▓▄ ▄██▒▓█  ▄ "
printf '%s\n' "              ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░██░▒ ▓███▀ ░▒████▒"
printf '%s\n' "                    ░           ░           ░       ░ by bit4mind  "
echo " ";
printf '%s\n' "   0. Check dependencies and download upgraded services"
printf '%s\n' "   1. Choose transparent proxy type and configure related services"
printf '%s\n' "   2. Start/Restart service (if restart this will change your IP address)"
printf '%s\n' "   3. Execute all tasks above"
printf '%s\n' "   4. Close this window"
printf '%s\n' "   5. Display status service"
printf '%s\n' "   6. Enable service to start automatically at boot"
printf '%s\n' "   7. Stop service without removing files and setting"
printf '%s\n' "   8. Exit removing service files and settings from system"
printf '%s\n' "   9. Edit torrc file"
printf '%s\n' "   10. Install this script"
echo " ";
echo -n "  Choose: ";
read -e task
case "$task" in  
0)
## Detect if X runs
if ! timeout 1s xset q &>/dev/null; then
echo " ";
echo "==> No X server detected. Try to use command line option instead." >&2
sleep 5
exit 1
fi
download
menu
;;
1)
configure
menu
;;
2)
start_service
menu
;;
3)
download
configure
start_service
menu
;;
4)
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
if hash wmctrl 2>/dev/null; then
wmctrl -c :ACTIVE:
else
echo "==> Sorry! Your system is not ready to complete this action";
echo "==> Please, check if you have installed the necessary files";
sleep 7
menu
return 1
fi
;;
5)
checking_service
sleep 7
menu
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
menu
;;
8)
cleanall
;;
9)
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
if [ ! -s "$root/torrc" ]; then
echo "";
echo "==> Sorry! Your system is not ready to complete this action";
echo "==> Please, check if you have installed the necessary files";
sleep 7
menu
return 1
else
echo "";
xterm -T "Torrc" -e "leafpad $root/torrc" > /dev/null 2>&1 
echo "==> Please restart the service to apply changes";
sleep 7
menu
fi
;;
10)
install_service
sleep 7
menu
;;
*)
echo "";
echo "==> Are you serious?"
sleep 5
menu
esac
}
##
##  Checking dependencies and downloading upgraded services
##
download(){
if [ -s "$root" ]; then
echo "";
echo "==> Please, firstly remove all files and settings via dedicated option";
sleep 7
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi
fi
### Checking for network connection
rm conn.txt > /dev/null 2>&1
ping -c1 opendns.com > conn.txt 2>&1
if ( ! grep -q "icmp_seq=1" conn.txt ); then
rm conn.txt > /dev/null 2>&1
echo "==> Please check your network connection!";
sleep 5
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi   
fi
clear
echo "==> Checking dependencies and preparing the system"
rm -rf $root > /dev/null 2>&1
adduser -q --disabled-password --gecos "" $owner > /dev/null 2>&1
usermod -u 999 $owner > /dev/null 2>&1
mv cpath $root > /dev/null 2>&1
mkdir -p $root/temp
chmod -R 777 $root/temp
apt-get update > $root/temp/apt.log
if [ ! -e "menu" ]; then
apt-get install -y curl wget psmisc nano apt-transport-https unbound ifupdown > /dev/null
else
apt-get install -y curl wget xterm psmisc wmctrl leafpad apt-transport-https unbound ifupdown > /dev/null
fi
sleep 1
clear
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
echo "==> Sorry! The script cannot recognize your Tor package";
exit 1
fi
else
echo "==> Which version of Tor do you prefer to use?";
echo "      1.Tor Project repository";
echo "      2.Official repository";
echo "      3.I already have tor installed";
echo " "
echo -n  " Choose: ";
read -e choose
case "$choose"
in 1)
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
echo "==> Sorry! The script cannot recognize your Tor package";
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi
fi
;;
*)
echo "==> Are you serious?";
sleep 5
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi
esac
fi
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
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/public-resolvers.md > /dev/null 2>&1
echo "==> Downloading anonymized DNS relays list";
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/relays.md > /dev/null 2>&1
### Backup systemd-resolved
if [ ! -s "$root/resolved.bak" ]; then
cp $resolved $root/resolved.bak > /dev/null 2>&1
fi
### Backup NetworkManager.conf (if exists)
if [ ! -s "$netman.bak" ]; then
if [ -s "$netman" ]; then
cp $netman $netman.bak > /dev/null 2>&1
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
for target in $(cat $root/temp/distribution.txt)
do
if grep -Fq "$target" $root/temp/apt.log; then
echo $target > $root/temp/os.txt
fi
done
os=$(cat $root/temp/os.txt | sed -e 's/^[ \t]*//')
echo "";
if [[ "$os" == " " ]]; then
echo "==> Sorry! Apparently your OS hasn't candidate in Tor Project";
echo "==> repo...Please, re-run the script and choose other options";
exit 1
fi
if curl --head --silent --fail https://deb.torproject.org/torproject.org/dists/$os/main/binary-i386/ > /dev/null 2>&1;
then
echo "==> Enabling $os repository";
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
if ( grep "torproject.org $os Release" $root/temp/apt.log > /dev/null 2>&1 )
then
   echo "";
   echo "==> Sorry! The script can't obtain the correct codename for your OS...";
   echo "==> Please, try to enter the correct codename for the debian or ubuntu";
   echo "==> repository compatible with your OS...In doubt, search on internet!";
   echo "==> Warning: if the repository is not correct, the script could crash!"; 
   echo -n "    Please, enter the codename (for example: buster): ";
   read -e codename 
   rm $repo
   touch $repo
   echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg]  https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   apt-get update > /dev/null
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
   echo 
else
   echo "==> Installing Tor";
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
fi
}
##
## CONFIGURING SERVICES
##
configure(){
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
if [ ! -s "$root/dnscrypt-proxy.toml.bak" ]; then
echo "";
echo "==> Sorry! Your system is not ready to complete this action";
echo "==> Please, check if you have installed the necessary files";
sleep 7
if [ -e "menu" ]; then
menu
return 1
else 
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
elif [ -e "configure_option2" ]; then 
rm $root/stp-service > /dev/null 2>&1
touch $root/stp-service
echo "0" > $root/stp-service
dnscryptconf
elif [ -e "$(cat $root/cpath)/temp/menu" ] || [ -e "$(cat $root/cpath)/temp/configure" ]; then
clear
echo "==> Which type of transparent proxy do you prefer to use?";
echo "      1. Standard transparent proxy";
echo "      2. Trasparent proxy with DNSCrypt and Anonymized-DNS feature";
echo " "
echo -n  " Choose: ";
read -e choose
case "$choose" in 
1)
rm $root/stp-service > /dev/null 2>&1
touch $root/stp-service
echo "1" > $root/stp-service
;;
2)
rm $root/stp-service > /dev/null 2>&1
touch $root/stp-service
echo "0" > $root/stp-service 
dnscryptconf
;;
*)
echo "";
echo "==> Are you serious?"
sleep 5
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
configure
return 1
else 
exit 1
fi
esac
else
echo "==> Sorry! Something went wrong...Please, report this issue to the project";
exit 1
fi
echo "==> Configuring Tor";
sleep 2
### Configuring Tor
cp $tor $root/torrc
echo "Log notice file $root/notices.log" >> $root/torrc
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> $root/torrc
echo "AutomapHostsOnResolve 1" >> $root/torrc
echo "TransPort 9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort" >> $root/torrc
echo "DNSPort 5353" >> $root/torrc
### Disabling dnsmasq and configure Network-Manager (if exists) and systemd-resolved
if [ -s $netman ]; then
rm $root/NetworkManager.conf.temp > /dev/null 2>&1
cp $netman.bak $root/NetworkManager.conf.temp
cd $root
chown $USER:$USER NetworkManager.conf.temp
sed -i 's/^dns=dnsmasq/#&/' NetworkManager.conf.temp
sed '/\[main\]/a dns=default' NetworkManager.conf.temp > NetworkManager.conf
fi
if [ -s "$root/resolved.bak" ]; then
cp $root/resolved.bak $root/resolved.conf.temp
sleep 1
chown $USER:$USER resolved.conf.temp
sed -i 's/^DNSStubListener=yes/#&/' resolved.conf.temp
echo "DNS=127.0.0.1" >> resolved.conf.temp
echo "DNSStubListener=no" >> resolved.conf.temp
fi
rm $root/iptables_rules.sh > /dev/null 2>&1
touch $root/iptables_rules.sh
### Configuring basic iptables rules
### Reference: https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy
echo "#!/bin/bash" > $root/iptables_rules.sh
# Destinations you don't want routed through Tor
echo "_non_tor=\"127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16\"" >> $root/iptables_rules.sh
# The UID that Tor runs as (varies from system to system)
echo "_user_uid=\"999\"" >> $root/iptables_rules.sh
# Tor's VirtualAddrNetworkIPv4
echo "_virt_addr=\"10.192.0.0/10\"" >> $root/iptables_rules.sh
# Tor's TransPort
echo "_trans_port=\"9040\"" >> $root/iptables_rules.sh
echo "iptables -F" >> $root/iptables_rules.sh
echo "iptables -t nat -F" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -d \$_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -m state --state INVALID -j DROP" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -m owner --uid-owner \$_user_uid -j RETURN" >> $root/iptables_rules.sh
if ( grep -Fq "1" $root/stp-service); then
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353" >> $root/iptables_rules.sh
else
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53" >> $root/iptables_rules.sh
fi
echo "for _clearnet in \$_non_tor; do" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -d \$_clearnet -j RETURN" >> $root/iptables_rules.sh
echo "done" >> $root/iptables_rules.sh
echo "sleep 5" >> $root/iptables_rules.sh
echo "iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT" >> $root/iptables_rules.sh
echo "iptables -A INPUT -i lo -j ACCEPT" >> $root/iptables_rules.sh
echo "for _lan in \$_non_tor; do" >> $root/iptables_rules.sh
echo "iptables -A INPUT -s \$_lan -j ACCEPT" >> $root/iptables_rules.sh
echo "done" >> $root/iptables_rules.sh
echo "sleep 5" >> $root/iptables_rules.sh
echo "iptables -A INPUT -j DROP" >> $root/iptables_rules.sh
echo "iptables -A FORWARD -j DROP" >> $root/iptables_rules.sh
echo "for _clearnet in \$_non_tor; do" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -d \$_clearnet -j ACCEPT" >> $root/iptables_rules.sh
echo "done" >> $root/iptables_rules.sh
echo "sleep 3" >> $root/iptables_rules.sh
echo "iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports \$_trans_port" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -m owner --uid-owner \$_user_uid -j ACCEPT" >> $root/iptables_rules.sh
echo "sleep 2" >> $root/iptables_rules.sh
echo "iptables -A OUTPUT -j DROP" >> $root/iptables_rules.sh
echo "sleep 1" >> $root/iptables_rules.sh
echo "iptables -P FORWARD DROP" >> $root/iptables_rules.sh
echo "iptables -P INPUT DROP" >> $root/iptables_rules.sh
echo "iptables -P OUTPUT DROP" >> $root/iptables_rules.sh
chmod +x $root/iptables_rules.sh
cd $(cat $root/cpath)
}
##
## CONFIGURING DNSCRYPT
##
dnscryptconf(){
### Configuring dnscrypt_proxy
rm $root/dnscrypt-proxy.toml > /dev/null 2>&1
cp $root/dnscrypt-proxy.toml.bak $root/dnscrypt-proxy.toml
if [ -e "configure_option2" ]; then
server1="$(cat server1)"
else
echo "==> Opening file contain public resolvers";
sleep 2
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/public-resolvers.md
else
xterm -T "Resolvers" -e "leafpad $root/public-resolvers.md" &
sleep 1
clear
fi
echo "==> Please enter the name of the first resolver to use, only ipv4!";
echo -n "    First server: ";
read -e server1
echo "";
fi
if ! grep "\<$server1\>" $root/public-resolvers.md > /dev/null; then
echo "==> First server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
if [ -e "configure_option2" ]; then
server2="$(cat server2)"
else
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/public-resolvers.md
fi
echo "==> Please enter the name of the second resolver to use, only ipv4!";
echo -n "    Second server: ";
read -e server2
if ! grep "\<$server2\>" $root/public-resolvers.md > /dev/null; then
echo "==> Second server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
fi
if [ -e "configure_option2" ]; then
relay1="$(cat relay1)"
else
clear
echo "==> Opening file contain relays";
sleep 2
killall leafpad > /dev/null 2>&1
echo "==> Carefully choose relays/servers so that they are run by different entities!";
sleep 2
echo "";
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/relays.md
fi
echo "==> Please enter the name of the first realy to use!";
echo -n "    First relay for the first server: ";
read -e relay1
echo "";
if ! grep "\<$relay1\>" $root/relays.md > /dev/null; then
echo "==> First relay for the first server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
fi
if [ -e "configure_option2" ]; then
relay2="$(cat relay2)"
else
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/relays.md
fi
echo "==> Please enter the name of the second relay to use!";
echo -n "    Second relay for the first server: ";
read -e relay2
echo "";
if ! grep "\<$relay2\>" $root/relays.md > /dev/null; then
echo "==> Second relay for the first server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
fi
if [ -e "configure_option2" ]; then
relay3="$(cat relay3)"
else
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/relays.md
fi
echo "==> Please enter the name of the third resolver to use!";
echo -n "    First relay for the second server: ";
read -e relay3
echo "";
if ! grep "\<$relay3\>" $root/relays.md > /dev/null; then
echo "==> First relay for the second server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
fi
if [ -e "configure_option2" ]; then
relay4="$(cat relay4)"
else
if [ -e "configure" ]; then
echo "==> Type "q" to quit";
sleep 3
more $root/relays.md
fi
echo "==> Please enter the name of the fourth resolver to use!";
echo -n "    Second relay for the second server: ";
read -e relay4
echo "";
if ! grep "\<$relay4\>" $root/relays.md > /dev/null; then
echo "==> Second relay for the second server not found! Please retry";
killall leafpad > /dev/null 2>&1
sleep 3
if [ -e "menu" ]; then
configure
return 1
else 
exit 1
fi
fi
fi
killall leafpad > /dev/null 2>&1
clear
echo "==> Configuring DNSCrypt";
sed -i "1iforce_tcp = true" $root/dnscrypt-proxy.toml
sed -i "2iserver_names = ['$server1', '$server2']" $root/dnscrypt-proxy.toml
sed -i "s/127.0.0.1:53/127.0.0.1:10000/g; s/9.9.9.9/208.67.222.222/g; s/8.8.8.8/208.67.220.220/g; s/require_dnssec = false/require_dnssec = true/g; s/force_tcp = false/#force_tcp = false/g; s/\[anonymized_dns\]/\[anonymized_dns\]\nroutes = \[\n{ server_name='$server1', via=\[\'$relay1\', \'$relay2\'\] },\n{ server_name=\'$server2\', via=[\'$relay3\', \'$relay4\'] }\n\]/g; s/skip_incompatible = false/skip_incompatible = true/g" $root/dnscrypt-proxy.toml
echo "==> Configuring Unbound";
### Configuring unbound
unbound-anchor > /dev/null 2>&1
sleep 1
echo "server:" > $unbound
echo "tcp-upstream: yes" >> $unbound
echo "domain-insecure: \"onion\"" >> $unbound
echo "private-domain: \"onion\"" >> $unbound
echo "do-not-query-localhost: no" >> $unbound 
echo "interface: 127.0.0.1@53" >> $unbound
echo "local-zone: \"onion.\" transparent" >> $unbound
echo "forward-zone:" >> $unbound
echo "    name: \"onion\"" >> $unbound
echo "    forward-addr: 127.0.0.1@5353" >> $unbound
echo "forward-zone:" >> $unbound
echo "   name: \".\"" >> $unbound
echo "   forward-addr: 127.0.0.1@10000" >> $unbound
}
##
## Starting services and configuring iptables
##
start_service(){
### Checking for required files
if [ ! -s "$root/stp-service" ]; then
echo "";
echo "==> Sorry! Your system is not ready to start the service...";
echo "==> Please, check if you have installed the necessary files";
sleep 7
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi
fi
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
if [ -s "/etc/network/if-up.d/anon-service" ]; then
echo "";
echo "==> Sorry! This menu option is not usable in permanent mode";
echo "==> Reboot your system or simply restart your connection instead";
sleep 7
if [ -e "menu" ]; then
menu
return 1
else 
exit 1
fi
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
### Disable ipv6 
echo "1" > /dev/null 2>&1 | tee /proc/sys/net/ipv6/conf/default/disable_ipv6
echo "1" > /dev/null 2>&1 | tee /proc/sys/net/ipv6/conf/all/disable_ipv6
### Configure Network-Manager
cd $root
cp resolved.conf.temp $resolved > /dev/null 2>&1
chown root:root $resolved > /dev/null 2>&1
if [ -s $netman ]; then
cp NetworkManager.conf $netman
chown root:root $netman
fi
service dnsmasq stop > /dev/null 2>&1
service bind stop > /dev/null 2>&1
service systemd-resolved stop
killall dnsmasq bind > /dev/null 2>&1
sleep 1
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
service systemd-resolved restart
service network-manager restart > /dev/null 2>&1
systemctl restart networking > /dev/null 2>&1
sleep 5
cat /etc/resolv.conf > /dev/null 2>&1 | sed -e '/^$/d; /^#/d' > $root/dnsread
if [[ $(cat $root/dnsread) != "nameserver 127.0.0.1" ]]; then 
rm /etc/resolv.conf > /dev/null 2>&1 
echo "";
echo "==> Make sure 127.0.0.1 is your DNS system setting and then press ENTER";
read REPLY
service systemd-resolved restart
service network-manager restart > /dev/null 2>&1
systemctl restart networking.service > /dev/null 2>&1
fi
rm $root/dnsread > /dev/null 2>&1
sleep 5
chown -R $owner:$owner $root
## Restore original files automatically at shutdown
if ( ! pgrep -f "restoring_orig.sh " )  > /dev/null; then
rm restoring_orig.sh > /dev/null 2>&1 
touch restoring_orig.sh
echo "#!/bin/bash" > restoring_orig.sh
echo "restoring_script() {" >> restoring_orig.sh 
echo "if [ ! -f /etc/network/if-up.d/anon-service ]; then" >> restoring_orig.sh
echo "cp $root/resolved.bak $resolved" >> restoring_orig.sh
echo "cp $netman.bak $netman > /dev/null 2>&1" >> restoring_orig.sh
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
if [ -e "$(cat $root/cpath)/temp/" ]; then
nohup ./restoring_orig.sh > /dev/null 2>&1 &
clear
else
xterm -e nohup ./restoring_orig.sh
fi
fi
echo "==> Starting anon-service";
## Start selected transparent proxy
active_service=$(cat $root/stp-service)
case $active_service in
"0")
nohup su - $owner -c "./dnscrypt-proxy" > /dev/null 2>&1 &
sleep 1
rm $root/notices.log > /dev/null 2>&1
touch $root/notices.log
chown anon-service:anon-service $root/notices.log
nohup su - $owner -c "tor -f $root/torrc" > /dev/null 2>&1 &
echo "==> Checking connection to Tor";
SECONDS=0
secs=30
while (( SECONDS < secs ));
do
if ( grep -Fq "100%" $root/notices.log ); then 
break
fi
sleep 1
done
rm $root/notices.log > /dev/null 2>&1
cd $root
./iptables_rules.sh
unbound &
### Checking services
if ( ! pgrep -x "tor" ) > /dev/null; then
echo "==> Sorry! No connection to TOR...Please, report this issue to the project";
sleep 7
shutdown_service
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else 
exit 1
fi
fi
if ( ! pgrep -x "dnscrypt-proxy" ) > /dev/null; then
echo "==> Sorry! Dnscrypt-proxy isn't running...Please, report this issue to the project";
sleep 7
shutdown_service
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else
exit 1
fi
fi
if ( ! pgrep -x "unbound" ) > /dev/null; then
echo "==> Sorry! Unbound isn't running...Please, report this issue to the project";
sleep 7
shutdown_service
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else
exit 1
fi
else
echo "==> Congratulations! Your system is configurated to use Tor and DNSCrypt";
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
while (( SECONDS < secs ));
do
if ( grep -Fq "100%" $root/notices.log ); then 
break
fi
sleep 1
done
rm $root/notices.log > /dev/null 2>&1
cd $root
./iptables_rules.sh
### Checking services
if ( ! pgrep -x "tor" > /dev/null ); then
echo "==> Sorry! No connection to TOR...Please, report this issue to the project";
sleep 7
shutdown_service
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else
exit 1
fi
else
echo "==> Congratulations! Your system is configurated to use Tor";
touch $root/running
sleep 5
fi
esac
cd $(cat $root/cpath)
}
##
## Install this script
##
install_service(){
touch /usr/bin/anon-service > /dev/null 2>&1
cp $0 /usr/bin/anon-service > /dev/null 2>&1
chmod +x /usr/bin/anon-service
echo "";
echo "==> Now you can run it simply typing \"sudo anon-service\" in your terminal";
cd $(cat $root/cpath)
}
##
## Run at boot
##
permanent_service(){
if [ ! -f "$root/stp-service" ]; then
echo "";
echo "==> Sorry! Your system is not ready to start the service...";
echo "==> Please, check if you have installed the necessary files";
sleep 7
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else
exit 1
fi
fi
cd $root
cp resolved.conf.temp $resolved > /dev/null 2>&1
chown root:root $resolved > /dev/null 2>&1
cp NetworkManager.conf $netman > /dev/null 2>&1
chown root:root $netman
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
touch /etc/network/if-up.d/anon-service
echo "#!/bin/sh" > /etc/network/if-up.d/anon-service
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
echo "iptables -P FORWARD ACCEPT" >> /etc/network/if-up.d/anon-service
echo "echo \"1\" > /dev/null 2>&1 | tee /proc/sys/net/ipv6/conf/default/disable_ipv6" >> /etc/network/if-up.d/anon-service
echo "echo \"1\" > /dev/null 2>&1 | tee /proc/sys/net/ipv6/conf/all/disable_ipv6" >> /etc/network/if-up.d/anon-service
echo "service dnsmasq stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service bind stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "killall dnsmasq bind > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "cd $root" >> /etc/network/if-up.d/anon-service
echo "service tor stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service dnscrypt-proxy stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "service unbound stop > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "killall unbound tor dnscrypt-proxy > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "chown -R $owner:$owner $root" >> /etc/network/if-up.d/anon-service
selected_service=$(cat $root/stp-service)
if (( $selected_service == 1 )); then
echo "nohup su - $owner -c \"./dnscrypt-proxy\" > /dev/null 2>&1 &" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
fi
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
echo "rm $root/notices.log > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
echo "_non_tor=\"127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16\"" >> /etc/network/if-up.d/anon-service
echo "_user_uid=\"999\"" >> /etc/network/if-up.d/anon-service
echo "_virt_addr=\"10.192.0.0/10\"" >> /etc/network/if-up.d/anon-service
echo "_trans_port=\"9040\"" >> /etc/network/if-up.d/anon-service
echo "iptables -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state INVALID -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -m owner --uid-owner \$_user_uid -j RETURN" >> /etc/network/if-up.d/anon-service
if (( $selected_service == 0 )); then
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53" >> /etc/network/if-up.d/anon-service
else
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353" >> /etc/network/if-up.d/anon-service
fi
echo "for _clearnet in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_clearnet -j RETURN" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 5s" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -i lo -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "for _lan in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -s \$_lan -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 5s" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A FORWARD -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "for _clearnet in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -d \$_clearnet -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 3s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m owner --uid-owner \$_user_uid -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 2s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -P FORWARD DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P INPUT DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P OUTPUT DROP" >> /etc/network/if-up.d/anon-service
if (( $selected_service == 1 )); then
echo "unbound" >> /etc/network/if-up.d/anon-service
fi
echo "echo \"+++ anon-service started +++\"" >> /etc/network/if-up.d/anon-service
echo "touch \$root/running > /dev/null 2>&1" >> /etc/network/if-up.d/anon-service
chown root:root /etc/network/if-up.d/anon-service
chmod 755 /etc/network/if-up.d/anon-service
chmod +x /etc/network/if-up.d/anon-service
echo "";
echo "==> Now you are ready to go! If you haven't set 127.0.0.1 in your DNS"; 
echo "==> setting, do it and restart your connection or reboot your system.";
echo "";
cd $(cat $root/cpath)
}
##
## CHECKING IF RUNNING
##
checking_service(){
if [ ! -e $root/running ] > /dev/null; then
echo "==> Service is not running!";
sleep 3	
else
echo "==> Service is running!";
curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 "Your IP address" | sed -e 's/<[^>]*>//g' | xargs > $root/ip.txt
if ( grep -q "Your" $root/ip.txt ); then
ipaddr=$(cat $root/ip.txt)
echo "==> $ipaddr";
else
echo "==> But the service can't access internet. Try the restart option";
if [ -e "$(cat $root/cpath)/temp/menu" ]; then
menu
return 1
else
exit 1
fi
fi
fi
}
##
## Exit
##
shutdown_service(){
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
clear
service dnscrypt-proxy stop > /dev/null 2>&1
sleep 3
if ! pgrep -x "tor" > /dev/null; then
echo "==> Restoring original files"; 
sleep 7
else
echo "==> Stopping anon-service";
sleep 7
fi
rm $root/tor.txt > /dev/null 2>&1
rm $root/running > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service tor stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy restoring_orig.sh > /dev/null 2>&1
cp $root/resolved.bak $resolved > /dev/null 2>&1
cp $netman.bak $netman > /dev/null 2>&1
if [ -s "/etc/network/if-up.d/anon-service" ]; then
rm /etc/network/if-up.d/anon-service
echo "";
echo "==> Now the service is no more enabled at startup!";
echo "==> You can reactivate it using appropriate option";
echo -e "\n\n";
sleep 7
fi
service systemd-resolved restart
service network-manager restart > /dev/null 2>&1

systemctl restart networking > /dev/null 2>&1
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
cd $(cat $root/cpath)
}
##
## Cleaning all and exit
##
cleanall(){
clear
echo "==> Removing anon-service files and settings from system";
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy restoring_orig.sh > /dev/null 2>&1
if [[ -s "$root/resolved.bak" ]]; then
cp $root/resolved.bak $resolved > /dev/null 2>&1
service systemd-resolved restart
fi
if [[ -s "$netman.bak" ]]; then
cp $netman.bak $netman > /dev/null 2>&1
fi
rm /usr/bin/anon-service > /dev/null 2>&1
service systemd-resolved restart
service network-manager restart > /dev/null 2>&1
systemctl restart networking > /dev/null 2>&1
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
if [[ -s "$root/installed" ]]; then
apt-get remove -y unbound > /dev/null 2>&1
else
apt-get remove -y unbound tor deb.torproject.org-keyring > /dev/null 2>&1
fi
apt-get clean > /dev/null
apt-get -y autoremove > /dev/null 2>&1
apt-get -y autoclean > /dev/null 2>&1
rm -rf $(cat $root/cpath)/temp > /dev/null 2>&1
userdel -r $owner > /dev/null 2>&1
rm -rf $root > /dev/null 2>&1
rm cpath > /dev/null 2>&1
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
clear
echo -e "\n\n\n\n\n\n";
echo "==> Remember to change your DNS system setting";
echo "    ______________________________________________";
echo " "
echo "    +++ Have a nice day! ;) +++";
echo "    ______________________________________________";
echo -e "\n\n";
exit 0
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
printf '%s\n' " --stop               without removing service files and settings"
printf '%s\n' " --restart            restart service"
printf '%s\n' " --status             display status service"
printf '%s\n' " --menu               display interactive menu"
printf '%s\n' " --install            install this script"
printf '%s\n' " --permanent          enable service to start automatically at boot"
printf '%s\n' " --remove             exit removing files and settings from system"
printf '%s\n' " --edit               edit torrc file"
echo "";
printf '%s\n' " --help               display this help"
printf '%s\n' " --version            display version"
echo "";
}
##
## Main
##
clear
### Checking for administrator privileges 
ifsudo=$(id -u)
if [ $ifsudo != 0 ]; then
echo "==> Please, run script with administrator privileges";
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
exit 1
fi
;;
-2)
if [ -e "download" ]; then
touch tor_option2
else
echo "==> Invalid option '$2'";
exit 1
fi
;;
-3)
if [ -e "download" ]; then
touch tor_option3
else 
echo "==> Invalid option '$2'";
fi
;;
-- | -* | *)
echo "Invalid option '$2'";
exit 1
;;
esac
download
else
download
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
exit 1
fi
;;
-2)
if [ -e "configure" ]; then
touch configure_option2
else
echo "==> Invalid option '$2'";
exit 1
fi
if [ ! -z "$3" ]; then
echo "$3" > server1
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
if [ ! -z "$4" ]; then
echo "$4" > server2
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
if [ ! -z "$5" ]; then
echo "$5" > relay1
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
if [ ! -z "$6" ]; then
echo "$6" > relay2
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
if [ ! -z "$7" ]; then
echo "$7" > relay3
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
if [ ! -z "$8" ]; then
echo "$8" > relay4
else
echo "==> Error! DNSCrypt enable option requires more arguments"
exit 1
fi
;;
-- | -* | *)
echo "Invalid option '$2'";
exit 1
;;
esac        
configure
exit 0
else
configure
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
echo "==> Reloading...";
sleep 3
if [ -f "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
if [ -s "/etc/network/if-up.d/anon-service" ]; then
service systemd-resolved restart
service network-manager restart > /dev/null 2>&1
systemctl restart networking > /dev/null 2>&1
exit 0
else
start_service
exit 0
fi
;;
--status)
if [ ! -e $root/running ] > /dev/null; then
echo "==> Service is not running!";
sleep 3	
else
echo "==> Service is running!";
curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 	1 "Your IP address" | sed -e 's/<[^>]*>//g' | xargs > $root/ip.txt
sleep 3
if ( grep -q "Your" $root/ip.txt ); then
		ipaddr=$(cat $root/ip.txt)
echo "==> $ipaddr";
else
echo "==> But the service can't access internet. Try the restart option";
exit 0
fi
fi
;;
--menu)
cd temp
touch menu
menu
;;
--install)
install_service
;;
--permanent)
permanent_service
exit 0
;;
--remove)
cleanall
exit 0
;;
--version)
echo "anon-service $version";
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
echo "";
echo "==> Sorry! Your system is not ready to complete this action";
echo "==> Please, check if you have installed the necessary files";
sleep 3
exit 1
else
echo "";
nano $root/torrc
echo "==> Please restart the service to apply changes";
sleep 3
exit 0
fi
;;
-- | -* | *)
echo "Invalid option '$1'";
exit 1
;;
esac
else
cd temp
touch menu
menu
fi
