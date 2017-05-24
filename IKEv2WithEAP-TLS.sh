#!/bin/sh
apt-get update
apt-get install build-essential libgmp3-dev libgmp-dev openssl libssl-dev -y

wget https://download.strongswan.org/strongswan-5.5.2.tar.gz
tar zxvf strongswan-5.5.2.tar.gz
cd strongswan-5.5.2

./configure --sysconfdir=/etc --enable-eap-mschapv2 --enable-eap-identity --enable-md4 --enable-eap-tls
#openVZ virtualization should configure with this option: --enable-kernel-libipsec
make && make install

#you can replace C,O with anything you want, but they should be kept the same in those certs.
#replace ikev2.wbuntu.me with your server's domain name
#replace client.wbuntu.me with your url for client
ipsec pki --gen --outform pem > caKey.pem
ipsec pki --self --in caKey.pem --dn "C=CH, O=Wbuntu, CN=Wbuntu CA" --ca --outform pem > caCert.pem

ipsec pki --gen --outform pem > serverKey.pem
ipsec pki --pub --in serverKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=CH, O=Wbuntu, CN=ikev2.wbuntu.me" --san="ikev2.wbuntu.me" --flag serverAuth --outform pem > serverCert.pem

#you have to add a password for clientCert
ipsec pki --gen --outform pem > clientKey.pem
ipsec pki --pub --in clientKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=CH, O=Wbuntu, CN=client.wbuntu.me" --san="client.wbuntu.me" --flag clientAuth --outform pem > clientCert.pem
openssl pkcs12 -export -inkey clientKey.pem -in clientCert.pem -name "client.wbuntu.me" -certfile caCert.pem -caname "Wbuntu CA" -out clientCert.p12

cp caCert.pem /etc/ipsec.d/cacerts/
cp serverCert.pem /etc/ipsec.d/certs/
cp serverKey.pem /etc/ipsec.d/private/
cp clientCert.pem /etc/ipsec.d/certs/
cp clientKey.pem /etc/ipsec.d/private/

mkdir clientCerts
cp caCert.pem clientCert.p12 clientCerts
mkdir allCerts
mv caKey.pem caCert.pem serverKey.pem serverCert.pem clientKey.pem clientCert.pem clientCert.p12 allCerts

#replace ikev2.wbuntu.me with your server's domain name
#replcae client.wbuntu.me with the url you defined before
cat > /etc/ipsec.conf<<EOF
config setup
        uniqueids=never
conn %default
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ike
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
conn ikev2-eap-mschapv2
        keyexchange=ikev2
        leftauth=pubkey
        leftcert=serverCert.pem
        leftid=@ikev2.wbuntu.me
        leftsendcert=always
        left=%defaultroute
        leftsubnet=0.0.0.0/0
        leftfirewall=yes
        rightauth=eap-mschapv2
        right=%any
        rightsourceip=10.0.0.0/24
        eap_identity=%any
        auto=add
conn ikev2-eap-tls
        keyexchange=ikev2
        leftauth=pubkey
        leftcert=serverCert.pem
        leftid=@ikev2.wbuntu.me
        leftsendcert=always
        left=%defaultroute
        leftsubnet=0.0.0.0/0
        leftfirewall=yes
        rightauth=eap-tls
        rightcert=clientCert.pem
        rightid=@client.wbuntu.me
        rightsourceip=10.0.0.0/24
        eap_identity=%any
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

#replcae PSK, username, passwd with your own
cat > /etc/ipsec.secrets<<EOF
: RSA serverKey.pem
: RSA clientKey.pem
: PSK "YourPSKHere"
accountNameHere : EAP "passwdForAccountHere"
accountNameHere : XAUTH "passwdForAccountHere"
EOF

#replace 192.241.216.55 with your server IP
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j SNAT --to-source 192.241.216.55


iptables-save > /etc/iptables.rules

cat > /etc/network/if-up.d/iptables<<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
ipsec start
EOF

chmod +x /etc/network/if-up.d/iptables

ipsec start
