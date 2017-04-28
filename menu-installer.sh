#!/bin/sh
#
# Este script fue escrito para automatizar el proceso de instalacion y configuracion de Foreman
# desde el interprete de comandos, lo que no quita que se debera luego configurar el sistema una 
# vez corriendo desde la Interface WEB.
#
# Las siguientes son las consideraciones previas que se deben tener en cuenta tanto de Hardware
# como de Software:
#
# Recomendaciones de hardware
#   Utilizar una maquina virtual en VMWare
#     - 32Gb de ram
#     - 4 CPU
#     - 2 placas de red
#       - VLAN de red con conexion a todo el resto de las VLANs
#       - VLAN de red unica, donde se pueda instalar un servidor de DHCP para la asignacion de IP para provisionamiento.
#     - 4 discos, donde se configuraran los VG para cada uno de los siguientes FS.
#       - 20GB -> FS del sistema /
#       - 5GB -> SWAP
#       - 50GB -> Base de Datos /var/lib/mongodb
#       - 200GB -> Repositorios /var/lib/pulp
#
# Recomendaciones de software
#   - Sistema base CentOS 7 x86_64 en el ultimo nivel disponible
#   - Instalar vmtools, u open-vm-tools, o similar.
#   - Selinux desactivado
#   - Firewall del sistema operativo desactivado o con la apertura de puertos requerida.
#   - Se usara Foreman 1.13
#   - Se usara Katello 3.2
#   - Se debe configurar proxy en repositorios para buscar paquetes
#
# Autor = Juan Carlos Deguer
# Github = https://github.com/jcdeguer
# Contacto = juan.deguer@gmail.com
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

respuesta=0
PROXY=''
while read respuesta
do
 date
 clear
 echo " "
 echo " ################################################"
 echo " #                                              #"
 echo " #       Auto install The Foreman Project       #"
 echo " #                                              #"
 echo " ################################################"
 echo " "
 echo " Elija la opcion deseada escribiendo el numero entre corchetes '[]' "
 echo " "
 echo " [1] - Preparar el Sistema Operativo. "
 echo " [2] - Definir proxy. "
 echo " [3] - Configurar proxy en repositorios. "
 echo " [4] - Configurar repositorios. "
 echo " [5] - Instalar paquetes necesarios. "
 echo " [6] - Actualizar todo el sistema. "
 echo " [7] - Parametrizar e instalar Foreman. "
 echo " [8] - Salir. "
 echo " "
 echo " Su opcion: "
 read respuesta
 case "$respuesta" in
        1)
         date
         clear
         echo " Se eligio [ Preparar el Sistema Operativo ]... se puede cancelar con [Ctrl]+[C] "
         sleep 5
         clear
         echo " Demasiado tarde, se esta preparando el sistema, solo resta esperar... "
         echo " Desactivando Firewalld... " && systemctl stop firewalld && systemctl disable firewalld && echo " Firewall desactivado ok." && systemctl status firewalld || echo " Algo salio mal, verifique que paso. "
         sleep 5
         echo " Desabilitando Selinux... " && cp -p /etc/selinux/config /etc/selinux/config.`date +%s`.bkp && cat /etc/selinux/config | grep -v "SELINUX=" > /etc/selinux/config.new && echo "SELINUX=disabled" >> /etc/selinux/config.new && mv -f /etc/selinux/config.new /etc/selinux/config && setenforce -1 || echo " Algo salio mal, verifique que paso. "
         sleep 5
         echo " Se configurara el aio-max-nr... " && echo "fs.aio-max-nr=33000" >> vim /etc/sysctl.conf && sysctl -p && echo " Se configuro el fs.aio-max-nr en el sysctl, pressione [ENTER] para continuar..." || echo " Algo salio mal, verifique que paso, pressione [ENTER] para continuar..."
         sleep 5
        ;;
        2)
         clear
         echo " Se eligio [ Definir proxy ]... se puede cancelar con [Ctrl]+[C] "
         echo " Escriba el servidor proxy, si se requiere uno para salir a internet "
         echo " NOTA: Se debe respetar la forma http://DIRECCION_IP:PUERTO "
         read PROXY
         export http_proxy="$PROXY"
         export https_proxy="$PROXY"
         export ftp_proxy="$PROXY"
         echo " Se definio como proxy http -> $http_proxy; https -> $https_proxy; ftp -> $ftp_proxy pressione [ENTER] para continuar..."
         sleep 5
        ;;
        3)
         date
         clear
         echo " Se eligio [ Configurar proxy en repositorios ]... se puede cancelar con [Ctrl]+[C] "
         echo " Se agregara $PROXY al /etc/yum.conf " && cp -p /etc/yum.conf /etc/yum.conf.`date +%s`.bkp && cp -p /etc/yum.conf /etc/yum.conf.tmp && cat /etc/yum.conf.tmp | grep -v "proxy" > /etc/yum.conf && echo "proxy=$PROXY" >> /etc/yum.conf && echo " Se configuro el proxy al yum, pressione [ENTER] para continuar..."
         sleep 5
        ;;
        4)
         date
         clear
         echo " Se eligio [ Configurar repositorios ]... se puede cancelar con [Ctrl]+[C] "
         sleep 3
         echo " Se descargan los paquetes necesarios... " && yum clean all && yum -y localinstall http://yum.theforeman.org/releases/1.13/el7/x86_64/foreman-release.rpm http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://fedorapeople.org/groups/katello/releases/yum/3.2/katello/el7/x86_64/katello-repos-latest.rpm  http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-2-2.el7.centos.noarch.rpm http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-rh-2-2.el7.centos.noarch.rpm && rpm -ivh /var/tmp/yum-root-S2f0Kr/centos-release-scl-* && yum -y install centos-release-scl foreman-release-scl && echo "[centos-sclo-rh-]" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && echo "name=CentOS-7 - SCLo scl RH" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && echo "baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh/" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && echo "gpgcheck=0" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && echo "enabled=1" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && echo " Se instalaron los repositorios, presione [ENTER] para continuar..."
        ;;
        5)
         date
         echo " Se eligio [ Instalar paquetes necesarios ]... se puede cancelar con [Ctrl]+[C] "
         sleep 5
         yum install -y  katello foreman-vmware.noarch rubygem-foreman_api.noarch
        ;;
        6)
         date
         echo " Se eligio [ Actualizar todo el sistema ]... se puede cancelar con [Ctrl]+[C] "
         sleep 5
         yum clean all && yum update -y && echo " Se actualizo todo el sistema, presione [ENTER] para reinciar el equipo..." && shutdown -fr now
        ;;
        7)
         date
         echo " Se eligio [ Parametrizar e instalar Foreman ]... se puede cancelar con [Ctrl]+[C] "
         sleep 5
         foreman-installer --scenario katello -i -v && echo " Se parametrizo e instalo Foreman correctamente, presione [ENTER] para continuar..."
        ;;
        8)
         date
         echo " Se eligio [ Salir ]... Volviendo al interprete de comandos. "
         sleep 5
         break
        ;;
        *)
         date
         esperar=3
         while (test "$esperar" -gt 0)
         do
          clear
          echo " No se eligio una opcion valida, vuelva a intentarlo en $esperar segundos..."
          sleep 1
          esperar=$((esperar-1))
         done
        ;;
 esac
done
