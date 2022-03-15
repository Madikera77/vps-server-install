### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

#!/bin/sh

echo "Configuration du Firewall Iptables..."
echo "Si vous effectuez cette configuration sur un serveur distant via SSH, vous risquez d'être déconnecté."
echo "Ne vous inquietez pas, le script continue. Veuillez juste vous reconnecter."

# Réinitialise les règles
sudo iptables -t filter -F
sudo iptables -t filter -X

# Bloque tout le trafic
sudo iptables -t filter -P INPUT DROP
sudo iptables -t filter -P FORWARD DROP
sudo iptables -t filter -P OUTPUT DROP

# Autorise les connexions déjà établies et localhost
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -o lo -j ACCEPT

# ICMP (Ping)
sudo iptables -t filter -A INPUT -p icmp -j ACCEPT
sudo iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# SSH
sudo iptables -t filter -A INPUT -p tcp --dport 2222 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 2222 -j ACCEPT

# DNS
sudo iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

# HTTP
sudo iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT

# HTTPS
sudo iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT

# FTP
sudo iptables -t filter -A OUTPUT -p tcp --dport 20:21 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 20:21 -j ACCEPT

# Mail SMTP
sudo iptables -t filter -A INPUT -p tcp --dport 25 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 25 -j ACCEPT

# Mail POP3
sudo iptables -t filter -A INPUT -p tcp --dport 110 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 110 -j ACCEPT

# Mail IMAP
sudo iptables -t filter -A INPUT -p tcp --dport 143 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 143 -j ACCEPT

# NTP (horloge du serveur)
sudo iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT

#Limit flood
sudo iptables -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT
sudo iptables -A FORWARD -p udp -m limit --limit 1/second -j ACCEPT
sudo iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT

#Limit scan
sudo iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT

# git !
sudo iptables -A OUTPUT -o eth0 -p tcp --dport 9418 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -o eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i eth0 -p tcp --sport 9418 -m state --state ESTABLISHED -j ACCEPT

# keymetrics
sudo iptables -t filter -A INPUT -p tcp --dport 43554 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 43554 -j ACCEPT

# Affichage des nouvelles règles
echo -e "\n"
sudo iptables -L -v
echo -e "\n"

# Sauvegarde de la configuration
sudo /sbin/iptables-save
echo -e "\nLa configuration a été sauvegardé."