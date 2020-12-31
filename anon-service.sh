#!/usr/bin/env bash

# #####################################################################
# anon-service.sh
# version 1.09
# 
# Transparent proxy through Tor with DNSCrypt and Anonymized DNS 
# feature enabled.
#
# Copyright (C) 2020 Bit4mind
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
repo=/etc/apt/sources.list.d/tor.list
## DNSCrypt-proxy release
dnscrel="2.0.44"
## If necessary, change the path according to your system
netman=/etc/NetworkManager/NetworkManager.conf
resolved=/etc/systemd/resolved.conf
tor=/etc/tor/torrc
unbound=/etc/unbound/unbound.conf


menu(){
clear
echo "                    ▄▄▄      ███▄    █ ▒█████   ███▄    █          ";
echo "                   ▒████▄    ██ ▀█   █▒██▒  ██▒ ██ ▀█   █          ";
echo "                   ▒██  ▀█▄ ▓██  ▀█ ██▒██░  ██▒▓██  ▀█ ██▒         ";
echo "                   ░██▄▄▄▄██▓██▒  ▐▌██▒██   ██░▓██▒  ▐▌██▒         ";
echo "                    ▓█   ▓██▒██░   ▓██░ ████▓▒░▒██░   ▓██░         ";
echo "                ██████ ▓█████  ██▀███░  ██▒ ░ █▓ ██▓ ▄████▄ ▓█████ ";
echo "              ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓██▒▒██▀ ▀█ ▓█   ▀ ";
echo "              ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██▒▒▓█    ▄▒███   ";
echo "                ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░░██░▒▓▓▄ ▄██▒▓█  ▄ ";
echo "              ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░██░▒ ▓███▀ ░▒████▒";
echo "                    ░           ░           ░       ░ by bit4mind  ";
echo " ";
echo "   0. Check dependencies and download upgraded services";
echo "   1. Set servers/relays for anonymized DNS feature and configure other services";
echo "   2. Start/Restart anon-service";
echo "   3. Execute all tasks above";
echo "   4. Close this window";
echo "   5. Enable service to start automatically at boot";
echo "   6. Stop anon-service/Restore original files without removing anon-service";
echo "   7. Exit removing anon-service files and settings from system";
echo -en "\033[38;2;0;100;0m    Misc\033[0m\n";
echo "   8. Change IP address";
echo "   9. Install this script";
echo " ";
echo -n "  Choose: ";
read -e task
case "$task" in  
0)
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
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
wmctrl -c :ACTIVE:
;;
5)
if [ ! -s "$root/dnscrypt-proxy.toml" ]; then
echo "";
echo "==> Sorry! Your system is not ready to start the service...";
echo "==> Please, check if you have installed the necessary files";
sleep 7
menu
exit
fi
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
cd $root
cp resolved.conf.temp $resolved
chown root:root $resolved
cp NetworkManager.conf $netman
chown root:root $netman
touch resolv.conf
echo nameserver 127.0.0.1 > resolv.conf
mv resolv.conf /etc/resolv.conf
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
touch /etc/network/if-up.d/anon-service
echo "#!/bin/sh" > /etc/network/if-up.d/anon-service
echo "root=/home/anon-service" >> /etc/network/if-up.d/anon-service
echo "owner=anon-service" >> /etc/network/if-up.d/anon-service
echo "iptables -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -F" >> /etc/network/if-up.d/anon-service
echo "iptables --flush" >> /etc/network/if-up.d/anon-service
echo "iptables --table nat --flush" >> /etc/network/if-up.d/anon-service
echo "iptables --delete-chain" >> /etc/network/if-up.d/anon-service
echo "iptables --table nat --delete-chain" >> /etc/network/if-up.d/anon-service 
echo "iptables -P OUTPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -P INPUT ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -P FORWARD ACCEPT" >> /etc/network/if-up.d/anon-service
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
echo "nohup su - $owner -c \"./dnscrypt-proxy\" > /dev/null 2>&1 &" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
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
echo "_resv_iana=\"0.0.0.0/8 100.64.0.0/10 169.254.0.0/16 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255/32\"" >> /etc/network/if-up.d/anon-service
echo "_tor_uid=\"$(id -u debian-tor)\"" >> /etc/network/if-up.d/anon-service
echo "_virt_addr=\"10.192.0.0/10\"" >> /etc/network/if-up.d/anon-service
echo "_trans_port=\"9040\"" >> /etc/network/if-up.d/anon-service
echo "iptables -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -F" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state INVALID -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -m owner --uid-owner \$_tor_uid -j RETURN" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53" >> /etc/network/if-up.d/anon-service
echo "for _clearnet in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_clearnet -j RETURN" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "for _iana in \$_resv_iana; do" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -d \$_iana -j RETURN" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 8s" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -i lo -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "for _lan in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -s \$_lan -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 7s" >> /etc/network/if-up.d/anon-service
echo "iptables -A INPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -A FORWARD -j DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports \$_trans_port" >> /etc/network/if-up.d/anon-service
echo "for _clearnet in \$_non_tor; do" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -d \$_clearnet -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "done" >> /etc/network/if-up.d/anon-service
echo "sleep 3s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -m owner --uid-owner \$_tor_uid -j ACCEPT" >> /etc/network/if-up.d/anon-service
echo "sleep 2s" >> /etc/network/if-up.d/anon-service
echo "iptables -A OUTPUT -j DROP" >> /etc/network/if-up.d/anon-service
echo "sleep 1s" >> /etc/network/if-up.d/anon-service
echo "iptables -P FORWARD DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P INPUT DROP" >> /etc/network/if-up.d/anon-service
echo "iptables -P OUTPUT DROP" >> /etc/network/if-up.d/anon-service
echo "unbound" >> /etc/network/if-up.d/anon-service
echo "echo \"+++ anon-service started +++\"" >> /etc/network/if-up.d/anon-service
chown root:root /etc/network/if-up.d/anon-service
chmod 755 /etc/network/if-up.d/anon-service
chmod +x /etc/network/if-up.d/anon-service
echo "";
echo "==> Now you are ready to go! If you haven't set 127.0.0.1 in your DNS"; 
echo "==> setting, do it and restart your connection or reboot your system.";
exit 0
;;
6)
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
shutdown_service
menu
;;
7)
cleanall
;;
8)
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
service dnscrypt-proxy stop > /dev/null 2>&1
sleep 3
if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
echo "==> Service is not running!"
exit 1
else
echo " ";
killall -HUP tor && curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 "Your IP address" | sed -e 's/<[^>]*>//g' | xargs
sleep 7
menu
fi
;;
9)
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
touch /usr/bin/anon-service > /dev/null 2>&1
cp $0 /usr/bin/anon-service > /dev/null 2>&1
chmod +x /usr/bin/anon-service
echo -e "\n\n";
echo "==> Now you can run it simply typing \"sudo anon-service\" in your terminal";
sleep 7
menu
;;
*)
echo "==> Are you serious?"
exit 1
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
menu
exit
fi
echo "";
echo "==> Checking dependencies and preparing the system"
#rm -rf $root > /dev/null 2>&1
adduser -q --disabled-password --gecos "" $owner > /dev/null 2>&1
usermod -u 999 $owner > /dev/null 2>&1
mv cpath $root/ > /dev/null 2>&1
mkdir -p $root/temp
chmod -R 777 $root/temp
apt-get update > $root/temp/apt.log
apt-get install -y curl wget psmisc xterm gedit apt-transport-https unbound > /dev/null
sleep 1
clear
echo "==> Which version of Tor do you prefer to use?";
echo "      1.Tor Project repository";
echo "      2.Official repository";
echo "      3.I already have tor installed";
echo " "
echo -n  " Choose: ";
read -e choose
case "$choose"
in 1)
touch $root/temp/distribution.txt
### Tor Project supported distro
cd $root/temp/
curl -L -O https://deb.torproject.org/torproject.org/dists > /dev/null 2>&1
cat dists | sed -e 's/\(^.*\/">\)\(.*\)\(\/<\/a>.*$\)/\2/' | awk '!/</' > distribution.txt
touch $root/temp/os.txt
for target in $(cat $root/temp/distribution.txt)
do
if grep -Fq "$target" $root/temp/apt.log; then
echo $target > $root/temp/os.txt
fi
done
os=$(cat $root/temp/os.txt | sed -e 's/^[ \t]*//')
if [[ "$os" != "focal" ]]; then
echo "";
echo "==> Enabling $os repository";
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
touch $repo
echo "deb https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
echo "deb-src https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
elif [[ "$os" == "focal" ]]; then
echo "==> Enabling $os repository"
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
touch $repo
echo "deb [arch=amd64] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
echo "deb-src [arch=amd64] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
else
echo "";
echo "==> Sorry! Apparently your OS hasn't candidate in Tor Project";
echo "==> repo...Please, re-run the script and choose other options";
exit 1
fi
echo "==> Downloading and importing signing key";
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import > /dev/null 2>&1
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - > /dev/null 2>&1
sleep 1
chown -R $USER:$USER /home/*/.gnupg/
cd
echo "==> Checking repository"; 
apt-get update > $root/temp/apt.log 
sleep 1
if ( grep "torproject.org $os Release" $root/temp/apt.log )
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
   echo "deb https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   echo "deb-src https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   apt-get update > /dev/null
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
   echo 
else
   echo "==> Installing Tor";
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
fi
;;
2)
rm $repo  > /dev/null 2>&1
apt-get update > /dev/null
echo "==> Installing Tor";
apt-get install -y tor > /dev/null 2>&1
;;
3)
echo "==> OK!";
touch $root/installed
;;
*)
echo "==> Are you serious?";
exit 1
esac
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
cd $root
rm -rf $root/temp > /dev/null 2>&1
rm *.md > /dev/null 2>&1
rm *.md* > /dev/null 2>&1
echo "==> Downloading public resolvers list";
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/public-resolvers.md > /dev/null 2>&1
echo "==> Downloading anonymized DNS relays list";
curl -L -O https://download.dnscrypt.info/dnscrypt-resolvers/v3/relays.md > /dev/null 2>&1
### Backup systemd-resolved
if [ ! -s "$root/resolved.bak" ]; then
cp $resolved $root/resolved.bak
fi
### Backup NetworkManager.conf
if [ ! -s "$netman.bak" ]; then
cp $netman $netman.bak
fi
cd $(cat $root/cpath)
}
##
## CONFIGURING SERVICES
##
configure(){
if [ ! -s "$root/dnscrypt-proxy.toml.bak" ]; then
echo "";
echo "==> Sorry! Your system is not ready to complete this action";
echo "==> Please, check if you have installed the necessary files";
sleep 7
menu
exit
fi
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
fi
### Disable tor and unbound starting at boot time
systemctl disable unbound > /dev/null 2>&1
systemctl disable tor > /dev/null 2>&1
### Configuring dnscrypt_proxy
rm $root/dnscrypt-proxy.toml > /dev/null 2>&1
cp $root/dnscrypt-proxy.toml.bak $root/dnscrypt-proxy.toml
echo "";
echo "==> Opening file contain public resolvers";
xterm -T "Resolvers" -e "gedit $root/public-resolvers.md" &
sleep 1
clear
echo "==> Please enter the name of the first resolver to use, only ipv4!";
echo -n "    First server: ";
read -e server1
echo " ";
echo "==> Please enter the name of the second resolver to use, only ipv4!";
echo -n "    Second server: ";
read -e server2
echo "==> Opening file contain relays";
killall gedit > /dev/null 2>&1
xterm -T "Relay" -e "gedit $root/relays.md" &
clear
echo "==> Carefully choose relays/servers so that they are run by different entities!";
echo " ";
echo "==> Please enter the name of the first realy to use!";
echo -n "    First relay for the first server: ";
read -e relay1
echo " ";
echo "==> Please enter the name of the second relay to use!";
echo -n "    Second relay for the first server: ";
read -e relay2
echo " ";
echo "==> Please enter the name of the third resolver to use!";
echo -n "    First relay for the second server: ";
read -e relay3
echo " ";
echo "==> Please enter the name of the fourth resolver to use!";
echo -n "    Second relay for the second server: ";
read -e relay4
killall gedit > /dev/null 2>&1
clear
echo "==> Configuring other services"
sed -i "1iforce_tcp = true" $root/dnscrypt-proxy.toml
sed -i "2iserver_names = ['$server1', '$server2']" $root/dnscrypt-proxy.toml
sed -i 's/127.0.0.1:53/127.0.0.1:10000/g; s/9.9.9.9/208.67.222.222/g; s/8.8.8.8/208.67.220.220/g; s/require_dnssec = false/require_dnssec = true/g; s/force_tcp = false/#force_tcp = false/g; s/skip_incompatible = false/skip_incompatible = true/g' $root/dnscrypt-proxy.toml
sed -i '699iroutes = \[' $root/dnscrypt-proxy.toml
sed -i "700i{ server_name='$server1', via=['$relay1', '$relay2'] }," $root/dnscrypt-proxy.toml
sed -i "701i{ server_name='$server2', via=['$relay3', '$relay4'] }" $root/dnscrypt-proxy.toml
sed -i '702i\]' $root/dnscrypt-proxy.toml
sleep 1
### Configuring Tor
cp $tor $root/torrc
echo "Log notice file $root/notices.log" >> $root/torrc
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> $root/torrc
echo "AutomapHostsOnResolve 1" >> $root/torrc
echo "TransPort 9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort" >> $root/torrc
echo "DNSPort 5353" >> $root/torrc
### Configuring unbound
unbound-anchor > /dev/null 2>&1
sleep 1
echo "server:" > $unbound
echo "tcp-upstream: yes" >> $unbound
echo "domain-insecure: \"onion\"" >> $unbound
echo "private-domain: \"onion\"" >> $unbound
echo "do-not-query-localhost: no" >> $unbound 
echo "interface: 127.0.0.1@53" >> $unbound
#echo "rrset-roundrobin: yes" >> $unbound
echo "local-zone: \"onion.\" transparent" >> $unbound
echo "forward-zone:" >> $unbound
echo "    name: \"onion\"" >> $unbound
echo "    forward-addr: 127.0.0.1@5353" >> $unbound
echo "forward-zone:" >> $unbound
echo "   name: \".\"" >> $unbound
echo "   forward-addr: 127.0.0.1@10000" >> $unbound
#echo "include: \"/etc/unbound/unbound.conf.d/*.conf\"" >> $unbound
### Disabling dnsmasq and configure Network-Manager and systemd-resolved
cp $netman.bak $root/NetworkManager.conf.temp
cd $root
chown $USER:$USER NetworkManager.conf.temp
sed -i 's/^dns=dnsmasq/#&/' NetworkManager.conf.temp
sed '/\[main\]/a dns=default' NetworkManager.conf.temp > NetworkManager.conf
if [[ -s "$resolved" ]]; then
cp $resolved $root/resolved.conf.temp
chown $USER:$USER resolved.conf.temp
sed -i 's/^DNSStubListener=yes/#&/' resolved.conf.temp
echo "DNSStubListener=no" >> resolved.conf.temp
fi
cd $(cat $root/cpath)
}
##
## Starting services and configuring iptables
##
start_service(){
### Checking for required files
if [ ! -s "$root/dnscrypt-proxy.toml" ]; then
echo "";
echo "==> Sorry! Your system is not ready to start the service...";
echo "==> Please, check if you have installed the necessary files";
sleep 7
menu
exit
fi
if [ -s "cpath" ]; then
mv cpath $root/ > /dev/null 2>&1
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
### Configure Network-Manager
cd $root
cp resolved.conf.temp $resolved 
chown root:root $resolved
cp NetworkManager.conf $netman
chown root:root $netman
service dnsmasq stop > /dev/null 2>&1
service bind stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
killall dnsmasq bind > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1 
sleep 1
cd $root
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
echo "";
echo "==> Please change your DNS system setting to 127.0.0.1 and then press ENTER";
read REPLY
clear
echo "==> Starting anon-service";
service systemd-resolved restart
service network-manager restart
sleep 10
chown -R $owner:$owner $root
nohup xterm -T "Dnscrypt-proxy" -e su - $owner -c "./dnscrypt-proxy" > /dev/null 2>&1 &
sleep 1
rm $root/notices.log > /dev/null 2>&1
touch $root/notices.log
chown anon-service:anon-service $root/notices.log
nohup xterm -T "Tor" -e su - $owner -c "tor -f $root/torrc" > /dev/null 2>&1 &
echo "==> Checking connection to Tor";
SECONDS=0
secs=39
while (( SECONDS < secs ));
do
if (grep -Fq "100%" $root/notices.log ); then 
break
fi
done
rm $root/notices.log > /dev/null 2>&1
### Configuring basic iptables rules
### Reference: https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy
# Destinations you don't want routed through Tor
_non_tor="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
# Other IANA reserved blocks (These are not processed by tor and dropped by default)
_resv_iana="0.0.0.0/8 100.64.0.0/10 169.254.0.0/16 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255/32"
# The UID that Tor runs as (varies from system to system)
_tor_uid="$(id -u debian-tor)"
# Tor's VirtualAddrNetworkIPv4
_virt_addr="10.192.0.0/10"
# Tor's TransPort
_trans_port="9040"
iptables -F
iptables -t nat -F
iptables -t nat -A OUTPUT -d $_virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $_trans_port
iptables -A OUTPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A OUTPUT -m owner --uid-owner $_tor_uid -j RETURN
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53
for _clearnet in $_non_tor; do
iptables -t nat -A OUTPUT -d $_clearnet -j RETURN
done
for _iana in $_resv_iana; do
  iptables -t nat -A OUTPUT -d $_iana -j RETURN
done
iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
for _lan in $_non_tor; do
iptables -A INPUT -s $_lan -j ACCEPT
done
sleep 15
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $_trans_port
for _clearnet in $_non_tor; do
iptables -A OUTPUT -d $_clearnet -j ACCEPT
done
sleep 3
iptables -A OUTPUT -m owner --uid-owner $_tor_uid -j ACCEPT
sleep 2
iptables -A OUTPUT -j DROP
sleep 1
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
unbound &
echo -e "\n";
### Checking services
if ! pgrep -x "tor" > /dev/null; then
echo "==> Sorry! No connection to TOR...Please, report this issue to the project";
sleep 7
cleanall
fi
if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
echo "==> Sorry! Dnscrypt-proxy isn't running...Please, report this issue to the project";
sleep 7
cleanall
fi
if ! pgrep -x "unbound" > /dev/null; then
echo "==> Sorry! Unbound isn't running...Please, report this issue to the project";
sleep 7
cleanall
else
echo "==> Congratulations! Your system is configurated to use Tor and DNSCrypt";
sleep 5
fi
cd $(cat $root/cpath)
}
##
## Exit
##
shutdown_service(){
clear
service dnscrypt-proxy stop > /dev/null 2>&1
sleep 3
if ! pgrep -x "dnscrypt-proxy" > /dev/null; then
echo "==> Service is not running!";
echo "==> Restoring original files"; 
sleep 7
else
echo "==> Stopping anon-service";
sleep 7
fi
rm $root/tor.txt > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service tor stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
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
service network-manager restart
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
killall unbound tor dnscrypt-proxy xterm > /dev/null 2>&1
if [[ -s "$root/resolved.bak" ]]; then
cp $root/resolved.bak $resolved > /dev/null 2>&1
service systemd-resolved restart
fi
if [[ -s "$netman.bak" ]]; then
cp $netman.bak $netman > /dev/null 2>&1
fi
rm /usr/bin/anon-service > /dev/null 2>&1
service systemd-resolved restart
service network-manager restart
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
rm /etc/network/if-up.d/anon-service > /dev/null 2>&1
if [[ -s "$root/installed" ]]; then
apt-get remove -y unbound > /dev/null 2>&1
else
apt-get remove -y unbound tor > /dev/null 2>&1
fi
apt-get clean > /dev/null
apt-get -y autoremove > /dev/null 2>&1
apt-get -y autoclean > /dev/null 2>&1
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
echo "==> If you want this, please remove manually the Tor Project signing key";
echo "    ____________________________________________________________________";
echo " "
echo "    +++ Have a nice day! ;) +++";
echo -e "\n\n";
exit 0
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
### Checking for required files
if [ -s $root/dnscrypt-proxy.toml ]; then
wmctrl -r ':ACTIVE:' -e 0,0,0,840,530 && sleep 1
wmctrl -r ':ACTIVE:' -e 0,0,0,841,531 && menu
else
### Checking for network connection and installing wmctrl
rm conn.txt > /dev/null 2>&1
ping -c1 opendns.com > conn.txt 2>&1
if ( grep -q "icmp_seq=1" conn.txt ); then
clear
rm conn.txt > /dev/null 2>&1
apt-get update > /dev/null
apt-get install -y wmctrl > /dev/null
sleep 1
wmctrl -r ':ACTIVE:' -e 0,0,0,840,530 && sleep 1
wmctrl -r ':ACTIVE:' -e 0,0,0,841,531 && menu
else
rm conn.txt > /dev/null 2>&1
rm cpath > /dev/null 2>&1
echo "==> Please first connect your system to internet!";
exit 1   
fi
fi
