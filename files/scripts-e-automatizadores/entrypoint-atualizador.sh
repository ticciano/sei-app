#!/bin/bash

# ENVIRONMENT VARIABLES
# $APP_PROTOCOLO
# $APP_HOST
# $APP_ORGAO
# $APP_ORGAO_DESCRICAO
# $APP_NOMECOMPLEMENTO
# $APP_DB_TIPO
# $APP_DB_PORTA
# $APP_DB_SIP_USERNAME
# $APP_DB_SIP_PASSWORD
# $APP_DB_SEI_USERNAME
# $APP_DB_SEI_PASSWORD
# $APP_DB_ROOT_USERNAME
# $APP_DB_ROOT_PASSWORD

set -e

if [ -z "$APP_PROTOCOLO" ] || \
   [ -z "$APP_HOST" ] || \
   [ -z "$APP_ORGAO" ] || \
   [ -z "$APP_ORGAO_DESCRICAO" ] || \
   [ -z "$APP_NOMECOMPLEMENTO" ] || \
   [ -z "$APP_DB_TIPO" ] || \
   [ -z "$APP_DB_PORTA" ] || \
   [ -z "$APP_DB_SEI_BASE" ] || \
   [ -z "$APP_DB_SIP_BASE" ] || \
   [ -z "$APP_DB_SIP_USERNAME" ] || \
   [ -z "$APP_DB_SIP_PASSWORD" ] || \
   [ -z "$APP_DB_SEI_USERNAME" ] || \
   [ -z "$APP_DB_SEI_PASSWORD" ] || \
   [ -z "$APP_DB_ROOT_USERNAME" ] || \
   [ -z "$APP_DB_ROOT_PASSWORD" ]; then
    echo "Informe as seguinte variáveis de ambiente no seu docker-compose ou no container:"
    echo "APP_PROTOCOLO=$APP_PROTOCOLO"
    echo "APP_HOST=$APP_HOST"
    echo "APP_ORGAO=$APP_ORGAO"
    echo "APP_ORGAO_DESCRICAO=$APP_ORGAO_DESCRICAO"
    echo "APP_NOMECOMPLEMENTO=$APP_NOMECOMPLEMENTO"
    echo "APP_DB_TIPO=$APP_DB_TIPO (deve ser MySql, Sqlserver ou Oracle)"
    echo "APP_DB_PORTA=$APP_DB_PORTA"
    echo "APP_DB_SIP_BASE=$APP_DB_SIP_BASE"
    echo "APP_DB_SEI_BASE=$APP_DB_SEI_BASE"
    echo "APP_DB_SIP_USERNAME=$APP_DB_SIP_USERNAME"
    echo "APP_DB_SIP_PASSWORD=$APP_DB_SIP_PASSWORD"
    echo "APP_DB_SEI_USERNAME=$APP_DB_SEI_USERNAME"
    echo "APP_DB_SEI_PASSWORD=$APP_DB_SEI_PASSWORD"
    echo "APP_DB_ROOT_USERNAME=$APP_DB_ROOT_USERNAME"
    echo "APP_DB_ROOT_PASSWORD=$APP_DB_ROOT_PASSWORD"

    exit 1
fi


echo "***************************************************"
echo "***************************************************"
echo "**INICIANDO CONFIGURACOES BASICAS DO APACHE E SEI**"
echo "***************************************************"
echo "***************************************************"

APP_HOST_URL=$APP_PROTOCOLO://$APP_HOST

echo "127.0.0.1 $APP_HOST" >> /etc/hosts

# Direciona logs para saida padrão para utilizar docker logs
ln -sf /dev/stdout /var/log/httpd/access_log
ln -sf /dev/stdout /var/log/httpd/ssl_access_log
ln -sf /dev/stdout /var/log/httpd/ssl_request_log
ln -sf /dev/stderr /var/log/httpd/error_log
ln -sf /dev/stderr /var/log/httpd/ssl_error_log


# Atribuição dos parâmetros de configuração do SEI
if [ -f /opt/sei/config/ConfiguracaoSEI.php ] && [ ! -f /opt/sei/config/ConfiguracaoSEI.php~ ]; then
    mv /opt/sei/config/ConfiguracaoSEI.php /opt/sei/config/ConfiguracaoSEI.php~
fi

if [ ! -f /opt/sei/config/ConfiguracaoSEI.php ]; then
    cp /sei/files/conf/ConfiguracaoSEI.php /opt/sei/config/ConfiguracaoSEI.php
fi

# Atribuição dos parâmetros de configuração do SIP
if [ -f /opt/sip/config/ConfiguracaoSip.php ] && [ ! -f /opt/sip/config/ConfiguracaoSip.php~ ]; then
    mv /opt/sip/config/ConfiguracaoSip.php /opt/sip/config/ConfiguracaoSip.php~
fi

if [ ! -f /opt/sip/config/ConfiguracaoSip.php ]; then
    cp /sei/files/conf/ConfiguracaoSip.php /opt/sip/config/ConfiguracaoSip.php
fi

# Ajustes de permissões diversos para desenvolvimento do SEI
chmod +x /opt/sei/bin/pdfboxmerge.jar
mkdir -p /opt/sei/temp
mkdir -p /opt/sip/temp
chmod -R 777 /opt/sei/temp
chmod -R 777 /opt/sip/temp


set +e

RET=1
while [ ! "$RET" == "0" ]
do
    echo ""
    echo "Esperando a base de dados ficar disponivel... Vamos tentar chama-la ...."
    sleep 3
    
    php -r "
    require_once '/opt/sip/web/Sip.php';    
    \$conexao = BancoSip::getInstance();
    \$conexao->abrirConexao();
    \$conexao->executarSql('select sigla from sistema');"
    
    RET=$?   
    
