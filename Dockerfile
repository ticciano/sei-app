FROM centos:7

ENV TERM xterm

ADD https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/msttcore-fonts-2.0-3.noarch.rpm \
    https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm \
    https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm \
    https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm \
    https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/uploadprogress.tgz \
    https://github.com/cadumsx/sei-docker-binarios/raw/main/pacoteslinux/wkhtmltox-0.12.6-1.centos7.x86_64.rpm /sei/instaladores/
    #https://github.com/spbgovbr/sei-docker-binarios/raw/main/pacoteslinux/libsodium-1.0.18-stable.tar.gz /sei/instaladores/
    

# Descomentar caso os repositorios europeus estejam bloqueados no firewall
# COPY remi-repo/* /etc/yum.repos.d/

COPY prometheus/node_exporter /usr/local/bin

ADD files/ /sei/files/
    
RUN bash /sei/files/install.sh

RUN cp /sei/files/scripts-e-automatizadores/entrypoint.sh / && \
    cp /sei/files/scripts-e-automatizadores/entrypoint-atualizador.sh /

EXPOSE 80
EXPOSE 443
