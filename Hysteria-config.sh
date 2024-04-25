#!/bin/bash
echo "Please insert the path that you want to install and set up sing-box in:"
read installationpath

rm -r $installationpath/Hysteria
mkdir $installationpath/Hysteria
mkdir $installationpath/Hysteria/cert
mkdir $installationpath/Hysteria/config
mkdir $installationpath/Hysteria/site #The site to redirect to when hysteria authentication is failed

touch $installationpath/Hysteria/installation.log
# the log file that will be created to record the installation results and errors,
# btw installation.log can be manually deleted

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
        apt update
        apt install nginx
        apt upgrade curl && apt install curl
        #update basic modules

        bash <(curl -fsSL https://sing-box.app/deb-install.sh)
        echo "sing-box core installed" >> ~/Hysteria/installation.log
        #install sing-box core

        wget -P $installationpath/Hysteria/config/ https://github.com/G-ORKY/Proxy-server-initiallizer/blob/main/Hysteriaconfig.json
        wget -P $installationpath/Hysteria/site/ https://github.com/G-ORKY/Proxy-server-initiallizer/blob/main/re.html
        #download the configuration file and the site to redirect to when hysteria authentication is failed

        echo "Choose the path you want to put your log file in, or leave it empty to use the default path($logpath):"
        read logpath
        if $logpath=="";
        then
            $logpath=$installationpath/Hysteria/config/Hysteriaconfig.json
            sed -i s/!singbox-log/$logpath/g $installationpath/Hysteria/config/Hysteriaconfig.json
        else
            sed -i s/!singbox-log/$logpath/g $installationpath/Hysteria/config/Hysteriaconfig.json
        fi



    else
        echo "This script is currently not supported on your OS, please contact us to request support for your OS."
    fi
else
    echo "please use the root account to run this script."
    echo "btw you can use "sudo -i" and then run this script to set up."
fi

