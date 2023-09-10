#!/bin/bash

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

export LANG=en_US.UTF-8

red='\033[0;31m'

bblue='\033[0;34m'

plain='\033[0m'

red(){ echo -e "\033[31m\033[01m$1\033[0m";}

green(){ echo -e "\033[32m\033[01m$1\033[0m";}

yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}

blue(){ echo -e "\033[36m\033[01m$1\033[0m";}

white(){ echo -e "\033[37m\033[01m$1\033[0m";}

bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}

rred(){ echo -e "\033[35m\033[01m$1\033[0m";}

readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}

readp(){ read -p "$(yellow "$1")" $2;}

[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit 1

#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts

if [[ -f /etc/redhat-release ]]; then

release="Centos"

elif cat /etc/issue | grep -q -E -i "debian"; then

release="Debian"

elif cat /etc/issue | grep -q -E -i "ubuntu"; then

release="Ubuntu"

elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then

release="Centos"

elif cat /proc/version | grep -q -E -i "debian"; then

release="Debian"

elif cat /proc/version | grep -q -E -i "ubuntu"; then

release="Ubuntu"

elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then

release="Centos"

else

red " 不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统"

exit 1

fi

[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'

[[ $(type -P curl) ]] || (yellow "检测到curl未安装，升级安装中" && $yumapt update;$yumapt install curl)

[[ $(type -P kmod) ]] || $yumapt install kmod

vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`

sys(){

[ -f /etc/os-release ] && grep -i pretty_name /etc/os-release | cut -d \" -f2 && return

[ -f /etc/lsb-release ] && grep -i description /etc/lsb-release | cut -d \" -f2 && return

[ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return;}

white " 操作系统      : $(blue "$op")"

white " 内核版本      : $(blue "$version")"

white " CPU架构       : $(blue "$cpu")"

white " 虚拟化类型    : $(blue "$vi")"

white " TCP加速算法   : $(blue "$bbr")"

white " 本地IP优先级  : $(blue "$ip")"

op=`sys`

version=`uname -r | awk -F "-" '{print $1}'`

main=`uname  -r | awk -F . '{print $1 }'`

minor=`uname -r | awk -F . '{print $2}'`

uname -m | grep -q -E -i "aarch" && cpu=ARM64 || cpu=AMD64

vi=`systemd-detect-virt`

if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then

bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`

elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then

bbr="openvz版bbr-plus"

else

bbr="暂不支持显示"

fi

v46=`curl -s api64.ipify.org -k`

if [[ $v46 =~ '.' ]]; then

ip="$v46（IPV4优先）"

else

ip="$v46（IPV6优先）"

fi

get_char(){

SAVEDSTTY=`stty -g`

stty -echo

stty cbreak

dd if=/dev/tty bs=1 count=1 2> /dev/null

stty -raw

stty echo

stty $SAVEDSTTY

}

back(){

white "------------------------------------------------------------------------------------------------"

white " 回主菜单，请按任意键"

white " 退出脚本，请按Ctrl+C"

get_char && bash <(curl -sSL https://gitlab.com/rwkgyg/ygkkktools/raw/main/tools.sh)

}

root(){

#!/bin/bash

# 获取要监控的本地服务器IP地址

IP=`ifconfig | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}'`

echo "IP地址："$IP

# 获取cpu总核数

cpu_num=`grep -c "model name" /proc/cpuinfo`

echo "cpu总核数："$cpu_num

# 1、获取CPU利用率

################################################

#us 用户空间占用CPU百分比

#sy 内核空间占用CPU百分比

#ni 用户进程空间内改变过优先级的进程占用CPU百分比

#id 空闲CPU百分比

#wa 等待输入输出的CPU时间百分比

#hi 硬件中断

#si 软件中断

#################################################

# 获取用户空间占用CPU百分比

cpu_user=`top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%"`

echo "用户空间占用CPU百分比："$cpu_user

# 获取内核空间占用CPU百分比

cpu_system=`top -b -n 1 | grep Cpu | awk '{print $4}' | cut -f 1 -d "%"`

echo "内核空间占用CPU百分比："$cpu_system

# 获取空闲CPU百分比

cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "%"`

echo "空闲CPU百分比："$cpu_idle

# 获取等待输入输出占CPU百分比

cpu_iowait=`top -b -n 1 | grep Cpu | awk '{print $10}' | cut -f 1 -d "%"`

echo "等待输入输出占CPU百分比："$cpu_iowait

#2、获取CPU上下文切换和中断次数

# 获取CPU中断次数

cpu_interrupt=`vmstat -n 1 1 | sed -n 3p | awk '{print $11}'`

echo "CPU中断次数："$cpu_interrupt

# 获取CPU上下文切换次数

cpu_context_switch=`vmstat -n 1 1 | sed -n 3p | awk '{print $12}'`

echo "CPU上下文切换次数："$cpu_context_switch

#3、获取CPU负载信息

# 获取CPU15分钟前到现在的负载平均值

cpu_load_15min=`uptime | awk '{print $11}' | cut -f 1 -d ','`

echo "CPU 15分钟前到现在的负载平均值："$cpu_load_15min

# 获取CPU5分钟前到现在的负载平均值

cpu_load_5min=`uptime | awk '{print $10}' | cut -f 1 -d ','`

echo "CPU 5分钟前到现在的负载平均值："$cpu_load_5min

# 获取CPU1分钟前到现在的负载平均值

cpu_load_1min=`uptime | awk '{print $9}' | cut -f 1 -d ','`

echo "CPU 1分钟前到现在的负载平均值："$cpu_load_1min

# 获取任务队列(就绪状态等待的进程数)

cpu_task_length=`vmstat -n 1 1 | sed -n 3p | awk '{print $1}'`

echo "CPU任务队列长度："$cpu_task_length

#4、获取内存信息

# 获取物理内存总量

mem_total=`free | grep Mem | awk '{print $2}'`

echo "物理内存总量："$mem_total

# 获取操作系统已使用内存总量

mem_sys_used=`free | grep Mem | awk '{print $3}'`

echo "已使用内存总量(操作系统)："$mem_sys_used

# 获取操作系统未使用内存总量

mem_sys_free=`free | grep Mem | awk '{print $4}'`

echo "剩余内存总量(操作系统)："$mem_sys_free

# 获取应用程序已使用的内存总量

mem_user_used=`free | sed -n 3p | awk '{print $3}'`

echo "已使用内存总量(应用程序)："$mem_user_used

# 获取应用程序未使用内存总量

mem_user_free=`free | sed -n 3p | awk '{print $4}'`

echo "剩余内存总量(应用程序)："$mem_user_free

# 获取交换分区总大小

mem_swap_total=`free | grep Swap | awk '{print $2}'`

echo "交换分区总大小："$mem_swap_total

# 获取已使用交换分区大小

mem_swap_used=`free | grep Swap | awk '{print $3}'`

echo "已使用交换分区大小："$mem_swap_used

# 获取剩余交换分区大小

mem_swap_free=`free | grep Swap | awk '{print $4}'`

echo "剩余交换分区大小："$mem_swap_free

#5、获取磁盘I/O统计信息

echo "指定设备(/dev/sda)的统计信息"

# 每秒向设备发起的读请求次数

disk_sda_rs=`iostat -kx | grep sda| awk '{print $4}'`

echo "每秒向设备发起的读请求次数："$disk_sda_rs

# 每秒向设备发起的写请求次数

disk_sda_ws=`iostat -kx | grep sda| awk '{print $5}'`

echo "每秒向设备发起的写请求次数："$disk_sda_ws

# 向设备发起的I/O请求队列长度平均值

disk_sda_avgqu_sz=`iostat -kx | grep sda| awk '{print $9}'`

echo "向设备发起的I/O请求队列长度平均值"$disk_sda_avgqu_sz

# 每次向设备发起的I/O请求平均时间

disk_sda_await=`iostat -kx | grep sda| awk '{print $10}'`

echo "每次向设备发起的I/O请求平均时间："$disk_sda_await

# 向设备发起的I/O服务时间均值

disk_sda_svctm=`iostat -kx | grep sda| awk '{print $11}'`

echo "向设备发起的I/O服务时间均值："$disk_sda_svctm

# 向设备发起I/O请求的CPU时间百分占比

disk_sda_util=`iostat -kx | grep sda| awk '{print $12}'`

echo "向设备发起I/O请求的CPU时间百分占比："$disk_sda_util

}

opport(){

systemctl stop firewalld.service >/dev/null 2>&1

systemctl disable firewalld.service >/dev/null 2>&1

setenforce 0 >/dev/null 2>&1

ufw disable >/dev/null 2>&1

iptables -P INPUT ACCEPT >/dev/null 2>&1

iptables -P FORWARD ACCEPT >/dev/null 2>&1

iptables -P OUTPUT ACCEPT >/dev/null 2>&1

iptables -t mangle -F >/dev/null 2>&1

iptables -F >/dev/null 2>&1

iptables -X >/dev/null 2>&1

netfilter-persistent save >/dev/null 2>&1

if [[ -n $(apachectl -v 2>/dev/null) ]]; then

systemctl stop httpd.service >/dev/null 2>&1

systemctl disable httpd.service >/dev/null 2>&1

service apache2 stop >/dev/null 2>&1

systemctl disable apache2 >/dev/null 2>&1

fi

green "关闭VPS防火墙、开放端口规则执行完毕"

back

}

bbr(){

if [[ $vi = lxc ]]; then

red "VPS虚拟化类型为lxc，目前不支持安装各类加速（自带集成BBR除外） "

elif [[ $vi = openvz ]]; then

[[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]] && green "openvz版bbr-plus已在运行中" && back

green "VPS虚拟化类型为openvz，支持lkl-haproxy版的BBR-PLUS加速" && sleep 2

wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh && bash lkl-haproxy.sh

elif [[ ! $vi =~ lxc|openvz ]]; then

bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`

if [[ $bbr != bbr ]]; then

yellow "当前TCP拥塞控制算法：$bbr，BBR+FQ加速未开启" && sleep 1

yellow "尝试安装BBR+FQ加速……" && sleep 2

bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)

[[ -n $(lsmod | grep bbr) ]] && green "安装结束，已开启BBR+FQ加速"

else

green "当前TCP拥塞控制算法：$bbr，BBR+FQ加速已开启"

fi

fi

back

}

v4v6(){

v46=`curl -s api64.ipify.org -k`

[[ $v46 \=~ '.' \]\] && green "当前VPS本地为IPV4优先：$

KaTeX parse error: Can't use function '\]' in math mode at position 13: v46 \=~ '.' \̲]̲\] && green "当前…

v46" || green "当前VPS本地为IPV6优先：$v46"

ab="1.设置IPV4优先\n2.设置IPV6优先\n3.恢复系统默认优先\n0.返回上一层\n 请选择："

readp "$ab" cd

case "$cd" in

1 )

[[ -e /etc/gai.conf ]] && grep -qE '^ *precedence ::ffff:0:0/96  100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf

sed -i '/^label 2002::\/16   2/d' /etc/gai.conf

v46=`curl -s api64.ipify.org -k`

[[ $v46 \=~ '.' \]\] && green "当前VPS本地为IPV4优先：$

KaTeX parse error: Can't use function '\]' in math mode at position 13: v46 \=~ '.' \̲]̲\] && green "当前…

