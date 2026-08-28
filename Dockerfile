# Usamos Ubuntu como sistema base
FROM ubuntu:22.04

# Evitamos interacciones manuales
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalamos dependencias requeridas
RUN apt-get update && apt-get install -y \
    build-essential \
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

# 2. Copiamos el código fuente hacia dentro del contenedor
COPY ./src/asterisk-20*/ /usr/src/asterisk/

# 3. Compilamos Asterisk
WORKDIR /usr/src/asterisk
RUN make distclean || true
RUN ./configure
RUN make menuselect.makeopts
RUN make
RUN make install
RUN make samples

# 4. Inyectamos configuraciones
COPY ./config-sergio/ /etc/asterisk/

# 5. Inyectamos los certificados de seguridad
COPY ./keys/ /etc/asterisk/keys/

# 6. Exponemos los puertos (Puerto 5061 TCP)
EXPOSE 5060/udp 5060/tcp
EXPOSE 5061/tcp
EXPOSE 10000-20000/udp

# 7. Comando por defecto
CMD ["/usr/sbin/asterisk", "-f"]
