# IPSecAndIKEv2VPNWithStrongswan

相关链接

[折腾搬瓦工–04–配置IPSec VPN](https://wbuntu.com/?p=224)

[折腾搬瓦工–06–配置IKEv2 VPN](https://wbuntu.com/?p=323)

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

## 新增 02

新增文件**IKEv2WithEAP-TLS.sh**，主要针对iOS上的证书验证做了修改，可以免账号密码，直接使用证书验证客户端了，另外缩减了一下strongSwan的编译选项，去除掉没有使用的模块，让编译过程更快一点。

新增的配置文件兼容之前的VPN配置，在openVZ及KVM主机上都测试过，注意openVZ的机子需要附加**--enable-kernel-libipsec**选项，编译用户空间的ipsec模块。

PS:如果客户端采用IKEv2+账号密码认证，又不想在客户端上安装自签名的根证书，可以采取这个方法。

1.为VPS绑定的域名申请一个免费的HTTPS证书

2.将证书的公钥与私钥分别上传到/etc/ipsec.d/certs与/etc/ipsec.d/private目录下

3.在ipsec.conf中设置leftid为绑定的域名，leftcert为上传的证书名，在ipsec.secrets中添加私钥

同时为新的配置写了一篇博客：[折腾搬瓦工–09–为iPhone配置证书认证的VPN](https://wbuntu.com/?p=499)
