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
   echo "S'ha trobat una instal·lació activa del docker"
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
aleat=$RANDOM
db_container=db_$aleat
odoo_container=odoo_$aleat
do_db=true
do_odoo=true
port=8069
quit=0
apt install net-tools
while [ "$quit" -ne 1 ]; do
  netstat -a | grep $port >> /dev/null
  if [ $? -gt 0 ]; then
    quit=1
  else
    port=`expr $port + 1`
  fi
done

while [ $do_db = true ]; do
if [ $(docker ps -a -q -f name=$db_container) ]; then
   echo "El nom $db_container per a el contenidor de la base de dades ja es troba en ús per un altre contenidor"
	echo "Generant un nom aleatori"
	db_container=db_$RANDOM
	echo "S'intenta el següent nom per a la base de dades: $db_container"
else
do_db=false
echo "S'utilitzarà el nom $db_container per a el contenidor de la base de dades"
docker pull postgres:13
docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name $db_container postgres:13
fi
done

while [ $do_odoo = true ]; do
if [ $(docker ps -a -q -f name=$odoo_container) ]; then
	echo "El nom $odoo_container per a el contenidor d'odoo ja es troba en ús per un altre contenidor"
	echo "Generant un nom aleatori"
	odoo_container=odoo_$RANDOM
	echo "S'intenta el següent nom per a l'odoo: $odoo_container"
else
   do_odoo=false
	echo "S'utilitzarà el nom $odoo_container per a el contenidor d'odoo"
	docker pull odoo
	docker run -d -p $port:$port --name $odoo_container --link $db_container:db -t odoo

fi
done
whiptail --title "Comanda root" \
         --yesno "Voleu crear un alias a l'usuari root, per a iniciar el servei?" 7 70
         ans=$?
if [ $ans -eq 0 ]
then
if grep -q "odoo-start" /root/.bashrc
    then
     sed -i".bak" "/odoo-start/d" /root/.bashrc
     echo 'alias odoo-start="docker start' $db_container $odoo_container'"' >> /root/.bashrc
    else
	echo 'alias odoo-start="docker start' $db_container $odoo_container'"' >> /root/.bashrc
    fi
    if grep -q "odoo-stop" /root/.bashrc
    then
     sed -i".bak" "/odoo-stop/d" /root/.bashrc
     echo 'alias odoo-stop="docker stop' $db_container $odoo_container'"' >> /root/.bashrc
    else
	echo 'alias odoo-stop="docker stop' $db_container $odoo_container'"' >> /root/.bashrc
    fi
    whiptail --title "Dades d'accés" \
         --msgbox "Ha finalitzat la instal·lació \n\n Us deixem les vostres dades: \n    Iniciar servei: docker start $db_container $odoo_container o bé odoo-start (com a root) \n    Aturar servei: docker stop $db_container $odoo_container o bé odoo-stop (com a root) \n    Port d'accés: $port" 12 80


else
    whiptail --title "Dades d'accés" \
         --msgbox "Ha finalitzat la instal·lació \n\n Us deixem les vostres dades: \n    Iniciar servei: docker start $db_container $odoo_container \n    Aturar servei: docker stop $db_container $odoo_container \n    Port d'accés: $port" 12 50

fi
}
root_check
