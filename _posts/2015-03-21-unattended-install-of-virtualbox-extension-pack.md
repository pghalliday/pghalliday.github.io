---
layout: post
title:  "Unattended Install of VirtualBox Extension Pack"
categories: virtualbox extension pack unattended chef dotfiles
disqus_identifier: unattended-install-of-virtualbox-extension-pack
comments: true
---

Another note I'm really leaving for myself. I've migrated my `dotfiles` project to use `Chef`, both installing and configuring my commonly used applications. One which is annoying is `VirtualBox`. 2 problems really. The first is that the VirtualBox Ubuntu repository can be super slow. For now I'm living with that.

The second is that I need to install the extension pack for good USB support. This is tricky because the download is version specific and in my chef recipe I always install the latest version. Also I had to dig around a bit to discover how to install without a GUI.

Anyway, problem solved and I figured I'd share this handy script that

- checks the installed version
- downloads the correct extension pack to the current directory
- verifies the shasum
- installs it

```sh
#!/bin/bash

set -e

version=$(VBoxManage --version)
IFS='r' read -a versions <<< "${version}"
shasums_url=https://www.virtualbox.org/download/hashes/${versions[0]}
extpack=Oracle_VM_VirtualBox_Extension_Pack-${versions[0]}-${versions[1]}.vbox-extpack
extpack_url=http://download.virtualbox.org/virtualbox/${versions[0]}
wget -O ${extpack} ${extpack_url}/${extpack}
wget -O - ${shasums_url}/SHA256SUMS | grep ${extpack} | sha256sum -c
VBoxManage extpack install --replace ${extpack}
```

Enjoy! ;)
