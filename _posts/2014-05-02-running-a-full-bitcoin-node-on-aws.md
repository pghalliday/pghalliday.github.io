---
layout: post
title:  "Running a full Bitcoin node on AWS"
categories: AWS bitcoin
disqus_identifier: running-a-full-bitcoin-node-on-aws
---

UPDATE - 10th August 2014: The results are in
=============================================

The node stayed stable throughout July and the free tier benefits ran out before that so the following is the complete cost.

Total incl. VAT: $42.06

The main contributions to this were:

Data Transfer
-------------

$0.120 per GB - up to 10 TB / month data transfer out: 135.096 GB: $16.21

EC2
---

$0.020 per On Demand Linux t1.micro Instance Hour: 744 Hrs:	$14.88

$0.05 per 1 million I/O requests - US East (Northern Virginia): 23,715,799 IOs: $1.19

$0.05 per GB-month of Magnetic provisioned storage - US East (Northern Virginia): 48.000 GB-Mo: $2.40

---

I just want to know how much it will cost to run a full bitcoin node on an EC2 instance. The two main factors being disk usage (the size of the block chain at the time of writing being around 17GB) and IO (how much traffic I may have to pay for to allow incoming connections on port 8333).

1. I start with a t1.micro instance running Ubuntu 14.04 (LTS) 64 bit.
1. For now I accept the default 8GB root volume and add an additional 40GB EBS volume on which I'll store the blockchain (Originally I started with 20GB but this did not last long before running out of space and crashing the node - i'm sure less would suffice for a while but i don't want to resize the disk again every few days/weeks)
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

Before I start the `bitcoind` service I want to configure it to use my EBS volume for the blockchain. The first step of which is to initialize and mount the volume. Run the following command to get the device name

```
# lsblk
NAME  MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvdb  202:16   0  40G  0 disk 
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
sudo adduser --system --group --shell /bin/bash --home /data/bitcoin bitcoin
```

To configure `bitcoind` we now need to add a config file to `/data/bitcoin/.bitcoin/bitcoin.conf`

```
rpcuser=bitcoinrpc
rpcpassword=DO_NOT_USE_THIS_PASSWORD_MAKE_UP_SOMETHING_RANDOM_YOU_DONT_HAVE_TO_REMEMBER_IT
```

Now set the permissions on it

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
exec start-stop-daemon --start -c $user --chdir $home --pidfile $pidfile --startas $cmd -b --nicelevel 15 -m
end script
```

Before we can start the service we need to make sure that the machine does not run out of memory and crash it. This will happen after a fairly short time. The solution is to add a swapfile.

```
sudo dd if=/dev/zero of=/swapfile bs=1M count=1536
sudo mkswap /swapfile
sudo swapon /swapfile
```

This creates a 1.5GB (a little over twice the RAM of 0.613GB on a t1.micro instance) swap file and activates it. In order to ensure it is activated on reboot we need to add another entry to `/etc/fstab`

```
/swapfile       none    swap    sw      0       0 
```

To ensure that the swapfile is only used when it's really needed we should set the swappiness. This is an optimization of the kernel. A high value (maximum of 100) would tell the kernel to favour the swap file, we will set a low value of 10 to favour RAM when it is available.

```
echo 10 | sudo tee /proc/sys/vm/swappiness
echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
```

These commands set the current swappiness value and set the kernel configuration to the same value on reboot. To finish configuring the swapfile, set its permissions so that it cannot be read by other users.

```
sudo chown root:root /swapfile 
sudo chmod 0600 /swapfile
```

Only now should we register the service and start it...

```
sudo initctl reload-configuration
sudo start bitcoind
```

And there we go, the bitcoin node should be running and downloading the blockchain. I have no intention of actually using it as a wallet but hopefully it will be providing the useful services of a participating full node. Now let's see how the costs stack up.
