#!/bin/sh
apt-get update
apt-get install strongswan strongswan-plugin-xauth-generic strongswan-plugin-eap-mschapv2 strongswan-plugin-eap-md5 -y
#attention! domainName must be your server's domain name
ipsec pki --gen --outform pem > caKey.pem
ipsec pki --self --in caKey.pem --dn "C=CH, O=strongSwan, CN=strongSwan CA" --ca --outform pem > caCert.pem
ipsec pki --gen --outform pem > serverKey.pem
ipsec pki --pub --in serverKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=CH, O=strongSwan, CN=domainName" --san="domainName" --flag serverAuth --outform pem > serverCert.pem
#you have to add a password for clientCert
ipsec pki --gen --outform pem > clientKey.pem
ipsec pki --pub --in clientKey.pem | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "C=CH, O=strongSwan, CN=client" --outform pem > clientCert.pem
openssl pkcs12 -export -inkey clientKey.pem -in clientCert.pem -name "client" -certfile caCert.pem -caname "strongSwan CA" -out clientCert.p12

cp caCert.pem /etc/ipsec.d/cacerts/
cp serverCert.pem /etc/ipsec.d/certs/
cp serverKey.pem /etc/ipsec.d/private/
cp clientCert.pem /etc/ipsec.d/certs/
cp clientKey.pem /etc/ipsec.d/private/

mkdir clientCerts
cp caCert.pem clientCert.p12 clientCerts
mkdir allCerts
mv caKey.pem caCert.pem serverKey.pem serverCert.pem clientKey.pem clientCert.pem clientCert.p12 allCerts

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
    leftid=@domainName
    leftsendcert=always
    left=%defaultroute
    leftsubnet=0.0.0.0/0
    leftfirewall=yes
    rightauth=eap-mschapv2
    eap_identity=%any
    right=%any
    rightsourceip=10.0.0.0/24
    auto=add
conn ikev2-eap-md5
    keyexchange=ikev2
    leftauth=pubkey
    leftcert=serverCert.pem
    leftid=@domainName
    leftsendcert=always
    left=%defaultroute
    leftsubnet=0.0.0.0/0
    leftfirewall=yes
    rightauth=eap-md5
    eap_identity=%any
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
: RSA serverKey.pem
: PSK "YourPSKHere"
accountNameHere : EAP "passwdForAccountHere"
accountNameHere : XAUTH "passwdForAccountHere"
EOF

iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT

iptables-save > /etc/iptables.rules

cat > /etc/network/if-up.d/iptables<<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
ipsec start
EOF

chmod +x /etc/network/if-up.d/iptables

ipsec restart
