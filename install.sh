#!/bin/bash
wan=$(ip -f inet -o addr show enp0s3|cut -d\  -f 7 | cut -d/ -f 1)
wlan=$(ip -f inet -o addr show wlan0|cut -d\  -f 7 | cut -d/ -f 1)
ppp1=$(/sbin/ip route | awk '/default/ { print $3 }')
ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Installing pptpd
echo "Installing PPTPD"
sudo apt-get install pptpd -y

# edit DNS
echo "Setting Google DNS"
sudo echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options
sudo echo "ms-dns 8.8.4.4" >> /etc/ppp/pptpd-options

# Edit PPTP Configuration
echo "Editing PPTP Configuration"
remote="$ppp1"
remote+="0-200"
sudo echo "localip $ppp1" >> /etc/pptpd.conf
sudo echo "remoteip $remote" >> /etc/pptpd.conf

# Enabling IP forwarding in PPTP server
echo "Enabling IP forwarding in PPTP server"
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo sysctl -p

# Tinkering in Firewall
echo "Tinkering in Firewall"
if [ -z "$wan" ]
	then
		sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE && iptables-save
		sudo iptables --table nat --append POSTROUTING --out-interface ppp0 -j MASQUERADE
		$("sudo iptables -I INPUT -s $ip/8 -i ppp0 -j ACCEPT")
		sudo iptables --append FORWARD --in-interface wlan0 -j ACCEPT
	else
		sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE && iptables-save
		sudo iptables --table nat --append POSTROUTING --out-interface ppp0 -j MASQUERADE
		$("sudo iptables -I INPUT -s $ip/8 -i ppp0 -j ACCEPT")
		sudo iptables --append FORWARD --in-interface enp0s3 -j ACCEPT
fi

clear

# Adding VPN Users
echo "Set username:"
read username
echo "Set Password:"
read password
sudo echo "$username * $password *" >> /etc/ppp/chap-secrets

# Restarting Service 
sudo service pptpd restart



echo "Acquire::GzipIndexes \"false\"; Acquire::CompressionTypes::Order:: \"gz\";" >/etc/apt/apt.conf.d/docker-gzip-indexes && \
 sed -i s/archive.ubuntu.com/ftp.sjtu.edu.cn/g /etc/apt/sources.list && \
 sed -i s/security.ubuntu.com/ftp.sjtu.edu.cn/g /etc/apt/sources.list && \
 apt update && \
 apt -y upgrade && \
 apt -y dist-upgrade && \
 apt -y install pptpd ntp ntpdate net-tools iputils-ping wget python2 && \
 apt -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions unzip locales && \
 apt -y install libglib2.0-0 libglib2.0-data libicu70 libxml2 shared-mime-info xdg-user-dirs && \
 dpkg-reconfigure locales && \
 locale-gen C.UTF-8 && \
 /usr/sbin/update-locale LANG=C.UTF-8 && \
 wget http://prdownloads.sourceforge.net/webadmin/webmin_2.001_all.deb && \
 dpkg --install webmin_2.001_all.deb && \
 apt -y install -f  && \
 
echo "Starting Webmin Service ..."
    /usr/sbin/service webmin restart
 /usr/share/webmin/changepass.pl /etc/webmin root pass
 
echo "All done!"
