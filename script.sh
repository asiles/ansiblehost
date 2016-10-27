#!/bin/sh
echo "Version: 2.0 - 08/07/2015"
USER_CF=ansible
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkfNkupNWQ1m0realCoO6N3EH06WvB3g7irT+0i6YkS8VsvKfIpB4y3TvRGhNgveQEPWGrkQpLBKDptsI6Axp2y82ItxhSX5Pz5RiRdohUJZvsfNZlSKq2ZMR119I3iJoYswz24PjT8LO+6EcAUIjNI+YNcHuTXfLGbAW8JOP9S3kVkTpo9JvPimqQatfnG+YDrPltQmpgxgHThC/skEqFD023U9eu881jxlMZ5XQA/cmEPWVldv9+9qlfrK6LDAX+6fNzDpnbJ9sy6Cv+GncPUu0avkcRIoQdSDMimX4kyIxh4EWtOwIA28mcZE2iNW4WbWmxaTcRY/kIFuUhSgbb ansible@asnible'
#PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8fu5iNyvNOxMkjb3f/Thrq++FhbSLGfttiySGhrDp7Pb/npjPWH8/KG+B0+iUa+QzL6dmXbCeYNxHFN4vqhDibieR+7VyCs8f5vmrkcjW4uZm58YAIBYGSdG6lntyRR9yRgQiGCrOQwDvFOUAq21RwwkR+fGzxo9GNW+r++d1kvelB7MS0HTT7BF58zmVMpSdycEN+zftSKwx0DVNL3MM371Amjd1Nm0wOtEP7QzBqvKBCsUQ2tpf37gQ9yQcJMfY0n2ta83lgIxxPLMZehdSQmcKlnVBmVqb9XjiTkZSBoectJnfmLtAC7YClTvKMLmhfMUBkryWrJ3YpIxGkpif ansible@new-ansible'
#SHADOW='\$6\$AppBBndZ\$PGx/Dc.Bfrass3Zlv80G8ngA1SBX0cPWbD/1rybf5nhMq6Z7a4hgGnE6WM2XyMzon/HCAUBcJpM9hI4fw1LQU0'
SHADOW='$6$AppBBndZ$PGx/Dc.Bfrass3Zlv80G8ngA1SBX0cPWbD/1rybf5nhMq6Z7a4hgGnE6WM2XyMzon/HCAUBcJpM9hI4fw1LQU0'
YUM_CMD='yum install -y python-simplejson'
  
# Miramos si existe el usuario y si es asi, lo borramos
id -u $USER_CF >/dev/null 2>&1
if [ $? -eq 0 ];then
  # eliminamos usuario ya existente
  userdel -r $USER_CF >/dev/null 2>&1
  groupdel $USER_CF >/dev/null 2>&1
fi
# Creamos usuario nuevo 
useradd $USER_CF -p $SHADOW -U -m >/dev/null 2>&1
# Añadimos la entrada del nuevo usuario en sudo.
# Miramos que exista el directorio de configuraciones de sudo (sistema actual)
if [ -d "/etc/sudoers.d" ];then
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && chmod 0440 /etc/sudoers.d/ansible   
else
    # No existe directorio de configuraciones de sudo y se debe insertar la linea en el fichero unico de configuracion (sistemas antiguos)
    # Miramos si exite el fichero de configuracion unica de sudo. Sino existe es que no esta intalado.
    if [ -e "/etc/sudoers" ];then
        # Existe
        echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    else
        # No existe
        echo "Existe algun problema con sudo. Esta instalado? No existe ni /etc/sudoers.d ni /etc/sudoers"
    fi
fi
# Creamos el directorio .SSH en el HOME del usuario que se acaba de crear y su correspondiente fichero authorized_keys
HOME_DIR=`grep $USER_CF /etc/passwd | cut -d ':' -f6`
su root -c "mkdir $HOME_DIR/.ssh"
su root -c "chmod 700 $HOME_DIR/.ssh"
su root -c "echo $PUBLIC_KEY > $HOME_DIR/.ssh/authorized_keys"
su root -c "chmod 600 $HOME_DIR/.ssh/authorized_keys"
su root -c "chown -R $USER_CF.$USER_CF $HOME_DIR"
# Miramos si existe Python (problema habitual en Debian)
python --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    #NO HAY PYTHON
    echo "Python no esta instalado en el sistema. Lo mas seguro es que debas instalarlo manualmente (por ejemplo: apt-get install python, yum install python o zypper install python )."
else
    echo "Python Ok"
    # Miramos la distribución para instalar la libreria python-simplejson necesaria. Esto ocurre con RedHat 5.x.
    if [ -e "/etc/redhat-release" ];then
        grep "5." /etc/redhat-release >/dev/null 2>&1
        if [ $? -eq 0 ];then
            eval $YUM_CMD
        fi
    fi
    # Miramos si existe el modulo JSON en Python
    pydoc modules | grep json >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        #NO HAY JSON en PYTHON
        echo "Python no tiene ningun modulo JSON instalado. Lo mas seguro es que debas instalarlo manualmente (por ejemplo: apt-get install python-simplejson, yum install python-simplejson o zypper install python-simplejson )."
    else
        echo "Modulo JSON en Python OK"
    fi
fi
echo "Done."   
