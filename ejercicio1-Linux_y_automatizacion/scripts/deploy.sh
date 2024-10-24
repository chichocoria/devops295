#/bin/bash
#Autor:Ruben Dario Coria
#Probado en ubuntu 22.04 LTS

# Variables
repo="devops295"
directory="ejercicio1-Linux_y_automatizacion"
USERID=$(id -u)

# Colores
Color_Off='\033[0m' # Text Reset
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'   # Blue


# Funciones
# Funciones de success o failed del deploy

success () {
   echo -e "${Green}El Deploy se realizo con exito....${Color_Off}"
   echo -e "${Green}Enviando notificacion... :)${Color_Off}"   
}

failed () {
   echo -e "${Green}El deploy Fallo${Color_Off}"
   exit 1
}


if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[33mCorrer con usuario ROOT\033[0m"
    exit
fi 

echo -e "${Green}==================Script ejercicio 1 -Bootcamp Devops===================${Color_Off}"
apt-get update
echo -e "${Yellow}Servidor se encuentra Actualizado ...${Color_Off}"
sleep 2

echo -e "${Green}================INIT=====================${Color_Off}"

# Verificar git está instalado
if dpkg -s git | grep "install ok installed" > /dev/null 2>&1; then
    echo -e "${Green}git está instalado.${Color_Off}"
else
    echo -e "${Green}git se va a instalar...${Color_Off}"
    apt install git -y
fi

# Verificar si mariadb está instalado
if dpkg -s mariadb-server | grep "install ok installed" > /dev/null 2>&1; then
    echo -e "${Green}mariadb está instalado.${Color_Off}"
else
    echo -e "${Red}El paquete no se encuentra instalado${Color_Off}"
    echo -e "${Green}mariadb se va a instalar...${Color_Off}"
    sudo apt install -y mariadb-server
    #Iniciando la base de datos
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
fi
##Verificar el estado de mariadb
mariadb=$(service mariadb status)
if [[ $mariadb == *"active (running)"* ]]; then
    echo -e "${Green}El proceso mariadb esta corriendo${Color_Off}"
else 
    echo -e "${Red}El proceso mariadb no esta corriendo${Color_Off}"
fi

# Configuracion de la base de datos.
echo -e "${Blue}Configurando la base de datos...${Color_Off}"
# Creando la base de datos, usuario y contraseña
mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"

# Ejecutar el script para insertar los datos en la base de datos
mysql < devopstravel.sql
echo -e "${Green}Se creo bd, users y se insertaron datos en la DB${Color_Off}"

# Verificar si apache está instalado
if dpkg -s apache2 | grep "install ok installed" > /dev/null 2>&1; then
    echo -e "${Green}Apache está instalado.${Color_Off}"
else
    echo -e "${Green}Apache se va a instalar...${Color_Off}"
    apt install apache2 -y
    sudo apt install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl 
    #Inicio de apache
    sudo systemctl start apache2 
    sudo systemctl enable apache2
fi

##Verificar el estado de apache
servstat=$(service apache2 status)
if [[ $servstat == *"active (running)"* ]]; then
    echo -e "${Green}El proceso apache esta corriendo${Color_Off}"
else 
    echo -e "${Red}El proceso apache no esta corriendo${Color_Off}"
fi

# Verificar si php está instalado
if command -v php &> /dev/null; then
    echo -e "${Green}PHP esta instalado en el sistema${Color_Off}"
    # print de la version de php
    php --version
else
    echo "PHP no está instalado en el sistema."
fi

echo -e "${Green}===============BUILD======================${Color_Off}"

# Verificar si existe el repositorio bootcamp-devops-2023
cd /root
if [ -d "$repo" ]; then
    echo -e "${Green}La carpeta $repo existe ...${Color_Off}"
    echo -e "${Green}Corriendo gitpull para traer cambios...${Color_Off}"
    cd $repo
    git pull
else
    # Clonar el repositorio
    echo -e "${Green}instalando WEB ...${Color_Off}}"
    sleep 1
    cd /root
    git clone https://github.com/chichocoria/$repo.git
fi


# Cambiar a la branch clase2-linux-bash
#cd /root/$repo
#git checkout clase2-linux-bash
# Copiar el contenido de la carpeta a /var/www/html
echo -e "${Green}Copiando contenido de la carpeta $repo a /var/www/html{Color_Off}"
cd /root
cp -r $repo/$directory/* /var/www/html

# Configurar apache para que soporte extensión php
cd /etc/apache2/mods-enabled/
cp dir.conf dir.conf.bak
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/g' dir.conf

#Enviar la password como argumento al correr el script.
#ejemplo: ./script.sh db_password
sed -i 's/$dbPassword = "";/$dbPassword = "'$1'";/g' /var/www/html/config.php


##########Validar si la URL da code 200 OK#################
url="localhost/info.php"

# Realizar la solicitud HTTP y almacenar el código de respuesta en una variable
http_code=$(curl -s -o /dev/null -w "%{http_code}" $url)

# Verificar si el código de respuesta es 200 (OK)
if [ $http_code -eq 200 ]; then
    echo -e "${Green}La URL $url está OK (código 200).${Color_Off}"
else
    echo -e "${Green}La URL $url retornó un código de respuesta diferente de 200: $http_code ${Color_Off}"
fi
##############################################################

echo -e "${Green}===============DEPLOY======================${Color_Off}"

# Restart apache
systemctl restart apache2

##########Validar si la URL da code 200 OK#################
url1="localhost"

# Realizar la solicitud HTTP y almacenar el código de respuesta en una variable
http_code1=$(curl -o /dev/null -s -w "%{http_code}" $url1)

# Verificar si el código de respuesta es 200 (OK)
if [ $http_code1 -eq 200 ]; then
    echo -e "${Green}La URL Devops Travel está OK (código 200).${Color_Off}"
    success
    cd ~/devops295/ejercicio1-Linux_y_automatizacion/scripts
    source discord.sh /root/devops295
    echo -e "${Green}La URL $url1 retornó un código de respuesta diferente de 200: $http_code1 ${Color_Off}"
fi
##############################################################