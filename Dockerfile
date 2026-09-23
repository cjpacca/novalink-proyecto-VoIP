# Usamos Ubuntu como sistema base
FROM ubuntu:22.04

# Evitamos interacciones manuales
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalamos dependencias requeridas
RUN apt-get update && apt-get install -y \
    build-essential \
    openssl \
    wget \
    git \
    pkg-config \
    libedit-dev \
    uuid-dev \
    libjansson-dev \
    libxml2-dev \
    sqlite3 \
    libsqlite3-dev \
    libssl-dev \
    libsrtp2-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Descargamos el código fuente de Asterisk directamente desde el servidor oficial
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz && \
    tar -xzf asterisk-20-current.tar.gz && \
    rm asterisk-20-current.tar.gz && \
    mv asterisk-20.*/ asterisk/

# 3. Compilamos Asterisk
WORKDIR /usr/src/asterisk
RUN make distclean || true
RUN ./configure
RUN make menuselect.makeopts
RUN make
RUN make install
RUN make samples

# 4. (Opcional) Las configuraciones se montarán externamente como Volumen (-v)
# COPY ./config-sergio/ /etc/asterisk/

# 5. Autogeneramos los certificados de seguridad TLS para la central (IP Dinámica)
ARG PBX_IP="127.0.0.1"
RUN mkdir -p /etc/asterisk/keys/ && \
    openssl req -x509 -newkey rsa:4096 \
    -keyout /etc/asterisk/keys/asterisk.key \
    -out /etc/asterisk/keys/asterisk.crt \
    -days 365 -nodes -subj "/CN=${PBX_IP}"

# 6. Exponemos los puertos (Puerto 5061 TCP)
EXPOSE 5060/udp 5060/tcp
EXPOSE 5061/tcp
EXPOSE 10000-20000/udp

# 7. Comando por defecto
CMD ["/usr/sbin/asterisk", "-f"]
