---
toc: true
layout: post
title:  "Docker+frp+OpenVPN搭建VPN"
date:   2022-03-31
excerpt: "15分钟无脑搭建"
image: ""
comments: true
toc: true
tags: Y-2022 tips vpn
---

如果你是一个软硬件爱好者，喜欢在家里捣鼓各种设备，比如：搭建NAS服务器等等，那么你可能会有需求从外网访问内部设备，或者开放内网服务可以在公网中无限制的访问。

那么问题来了，怎么快速搭建一套VPN，可以顺畅的访问内网服务呢？我们直接进入正题:runner:

## 准备条件

1. 一台具有公网IP的云服务器（安装Docker），我们这里以aliyun为例；
2. 一台内网机器（安装Docker）

## 云服务端端配置

> :bookmark:说明：<br>
> 下文中[xxx]标注的内容，请务必依据自己的情况做相应替换！

我们需要利用frp实现一个内网机器的反向代理穿透，在云服务器端启动frp的服务端：<br>
frps的配置文件放在`/etc/frp/frps.ini`:

```
[common]
bind_addr = 0.0.0.0
bind_port = 7000
dashboard_addr = 0.0.0.0
token = [xxx:any token]

# Management dashboard
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = admin

```

为了实现开机自启，在`/etc/systemd/system/`下面添加一个Service，名叫frps.service:

```
[Unit]
Description=Launch the frps server
After=network.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=docker run -d --name=frps --restart=always -v /etc/frp/frps.ini:/etc/frp/frps.ini -p 7000:7000 -p 7001:7001/udp -p 7500:7500 snowdreamtech/frps

[Install]
WantedBy=multi-user.target
```
该服务主要开放了三个端口，务必记的去到阿里云管理后台添加对应的安全组：<br>
- 7000：用于frp服务的管理端口(tcp)
- 7001: 给后面OpenVPN开放的端口(udp)
- 7500: frp服务的dashboard端口(tcp)，启动后，可以通过`[xxx:aliyun public ip]:7500`访问frp后台，查看当前连接情况

启动该服务，并加入到开机自启列表：<br>
```
sudo systemctl start frps.service
sudo systemctl enable frps.service
```

## 内网主机配置

### 配置frp客户端：
相应的，我们需要在一台内网机器上部署frp的客户端，其对应的配置文件`/etc/frp/frpc.ini`:
```
[common]
server_addr=[xxx:aliyun public ip]
server_port=7000
token=[xxx:the token set in frps]

[openvpn]
type=udp
local_ip=127.0.0.1
local_port=1194
remote_port=7001
```
### 配置OpenVPN

- 分配一个专门给OpenVPN的Volume，后续始终使用该Volume<br>

```
export OVPN_DATA="my-openvpn-volume"
docker volume create --name $OVPN_DATA
```

- 生成配置文件<br>

```
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://[xxx:aliyun public ip]:7001
```

- 初始化PKI认证<br>

```
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
```


### 启动frpc&&OpenVPN，并加入开机自启<br>

特编写了一个启动脚本`launch_vpn`，放置到`/etc/my_vpn/launch_vpn`：
```
#!/usr/bin/env bash

# launch the frp client, while the frp server runs on the aliyun server
docker run  --network host -d -v /etc/frp/frpc.ini:/etc/frp/frpc.ini -p 1149:1149/udp --name frpc snowdreamtech/frpc

# launch openvpn service
export OVPN_DATA="my-openvpn-volume"
docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn
```

并加入到自启动服务`my_vpn.service`:
```
[Unit]
Description=Auto launch repsonding jobs to enable vpn service
After=network.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/etc/my_vpn/launch_vpn

[Install]
WantedBy=multi-user.target

```

### 添加VPN账号

好的，到此为止，OpenVPN服务已经搭建完毕。是时候给需要的人添加VPN账户了，为了方便添加账户，特编写了一个简易脚本`add_account.sh`: <br>
```
#!/usr/bin/env bash

if [ $# -lt 1 ]; then echo "invalid param." && exit; fi

export OVPN_DATA="my-openvpn-volume"
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full "$1" nopass
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient "$1" > "$1".ovpn

echo "Add client $1 finished."

```

使用方式：`add_account.sh [xxx:name]`<br>

执行完毕，在当前路径生成一个`[xxx:name].ovpn`密钥文件，后续使用客户端导入该密钥连接即可。

## Enjoy :smile_cat:

不同的操作系统，下载对应的[OpenVPN客户端](https://openvpn.net/community-downloads/)，导入ovpn密钥文件连接即可实现内网穿透啦。<br>
心动了吗，快去试试吧~~


## References

- [1] [frp](https://github.com/fatedier/frp)
- [2] [docker-frp](https://github.com/snowdreamtech/frp)
- [3] [docker-vpn](https://github.com/kylemanna/docker-openvpn)
