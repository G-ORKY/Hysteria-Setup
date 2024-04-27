#!/bin/bash

/!homepath/acme.sh --install-cert -d !servername --ecc --fullchain-file !certpath/cert/!servername.crt --key-file !certpath/cert/!servername.key


chmod +r !certpath/!servername.key
echo "Read Permission Granted for Private Key"

pid=$(pidof sudo sing-box run -c !installationpath/Hystaria/config/Hysteriaconfig.json)
sudo kill $pid

sudo sing-box run -c !installationpath/Hystaria/config/Hysteriaconfig.json
echo "sing-box Renewed"
