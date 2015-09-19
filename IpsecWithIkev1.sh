#!/bin/sh
apt-get update
apt-get install build-essential libgmp3-dev libgmp-dev openssl libssl-dev -y

wget http://download.strongswan.org/strongswan.tar.gz
tar zxvf strongswan*
cd strongswan-*

./configure --sysconfdir=/etc --disable-sql --disable-mysql --disable-ldap --enable-dhcp --enable-eap-identity --enable-eap-mschapv2 --enable-md4 --enable-xauth-eap --enable-eap-peap --enable-eap-md5 --enable-openssl --enable-shared --enable-unity --enable-eap-tls --enable-eap-ttls --enable-eap-tnc --enable-eap-dynamic --enable-addrblock --enable-eap-radius --enable-radattr --enable-nat-transport --enable-cisco-quirks --enable-kernel-netlink --enable-kernel-libipsec

make && make install

cat > /etc/ipsec.conf<<EOF
config setup
        uniqueids=never
conn ikev1
        keyexchange=ikev1
        authby=xauthpsk
        xauth=server
        left=%defaultroute
        leftsubnet=0.0.0.0/0
        leftfirewall=yes
        right=%any
        rightsourceip=10.0.0.0/24
        auto=add
EOF

cat > /etc/strongswan.conf<<EOF
charon {
        duplicheck.enable = no
        install_virtual_ip = yes
        dns1 = 8.8.8.8
        dns2 = 8.8.4.4
        load_modular = yes
        plugins {
                include strongswan.d/charon/*.conf
        }
}

include strongswan.d/*.conf
EOF

cat > /etc/ipsec.secrets<<EOF
: PSK "YourPSKHere"
accountNameHere : XAUTH "passwdForAccountHere"
EOF

iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o venet0 -j MASQUERADE
iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT

iptables-save > /etc/iptables.rules

cat > /etc/network/if-up.d/iptables<<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
ipsec start
EOF

chmod +x /etc/network/if-up.d/iptables

ipsec start
