#!/bin/bash
echo "Please type the path that you want to install and set up sing-box in:"
read installationpath

echo "Please type the domain used on this server as the proxy server name:"
read servername

echo "Please type the user you want use for installation:"
read usr
homepath="/home/$usr"

rm -r $installationpath/Hysteria #remove the previous installation if exists
mkdir $installationpath/Hysteria

mkdir $installationpath/Hysteria/cert
certpath=$installationpath/Hysteria/cert

mkdir $installationpath/Hysteria/config
mkdir $installationpath/Hysteria/site #The site to redirect to when hysteria authentication is failed
sitepath=$installationpath/Hysteria/site

touch $installationpath/Hysteria/installation.log
# the log file that will be created to record the installation results and errors,
# btw installation.log can be manually deleted

usrtype=$(whoami)
echo $usrtype
if [ "$usrtype"==root ];
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

        wget -P $installationpath/Hysteria/config/ https://raw.githubusercontent.com/G-ORKY/Proxy-server-initiallizer/main/Hysteriaconfig.json
        wget -P $installationpath/Hysteria/site/ https://raw.githubusercontent.com/G-ORKY/Proxy-server-initiallizer/main/re.html
        sudo chmod +777 $installationpath/Hysteria/site/re.html
        #download the configuration file and the site to redirect to when hysteria authentication is failed

        echo "Choose the path you want to put your log file in, or leave it empty to use the default path($logpath):"
        read logpath
        if $logpath=="";
        then
            $logpath=$installationpath/Hysteria/config/Hysteriaconfig.json
            sed -i s/!singbox-log/$logpath/g $installationpath/Hysteria/config/Hysteriaconfig.json
            #set the log path in the configuration file
        else
            sed -i s/!singbox-log/$logpath/g $installationpath/Hysteria/config/Hysteriaconfig.json
            #set the log path in the configuration file
        fi

        echo "Choose username you want to use:"
        read username
        sed -i s/!usrname/$username/g $installationpath/Hysteria/config/Hysteriaconfig.json
        #set the username in the configuration file

        echo "Enterthe password you want to use:"
        read password
        sed -i s/!usrpassword/$password/g $installationpath/Hysteria/config/Hysteriaconfig.json
        #set the password in the configuration file

        wget -P /home/$usr -O -  https://get.acme.sh | sh

        . .bashrc

        /home/$usr/.acme.sh/acme.sh --upgrade --auto-upgrade
        #install and turn on the auto upgrade for acme.sh

        echo "Choose the option you want to use to obtain the certificate :"
        echo "1."I have the site privious run on this server!""
        echo "2."I have the domain but it is not related to any site on this server and I AGREE to use the default site!""
        echo " "
        echo "Option 2 will replace the privious nginx.conf file, so if you have any custom configuration, please choose option 1 or make sure that you have the backup of the nginx.conf and you need to re-add your privious config after configuration!!!"
        
        read siteoption
        if $siteoption=="1"
        then
            echo "Use the privious site to obtain a certificate"
        else
            rm -f /etc/nginx/nginx.conf
            wget -P /etc/nginx/ "https://raw.githubusercontent.com/G-ORKY/Proxy-server-initiallizer/main/nginx.conf"
            sleep 3
            sed -i "s/!servername!/"$servername"/g" /etc/nginx/nginx.conf
            # sed -i "s/!sitepath!/"$sitepath"/g" /etc/nginx/nginx.conf
            sed -i "s|!sitepath!|"$sitepath"|g" /etc/nginx/nginx.conf
            sudo systemctl reload nginx
        fi

        sudo chmod +777 $sitepath

        deploystate=$(/home/$usr/.acme.sh/acme.sh --issue --server letsencrypt --test -d $servername -w $sitepath --keylength ec-256)
        echo $deploystate >> $installationpath/Hysteria/installation.log

        testoutcome=$(cat $installationpath/Hysteria/installation.log | grep 'error')
        if $testoutcome=="error";
        then
            echo "Failed to obtain the certificate, please check the log file for more details."
        else
            /home/$usr/.acme.sh/acme.sh --set-default-ca --server letsencrypt
            /home/$usr/.acme.sh/acme.sh --issue -d $servername -w $sitepath --keylength ec-256 --force
            /home/$usr/.acme.sh/acme.sh --installcert -d $servername  --key-file /$certpath/$servername.key --fullchain-file /$certpath/$servername.crt --ecc

            sudo chmod +r /$certpath/$servername.key

            wget -P $certpath https://raw.githubusercontent.com/G-ORKY/Proxy-server-initiallizer/main/certrenew.sh
            sed -i s#!homepath#home/$usr#g $certpath/certrenew.sh
            sed -i s#!servername#$servername#g $certpath/certrenew.sh
            sed -i s#!certpath#$certpath#g $certpath/certrenew.sh
            sed -i s#!installationpath#$installationpath#g $certpath/certrenew.sh

            sudo chmod +x $certpath/certrenew.sh

            echo "Congratulations! All done! Please enter your password to start the sing-box. Feel free to use your proxy server!"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "Please remember to add the crontab to renew the certificate automatically, you can use the following command to add the crontab:"
            echo "# 1:00am, 1st day each month, run `certrenew.sh`"
            echo "0 1 1 * *   bash $certpath/certrenew.sh"

            sudo sing-box run -c $installationpath/config/Hysteriaconfig.json
        fi

    else
        echo "This script is currently not supported on your OS, please contact us to request support for your OS."
    fi
else
    echo "please use the root account to run this script."
    echo "btw you can use "sudo -i" and then run this script to set up."
fi

