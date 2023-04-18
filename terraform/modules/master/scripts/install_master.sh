#!/bin/bash

GO_VERSION="go1.20.3.linux-amd64"

# wait for a valid network configuration
echo "# Waiting for valid network configuration"
until ping -c 1 8.8.8.8; do sleep 1; done

echo "# Installing golang-go version ${GO_VERSION}"
#export DEBIAN_FRONTEND=noninteractive
#apt-get update
#apt-get install -y golang-go

wget -c https://go.dev/dl/${GO_VERSION}.tar.gz -O - | sudo tar -xz -C /usr/local
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> /root/.bashrc
echo "export PATH=$PATH:/usr/local/go/bin" >> /home/master/.bashrc
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
mkdir /root/go
export GOPATH="/root/go"

echo "Installing latest k0sctl using go
sudo -H -u master bash -c 'export PATH=$PATH:/usr/local/go/bin
 && cd ~ && go install github.com/k0sproject/k0sctl@latest'

ln -s /home/master/go/bin/k0sctl /usr/local/bin/k0sctl

echo "# Finished master installation"