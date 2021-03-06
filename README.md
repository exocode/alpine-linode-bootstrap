# Alpine Linode Docker Bootstrap

A simple script that can be executed in __recovery mode__ to bootstrap Alpine Linux on a Linode server.

## Creating a Linode

This script assumes your Linode will have __three disks__ for __boot, root, and swap__, assigned to /dev/sda, /dev/sdb, /dev/sdc, respectively. 

    boot /dev/sda
    root /dev/sdb
    swap /dev/sdc

If you decide not to use a swap disk, you will need to manually delete the relevant parts from the script (which should be fairly easy).

Once the disks have been created, make a new configuration profile. It can be labeled anything you would like, but the following options should be changed: 

- **Kernel** to GRUB 2
- **Block Device Assignment**s to the order specified above
- **Filesystem/Boot Helpers** all to *No*. 
- Everything else should be left as the default. 

Boot the Linode into __recovery mode__ with the disks assigned as above.

Once logged in do the following:

## Prepare to allow HTTPS
    	
    update-ca-certificates

## Executing the Script

Connect to the Linode with Lish either via SSH or the browser console. To download and run the script:

    curl -o- https://raw.githubusercontent.com/exocode/alpine-linode-bootstrap/master/alpine-linode-bootstrap.sh | bash

__if errors occour choose another mirror or rerun the script


## Helpful scripts for choosing another mirror

sets automatically the fastest apk repo

    wget https://raw.githubusercontent.com/padthaitofuhot/apkfastestmirror/master/apkfastestmirror.sh
    ash ./apkfastestmirror.sh --install
    apkfastestmirror -r
    
https://github.com/padthaitofuhot/apkfastestmirror


## Finished installation

Once that finishes, shut the Linode down from recovery mode and, staying in the Lish console, run:
  
    boot 1

After a bit, you should be at the Alpine login screen. The root user, by default, does not have a password. At this point, you can install an SSH server, which pretty much completes the installation.

## Further Installation

### Set a root password
    
    passwd
    
    adduser example-user
    
### Install sudo package

    apk add sudo

Configure sudo to allow users in the sudo group to temporarily elevate their privileges:

    echo "%sudo   ALL=(ALL) ALL" >> /etc/sudoers

    addgroup sudo
    adduser example-user sudo
  
### Login with id_rsa.pub

On server create a .ssh directory

    mkdir -p ~/.ssh && chmod -R 700 ~/.ssh/
  
### Install and configure SSH daemon

    setup-sshd

Linode recommends the `openssh` server if you want full SFTP access. 
`dropbear` is a more lightweight option, although it only provides SSH access.

At this point, you should be able to connect to your server via SSH.


## iptables / Firewall

Install the iptables firewall. Docker adds its own rules if you start a container.

    apk add iptables

## Docker

uncomment `http://your_choosen_repo/alpine/edge/community` in `/etc/apk/repositories`

    vi /etc/apk/repositories 
    
    apk update # to update the new repo list
    
    apk add docker

To start the Docker daemon at boot, run:

    rc-update add docker boot
    
Then to start the Docker daemon manually, run:

    service docker start
    
## Extend your Java 

I ran into the issue that heavy used apps wont start with docker (in my example Rancher).
I had to do this:

    sysctl -w kernel.pax.softmode=1


## Docker Compose

To install docker-compose, first install pip:

    apk add py-pip
    
Then install docker-compose, run:

    pip install docker-compose

## Rancher

If your DB runs on another host (which is best practice) run:

    docker run -d --restart=always -p 8080:8080 \
      -e CATTLE_DB_CATTLE_MYSQL_HOST=<hostname or IP of MySQL instance> \
      -e CATTLE_DB_CATTLE_MYSQL_PORT=<port> \
      -e CATTLE_DB_CATTLE_MYSQL_NAME=<Name of Database> \
      -e CATTLE_DB_CATTLE_USERNAME=<Username> \
      -e CATTLE_DB_CATTLE_PASSWORD=<Password> \
      rancher/server:v1.0.2


### Reconfigure networking (you can skip this, we already done this for you)

    setup-interfaces
    - eth0
    - dhcp
    - no

then restart the networking service:
    
    service networking restart



## Credit

This script is basically [Andy Leap's guide](https://github.com/andyleap/docs/blob/master/docs/tools-reference/custom-kernels-distros/install-alpine-linux-on-your-linode.md) written as a working script (with fixed networking!), so big thanks to him.


# ISSUE

I had problems on my host with the IP address. Everytime I reboot the IP got lost. Only after a ``service networking restart`` solved my IP. My workaround is to edit ``vi /etc/init.d/networking``:

In the ``start()`` section change this line

    if ! ifup $iface >/dev/null; then

to this (forces a restart)

    if ! ifup -f $iface >/dev/null; then