done  

set -e

echo "***************************************************"
echo "***************************************************"
echo "UPDATE NA BASE DE DADOS - ORGAO E SISTEMA**********"
echo "***************************************************"
echo "***************************************************"

# Atualização do endereço de host da aplicação
echo "Atualizando Banco de Dados com as Configuracoes Iniciais..."

if [ "$APP_DB_TIPO" == "Oracle" ]; then
    echo "Atualizando Oracle..."
#    echo "alter user sip identified by sip_user;" | sqlplus64 $APP_DB_ROOT_USERNAME/$APP_DB_ROOT_PASSWORD@$APP_DB_HOST
#    echo "alter user sei identified by sei_user;" | sqlplus64 $APP_DB_ROOT_USERNAME/$APP_DB_ROOT_PASSWORD@$APP_DB_HOST
    echo "update orgao set sigla='$APP_ORGAO', descricao='$APP_ORGAO_DESCRICAO';" | sqlplus64 $APP_DB_SIP_USERNAME/$APP_DB_SIP_PASSWORD@$APP_DB_HOST
#    echo "update orgao set sigla='$APP_ORGAO', descricao='$APP_ORGAO_DESCRICAO';" | sqlplus64 sei/sei_user@$APP_DB_HOST
    echo "update sistema set pagina_inicial='$APP_HOST_URL/sip' where sigla='SIP';" | sqlplus64 $APP_DB_SIP_USERNAME/$APP_DB_SIP_PASSWORD@$APP_DB_HOST
    echo "update sistema set pagina_inicial='$APP_HOST_URL/sei/inicializar.php', web_service='$APP_HOST_URL/sei/controlador_ws.php?servico=sip' where sigla='SEI';" | sqlplus64 $APP_DB_ROOT_USERNAME/$APP_DB_ROOT_PASSWORD@$APP_DB_HOST
fi


echo "***************************************************"
echo "***************************************************"
echo "**GERACAO DE CERTIFICADO PARA O APACHE*************"
echo "***************************************************"
echo "***************************************************"

# Gera certificados caso necessário para desenvolvimento    
if [ ! -d "/sei/certs/seiapp" ]; then
    echo "Diretorio /sei/certs/seiapp nao encontrado, criando ..."
    mkdir -p /sei/certs/seiapp
fi

echo "Verificando se certificados existem no diretorio /certs...."
if [ ! -f /sei/certs/seiapp/sei-ca.pem ] || [ ! -f /sei/certs/seiapp/sei.crt ]; then
    echo "Arquivos de cert nao encontrados criando auto assinados ..."
    
    cd /sei/certs/seiapp

    echo "Criando CA"  
    openssl genrsa -out sei-ca-key.pem 2048
    openssl req -x509 -new -nodes -key sei-ca-key.pem \
        -days 10000 -out sei-ca.pem -subj "/CN=sei-dev"
    
    echo "Criando certificados para o dominio: $APP_HOST"
    openssl genrsa -out sei.key 2048
    openssl req -new -nodes -key sei.key \
        -days 10000 -out sei.csr -subj "/CN=$APP_HOST"
    openssl x509 -req -in sei.csr -CA sei-ca.pem \
        -CAkey sei-ca-key.pem -CAcreateserial \
        -out sei.crt -days 10000 -extensions v3_req

    cat /sei/certs/seiapp/sei-ca.pem >> /etc/ssl/certs/cacert.pem
    echo "Adicionada nova CA ao TrustStore\n"
else
    echo "Arquivos de cert encontrados vamos tentar utilizá-los..."
fi

cd /sei/certs/seiapp
cp sei.crt /etc/pki/tls/certs/sei.crt
cp sei-ca.pem /etc/pki/tls/certs/sei-ca.pem
cp sei.key /etc/pki/tls/private/sei.key 
cat sei.crt sei.key >> /etc/pki/tls/certs/sei.pem

echo "Incluindo TrustStore no sistema"
#cp /icpbrasil/*.crt /etc/pki/ca-trust/source/anchors/
cp sei-ca.pem /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
update-ca-trust enable

echo "***************************************************"
echo "***************************************************"
echo "**ATUALIZACAO DE SEQUENCES*************************"
echo "***************************************************"
echo "***************************************************"

if [ ! -f /sei/controlador-instalacoes/instalado.ok ]; then
    
    echo "Vamos fazer o apache se apropriar dos dados externos... Aguarde"
    chown -R apache:apache /sei/arquivos_externos_sei/

fi

echo "Atualizar sequences! todo ajeitar a base de ref e retirar isso"
# copiado do sei-vagrant do guilhermao
# Atualizar os endereços de host definidos para na inicialização e sincronização de sequências
php -r "
    require_once '/opt/sip/web/Sip.php';    
    \$conexao = BancoSip::getInstance();
    \$conexao->setBolScript(true);
    \$objScriptRN = new ScriptRN();
    \$objScriptRN->atualizarSequencias();    
"

echo "atualizar sequences do SEI"
# Atualizar os endereços de host definidos para na inicialização e sincronização de sequências
php -r "
    require_once '/opt/sei/web/SEI.php';
    \$conexao = BancoSEI::getInstance();
    \$conexao->setBolScript(true);
    \$objScriptRN = new ScriptRN();
    \$objScriptRN->atualizarSequencias();
" 
echo "Finalizacao de atualizacao de sequences"

touch /sei/controlador-instalacoes/instalado.ok

echo "***************************************************"
echo "Atualizador chegou ao final..."
echo "Verifique nas mensagens acima se ocorreu tudo certo."
echo "Talvez haja alguma observacao importante"
echo "Fechando e liberando para o modulo de aplicacao"
echo "***************************************************"

