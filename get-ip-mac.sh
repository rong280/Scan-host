#!/bin/bash

check_system(){
	if [ -f /etc/os-release ];then
			source /etc/os-release
		if [ $ID != centos ];then
				echo 此脚本暂不支持该系统
				exit
		elif [[ $VERSION_ID == [78] ]];then
				command -v ifconfig &> /dev/null
					if [ $? != 0 ];then
						yum -y install net-tools &> /dev/null || { echo 安装net-tools失败,请检查网络或yum源;exit; }
					fi
				GETDEVICE=$(ifconfig | awk 'BEGIN{RS=""}!/^lo:/{print $1$6}')
		fi
	else
			SYSTEM=$(rpm -q centos-release | awk -F"-" '{print $3}')
				if	[[ $SYSTEM == [56] ]];then
					GETDEVICE=$(ifconfig | awk 'BEGIN{RS=""}!/^lo/{print $1":"$7}')
				else
					echo 此脚本暂不支持该系统
					exit
				fi
	fi
}

check_system

echo "请输入对应的数字选择网卡"
select DEVICE in $GETDEVICE
do
		case $DEVICE in
			$DEVICE)
				NICNAME=$DEVICE
				break
				;;
		esac
done

if [[ $VERSION_ID == [78] ]];then
		eval $(echo $NICNAME | awk -F":" '{printf("DEV=%s;NIC=%s",$1,$2)}')
elif [[ $SYSTEM == [56] ]];then
		eval $(echo $NICNAME | awk -F":" '{printf("DEV=%s;NIC=%s",$1,$3)}')
fi

IP=$(echo $NIC | cut -d. -f1,2,3)

start=`date +%s`

for ((i=2;i<=254;i++))
do
	{
		ping -c1 $IP.$i &> /dev/null
	}&
done
wait

echo && arp -n -i $DEV 2> /dev/null | awk '!/^Addr/{print $1"\t"$3}' | sort -n -t"." -k4

end=`date +%s`

echo && echo "检测完毕，耗时：`expr $end - $start` 秒" && echo
