# Alpine Linode Docker Bootstrap

A simple script that can be executed in recovery mode to bootstrap Alpine Linux on a Linode server.

## Creating a Linode

This script assumes your Linode will have three disks for boot, root, and swap, assigned to /dev/sda, /dev/sdb, /dev/sdc, respectively. 

    boot /dev/sda
    root /dev/sdb
    swap /dev/sdc

If you decide not to use a swap disk, you will need to manually delete the relevant parts from the script (which should be fairly easy).

Once the disks have been created, make a new configuration profile. It can be labeled anything you would like, but the following options should be changed: 

- **Kernel** to GRUB 2
- **Block Device Assignment**s to the order specified above
- **Filesystem/Boot Helpers** all to *No*. 
- Everything else should be left as the default. 

Boot the Linode into recovery mode with the disks assigned as above.

## Prepare to allow HTTPS
    	
    update-ca-certificates

## Executing the Script

Connect to the Linode with Lish either via SSH or the browser console. To download and run the script:

    curl -o- https://raw.githubusercontent.com/exocode/alpine-linode-bootstrap/master/alpine-linode-bootstrap.sh | bash

__ if errors occour choose another mirror by uncommenting it 

Once that finishes, shut the Linode down from recovery mode and, staying in the Lish console, run:
  
    boot 1

After a bit, you should be at the Alpine login screen. The root user, by default, does not have a password. At this point, you can install an SSH server, which pretty much completes the installation.

## Further Installation

### Set up and start networking

    setup-interfaces

Press enter 3 times to accept the defaults of 
    - eth0
    - dhcp
    - no

then restart the networking service:
    
    service networking restart

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
  

## Docker

uncomment `http://your_choosen_repo/alpine/edge/community` in `/etc/apk/repositories`

    vi /etc/apk/repositories 
    
    apk update # to update the new repo list
    
    apk add docker

To start the Docker daemon at boot, run:

    rc-update add docker boot
    
Then to start the Docker daemon manually, run:

    service docker start

## Docker Compose

To install docker-compose, first install pip:

    apk add py-pip
    
Then install docker-compose, run:

    pip install docker-compose


## Helpful scripts

sets automatically the fastest apk repo

    https://raw.githubusercontent.com/padthaitofuhot/apkfastestmirror/master/apkfastestmirror.sh
    ash ./apkfastestmirror.sh --install
    apkfastestmirror -r
    
https://github.com/padthaitofuhot/apkfastestmirror

## Credit

This script is basically [Andy Leap's guide](https://github.com/andyleap/docs/blob/master/docs/tools-reference/custom-kernels-distros/install-alpine-linux-on-your-linode.md) written as a working script (with fixed networking!), so big thanks to him.
