!/usr/bin/env bash

set -e

yum clean all
yum -y update

# Instalação dos componentes básicos do servidor web apache
yum -y install httpd memcached openssl wget curl unzip gcc java-1.8.0-openjdk libxml2 cabextract xorg-x11-font-utils fontconfig mod_ssl

# Instalação dos componentes para wkhtmltox
yum -y install libpng libjpeg icu libX11 libXext libXrender xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi

# Instalação do PHP e demais extenções necessárias para o projeto
yum install -y epel-release yum-utils

# CENTOS 0.1
# yum install -y http://mirror.team-cymru.com/remi/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php73
yum -y update

# Instalação do PHP e demais extenções necessárias para o projeto
yum -y install php php-common php-cli php-pear php-bcmath php-gd php-gmp php-imap php-intl php-ldap php-mbstring php-mysqli \
    php-odbc php-pdo php-pecl-apcu php-pspell php-zlib php-snmp php-soap php-xml php-xmlrpc php-zts php-devel \
    php-pecl-apcu-devel php-pecl-memcache php-calendar php-shmop php-intl php-mcrypt php-pecl-zip \
    gearmand libgearman libgearman-devel php-pecl-gearman vixie-cron \
    freetds freetds-devel php-mssql php-sodium \
    git nc gearmand libgearman-dev libgearman-devel mysql

# CENTOS 0.2
# Configuração do pacote de línguas pt_BR
localedef pt_BR -i pt_BR -f ISO-8859-1

# Instalação do componentes UploadProgress

cd /sei/instaladores
tar -zxvf uploadprogress.tgz
cd uploadprogress
phpize
./configure --enable-uploadprogress
make
make install
echo "extension=uploadprogress.so" > /etc/php.d/uploadprogress.ini
cd -

cp /sei/files/conf/sei.ini /etc/php.d/
cp /sei/files/conf/sei.conf /etc/httpd/conf.d/ 

# Configuração das bibliotecas de fontes utilizadas pelo SEI
cd /sei/instaladores
rpm -Uvh msttcore-fonts-2.0-3.noarch.rpm
rm -f msttcore-fonts-2.0-3.noarch.rpm


# Instalação do wkhtmltox
cd /sei/instaladores
rpm -Uvh wkhtmltox-0.12.6-1.centos7.x86_64.rpm
rm -f wkhtmltox-0.12.6-1.centos7.x86_64.rpm

# ORACLE oci
mkdir -p /opt/oracle \
cd /opt/oracle

cp /sei/instaladores/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm /opt/oracle
cp /sei/instaladores/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm /opt/oracle
cp /sei/instaladores/oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm /opt/oracle

yum install -y oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm

cd -

echo /usr/lib/oracle/12.2/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Install Oracle extensions
#yum install -y php73-php-pecl-oci8

yum install -y php-dev php-pear build-essential systemtap-sdt-devel 
pecl channel-update pecl.php.net 
export PHP_DTRACE=yes &&  echo "instantclient,/usr/lib/oracle/12.2/client64/lib"|pecl install oci8-2.2.0 && unset PHP_DTRACE

echo "extension=oci8.so" > /etc/php.d/oci8.ini 

rm -rf  /files/instaladores \
        /opt/oracle/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm \
        /opt/oracle/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm \
        /opt/oracle/oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm


# install sodium
#cd /sei/instaladores
#tar -xvzf libsodium-1.0.18-stable.tar.gz 
#cd libsodium-stable/
#./configure
#make
#make install
#ldconfig
#pecl install -f libsodium
#echo "extension=sodium.so" > /etc/php.d/uploadprogress.ini
#cd -


mkdir -p /sei/controlador-instalacoes/ /sei/arquivos_externos_sei/ /sei/certs

yum -y clean all

exit 0