v46" || green "当前VPS本地为IPV6优先：$v46"

back;;

2 )

[[ -e /etc/gai.conf ]] && grep -qE '^ *label 2002::/16   2' /etc/gai.conf || echo 'label 2002::/16   2' >> /etc/gai.conf

sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf

v46=`curl -s api64.ipify.org -k`

[[ $v46 \=~ '.' \]\] && green "当前VPS本地为IPV4优先：$

KaTeX parse error: Can't use function '\]' in math mode at position 13: v46 \=~ '.' \̲]̲\] && green "当前…

v46" || green "当前VPS本地为IPV6优先：$v46"

back;;

3 )

sed -i '/^precedence ::ffff:0:0\/96  100/d;/^label 2002::\/16   2/d' /etc/gai.conf

v46=`curl -s api64.ipify.org -k`

[[ $v46 \=~ '.' \]\] && green "当前VPS本地为IPV4优先：$

KaTeX parse error: Can't use function '\]' in math mode at position 13: v46 \=~ '.' \̲]̲\] && green "当前…

v46" || green "当前VPS本地为IPV6优先：$v46"

back;;

0 )

bash <(curl -sSL https://gitlab.com/rwkgyg/ygkkktools/raw/main/tools.sh)

esac

}

js(){

ps aux | awk '{if($8 == "Z"){print $2,$11}}'

}

