#!/bin/bash
# lcmp
systemctl stop firewalld   &&  systemctl disable firewalld
if [ $? -eq 0 ]  
	then  
	    echo "====================防火墙已关闭并且关闭开机自启==================="
	else
	    echo "======================请部署完成手动关闭防火墙======================"
fi
ping 192.168.10.123 -c 2 >/dev/null
if [ $? -eq 0 ]
	then
	    echo "===========================与源地址通讯正常=========================="
	else
	    echo "========================源地址通信异常，请检查========================"
 	    exit 1
fi
yum clean all >/dev/null
if [ $? -eq 0 ]
	then
	    echo "============================yum缓存清理成功============================"
	else
	    echo "=========================清理失败将再次尝试清理========================"
	    yum clean all >/dev/null
		if [ $? -eq 0 ]
			then
			    echo "=======================尝试清理成功========================"
			else
			    echo "===========================请手动使用 yum clean all 清理yum缓存======================"
		fi
fi
sleep 5  && echo "==============================请等待一会儿==============================="
yum makecache >/dev/null
if [ $? -eq 0 ]
	then
	    echo "===========================正在重建yum数据库========================="
	    sleep  8  && echo "============================请等待一会儿======================"
	    echo "============================Yum数据库重建完成=========================="
	else
	    echo "====================数据库重建失败请检查yum仓库是否配置成功======================="
	    cd /etc/yum.repo.d/  && echo "===============================已为您转至Yum仓库路径==========================="
fi
yum install -y caddy php-fpm php-mysql mariadb*  >/dev/null && echo "正在部署lcmp架构"
echo "LCMP部署完成，正在执行初始化"
sed -i "3afastcgi \/ 127.0.0.1:9000 php" /etc/caddy/caddy.conf >/dev/null
if [ $? -eq 0 ]
	then
	    echo "LCMP初步测试配置完成"
	else
	    echo "配置出错，请检查"
	    exit 3
fi
systemctl start php-fpm && systemctl enable php-fpm >/dev/null
if [ $? -eq 0 ]
	then
	    echo "启动PHP服务并加入开机自启"
	else
	    echo "PHP服务启动异常，请检查"
	    exit 2
fi
systemctl start mariadb && systemctl enable mariadb >/dev/null
if [ $? -eq 0 ]
	then
	    echo "开启Mysql数据库并加入系统服务"
	    echo "请回车确认初始化mysql数据库密码"
	    echo "MySQL初始化账号 : root"
	    echo "MySQL初始化密码 : 123456"
	    mysqladmin -uroot -p password 123456
	else
	    echo "开启Mysql出错，请检查！"
	    exit 4
fi
mysql  -uroot -p123456 <<EOF
exit
EOF
if [ $? -eq 0 ]
	then
	    echo "测试登录Mysql成功"
	else
	    echo "登录MySQL测试失败，请检查故障"
	    exit 5
fi
echo "<?php phpinfo(); ?>" >/usr/share/caddy/index.php
echo "写入测试文件完成，即将开始测试。"
systemctl start caddy >/dev/null
systemctl enable caddy >/dev/null
echo "开启web服务并加入开机自启"
curl http://127.0.0.1 >/dev/null
if [ $? -eq 0 ]
	then
	    echo "LCMP架构部署完成，放心使用吧"
	    echo "源码存放路径 /usr/share/caddy/ 可以在caddy配置文件修改"
	else
	    echo "网站测试失败，请检查/"
	    exit 6
fi
