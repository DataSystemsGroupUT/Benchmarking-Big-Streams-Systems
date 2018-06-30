#! /usr/bin/env bash
sudo apt-get upgrade
sudo apt-get update
sudo apt-get install git
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt-get install maven
sudo update-alternatives --config java


source /etc/environment
echo $JAVA_HOME

sudo apt-get install make
sudo apt-get install gcc
sudo apt-get install tcl
sudo apt-get install build-essential

sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python2.7

wget -O- https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/install.sh | sudo /bin/bash


wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
sudo mkdir -p /usr/local/bin/
sudo mv ./lein* /usr/local/bin/lein
sudo chmod a+x /usr/local/bin/lein
export PATH=$PATH:/usr/local/bin
lein repl


sudo reboot
