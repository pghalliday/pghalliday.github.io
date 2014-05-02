---
layout: post
title:  "Running a full Bitcoin node on AWS"
categories: AWS bitcoin
disqus_identifier: running-a-full-bitcoin-node-on-aws
---

I just want to know how much it will cost to run a full bitcoin node on an EC2 instance. The two main factors being disk usage (the size of the block chain at the time of writing being around 17GB) and IO (how much traffic I may have to pay for to allow incoming connections on port 8333).

1. I start with a t1.micro instance running Ubuntu 14.04 (LTS) 64 bit.
1. For now I accept the default 8GB root volume and add an additional 20GB EBS volume on which I'll store the blockchain (should be good for a few weeks... I think)
1. I configure any IP access on port 22 for SSH (I have to be able to configure my server - although I could restrict the IP addresses allowed to connect on this port for added security)
1. I configure any IP access on port 8333 (I want this to be a useful node and not a leech! So other nodes have to be able to connect)
1. I create a new key pair to access the server using SSH and launch the instance!

Next I have to connect and install/configure bitcoind. To simplify things I'll add a `~/.ssh/config` file to point to my new key and awkward public DNS name

```
Host bitcoin-node
	HostName ec2-XXX-XXX-XXX-XXX.compute-1.amazonaws.com
	User ubuntu
    IdentityFile ~/.ssh/bitcoin-node.pem
```

This allows me to connect with a simple `ssh bitcoin-node`

So, now to install `bitcoind`...

```
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install bitcoind
```

And configure it as a service...

Before I start the `bitcoind` service I want to configure it to use my 20GB EBS volume for the blockchain. The first step of which is to initialize and mount the volume. Run the following command to get the device name

```
# lsblk
NAME  MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvdb  202:16   0  20G  0 disk 
xvda1 202:1    0   8G  0 disk /
```

As you can see, in my case I have an unitialized volume at `/dev/xvdb` (`lsblk` strips the `/dev/` from the device name). So I use the following command to initialize an `ext4` filesystem

```
sudo mkfs -t ext4 /dev/xvdb
```

Next, I need to configure this to be mounted on boot. First I will create a mount point

```
sudo mkdir /data
```

Then we can add the following line to `/etc/fstab` to mount the volume on boot in future

```
/dev/xvdb       /data   ext4    defaults        0       2
```

Run the following to mount the volumes listed in `/etc/fstab`

```
sudo mount -a
```

Now add a `bitcoin` system user, setting its home directory on the EBS volume

```
sudo adduser --system --group --home /data/bitcoin bitcoin
```

To configure `bitcoind` we now need to add a config file to `/data/bitcoin/.bitcoin/bitcoin.conf`

```
rpcuser=bitcoinrpc
rpcpassword=DO_NOT_USE_THIS_PASSWORD_MAKE_UP_SOMETHING_RANDOM_YOU_DONT_HAVE_TO_REMEMBER_IT
```

And set the permissions on it

```
sudo chown bitcoin:bitcoin /data/bitcoin/.bitcoin/bitcoin.conf
sudo chmod 0600 /data/bitcoin/.bitcoin/bitcoin.conf
```

Now we can add an upstart config at `/etc/init/bitcoind.conf`

```
description "bitcoind"

start on filesystem
stop on runlevel [!2345]
oom never
expect daemon
respawn
respawn limit 10 60 # 10 times in 60 seconds

script
user=bitcoin
home=/data/bitcoin
cmd=/usr/bin/bitcoind
pidfile=$home/bitcoind.pid
# Don't change anything below here unless you know what you're doing
[[ -e $pidfile && ! -d "/proc/$(cat $pidfile)" ]] && rm $pidfile
[[ -e $pidfile && "$(cat /proc/$(cat $pidfile)/cmdline)" != $cmd* ]] && rm $pidfile
exec start-stop-daemon --start -c $user --chdir $home --pidfile $pidfile --startas $cmd -b -m
end script
```

Lastly, to register the service and start it...

```
sudo initctl reload-configuration
sudo start bitcoind
```

Now it should be running, although I have no intention of actually using it as a wallet it will hopefully be providing the useful services of a participating full node. Now let's see how the costs stack up.
