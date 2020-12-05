#!/usr/bin/env bash

# #####################################################################
# anon-service.sh
# version 1.0
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
## If necessary, change the path according to your system
netman=/etc/NetworkManager/NetworkManager.conf
resolved=/etc/systemd/resolved.conf
tor=/etc/tor/torrc
unbound=/etc/unbound/unbound.conf
## If Tor stucks before 100%, try to increase this value
time=19

menu(){
echo "                                                            ";
echo "             ▄▄▄      ███▄    █ ▒█████   ███▄    █          ";
echo "            ▒████▄    ██ ▀█   █▒██▒  ██▒ ██ ▀█   █          ";
echo "            ▒██  ▀█▄ ▓██  ▀█ ██▒██░  ██▒▓██  ▀█ ██▒         ";
echo "            ░██▄▄▄▄██▓██▒  ▐▌██▒██   ██░▓██▒  ▐▌██▒         ";
echo "             ▓█   ▓██▒██░   ▓██░ ████▓▒░▒██░   ▓██░         ";
echo "         ██████ ▓█████  ██▀███░  ██▒ ░ █▓ ██▓ ▄████▄ ▓█████ ";
echo "       ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓██▒▒██▀ ▀█ ▓█   ▀ ";
echo "       ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒██▒▒▓█    ▄▒███   ";
echo "         ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░░██░▒▓▓▄ ▄██▒▓█  ▄ ";
echo "       ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░██░▒ ▓███▀ ░▒████▒";
echo "             ░           ░           ░       ░ by bit4mind  ";
echo " "
echo "   1. Check dependencies and download upgraded services";
echo "   2. Edit public servers and relays for anonymized DNS"; 
echo "      feature and configure other service";
echo "   3. Start anon-service";
echo "   4. Execute all tasks above";
echo "   5. Close this window";
echo "   6. Stop anon-service and exit without removing data files and settings";
echo "   7. Exit removing anon-service files and settings from system";
echo -e "\n"
echo -n "  Choose: ";
read -e task
case "$task" in  
1)
download
clear
menu
;;
2)
configure
clear
menu
;;
3)
start
clear
menu
;;
4)
download
configure
start
clear
menu
;;
5)
xdotool windowkill `xdotool getactivewindow`
;;
6)
shutdown
;;
7)
cleanall
;;
*)
echo "--- Are you serious? ---"
exit 1
esac
}
##
##  Checking dependencies and downloading upgraded services
##
download(){
echo "+++ Checking dependencies and preparing the system +++"
rm -rf $root > /dev/null 2>&1
adduser -q --disabled-password --gecos "" $owner > /dev/null 2>&1
usermod -u 999 $owner > /dev/null 2>&1
mkdir -p $root/temp
chmod -R 777 $root/temp
apt-get update > $root/temp/apt.log
apt-get install -y curl wget psmisc xdotool xterm gedit apt-transport-https unbound > /dev/null
sleep 1
clear
echo " Which version of Tor do you prefer to use?";
echo "   1.Tor Project repository";
echo "   2.Official repository";
echo "   3.I already have tor installed";
echo " "
echo -n  " Choose: ";
read -e choose
case "$choose"
in 1)
touch $root/temp/distribution.txt
echo -e "bionic\nbullseye\nbuster\neoan\nfocal\ngroovy\njessie\nsid\nstretch\nxenial\n\n" > $root/temp/distribution.txt
touch $root/temp/os.txt
for target in $(cat $root/temp/distribution.txt)
do
if grep -Fq "$target" $root/temp/apt.log; then
echo $target > $root/temp/os.txt
fi
done
os=$(cat $root/temp/os.txt | sed -e 's/^[ \t]*//')
if [[ "$os" != "focal" ]]; then
echo "+++ Enabling $os repository +++";
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
touch $repo
echo "deb https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
echo "deb-src https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
elif [[ "$os" == "focal" ]]; then
echo "+++ Enabling $os repository +++"
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
touch $repo
echo "deb [arch=amd64] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
echo "deb-src [arch=amd64] https://deb.torproject.org/torproject.org $os main" | tee -a $repo > /dev/null
else
echo "Sorry! Apparently your OS has not candidate in Tor Project repository.";
echo "Please re-run the script and choose other options.";
exit 1
fi
cd $root/temp/
echo "+++ Downloading and importing signing key +++";
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import > /dev/null 2>&1
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - > /dev/null 2>&1
sleep 1
chown -R $USER:$USER /home/*/.gnupg/
cd
echo "+++ Checking repository +++"; 
apt-get update > $root/temp/apt.log 
sleep 1
if ( grep "torproject.org $os Release" $root/temp/apt.log )
then
   echo "Sorry! The script can't obtain the correct codename for your OS";
   echo "Please try to enter the correct codename for the debian/ubuntu repository";
   echo "compatible with your OS. In doubt search on internet!";
   echo "Warning: if the repository is not correct, the script could crash!"; 
   echo -n "(for example: buster): ";
   read -e codename 
   rm $repo
   touch $repo
   echo "deb https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   echo "deb-src https://deb.torproject.org/torproject.org $codename main" | tee -a $repo > /dev/null
   apt-get update > /dev/null
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
   echo 
else
   echo "+++ Installing Tor +++";
   apt-get install -y tor deb.torproject.org-keyring > /dev/null 2>&1
fi
;;
2)
rm $repo  > /dev/null 2>&1
apt-get update > /dev/null
echo "+++ Installing Tor +++";
apt-get install -y tor > /dev/null 2>&1
;;
3)
echo "+++ OK! +++";
;;
*)
echo "--- Are you serious? ---";
exit 1
esac
touch $root/temp/arch.txt > /dev/null
uname -a > $root/temp/arch.txt
if ( grep -Fq "x86_64" $root/temp/arch.txt ); then
   cd $root/temp/
echo "+++ Downloading dnscrypt-proxy +++";
   wget -q https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.44/dnscrypt-proxy-linux_x86_64-2.0.44.tar.gz
else
   cd $root/temp/
echo "+++ Downloading dnscrypt-proxy +++";
   wget -q https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.44/dnscrypt-proxy-linux_i386-2.0.44.tar.gz
fi
tar -xf dnscrypt-proxy-linux_*.tar.gz
cp linux-*/dnscrypt-proxy $root
cp linux-*/example-dnscrypt-proxy.toml $root/dnscrypt-proxy.toml.bak
cp linux-*/localhost.pem $root
cd $root
rm -rf $root/temp > /dev/null 2>&1
rm *.md > /dev/null 2>&1
rm *.md* > /dev/null 2>&1
echo "+++ Downloading public resolvers list +++";
wget -q https://download.dnscrypt.info/dnscrypt-resolvers/v3/public-resolvers.md
echo "+++ Downloading anonymized DNS relays list +++";
wget -q https://download.dnscrypt.info/dnscrypt-resolvers/v3/relays.md
## Backup systemd-resolved
cp $resolved $root/resolved.bak
## Backup NetworkManager.conf
cp $netman $netman.bak
}
##
## CONFIGURING SERVICES
##
configure(){
if [ ! -f "$root" ]; then
echo "";
echo "Sorry! Your system is not ready to complete this action";
echo "Please first check if you have installed the necessary files";
exit 1
fi
## Configuring dnscrypt_proxy
rm $root/dnscrypt-proxy.toml > /dev/null 2>&1
cp $root/dnscrypt-proxy.toml.bak $root/dnscrypt-proxy.toml
cp $root/resolved.bak $resolved
echo "+++ Opening file contain public resolvers +++";
xterm -T "Resolvers" -e "gedit $root/public-resolvers.md" &
sleep 1
clear
echo " "
echo "Please enter the name of the first resolver to use, only ipv4!";
echo -n "First server: ";
read -e server1
echo " "
echo "Please enter the name of the second resolver to use, only ipv4!";
echo -n "Second server: ";
read -e server2
echo "+++ Opening file contain relays +++";
killall gedit > /dev/null 2>&1
xterm -T "Relay" -e "gedit $root/relays.md" &
clear
echo " "
echo "Carefully choose relays and servers so that they are run by different entities!";
echo " "
echo "Please enter the name of the first realy to use!";
echo -n "First relay for the first server: ";
read -e relay1
echo " "
echo "Please enter the name of the second relay to use!";
echo -n "Second relay for the first server: ";
read -e relay2
echo " "
echo "Please enter the name of the third resolver to use!";
echo -n "First relay for the second server: ";
read -e relay3
echo " "
echo "Please enter the name of the fourth resolver to use!";
echo -n "Second relay for the second server: ";
read -e relay4
killall gedit > /dev/null 2>&1
clear
echo "+++ Configuring other services +++"
sed -i "1iserver_names = ['$server1', '$server2']" $root/dnscrypt-proxy.toml
sed -i 's/127.0.0.1:53/127.0.0.1:10000/g; s/9.9.9.9/208.67.222.222/g; s/8.8.8.8/208.67.220.220/g; s/require_dnssec = false/require_dnssec = true/g; s/force_tcp = false/force_tcp = true/g; s/skip_incompatible = false/skip_incompatible = true/g' $root/dnscrypt-proxy.toml
sed -i '699iroutes = \[' $root/dnscrypt-proxy.toml
sed -i "700i{ server_name='$server1', via=['$relay1', '$relay2'] }," $root/dnscrypt-proxy.toml
sed -i "701i{ server_name='$server2', via=['$relay3', '$relay4'] }" $root/dnscrypt-proxy.toml
sed -i '702i\]' $root/dnscrypt-proxy.toml
## Disabling dnsmasq
cp $netman.bak $root/NetworkManager.conf.temp
cd $root
chown $USER:$USER NetworkManager.conf.temp
sed -i 's/^dns=dnsmasq/#&/' NetworkManager.conf.temp
#sed -i 's/^dns=default/#&/' NetworkManager.conf.temp
sed '/\[main\]/a dns=default' NetworkManager.conf.temp > NetworkManager.conf
mv NetworkManager.conf $netman
if [[ -f "$resolved" ]]; then
cp $resolved $resolved.bak
cp $resolved $root/resolved.conf.temp
chown $USER:$USER resolved.conf.temp
sed -i 's/^DNSStubListener=yes/#&/' resolved.conf.temp
echo "DNSStubListener=no" >> resolved.conf.temp
cp resolved.conf.temp $resolved
fi
service dnsmasq stop > /dev/null 2>&1
service bind stop > /dev/null 2>&1
#service dnscrypt-proxy stop
killall dnsmasq bind > /dev/null 2>&1
rm /etc/resolv.conf 
sleep 1
## Configuring Tor
cp $tor $root/torrc
echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> $root/torrc
echo "AutomapHostsOnResolve 1" >> $root/torrc
echo "TransPort 9040" >> $root/torrc
echo "DNSPort 5353" >> $root/torrc
## Configuring unbound
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
}
##
## Starting services and configuring iptables
##
start(){
if [ ! -f "$root" ]; then
echo "";
echo "Sorry! Your system is not ready to start the service";
echo "Please first check if you have installed the necessary files";
exit 1
fi
cd $root
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
cp resolved.conf.temp $resolved > /dev/null 2>&1
rm /etc/resolv.conf > /dev/null 2>&1
echo -e "\n\n"
echo "   Please change your DNS system setting to 127.0.0.1 and then press ENTER";
read REPLY
clear
echo "+++ Starting anon-service +++";
service systemd-resolved restart
service network-manager restart
sleep 13
xterm -e unbound &
chown -R $owner:$owner $root
xterm -T "Tor" -e su - $owner -c "tor -f $root/torrc" &
xterm -T "Dnscrypt-proxy" -e ./dnscrypt-proxy &
echo "Checking connection to Tor";
rm $root/tor.log > /dev/null 2>&1
until [ -s $root/tor.log ]
do
sleep $time
curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs > $root/tor.log
torlogsize=$(stat -c%s $root/tor.log)
if (( $torlogsize > 1 )); then
sed -i 's/browser/system/g' $root/tor.log
cat $root/tor.log
sleep 3
else
echo "Waiting for connection...";
rm $root/tor.log > /dev/null 2>&1
fi
done
rm $root/tor.log > /dev/null 2>&1
## Configuring basic iptables rules
## Reference: https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy
# destinations you don't want routed through Tor
_non_tor="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
# the UID that Tor runs as (varies from system to system)
_tor_uid="$(id -u debian-tor)"
# Tor's TransPort
_trans_port="9040"
iptables -F
iptables -t nat -F
iptables -A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,FIN ACK,FIN -j DROP
iptables -A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,RST ACK,RST -j DROP
iptables -t nat -A OUTPUT -m owner --uid-owner $_tor_uid -j RETURN
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53
for _clearnet in $_non_tor; do
iptables -t nat -A OUTPUT -d $_clearnet -j RETURN
done
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $_trans_port
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
for _clearnet in $_non_tor; do
iptables -A OUTPUT -d $_clearnet -j ACCEPT
done
iptables -A OUTPUT -m owner --uid-owner $_tor_uid -j ACCEPT
iptables -A OUTPUT -j REJECT
}
##
## Exit
##
shutdown(){
clear
echo "+++ Stopping anon-service +++";
rm $root/tor.txt > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service tor stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy > /dev/null 2>&1
if [[ -f "$root/resolved.bak" ]]; then
cp $root/resolved.bak $resolved > /dev/null 2>&1
fi
if [[ -f "$netman.bak" ]]; then
cp $netman.bak $netman > /dev/null 2>&1
fi
service systemd-resolved restart
service network-manager restart
iptables -F
iptables -t nat -F
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain 
iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
exit 0
}
##
## Cleaning all and exit
##
cleanall(){
clear
echo "+++ Removing anon-service files and settings from system +++";
service tor stop > /dev/null 2>&1
service dnscrypt-proxy stop > /dev/null 2>&1
service unbound stop > /dev/null 2>&1
killall unbound tor dnscrypt-proxy xterm > /dev/null 2>&1
if [[ -f "$root/resolved.bak" ]]; then
cp $root/resolved.bak $resolved > /dev/null 2>&1
service systemd-resolved restart
fi
if [[ -f "$netman.bak" ]]; then
cp $netman.bak $netman > /dev/null 2>&1
fi
service systemd-resolved restart
service network-manager restart
rm $repo > /dev/null 2>&1
rm $repo* > /dev/null 2>&1
apt-get remove -y tor unbound > /dev/null 2>&1
apt-get clean > /dev/null
apt-get -y autoremove > /dev/null 2>&1
apt-get -y autoclean > /dev/null 2>&1
userdel -r $owner > /dev/null 2>&1
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
echo "    If you want this, please remove manually the Tor Project signing key";
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
if [ -s $root/dnscrypt-proxy.toml ]; then
wmctrl -r ':ACTIVE:' -e 0,0,0,780,570 && sleep 1
wmctrl -r ':ACTIVE:' -e 0,0,0,781,571 && menu
else
rm conn.txt > /dev/null 2>&1
ping -c1 opendns.com > conn.txt 2>&1
if ( grep -q "icmp_seq=1" conn.txt ); then
clear
rm conn.txt > /dev/null 2>&1
apt-get install -y wmctrl > /dev/null
wmctrl -r ':ACTIVE:' -e 0,0,0,780,570 && sleep 1
wmctrl -r ':ACTIVE:' -e 0,0,0,781,571 && menu
else
echo "          Please first connect your system to internet!";
exit 1   
fi
fi

