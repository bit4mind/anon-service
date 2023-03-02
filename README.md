# anon-service

Transparent proxy through Tor with optionally DNSCrypt and Anonymized-DNS feature enabled.

From Wikipedia: Tor is free and open-source software for enabling anonymous
communication by directing Internet traffic through a free, worldwide, volunteer
overlay network consisting of more than seven thousand relays in order to 
conceal a user's location and usage from anyone conducting network surveillance
or traffic analysis. Using Tor makes it more difficult to trace Internet
activity to the user: this includes "visits to Web sites, online posts, instant 
messages, and other communication forms".
The task of this script is to redirect outgoing connections through "The Onion 
Router" network and optionally to provide encryption/authentication to DNS traffic 
in the clearnet via dnscrycpt/DNSSEC, leaving the resolution of onion domains to the 
Tor DNS resolvers.
All applications will use the TOR network even if they do not support SOCKS.
The script supports Anonymized-DNS feature and is able to find the correct 
version for your distribution by downloading it directly from the TOR Project 
repository.



## REQUIREMENTS


The script should work on many debian-based distros (desktop and server) with the Unbound package present 
in the repositories. Tested on Debian, Ubuntu, Mint.



## HOW IT WORKS
You can execute all tasks via command-line or via the interactive menu.
The default mode (starting the script without any options) is the interactive menu.
The interactive menu works as a launcher: after installing the necessary software, you can select
the transparent proxy type or reconfigure resolvers/relays before each 
reactivation of the service; you can stop the service without deleting the data
and then reactivate it faster.
You can install it to start automatically at boot: in this case you could restart
service simply restarting your connection and continue to use the script for
editing configuration file, configuring dnscrypt servers and relays or removing all things.
Editing torrc file you can customize your tor configuration (https://tor.void.gr/docs/tor-manual.html.en).
Editing iptables rules you can grant yourself ssh access from remote machines and other stuff.

Usage:

```
chmod +x anon-service.sh
```
```
sudo ./anon-service.sh --help

 ./anon-service.sh [option] <value> <server1> <server2> <relay1> <relay2> <relay3> <relay4>

Options:
 --download  <value>  check dependencies and download them
                      <value> Tor from: -1 Tor Project repository
                      -2 OS repository -3 already installed
 --configure <value>  choose transparent proxy type
                      <value> -1 standard -2 with DNSCrypt
 --start              start service
 --stop               exit without removing service files and settings
 --restart            restart service
 --status             display status service
 --menu               display interactive menu
 --install            install this script
 --permanent          enable service to start automatically at boot
 --remove             exit removing files and settings from system
 --edit      <value>  edit configuraion files
                      <value> torrc or iptables
 --restore            restore original files and settings
 
 --help               display this help
 --version            display version
```
Examples:

```
sudo ./anon-service.sh --download -1 && sudo ./anon-service.sh --configure -1 && sudo ./anon-service.sh --start
```

This will start the service in standard transparent proxy mode getting Tor from the official project repository
```
sudo ./anon-service.sh --download -1 && sudo ./anon-service.sh --configure -2 dnscrypt-de-blahdns-ipv4 meganerd anon-acsacsar-ams-ipv4 anon-openinternet anon-v.dnscrypt.uk-ipv4 anon-sth-se && sudo ./anon-service.sh --start
```
This will start the service with DNSCrypt and the Anonymized-DNS feature enabled by obtaining Tor from the official
project repository. Change servers and relays to whatever you want based on the updated list of public resolvers 
and relays provided by the dnscrypt-proxy project

### Important: 
If you want to update the script, first remove all files and settings using the 
appropriate option in the same script.

NOTES:
The command-line download option will install the software required to run without 
a graphical environment: some options in the interactive menu may not work.
If you install the script to start automatically at boot, be aware that the service 
will start with a small delay after the host has established the connection to the 
network. Before the service is fully loaded, the connection will not work: you can 
check status via syslog with the command:

```
tail -f /var/log/syslog
```

If you enable service to start automatically at boot, will be configured
the last type of trasparent proxy used.

### WARNING

This is NOT a solution that grants strong anonymity and the developers themselves 
do not recommend using tor as a transparent proxy
(https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy).
When you browse the web even if you do not use personal data and hide your IP address,
traces are left that can uniquely identify your machine such as the hostname and mac 
address of the network device. Your browser itself can uniquely identify you: from 
the point of view of tracking/fingerprinting Tor browser guarantees greater security 
because it already comes with built-in fixes and extensions like Noscript and HTTPS 
Everywhere, useful to avoid some attacks and tracking methods.
However you could still use Tor browser (without DNSCrypt/DNSSEC) even while the
service is running, but this scenario is also not recommended
(https://trac.torproject.org/projects/tor/wiki/doc/TorifyHOWTO#ToroverTor).
If you are looking for a strong anonymity solution, switch to Linux distributions 
focused on security and privacy like Whomix or Tails.

## TROUBLESHOTTING

System update may create permissions issues with Unbound: first remove Unbound package purging
the configuration files, then reinstall it and reconfigure the service via the 
dedicated option.
If something goes wrong (e.g. electrical blackout) restore the original data and settings
using the dedicated option or remove the service.
This script may not work properly on a not-fully updated system.