ps(){

#!/bin/bash

echo "-------------------CUP占用前10排序--------------------------------"

ps -eo user,pid,pcpu,pmem,args --sort=-pcpu |head -n 10

echo "-------------------内存占用前10排序--------------------------------"

ps -eo user,pid,pcpu,pmem,args --sort=-pmem |head -n 10

}

screen(){

bash <(curl -sSL https://cdn.jsdelivr.net/gh/kkkyg/screen-script/screen.sh)

back

}

warp(){

#!/bin/bash

# @Author: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git

# @Date: 2023-09-08 09:47:32

# @LastEditors: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git

# @LastEditTime: 2023-09-08 11:46:59

# @FilePath: \脚本\脚本v1\一键查看服务器利用率.sh

# @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: [https://github.com/OBKoro1/koro1FileHeader/wiki/配置](https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE)

function cpu(){

util=$(vmstat | awk '{if(NR==3)print $13+$14}')

iowait=$(vmstat | awk '{if(NR==3)print $16}')

echo "CPU -使用率：${util}% ,等待磁盘IO相应使用率：${iowait}:${iowait}%"

}

function memory (){

total=`free -m |awk '{if(NR==2)printf "%.1f",$2/1024}'`

used=`free -m |awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}'`

available=`free -m |awk '{if(NR==2) printf "%.1f",$NF/1024}'`

echo "内存 - 总大小: ${total}G , 使用: ${used}G , 剩余: ${available}G"

}

disk(){

fs=$(df -h |awk '/^\/dev/{print $1}')

for p in $fs; do

mounted=$(df -h |awk '$1=="'$p'"{print $NF}')

size=$(df -h |awk '$1=="'$p'"{print $2}')

used=$(df -h |awk '$1=="'$p'"{print $3}')

used_percent=$(df -h |awk '$1=="'$p'"{print $5}')

echo "硬盘 - 挂载点: $mounted , 总大小: $size , 使用: $used , 使用率:$used_percent"

done

}

function tcp_status() {

summary=$(ss -antp | awk '

{status[$1]++}

END {

for (i in status) {

state=i;

if (i == "ESTAB") state="已建立";

else if (i == "LISTEN") state="监听中";

else if (i == "SYN_SENT") state="发送同步";

else if (i == "SYN_RECV") state="接收同步";

else if (i == "FIN_WAIT1") state="等待结束1";

else if (i == "FIN_WAIT2") state="等待结束2";

else if (i == "TIME_WAIT") state="时间等待";

else if (i == "CLOSE") state="关闭";

else if (i == "State") state="状态";

else if (i == "CLOSE_WAIT") state="等待关闭";

else if (i == "LAST_ACK") state="最后确认";

printf "%s:%s ", state, status[i];

}

}')

echo "TCP连接状态 - $summary"

}

cpu

memory

disk

tcp_status

}

cpu(){

system_info()

{

echo "====================system info========================"

VERSION=`cat /etc/redhat-release| awk 'NR==1{print}'`

KERNEL=`uname -a|awk '{print $3}'`

HOSTNAME=`uname -a|awk '{print $2}'`

cat /etc/issue &> /dev/null

if [ "$?" -ne 0 ];then

echo -e "\033[31m The system is no support \033[0m"

exit 1

else

echo -e "system_version is \033[32m $VERSION \033[0m"

echo -e "system_kernel_version is  \033[32m $KERNEL \033[0m"

echo -e "system_hostname is \033[32m $HOSTNAME \033[0m"

fi

}

disk_info ()

{

echo "======================disk info========================"

DISK=$(df -ThP|column -t)

echo -e "\033[32m $DISK \033[0m"

}

cpu_info ()

{

echo "=======================cpu info========================"

echo -e "cpu processor is \033[32m $(grep "processor" /proc/cpuinfo |wc -l) \033[0m"

echo -e "cpu mode name is \033[32m $(grep "model name" /proc/cpuinfo |uniq|awk '{print $4,$5,$6,$7,$8,$9}') \033[0m"

grep "cpu MHz" /proc/cpuinfo |uniq |awk '{print $1,$2":"$4}'

awk '/cache size/ {print $1,$2":"$4$5}' /proc/cpuinfo |uniq

}

mem_info ()

{

echo "====================memory info========================"

MemTotal=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

MemFree=$(awk '/MemFree/ {print $2}' /proc/meminfo)

Buffers=$(awk '/^Buffers:/ {print $2}' /proc/meminfo)

Cached=$(awk '/^Cached:/ {print $2}' /proc/meminfo)

FreeMem=$(($MemFree/1024+$Buffers/1024+$Cached/1024))

UsedMem=$(($MemTotal/1024-$FreeMem))

echo -e "Total memory is \033[32m $(($MemTotal/1024)) MB \033[0m"

echo -e "Free  memory is \033[32m ${FreeMem} MB \033[0m"

echo -e "Used  memory is \033[32m ${UsedMem} MB \033[0m"

}

loadavg_info ()

{

echo "==================load average info===================="

Load1=$(awk  '{print $1}' /proc/loadavg)

Load5=$(awk  '{print $2}' /proc/loadavg)

Load10=$(awk '{print $3}' /proc/loadavg)

echo -e "Loadavg 在 1  min is \033[32m $Load1 \033[0m"

echo -e "Loadavg 在 5  min is \033[32m $Load5 \033[0m"

echo -e "Loadavg 在 10 min is \033[32m $Load10 \033[0m"

}

network_info ()

{

echo "====================network info======================="

network_card=$(ip addr |grep inet |egrep -v "inet6|127.0.0.1" | awk '{print $NF}')

IP=$(ip addr |grep inet |egrep -v "inet6|127.0.0.1" |awk '{print $2}' |awk -F "/" '{print $1}')

echo -e "network_device is \033[32m $network_card \033[0m  address is  \033[32m $IP \033[0m"

}

system_info

disk_info

cpu_info

mem_info

loadavg_info

network_info

}

start_menu(){

clear

green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

white "维护脚本"

yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

white " VPS系统信息如下："

white " 操作系统      : $(blue "$op")"

white " 内核版本      : $(blue "$version")"

white " CPU架构       : $(blue "$cpu")"

white " 虚拟化类型    : $(blue "$vi")"

white " TCP加速算法   : $(blue "$bbr")"

white " 本地IP优先级  : $(blue "$ip")"

white " ==================维护脚本=========================================="

green "  1. 一键获取linux内存、cpu、磁盘IO等信息 "

green "  2. 关闭防火墙、开放端口规则"

green "  3. 系统优化"

green "  4. 更改VPS本地IP优先级"

green "  5. 找出cpu/内存占用高进程"

green "  6. 一键查看服务器利用率"

green "  7 cpu脚本"

green "  8 查找僵尸进程"

green "  0. 退出脚本 "

red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

readp "请输入数字:" Input

case "$Input" in

1 ) root;;

2 ) opport;;

3 ) bbr;;

4 ) v4v6;;

5 ) ps;;

6 ) warp;;

7 ) cpu;;

8 ) js;;

9 ) WARPOC;;

11 ) cpu;;

* ) exit 0

esac

}

start_menu "first"
