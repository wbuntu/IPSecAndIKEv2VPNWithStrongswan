# IPSecAndIKEv2VPNWithStrongswan
一键安装IPsec及IKEv2VPN，分别适用于搬瓦工VPS(OpenVZ)与DigitalOcean（KVM）

搬瓦工使用的文件为IPSecAndIKEv2SourceCode.sh

DO使用的文件为IPSecAndIKEv2Binary.sh

测试环境为

搬瓦工：Ubuntu 14.04 32位版本，内核版本为2.6.32-042stab102.9

DO：Ubuntu 14.04 64位版本，内核版本为3.13.0-48-generic x86_64

在文件修改/etc/ipsec.secrets部分中可自行定义PSK、账号和密码

在终端下运行

    cat /proc/sys/net/ipv4/ip_forward

若输出为1，则IPV4转发正常，否则修改/etc/sysctl.conf,搜索net.ipv4.ip_forward=1，去掉它的注释，保存后退出，执行sysctl -p，成功开启转发后，为文件添加执行权限后运行即可

## 新增 00
添加了对IKEv2的支持，需要在文件中替换三个domainName为VPS的域名，(如果没有域名，可以只配置IPSec VPN)它对应iOS 9中IKEv2 VPN里的远程ID（Remote ID），客户端使用帐号密码验证，采用MS-CHAPv2，需要配置/etc/ipsec.secrets部分中的EAP左右的账户名与密码，客户端还必须安装根证书caCert.pem来验证服务端

脚本中也配置好了客户端证书，使用Cisco IPSec时，采用证书代替预共享密钥配置成功，但使用IKEv2配置证书验证时失败，暂且搁置，如果有小伙伴尝试成功，请务必告诉我

## 新增 01

修改了配置，现在可以支持的如下，除了使用IPSec VPN不需要安装根证书外，其他的都需要安装根证书

 * windows（windows 7或以上，使用IKEv2，采用eap-mschapv2协议）
 * 安卓（使用strongswan官方安卓客户端配置，采用eap-md5协议）
 * iOS（使用IKEv2或IPSec，采用eap-mschapv2协议）


