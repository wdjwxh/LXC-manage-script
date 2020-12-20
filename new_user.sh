#!/bin/bash
# save as /root/new_lxc.sh

### add user
USERNAME=$1
if [[ -z "$USERNAME" ]]; then
    echo "Please give me a username"
    exit 1
fi
printf "Allocating LXC Container for \e[96;1m$USERNAME\e[0m...\n"

# create user
echo "Creating user..."
#useradd -m -G sudo -p WjBvLfnOeZocg $USERNAME # temporary password is 123456

# grant lxc virtual network permission
echo "Granting LXC virtual network permission..."
#echo $USERNAME veth lxcbr0 10 >> /etc/lxc/lxc-usernet

# clone and config the container
echo "Cloning the container..."
lxc copy ubuntu-template s-$USERNAME --instance-only
lxc start s-$USERNAME
lxc exec s-$USERNAME -- sh -c "hostname s-$USERNAME"
lxc exec s-$USERNAME -- sh -c "rm -f /root/.ssh/id_rsa* && ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''"
lxc exec s-$USERNAME -- sh -c "cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys"
lxc exec s-$USERNAME -- sh -c "echo 'TZ='Asia/Shanghai'; export TZ' >> /root/.profile"
lxc file pull s-$USERNAME/root/.ssh/id_rsa /root/manager/keys/$USERNAME.private.key

# allocate ssh port
printf "Allocating ssh port: "
PORTFILE=/root/manager/next-port
PORT=$(cat $PORTFILE)
echo $PORT > /root/manager/ports/$USERNAME
echo $(( $PORT+1 )) > $PORTFILE
printf "\e[96;1m$PORT\e[0m\n"

LXCIP=$(lxc info s-$USERNAME | grep 'eth0:' | grep 'inet'  | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
if [[ -z "$LXCIP" ]]; then
    echo "Failed to get your container IP."
    echo "If this problem cannot be solved by retrying, please contact administrators."
    exit 1
fi
iptables -t nat -A PREROUTING -p tcp --dport $PORT -j DNAT --to-destination $LXCIP:8880
iptables -t nat -A POSTROUTING -p tcp -d $LXCIP --dport 8880 -j MASQUERADE
lxc info s-$USERNAME

# finish
#usermod -s /public/login.bash $USERNAME
echo "Done!"
printf "KeyFile: \e[96;1m keys/$USERNAME.private.key\e[0m\n"
printf "Port: \e[96;1m $PORT\e[0m\n"
printf "Have a try: \e[96;1m ssh -i {keyfile} -p $PORT root@10.6.101.26 \e[0m\n"
