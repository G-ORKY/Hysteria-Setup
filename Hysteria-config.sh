#!/bin/bash
read installationpath

rm -r $installationpath/Hysteria
mkdir $installationpath/Hysteria
mkdir $installationpath/Hysteria/cert
mkdir $installationpath/Hysteria/config
mkdir $installationpath/Hysteria/site #The site to redirect to when hysteria authentication is failed

touch $installationpath/Hysteria/installation.log
# the log file that will be created to record the installation results and errors,
# btw installation.log can be manually deleted
touch $installationpath/Hysteria/config/hysteria.json
touch $installationpath/Hysteria/site/index.html

usrtype=$(whoami)
if usrtype=="root";
then
    version=$(cat /etc/*-release | grep -oP '(?<=^ID=).+' | tr -d '"')
    version_id=$(cat /etc/*-release | grep -oP '(?<=^VERSION_ID=).+' | tr -d '"')

    echo $version+$version_id

    #version=$(cat /proc/version)
    # sed a\ $version ~/Hysteria/installation.log

    echo $version+$version_id \n >> ~/Hysteria/installation.log

    if [ $version = "ubuntu" ] || [ $version = "debian" ]; 
    then
        apt install nginx
        apt update
        apt upgrade curl && apt install curl

        bash <(curl -fsSL https://sing-box.app/deb-install.sh)
        echo "sing-box core installed" >> ~/Hysteria/installation.log

        


    else
        echo "This script is currently not supported on your OS, please contact us to request support for your OS."
    fi
else
    echo "please use the root account to run this script."
    echo "btw you can use "sudo -i" and then run this script to set up."
fi

