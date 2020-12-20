#!/bin/bash
# get all filename in specified path

path=/root/manager/ports/
files=$(ls $path)
iptables -t nat -F
for filename in $files
do
	USERNAME=$filename 
	# allocate ssh port
	PORTFILE=/root/manager/ports/$USERNAME
	PORT=$(cat $PORTFILE)

	echo "Finding $USERNAME......"
	LXCIP=$(lxc info s-$USERNAME  | grep 'eth0:' | grep 'inet'  | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
	if [[ -z "$LXCIP" ]]; then
		echo "Failed to get container IP for $USERNAME."
		echo "If this problem cannot be solved by retrying, please contact administrators."
	else
		printf "\e[96;1m refresh $PORT\e[0m\n"
		HAS_RULE=$(iptables-save | grep $LXCIP | grep $PORT | wc -l)
		if [ $HAS_RULE -eq 0 ]; then
		iptables -t nat -A PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $LXCIP:8880
		iptables -t nat -A POSTROUTING -p tcp -d $LXCIP --dport 8880 -j MASQUERADE
		fi
	fi
done
