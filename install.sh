#!/bin/bash
#Autor: Òscar Herrán Morueco
root_check()
{
if [ "$(id -u)" != "0" ]; then
	whiptail --title "Error!" \
    --msgbox "Heu d'executar aquest script com a root (sudo) > ./nomscript.sh" 10 30
	exit 1
fi
comprova_connexio
}

comprova_connexio()
{


if nc -zw1 google.com 443; then
  main
  else
  whiptail --title "Error!" \
    --msgbox "Comproveu la connexió a internet!" 10 30
    clear
    exit 1
fi
}

main()
{
apt update
apt upgrade -y
if [[ $(which docker) && $(docker --version) ]]; then
 	odoo_container_install
  else
    echo "No s'ha trobat una instal·lació activa del docker"
    echo "Instal·lant el docker"
    if [ -f "etc/apt/keyrings/docker.gpg" ]; then
    rm '/etc/apt/keyrings/docker.gpg'
    fi
    apt install ca-certificates curl gnupg lsb-release -y
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose -y
    odoo_container_install
    fi
}

odoo_container_install(){
db_container=db
odoo_container=odoo
if [ -n $(docker container ls | grep $db_container) ];then
	echo "El nom $db_container ja es troba en ús per un altre contenidor"
	echo "Generant un nom aleatori"
else
if [ -n $(docker container ls | grep $odoo_container) ];then
	echo "El nom $odoo_container ja es troba en ús per un altre contenidor"
	echo "Generant un nom aleatori"
fi
fi

}
root_check
