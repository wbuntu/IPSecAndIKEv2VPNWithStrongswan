# IPSecAndIKEv2VPNWithStrongSwan

在使用了很长一段时间的IKEv2后，再次更新下本文件～

这个是一键安装IPsec及IKEv2 VPN的指南，适用于KVM，XEN虚拟化的VPS，以及支持TUN/TAP的openVZ主机

文件说明：建议从源码编译，最后一个文件仅供参考
 
* IKEv2WithEAP-TLS.sh        

配置EAP-MSCHAPv2与EAP-TLS认证的IKEv2服务端，从源码编译

* IPSecAndIKEv2SourceCode.sh

配置EAP-MSCHAPv2认证的IKEv2服务端及IPSec认证的服务端，从源码编译

 * IPSecAndIKEv2Binary.sh     

配置EAP-MSCHAPv2认证的IKEv2服务端及IPSec认证的服务端，使用apt从源安装程序

## 前言
这份安装指南适用于哪些用户？

* 在国内VPS上搭建VPN隧道，使用内网穿透功能的用户，面向开发和调试（国内的大局域网）
* 有穿墙需求，对安全性要求相对高，主要使用4G网络或联通3G网络的用户（网络的质量和价格是成正比的）

其他类型的用户，需要穿墙的请使用**shadowsocks-libev**，需要使用内网穿透的，国外主机可以自己搭建**FRP**或者**ngork**，国内可以购买花生壳内网穿透（虽然这玩意不是很稳定，但相对便宜）

大多数VPN都依赖UDP协议构建隧道，对网络质量有较高的要求，国际线路即使是TCP协议都很容易丢包，使用**net-speeder**之类的加倍发包工具，也无法改善VPN连接的稳定性，此外部分运营商对VPN协议或者国外IP十分不友好

关于shadowsocks-libev，可以参考

[折腾搬瓦工–02–搭建shadowsocks服务端](https://wbuntu.com/?p=44)

启用BBR的KVM、XEN主机，或者使用lkl来hook程序，开启BBR的openVZ主机，目前使用过Vultr，Linode，DigitalOcean，搬瓦工的主机，不论日本主机还是美国主机，都有很好的表现

下面是IKEv2的安装指南

## 指南

### IP转发
在文件修改/etc/ipsec.secrets部分中可自行定义PSK、账号和密码

在终端下运行

    cat /proc/sys/net/ipv4/ip_forward

若输出为1，则已启用IPV4转发，否则需要修改**/etc/sysctl.conf**,搜索**net.ipv4.ip_forward=1**，去掉它的注释，保存后退出，执行**sysctl -p**，应用修改

### 证书
使用IPSec VPN不需要安装根证书，使用IKEv2需要安装根证书，使用自签名的证书需要安装服务端生成的根证书，使用let's encrypt证书的话，除Linux需要安装**DST Root CA X3**根证书，其他的不需要

 * windows（windows 7或以上，使用IKEv2，采用eap-mschapv2认证）
 * 安卓（使用strongswan官方安卓客户端配置，采用eap-md5认证）
 * iOS（使用IKEv2或IPSec，采用eap-mschapv2认证）
 * Linux（使用StrongSwan客户端模式，配置ipsec.conf，支持所有的认证方式）

### 编译，配置与安装

将脚本下载到VPS上，修改对应的账号密码、IP、域名等内容，然后添加可执行权限后运行即可

由于是在Ubuntu上配置完成的，没有对CentOS进行过测试，但除了一些编译所需的软件名称不同外，其余操作相同

相关的博客记录如下

配置IPSec VPN，包括一些对StrongSwan配置文件的说明：

[折腾搬瓦工–04–配置IPSec VPN](https://wbuntu.com/?p=224)

配置IKEv2 VPN，包括对iOS使用IKEv2的一些说明：

[折腾搬瓦工–06–配置IKEv2 VPN](https://wbuntu.com/?p=323)

配置客户端证书认证的IKEv2 VPN，这篇文章比较长，包含步骤说明，截图，以及终端输出：

[折腾搬瓦工–09–为iPhone配置证书认证的VPN](https://wbuntu.com/?p=499)

配置内网穿透，建议使用crontab定时重启客户端服务，虽然国内大局域网很稳定，但也有丢包导致无法连接的时候

[折腾搬瓦工–10–将内网服务暴露到外网](https://wbuntu.com/?p=820)

