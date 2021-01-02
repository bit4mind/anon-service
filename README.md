# anon-service
### WARNING: this is an old version! You should use the latest version! If you want to continue with this version (if necessary) update the DNSCrypt-proxy version number (line 32) and update line 127 with the supported distros present in the TOR project repository (https://deb.torproject.org/torproject.org/dists)

Transparent proxy through Tor with DNSCrypt and Anonymized DNS feature enabled.

From Wikipedia: Tor is free and open-source software for enabling anonymous
communication by directing Internet traffic through a free, worldwide, volunteer
overlay network consisting of more than seven thousand relays in order to 
conceal a user's location and usage from anyone conducting network surveillance
or traffic analysis. Using Tor makes it more difficult to trace Internet
activity to the user: this includes "visits to Web sites, online posts, instant 
messages, and other communication forms".

The task of this script is to redirect outgoing connections through "The Onion 
Router" network and to provide encryption/authentication to DNS traffic in the 
clearnet via dnscrycpt/DNSSEC, leaving the resolution of onion domains to the 
Tor DNS resolvers.
All applications will use the TOR network even if they do not support SOCKS.
The script supports anonymized DNS feature and is able to find the correct 
version for your distribution by downloading it directly from the TOR Project 
repository.




## REQUIREMENTS

The script should work on many debian-based distros with network-manager installed and 
the unbound package present in the repositories. Tested on Debian, Ubuntu, Mint.



## HOW IT WORKS

The script works as a launcher: after installing the necessary software, you can 
reconfigure resolvers and relays before each reactivation of the service or you can
stop the service without deleting the data and then reactivate it faster without 
having to install the requirements again and reconfigure DNS traffic.
In the next version will be added the possibility to install and enable the script 
as a real service at startup.

Usage:

```
chmod +x anon-service.sh
```
```
sudo ./anon-service.sh
```

### Important: 
If something goes wrong or you just want to update the script, first remove all
files and settings using the appropriate option in the same script.


### WARNING

This is NOT a solution that grants strong anonymity and the developers themselves 
do not recommend using tor as a trasparent proxy
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
The real benefits of using this script derive from the security of DNS traffic: 
dnscrypt makes spying, spoofing and man-in-the-middle attacks difficult.
If you are looking for a strong anonymity solution, switch to Linux distributions 
focused on security and privacy like Whomix or Tails.



## TROUBLESHOTTING AND WORKAROUND

This script may not work properly if used on a not-fully updated system.

Tor stucks before 100% and connection not works: try to increase time value 
at the beginning of a script.

Unbound package not found: update your system or install it before.
